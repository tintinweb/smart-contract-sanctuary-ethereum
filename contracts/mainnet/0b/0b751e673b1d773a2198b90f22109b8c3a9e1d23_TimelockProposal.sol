/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns(uint);
}

interface INonfungiblePositionManager {
    function safeTransferFrom(address, address, uint) external;
}

contract TimelockProposal {

    function execute() external {
        INonfungiblePositionManager positionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

        uint tokenId = 182321;
        address treasury = 0xfd66Fb512dBC2dFA49377CfE1168eaFc4ea6Aa5D;
        IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        address multisig = 0x38495b79a3939549dd130Ba4d9F0fC38B6C4aF75;

        uint256 wethBalance = weth.balanceOf(treasury);
        weth.transfer(multisig, wethBalance);

        positionManager.safeTransferFrom(address(this), multisig, tokenId);

        // ** collect WETH & UniV3 position from treasury into multisig **
    }
}