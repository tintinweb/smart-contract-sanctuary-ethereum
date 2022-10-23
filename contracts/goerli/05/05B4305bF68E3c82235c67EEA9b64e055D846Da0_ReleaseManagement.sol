/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

error Account__AlreadyRegistered();

contract ReleaseManagement {
    // State Variables
    address private immutable owner;

    // Arrays
    Account[] account;
    Data[] releaseData;

    // Mappings
    mapping(address => bool) private registered;
    mapping(string => uint256) private nameToId;
    mapping(address => uint256) private addressToRank;
    mapping(address => uint256) private addressToId;

    // Structs
    // Account data
    struct Account {
        string name;
        address walletaddress;
        string position;
        string department;
        uint256 rank;
    }
    // Release request data
    struct Data {
        uint256 id;
        string project;
        string name;
        string files;
        string filepath;
        string filehash;
        string description;
        string status;
        string reasoning;
        string approver;
        address walletaddress;
    }

    // Constructor
    constructor() {
        // defines the deployer/owner of the contract
        owner = msg.sender;
    }

    // Functions
    // Accountcreation
    function createAccount(string memory _name, string memory _department)
        public
    {
        // checks if an account has already been created
        if (registered[msg.sender]) {
            revert Account__AlreadyRegistered();
        }
        // Owner = "Chef" and everyone else = "Mitarbeiter"
        if (msg.sender == owner) {
            account.push(Account(_name, msg.sender, "Chef", _department, 4));
        } else {
            account.push(
                Account(_name, msg.sender, "Mitarbeiter", _department, 0)
            );
        }
        registered[msg.sender] = true;
        nameToId[_name] = account.length - 1;
        addressToRank[msg.sender] = 0;
        addressToId[msg.sender] = account.length - 1;
    }

    // Change Name or Unit of an Account
    function changeAccountData(
        uint256 _id,
        string memory _name,
        string memory _department
    ) public onlyRegistered {
        require(
            account[_id].walletaddress == msg.sender,
            "Sender has no auhtorization for this function!"
        );
        account[_id].name = _name;
        account[_id].department = _department;
    }

    // Change rank, different ranks have different rights
    // restricted to accounts (rank 3 or higher)  and owner
    function changeRank(string memory _name, uint256 _rank)
        public
        onlyRank3orAbove
    {
        account[nameToId[_name]].rank = _rank;
        if (_rank == 0) {
            account[nameToId[_name]].position = "Mitarbeiter";
        } else if (_rank == 1) {
            account[nameToId[_name]].position = "Praktikant";
        } else if (_rank == 2) {
            account[nameToId[_name]].position = "Werkstudent";
        } else if (_rank == 3) {
            account[nameToId[_name]].position = "Abteilungsleiter";
        } else if (_rank == 4) {
            account[nameToId[_name]].position = "Chef";
        }

        addressToRank[account[nameToId[_name]].walletaddress] = _rank;
    }

    // Function to enter the request data
    function createRequest(
        string memory _project,
        string memory _name,
        string memory _files,
        string memory _filepath,
        string memory _filehash,
        string memory _description,
        string memory _approver
    ) public onlyRegistered {
        releaseData.push(
            Data(
                releaseData.length,
                _project,
                _name,
                _files,
                _filepath,
                _filehash,
                _description,
                "Pending",
                "Pending",
                _approver,
                msg.sender
            )
        );
    }

    // Remove Request,
    // only the creator of the request ist authorizied
    function deleteRequest(uint256 _id) public onlyRegistered {
        require(
            releaseData[_id].walletaddress == msg.sender,
            "Sender has no authorization for this function!"
        );
        require(
            (keccak256(bytes(releaseData[_id].status)) ==
                (keccak256(bytes("Pending")))),
            "Request can not be deleted! Status has already changed!"
        );
        for (uint i = _id; i < releaseData.length - 1; i++) {
            releaseData[i] = releaseData[i + 1];
            releaseData[i].id = i;
        }
        releaseData.pop();
    }

    // Change the approval state of the releaseData array
    function changeApprovalDecision(
        uint256 _id,
        string memory _status,
        string memory _reasoning
    ) public onlyRank3orAbove {
        releaseData[_id].status = _status;
        releaseData[_id].reasoning = _reasoning;
    }

    // Getter Functions
    function showAccount() public view returns (Account[] memory) {
        return account;
    }

    function showData() public view returns (Data[] memory) {
        return releaseData;
    }

    function alreadyRegistered() public view returns (bool) {
        return registered[msg.sender];
    }

    function accountId() public view returns (uint256) {
        return addressToId[msg.sender];
    }

    function accessRights() public view returns (bool) {
        if (addressToRank[msg.sender] >= 3 || msg.sender == owner) {
            return true;
        } else {
            return false;
        }
    }

    // requirement for the use of specific functions
    modifier onlyRank3orAbove() {
        require(
            (addressToRank[msg.sender] >= 3) || msg.sender == owner,
            "Sender has no authorization for this function!"
        );
        _;
    }
    modifier onlyRegistered() {
        require(
            registered[msg.sender],
            "Sender is not registered! Please create an account!"
        );
        _;
    }
}