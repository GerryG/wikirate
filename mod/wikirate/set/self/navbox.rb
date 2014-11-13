format :html do

  view :raw do |args|
    input_args = { :class=>'navbox' }
    @@placeholder ||= begin
      p = Card["#{Card[:navbox].name}+*placeholder"] and p.raw_content
    end
    
    input_args[:placeholder] = @@placeholder if @@placeholder

    %{
      <form action="#{Card.path_setting '/:search'}" method="get" class="navbox-form nodblclick">
        <div class="fa fa-search search-icon-position"></div>
        #{ text_field_tag :_keyword, '', input_args }
     </form>
    }
  end
end