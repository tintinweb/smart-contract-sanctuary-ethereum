//SPDX-License-Identifier:MIT

pragma solidity^0.8.10;

contract Realestate{
     address public owner=0x773DaeB6fA40397057180659b5BF90bB3086307f;

    struct properties{
    string propertyAddress;
    uint256 value;
    }

    properties[] public realestate;


        constructor() {
        owner = msg.sender;
     }
         modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function add(string calldata _propertyaddress, uint256 _value ) public onlyOwner {

        realestate.push(properties(_propertyaddress,_value));

    }
     function getProperties() public view returns (properties[] memory) {
        return realestate;
    }
 

}