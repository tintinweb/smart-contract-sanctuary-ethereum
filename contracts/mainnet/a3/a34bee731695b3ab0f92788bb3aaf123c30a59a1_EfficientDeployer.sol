/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

//SPDX-License-Identifier: UNLICENSED

contract EfficientDeployer {
    address owner = msg.sender;
    
    modifier isOwner() {
        require(msg.sender == owner, "Forbidden.");
        _;
    }
    
    function deploy(bytes memory code, uint256 salt) isOwner public returns(address) {
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        return addr;
    }
    
    function computeAddress(bytes memory code, uint256 salt) public view returns(address) {
        uint8 prefix = 0xff;
        bytes32 initCodeHash = keccak256(abi.encodePacked(code));
        bytes32 hash = keccak256(abi.encodePacked(prefix, address(this), salt, initCodeHash));
        return address(uint160(uint256(hash)));
    }
}