require "openssl"
require "fileutils"
require 'securerandom'

class LTIDatabase < ApplicationRecord
  self.table_name = "lti_databases"

  include ::SelectableAttr::Base
  
  has_many :lti_database_sites, class_name: 'LTIDatabaseSite', dependent: :destroy, autosave: true
  has_many :sites, :through => :lti_database_sites
  
  validates :site_ids, presence: true
  validates :name, presence: true
  validates :iss, presence: true
  validates :client_id, presence: true
  validates :auth_login_url, presence: true
  validates :auth_token_url, presence: true
  validates :key_set_url, presence: true
  validates :private_key_file, presence: true
  validates :kid, presence: true
  
  def initialize(attr)
    super(attr)
    @session = Thread.current[:request].session
    @session["iss"] = ::LTIDatabase.to_config
  end
  
  def deployment
    result = nil
    begin
      result = JSON.parse(self.deployment_json)
    rescue
    end
    result
  end
  
  def self.to_config
    datas = self.all
    result = {}
    datas.each do |data|
      result["#{data.iss}_#{data.client_id}"] = {
        "client_id" => data.client_id,
        "auth_login_url" => data.auth_login_url,
        "auth_token_url" => data.auth_token_url,
        "key_set_url" => data.key_set_url,
        "kid" => data.kid,
        "deployment" => data.deployment
      }
    end
    result
  end
  
  def find_registration_by_issuer(iss)
    iss_sessionkey = iss.split("_")[0]
    
    if @session["iss"].blank? || @session["iss"][iss_sessionkey].blank?
      return nil
    end

    iss_sessionkey = iss.split("_")[0]
    
    result = ::LTI::LTIRegistration.new
      
    result.set_auth_login_url(@session["iss"][iss_sessionkey]["auth_login_url"])
      .set_auth_token_url(@session["iss"][iss_sessionkey]["auth_token_url"])
      .set_auth_server(@session["iss"][iss_sessionkey]["auth_server"])
      .set_client_id(@session["iss"][iss_sessionkey]["client_id"])
      .set_key_set_url(@session["iss"][iss_sessionkey]["key_set_url"])
      .set_kid(@session["iss"][iss_sessionkey]["kid"])
      .set_issuer(iss)
      .set_tool_private_key(private_key(iss))
      
    result
  end
    
  def find_registration_by_issuer_and_client_id(iss, client_id)
    iss_sessionkey = "#{iss}_#{client_id}"

    if @session["iss"].blank? || @session["iss"][iss_sessionkey].blank?
      return nil
    end

    result = ::LTI::LTIRegistration.new
      
    result.set_auth_login_url(@session["iss"][iss_sessionkey]["auth_login_url"])
      .set_auth_token_url(@session["iss"][iss_sessionkey]["auth_token_url"])
      .set_auth_server(@session["iss"][iss_sessionkey]["auth_server"])
      .set_client_id(@session["iss"][iss_sessionkey]["client_id"])
      .set_key_set_url(@session["iss"][iss_sessionkey]["key_set_url"])
      .set_kid(@session["iss"][iss_sessionkey]["kid"])
      .set_issuer(iss)
      .set_tool_private_key(private_key(iss))
      
    result
  end
      
  def find_deployment(iss, deployment_id)
    unless @session["iss"][iss]["deployment"].include?(deployment_id)
      return nil
    end
    
    deployment = ::LTI::LTIDeployment.new
    
    deployment.set_deployment_id(deployment_id)
    
    deployment
  end
    
  def find_deployment_by_iss_and_client_id(iss, client_id, deployment_id)
    iss_sessionkey = "#{iss}_#{client_id}"

    deployment_ids = @session["iss"][iss_sessionkey]["deployment"]
    deployment_ids = [deployment_ids.to_s] unless deployment_ids.is_a?(Array)
    unless deployment_ids.include?(deployment_id)
      return nil
    end
    
    deployment = ::LTI::LTIDeployment.new
    
    deployment.set_deployment_id(deployment_id)
    
    deployment
  end

  #noinspection RubyArgCount
  def self.create_pem
    bits = 2048

    rsa = OpenSSL::PKey::RSA.new(bits)

    plain = rsa.to_pem
    public_key = rsa.public_key.to_pem

    return plain, public_key
  end

  def self.create_kid
    random_uuid_v4
  end
      
  private
  def private_key(iss)
    lti_database = ::LTIDatabase.where(iss: iss).first
    lti_database.private_key_file
  end

  def self.random_uuid_v4
    a = SecureRandom.hex(4) # 8
    b = SecureRandom.hex(2) # 4

    c_rest = SecureRandom.hex(2)[0, 3]
    c = "4#{c_rest}"

    variant_head = %w[0 1 2 3 4 5 6 7 8 9 a b c d e f].sample
    d_rest = SecureRandom.hex(2)[0, 3]
    d = "#{variant_head}#{d_rest}"

    e = SecureRandom.hex(6) # 12

    [a, b, c, d, e].join('-')
  end
end
