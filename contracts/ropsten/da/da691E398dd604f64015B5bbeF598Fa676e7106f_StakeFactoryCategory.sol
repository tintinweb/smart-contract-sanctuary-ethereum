// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../interfaces/IAdminAccess.sol";
contract StakeFactoryCategory{
    IAdminAccess public access;

    modifier atLeastAdmin() {
        require(access.hasAdminRole(msg.sender)||(access.getOwner() == msg.sender), "at least need admin role");
        _;
    }
    struct Category{
        bool exist;
        uint8 stakingType;
        bytes categoryName;
        bytes description;
        address factoryAddress;
    }
    Category[] private stakeCategory;
    function addCategory(uint8 _stakingType,bytes memory _categoryName,bytes memory _description,address _factoryAddress) public{
        require(!stakeCategory[_stakingType].exist,"staking type is exist");
        stakeCategory.push(Category({
            exist:true,
            stakingType:_stakingType,
            categoryName:_categoryName,
            description:_description,
            factoryAddress:_factoryAddress
        }));
    }
    function getCategory(uint8 stakingType) public view returns (uint8 stakeType,bytes memory categoryName,bytes memory description,address factoryAddress){
        Category memory c=stakeCategory[stakingType];
        return (c.stakingType,c.categoryName,c.description,c.factoryAddress);
    }
    function getCategoryCount() public view returns (uint256 count){
        return stakeCategory.length;
    }
    constructor(address _access){
        access=IAdminAccess(_access);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAdminAccess {
    function hasAdminRole(address) external returns (bool);
    function addToAdminRole(address) external;
    function removeFromAdminRole(address) external;
    function getOwner() external returns (address);
}