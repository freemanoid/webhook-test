class SpellChecksController < ApplicationController
  def show
    @pull_request = PullRequest.find(params[:pull_request_id])

    require 'open-uri'

    uri = URI.parse(@pull_request.diff_url)
    diff = uri.read
    parser = GitDiffParser.parse(diff)
    changed_lines = parser.flat_map(&:changed_lines).map(&:content)

    words = changed_lines.flat_map { |l| l.chomp[1..-1].split(" ") } #remove \n, +-

    words = "I he ast peole wold us ths tol".split(" ")

    @suggestions = {}

    FFI::Hunspell.dict('en_US') do |dict|
      words.each_with_object(@suggestions) do |w, obj|
        if !dict.check?(w)
          @suggestions[w] = dict.suggest(w)
        end
      end
    end

    config = FFI::Aspell.config_new
    FFI::Aspell.config_replace(config, 'lang', 'en')
    speller = FFI::Aspell.speller_new(config)

    @suggestions_aspell = {}

    words.each_with_object(@suggestions_aspell) do |w, obj|
      if !FFI::Aspell.speller_check(speller, w, w.length)
        list = FFI::Aspell.speller_suggest(speller, w, w.length)
        elements = FFI::Aspell.word_list_elements(list)
        sug_words = []

        while next_suggestion = FFI::Aspell.string_enumeration_next(elements)
          sug_words << next_suggestion
        end

        FFI::Aspell.string_enumeration_delete(elements)

        @suggestions_aspell[w] = sug_words
      end
    end

    FFI::Aspell.speller_delete(speller)
  end
end

