const minimist = require('minimist');
const platform = minimist(process.argv.slice(2)).platform;
const commonModules = require(`${__dirname}/node_modules/@areslabs/ares-jsbundle-commonpack/commonBundleConfig.${platform}.json`);
const path = require('path');

function postProcessModulesFilter(module) {
    if (module['path'].indexOf('__prelude__') >= 0) {
        return false;
    }
    let mod = commonModules.filter(item => path.relative(__dirname, module['path']).indexOf(item.path) === 0);

    if(mod.length > 0) {
        return false;
    }
    return true;
}

function createModuleIdFactory() {
    if (createModuleIdFactory.createCommonIdFactory) {
        return createModuleIdFactory.createCommonIdFactory();
    }
    const fileToIdMap = new Map();
    commonModules.forEach(item => fileToIdMap.set(item.path, item.id));
    let nextId = 5001;
    return modulePath => {
        modulePath = path.relative(__dirname, modulePath);
        let id = fileToIdMap.get(modulePath);
        if (typeof id !== 'number') {
            id = nextId++;
            fileToIdMap.set(modulePath, id);
        }
        return id;
    };
}


module.exports = {
    serializer: {
        createModuleIdFactory: createModuleIdFactory,
        processModuleFilter: postProcessModulesFilter
        /* serializer options */
    }
};
