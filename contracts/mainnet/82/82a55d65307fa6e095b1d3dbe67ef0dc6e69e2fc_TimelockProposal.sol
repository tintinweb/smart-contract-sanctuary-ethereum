/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IOwnable {
  function acceptOwnership() external;
}

contract TimelockProposal {

  function execute() external {

    // PairFactory
    IOwnable(0x0fC7e80090bbc1740595b1fcCd33E0e82547212F).acceptOwnership();

    // OracleAggregator
    IOwnable(0x993726B3Fef1fa124A8FA198D047C36827D2dD20).acceptOwnership();

    // LendingController
    IOwnable(0x2CA9b2cd3b50a4B11bc2aC73bC617aa5Be9A6ca1).acceptOwnership();

    // veWILD
    IOwnable(0xc4347dbda0078d18073584602CF0C1572541bb15).acceptOwnership();


    address wildDeployer = 0xd7b3b50977a5947774bFC46B760c0871e4018e97;

    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 wild = IERC20(0x403d512AB96103562DCaFe4635545E8Ee2753f6e);

    weth.transfer(wildDeployer, 16.89e18);
    wild.transfer(wildDeployer, 3275100e18);

    // ** Gas expenses **

    // Amount: 0.2 ETH

    // Block range: 14352092 to 14412592
    // Last done at https://etherscan.io/address/0xD6231F50b53250b10fDD7CAE7A3e54002cc66d78#code


    // Hire 0xArvaz full-time

    // 48,000 USDC / year (16.55 ETH @ $2,900 / ETH)
    // https://etherscan.io/tx/0x5b669f736896976bb44e5b7ae373b48ff03e1d01596fc77c238656a10ad95ce5

    // + 3,000,000 WILD / year
    // https://etherscan.io/tx/0x8246c7e26e3bd56e04483281f45e49d137e0cc6ad22557d399928c8977fa7e15


    // **** Salaries ****

    // Amount: 0.14 ETH

    // Salaries
    // https://etherscan.io/tx/0x3f393a1da40eea6d5a9052c546a5ef9038283ac2b870ea83bb343e4c96b528ac

    // **** TOTAL: Gas + salaries ****

    // 0.2 + 0.14 + 16.55 = 16.89 ETH

    
    // **** Borrow incentives + veWILD ****

    // Amount: 238,000 + 37,100 = 275,100 WILD

    // https://etherscan.io/tx/0xc719d0ae1d3427072a4bb85421c2a8d8f2263854418a01b19dbda06f68d6f587
    // https://etherscan.io/tx/0x40f8d54b88c0b60cbf903a1e2d93d02bdadd91d2b7c07509e840bb6e4e44576f
  }
}