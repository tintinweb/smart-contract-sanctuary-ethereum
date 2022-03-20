/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


interface IBEP20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract reward{
    using SafeMath for uint256;
    
     IBEP20 public token;
     mapping(uint256 => uint256) public allocation;
     mapping(address=> uint256) public feedback;
     mapping(address=>uint256) public redeemcode;
     mapping(address=>bool) public check;
     mapping(address=>bool) public rewardcheck;

     address payable public owner;

 

     
    constructor (IBEP20 _Token) 
    {     
      
         token = _Token;
         owner = payable(msg.sender);
    allocation[1] = 10000000000000000000;
    allocation[2] = 20000000000000000000;
    allocation[3] = 30000000000000000000;
    allocation[4] = 40000000000000000000;
    allocation[5] = 50000000000000000000;
    }

    modifier onlyOnwer(){

        require(msg.sender==owner,"You are not the owner");
        _;
    }


    function givefeedback(uint256 _number) public{

        require(_number==1||_number==2||_number==3||_number==4||_number==5,"Invalid FeedBack");
        require(check[msg.sender]!=true,"Already gave the feedback!");
       uint256 code= (uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))))%10000;
       redeemcode[msg.sender]=code;
       feedback[msg.sender]=_number;
       check[msg.sender]=true;
    }

    function getreward(uint256 _code) public{

         require(rewardcheck[msg.sender]!=true,"Already reward was withdrawn!");
        require(redeemcode[msg.sender]==_code,"Invalid Redeem Code!");


        if(feedback[msg.sender]==1)
        {
            token.transfer(msg.sender,allocation[1]);

        }

       else if(feedback[msg.sender]==2){
           token.transfer(msg.sender,allocation[2]);
        }

        else if(feedback[msg.sender]==3){

            token.transfer(msg.sender,allocation[3]);

        }

        else if(feedback[msg.sender]==4){
            token.transfer(msg.sender,allocation[4]);

        }

        else if(feedback[msg.sender]==5){
            token.transfer(msg.sender,allocation[5]);

        }

        rewardcheck[msg.sender]=true;

    }

    function changerewardperct(uint256 one,uint256 two,uint256 three,uint256 four,uint256 five) public onlyOnwer{

        allocation[1]=one;
        allocation[2] = two;
        allocation[3] = three;
        allocation[4] = four;
        allocation[5] = five;




    }


      function Withdraw(uint256 amount) payable public onlyOnwer{
        require(address(this).balance >= amount, "Invalid amount");
        owner.transfer(amount);
    }

    function WithdrawToken(uint256 _amount) public onlyOnwer{
        
        token.transfer(owner, _amount);
    }   

}
//  lmy token 0x66fD97a78d8854fEc445cd1C80a07896B0b4851f