class MiqHashStruct
  undef_method(:id) if method_defined?(:id)
  undef_method(:format) if private_method_defined?(:format)

  def initialize(hash = {})
    raise ArgumentError, "hash expected to be a Hash" unless hash.respond_to?(:to_hash)
    @hash = hash.to_hash

    # Get the key type by assuming from the first key's type
    #   Do not worry about mixed keys since it is uncommon
    key = hash.keys[0]
    @key_type = key.nil? ? Symbol : key.class
    raise ArgumentError, "hash keys must be either Symbol or String" unless [Symbol, String].include?(@key_type)
  end

  def _hash
    @hash
  end
  alias_method :to_hash, :_hash
  alias_method :to_h, :_hash

  def _key_type
    @key_type
  end

  def _key_type=(value)
    raise ArgumentError, "key type must be Symbol or String" unless [Symbol, String].include?(value)

    unless @key_type == value
      m = (value == String) ? :to_s : :to_sym
      @hash.keys.each do |k|
        next if k.class == value
        @hash[k.send(m)] = @hash.delete(k)
      end
      @key_type = value
    end
  end

  def ==(other)
    self.class == other.class && to_h == other.to_h
  end

  def method_missing(m, *args)
    m2 = m.to_s
    if m2[-1, 1] == "="
      m2.chop!
      m2 = m2.to_sym if @key_type == Symbol
      @hash[m2] = args.first
    else
      m = m2 if @key_type == String
      @hash[m]
    end
  end

  private

  def respond_to_missing?(sym, *)
    # Methods for Marshal and YAML dumping and loading shouldn't #respond_to_missing?
    return false if sym.in?([:encode_with, :init_with, :yaml_initialize, :marshal_dump, :_dump])

    # Setters are always true
    return true if sym.to_s.end_with? '='

    # Getters only when the attribute is defined
    return true if @hash.key?(sym)

    false
  end
end
