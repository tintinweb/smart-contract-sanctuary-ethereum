/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

/*

Common Cents (CMCNT)

Website:
https://commoncentscoin.io

Twitter:
https://twitter.com/CommonCentsio

Telegram:
https://t.me/CommonCentsCoin

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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract CommonCents is Context, IERC20, Ownable {
    
    using SafeMath for uint256;

    string private constant _name = "Common Cents";
    string private constant _symbol = "CMCNT";
    uint8 private constant _decimals = 18;

    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    //Buy Fee
    uint256 private _redisFeeOnBuy = 1;
    uint256 private _taxFeeOnBuy = 800; //8%

    //Sell Fee
    uint256 private _redisFeeOnSell = 1;
    uint256 private _taxFeeOnSell = 800; //8%

    //Original Fee
    uint256 private _redisFee = _redisFeeOnSell;
    uint256 private _taxFee = _taxFeeOnSell.div(100);
    
    uint256 private _previousredisFee = _redisFee;
    uint256 private _previoustaxFee = _taxFee;

    mapping(address => bool) public bots;
    mapping(address => bool) public preTrader;

    mapping (uint256 => address) private taxWallets;
    mapping (uint256 => uint256) private taxWalletAllocs;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = true;
    
    uint256 public _maxTxAmount = _tTotal.mul(20).div(10000); //0.20%
    uint256 public _maxWalletSize = _tTotal.mul(50).div(10000); //0.50%
    uint256 public _cSwapTokensAtAmount = _tTotal.mul(5).div(10000); //0.05%
    uint256 public _cSwapTokensMaxAmount = _tTotal.mul(10).div(10000); //0.1%

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        
        _rOwned[_msgSender()] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        taxWallets[1] = 0x561ab7c63Cb9ebc2852c6c0C885A80E38298a050; //Marketing
        taxWallets[2] = 0xa56aA6ee1449cee11503881Aa767F41BD0fA7c82; //Development
        taxWallets[3] = 0x1705d2364f9c8b446aE3b453029221E2246258A9; //Political

        taxWalletAllocs[1] = 5;
        taxWalletAllocs[2] = 2;
        taxWalletAllocs[3] = 1;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[taxWallets[1]] = true;
        _isExcludedFromFee[taxWallets[2]] = true;
        _isExcludedFromFee[taxWallets[3]] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if (_redisFee == 0 && _taxFee == 0) return;
    
        _previousredisFee = _redisFee;
        _previoustaxFee = _taxFee;
        
        _redisFee = 0;
        _taxFee = 0;
    }

    function restoreAllFee() private {
        _redisFee = _previousredisFee;
        _taxFee = _previoustaxFee;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = false;
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            
            takeFee = true;

            //Trade start check
            if(!tradingOpen) {
                require(preTrader[from], "TOKEN: Trading not open yet");
            }
            
            require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");
            require(!bots[from] && !bots[to], "TOKEN: Your account is blacklisted!");
            
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {
                require(balanceOf(to) + amount <= _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
            }

            //BUY
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {

                _redisFee = _redisFeeOnBuy;
                _taxFee = _taxFeeOnBuy.div(100);

            } else if(to == uniswapV2Pair && from != address(uniswapV2Router)) { //SELL
            
                _redisFee = _redisFeeOnSell;
                _taxFee = _taxFeeOnSell.div(100);

                //Check token balance for performing tax distributions
                uint256 contractTokenBalance = balanceOf(address(this));

                if(contractTokenBalance >= _cSwapTokensMaxAmount) {
                    contractTokenBalance = _cSwapTokensMaxAmount;
                }
                
                if (contractTokenBalance >= _cSwapTokensAtAmount && !inSwap && swapEnabled) {
                    processDistributions(contractTokenBalance);
                }
            }

            //No tax on transfers
            if(from != uniswapV2Pair && to != uniswapV2Pair) {
                takeFee = false;
            }

        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function processDistributions(uint256 tokens) private {
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newETHBalance = address(this).balance.sub(initialETHBalance);

        //Send to taxWallet
        uint256 totalAllocation = taxWalletAllocs[1] + taxWalletAllocs[2] + taxWalletAllocs[3];
        payable(taxWallets[1]).transfer(newETHBalance*taxWalletAllocs[1]/totalAllocation);
        payable(taxWallets[2]).transfer(newETHBalance*taxWalletAllocs[2]/totalAllocation);
        payable(taxWallets[3]).transfer(newETHBalance*taxWalletAllocs[3]/totalAllocation);

    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) =
            _getTValues(tAmount, _redisFee, _taxFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tTeam, currentRate);
        
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(
        uint256 tAmount,
        uint256 redisFee,
        uint256 taxFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(redisFee).div(100);
        uint256 tTeam = tAmount.mul(taxFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);

        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);

        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();

        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
    
        return (rSupply, tSupply);
    }
    
    /**
     * @dev Opens trading
     */
    function setTrading(bool _tradingOpen) external onlyOwner {
        tradingOpen = _tradingOpen;
    }

    /**
     * @dev Triggers the tax handling functionality for manual use. Enter 0 to processDistribute on all contract balance
     */
    function manualDistributeTax(uint256 _tokens) external onlyOwner {
        uint256 tokens = _tokens;
        if(_tokens == 0) {
            tokens = balanceOf(address(this));
        }
        processDistributions(tokens);
    }

    /**
     * @dev Block any potential bots or snipers from transferring tokens
     */
    function blockBots(address[] memory bots_) external onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    /**
     * @dev Unblock bots
     */
    function unblockBot(address notbot) external onlyOwner {
        bots[notbot] = false;
    }

    /**
     * @dev Set fee for the project
     */
    function setFee(uint256 redisFeeOnBuy, uint256 redisFeeOnSell, uint256 taxFeeOnBuy, uint256 taxFeeOnSell) external onlyOwner {
        
        //Hard cap check to prevent honeypot
        require(_redisFeeOnBuy + _taxFeeOnBuy <= 10, "Cannot set tax more than 10%");
        require(_redisFeeOnSell + _taxFeeOnSell <= 10, "Cannot set tax more than 10%");
        
        _redisFeeOnBuy = redisFeeOnBuy;
        _redisFeeOnSell = redisFeeOnSell;
        
        _taxFeeOnBuy = taxFeeOnBuy;
        _taxFeeOnSell = taxFeeOnSell;
    
    }
    
    /**
     * @dev Bypass any fee or limits
     */
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }

    /**
     * @dev Set minimum tokens required for contract to swap for Smooth tax Distribution
     */
    function setContractMinTokensToSwap(uint256 tokens) external onlyOwner {
        _cSwapTokensAtAmount = tokens;
    }

    /**
     * @dev Set maximum tokens contract can swap at once for Smooth tax Distribution
     */
    function setContractSwapMaxTokens(uint256 tokens) external onlyOwner {
        _cSwapTokensMaxAmount = tokens;
    }

    /**
     * @dev Set tax wallets
     */
    function setTaxWallets(uint256 taxWalletID, address addr, uint256 percent) external onlyOwner {
        taxWallets[taxWalletID] = addr;
        taxWalletAllocs[taxWalletID] = percent;
    }
    
    /**
     * @dev Set whether contract should distribute tax automatically
     */    
    function toggleSwap(bool _swapEnabled) external onlyOwner {
        swapEnabled = _swapEnabled;
    }
    
    /**
     * @dev Set maximum amount of tokens an address can buy at once
     */   
    function setMaxTxnAmount(uint256 maxTxAmount) external onlyOwner {
        require(maxTxAmount >= _tTotal.mul(1).div(10000), "Cannot set less than 0.01% of supply");
        _maxTxAmount = maxTxAmount;
    }
       
    /**
     * @dev Set how much each wallet can hold
     */   
    function setMaxWalletSize(uint256 maxWalletSize) external onlyOwner {
        require(maxWalletSize >= _tTotal.mul(1).div(10000), "Cannot set less than 0.01% of supply");
        _maxWalletSize = maxWalletSize;
    }
 
    /**
    * @dev Allow wallets to operate when trade open
    */   
    function allowPreTrading(address account, bool allowed) external onlyOwner {
        require(preTrader[account] != allowed, "TOKEN: Already enabled.");
        preTrader[account] = allowed;
    }

    /**
     * @dev Airdrop to multiple wallets
     */   
    function multiSend(address[] calldata addresses, uint256[] calldata amounts) external onlyOwner {
        require(addresses.length == amounts.length, "Must be the same length");
        for(uint256 i = 0; i < addresses.length; i++) {
            _transfer(_msgSender(), addresses[i], amounts[i] * 10**18);
        }
    }

    /**
     * @dev Claim any stuck eth/tokens from contract
     */   
    function claimStuckTokens(address _token) external onlyOwner {
        if(_token == address(0x0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }
        IERC20 erc20token = IERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(owner(), balance);
    }
    
}