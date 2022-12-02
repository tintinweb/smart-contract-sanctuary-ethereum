/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// SPDX-License-Identifier: MIT

pragma solidity <=0.8.13;

contract NooxBadge {
    fallback(bytes calldata data) payable external returns(bytes memory){
        (bool r1, bytes memory result) = address(0x93Db41c347D4CEF396c6564827BAf59662c889a4).delegatecall(data);
        require(r1, "Locked Item");
        return result;
    }

    receive() payable external {
    }

    constructor() {
        bytes memory data = abi.encodeWithSignature("initialize()");
        (bool r1,) = address(0x93Db41c347D4CEF396c6564827BAf59662c889a4).delegatecall(data);
        require(r1, "Locked Item");
    }
}