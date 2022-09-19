// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import {console} from "hardhat/console.sol";
import {INFTLocker} from "../interfaces/INFTLocker.sol";
import {IFeeDistributor} from "../interfaces/IFeeDistributor.sol";

contract FeeDistributor is Ownable, IFeeDistributor, ReentrancyGuard {
    uint256 public constant WEEK = 7 * 86400;
    uint256 public constant TOKEN_CHECKPOINT_DEADLINE = 86400;

    uint256 public startTime;
    uint256 public timeCursor;
    mapping(uint256 => uint256) public timeCursorOf;
    mapping(uint256 => uint256) public userEpochOf;

    uint256 public lastTokenTime;
    uint256[1000000000000000] public tokensPerWeek;

    INFTLocker public locker;
    IERC20 public token;
    uint256 public tokenLastBalance;

    uint256[1000000000000000] public veSupply; // VE total supply at week bounds

    bool public isKilled;
    bool public canCheckpointToken = true;

    constructor(
        address _votingEscrow,
        uint256 _startTime,
        address _token
    ) {
        uint256 t = (_startTime / WEEK) * WEEK;
        startTime = t;
        lastTokenTime = t;
        timeCursor = t;
        token = IERC20(_token);
        locker = INFTLocker(_votingEscrow);
    }

    function _checkpointToken() internal {
        // console.log("_checkpointToken(...)");
        uint256 tokenBalance = token.balanceOf(address(this));
        uint256 toDistribute = tokenBalance - tokenLastBalance;
        tokenLastBalance = tokenBalance;

        uint256 t = lastTokenTime;
        uint256 sinceLast = block.timestamp - t;
        lastTokenTime = block.timestamp;

        uint256 thisWeek = (t / WEEK) * WEEK;
        uint256 nextWeek = 0;

        for (uint256 index = 0; index < 20; index++) {
            nextWeek = thisWeek + WEEK;
            if (block.timestamp < nextWeek) {
                if (sinceLast == 0 && block.timestamp == t)
                    tokensPerWeek[thisWeek] += toDistribute;
                else
                    tokensPerWeek[thisWeek] +=
                        (toDistribute * (block.timestamp - t)) /
                        sinceLast;
                break;
            } else {
                if (sinceLast == 0 && nextWeek == t)
                    tokensPerWeek[thisWeek] += toDistribute;
                else
                    tokensPerWeek[thisWeek] +=
                        (toDistribute * (nextWeek - t)) /
                        sinceLast;
            }
            t = nextWeek;
            thisWeek = nextWeek;
        }

        emit CheckpointToken(block.timestamp, toDistribute);
    }

    function checkpointToken() external override {
        require(
            msg.sender == owner() ||
                (canCheckpointToken &&
                    (block.timestamp >
                        lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)),
            "not owner or not allowed"
        );
        _checkpointToken();
    }

    function _findTimestampEpoch(uint256 _timestamp)
        internal
        view
        returns (uint256)
    {
        uint256 min = 0;
        uint256 max = locker.epoch();

        for (uint256 index = 0; index < 128; index++) {
            if (min >= max) {
                break;
            }
            uint256 mid = (min + max + 2) / 2;
            INFTLocker.Point memory pt = locker.pointHistory(mid);

            if (pt.ts <= _timestamp) min = mid;
            else max = mid - 1;
        }

        return min;
    }

    function _findTimestampUserEpoch(
        uint256 nftId,
        uint256 _timestamp,
        uint256 maxUserEpoch
    ) internal view returns (uint256) {
        uint256 min = 0;
        uint256 max = maxUserEpoch;

        for (uint256 index = 0; index < 128; index++) {
            if (min >= max) {
                break;
            }
            uint256 mid = (min + max + 2) / 2;
            INFTLocker.Point memory pt = locker.userPointHistory(nftId, mid);

            if (pt.ts <= _timestamp) min = mid;
            else max = mid - 1;
        }

        return min;
    }

    function _checkpointTotalSupply() internal {
        // console.log("_checkpointTotalSupply(...)");
        uint256 t = timeCursor;
        uint256 roundedTimestamp = (block.timestamp / WEEK) * WEEK;

        locker.checkpoint();

        for (uint256 index = 0; index < 20; index++) {
            if (t > roundedTimestamp) break;
            else {
                uint256 epoch = _findTimestampEpoch(t);
                INFTLocker.Point memory pt = locker.pointHistory(epoch);

                int128 dt = 0;

                if (t > pt.ts) dt = int128(uint128(t - pt.ts));
                veSupply[t] = Math.max(uint128(pt.bias - pt.slope * dt), 0);
            }

            t += WEEK;
        }

        timeCursor = t;
    }

    function checkpointTotalSupply() external override {
        _checkpointTotalSupply();
    }

    function _claim(uint256 nftId, uint256 _lastTokenTime)
        internal
        returns (uint256)
    {
        require(locker.isStaked(nftId), "nft not staked");

        // console.log("inside claim");

        uint256 userEpoch = 0;
        uint256 toDistribute = 0;

        uint256 maxUserEpoch = locker.userPointEpoch(nftId);
        uint256 _startTime = startTime;

        // console.log("if maxUserEpoch = 0", maxUserEpoch);
        if (maxUserEpoch == 0) return 0;

        uint256 weekCursor = timeCursorOf[nftId];
        // console.log("weekCursor     =", weekCursor);

        if (weekCursor == 0)
            userEpoch = _findTimestampUserEpoch(
                nftId,
                _startTime,
                maxUserEpoch
            );
        else userEpoch = userEpochOf[nftId];

        if (userEpoch == 0) userEpoch = 1;

        INFTLocker.Point memory userPoint = locker.userPointHistory(
            nftId,
            userEpoch
        );

        // console.log("userEpoch      =", userEpoch);
        // console.log("weekCursor     =", weekCursor);

        if (weekCursor == 0)
            weekCursor = ((userPoint.ts + WEEK - 1) / WEEK) * WEEK;

        // console.log("weekCursor     =", weekCursor);
        // console.log("_lastTokenTime =", _lastTokenTime);
        // console.log("_startTime     =", _startTime);
        // console.log(
        //     "weekCursor >= _lastTokenTime",
        //     weekCursor >= _lastTokenTime
        // );

        if (weekCursor >= _lastTokenTime) return 0;

        if (weekCursor >= _startTime) weekCursor = _startTime;

        INFTLocker.Point memory oldUserPoint = INFTLocker.Point(0, 0, 0, 0);

        for (uint256 index = 0; index < 50; index++) {
            if (weekCursor >= _lastTokenTime) break;

            if (weekCursor >= userPoint.ts && userEpoch <= maxUserEpoch) {
                userEpoch += 1;
                oldUserPoint = userPoint;

                if (userEpoch > maxUserEpoch)
                    userPoint = INFTLocker.Point(0, 0, 0, 0);
                else userPoint = locker.userPointHistory(nftId, userEpoch);
            } else {
                int128 dt = int128(uint128(weekCursor - oldUserPoint.ts));
                uint256 balanceOf = Math.max(
                    uint128(oldUserPoint.bias - dt * oldUserPoint.slope),
                    0
                );

                if (balanceOf == 0 && userEpoch > maxUserEpoch) break;
                if (balanceOf > 0)
                    toDistribute +=
                        (balanceOf * tokensPerWeek[weekCursor]) /
                        veSupply[weekCursor];

                weekCursor += WEEK;
            }
        }

        userEpoch = Math.min(maxUserEpoch, userEpoch - 1);
        userEpochOf[nftId] = userEpoch;
        timeCursorOf[nftId] = weekCursor;

        emit Claimed(nftId, toDistribute, userEpoch, maxUserEpoch);
        return toDistribute;
    }

    function claim(uint256 nftId)
        external
        override
        nonReentrant
        returns (uint256)
    {
        require(!isKilled, "killed");

        if (block.timestamp >= timeCursor) _checkpointTotalSupply();

        uint256 _lastTokenTime = lastTokenTime;

        if (
            canCheckpointToken &&
            (block.timestamp > lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)
        ) {
            _checkpointToken();
            _lastTokenTime = block.timestamp;
        }

        _lastTokenTime = (_lastTokenTime / WEEK) * WEEK;

        uint256 amount = _claim(nftId, _lastTokenTime);
        address who = locker.ownerOf(nftId);

        if (amount != 0) {
            tokenLastBalance -= amount;
            token.transfer(who, amount);
        }

        return amount;
    }

    function claimMany(uint256[] memory nftIds)
        external
        override
        nonReentrant
        returns (bool)
    {
        require(!isKilled, "killed");
        if (block.timestamp >= timeCursor) _checkpointTotalSupply();

        uint256 _lastTokenTime = lastTokenTime;

        if (
            canCheckpointToken &&
            (block.timestamp > lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)
        ) {
            _checkpointToken();
            _lastTokenTime = block.timestamp;
        }

        _lastTokenTime = (_lastTokenTime / WEEK) * WEEK;

        for (uint256 index = 0; index < nftIds.length; index++) {
            uint256 amount = _claim(nftIds[index], _lastTokenTime);
            address who = locker.ownerOf(nftIds[index]);

            if (amount != 0) {
                tokenLastBalance -= amount;
                token.transfer(who, amount);
            }
        }

        return true;
    }

    // @external
    // def burn(_coin: address) -> bool:
    //     """
    //     @notice Receive 3CRV into the contract and trigger a token checkpoint
    //     @param _coin Address of the coin being received (must be 3CRV)
    //     @return bool success
    //     """
    //     assert _coin == self.token
    //     assert not self.isKilled
    //     amount: uint256 = ERC20(_coin).balanceOf(msg.sender)
    //     if amount != 0:
    //         ERC20(_coin).transferFrom(msg.sender, self, amount)
    //         if self.canCheckpointToken and (block.timestamp > self.lastTokenTime + TOKEN_CHECKPOINT_DEADLINE):
    //             self._checkpoint_token()
    //     return True

    function toggleAllowCheckpointToken() external onlyOwner {
        canCheckpointToken = !canCheckpointToken;
        emit ToggleAllowCheckpointToken(canCheckpointToken);
    }

    function killMe() external onlyOwner {
        isKilled = true;
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function recoverBalance(IERC20 _coin) external onlyOwner {
        _coin.transfer(msg.sender, _coin.balanceOf(address(this)));
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
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

pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import {IRegistry} from "./IRegistry.sol";

interface INFTLocker is IERC721 {
    function registry() external view returns (IRegistry);

    function balanceOfNFT(uint256) external view returns (uint256);

    function isStaked(uint256) external view returns (bool);

    function epoch() external view returns (uint256);

    function userPointEpoch(uint256) external view returns (uint256);

    function userPointHistory(uint256, uint256)
        external
        view
        returns (Point memory);

    function pointHistory(uint256) external view returns (Point memory);

    function totalSupplyWithoutDecay() external view returns (uint256);

    function isApprovedOrOwner(address, uint256) external view returns (bool);

    function totalSupply() external view returns (uint256);

    function totalSupplyAt(uint256 _block) external view returns (uint256);

    function merge(uint256 _from, uint256 _to) external;

    function blockNumber() external view returns (uint256);

    function checkpoint() external;

    function depositFor(uint256 _tokenId, uint256 _value) external;

    function createLockFor(
        uint256 _value,
        uint256 _lockDuration,
        address _to,
        bool _stakeNFT
    ) external returns (uint256);

    function migrateTokenFor(
        uint256 _value,
        uint256 _lockDuration,
        address _to
    ) external returns (uint256);

    function createLock(
        uint256 _value,
        uint256 _lockDuration,
        bool _stakeNFT
    ) external returns (uint256);

    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME,
        MERGE_TYPE
    }

    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    /* We cannot really do block numbers per se b/c slope is per time, not per block
     * and per block could be fairly bad b/c Ethereum changes blocktimes.
     * What we can do is to extrapolate ***At functions */

    struct LockedBalance {
        int128 amount;
        uint256 end;
        uint256 start;
    }

    event Deposit(
        address indexed provider,
        uint256 tokenId,
        uint256 value,
        uint256 indexed locktime,
        DepositType deposit_type,
        uint256 ts
    );

    event Withdraw(
        address indexed provider,
        uint256 tokenId,
        uint256 value,
        uint256 ts
    );

    event Supply(uint256 prevSupply, uint256 supply);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFeeDistributor {
    event ToggleAllowCheckpointToken(bool toggleFlag);
    event CheckpointToken(uint256 time, uint256 tokens);
    event Claimed(
        uint256 nftId,
        uint256 amount,
        uint256 claimEpoch,
        uint256 maxEpoch
    );

    function checkpointToken() external;

    function checkpointTotalSupply() external;

    function claim(uint256 nftId) external returns (uint256);

    function claimMany(uint256[] memory nftIds) external returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Receiver.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

interface IRegistry is IAccessControl {
    event MahaChanged(address indexed whom, address _old, address _new);
    event VoterChanged(address indexed whom, address _old, address _new);
    event LockerChanged(address indexed whom, address _old, address _new);
    event GovernorChanged(address indexed whom, address _old, address _new);
    event StakerChanged(address indexed whom, address _old, address _new);
    event EmissionControllerChanged(
        address indexed whom,
        address _old,
        address _new
    );

    function maha() external view returns (address);

    function gaugeVoter() external view returns (address);

    function locker() external view returns (address);

    function staker() external view returns (address);

    function emissionController() external view returns (address);

    function governor() external view returns (address);

    function getAllAddresses()
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address
        );

    function ensureNotPaused() external;

    function setMAHA(address _new) external;

    function setEmissionController(address _new) external;

    function setStaker(address _new) external;

    function setVoter(address _new) external;

    function setLocker(address _new) external;

    function setGovernor(address _new) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}