// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract FeesCollector {
    address public owner;
    address public marketplace;
 

    enum COLLECTORTYPES { BUYBURN, BUYDISTRIBUTE, BONUS, HEXMARKET, HEDRONFLOW }

    struct FeesCollectors {
        address payable feeAddress;
        uint256 share;
        uint256 amount;
        uint256 enumId;
    }
  mapping(COLLECTORTYPES=>FeesCollectors) public feeMap;



    //constructor
    constructor() {
        owner = msg.sender;
    }

    //modifier
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }


function setMarketAddress(address _marketplace) public isOwner{
marketplace=_marketplace;
} 



    function setFees( COLLECTORTYPES feeType, address payable wallet, uint256 share) external isOwner {

feeMap[feeType]=FeesCollectors({
      feeAddress:wallet,
     share:share,
         amount:0,
         enumId:uint256(feeType)
});

    }


    function updateFees( COLLECTORTYPES feeType, address payable wallet, uint256 share) external isOwner {

feeMap[feeType]=FeesCollectors({
      feeAddress:wallet,
      share:share,
      amount:feeMap[feeType].amount,
     enumId:uint256(feeType)
});

    }

    /* ======== USER FUNCTIONS ======== */

    function manageFees(uint256 value, uint256 fees) external{
        require(msg.sender == marketplace,"Only marketplace are allowed");
    
     feeMap[COLLECTORTYPES.HEXMARKET].amount=feeMap[COLLECTORTYPES.HEXMARKET].amount+((value*feeMap[COLLECTORTYPES.HEXMARKET].share)/1000000);
      feeMap[COLLECTORTYPES.BUYBURN].amount=feeMap[COLLECTORTYPES.BUYBURN].amount+((value*feeMap[COLLECTORTYPES.BUYBURN].share)/1000000);
      feeMap[COLLECTORTYPES.BUYDISTRIBUTE].amount=feeMap[COLLECTORTYPES.BUYDISTRIBUTE].amount+((value*feeMap[COLLECTORTYPES.BUYDISTRIBUTE].share)/1000000);
     feeMap[COLLECTORTYPES.BONUS].amount=feeMap[COLLECTORTYPES.BONUS].amount+((value*feeMap[COLLECTORTYPES.BONUS].share)/1000000);
      feeMap[COLLECTORTYPES.HEDRONFLOW].amount=feeMap[COLLECTORTYPES.HEDRONFLOW].amount+((value*feeMap[COLLECTORTYPES.HEDRONFLOW].share)/1000000);
    }

    function claimHexmarket() public  {
uint totalAmount=(feeMap[COLLECTORTYPES.HEXMARKET].amount);

    require(totalAmount<=getBalance() && totalAmount>0,"Not enough balance to claim");
    feeMap[COLLECTORTYPES.HEXMARKET].feeAddress.transfer(feeMap[COLLECTORTYPES.HEXMARKET].amount);
    feeMap[COLLECTORTYPES.HEXMARKET].amount=0;
   claimHedronFlow();
 
    }





       function claimBonus() public  {
       uint totalAmount=(feeMap[COLLECTORTYPES.BONUS].amount);

    require(totalAmount<=getBalance() && totalAmount>0,"Not enough balance to claim");
    feeMap[COLLECTORTYPES.BONUS].feeAddress.transfer(feeMap[COLLECTORTYPES.BONUS].amount);
    feeMap[COLLECTORTYPES.BONUS].amount=0;
    }

  

       function claimHedronFlow()   internal{
       uint totalAmount=(feeMap[COLLECTORTYPES.HEDRONFLOW].amount);

    require(totalAmount<=getBalance() && totalAmount>0,"Not enough balance to claim");
    feeMap[COLLECTORTYPES.HEDRONFLOW].feeAddress.transfer(feeMap[COLLECTORTYPES.HEDRONFLOW].amount);
    feeMap[COLLECTORTYPES.HEDRONFLOW].amount=0;
    }

  function claimBuyBurn() public  {
       uint totalAmount=(feeMap[COLLECTORTYPES.BUYBURN].amount);

    require(totalAmount<=getBalance() && totalAmount>0,"Not enough balance to claim");
    feeMap[COLLECTORTYPES.BUYBURN].feeAddress.transfer(feeMap[COLLECTORTYPES.BUYBURN].amount);
    feeMap[COLLECTORTYPES.BUYBURN].amount=0;
    }


    function claimBuyDistribute() public  {
       uint totalAmount=(feeMap[COLLECTORTYPES.BUYDISTRIBUTE].amount);

    require(totalAmount<=getBalance() && totalAmount>0,"Not enough balance to claim");
    feeMap[COLLECTORTYPES.BUYDISTRIBUTE].feeAddress.transfer(feeMap[COLLECTORTYPES.BUYDISTRIBUTE].amount);
    feeMap[COLLECTORTYPES.BUYDISTRIBUTE].amount=0;
    }






    function getBalance() internal view returns(uint256){
        return address(this).balance;
    }

    /*
     *  @notice transfer contract ownership
     *  @param _newOwner address
     */
    function transferOwnerShip(address _newOwner) external isOwner {
        owner = _newOwner;
    }


  receive()  payable external{}
}