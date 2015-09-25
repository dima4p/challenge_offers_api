# Model OffersRequest defines the protocol to get the Offers
#
class OffersRequest

  include ActiveModel::Validations

  attr_accessor :uid, :pub0, :page, :pages, :qty

  validates :uid, :pub0, presence: true
  validates :pages, numericality: true
  validates :page, numericality: {less_than_or_equal_to: :pages}

  def initialize(hash)
    hash = hash.with_indifferent_access
    @uid = hash[:uid]
    @pub0 = hash[:pub0]
    @page = hash[:page].to_i
    @pages = (hash[:pages] || 1).to_i
  end

  def attributes
    {
      uid: uid,
      pub0: pub0,
      page: page,
    }
  end

  def fetch!
    result = self.class.get attributes
    Rails.logger.debug "OffersRequest@#{__LINE__}#fetch! #{result.inspect}"
    if result.is_a? Hash
      @pages = result['pages'].to_i
      @qty = result['count'].to_i
      result['offers'].map do |hash|
        Offer.new hash
      end
    else
      result
    end
  end

  class << self
    def get(params)
      params = params.dup
      params[:appid] = Rails.application.secrets[:appid]
      params[:format] = :json
      params[:device_id] = Rails.application.secrets[:device_id]
      params[:locale] = :de
      params[:ip] = Rails.application.secrets[:ip]
      params[:offer_types] = Rails.application.secrets[:offer_types]
      params[:timestamp] = Time.current.to_i
      params = process_params params
      uri = URI Rails.application.secrets[:api_url]
      uri.query = params.to_param
      res = Net::HTTP.get_response(uri)
      return I18n.t 'offers_request.bad_response', name: res.class unless res.is_a? Net::HTTPOK
      res = JSON.parse res.body
      res.slice! *%w[code count pages offers]
      res
    end

    private

    def process_params(params)
      params = Hash[params.sort]
      string = "#{params.to_param}&#{Rails.application.secrets[:api_key]}"
      params[:hashkey] = Digest::SHA1.hexdigest string
      params
    end
  end   # class << self
end