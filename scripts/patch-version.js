#!/usr/bin/env node


'use strict';

const chalk = require('chalk');
const options = require('minimist')(process.argv.slice(2));
const commands = options._;
var versionArray = []



checkArgsAmount(commands)
var versions = getVersionArray(commands)
versions.forEach((item,idx)=>{
  let versionObj= {};
  let splitArr = item.split('.');
  versionObj['major'] = parseInt(splitArr[0]);
  versionObj['minor'] = parseInt(splitArr[1]);
  versionObj['patch'] = parseInt(splitArr[2]);
  versionArray.push(versionObj)
})
var filterMajor = getNewestVersion(versionArray,'major');
var filterMinor = getNewestVersion(filterMajor,'minor');
var filterPatch = getNewestVersion(filterMinor,'patch');
console.log(getNextPatchVersion(filterPatch[0]))



function getVersionArray(commandsArray){
  let result = []
  commandsArray.forEach((item,idx)=>{
    if(idx%2 !==0){
      result.push(item)
    }
  })
  return result
}

function checkArgsAmount(args){
  if (args.length%2 !==0) {
    console.error(chalk.red('patch-version.js checkArgsAmount error'));
    process.exit(1);
  }
}

function getNewestVersion(versionArray,versionType){
  var tempArr = [];
  versionArray.forEach((item,idx)=>{
    tempArr.push(item[versionType]);
  })
  let max = Math.max.apply(null,tempArr)
  let filterArray = []
  versionArray.forEach((item,idx)=>{
    if(item[versionType]===max){
      filterArray.push(item)
    }
  })
  return filterArray
}

function getNextPatchVersion(versionObj){
  return `${versionObj['major']}.${versionObj['minor']}.${versionObj['patch']+1}`
}