/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

//SPDX-License-Identifier: No License
pragma solidity ^0.8.0;

// Made in partnership with Tokify

/**
 * SAFEMATH LIBRARY
 */
library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IRewardsPool {
    function setShare(address shareholder, uint256 amount) external;
    function process(uint256 amountBNB) external;
    function transferBNBToAddress(address recipient, uint256 amount) external;
}

/// @dev Contract to store and distribute BNB rewards accrued through taxes in the parent token contract
contract RewardsPool is IRewardsPool {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
    }

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;

    mapping (address => Share) public shares;

    uint256 public totalShares;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    /// @dev Require the caller to be the parent token contract
    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor () {
        _token = msg.sender;
    }

    receive() external payable{}

    /// @dev Set share of the parent token holder to later understand what percentage of reward to distribute to this wallet
    function setShare(address shareholder, uint256 amount) external override onlyToken {

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        /// @dev adjust total shares to later understand the proportion owned by shareholder
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
    }

    /// @dev Process the reward by iterating over every single shareholder and sending them the BNB reward
    /// @param amountBNB the total amount of BNB reward to be distributed (this does not have to be the whole reward pool)
    function process(uint256 amountBNB) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 currentIndex = 0;

        while(currentIndex < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
            
            distributeDividend(shareholders[currentIndex], amountBNB);
            currentIndex++;
        }
    }

    /// @dev Send reward to specific shareholder according to their holding amount of the parent token
    /// @param totalBNB the total amount of BNB reward to be distributed to calculate how much shareholder should receive
    function distributeDividend(address shareholder, uint256 totalBNB) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = shares[shareholder].amount.mul(totalBNB).div(totalShares);
        if(amount > 0){
            payable(shareholder).transfer(amount);
        }
    }

    /// @dev Add shareholder to the list of shareholders
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    /// @dev Remove shareholder from the list of shareholders
    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    /// @dev Transfer the BNB reward from the contract to a recipient
    function transferBNBToAddress(address recipient, uint256 amount) external override onlyToken {
        payable(recipient).transfer(amount);
    }
}

/** @dev this token is backed by BNB, which can be sent to the contract by anyone and can be redeemed by burning the token. 

There are two BNB pools - the asset pool which is simply the amount of BNB the contract holds, 
and the reward pool, which is the amount of BNB collected through taxes and is stored in a separate contract (RewardsPool).

When burning the token, the amount of BNB given is calculated by taking (token amount)/(circulating supply) and giving that fraction of the asset pool BNB.
However if there is BNB in the rewards pool, that is given first before dipping into the asset pool. This raises the floor price of the token when burning it as less BNB leaves the asset pool.

The rewards pool is separated because the owner of the token can also choose to distribute a fraction of the rewards pool at specific points in time to reward holders.
*/ 

contract FloorRising is IBEP20, Auth {
    using SafeMath for uint256;

    uint256 public constant MASK = type(uint128).max;
    address WBNB = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Floor Rising";
    string constant _symbol = "FLR";
    uint8 constant _decimals = 9;

    uint256 private _totalSupply = 1000000000000000;
    uint256 public _maxTxAmount = _totalSupply.div(400); // 0.25%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;

    /// @dev liquidityFee determines tax to send to the liquidity pool
    uint256 liquidityFee = 200;
    /// @dev reflectionFee determines tax to send to the rewards pool
    uint256 reflectionFee = 200;
    /// @dev reflectionFee determines tax to send to the marketing wallet
    uint256 marketingFee = 400;
    uint256 totalFee = liquidityFee.add(reflectionFee).add(marketingFee);
    /// @dev fee denominator allows taxes to be decimal number percentages
    uint256 feeDenominator = 10000;

    /// @dev multipliers allows taxes to be reduced or increased when buying/selling (with same denominator as the fees)
    uint256 buyMultiplier = 10000;
    uint256 sellMultiplier = 10000;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver = 0x06F87581b8670413D3d84fB4A7FbD220de7d8c9C;
    address generatorFeeReceiver = 0xF6bF36933149030ed4B212F0a79872306690e48e;
    uint256 generatorFee = 500;

    /// @dev takeFeeActive allows to temporarily pause any taxes
    bool takeFeeActive = true;

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    RewardsPool rewardsPool;
    address public rewardsPoolAddress;

    /// @dev before processing taxes in BNB, the taxed token is accumulated in the contract to save on gas fees
    /// @dev the swap to BNB will only occur once the swapThreshold is reached
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 2000; // 0.005%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        /// @dev set the router address and create pair
        address _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        router = IDEXRouter(_dexRouter);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        WBNB = router.WETH();

        /// @dev create the rewards pool to store and handle BNB rewards
        rewardsPool = new RewardsPool();
        rewardsPoolAddress = address(rewardsPool);

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;

        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;

        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        /// @dev if the token is currently being swapped by the contract into BNB, then no taxes apply
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        /// @dev if the token is being burned then the recipient will be reimbursed with BNB according to the amount in the asset pool
        if(recipient == DEAD){ return _burnForBNB(sender, amount); }
        /// @dev check that the size of the transaction is not over the transaction limit
        checkTxLimit(sender, amount);
        /// @dev check if enough of the token has been accumulated in the contract to swap into BNB and if so then swap the token accumulated in contract to BNB
        if(shouldSwapBack()){ swapBack(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);

        /// @dev set the new shares of the token holders according to the balances after this transfer has occurred
        if(!isDividendExempt[sender]){ try rewardsPool.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try rewardsPool.setShare(recipient, _balances[recipient]) {} catch {} }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
//        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    /// @dev check if taking fee is active and if yes if the sender is exempt from the fee
    function shouldTakeFee(address sender) internal view returns (bool) {
        if (takeFeeActive == false) {
            return false;
        }
        return !isFeeExempt[sender];
    }

    /// @dev calculae the total fee to be taken on the transaction
    function getTotalFee(bool selling, bool buying) public view returns (uint256) {
        if(selling){ return getSellMultipliedFee(); }
        if(buying){ return getBuyMultipliedFee(); }
        return totalFee;
    }

    /// @dev multiply fee by buying multiplier if person is buying the token
    function getBuyMultipliedFee() public view returns (uint256) {
        return totalFee.mul(buyMultiplier).div(feeDenominator);
    }

    /// @dev multiply fee by selling multiplier if person is selling the token
    function getSellMultipliedFee() public view returns (uint256) {
        return totalFee.mul(sellMultiplier).div(feeDenominator);
    }

    /// @dev figure out the amount transferred when taxes are deducted and add the taxes to this contract
    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair, sender == pair)).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    /// @dev function to swap the token accumulated in the contract through taxes into BNB
    /// @dev the BNB is then accordingly distributed into the rewards pool, the liquidity pool and the marketing wallet
    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        /// @dev set the path through which the contract exchanges the token to BNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
        uint256 balanceBefore = address(this).balance;

        /// @dev exchange the token for BNB
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        /// @dev caluculate how much new BNB has been converted
        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));

        /// @dev since adding to liquidity pool requires both BNB and the token, we only convert half of it
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
        
        /// @dev transfer the portion of taxes taken for rewards to the rewards pool
        payable(rewardsPoolAddress).transfer(amountBNBReflection);
        
        /// @dev tax on the marketing wallet going towards the contract generator platform
        uint256 generatorAmount = amountBNBMarketing.mul(generatorFee).div(
            feeDenominator
        );
        uint256 marketingAmount = amountBNBMarketing.sub(generatorAmount);
        payable(marketingFeeReceiver).transfer(marketingAmount);
        payable(generatorFeeReceiver).transfer(generatorAmount);

        /// @dev transfer the portion of taxes taken for liquidity pool to the liquidity pool
        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    /// @dev set the transaction limit
    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    /// @dev set whether an address is exempt from the reward
    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            rewardsPool.setShare(holder, 0);
        }else{
            rewardsPool.setShare(holder, _balances[holder]);
        }
    }

    /// @dev set whether an address is exempt from the fee
    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    /// @dev set whether an address is exempt from the maximum transaction limit
    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    /// @dev set the fees with a denominator of 10000
    function setFeesWithDenominator10000(
        uint256 _liquidityFee,
        uint256 _reflectionFee,
        uint256 _marketingFee
    ) external authorized {
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee.add(_reflectionFee).add(
            _marketingFee
        );
        require(totalFee < feeDenominator / 4);
    }

    /// @dev set the buy and sell multipliers with a denominator of 10000
    function setFeeMultipliersWithDenominator10000(
        uint256 _buyMultiplier,
        uint256 _sellMultiplier
    ) external authorized {
        buyMultiplier = _buyMultiplier;
        sellMultiplier = _sellMultiplier;
        require(buyMultiplier <= feeDenominator * 2);
        require(sellMultiplier <= feeDenominator * 2);
    }

    /// @dev set the addresses that benefit from the marketing fee and those that receive the liquidity
    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    /// @dev set whether the contract an swap back its accumulated token into BNB and set the threshold for this
    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    /// @dev set the maximum amount of liquidity up to which taxes keep being sent to the pool
    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    /// @dev enable or disable the fee
    function setFeeActive(bool setTakeFeeActive) external authorized {
        takeFeeActive = setTakeFeeActive;
    }

    /// @dev get the token supply not stored in the burn wallets
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    /// @dev get how much of the token is in the liquidity pool
    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    /// @dev check whether too much of the token is in the liquidity pool
    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    /// @dev pay out a fraction of the BNB stored in the reward pool contract (RewardsPool)
    function payoutFractionOfRewardsPool(uint256 numerator, uint256 denominator) external authorized {
        rewardsPool.process(rewardsPoolAddress.balance.mul(numerator).div(denominator));
    }

    /// @dev get amount of BNB stored in the asset pool (this contract)
    function getAmountBNBInAssetPool() public view returns (uint256) {
        return address(this).balance;
    }

    /// @dev get amount of BNB stored in the rewards pool (RewardsPool contract)
    function getAmountBNBInRewardsPool() public view returns (uint256) {
        return rewardsPoolAddress.balance;
    }

    /// @dev allow holders to burn their token in exchange for BNB stored in the asset and rewards pool
    function burnForBNB(uint256 amount) external returns (bool) {

        address sender = msg.sender;
        return _burnForBNB(sender, amount);
    }

    /// @dev function to process the sending of BNB to person burning the token
    function _burnForBNB(address sender, uint256 amount) internal returns (bool) {
        /// @dev calculate amount BNB to transfer to wallet burning the token
        /// @dev this is done by taking the fraction of the circulating supply being burned and multiplying it with the BNB stored in the asset pool
        uint256 amountBNBToTransfer = getAmountBNBInAssetPool().mul(amount).div(getCirculatingSupply());
        
        address recipient = DEAD;
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);

        /// @dev when sending BNB, first the BNB from the rewards pool is sent according to amount calculated
        /// @dev if there is not enough BNB in the rewards pool then the rest is covered by BNB in the asset pool
        /// @dev this ensurees that the floor price rises when a holder burns the token as the asset pool decreases at a slower rate than the token is burned
        if(getAmountBNBInRewardsPool() >= amountBNBToTransfer) {
            rewardsPool.transferBNBToAddress(sender, amountBNBToTransfer);
        } else {
            uint256 amountAssetPoolBNBToTransfer = amountBNBToTransfer.sub(getAmountBNBInRewardsPool());
            rewardsPool.transferBNBToAddress(sender, getAmountBNBInRewardsPool());
            payable(sender).transfer(amountAssetPoolBNBToTransfer);
        }

        /// @dev set the new share of the wallet burning the token
        if(!isDividendExempt[sender]){ try rewardsPool.setShare(sender, _balances[sender]) {} catch {} }

        emit Transfer(sender, recipient, amount);
        return true;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
}