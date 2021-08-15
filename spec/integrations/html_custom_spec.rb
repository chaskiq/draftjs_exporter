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
        'unstyled' => { element: 'div', className: 'graf graf--p' }
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
end
