# frozen_string_literal: true
require 'spec_helper'
require 'draftjs_exporter/html'
require 'draftjs_exporter/entities/link'
require 'pry'

RSpec.describe DraftjsExporter::HTML do
  subject(:mapper) do
    described_class.new(
      entity_decorators: {
        'LINK' => DraftjsExporter::Entities::Link.new(className: 'foobar-baz')
      },
      block_map: {
        'header-one' => { element: 'h1', className: 'graf graf--h2'},
        'header-two' => { element: 'h2', className: 'graf graf--h3'},
        'header-tree' => { element: 'h3', className: 'graf graf--h4'},
        'blockquote' => { element: 'blockquote', className: 'graf graf--blockquote'},
        'code-block' => { element: 'pre', className: 'graf graf--code'},
        'unordered-list-item' => {
          element: 'li', className: 'graf graf--insertunorderedlist',
          wrapper: ['ul', { className: 'public-DraftStyleDefault-ul' }]
        },
        'ordered-list-item' => {
          element: 'li', className: 'graf graf--insertorderedlist',
          wrapper: ['ul', { className: 'public-DraftStyleDefault-ul' }]
        },
        'unstyled' => { element: 'div', className: 'graf graf--p' },
        'file' => { 
            render: lambda do |document, block|
              image_url = block.fetch(:data, {}).fetch(:url, "")
              image_direction = block.fetch(:data, {}).fetch(:url, "")
              caption = block[:text]
            
              html = %{ 
                <a
                  href="#{image_url}"
                  rel="noopener noreferrer"
                  target="blank"
                  className="flex items-center border rounded bg-gray-800 border-gray-600 p-4 py-2"
                >
                  #{block[:text]}
                </a>
              }

              block[:text] = ""
              figure = document.create_element("div")
              figure.add_child(html)
              figure
            end
        },
        'image' => { 
          render: lambda do |document, block|
            image_url = block.fetch(:data, {}).fetch(:url, "")
            image_width = block.fetch(:data, {}).fetch(:width, "")
            image_height = block.fetch(:data, {}).fetch(:height, "")
            image_ratio = block.fetch(:data, {}).fetch(:ratio, "100")
            image_direction = block.fetch(:data, {}).fetch(:direction, "")
            caption = block[:text]

            default_style = "max-width=#{image_width}px;max-height=#{image_height}px"
          
            html = %{ 
              <div>
                <div className="aspectRatioPlaceholder is-locked" style="#{default_style}">
                  <div
                    className="aspect-ratio-fill"
                    style="padding-bottom: '#{image_ratio}%'"
                  ></div>
                  <img url="#{image_url}" width="#{image_width}" height="#{image_height}" />
                </div>
              </div>
        
              <figcaption className="imageCaption">
                <span>
                  <span data-text="true">#{caption}</span>
                </span>
              </figcaption>
            }

            block[:text] = ""
            figure = document.create_element("figure")
            figure[:class] = "graf graf--figure"
            figure.add_child(html)
            figure
          end
        }
      },
      style_map: {
        'ITALIC' => { fontStyle: 'italic' }
      }
    )
  end

  describe '#call' do
    context 'with different blocks' do
      it 'decodes the content_state to html' do
        input = {
          entityMap: {},
          blocks: [
            {
              key: '5s7g9',
              text: 'Header',
              type: 'header-one',
              depth: 0,
              inlineStyleRanges: [],
              entityRanges: []
            },
            {
              key: 'dem5p',
              text: 'some paragraph text',
              type: 'unstyled',
              depth: 0,
              inlineStyleRanges: [],
              entityRanges: []
            }
          ]
        }

        expected_output = <<-OUTPUT.strip
        <h1 class=\"graf graf--h2\">Header</h1><div class=\"graf graf--p\">some paragraph text</div>
        OUTPUT
        expect(mapper.call(input)).to eq(expected_output)
      end
    end
  end

  describe '#call' do
    context 'block quote' do
      it 'decodes the content_state to html' do
        input = {
          entityMap: {},
          blocks: [
            {
              key: '5s7g9',
              text: 'quote quote',
              type: 'blockquote',
              depth: 0,
              inlineStyleRanges: [],
              entityRanges: []
            }
          ]
        }

        expected_output = <<-OUTPUT.strip
        <blockquote class=\"graf graf--blockquote\">quote quote</blockquote>
        OUTPUT
        expect(mapper.call(input)).to eq(expected_output)
      end
    end
  end

  describe '#call' do
    context 'code block' do
      it 'decodes the content_state to html' do
        input = {
          entityMap: {},
          blocks: [
            {
              key: '5s7g9',
              text: 'code code',
              type: 'code-block',
              depth: 0,
              inlineStyleRanges: [],
              entityRanges: []
            }
          ]
        }

        expected_output = <<-OUTPUT.strip
        <pre class=\"graf graf--code\">code code</pre>
        OUTPUT
        expect(mapper.call(input)).to eq(expected_output)
      end
    end
  end

  describe '#call' do
    context 'file block' do
      it 'decodes the content_state to html' do
        input = {
          entityMap: {},
          blocks: [
            {
              "key":"f1qmb",
              "text":"alo alo",
              "type":"file",
              "depth":0,
              "inlineStyleRanges":[],
              "entityRanges":[],
              "data":{
                "aspect_ratio":{
                  "width":0,
                  "height":0,
                  "ratio":100
                },
                "width":0,
                "caption":"type a caption (optional)",
                "height":0,
                "forceUpload":false,
                "url":"/rails/active_storage/b.js",
                "loading_progress":0,
                "selected":false,
                "loading":true,
                "file":{},
                "direction":"center"
              }
            }
          ]
        }

        expected_output = <<-OUTPUT.strip
              <div> 
                <a href="/rails/active_storage/b.js" rel="noopener noreferrer" target="blank" classname="flex items-center border rounded bg-gray-800 border-gray-600 p-4 py-2">
                  alo alo
                </a>
              </div>
        OUTPUT
        expect(mapper.call(input)).to eq(expected_output)
      end
    end
  end


  describe '#call' do
    context 'image block' do
      it 'decodes the content_state to html' do
        input = {
          "blocks":[
            {
            "key":"f1qmb", 
            "text":"oijoij", 
            "type":"image", 
            "depth":0, 
            "inlineStyleRanges":[], 
            "entityRanges":[], 
            "data":{
              "aspect_ratio":{
                "width":1000, 
                "height":435.546875, 
                "ratio":43.5546875
              }, 
              "width":1024, 
              "caption":"type a caption (optional)", 
              "height":446, 
              "forceUpload":false, 
              "url":"/ra/bg-q.png", 
              "loading_progress":0, 
              "selected":false,
              "loading":true, 
              "file":{}, 
              "direction":"center"
              }
            }
          ], 
          "entityMap":{}
        }

        expected_output = <<-OUTPUT.strip
       <figure class="graf graf--figure"> 
              <div>
                <div classname="aspectRatioPlaceholder is-locked" style="max-width=1024px;max-height=446px">
                  <div classname="aspect-ratio-fill" style="padding-bottom: '100%'"></div>
                  <img url="/ra/bg-q.png" width="1024" height="446">
                </div>
              </div>
        
              <figcaption classname="imageCaption">
                <span>
                  <span data-text="true">oijoij</span>
                </span>
              </figcaption>
            </figure>
        OUTPUT
        expect(mapper.call(input)).to eq(expected_output)
      end
    end
  end

end
