(function($) {
  $(document).on("click", ".js-proxy-login, .js-stop-proxy-login", function(e) {
    e.preventDefault();
    const message = $(this).data("confirm-message");
    if (message && !window.confirm(message)) {
      return;
    }
    $(this).closest("form").submit();
  });
})(window.jQuery);
