module LTI
  # ::Exception だと `rescue => e`（StandardError のみ）に入らず、意図した _render_500 にならない。
  class Exception < ::StandardError
  end
end