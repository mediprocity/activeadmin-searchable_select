module ActiveAdmin
  module Select2
    # Mixin for searchable select inputs.
    #
    # Supports the same options as inputs of type `:select`.
    #
    # Adds support for an `ajax` option to fetch options data from a
    # JSON endpoint. Pass either `true` to use defaults or a hash
    # containing some of the following options:
    #
    # - `resource`: ActiveRecord model class of ActiveAdmin resource
    #    which provides the collection action to fetch options
    #    from. By default the resource is auto detected via the name
    #    of the input attribute.
    #
    # - `collection_name`: Name passed to the
    #   `searchable_select_options` method that defines the collection
    #   action to fetch options from.
    #
    # - `params`: Hash of query parameters that shall be passed to the
    #   options endpoint.
    #
    # If the `ajax` option is present, the `collection` option is
    # ignored.
    module SelectInputExtension
      # @api private
      def input_html_options
        options = super
        options[:class] = [options[:class], 'select2-input'].compact.join(' ')
        options.merge('data-ajax-url' => ajax_url)
      end

      # @api private
      def collection_from_options
        options[:ajax] ? selected_value_collection : super
      end

      private

      def ajax_url
        return unless options[:ajax]
        template.polymorphic_path([:admin, ajax_resource_class],
                                  action: option_collection.collection_action_name,
                                  **ajax_params)
      end

      def selected_value_collection
        [selected_value_option].compact
      end

      def selected_value_option
        [option_collection.text(selected_record), selected_record.id] if selected_record
      end

      def selected_record
        @selected_record ||=
          selected_value && option_collection_scope.find_by_id(selected_value)
      end

      def selected_value
        @object.send(input_name) if @object
      end

      def option_collection_scope
        option_collection.scope(template, ajax_params)
      end

      def option_collection
        ajax_resource
          .searchable_select_option_collections
          .fetch(ajax_option_collection_name) do
          raise("No option collection named '#{ajax_option_collection_name}' " \
                "defined in '#{ajax_resource_class.name}' admin.")
        end
      end

      def ajax_resource
        @ajax_resource ||=
          template.active_admin_namespace.resource_for(ajax_resource_class) ||
          raise("No admin found for '#{ajax_resource_class.name}' to fetch " \
                'options for searchable select input from.')
      end

      def ajax_resource_class
        ajax_options.fetch(:resource) do
          raise_cannot_auto_detect_resource unless reflection
          reflection.klass
        end
      end

      def raise_cannot_auto_detect_resource
        raise('Cannot auto detect resource to fetch options for searchable select input from. ' \
              "Explicitly pass class of an ActiveAdmin resource:\n\n" \
              "  f.input(:custom_category,\n" \
              "          type: :select2,\n" \
              "          ajax: {\n" \
              "            resource: Category\n" \
              "          })\n")
      end

      def ajax_option_collection_name
        ajax_options.fetch(:collection_name, :all)
      end

      def ajax_params
        ajax_options.fetch(:params, {})
      end

      def ajax_options
        options[:ajax] == true ? {} : options[:ajax]
      end
    end
  end
end