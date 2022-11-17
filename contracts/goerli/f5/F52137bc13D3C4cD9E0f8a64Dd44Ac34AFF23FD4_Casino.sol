/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface ChipInterface {
    function mint(address _to, uint256 _amount) external;
    function burn(address _to, uint256 _amount) external;
}

contract Casino {
    ChipInterface public chipContract;

    address payable owner;

    uint256 public membershipFee = 1 * 10**16;
    uint48 public initialChipCount = 1000;

    event ChipsGiven(address indexed user, uint48 amount, uint48 timestamp);
    event ChipsTaken(address indexed user, uint48 amount, uint48 timestamp);
    event NewMember(
        address indexed player,
        uint48 timestamp,
        uint48 initialChipCount
    );
    address[] memberAddresses;
    mapping(address => bool) public members;
    mapping(address => bool) games;

    constructor(address chips) {
        chipContract = ChipInterface(chips);
        owner = payable(msg.sender);
    }

    modifier noReentry {
        require(!members[msg.sender], "You are already a member of the casino.");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender], "Only members can use this function.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can use this function.");
        _;
    }

    modifier onlyGames() {
        require(games[msg.sender], "Only games can use this function.");
        _;
    }

    function transferOwnership(address payable newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setChipContract(address newContract, bool supplyMembers)
        external
        onlyOwner
    {
        chipContract = ChipInterface(newContract);
        if (supplyMembers) {
            for (uint256 i = memberAddresses.length - 1; i >= 0; i--) {
                chipContract.mint(memberAddresses[i], initialChipCount);
            }
        }
    }

    function setInitialChipCount(uint48 newChipCount) external onlyOwner {
        initialChipCount = newChipCount;
    }

    function setMembershipFee(uint256 fee) external onlyOwner {
        membershipFee = fee;
    }

    function joinCasino() external payable noReentry {
        require(msg.value == membershipFee, "Must send membershipFee");
        owner.transfer(msg.value);
        memberAddresses.push(msg.sender);
        members[msg.sender] = true;
        chipContract.mint(msg.sender, initialChipCount);
        emit NewMember(msg.sender, uint48(block.timestamp), initialChipCount);
    }

    function giveChips(address to, uint48 amount) external onlyGames {
        chipContract.mint(to, amount);
        emit ChipsGiven(to, amount, uint48(block.timestamp));
    }

    function takeChips(address from, uint48 amount) external onlyGames {
        chipContract.burn(from, amount);
        emit ChipsTaken(from, amount, uint48(block.timestamp));
    }

    function addGame(address game) external onlyOwner {
        games[game] = true;
    }

    function removeGame(address game) external onlyOwner {
        games[game] = false;
    }

    function isGame(address _address) public view returns (bool) {
        return games[_address];
    }

    function isMember(address _address) public view returns (bool) {
        return members[_address];
    }
}