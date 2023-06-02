/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

pragma solidity ^0.8.0;

contract RegressionTest {
    address public addressVariable;
    bool public boolVariable;
    string public stringVariable;
    uint256 public uintVariable;
    bytes public bytesVariable;
    bytes32[] public bytes32ArrayVariable;

    function setAddressVariable(address _value) public {
        addressVariable = _value;
    }

    function setBoolVariable(bool _value) public {
        boolVariable = _value;
    }

    function setStringVariable(string memory _value) public {
        stringVariable = _value;
    }

    function setUintVariable(uint256 _value) public {
        uintVariable = _value;
    }

    function setBytesVariable(bytes memory _value) public {
        bytesVariable = _value;
    }

    function setBytes32ArrayVariable(bytes32[] memory _value) public {
        bytes32ArrayVariable = _value;
    }

    function getAddressVariable() public view returns (address) {
        return addressVariable;
    }

    function getBoolVariable() public view returns (bool) {
        return boolVariable;
    }

    function getStringVariable() public view returns (string memory) {
        return stringVariable;
    }

    function getUintVariable() public view returns (uint256) {
        return uintVariable;
    }

    function getBytesVariable() public view returns (bytes memory) {
        return bytesVariable;
    }

    function getBytes32ArrayVariable() public view returns (bytes32[] memory) {
        return bytes32ArrayVariable;
    }
}