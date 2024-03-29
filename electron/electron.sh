#!/bin/zsh

# current workspace
export ELECTRON_WORKSPACE="$HOME/Developer/electron-gn"

# depot_tools
export PATH=$PATH:~/Developer/depot_tools

# sccache
export SCCACHE_BUCKET="electronjs-sccache"
export SCCACHE_TWO_TIER=true

# navigate to electron dir
alias e='cd $ELECTRON_WORKSPACE/src/electron'

# change electron workspace
alias eco='electron_checkout_workspace'
electron_checkout_workspace() {
  dir="$HOME/Developer/electron-$1"
  if [ -d $dir ]; then
    export ELECTRON_WORKSPACE=$dir 
    echo "[info] electron workspace: '$ELECTRON_WORKSPACE'"
  else
    echo "[error] workspace '$dir' not found"
  fi
}

# setup fresh electron build
# (https://github.com/electron/electron/blob/master/docs/development/build-instructions-gn.md)
alias efb='electron_fresh_build'
electron_fresh_build() {
  echo "[info] creating fresh electron build"
  curr_dir=$PWD # save cwd
  # caching
  export GIT_CACHE_PATH="${HOME}/.git_cache"
  mkdir -p "${GIT_CACHE_PATH}"
  # getting the code
  cd $ELECTRON_WORKSPACE
  gclient config --name "src/electron" --unmanaged https://github.com/electron/electron
  gclient sync --with_branch_heads --with_tags
  # set remote url
  cd $ELECTRON_WORKSPACE/src/electron
  # checkout specific branch
  if [[ -n "$1" ]]; then
    echo "[info] checkout '$1'"
    git checkout $1
  else
    echo "[info] checkout 'master'"
    git checkout master
  fi
  git remote set-url origin https://github.com/electron/electron
  git pull
  gclient sync -f
  # buildfiles
  cd $ELECTRON_WORKSPACE/src
  export CHROMIUM_BUILDTOOLS_PATH=`pwd`/buildtools
  export GN_EXTRA_ARGS="${GN_EXTRA_ARGS} cc_wrapper=\"${PWD}/electron/external_binaries/sccache\""
  gn gen out/Debug --args="import(\"//electron/build/args/debug.gn\") $GN_EXTRA_ARGS"
  cd $curr_dir # return
}

# build electron from src
alias ebd='electron_build'
electron_build() {
  echo "[info] building electron"
  curr_dir=$PWD # save cwd
  cd $ELECTRON_WORKSPACE/src
  ninja -C out/Debug electron
  cd $curr_dir # return
}

# electron recompile node headers
alias enh='electron_node_headers'
electron_node_headers() {
  echo "[info] recompiling node headers"
  curr_dir=$PWD # save cwd
  cd $ELECTRON_WORKSPACE/src
  ninja -C out/Debug third_party/electron_node:headers # recompile node headers
  cd $curr_dir # return
}

# run electron tests
alias ert='electron_run_tests'
electron_run_tests() {
  echo "[info] running electron tests"
  curr_dir=$PWD # save cwd
  if [[ "$1" == "-r" ]]; then
    echo "[info] only remote process"
    e && yarn test --ci --runners=remote
  elif  [[ "$1" == "-m" ]]; then
    echo "[info] only main process"
    e && yarn test --ci --runners=main
  else 
    e && yarn test --ci
  fi
  cd $curr_dir
}

# run electron build
alias erb='electron_run_build'
electron_run_build() {
  echo "[info] running electron"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    $ELECTRON_WORKSPACE/src/out/Debug/Electron.app/Contents/MacOS/Electron
  else
    echo "[error] unsupported operating system '$OSTYPE'"
  fi
}