/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

pragma solidity 0.8.9;
//SPDX-License-Identifier: MIT

// minimal ETH splitter
contract PosPowMiniEthSplitter {
    function difficulty() external view returns (uint) {
        return block.difficulty;
    }

    function sendETHPOW(address to) external payable {
        require(block.difficulty < 1 << 64, "not POW");
        _sendETH(to);
    }

    function sendETHPOS(address to) external payable {
        require(block.difficulty > 1 << 64, "not POS");
        _sendETH(to);
    }

    // internal
    function _sendETH(address to) internal {
        (bool success, ) = address(to).call{value : msg.value}("");
        require(success, "failed to send");
    }
}