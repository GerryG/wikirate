card_accessor :vote_count, :type=>:number, :default=>"0"
card_accessor :upvote_count, :type=>:number, :default=>"0"
card_accessor :downvote_count, :type=>:number, :default=>"0"

card_accessor :metric_type,
              :type=>:pointer, :default=>"[[Researched]]"

def metric_type
  metric_type_card.item_names.first
end

def metric_type_codename
  Card[metric_type].codename
end

    # def value company, year
#   (value_card = Card["#{name}+#{company}+#{year}+#{value}"]) &&
#     value_card.content
# end

def create_value args
  missing = [:company, :year, :value].reject { |v| args[v] }
  if missing.present?
    errors.add 'metric value', "missing #{missing.to_sentence}"
    return
  end
  create_args = {
    name: "#{name}+#{args[:company]}+#{args[:year]}",
    type_id: Card::MetricValueID,
    '+value' => args[:value]
  }
  if metric_type_codename == :reseached
    if !args[:source]
      errors.add 'metric value', "missing source"
      return
    end
    create_args[:source] = args[:source]
  end
  Card.create! create_args
end

def companies_with_years_and_values
  Card.search(right: 'value', left: {
    left: { left: card.name },
    right: { type: 'year' }
    }).map do |card|
      [
        card.cardname.left_name.left_name.right,
        card.cardname.left_name.right, card.content
      ]
  end
end

def random_value_card
  Card.search(right: 'value',
              left: {
                left: { left: name },
                right: { type: 'year' }
              },
              limit: 1).first
end

def random_company_card_with_value
  return unless rvc = random_value_card
  rvc.left.left.right
end

format :html do

  def tab_radio_button id, active=false
    <<-HTML
    <li role="tab" class="pointer-radio #{'active' if active}">
      <label data-target="##{tab_pane_id id}">
        <input id="#{id}" name="intervaltype"
               value="#{id}"
               class="pointer-radio-button"
               type="radio" #{'checked' if active} />
          #{id}
        </label>
    </li>
    HTML
  end

  def tab_pane_id name
    "#{name.downcase}Pane"
  end

  def tab_pane name, active=false
    new_metric = Card.new type: MetricID, '+*metric type' => "[[#{name}]]"
    new_metric.reset_patterns
    new_metric.include_set_modules
    div_args = {
      role: 'tabpanel',
      class: 'tab-pane',
      id: tab_pane_id(name)
    }
    add_class div_args, 'active' if active
    content_tag :div, div_args do
      subformat(new_metric)._render_new_tab_pane
    end
  end

  view :new do |args|
    frame_and_form :create, args, 'main-success' => 'REDIRECT' do

    <<-HTML
    <fieldset class="card-editor editor">
      <div role="tabpanel">
        <input class="card-content form-control" type="hidden" value=""
               name="card[subcards][+*metric type][content]"
               id="card_subcards___metric_type_content">
          <ul class="nav nav-tabs pointer-radio-list" role="tablist">
            #{tab_radio_button 'Researched', true}
            #{tab_radio_button 'Formula'}
            #{tab_radio_button 'Score'}
            #{tab_radio_button 'WikiRating'}
          </ul>

          <!-- Tab panes -->
          <div class="tab-content">
            #{tab_pane 'Researched', true}
            #{tab_pane 'Formula'}
            #{tab_pane 'Score'}
            #{tab_pane 'WikiRating'}
          </div>
      </div>
    </fieldset>
    <script>
    $('input[name="intervaltype"]').click(function () {
        //jQuery handles UI toggling correctly when we apply "data-target"
        // attributes and call .tab('show')
        //on the <li> elements' immediate children, e.g the <label> elements:
        $(this).closest('label').tab('show');
    });
    </script>
    HTML
    end
  end

  view :new_tab_pane do |args|
    default_new_args_buttons args
    content_args = args.merge structure: 'metric+*type+*edit structure'
    card_form :create, hidden: {
                         'subcards[+*metric type]' => "[[#{card.metric_type}]]"
                       },
                       'main-success' => 'REDIRECT' do
      output [
               _render(:name_formgroup, args),
               _render(:content_formgroup, content_args),
               _render(:button_formgroup, args)
             ]
    end
  end

  view :name_formgroup do |args|
    formgroup 'Metric Name', raw(name_field form), editor: 'name', help:
      args[:help]
  end

  def name_field form=nil, options={}
    form ||= self.form
    output [
             metric_designer_field(options),
             '<span>+</span>',
             metric_title_field(options)
           ]
  end

  def metric_designer_field options={}
    # I don't see a way to get options through to the form field
    if options.present?
      label_tag(:designer, 'Metric Designer') +
        text_field('subcards[+designer]', {
          value: Auth.current.name,
          autocomplete: 'off'
        }.merge(options))
    else
      designer = card.add_subfield :designer, content: Auth.current.name,
                                              type_id: PhraseID
      nest designer, options.merge(view: :editor, title: 'Metric Designer')
    end
  end

  def metric_title_field options={}
    title = card.add_subfield(:title, content: card.cardname.tag,
                                 type_id: PhraseID)
    #with_nest_mode :edit  do
      nest title, view: :editor, title: 'Metric Title'
   # end
    # text_field('subcards[+*title]', {
    #   value: card.name,
    #   autocomplete: 'off'
    # }.merge(options))
  end

  view :legend do |args|
    if (unit = Card.fetch("#{card.name}+unit"))
      unit.raw_content
    elsif (range = Card.fetch("#{card.name}+range"))
      "/#{range.raw_content}"
    else
      ''
    end
  end

  view :item_view do |args|
    handle =
      if args[:draggable]
        <<-HTML
          <div class="handle">
            <span class="glyphicon glyphicon-option-vertical"></span>
          </div>
        HTML
      end

    value =
      if args[:company]
        <<-HTML
          <div class="data-item hide-with-details">
            {{#{card.name}+#{args[:company]}+latest value|concise}}
          </div>
        HTML
      end

    vote =
      if args[:vote]
        %(<div class="hidden-xs hidden-md">{{#{card.name}+*vote count}}</div>)
      end
    metric_designer = card.cardname.left
    metric_name = card.cardname.right

    html = <<-HTML
    <!--prototype: Company+MetricDesigner+MetricName+yinyang drag item -->
    <div class="yinyang-row">
    <div class="metric-item value-item">
      <div class="header metric-details-toggle"
           data-append="#{card.key}+add_to_formula">
        #{handle}
        #{vote}
        <div class="logo hidden-xs hidden-md">
          {{#{metric_designer}+image|core;size:small}}
        </div>
        <div class="name">
            {{#{metric_name}|name}}
        </div>
      </div>
      <div class="details"></div>
    </div>
  </div>
    HTML
    with_inclusion_mode :normal do
      wrap args do
        process_content html
      end
    end
  end


  view :item_view_with_value do |args|
    handle =
      if args[:draggable]
        <<-HTML
          <div class="handle">
            <span class="glyphicon glyphicon-option-vertical"></span>
          </div>
        HTML
      end

    value =
      if args[:company]
        <<-HTML
          <div class="data-item hide-with-details">
            {{#{card.name}+#{args[:company]}+latest value|concise}}
          </div>
        HTML
      end

    vote =
      if args[:vote]
        %(<div class="hidden-xs hidden-md">{{#{card.name}+*vote count}}</div>)
      end
    metric_designer = card.cardname.left
    metric_name = card.cardname.right

    html = <<-HTML
    <!--prototype: Company+MetricDesigner+MetricName+yinyang drag item -->
    <div class="yinyang-row">
    <div class="metric-item value-item">
      <div class="header">
        #{handle}
        #{vote}
        <a href="{{_llr+contributions|linkname}}">
        <div class="logo hidden-xs hidden-md">
          {{#{metric_designer}+image|core;size:small}}
        </div>
        </a>
        <div class="name">
          <a class="inherit-anchor" href="{{#{card.name}|linkname}}">
            {{#{metric_name}|name}}
          </a>
        </div>
      </div>
      <div class="data metric-details-toggle"
           data-append="#{card.key}+add_to_formula">
        #{value}
        <div class="data-item show-with-details text-center">
          <span class="label label-metric">
            [[#{card.name}|Metric Details]]
          </span>
        </div>
      </div>
      <div class="details">
      </div>
    </div>
  </div>
    HTML
    with_inclusion_mode :normal do
      wrap args do
        process_content html
      end
    end
  end

  def view_caching?
    true
  end
end

def analysis_names
  return [] unless (topics = Card["#{name}+#{Card[:wikirate_topic].name}"]) &&
                   (companies = Card["#{name}+#{Card[:wikirate_company].name}"])

  companies.item_names.map do |company|
    topics.item_names.map do |topic|
      "#{company}+#{topic}"
    end
  end.flatten
end

format :json do
  view :content do
    companies_with_years_and_values.to_json
  end
end

event :set_metric_name, :initialize,
      on: :create do
  binding.pry
  return if name.present?
  title = (tcard = remove_subfield(:title)) && tcard.content
  designer = (dcard = remove_subfield(:designer)) && dcard.content
  self.name = "#{designer}+#{title}"
end
