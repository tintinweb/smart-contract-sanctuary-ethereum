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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableALCA.sol";
import "contracts/utils/auth/ImmutablePublicStaking.sol";
import "contracts/utils/auth/ImmutableFoundation.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/utils/ERC20SafeTransfer.sol";
import "contracts/utils/MagicEthTransfer.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/libraries/errors/LockupErrors.sol";
import "contracts/libraries/lockup/AccessControlled.sol";
import "contracts/RewardPool.sol";
import "contracts/Lockup.sol";

/**
 * @notice This contract holds all ALCA that is held in escrow for lockup
 * bonuses. All ALCA is hold into a single staked position that is owned
 * locally.
 * @dev deployed by the RewardPool contract
 */
contract BonusPool is
    ImmutableALCA,
    ImmutablePublicStaking,
    ImmutableFoundation,
    ERC20SafeTransfer,
    EthSafeTransfer,
    ERC721Holder,
    AccessControlled,
    MagicEthTransfer
{
    uint256 internal immutable _totalBonusAmount;
    address internal immutable _lockupContract;
    address internal immutable _rewardPool;
    // tokenID of the position created to hold the amount that will be redistributed as bonus
    uint256 internal _tokenID;

    event BonusPositionCreated(uint256 tokenID);

    constructor(
        address aliceNetFactory_,
        address lockupContract_,
        address rewardPool_,
        uint256 totalBonusAmount_
    )
        ImmutableFactory(aliceNetFactory_)
        ImmutableALCA()
        ImmutablePublicStaking()
        ImmutableFoundation()
    {
        _totalBonusAmount = totalBonusAmount_;
        _lockupContract = lockupContract_;
        _rewardPool = rewardPool_;
    }

    receive() external payable {
        if (msg.sender != _publicStakingAddress()) {
            revert LockupErrors.AddressNotAllowedToSendEther();
        }
    }

    /// @notice function that creates/mint a publicStaking position with an amount that will be
    /// redistributed as bonus at the end of the lockup period. The amount of ALCA has to be
    /// transferred before calling this function.
    /// @dev can be only called by the AliceNet factory
    function createBonusStakedPosition() public onlyFactory {
        if (_tokenID != 0) {
            revert LockupErrors.BonusTokenAlreadyCreated();
        }
        IERC20 alca = IERC20(_alcaAddress());
        //get the total balance of ALCA owned by bonus pool as stake amount
        uint256 _stakeAmount = alca.balanceOf(address(this));
        if (_stakeAmount < _totalBonusAmount) {
            revert LockupErrors.NotEnoughALCAToStake(_stakeAmount, _totalBonusAmount);
        }
        // approve the staking contract to transfer the ALCA
        alca.approve(_publicStakingAddress(), _totalBonusAmount);
        uint256 tokenID = IStakingNFT(_publicStakingAddress()).mint(_totalBonusAmount);
        _tokenID = tokenID;
        emit BonusPositionCreated(_tokenID);
    }

    /// @notice Burns that bonus staked position, and send the bonus amount of shares + profits to
    /// the rewardPool contract, so users can collect.
    function terminate() public onlyLockup {
        if (_tokenID == 0) {
            revert LockupErrors.BonusTokenNotCreated();
        }
        // burn the nft to collect all profits.
        IStakingNFT(_publicStakingAddress()).burn(_tokenID);
        // restarting the _tokenID
        _tokenID = 0;
        // send the total balance of ALCA to the rewardPool contract
        uint256 alcaBalance = IERC20(_alcaAddress()).balanceOf(address(this));
        _safeTransferERC20(
            IERC20Transferable(_alcaAddress()),
            _getRewardPoolAddress(),
            alcaBalance
        );
        // send also all the balance of ether
        uint256 ethBalance = address(this).balance;
        RewardPool(_getRewardPoolAddress()).deposit{value: ethBalance}(alcaBalance);
    }

    /// @notice gets the lockup contract address
    /// @return the lockup contract address
    function getLockupContractAddress() public view returns (address) {
        return _getLockupContractAddress();
    }

    /// @notice gets the rewardPool contract address
    /// @return the rewardPool contract address
    function getRewardPoolAddress() public view returns (address) {
        return _getRewardPoolAddress();
    }

    /// @notice gets the tokenID of the publicStaking position that has the whole bonus amount
    /// @return the tokenID of the publicStaking position that has the whole bonus amount
    function getBonusStakedPosition() public view returns (uint256) {
        return _tokenID;
    }

    /// @notice gets the total amount of ALCA that was staked initially in the publicStaking position
    /// @return the total amount of ALCA that was staked initially in the publicStaking position
    function getTotalBonusAmount() public view returns (uint256) {
        return _totalBonusAmount;
    }

    /// @notice estimates a user's bonus amount + bonus position profits.
    /// @param currentSharesLocked_ The current number of shares locked in the lockup contract
    /// @param userShares_ The amount of shares that a user locked-up.
    /// @return bonusRewardEth the estimated amount ether profits for a user
    /// @return bonusRewardToken the estimated amount ALCA profits for a user
    function estimateBonusAmountWithReward(
        uint256 currentSharesLocked_,
        uint256 userShares_
    ) public view returns (uint256 bonusRewardEth, uint256 bonusRewardToken) {
        if (_tokenID == 0) {
            return (0, 0);
        }

        (uint256 estimatedPayoutEth, uint256 estimatedPayoutToken) = IStakingNFT(
            _publicStakingAddress()
        ).estimateAllProfits(_tokenID);

        (uint256 shares, , , , ) = IStakingNFT(_publicStakingAddress()).getPosition(_tokenID);
        estimatedPayoutToken += shares;

        // compute what will be the amount that a user will receive from the amount that will be
        // sent to the reward contract.
        bonusRewardEth = (estimatedPayoutEth * userShares_) / currentSharesLocked_;
        bonusRewardToken = (estimatedPayoutToken * userShares_) / currentSharesLocked_;
    }

    function _getLockupContractAddress() internal view override returns (address) {
        return _lockupContract;
    }

    function _getBonusPoolAddress() internal view override returns (address) {
        return address(this);
    }

    function _getRewardPoolAddress() internal view override returns (address) {
        return _rewardPool;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IAliceNetFactory {
    function lookup(bytes32 salt_) external view returns (address);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IERC20Transferable {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IERC721Transferable {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IMagicEthTransfer {
    function depositEth(uint8 magic_) external payable;
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IStakingNFT {
    function skimExcessEth(address to_) external returns (uint256 excess);

    function skimExcessToken(address to_) external returns (uint256 excess);

    function depositToken(uint8 magic_, uint256 amount_) external;

    function depositEth(uint8 magic_) external payable;

    function lockPosition(
        address caller_,
        uint256 tokenID_,
        uint256 lockDuration_
    ) external returns (uint256);

    function lockOwnPosition(uint256 tokenID_, uint256 lockDuration_) external returns (uint256);

    function lockWithdraw(uint256 tokenID_, uint256 lockDuration_) external returns (uint256);

    function mint(uint256 amount_) external returns (uint256 tokenID);

    function mintTo(
        address to_,
        uint256 amount_,
        uint256 lockDuration_
    ) external returns (uint256 tokenID);

    function burn(uint256 tokenID_) external returns (uint256 payoutEth, uint256 payoutALCA);

    function burnTo(
        address to_,
        uint256 tokenID_
    ) external returns (uint256 payoutEth, uint256 payoutALCA);

    function collectEth(uint256 tokenID_) external returns (uint256 payout);

    function collectToken(uint256 tokenID_) external returns (uint256 payout);

    function collectAllProfits(
        uint256 tokenID_
    ) external returns (uint256 payoutToken, uint256 payoutEth);

    function collectEthTo(address to_, uint256 tokenID_) external returns (uint256 payout);

    function collectTokenTo(address to_, uint256 tokenID_) external returns (uint256 payout);

    function collectAllProfitsTo(
        address to_,
        uint256 tokenID_
    ) external returns (uint256 payoutToken, uint256 payoutEth);

    function getPosition(
        uint256 tokenID_
    )
        external
        view
        returns (
            uint256 shares,
            uint256 freeAfter,
            uint256 withdrawFreeAfter,
            uint256 accumulatorEth,
            uint256 accumulatorToken
        );

    function getTotalShares() external view returns (uint256);

    function getTotalReserveEth() external view returns (uint256);

    function getTotalReserveALCA() external view returns (uint256);

    function estimateEthCollection(uint256 tokenID_) external view returns (uint256 payout);

    function estimateTokenCollection(uint256 tokenID_) external view returns (uint256 payout);

    function estimateAllProfits(
        uint256 tokenID_
    ) external view returns (uint256 payoutEth, uint256 payoutToken);

    function estimateExcessToken() external view returns (uint256 excess);

    function estimateExcessEth() external view returns (uint256 excess);

    function getEthAccumulator() external view returns (uint256 accumulator, uint256 slush);

    function getTokenAccumulator() external view returns (uint256 accumulator, uint256 slush);

    function getLatestMintedPositionID() external view returns (uint256);

    function getAccumulatorScaleFactor() external pure returns (uint256);

    function getMaxMintLock() external pure returns (uint256);

    function getMaxGovernanceLock() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IStakingToken {
    function migrate(uint256 amount) external returns (uint256);

    function migrateTo(address to, uint256 amount) external returns (uint256);

    function finishEarlyStage() external;

    function externalMint(address to, uint256 amount) external;

    function externalBurn(address from, uint256 amount) external;

    function getLegacyTokenAddress() external view returns (address);

    function convert(uint256 amount) external view returns (uint256);
}

interface IStakingTokenMinter {
    function mint(address to, uint256 amount) external;
}

interface IStakingTokenBurner {
    function burn(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library ERC20SafeTransferErrors {
    error CannotCallContractMethodsOnZeroAddress();
    error Erc20TransferFailed(address erc20Address, address from, address to, uint256 amount);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library ETHSafeTransferErrors {
    error CannotTransferToZeroAddress();
    error EthTransferFailed(address from, address to, uint256 amount);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library LockupErrors {
    error AddressNotAllowedToSendEther();
    error OnlyStakingNFTAllowed();
    error ContractDoesNotOwnTokenID(uint256 tokenID_);
    error AddressAlreadyLockedUp();
    error TokenIDAlreadyClaimed(uint256 tokenID_);
    error InsufficientBalanceForEarlyExit(uint256 exitValue, uint256 currentBalance);
    error UserHasNoPosition();
    error PreLockStateRequired();
    error PreLockStateNotAllowed();
    error PostLockStateNotAllowed();
    error PostLockStateRequired();
    error PayoutUnsafe();
    error PayoutSafe();
    error TokenIDNotLocked(uint256 tokenID_);
    error InvalidPositionWithdrawPeriod(uint256 withdrawFreeAfter, uint256 endBlock);
    error InLockStateRequired();

    error BonusTokenNotCreated();
    error BonusTokenAlreadyCreated();
    error NotEnoughALCAToStake(uint256 currentBalance, uint256 expectedAmount);

    error InvalidTotalSharesValue();
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library MagicValueErrors {
    error BadMagic(uint256 magic);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract AccessControlled {
    error CallerNotLockup();
    error CallerNotLockupOrBonus();

    modifier onlyLockup() {
        if (msg.sender != _getLockupContractAddress()) {
            revert CallerNotLockup();
        }
        _;
    }

    modifier onlyLockupOrBonus() {
        // must protect increment of token balance
        if (
            msg.sender != _getLockupContractAddress() &&
            msg.sender != address(_getBonusPoolAddress())
        ) {
            revert CallerNotLockupOrBonus();
        }
        _;
    }

    function _getLockupContractAddress() internal view virtual returns (address);

    function _getBonusPoolAddress() internal view virtual returns (address);

    function _getRewardPoolAddress() internal view virtual returns (address);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/interfaces/IERC721Transferable.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/libraries/errors/LockupErrors.sol";
import "contracts/libraries/lockup/AccessControlled.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutablePublicStaking.sol";
import "contracts/utils/auth/ImmutableALCA.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/utils/ERC20SafeTransfer.sol";
import "contracts/BonusPool.sol";
import "contracts/RewardPool.sol";

/**
 * @notice This contract locks up publicStaking position for a certain period. The position is
 *  transferred to this contract, and the original owner is entitled to collect profits, and unlock
 *  the position. If the position was kept locked until the end of the locking period, the original
 *  owner will be able to get the original position back, plus any profits gained by the position
 *  (e.g from ALCB sale) + a bonus amount based on the amount of shares of the public staking
 *  position.
 *
 *  Original owner will be able to collect profits from the position normally during the locking
 *  period. However, a certain percentage will be held by the contract and only distributed after the
 *  locking period has finished and the user unlocks.
 *
 *  Original owner will be able to unlock position (partially or fully) before the locking period has
 *  finished. The owner will able to decide which will be the amount unlocked earlier (called
 *  exitAmount). In case of full exit (exitAmount == positionShares), the owner will not get the
 *  percentage of profits of that position that are held by this contract and he will not receive any
 *  bonus amount. In case, of partial exit (exitAmount < positionShares), the owner will be loosing
 *  only the profits + bonus relative to the exiting amount.
 *
 *
 * @dev deployed by the AliceNetFactory contract
 */

/// @custom:salt Lockup
/// @custom:deploy-type deployCreateAndRegister
/// @custom:deploy-group lockup
/// @custom:deploy-group-index 0
contract Lockup is
    ImmutablePublicStaking,
    ImmutableALCA,
    ERC20SafeTransfer,
    EthSafeTransfer,
    ERC721Holder
{
    enum State {
        PreLock,
        InLock,
        PostLock
    }

    uint256 public constant SCALING_FACTOR = 10 ** 18;
    uint256 public constant FRACTION_RESERVED = SCALING_FACTOR / 5;
    // rewardPool contract address
    address internal immutable _rewardPool;
    // bonusPool contract address
    address internal immutable _bonusPool;
    // block on which lock starts
    uint256 internal immutable _startBlock;
    // block on which lock ends
    uint256 internal immutable _endBlock;
    // Total Locked describes the total number of ALCA locked in this contract.
    // Since no accumulators are used this is tracked to allow proportionate
    // payouts.
    uint256 internal _totalSharesLocked;
    // _ownerOf tracks who is the owner of a tokenID locked in this contract
    // mapping(tokenID -> owner).
    mapping(uint256 => address) internal _ownerOf;
    // _tokenOf is the inverse of ownerOf and returns the owner given the tokenID
    // users are only allowed 1 position per account, mapping (owner -> tokenID).
    mapping(address => uint256) internal _tokenOf;

    // maps and index to a tokenID for iterable counting i.e (index ->  tokenID).
    // Stop iterating when token id is zero. Must use tail insert to delete or else
    // pagination will end early.
    mapping(uint256 => uint256) internal _tokenIDs;
    // lookup index by ID (tokenID -> index).
    mapping(uint256 => uint256) internal _reverseTokenIDs;
    // tracks the number of tokenIDs this contract holds.
    uint256 internal _lenTokenIDs;

    // support mapping to keep track all the ethereum owed to user to be
    // redistributed in the postLock phase during safe mode.
    mapping(address => uint256) internal _rewardEth;
    // support mapping to keep track all the token owed to user to be
    // redistributed in the postLock phase during safe mode.
    mapping(address => uint256) internal _rewardTokens;
    // Flag to determine if we are in the postLock phase safe or unsafe, i.e if
    // users are allowed to withdrawal or not. All profits need to be collect by all
    // positions before setting the safe mode.
    bool public payoutSafe;

    // offset for pagination when collecting the profits in the postLock unsafe
    // phase. Many people may call aggregateProfits until all rewards has been
    // collected.
    uint256 internal _tokenIDOffset;

    event EarlyExit(address to_, uint256 tokenID_);
    event NewLockup(address from_, uint256 tokenID_);

    modifier onlyPreLock() {
        if (_getState() != State.PreLock) {
            revert LockupErrors.PreLockStateRequired();
        }
        _;
    }

    modifier excludePreLock() {
        if (_getState() == State.PreLock) {
            revert LockupErrors.PreLockStateNotAllowed();
        }
        _;
    }

    modifier onlyPostLock() {
        if (_getState() != State.PostLock) {
            revert LockupErrors.PostLockStateRequired();
        }
        _;
    }

    modifier excludePostLock() {
        if (_getState() == State.PostLock) {
            revert LockupErrors.PostLockStateNotAllowed();
        }
        _;
    }

    modifier onlyPayoutSafe() {
        if (!payoutSafe) {
            revert LockupErrors.PayoutUnsafe();
        }
        _;
    }

    modifier onlyPayoutUnSafe() {
        if (payoutSafe) {
            revert LockupErrors.PayoutSafe();
        }
        _;
    }

    modifier onlyInLock() {
        if (_getState() != State.InLock) {
            revert LockupErrors.InLockStateRequired();
        }
        _;
    }

    constructor(
        uint256 enrollmentPeriod_,
        uint256 lockDuration_,
        uint256 totalBonusAmount_
    ) ImmutableFactory(msg.sender) ImmutablePublicStaking() ImmutableALCA() {
        RewardPool rewardPool = new RewardPool(
            _alcaAddress(),
            _factoryAddress(),
            totalBonusAmount_
        );
        _rewardPool = address(rewardPool);
        _bonusPool = rewardPool.getBonusPoolAddress();
        _startBlock = block.number + enrollmentPeriod_;
        _endBlock = _startBlock + lockDuration_;
    }

    /// @dev only publicStaking and rewardPool are allowed to send ether to this contract
    receive() external payable {
        if (msg.sender != _publicStakingAddress() && msg.sender != _rewardPool) {
            revert LockupErrors.AddressNotAllowedToSendEther();
        }
    }

    /// @notice callback function called by the ERC721.safeTransfer. On safe transfer of
    /// publicStaking positions to this contract, it will be performing checks and in case everything
    /// is fine, that position will be locked in name of the original owner that performed the
    /// transfer
    /// @dev publicStaking positions can only be safe transferred to this contract on PreLock phase
    /// (enrollment phase)
    /// @param from_ original owner of the publicStaking Position. The position will locked for this
    /// address
    /// @param tokenID_ The publicStaking tokenID that will be locked up
    function onERC721Received(
        address,
        address from_,
        uint256 tokenID_,
        bytes memory
    ) public override onlyPreLock returns (bytes4) {
        if (msg.sender != _publicStakingAddress()) {
            revert LockupErrors.OnlyStakingNFTAllowed();
        }

        _lockFromTransfer(tokenID_, from_);
        return this.onERC721Received.selector;
    }

    /// @notice transfer and locks a pre-approved publicStaking position to this contract
    /// @dev can only be called at PreLock phase (enrollment phase)
    /// @param tokenID_ The publicStaking tokenID that will be locked up
    function lockFromApproval(uint256 tokenID_) public {
        // msg.sender already approved transfer, so contract can safeTransfer to itself; by doing
        // this onERC721Received is called as part of the chain of transfer methods hence the checks
        // run from within onERC721Received
        IERC721Transferable(_publicStakingAddress()).safeTransferFrom(
            msg.sender,
            address(this),
            tokenID_
        );
    }

    /// @notice locks a position that was already transferred to this contract without using
    /// safeTransfer. WARNING: SHOULD ONLY BE USED FROM SMART CONTRACT THAT TRANSFERS A POSITION AND
    /// CALL THIS METHOD RIGHT IN SEQUENCE
    /// @dev can only be called at PreLock phase (enrollment phase)
    /// @param tokenID_ The publicStaking tokenID that will be locked up
    /// @param tokenOwner_ The address that will be used as the user entitled to that position
    function lockFromTransfer(uint256 tokenID_, address tokenOwner_) public onlyPreLock {
        _lockFromTransfer(tokenID_, tokenOwner_);
    }

    /// @notice collects all profits from a position locked up by this contract. Only a certain
    /// amount of the profits will be sent, the rest will held by the contract and released at the
    /// final unlock.
    /// @dev can only be called if the PostLock phase has not began
    /// @dev can only be called by position's entitled owner
    /// @return payoutEth the amount of eth that was sent to user
    /// @return payoutToken the amount of ALCA that was sent to user
    function collectAllProfits()
        public
        excludePostLock
        returns (uint256 payoutEth, uint256 payoutToken)
    {
        return _collectAllProfits(_payableSender(), _validateAndGetTokenId());
    }

    /// @notice function to partially or fully unlock a locked position. The entitled owner will
    /// able to decide which will be the amount unlocked earlier (exitValue_). In case of full exit
    /// (exitValue_ == positionShares), the owner will not get the percentage of profits of that
    /// position that are held by this contract and he will not receive any bonus amount. In case, of
    /// partial exit (exitValue_< positionShares), the owner will be loosing only the profits + bonus
    /// relative to the exiting amount. The owner may choose via stakeExit_ boolean if the ALCA will be
    /// sent a new publicStaking position or as ALCA directly to his address.
    /// @dev can only be called if the PostLock phase has not began
    /// @dev can only be called by position's entitled owner
    /// @param exitValue_ The amount in which the user wants to unlock earlier
    /// @param stakeExit_ Flag to decide the ALCA will be sent directly or staked as new
    /// publicStaking position
    /// @return payoutEth the amount of eth that was sent to user discounting the reserved amount
    /// @return payoutToken the amount of ALCA discounting the reserved amount that was sent or
    /// staked as new position to the user
    function unlockEarly(
        uint256 exitValue_,
        bool stakeExit_
    ) public excludePostLock returns (uint256 payoutEth, uint256 payoutToken) {
        uint256 tokenID = _validateAndGetTokenId();
        // get the number of shares and check validity
        uint256 shares = _getNumShares(tokenID);
        if (exitValue_ > shares) {
            revert LockupErrors.InsufficientBalanceForEarlyExit(exitValue_, shares);
        }
        // burn the existing position
        (payoutEth, payoutToken) = IStakingNFT(_publicStakingAddress()).burn(tokenID);
        // separating alca reward from alca shares
        payoutToken -= shares;
        // blank old record
        _ownerOf[tokenID] = address(0);
        // create placeholder
        uint256 newTokenID;
        // find shares delta and mint new position
        uint256 remainingShares = shares - exitValue_;
        if (remainingShares > 0) {
            // approve the transfer of ALCA in order to mint the publicStaking position
            IERC20(_alcaAddress()).approve(_publicStakingAddress(), remainingShares);
            // burn profits contain staked position... so sub it out
            newTokenID = IStakingNFT(_publicStakingAddress()).mint(remainingShares);
            // set new records
            _ownerOf[newTokenID] = msg.sender;
            _replaceTokenID(tokenID, newTokenID);
        } else {
            _removeTokenID(tokenID);
        }
        // safe because newTokenId is zero if shares == exitValue
        _tokenOf[msg.sender] = newTokenID;
        _totalSharesLocked -= exitValue_;
        (payoutEth, payoutToken) = _distributeAllProfits(
            _payableSender(),
            payoutEth,
            payoutToken,
            exitValue_,
            stakeExit_
        );
        emit EarlyExit(msg.sender, tokenID);
    }

    /// @notice aggregateProfits iterate alls locked positions and collect their profits before
    /// allowing withdraws/unlocks. This step is necessary to make sure that the correct reserved
    /// amount is in the rewardPool before allowing unlocks. This function will not send any ether or
    /// ALCA to users, since this can be very dangerous (specially on a loop). Instead all the
    /// assets that are not sent to the rewardPool are held in the lockup contract, and the right
    /// balance is stored per position owner. All the value will be send to the owner address at the
    /// call of the `{unlock()}` function. This function can only be called after the locking period
    /// has finished. Anyone can call this function.
    function aggregateProfits() public onlyPayoutUnSafe onlyPostLock {
        // get some gas cost tracking setup
        uint256 gasStart = gasleft();
        uint256 gasLoop;
        // start index where we left off plus one
        uint256 i = _tokenIDOffset + 1;
        // for loop that will exit when one of following is true the gas remaining is less than 5x
        // the estimated per iteration cost or the iterator is done
        for (; ; i++) {
            (uint256 tokenID, bool ok) = _getTokenIDAtIndex(i);
            if (!ok) {
                // if we get here, iteration of array is done and we can move on with life and set
                // payoutSafe since all payouts have been recorded
                payoutSafe = true;
                // burn the bonus Position and send the bonus to the rewardPool contract
                BonusPool(payable(_bonusPool)).terminate();
                break;
            }
            address payable acct = _getOwnerOf(tokenID);
            _collectAllProfits(acct, tokenID);
            uint256 gasRem = gasleft();
            if (gasLoop == 0) {
                // record gas iteration estimate if not done
                gasLoop = gasStart - gasRem;
                // give 5x multi on it to ensure even an overpriced element by 2x the normal
                // cost will still pass
                gasLoop = 5 * gasLoop;
                // accounts for state writes on exit
                gasLoop = gasLoop + 10000;
            } else if (gasRem <= gasLoop) {
                // if we are below cutoff break
                break;
            }
        }
        _tokenIDOffset = i;
    }

    /// @notice unlocks a locked position and collect all kind of profits (bonus shares, held
    /// rewards etc). Can only be called after the locking period has finished and {aggregateProfits}
    /// has been executed for positions. Can only be called by the user entitled to a position
    /// (address that locked a position). This function can only be called after the locking period
    /// has finished and {aggregateProfits()} has been executed for all locked positions.
    /// @param to_ destination address were the profits, shares will be sent
    /// @param stakeExit_ boolean flag indicating if the ALCA should be returned directly or staked
    /// into a new publicStaking position.
    /// @return payoutEth the ether amount deposited to an address after unlock
    /// @return payoutToken the ALCA amount staked or sent to an address after unlock
    function unlock(
        address to_,
        bool stakeExit_
    ) public onlyPostLock onlyPayoutSafe returns (uint256 payoutEth, uint256 payoutToken) {
        uint256 tokenID = _validateAndGetTokenId();
        uint256 shares = _getNumShares(tokenID);
        bool isLastPosition = _lenTokenIDs == 1;

        (payoutEth, payoutToken) = _burnLockedPosition(tokenID, msg.sender);

        (uint256 accumulatedRewardEth, uint256 accumulatedRewardToken) = RewardPool(_rewardPool)
            .payout(_totalSharesLocked, shares, isLastPosition);
        payoutEth += accumulatedRewardEth;
        payoutToken += accumulatedRewardToken;

        (uint256 aggregatedEth, uint256 aggregatedToken) = _withdrawalAggregatedAmount(msg.sender);
        payoutEth += aggregatedEth;
        payoutToken += aggregatedToken;
        _transferEthAndTokensWithReStake(to_, payoutEth, payoutToken, stakeExit_);
    }

    /// @notice gets the address that is entitled to unlock/collect profits for a position. I.e the
    /// address that locked this position into this contract.
    /// @param tokenID_ the position Id to retrieve the owner
    /// @return the owner address of a position. Returns 0 if a position is not locked into this
    /// contract
    function ownerOf(uint256 tokenID_) public view returns (address payable) {
        return _getOwnerOf(tokenID_);
    }

    /// @notice gets the positionID that an address is entitled to unlock/collect profits. I.e
    /// position that an address locked into this contract.
    /// @param acct_ address to retrieve a position (tokenID)
    /// @return the position ID (tokenID) of the position that the address locked into this
    /// contract. If an address doesn't possess any locked position in this contract, this function
    /// returns 0
    function tokenOf(address acct_) public view returns (uint256) {
        return _getTokenOf(acct_);
    }

    /// @notice gets the total number of positions locked into this contract. Can be used with
    /// {getIndexByTokenId} and {getPositionByIndex} to get all publicStaking positions held by this
    /// contract.
    /// @return the total number of positions locked into this contract
    function getCurrentNumberOfLockedPositions() public view returns (uint256) {
        return _lenTokenIDs;
    }

    /// @notice gets the position referenced by an index in the enumerable mapping implemented by
    /// this contract. Can be used {getIndexByTokenId} to get all positions IDs locked by this
    /// contract.
    /// @param index_ the index to get the positionID
    /// @return the tokenId referenced by an index the enumerable mapping (indexes start at 1). If
    /// the index doesn't exists this function returns 0
    function getPositionByIndex(uint256 index_) public view returns (uint256) {
        return _tokenIDs[index_];
    }

    /// @notice gets the index of a position in the enumerable mapping implemented by this contract.
    /// Can be used {getPositionByIndex} to get all positions IDs locked by this contract.
    /// @param tokenID_ the position ID to get index for
    /// @return the index of a position in the enumerable mapping (indexes start at 1). If the
    /// tokenID is not locked into this contract this function returns 0
    function getIndexByTokenId(uint256 tokenID_) public view returns (uint256) {
        return _reverseTokenIDs[tokenID_];
    }

    /// @notice gets the ethereum block where the locking period will start. This block is also
    /// when the enrollment period will finish. I.e after this block we don't allow new positions to
    /// be locked.
    /// @return the ethereum block where the locking period will start
    function getLockupStartBlock() public view returns (uint256) {
        return _startBlock;
    }

    /// @notice gets the ethereum block where the locking period will end. After this block
    /// aggregateProfit has to be called to enable the unlock period.
    /// @return the ethereum block where the locking period will end
    function getLockupEndBlock() public view returns (uint256) {
        return _endBlock;
    }

    /// @notice gets the ether and ALCA balance owed to a user after aggregateProfit has been
    /// called. This funds are send after final unlock.
    /// @return user ether balance held by this contract
    /// @return user ALCA balance held by this contract
    function getTemporaryRewardBalance(address user_) public view returns (uint256, uint256) {
        return _getTemporaryRewardBalance(user_);
    }

    /// @notice gets the RewardPool contract address
    /// @return the reward pool contract address
    function getRewardPoolAddress() public view returns (address) {
        return _rewardPool;
    }

    /// @notice gets the bonusPool contract address
    /// @return the bonusPool contract address
    function getBonusPoolAddress() public view returns (address) {
        return _bonusPool;
    }

    /// @notice gets the current amount of ALCA that is locked in this contract, after all early exits
    /// @return the amount of ALCA that is currently locked in this contract
    function getTotalSharesLocked() public view returns (uint256) {
        return _totalSharesLocked;
    }

    /// @notice gets the current state of the lockup (preLock, InLock, PostLock)
    /// @return the current state of the lockup contract
    function getState() public view returns (State) {
        return _getState();
    }

    /// @notice estimate the (liquid) income that can be collected from locked positions via
    /// {collectAllProfits}
    /// @dev this functions deducts the reserved amount that is sent to rewardPool contract
    function estimateProfits(
        uint256 tokenID_
    ) public view returns (uint256 payoutEth, uint256 payoutToken) {
        // check if the position owned by this contract
        _verifyLockedPosition(tokenID_);
        (payoutEth, payoutToken) = IStakingNFT(_publicStakingAddress()).estimateAllProfits(
            tokenID_
        );
        (uint256 reserveEth, uint256 reserveToken) = _computeReservedAmount(payoutEth, payoutToken);
        payoutEth -= reserveEth;
        payoutToken -= reserveToken;
    }

    /// @notice function to estimate the final amount of ALCA and ether that a locked
    /// position will receive at the end of the locking period. Depending on the preciseEstimation_ flag this function can be an imprecise approximation,
    /// the real amount can differ especially as user's collect profits in the middle of the locking
    /// period. Passing preciseEstimation_ as true will give a precise estimate since all profits are aggregated in a loop,
    /// hence is optional as it can be expensive if called as part of a smart contract transaction that alters state. After the locking
    /// period has finished and aggregateProfits has been executed for all locked positions the estimate will also be accurate.
    /// @dev this function is just an approximation when preciseEstimation_ is false, the real amount can differ!
    /// @param tokenID_ The token to check for the final profits.
    /// @param preciseEstimation_ whether to use the precise estimation or the approximation (precise is expensive due to looping so use wisely)
    /// @return positionShares_ the positions ALCA shares
    /// @return payoutEth_ the ether amount that the position will receive as profit
    /// @return payoutToken_ the ALCA amount that the position will receive as profit
    function estimateFinalBonusWithProfits(
        uint256 tokenID_,
        bool preciseEstimation_
    ) public view returns (uint256 positionShares_, uint256 payoutEth_, uint256 payoutToken_) {
        // check if the position owned by this contract
        _verifyLockedPosition(tokenID_);
        positionShares_ = _getNumShares(tokenID_);

        uint256 currentSharesLocked = _totalSharesLocked;

        // get the bonus amount + any profit from the bonus staked position
        (payoutEth_, payoutToken_) = BonusPool(payable(_bonusPool)).estimateBonusAmountWithReward(
            currentSharesLocked,
            positionShares_
        );

        //  get the cumulative rewards held in the rewardPool so far. In the case that
        // aggregateProfits has not been ran, the amount returned by this call may not be precise,
        // since only some users may have been collected until this point, in which case
        // preciseEstimation_ can be passed as true to get a precise estimate.
        (uint256 rewardEthProfit, uint256 rewardTokenProfit) = RewardPool(_rewardPool)
            .estimateRewards(currentSharesLocked, positionShares_);
        payoutEth_ += rewardEthProfit;
        payoutToken_ += rewardTokenProfit;

        uint256 reservedEth;
        uint256 reservedToken;

        // if aggregateProfits has been called (indicated by the payoutSafe flag), this calculation is not needed
        if (preciseEstimation_ && !payoutSafe) {
            // get this positions share based on all user profits aggregated (NOTE: precise but expensive due to the loop)
            (reservedEth, reservedToken) = _estimateUserAggregatedProfits(
                positionShares_,
                currentSharesLocked
            );
        } else {
            // get any future profit that will be held in the rewardPool for this position
            (uint256 positionEthProfit, uint256 positionTokenProfit) = IStakingNFT(
                _publicStakingAddress()
            ).estimateAllProfits(tokenID_);
            (reservedEth, reservedToken) = _computeReservedAmount(
                positionEthProfit,
                positionTokenProfit
            );
        }

        payoutEth_ += reservedEth;
        payoutToken_ += reservedToken;

        // get any eth and token held by this contract as result of the call to the aggregateProfit
        // function
        (uint256 aggregatedEth, uint256 aggregatedTokens) = _getTemporaryRewardBalance(
            _getOwnerOf(tokenID_)
        );
        payoutEth_ += aggregatedEth;
        payoutToken_ += aggregatedTokens;
    }

    /// @notice return the percentage amount that is held from the locked positions
    /// @dev this value is scaled by 100. Therefore the values are from 0-100%
    /// @return the percentage amount that is held from the locked positions
    function getReservedPercentage() public pure returns (uint256) {
        return (100 * FRACTION_RESERVED) / SCALING_FACTOR;
    }

    /// @notice gets the fraction of the amount that is reserved to reward pool
    /// @return the calculated reserved amount
    function getReservedAmount(uint256 amount_) public pure returns (uint256) {
        return (amount_ * FRACTION_RESERVED) / SCALING_FACTOR;
    }

    function _lockFromTransfer(uint256 tokenID_, address tokenOwner_) internal {
        _validateEntry(tokenID_, tokenOwner_);
        _checkTokenTransfer(tokenID_);
        _lock(tokenID_, tokenOwner_);
    }

    function _lock(uint256 tokenID_, address tokenOwner_) internal {
        uint256 shares = _verifyPositionAndGetShares(tokenID_);
        _totalSharesLocked += shares;
        _tokenOf[tokenOwner_] = tokenID_;
        _ownerOf[tokenID_] = tokenOwner_;
        _newTokenID(tokenID_);
        emit NewLockup(tokenOwner_, tokenID_);
    }

    function _burnLockedPosition(
        uint256 tokenID_,
        address tokenOwner_
    ) internal returns (uint256 payoutEth, uint256 payoutToken) {
        // burn the old position
        (payoutEth, payoutToken) = IStakingNFT(_publicStakingAddress()).burn(tokenID_);
        //delete tokenID_ from iterable tokenID mapping
        _removeTokenID(tokenID_);
        delete (_tokenOf[tokenOwner_]);
        delete (_ownerOf[tokenID_]);
    }

    function _withdrawalAggregatedAmount(
        address account_
    ) internal returns (uint256 payoutEth, uint256 payoutToken) {
        // case of we are sending out final pay based on request just pay all
        payoutEth = _rewardEth[account_];
        payoutToken = _rewardTokens[account_];
        _rewardEth[account_] = 0;
        _rewardTokens[account_] = 0;
    }

    function _collectAllProfits(
        address payable acct_,
        uint256 tokenID_
    ) internal returns (uint256 payoutEth, uint256 payoutToken) {
        (payoutEth, payoutToken) = IStakingNFT(_publicStakingAddress()).collectAllProfits(tokenID_);
        return _distributeAllProfits(acct_, payoutEth, payoutToken, 0, false);
    }

    function _distributeAllProfits(
        address payable acct_,
        uint256 payoutEth_,
        uint256 payoutToken_,
        uint256 additionalTokens,
        bool stakeExit_
    ) internal returns (uint256 userPayoutEth, uint256 userPayoutToken) {
        State state = _getState();
        bool localPayoutSafe = payoutSafe;
        userPayoutEth = payoutEth_;
        userPayoutToken = payoutToken_;
        (uint256 reservedEth, uint256 reservedToken) = _computeReservedAmount(
            payoutEth_,
            payoutToken_
        );
        userPayoutEth -= reservedEth;
        userPayoutToken -= reservedToken;
        // send tokens to reward pool
        _depositFundsInRewardPool(reservedEth, reservedToken);
        // in case this is being called by {aggregateProfits()} we don't send any asset to the
        // users, we just store the owed amounts on state
        if (!localPayoutSafe && state == State.PostLock) {
            // we should not send here and should instead track to local mapping as
            // otherwise a single bad user could block exit operations for all other users
            // by making the send to their account fail via a contract
            _rewardEth[acct_] += userPayoutEth;
            _rewardTokens[acct_] += userPayoutToken;
            return (userPayoutEth, userPayoutToken);
        }
        // adding any additional token that should be sent to the user (e.g shares from
        // burned position on early exit)
        userPayoutToken += additionalTokens;
        _transferEthAndTokensWithReStake(acct_, userPayoutEth, userPayoutToken, stakeExit_);
        return (userPayoutEth, userPayoutToken);
    }

    function _transferEthAndTokensWithReStake(
        address to_,
        uint256 payoutEth_,
        uint256 payoutToken_,
        bool stakeExit_
    ) internal {
        if (stakeExit_) {
            IERC20(_alcaAddress()).approve(_publicStakingAddress(), payoutToken_);
            IStakingNFT(_publicStakingAddress()).mintTo(to_, payoutToken_, 0);
        } else {
            _safeTransferERC20(IERC20Transferable(_alcaAddress()), to_, payoutToken_);
        }
        _safeTransferEth(to_, payoutEth_);
    }

    function _newTokenID(uint256 tokenID_) internal {
        uint256 index = _lenTokenIDs + 1;
        _tokenIDs[index] = tokenID_;
        _reverseTokenIDs[tokenID_] = index;
        _lenTokenIDs = index;
    }

    function _replaceTokenID(uint256 oldID_, uint256 newID_) internal {
        uint256 index = _reverseTokenIDs[oldID_];
        _reverseTokenIDs[oldID_] = 0;
        _tokenIDs[index] = newID_;
        _reverseTokenIDs[newID_] = index;
    }

    function _removeTokenID(uint256 tokenID_) internal {
        uint256 initialLen = _lenTokenIDs;
        if (initialLen == 0) {
            return;
        }
        if (initialLen == 1) {
            uint256 index = _reverseTokenIDs[tokenID_];
            _reverseTokenIDs[tokenID_] = 0;
            _tokenIDs[index] = 0;
            _lenTokenIDs = 0;
            return;
        }
        // pop the tail
        uint256 tailTokenID = _tokenIDs[initialLen];
        _tokenIDs[initialLen] = 0;
        _lenTokenIDs = initialLen - 1;
        if (tailTokenID == tokenID_) {
            // element was tail, so we are done
            _reverseTokenIDs[tailTokenID] = 0;
            return;
        }
        // use swap logic to re-insert tail over other position
        _replaceTokenID(tokenID_, tailTokenID);
    }

    function _depositFundsInRewardPool(uint256 reservedEth_, uint256 reservedToken_) internal {
        _safeTransferERC20(IERC20Transferable(_alcaAddress()), _rewardPool, reservedToken_);
        RewardPool(_rewardPool).deposit{value: reservedEth_}(reservedToken_);
    }

    function _getNumShares(uint256 tokenID_) internal view returns (uint256 shares) {
        (shares, , , , ) = IStakingNFT(_publicStakingAddress()).getPosition(tokenID_);
    }

    function _estimateTotalAggregatedProfits()
        internal
        view
        returns (uint256 payoutEth, uint256 payoutToken)
    {
        for (uint256 i = 1; i <= _lenTokenIDs; i++) {
            (uint256 tokenID, ) = _getTokenIDAtIndex(i);
            (uint256 stakingProfitEth, uint256 stakingProfitToken) = IStakingNFT(
                _publicStakingAddress()
            ).estimateAllProfits(tokenID);
            (uint256 reserveEth, uint256 reserveToken) = _computeReservedAmount(
                stakingProfitEth,
                stakingProfitToken
            );
            payoutEth += reserveEth;
            payoutToken += reserveToken;
        }
    }

    function _estimateUserAggregatedProfits(
        uint256 userShares_,
        uint256 totalShares_
    ) internal view returns (uint256 payoutEth, uint256 payoutToken) {
        (payoutEth, payoutToken) = _estimateTotalAggregatedProfits();
        payoutEth = (payoutEth * userShares_) / totalShares_;
        payoutToken = (payoutToken * userShares_) / totalShares_;
    }

    function _payableSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _getTokenIDAtIndex(uint256 index_) internal view returns (uint256 tokenID, bool ok) {
        tokenID = _tokenIDs[index_];
        return (tokenID, tokenID > 0);
    }

    function _checkTokenTransfer(uint256 tokenID_) internal view {
        if (IERC721(_publicStakingAddress()).ownerOf(tokenID_) != address(this)) {
            revert LockupErrors.ContractDoesNotOwnTokenID(tokenID_);
        }
    }

    function _validateEntry(uint256 tokenID_, address sender_) internal view {
        if (_getOwnerOf(tokenID_) != address(0)) {
            revert LockupErrors.TokenIDAlreadyClaimed(tokenID_);
        }
        if (_getTokenOf(sender_) != 0) {
            revert LockupErrors.AddressAlreadyLockedUp();
        }
    }

    function _validateAndGetTokenId() internal view returns (uint256) {
        // get tokenID of caller
        uint256 tokenID = _getTokenOf(msg.sender);
        if (tokenID == 0) {
            revert LockupErrors.UserHasNoPosition();
        }
        return tokenID;
    }

    function _verifyLockedPosition(uint256 tokenID_) internal view {
        if (_getOwnerOf(tokenID_) == address(0)) {
            revert LockupErrors.TokenIDNotLocked(tokenID_);
        }
    }

    // Gets the shares of position and checks if a position exists and if we can collect the
    // profits after the _endBlock.
    function _verifyPositionAndGetShares(uint256 tokenId_) internal view returns (uint256) {
        // get position fails if the position doesn't exists!
        (uint256 shares, , uint256 withdrawFreeAfter, , ) = IStakingNFT(_publicStakingAddress())
            .getPosition(tokenId_);
        if (withdrawFreeAfter >= _endBlock) {
            revert LockupErrors.InvalidPositionWithdrawPeriod(withdrawFreeAfter, _endBlock);
        }
        return shares;
    }

    function _getState() internal view returns (State) {
        if (block.number < _startBlock) {
            return State.PreLock;
        }
        if (block.number < _endBlock) {
            return State.InLock;
        }
        return State.PostLock;
    }

    function _getOwnerOf(uint256 tokenID_) internal view returns (address payable) {
        return payable(_ownerOf[tokenID_]);
    }

    function _getTokenOf(address acct_) internal view returns (uint256) {
        return _tokenOf[acct_];
    }

    function _getTemporaryRewardBalance(address user_) internal view returns (uint256, uint256) {
        return (_rewardEth[user_], _rewardTokens[user_]);
    }

    function _computeReservedAmount(
        uint256 payoutEth_,
        uint256 payoutToken_
    ) internal pure returns (uint256 reservedEth, uint256 reservedToken) {
        reservedEth = (payoutEth_ * FRACTION_RESERVED) / SCALING_FACTOR;
        reservedToken = (payoutToken_ * FRACTION_RESERVED) / SCALING_FACTOR;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/libraries/lockup/AccessControlled.sol";
import "contracts/libraries/errors/LockupErrors.sol";
import "contracts/BonusPool.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/utils/ERC20SafeTransfer.sol";

/**
 * @notice RewardPool holds all ether and ALCA that is part of reserved amount
 * of rewards on base positions.
 * @dev deployed by the lockup contract
 */
contract RewardPool is AccessControlled, EthSafeTransfer, ERC20SafeTransfer {
    address internal immutable _alca;
    address internal immutable _lockupContract;
    address internal immutable _bonusPool;
    uint256 internal _ethReserve;
    uint256 internal _tokenReserve;

    constructor(address alca_, address aliceNetFactory_, uint256 totalBonusAmount_) {
        _bonusPool = address(
            new BonusPool(aliceNetFactory_, msg.sender, address(this), totalBonusAmount_)
        );
        _lockupContract = msg.sender;
        _alca = alca_;
    }

    /// @notice function that receives ether and updates the token and ether reservers. The ALCA
    /// tokens has to be sent prior the call to this function.
    /// @dev can only be called by the bonusPool or lockup contracts
    /// @param numTokens_ number of ALCA tokens transferred to this contract before the call to this
    /// function
    function deposit(uint256 numTokens_) public payable onlyLockupOrBonus {
        _tokenReserve += numTokens_;
        _ethReserve += msg.value;
    }

    /// @notice function to pay a user after the lockup period. If a user is the last exiting the
    /// lockup it will receive any remainders kept by this contract by integer division errors.
    /// @dev only can be called by the lockup contract
    /// @param totalShares_ the total shares at the end of the lockup period
    /// @param userShares_ the user shares
    /// @param isLastPosition_ if the user is the last position exiting from the lockup contract
    function payout(
        uint256 totalShares_,
        uint256 userShares_,
        bool isLastPosition_
    ) public onlyLockup returns (uint256 proportionalEth, uint256 proportionalTokens) {
        if (totalShares_ == 0 || userShares_ > totalShares_) {
            revert LockupErrors.InvalidTotalSharesValue();
        }

        // last position gets any remainder left on this contract
        if (isLastPosition_) {
            proportionalEth = address(this).balance;
            proportionalTokens = IERC20(_alca).balanceOf(address(this));
        } else {
            (proportionalEth, proportionalTokens) = _computeProportions(totalShares_, userShares_);
        }
        _safeTransferERC20(IERC20Transferable(_alca), _lockupContract, proportionalTokens);
        _safeTransferEth(payable(_lockupContract), proportionalEth);
    }

    /// @notice gets the bonusPool contract address
    /// @return the bonusPool contract address
    function getBonusPoolAddress() public view returns (address) {
        return _getBonusPoolAddress();
    }

    /// @notice gets the lockup contract address
    /// @return the lockup contract address
    function getLockupContractAddress() public view returns (address) {
        return _getLockupContractAddress();
    }

    /// @notice get the ALCA reserve kept by this contract
    /// @return the ALCA reserve kept by this contract
    function getTokenReserve() public view returns (uint256) {
        return _tokenReserve;
    }

    /// @notice get the ether reserve kept by this contract
    /// @return the ether reserve kept by this contract
    function getEthReserve() public view returns (uint256) {
        return _ethReserve;
    }

    /// @notice estimates the final amount that a user will receive from the assets hold by this
    /// contract after end of the lockup period.
    /// @param totalShares_ total number of shares locked by the lockup contract
    /// @param userShares_ the user's shares
    /// @return proportionalEth The ether that a user will receive at the end of the lockup period
    /// @return proportionalTokens The ALCA that a user will receive at the end of the lockup period
    function estimateRewards(
        uint256 totalShares_,
        uint256 userShares_
    ) public view returns (uint256 proportionalEth, uint256 proportionalTokens) {
        if (totalShares_ == 0 || userShares_ > totalShares_) {
            revert LockupErrors.InvalidTotalSharesValue();
        }
        return _computeProportions(totalShares_, userShares_);
    }

    function _computeProportions(
        uint256 totalShares_,
        uint256 userShares_
    ) internal view returns (uint256 proportionalEth, uint256 proportionalTokens) {
        proportionalEth = (_ethReserve * userShares_) / totalShares_;
        proportionalTokens = (_tokenReserve * userShares_) / totalShares_;
    }

    function _getLockupContractAddress() internal view override returns (address) {
        return _lockupContract;
    }

    function _getBonusPoolAddress() internal view override returns (address) {
        return _bonusPool;
    }

    function _getRewardPoolAddress() internal view override returns (address) {
        return address(this);
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "contracts/interfaces/IERC721Transferable.sol";
import "contracts/interfaces/IAliceNetFactory.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/interfaces/IStakingToken.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/utils/ERC20SafeTransfer.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutablePublicStaking.sol";
import "contracts/utils/auth/ImmutableALCA.sol";
import "contracts/Lockup.sol";

/// @custom:salt StakingRouterV1
/// @custom:deploy-type deployCreateAndRegister
/// @custom:deploy-group lockup
/// @custom:deploy-group-index 1
contract StakingRouterV1 is
    ImmutablePublicStaking,
    ImmutableALCA,
    ERC20SafeTransfer,
    EthSafeTransfer
{
    error InvalidStakingAmount(uint256 stakingAmount, uint256 migratedAmount);

    bytes32 internal constant _LOCKUP_SALT =
        0x4c6f636b75700000000000000000000000000000000000000000000000000000;
    address internal immutable _legacyToken;
    address internal immutable _lockupContract;

    constructor() ImmutableFactory(msg.sender) ImmutablePublicStaking() ImmutableALCA() {
        _legacyToken = IStakingToken(_alcaAddress()).getLegacyTokenAddress();
        _lockupContract = IAliceNetFactory(_factoryAddress()).lookup(_LOCKUP_SALT);
    }

    /// @notice Migrates an amount of legacy token (MADToken) to ALCA tokens and stake them in the
    /// PublicStaking contract. User calling this function must have approved this contract to
    /// transfer the `migrationAmount_` MADTokens beforehand.
    /// @param to_ the address that will own the position
    /// @param migrationAmount_ the amount of legacy token to migrate
    /// @param stakingAmount_ the amount of ALCA that will staked and locked
    function migrateAndStake(address to_, uint256 migrationAmount_, uint256 stakingAmount_) public {
        uint256 migratedAmount = _migrate(msg.sender, migrationAmount_);
        _verifyAndSendAnyRemainder(to_, migratedAmount, stakingAmount_);
        _stake(to_, stakingAmount_);
    }

    /// @notice Migrates an amount of legacy token (MADToken) to ALCA tokens, stake them in the
    /// PublicStaking contract and in sequence lock the position. User calling this function must have
    /// approved this contract to transfer the `migrationAmount_` MADTokens beforehand.
    /// @param to_ the address that will own the locked position
    /// @param migrationAmount_ the amount of legacy token to migrate
    /// @param stakingAmount_ the amount of ALCA that will staked and locked
    function migrateStakeAndLock(
        address to_,
        uint256 migrationAmount_,
        uint256 stakingAmount_
    ) public {
        uint256 migratedAmount = _migrate(msg.sender, migrationAmount_);
        _verifyAndSendAnyRemainder(to_, migratedAmount, stakingAmount_);
        // mint the position directly to the lockup contract
        uint256 tokenID = _stake(_lockupContract, stakingAmount_);
        // right in sequence claim the minted position
        Lockup(payable(_lockupContract)).lockFromTransfer(tokenID, to_);
    }

    /// @notice Stake an amount of ALCA in the PublicStaking contract and lock the position in
    /// sequence. User calling this function must have approved this contract to
    /// transfer the `stakingAmount_` ALCA beforehand.
    /// @param to_ the address that will own the locked position
    /// @param stakingAmount_ the amount of ALCA that will staked
    function stakeAndLock(address to_, uint256 stakingAmount_) public {
        _safeTransferFromERC20(IERC20Transferable(_alcaAddress()), msg.sender, stakingAmount_);
        // mint the position directly to the lockup contract
        uint256 tokenID = _stake(_lockupContract, stakingAmount_);
        // right in sequence claim the minted position
        Lockup(payable(_lockupContract)).lockFromTransfer(tokenID, to_);
    }

    /// @notice Get the address of the legacy token.
    /// @return the address of the legacy token (MADToken).
    function getLegacyTokenAddress() public view returns (address) {
        return _legacyToken;
    }

    function _migrate(address from_, uint256 amount_) internal returns (uint256 migratedAmount_) {
        _safeTransferFromERC20(IERC20Transferable(_legacyToken), from_, amount_);
        IERC20(_legacyToken).approve(_alcaAddress(), amount_);
        migratedAmount_ = IStakingToken(_alcaAddress()).migrateTo(address(this), amount_);
    }

    function _stake(address to_, uint256 stakingAmount_) internal returns (uint256 tokenID_) {
        IERC20(_alcaAddress()).approve(_publicStakingAddress(), stakingAmount_);
        tokenID_ = IStakingNFT(_publicStakingAddress()).mintTo(to_, stakingAmount_, 0);
    }

    function _verifyAndSendAnyRemainder(
        address to_,
        uint256 migratedAmount_,
        uint256 stakingAmount_
    ) internal {
        if (stakingAmount_ > migratedAmount_) {
            revert InvalidStakingAmount(stakingAmount_, migratedAmount_);
        }
        uint256 remainder = migratedAmount_ - stakingAmount_;
        if (remainder > 0) {
            _safeTransferERC20(IERC20Transferable(_alcaAddress()), to_, remainder);
        }
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/interfaces/IAliceNetFactory.sol";

abstract contract ImmutableALCA is ImmutableFactory {
    address private immutable _alca;
    error OnlyALCA(address sender, address expected);

    modifier onlyALCA() {
        if (msg.sender != _alca) {
            revert OnlyALCA(msg.sender, _alca);
        }
        _;
    }

    constructor() {
        _alca = IAliceNetFactory(_factoryAddress()).lookup(_saltForALCA());
    }

    function _alcaAddress() internal view returns (address) {
        return _alca;
    }

    function _saltForALCA() internal pure returns (bytes32) {
        return 0x414c434100000000000000000000000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";

abstract contract ImmutableFactory is DeterministicAddress {
    address private immutable _factory;
    error OnlyFactory(address sender, address expected);

    modifier onlyFactory() {
        if (msg.sender != _factory) {
            revert OnlyFactory(msg.sender, _factory);
        }
        _;
    }

    constructor(address factory_) {
        _factory = factory_;
    }

    function _factoryAddress() internal view returns (address) {
        return _factory;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableFoundation is ImmutableFactory {
    address private immutable _foundation;
    error OnlyFoundation(address sender, address expected);

    modifier onlyFoundation() {
        if (msg.sender != _foundation) {
            revert OnlyFoundation(msg.sender, _foundation);
        }
        _;
    }

    constructor() {
        _foundation = getMetamorphicContractAddress(
            0x466f756e646174696f6e00000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _foundationAddress() internal view returns (address) {
        return _foundation;
    }

    function _saltForFoundation() internal pure returns (bytes32) {
        return 0x466f756e646174696f6e00000000000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutablePublicStaking is ImmutableFactory {
    address private immutable _publicStaking;
    error OnlyPublicStaking(address sender, address expected);

    modifier onlyPublicStaking() {
        if (msg.sender != _publicStaking) {
            revert OnlyPublicStaking(msg.sender, _publicStaking);
        }
        _;
    }

    constructor() {
        _publicStaking = getMetamorphicContractAddress(
            0x5075626c69635374616b696e6700000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _publicStakingAddress() internal view returns (address) {
        return _publicStaking;
    }

    function _saltForPublicStaking() internal pure returns (bytes32) {
        return 0x5075626c69635374616b696e6700000000000000000000000000000000000000;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract DeterministicAddress {
    function getMetamorphicContractAddress(
        bytes32 _salt,
        address _factory
    ) public pure returns (address) {
        // byte code for metamorphic contract
        // 6020363636335afa1536363636515af43d36363e3d36f3
        bytes32 metamorphicContractBytecodeHash_ = 0x1c0bf703a3415cada9785e89e9d70314c3111ae7d8e04f33bb42eb1d264088be;
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                _factory,
                                _salt,
                                metamorphicContractBytecodeHash_
                            )
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IERC20Transferable.sol";
import "contracts/libraries/errors/ERC20SafeTransferErrors.sol";

abstract contract ERC20SafeTransfer {
    // _safeTransferFromERC20 performs a transferFrom call against an erc20 contract in a safe manner
    // by reverting on failure
    // this function will return without performing a call or reverting
    // if amount_ is zero
    function _safeTransferFromERC20(
        IERC20Transferable contract_,
        address sender_,
        uint256 amount_
    ) internal {
        if (amount_ == 0) {
            return;
        }
        if (address(contract_) == address(0x0)) {
            revert ERC20SafeTransferErrors.CannotCallContractMethodsOnZeroAddress();
        }

        bool success = contract_.transferFrom(sender_, address(this), amount_);
        if (!success) {
            revert ERC20SafeTransferErrors.Erc20TransferFailed(
                address(contract_),
                sender_,
                address(this),
                amount_
            );
        }
    }

    // _safeTransferERC20 performs a transfer call against an erc20 contract in a safe manner
    // by reverting on failure
    // this function will return without performing a call or reverting
    // if amount_ is zero
    function _safeTransferERC20(
        IERC20Transferable contract_,
        address to_,
        uint256 amount_
    ) internal {
        if (amount_ == 0) {
            return;
        }
        if (address(contract_) == address(0x0)) {
            revert ERC20SafeTransferErrors.CannotCallContractMethodsOnZeroAddress();
        }
        bool success = contract_.transfer(to_, amount_);
        if (!success) {
            revert ERC20SafeTransferErrors.Erc20TransferFailed(
                address(contract_),
                address(this),
                to_,
                amount_
            );
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/libraries/errors/ETHSafeTransferErrors.sol";

abstract contract EthSafeTransfer {
    /// @notice _safeTransferEth performs a transfer of Eth using the call
    /// method / this function is resistant to breaking gas price changes and /
    /// performs call in a safe manner by reverting on failure. / this function
    /// will return without performing a call or reverting, / if amount_ is zero
    function _safeTransferEth(address to_, uint256 amount_) internal {
        if (amount_ == 0) {
            return;
        }
        if (to_ == address(0)) {
            revert ETHSafeTransferErrors.CannotTransferToZeroAddress();
        }
        address payable caller = payable(to_);
        (bool success, ) = caller.call{value: amount_}("");
        if (!success) {
            revert ETHSafeTransferErrors.EthTransferFailed(address(this), to_, amount_);
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/MagicValue.sol";
import "contracts/interfaces/IMagicEthTransfer.sol";

abstract contract MagicEthTransfer is MagicValue {
    function _safeTransferEthWithMagic(IMagicEthTransfer to_, uint256 amount_) internal {
        to_.depositEth{value: amount_}(_getMagic());
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/libraries/errors/MagicValueErrors.sol";

abstract contract MagicValue {
    // _MAGIC_VALUE is a constant that may be used to prevent
    // a user from calling a dangerous method without significant
    // effort or ( hopefully ) reading the code to understand the risk
    uint8 internal constant _MAGIC_VALUE = 42;

    modifier checkMagic(uint8 magic_) {
        if (magic_ != _getMagic()) {
            revert MagicValueErrors.BadMagic(magic_);
        }
        _;
    }

    // _getMagic returns the magic constant
    function _getMagic() internal pure returns (uint8) {
        return _MAGIC_VALUE;
    }
}