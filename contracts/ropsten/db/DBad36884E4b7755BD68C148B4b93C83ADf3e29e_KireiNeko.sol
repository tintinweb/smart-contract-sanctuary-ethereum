// SPDX-License-Identifier: MIT

/**
███╗░░░███╗███████╗████████╗░█████╗░  ░█████╗░██╗░░██╗███████╗███████╗███╗░░░███╗░██████╗
████╗░████║██╔════╝╚══██╔══╝██╔══██╗  ██╔══██╗██║░░██║██╔════╝██╔════╝████╗░████║██╔════╝
██╔████╔██║█████╗░░░░░██║░░░███████║  ██║░░╚═╝███████║█████╗░░█████╗░░██╔████╔██║╚█████╗░
██║╚██╔╝██║██╔══╝░░░░░██║░░░██╔══██║  ██║░░██╗██╔══██║██╔══╝░░██╔══╝░░██║╚██╔╝██║░╚═══██╗
██║░╚═╝░██║███████╗░░░██║░░░██║░░██║  ╚█████╔╝██║░░██║███████╗███████╗██║░╚═╝░██║██████╔╝
╚═╝░░░░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝  ░╚════╝░╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░░░░╚═╝╚═════╝░
Telegram : @meta_cheems
Website : www.metacheems.live

1% Max Buy & Sell 
2% Max Wallet 

Buy Fee
5% Marketing 
3% Liquidity 

Sell Fee
5% Marketing
5% Liquidity
**/

pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./IPancakeSwapFactory.sol";
import "./IPancakeSwapRouter.sol";
import "./SafeMath.sol";

contract KireiNeko is Context, IBEP20, Ownable {
    
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;

    mapping(address => mapping(address => uint256)) private _allowances;
    
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isExcludedFromMaxWallet;
    address[] private _excluded;

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 10_000_000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 public maxTxAmountBuy = _tTotal / 1; // 100% of supply
    uint256 public maxTxAmountSell = _tTotal / 1; // 100% of supply
    uint256 public maxWalletAmount = _tTotal / 1; // 100% of supply

    address payable public marketingAddress;
    address public liquidityReceiver;

    mapping(address => bool) public isAutomatedMarketMakerPair;

    string private _name;
    string private _symbol;

    bool private inSwapAndLiquify;

    PancakeSwapRouterV2 public PancakeSwapV2Router;
    address public uniswapPair;
    bool public swapAndLiquifyEnabled = true;
    uint256 public numTokensSellToAddToLiquidity = _tTotal / 1000;

    struct feeRatesStruct {
        uint8 marketing;
        uint8 lp;
        uint8 toSwap;
    }

    feeRatesStruct public buyRates =
        feeRatesStruct({
            marketing: 3, // marketing team fee in %
            lp: 1, // lp rate in %
            toSwap: 10 // buyback + marketing + lp
        });

    feeRatesStruct public sellRates =
        feeRatesStruct({
            marketing: 3, // marketing team fee in %
            lp: 1, // lp rate in %
            toSwap: 4 // buyback + marketing + lp
        });

    feeRatesStruct private appliedRates = buyRates;

    struct TotFeesPaidStruct {
        uint256 toSwap;
    }
    TotFeesPaidStruct public totFeesPaid;

    struct valuesFromGetValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rToSwap;
        uint256 tTransferAmount;
        uint256 tToSwap;
    }

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ETHReceived,
        uint256 tokensIntotoSwap
    );
    event LiquidityAdded(uint256 tokenAmount, uint256 ETHAmount);
    event buybackAndmarketingFeesAdded(uint256 marketingFee, uint256 buybackFee);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event BlacklistedUser(address botAddress, bool indexed value);
    event MaxWalletAmountUpdated(uint256 amount);
    event ExcludeFromMaxWallet(address account, bool indexed isExcluded);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(string memory Name, string memory Symbol, address marketingWallet, address liquidityWallet) {
        _name = Name;
        _symbol = Symbol;

        PancakeSwapRouterV2 _PancakeSwapV2Router = PancakeSwapRouterV2(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapPair = IUniswapV2Factory(_PancakeSwapV2Router.factory()).createPair(address(this), _PancakeSwapV2Router.WETH());
        isAutomatedMarketMakerPair[uniswapPair] = true;
        emit SetAutomatedMarketMakerPair(uniswapPair, true);
        PancakeSwapV2Router = _PancakeSwapV2Router;

        _rOwned[owner()] = _rTotal;
        marketingAddress = payable(marketingWallet);
        liquidityReceiver = liquidityWallet;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[marketingAddress] = true;
        _isExcludedFromFee[liquidityReceiver] = true;
        _isExcludedFromFee[address(this)] = true;

        _isExcludedFromMaxWallet[owner()] = true;
        _isExcludedFromMaxWallet[marketingAddress] = true;
        _isExcludedFromMaxWallet[liquidityReceiver] = true;
        _isExcludedFromMaxWallet[address(this)] = true;

        _isExcludedFromMaxWallet[uniswapPair] = true;

        emit Transfer(address(0), owner(), _tTotal);
    }

    //std ERC20:
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    //override ERC20:
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function excludeMultipleAccountsFromMaxWallet(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            require(
                _isExcludedFromMaxWallet[accounts[i]] != excluded,
                "_isExcludedFromMaxWallet already set to that value for one wallet"
            );
            _isExcludedFromMaxWallet[accounts[i]] = excluded;
            emit ExcludeFromMaxWallet(accounts[i], excluded);
        }
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedFromMaxWallet(address account)
        public
        view
        returns (bool)
    {
        return _isExcludedFromMaxWallet[account];
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //  @marketing receive ETH from PancakeSwapV2Router when swapping
    receive() external payable {}

    function _takeToSwap(uint256 rToSwap, uint256 tToSwap) private {
        _rOwned[address(this)] += rToSwap;
        if (_isExcluded[address(this)]) _tOwned[address(this)] += tToSwap;
        totFeesPaid.toSwap += tToSwap;
    }

    function _getValues(uint256 tAmount, bool takeFee)
        private
        view
        returns (valuesFromGetValues memory to_return)
    {
        to_return = _getTValues(tAmount, takeFee);
        (
            to_return.rAmount,
            to_return.rTransferAmount,
            to_return.rToSwap
        ) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }

    function _getTValues(uint256 tAmount, bool takeFee)
        private
        view
        returns (valuesFromGetValues memory s)
    {
        if (!takeFee) {
            s.tTransferAmount = tAmount;
            return s;
        }
        s.tToSwap = (tAmount * appliedRates.toSwap) / 100;
        s.tTransferAmount = tAmount - s.tToSwap;
        return s;
    }

    function _getRValues(
        valuesFromGetValues memory s,
        uint256 tAmount,
        bool takeFee,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rToSwap
        )
    {
        rAmount = tAmount * currentRate;

        if (!takeFee) {
            return ( rAmount, 0, 0);
        }
        rToSwap = s.tToSwap * currentRate;
        rTransferAmount = rAmount - rToSwap;
        return (rAmount, rTransferAmount, rToSwap);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply -= _rOwned[_excluded[i]];
            tSupply -= _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
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
        require(
            amount <= balanceOf(from),
            "You are trying to transfer more than your balance"
        );
        bool takeFee = !(_isExcludedFromFee[from] || _isExcludedFromFee[to]);

        if (takeFee) {
            if (isAutomatedMarketMakerPair[from]) {
                appliedRates = buyRates;
                require(
                    amount <= maxTxAmountBuy,
                    "amount must be <= maxTxAmountBuy"
                );
            } else {
                appliedRates = sellRates;
                require(
                    amount <= maxTxAmountSell,
                    "amount must be <= maxTxAmountSell"
                );
            }
        }

        if (
            balanceOf(address(this)) >= numTokensSellToAddToLiquidity &&
            !inSwapAndLiquify &&
            !isAutomatedMarketMakerPair[from] &&
            swapAndLiquifyEnabled
        ) {
            //add liquidity
            swapAndLiquify(numTokensSellToAddToLiquidity);
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        valuesFromGetValues memory s = _getValues(tAmount, takeFee);

        if (_isExcluded[sender]) {
            _tOwned[sender] -= tAmount;
        }
        if (_isExcluded[recipient]) {
            _tOwned[recipient] += s.tTransferAmount;
        }

        _rOwned[sender] -= s.rAmount;
        _rOwned[recipient] += s.rTransferAmount;
        if (takeFee) {
            _takeToSwap(s.rToSwap, s.tToSwap);
            emit Transfer(sender, address(this), s.tToSwap);
        }
        require(
            _isExcludedFromMaxWallet[recipient] ||
                balanceOf(recipient) <= maxWalletAmount,
            "Recipient cannot hold more than maxWalletAmount"
        );
        emit Transfer(sender, recipient, s.tTransferAmount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 denominator = appliedRates.toSwap * 2;
        uint256 tokensToAddLiquidityWith = (contractTokenBalance *
            appliedRates.lp) / denominator;
        uint256 toSwap = contractTokenBalance - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForETH(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 ETHToAddLiquidityWith = (deltaBalance * appliedRates.lp) /
            (denominator - appliedRates.lp);

        // add liquidity
        addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith);

        // we give the remaining tax to marketing
        uint256 remainingBalance = address(this).balance;
        uint256 marketingFee = (remainingBalance * appliedRates.marketing) / (denominator - appliedRates.marketing);
        marketingAddress.transfer(marketingFee);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the pair path of token
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = PancakeSwapV2Router.WETH();

        if (allowance(address(this), address(PancakeSwapV2Router)) < tokenAmount) {
            _approve(address(this), address(PancakeSwapV2Router), ~uint256(0));
        }

        // make the swap
        PancakeSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        // add the liquidity
        PancakeSwapV2Router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityReceiver,
            block.timestamp
        );
        emit LiquidityAdded(tokenAmount, ETHAmount);
    }

    function setAutomatedMarketMakerPair(address _pair, bool value)
        external
        onlyOwner
    {
        require(
            isAutomatedMarketMakerPair[_pair] != value,
            "Automated market maker pair is already set to that value"
        );
        isAutomatedMarketMakerPair[_pair] = value;
        if (value) {
            _isExcludedFromMaxWallet[_pair] = true;
            emit ExcludeFromMaxWallet(_pair, value);
        }
        emit SetAutomatedMarketMakerPair(_pair, value);
    }

    function setNumTokensSellToAddToLiq(uint256 amountTokens)
        external
        onlyOwner
    {
        numTokensSellToAddToLiquidity = amountTokens * 10**_decimals;
    }

    function setmarketingAddress(address payable _marketingAddress) external onlyOwner {
        marketingAddress = _marketingAddress;
    }

    function manualSwapAndAddToLiq() external onlyOwner {
        swapAndLiquify(balanceOf(address(this)));
    }

    function excludeFromMaxWallet(address account, bool excluded)
        external
        onlyOwner
    {
        require(
            _isExcludedFromMaxWallet[account] != excluded,
            "_isExcludedFromMaxWallet already set to that value"
        );
        _isExcludedFromMaxWallet[account] = excluded;

        emit ExcludeFromMaxWallet(account, excluded);
    }
}