#!/bin/bash
#########################################################################
# Author: chenqizheng@jd.com
PLATFORM=$1
GIT_HOME=$2
TARGET_BRANCH=$3
echo $4
JDREACT_MODULE=$4
ROOT_DIR=$(pwd)
build_version=$TARGET_BRANCH
build_platform=$PLATFORM
bundle_githash=`git log -1 --oneline | cut -d ' ' -f1`
build_result=''

COMMONPACK_NAME=`node ./scripts/get-commonpack-name.js`
. ${ROOT_DIR}/node_modules/${COMMONPACK_NAME}/jdreact.properties

chinese_module_name=$(cat jsbundles/$JDREACT_MODULE.version | grep "chineseModuleName" | awk -F "[:]" '/chineseModuleName/{print$2}' | sed 's/\"//g' | awk -F, '{print $1}')
if  [ ! -n "$chinese_module_name" ]; then
    chinese_module_name=$JDREACT_MODULE
fi
po_erp=$(cat jsbundles/$JDREACT_MODULE.version | grep "poErp" | awk -F "[:]" '/poErp/{print$2}' | sed 's/\"//g' | awk -F, '{print $1}')
git log -1 > gitlog.txt
if  [ ! -n "$po_erp" ]; then
    po_erp=`git log -1 | awk -F "[:]" '/Author/{print$2}' | awk '{sub(/^ */,"");sub(/ *$/,"")}1' | awk -F' ' '{print $1}'`
fi
PUSH_COMMENTS="[jdreact-bundle][$chinese_module_name][$po_erp] update '$JDREACT_MODULE' to '$JENKINS_BUILD_ID' by CI Robot. \n"$(cat gitlog.txt)"\n\nJENKINS_LAST_COMMIT = $bundle_githash\nJENKINS_JOB_NAME = $JENKINS_JOB_NAME \nJENKINS_BUILD_ID = $JENKINS_BUILD_ID \n\n========================================================\n\nif any issue, please contact shenchen1@jd.com."
rm -f gitlog.txt

echo ">>>>>> Starting to push jsbundles to app GIT ...."
echo "PLATFORM = $PLATFORM"
echo "GIT_HOME = $GIT_HOME"
echo "ROOT_DIR = $ROOT_DIR"
echo "TARGET_BRANCH = $TARGET_BRANCH"
echo "JDREACT_MODULE = $JDREACT_MODULE"
echo "CUSTOM_ANDROID_JDREACT_ASSETS = $CUSTOM_ANDROID_JDREACT_ASSETS"
echo "CUSTOM_ANDROID_JDREACT_DRAWABLE = $CUSTOM_ANDROID_JDREACT_DRAWABLE"
echo "CUSTOM_IOS_JDREACT_BUNDLE_PATH = $CUSTOM_IOS_JDREACT_BUNDLE_PATH"

doErrorExit () {
  cd $ROOT_DIR
  echo ">>>>>> remove BUILD_FILE"
  exit 1
}

doExit ( ) {
  exit 0
}

# got ROOT_DIR
cd $ROOT_DIR

# build jdreact jsbundle
if [ $PLATFORM == 'android' ]; then
  echo ">>>>>> Starting to build Android jsbundles ...."
  build_result=`./scripts/make-business-jsbundles-standalone.sh -p android -m $JDREACT_MODULE $OPTIM_IMAGE`
  echo "$build_result"
  if [[ $build_result =~ "make failed" ]]; then
    echo ">>>>>> jsbundle build failed!!! ...."
    doErrorExit
  fi

elif [ $PLATFORM == 'ios' ]; then
  echo ">>>>>> Starting to build iOS jsbundles ...."
  build_result=`./scripts/make-business-jsbundles-standalone.sh -p ios -m $JDREACT_MODULE $OPTIM_IMAGE`
  echo "$build_result"
  if [[ $build_result =~ "make failed" ]]; then
    echo ">>>>>> jsbundle build failed!!! ...."
    doErrorExit
  fi
else
  echo "platform is wrong! just exit!"
  doErrorExit
fi

# init & fetch android git
if [ $PLATFORM == 'android' ]; then
  if [ -d $GIT_HOME ]; then
    cd $GIT_HOME
    echo ">>>>>> fetch latest Android GIT"
    git checkout -- .
    git gc
    git fetch origin $TARGET_BRANCH || git fetch origin $TARGET_BRANCH || git fetch origin $TARGET_BRANCH || doErrorExit
    if [[ "$?" != "0" ]]; then
      echo ">>>>>> GIT fetch Failed!!! ...."
      doErrorExit
    fi
    echo ">>>>>> GIT fetch ok!!! ...."
    git checkout origin/$TARGET_BRANCH
    cd -
  else
    echo ">>>>>> not find android git, exit!"
    doErrorExit
  fi
elif [ $PLATFORM == 'ios' ]; then
  if [ -d $GIT_HOME ]; then
    cd $GIT_HOME
    echo ">>>>>> fetch latest iOS GIT"
    git checkout -- .
    git gc
    git fetch origin $TARGET_BRANCH || git fetch origin $TARGET_BRANCH || git fetch origin $TARGET_BRANCH || doErrorExit
    if [[ "$?" != "0" ]]; then
      echo ">>>>>> GIT fetch Failed!!! ...."
      doErrorExit
    fi
    echo ">>>>>> GIT fetch ok!!! ...."
    git checkout origin/$TARGET_BRANCH
    cd -
  else
    echo ">>>>>> not find iOS git, exit!"
    doErrorExit
  fi
else
  echo "platform is wrong! just exit!"
  doErrorExit
fi

# copy jsbundle to android git
if [ $PLATFORM == 'android' ]; then
  echo ">>>>>> delete old images from android git"
  modulename=$(echo $JDREACT_MODULE | tr 'A-Z' 'a-z')
  rm -f $GIT_HOME/$CUSTOM_ANDROID_JDREACT_DRAWABLE/drawable*/jsbundles_${modulename}_*
  echo ">>>>>> copy jsbundle to android git"
  mkdir $GIT_HOME/$CUSTOM_ANDROID_JDREACT_ASSETS/jdreact/$JDREACT_MODULE/
  cp -rf outputBundle/*.* $GIT_HOME/$CUSTOM_ANDROID_JDREACT_ASSETS/jdreact/$JDREACT_MODULE/
  rm -f `find outputBundle/drawable* -name *.html`
  rm -f $GIT_HOME/$CUSTOM_ANDROID_JDREACT_ASSETS/jdreact/$JDREACT_MODULE/*.map
  cp -rf outputBundle/drawable* $GIT_HOME/$CUSTOM_ANDROID_JDREACT_DRAWABLE/
elif [ $PLATFORM == 'ios' ]; then
  echo ">>>>>> copy jsbundle to iOS git"
  mkdir $GIT_HOME/$CUSTOM_IOS_JDREACT_BUNDLE_PATH/react.bundle/$JDREACT_MODULE/
  cp -rf outputBundle/* $GIT_HOME/$CUSTOM_IOS_JDREACT_BUNDLE_PATH/react.bundle/$JDREACT_MODULE/
  rm -f $GIT_HOME/$CUSTOM_IOS_JDREACT_BUNDLE_PATH/react.bundle/$JDREACT_MODULE/*.map
else
  echo "platform is wrong! just exit!"
  doErrorExit
fi

# push changes to android git
if [ $PLATFORM == 'android' ]; then
  echo ">>>>>> push changes to android git"
  cd $GIT_HOME
  git add $CUSTOM_ANDROID_JDREACT_DRAWABLE/*
  git add $CUSTOM_ANDROID_JDREACT_ASSETS/jdreact/*
  git commit -m "`echo -e $PUSH_COMMENTS`"
  echo ">>>>>> 2.1) remote prune origin..."
  git remote prune origin
  git fetch origin $TARGET_BRANCH
  if [[ "$?" != "0" ]]; then
    echo ">>>>>> git fetch origin Failed!!! ...."
    doErrorExit
  fi
  echo ">>>>>> git fetch origin ok!!! ...."
  git rebase origin/$TARGET_BRANCH
  git push origin HEAD:$TARGET_BRANCH
  if [[ "$?" != "0" ]]; then
    echo ">>>>>> GIT PUSH Failed!!! ...."
    doErrorExit
  fi
  echo ">>>>>> PUSH ok!!"
  cd -
elif [ $PLATFORM == 'ios' ]; then
  echo ">>>>>> push changes to iOS git"
  cd $GIT_HOME
  echo ">>>>>> 1) git add files..."
  git add $CUSTOM_IOS_JDREACT_BUNDLE_PATH/react.bundle/*
  echo ">>>>>> 2) git commit..."
  git commit -m "`echo -e $PUSH_COMMENTS`"
  echo ">>>>>> 2.1) remote prune origin..."
  git remote prune origin
  echo ">>>>>> 3) git remote update..."
  git fetch origin $TARGET_BRANCH
  if [[ "$?" != "0" ]]; then
    echo ">>>>>> git fetch origin Failed!!! ...."
    doErrorExit
  fi
  echo ">>>>>> git fetch origin ok!!! ...."
  echo ">>>>>> 4) git rebase..."
  git rebase origin/$TARGET_BRANCH
  echo ">>>>>> 5) start to push"
  git push origin HEAD:$TARGET_BRANCH
  if [[ "$?" != "0" ]]; then
    echo ">>>>>> GIT PUSH Failed!!! ...."
    doErrorExit
  fi
  echo ">>>>>> PUSH ok!!"
  cd -
else
  echo "platform is wrong! just exit!"
  doErrorExit
fi

doExit