//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";

contract FrameDataStoreOwnable is Ownable {
    struct ContractData {
        address rawContract;
        uint128 size;
        uint128 offset;
    }

    struct ContractDataPages {
        uint256 maxPageNumber;
        bool exists;
        mapping(uint256 => ContractData) pages;
    }

    mapping(string => ContractDataPages) internal _contractDataPages;

    mapping(address => bool) internal _controllers;

    bool public isLocked = false;

    string public name;
    string public version;

    constructor() {
    }

    function saveData(
        string memory _key,
        uint128 _pageNumber,
        bytes memory _b
    ) public onlyOwner {
        require(
            _b.length < 24576,
            "FrameDataStore: Exceeded 24,576 bytes max contract size"
        );

        require(
            !hasKey(_key) || getMaxPageNumber(_key) == _pageNumber - 1, 
            "FrameDataStore: Cannot overwrite page or skip next page for key"
        );

        require(
            !isLocked, 
            "FrameDataStore: Contract locked"
        );

        // Create the header for the contract data
        bytes memory init = hex"610000_600e_6000_39_610000_6000_f3";
        bytes1 size1 = bytes1(uint8(_b.length));
        bytes1 size2 = bytes1(uint8(_b.length >> 8));
        init[2] = size1;
        init[1] = size2;
        init[10] = size1;
        init[9] = size2;

        // Prepare the code for storage in a contract
        bytes memory code = abi.encodePacked(init, _b);

        // Create the contract
        address dataContract;
        assembly {
            dataContract := create(0, add(code, 32), mload(code))
            if eq(dataContract, 0) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // Store the record of the contract
        _saveDataForDeployedContract(
            _key,
            _pageNumber,
            dataContract,
            uint128(_b.length),
            0
        );
    }

    function _saveDataForDeployedContract(
        string memory _key,
        uint256 _pageNumber,
        address dataContract,
        uint128 _size,
        uint128 _offset
    ) internal {
        // Pull the current data for the contractData
        ContractDataPages storage _cdPages = _contractDataPages[_key];

        // Store the maximum page
        if (_cdPages.maxPageNumber < _pageNumber) {
            _cdPages.maxPageNumber = _pageNumber;
        }

        // Keep track of the existance of this key
        _cdPages.exists = true;

        // Add the page to the location needed
        _cdPages.pages[_pageNumber] = ContractData(
            dataContract,
            _size,
            _offset
        );
    }

    function setName(string memory _name) public {
        require(bytes(name).length < 3, "FrameDataStore: Name already set");
        name = _name;
    }

    function setVersion(string memory _version) public {
        require(bytes(version).length < 3, "FrameDataStore: Version already set");
        version = _version;
    }

    function getSizeBetweenPages(
        string memory _key,
        uint256 _startPage,
        uint256 _endPage
    ) public view returns (uint256) {
        // For all data within the contract data pages, iterate over and compile them
        ContractDataPages storage _cdPages = _contractDataPages[_key];

        // Determine the total size
        uint256 totalSize;
        for (uint256 idx = _startPage; idx <= _endPage; idx++) {
            totalSize += _cdPages.pages[idx].size;
        }

        return totalSize;
    }

    function getMaxPageNumber(string memory _key)
        public
        view
        returns (uint256)
    {
        return _contractDataPages[_key].maxPageNumber;
    }

    function getData(
        string memory _key,
        uint256 _startPage,
        uint256 _endPage
    ) public view returns (bytes memory) {
        // Get the total size
        uint256 totalSize = getSizeBetweenPages(_key, _startPage, _endPage);

        // Create a region large enough for all of the data
        bytes memory _totalData = new bytes(totalSize);

        // Retrieve the pages
        ContractDataPages storage _cdPages = _contractDataPages[_key];

        uint256 endPageNumber = _endPage;

        // For each page, pull and compile
        uint256 currentPointer = 32;
        for (uint256 idx = _startPage; idx <= endPageNumber; idx++) {
            ContractData storage dataPage = _cdPages.pages[idx];
            address dataContract = dataPage.rawContract;
            uint256 size = uint256(dataPage.size);
            uint256 offset = uint256(dataPage.offset);

            // Copy directly to total data
            assembly {
                extcodecopy(
                    dataContract,
                    add(_totalData, currentPointer),
                    offset,
                    size
                )
            }

            // Update the current pointer
            currentPointer += size;
        }

        return _totalData;
    }

    function getAllDataFromPage(
        string memory _key,
        uint256 _startPage
    ) public view returns (bytes memory) {
        ContractDataPages storage _cdPages = _contractDataPages[_key];
        return getData(_key, _startPage, _cdPages.maxPageNumber);
    }

    function hasKey(string memory _key) public view returns (bool) {
        return _contractDataPages[_key].exists;
    }

    function lock() public onlyOwner {
        require(!isLocked, "FrameDataStore: Contract already locked");
        isLocked = true;
    }
}