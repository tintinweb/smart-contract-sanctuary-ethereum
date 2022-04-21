/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    address private m_Owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        m_Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return m_Owner;
    }
    function transferOwnership(address _address) public virtual onlyOwner {
        emit OwnershipTransferred(m_Owner, _address);
        m_Owner = _address;
    }
    modifier onlyOwner() {
        require(_msgSender() == m_Owner, "Ownable: caller is not the owner");
        _;
    }                                                                                           
}                          
interface IUniswapV2Factory {                                                         
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
contract SimpleToken is IERC20, Ownable {
    using SafeMath for uint256;
    uint256 private constant TOTAL_SUPPLY = 100000 * 10**18;
    string private m_Name = "SimpleToken";
    string private m_Symbol = "SIMPLE";
    uint8 private m_Decimals = 9;
    address private m_UniswapV2Pair;
    IUniswapV2Router02 private m_UniswapV2Router;
    uint256 private m_TxLimit  = 500 * 10**18;
    uint256 private m_WalletLimit = m_TxLimit.mul(3);
    bool private m_Liquidity = false;
    event SetTxLimit(uint TxLimit);
    mapping (address => bool) private m_ExcludedAddresses;
    mapping (address => uint256) private m_Balances;
    mapping (address => mapping (address => uint256)) private m_Allowances;

    struct DataStruct {
        uint256 uintVar;
        string stringVar;
        bool boolVar;
        address addressVar;
    }

    receive() external payable {}

    constructor () {
        m_Balances[_msgSender()] = TOTAL_SUPPLY;
        m_ExcludedAddresses[owner()] = true;
        m_ExcludedAddresses[address(this)] = true;
        emit Transfer(address(0), address(this), TOTAL_SUPPLY);
    }
    function name() public view returns (string memory) {
        return m_Name;
    }
    function symbol() public view returns (string memory) {
        return m_Symbol;
    }
    function decimals() public view returns (uint8) {
        return m_Decimals;
    }
    function totalSupply() public pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }
    function balanceOf(address _account) public view override returns (uint256) {
        return m_Balances[_account];
    }
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(_msgSender(), _recipient, _amount);
        return true;
    }
    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return m_Allowances[_owner][_spender];
    }
    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }
    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, _msgSender(), m_Allowances[_sender][_msgSender()].sub(_amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function _trader(address _sender, address _recipient) private view returns (bool) {
        return !(m_ExcludedAddresses[_sender] || m_ExcludedAddresses[_recipient]);
    }
    function _txRestricted(address _sender, address _recipient) private view returns (bool) {
        return _sender == m_UniswapV2Pair && _recipient != address(m_UniswapV2Router) && !m_ExcludedAddresses[_recipient];
    }
    function _walletCapped(address _recipient) private view returns (bool) {
        return _recipient != m_UniswapV2Pair && _recipient != address(m_UniswapV2Router);
    }
    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        m_Allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");
        require(_amount > 0, "Transfer amount must be greater than zero");
        
        if(_walletCapped(_recipient))
            require(balanceOf(_recipient) < m_WalletLimit);
            
        if (_trader(_sender, _recipient)) {
            if (_txRestricted(_sender, _recipient)) 
                require(_amount <= m_TxLimit);
        }
        
        _updateBalances(_sender, _recipient, _amount);
	}
    function _updateBalances(address _sender, address _recipient, uint256 _amount) private {
        m_Balances[_sender] = m_Balances[_sender].sub(_amount);
        m_Balances[_recipient] = m_Balances[_recipient].add(_amount);
        emit Transfer(_sender, _recipient, _amount);
    }
    function addLiquidity() external onlyOwner() {
        require(!m_Liquidity,"Liquidity already added.");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        m_UniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(m_UniswapV2Router), TOTAL_SUPPLY);
        m_UniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        m_UniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(m_UniswapV2Pair).approve(address(m_UniswapV2Router), type(uint).max);
        m_Liquidity = true;
    }

    function getUint256() external pure returns (uint256) {
        uint256 _ret = 256;
        return _ret;
    }
    
    function getUint128() external pure returns (uint128) {
        uint128 _ret = 128;
        return _ret;
    }
    
    function getUint64() external pure returns (uint64) {
        uint64 _ret = 64;
        return _ret;
    }

    function getUint32() external pure returns (uint32) {
        uint32 _ret = 32;
        return _ret;
    }
    
    function getUint16() external pure returns (uint16) {
        uint16 _ret = 16;
        return _ret;
    }
    
    function getUint8() external pure returns (uint8) {
        uint8 _ret = 8;
        return _ret;
    }

    function getUint() external pure returns (uint) {
        uint _ret = 1;
        return _ret;
    }

    function getDataStruct() external pure returns (DataStruct memory) {
        DataStruct memory _struct = DataStruct(
            123,
            "stringvar",
            true,
            0x250E75B9F33940506D1cF31FaB63cFAA5ad98C95
        );
        return _struct;
    }

    function getUintArr(uint256[] memory _arr) external pure returns (uint256[] memory) {
        return _arr;
    }

    function getStrArr(string[] memory _arr) external pure returns (string[] memory) {
        return _arr;
    }
    
    function getBoolArr(bool[] memory _arr) external pure returns (bool[] memory) {
        return _arr;
    }
    
    function getAddrArr(address[] memory _arr) external pure returns (address[] memory) {
        return _arr;
    }

    function getBytes(bytes memory _bytes) external pure returns (bytes memory) {
        return _bytes;
    }

    function getBytesArr(bytes[] memory _arr) external pure returns (bytes[] memory) {
        return _arr;
    }

    function getPrimitiveMultiReturnData() external pure returns (uint256, string memory, bool, address) {
        return (
            123,
            "stringvar",
            true,
            0x250E75B9F33940506D1cF31FaB63cFAA5ad98C95
        );
    }

    function getStructMultiReturnData() external pure returns (uint256, string memory, bool, address, DataStruct memory) {
        DataStruct memory _struct = DataStruct(
            123,
            "stringvar",
            true,
            0x250E75B9F33940506D1cF31FaB63cFAA5ad98C95
        );
        return (
            123,
            "stringvar",
            true,
            0x250E75B9F33940506D1cF31FaB63cFAA5ad98C95,
            _struct
        );
    }

    function getComplex(uint _num, string memory _str, bool _bool) external pure returns (string[] memory, DataStruct memory, uint) {
        DataStruct memory _struct = DataStruct(
            123,
            "stringvar",
            true,
            0x250E75B9F33940506D1cF31FaB63cFAA5ad98C95
        );
        string[] memory _strings = new string[](3);
        _strings[0] = _str;
        _strings[1] = "var2";
        _strings[2] = "var3";
        return (
            _strings,
            _struct,
            _bool ? 5 : 5*_num
        );
    }

    function getComplex2(string[] memory _str, uint[] memory _num, bool[] memory _bool) external pure returns (DataStruct memory, uint[] memory, string memory) {
        DataStruct memory _struct = DataStruct(
            123,
            "stringvar",
            true,
            0x250E75B9F33940506D1cF31FaB63cFAA5ad98C95
        );
        uint[] memory _ints = new uint[](3);
        _ints[0] = _num[0];
        _ints[1] = _bool[1] ? 123 : 1000;
        _ints[2] = _bool[2] ? 321 : 5000;
        return (
            _struct,
            _ints,
            _str[_num[0]]
        );
    }
}