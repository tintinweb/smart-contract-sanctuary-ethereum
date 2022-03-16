// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

import "../interfaces/IRewardPool.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/IPausable.sol";

contract RewardPoolTemplate_R0 is Initializable, ContextUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, OwnableUpgradeable, ERC20Upgradeable, ERC165Upgradeable, IRewardPool {

    uint8 constant public PAYOUT_TYPE_UNIFORM = uint8(0x00);

    uint16 constant public CLAIM_MODE_UNAVAILABLE = uint16(0 << 0);
    uint16 constant public CLAIM_MODE_ERC20 = uint16(1 << 0);
    uint16 constant public CLAIM_MODE_PARACHAIN = uint16(1 << 1);

    struct RewardPayout {
        uint8 payoutType;
        uint128 totalRewards;
        uint64 fromBlock;
        uint32 durationBlocks;
    }

    struct RewardState {
        uint64 firstNotClaimedBlock;
        uint128 pendingRewards;
        uint32 activeRewardPayout;
    }

    RewardPayout[] private _rewardPayouts;
    mapping(address => RewardState) _rewardStates;
    address private _transactionNotary;
    mapping(bytes32 => bool) _verifiedProofs;
    IERC20Upgradeable private _stakingToken;
    uint8 private _decimals;
    address private _multiSigWallet;
    uint16 private _claimMode;
    bool private _burnEnabled;

    function initialize(string calldata symbol, string calldata name, uint8 decimals_, address transactionNotary, address multiSigWallet, IERC20Upgradeable rewardToken, uint16 claimMode) external initializer {
        __Context_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __Ownable_init();
        __ERC20_init(name, symbol);
        __RewardPool_init(decimals_, transactionNotary, multiSigWallet, rewardToken, claimMode);
    }

    function __RewardPool_init(uint8 decimals_, address transactionNotary, address multiSigWallet, IERC20Upgradeable stakingToken, uint16 claimMode) internal {
        // init contract state
        _transactionNotary = transactionNotary;
        _decimals = decimals_;
        _multiSigWallet = multiSigWallet;
        _claimMode = claimMode;
        _stakingToken = stakingToken;
        // do some validations
        require(claimMode & CLAIM_MODE_ERC20 > 0 && address(stakingToken) != address(0x00), "staking token is required for ERC20 claim mode");
        // make sure contract is paused by default
        _pause();
    }

    function getRewardPayouts() external view returns (RewardPayout[] memory) {
        return _rewardPayouts;
    }

    function getTransactionNotary() external view returns (address) {
        return _transactionNotary;
    }

    function getRewardToken() external view returns (IERC20Upgradeable) {
        return _stakingToken;
    }

    function getStakingToken() external view returns (IERC20Upgradeable) {
        return _stakingToken;
    }

    function getMultiSigWallet() external view returns (address) {
        return _multiSigWallet;
    }

    function getClaimMode() external view returns (uint16) {
        return _claimMode;
    }

    function getCurrentRewardState(address account) external view returns (RewardState memory) {
        return _rewardStates[account];
    }

    function getFutureRewardState(address account) external view returns (RewardState memory) {
        RewardState memory rewardState = _rewardStates[account];
        _calcPendingRewards(balanceOf(account), rewardState);
        return rewardState;
    }

    modifier onlyMultiSig() {
        require(msg.sender == _multiSigWallet, "only multi-sig");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == _transactionNotary, "Operator: not allowed");
        _;
    }

    modifier whenTokenBurnEnabled() {
        require(_burnEnabled, "token burning is not allowed yet");
        _;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function changeMultiSigWallet(address multiSigWallet) external onlyMultiSig {
        _multiSigWallet = multiSigWallet;
    }

    modifier whenZeroSupply() {
        require(totalSupply() == 0, "total supply is not zero");
        _;
    }

    function initZeroRewardPayout(uint256 maxSupply, uint8 payoutType, uint64 fromBlock, uint64 toBlockExclusive, uint256 amount) external onlyMultiSig whenZeroSupply whenPaused override {
        // mint max possible total supply of aDOTp tokens and locked them on smart contract
        _mint(address(this), maxSupply);
        // deposit zero reward payout to init first distribution scheme
        _depositRewardPayout(payoutType, fromBlock, toBlockExclusive, amount);
        // make contract active
        _unpause();
    }

    function depositRewardPayout(uint8 payoutType, uint64 fromBlock, uint64 toBlockExclusive, uint256 amount) external onlyMultiSig whenNotPaused override {
        _depositRewardPayout(payoutType, fromBlock, toBlockExclusive, amount);
    }

    function _depositRewardPayout(uint8 payoutType, uint64 fromBlock, uint64 toBlockExclusive, uint256 amount) internal {
        require(toBlockExclusive > fromBlock, "intersection is not allowed");
        // verify payout type
        require(payoutType == PAYOUT_TYPE_UNIFORM, "invalid payout type");
        // we must be sure that reward payouts are ordered and doesn't intersect to each other
        if (_rewardPayouts.length > 0) {
            RewardPayout memory latestRewardPayout = _rewardPayouts[_rewardPayouts.length - 1];
            require(latestRewardPayout.fromBlock + latestRewardPayout.durationBlocks <= fromBlock, "intersection is not allowed");
        }
        // write new reward payout to storage
        _rewardPayouts.push(RewardPayout({
        totalRewards : uint128(amount),
        fromBlock : fromBlock,
        durationBlocks : uint32(toBlockExclusive - fromBlock),
        payoutType : payoutType
        }));
        // transfer tokens from sender
        if (address(_stakingToken) != address(0x00)) {
            require(_stakingToken.transferFrom(msg.sender, address(this), amount), "can't transfer reward tokens");
        }
        // emit event
        emit RewardPayoutDeposited(payoutType, fromBlock, toBlockExclusive, amount);
    }

    function isClaimUsed(uint256 claimId) external view override returns (bool) {
        return _verifiedProofs[bytes32(claimId)];
    }

    function claimTokensFor(uint256 claimId, uint256 amount, uint256 claimBeforeBlock, address account, bytes memory signature) external nonReentrant whenNotPaused override {
        // do proof verification
        require(block.number < claimBeforeBlock, "claim is expired");
        bytes32 messageHash = keccak256(abi.encode(address(this), claimId, amount, claimBeforeBlock, account));
        require(ECDSAUpgradeable.recover(messageHash, signature) == _transactionNotary, "bad signature");
        // make sure proof can only be used once
        require(!_verifiedProofs[bytes32(claimId)], "proof is already used");
        /* TODO: "tbh we don't need to store claim id, because its enough to remember claimBeforeBlock field instead of it and this operation can safe 20k gas for user" */
        _verifiedProofs[bytes32(claimId)] = true;
        // send tokens to user (advance is included in mint operation, check on transfer hook)
        _transfer(address(this), account, amount);
        // we need to recalculate entire rewards before claim to restore possible lost tokens based on new share amount
        RewardState memory rewardState = _rewardStates[account];
        rewardState.activeRewardPayout = 0;
        rewardState.firstNotClaimedBlock = 0;
        _calcPendingRewards(amount, rewardState);
        _rewardStates[account] = rewardState;
        // emit event
        emit TokensClaimed(claimId, amount, claimBeforeBlock, account);
    }

    function claimableRewardsOf(address account) external view override returns (uint256) {
        RewardState memory rewardState = _rewardStates[account];
        _calcPendingRewards(balanceOf(account), rewardState);
        return uint256(rewardState.pendingRewards);
    }

    function isTokenClaim() external view override returns (bool) {
        return _claimMode & CLAIM_MODE_ERC20 > 0;
    }

    function isParachainClaim() external view override returns (bool) {
        return _claimMode & CLAIM_MODE_PARACHAIN > 0;
    }

    function claimTokenRewards() external nonReentrant whenNotPaused override {
        require(_claimMode & CLAIM_MODE_ERC20 > 0, "not supported claim mode");
        address account = address(msg.sender);
        uint256 amount = _chargeRewardsClaim(account);
        require(_stakingToken.transfer(account, amount), "can't send rewards");
        emit ClaimedTokenRewards(account, amount);
    }

    function claimParachainRewards(bytes calldata recipient) external nonReentrant whenNotPaused override {
        require(_claimMode & CLAIM_MODE_PARACHAIN > 0, "not supported claim mode");
        address account = address(msg.sender);
        uint256 amount = _chargeRewardsClaim(account);
        emit ClaimedParachainRewards(account, recipient, amount);
    }

    function _chargeRewardsClaim(address account) internal returns (uint256) {
        RewardState memory rewardState = _rewardStates[account];
        _calcPendingRewards(balanceOf(account), rewardState);
        require(rewardState.pendingRewards > 0, "there is no rewards to be claimed");
        uint256 amount = rewardState.pendingRewards;
        rewardState.pendingRewards = 0;
        _rewardStates[account] = rewardState;
        return amount;
    }

    function _advancePendingRewards(address account) internal {
        // we can't do advance for this because it mints useless rewards otherwise
        if (account == address(this)) {
            return;
        }
        // write new pending reward state from memory to storage
        RewardState memory rewardState = _rewardStates[account];
        _calcPendingRewards(balanceOf(account), rewardState);
        _rewardStates[account] = rewardState;
    }

    function _calcPendingRewards(uint256 balance, RewardState memory rewardState) internal view {
        // don't do any advances before rewards payed or there is active scheme
        if (_rewardPayouts.length == 0 || rewardState.activeRewardPayout >= _rewardPayouts.length) {
            return;
        }
        // do reward distribution
        uint64 latestPayoutBlock = 0;
        uint256 totalRewardPayouts = _rewardPayouts.length;
        for (uint256 i = rewardState.activeRewardPayout; i < totalRewardPayouts; i++) {
            RewardPayout memory rewardPayout = _rewardPayouts[i];
            if (i == totalRewardPayouts - 1) {
                latestPayoutBlock = rewardPayout.fromBlock + rewardPayout.durationBlocks;
            }
            _calcPendingRewardsForPayout(balance, rewardState, rewardPayout);
        }
        // change latest reward payout offset (tiny optimization)
        uint64 blockNumber = uint64(block.number);
        if (blockNumber >= latestPayoutBlock) {
            rewardState.activeRewardPayout = uint32(_rewardPayouts.length);
            rewardState.firstNotClaimedBlock = latestPayoutBlock;
        } else {
            rewardState.activeRewardPayout = uint32(_rewardPayouts.length - 1);
            rewardState.firstNotClaimedBlock = blockNumber + 1;
        }
    }

    function _calcPendingRewardsForPayout(uint256 balance, RewardState memory rewardState, RewardPayout memory currentPayout) internal view {
        (uint256 fromBlock, uint256 toBlockExclusive) = (uint256(currentPayout.fromBlock), uint256(currentPayout.fromBlock + currentPayout.durationBlocks));
        // special case when we're out of allowed block range, just skip this payout scheme
        uint64 blockNumber = uint64(block.number);
        if (blockNumber < fromBlock || rewardState.firstNotClaimedBlock >= toBlockExclusive) {
            return;
        }
        uint256 stakingBlocks = MathUpgradeable.min(blockNumber + 1, toBlockExclusive) - MathUpgradeable.max(fromBlock, rewardState.firstNotClaimedBlock);
        // calc reward distribution based on payout type
        if (currentPayout.payoutType == PAYOUT_TYPE_UNIFORM) {
            uint256 avgRewardsPerBlock = uint256(currentPayout.totalRewards) / currentPayout.durationBlocks;
            uint256 accountShare = 1e18 * balance / totalSupply();
            rewardState.pendingRewards += uint128(accountShare * avgRewardsPerBlock / 1e18 * stakingBlocks);
        } else {
            revert("not supported payout type");
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 /*amount*/) internal override {
        if (from != to) {
            _advancePendingRewards(from);
        }
        _advancePendingRewards(to);
    }

    function toggleTokenBurn(bool isEnabled) external onlyOperator whenNotPaused override {
        _burnEnabled = isEnabled;
    }

    function isTokenBurnEnabled() external view override returns (bool) {
        return _burnEnabled;
    }

    function burnTokens(uint256 amount, bytes calldata recipient) external nonReentrant whenNotPaused whenTokenBurnEnabled override {
        uint256 balance = balanceOf(_msgSender());
        require(balance >= amount, "cannot burn more tokens than available");
        _burn(_msgSender(), amount);
        address account = address(msg.sender);
        emit TokensBurnedForRefund(account, recipient, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId)
        || interfaceId == type(IOwnable).interfaceId
        || interfaceId == type(IPausable).interfaceId
        || interfaceId == type(IERC20Upgradeable).interfaceId
        || interfaceId == type(IERC20MetadataUpgradeable).interfaceId
        || interfaceId == type(IRewardPool).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IRewardPool {

    event RewardPayoutDeposited(uint8 payoutType, uint64 fromBlock, uint64 toBlockExclusive, uint256 amount);

    event TokensClaimed(uint256 claimId, uint256 amount, uint256 claimBeforeBlock, address account);

    event ClaimedParachainRewards(address account, bytes recipient, uint256 amount);

    event ClaimedTokenRewards(address account, uint256 amount);

    event TokensBurnedForRefund(address account, bytes recipient, uint256 amount);

    function initZeroRewardPayout(uint256 maxSupply, uint8 payoutType, uint64 fromBlock, uint64 toBlockExclusive, uint256 amount) external;

    function depositRewardPayout(uint8 payoutType, uint64 fromBlock, uint64 toBlockExclusive, uint256 amount) external;

    function isClaimUsed(uint256 claimId) external view returns (bool);

    function claimTokensFor(uint256 claimId, uint256 amount, uint256 claimBeforeBlock, address account, bytes memory signature) external;

    function claimableRewardsOf(address account) external view returns (uint256);

    function isTokenClaim() external view returns (bool);

    function isParachainClaim() external view returns (bool);

    function claimTokenRewards() external;

    function claimParachainRewards(bytes calldata recipient) external;

    function toggleTokenBurn(bool isEnabled) external;

    function isTokenBurnEnabled() external view returns (bool);

    function burnTokens(uint256 amount, bytes calldata recipient) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IPausable {

    event Paused(address account);

    event Unpaused(address account);

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IOwnable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

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
interface IERC165Upgradeable {
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

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    uint256[49] private __gap;
}