module Spree
  class CmsImage < Spree::Asset
    include ActiveModel::AttributeMethods

    validate :no_attachment_errors

    def self.styles_lambda(_attachment)
      {
        retina: '2400x>',
        large: '1800x>',
        medium: '900x>',
        small: '500x>',
        mini: '200x>',
        icon: '50x>'
      }
    end

    has_attached_file :attachment,
                      styles: ->(attachment) { attachment.instance.class.styles_lambda(attachment) },
                      default_style: :normal,
                      convert_options: { all: '-strip -colorspace sRGB' },
                      processors: %i[thumbnail paperclip_optimizer]
    validates_attachment :attachment, presence: true, content_type: {
      content_type: %w[image/jpeg image/jpg image/png image/gif image/svg+xml]
    }
    after_post_process :find_dimensions

    if Rails.application.secrets.aws_s3_enabled
      attachment_definitions[:attachment][:path] = '/media/cmsimage/:id/:style/:basename.:extension'
      attachment_definitions[:attachment][:default_url] = '/media/cmsimage/:id/:style/:basename.:extension'
      attachment_definitions[:attachment][:url] = ':s3_alias_url'
      attachment_definitions[:attachment][:s3_host_alias] = Rails.application.secrets.attachments_host || Rails.application.secrets.cdn_host
    else
      attachment_definitions[:attachment][:path] = "#{Rails.root}/public/media/cmsimage/:id/:style/:basename.:extension"
      attachment_definitions[:attachment][:url] = "//#{Rails.application.secrets.cdn_host}/media/cmsimage/:id/:style/:basename.:extension"
    end

    def url(size)
      size = :original if attachment_content_type == 'image/svg+xml'
      attachment.url(size, false)
    end

    def find_dimensions
      temporary = attachment.queued_for_write[:original]
      filename = temporary.path unless temporary.nil?
      filename = attachment.path if filename.blank?
      geometry = Paperclip::Geometry.from_file(filename)
      self.attachment_width = geometry.width
      self.attachment_height = geometry.height
    end

    def no_attachment_errors
      unless attachment.errors.empty?
        errors.add :attachment, "Paperclip returned errors for file '#{attachment_file_name}' - check ImageMagick installation or image source file."
        false
      end
    end
  end
end
