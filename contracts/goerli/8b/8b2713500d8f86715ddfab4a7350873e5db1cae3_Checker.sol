/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

interface IDataTypesPractice {
    function getInt256() external view returns(int256);
    function getUint256() external view returns(uint256);
    function getIint8() external view returns(int8);
    function getUint8() external view returns(uint8);
    function getBool() external view returns(bool);
    function getAddress() external view returns(address);
    function getBytes32() external view returns(bytes32);
    function getArrayUint5() external view returns(uint256[5] memory);
    function getArrayUint() external view returns(uint256[] memory);
    function getString() external view returns(string memory);

    function getBigUint() external pure returns(uint256);
}

contract Checker {
    function check(address _contract) external view returns(bool) {
        IDataTypesPractice _practice = IDataTypesPractice(_contract);

        if (_practice.getInt256() == 0) return false;
        if (_practice.getUint256() == 0) return false;
        if (_practice.getIint8() == 0) return false;
        if (_practice.getUint8() == 0) return false;
        if (!_practice.getBool()) return false;
        if (_practice.getAddress() == address(0)) return false;
        if (_practice.getBytes32() == bytes32(0x0)) return false;

        uint256[5] memory _arrS = _practice.getArrayUint5();
        for (uint256 i = 0; i < 5; i++) {
            if (_arrS[i] == 0) return false;
        }

        if (_practice.getArrayUint().length == 0) return false;

        if ((keccak256(abi.encodePacked((_practice.getString()))) 
            != keccak256(abi.encodePacked(('Hello World!'))))) return false;

        if (_practice.getBigUint() <= 1000000) return false;

        return true;
    }
}