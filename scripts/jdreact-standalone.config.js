const platform = process.env.METRO_PLATFORM;
const rootDir = process.env.METRO_ROOT_DIR;
const fs = require('fs');
let jdreactConfig;
try {
    fs.statSync(`${process.cwd()}/jdreact.config.js`);
    jdreactConfig = require(`${process.cwd()}/jdreact.config.js`)
    if (jdreactConfig.businessStartID == undefined || jdreactConfig.businessStartID < 5000) {
        jdreactConfig.businessStartID = 5000;
    }
} catch (e) {
    jdreactConfig = { commonpack: "@jdreact/jdreact-commonpack-standalone", businessStartID: 5000 }
}
const commonModules = require(`${process.cwd()}/node_modules/${jdreactConfig.commonpack}/commonBundleConfig.${platform}.json`);
const path = require('path');
const commonImgs = [
    '@jdreact/jdreact-core-lib-img/dot_dark.png',
    '@jdreact/jdreact-core-lib-img/minus_dark.png',
    '@jdreact/jdreact-core-lib-img/plus_dark.png'
]

function isSpecialModule(module) {
    for (let index = 0; index < commonImgs.length; index++) {
        if (module['path'].indexOf(commonImgs[index]) >= 0) {
            return true;
        }
    }
    return false;
}
function postProcessModulesFilter(module) {
    if (module['path'].indexOf('__prelude__') >= 0) {
        return false;
    }
    if (platform === 'ios' && isSpecialModule(module)) {
        return true;
    }
    let mod = commonModules.filter(item => path.relative(rootDir, module['path']).indexOf(item.path) === 0);

    if (mod.length > 0) {
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
    let nextId = jdreactConfig.businessStartID;
    return modulePath => {
        modulePath = path.relative(rootDir, modulePath);
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
    },
    projectRoot: rootDir
};
