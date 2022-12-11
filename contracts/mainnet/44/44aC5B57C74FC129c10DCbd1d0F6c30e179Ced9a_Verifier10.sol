// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IVerifier {
    function verify(bytes memory flag) external returns(bool);
}

contract Verifier10 {
    address public alice;
    IVerifier _verifier;
    uint value = 0x55;

    constructor(address verifier) {
        _verifier = IVerifier(verifier);
    }

    function verify(bytes memory flag) external returns(bool){
        require(uint(uint8(flag[9])) == value);
        return _verifier.verify(flag);
    }
    function verify1(bytes memory flag) external returns(bool){
        require(uint(uint8(flag[9])) == 0x55);
        return _verifier.verify(flag);
    }
    function verify2(bytes memory flag) external returns(bool){
        require(uint(uint8(flag[9])) == 0x44);
        return _verifier.verify(flag);
    }
    function verify3(bytes memory flag) external returns(bool){
        require(uint(uint8(flag[9])) == 0x33);
        return _verifier.verify(flag);
    }
    function verify4(bytes memory flag) external returns(bool){
        require(uint(uint8(flag[9])) == 0x61);
        return _verifier.verify(flag);
    }
    function verify5(bytes memory flag) external returns(bool){
        require(uint(uint8(flag[9])) == 0x38);
        return _verifier.verify(flag);
    }
    function verify6(bytes memory flag) external returns(bool){
        require(uint(uint8(flag[9])) == 0x70);
        return _verifier.verify(flag);
    }
    fallback() external {
        bytes memory flag = abi.decode(msg.data[4:], (bytes));
        require(uint(uint8(flag[9])) == 0x35);
    }
}