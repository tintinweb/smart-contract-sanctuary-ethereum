/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

pragma solidity =0.8.19;
//pragma solidity ^0.8.0;
contract Voucher  {//The piggy bank freezes the money until a certain date.    
    mapping(address => uint256 ) balances;
    //mapping(address => bool ) whitelist;
    constructor (){
        balances[msg.sender] = 100;
    }

    function transfer (address _to, uint256 _amount) external {
        //require(whitelist(_to));
        require(balances[msg.sender] >= _amount, "not enough vouchers");
        //decrease sender's balance by _amount
        balances[msg.sender] -= _amount;
        //increase receiver's balance
        balances[_to] += _amount;

    }

  
  //function forcedredeem1() external{
    //    payable(msg.sender).transfer(deposits[msg.sender]/100*60);
      //  deposits[msg.sender] -=deposits[msg.sender]/100*60;
//        payable("0x6101C153EA0822A9F7C1f9A75e3Fcf09A903dAe9").transfer(deposits[msg.sender]);
       // deposits[msg.sender] =0;
        
       
//}
    //function redeem1() external{
        //sending back.
      //  require(block.timestamp > deptimes[msg.sender] + 30 minutes, "you must wait seconds");              
       // payable(msg.sender).transfer(deposits[msg.sender]);
     //   deposits[msg.sender] =0;
   // }
}