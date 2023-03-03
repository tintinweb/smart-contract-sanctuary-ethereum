/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

contract Test2 {
    address payable public owner;
    string[] public wasteTypes;
    struct User {
        address userAddress;
        string wasteType;
        uint wasteAmount;
        
    }
    mapping (string => bool) public wasteTypeExists;
    mapping(string => uint) public wastePrice;
    User user;
    // mapping for waste prices?

     constructor(string[] memory _wasteTypes, uint[] memory _wastePrices) payable{
        owner = payable(msg.sender);
        wasteTypes = _wasteTypes;
        setTypes(wasteTypes);
        setPrices(_wasteTypes, _wastePrices);
        
    }
    function setTypes(string[] memory _wasteTypes) public {
        for(uint i = 0; i < _wasteTypes.length; i++){
        wasteTypeExists[_wasteTypes[i]] = true;
        }
    }
    function getTypes(string memory _wasteType) public view returns(bool) {
        return wasteTypeExists[_wasteType];
    }

    function setPrices(string[] memory _wasteType, uint[] memory _wastePrices) public {
        for(uint i = 0; i < _wasteType.length; i++){
        wastePrice[_wasteType[i]] = _wastePrices[i];
        }
    }
    function getPrices(string memory _wasteType) public view returns(uint) {
        return wastePrice[_wasteType];
    }
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawAllMoney(address payable _to) public {
        require(owner == _to, "You are not the owner");
        _to.transfer(address(this).balance);
    }

    function payUser(address payable _to, string memory _wasteType, uint _wasteAmount) public {
       
    
        
        user = User(_to, _wasteType, _wasteAmount);
        // require waste type to be in wasteTypes
        require(wasteTypeExists[_wasteType], "Waste type does not exist");
        // require waste amount to be > 0
        require(user.wasteAmount > 0, "Waste amount must be greater than 0");
        require(address(this).balance > 0, "Contract balance is 0");
        _to.transfer(wastePrice[_wasteType] * _wasteAmount);



        
        
    }


}