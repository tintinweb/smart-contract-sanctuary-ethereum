/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ForestNotary {

    address public owner;

    mapping(bytes32 => Forest) public forests;

    uint public forestsCount;

    address constant BLANK_ADDRESS = address(0);

    bytes32 constant BLANK_BYTES = bytes32(bytes(''));

    struct Verification {
        uint value;
        uint acquiredAt;
        uint createdAt;
    }

    struct Forest {
        bytes32 name;
        Verification[] verifications;
        uint verificationsCount;
        uint createdAt;
    }

    event ForestRegistered(bytes32 indexed forestName);

    event ForestVerificationAdded(bytes32 indexed forestName, uint value, uint acquiredAt);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "The sender is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function registerForest(bytes32 _forestName) public onlyOwner {
        validateBytes(_forestName);
        require(forests[_forestName].createdAt == 0, "The forest is already registered");
        forests[_forestName].name = _forestName;
        forests[_forestName].createdAt = block.timestamp;
        forestsCount++;
        emit ForestRegistered(_forestName);
    }

    function getForestInfo(bytes32 _forestName) public view returns (bytes32, uint, uint) {
        validateForestExist(_forestName);
        Forest storage forest = forests[_forestName];
        return (forest.name, forest.createdAt, forest.verificationsCount);
    }

    function addVerification(bytes32 _forestName, uint _value, uint _acquiredAt) public onlyOwner {
        validateForestExist(_forestName);
        Verification memory verification = Verification(_value, _acquiredAt, block.timestamp);
        forests[_forestName].verifications.push(verification);
        forests[_forestName].verificationsCount++;
        emit ForestVerificationAdded(_forestName, _value, _acquiredAt);
    }

    function getVerification(bytes32 _forestName, uint _index) public view returns (Verification memory) {
        validateForestExist(_forestName);
        Forest storage forest = forests[_forestName];
        require(_index < forest.verificationsCount, "The forest verification does not exist");
        Verification storage verification = forest.verifications[_index];
        return verification;
    }

    function getVerificationInfo(bytes32 _forestName, uint _index) public view returns (uint, uint, uint) {
        Verification memory verification = getVerification(_forestName, _index);
        return (verification.value, verification.acquiredAt, verification.createdAt);
    }

    function getLastVerification(bytes32 _forestName) public view returns (Verification memory) {
        validateForestExist(_forestName);
        Forest storage forest = forests[_forestName];
        require(forest.verificationsCount < 1, "The forest verification does not exist");
        Verification storage verification = forest.verifications[forest.verificationsCount - 1];
        return verification;
    }

    function getLastVerificationInfo(bytes32 _forestName) public view returns (uint, uint, uint) {
        Verification memory verification = getLastVerification(_forestName);
        return (verification.value, verification.acquiredAt, verification.createdAt);
    }

    function withdrawAll(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }

    function destroySmartContract(address payable _to) public onlyOwner {
        selfdestruct(_to);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        validateAddress(_newOwner);
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function validateAddress(address _addr) internal pure {
        require(_addr != BLANK_ADDRESS, "Not valid address");
    }

    function validateBytes(bytes32 _bytes) internal pure {
        require(_bytes != BLANK_BYTES, "Not valid bytes");
    }

    function validateForestExist(bytes32 _forestName) internal view {
        require(forests[_forestName].createdAt != 0, "The forest is not registered");
    }

    function stringToBytes(string memory _text) public pure returns(bytes32) {
        return (bytes32(bytes(_text)));
    }
}