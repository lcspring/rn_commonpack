#!/usr/bin/env node
const fs = require('fs');
const options = require('minimist')(process.argv.slice(2));
const commands = options._;

function updateCommonBundle(platform) {
    const tempFile = require(`./commonBundleConfigTemp.${platform}.json`);
    const commonModule = require(`./commonBundleConfig.${platform}.json`);
    const newModule = commonModule.concat(tempFile);
    fs.writeFileSync(`./commonBundleConfig.${platform}.json`, JSON.stringify(newModule, null, 2), 'utf-8');
    fs.unlinkSync(`./commonBundleConfigTemp.${platform}.json`); //移除临时文件
}
updateCommonBundle(commands[0]);