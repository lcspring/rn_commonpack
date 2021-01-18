#!/bin/bash
#########################################################################
# Author: chenqizheng
ROOT_DIR=$(pwd)
PLATFORM=$1   # android ios 两种值
GIT_HOME=$2
TARGET_BRANCH=$3
JS_BRANCH=$4
JENKINS_BUILD_ID=$5
JENKINS_JOB_NAME=$6
NEED_COMMIT='true'
TAG_NAME="master"
bundle_githash=`git log -1 --oneline | cut -d ' ' -f1`
PUSH_COMMENTS="[jdreact-bundle] update 'JDReactCommon' to '$JENKINS_BUILD_ID' by CI Robot. \n\nJENKINS_LAST_COMMIT = $bundle_githash\nJENKINS_JOB_NAME = $JENKINS_JOB_NAME \nJENKINS_BUILD_ID = $JENKINS_BUILD_ID \n\n========================================================\n\nif any issue, please contact chenqizheng@jd.com."
. ${ROOT_DIR}/jdreact.properties

echo "====================================="
echo "=== JDReact JSBundle Commonpack build System ==="
echo "====================================="
echo "====================================="
echo "PLATFORM = $PLATFORM"
echo "GIT_HOME = $GIT_HOME"
echo "TARGET_BRANCH = $TARGET_BRANCH"
echo "ROOT_DIR = $ROOT_DIR"
echo "BRANCH_NAME = $TAG_NAME"
echo "CUSTOM_ANDROID_JDREACT_ASSETS = $CUSTOM_ANDROID_JDREACT_ASSETS"
echo "CUSTOM_ANDROID_JDREACT_DRAWABLE = $CUSTOM_ANDROID_JDREACT_DRAWABLE"
echo "CUSTOM_IOS_JDREACT_BUNDLE_PATH = $CUSTOM_IOS_JDREACT_BUNDLE_PATH"

doErrorExit () {
  cd $ROOT_DIR
  exit 1
}

initAndroidGit () {
  if [ -d $GIT_HOME ]; then
    cd $GIT_HOME
    echo ">>>>>> fetch latest Android GIT"
    git checkout -- .
    #git gc
    git fetch origin || git fetch origin || git fetch origin || doErrorExit
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

}

initIOSGit () {
  if [ -d $GIT_HOME ]; then
    cd $GIT_HOME
    echo ">>>>>> fetch latest iOS GIT"
    git checkout -- .
    #git gc
    git fetch origin $TARGET_BRANCH || git fetch origin $TARGET_BRANCH|| git fetch origin $TARGET_BRANCH|| doErrorExit
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
}

copyCommonToAndroid () {
  echo ">>>>>> copy commonpack to android git"
  mkdir $GIT_HOME/$CUSTOM_ANDROID_JDREACT_ASSETS/jdreact/JDReactCommon/
  cp -rf $ROOT_DIR/outputBundle-android/*.* $GIT_HOME/$CUSTOM_ANDROID_JDREACT_ASSETS/jdreact/JDReactCommon/
  rm -f `find outputBundle/drawable* -name *.html`
  rm -f $GIT_HOME/$CUSTOM_ANDROID_JDREACT_ASSETS/jdreact/JDReactCommon/*.map
  cp -rf $ROOT_DIR/outputBundle-android/drawable* $GIT_HOME/$CUSTOM_ANDROID_JDREACT_DRAWABLE/
}

copyCommonToIOS () {
  echo ">>>>>> copy commonpack to iOS git"
  mkdir $GIT_HOME/$CUSTOM_IOS_JDREACT_BUNDLE_PATH/react.bundle/JDReactCommon/
  cp -rf $ROOT_DIR/outputBundle-ios/* $GIT_HOME/$CUSTOM_IOS_JDREACT_BUNDLE_PATH/react.bundle/JDReactCommon/
  rm -f $GIT_HOME/$CUSTOM_IOS_JDREACT_BUNDLE_PATH/react.bundle/JDReactCommon/*.map
}

pushCommonToAndroid () {
  echo ">>>>>> push changes to android git"
  cd $GIT_HOME
  git add $CUSTOM_ANDROID_JDREACT_DRAWABLE/*
  git add $CUSTOM_ANDROID_JDREACT_ASSETS/jdreact/*
  git commit -m "`echo -e $PUSH_COMMENTS`"
  git fetch origin $TARGET_BRANCH
  if [[ "$?" != "0" ]]; then
    echo ">>>>>> git fetch origin Failed!!! ...."
    doErrorExit
  fi
  echo ">>>>>> git fetch origin ok!!! ...."
  git rebase origin/$TARGET_BRANCH
  if [ $NEED_COMMIT == 'true' ]; then
    git push origin HEAD:$TARGET_BRANCH
    if [[ "$?" != "0" ]]; then
      echo ">>>>>> GIT PUSH Failed!!! ...."
      doErrorExit
    fi
    echo ">>>>>> PUSH ok!!"
  fi
  cd -
}

pushCommonToIOS () {
  echo ">>>>>> push changes to iOS git"
  cd $GIT_HOME
  echo ">>>>>> 1) git add files..."
  git add $CUSTOM_IOS_JDREACT_BUNDLE_PATH/react.bundle/*
  echo ">>>>>> 2) git commit..."
  git commit -m "`echo -e $PUSH_COMMENTS`"
  echo ">>>>>> 2.1) remote prune origin..."
  git remote prune origin
  echo ">>>>>> 3) git fetch origin..."
  git fetch origin $TARGET_BRANCH
  if [[ "$?" != "0" ]]; then
    echo ">>>>>> git fetch origin Failed!!! ...."
    doErrorExit
  fi
  echo ">>>>>> git remote update ok!!! ...."
  echo ">>>>>> 4) git rebase..."
  git rebase origin/$TARGET_BRANCH
  if [ $NEED_COMMIT == 'true' ]; then
    echo ">>>>>> 5) start to push"
    git push origin HEAD:$TARGET_BRANCH
    if [[ "$?" != "0" ]]; then
      echo ">>>>>> GIT PUSH Failed!!! ...."
      doErrorExit
    fi
    echo ">>>>>> PUSH ok!!"
  fi
  cd -
}

echo ">>>>>> Starting to jdreact pull git ...."
git checkout .
git checkout origin/$TAG_NAME
git pull origin $TAG_NAME
if [[ "$?" != "0" ]]; then
  echo ">>>>>> pull git faild!!"
  exit 1
else
  echo ">>>>>> pull git success!!"
fi

# init & fetch android git
if [ $PLATFORM == 'android' ]; then
  initAndroidGit

elif [ $PLATFORM == 'ios' ]; then
  initIOSGit

else
  echo "platform is wrong! just exit!"
  doErrorExit
fi



# build commonpack
echo ">>>>>> build android and ios commonpack"
npm run clean
npm run cp

if [ $PLATFORM == 'android' ]; then
  npm run build-android

elif [ $PLATFORM == 'ios' ]; then
  npm run build-ios

else
  echo "platform is wrong! just exit!"
  doErrorExit
fi


if [[ "$?" != "0" ]]; then
  echo ">>>>>> build commonpack faild!!"
  exit 1
else
  echo ">>>>>> build commonpack success!!"
fi



android_dir=outputBundle-android
ios_dir=outputBundle-ios

# push commonpack to jdreact git
echo -e ">>>>>> push to commonpack git"
echo -e "commit"
git add --all
git commit -m "build commonpack"
git remote update
git rebase origin/$TAG_NAME
git push origin HEAD:$TAG_NAME
echo -e "commit end"



# copy commonpack to android git
if [ $PLATFORM == 'android' ]; then
  copyCommonToAndroid
elif [ $PLATFORM == 'ios' ]; then
  copyCommonToIOS
else
  echo "platform is wrong! just exit!"
  doErrorExit
fi

# push changes to android git
if [ $PLATFORM == 'android' ]; then
  pushCommonToAndroid
elif [ $PLATFORM == 'ios' ]; then
  pushCommonToIOS
else
  echo "platform is wrong! just exit!"
  doErrorExit
fi

# publish to npm
cd $ROOT_DIR
old_version=`npm dist-tag ls`
new_version=`node ./scripts/patch-version.js $old_version`
echo "old version is : $old_version"
echo "new version is : $new_version"
npm version $new_version
pkg_name=`node ./scripts/get-pkgname.js $PKGNAME`
echo "publish package.json name is : $pkg_name"
npm publish

# commit version
if [[ "$?" =~ "1" ]]; then
  echo ">>>>>> publish $pkg_name faild!!"
  exit 1
else
  echo ">>>>>> publish $pkg_name success!!"
fi

# push to git
echo -e ">>>>>> push to git"
echo -e "commit"
git add --all
git commit -m "build $pkg_name $new_version"
git push origin HEAD:$JS_BRANCH
echo -e "commit end"
echo ">>>>>> push to jdreact-core git success!!"