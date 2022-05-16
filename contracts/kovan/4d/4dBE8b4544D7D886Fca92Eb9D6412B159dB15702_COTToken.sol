/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

pragma solidity ^0.5.0;

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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


contract ERC20Interface {
    string public name;
    string public symbol;
    uint8 public decimals;
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor()public {
    owner = msg.sender;
  }
 
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


contract COTToken is ERC20Interface,Ownable{
    string public symbol;
    string public name;
    uint public decimal;
    uint  _totalSupply;

    mapping(address=>uint) balances;
    mapping(address=>mapping(address=>uint)) allowd;

    using SafeMath for uint;

   constructor()public{
       symbol = "CTT";
       name = "COT TOKEN";
       decimal = 18;
       _totalSupply = 1000000000000000000000000000;
       balances[msg.sender] = _totalSupply;
   }


   function totalSupply() public view returns (uint){
       return _totalSupply;
   }

    function balanceOf(address tokenOwner) public view returns (uint){
         return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool){
        balances[msg.sender] =  balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender,to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint){
        return allowd[tokenOwner][spender];
    }


    function approve(address spender, uint tokens) public returns (bool){
        allowd[msg.sender][spender] = tokens;
        emit Transfer(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool){
         allowd[from][to] = allowd[from][to].sub(tokens);
         balances[from] = balances[from].sub(tokens);
         balances[to] = balances[to].add(tokens);
         return true;
    }


    function()external payable{
        revert();
    }

    function transferAnyERC20Token(address addr,uint tokens)public onlyOwner returns(bool){
        ERC20Interface(addr).transfer(msg.sender,tokens);
        return true;
    }
}