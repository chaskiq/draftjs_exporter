module DraftjsExporter
  class WrapperState
    def initialize(block_map)
      @block_map = block_map
      @document = Nokogiri::HTML::Document.new
      @fragment = Nokogiri::HTML::DocumentFragment.new(document)
      reset_wrapper
    end

    def element_for(block)
      type = block.fetch(:type, 'unstyled')

      custom_proc = block_map.fetch(type).fetch(:render, nil)
      
      if custom_proc
        e = custom_proc.call(document, block)
        return parent_for(type).add_child(e)
      end

      document.create_element(block_options(type)).tap do |e|
        element_class_name = block_map.fetch(type).fetch(:className, nil)
        e[:class] = element_class_name unless element_class_name.nil?
        parent_for(type).add_child(e)
      end
    end

    def to_s
      to_html
    end

    def to_html(options = {})
      fragment.to_html(options)
    end

    private

    attr_reader :fragment, :document, :block_map, :wrapper

    def set_wrapper(element, options = {})
      @wrapper = [element, options]
    end

    def wrapper_element
      @wrapper[0] || fragment
    end

    def wrapper_options
      @wrapper[1]
    end

    def parent_for(type)
      options = block_map.fetch(type)
      return reset_wrapper unless options.key?(:wrapper)

      new_options = nokogiri_options(*options.fetch(:wrapper))
      return wrapper_element if new_options == wrapper_options

      create_wrapper(new_options)
    end

    def reset_wrapper
      set_wrapper(fragment)
      wrapper_element
    end

    def nokogiri_options(element_name, element_attributes)
      config = element_attributes || {}
      options = {}
      options[:class] = config.fetch(:className) if config.key?(:className)
      [element_name, options]
    end

    def block_options(type)
      block_map.fetch(type).fetch(:element)
    end

    def create_wrapper(options)
      document.create_element(*options).tap do |new_element|
        reset_wrapper.add_child(new_element)
        set_wrapper(new_element, options)
      end
    end
  end
end
