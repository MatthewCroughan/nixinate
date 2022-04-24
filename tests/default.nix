{ pkgs, makeTest, inputs }:
{
  vmTestLocal = (import ./vmTest { inherit pkgs makeTest inputs; }).local;
  vmTestRemote = (import ./vmTest { inherit pkgs makeTest inputs; }).remote;
}
