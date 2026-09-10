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
    #
    # Detection ducks on #id rather than testing Document/EmbeddedDocument,
    # because a host app that builds model classes at runtime can produce
    # documents those tests answer false for.
    def describe(document)
      return document.inspect unless document.respond_to?(:id)

      "#{named_class(document.class)} #{document.id}"
    end

    # Models built at runtime are anonymous subclasses; walk up to a named one.
    def named_class(klass)
      klass = klass.superclass while klass.name.nil? && klass.superclass
      klass.name || klass.inspect
    end
  end
end
