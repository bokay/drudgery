module Drudgery
  class Job
    attr_reader :id
    attr_accessor :extractor, :loader, :transformer, :batch_size

    def initialize(options={})
      @id           = Time.now.nsec
      @extractor    = options[:extractor]
      @loader       = options[:loader]
      @transformer  = options[:transformer]
      @batch_size   = options[:batch_size] || 1000

      @records = []
    end

    def name
      "#{@extractor.name} => #{@loader.name}"
    end

    def extract(*args)
      if args.first.kind_of?(Symbol)
        extractor = Drudgery::Extractors.instantiate(*args)
      else
        extractor = args.first
      end

      yield extractor if block_given?

      @extractor = extractor
    end

    def transform(transformer=Drudgery::Transformer.new, &processor)
      transformer.register(processor)

      @transformer = transformer
    end

    def load(*args)
      if args.first.kind_of?(Symbol)
        loader = Drudgery::Loaders.instantiate(*args)
      else
        loader = args.first
      end

      yield loader if block_given?

      @loader = loader
    end

    def perform
      extract_records do |record|
        @records << record

        if @records.size == @batch_size
          load_records
        end
      end

      load_records
    end

    private
    def extract_records
      @extractor.extract do |data, index|
        record = transform_data(data)

        if record.nil?
          next
        else
          yield record
        end
      end
    end

    def load_records
      @loader.load(@records) unless @records.empty?
      @records.clear
    end

    def transform_data(data)
      if @transformer
        @transformer.transform(data)
      else
        data
      end
    end
  end
end
