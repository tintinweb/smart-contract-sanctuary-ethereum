//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IAssetManager.sol";
import "./interfaces/IExchange.sol";
import "./AssetPool.sol";
import "./libraries/Util.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AssetManager is IAssetManager, Ownable {
    IExchange public exchange;
    address public usd;
    mapping(address => bool) public override tokenSupported;
    address[] internal tokens;
    CreatePoolConfig public createPoolConfig;

    event PoolCreated(address pool);

    constructor(
        IExchange _exchange,
        address _usd,
        address[] memory _tokens,
        CreatePoolConfig memory config
    ) {
        require(_tokens.length > 0, "Tokens list must > 0");
        exchange = _exchange;
        usd = _usd;
        tokens = _tokens;
        for (uint i = 0; i < _tokens.length; i++) {
            address token = tokens[i];
            tokenSupported[token] = true;
        }
        setCreatePoolConfig(config);
    }

    function createPool(IAssetPool.Pool memory pool) external payable {
        CreatePoolConfig memory config = createPoolConfig;
        if (pool.manager == address(0)) pool.manager = msg.sender;
        IAssetPool assetPool = _deployPool(pool);
        uint value;
        if (config.token == address(0)) value = msg.value;
        else {
            IERC20(config.token).transferFrom(msg.sender, address(this), config.minAmount);
            IERC20(config.token).approve(address(assetPool), type(uint).max);
        }
        assetPool.deposit{value: value}(config.token, config.minAmount);
        emit PoolCreated(address(assetPool));
    }

    function _deployPool(IAssetPool.Pool memory pool) internal virtual returns (IAssetPool) {
        return new AssetPool(pool);
    }

    function getUsdBalance(address account) external view override returns (uint usdBalance) {
        address[] memory tokensSupported = tokens;
        for (uint i = 0; i < tokensSupported.length; i++) {
            address token = tokensSupported[i];
            uint balance = Util.getBalance(token, account);
            usdBalance += getUsdAmount(token, balance);
        }
    }

    function getUsdAmount(address token, uint amount) public view override returns (uint) {
        if (token == usd) return amount;
        address[] memory pair = new address[](2);
        pair[0] = token;
        pair[1] = usd;
        uint[] memory amounts = exchange.getAmountsOut(amount, pair);
        return amounts[1];
    }

    function getAmountFromUsd(address token, uint amount) public view override returns (uint) {
        if (token == usd) return amount;
        address[] memory pair = new address[](2);
        pair[0] = token;
        pair[1] = usd;
        uint[] memory amounts = exchange.getAmountsIn(amount, pair);
        return amounts[0];
    }

    function tokensList() external view returns (address[] memory) {
        return tokens;
    }

    function setExchange(IExchange _exchange) external onlyOwner {
        exchange = _exchange;
    }

    function addTokenSupported(address token) external onlyOwner {
        require(!tokenSupported[token], "Already supported");
        tokenSupported[token] = true;
        tokens.push(token);
    }

    function removeTokenSupported(address token) external onlyOwner {
        require(tokenSupported[token], "Not yet supported");
        tokenSupported[token] = false;
        address[] memory tokensSupported = tokens;
        for (uint i; i < tokensSupported.length; i++) {
            if (tokensSupported[i] == token) {
                address tokenLast = tokensSupported[tokensSupported.length - 1];
                tokens[i] = tokenLast;
                tokens.pop();
                break;
            }
        }
    }

    function setUsd(address _usd) external onlyOwner {
        usd = _usd;
    }

    function setCreatePoolConfig(CreatePoolConfig memory config) public onlyOwner {
        require(tokenSupported[config.token], "Token not supported");
        createPoolConfig = config;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAssetManager {
    struct CreatePoolConfig {
        address token;
        uint minAmount;
    }

    function tokenSupported(address token) external view returns (bool);

    function getUsdBalance(address account) external view returns (uint);

    function getUsdAmount(address token, uint amount) external view returns (uint);

    function getAmountFromUsd(address token, uint amount) external view returns (uint);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IExchange {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IAssetPool.sol";
import "./interfaces/IAssetManager.sol";
import "./libraries/Util.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AssetPool is IAssetPool, Ownable {
    Pool public poolInfo;

    mapping(address => uint) internal shares;
    uint public sharesTotal;

    mapping(address => uint) internal sharesPhase;
    uint internal shareCurrentPhase;

    Fee internal feeInfo;

    uint internal constant PRECISION_DECIMALS = 1e4;

    // Psudo constant - for override value
    function MONTH_TIME() internal view virtual returns (uint) {
        return 30 days;
    }

    constructor(Pool memory info) {
        require(info.minAmount < info.maxAmount, "Min amount have to lower than Max amount");
        poolInfo = info;
    }

    modifier onlyManager() {
        require(msg.sender == poolInfo.manager, "Not manager");
        _;
    }

    function deposit(address token, uint amount) public payable override {
        Pool memory info = poolInfo;
        require(info.isOpen, "Not open");
        require(assetManager().tokenSupported(token), "Token not supported");
        require(amount > 0, "Invalid amount");

        address user = msg.sender == owner() ? info.manager : msg.sender;
        if (token == address(0)) {
            require(msg.value == amount, "Invalid ETH amount");
        } else {
            IERC20(token).transferFrom(msg.sender, address(this), amount);
        }

        (uint shareMinted, uint feeTotal, bool isPhaseChanged) = _getMintShareAmounts(token, amount);
        _updateFee(feeTotal);
        _mintTotalShare(isPhaseChanged, shareMinted);
        _mintShare(user, shareMinted);
    }

    function _getMintShareAmounts(address token, uint amount)
        internal
        view
        returns (
            uint shareMinted,
            uint feeTotal,
            bool isPhaseChanged
        )
    {
        Pool memory info = poolInfo;
        uint usdDeposited = assetManager().getUsdAmount(token, amount);
        require(usdDeposited >= info.minAmount && usdDeposited <= info.maxAmount, "Deposit not in limit");
        uint liquidity = assetManager().getUsdBalance(address(this)) - usdDeposited;
        liquidity -= feeTotal = _calculateFeeTotal(liquidity);
        if (liquidity == 0) {
            shareMinted = usdDeposited;
            if (sharesTotal > 0) {
                isPhaseChanged = true;
            }
        } else {
            shareMinted = (usdDeposited * sharesTotal) / liquidity;
        }
    }

    function _mintTotalShare(bool isPhaseChanged, uint shareMinted) internal {
        if (isPhaseChanged) {
            sharesTotal = shareMinted;
            shareCurrentPhase++;
        } else {
            sharesTotal += shareMinted;
        }
    }

    function _mintShare(address user, uint shareMinted) internal {
        if (sharesPhase[user] == shareCurrentPhase) {
            shares[user] += shareMinted;
        } else {
            shares[user] = shareMinted;
            sharesPhase[user] = shareCurrentPhase;
        }
    }

    function withdraw(address token, uint amount) external override {
        require(assetManager().tokenSupported(token), "Token not supported");
        require(amount > 0, "Invalid amount");
        address user = msg.sender;
        if (user == poolInfo.manager) {
            require(userShare(user) == sharesTotal, "Others have not withraw");
        }

        (uint shareBurnt, uint fee, uint feeTotal) = _getBurnShareAmounts(token, amount);
        require(amount <= Util.getBalance(token, address(this)) - fee, "Have no balance to withdraw");
        _updateFee(feeTotal);
        _burnShare(user, shareBurnt);
        _sendFee(token, fee, feeTotal);

        Util.transfer(token, user, amount);
    }

    function _getBurnShareAmounts(address token, uint amount)
        internal
        view
        returns (
            uint shareBurnt,
            uint fee,
            uint feeTotal
        )
    {
        uint usdWithdrawn = assetManager().getUsdAmount(token, amount);
        uint liquidity = assetManager().getUsdBalance(address(this));
        (fee, feeTotal) = _calculateFee(token, liquidity);
        liquidity -= feeTotal;
        if (liquidity > 0) {
            shareBurnt = (sharesTotal * usdWithdrawn) / liquidity;
        }
    }

    function _burnShare(address user, uint shareBurnt) internal {
        require(shareBurnt <= userShare(user), "Withdraw more than share");
        shares[user] -= shareBurnt;
        sharesTotal -= shareBurnt;
    }

    function invest(Action[] calldata actions) external override onlyManager {
        uint liquidity = assetManager().getUsdBalance(address(this));
        uint feeTotal = _calculateFeeTotal(liquidity);
        _updateFee(feeTotal);

        for (uint i = 0; i < actions.length; i++) {
            Action memory action = actions[i];
            (bool success, ) = action.to.call{value: action.value}(action.data);
            require(success, "Contract call fail");
        }
    }

    function claimFee(address token) external override onlyManager {
        require(assetManager().tokenSupported(token), "Token not supported");
        uint balance = Util.getBalance(token, address(this));
        require(balance > 0, "Have no balance to claim");
        uint liquidity = assetManager().getUsdBalance(address(this));
        (uint fee, uint feeTotal) = _calculateFee(token, liquidity);
        require(fee > 0, "Have no fee to claim");
        _sendFee(token, fee, feeTotal);
    }

    function _updateFee(uint feeTotal) internal {
        if (feeInfo.pendingAmount != feeTotal) {
            feeInfo.pendingAmount = feeTotal;
        }
        _updateLastMonthTime();
    }

    function _updateLastMonthTime() internal {
        uint lastMonthTime = feeInfo.lastMonthTime;
        if (lastMonthTime == 0) feeInfo.lastMonthTime = uint40(block.timestamp);
        else {
            uint monthSpan = _getMonthSpan(lastMonthTime);
            if (monthSpan > 0) {
                feeInfo.lastMonthTime = uint40(lastMonthTime + monthSpan * MONTH_TIME());
            }
        }
    }

    function _getMonthSpan(uint lastMonthTime) internal view returns (uint) {
        if (lastMonthTime == 0) return 0;
        uint timeSpan = block.timestamp - lastMonthTime;
        return timeSpan / MONTH_TIME();
    }

    function _calculateFeeTotal(uint liquidity) internal view returns (uint feeTotal) {
        Fee memory info = feeInfo;
        uint monthSpan = _getMonthSpan(info.lastMonthTime);
        uint feeRate = poolInfo.feeMonthlyRate * monthSpan;
        uint updatedFee = (liquidity * feeRate) / PRECISION_DECIMALS;
        feeTotal = info.pendingAmount + updatedFee;
        if (feeTotal > liquidity) feeTotal = liquidity;
    }

    function _calculateFee(address token, uint liquidity) internal view returns (uint fee, uint feeTotal) {
        feeTotal = _calculateFeeTotal(liquidity);
        uint balance = Util.getBalance(token, address(this));
        fee = (balance * feeTotal) / liquidity;
    }

    function _sendFee(
        address token,
        uint fee,
        uint feeTotal
    ) internal {
        uint feeRemained = feeTotal - assetManager().getUsdAmount(token, fee);
        _updateFee(feeRemained);
        Util.transfer(token, poolInfo.manager, fee);
    }

    function feeAmount(address token) external view returns (uint amount, uint amountTotalUsd) {
        require(assetManager().tokenSupported(token), "Token not supported");
        uint liquidity = assetManager().getUsdBalance(address(this));
        return _calculateFee(token, liquidity);
    }

    function withdrawableAmount(address user, address token)
        external
        view
        returns (uint amount, uint amountTotalUsd)
    {
        require(assetManager().tokenSupported(token), "Token not supported");
        if (sharesTotal > 0) {
            uint liquidity = assetManager().getUsdBalance(address(this));
            (uint fee, uint feeTotal) = _calculateFee(token, liquidity);
            liquidity -= feeTotal;
            amountTotalUsd = (liquidity * userShare(user)) / sharesTotal;
            if (amountTotalUsd > 0) {
                uint balance = Util.getBalance(token, address(this)) - fee;
                amount = assetManager().getAmountFromUsd(token, amountTotalUsd);
                amount = amount > balance ? balance : amount;
            }
        }
    }

    function userShare(address user) public view returns (uint share) {
        if (sharesPhase[user] == shareCurrentPhase) return shares[user];
    }

    function assetManager() internal view returns (IAssetManager) {
        return IAssetManager(owner());
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library Util {
    function getBalance(address token, address account) internal view returns (uint) {
        if (token == address(0)) {
            return payable(account).balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    function transfer(
        address token,
        address account,
        uint amount
    ) internal {
        if (token == address(0)) {
            payable(account).transfer(amount);
        } else {
            IERC20(token).transfer(account, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAssetPool {
    struct Pool {
        address manager;
        bool isOpen;
        uint minAmount;
        uint maxAmount;
        uint feeMonthlyRate;
    }

    struct Action {
        address to;
        uint value;
        bytes data;
    }

    struct Fee {
        uint pendingAmount;
        uint40 lastMonthTime;
    }

    function deposit(address token, uint amount) external payable;

    function withdraw(address token, uint amount) external;

    function invest(Action[] calldata actions) external;

    function claimFee(address token) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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