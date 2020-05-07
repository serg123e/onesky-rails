require 'spec_helper'

describe Onesky::Rails::Client do
  let(:config_hash) { create_config_hash }

  describe '#new' do

    it 'with correct config' do
      stub_request(:get, full_path_with_auth_hash("/projects/#{config_hash['project_id']}/languages", config_hash['api_key'], config_hash['api_secret']))
        .to_return(status: 200, body: languages_response.to_json)

      client = Onesky::Rails::Client.new(config_hash)
      expect(client.base_locale).to eq(I18n.default_locale)
    end

    it 'with invalid config' do
      expect{Onesky::Rails::Client.new({})}.to raise_error(ArgumentError)
    end
  end

  describe '#verify_languages!' do
    let(:client) {Onesky::Rails::Client.new(config_hash)}

    context 'success' do
      before(:each) do
        stub_project_language_request(languages_response)
      end

      it 'to retrieve languages activated at OneSky' do
        expect{client.verify_languages!}.to_not raise_error
        expect(client.onesky_locales).to eq(['ja'])
      end

      context 'with explicit base locale and different default locale' do
        let(:config_hash) { create_config_hash.merge({'base_locale' => 'en'}) }

        it 'to retrieve languages activated at OneSky' do
          I18n.default_locale = :ja

          expect{client.verify_languages!}.to_not raise_error
          expect(client.onesky_locales).to eq(['ja'])
        end
      end
    end

    context 'success with custom locale' do
      before(:each) do
        stub_project_language_request(custom_locale_response)
      end

      it 'to use custom locale' do
        expect{client.verify_languages!}.to_not raise_error
        expect(client.onesky_locales).to eq(['es'])
      end
    end

    context 'fail' do
      it 'with incorrect credentials' do
        stub_request(:get, full_path_with_auth_hash("/projects/#{config_hash['project_id']}/languages", config_hash['api_key'], config_hash['api_secret']))
          .to_return(status: 401, body: {meta: {code: 401, message: 'Fail to authorize'}}.to_json)

        expect{client.verify_languages!}.to raise_error(Onesky::Errors::UnauthorizedError, '401 Unauthorized - Fail to authorize')
      end

      it 'with mis-match base locale' do
        I18n.default_locale = :ja

        stub_request(:get, full_path_with_auth_hash("/projects/#{config_hash['project_id']}/languages", config_hash['api_key'], config_hash['api_secret']))
          .to_return(status: 200, body: languages_response.to_json)

        expect{client.verify_languages!}.to raise_error(Onesky::Rails::BaseLanguageNotMatchError, 'The default locale (ja) of your Rails app doesn\'t match the base language (en) of the OneSky project')
      end
    end
    context 'working with mapped locales' do
      before(:all) do
        config = create_config_hash
        config['locale_mapping'] = { 'es' => 'es-ES',
                                     'ar' => 'es-AR',
                                     'uk' => 'en-GB' }

        @client = Onesky::Rails::Client.new(config)
      end
      it 'converts to rails' do
        expect( @client.to_rails_locale('es-ES')).to eq 'es'
      end
      it 'converts to onesky' do
        expect( @client.to_onesky_locale('es')).to eq 'es-ES'
      end
      it 'keep working as before with not-mapped locales' do
        expect( @client.to_onesky_locale('ru_RU')).to eq 'ru-RU'
        expect( @client.to_rails_locale('ru-RU')).to eq 'ru_RU'
      end
    end
  end

end
