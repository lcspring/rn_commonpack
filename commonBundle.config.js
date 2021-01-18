const fs = require('fs');
const path = require('path');
const minimist = require('minimist');
const platform = minimist(process.argv.slice(2)).platform;

const tempFile = path.resolve(`./commonBundleConfigTemp.${platform}.json`);

const commonModule = require(`./commonBundleConfig.${platform}.json`);

function createModuleIdFactory() {
    let nextId = 0;
    if(!commonModule || commonModule.length === 0) {
        nextId = 0;
    }else{
        //commonModule 中id的最大值
        nextId = Math.max.apply(Math, commonModule.map(function(item) {return item.id}));
        ++nextId;
    }
    const configs = [];
    const fileToIdMap = new Map();
    commonModule.forEach(item => fileToIdMap.set(item.path, item.id));

    return modulePath => {
        modulePath = path.relative(__dirname, modulePath);
        let id = fileToIdMap.get(modulePath);
        if (typeof id !== "number") {
            id = nextId++;
            fileToIdMap.set(modulePath, id);
            configs.push({
                id,
                path: modulePath
            });
            fs.writeFileSync(tempFile, JSON.stringify(configs, null, 2), 'utf-8');
        }
        return id;
    };
}


module.exports = {
    serializer: {
        createModuleIdFactory:createModuleIdFactory
    }
};
