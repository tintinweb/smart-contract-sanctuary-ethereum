/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

pragma solidity ^0.6.0;

interface IERC20{
    function totalSupply() external view returns(uint256);
    function balanceOf(address acount) external view returns(uint256);
    function transfer(address recipient,uint amoount) external returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    }

contract CGCToken is IERC20 {
    string public constant name ="MyToken" ;
    string public constant symbol="MyT"; 
    uint public constant decimals=0; 

   event Approval(address indexed TokenOwner, address indexed spender, uint Tokens);
   event Transfer(address indexed from, address indexed to,uint tokens);


   mapping(address => uint256) balances;

   mapping(address => mapping(address => uint256)) allowed;

   uint256 totalSupply_ = 1000 wei;

   constructor() public {
       balances[msg.sender] = totalSupply_;
   }

   function totalSupply() public override view returns(uint256) {
       return totalSupply_;
   }

   function balanceOf(address tokenOwner) public override view returns(uint256){
       return balances[tokenOwner];
    }
    
    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }







}