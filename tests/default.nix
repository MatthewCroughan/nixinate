{ pkgs, makeTest, inputs }:
{
  vmTest = import ./vmTest { inherit pkgs makeTest inputs; };
}
