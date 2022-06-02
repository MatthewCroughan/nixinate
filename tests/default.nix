{ pkgs, makeTest, inputs }:
{
  vmTestLocal = (import ./vmTest { inherit pkgs makeTest inputs; }).local;
  vmTestRemote = (import ./vmTest { inherit pkgs makeTest inputs; }).remote;
  vmTestLocalHermetic = (import ./vmTest { inherit pkgs makeTest inputs; }).localHermetic;
  vmTestRemoteHermetic = (import ./vmTest { inherit pkgs makeTest inputs; }).remoteHermetic;
}
