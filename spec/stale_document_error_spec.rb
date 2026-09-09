describe MongoMapper::StaleDocumentError do
  let(:model) do
    Class.new do
      include MongoMapper::Document
      plugin MongoMapper::Plugins::OptimisticLocking

      def self.name
        "BlogPost"
      end
    end
  end

  it "names the document by class and id instead of dumping its attributes" do
    document = model.create!
    error = described_class.new(document)

    expect(error.message).to eq("Document BlogPost #{document.id} is stale and must be reloaded from MongoDB")
    expect(error.document).to be(document)
  end

  it "walks up to the first named class for anonymous subclasses" do
    document = Class.new(model).new

    expect(described_class.new(document).message).to eq(
      "Document BlogPost #{document.id} is stale and must be reloaded from MongoDB"
    )
  end

  it "still inspects arguments that are not documents" do
    expect(described_class.new("form doc").message).to eq(
      'Document "form doc" is stale and must be reloaded from MongoDB'
    )
  end
end
