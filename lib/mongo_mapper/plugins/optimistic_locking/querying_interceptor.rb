module MongoMapper
  module Plugins
    module OptimisticLocking
      module QueryingInterceptor
        def save_to_collection(options = {})
          if persisted? && keys.keys.include?("_lock_version")

            # Delete this key from the options hash, otherwise we get hit by
            # this: https://github.com/mongomapper/mongomapper/issues/550
            options.delete(:persistence_method)

            current_lock_version = self._lock_version
            begin
              self._lock_version += 1

              result = collection.update_one(
                {
                  :_id => self._id,
                  :$or => [
                    { :_lock_version => current_lock_version },
                    { :_lock_version => { :$exists => false } }
                  ]
                },
                to_mongo,
                { upsert: false, w: 1 }
              )

              raise MongoMapper::StaleDocumentError.new(self) unless result.modified_count > 0
            rescue
              self._lock_version -= 1
              raise
            end
          else
            super(options)
          end
        end
      end
    end
  end
end
