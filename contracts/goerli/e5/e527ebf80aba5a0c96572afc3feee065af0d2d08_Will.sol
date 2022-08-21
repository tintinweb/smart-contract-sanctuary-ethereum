// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract Will {

    address public Owner;
    address private guardian;
    uint256 public expiration;
    bytes32[] private Keys;

    modifier onlyOwner() {
        require ( msg.sender == Owner, "Not owner!" );
        _;
    }

    modifier expiredCheck() {
        require ( block.timestamp < expiration, "Not expired!" );
        _;
    }

    modifier onlyGuardian() {
        require (msg.sender == guardian, "Only Guardian!");
        _;
    }

    constructor(address _owner, address _guardian, uint256 _expiration) {
        Owner = _owner;
        guardian = _guardian;
        expiration = block.timestamp + _expiration;
    }

    function timeLeft() public view onlyOwner returns (uint256) {
        return expiration - block.timestamp;
    }

    function setExtension(uint256 _extension) external onlyOwner expiredCheck {
        expiration = block.timestamp + timeLeft() + _extension;
    }

    function getGuardian() external view onlyOwner returns (address) {
        return guardian;
    }

    function setKey(bytes32 _key) external onlyOwner {
        Keys.push(_key);
    }

    function getKeys() external view onlyGuardian expiredCheck returns (bytes32[] memory) {
        return Keys;
    }
}