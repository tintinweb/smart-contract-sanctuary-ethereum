/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
library Util {

function generateRandomNumber() internal view returns (uint) {
    uint amount = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number))) % (1000-1);
     amount = amount + 1;
     return amount;
}

}



pragma solidity ^0.8.17;
contract Adtx {
    address payable public owner;
    uint public amount;


    using Util for uint;
    
	struct Ad {
		bool isActive;
        uint adWeight;
        uint adAmount;
	}


    mapping(address => Ad) public advertisers;

    constructor() payable {
        owner = payable(msg.sender);
        amount = msg.value;
    }

    event AddAdvertiser(address,uint);
    event RemoveAdvertiser(address);
    event IsAdvertiser(address);
    event GetAdWeight(address);

    receive() external payable {}

    //withdraw
    function withdraw(uint _amount) external {
        require(msg.sender == owner, "caller is not owner");
        payable(msg.sender).transfer(_amount);
    }
    
    //getBalance
    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    //advertisers list management:
    function addAdvertiser(address adrs, uint adPrice) external returns(bool){
         require(msg.sender == owner, "caller is not owner");
         advertisers[adrs].isActive = true;
         advertisers[adrs].adAmount = adPrice;
         advertisers[adrs].adWeight = adPrice * getRandomNumber();
         emit AddAdvertiser(adrs,adPrice);
         return true;
    }

     

    function isAdvertiser(address adrs) external returns(bool){
        emit IsAdvertiser(adrs);
        return advertisers[adrs].isActive;
    }

/*     function getAdWeight(address adrs) external returns(uint){
        emit GetAdWeight(adrs);
        return advertisers[adrs].adWeight;
    } */

    function removeAdvertiser(address adrs) external returns(bool){
        require(msg.sender == owner, "caller is not owner");
        advertisers[adrs].isActive = false;
        advertisers[adrs].adWeight = 0;
        emit RemoveAdvertiser(adrs);
        return true;
    }

    function getRandomNumber() public view returns(uint rndmn){
        rndmn = Util.generateRandomNumber();
        //console.log(rndmn);
        return rndmn;
    }
}