$(function () {
    // These parameters are only checked on first load of page, allowing for links/selectors on other pages
    var data, country_val, partnerships_val;

    var g_country = $_GET('country'),
       g_partners = $_GET('partners'),
       g_sponsors = $_GET('sponsors'),
        site_root = '/OIA_Dashboard/www';
    var path = site_root + '/engagement-map/partenership.json';
    

    $.getJSON(path, function (data) {
        console.log(path);
        console.log(data);
    	getLocations(data);

    	$('#country').change(function (e) {
    		getLocations(data);
    		cleanURL();
		});
        $('#partners').change(function (e) {
    		getLocations(data);
    		cleanURL();
		});
		$('#sponsors').change(function (e) {
    		getLocations(data);
    		cleanURL();
		});
    	$('#reset').click(function (e) {
    		resetFilters();
			e.preventDefault();
    		getLocations(data);
    		cleanURL();
		});

    	if (g_country != undefined && g_partners != undefined || g_sponsors != undefined ) {
	        $('#country').val(decode(g_country.replace(new RegExp('_', 'g'), ' ')));
	        $('#partners').val(decode(g_partners.replace(new RegExp('_', 'g'), ' ')));
	        $('#sponsors').val(decode(g_sponsors.replace(new RegExp('_', 'g'), ' ')));
	        getLocations(data);
	    }
    });
});

function getLocations(data) {
    
    var target = '#intl-partners';
	
	$('#intl_partners tbody').fadeOut(400, function() {
		// but empty both tabs lest anchors be duplicated
		$('#intl_partners tbody').empty();

		var results = 0,
             letter = '',
              total = 0;

		$.each(data.locations, function(i, locations) {
			var display = true;
			// If country is selected, hide non-matches
			var country_val = $('#country').val(),
             partnerships_val = $('#partners').val(),
			    sponsors = $('#sponsors').val();

			if (country_val != '' && display == true) {
				display = false;
				if (country_val == locations.country) {
					display = true;
				}
			}
            if (partnerships_val != 'all' && display == true) {
        		$.each(locations.partnerships, function(m, l) {
					display = false;
					if (locations.partnerships[m].type.includes(partnerships_val)) {
    				display = true;
    				return false;
					}
					else if (partnerships_val == locations.partnerships[m].type.substring(0,23)) {
						display = true;
						return false;
					}
				});
			}
			console.log(sponsors);
			if (sponsors != '' && display == true) {
				$.each(locations.partnerships, function(k, a) {
					display = false;
					if (locations.partnerships[k].inUnit.includes(sponsors)) {
   					display = true;
    				return false;
					}
				});
			}
			// Adding data to table
			if (display == true) {
				var m = '<tr'; 
				if (results % 2 == 0){
					m += ' class="stripe"><td>'
				} else {m += '><td>'};
				console.log(typeof locations.country);      
				var countryArray = locations.country.split('\n');
				for ( var i = 0; i < locations.partnerships.length; i++ ) {
    				if ( locations.partnerships[i].url != '' ) {
    					m += locations.country +'<img src="./' + countryArray[i] +'_flag.png" alt="'+ countryArray[i] +' Flag" style=" width: 1rem; height:1rem;"></td><td>';
    					m += '<a href="' + locations.partnerships[i].url + '">' + locations.institution + '</a></td><td><ul>';
						m += '<b>Type:</b> </Br>' + locations.partnerships[i].type + '</Br> <b>Departments:</b> </Br><ul>';
						m += locations.partnerships[i].inUnit.split('\n').map(function(line) {
    					return '<li>' + line + '</li>';
						}).join('');
						m += '</ul></li>';

					}
					else {
						m += '<li><b>Type:</b> </Br>' + locations.partnerships[i].type + ' </Br> <b>Departments:</b> </Br> ' + locations.partnerships[i].inUnit.replace(/\n/g, ' - ') + '</li>';
					}
				}
				m += '</ul></td></tr>';
				$('#intl_partners tbody').append(m);
				results++;
			}
            total++;
		});
        $('#partnership-info').html('<p>Showing ' + results + ' of ' + total + ' entries</p>');
		if (results == 0) {
			$('#intl_partners tbody').append('<tr><td colspan="3">No results found.</td></tr>');
		}
		$('#intl_partners tbody').fadeIn();
	});
}
function decode(str) {
	return unescape(str.replace(/\+/g, " "));
}
function $_GET(q,s) { 
    s = s ? s : window.location.search; 
    var re = new RegExp('&'+q+'(?:=([^&]*))?(?=&|$)','i'); 
    return (s=s.replace(/^\?/,'&').match(re)) ? (typeof s[1] == 'undefined' ? '' : decodeURIComponent(s[1])) : undefined; 
}

function cleanURL() {
    var uri = window.location.toString();
	var clean_uri = uri.substring(0, uri.indexOf("?"));
	history.replaceState({}, '', clean_uri);
}

function resetFilters() {
	$('#country').val('');
    $('#partners').val('all');
    $('#sponsors').val('');
}