// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TimelockProposal {

  function execute() external {

    address multisig = 0x38495b79a3939549dd130Ba4d9F0fC38B6C4aF75;

    IERC20 wild = IERC20(0x403d512AB96103562DCaFe4635545E8Ee2753f6e);

    wild.transfer(multisig, 1e24);

    // ** WILD to MultiSig **
    
    // Transfer 1M WILD Token to MultiSig for Reward Distributions

  }
}