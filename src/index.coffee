define = require('amdefine')(module)  if typeof define isnt 'function'

define [
  'util'
  'lodash'
  'async'
  'request'
  'iconv'
  'know-your-http-well'
], (
  util
  _
  async
  request
  {Iconv}
  httpWell
) ->
  "use strict"

  statusWell = httpWell.statusPhrasesToCodes
  phraseWell = httpWell.statusCodesToPhrases
  ISO88591toUTF8 = new Iconv('ISO-8859-1', 'UTF-8').convert

  RpcError = (message) ->
    Error.call @
    Error.captureStackTrace @, @constructor
    @name = @constructor.name
    @message = message
  util.inherits RpcError, Error


  exports = {
    request
    RpcError
    personSearch:
      uri2: 'http://requestb.in/1fga5ng1'
      uri: 'http://www.ratsit.se/BC/SearchSimple.aspx/PersonSearch'
      method: 'POST'
      headers:
        'Content-Type': 'application/json; charset=UTF-8'
      body:
        who: ''
        where: ''
        filter: {
          Married: true
          Unmarried: true
          Male: true
          Female: true
          CompanyEngagement: true
          NoCompanyEngagement: true
          AgeFrom: '0'
          AgeTo: '150'
        }
      encoding: null # return body as Buffer
  }


  exports.search = (searchOptions, next) ->
    searchOptions.who ?= ''
    searchOptions.where ?= ''
    exports.search.req searchOptions, (args...) ->
      [err, res, body] = args
      return exports.makeError args, next  if err?
      try
        # "Content-Type: application/json; charset=iso-8859-1" http://is.gd/watjs
        body = ISO88591toUTF8 body
        body = JSON.parse body
        throw exports.makeError [err, res, body], next  if body.d.ErrorMessage?.length
        exports.makePersons body.d.PersonData, next
      catch err
        throw err
        return exports.makeError [err, res, body], next


  exports.search.req = (args, next) ->
    # {who, where, filter} = args
    body = args

    options = _.cloneDeep exports.personSearch
    options.body = _.merge options.body, body
    options.body.filter = JSON.stringify options.body.filter # http://is.gd/watjs
    options.body = JSON.stringify options.body
    request options, next


  exports.makeAddress = (data, next) ->
    id = new Buffer(data.Url).toString 'base64'
    res = [ # naïve
      /^(.+) +([0-9]+) +(.*)$/
      /^(.+) +([0-9]+)$/
    ]
    for re in res
      if re.test data.Address
        [
          street_address
          street_name
          street_number
          street_extension
        ] = re.exec data.Address
        break
    street_name = street_address  unless street_name

    address = {
      id
      given_name: data.FirstName
      family_name: data.LastName
      care_of: data.CoAddress or undefined
      street_address
      street_name
      street_number
      street_extension
      postal_code: data.ZipCode
      city: data.City
      country: 'SE'
      links: [{
        rel: ['self', 'http://rel.hyperrest.com/address'].join ' '
        href: "http://i4ratsit-se.hyperrest.com/addresses/#{id}"
      }]
    }
    next null, address


  exports.makePerson = (data, next) ->
    fun = (address) ->
      addressLink = _.find address.links, (link) -> _.contains link.rel.split(' '), 'self'
      addressLink = {
        rel: ['item', 'http://rel.hyperrest.com/address'].join ' '
        href: addressLink.href
        index: 0
      }  if addressLink?
      delete address.links

      id = address.id

      person = {
        id
        title: data.Title
        given_name: data.FirstName
        family_name: data.LastName
        gender: data.Gender
        date_of_birth: data.DateOfBirth
        addresses: [address]
        links: [{
            rel: ['self', 'http://rel.hyperrest.com/person'].join ' '
            href: "http://i4ratsit-se.hyperrest.com/persons/#{id}"
          }, {
            rel: ['alternative'].join ' '
            href: data.Url
          }
          addressLink
        ]
      }
      next null, person

    data.FirstName = data.FirstName.replace /<\/?b>/g, '' # http://is.gd/watjs

    [dateOfBirth] = /[0-9]{8}/.exec data.Url
    if dateOfBirth?
      [dateOfBirth, year, month, day] = /([0-9]{4})([0-9]{2})([0-9]{2})/.exec dateOfBirth
      data.DateOfBirth = "#{year}-#{month}-#{day}"

    if /male/.test data.Gender # http://is.gd/watjs
      data.Gender = 'male'
      data.Title = 'Mr.'
    else if /female/.test data.Gender # http://is.gd/watjs
      data.Gender = 'female'
      data.Title = 'Ms.'
      data.Title = 'Mrs.'  unless /unmarried/.test data.Married # http://is.gd/watjs

    exports.makeAddress data, (err, address) ->
      return next err  if err?
      fun address


  exports.makePersons = (personData, next) ->
    items = []
    links = []

    fun = (persons) ->
      for person, index in persons
        personLink = _.find person.links, (link) -> _.contains link.rel.split(' '), 'self'
        personLink = {
          rel: ['item', 'http://rel.hyperrest.com/person'].join ' '
          href: personLink.href
          index
        }  if personLink?
        delete person.links

        items.push person
        links.push personLink

      next null, {
        headers:
          'Content-Type': 'application/vnd.hyperrest.persons-v1+json'
        body: {
          items
          links
        }
      }

    async.mapSeries personData, exports.makePerson, (err, persons) ->
      return next err  if err?
      fun persons


  exports.makeError = ([err, res, body, options], next) ->
    # TODO ClientRequest
    # TODO body.ErrorMessage
    type = "http://problem.hyperrest.com/#{statusWell.INTERNAL_SERVER_ERROR}"
    title = phraseWell[statusWell.INTERNAL_SERVER_ERROR]

    next null, {
      statusCode: statusWell.INTERNAL_SERVER_ERROR
      headers:
        'Content-Type': 'application/problem+json; charset=UTF-8'
      body: {
        type
        title
        err: err.toString()
        response:
          statusCode: res.statusCode
          headers: res.headers
          body: body.toString()
      }
    }


  exports
