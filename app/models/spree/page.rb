class Spree::Page < Spree::Base
  sir_trevor_content :body

  default_scope { order(position: :asc) }

  has_and_belongs_to_many :stores, join_table: 'spree_pages_stores'
  has_many :images, -> { order(:position) },
           as: :viewable, dependent: :destroy, class_name: 'Spree::CmsImage'

  validates :title, presence: true
  validates :slug, presence: true
  validates :layout, presence: true
  validates :slug, uniqueness: true

  scope :visible, -> { where(visible: true) }
  scope :header_links, -> { where(show_in_header: true).visible }
  scope :footer_links, -> { where(show_in_footer: true).visible }
  scope :sidebar_links, -> { where(show_in_sidebar: true).visible }

  # Base category scope
  scope :page, -> { where(category: ['page', '', nil]) }

  scope :by_store, ->(store) { joins(:stores).where('spree_pages_stores.store_id = ?', store) }

  before_save :update_positions_and_slug

  def initialize(*args)
    super(*args)
    last_page = Spree::Page.last
    self.position = last_page ? last_page.position + 1 : 0
  end

  def link
    slug
  end

  def blocks(type = nil)
    return body.to_a if type.nil?

    body.to_a.select { |block| block_type? block, type }
  end

  private

  def block_type(block)
    block.class.name.split('::').last
  end

  def block_type?(block, type)
    block_type(block) == type
  end

  def update_positions_and_slug
    # Ensure that all slugs start with a slash.
    slug.prepend('/') unless slug.start_with?('/')
    return if new_record?
    return unless (prev_position = Spree::Page.find(id).position)
    if prev_position > position
      Spree::Page.where('? <= position and position < ?', position, prev_position).update_all('position = position + 1')
    elsif prev_position < position
      Spree::Page.where('? < position and position <= ?', prev_position, position).update_all('position = position - 1')
    end
  end
end
