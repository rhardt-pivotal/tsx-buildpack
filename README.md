# tsx Buildpack
multi-buildpack to enable TimeShiftX to run alongside your java app on Tanzu Application Service (Formerly PCF)

1.  `git clone https://gitlab.com/RHardt3/time-shift-demo.git`
2.  `cd time-shift-demo`
3.  `./mvnw clean package`
4.  `cd ./tmp`
5.  `cf push tsx-demo -p . --no-start -b binary_buildpack # deploys an empty app so we can set metadata`
6.  `cf set-env tsx-demo TSX_TAR_URI https://path-to-tar-file  # doesn't honor HTTP_PROXY, so needs to be hosted internally (c.f. staticfile buildpack)`
7.  `cf set-env tsx-demo TSX_ARGS "set -y -2"  # fine year, worth reliving`
8.  `cf set-env tsx-demo HTTP_PROXY http://proxy.server.uri  # optional - necessary if you're behind a proxy and the buildpacks aren't hosted internally`
9.  `cf set-env tsx-demo HTTPS_PROXY http://proxy.server.uri  # optional - same`
10.  `cd ..`
11.  `cf push tsx-demo -b https://gitlab.com/RHardt3/tsx-buildpack.git -b https://github.com/cloudfoundry/java-buildpack -p ./target/time-shift-demo-3-0.0.1-SNAPSHOT.jar`
12.  subsequent pushes only require step 11