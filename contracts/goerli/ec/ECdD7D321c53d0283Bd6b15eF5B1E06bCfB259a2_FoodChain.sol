// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract FoodChain {
    struct MinifiedProduct {
        uint256 id;
        string name;
    }
    struct Set {
        string[] values;
        mapping(string => MinifiedProduct[]) products;
        mapping(string => bool) isIn;
    }
    
    struct Product {
        uint256 id;
        string name;
        string category;
        string origin;
        string farmerName;
        string centralMarketName;
        string authorityAgentName;
        bool hasPesticide;
        uint32 additionTimestamp; // Addition date represented using unix epoch
        uint256 quantity;
        uint256 unitPrice; // Price unit is centime
        string[] labels;
        string landType;
    }
    
    uint256 public codeSequence;
    uint32 public currentEpoch; // The epoch will be set from the outside
    mapping(uint256 => Product) private products;
    Set categorySet;

    function incrementSequence() private {
        codeSequence += 1;
    }

    function setCurrentEpoch(uint32 _currentEpoch) public {
        currentEpoch = _currentEpoch;
    }

    function addProduct(string memory _name, string memory _category, string memory _origin, string memory _farmerName,
                        string memory _centralMarketName, string memory _authorityAgentName, bool _hasPesticide,
                        uint256 _quantity, uint256 _price, string[] memory _labels, string memory _landType) public {
        products[codeSequence] = Product(codeSequence, _name, _category, _origin, _farmerName, _centralMarketName,
                                        _authorityAgentName, _hasPesticide, currentEpoch, _quantity, _price, _labels, _landType);
        incrementSequence();
        addCategory(_category);
        categorySet.products[_category].push(MinifiedProduct(codeSequence - 1, _name));
    }

    function retrieve(uint256 _id) public view returns(Product memory) {
        return products[_id];
    }

    function addCategory(string memory _category) private {
        if(!categorySet.isIn[_category])
        {
            categorySet.values.push(_category);
            categorySet.isIn[_category] = true;
        }
    }

    function fetchCategories() public view returns(string[] memory) {
        return categorySet.values;
    }

    function fetchCategoryProducts(string memory _category) public view returns(MinifiedProduct[] memory) {
        return categorySet.products[_category];
    }

    function stringCompare(string memory str1, string memory str2) private pure returns(bool) {
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }
}