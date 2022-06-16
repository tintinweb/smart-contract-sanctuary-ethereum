// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IGovernment.sol";

contract Government is IGovernment {
    
    modifier onlyGovernment() {
        require(msg.sender == _adminAddress, "You're not Government !!!");
        _;
    }

    address private _adminAddress;
    mapping(address => bool) private government;
    mapping(string => address) private addressName;
    mapping(address => string) private nameAddress;
    uint256 private _supply;
    mapping(uint256 => address) private _addressIndex;
    mapping(address => uint256) private _indexAddress;

    constructor() {
        _supply = 0;
        _addressIndex[_supply] = msg.sender;
        _adminAddress = msg.sender;
        addressName["admin"] = msg.sender;
        _indexAddress[msg.sender] = _supply++;
        government[msg.sender] = true;
        nameAddress[msg.sender] = "admin";
    }

    function supply() public view returns (uint256) {
        return _supply;
    }

    function indexAddress(address _address) public view returns (uint256) {
        return _indexAddress[_address];
    }

    function addressIndex(uint256 index) public view returns (address) {
        return _addressIndex[index];
    }

    function unlockAddress(address _address) private {
        government[_address] = true;
    }

    function lockAddress(address _address) private {
        government[_address] = false;
    }

    function deleteAddressName(address _address) private {
        string memory _name = nameAddress[_address];
        addressName[_name] = address(0);
    }

    function setAllowance(address _address, string memory _name) private {
        nameAddress[_address] = _name;
        addressName[_name] = _address;
        _indexAddress[_address] = _supply;
        _addressIndex[_supply++] = _address;
    }

    function addAllowance(address _address, string memory _name) public onlyGovernment {
        require(!government[_address], "Address have already added !!!");
        unlockAddress(_address);
        setAllowance(_address, _name);
        _supply++;
    }

    function changeAllowance(address _address, string memory _name) public onlyGovernment {
        require(government[_address], "Address haven't added yet !!!");
        require(_address != _adminAddress, "Can not change admin !!!");
        deleteAddressName(_address);
        setAllowance(_address, _name);
    }

    function deleteAllowance(address _address) public onlyGovernment {
        require(government[_address], "Address haven't added yet !!!");
        require(_address != _adminAddress, "Can not delete admin !!!");
        lockAddress(_address);
        deleteAddressName(_address);
        uint256 index = indexAddress(_address);
        _addressIndex[index] = address(0);
        _indexAddress[_address] = 666;
        _supply--;
    }
    
    function _isAllowed(address _address) external override view returns (bool) {
        return government[_address];
    }

    function _nameToAddress(string memory _addressName) external override view returns (address) {
        return addressName[_addressName];
    }

    function _addressToName(address _address) external override view returns (string memory) {
        return nameAddress[_address];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGovernment {
    function _isAllowed(address _address) external view returns (bool);

    function _nameToAddress(string memory addressName) external view returns (address);

    function _addressToName(address _address) external view returns (string memory);
}