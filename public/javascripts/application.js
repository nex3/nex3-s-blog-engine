Element.addMethods({
    spin: function(element) {
        var img = document.createElement('img');
        if (arguments[1])
            img.src = "/images/spinner" + arguments[1] + ".gif";
        else
            img.src = "/images/spinner.gif";
        img.alt = "Please Wait";
        Element.addClassName(img, "spinner");

        $A(element.childNodes).each(Element.remove);
        
        element.appendChild(img);
        element.show();
    }
});

function search(input) {
    $("search_results").spin(1);
    new Ajax.Request("/posts.js", {
        method: "get",
        parameters: { query: input.getValue() }
    });
}

function setSearchListener() {
    var input = $$(".search form input[type=text]")[0];
    new Form.Element.Observer(input, 1, search);
}

var isAction;

Event.observe(window, 'load', function() {
    var body = document.getElementsByTagName('body')[0];
    isAction = function(controller, action) {
        return body.hasClassName(controller) && body.hasClassName(action);
    };

    setSearchListener();

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
