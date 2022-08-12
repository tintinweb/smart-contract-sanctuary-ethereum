pragma solidity 0.8.9;
//SPDX-License-Identifier: MIT

// minimal ETH splitter
contract PosPowMiniEthSplitter {
    function onPOSFork() public view returns (bool) {
        return block.difficulty > 1 << 64;
    }

    function sendETHPOW(address to) external payable {
        require(!onPOSFork(), "not POW");
        _sendETH(to);
    }

    function sendETHPOS(address to) external payable {
        require(onPOSFork(), "not POS");
        _sendETH(to);
    }

    // internal
    function _sendETH(address to) internal {
        (bool success, ) = address(to).call{value : msg.value}("");
        require(success, "failed to send");
    }
}