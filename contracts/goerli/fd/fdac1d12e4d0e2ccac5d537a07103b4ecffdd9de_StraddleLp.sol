//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IStraddleLp} from "../contracts/interfaces/IStraddleLp.sol";
import {StraddleBaseLp} from "../contracts/helpers/StraddleBaseLp.sol";

contract StraddleLp is StraddleBaseLp {
    using SafeERC20 for IERC20;

    /*==== CONSTRUCTOR ====*/

    /// @dev An StraddleLp contract maps an asset to its straddle contract.
    /// @dev I.e., A ETH to ETH straddle.
    /// @param _name Name of contract, i.e., ETH-STRADDLE-SLP.
    constructor(string memory _name) {
        name = _name;
    }

    /*==== USER METHODS ====*/

    /// @inheritdoc IStraddleLp
    function addToLp(
        uint256 strike,
        uint256 numTokens,
        uint256 markup,
        address to
    ) external nonReentrant returns (bool) {
        _isEligibleSender();
        _whenNotPaused();

        if (!_addLiquidity(strike, numTokens, markup, to)) {
            revert LpPositionFailedToAdd();
        }
        return true;
    }

    /// @inheritdoc IStraddleLp
    function multiAddToLp(
        uint256[] memory strikes,
        uint256[] memory liquidity,
        uint256[] memory markup,
        address to
    ) external nonReentrant returns (bool) {
        _isEligibleSender();
        _whenNotPaused();

        if (
            strikes.length == 0 ||
            strikes.length > MULTI_ADD_LIMIT ||
            strikes.length != liquidity.length ||
            liquidity.length != markup.length
        ) {
            revert InvalidParams();
        }

        for (uint256 i; i < strikes.length; ) {
            if (!_addLiquidity(strikes[i], liquidity[i], markup[i], to)) {
                revert LpPositionFailedToAdd();
            }
            unchecked {
                ++i;
            }
        }
        return true;
    }

    /// @dev helper function to add liquidity
    function _addLiquidity(
        uint256 strike,
        uint256 numTokens,
        uint256 markup,
        address seller
    ) internal returns (bool) {
        validateLowerThanCurrentPrice(strike);
        validateStrike(strike);

        if (numTokens == 0) {
            revert InvalidLiquidity();
        }
        if (markup == 0 || markup > 100) {
            revert InvalidMarkup();
        }

        uint256 liquidity = Math.mulDiv(
            strike,
            numTokens,
            AMOUNT_PRICE_TO_USDC_DECIMALS
        );
        uint256 lpId = allLpPositions[strike].length;
        LpPosition memory lpPos = LpPosition({
            lpId: lpId,
            epoch: getStraddleEpoch(),
            strike: strike,
            liquidity: liquidity,
            liquidityUsed: 0,
            markup: markup,
            purchased: 0,
            seller: seller,
            killed: false
        });

        allLpPositions[strike].push(lpPos);
        userLpPositions[seller][strike].push(lpId);
        strikeLiquidity[getStraddleEpoch()][strike].write += liquidity;

        IERC20(addresses.usd).safeTransferFrom(
            msg.sender,
            address(this),
            liquidity
        );

        emit LiquidityAdded(strike, numTokens, seller);
        return true;
    }

    /// @inheritdoc IStraddleLp
    function fillLpPosition(
        uint256 strike,
        uint256 lpIndex,
        uint256 amount
    ) external nonReentrant returns (bool) {
        _isEligibleSender();
        _whenNotPaused();

        _fillLpPosition(getStraddleEpoch(), strike, lpIndex, amount);
        return true;
    }

    /// @inheritdoc IStraddleLp
    function multiFillLpPosition(
        uint256[] memory strikes,
        uint256[] memory lpIndices,
        uint256[] memory amounts
    ) external nonReentrant returns (bool) {
        _isEligibleSender();
        _whenNotPaused();

        if (
            lpIndices.length == 0 ||
            lpIndices.length != amounts.length ||
            lpIndices.length != strikes.length
        ) {
            revert InvalidParams();
        }

        uint256 currentEpoch = getStraddleEpoch();

        for (uint256 i; i < lpIndices.length; ) {
            _fillLpPosition(currentEpoch, strikes[i], lpIndices[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
        return true;
    }

    /// @dev helper function to fill an LP position at index
    function _fillLpPosition(
        uint256 currentEpoch,
        uint256 strike,
        uint256 lpIndex,
        uint256 numTokens
    ) internal returns (bool) {
        if (numTokens <= DUST_THRESHOLD) {
            revert InvalidAmount();
        }
        if (lpIndex >= allLpPositions[strike].length) {
            revert InvalidLpIndex();
        }

        LpPosition memory lpPosition = allLpPositions[strike][lpIndex];
        if (lpPosition.killed) {
            revert LpPositionDead();
        }
        if (lpPosition.epoch != currentEpoch) {
            revert InvalidEpochToFill();
        }

        uint256 premium = getPutOptionPremium(strike, numTokens);
        if (premium > lpPosition.liquidity) {
            revert InsuffientLiquidity(premium, lpPosition.liquidity);
        }

        uint256 markup = Math.mulDiv(premium, lpPosition.markup, PERCENT);

        allLpPositions[strike][lpIndex].liquidity -= premium;
        allLpPositions[strike][lpIndex].liquidityUsed += premium;
        // TODO: can deposit 10 tokens but depending on premium, can buy more than 10
        allLpPositions[strike][lpIndex].purchased += numTokens;
        strikeLiquidity[currentEpoch][strike].write -= premium;
        strikeLiquidity[currentEpoch][strike].purchase += premium;

        uint256 receiptId = allPurchasePositions[strike].length;

        PurchaseReceipt memory receipt = PurchaseReceipt({
            receiptId: receiptId,
            epoch: getStraddleEpoch(),
            amount: numTokens,
            buyer: msg.sender,
            settled: false
        });
        allPurchasePositions[strike].push(receipt);
        userPurchasePositions[msg.sender][strike].push(receiptId);

        // if liquidity is lower than threshold, kill the position
        if (allLpPositions[strike][lpIndex].liquidity < DUST_THRESHOLD) {
            if (!_clearLpDust(strike, lpIndex)) {
                revert LpDustFailedToClear();
            }
        }

        // Transfer premium to seller
        IERC20(addresses.usd).safeTransferFrom(
            msg.sender,
            lpPosition.seller,
            premium + markup
        );

        emit LPPositionFilled(strike, lpIndex, numTokens, premium, msg.sender);
        return true;
    }

    /// @inheritdoc IStraddleLp
    function killLpPosition(uint256 strike, uint256 lpIndex)
        external
        nonReentrant
        returns (bool)
    {
        _isEligibleSender();
        _whenNotPaused();

        if (!_killLpPosition(strike, lpIndex)) {
            revert LpPositionFailedToKill();
        }
        return true;
    }

    /// @inheritdoc IStraddleLp
    function multiKillLpPosition(
        uint256[] memory strikes,
        uint256[] memory lpIndices
    ) external nonReentrant returns (bool) {
        _isEligibleSender();
        _whenNotPaused();

        if (lpIndices.length == 0 || lpIndices.length != strikes.length) {
            revert InvalidParams();
        }
        for (uint256 i; i < lpIndices.length; ) {
            if (!_killLpPosition(strikes[i], lpIndices[i])) {
                revert LpPositionFailedToKill();
            }
            unchecked {
                ++i;
            }
        }
        return true;
    }

    /// @dev helper function to kill an LP position at index
    function _killLpPosition(uint256 strike, uint256 lpIndex)
        internal
        returns (bool)
    {
        if (lpIndex >= allLpPositions[strike].length) {
            revert InvalidLpIndex();
        }

        LpPosition memory lpPosition = allLpPositions[strike][lpIndex];
        if (lpPosition.seller != msg.sender) {
            revert OnlySellerCanKill();
        }
        if (lpPosition.killed) {
            revert LpPositionDead();
        }
        if (
            !_killAndTransfer(
                lpPosition.epoch,
                strike,
                lpIndex,
                lpPosition.seller,
                lpPosition.liquidity
            )
        ) {
            revert PositionFailedToKillAndTransfer();
        }

        emit LPPositionKilled(strike, lpIndex);
        return true;
    }

    /// @dev helper function to clear LP dust position at index
    function _clearLpDust(uint256 strike, uint256 lpIndex)
        internal
        returns (bool)
    {
        LpPosition memory lpPosition = allLpPositions[strike][lpIndex];

        if (
            !_killAndTransfer(
                lpPosition.epoch,
                strike,
                lpIndex,
                lpPosition.seller,
                lpPosition.liquidity
            )
        ) {
            revert PositionFailedToKillAndTransfer();
        }

        emit LPDustCleared(strike, lpIndex);
        return true;
    }

    /// @dev helper function to kill position and
    /// @dev transfer liquidity left in position back to LP
    function _killAndTransfer(
        uint256 epoch,
        uint256 strike,
        uint256 lpIndex,
        address seller,
        uint256 liquidity
    ) internal returns (bool) {
        allLpPositions[strike][lpIndex].killed = true;

        if (liquidity != 0) {
            strikeLiquidity[epoch][strike].write -= liquidity;
            IERC20(addresses.usd).safeTransfer(seller, liquidity);
        }

        emit LpPositionKillAndTransfer(strike, lpIndex);
        return true;
    }

    /// @inheritdoc IStraddleLp
    function settle(uint256 strike, uint256 receiptIndex)
        external
        nonReentrant
        returns (bool)
    {
        _isEligibleSender();
        _whenNotPaused();

        if (receiptIndex >= allPurchasePositions[strike].length) {
            revert InvalidParams();
        }

        if (!_settle(strike, receiptIndex)) {
            revert FailToSettle();
        }

        return true;
    }

    /// @inheritdoc IStraddleLp
    function multiSettle(
        uint256[] memory strikes,
        uint256[] memory receiptIndices
    ) external nonReentrant returns (bool) {
        _isEligibleSender();
        _whenNotPaused();

        if (
            receiptIndices.length == 0 ||
            receiptIndices.length != strikes.length
        ) {
            revert InvalidParams();
        }

        for (uint256 i; i < receiptIndices.length; ) {
            if (!_settle(strikes[i], receiptIndices[i])) {
                revert FailToSettle();
            }
            unchecked {
                ++i;
            }
        }

        return true;
    }

    /// @dev helper function to settle position
    function _settle(uint256 strike, uint256 receiptIndex)
        internal
        returns (bool)
    {
        PurchaseReceipt memory receipt = allPurchasePositions[strike][
            receiptIndex
        ];

        if (receipt.settled) {
            revert PositionWasSettled();
        }

        uint256 pnl = calculatePutOptionPnl(
            getStraddleSettlementPrice(receipt.epoch),
            strike,
            receipt.amount
        );

        if (pnl == 0) {
            revert PnlIsZero();
        }

        allPurchasePositions[strike][receiptIndex].settled = true;

        IERC20(addresses.usd).safeTransfer(receipt.buyer, pnl);

        emit Settled(strike, receiptIndex);
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IStraddleLp {
    event LiquidityAdded(
        uint256 strike,
        uint256 numTokens,
        address indexed seller
    );
    event LPPositionFilled(
        uint256 strike,
        uint256 index,
        uint256 numTokens,
        uint256 premium,
        address indexed buyer
    );
    event LPPositionKilled(uint256 strike, uint256 index);
    event LPDustCleared(uint256 strike, uint256 index);
    event LpPositionKillAndTransfer(uint256 strike, uint256 index);
    event AddressesSet(Addresses addresses);
    event StraddleExpiryUpdated(address straddle, uint256 expiry);
    event EmergencyWithdrawn(address caller);
    event Settled(uint256 strike, uint256 receiptIndex);

    struct LpPosition {
        uint256 lpId;
        uint256 epoch;
        uint256 strike;
        uint256 liquidity;
        uint256 liquidityUsed;
        uint256 markup;
        uint256 purchased;
        address seller;
        bool killed;
    }

    struct Addresses {
        address usd;
        address straddle;
        address underlying;
    }

    struct Liquidity {
        uint256 write;
        uint256 purchase;
    }

    struct PurchaseReceipt {
        uint256 receiptId;
        uint256 epoch;
        uint256 amount;
        address buyer;
        bool settled;
    }

    /**
     * Adds a new LP position for a token
     * @param strike Strikes to purchase at
     * @param numTokens Num of tokens to sell
     * @param markup Markup on top of the option's premium in %
     * @param to Address to send option tokens to if purchase succeeds
     * @return Whether new LP position was created
     */
    function addToLp(
        uint256 strike,
        uint256 numTokens,
        uint256 markup,
        address to
    ) external returns (bool);

    /**
     * Adds multiple new LP positions for a token
     * @param strikes Strikes to sell at
     * @param amounts Num of tokens to sell
     * @param markups Markups on top of the option's premium in %
     * @param to Address to send option tokens to if purchase succeeds
     * @return Whether new LP position was created
     */
    function multiAddToLp(
        uint256[] memory strikes,
        uint256[] memory amounts,
        uint256[] memory markups,
        address to
    ) external returns (bool);

    /**
     * Fills an LP position with available liquidity
     * @param strike of LP to fill
     * @param lpIndex Index of LP position
     * @param numTokens num of options to buy from each LP position
     * @return Whether LP positions were filled
     */
    function fillLpPosition(
        uint256 strike,
        uint256 lpIndex,
        uint256 numTokens
    ) external returns (bool);

    /**
     * Fills multiple LP positions with available liquidity
     * @param strikes of LP to fill
     * @param lpIndices Index of LP position
     * @param amounts Amount of options to buy from each LP position
     * @return Whether LP positions were filled
     */
    function multiFillLpPosition(
        uint256[] memory strikes,
        uint256[] memory lpIndices,
        uint256[] memory amounts
    ) external returns (bool);

    /**
     * Kills an active LP position
     * @param strike of LP provided
     * @param lpIndex Index of LP position
     * @return Whether LP position is killed
     */
    function killLpPosition(uint256 strike, uint256 lpIndex)
        external
        returns (bool);

    /**
     * Kills multiple active LP positions
     * @param strikes of LP provided
     * @param lpIndices Index of LP position
     * @return Whether LP positions are killed
     */
    function multiKillLpPosition(
        uint256[] memory strikes,
        uint256[] memory lpIndices
    ) external returns (bool);

    /**
     * Settles the option position
     * @param strike of option purchased
     * @param receiptIndex Index of purchase receipt
     * @return Whether settlement was successful
     */
    function settle(uint256 strike, uint256 receiptIndex)
        external
        returns (bool);

    /**
     * Settles multiple option positions
     * @param strikes of option purchased
     * @param receiptIndices Indices of purchase receipt
     * @return Whether settlement was successful
     */
    function multiSettle(
        uint256[] memory strikes,
        uint256[] memory receiptIndices
    ) external returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Pausable} from "./Pausable.sol";
import {ContractWhitelist} from "./ContractWhitelist.sol";
import {IStraddle} from "../interfaces/IStraddle.sol";
import {IStraddleLp} from "../interfaces/IStraddleLp.sol";

abstract contract StraddleBaseLp is
    IStraddleLp,
    ReentrancyGuard,
    Ownable,
    Pausable,
    ContractWhitelist
{
    using SafeERC20 for IERC20;

    uint256 internal constant TENS = 2;
    uint256 internal constant THIRD_SIG_FIG = 5;
    uint256 internal constant DEFAULT_TICKSPACING = 1e8;
    uint256 internal constant TEN_USD = 10e8;
    uint256 internal constant MULTI_ADD_LIMIT = 5;
    uint256 internal constant PERCENT = 1e2;
    uint256 internal constant USDC_DECIMALS = 1e6;
    uint256 internal constant PREMIUM_DECIMALS = 1e8;
    uint256 internal constant DUST_THRESHOLD = 1e7; // $10
    uint256 internal constant TOKEN_DUST_THRESHOLD = 1e15; // 0.001 $token
    uint256 internal constant AMOUNT_PRICE_TO_USDC_DECIMALS =
        (1e18 * 1e8) / 1e6;

    string public name;
    Addresses public addresses;

    // mapping (epoch => strike => liquidity)
    mapping(uint256 => mapping(uint256 => Liquidity)) public strikeLiquidity;
    // mapping (straddle address => expiries)
    mapping(address => uint256[]) internal straddleExpiries;
    // mapping (strike) => LpPosition[])
    mapping(uint256 => LpPosition[]) internal allLpPositions;
    // mapping (user => strike => lpId[])
    mapping(address => mapping(uint256 => uint256[])) internal userLpPositions;
    // mapping (strike) => PurchaseReceipt[])
    mapping(uint256 => PurchaseReceipt[]) internal allPurchasePositions;
    // mapping (user => strike => PositionsId[])
    mapping(address => mapping(uint256 => uint256[]))
        internal userPurchasePositions;

    /// @param strike strike price
    /// @notice if strike is less than $10,
    /// @notice make sure the first DP is 5 and second DP is 0
    function validateBelowTen(uint256 strike) internal pure returns (bool) {
        // 150e6
        if (strike % (DEFAULT_TICKSPACING / TENS) != 0) {
            revert InvalidTick(strike);
        }
        uint256 firstDp = strike / (DEFAULT_TICKSPACING / 10);
        if (firstDp % THIRD_SIG_FIG != 0) {
            revert InvalidTick(strike);
        }
        return true;
    }

    /// @param strike strike price to LP
    /// @notice strike takes in 8 decimal place
    /// @notice and must be in 2 or 3 significant digits
    /// @notice if it has 3 sf, the 3rd sf must be 5
    /// @notice e.g., 42,500, 4,250, 42
    function validateStrike(uint256 strike) internal pure returns (bool) {
        if (strike < TEN_USD) {
            validateBelowTen(strike);
        } else {
            if (strike % DEFAULT_TICKSPACING != 0) {
                revert InvalidTick(strike);
            }

            uint256 usdStrike = strike / DEFAULT_TICKSPACING; // 45, 420, 4,250, 42,500
            uint256 placeValue = Math.log10(usdStrike); // 1, 2, 3, 4
            if (placeValue <= TENS && usdStrike % THIRD_SIG_FIG != 0) {
                revert InvalidTick(strike);
            }

            uint256 factor = placeValue > TENS ? 10**(placeValue - TENS) : 0; // 0, 0, 10, 100
            if (
                placeValue > TENS &&
                (usdStrike % factor != 0 ||
                    (usdStrike / factor) % THIRD_SIG_FIG != 0)
            ) {
                revert InvalidTick(strike);
            }
        }
        return true;
    }

    /// @param strike strike price to LP
    /// @notice strike must be lower than current price
    function validateLowerThanCurrentPrice(uint256 strike)
        internal
        view
        returns (bool)
    {
        if (strike > getStraddleAssetPrice()) {
            revert InvalidStrike(strike);
        }
        return true;
    }

    /*==== ADMIN METHODS ====*/

    /// @notice Pauses the vault for emergency cases
    /// @dev Can only be called by the owner
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the vault
    /// @dev Can only be called by the owner
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Sets (adds) a list of addresses to the address list
    /// @notice takes in USDC, STRADDLE, and UNDERLYING address
    /// @dev Can only be called by the owner
    /// @param _addresses addresses of contracts in the Addresses struct
    function setAddresses(Addresses calldata _addresses)
        external
        onlyOwner
        returns (bool)
    {
        addresses = _addresses;
        emit AddressesSet(_addresses);
        return true;
    }

    /// @notice Transfers all funds to msg.sender
    /// @dev Can only be called by the owner
    /// @param tokens The list of erc20 tokens to withdraw
    /// @param transferNative Whether should transfer the native currency
    function emergencyWithdrawn(address[] calldata tokens, bool transferNative)
        external
        onlyOwner
    {
        _whenPaused();
        if (transferNative) payable(msg.sender).transfer(address(this).balance);

        IERC20 token;

        for (uint256 i = 0; i < tokens.length; i++) {
            token = IERC20(tokens[i]);
            token.safeTransfer(msg.sender, token.balanceOf(address(this)));
        }

        emit EmergencyWithdrawn(msg.sender);
    }

    /// @notice Add a contract to the whitelist
    /// @dev Can only be called by the admin
    /// @param _contract Address of the contract that needs to be added to the whitelist
    function addToContractWhitelist(address _contract) external onlyOwner {
        _addToContractWhitelist(_contract);
    }

    /// @notice Remove a contract to the whitelist
    /// @dev Can only be called by the admin
    /// @param _contract Address of the contract that needs to be removed from the whitelist
    function removeFromContractWhitelist(address _contract) external onlyOwner {
        _removeFromContractWhitelist(_contract);
    }

    /// @notice Updates the list of epoch expiries
    /// @param straddle addresses of straddle
    /// @dev Can be run by a bot
    function updateStraddleExpiry(address straddle) external returns (bool) {
        uint256 expiry = getStraddleExpiry();
        require(expiry > block.timestamp, "Expiry must be in the future");
        if (
            straddleExpiries[straddle].length == 0 ||
            straddleExpiries[straddle][straddleExpiries[straddle].length - 1] !=
            expiry
        ) {
            straddleExpiries[straddle].push(expiry);
            emit StraddleExpiryUpdated(straddle, expiry);
            return true;
        }
        return false;
    }

    /*==== straddle VIEW METHODS ====*/

    function getStraddle() public view returns (IStraddle) {
        return IStraddle(addresses.straddle);
    }

    function getStraddleEpoch() public view returns (uint256) {
        return getStraddle().currentEpoch();
    }

    function getStraddleExpiry() public view returns (uint256) {
        return getStraddle().epochData(getStraddleEpoch()).expiry;
    }

    function getStraddleAssetPrice() public view returns (uint256) {
        return getStraddle().getUnderlyingPrice();
    }

    function getStraddleSettlementPrice(uint256 epoch)
        public
        view
        returns (uint256)
    {
        uint256 epochExpiry = getStraddle().epochData(epoch).expiry;
        require(epochExpiry <= block.timestamp, "Epoch has not expired");
        return getStraddle().epochData(epoch).settlementPrice;
    }

    /**
     * Calculates premium for a put option
     * @param strike Option strike
     * @param amount Underlying amount
     * @return Price of the put option
     */
    function getPutOptionPremium(uint256 strike, uint256 amount)
        public
        view
        returns (uint256)
    {
        return
            getStraddle().calculatePremium(
                true,
                strike,
                amount,
                getStraddleExpiry()
            ) / 1 ether;
    }

    /**
     * Calculates pnl for a put option
     * @param price Current price or settled price
     * @param strike Option strike
     * @param amount Underlying amount
     * @return Price of the put option
     */
    function calculatePutOptionPnl(
        uint256 price,
        uint256 strike,
        uint256 amount
    ) public pure returns (uint256) {
        return
            strike > price
                ? Math.mulDiv(
                    strike - price,
                    amount,
                    AMOUNT_PRICE_TO_USDC_DECIMALS
                )
                : 0;
    }

    /*==== VIEW METHODS ====*/

    function getEpochExpiries(address straddle)
        public
        view
        returns (uint256[] memory)
    {
        return straddleExpiries[straddle];
    }

    function getStrikeLiquidity(uint256 epoch, uint256 strike)
        public
        view
        returns (Liquidity memory)
    {
        return strikeLiquidity[epoch][strike];
    }

    /**
     * Returns all LP positions for a given user
     * @param strike epoch strike token address
     * @param user address of user
     * @return positions the user's LP positions
     */
    function getUserLpPositions(uint256 strike, address user)
        external
        view
        returns (LpPosition[] memory positions)
    {
        uint256[] memory userPositionsId = userLpPositions[user][strike];
        uint256 numPositions = userPositionsId.length;
        positions = new LpPosition[](numPositions);
        for (uint256 i; i < numPositions; ) {
            positions[i] = allLpPositions[strike][userPositionsId[i]];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * Returns all LP positions for a given strikeToken
     * @param strike strike user deposited
     * @return all LP positions
     */
    function getAllLpPositions(uint256 strike)
        external
        view
        returns (LpPosition[] memory)
    {
        return allLpPositions[strike];
    }

    /**
     * Returns all purchase positions for a given user
     * @param strike epoch strike token address
     * @param user address of user
     * @return positions the user's purchase positions
     */
    function getUserPurchasePositions(uint256 strike, address user)
        external
        view
        returns (PurchaseReceipt[] memory positions)
    {
        uint256[] memory userReceiptsId = userPurchasePositions[user][strike];
        uint256 numPositions = userReceiptsId.length;
        positions = new PurchaseReceipt[](numPositions);
        for (uint256 i; i < numPositions; ) {
            positions[i] = allPurchasePositions[strike][userReceiptsId[i]];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * Returns all purchase positions for a given strikeToken
     * @param strike strike user deposited
     * @return all purchase positions
     */
    function getAllPurchasePositions(uint256 strike)
        external
        view
        returns (PurchaseReceipt[] memory)
    {
        return allPurchasePositions[strike];
    }

    /*==== ERRORS ====*/

    error FailToSettle();
    error InsuffientLiquidity(uint256 premium, uint256 liquidity);
    error InvalidAmount();
    error InvalidEpochToFill();
    error InvalidLiquidity();
    error InvalidLpIndex();
    error InvalidMarkup();
    error InvalidParams();
    error InvalidPlaceValue(uint256 strike);
    error InvalidStrike(uint256 strike);
    error InvalidTick(uint256 strike);
    error LpPositionDead();
    error LpPositionFailedToAdd();
    error LpPositionFailedToFill();
    error LpPositionFailedToKill();
    error LpDustFailedToClear();
    error PnlIsZero();
    error PositionFailedToKillAndTransfer();
    error PositionWasSettled();
    error OnlySellerCanKill();
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title Lighter version of the Openzeppelin Pausable contract
/// @author witherblock
/// @notice Helps pause a contract to block the execution of selected functions
/// @dev Difference from the Openzeppelin version is changing the modifiers to internal fns and requires to reverts
abstract contract Pausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Internal function to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _whenNotPaused() internal view {
        if (paused()) revert ContractPaused();
    }

    /**
     * @dev Internal function to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _whenPaused() internal view {
        if (!paused()) revert ContractNotPaused();
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual {
        _whenNotPaused();
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual {
        _whenPaused();
        _paused = false;
        emit Unpaused(msg.sender);
    }

    error ContractPaused();
    error ContractNotPaused();
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @title ContractWhitelist
/// @author witherblock
/// @notice A helper contract that lets you add a list of whitelisted contracts that should be able to interact with restricited functions
abstract contract ContractWhitelist {
    /// @dev contract => whitelisted or not
    mapping(address => bool) public whitelistedContracts;

    /*==== SETTERS ====*/

    /// @dev add to the contract whitelist
    /// @param _contract the address of the contract to add to the contract whitelist
    function _addToContractWhitelist(address _contract) internal {
        require(isContract(_contract), "Address must be a contract");
        require(
            !whitelistedContracts[_contract],
            "Contract already whitelisted"
        );

        whitelistedContracts[_contract] = true;

        emit AddToContractWhitelist(_contract);
    }

    /// @dev remove from  the contract whitelist
    /// @param _contract the address of the contract to remove from the contract whitelist
    function _removeFromContractWhitelist(address _contract) internal {
        require(whitelistedContracts[_contract], "Contract not whitelisted");

        whitelistedContracts[_contract] = false;

        emit RemoveFromContractWhitelist(_contract);
    }

    // modifier is eligible sender modifier
    function _isEligibleSender() internal view {
        // the below condition checks whether the caller is a contract or not
        if (msg.sender != tx.origin)
            require(
                whitelistedContracts[msg.sender],
                "Contract must be whitelisted"
            );
    }

    /*==== VIEWS ====*/

    /// @dev checks for contract or eoa addresses
    /// @param addr the address to check
    /// @return bool whether the passed address is a contract address
    function isContract(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /*==== EVENTS ====*/

    event AddToContractWhitelist(address indexed _contract);

    event RemoveFromContractWhitelist(address indexed _contract);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

struct EpochData {
    // Start time
    uint256 startTime;
    // Expiry time
    uint256 expiry;
    // Total USD deposits
    uint256 usdDeposits;
    // Active USD deposits (used for writing)
    uint256 activeUsdDeposits;
    // Settlement Price
    uint256 settlementPrice;
    // Percentage of total settlement executed
    uint256 settlementPercentage;
    // Amount of underlying assets purchased
    uint256 underlyingPurchased;
}

interface IStraddle {
    function epochData(uint256 epoch) external view returns (EpochData memory);

    function currentEpoch() external view returns (uint256 epoch);

    function calculatePremium(
        bool _isPut,
        uint256 _strike,
        uint256 _amount,
        uint256 _expiry
    ) external view returns (uint256 premium);

    function getUnderlyingPrice() external view returns (uint256 price);
}