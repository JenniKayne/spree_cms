module SpreeCms
  module PageHelpers
    def cms_asset(image_definition, _size)
      Spree::CmsImage.where(id: image_definition[:id]).first
    end

    def cms_image(image_definition, size)
      asset = Spree::CmsImage.where(id: image_definition[:id]).first
      return image_definition[:url] if asset.blank?

      asset.url(size)
    end

    def options_for_cms_blocks_group_select(selected_value = nil)
      options_for_select(
        SpreeCms.configuration.cms_block_groups.map { |key, h| [h[:name], key] },
        selected_value
      )
    end

    def partial_exists(partial_path)
      lookup_context.find_all(partial_path, [], true).any?
    end

    def render_snippet(slug)
      page = Spree::Page.find_by_slug(slug)
      raw page.body if page
    end
  end
end
