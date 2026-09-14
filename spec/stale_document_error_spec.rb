describe MongoMapper::StaleDocumentError do
  # A real constant, not `def self.name`: a subclass INHERITS a redefined
  # self.name, which would leave the anonymous-subclass example below asserting
  # nothing.
  let(:model) do
    stub_const("BlogPost", Class.new do
      include MongoMapper::Document
      plugin MongoMapper::Plugins::OptimisticLocking
    end)
  end

  it "names the document by class and id instead of dumping its attributes" do
    document = model.create!
    error = described_class.new(document)

    expect(error.message).to eq("Document BlogPost #{document.id} is stale and must be reloaded from MongoDB")
    expect(error.document).to be(document)
  end

  it "walks up to the first named class for anonymous subclasses" do
    subclass = Class.new(model)
    document = subclass.new

    expect(subclass.name).to be_nil # otherwise this example never exercises the walk
    expect(described_class.new(document).message).to eq(
      "Document BlogPost #{document.id} is stale and must be reloaded from MongoDB"
    )
  end

  it "falls back to the class itself when no ancestor names the model" do
    document = Class.new { include MongoMapper::Document }.new

    message = described_class.new(document).message

    expect(message).to match(/\ADocument #<Class:0x[0-9a-f]+> #{document.id} is stale/)
    expect(message).not_to include("Document Object")
  end

  it "names an embedded document, which is not a MongoMapper::Document" do
    embedded = Class.new do
      def self.name
        "Profiles::Actor::Role"
      end

      def id
        "63e1423f84534665b4000535"
      end
    end.new

    expect(embedded).not_to be_a(MongoMapper::Document)
    expect(described_class.new(embedded).message).to eq(
      "Document Profiles::Actor::Role 63e1423f84534665b4000535 is stale and must be reloaded from MongoDB"
    )
  end

  it "still inspects arguments that are not documents" do
    expect(described_class.new("form doc").message).to eq(
      'Document "form doc" is stale and must be reloaded from MongoDB'
    )
  end
end
