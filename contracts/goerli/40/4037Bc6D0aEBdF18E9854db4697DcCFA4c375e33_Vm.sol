// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

error Vm_Not_Authorized();
error Vm_Not_Registered();
error Vm_Already_Voted();
error Vm_Account_Mismatch();

contract Vm {
    address public manager;

    struct voter {
        string name;
        string dob;
        address account;
        uint256 aadhar;
    }

    struct canidate {
        string name;
        string party;
        uint256 vote;
    }

    uint256 public canidateCount;
    mapping(uint256 => canidate) public canidatesList;

    uint256 public voterCount;
    mapping(uint256 => voter) public votersList;

    mapping(uint256 => bool) public registeredVoters;
    mapping(uint256 => bool) public votedList;

    constructor(address managerAddress) {
        manager = managerAddress;
    }

    modifier restrictedToManager() {
        if (msg.sender != manager) {
            revert Vm_Not_Authorized();
        }
        _;
    }

    function addCanidate(string memory name, string memory party) public restrictedToManager {
        canidate storage newCanidate = canidatesList[canidateCount];
        canidateCount++;

        newCanidate.name = name;
        newCanidate.party = party;
        newCanidate.vote = 0;
    }

    function addVoter(
        string memory name,
        string memory dob,
        address account,
        uint256 aadhar
    ) public restrictedToManager {
        voter storage newVoter = votersList[aadhar];
        voterCount++;

        newVoter.name = name;
        newVoter.dob = dob;
        newVoter.account = account;
        newVoter.aadhar = aadhar;
    }

    function vote(uint256 aadhar, uint256 canidateID) public {
        if (votersList[aadhar].aadhar != aadhar) {
            revert Vm_Not_Registered();
        }

        if (votedList[aadhar]) {
            revert Vm_Already_Voted();
        }
        votedList[aadhar] = true;

        if (votersList[aadhar].account != msg.sender) {
            revert Vm_Account_Mismatch();
        }

        canidate storage selectedCanidate = canidatesList[canidateID];
        selectedCanidate.vote++;
    }

    function getManagerAddress() public view returns (address) {
        return manager;
    }
}