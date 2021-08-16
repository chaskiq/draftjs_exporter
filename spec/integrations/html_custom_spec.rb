# frozen_string_literal: true
require 'spec_helper'
require 'draftjs_exporter/html'
require 'draftjs_exporter/entities/link'

image_proc = lambda do |document, block|
  image_url = block.fetch(:data, {}).fetch(:url, "")
  image_width = block.fetch(:data, {}).fetch(:width, "")
  image_height = block.fetch(:data, {}).fetch(:height, "")
  image_ratio = block.fetch(:data, {}).fetch(:ratio, "100")
  image_direction = block.fetch(:data, {}).fetch(:direction, "")
  caption = block[:text]

  default_style = "max-width=#{image_width}px;max-height=#{image_height}px"

  html = %{ 
    <div>
      <div class="aspectRatioPlaceholder is-locked" style="#{default_style}">
        <div
          class="aspect-ratio-fill"
          style="padding-bottom: '#{image_ratio}%'"
        ></div>
        <img url="#{image_url}" width="#{image_width}" height="#{image_height}" />
      </div>
    </div>

    <figcaption class="imageCaption">
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

video_proc = lambda do |document, block|
  images = block.fetch(:data, {}).fetch(:images, "")
  title = block.fetch(:data, {}).fetch(:title, "")
  html = block.dig(:data, :embed_data, :html)

  description = block.fetch(:data, {}).fetch(:description, "")
  provider_url = block.fetch(:data, {}).fetch(:provider_url, "")
  provisory_text = block.fetch(:data, {}).fetch(:provisory_text, "")

  fig = %{
    <figcaption class="imageCaption">
      <div class="public-DraftStyleDefault-block public-DraftStyleDefault-ltr">
        <span>
          <span>#{provisory_text}</span>
        </span>
      </div>
    </figcaption>
  }

  html = %{ 
    <figure
      class="graf--figure graf--iframe graf--first"
      tabIndex="0"
    >
      <div class="iframeContainer">
        #{html}
      </div>
      #{fig}
    </figure>
  }

  block[:text] = ""
  figure = document.create_element("div")
  figure[:class] = "graf graf--mixtapeEmbed"
  figure.add_child(html)
  figure

end

embed_proc = lambda do |document, block|
  images = block.fetch(:data, {}).fetch(:images, "")
  title = block.fetch(:data, {}).fetch(:title, "")
  description = block.fetch(:data, {}).fetch(:description, "")
  provider_url = block.fetch(:data, {}).fetch(:provider_url, "")
  provisory_text = block.fetch(:data, {}).fetch(:provisory_text, "")

  image_element = images[0] && images[0][:url] ? %{
    <a target="_blank"
      rel="noopener noreferrer"
      class="js-mixtapeImage mixtapeImage"
      href="#{provisory_text}"
      style="background-image: url(#{images[0][:url]})">
    </a> 
  } : ""

  html = %{ 
    <span>
      #{image_element}
      <a
        class="markup--anchor markup--mixtapeEmbed-anchor"
        target="_blank"
        rel="noopener noreferrer"
        href="#{provisory_text}"
      >
        <strong class="markup--strong markup--mixtapeEmbed-strong">
          #{title}
        </strong>
        <em class="markup--em markup--mixtapeEmbed-em">
          #{description}
        </em>
      </a>
      #{provider_url}
    </span>
  }

  block[:text] = ""
  figure = document.create_element("div")
  figure[:class] = "graf graf--mixtapeEmbed"
  figure.add_child(html)
  figure
end

recorded_video_proc = lambda do |document, block|
  url = block.fetch(:data, {}).fetch(:url, "")
  text = block.fetch(:data, {}).fetch(:text, "")

  html = %{
    <div className="iframeContainer">
      <video
        autoPlay="false"
        style="width:'100%'"
        controls="true"
        src="#{url}"
      ></video>
    </div>
    <figcaption className="imageCaption">
      <div className="public-DraftStyleDefault-block public-DraftStyleDefault-ltr">
        <span>#{text}</span>
      </div>
    </figcaption>
  }

  block[:text] = ""
  figure = document.create_element("div")
  figure[:class] = "graf--figure graf--iframe graf--first"
  figure.add_child(html)
  figure
end

file_proc = lambda do |document, block|
  image_url = block.fetch(:data, {}).fetch(:url, "")
  image_direction = block.fetch(:data, {}).fetch(:url, "")
  caption = block[:text]

  html = %{ 
    <a
      href="#{image_url}"
      rel="noopener noreferrer"
      target="blank"
      class="flex items-center border rounded bg-gray-800 border-gray-600 p-4 py-2"
    >
      #{block[:text]}
    </a>
  }

  block[:text] = ""
  figure = document.create_element("div")
  figure.add_child(html)
  figure
end

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
        'file' => { render: file_proc },
        'image' => { render: image_proc },
        'giphy' => { render: image_proc },
        'embed'=> { render: embed_proc },
        'video'=> { render: video_proc },
        'recorded-video'=> {
          render: recorded_video_proc
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
    <a href="/rails/active_storage/b.js" rel="noopener noreferrer" target="blank" class="flex items-center border rounded bg-gray-800 border-gray-600 p-4 py-2">
      alo alo
    </a>
  </div>
        OUTPUT
        expect(mapper.call(input)).to eq(expected_output)
      end
    end

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
      <div class="aspectRatioPlaceholder is-locked" style="max-width=1024px;max-height=446px">
        <div class="aspect-ratio-fill" style="padding-bottom: '100%'"></div>
        <img url="/ra/bg-q.png" width="1024" height="446">
      </div>
    </div>

    <figcaption class="imageCaption">
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

  context 'video embed block' do
    it 'decodes' do
    input = {
      "blocks": [
          {
              "key": "f1qmb",
              "text": "https://www.youtube.com/watch?v=K8ohjkm-rsw",
              "type": "video",
              "depth": 0,
              "inlineStyleRanges": [],
              "entityRanges": [],
              "data": {
                  "provisory_text": "https://www.youtube.com/watch?v=K8ohjkm-rsw",
                  "endpoint": "/oembed?url=",
                  "type": "video",
                  "embed_data": {
                      "url": "https://www.youtube.com/watch?v=K8ohjkm-rsw",
                      "title": "Scottie Pippen's Emotional Speech After UCA Names Basketball Court After Him",
                      "description": nil,
                      "html": "<iframe width=\"200\" height=\"113\" src=\"https://www.youtube.com/embed/K8ohjkm-rsw?feature=oembed\" frameborder=\"0\" allow=\"accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture\" allowfullscreen></iframe>",
                      "provider_url": "https://www.youtube.com",
                      "images": [
                          {
                              "url": nil
                          }
                      ],
                      "media": {
                          "html": "<iframe width=\"200\" height=\"113\" src=\"https://www.youtube.com/embed/K8ohjkm-rsw?feature=oembed\" frameborder=\"0\" allow=\"accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture\" allowfullscreen></iframe>"
                      }
                  }
              }
          }
      ],
      "entityMap": {}
    }


    expected_output = <<-OUTPUT.strip
    <div class="graf graf--mixtapeEmbed"> 
    <figure class="graf--figure graf--iframe graf--first" tabindex="0">
      <div class="iframeContainer">
        <iframe width="200" height="113" src="https://www.youtube.com/embed/K8ohjkm-rsw?feature=oembed" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
      </div>
      
    <figcaption class="imageCaption">
      <div class="public-DraftStyleDefault-block public-DraftStyleDefault-ltr">
        <span>
          <span>https://www.youtube.com/watch?v=K8ohjkm-rsw</span>
        </span>
      </div>
    </figcaption>
  
    </figure>
  </div>
    OUTPUT
    expect(mapper.call(input)).to eq(expected_output)
    end
  end


  context 'embed' do

    it "decodes" do
      input = {"blocks":[{"key":"f1qmb","text":"http://chaskiq.io","type":"embed","depth":0,"inlineStyleRanges":[],"entityRanges":[],"data":{"provisory_text":"http://chaskiq.io","endpoint":"/oembed?url=","type":"embed","embed_data":{"url":"http://chaskiq.io","title":"The front line of your customer experience.","description":"Messaging Platform for Marketing, Support & Sales","html":nil,"provider_url":"http://chaskiq.io","images":[{"url":nil}],"media":{"html":nil}},"error":""}}],"entityMap":{}}
      
        expected_output = <<-OUTPUT.strip
    <div class="graf graf--mixtapeEmbed"> 
    <span>
      
      <a class="markup--anchor markup--mixtapeEmbed-anchor" target="_blank" rel="noopener noreferrer" href="http://chaskiq.io">
        <strong class="markup--strong markup--mixtapeEmbed-strong">
          
        </strong>
        <em class="markup--em markup--mixtapeEmbed-em">
          
        </em>
      </a>
      
    </span>
  </div>
        OUTPUT
        expect(mapper.call(input)).to eq(expected_output)
    end

  end

  context 'video recorded' do
    it "decodes" do
      input = {"blocks":[{"key":"f1qmb","text":"okokok","type":"recorded-video","depth":0,"inlineStyleRanges":[],"entityRanges":[],"data":{"rejectedReason":"","secondsLeft":0,"fileReady":true,"paused":false,"url":"/rails/active_storage/recorded","recording":false,"granted":true,"loading":false,"direction":"center"}}],"entityMap":{}}
      expected_output = <<-OUTPUT.strip
  <div class="graf--figure graf--iframe graf--first">
    <div classname="iframeContainer">
      <video autoplay="false" style="width:'100%'" controls="true" src="/rails/active_storage/recorded"></video>
    </div>
    <figcaption classname="imageCaption">
      <div classname="public-DraftStyleDefault-block public-DraftStyleDefault-ltr">
        <span></span>
      </div>
    </figcaption>
  </div>
      OUTPUT
      expect(mapper.call(input)).to eq(expected_output)
    end
  end

end
