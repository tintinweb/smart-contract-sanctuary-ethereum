/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IVerifier {
    function verify(bytes memory flag) external returns(bool);
}

contract Verifier3 {
    address public alice;
    IVerifier _verifier;
    address _target;
    uint value = 0x66;

    constructor(address verifier, address target) {
        _verifier = IVerifier(verifier);
        _target = target;
    }

    function verify(bytes memory flag) external returns(bool){
        uint size = getSize(_target);
        require(uint(uint8(flag[2])) == size-265);
        return _verifier.verify(flag);
    }

    function getSize(address _addr) internal returns (uint) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size;
    }
}