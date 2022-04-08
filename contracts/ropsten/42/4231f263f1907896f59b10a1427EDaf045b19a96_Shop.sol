/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Shop {
    address private owner;
    struct picture {
        address address_wallet;
        string picName;
        string name;
        uint price;
        string deliverAddress;
        string tel;
        string path;
        uint status;
        string trackingNumber;
}
 uint countID;
 string[] pathName;
 uint[] picID;

mapping(uint => picture) public pictures;

event OwnerSet(address indexed oldOwner, address indexed newOwner);

constructor() {
    countID = 1;
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

function createSellPic(uint price,string memory path,string memory picName) public  {
pictures[countID].address_wallet = owner;
pictures[countID].picName = picName;
pictures[countID].name = "Piya";
pictures[countID].price = price;
pictures[countID].deliverAddress = "at Me";
pictures[countID].tel = "02777777";
pictures[countID].path = path;
pictures[countID].status = 1;

 delete pathName;
 delete picID;
for (uint i=1;i<=countID;i++) {
            if(pictures[i].status==1) {
                pathName.push(pictures[i].picName);
                picID.push(i);
            }
    }

// keccak256(abi.encodePacked(pictures[i].status)) != keccak256(abi.encodePacked("Send"))
// pictures[countID] = picture(owner,picName,"Me",price,"at Me","027777",path,"Sell");
    // return (owner,price,path); view returns (address,uint,string memory)
    countID++;
}

function getPic() public view returns (string[] memory,uint[] memory) {
    
return (pathName,picID);
}

function sendPicture(uint id,string memory tracking) public{
pictures[id].status = 3;
pictures[id].trackingNumber = tracking;

 delete pathName;
 delete picID;
for (uint i=1;i<=countID;i++) {
            if(pictures[i].status==1) {
                pathName.push(pictures[i].picName);
                picID.push(i);
            }
    }
}

/*
modifier costs(uint _amount) {
      require(
         msg.value >= _amount,
         "Not enough Ether provided."
      );
      _;
      if (msg.value > _amount)
         msg.sender.transfer(msg.value - _amount);
   }
   //msg มาตอนไหน

 function forceOwnerChange(address _newOwner) public payable costs(200 ether) {
      owner = _newOwner;
      if (uint(owner) & 0 == 1) return;        
   }
*/

}