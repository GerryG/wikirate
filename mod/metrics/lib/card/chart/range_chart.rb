class Card
  module Chart
    class RangeChart < VegaChart
      DEFAULT_BAR_CNT = 10

      def initialize format, opts
        opts[:highlight] &&= opts[:highlight].to_f
        @buckets = opts.delete(:buckets) || DEFAULT_BAR_CNT
        super format, opts
      end

      def generate_data
        calculate_ranges
        add_label min
        each_bucket do |lower, upper|
          add_data range: { from: lower, to: upper }
          add_label upper
        end
      end

      private

      def click_action
        :zoom
      end

      def each_bucket
        lower = min
        @buckets.times do
          upper = lower + bucket_size
          yield lower, upper
          lower = upper
        end
      end

      def add_label number
        @labels << @format.number_to_human(number.to_f).to_f
      end

      def data_item_hash filter
        super(filter).merge x: filter[:range][:to]
      end

      def x_axis
        super.merge scale: "x_label", title: "Ranges"
      end

      def scales
        super << x_label_scale
      end

      def x_label_scale
        { name: "x_label",
          type: "ordinal",
          range: "width",
          domain: @labels,
          points: true }
      end

      def calculate_ranges
        if bucket_size > 2
          @bucket_size = (@bucket_size + 1).to_i
          @min = @min.to_i
          @max = @min + @bucket_size * @buckets
        end
      end

      def bucket_size
        @bucket_size ||= (max - min).to_f / @buckets
      end

      def max
        @max ||= @filter_query.where.maximum(:numeric_value).to_f
      end

      def min
        @min ||= @filter_query.where.minimum(:numeric_value).to_f
      end

      def highlight? filter
        return true unless @highlight_value
        from = filter[:range][:from]
        to = filter[:range][:to]
        @highlight_value >= from && @highlight_value < to
      end

      def highlight_value_from_filter_opts _filter_opts
        nil # zoom instead of higlight
        # filter_opts[:range][:from]
      end
    end
  end
end