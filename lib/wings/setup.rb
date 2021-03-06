# frozen_string_literal: true

ActiveFedora::Base.include Wings::Valkyrizable

module ActiveFedora
  def self.model_mapper
    ActiveFedora::DefaultModelMapper.new(classifier_class: Wings::ActiveFedoraClassifier)
  end
end

Valkyrie::MetadataAdapter.register(
  Wings::Valkyrie::MetadataAdapter.new, :wings_adapter
)
Valkyrie.config.metadata_adapter = :wings_adapter

if ENV['RAILS_ENV'] == 'test'
  Valkyrie::MetadataAdapter.register(
    Valkyrie::Persistence::Memory::MetadataAdapter.new, :test_adapter
  )
end

Valkyrie::StorageAdapter.register(
  Wings::Storage::ActiveFedora
    .new(connection: Ldp::Client.new(ActiveFedora.fedora.host), base_path: ActiveFedora.fedora.base_path),
  :active_fedora
)
Valkyrie.config.storage_adapter = :active_fedora

# TODO: Custom query registration is not Wings specific.  These custom_queries need to be registered for other adapters too.
#       A refactor is needed to add the default implementations to hyrax.rb and only handle the wings specific overrides here.
custom_queries = [Hyrax::CustomQueries::Navigators::CollectionMembers,
                  Hyrax::CustomQueries::Navigators::ChildCollectionsNavigator,
                  Hyrax::CustomQueries::Navigators::ChildFilesetsNavigator,
                  Hyrax::CustomQueries::Navigators::ChildWorksNavigator,
                  Hyrax::CustomQueries::Navigators::FindFiles,
                  Wings::CustomQueries::FindAccessControl, # override Hyrax::CustomQueries::FindAccessControl
                  Wings::CustomQueries::FindFileMetadata, # override Hyrax::CustomQueries::FindFileMetadata
                  Wings::CustomQueries::FindManyByAlternateIds] # override Hyrax::CustomQueries::FindManyByAlternateIds
custom_queries.each do |query_handler|
  Valkyrie.config.metadata_adapter.query_service.custom_queries.register_query_handler(query_handler)
end

Wings::ModelRegistry.register(Hyrax::AccessControl,     Hydra::AccessControl)
Wings::ModelRegistry.register(Hyrax::AdministrativeSet, AdminSet)
Wings::ModelRegistry.register(Hyrax::PcdmCollection,    ::Collection)
Wings::ModelRegistry.register(Hyrax::FileSet,           FileSet)
Wings::ModelRegistry.register(Hyrax::Embargo,           Hydra::AccessControls::Embargo)
Wings::ModelRegistry.register(Hyrax::Lease,             Hydra::AccessControls::Lease)
