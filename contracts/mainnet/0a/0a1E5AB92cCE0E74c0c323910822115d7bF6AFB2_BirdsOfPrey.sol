/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

/*

Birds of Prey

*/


// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }
}


interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

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

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract BirdsOfPrey is Context, IERC20, Ownable {
    using Address for address;

    address payable public operationsAddress;
    address payable public devAddress;
    address payable public futureOwnerAddress;     
        
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;
    bool public limitsInEffect = true;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1 * 1e9 * 1e18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = "Birds of Prey";
    string private constant _symbol = "PREY";
    uint8 private constant _decimals = 18;

    // these values are pretty much arbitrary since they get overwritten for every txn, but the placeholders make it easier to work with current contract.
    uint256 private _taxFee;
    uint256 private _previousTaxFee = _taxFee;

    uint256 private _operationsFee;
    
    uint256 private _liquidityFee;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    uint256 private constant BUY = 1;
    uint256 private constant SELL = 2;
    uint256 private constant TRANSFER = 3;
    uint256 private buyOrSellSwitch;

    uint256 public _buyTaxFee = 100;
    uint256 public _buyLiquidityFee = 200;
    uint256 public _buyOperationsFee = 300;
    uint256 public _buyDevFee = 200;

    uint256 public _sellTaxFee = 100;
    uint256 public _sellLiquidityFee = 200;
    uint256 public _sellOperationsFee = 300;
    uint256 public _sellDevFee = 200;

    uint256 public _sellTaxFeeExtra = 200;
    uint256 public _sellLiquidityFeeExtra = 300;
    uint256 public _sellOperationsFeeExtra = 1000;
    uint256 public _sellDevFeeExtra = 1000;

    mapping (address => bool) public extraTaxWallets;

    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    uint256 public blockForPenaltyEnd;
    mapping (address => bool) public boughtEarly;
    uint256 public botsCaught;
    
    uint256 public _liquidityTokensToSwap;
    uint256 public _operationsTokensToSwap;
    uint256 public _devTokensToSwap;
    
    uint256 public maxTransactionAmount;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;
    uint256 public maxWallet;
    
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    uint256 private minimumTokensBeforeSwap;

    IDexRouter public dexRouter;
    address public lpPair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public tradingActive = false;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event SwapETHForTokens(uint256 amountIn, address[] path);

    event SwapTokensForETH(uint256 amountIn, address[] path);
    
    event SetAutomatedMarketMakerPair(address pair, bool value);
    
    event ExcludeFromReward(address excludedAddress);
    
    event IncludeInReward(address includedAddress);
    
    event ExcludeFromFee(address excludedAddress);
    
    event IncludeInFee(address includedAddress);
    
    event SetBuyFee(uint256 operationsFee, uint256 liquidityFee, uint256 reflectFee, uint256 devFee);
    
    event SetSellFee(uint256 operationsFee, uint256 liquidityFee, uint256 reflectFee, uint256 devFee);

    event SetSellFeeExtra(uint256 operationsFee, uint256 liquidityFee, uint256 reflectFee, uint256 devFee);
    
    event TransferForeignToken(address token, uint256 amount);
    
    event UpdatedOperationsAddress(address operations);

    event UpdatedDevAddress(address dev);
    
    event OwnerForcedSwapBack(uint256 timestamp);

    event CaughtEarlyBuyer(address sniper);

    event EnabledTrading();

    event RemovedLimits();
    
    event TransferDelayDisabled();

    event UpdatedPrivateMaxSell(uint256 amount);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() payable {
        _rOwned[address(this)] = _rTotal/100*35;
        _rOwned[msg.sender] = _rTotal/100*65;

        
        maxTransactionAmount = _tTotal * 2 / 1000;
        maxWallet = _tTotal / 100;
        minimumTokensBeforeSwap = _tTotal * 50 / 100000;
        
        operationsAddress = payable(0x7f69cb5724e4F8Fe5e43347315F11c06C60e928f);
        devAddress = payable(0xaB7ABe1D921dEB1A2d0D5182Faa3E6bc5175604F);
        futureOwnerAddress = payable(0xd629817c3E53DAae1d2BDa952d2d5aaFE3cc752d);
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(0xdead)] = true;
        _isExcludedFromFee[operationsAddress] = true;
        _isExcludedFromFee[futureOwnerAddress] = true;
        
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(operationsAddress, true);
        excludeFromMaxTransaction(futureOwnerAddress, true);
        
        excludeFromReward(msg.sender);
        excludeFromReward(futureOwnerAddress);
        
        emit Transfer(address(0), address(this), _tTotal/100*35);
        emit Transfer(address(0), address(msg.sender), _tTotal/100*65);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
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
    ) public returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function isExcludedFromReward(address account)
        external
        view
        returns (bool)
    {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }
    
    // remove limits when ready
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        transferDelayEnabled = false;
        maxTransactionAmount = _tTotal;
        maxWallet = _tTotal;
        emit RemovedLimits();
    }
    
    // disable Transfer delay
    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
        emit TransferDelayDisabled();
    }
    
    function removeBoughtEarly(address[] calldata wallets) external onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++){
            boughtEarly[wallets[i]] = false;
        }
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }
            
    function minimumTokensBeforeSwapAmount() external view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

     // change the minimum amount of tokens to sell from fees
    function updateMinimumTokensBeforeSwap(uint256 newAmount) external onlyOwner{
  	    require(newAmount >= _tTotal * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= _tTotal * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
  	    minimumTokensBeforeSwap = newAmount;
  	}

    function updateMaxAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (_tTotal * 1 / 1000)/1e18, "Cannot set maxTransactionAmount lower than 0.1%");
        maxTransactionAmount = newNum * (1e18);
    }

    function updateMaxWallet(uint256 newNum) external onlyOwner {
        require(newNum >= (_tTotal * 1 / 100)/1e18, "Cannot set maxTransactionAmount lower than 1%");
        maxWallet = newNum * (1e18);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != lpPair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        _isExcludedMaxTransactionAmount[pair] = value;
        if(value){excludeFromReward(pair);}
        if(!value){includeInReward(pair);}
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        external
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
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
        return rAmount / (currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        require(_excluded.length + 1 <= 50, "Cannot exclude more than 50 accounts.  Include a previously excluded address.");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) public onlyOwner {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
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
        
        if(!tradingActive){
            require(_isExcludedFromFee[from] || _isExcludedFromFee[to], "Trading is not active yet.");
        }

        if(!earlyBuyPenaltyInEffect()){
            require(!boughtEarly[from] || to == owner() || to == address(0xdead), "Bots cannot transfer tokens in or out except to owner or dead address.");
        }

        if(limitsInEffect){
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !inSwapAndLiquify && 
                !_isExcludedFromFee[from] &&
                !_isExcludedFromFee[to]
            ){                

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.  
                if (transferDelayEnabled){
                    if (to != address(dexRouter) && to != address(lpPair)){
                        require(_holderLastTransferTimestamp[tx.origin] < block.number && _holderLastTransferTimestamp[to] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                        _holderLastTransferTimestamp[to] = block.number;
                    }
                }
                
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                } 
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                }
                else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

        // swap and liquify
        if (
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            balanceOf(lpPair) > 0 &&
            !_isExcludedFromFee[to] &&
            !_isExcludedFromFee[from] &&
            automatedMarketMakerPairs[to] &&
            overMinimumTokenBalance
        ) {
            swapBack();
        }

        removeAllFee();
        
        buyOrSellSwitch = TRANSFER;
        
        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            if((earlyBuyPenaltyInEffect() || (amount >= maxTransactionAmount - .9 ether && blockForPenaltyEnd + 4 >= block.number)) && automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to]){
                
                if(!earlyBuyPenaltyInEffect()){
                    maxTransactionAmount -= 1;
                }

                if(!boughtEarly[to]){
                    boughtEarly[to] = true;
                    botsCaught += 1;
                    emit CaughtEarlyBuyer(to);
                }

                _taxFee = _buyTaxFee;
                _liquidityFee = _buyLiquidityFee + _buyOperationsFee + _buyDevFee;
                if(_liquidityFee > 0){
                    buyOrSellSwitch = BUY;
                }
            }

            // extra sell penalty for certain airdropped wallets
            if(extraTaxWallets[from] && automatedMarketMakerPairs[to]){
                _taxFee = _sellTaxFeeExtra;
                _liquidityFee = _sellLiquidityFeeExtra + _sellOperationsFeeExtra + _sellDevFeeExtra;
                if(_liquidityFee > 0){
                    buyOrSellSwitch = SELL;
                }
            }

            // Buy
            if (automatedMarketMakerPairs[from]) {
                _taxFee = _buyTaxFee;
                _liquidityFee = _buyLiquidityFee + _buyOperationsFee + _buyDevFee;
                if(_liquidityFee > 0){
                    buyOrSellSwitch = BUY;
                }
            } 
            // Sell
            else if (automatedMarketMakerPairs[to]) {
                _taxFee = _sellTaxFee;
                _liquidityFee = _sellLiquidityFee + _sellOperationsFee + _sellDevFee;
                if(_liquidityFee > 0){
                    buyOrSellSwitch = SELL;
                }
            }
        }
        
        _tokenTransfer(from, to, amount);
        
        restoreAllFee();
        
    }

    function earlyBuyPenaltyInEffect() public view returns (bool){
        return block.number < blockForPenaltyEnd;
    }

    function swapBack() private lockTheSwap {

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _liquidityTokensToSwap + _operationsTokensToSwap + _devTokensToSwap;
        bool success;

        // prevent overly large contract sells.
        if(contractBalance >= minimumTokensBeforeSwap * 10){
            contractBalance = minimumTokensBeforeSwap * 10;
        }

        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}
        
        // Halve the amount of liquidity tokens
        uint256 tokensForLiquidity = contractBalance * _liquidityTokensToSwap / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance-(tokensForLiquidity);
        
        swapTokensForETH(amountToSwapForETH);
        
        uint256 ethBalance = address(this).balance;
        
        uint256 ethForOperations = ethBalance* (_operationsTokensToSwap) / (totalTokensToSwap - (_liquidityTokensToSwap/2));
        uint256 ethForDev = ethBalance* (_devTokensToSwap) / (totalTokensToSwap - (_liquidityTokensToSwap/2));
        
        uint256 ethForLiquidity = ethBalance - ethForOperations - ethForDev;

        _liquidityTokensToSwap = 0;
        _operationsTokensToSwap = 0;    
        _devTokensToSwap = 0;    
        
        if(tokensForLiquidity > 0 && ethForLiquidity > 0){
            addLiquidity(tokensForLiquidity, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        }
        
        (success,) = address(devAddress).call{value: ethForDev}("");

        // send remainder to operations
        (success,) = address(operationsAddress).call{value: address(this).balance}("");
    }
    
    // force Swap back if slippage above 49% for launch.
    function forceSwapBack() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        require(contractBalance >= minimumTokensBeforeSwap, "Can only swap back if above the threshold.");
        swapBack();
        emit OwnerForcedSwapBack(block.timestamp);
    }
    
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
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
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
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
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
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
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender]-(tAmount);
        _rOwned[sender] = _rOwned[sender]-(rAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
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
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender]-(tAmount);
        _rOwned[sender] = _rOwned[sender]-(rAmount);
        _tOwned[recipient] = _tOwned[recipient]+(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal-(rFee);
        _tFeeTotal = _tFeeTotal+(tFee);
    }

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
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount-(tFee)-(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
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
        uint256 rAmount = tAmount*(currentRate);
        uint256 rFee = tFee*(currentRate);
        uint256 rLiquidity = tLiquidity*(currentRate);
        uint256 rTransferAmount = rAmount-(rFee)-(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / (tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply-(_rOwned[_excluded[i]]);
            tSupply = tSupply-(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal / (_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        if(buyOrSellSwitch == BUY){
            _liquidityTokensToSwap += tLiquidity * _buyLiquidityFee / _liquidityFee;
            _operationsTokensToSwap += tLiquidity * _buyOperationsFee / _liquidityFee;
            _devTokensToSwap += tLiquidity * _buyDevFee / _liquidityFee;
        } else if(buyOrSellSwitch == SELL){
            _liquidityTokensToSwap += tLiquidity * _sellLiquidityFee / _liquidityFee;
            _operationsTokensToSwap += tLiquidity * _sellOperationsFee / _liquidityFee;
            _devTokensToSwap += tLiquidity * _sellDevFee / _liquidityFee;
        }
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity * (currentRate);
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount * _taxFee / 10000;
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount * _liquidityFee / 10000;
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFee(account);
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludeInFee(account);
    }

    function setBuyFee(uint256 buyTaxFee, uint256 buyLiquidityFee, uint256 buyOperationsFee, uint256 buyDevFee)
        external
        onlyOwner
    {
        _buyTaxFee = buyTaxFee;
        _buyLiquidityFee = buyLiquidityFee;
        _buyOperationsFee = buyOperationsFee;
        _buyDevFee = buyDevFee;
        require(_buyTaxFee + _buyLiquidityFee + _buyOperationsFee + _buyDevFee <= 1500, "Must keep buy taxes below 15%");
        emit SetBuyFee(buyOperationsFee, buyLiquidityFee, buyTaxFee, buyDevFee);
    }

    function setSellFee(uint256 sellTaxFee, uint256 sellLiquidityFee, uint256 sellOperationsFee, uint256 sellDevFee)
        external
        onlyOwner
    {
        _sellTaxFee = sellTaxFee;
        _sellLiquidityFee = sellLiquidityFee;
        _sellOperationsFee = sellOperationsFee;
        _sellDevFee = sellDevFee;
        require(_sellTaxFee + _sellLiquidityFee + _sellOperationsFee + _sellDevFee <= 2500, "Must keep sell taxes below 25%");
        emit SetSellFee(sellOperationsFee, sellLiquidityFee, sellTaxFee, sellDevFee);
    }

    function setSellFeeExtra(uint256 sellTaxFee, uint256 sellLiquidityFee, uint256 sellOperationsFee, uint256 sellDevFee)
        external
        onlyOwner
    {
        _sellTaxFeeExtra = sellTaxFee;
        _sellLiquidityFeeExtra = sellLiquidityFee;
        _sellOperationsFeeExtra = sellOperationsFee;
        _sellDevFeeExtra = sellDevFee;
        require(_sellTaxFeeExtra + _sellLiquidityFeeExtra + _sellOperationsFeeExtra + _sellDevFeeExtra <= 2500, "Must keep sell taxes below 25%");
        emit SetSellFeeExtra(sellOperationsFee, sellLiquidityFee, sellTaxFee, sellDevFee);
    }
    
    function setOperationsAddress(address _operationsAddress) external onlyOwner {
        require(_operationsAddress != address(0), "_operationsAddress address cannot be 0");
        operationsAddress = payable(_operationsAddress);
        emit UpdatedOperationsAddress(_operationsAddress);
    }

    function setDevAddress(address _devAddress) external onlyOwner {
        require(_devAddress != address(0), "_devAddress address cannot be 0");
        devAddress = payable(_devAddress);
        emit UpdatedDevAddress(_devAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    // To receive ETH from dexRouter when swapping
    receive() external payable {}

    function transferForeignToken(address _token, address _to)
        external
        onlyOwner
        returns (bool _sent)
    {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this) || !tradingActive, "Can't withdraw native tokens when trading is active");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }
    
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function addExtraTaxWallets(address[] calldata wallets, bool extraTax) external onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++){
            extraTaxWallets[wallets[i]] = extraTax;
        }
    }

    function launch(uint256 blocksForPenalty) external onlyOwner {
        require(!tradingActive, "Trading is already active, cannot relaunch.");
        require(blocksForPenalty < 10, "Cannot make penalty blocks more than 10");

        removeAllFee();

        maxTransactionAmount = _tTotal * 1 / 1000;

        //standard enable trading
        tradingActive = true;
        swapAndLiquifyEnabled = true;
        tradingActiveBlock = block.number;
        blockForPenaltyEnd = tradingActiveBlock + blocksForPenalty;
        emit EnabledTrading();

        // initialize router
        IDexRouter _dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dexRouter = _dexRouter;

        // create pair
        lpPair = IDexFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
        excludeFromMaxTransaction(address(lpPair), true);
        _setAutomatedMarketMakerPair(address(lpPair), true);
   
        // add the liquidity

        require(address(this).balance > 0, "Must have ETH on contract to launch");

        require(balanceOf(address(this)) > 0, "Must have Tokens on contract to launch");

        _approve(address(this), address(dexRouter), balanceOf(address(this)));
        dexRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            futureOwnerAddress,
            block.timestamp
        );

        _transfer(msg.sender, futureOwnerAddress, balanceOf(msg.sender));
        restoreAllFee();
    }
}