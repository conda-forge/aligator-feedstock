#!/bin/sh

rm -rf build

mkdir build
cd build

BUILD_NUMPY_INCLUDE_DIRS=$( $PYTHON -c "import numpy; print (numpy.get_include())")
TARGET_NUMPY_INCLUDE_DIRS=$SP_DIR/numpy/core/include

echo $BUILD_NUMPY_INCLUDE_DIRS
echo $TARGET_NUMPY_INCLUDE_DIRS

GENERATE_PYTHON_STUBS=1
if [[ $CONDA_BUILD_CROSS_COMPILATION == 1 ]]; then
  echo "Copying files from $BUILD_NUMPY_INCLUDE_DIRS to $TARGET_NUMPY_INCLUDE_DIRS"
  mkdir -p $TARGET_NUMPY_INCLUDE_DIRS
  cp -r $BUILD_NUMPY_INCLUDE_DIRS/numpy $TARGET_NUMPY_INCLUDE_DIRS
  GENERATE_PYTHON_STUBS=0
fi

# crocoddyl package doesn't exists on linux_aarch64 and linux_ppc64le architecture
BUILD_CROCODDYL_COMPAT=1
if [[ $HOST =~ linux ]]; then
  if [[ $HOST =~ aarch64 || $HOST =~ powerpc64le ]]; then
    BUILD_CROCODDYL_COMPAT=0
  fi
fi

cmake ${CMAKE_ARGS} .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DPYTHON_EXECUTABLE=$PYTHON \
      -DBUILD_PYTHON_INTERFACE=ON \
      -DGENERATE_PYTHON_STUBS=$GENERATE_PYTHON_STUBS \
      -DPython3_NumPy_INCLUDE_DIR=$TARGET_NUMPY_INCLUDE_DIRS \
      -DBUILD_WITH_OPENMP_SUPPORT=ON \
      -DBUILD_CROCODDYL_COMPAT=$BUILD_CROCODDYL_COMPAT \
      -DBUILD_EXAMPLES=ON \
      -DBUILD_BENCHMARK=OFF \
      -DBUILD_TESTING=OFF

# build
cmake --build . --parallel ${CPU_COUNT}

# install
cmake --build . --target install

if [[ $CONDA_BUILD_CROSS_COMPILATION == 1 ]]; then
  sed -i 's|'"$BUILD_PREFIX"'|'"$PREFIX"'|g' $PREFIX/lib/cmake/aligator/aligatorTargets.cmake
fi
