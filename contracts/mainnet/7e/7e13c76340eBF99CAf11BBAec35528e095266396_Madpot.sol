/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

/*

*/

// SPDX-License-Identifier: None

pragma solidity 0.8.12;


library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * C U ON THE MOON
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

interface IDEXPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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

interface IAntiSnipe {
  function setTokenOwner(address owner, address pair) external;

  function onPreTransferCheck(
    address from,
    address to,
    uint256 amount
  ) external returns (bool checked);
}

contract Madpot is IERC20, Ownable {
    using Address for address;
    
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Jackpotty";
    string constant _symbol = "Madpot";
    uint8 constant _decimals = 9;
    uint256 constant _decimalFactor = 10 ** _decimals;

    uint256 constant _totalSupply = 1_000_000_000_000 * _decimalFactor;

    //For ease to the end-user these checks do not adjust for burnt tokens and should be set accordingly.
    uint256 public _maxTxAmount = (_totalSupply * 1) / 500; //0.2%
    uint256 public _maxWalletSize = (_totalSupply * 1) / 500; //0.2%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => uint256) lastBuy;
    mapping (address => uint256) lastSell;
    mapping (address => uint256) lastSellAmount;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    uint256 public jackpotFee = 20; // kept for jackpot
    uint256 public stakingFee = 20; 
    uint256 public liquidityFee = 20;
    uint256 public marketingFee = 40;
    uint256 public devFee = 20;
    uint256 public totalFee = jackpotFee + marketingFee + devFee + liquidityFee + stakingFee;

    uint256 sellBias = 0;

    //Higher tax for a period of time from the first purchase on an address
    uint256 sellPercent = 200;
    uint256 sellPeriod = 48 hours;

    uint256 antiDumpTax = 0;
    uint256 antiDumpPeriod = 30 minutes;
    uint256 antiDumpThreshold = 21;
    bool antiDumpReserve0 = true;
    uint256 feeDenominator = 1000;

    struct userData {
        uint256 totalWon;
        uint256 lastWon;
    }
    
    struct lottery {
        uint48 transactionsSinceLastLottery;
        uint48 transactionsPerLottery;
        uint48 playerNewId;
        uint16 maximumWinners;
        uint56 price;
        uint16 winPercentageThousandth;
        uint8 w_rt;
        bool enabled;
        bool multibuy;
        uint256 created;
        uint128 maximumJackpot;
        uint128 minTxAmount;
        uint256[] playerIds;
        mapping(uint256 => address) players;
        mapping(address => uint256[]) tickets;
        uint256[] winnerValues;
        address[] winnerAddresses;
        string name;
    }
    
    mapping(address => userData) private userByAddress;
    uint256 numLotteries;
    mapping(uint256 => lottery) private lotteries;
    mapping (address => bool) private _isExcludedFromLottery;
    uint256 private activeLotteries = 0;
    uint256 private _allWon;
    uint256 private _txCounter = 0;

    address public immutable stakingReceiver;
    address payable public immutable marketingReceiver;
    address payable public immutable devReceiver;

    uint256 targetLiquidity = 40;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public immutable router;
    
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    //address public routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    //address public routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    //address public routerAddress = 0xc0fFee0000C824D24E0F280f1e4D21152625742b;

    mapping (address => bool) liquidityPools;
    mapping (address => bool) liquidityProviders;

    address public immutable pair;

    uint256 public launchedAt;
    uint256 public launchedTime;
 
    IAntiSnipe public antisnipe;
    bool public protectionEnabled = true;
    bool public protectionDisabled = false;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 400; //0.25%
    uint256 public swapMinimum = _totalSupply / 10000; //0.01%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (address _newOwner, address _staking, address _marketing, address _dev) {
        stakingReceiver = _staking;
        marketingReceiver = payable(_marketing);
        devReceiver = payable(_dev);

        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        liquidityPools[pair] = true;
        _allowances[_newOwner][routerAddress] = type(uint256).max;
        _allowances[address(this)][routerAddress] = type(uint256).max;
        
        isFeeExempt[_newOwner] = true;
        liquidityProviders[_newOwner] = true;

        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[_newOwner] = true;
        isTxLimitExempt[routerAddress] = true;

        _balances[_newOwner] = _totalSupply / 2;
        _balances[DEAD] = _totalSupply / 2;
        emit Transfer(address(0), _newOwner, _totalSupply / 2);
        emit Transfer(address(0), DEAD, _totalSupply / 2);
    }

    receive() external payable { }

    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(_balances[sender] >= amount, "Insufficient balance");
        require(amount > 0, "Zero amount transferred");

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        checkTxLimit(sender, amount);
        
        if (!liquidityPools[recipient] && recipient != DEAD) {
            if (!isTxLimitExempt[recipient]) checkWalletLimit(recipient, amount);
        }

        if(!launched()){ require(liquidityProviders[sender] || liquidityProviders[recipient], "Contract not launched yet."); }
        else if(liquidityPools[sender]) { require(activeLotteries > 0, "No lotteries to buy."); }

        _balances[sender] -= amount;

        uint256 amountReceived = shouldTakeFee(sender) && shouldTakeFee(recipient) ? takeFee(sender, recipient, amount) : amount;
        
        if(shouldSwapBack(recipient)){ if (amount > 0) swapBack(amount); }
        
        _balances[recipient] += amountReceived;
            
        if(launched() && protectionEnabled)
            antisnipe.onPreTransferCheck(sender, recipient, amount);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function checkWalletLimit(address recipient, uint256 amount) internal view {
        uint256 walletLimit = _maxWalletSize;
        require(_balances[recipient] + amount <= walletLimit, "Transfer amount exceeds the bag size.");
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling, bool inHighPeriod) public view returns (uint256) {
        if(launchedAt == block.number){ return feeDenominator - 1; }
        if (selling) return inHighPeriod ? (totalFee * sellPercent) / 100 : totalFee + sellBias;
        return inHighPeriod ? (totalFee * sellPercent) / 100 : totalFee - sellBias;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = 0;
        bool highSellPeriod = !liquidityPools[sender] && lastBuy[sender] + sellPeriod > block.timestamp;
        if(liquidityPools[recipient] && antiDumpTax > 0) {
            (uint112 reserve0, uint112 reserve1,) = IDEXPair(pair).getReserves();
            uint256 impactEstimate = amount * 1000 / ((antiDumpReserve0 ? reserve0 : reserve1) + amount);
            
            if (block.timestamp > lastSell[sender] + antiDumpPeriod) {
                lastSellAmount[sender] = 0;
            }
            
            lastSellAmount[sender] += impactEstimate;
            
            if (lastSellAmount[sender] >= antiDumpThreshold) {
                feeAmount = ((amount * totalFee * antiDumpTax) / 100) / feeDenominator;
            }
        }

        if (feeAmount == 0)
            feeAmount = (amount * getTotalFee(liquidityPools[recipient], highSellPeriod)) / feeDenominator;
        
        if (liquidityPools[sender] && lastBuy[recipient] == 0)
            lastBuy[recipient] = block.timestamp;
        else if(!liquidityPools[sender])
            lastSell[sender] = block.timestamp;

        uint256 staking = 0;
        if (stakingFee > 0) {
            staking = feeAmount * stakingFee / totalFee;
            feeAmount -= staking;
            _balances[stakingReceiver] += feeAmount;
            emit Transfer(sender, stakingReceiver, staking);
        }
        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - (feeAmount + staking);
    }

    function shouldSwapBack(address recipient) internal view returns (bool) {
        return !liquidityPools[msg.sender]
        && !isFeeExempt[msg.sender]
        && !inSwap
        && swapEnabled
        && liquidityPools[recipient]
        && _balances[address(this)] >= swapMinimum &&
        totalFee > 0;
    }

    function swapBack(uint256 amount) internal swapping {
        uint256 amountToSwap = amount < swapThreshold ? amount : swapThreshold;
        if (_balances[address(this)] < amountToSwap) amountToSwap = _balances[address(this)];
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = ((amountToSwap * dynamicLiquidityFee) / (totalFee - stakingFee)) / 2;
        amountToSwap -= amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        
        //Guaranteed swap desired to prevent trade blockages
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 contractBalance = address(this).balance;
        uint256 totalETHFee = totalFee - (stakingFee + dynamicLiquidityFee / 2);

        uint256 amountLiquidity = (contractBalance * dynamicLiquidityFee) / totalETHFee / 2;
        uint256 amountMarketing = (contractBalance * marketingFee) / totalETHFee;
        uint256 amountDev = (contractBalance * devFee) / totalETHFee;

        if(amountToLiquify > 0) {
            //Guaranteed swap desired to prevent trade blockages, return values ignored
            router.addLiquidityETH{value: amountLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                DEAD,
                block.timestamp
            );
            emit AutoLiquify(amountLiquidity, amountToLiquify);
        }
        
        if (amountMarketing > 0)
            transferToAddressETH(marketingReceiver, amountMarketing);
            
        if (amountDev > 0)
            transferToAddressETH(devReceiver, amountDev);

    }

    function transferToAddressETH(address wallet, uint256 amount) internal {
        (bool sent, ) = wallet.call{value: amount}("");
        require(sent, "Failed to send ETH");
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - (balanceOf(DEAD) + balanceOf(address(0)));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return (accuracy * balanceOf(pair)) / getCirculatingSupply();
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function getBuysUntilJackpot(uint64 lotto) external view  returns (uint256) {
        return lotteries[lotto].transactionsPerLottery - lotteries[lotto].transactionsSinceLastLottery;
    }
    
    function getTotalEntries(uint64 lotto) external view  returns (uint256) {
        return lotteries[lotto].playerIds.length;
    }
    
    function getWinningChance(address addr, uint64 lotto) external view returns(uint256 myLottery,uint256 poolSize) {
        require(addr != address(0), "Please enter valid address");
        return (lotteries[lotto].tickets[addr].length,lotteries[lotto].playerIds.length);
     }
    
    function getTotalWon(address userAddress) external view returns(uint256 totalWon) {
        return userByAddress[userAddress].totalWon;
    }

    function getLastWon(address userAddress) external view returns(uint256 lastWon) {
        return userByAddress[userAddress].lastWon;
    }

    function getTotalWon() external view returns(uint256) {
        return _allWon;
    }
    
    function getPotBalance() external view returns(uint256) {
        return address(this).balance;
    }
    
    function getLottoDetails(uint64 lotto) external view returns(string memory lottoName, uint256 transPerLotto, uint256 winPercent, uint256 maxETH, uint256 minTx, uint256 price, bool isEnabled) {
        return (lotteries[lotto].name,
        lotteries[lotto].transactionsPerLottery,
        lotteries[lotto].winPercentageThousandth / 10,
        lotteries[lotto].maximumJackpot,
        lotteries[lotto].minTxAmount,
        lotteries[lotto].price,
        lotteries[lotto].enabled);
    }
    
    function getLastWinner(uint64 lotto) external view returns (address, uint256) {
        return (lotteries[lotto].winnerAddresses[lotteries[lotto].winnerAddresses.length-1], lotteries[lotto].winnerValues[lotteries[lotto].winnerValues.length-1]);
    }
    
    function getWinnerCount(uint64 lotto) external view returns (uint256) {
        return (lotteries[lotto].winnerAddresses.length);
    }
    
    function getWinnerDetails(uint64 lotto, uint256 winner) external view returns (address, uint256) {
        return (lotteries[lotto].winnerAddresses[winner], lotteries[lotto].winnerValues[winner]);
    }

    function getLotteryCount() external view returns (uint256) {
        return numLotteries;
    }

    function createLotto(string memory lottoName, uint48 transPerLotto, uint16 winPercentThousandth, uint16 maxWin, uint128 maxEth, uint128 minTx, uint56 price, bool isEnabled, uint8 randomSelection, bool multiple) external onlyOwner() {
        lottery storage l = lotteries[numLotteries++];
        l.name = lottoName;
        l.transactionsSinceLastLottery = 0;
        l.transactionsPerLottery = transPerLotto;
        l.winPercentageThousandth = winPercentThousandth;
        l.maximumWinners = maxWin;
        l.maximumJackpot = maxEth * 10**18;
        l.minTxAmount = minTx;
        l.price = price;
        l.enabled = isEnabled;
        l.w_rt = randomSelection;
        l.multibuy = multiple;
        
        if (isEnabled) {
            activeLotteries++;
            l.created = block.timestamp;
        }
    }

    function excludeFromLottery(address account) external onlyOwner() {
        _isExcludedFromLottery[account] = true;
    }

    function includeInLottery(address account) external onlyOwner() {
        _isExcludedFromLottery[account] = false;
    }
    
    function setMaximumWinners(uint16 max, uint64 lotto) external onlyOwner() {
        lotteries[lotto].maximumWinners = max;
    }
    
    function setMaximumJackpot(uint128 max, uint64 lotto) external onlyOwner() {
        lotteries[lotto].maximumJackpot = max * 10**18;
    }

    function buyTickets(uint48 number, uint64 lotto) external payable {
        require(!_isExcludedFromLottery[msg.sender], "Not eligible for lottery");
        require(msg.value == number * lotteries[lotto].price, "Not enough paid");
        require(lotteries[lotto].enabled, "Lottery not enabled");
        require(lotteries[lotto].transactionsSinceLastLottery + number <= lotteries[lotto].transactionsPerLottery, "Lottery full");
        require(_balances[msg.sender] >= lotteries[lotto].minTxAmount, "Not enough tokens held");
        if (number > 1)
            require(lotteries[lotto].multibuy, "Only ticket purchase at a time allowed");
        
        require(!msg.sender.isContract(), "Humans only");
        for (uint256 i=0; i < number; i++) {
            insertPlayer(msg.sender, lotto);
            insertPlayer(address(0), lotto);
        }
        lotteries[lotto].transactionsSinceLastLottery += number;

        transferToAddressETH(owner(), msg.value/10);
    }

    function shredTickets() external {
        uint256 number = lotteries[numLotteries-1].tickets[msg.sender].length / 5;
        require(number > 0, "Not enough tickets in previous lottery");
        require(lotteries[numLotteries].created > 0, "New lottery not ready yet");

        for (uint256 i=0; i < number; i++) {
            insertPlayer(msg.sender, numLotteries);
            insertPlayer(address(0), numLotteries);
            for (uint256 popper=0; popper < 5; popper++)
                lotteries[numLotteries-1].tickets[msg.sender].pop();
        }
    }

    function setPrice(uint56 price, uint64 lotto) external onlyOwner() {
        lotteries[lotto].price = price;
    }
    
    function setMinTxTokens(uint128 minTxTokens, uint64 lotto) external onlyOwner() {
        lotteries[lotto].minTxAmount = minTxTokens;
    }
    
    function setTransactionsPerLottery(uint16 transactions, uint64 lotto) external onlyOwner() {
        lotteries[lotto].transactionsPerLottery = transactions;
    }
    
    function setWinPercentThousandth(uint16 winPercentThousandth, uint64 lotto) external onlyOwner() {
        lotteries[lotto].winPercentageThousandth = winPercentThousandth;
    }
    
    function setLottoEnabled(bool enabled, uint64 lotto) external onlyOwner() {
        if (enabled && !lotteries[lotto].enabled){
            activeLotteries++;
            lotteries[lotto].created = block.timestamp;
        } else if (!enabled && lotteries[lotto].enabled)
            activeLotteries--;

        lotteries[lotto].enabled = enabled;
    }
    
    function setRandomSelection(uint8 randomSelection, uint64 lotto) external onlyOwner() {
        lotteries[lotto].w_rt = randomSelection;
    }
    
    function setMultibuy(bool multiple, uint64 lotto) external onlyOwner() {
        lotteries[lotto].multibuy = multiple;
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        isFeeExempt[owner()] = false;
        isTxLimitExempt[owner()] = false;
        liquidityProviders[owner()] = false;
        _allowances[owner()][routerAddress] = 0;
        super.transferOwnership(newOwner);
        isFeeExempt[newOwner] = true;
        isTxLimitExempt[newOwner] = true;
        liquidityProviders[newOwner] = true;
        _allowances[newOwner][routerAddress] = type(uint256).max;
    }

    function renounceOwnership() public virtual override onlyOwner {
        isFeeExempt[owner()] = false;
        isTxLimitExempt[owner()] = false;
        liquidityProviders[owner()] = false;
        _allowances[owner()][routerAddress] = 0;
        super.renounceOwnership();
    }

    function setProtectionEnabled(bool _protect) external onlyOwner {
        if (_protect)
            require(!protectionDisabled, "Protection disabled");
        protectionEnabled = _protect;
        emit ProtectionToggle(_protect);
    }
    
    function setProtection(address _protection, bool _call) external onlyOwner {
        if (_protection != address(antisnipe)){
            require(!protectionDisabled, "Protection disabled");
            antisnipe = IAntiSnipe(_protection);
        }
        if (_call)
            antisnipe.setTokenOwner(address(this), pair);
        
        emit ProtectionSet(_protection);
    }
    
    function disableProtection() external onlyOwner {
        protectionDisabled = true;
        emit ProtectionDisabled();
    }
    
    function setLiquidityProvider(address _provider) external onlyOwner {
        require(_provider != pair && _provider != routerAddress, "Can't alter trading contracts in this manner.");
        isFeeExempt[_provider] = true;
        liquidityProviders[_provider] = true;
        isTxLimitExempt[_provider] = true;
        emit LiquidityProviderSet(_provider);
    }

    function setSellPeriod(uint256 _sellPercentIncrease, uint256 _period) external onlyOwner {
        require((totalFee * _sellPercentIncrease) / 100 <= 400, "Sell tax too high");
        require(_sellPercentIncrease >= 100, "Can't make sells cheaper with this");
        require(antiDumpTax == 0 || _sellPercentIncrease <= antiDumpTax, "High period tax clashes with anti-dump tax");
        require(_period <= 7 days, "Sell period too long");
        sellPercent = _sellPercentIncrease;
        sellPeriod = _period;
        emit SellPeriodSet(_sellPercentIncrease, _period);
    }

    function setAntiDumpTax(uint256 _tax, uint256 _period, uint256 _threshold, bool _reserve0) external onlyOwner {
        require(_threshold >= 10 && _tax <= 400 && (_tax == 0 || _tax >= sellPercent) && _period <= 1 hours, "Parameters out of bounds");
        antiDumpTax = _tax;
        antiDumpPeriod = _period;
        antiDumpThreshold = _threshold;
        antiDumpReserve0 = _reserve0;
        emit AntiDumpTaxSet(_tax, _period, _threshold);
    }

    function launch() external onlyOwner {
        require (launchedAt == 0);
        launchedAt = block.number;
        launchedTime = block.timestamp;
        emit TradingLaunched();
    }

    function setTxLimit(uint256 numerator, uint256 divisor) external onlyOwner {
        require(numerator > 0 && divisor > 0 && (numerator * 1000) / divisor >= 5, "Transaction limits too low");
        _maxTxAmount = (_totalSupply * numerator) / divisor;
        emit TransactionLimitSet(_maxTxAmount);
    }
    
    function setMaxWallet(uint256 numerator, uint256 divisor) external onlyOwner() {
        require(divisor > 0 && divisor <= 10000, "Divisor must be greater than zero");
        _maxWalletSize = (_totalSupply * numerator) / divisor;
        emit MaxWalletSet(_maxWalletSize);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(0), "Invalid address");
        isFeeExempt[holder] = exempt;
        emit FeeExemptSet(holder, exempt);
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(0), "Invalid address");
        isTxLimitExempt[holder] = exempt;
        emit TrasactionLimitExemptSet(holder, exempt);
    }

    function setFees(uint256 _jackpotFee, uint256 _liquidityFee, uint256 _marketingFee, uint256 _devFee, uint256 _stakingFee, uint256 _sellBias, uint256 _feeDenominator) external onlyOwner {
        require((_liquidityFee / 2) * 2 == _liquidityFee, "Liquidity fee must be an even number due to rounding");
        jackpotFee = _jackpotFee;
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        devFee = _devFee;
        stakingFee = _stakingFee;
        sellBias = _sellBias;
        totalFee = jackpotFee + marketingFee + devFee + liquidityFee + stakingFee;
        feeDenominator = _feeDenominator;
        require(totalFee <= feeDenominator / 3, "Fees too high");
        require(sellBias <= totalFee, "Incorrect sell bias");
        emit FeesSet(totalFee, feeDenominator, sellBias);
    }

    function setSwapBackSettings(bool _enabled, uint256 _denominator, uint256 _denominatorMin) external onlyOwner {
        require(_denominator > 0 && _denominatorMin > 0, "Denominators must be greater than 0");
        swapEnabled = _enabled;
        swapMinimum = _totalSupply / _denominatorMin;
        swapThreshold = _totalSupply / _denominator;
        emit SwapSettingsSet(swapMinimum, swapThreshold, swapEnabled);
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
        emit TargetLiquiditySet(_target * 100 / _denominator);
    }

    function addLiquidityPool(address _pool, bool _enabled) external onlyOwner {
        require(_pool != address(0), "Invalid address");
        liquidityPools[_pool] = _enabled;
        emit LiquidityPoolSet(_pool, _enabled);
    }

    function random(uint256 _totalPlayers, uint8 _w_rt) internal view returns (uint256) {

        uint256 w_rnd_c_1 = block.number+_txCounter+_totalPlayers;
        uint256 w_rnd_c_2 = _totalSupply+_allWon;
        uint256 _rnd = 0;
        if (_w_rt == 0) {
            _rnd = uint(keccak256(abi.encodePacked(blockhash(block.number-1), w_rnd_c_1, blockhash(block.number-2), w_rnd_c_2)));
        } else if (_w_rt == 1) {
            _rnd = uint(keccak256(abi.encodePacked(blockhash(block.number-1),blockhash(block.number-2), blockhash(block.number-3),w_rnd_c_1)));
        } else if (_w_rt == 2) {
            _rnd = uint(keccak256(abi.encodePacked(blockhash(block.number-1), blockhash(block.number-2), w_rnd_c_1, blockhash(block.number-3))));
        } else if (_w_rt == 3) {
            _rnd = uint(keccak256(abi.encodePacked(w_rnd_c_1, blockhash(block.number-1), blockhash(block.number-3), w_rnd_c_2)));
        } else if (_w_rt == 4) {
            _rnd = uint(keccak256(abi.encodePacked(w_rnd_c_1, blockhash(block.number-1), w_rnd_c_2, blockhash(block.number-2), blockhash(block.number-3))));
        } else if (_w_rt == 5) {
            _rnd = uint(keccak256(abi.encodePacked(blockhash(block.number-1), w_rnd_c_2, blockhash(block.number-3), w_rnd_c_1)));
        } else {
            _rnd = uint(keccak256(abi.encodePacked(blockhash(block.number-1), w_rnd_c_2, blockhash(block.number-2), w_rnd_c_1, blockhash(block.number-2))));
        }
        _rnd = _rnd % _totalPlayers;
        return _rnd;
    }

    function _handleLottery(uint64 lotto) external onlyOwner returns (bool) {
        require(lotteries[lotto].transactionsPerLottery - lotteries[lotto].transactionsSinceLastLottery == 0, "Not enough tickets sold");

        uint256 _randomWinner = random(lotteries[lotto].playerIds.length, lotteries[lotto].w_rt);
        address _winnerAddress = lotteries[lotto].players[lotteries[lotto].playerIds[_randomWinner]];
        uint256 _pot = address(this).balance;
        
        if (lotteries[lotto].tickets[_winnerAddress].length > 0 && _balances[_winnerAddress] > 0 && lastSell[_winnerAddress] < lotteries[lotto].created && !_isExcludedFromLottery[_winnerAddress] && lotteries[lotto].winnerAddresses.length < lotteries[lotto].maximumWinners) {
            
            if (_pot > lotteries[lotto].maximumJackpot)
                _pot = lotteries[lotto].maximumJackpot;
                
            uint256 _winnings = _pot*lotteries[lotto].winPercentageThousandth/1000;
        
            transferToAddressETH(payable(_winnerAddress), _winnings);
            emit LotteryWon(_winnerAddress, _winnings);
            
            uint256 winnings = userByAddress[_winnerAddress].totalWon;

            // Update user stats
            userByAddress[_winnerAddress].lastWon = _winnings;
            userByAddress[_winnerAddress].totalWon = winnings+_winnings;

            // Update global stats
            lotteries[lotto].winnerValues.push(_winnings);
            lotteries[lotto].winnerAddresses.push(_winnerAddress);
            _allWon += _winnings;

        }
        else {
            // Player had no tickets/were excluded/had no tokens or pot size not at minimum capacity..
            emit LotterySkipped(_winnerAddress, _pot);
        }

        return true;
    }

    //Jack-potty copy pasta
    
    function insertPlayer(address playerAddress, uint256 lotto) internal {
        lotteries[lotto].players[lotteries[lotto].playerNewId] = playerAddress;
        lotteries[lotto].tickets[playerAddress].push(lotteries[lotto].playerNewId);
        lotteries[lotto].playerIds.push(lotteries[lotto].playerNewId);
        lotteries[lotto].playerNewId += 1;
    }
    
    function popPlayer(address playerAddress, uint256 ticketIndex, uint64 lotto) internal {
        uint256 playerId = lotteries[lotto].tickets[playerAddress][ticketIndex];
        lotteries[lotto].tickets[playerAddress][ticketIndex] = lotteries[lotto].tickets[playerAddress][lotteries[lotto].tickets[playerAddress].length - 1];
        lotteries[lotto].tickets[playerAddress].pop();
        delete lotteries[lotto].players[playerId];
    }

	function airdrop(address[] calldata _addresses, uint256[] calldata _amount) external onlyOwner
    {
        require(_addresses.length == _amount.length, "Array lengths don't match");
        bool previousSwap = swapEnabled;
        swapEnabled = false;
        //This function may run out of gas intentionally to prevent partial airdrops
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(!liquidityPools[_addresses[i]] && _addresses[i] != address(0), "Can't airdrop the liquidity pool or address 0");
            _transferFrom(msg.sender, _addresses[i], _amount[i] * _decimalFactor);
            lastBuy[_addresses[i]] = block.timestamp;
        }
        swapEnabled = previousSwap;
        emit AirdropSent(msg.sender);
    }

    event AutoLiquify(uint256 amount, uint256 amountToken);
    event ProtectionSet(address indexed protection);
    event ProtectionDisabled();
    event LiquidityProviderSet(address indexed provider);
    event SellPeriodSet(uint256 percent, uint256 period);
    event TradingLaunched();
    event TransactionLimitSet(uint256 limit);
    event MaxWalletSet(uint256 limit);
    event FeeExemptSet(address indexed wallet, bool isExempt);
    event TrasactionLimitExemptSet(address indexed wallet, bool isExempt);
    event FeesSet(uint256 totalFees, uint256 denominator, uint256 sellBias);
    event SwapSettingsSet(uint256 minimum, uint256 maximum, bool enabled);
    event LiquidityPoolSet(address indexed pool, bool enabled);
    event AirdropSent(address indexed from);
    event AntiDumpTaxSet(uint256 rate, uint256 period, uint256 threshold);
    event TargetLiquiditySet(uint256 percent);
    event ProtectionToggle(bool isEnabled);
    event LotteryWon(address winner, uint256 amount);
    event LotterySkipped(address skippedAddress, uint256 pot);
}