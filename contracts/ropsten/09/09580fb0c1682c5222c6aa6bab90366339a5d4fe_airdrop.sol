/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    } 
}

contract EarnTMcoin is Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply ;
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 Initial_supply  = 1000000000 ;
    uint256  Max_Fixed_supply  = 1000000000000 ;  

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    constructor() {
        name = "EarnTM coin";
        symbol= "ETM";
        decimals= 18;
        totalSupply=Initial_supply *(10 ** 18);
        balances[msg.sender] = totalSupply;
    }

    function mint(uint256 amount)public onlyOwner returns (bool) {
        amount = amount * 10 ** 18;
        Max_Fixed_supply = Max_Fixed_supply * 10 ** 18;
        require(totalSupply + amount <= Max_Fixed_supply , " you can not mint mmore than 1 trillion");
        _mint(_msgSender(), amount );
        return true;
    }
       // chk balance from token 
    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf(msg.sender) >= value, "balance too low");
        value = value * (10 ** decimals);
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        require(balanceOf(from) >= value, "balance too low");
        require(allowance[from][msg.sender] <= value, "allowance too low");
        value = value * (10 ** decimals);
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");
        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount * (10 ** decimals));
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");
        balances[account] = balances[account].sub(
            amount,
            "BEP20: burn amount exceeds balance"
        );
        totalSupply = totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
}
contract airdrop
{
   uint256 public airdropToken ;
   uint256 public token_per_user = 2;
   address payable public ownerable;  
   uint256[] amount;
   address[]  user;
   address Token;  
   bool airdrop_active = true;   
     EarnTMcoin token;   
     mapping(address =>bool ) result; 
     struct store  
     {     
             address token;
             uint256 token_per_user;   
             address user;  
             bool airdropclaimed;    
                  }  
     store[]public totalUser;     
     //tokens put in airdrop.import interface ,EarnTMcoin
     //token can transferby  function use  ,can also use mint function to transfer into airdrop contract
   
      //  constructor (address token_,uint256 amount_airdrop)  
      function initializeAirDrop (address token_,uint256 amount_airdrop) public 
    {   
         ownerable= payable (msg.sender);
         Token=token_;
        airdropToken = amount_airdrop;
        require(address( token_) != address(0)  ,"address must be available");  //airdrop tokeN address not = to 0
        require(amount_airdrop != 0);  
      //  require(msg.sender != address(0));
          require(token.balanceOf(msg.sender) >=airdropToken , "balance too low");     
          token.transferFrom(msg.sender,address(this),airdropToken);      
      // token._mint(address(this),airdropToken);    
       } 

         modifier onlyOwner() {
    require(msg.sender == ownerable);
    _;
  }  
       function claimToken()external
       {
          // require(ownerable != airdropToken);
           require(payable(msg.sender) != ownerable,"owner can not claim tokens");
           require(token.balanceOf(address(this))>=token_per_user,"balance must be greater than require amount");
           require( airdrop_active ==true ," airdrop should be active");
           require(result[msg.sender] == true,"you have already taken airdrop" ) ;                    //when toke ntransfer then mapping wil be trie
          // require(.(msg.sender) != msg.sender, " you can take token only once");
           token.transferFrom(address(this),msg.sender,token_per_user);
           result[msg.sender] = true;
           //push data into mapping 
         //   totalUser.push(store(Token, token_per_user,msg.sender,true)) ;   
         //msg .sender & true of allUser    

       }
   
      function cancel() external 
     {
       require (payable (msg.sender)== ownerable);       
         airdrop_active =false ;     
    }
    function changeTokenAdres(address newTokenAdres)public onlyOwner
    {
             Token = newTokenAdres ;
    }
    function update_tokensPerUser(uint256 newPerUser) public onlyOwner
    {
             token_per_user =newPerUser;
    }
    //   uint256 tokenId = tokenIds[index];
    //   address receiver = receivers[index];
    //   require(receiver == msg.sender, "Defined airdrop receiver needs to be msg.sender!");
   
    }