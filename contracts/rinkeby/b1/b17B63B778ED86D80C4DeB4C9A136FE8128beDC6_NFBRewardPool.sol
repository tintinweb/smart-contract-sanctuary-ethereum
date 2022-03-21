// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFBRewardPool is Ownable, ReentrancyGuard {
    address public nfbRouter;
    uint256 public totalRewards;
    uint16 public maxWinnersCount;
    uint256[] public rewardRanges;
    uint256[] public rewardDistribution;
    address public wETH;
    mapping(uint256 => bool) public hasClaimed;

    event LogNFBRouterSet(address triggeredBy, address newAddress);
    event LogRewardPoolUpdated(address from, uint256 newTotalRewardPool);
    event LogWithdraw(address to, uint256 amount);
    event LogWithdrawFundsLeft(address to, uint256 amount);
    event LogClaimed(uint256 position);

    modifier isValidAddress(address addr) {
        require(addr != address(0), "NFBRewardPool: Invalid address");
        _;
    }

    modifier onlyFromNFBRouter() {
        require(msg.sender == nfbRouter, "NFBRewardPool: Invalid call");
        _;
    }

    constructor(
        uint256[] memory _rewardDistribution,
        uint256[] memory _rewardRanges,
        uint16 _maxWinnersCount,
        address _wETH
    ) isValidAddress(_wETH) {
        rewardDistribution = _rewardDistribution;
        rewardRanges = _rewardRanges;
        maxWinnersCount = _maxWinnersCount;
        wETH = _wETH;
    }

    /**
     * @dev Setter for the `nfbRouter`
     * @param _nfbRouter NFBRouter contract address
     * * Requirements:
     *
     * - only owner of the contract can call.
     *
     * Emits {LogNFBRouterSet} event.
     */
    function setNFBRouter(address _nfbRouter) external onlyOwner {
        require(
            _nfbRouter != address(0),
            "NFBRewardPool: NFBRouter can't be zero address"
        );
        nfbRouter = _nfbRouter;
        emit LogNFBRouterSet(msg.sender, _nfbRouter);
    }

    /**
     * @dev Set that position for `winningBracket` in NFBRouter is claimed
     * @param position NFBRouter contract address
     * * Requirements:
     *
     * - only onlyFromNFBRouter can call.
     *
     * Emits {LogClaimed} event.
     */
    function setClaimed(uint256 position) private {
        hasClaimed[position] = true;

        emit LogClaimed(position);
    }

    /**
     * @dev Updates the `totalRewards` when a NFT is minted or updated
     * @param amount amount which will be added to the `totalRewards`
     * * Requirements:
     *
     * - must be called from `nfbRouter` only.
     *
     * Emits {LogRewardPoolUpdated} event.
     */
    function updateRewardPool(uint256 amount)
        external
        onlyFromNFBRouter
        nonReentrant
    {
        totalRewards += amount;
        emit LogRewardPoolUpdated(msg.sender, amount);
    }

    /**
     * @dev Calculates reward percent for given bracket position in the winning brackets array in NFBRouter contract.
     * @param position - which we are going to calculate the reward against.
     * @return reward
     * Requirements:
     *
     * the balance in the currency which NFBRouter operates must be higher than zero
     */
    function calcReward(uint256 position) public view returns (uint256) {
        uint256 balance = IERC20(wETH).balanceOf(address(this));
        require(balance > 0, "NFBRewardPool: insufficient funds");

        uint256 reward = 0;

        for (uint256 r = 0; r < rewardRanges.length - 1; r++) {
            // if the provided position is in the last range of winners
            if (position >= rewardRanges[rewardRanges.length - 1]) {
                reward =
                    rewardDistribution[rewardRanges.length - 1] /
                    (maxWinnersCount -
                        rewardRanges[rewardRanges.length - 1] +
                        1); // total percent for the current range / winners count in the range
                break;

                // if the provided position is in all range before the last
            } else if (
                (position >= rewardRanges[r]) &&
                (position < rewardRanges[r + 1])
            ) {
                reward =
                    rewardDistribution[r] /
                    (rewardRanges[r + 1] - rewardRanges[r]); // total percent for the current range / winners count in the range
                break;
            }
        }

        return (totalRewards / 1e15) * reward;
    }

    /**
     * @dev Send certain amount of funds, depending on the ranking `to` the owner of a winning bracket
     * @param _to player who will receive its reward
     * @param position position which the bracket takes in `winningBrackets`.
     * * Requirements:
     *
     * - must be called from `nfbRouter` only.
     *
     * Emits {LogWithdraw} event.
     */
    function withdraw(address _to, uint256 position)
        external
        onlyFromNFBRouter
        nonReentrant
        returns (uint256)
    {
        uint256 _amount = calcReward(position);

        setClaimed(position);

        require(
            IERC20(wETH).transfer(_to, _amount),
            "NFBRewardPool: failed to send reward"
        );

        emit LogWithdraw(_to, _amount);

        return _amount;
    }

    /**
     * @dev Send the funds left after specific period of time the tournament has finished.
     * @param _to owner of NFBRouter
     * * Requirements:
     *
     * - must be called from `nfbRouter` only.
     *
     * Emits {LogWithdraw} event.
     */
    function withdrawFundsLeft(address _to)
        external
        onlyFromNFBRouter
        nonReentrant
        returns (uint256)
    {
        uint256 _amount = IERC20(wETH).balanceOf(address(this));

        require(
            IERC20(wETH).transfer(_to, _amount),
            "NFBRewardPool: failed to pull funds"
        );

        emit LogWithdrawFundsLeft(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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