/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

library OMCLib {
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    function _safeTransfer(address token, address to, uint value) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SAFE_TRANSER FAIL");
    }
}