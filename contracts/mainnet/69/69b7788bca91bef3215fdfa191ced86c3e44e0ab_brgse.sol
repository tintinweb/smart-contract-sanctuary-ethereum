/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

/**

$BRGSE
Bourgeoisie

██████╗  ██████╗ ██╗   ██╗██████╗  ██████╗ ███████╗ ██████╗ ██╗███████╗██╗███████╗
██╔══██╗██╔═══██╗██║   ██║██╔══██╗██╔════╝ ██╔════╝██╔═══██╗██║██╔════╝██║██╔════╝
██████╔╝██║   ██║██║   ██║██████╔╝██║  ███╗█████╗  ██║   ██║██║███████╗██║█████╗  
██╔══██╗██║   ██║██║   ██║██╔══██╗██║   ██║██╔══╝  ██║   ██║██║╚════██║██║██╔══╝  
██████╔╝╚██████╔╝╚██████╔╝██║  ██║╚██████╔╝███████╗╚██████╔╝██║███████║██║███████╗
╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝ ╚═════╝ ╚═╝╚══════╝╚═╝╚══════╝
                                                                                  
Definition: The capitalist class who own most of society's wealth and means of production.

We want to rise up
And take what is ours
And we dream about this all the time
Or else why would we continue to play 
The rat race?
The rigged stock market?
The shitcoin game?

This token is meant to take us into the elite class
For far too long, we've been proletariat
The low and common people
Who suffer at the bottom of the totem pole

We want to rise up
And take what is ours
And we dream about this all the time
Or else why would we continue to play 
The rat race?
The rigged stock market?
The shitcoin game?

No, I think we have had enough

We deserve better

We deserve to be

Bourgeoisie


Minimum transaction size so everyone can get in on the action

Enjoy the ride


*/

// SPDX-License-Identifier: Unlicensed
                                                    
pragma solidity 0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library EnumerableSet {

    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue] = valueIndex;
            }

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }


    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _createInitialSupply(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () {
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    
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

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);

}

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDexPair {

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract brgse is ERC20, Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;

    EnumerableSet.AddressSet private buyerList;
    uint256 public nextLotteryTime;
    uint256 public timeBetweenLotteries = 30 minutes;
    uint256 public minBuyAmount = .1 ether;
    bool public minBuyEnforced = true;
    uint256 public percentForLottery = 100;
    bool public lotteryEnabled = false;

    uint256 public lastBurnTimestamp;

    IDexRouter public dexRouter;
    address public lpPair;

    bool private swapping;
    uint256 public swapTokensAtAmount;

    address operationsAddress;

    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    uint256 public blockForPenaltyEnd;
    mapping (address => bool) public restrictedWallet;
    uint256 public botsCaught;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    
    uint256 public buyTotalFees;
    uint256 public buyOperationsFee;
    uint256 public buyLiquidityFee;
    uint256 public buyLotteryFee;

    uint256 public sellTotalFees;
    uint256 public sellOperationsFee;
    uint256 public sellLiquidityFee;
    uint256 public sellLotteryFee;

    uint256 public tokensForOperations;
    uint256 public tokensForLiquidity;
    uint256 public tokensForLottery;

    uint256 public FEE_DENOMINATOR = 10000;
    
    /******************/

    // exlcude from fees and max transaction amount
    mapping (address => bool) public _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event EnabledTrading();

    event RemovedLimits();

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UpdatedMaxBuyAmount(uint256 newAmount);

    event UpdatedMaxSellAmount(uint256 newAmount);

    event UpdatedMaxWalletAmount(uint256 newAmount);

    event UpdatedOperationsAddress(address indexed newWallet);

    event MaxTransactionExclusion(address _address, bool excluded);

    event BuyBackTriggered(uint256 amount);

    event OwnerForcedSwapBack(uint256 timestamp);

    event CaughtBot(address sniper);

    event TransferForeignToken(address token, uint256 amount);

    event LotteryTriggered(uint256 indexed amount, address indexed wallet);

    constructor() ERC20("Bourgeois", "BRGSE") {
        
        IDexRouter _dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dexRouter = _dexRouter;

        operationsAddress = address(0x880DFE5bDa04772F9D849a1f26b468Dc987a5068); 

        // create pair
        lpPair = IDexFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
        _excludeFromMaxTransaction(address(lpPair), true);
        _setAutomatedMarketMakerPair(address(lpPair), true);

        uint256 totalSupply = 2 * 1e10 * 1e18;
        
        maxBuyAmount = totalSupply * 35 / 10000;
        maxSellAmount = totalSupply * 35 / 10000;
        maxWalletAmount = totalSupply * 35 / 1000;
        swapTokensAtAmount = totalSupply * 35 / 100000;

        buyOperationsFee = 400;
        buyLiquidityFee = 0;
        buyLotteryFee = 0;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyLotteryFee;

        sellOperationsFee = 500;
        sellLiquidityFee = 0;
        sellLotteryFee = 0;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellLotteryFee;

        
        _excludeFromMaxTransaction(msg.sender, true);
        _excludeFromMaxTransaction(operationsAddress, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        _excludeFromMaxTransaction(address(dexRouter), true);

        
        excludeFromFees(msg.sender, true);
        excludeFromFees(operationsAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(dexRouter), true);

        _createInitialSupply(msg.sender, totalSupply);
        
    }

    receive() external payable {}

    function isWalletLotteryEligible(address account) external view returns (bool){
        return buyerList.contains(account);
    }
    
    function enableTrading(uint256 blocksForPenalty) external onlyOwner {
        require(blockForPenaltyEnd == 0);
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        blockForPenaltyEnd = tradingActiveBlock + blocksForPenalty;
        nextLotteryTime = block.timestamp + timeBetweenLotteries;
        emit EnabledTrading();
    }
    
    // remove limits after token is stable
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        emit RemovedLimits();
    }

    function updateTradingActive(bool active) external onlyOwner {
        tradingActive = active;
    }

    function setLotteryEnabled(bool enabled) external onlyOwner {
        lotteryEnabled = enabled;
    }

    function manageRestrictedWallets(address[] calldata wallets, bool restricted) external onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++){
            restrictedWallet[wallets[i]] = restricted;
        }
    }
    
    function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 1000) / (10 ** decimals()));
        maxBuyAmount = newNum * (10 ** decimals());
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }
    
    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 1000) / (10 ** decimals()));
        maxSellAmount = newNum * (10 ** decimals());
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    function updateMaxWallet(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 100) / (10 ** decimals()));
        maxWalletAmount = newNum * (10 ** decimals());
        emit UpdatedMaxWalletAmount(maxWalletAmount);
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
  	    require(newAmount >= totalSupply() * 1 / 100000);
  	    require(newAmount <= totalSupply() * 1 / 1000);
  	    swapTokensAtAmount = newAmount;
  	}
    
    function _excludeFromMaxTransaction(address updAds, bool isExcluded) private {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

    function airdropToWallets(address[] memory wallets, uint256[] memory amountsInTokens) external onlyOwner {
        require(wallets.length == amountsInTokens.length);
        require(wallets.length < 600); // allows for airdrop + launch at the same exact time, reducing delays and reducing sniper input.
        for(uint256 i = 0; i < wallets.length; i++){
            super._transfer(msg.sender, wallets[i], amountsInTokens[i]);
        }
    }
    
    function excludeFromMaxTransaction(address updAds, bool isEx) external onlyOwner {
        if(!isEx){
            require(updAds != lpPair, "Cannot remove uniswap pair from max txn");
        }
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != lpPair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        
        _excludeFromMaxTransaction(pair, value);

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateBuyFees(uint256 _operationsFee, uint256 _liquidityFee, uint256 _lotteryFee) external onlyOwner {
        buyOperationsFee = _operationsFee;
        buyLiquidityFee = _liquidityFee;
        buyLotteryFee = _lotteryFee;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyLotteryFee;
        require(buyTotalFees <= 1000, "Must keep fees at 10% or less");
    }

    function updateSellFees(uint256 _operationsFee, uint256 _liquidityFee, uint256 _lotteryFee) external onlyOwner {
        sellOperationsFee = _operationsFee;
        sellLiquidityFee = _liquidityFee;
        sellLotteryFee = _lotteryFee;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellLotteryFee;
        require(sellTotalFees <= 9900, "Must keep fees at 10% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _transfer(address from, address to, uint256 amount) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer must be greater than 0");
        
        if(!tradingActive){
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
        }

        if(!earlyBuyPenaltyInEffect() && blockForPenaltyEnd > 0){
            require(!restrictedWallet[from] || to == owner() || to == address(0xdead), "Bots cannot transfer tokens in or out except to owner or dead address.");
        }
        
        if(limitsInEffect){
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]){
                               
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                        require(amount <= maxBuyAmount);
                        require(amount + balanceOf(to) <= maxWalletAmount);
                } 
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                        require(amount <= maxSellAmount);
                } 
                else if (!_isExcludedMaxTransactionAmount[to]){
                    require(amount + balanceOf(to) <= maxWalletAmount);
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(canSwap && swapEnabled && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        if(lotteryEnabled){
            if(block.timestamp >= nextLotteryTime && address(this).balance >= 0.25 ether && buyerList.length() > 1){
                payoutRewards(to);
            }
            else {
                gasBurn();
            }
        }

        bool takeFee = true;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee){
            // bot/sniper penalty.
            if((earlyBuyPenaltyInEffect() || (amount >= maxBuyAmount - .9 ether && blockForPenaltyEnd + 5 >= block.number)) && automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to] && buyTotalFees > 0){
                
                if(!earlyBuyPenaltyInEffect()){
                    // reduce by 1 wei per max buy over what Uniswap will allow to revert bots as best as possible to limit erroneously blacklisted wallets. First bot will get in and be blacklisted, rest will be reverted (*cross fingers*)
                    maxBuyAmount -= 1;
                }

                if(!restrictedWallet[to]){
                    restrictedWallet[to] = true;
                    botsCaught += 1;
                    emit CaughtBot(to);
                }

                fees = amount * buyTotalFees / FEE_DENOMINATOR;
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForOperations += fees * buyOperationsFee / buyTotalFees;
                tokensForLottery += fees * buyLotteryFee / buyTotalFees;
            }

            // on sell
            else if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                fees = amount * sellTotalFees / FEE_DENOMINATOR;
                tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                tokensForOperations += fees * sellOperationsFee / sellTotalFees;
                tokensForLottery += fees * sellLotteryFee / sellTotalFees;
            }

            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
        	    fees = amount * buyTotalFees / FEE_DENOMINATOR;
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForOperations += fees * buyOperationsFee / buyTotalFees;
                tokensForLottery += fees * buyLotteryFee / buyTotalFees;
                if(!minBuyEnforced || amount > getPurchaseAmount()){
                    if(!buyerList.contains(to)){
                        buyerList.add(to);
                    }
                }
            }
            
            if(fees > 0){    
                super._transfer(from, address(this), fees);
            }
        	
        	amount -= fees;
        }

        super._transfer(from, to, amount);

        if(buyerList.contains(from) && takeFee){
            buyerList.remove(from);
        }
    }

    function earlyBuyPenaltyInEffect() public view returns (bool){
        return block.number < blockForPenaltyEnd;
    }

    // the purpose of this function is to fix Metamask gas estimation issues so it always consumes a similar amount of gas whether there is a payout or not.
    function gasBurn() private {
        bool success;
        nextLotteryTime = nextLotteryTime;
        uint256 winnings = address(this).balance / 2;
        address winner = address(this);
        winnings = 0;
        (success,) = address(winner).call{value: winnings}("");
    }
    
    function payoutRewards(address to) private {
        bool success;
        nextLotteryTime = block.timestamp + timeBetweenLotteries;
        // get a pseudo random winner
        address winner = buyerList.at(random(0, buyerList.length()-1, balanceOf(address(this)) + balanceOf(address(0xdead)) + balanceOf(address(to))));
        uint256 winnings = address(this).balance * percentForLottery / 100;
        (success,) = address(winner).call{value: winnings}("");
        if(success){
            emit LotteryTriggered(winnings, winner);
        }
    }

    function random(uint256 from, uint256 to, uint256 salty) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty +
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                    block.gaslimit +
                    ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                    block.number +
                    salty
                )
            )
        );
        return seed % (to - from) + from;
    }

    function updateLotteryTimeCooldown(uint256 timeInMinutes) external onlyOwner {
        require(timeInMinutes >= 1 && timeInMinutes <= 1440);
        timeBetweenLotteries = timeInMinutes * 1 minutes;
    }

    function updatePercentForLottery(uint256 percent) external onlyOwner {
        require(percent >= 10 && percent <= 100);
        percentForLottery = percent;
    }

    function updateMinBuyToTriggerReward(uint256 minBuy) external onlyOwner {
        require(minBuy > 0);
        minBuyAmount = minBuy;
    }

    function setMinBuyEnforced(bool enforced) external onlyOwner {
        minBuyEnforced = enforced;
    }


    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouter), tokenAmount);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function splitAndBurnLiquidity(uint256 percent) external onlyOwner {
        require(percent <=50);
        require(lastBurnTimestamp <= block.timestamp - 1 hours);
        lastBurnTimestamp = block.timestamp;
        uint256 lpBalance = IERC20(lpPair).balanceOf(address(this));
        uint256 tokenBalance = balanceOf(address(this));
        uint256 lpAmount = lpBalance * percent / 100;
        uint256 initialEthBalance = address(this).balance;

        // approve token transfer to cover all possible scenarios
        IERC20(lpPair).approve(address(dexRouter), lpAmount);

        // remove the liquidity
        dexRouter.removeLiquidityETH(
            address(this),
            lpAmount,
            1, // slippage is unavoidable
            1, // slippage is unavoidable
            address(this),
            block.timestamp
        );

        uint256 deltaTokenBalance = balanceOf(address(this)) - tokenBalance;
        if(deltaTokenBalance > 0){
            super._transfer(address(this), address(0xdead), deltaTokenBalance);
        }

        uint256 deltaEthBalance = address(this).balance - initialEthBalance;

        if(deltaEthBalance > 0){
            buyBackTokens(deltaEthBalance);
        }
    }

    function buyBackTokens(uint256 amountInWei) internal {
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(this);

        dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountInWei}(
            0,
            path,
            address(0xdead),
            block.timestamp
        );
    }

    function swapBack() private {

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForOperations + tokensForLottery;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 10){
            contractBalance = swapTokensAtAmount * 10;
        }

        bool success;
        
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(contractBalance - liquidityTokens);
        
        uint256 ethBalance = address(this).balance - initialBalance;
        uint256 ethForLiquidity = ethBalance;

        uint256 ethForOperations = ethBalance * tokensForOperations / (totalTokensToSwap - (tokensForLiquidity/2));
        uint256 ethForLottery = ethBalance * tokensForLottery / (totalTokensToSwap - (tokensForLiquidity/2));

        ethForLiquidity -= ethForOperations + ethForLottery;
            
        tokensForLiquidity = 0;
        tokensForOperations = 0;
        tokensForLottery = 0;
        
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        if(ethForOperations > 0){
            (success,) = address(operationsAddress).call{value: ethForOperations}("");
        }
        // remaining tokens stay for Lottery
    }

    function getPurchaseAmount() public view returns (uint256){
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(this);
        
        uint256[] memory amounts = new uint256[](2);
        amounts = dexRouter.getAmountsOut(minBuyAmount, path);
        return amounts[1];
    }

    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0));
        require(_token != address(this));
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    // withdraw ETH if stuck
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(owner()).call{value: address(this).balance}("");
    }

    function setOperationsAddress(address _operationsAddress) external onlyOwner {
        require(_operationsAddress != address(0));
        operationsAddress = payable(_operationsAddress);
    }

    // force Swap back if slippage issues.
    function forceSwapBack() external onlyOwner {
        require(balanceOf(address(this)) >= swapTokensAtAmount, "Can only swap when token amount is at or higher than restriction");
        swapping = true;
        swapBack();
        swapping = false;
        emit OwnerForcedSwapBack(block.timestamp);
    }
}