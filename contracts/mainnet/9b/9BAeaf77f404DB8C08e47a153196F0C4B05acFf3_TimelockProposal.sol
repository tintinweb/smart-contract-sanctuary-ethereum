/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-19
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

    address wildDeployer = 0xd7b3b50977a5947774bFC46B760c0871e4018e97;

    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 wild = IERC20(0x403d512AB96103562DCaFe4635545E8Ee2753f6e);

    weth.transfer(wildDeployer, 1.105e18);
    wild.transfer(wildDeployer, 269668e18);

    // ** Gas expenses **

    // Amount: 0.08 ETH

    // Block range: 14412592 to 14531435
    // Last done at https://etherscan.io/address/0xbb6e5e47d95d05474a153ec767c8e5d0a13a3d62/advanced#code


    // **** Expenses ****

    // Infura from Sep, 2021 to Apr, 2022 - 3,000 USD (~ 0.9 ETH)
    // Job post - 0.125 ETH
    // https://etherscan.io/tx/0x504e10b2c603dead858c022e06f352768518efd9454cbd1071dfd3e3c7fb168b

    // **** TOTAL: Gas + expenses ****

    // 0.08 + 0.9 + 0.125 = 1.105 ETH

    
    // **** Borrow incentives + veWILD ****

    // Amount: 232,568 + 37,100 = 269,668 WILD

    // https://etherscan.io/tx/0xe9a074b26c908918f6f42b92f87c1f7334f3661ffe3bdcce535cd82a8bff6add
    // https://etherscan.io/tx/0x61f49fb9b0b91e6b4fb5a58d2a59c29de9f6051e7d43763c4373c6f8c337ca03
  }
}