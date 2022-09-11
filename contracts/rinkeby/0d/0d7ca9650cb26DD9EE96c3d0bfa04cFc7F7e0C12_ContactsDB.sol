// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract ContactsDB {
    address internal owner;
    address[] internal ContactsAdmins;
    address[] internal PartiesAddresses;
    string[] public Countries;
    string[] public Roles;
    mapping(uint8 => mapping(uint8 => address[])) public RoleCountry_Address;
    mapping(uint8 => mapping(uint8 => address[])) public CountryCountry_Address;
    mapping(address => PartyInfo) parties;
    mapping(address => bool) public IsUserActive;

    constructor() {
        owner = msg.sender;
        Roles.push("NONE");
        Roles.push("CUSTOMER");
        Roles.push("PRODUCER");
        Roles.push("BANK");
        Roles.push("SHIPPER");
        Roles.push("CUSTOMS");
        Roles.push("INSPECTOR");
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

    function AddCountries(string[] memory _Countries) public onlyOwner {
        require(_Countries.length > 0);
        for (uint256 i = 0; i < _Countries.length; i++) {
            if (bytes(_Countries[i]).length > 0) {
                Countries.push(_Countries[i]);
            }
        }
    }

    function ActivateUser(address _address) public onlyOwner {
        IsUserActive[_address] = true;
    }

    function AddRoles(string[] memory _Roles) public onlyOwner {
        require(_Roles.length > 0);
        for (uint256 i = 0; i < _Roles.length; i++) {
            if (bytes(_Roles[i]).length > 0) {
                Roles.push(_Roles[i]);
            }
        }
    }

    function AddParties(
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
                    RoleCountry_Address[_PartyInfo[i].RoleID][
                        _PartyInfo[i].CountriesIDs[ii]
                    ].push(_PartyAddresses[i]);
                }
                newPrty.PublicKey = _PartyInfo[i].PublicKey;
                PartiesAddresses.push(_PartyAddresses[i]);
                IsUserActive[_PartyAddresses[i]] = true;
            }
        }
    }

    function AddMe(PartyInfo memory _PartyInfo) public {
        bool AddExist = false;
        for (uint256 i_add = 0; i_add < PartiesAddresses.length; i_add++) {
            if (PartiesAddresses[i_add] == msg.sender) {
                AddExist = true;
            }
        }
        require(AddExist == false, "Address already exist!");
        PartyInfo storage newPrty = parties[msg.sender];
        newPrty.RoleID = _PartyInfo.RoleID;
        for (uint256 ii = 0; ii < _PartyInfo.CountriesIDs.length; ii++) {
            newPrty.CountriesIDs.push(_PartyInfo.CountriesIDs[ii]);
            RoleCountry_Address[_PartyInfo.RoleID][_PartyInfo.CountriesIDs[ii]]
                .push(msg.sender);
        }
        newPrty.PublicKey = _PartyInfo.PublicKey;
        PartiesAddresses.push(msg.sender);
        IsUserActive[msg.sender] = false;
    }

    function AddCountryCountry_Address(
        address _PartyAddress,
        uint8[] memory _SCountriesIDs,
        uint8[] memory _DCountriesIDs
    ) public onlyOwner {
        require(_SCountriesIDs.length > 0);
        require(_SCountriesIDs.length == _DCountriesIDs.length);
        bool AddExist = false;
        for (uint256 i_add = 0; i_add < PartiesAddresses.length; i_add++) {
            if (PartiesAddresses[i_add] == _PartyAddress) {
                AddExist = true;
            }
        }
        require(AddExist == true);
        for (uint256 i = 0; i < _SCountriesIDs.length; i++) {
            CountryCountry_Address[_SCountriesIDs[i]][_DCountriesIDs[i]].push(
                _PartyAddress
            );
        }
    }

    ////////////////////////////////////
    function AddCountriesIDsToParty(
        address _PartyAddress,
        uint8[] memory _CountriesIDs
    ) public onlyOwner {
        require(_CountriesIDs.length > 0);
        bool AddExist = false;
        for (uint256 i_add = 0; i_add < PartiesAddresses.length; i_add++) {
            if (PartiesAddresses[i_add] == _PartyAddress) {
                AddExist = true;
            }
        }
        require(AddExist == true);
        PartyInfo storage EditPrty = parties[_PartyAddress];
        bool coun_exist = false;
        for (uint256 i = 0; i < _CountriesIDs.length; i++) {
            for (uint8 i2 = 0; i2 < uint8(EditPrty.CountriesIDs.length); i2++) {
                if (EditPrty.CountriesIDs[i2] == _CountriesIDs[i]) {
                    coun_exist = true;
                }
            }
            if (coun_exist == false) {
                EditPrty.CountriesIDs.push(_CountriesIDs[i]);
            } else {
                coun_exist = false;
            }
        }
    }

    ///////////////////////////////////
    function DelCountriesIDsFromParty(
        address _PartyAddress,
        uint8[] memory _CountriesIDs
    ) public onlyOwner {
        require(_CountriesIDs.length > 0);
        PartyInfo storage EditPrty = parties[_PartyAddress];

        for (uint256 i = 0; i < _CountriesIDs.length; i++) {
            uint8[] memory _CountriesIDs_temp = EditPrty.CountriesIDs;
            delete EditPrty.CountriesIDs;
            for (uint256 b = 0; b < _CountriesIDs_temp.length; b++) {
                if (_CountriesIDs_temp[b] != _CountriesIDs[i]) {
                    EditPrty.CountriesIDs.push(_CountriesIDs_temp[b]);
                }
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

    ///////////////////////////////////////////////////////////////////////
    function getCountries() public view returns (string[] memory) {
        return Countries;
    }

    //////////////////////////////////////////////////////////////////////
    function getRoles() public view returns (string[] memory) {
        return Roles;
    }

    ///////////////////////////////////////////////////////////////////
    function CanUserCreate(address _Address) public view returns (bool) {
        PartyInfo memory s = parties[_Address];
        if (
            (IsUserActive[_Address] == true && s.RoleID == 1) ||
            (IsUserActive[_Address] == true && s.RoleID == 2)
        ) {
            return true;
        } else {
            return false;
        }
    }

    function getAddressByRoleCountry(uint8 _RoleID, uint8 _CountriesID)
        public
        view
        returns (address[] memory)
    {
        return (RoleCountry_Address[_RoleID][_CountriesID]);
    }

    function getAddressByCountryCountry(
        uint8 _CCountriesID,
        uint8 _DCountriesID
    ) public view returns (address[] memory) {
        return (CountryCountry_Address[_CCountriesID][_DCountriesID]);
    }

    function IsAddressRole(address _Address, uint8 _Role)
        public
        view
        returns (bool)
    {
        PartyInfo memory s = parties[_Address];
        if ((IsUserActive[_Address] == true && s.RoleID == _Role)) {
            return true;
        } else {
            return false;
        }
    }

    //////////////////////////////////////////////////////////
    function FactoryReset() public onlyOwner {
        PartyInfo memory s;
        for (uint256 i = 0; i < PartiesAddresses.length; i++) {
            parties[PartiesAddresses[i]] = s;
        }
        for (uint256 i = 0; i < PartiesAddresses.length; i++) {
            IsUserActive[PartiesAddresses[i]] = false;
        }
        for (uint256 i = 0; i < Roles.length; i++) {
            for (uint256 i2 = 0; i2 < Countries.length; i2++) {
                RoleCountry_Address[uint8(i)][uint8(i2)] = new address[](0);
            }
        }
        for (uint256 i = 0; i < Countries.length; i++) {
            for (uint256 i2 = 0; i2 < Countries.length; i2++) {
                CountryCountry_Address[uint8(i)][uint8(i2)] = new address[](0);
            }
        }
        ContactsAdmins = new address[](0);
        PartiesAddresses = new address[](0);
        Countries = new string[](0);
        Roles = new string[](0);
    }
}