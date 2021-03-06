#!/usr/bin/env coffee

pkg = require '../package'
argparse = require 'argparse'
ArgumentParser = argparse.ArgumentParser
i4ratsitSe = require '../index'
_ = require 'lodash'

parser = new ArgumentParser
  description: pkg.description
  version: pkg.version
  addHelp: true

parser.addArgument ['who'],
  help: 'Who are you looking for?'
  nargs: '+'

parser.addArgument ['--where'],
  dest: 'where'
  help: 'Where are you looking for?'

parser.addArgument ['--json'],
  dest: 'asJSON'
  help: 'Return data as JSON'
  defaultValue: false
  action: 'storeTrue'

exports.main = (args = process.args) ->
  args = parser.parseArgs args
  {who, where} = args
  who = who.join ' '

  i4ratsitSe.search {who, where}, (err, res) ->
    throw err  if err?
    unless res.headers['Content-Type'] is 'application/vnd.hyperrest.persons-v1+json'
      throw JSON.stringify(res, null, 2)
    if asJSON
      console.log JSON.stringify res, null, 2
      return
    for person in res.body.items
      console.log _.template exports.personTpl, person
      for address in person.addresses
        console.log _.template exports.addressTpl, address


exports.personTpl = """
--------------------------------------------------------------------------------
${ title } ${ given_name } ${ family_name.toUpperCase() }
${ date_of_birth }

"""

exports.addressTpl = """
${ given_name } ${ family_name.toUpperCase() }
${ street_name } ${ street_number } ${ street_extension }
${ postal_code } ${ city }
${ country }

"""

exports.main()  if require.main is module
