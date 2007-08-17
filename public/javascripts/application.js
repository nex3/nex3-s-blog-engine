Element.addMethods({
    spin: function(element) {
        var img = document.createElement('img');
        img.src = "/images/spinner.gif";
        img.alt = "Please Wait";
        Element.addClassName(img, "spinner");

        $A(element.childNodes).each(function(child) {
            Element.remove(child);
        });
        
        element.appendChild(img);
        element.show();
    }
});

var isAction;

Event.observe(window, 'load', function() {
    var body = document.getElementsByTagName('body')[0];
    isAction = function(controller, action) {
        return body.hasClassName(controller) && body.hasClassName(action);
    };

    if (isAction('users', 'edit')) {
        var checkbox = $('user_admin');
        var password_fields = $$('#password_stuff input');
        var toggleCheckbox = function() {
            (checkbox.checked ? Element.show : Element.hide)('password_stuff');

            if (checkbox.checked)
                password_fields.each(function(field) { field.value = ""; });
        };

        Event.observe(checkbox, 'click', toggleCheckbox);
        toggleCheckbox();
    }
});
