// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";
import "./ECDSA.sol";


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

contract Pesabase is Context, IERC20, Ownable, AccessControl {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    IUniswapV2Router02 private uniswapV2Router;

    mapping (address => uint) private cooldown;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;

    mapping (address => uint256) public replayNonce;

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;
    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;

    uint8 private constant _decimals = 9;
    uint8 private _sunday = 0;
    uint8 private _saturday = 6;
    uint8 private _openingTimeHr = 13;
    uint8 private _closingTimeHr = 19;
    uint8 private _openingTimeMin = 30;

    uint16 constant ORIGIN_YEAR = 1970;

    uint256 private constant _tTotal = 6e7 * 10**(_decimals);
    uint256 private _buyMarketingFee = 2;
    uint256 private _buyPreviousMarketingFee = _buyMarketingFee;
    uint256 private _buyDevelopmentFee = 3;
    uint256 private _buyPreviousDevelopmentFee = _buyDevelopmentFee;
    uint256 private _buyLiquidityFee = 2;
    uint256 private _buyPreviousLiquidityFee = _buyLiquidityFee;
    uint256 private _buyDreamFee = 2;
    uint256 private _buyPreviousDreamFee = _buyDreamFee;
    uint256 private _buyCharityFee = 1;
    uint256 private _buyPreviousCharityFee = _buyCharityFee;
    uint256 private _sellMarketingFee = 2;
    uint256 private _sellPreviousMarketingFee = _sellMarketingFee;
    uint256 private _sellDevelopmentFee = 3;
    uint256 private _sellPreviousDevelopmentFee = _sellDevelopmentFee;
    uint256 private _sellLiquidityFee = 2;
    uint256 private _sellPreviousLiquidityFee = _sellLiquidityFee;
    uint256 private _sellDreamFee = 2;
    uint256 private _sellPreviousDreamFee = _sellDreamFee;
    uint256 private _sellCharityFee = 1;
    uint256 private _sellPreviousCharityFee = _sellCharityFee;
    uint256 private tokensForMarketing;
    uint256 private tokensForDev;
    uint256 private tokensForLiquidity;
    uint256 private tokensForDream;
    uint256 private tokensForCharity;
    uint256 private tradingActiveBlock = 0;
    uint256 private blocksToBlacklist = 1;
    uint256 public _maxBuyAmount = _tTotal;
    uint256 public _maxSellAmount = _tTotal;
    uint256 public _maxWalletAmount = _tTotal;
    uint256 private swapTokensAtAmount = 0;

    address private uniswapV2Pair;
    address payable private _marketingWallet;
    address payable private _developmentWallet;
    address payable private _liquidityWallet;
    address payable private _dreamWallet;
    address payable private _charityWallet;
    
    string private constant _name = "Pesabase";
    string private constant _symbol = "PESA";
    
    bool private tradingOpen;
    bool private swapping;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    bool private marketHoursEnabled = false;
    bool private checkHolidays = false;
    bool private isSpecialEvent = false;


    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");


    struct _DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
            }
    
    event MaxBuyAmountUpdated(uint _maxBuyAmount);
    event MaxSellAmountUpdated(uint _maxSellAmount);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor (address mktg, address dev, address lp, address dream, address charity) {
        _marketingWallet = payable(mktg);
        _developmentWallet = payable(dev);
        _liquidityWallet = payable(lp);
        _dreamWallet = payable(dream);
        _charityWallet = payable(charity);
        _rOwned[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingWallet] = true;
        _isExcludedFromFee[_developmentWallet] = true;
        _isExcludedFromFee[_liquidityWallet] = true;
        _isExcludedFromFee[_dreamWallet] = true;
        _isExcludedFromFee[_charityWallet] = true;
        _setupRole(DEFAULT_ADMIN_ROLE,owner());
        _setupRole(RELAYER_ROLE, owner());
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
        return _rOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        cooldownEnabled = onoff;
    }

    function setMarketHoursEnabled(bool onoff) external onlyOwner() {
        marketHoursEnabled = onoff;
    }

    function setCheckHolidaysEnabled(bool onoff) external onlyOwner() {
        checkHolidays = onoff;
    }

    function setSpecialEvent(bool onoff) external onlyOwner() {
        isSpecialEvent = onoff;
    }

    function setSwapEnabled(bool onoff) external onlyOwner(){
        swapEnabled = onoff;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool takeFee = false;
        bool shouldSwap = false;
        if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {
            require(!bots[from] && !bots[to]);

            if (marketHoursEnabled && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                require(marketOpened(block.timestamp), "Market is closed.");
            }

            if (cooldownEnabled){
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)){
                    require(cooldown[tx.origin] < block.number - 1 && cooldown[to] < block.number - 1, "_transfer:: Transfer Delay enabled.  Try again later.");
                    cooldown[tx.origin] = block.number;
                    cooldown[to] = block.number;
                }
            }

            takeFee = true;
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(tradingOpen, "Trading is not allowed yet.");
                require(amount <= _maxBuyAmount, "Transfer amount exceeds the maxBuyAmount.");
                require(balanceOf(to) + amount <= _maxWalletAmount, "Exceeds maximum wallet token amount.");
            }
            
            if (to == uniswapV2Pair && from != address(uniswapV2Router) && !_isExcludedFromFee[from]) {
                require(tradingOpen, "Trading is not allowed yet.");
                require(amount <= _maxSellAmount, "Transfer amount exceeds the maxSellAmount.");
                shouldSwap = true;
            }
        }

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = (contractTokenBalance > swapTokensAtAmount) && shouldSwap;

        if (canSwap && swapEnabled && !swapping && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        _tokenTransfer(from,to,amount,takeFee, shouldSwap);
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing + tokensForDev + tokensForDream + tokensForCharity;
        bool success;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 5) {
            contractBalance = swapTokensAtAmount * 5;
        }
        
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH); 
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        
        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(totalTokensToSwap);
        uint256 ethForDev = ethBalance.mul(tokensForDev).div(totalTokensToSwap);
        uint256 ethForDream = ethBalance.mul(tokensForDream).div(totalTokensToSwap);
        uint256 ethForCharity = ethBalance.mul(tokensForCharity).div(totalTokensToSwap);
        
        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForDev - ethForDream - ethForCharity;
        
        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForDev = 0;
        tokensForDream = 0;
        tokensForCharity = 0;
        
        (success,) = address(_developmentWallet).call{value: ethForDev}("");
        (success,) = address(_dreamWallet).call{value: ethForDream}("");
        (success,) = address(_charityWallet).call{value: ethForCharity}("");
        
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        }
        
        
        (success,) = address(_marketingWallet).call{value: address(this).balance}("");
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _liquidityWallet,
            block.timestamp
        );
    }
        
    function sendETHToFee(uint256 amount) private {
        _marketingWallet.transfer(amount.div(2));
        _developmentWallet.transfer(amount.div(2));
    }
    
    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        cooldownEnabled = true;
        marketHoursEnabled = true;
        checkHolidays = true;
        _maxBuyAmount = 15e4 * 10**(_decimals);
        _maxSellAmount = 15e4 * 10**(_decimals);
        _maxWalletAmount = 6e5 * 10**(_decimals);
        swapTokensAtAmount = 1e3 * 10**(_decimals);
        tradingOpen = true;
        tradingActiveBlock = block.number;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }
    
    function setBots(address[] memory bots_, bool isBot) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = isBot;
        }
    }

    function setMaxBuyAmount(uint256 maxBuy) public onlyOwner {
        require(maxBuy >= 3e4 * 10**(_decimals), "Swap amount cannot be less than 0.05% total supply.");
        _maxBuyAmount = maxBuy;
    }

    function setMaxSellAmount(uint256 maxSell) public onlyOwner {
        require(maxSell >= 3e4 * 10**(_decimals), "Swap amount cannot be less than 0.05% total supply.");
        _maxSellAmount = maxSell;
    }
    
    function setMaxWalletAmount(uint256 maxToken) public onlyOwner {
        _maxWalletAmount = maxToken;
    }
    
    function setSwapTokensAtAmount(uint256 newAmount) public onlyOwner {
        require(newAmount >= 6e2 * 10**(_decimals), "Swap amount cannot be lower than 0.001% total supply.");
        require(newAmount <= 3e4 * 10**(_decimals), "Swap amount cannot be higher than 0.5% total supply.");
        swapTokensAtAmount = newAmount;
    }

    function setMarketingWallet(address marketingWallet) public onlyOwner() {
        require(marketingWallet != address(0), "marketingWallet address cannot be 0");
        _isExcludedFromFee[_marketingWallet] = false;
        _marketingWallet = payable(marketingWallet);
        _isExcludedFromFee[_marketingWallet] = true;
    }

    function setDevelopmentWallet(address developmentWallet) public onlyOwner() {
        require(developmentWallet != address(0), "developmentWallet address cannot be 0");
        _isExcludedFromFee[_developmentWallet] = false;
        _developmentWallet = payable(developmentWallet);
        _isExcludedFromFee[_developmentWallet] = true;
    }

    function setLiquidityWallet(address liquidityWallet) public onlyOwner() {
        require(liquidityWallet != address(0), "liquidityWallet address cannot be 0");
        _isExcludedFromFee[_liquidityWallet] = false;
        _liquidityWallet = payable(liquidityWallet);
        _isExcludedFromFee[_liquidityWallet] = true;
    }

    function setDreamWallet(address dreamWallet) public onlyOwner() {
        require(dreamWallet != address(0), "dreamWallet address cannot be 0");
        _isExcludedFromFee[_dreamWallet] = false;
        _dreamWallet = payable(dreamWallet);
        _isExcludedFromFee[_dreamWallet] = true;
    }

    function setCharityWallet(address charityWallet) public onlyOwner() {
        require(charityWallet != address(0), "charityWallet address cannot be 0");
        _isExcludedFromFee[_charityWallet] = false;
        _charityWallet = payable(charityWallet);
        _isExcludedFromFee[_charityWallet] = true;
    }

    function excludeFromFee(address[] memory accounts, bool isExcluded) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = isExcluded;
        }
    }

    function setBuyFee(uint256 buyMarketingFee, uint256 buyLiquidityFee, uint256 buyDevelopmentFee, uint256 buyDreamFee, uint256 buyCharityFee) external onlyOwner {
        require(buyMarketingFee + buyLiquidityFee + buyDevelopmentFee + buyDreamFee + buyCharityFee <= 30, "Must keep buy taxes below 30%");
        _buyMarketingFee = buyMarketingFee;
        _buyLiquidityFee = buyLiquidityFee;
        _buyDevelopmentFee = buyDevelopmentFee;
        _buyDreamFee = buyDreamFee;
        _buyCharityFee = buyCharityFee;
    }

    function setSellFee(uint256 sellMarketingFee, uint256 sellLiquidityFee, uint256 sellDevelopmentFee, uint256 sellDreamFee, uint256 sellCharityFee) external onlyOwner {
        require(sellMarketingFee + sellLiquidityFee + sellDevelopmentFee + sellDreamFee + sellCharityFee <= 30, "Must keep sell taxes below 30%");
        _sellMarketingFee = sellMarketingFee;
        _sellLiquidityFee = sellLiquidityFee;
        _sellDevelopmentFee = sellDevelopmentFee;
        _sellDreamFee = sellDreamFee;
        _sellCharityFee = sellCharityFee;
    }

    function setBlocksToBlacklist(uint256 blocks) public onlyOwner {
        blocksToBlacklist = blocks;
    }

    function removeAllFee() private {
        if(_buyMarketingFee == 0 && _buyLiquidityFee == 0 && _buyDevelopmentFee == 0 && _buyDreamFee == 0 && _buyCharityFee == 0 && _sellMarketingFee == 0 && _sellLiquidityFee == 0 && _sellDevelopmentFee == 0 && _sellDreamFee == 0 && _sellCharityFee == 0) return;
        
        _buyPreviousMarketingFee = _buyMarketingFee;
        _buyPreviousLiquidityFee = _buyLiquidityFee;
        _buyPreviousDevelopmentFee = _buyDevelopmentFee;
        _buyPreviousDreamFee = _buyDreamFee;
        _buyPreviousCharityFee = _buyCharityFee;
        _sellPreviousMarketingFee = _sellMarketingFee;
        _sellPreviousLiquidityFee = _sellLiquidityFee;
        _sellPreviousDevelopmentFee = _sellDevelopmentFee;
        _sellPreviousDreamFee = _sellDreamFee;
        _sellPreviousCharityFee = _sellCharityFee;
        
        _buyMarketingFee = 0;
        _buyLiquidityFee = 0;
        _buyDevelopmentFee = 0;
        _buyDreamFee = 0;
        _buyCharityFee = 0;
        _sellMarketingFee = 0;
        _sellLiquidityFee = 0;
        _sellDevelopmentFee = 0;
        _sellDreamFee = 0;
        _sellCharityFee = 0;
    }
    
    function restoreAllFee() private {
        _buyMarketingFee = _buyPreviousMarketingFee;
        _buyLiquidityFee = _buyPreviousLiquidityFee;
        _buyDevelopmentFee = _buyPreviousDevelopmentFee;
        _buyDreamFee = _buyPreviousDreamFee;
        _buyCharityFee = _buyPreviousCharityFee;
        _sellMarketingFee = _sellPreviousMarketingFee;
        _sellLiquidityFee = _sellPreviousLiquidityFee;
        _sellDevelopmentFee = _sellPreviousDevelopmentFee;
        _sellDreamFee = _sellPreviousDreamFee;
        _sellCharityFee = _sellPreviousCharityFee;
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool isSell) private {
        if(!takeFee) {
            removeAllFee();
        } else {
            amount = _takeFees(sender, amount, isSell);
        }

        _transferStandard(sender, recipient, amount);
        
        if(!takeFee) {
            restoreAllFee();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _takeFees(address sender, uint256 amount, bool isSell) private returns (uint256) {
        uint256 _totalFees;
        uint256 mktgFee;
        uint256 devFee;
        uint256 liqFee;
        uint256 dreamFee;
        uint256 charityFee;
        if(tradingActiveBlock + blocksToBlacklist >= block.number){
            _totalFees = 99;
            mktgFee = 25;
            devFee = 25;
            liqFee = 25;
            dreamFee = 25;
            charityFee = 24;
        } else {
            _totalFees = _getTotalFees(isSell);
            if (isSell) {
                mktgFee = _sellMarketingFee;
                devFee = _sellDevelopmentFee;
                liqFee = _sellLiquidityFee;
                dreamFee = _sellDreamFee;
                charityFee = _sellCharityFee;
            } else {
                mktgFee = _buyMarketingFee;
                devFee = _buyDevelopmentFee;
                liqFee = _buyLiquidityFee;
                dreamFee = _buyDreamFee;
                charityFee = _buyCharityFee;
            }
        }

        uint256 fees = amount.mul(_totalFees).div(100);
        tokensForMarketing += fees * mktgFee / _totalFees;
        tokensForDev += fees * devFee / _totalFees;
        tokensForLiquidity += fees * liqFee / _totalFees;
        tokensForDream += fees * dreamFee / _totalFees;
        tokensForCharity += fees * charityFee / _totalFees;
            
        if(fees > 0) {
            _transferStandard(sender, address(this), fees);
        }
            
        return amount -= fees;
    }

    receive() external payable {}
    
    function manualswap() public onlyOwner() {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() public onlyOwner() {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function _getTotalFees(bool isSell) private view returns(uint256) {
        if (isSell) {
            return _sellMarketingFee + _sellDevelopmentFee + _sellLiquidityFee + _sellDreamFee + _sellCharityFee;
        }
        return _buyMarketingFee + _buyDevelopmentFee + _buyLiquidityFee + _buyDreamFee + _buyCharityFee;
    }

    function marketOpened(uint timestamp) public view returns (bool) {
        _DateTime memory dt = parseTimestamp(timestamp);
        if (dt.weekday == _sunday || dt.weekday == _saturday) {
            return false;
        }
        if (dt.hour < _openingTimeHr || dt.hour > _closingTimeHr) {
            return false;
        }
        if (dt.hour == _openingTimeHr && dt.minute < _openingTimeMin) {
            return false;
        }
        if (checkHolidays) {
            if (dt.month == 1 && (dt.day == 1 || dt.day == 16)) {
                return false;
            }
            if (dt.month == 2 && dt.day == 20) {
                return false;
            }
            if (dt.month == 4 && dt.day == 15) {
                return false;
            }
            if (dt.month == 5 && dt.day == 30) {
                return false;
            }
            if (dt.month == 6 && dt.day == 20) {
                return false;
            }
            if (dt.month == 7 && dt.day == 4) {
                return false;
            }
            if (dt.month == 9 && dt.day == 5) {
                return false;
            }
            if (dt.month == 11 && dt.day == 24) {
                return false;
            }
            if (dt.month == 12 && dt.day == 26) {
                return false;
            }
        }
        if (isSpecialEvent) {
            return false;
        }
        
        return true;
    }

        function isLeapYear(uint16 year) public pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

        function leapYearsBefore(uint year) public pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }

        function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;

                // Year
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

                // Month
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }

                // Day
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }

                // Hour
                dt.hour = getHour(timestamp);

                // Minute
                dt.minute = getMinute(timestamp);

                // Second
                dt.second = getSecond(timestamp);

                // Day of week.
                dt.weekday = getWeekday(timestamp);
        }

        function getYear(uint timestamp) public pure returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;

                // Year
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }

        function getHour(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }

        function getMinute(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }

        function getSecond(uint timestamp) public pure returns (uint8) {
                return uint8(timestamp % 60);
        }

        function getWeekday(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }

    function setSunday(uint8 sunday) external onlyOwner() {
        _sunday = sunday;
    }

    function setSaturday(uint8 saturday) external onlyOwner() {
        _saturday = saturday;
    }

    function setMarketOpeningTimeHr(uint8 openingTimeHr) external onlyOwner() {
        _openingTimeHr = openingTimeHr;
    }

    function setMarketClosingTimeHr(uint8 closingTimeHr) external onlyOwner() {
        _closingTimeHr = closingTimeHr;
    }

    function setMarketOpeningTimeMin(uint8 openingTimeMin) external onlyOwner() {
        _openingTimeMin = openingTimeMin;
    }

    function metaApprove(bytes memory signature,address _spender, uint256 _amount,uint256 _nonce) public virtual returns (bool) {
        require(hasRole(RELAYER_ROLE, _msgSender()), "ERC20relayer: must have relayer role to relay tx");
        require(hasRole(RELAYER_ROLE, _spender), "ERC20spender: must have relayer role to spend on tx");
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked(_spender, _amount, _nonce)).toEthSignedMessageHash();
        address signer = ethSignedMessageHash.recover(signature);
        //make sure signer doesn't come back as 0x0
        require(signer!=address(0));
        require(_nonce == replayNonce[signer],"Attack: this is a replay attack ");
        replayNonce[signer]++;
        _approve(signer, _spender, _amount);
        return true;
    }
}