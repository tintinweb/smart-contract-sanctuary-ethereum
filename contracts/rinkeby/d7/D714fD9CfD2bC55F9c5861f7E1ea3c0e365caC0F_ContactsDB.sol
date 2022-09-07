// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract ContactsDB {
    address internal owner;
    address[] internal ContactsAdmins;
    address[] internal PartiesAddresses;
    string[] public Countries;
    string[] public Roles;
    ////////////////////////////////////////////////////////
    mapping(address => bytes32) internal AddressToPub;
    mapping(address => uint256) internal AddressToRole;
    mapping(address => uint256[]) internal AddressToCountries;
    /////////////////////////////////////////////
    mapping(address => PartyInfo) parties;

    constructor() public {
        owner = msg.sender;
    }

    struct PartyInfo {
        uint8 RoleID;
        uint8[] CountriesIDs;
        bytes32 PublicKey;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function AddParty(
        address[] memory _PartyAddresses,
        PartyInfo[] memory _PartyInfo
    ) public onlyOwner {
        require(_PartyAddresses.length == _PartyInfo.length);
        for (uint256 i = 0; i < _PartyAddresses.length; i++) {
            PartyInfo storage newPrty = parties[_PartyAddresses[i]];
            newPrty.RoleID = _PartyInfo[i].RoleID;

            for (uint256 ii = 0; ii < _PartyInfo[i].CountriesIDs.length; ii++) {
                newPrty.CountriesIDs[ii] = _PartyInfo[i].CountriesIDs[ii];
            }
            newPrty.PublicKey = _PartyInfo[i].PublicKey;

            PartiesAddresses.push(_PartyAddresses[i]);
        }
    }

    function AddCountriesIDsToParty(
        address _PartyAddress,
        uint8[] memory _CountriesIDs
    ) public onlyOwner {
        require(_CountriesIDs.length > 0);
        PartyInfo storage EditPrty = parties[_PartyAddress];
        for (uint256 i = 0; i < _CountriesIDs.length; i++) {
            EditPrty.CountriesIDs.push(_CountriesIDs[i]);
        }
    }

    function AddCountries(string[] memory _Countries) public onlyOwner {
        require(_Countries.length > 0);
        for (uint256 i = 0; i < _Countries.length; i++) {
            if (bytes(_Countries[i]).length > 0) {
                Countries.push(_Countries[i]);
            }
        }
    }

    function AddRoles(string[] memory _Roles) public onlyOwner {
        require(_Roles.length > 0);
        for (uint256 i = 0; i < _Roles.length; i++) {
            if (bytes(_Roles[i]).length > 0) {
                Roles.push(_Roles[i]);
            }
        }
    }
}