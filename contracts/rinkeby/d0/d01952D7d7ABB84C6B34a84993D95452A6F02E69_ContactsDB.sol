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

    constructor() {
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
        require(
            _PartyAddresses.length == _PartyInfo.length,
            "Addresses and info arrays should be same count!"
        );
        for (uint256 i = 0; i < _PartyAddresses.length; i++) {
            bool AddExist = false;
            for (uint256 i_add = 0; i_add < PartiesAddresses.length; i_add++) {
                if (PartiesAddresses[i_add] == _PartyAddresses[i]) {
                    AddExist = true;
                }
            }
            if (AddExist == false) {
                PartyInfo storage newPrty = parties[_PartyAddresses[i]];
                newPrty.RoleID = _PartyInfo[i].RoleID;
                for (
                    uint256 ii = 0;
                    ii < _PartyInfo[i].CountriesIDs.length;
                    ii++
                ) {
                    newPrty.CountriesIDs.push(_PartyInfo[i].CountriesIDs[ii]);
                }
                newPrty.PublicKey = _PartyInfo[i].PublicKey;

                PartiesAddresses.push(_PartyAddresses[i]);
            }
        }
    }

    function getParty(address _PartyAddresses)
        public
        view
        returns (
            uint8 _RoleID,
            uint8[] memory _CountriesIDs,
            bytes32 _PublicKey
        )
    {
        PartyInfo memory s = parties[_PartyAddresses];
        return (s.RoleID, s.CountriesIDs, s.PublicKey);
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

    function DelCountriesIDsFromParty(
        address _PartyAddress,
        uint8[] memory _CountriesIDs
    ) public onlyOwner {
        require(_CountriesIDs.length > 0);
        PartyInfo storage EditPrty = parties[_PartyAddress];
        for (uint256 i = 0; i < _CountriesIDs.length; i++) {
            for (uint256 b = 0; b < EditPrty.CountriesIDs.length; b++) {
                delete EditPrty.CountriesIDs[b];
            }
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