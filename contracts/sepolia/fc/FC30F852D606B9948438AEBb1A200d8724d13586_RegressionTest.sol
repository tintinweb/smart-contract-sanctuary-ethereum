/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

pragma solidity ^0.8.0;

contract RegressionTest {
    address public addressVariable;
    address[] public addressVariableArray;
    bool public boolVariable;
    string public stringVariable;
    uint256 public uintVariable;
    bytes public bytesVariable;
    bytes32[] public bytes32ArrayVariable;

    address immutable public owner;
    uint256 immutable public creationTime;
    uint256 public data;

    constructor(uint256 _data) {
        owner = msg.sender;
        creationTime = block.timestamp;
        data = _data;
    }

    function writeData() external payable {
        // Perform the desired write operation here

        // Example: Update the data variable with the value sent
        data = msg.value;
    }

    function setData(uint256 _newData) external {
        require(msg.sender == owner, "Only the contract owner can modify the data.");
        require(data == 0, "Data can only be set once.");
        data = _newData;
    }

    function setAddressVariable(address _value) public {
        addressVariable = _value;
    }

     function setAddressArrayVariable(address[] memory _value) public {
        addressVariableArray = _value;
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
    
    function getAddressVariableArray() public view returns (address[] memory) {
        return addressVariableArray;
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