/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ThirdParty {
    struct Category {
        uint categoryID;
        string cartegoryName;
        uint[] properties;
        bool visible;
    }
    uint categoryCounter;

    struct Package {
        uint categoryID;
        uint packageID;
        string packageName;
        uint price;
        uint period;
        uint dataLimit;
        bool[] propertyVisible;
    }
    uint packageCounter;

    struct Property {
        uint propertyID;
        string propertyName;
    }
    uint propertyCounter;

    Category[] allCategories;

    // all packages by category ID
    mapping(uint => Package[]) allPackages;

    // all properties
    Property[] allProperties;

    // Categories
    function getAllCategories() public view returns (Category[] memory) {
        Category[] memory allCates = new Category[](categoryCounter);
        for (uint i = 0; i < categoryCounter; i++) {
            allCates[i] = allCategories[i];
        }
        return allCates;
    }

    function addCategory(string memory _newCategory, uint[] memory _properties) public {
        allCategories.push(Category(
            categoryCounter++, 
            _newCategory,
            _properties,
            true
        ));
    }

    function editCategory(
        uint _categoryID,
        string memory _editCategory,
        uint[] memory _properties
    ) public {
        Category storage cartegory = allCategories[_categoryID];
        cartegory.cartegoryName = _editCategory;
        cartegory.properties = _properties;
    }

    function deleteCategory(uint _categoryID) public {
        delete allCategories[_categoryID];
        delete allPackages[_categoryID];
    }

    function getAllProperties() public view returns(Property[] memory) {
        uint propertyNum;
        for(uint i = 0 ; i < allProperties.length ; i++) {
            if(isCompare((allProperties[i].propertyName), "") == false) {
                propertyNum++;
            }
        }
        Property[] memory allProperty = new Property[](propertyNum);
        propertyNum = 0;
        for(uint i = 0 ; i < allProperties.length ; i++) {
            if(isCompare((allProperties[i].propertyName), "") != true) {
                allProperty[propertyNum++] = allProperties[i];
            }
        }
        return allProperty;
    }

    // Property
    function addProperty(string memory _propertyName) public {
        if(allProperties.length > 0) {
            bool flag = false;
            for(uint i = 0 ; i < allProperties.length ; i++) {
                if(isCompare(allProperties[i].propertyName, _propertyName) == true) {
                    flag = true;
                }
            }
            require(flag == false, "can't add same property");
            allProperties.push(Property({
                propertyID: allProperties.length,
                propertyName: _propertyName
            }));
        } else {
            allProperties.push(Property({
                propertyID: allProperties.length,
                propertyName: _propertyName
            }));
        }
    }

    function editProperty(
        uint _propertyID,
        string memory _propertyName
    ) public {
        allProperties[_propertyID].propertyName = _propertyName;
    }

    function deleteProperty(uint _propertyID) public {
        delete allProperties[_propertyID];
    }

    // Packages
    function getPackagesByCategory(uint _categoryID)
        public
        view
        returns (Package[] memory)
    {
        Package[] memory packages = new Package[](
            allPackages[_categoryID].length
        );
        for (uint i = 0; i < allPackages[_categoryID].length; i++) {
            packages[i] = allPackages[_categoryID][i];
        }
        return packages;
    }

    function addPackage(
        uint _categoryID,
        string memory _packageName,
        uint _price,
        uint _period,
        uint _dataLimit,
        bool[] memory _propertyVisible
    ) public {
        allPackages[_categoryID].push(
            Package(
                _categoryID,
                packageCounter++,
                _packageName,
                _price,
                _period,
                _dataLimit,
                _propertyVisible
            )
        );
    }

    function editPackage(
        uint _categoryID,
        uint _packageID,
        string memory _packageName,
        uint _price,
        uint _period,
        uint _dataLimit,
        bool[] memory _propertyVisible
    ) public {
        Package[] storage packagesByCategory = allPackages[_categoryID];

        for (uint i = 0; i < packagesByCategory.length; i++) {
            if (packagesByCategory[i].packageID == _packageID) {
                packagesByCategory[i].packageName = _packageName;
                packagesByCategory[i].price = _price;
                packagesByCategory[i].period = _period;
                packagesByCategory[i].dataLimit = _dataLimit;
                packagesByCategory[i].propertyVisible = _propertyVisible;
            }
        }
    }

    function deletePackage(uint _categoryID, uint _packageID) public {
        Package[] storage packagesByCategory = allPackages[_categoryID];
        uint index = 0;
        for (uint i = 0; i < packagesByCategory.length; i++) {
            if (packagesByCategory[i].packageID == _packageID) {
                // delete packagesByCategory[i];
                index = i;
            }
        }
        for (uint i = index; i< packagesByCategory.length - 1 ; i++){
            packagesByCategory[i] = packagesByCategory[i+1];
        }
        delete packagesByCategory[packagesByCategory.length -1];
    }

    function isCompare(string memory a, string memory b) private pure returns (bool) {
        if (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b))) {
            return true;
        } else {
            return false;
        }
    }
}