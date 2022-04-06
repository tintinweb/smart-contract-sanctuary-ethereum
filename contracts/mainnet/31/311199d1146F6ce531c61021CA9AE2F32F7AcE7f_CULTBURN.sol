/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

/*
 * No team tokens. All tax goes to liquidity pool. Price only goes up. Supply only goes down.
 * https://t.me/CultBurn
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
interface ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
contract CULTBURN is ERC20 {
    uint256 private constant TOTAL_SUPPLY = 666 * 10**18;
    string private m_Name = "Cult Burn";
    string private m_Symbol = "CULTBURN";
    uint8 private m_Decimals = 9;

    IUniswapV2Router02 private m_UniswapV2Router;
    address private m_UniswapV2Pair;
    bool private m_Liquidity = false;

    mapping (address => bool) private m_ExcludedAddresses;
    mapping (address => uint256) private m_Balances;
    mapping (address => mapping (address => uint256)) private m_Allowances;

    receive() external payable {}

    constructor () {
        m_Balances[address(this)] = TOTAL_SUPPLY;
        m_ExcludedAddresses[address(0)] = true;
        m_ExcludedAddresses[msg.sender] = true;
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
    function totalSupply() public pure returns (uint256) {
        return TOTAL_SUPPLY;
    }
    function balanceOf(address _account) public view returns (uint256) {
        return m_Balances[_account];
    }
    function transfer(address _recipient, uint256 _amount) public returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return m_Allowances[_owner][_spender];
    }
    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }
    function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, m_Allowances[_sender][msg.sender] - _amount);
        return true;
    }
    function _trader(address _sender, address _recipient) private view returns (bool) {
        return !(m_ExcludedAddresses[_sender] || m_ExcludedAddresses[_recipient]);
    }
    function _approve(address _owner, address _spender, uint256 _amount) private {
        m_Allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_amount > 0, "Transfer amount must be greater than zero");
        
        uint256 _taxes = 0;            
        if (_trader(_sender, _recipient)){   
            if(_sender == m_UniswapV2Pair || _recipient == m_UniswapV2Pair)
                _taxes = _amount/10;
        }
        _updateBalances(_sender, _recipient, _amount, _taxes);
	}
    function _updateBalances(address _sender, address _recipient, uint256 _amount, uint256 _taxes) private {
        uint256 _netAmount = _amount - _taxes;
        m_Balances[_sender] -= _amount;
        m_Balances[_recipient] += _netAmount;
        m_Balances[address(0)] += _taxes;
        emit Transfer(_sender, _recipient, _netAmount);
    }
    function addLiquidity() external {
        require(!m_Liquidity,"Liquidity already added.");
        m_UniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        m_ExcludedAddresses[address(m_UniswapV2Router)] = true;
        _approve(address(this), address(m_UniswapV2Router), TOTAL_SUPPLY);
        m_UniswapV2Pair = IUniswapV2Factory(m_UniswapV2Router.factory()).createPair(address(this), m_UniswapV2Router.WETH());
        m_UniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,0xdba690433becef6F8398c6672aad1aD4677Ed8C4,block.timestamp);
        m_Liquidity = true;
    }
}