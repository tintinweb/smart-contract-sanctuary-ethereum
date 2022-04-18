// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Payment {

    uint256 private lockingAmount;
    uint256 private lockingPeriod;

    mapping(string => address) private vanityName;
    mapping (address => uint256) private lockedBalance;
    mapping (address => uint256) private lockedDuration;
    mapping (address => string) private lastVanityName;

    constructor() {
        lockingAmount = 1 ether;
        lockingPeriod = 5 minutes;
    }

    function getVanityOwner(string memory _vanityName) public view returns (address) {
        address currentOwner = vanityName[_vanityName];
        uint256 expiryTime = lockedDuration[currentOwner];
        if (expiryTime < block.timestamp)
            return address(0);
        else
            return vanityName[_vanityName];
    }

    function registerVanityName(string memory _vanityName) public payable {
        require(lockedBalance[msg.sender] == 0, "Registration amount already deposited");
        require(msg.value == lockingAmount, "Deposited amount is invalid");
        require(getVanityOwner(_vanityName) == address(0), "Vanity name is already taken");

        uint256 lockedTime = block.timestamp + lockingPeriod;
        
        vanityName[_vanityName] = msg.sender;
        lockedBalance[msg.sender] = msg.value;
        lockedDuration[msg.sender] = lockedTime;
        lastVanityName[msg.sender] = _vanityName;
    }

    function renewRegistration() public {
        require(lockedBalance[msg.sender] == lockingAmount, "Insufficient locked amount");
        require(getVanityOwner(lastVanityName[msg.sender]) == address(0), "Vanity name is taken");

        vanityName[lastVanityName[msg.sender]] = msg.sender;
        lockedDuration[msg.sender] = block.timestamp + lockingPeriod;
    }

    function withdraw() public {
        require(lockedBalance[msg.sender] > 0, "Insufficient Amount");
        require(lockedDuration[msg.sender] < block.timestamp, "Locked duration is not completed");
        uint256 withdrawalAmount = lockedBalance[msg.sender];
        payable(msg.sender).transfer(withdrawalAmount);
    }

}