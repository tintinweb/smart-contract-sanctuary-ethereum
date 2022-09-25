// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

contract Converter {
    event Convert(address from, uint time);

// NO floating-point number >> UPGADE ON JS
    function ethToWei(uint _num) public pure returns(uint){
        return _num * 10 ** 18;
    }
    function weiToEth(uint _num) public pure returns(uint){
        return _num / 10 ** 18;
    }

    // Function Selector
    function funcSelector(string memory _funcName) public pure returns(bytes4){
        return bytes4(keccak256(bytes(_funcName)));
    }

    // Get Hash Kechack
    function getHash(string memory _str) public pure returns(bytes32){
        return keccak256(bytes(_str));
    }

    // Bytes to number
    function numToBytes(uint _num) public pure returns(bytes memory){
        return abi.encode(_num);
    }
    function bytesToNum(bytes calldata _bytes) public pure returns(uint x){
        (x) = abi.decode(_bytes, (uint));
    }

    // Bytes to string
    function strToBytes(string calldata _str) public pure returns(bytes memory){
        return abi.encode(_str);
    }
    function bytesToStr(bytes calldata _bytes) public pure returns(uint x){
        (x) = abi.decode(_bytes, (uint));
    }
}