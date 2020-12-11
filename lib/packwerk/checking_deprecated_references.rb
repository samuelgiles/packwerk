# typed: true
# frozen_string_literal: true

require "sorbet-runtime"

require "packwerk/reference_lister"

module Packwerk
  class CheckingDeprecatedReferences
    extend T::Sig
    include ReferenceLister

    def initialize(root_path)
      @root_path = root_path
      @deprecated_references = {}
    end

    sig do
      params(reference: Packwerk::Reference, violation_type: ViolationType)
        .returns(T::Boolean)
        .override
    end
    def listed?(reference, violation_type:)
      deprecated_references_for(reference.source_package).listed?(reference, violation_type: violation_type)
    end

    private

    def deprecated_references_for(source_package)
      @deprecated_references[source_package] ||= Packwerk::DeprecatedReferences.new(
        source_package,
        deprecated_references_file_for(source_package),
      )
    end

    def deprecated_references_file_for(package)
      File.join(@root_path, package.name, Packwerk::DeprecatedReferences::CONFIG_FILENAME)
    end
  end
end
