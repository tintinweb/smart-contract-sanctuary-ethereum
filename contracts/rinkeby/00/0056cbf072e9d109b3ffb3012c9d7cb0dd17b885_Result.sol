//SPDX-License-Identifier:MIT
pragma solidity >0.6.0;
import "./erc.sol";

contract Result{
     struct student{
         string name;
         int marks;
         address user;
         bool staked;
     }
     struct staker{
         address stkAdd;
         uint stkAmount;
     }
     staker[] arrstk;
     student[] std;
     uint arrlength;
     uint public i;
     mapping(address => uint256) currentBlc;
     ERC20 token;
     uint startTime;
     uint _amount;


    //  modifier timeOver {
    //     require(block.timestamp > stopTime,"Staking Time is Over");
    //     _;
    //  }
     constructor(address addressstud_)  {
        token = ERC20(addressstud_);
     }
     function arrLength(uint length) public {
         arrlength = length;
     }
      function getarr(string[] memory _name,int[] memory mark) public{
        for( i=0 ; i<=arrlength; i++){
          std.push(student({name:_name[i],marks:mark[i],user:msg.sender,staked:false}));
           manipArr();
        }
     }
     function manipArr() internal {
         if(std[i].marks>33){
         reward();
         }
     }
      function reward() internal {
         token.transfer(std[i].user, 500);
         
     }
     function staking(uint amount) public returns(bool){
         currentBlc[msg.sender] = token.balanceFor(msg.sender);
         require(currentBlc[msg.sender] >= amount,"balance is not enough");
         startTime = block.timestamp;
         arrstk.push(staker({stkAdd:msg.sender,stkAmount:amount}));
         token.transferFrom(msg.sender,address(this),amount);
         currentBlc[msg.sender] -= amount;
         currentBlc[address(this)] += amount;
         _amount = amount;
         return true;
     } 
     function stdAddress(uint l) external view returns(int marks){
         return std[l].marks;
     }
    
     function withDraw() public  {
         require(block.timestamp >= startTime + 60 seconds,"Staking time is not completed");
         token.transferFrom(address(this),msg.sender,_amount);
         token.transfer(msg.sender,50);
         }
     
}