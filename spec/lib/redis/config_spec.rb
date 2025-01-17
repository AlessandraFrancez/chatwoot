require 'rails_helper'

describe ::Redis::Config do
  context 'when single redis instance is used' do
    let(:redis_url) { 'redis://my-redis-instance:6379' }
    let(:redis_pasword) { 'some-strong-password' }

    before do
      allow(ENV).to receive(:fetch).with('REDIS_URL', 'redis://127.0.0.1:6379').and_return(redis_url)
      allow(ENV).to receive(:fetch).with('REDIS_PASSWORD', nil).and_return(redis_pasword)
      allow(ENV).to receive(:fetch).with('REDIS_SENTINELS', nil).and_return('')
      allow(ENV).to receive(:fetch).with('REDIS_SENTINEL_MASTER_NAME', 'mymaster').and_return('')
      described_class.reload_config
    end

    it 'checks for app redis config' do
      app_config = described_class.app
      expect(app_config.keys).to match_array([:url, :password])
      expect(app_config[:url]).to eq(redis_url)
      expect(app_config[:password]).to eq(redis_pasword)
    end

    it 'checks for sidekiq redis config' do
      sidekiq_config = described_class.sidekiq
      expect(sidekiq_config.keys).to match_array([:url, :password, :size])
      expect(sidekiq_config[:url]).to eq redis_url
      expect(sidekiq_config[:password]).to eq redis_pasword
      expect(sidekiq_config[:size]).to eq described_class::SIDEKIQ_SIZE
    end
  end

  context 'when redis sentinel is used' do
    let(:redis_url) { 'redis://my-redis-instance:6379' }
    let(:redis_sentinels) { 'sentinel_1:1234, sentinel_2:4321, sentinel_3' }
    let(:redis_master_name) { 'master-name' }
    let(:redis_pasword) { 'some-strong-password' }

    let(:expected_sentinels) do
      [
        { host: 'sentinel_1', port: '1234', password: 'some-strong-password' },
        { host: 'sentinel_2', port: '4321', password: 'some-strong-password' },
        { host: 'sentinel_3', port: '26379', password: 'some-strong-password' }
      ]
    end

    before do
      allow(ENV).to receive(:fetch).with('REDIS_URL', 'redis://127.0.0.1:6379').and_return(redis_url)
      allow(ENV).to receive(:fetch).with('REDIS_PASSWORD', nil).and_return(redis_pasword)
      allow(ENV).to receive(:fetch).with('REDIS_SENTINELS', nil).and_return(redis_sentinels)
      allow(ENV).to receive(:fetch).with('REDIS_SENTINEL_MASTER_NAME', 'mymaster').and_return(redis_master_name)
      described_class.reload_config
    end

    it 'checks for app redis config' do
      expect(described_class.app.keys).to match_array([:url, :password, :sentinels])
      expect(described_class.app[:url]).to eq("redis://#{redis_master_name}")
      expect(described_class.app[:sentinels]).to match_array(expected_sentinels)
    end

    it 'checks for sidekiq redis config' do
      expect(described_class.sidekiq.keys).to match_array([:url, :password, :sentinels, :size])
      expect(described_class.sidekiq[:size]).to eq described_class::SIDEKIQ_SIZE
    end
  end
end
