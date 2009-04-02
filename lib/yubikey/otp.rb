class Yubikey::OTP
  # first few modhex encoded characters of the OTP
  attr_reader :public_id
  # decrypted binary token
  attr_reader :token
  # binary AES key
  attr_reader :aes_key
  # hex id (encrypted in OTP)
  attr_reader :secret_id
  # integer that increments each time the Yubikey is plugged in
  attr_reader :insert_counter
  # ~8hz timer, reset on every insert
  attr_reader :timestamp
  # activation counter, reset on every insert
  attr_reader :session_counter
  # random integer used as padding and extra random noise
  attr_reader :random_number
  
  
  # Decode/decrypt a Yubikey one-time password
  #
  # [+otp+] ModHex encoded Yubikey OTP (at least 32 characters)
  # [+key+] 32-character hex AES key
  def initialize(otp, key)    
    raise InvalidOTPError, 'OTP must be  at least 32 characters of modhex' unless otp.modhex? && otp.length >= 32
    raise InvalidKeyError, 'Key must be 32 hex characters' unless key.hex? && key.length == 32
    
    @public_id = otp[0,otp.length-32] if otp.length > 32
    
    @token = Yubikey::ModHex.decode(otp[-32,32])
    @aes_key = key.to_bin
    
    decrypt
    parse
  end
  
  private
  
  def decrypt
    @token = Yubikey::AES.decrypt(@token, @aes_key)
  end
  
  def parse
    raise BadCRCError unless Yubikey::CRC.valid?(@token)
    
    @secret_id = @token[0,6].to_hex
    @insert_counter = @token[7] * 256 + @token[6]
    @timestamp = @token[10] * 65536 + @token[9] * 256 + @token[8]
    @session_counter = @token[11]
    @random_number = @token[13] * 256 + @token[12]
  end
  
  # :stopdoc:
  class InvalidOTPError < StandardError; end
  class InvalidKeyError < StandardError; end
  class BadCRCError < StandardError; end
end # Yubikey::OTP