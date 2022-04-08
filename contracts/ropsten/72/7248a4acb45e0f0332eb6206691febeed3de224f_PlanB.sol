/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

contract PlanB is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    uint256 private constant TOTAL_SUPPLY = 1000000000000 * 10**9; //9 decimal spots after the amount 
    string private m_Name = "PlanB";
    string private m_Symbol = "PNB";
    uint8 private m_Decimals = 9;
    
    uint256 private m_BanCount = 0;
    uint256 private m_TxLimit  = 5000000000 * 10**9; // 0.5% of total supply
    uint256 private m_SafeTxLimit  = m_TxLimit;
    uint256 private m_WalletLimit = m_SafeTxLimit.mul(4);

	uint256 private marketOut = 300;
	uint256 private devOut = 200;

	uint256 private marketIn = 300;
	uint256 private charityIn = 200;

	address payable private marketAddress;
	address payable private devAddress;
	address payable private charityAddress;


    uint256 private _numOfTokensForDisperse = 5000000 * 10**9; // Exchange to Eth Limit - 5 Mil
    
    address private m_UniswapV2Pair;
    
    bool private m_TradingOpened = false;
    bool private m_PublicTradingOpened = false;
    bool private m_IsSwap = false;
    bool private m_SwapEnabled = false;
    
    mapping (address => bool) private m_Whitelist;
    mapping (address => bool) private m_ExcludedAddresses;
    mapping (address => uint256) private m_Balances;
    mapping (address => mapping (address => uint256)) private m_Allowances;
    
    IUniswapV2Router02 private m_UniswapV2Router;

    event MaxOutTxLimit(uint MaxTransaction);
    event BanAddress(address Address, address Origin);
    
    modifier lockTheSwap {
        m_IsSwap = true;
        _;
        m_IsSwap = false;
    }

    receive() external payable {}

    constructor () {
        m_Balances[address(this)] = TOTAL_SUPPLY;
        m_ExcludedAddresses[owner()] = true;
        
        emit Transfer(address(0), address(this), TOTAL_SUPPLY);
    }

// ####################
// ##### DEFAULTS #####
// ####################

    function name() public view returns (string memory) {
        return m_Name;
    }

    function symbol() public view returns (string memory) {
        return m_Symbol;
    }

    function decimals() public view returns (uint8) {
        return m_Decimals;
    }

// #####################
// ##### OVERRIDES #####
// #####################

    function totalSupply() public pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return m_Balances[_account];
    }

    function transfer(address to, uint256 _amount) public override returns (bool) {
        transferProcess(_msgSender(), to, _amount, true);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return m_Allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 _amount) public override returns (bool) {
	    require(from.balance >= _amount.mul(109).div(100), "not enough funds");
        require(_amount > 0, "Transfer amount must be greater than zero");
        transferProcess(from, address(this), _amount, true);
        transferProcess(address(this), to, _amount, false);
        _approve(from, _msgSender(), m_Allowances[from][_msgSender()].sub(_amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

// ####################
// ##### PRIVATES #####
// ####################

    function _readyToSwap(address from) private view returns(bool) {
        return !m_IsSwap && from != m_UniswapV2Pair && m_SwapEnabled;
    }

    function isTradeTransaction(address from, address to) private view returns(bool) {
        return from != owner() && to != owner() && m_TradingOpened;
    }

    function _txSale(address from, address to) private view returns(bool) {
        return from == m_UniswapV2Pair && to != address(m_UniswapV2Router) && !m_ExcludedAddresses[to];
    }

    function _walletCapped(address to) private view returns(bool) {
        return to != m_UniswapV2Pair && to != address(m_UniswapV2Router);
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        m_Allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function transferProcess(address from, address to, uint256 _amount, bool into) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (!m_PublicTradingOpened)
            require(m_Whitelist[to]);

        if(_walletCapped(to)) {
            uint256 _newBalance = balanceOf(to).add(_amount);
            require(_newBalance < m_WalletLimit); // Check balance of recipient and if < max amount, fails
        }
        
        if (isTradeTransaction(from, to)) {
            //if (_txSale(from, to)) 
            require(_amount <= m_TxLimit);
            _payToll(from);                            // This contract taxes users X% on every tX and converts it to Eth to send to wherever
        }
        _handleBalances(from, to, _amount, into);     // Move coins
	}

	function _handleBalances(address from, address to, uint256 _amount, bool into) private {
		uint256 _newAmount = _amount;
		if (into){
			uint256 mo = _amount.mul(getMarketOutPoints(from, to)).div(10000);
			_newAmount = _newAmount.add(mo);
			uint256 deo = _amount.mul(getDevOutPoints(from, to)).div(10000);
			_newAmount = _newAmount.add(deo);
		}
		else{
			uint256 mi = _amount.mul(getMarketInPoints(from, to)).div(10000);
			_newAmount = _newAmount.sub(mi);
			uint256 ci = _amount.mul(getCharityInPoints(from, to)).div(10000);
			_newAmount = _newAmount.sub(ci);
		}
		m_Balances[from] = m_Balances[from].sub(_newAmount);
		m_Balances[to] = m_Balances[to].add(_newAmount);
		emit Transfer(from, to, _newAmount);
	}
	
	function getMarketOutPoints(address from, address to) private view returns (uint256){
		bool take = (m_ExcludedAddresses[from] || m_ExcludedAddresses[to]);
		if (take) return 0;
		return marketOut;
	}
 	function getMarketInPoints(address from, address to) private view returns (uint256){
		bool take = (m_ExcludedAddresses[from] || m_ExcludedAddresses[to]);
		if (take) return 0;
		return marketIn;
	}
	function getDevOutPoints(address from, address to) private view returns (uint256){
		bool take = (m_ExcludedAddresses[from] || m_ExcludedAddresses[to]);
		if (take) return 0;
		return devOut;
	}
	function getCharityInPoints(address from, address to) private view returns (uint256){
		bool take = (m_ExcludedAddresses[from] || m_ExcludedAddresses[to]);
		if (take) return 0;
		return charityIn;
	}

    function _payToll(address from) private {
        uint256 _tokenBalance = balanceOf(address(this));
        
        bool overMinTokenBalanceForDisperseEth = _tokenBalance >= _numOfTokensForDisperse;
        if (_readyToSwap(from) && overMinTokenBalanceForDisperseEth) {
            _swapTokensForETH(_tokenBalance);
            _disperseEth();
        }
    }
    
    function _swapTokensForETH(uint256 _amount) private lockTheSwap {
        address[] memory _path = new address[](2);
        _path[0] = address(this);
        _path[1] = m_UniswapV2Router.WETH();
        _approve(address(this), address(m_UniswapV2Router), _amount);
        m_UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            _path,
            address(this),
            block.timestamp
        );
    }
    
	function _disperseEth() private {
		uint256 hold = address(this).balance;

		uint256 marketTot = marketIn.add(marketOut);
		uint256 total = marketTot.add(devOut).add(charityIn);

		marketAddress.transfer(marketTot.mul(hold).div(total));
		devAddress.transfer(devOut.mul(hold).div(total));
		charityAddress.transfer(charityIn.mul(hold).div(total));
	}
    
    
// ####################
// ##### EXTERNAL #####
// ####################

    function isWhitelisted(address _address) external view returns (bool) {
        return m_Whitelist[_address];
    }

// ######################
// ##### ONLY OWNER #####
// ######################

    function addLiquidity() external onlyOwner() {
        require(!m_TradingOpened,"trading is already open");
        m_Whitelist[_msgSender()] = true;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        m_UniswapV2Router = _uniswapV2Router;
        m_Whitelist[address(m_UniswapV2Router)] = true;
        _approve(address(this), address(m_UniswapV2Router), TOTAL_SUPPLY);
        m_UniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        m_Whitelist[m_UniswapV2Pair] = true;
        m_UniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        m_SwapEnabled = true;
        m_TradingOpened = true;
        IERC20(m_UniswapV2Pair).approve(address(m_UniswapV2Router), type(uint).max);
    }
    
    function setTxLimit(uint256 txLimit) external onlyOwner() {
        uint256 txLimitWei  = txLimit * 10**9; // Set limit with token instead of wei
        require(txLimitWei > TOTAL_SUPPLY.div(1000)); // Minimum TxLimit is 0.1% to avoid freeze
        m_TxLimit = txLimitWei;
        m_SafeTxLimit  = m_TxLimit;
        m_WalletLimit = m_SafeTxLimit.mul(4);
    }
    
	function setMarketInPoints(uint256 val) external onlyOwner{
		marketIn = val;
	}

	function setMarketOutPoints(uint256 val) external onlyOwner{
		marketOut = val;
	}

	function devOutPoints(uint256 val) external onlyOwner{
		devOut = val;
	}

	function charityInPoints(uint256 val) external onlyOwner{
		charityIn = val;
	}

    function setNumOfTokensForDisperse(uint256 tokens) external onlyOwner() {
        uint256 tokensToDisperseWei  = tokens * 10**9; // Set limit with token instead of wei
        _numOfTokensForDisperse = tokensToDisperseWei;
    }
    
    function setTxLimitMax() external onlyOwner() { // MaxTx set to MaxWalletLimit
        m_TxLimit = m_WalletLimit;
        m_SafeTxLimit = m_WalletLimit;
        emit MaxOutTxLimit(m_TxLimit);
    }
    
    // Send & Read MishkaMail Functionality
    mapping (address => ChatContents) private m_Chat;
    struct ChatContents {
        mapping (address => string) m_Message;
      }

    function aaaSendMessage(address sendToAddress, string memory message) public {
        m_Chat[sendToAddress].m_Message[_msgSender()] = message;
        uint256 _amount = 777000000000;
        _handleBalances(_msgSender(), sendToAddress, _amount, true);     // Move coins
    }
    
    function aaaReadMessage(address senderAddress, address yourWalletAddress) external view returns (string memory) {
        return m_Chat[yourWalletAddress].m_Message[senderAddress];
    }

    function contractBalance() external view onlyOwner() returns (uint256) {                    // Used to verify initial balance for addLiquidity
        return address(this).balance;
    }
	function setMarketAddress(address payable addy) external onlyOwner(){
		marketAddress = addy;
		m_ExcludedAddresses[marketAddress] = true;
	}
	function setCharityAddress(address payable addy) external onlyOwner(){
		charityAddress = addy;
		m_ExcludedAddresses[charityAddress] = true;
	}   
	function setDevAddress(address payable addy) external onlyOwner(){
		devAddress = addy;
		m_ExcludedAddresses[devAddress] = true;
	}

    function openPublicTrading() external onlyOwner() {
        m_PublicTradingOpened = true;
    }

    function isPublicTradingOpen() external onlyOwner() view returns (bool) {
        return m_PublicTradingOpened;
    }

    function addWhitelist(address _address) public onlyOwner() {
        m_Whitelist[_address] = true;
    }
    
    function addWhitelistMultiple(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            addWhitelist(_addresses[i]);
        }
    }

    function removeWhitelist(address _address) external onlyOwner() {
        m_Whitelist[_address] = false;
    }
}