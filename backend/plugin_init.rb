# Work around small difference in rubyzip API
module Zip
  if !defined?(Error)
    class Error < StandardError
    end
  end
end
