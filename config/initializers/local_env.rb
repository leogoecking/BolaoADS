unless Rails.env.production?
  env_path = Rails.root.join(".env")

  if env_path.file?
    env_path.each_line do |line|
      line = line.strip
      next if line.blank? || line.start_with?("#") || !line.include?("=")

      key, value = line.split("=", 2)
      key = key.strip
      value = value.strip
      value = value[1...-1] if value.length >= 2 && value.start_with?('"') && value.end_with?('"')

      ENV[key] = value unless ENV.key?(key)
    end
  end
end
