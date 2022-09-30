/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract SimpleStorage {
    struct Asset {
    string name;
    string description;
    uint cost;
    uint quantity;
    string manufacturer;
    string customer;
    string addressFrom;
    string addressTo;
    bool initialized;    
    bool arrived;
    uint distributorId;
}
 struct Person{ //struct for distributor
        uint id;
        string name;
        string add;
        string email;
        string phone;
    }

    mapping(uint  => Person) private distributorStruct;
    uint public distributorCount=0;
    uint public assetCount=0;
    

     function insertDistributor(string memory name,string memory add,string memory email,string memory phone) public returns(bool)
    {
        for(uint i=0;i<distributorCount;i++){
                require(keccak256(abi.encodePacked((distributorStruct[i].email))) != keccak256(abi.encodePacked(("[email protected]"))),"Distributor already exists");
        }
        distributorStruct[distributorCount]=Person(distributorCount,name,add,email,phone);
        distributorCount++;
        return true;
    }

    function getDistributorbyId(uint id)public view returns(string memory,string memory,string memory,string memory){
        return (distributorStruct[id].name,distributorStruct[id].add,distributorStruct[id].email,distributorStruct[id].phone);
    }

    function getAlldistributors()public view returns (Person[] memory){
      Person[]   memory id = new Person[](distributorCount);
      for (uint i = 0; i < distributorCount; i++) {
          Person storage member = distributorStruct[i];
          id[i] = member;
      }
      return id;
    }

    // function balance(uint _amount) public pure returns(bool){
    //     require(_amount<20,"Balance need to be greater than 20");
    //     return true;
    //}
//end of distributor
mapping(uint  => Asset) private assetStore;
mapping(address => mapping(uint => bool)) private walletStore;
function createAsset(string memory name, string memory description, uint distributorId,uint cost,uint quantity, string memory manufacturer,string memory customer ,string memory addressFrom,string memory addressTo) public {
      assetStore[assetCount] = Asset(name, description,cost,quantity,manufacturer,customer,addressFrom,addressTo,true,false,distributorId);
      walletStore[msg.sender][assetCount] = true;
      assetCount++;
}
function transferAsset(address to, uint i) public{
    require(assetStore[assetCount].initialized==true,"No asset with this UUID exists");
    require(walletStore[msg.sender][i]==true,"Sender does not own this asset.");
    walletStore[msg.sender][i] = false;
    walletStore[to][i] = true;
}


 function getItemByUUID(uint i) public view returns(uint cost,uint quantity){
        require(i<=assetCount,"Asset does not exists");
        return (assetStore[i].cost,assetStore[i].quantity);
}

function isOwnerOf(address owner, uint i) public view returns (bool) {
    if(walletStore[owner][i]) {
        return true;
    }
    return false;
}

function getAllAssets() public view returns(Asset[] memory){
    Asset[]   memory x = new Asset[](assetCount);
      for (uint i = 0; i < assetCount; i++) {
          Asset storage member = assetStore[i];
          x[i] = member;
      }
      return x;
}

//consumer end 

function Arrived(uint i) public { 
   assetStore[i].arrived=true;
}
}