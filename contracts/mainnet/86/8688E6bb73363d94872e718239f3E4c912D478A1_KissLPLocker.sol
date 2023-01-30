/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// 
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// 
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// 
interface IUniswapRouterV2 {
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function factory() external view returns (address);
    function WETH() external view returns (address);
}

interface IUniswapFactoryV2 {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapPairV2 {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IKissDeployerToken {
    function identifier() external view returns (string memory);
}

contract KissLPLocker is Ownable {
    uint256 constant public RESOLUTION = 10000;
    string constant public tokenDiscriminator = "Safu Smart Deployer Template ";

    struct LockInfo {
        address getter;
        uint256 amount;
        uint256 lockTime;
        uint256 expireTime;
    }

    struct LockInfoArrayWrapper {
        LockInfo[] info;
        uint256 now;
    }

    struct LockInfoWrapper {
        LockInfo info;
        uint256 now;
    }

    mapping(address => bool) public isFeeExempt;
    address[] public feeDistributionWallets;
    uint256[] public feeDistributionRates;
    uint256 public lockFee;
    address public uniswapV2Router;

    mapping(address => mapping(address => LockInfo[])) context;

    event SetFeeDistributionInfo(address[] wallets, uint256[] rates);
    event SetLockFee(uint256 fee);
    event SetExemptFee(address addr, bool exempt);
    event LockContext(address locker, address pair, address getter, uint256 amount, uint256 lockTime, uint256 expireTime);
    event UnlockContext(address locker, address pair, uint256 lockedIndex, address getter, uint256 amount, uint256 when);
    event AppendLockContext(address locker, address pair, uint256 lockedIndex, uint256 amount);
    event SplitContext(address locker, address pair, uint256 lockedIndex, uint256 amount);

    constructor(address[] memory _feeWallets, uint256[] memory _feeRates, uint256 _lockFee, address[] memory _feeExemptWallets, address _router) {
        require(_feeWallets.length == _feeRates.length, "Invalid Parameters: 0x1");

        uint256 i;

        feeDistributionWallets = new address[](_feeWallets.length);
        feeDistributionRates = new uint256[](_feeRates.length);
        for (i = 0; i < _feeWallets.length; i ++) {
            feeDistributionWallets[i] = _feeWallets[i];
            feeDistributionRates[i] = _feeRates[i];
        }
        emit SetFeeDistributionInfo(feeDistributionWallets, feeDistributionRates);

        lockFee = _lockFee;
        emit SetLockFee(lockFee);

        for (i = 0; i < _feeExemptWallets.length; i ++) {
            isFeeExempt[_feeExemptWallets[i]] = true;
            emit SetExemptFee(_feeExemptWallets[i], true);
        }

        uniswapV2Router = _router;
    }

    function distributePayment(uint256 feeAmount) internal {
        uint256 i;
        for (i = 0; i < feeDistributionWallets.length; i ++) {
            uint256 share = feeDistributionRates[i] * feeAmount / RESOLUTION;
            address feeRx = feeDistributionWallets[i];

            if (share > 0) {
                (bool success,) = payable(feeRx).call{value: share}("");
                if (!success) {
                    continue;
                }
            }
        }
    }

    function recoverETH(address to) external payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to recover");

        (bool success,) = payable(to).call{value: balance}("");
        require(success, "Not Recovered ETH");
    }

    function recoverToken(address token, address to) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No token to recover");

        IERC20(token).transfer(to, balance);
    }

    function setFeeDistributionInfo(address[] memory _feeWallets, uint256[] memory _feeRates) external onlyOwner {
        require(_feeWallets.length == _feeRates.length, "Invalid Parameters: 0x1");

        uint256 i;

        feeDistributionWallets = new address[](_feeWallets.length);
        feeDistributionRates = new uint256[](_feeRates.length);
        for (i = 0; i < _feeWallets.length; i ++) {
            feeDistributionWallets[i] = _feeWallets[i];
            feeDistributionRates[i] = _feeRates[i];
        }
        emit SetFeeDistributionInfo(feeDistributionWallets, feeDistributionRates);
    }

    function setLockFee(uint256 _lockFee) external onlyOwner {
        require(lockFee != _lockFee, "Already Set");
        lockFee = _lockFee;
        emit SetLockFee(_lockFee);
    }

    function setFeeExempt(address pair, bool set) external onlyOwner {
        require(isFeeExempt[pair] != set, "Already Set");
        isFeeExempt[pair] = set;
        emit SetExemptFee(pair, set);
    }

    function getLockTotalInfo(address user, address pair) external view returns (LockInfoArrayWrapper memory) {
        return LockInfoArrayWrapper({
            info: context[user][pair],
            now: block.timestamp
        });
    }

    function getLockInfo(address user, address pair, uint256 lockedIndex) external view returns (LockInfoWrapper memory) {
        return LockInfoWrapper({
            info: context[user][pair][lockedIndex],
            now: block.timestamp
        });
    }

    function _newLock(address locker, address pair, address getter, uint256 amount, uint256 period, bool emitEvent) internal returns (uint256){
        context[locker][pair].push(LockInfo({
            getter: getter,
            amount: amount,
            lockTime: block.timestamp,
            expireTime: block.timestamp + period
        }));

        if (emitEvent) {
            LockInfo storage li = context[locker][pair][context[locker][pair].length - 1];
            emit LockContext(locker, pair, getter, amount, li.lockTime, li.expireTime);
        }
        return context[locker][pair].length - 1;
    }

    function _disposeFee(address locker, address token, bool loose) private returns (uint256) {
        if (lockFee == 0) return 0;

        uint256 feeAmount = lockFee;

        if (isFeeExempt[locker] || (loose && isKissDeployerToken(token))) {
            feeAmount = 0;
        }

        require(msg.value >= feeAmount, "Please Charge Fee");

        if (feeAmount > 0) {
            distributePayment(feeAmount);
        }

        return feeAmount;
    }

    function _appendLock(address locker, address pair, uint256 lockedIndex, uint256 amount) internal {
        LockInfo storage li = context[locker][pair][lockedIndex];

        require(li.lockTime > 0 && li.expireTime > 0, "Not Valid Lock");
        li.amount += amount;

        emit AppendLockContext(locker, pair, lockedIndex, amount);
    }

    function _splitLock(address locker, address pair, uint256 lockedIndex, uint256 amount) internal {
        require(amount > 0, "Trivial");

        LockInfo storage li = context[locker][pair][lockedIndex];
        require(li.lockTime > 0 && li.expireTime > 0, "Not Valid Lock");
        require(li.amount >= amount, "Not Enough Lock");

        li.amount -= amount;

        uint256 lastIndex = _newLock(locker, pair, li.getter, amount, li.expireTime - li.lockTime, false);

        LockInfo storage liLast = context[locker][pair][lastIndex];
        liLast.lockTime = li.lockTime;
        liLast.expireTime = li.expireTime;

        emit SplitContext(locker, pair, lockedIndex, amount);
    }

    function _addToLPFromLocker(address locker, address token, uint256 tokenAmount, uint256 ethAmount) private returns (uint256 liquidity) {
        uint256 oldBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).transferFrom(locker, address(this), tokenAmount);
        uint256 newBalance = IERC20(token).balanceOf(address(this));

        uint256 realAmount = newBalance - oldBalance;

        IERC20(token).approve(uniswapV2Router, realAmount);

        uint256 tokenBal1 = IERC20(token).balanceOf(address(this));
        uint256 ethBal1 = address(this).balance;

        (,, liquidity) = IUniswapRouterV2(uniswapV2Router).addLiquidityETH{value: ethAmount}(token, realAmount, 0, 0, address(this), block.timestamp);

        uint256 tokenBal2 = IERC20(token).balanceOf(address(this));
        uint256 ethBal2 = address(this).balance;

        if (tokenBal2 + realAmount > tokenBal1) {
            IERC20(token).transfer(locker, tokenBal2 + realAmount - tokenBal1);
        }

        if (ethBal2 + ethAmount > ethBal1) {
            (bool success, ) = payable(address(locker)).call{value: ethBal2 + ethAmount - ethBal1}("");
            require(success, "Failed to fund back");
        }
    }

    function addToLPAndLock(address token, address getter, uint256 amount, uint256 lockPeriod) external payable {
        address locker = msg.sender;

        uint256 feeAmount = _disposeFee(locker, token, true);

        uint256 liquidity = _addToLPFromLocker(locker, token, amount, msg.value - feeAmount);

        address factory = IUniswapRouterV2(uniswapV2Router).factory();
        address pair = IUniswapFactoryV2(factory).getPair(token, IUniswapRouterV2(uniswapV2Router).WETH());

        _newLock(locker, pair, getter, liquidity, lockPeriod, true);
    }

    function addToLPAndAppendLock(address token, uint256 amount, uint256 lockedIndex) external payable {
        address locker = msg.sender;

        uint256 liquidity = _addToLPFromLocker(locker, token, amount, msg.value);

        address factory = IUniswapRouterV2(uniswapV2Router).factory();
        address pair = IUniswapFactoryV2(factory).getPair(token, IUniswapRouterV2(uniswapV2Router).WETH());

        _appendLock(locker, pair, lockedIndex, liquidity);
    }

    function lock(address pair, address getter, uint256 liquidity, uint256 lockPeriod) external payable {
        address locker = msg.sender;

        require(isKissTokenPair(pair) != 2, "Not LP Token");

        uint256 feeAmount = _disposeFee(locker, pair, false);
        if (msg.value > feeAmount) {
            (bool success, ) = payable(locker).call{value: msg.value - feeAmount}("");
            require(success, "Failed to refund");
        }

        IERC20(pair).transferFrom(locker, address(this), liquidity);
        _newLock(locker, pair, getter, liquidity, lockPeriod, true);
    }

    function appendLock(address pair, uint256 lockedIndex, uint256 amount) external {
        address locker = msg.sender;
        IERC20(pair).transferFrom(locker, address(this), amount);
        _appendLock(locker, pair, lockedIndex, amount);
    }

    function splitLock(address pair, uint256 lockedIndex, uint256 amount) external {
        address locker = msg.sender;
        _splitLock(locker, pair, lockedIndex, amount);
    }

    function unlock(address pair, uint256 lockedIndex, uint256 amount) external {
        address locker = msg.sender;
        LockInfo storage li = context[locker][pair][lockedIndex];
        require(li.amount > 0, "Not Locked");
        require(li.lockTime > 0 && li.expireTime > 0 && li.expireTime < block.timestamp, "Not Expired");
        require(li.amount >= amount, "Asked Too Much");

        IERC20(pair).transfer(li.getter, li.amount);
        li.amount -= amount;

        if (li.amount == 0) {
            delete context[locker][pair][lockedIndex];
        }
        emit UnlockContext(locker, pair, lockedIndex, li.getter, amount, block.timestamp);
    }

    function isKissDeployerToken(address token) public view returns (bool) {
        try IKissDeployerToken(token).identifier() returns (string memory id) {
            bytes memory ss = bytes(id);
            bytes memory org = bytes(tokenDiscriminator);
            if (ss.length < org.length + 1) return false;

            uint256 i;
            for (i = 0; i < org.length; i ++) {
                if (ss[i] != org[i]) return false;
            }

            return true;
        } catch {
            return false;
        }
    }

    function isKissTokenPair(address pair) public view returns(uint256) {
        try IUniswapPairV2(pair).token0() returns (address token0) {
            if (isKissDeployerToken(token0)) {
                return 0;
            }
        } catch {
            return 2;
        }

        try IUniswapPairV2(pair).token1() returns (address token1) {
            if (isKissDeployerToken(token1)) {
                return 0;
            }
        } catch {
            return 2;
        }
        return 1;
    }

    receive() external payable {
    }
}