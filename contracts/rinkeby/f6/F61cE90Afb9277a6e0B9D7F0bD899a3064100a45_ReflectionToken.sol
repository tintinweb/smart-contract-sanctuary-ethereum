// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../TransferHelper.sol";

  contract  ReflectionToken {
     address ownerAddress =  0xdD870fA1b7C4700F2BD7f44238821C26f7392148; //address(this);
     address reflectionAmount = 0x583031D1113aD414F02576BD6afaBfb302140225;

     struct userInfo {
         address userAddress;
         uint256 amount ;
         uint256 investTime;
         bool isClaimed;
         
     }
     mapping(address => userInfo) public userInfoArray;


        fallback() external payable { }

        receive() external payable { }

     function invest()  payable public {
         uint256 _calculatedAmount = ((msg.value*5)/100);
         uint256 poolAmount = (msg.value -_calculatedAmount);
        //  payable(reflectionAmount).transfer(_calculatedAmount);
        //           payable(ownerAddress).transfer(poolAmount);

         TransferHelper.safeTransferETH(reflectionAmount , _calculatedAmount);
         TransferHelper.safeTransferETH(ownerAddress , poolAmount);

         userInfo memory Info =  userInfo({
             userAddress : msg.sender,
             amount :msg.value,
             investTime :block.timestamp,
             isClaimed :false
         });
         userInfoArray[msg.sender] =Info;
     }
      function claim() public returns(bool){
          require(userInfoArray[msg.sender].isClaimed == false ,"You've already claimed");
        //   require(userInfoArray[msg.sender].investTime + 1 days  >= block.timestamp ,"You can't claim before maturity");
         uint256 reward = uint256(userInfoArray[msg.sender].amount);
        TransferHelper.safeTransfer(ownerAddress , msg.sender , reward);
          return true;
                }

  }