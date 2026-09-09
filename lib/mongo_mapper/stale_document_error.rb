module MongoMapper
  class StaleDocumentError < MongoMapper::Error
    attr_reader :document

    def initialize(document)
      @document = document
      super("Document #{describe(document)} is stale and must be reloaded from MongoDB")
    end

    private

    # A document is named by class and id: dumping its attributes into the
    # message floods logs and leaks the record's data into error trackers.
    def describe(document)
      return document.inspect unless document.is_a?(MongoMapper::Document)

      "#{named_class(document.class)} #{document.id}"
    end

    # Models built at runtime are anonymous subclasses; walk up to a named one.
    def named_class(klass)
      klass = klass.superclass while klass.name.nil? && klass.superclass
      klass.name || klass.inspect
    end
  end
end
