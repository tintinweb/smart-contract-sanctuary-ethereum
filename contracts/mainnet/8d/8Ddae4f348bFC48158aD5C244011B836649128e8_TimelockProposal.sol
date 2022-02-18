// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IProxy {
  function upgradeTo(address newImplementation) external;
}

contract TimelockProposal {

  function execute() external {

    IProxy proxy = IProxy(0xc4347dbda0078d18073584602CF0C1572541bb15);

    address veToken = 0x879f2aD840E3f920B16982e55455D0905DDf164E;

    proxy.upgradeTo(veToken);
  }
}