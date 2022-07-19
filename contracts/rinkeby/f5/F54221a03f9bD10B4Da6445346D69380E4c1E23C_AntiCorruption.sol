/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// SPDX-License-Identifier:MIT 

pragma solidity ^0.6.0;

contract AntiCorruption
{

    struct Cause{

        string  cause_name ;
        string causeDescription;
        uint256 targetAmount;
        mapping(address=>uint256) donorsAndAmount;
        address payable finalReceiver;
        uint256 causeId;
        uint256 balanceAmount;
        address[] donorAddressList;
        uint256[] donorAmountList;

        

    }

    Cause[] public causeArray;
   

    function setCauseName(string memory causeNameInput ,string memory causeDescInput,uint256 targetInput,address payable finalTargetReceiver)public 
    {
      
       Cause memory cause ;
       cause.cause_name =causeNameInput;
       cause.causeDescription=causeDescInput;
       cause.targetAmount = targetInput;
       cause.finalReceiver = finalTargetReceiver;
       cause.balanceAmount=0;
       cause.causeId=causeArray.length+1; 
       causeArray.push(cause);
       
    }


     function balanceOfCause(uint id ) public view returns(uint256)
     {
        return causeArray[id-1].balanceAmount;
     }

     
     function targetAmountOfCause(uint id ) public view returns(uint256)
     {
            return causeArray[id-1].targetAmount;

     }

     function donateAmount(uint id,address donorAddress,uint256 donatedAmount) public
     {
        causeArray[id-1].donorAddressList.push(donorAddress);
        causeArray[id-1].donorAmountList.push(donatedAmount);
        causeArray[id-1].balanceAmount+=donatedAmount;

     }


     function donorsAddress(uint id) public view returns(address[] memory)
     {
        return causeArray[id-1].donorAddressList;
     }

     function donorsList(uint id) public view returns(uint[] memory)
     {
        return causeArray[id-1].donorAmountList;
     }



   

  

    
}