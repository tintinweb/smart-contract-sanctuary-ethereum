// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface ILendingController {
  function setColFactor(address _token, uint _value) external;
}


contract TimelockProposal {

  function execute() external {

    ILendingController lendingController = ILendingController(0x2CA9b2cd3b50a4B11bc2aC73bC617aa5Be9A6ca1);

    address ape = 0x4d224452801ACEd8B2F0aebE155379bb5D594381;

    lendingController.setColFactor(ape, 60e18);

    // ** APE Collateral Factor **
    
    // Set Collateral Factor of APE to 0.6

  }
}