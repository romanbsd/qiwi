module Qiwi
  module Response
    STATUS = {
      50 => :issued,
      52 => :being_processed,
      60 => :paid,
      150 => :cancelled_by_terminal,
      151 => :cancelled_no_auth,
      160 => :cancelled,
      161 => :cancelled_expired
    }
    STATUS.default_proc = lambda do |hash, status|
      if status >= 51 and status <= 59
        hash[52]
      elsif status < 50
        hash[50]
      elsif status > 100
        hash[160]
      else
        :unknown
      end
    end
  end
end
