/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TimelockProposal {

  function execute() external {

    address wildDeployer = 0xd7b3b50977a5947774bFC46B760c0871e4018e97;

    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 wild = IERC20(0x403d512AB96103562DCaFe4635545E8Ee2753f6e);

    weth.transfer(wildDeployer, 8.92e18);
    wild.transfer(wildDeployer, 827681e18);

    // ** Gas expenses **

    // Amount: 7.31 ETH

    // Block range: 13862568 to 14140347
    // Last done at https://etherscan.io/address/0xeF5606010407C5835e7A9253448b256FA8D4D3De#code


    // **** Salaries ****

    // Amount: 0.92 ETH + 2,000 USDC (~ 0.69 ETH) = 1.61 ETH

    // https://etherscan.io/tx/0x385634564e1fbddb1a4df5996a64c0393df77f0760e970535659d5d65c074bbd
    // https://etherscan.io/tx/0x1cd69e49e9917dfa3733126c8323ec0f97aec7b63eda43ae677ded318a489469
    // https://etherscan.io/tx/0xb6fd55c212cc2103a1abc4b928a40c056bf5dd87bb13e69a09d9a6497f25777b
    // https://etherscan.io/tx/0x3effabaf84670adabd74c3cad524460099ed4474ab413e33e7d3a189c17c3bea
    // https://etherscan.io/tx/0xfdd0fdd162572310d7da59cbf8b175d0f41dd3d79f8ce9c10bf02cabb0d88589


    // **** TOTAL: Gas + salaries ****

    // 7.31 + 1.61 = 8.92 ETH

    
    // **** Borrow incentives ****

    // Amount: 827,681 WILD

    // Round 1: https://etherscan.io/tx/0xd64abfa5a367f1ffa19b056920e77bfc601aaced25a01167435cf7e7260a0d5f
    // Round 2: https://etherscan.io/tx/0xd1831d411ca0e52558e27abd73b25d771c71a6bb8798cd53832df0341ff64869
    // Round 3: https://etherscan.io/tx/0xccf29fe6e6f15407465708e6dcdc2d69a9a1d8505619a4c3220e1ae7b669d844
  }
}