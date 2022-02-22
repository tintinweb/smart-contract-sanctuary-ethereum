// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IProxy {
  function upgradeTo(address newImplementation) external;
}

contract TimelockProposal {

  function execute() external {

    IProxy proxy = IProxy(0xc4347dbda0078d18073584602CF0C1572541bb15);

    address veToken = 0x5CCAfe74b0271AC80573044d1450E2B836f839fD;

    proxy.upgradeTo(veToken);
  }
}