// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract AgriTech {
    struct Farmer {
        address owner;
        string name;
        string addr;
        string[] companies;
        uint256[] values;
        uint256[] weight;
        uint256 total;
    }
    mapping(uint256 =>Farmer) public farmers; 

    uint256 public numOfFarmers =0;

    function addFarmer(address _owner, string memory _name, string memory _addr)public returns(uint256){
        Farmer storage farmer = farmers[numOfFarmers];
        farmer.owner = _owner;
        farmer.name = _name;
        farmer.addr = _addr;

        numOfFarmers++;
        return numOfFarmers-1;
    }

    function addTransaction(uint256 _id)public payable{
        uint256 amount = msg.value;
        Farmer storage farmer = farmers[_id];
        farmer.companies.push("711");
        farmer.values.push(amount);
        farmer.weight.push(0);

        (bool sent,) = payable(farmer.owner).call{value:amount}("");

        if(sent){
            farmer.total = farmer.total + amount;
        }
    }

    function getTransactions(uint256 _id)view public returns(string[] memory, uint256[] memory){
        return(farmers[_id].companies, farmers[_id].values);
    }

}