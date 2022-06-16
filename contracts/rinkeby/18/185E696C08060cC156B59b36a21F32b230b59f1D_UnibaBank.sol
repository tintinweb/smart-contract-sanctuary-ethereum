// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import {TransferHelper} from "TransferHelper.sol";

/**
 * @title UnibaBank
 * @notice It handles the logic of the bank
 */
contract UnibaBank is Ownable {
    struct UserInfo {
        mapping (address => uint256) tokenDeposited; // tokens  deposited
        uint256 ethDeposited;
        uint256 lastBlockClaimedRewards;
        uint256 shares;
        uint256 tokenAccrued;
    }

    struct coinType {
        address[] tokenContracts;
        uint8 mult;
    }

    // Precision factor for calculating rewards and exchange rate
    uint256 public constant PRECISION_FACTOR = 10**18;

    address private immutable unibaToken;

    // Reward rate (block)
    uint256 public constant REWARD_PER_BLOCK = 1 * PRECISION_FACTOR;
    // Total blocks for rewards
    uint256 public TOTAL_BLOCKS = 2102400;
    uint256 public immutable startBlock;

    uint8 private totalMult = 6;
    uint8 private constant UNIBA_MULT = 6;
    coinType private coinMult;
    coinType private stableMult;

    mapping(address => UserInfo) private userInfo;
    uint256 private totalShares;

    mapping(address => uint256) public totalTokenDeposited;
    uint256 public totalEthDeposited;

    event Deposit(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 harvestedAmount);
    event Withdraw(address indexed user, uint256 amount, uint256 harvestedAmount);

    /**
     * @notice Constructor
     * @param _unibaToken address of the Uniba token
     */
    constructor(address _unibaToken) {
        unibaToken = _unibaToken;
        startBlock = block.number;
        coinMult.mult = 3;
        stableMult.mult = 1;
    }

    /**
    * @notice Deposit ETH
    */
    function depositETH() external payable {
        require(msg.value > 0, "The amount deposited should be greater than 0!");

        userInfo[msg.sender].ethDeposited += msg.value;
        totalEthDeposited += msg.value;

        if (userInfo[msg.sender].lastBlockClaimedRewards != 0) userInfo[msg.sender].tokenAccrued = calculateRewards(msg.sender);
        userInfo[msg.sender].lastBlockClaimedRewards = block.number;
        userInfo[msg.sender].shares = calculateSharesDeposit(userInfo[msg.sender], msg.value, coinMult.mult);

        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Deposit tokens
     * @param token address of the token to deposit
     * @param amount amount to deposit
     */
    function deposit(address token, uint256 amount) public {
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);

        userInfo[msg.sender].tokenDeposited[token] += amount;
        totalTokenDeposited[token] += amount;

        if (userInfo[msg.sender].lastBlockClaimedRewards != 0) userInfo[msg.sender].tokenAccrued = calculateRewards(msg.sender);
        userInfo[msg.sender].lastBlockClaimedRewards = block.number;
        uint8 mult = isCoin(token) ? coinMult.mult : isStablecoin(token) ? stableMult.mult : 0;
        userInfo[msg.sender].shares = calculateSharesDeposit(userInfo[msg.sender], amount, mult);

        emit Deposit(msg.sender, amount);
    }

    function getTokenDepositedByUser(address account, address token) external view returns (uint256 amount) {
        amount = userInfo[account].tokenDeposited[token];
    }

    function getEtherDepositedByUser(address account) external view returns (uint256 amount) {
        amount = userInfo[account].ethDeposited;
    }

    /**
    * @notice Withdraw ETH
    * @param amount amount to withdraw
    */
    function withdrawETH(uint256 amount) external {
        require(amount <= userInfo[msg.sender].ethDeposited, "The amount to withdraw should be greater than the one deposited!");
        userInfo[msg.sender].ethDeposited -= amount;
        totalEthDeposited -= amount;

        (bool success, ) = msg.sender.call{value:amount}("");
        require(success);

        if (userInfo[msg.sender].lastBlockClaimedRewards != 0) userInfo[msg.sender].tokenAccrued = calculateRewards(msg.sender);
        userInfo[msg.sender].lastBlockClaimedRewards = block.number;
        userInfo[msg.sender].shares = calculateSharesWithdraw(userInfo[msg.sender], amount, coinMult.mult);

        emit Withdraw(msg.sender, amount, 0);
    }

    /**
     * @notice Withdraw tokens
     * @param token address of the token to withdraw
     * @param amount amount to withdraw
     */
    function withdraw(address token, uint256 amount) public {        
        require(amount <= userInfo[msg.sender].tokenDeposited[token], "The amount to withdraw should be greater than the one deposited!");
        userInfo[msg.sender].tokenDeposited[token] -= amount;
        totalTokenDeposited[token] -= amount;

        TransferHelper.safeApprove(token, address(this), amount);
        TransferHelper.safeTransferFrom(token, address(this), msg.sender, amount);

        if (userInfo[msg.sender].lastBlockClaimedRewards != 0) userInfo[msg.sender].tokenAccrued = calculateRewards(msg.sender);
        userInfo[msg.sender].lastBlockClaimedRewards = block.number;
        uint8 mult = isCoin(token) ? coinMult.mult : isStablecoin(token) ? stableMult.mult : 0;
        userInfo[msg.sender].shares = calculateSharesWithdraw(userInfo[msg.sender], amount, mult);

        emit Withdraw(msg.sender, amount, 0);
    }

    function addMultAltcoin(address token) public onlyOwner {
        uint256 index = coinMult.tokenContracts.length + 1;
        for(uint256 i = 0; i < coinMult.tokenContracts.length; i++) {
            if(coinMult.tokenContracts[i] == token) index = i;
        }
        if(index == coinMult.tokenContracts.length + 1) {
            coinMult.tokenContracts.push(token);
        } 
    }

    function addMultStablecoin(address token) public onlyOwner {
        uint256 index = stableMult.tokenContracts.length + 1;
        for(uint256 i = 0; i < stableMult.tokenContracts.length; i++) {
            if(stableMult.tokenContracts[i] == token) index = i;
        }
        if(index == stableMult.tokenContracts.length + 1) stableMult.tokenContracts.push(token);
    }

    function isCoin(address token) internal view returns (bool result) {
        result = false;
        uint256 index = coinMult.tokenContracts.length + 1;
        for(uint256 i = 0; i < coinMult.tokenContracts.length; i++) {
            if(coinMult.tokenContracts[i] == token) index = i;
        }
        if(index != coinMult.tokenContracts.length + 1) result = true;
    }

    function isStablecoin(address token) internal view returns (bool result) {
        result = false;
        uint256 index = stableMult.tokenContracts.length + 1;
        for(uint256 i = 0; i < stableMult.tokenContracts.length; i++) {
            if(stableMult.tokenContracts[i] == token) index = i;
        }
        if(index != stableMult.tokenContracts.length + 1) result = true; 
    }

    function calculateRewards(address user) internal view returns (uint256 result) {
        require(totalShares > 0, "There are no shares!");
        require(userInfo[user].lastBlockClaimedRewards < block.number, "You should wait to claim!");
        uint256 blockWindow = block.number - userInfo[user].lastBlockClaimedRewards;
        result = userInfo[user].shares / totalShares * blockWindow * PRECISION_FACTOR;
    }

    function calculateSharesDeposit(UserInfo storage user, uint256 amount, uint8 mult) internal returns (uint256 result) {
        uint256 prevShares = user.shares;
        uint256 newShares = mult * amount;
        totalShares += (newShares - prevShares);
        result = newShares + prevShares;
    }

    function calculateSharesWithdraw(UserInfo storage user, uint256 amount, uint8 mult) internal returns (uint256 result) {
        uint256 prevShares = user.shares;
        uint256 newShares = mult * amount;
        totalShares -= newShares;
        result = prevShares - newShares;
    }

    function getTokenToClaim(address user) public view returns (uint256 result) {
        result = calculateRewards(user) + userInfo[user].tokenAccrued;
    }

    function claim() public {        
        require(userInfo[msg.sender].lastBlockClaimedRewards != 0, "No tokens to claim!");
        uint256 toClaim = 0;

        toClaim = getTokenToClaim(msg.sender);
        userInfo[msg.sender].tokenAccrued = 0;
        userInfo[msg.sender].lastBlockClaimedRewards = block.number;

        TransferHelper.safeTransfer(unibaToken, msg.sender, toClaim);

        emit Harvest(msg.sender, toClaim);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import "IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
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