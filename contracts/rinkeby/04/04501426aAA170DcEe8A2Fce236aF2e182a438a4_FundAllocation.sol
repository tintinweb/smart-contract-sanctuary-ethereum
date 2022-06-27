/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.15;

contract FundAllocation {
    uint256 public provinceIndex = 0;
    uint256 public contractorIndex = 0;
    address private admin;

    struct Province {
        uint256 id;
        string name;
        uint256 stateNo;
        string capital;
        address wallet;
        bool isApproved;
        bool isRegistered;
    }

    struct Contractor {
        uint256 id;
        string name;
        bool isApproved;
        bool isRegistered;
    }


    address[] public provinceList;
    address[] public contractorList;

    mapping(address => Province) provinces;
    mapping(address => Contractor) contractors;
    mapping(address => bool) isProvince;
    mapping(address => bool) isContractor;

    constructor() {
        admin = msg.sender;
    }

    modifier excludeAdmin(address _address) {
        require(_address != admin, "Admin cannot be registered as Province");
        _;
    }

    modifier verifierAdmin(address _address) {
        require(_address == admin, "Only Admin can verify.");
        _;
    }

    modifier verifierProvince(address _address) {
        require(
            (isProvince[_address] && provinces[_address].isApproved),
            "Only approved Province can verify."
        );
        _;
    }

    modifier registeredAndApprovedProvince(address _address) {
        require(
            (provinces[_address].isRegistered &&
                provinces[_address].isApproved),
            "You are not registered or approved province"
        );
        _;
    }

    function findUserRole(address _address)
        public
        view
        returns (string memory user)
    {
        if (_address == admin) {
            return "admin";
        } else if (isProvince[_address] == true) {
            return "province";
        } else if (isContractor[_address] == true) {
            return "contractor";
        } else {
            return "unAuthorized";
        }
    }

    function registerProvince(
        string memory _name,
        uint256 _stateNo,
        string memory _capital
    ) public excludeAdmin(msg.sender) returns (bool) {
        require(bytes(_name).length > 0);
        require(_stateNo > 0);
        require(bytes(_capital).length > 0);
        address _address = msg.sender;

        provinceList.push(_address);
        provinceIndex += 1;

        provinces[_address].name = _name;
        provinces[_address].stateNo = _stateNo;
        provinces[_address].capital = _capital;
        provinces[_address].wallet = _address;
        provinces[_address].isRegistered = true;
        isProvince[_address] = true;
        return true;
    }

    function verifyProvince(address _address)
        public
        verifierAdmin(msg.sender)
        returns (bool)
    {
        require(
            !provinces[_address].isApproved,
            "The province is already approved"
        );
        provinces[_address].isApproved = true;
        return true;
    }

    function allProvince(uint256 _id)
        public
        view
        returns (
            string memory,
            uint256,
            string memory,
            address,
            bool,
            bool
        )
    {
        address _address = provinceList[_id];
        Province memory currentProvince = provinces[_address];
        return (
            currentProvince.name,
            currentProvince.stateNo,
            currentProvince.capital,
            currentProvince.wallet,
            currentProvince.isRegistered,
            currentProvince.isApproved
        );
    }

    function myProvince()
        public
        view
        registeredAndApprovedProvince(msg.sender)
        returns (
            uint256,
            string memory,
            uint256,
            string memory
        )
    {
        Province memory currentProvince = provinces[msg.sender];
        return (
            currentProvince.id,
            currentProvince.name,
            currentProvince.stateNo,
            currentProvince.capital
        );
    }

    function registerContractor(string memory _name)
        public
        excludeAdmin(msg.sender)
    {
        require(bytes(_name).length > 0);
        address _address = msg.sender;

        contractorList.push(_address);
        contractorIndex += 1;

        contractors[_address].name = _name;
        contractors[_address].isRegistered = true;
        isContractor[_address] = true;
    }

    function verifyContractor(address _address)
        public
        verifierProvince(msg.sender)
        returns (bool)
    {
        require(
            !contractors[_address].isApproved,
            "The Contractor is already approved"
        );
        provinces[_address].isApproved = true;
        return true;
    }

    function allContractor(uint256 _id)public view returns(string memory,bool,bool){
        address _address=contractorList[_id];
        Contractor memory currentContractor=contractors[_address];
        return (currentContractor.name,currentContractor.isRegistered,currentContractor.isApproved);

    }

    // function getTotalStates() public view returns(uint256){
    //     return stateList.length;
    // }

    // function stateLogin() public{
    //     if(states[msg.sender].isApproved == true ){

    //     }
    // }
}