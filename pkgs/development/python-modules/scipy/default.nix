{lib, fetchPypi, python, buildPythonPackage, gfortran, nose, pytest, numpy, fetchpatch}:

buildPythonPackage rec {
  pname = "scipy";
  version = "1.2.1";

  src = fetchPypi {
    inherit pname version;
    sha256 = "e085d1babcb419bbe58e2e805ac61924dac4ca45a07c9fa081144739e500aa3c";
  };

  checkInputs = [ nose pytest ];
  nativeBuildInputs = [ gfortran ];
  buildInputs = [ numpy.blas ];
  propagatedBuildInputs = [ numpy ];

  # Remove tests because of broken wrapper
  prePatch = ''
    rm scipy/linalg/tests/test_lapack.py
  '';

  # INTERNALERROR, solved with https://github.com/scipy/scipy/pull/8871
  # however, it does not apply cleanly.
  doCheck = false;

  preConfigure = ''
    sed -i '0,/from numpy.distutils.core/s//import setuptools;from numpy.distutils.core/' setup.py
    export NPY_NUM_BUILD_JOBS=$NIX_BUILD_CORES
  '';

  preBuild = ''
    ln -s ${numpy.cfg} site.cfg
  '';

  enableParallelBuilding = true;

  checkPhase = ''
    runHook preCheck
    pushd dist
    ${python.interpreter} -c 'import scipy; scipy.test("fast", verbose=10)'
    popd
    runHook postCheck
  '';

  passthru = {
    blas = numpy.blas;
  };

  setupPyBuildFlags = [ "--fcompiler='gnu95'" ];

  meta = {
    description = "SciPy (pronounced 'Sigh Pie') is open-source software for mathematics, science, and engineering. ";
    homepage = https://www.scipy.org/;
    maintainers = with lib.maintainers; [ fridh ];
  };
}
