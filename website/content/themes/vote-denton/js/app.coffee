
###
Author:

###


###
color data is present in the JSON feeds but each district is the same, so we assign unique values
###
colors =
  "DISTRICT 1": "#ABD9E9"
  "DISTRICT 2": "#FDAE61"
  "DISTRICT 3": "#2C7BB6"
  "DISTRICT 4": "#D7191C"

$ = jQuery

$doc = $(document)

downtown = new google.maps.LatLng(33.214851,-97.133045)
geocoder = new google.maps.Geocoder()

region_zoom = 11
detail_zoom = region_zoom + 4

districts = {}

###
the map object
###
map = null

###
marker, we only have one
###
marker = null

###
mimic ruby's reject method
###
reject = (array, predicate) ->
  res = []
  res.push(value) for value in array when not predicate value
  res


###
take a string ex. -97.127557979037221,33.156515808050976
split it into it's lat/lng component
return a google LatLng object
###
create_gmap_latlng_from_coordinate_pairs = (pair)->
  parts = pair.split(",")
  console.log 'data is malformed', pair if parts.length is not 2
  new google.maps.LatLng( parts[1], parts[0])



###

###
create_gmap_path = (data)->
  ( create_gmap_latlng_from_coordinate_pairs pair for pair in data.LinearRing.coordinates.split(" ") )

# ###
# take the raw JSON coordinates and turn it into a google maps polygon
# ###
# create_gmap_polygon = (data)->
#   # coordinates = ( create_gmap_latlng_from_coordinate_pairs pair for pair in data.LinearRing.coordinates.split(" ") )



###
a district will have one outerBoundaryIs object
a distrcit _may_ have an innerBoundaryIs array
###
make_region = (data, district)->
  paths = []

  paths.push create_gmap_path(data.outerBoundaryIs)
  interior_boundaries = (create_gmap_path inner for inner in data.innerBoundaryIs) if data.innerBoundaryIs
  paths.push interior for interior in interior_boundaries if interior_boundaries

  polygon = new google.maps.Polygon
    paths: paths
    strokeColor: colors[district]
    strokeWeight: 1
    fillColor: colors[district]
    fillOpacity: 0.4
    map: map
  google.maps.event.addListener polygon, 'click', (event)->

    data =
      latLng: event.latLng
    geocoder.geocode data, (results, status)->
      if (status == google.maps.GeocoderStatus.OK)
        console.log status, results
        if results[0].types.indexOf('street_address') > -1
          address = results[0].formatted_address
          $query.val( address )
          mark_point event.latLng, detail_zoom, address
        else
          mark_point event.latLng, detail_zoom


    # report_district district

  polygon


###
grab JSON from the server for a district
###
load_district_data = (district)->
  $.getJSON "/content/themes/vote-denton/js/" + district + ".json", (data, status)->
    ###
    district data, among other things, will contain:
    several polygons that encompass the boundaries
    ###
    district_name = data.Placemark.ExtendedData.SchemaData.SimpleData[2]['#text']
    regions = (make_region district_data, district_name for district_data in data.Placemark.MultiGeometry.Polygon ) if data.Placemark.MultiGeometry.Polygon
    districts[district_name] = regions


###

###
load_districts = ()->
  load_district_data district for district in [ "d1", "d2", "d3", "d4" ] #

$doc.ready load_districts

###
regions have an outer perimeter
regions also have exclusion zones
###
region_contains_point = (region, point)->
  return true if region.Contains point
  false


###
districts have many regions
###
district_contains_point = (district, region, point)->
  foo = ( region_contains_point region, point for region in districts[district] )
  results = reject foo, (value)-> value == false
  return district if results.length > 0
  false


find_district_by_point = (point)->
  final_district = []
  foo = ( district_contains_point district, region, point for district, region of districts )
  results = reject foo, (value)-> value == false
  return false if results.length is not 1
  # report_district results[0]
  results[0]

###
given a location on the map, via address search or click
show that location on the map
###

reset_map = ()->
  marker.setMap(null) if marker
  map.setCenter downtown
  map.setZoom region_zoom


mark_point = (point, zoom = detail_zoom, address = "Location" )->
  district = find_district_by_point point

  map.setCenter point
  map.setZoom detail_zoom

  marker_data =
    map: map,
    position: point
  marker.setMap(null) if marker
  marker = new google.maps.Marker marker_data


  tmplString = "<p>{{=it.address}} is in Denton City {{=it.district}}</p>"
  tmpl = doT.template(tmplString)


  infoWindow = new google.maps.InfoWindow
    content: tmpl
      district: district
      address: address



  infoWindow.open(map, marker)


# report_district = (district)->
#   $('#your_district').text( "You reside in " + district + "!")


$query = $('#address')

do_map = ()->
  $button = $('#map-button')
  $map = $('#map-canvas')

  # geocoder = new google.maps.Geocoder()
  map_options =
    zoom: region_zoom
    center: downtown
    mapTypeId: google.maps.MapTypeId.ROADMAP

  map = new google.maps.Map document.getElementById('map-canvas'), map_options

  google.maps.event.addListener map, 'click', ()->
    reset_map()

    $('#your_district').text( "Location indicated doesn't appear to be part of a Denton city district. Please type in your address, or click on the map to find your district." )


  lookup_address = (event)->
    event.preventDefault()

    data =
      'address':  $query.val() + " Denton TX"

    geocode_success = (results, status)->
      address = results[0].formatted_address
      $query.val( address )

      if status is google.maps.GeocoderStatus.OK
        mark_point results[0].geometry.location, detail_zoom, address
      else
        reset_map()

    geocoder.geocode data, geocode_success
  $button.click lookup_address

$doc.ready do_map
