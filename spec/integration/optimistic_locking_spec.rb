describe "optimistic locking plugin" do
  describe "models with plugin" do

    subject do
      Class.new do
        include MongoMapper::Document
        plugin MongoMapper::Plugins::OptimisticLocking

        key :foo_text, String
      end.new
    end

    context "new records" do

      it "saves the record normally" do

        subject.foo_text = "foo bar baz"

        expect( subject.save ).to be true
        expect( subject.reload.foo_text ).to eq "foo bar baz"

      end
    end

    context "previously persisted records" do

      before do
        subject.save!
      end

      it "saves the record normally if no conflicts exist" do

        subject.foo_text = "foo bar baz"

        expect( subject.save ).to be true
        expect( subject.reload.foo_text ).to eq "foo bar baz"

      end

      context 'conflict detected' do

        it 'raises a StaleDocumentError' do

          dupped_subject = subject.class.find!(subject.id)
          dupped_subject.foo_text = "baz bar foo"
          dupped_subject.save

          expect {
            subject.foo_text = "foo bar baz"
            subject.save
          }.to raise_error(MongoMapper::StaleDocumentError)

        end

      end

    end
  end

  describe "models without plugin" do

    subject do
      Class.new do
        include MongoMapper::Document
        # plugin MongoMapper::Plugins::OptimisticLocking

        key :foo_text, String
      end.new
    end

    it "allows records to interfere with one another" do
      subject.save

      dupped_subject = subject.class.find(subject.id)
      dupped_subject.foo_text = "baz bar foo"
      dupped_subject.save

      expect {
        subject.foo_text = "foo bar baz"
        subject.save
      }.to_not raise_error
    end
  end
end
