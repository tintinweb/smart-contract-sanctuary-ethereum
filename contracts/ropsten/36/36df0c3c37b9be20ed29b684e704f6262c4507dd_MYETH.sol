/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

//SPDX-License-Identifier:Unlicensed
pragma solidity ^0.8.13;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    
}

interface IERC20K {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Paused(address indexed admin);
    event Unpaused(address indexed admin);
}
contract MYETH is IERC20K {

    string public constant name="MY ETH";
    string public constant symbol="ETH";
    uint8 public constant decimal= 18;
  
    address public admin;
    mapping(address=>uint256)balances;
    mapping(address=>mapping(address=>uint256))allowed;
    uint256 totalsupply_=1000000*10**18;// ether will automatically add 18 decimal to ur value it will consider as token only

    using SafeMath for uint256;

    constructor(){
        admin=msg.sender;
        balances[msg.sender]=totalsupply_;
      
    }

    modifier onlyadmin{
    require(msg.sender==admin,"Only Admin can have access ");
    _;
 }

    function  totalSupply()public view returns(uint256){
        return totalsupply_;
    }
  //balance of owner
    function balanceOf(address tokenOwner)public view returns(uint256){
        return balances[tokenOwner];
    }
  //check balance
    function checkbalance(address receiver)public view returns(uint256){
        return balances[receiver];
    }

//transfer token to certain address
    function transfer(address receiver,uint256 numTokens)public returns(bool){
        require(numTokens<=balances[msg.sender]);
        balances[msg.sender]=balances[msg.sender].sub(numTokens);
        balances[receiver]=balances[receiver].add(numTokens);
        emit Transfer(msg.sender,receiver,numTokens);

        return true;
    }
//owner give rights of the certain tokens to spender
    function approve(address spender,uint256 numTokens)public returns(bool){
        allowed[msg.sender][spender]=numTokens;
        emit Approval(msg.sender,spender,numTokens);
        return true;
    }
//check the approval token rights
    function allowance(address owner,address spender)public view returns(uint){
        return allowed[owner][spender];
    }
// Increase the amount of tokens that an owner allowed to a spender
    function increaseallowance(address spender,uint256 addedValue)public returns(bool){
	  require(spender != address(0));
	  allowed[msg.sender][spender] = (allowed[msg.sender][spender].add(addedValue));
	  emit Approval(msg.sender, spender,allowed[msg.sender][spender]);
      return true;
    }
//Decrease the amount of tokens that an owner allowed to a spender
 function decreaseAllowance( address spender, uint256 subtractedValue)public returns (bool){
	  require(spender != address(0));
      allowed[msg.sender][spender] = (allowed[msg.sender][spender].sub(subtractedValue));
	  emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
	  return true;
  }


//it should be access after the approval is done and this will hit only by the spender
    function transferFrom(address owner,address buyer, uint256 numTokens)public returns(bool){
        require(numTokens<=balances[owner]);
        require(numTokens<=allowed[owner][msg.sender]);
        balances[owner]=balances[owner].sub(numTokens);
        allowed[owner][msg.sender]=allowed[owner][msg.sender].sub(numTokens);
        balances[buyer]=balances[buyer].add(numTokens);
        emit Transfer(owner,buyer,numTokens);
        return true;
    }
    //change the owner
    function changeOwner(address _newowner)external onlyadmin{
     require(_newowner!=address(0),"Invalid address");
     require(_newowner!=msg.sender,"New owner is not be old");
     admin=_newowner;
    }
    // mint function
     function mint(address owner, uint256 amount) public onlyadmin{
        require(owner!= address(0), "MINT_TO_ZEROADDRESS");
        require(amount > 0, "INVALID_AMOUNT");
        totalsupply_= totalsupply_.add(amount);
        balances[owner] = balances[owner].add(amount);
        emit Transfer(address(0), owner, amount);
    }
    //burn function
     function burn(address owner, uint256 amount) public onlyadmin{
        require(owner == msg.sender,"Only owner can burn their address only");
        require(owner != address(0), "BURN_FROM_ZEROADDRESS");
        require(amount > 0, "INVALID_AMOUNT");
        balances[owner] = balances[owner].sub(amount, "Burn amount exceeds balance");
        totalsupply_ =  totalsupply_.sub(amount);
        emit Transfer(owner, address(0), amount);
    }

}