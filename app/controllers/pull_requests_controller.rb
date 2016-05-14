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
  end
end

