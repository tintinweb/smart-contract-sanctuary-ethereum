/**
 *Submitted for verification at Etherscan.io on 2022-03-08
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

    weth.transfer(wildDeployer, 11.65e18);
    wild.transfer(wildDeployer, 513099e18);

    // ** Gas expenses **

    // Amount: 1.12 ETH

    // Block range: 14140347 to 14345490
    // Last done at https://etherscan.io/address/0xffD5d4b5a6dF94f6B8D481f5f402a810713Dd44E#code


    // **** Salaries ****

    // Amount: 0.81 ETH

    // Salaries
    // https://etherscan.io/tx/0x88a5c96df7338c686ad16911356da8a3a6da5314310a8efadcdd07f2d1a83d91
    // https://etherscan.io/tx/0xc36f4c5abee0c22e10415d0583e9308cca0f9d84b2b7a59aa0a2b30eb1ba6a33
    // https://etherscan.io/tx/0x33c8fedda0191418438e36f045a2efe0f850af3a53f6e4c2a18e8737eafd2384
    // https://etherscan.io/tx/0x3305384738490470ba57d4a98cd80bd6fe45755c40e505dab0377b55e7c0fa59

    // CRE8R DAO - 25,000 USDC (@ 2,574 USD / ETH) = 9.72 ETH
    // https://etherscan.io/tx/0x9fe26b823e5718eabb972b8c38788c203d8abab15df30089f24808406e781c87

    // **** TOTAL: Gas + salaries + marketing ****

    // 1.12 + 0.81 + 9.72 = 11.65 ETH

    
    // **** Borrow incentives ****

    // Amount: 513,099 WILD

    // https://etherscan.io/tx/0xa03671072bcf054f4e1c868a471413125cb337f0538eafa7a3028d95d3ab8fa1
    // https://etherscan.io/tx/0x280bd24f0365c9d455641aa123a9df102eae497d62f3f739facc9d3dfff61504
  }
}