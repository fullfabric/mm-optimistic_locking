module MongoMapper
  module Plugins
    module OptimisticLocking
      module QueryingInterceptor
        def self.included(base)
          base.class_eval do
            alias_method_chain :save_to_collection, :optimistic_locking
          end
        end

        def save_to_collection_with_optimistic_locking(options = {})
          if persisted? && keys.keys.include?("_lock_version")

            # Delete this key from the options hash, otherwise we get hit by
            # this: https://github.com/mongomapper/mongomapper/issues/550
            options.delete(:persistence_method)

            current_lock_version = self._lock_version
            begin
              self._lock_version += 1
              result = collection.update({:_id => self._id, :$or => [ {:_lock_version => current_lock_version},  { :_lock_version => { :$exists => false } } ] },
                                          to_mongo, :upsert => false, :w => 1)

              raise MongoMapper::StaleDocumentError.new(self) unless result["updatedExisting"]
            rescue
              self._lock_version -= 1
              raise
            end
          else
            save_to_collection_without_optimistic_locking(options)
          end
        end
      end
    end
  end
end
