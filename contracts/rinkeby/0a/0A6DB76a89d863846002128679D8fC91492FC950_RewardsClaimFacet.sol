// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IRewardsClaim } from "../interfaces/facets/IRewardsClaim.sol";
import { LibStorage, TokenAddressStorage, RewardsManagementStorage } from "../libraries/LibStorage.sol";

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RewardsClaimFacet is IRewardsClaim {
    /**
     * @notice Claims available rewards for caller
     *
     * @param epoch The epoch to claim rewards for
     * @param amount The amount of reward tokens to claim for the user
     * @param merkleProof The merkle proof for the user's claim
     */
    function claimRewards(
        uint256 epoch,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external override {
        TokenAddressStorage storage tas = LibStorage.tokenAddressStorage();
        RewardsManagementStorage storage rms = LibStorage.rewardsManagementStorage();

        // ensure user claims reward to an epoch that has ended
        require(rms.epochEndings[epoch] > 0, "Epoch not started");
        require(block.timestamp > rms.epochEndings[epoch], "Epoch not ended");

        // ensure the rewards have been set
        require(
            rms.epochRewardsMekleRoots[epoch] != bytes32(0) && rms.epochTotalRewards[epoch] > 0,
            "Epoch rewards not set"
        );

        // ensure user has not already claimed
        require(!rms.rewardsClaimed[epoch][msg.sender], "Already claimed");

        // verify the proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(merkleProof, rms.epochRewardsMekleRoots[epoch], leaf), "Invalid merkle proof");

        // set to claimed
        rms.rewardsClaimed[epoch][msg.sender] = true;

        // transfer the rewards tokens
        IERC20(tas.fukuToken).transfer(msg.sender, amount);

        emit RewardsClaim(msg.sender, epoch, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRewardsClaim {
    event RewardsClaim(address user, uint256 epoch, uint256 amount);

    function claimRewards(
        uint256 epoch,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { BidInfo, OptionInfo, AcceptedOption } from "../FukuTypes.sol";

struct BidMarketStorage {
    uint256 nextBidId;
    mapping(uint256 => BidInfo) bids;
}

struct OptionMarketStorage {
    uint256 nextOptionId;
    mapping(uint256 => OptionInfo) options;
    mapping(uint256 => AcceptedOption) acceptedOptions;
}

struct VaultStorage {
    mapping(bytes12 => address) vaultAddresses;
    mapping(address => mapping(bytes12 => uint256)) userVaultBalances;
}

struct TokenAddressStorage {
    address punkToken;
    address fukuToken;
}

struct AirdropClaimStorage {
    bytes32 merkleRoot;
    uint256 totalAmount; // todo: unused
    uint256 initialUnlockBps; // todo: unused
    mapping(address => uint256) claimed;
}

struct RewardsManagementStorage {
    uint256 nextEpochId;
    uint256 epochDuration;
    mapping(uint256 => uint256) epochEndings;
    mapping(uint256 => bytes32) epochRewardsMekleRoots;
    mapping(uint256 => uint256) epochTotalRewards;
    mapping(uint256 => mapping(address => bool)) rewardsClaimed;
}

struct DepositsRewardsStorage {
    mapping(bytes12 => uint256) periodFinish;
    mapping(bytes12 => uint256) rewardRate;
    mapping(bytes12 => uint256) rewardsDuration;
    mapping(bytes12 => uint256) lastUpdateTime;
    mapping(bytes12 => uint256) rewardPerTokenStored;
    mapping(bytes12 => uint256) totalSupply;
    mapping(bytes12 => mapping(address => uint256)) userRewardPerTokenPaid;
    mapping(bytes12 => mapping(address => uint256)) rewards;
}

library LibStorage {
    bytes32 constant BID_MARKET_STORAGE_POSITION = keccak256("fuku.storage.market.bid");
    bytes32 constant OPTION_MARKET_STORAGE_POSTION = keccak256("fuku.storage.market.option");
    bytes32 constant VAULT_STORAGE_POSITION = keccak256("fuku.storage.vault");
    bytes32 constant TOKEN_ADDRESS_STORAGE_POSITION = keccak256("fuku.storage.token.address");
    bytes32 constant AIRDROP_CLAIM_STORAGE_POSITION = keccak256("fuku.storage.airdrop.claim");
    bytes32 constant REWARDS_MANAGEMENT_STORAGE_POSITION = keccak256("fuku.storage.rewards.management");
    bytes32 constant DEPOSITS_REWARDS_STORAGE_POSITION = keccak256("fuku.storage.deposits.rewards");

    function bidMarketStorage() internal pure returns (BidMarketStorage storage bms) {
        bytes32 position = BID_MARKET_STORAGE_POSITION;
        assembly {
            bms.slot := position
        }
    }

    function optionMarketStorage() internal pure returns (OptionMarketStorage storage oms) {
        bytes32 position = OPTION_MARKET_STORAGE_POSTION;
        assembly {
            oms.slot := position
        }
    }

    function vaultStorage() internal pure returns (VaultStorage storage vs) {
        bytes32 position = VAULT_STORAGE_POSITION;
        assembly {
            vs.slot := position
        }
    }

    function tokenAddressStorage() internal pure returns (TokenAddressStorage storage tas) {
        bytes32 position = TOKEN_ADDRESS_STORAGE_POSITION;
        assembly {
            tas.slot := position
        }
    }

    function airdropClaimStorage() internal pure returns (AirdropClaimStorage storage acs) {
        bytes32 position = AIRDROP_CLAIM_STORAGE_POSITION;
        assembly {
            acs.slot := position
        }
    }

    function rewardsManagementStorage() internal pure returns (RewardsManagementStorage storage rms) {
        bytes32 position = REWARDS_MANAGEMENT_STORAGE_POSITION;
        assembly {
            rms.slot := position
        }
    }

    function depositsRewardsStorage() internal pure returns (DepositsRewardsStorage storage drs) {
        bytes32 position = DEPOSITS_REWARDS_STORAGE_POSITION;
        assembly {
            drs.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

enum OptionDuration {
    ThirtyDays,
    NinetyDays
}

struct BidInputParams {
    bytes12 vault; // the vault from where the funds for the bid originate
    address nft; // the address of the nft collection
    uint256 nftIndex; // the index of the nft in the collection
    uint256 amount; // the bid amount
}

struct BidInfo {
    BidInputParams bidInput; // the input params used to create bid
    address bidder; // the address of the bidder
}

struct OptionInputParams {
    BidInputParams bidInput;
    uint256 premium;
    OptionDuration duration;
}

struct OptionInfo {
    OptionInputParams optionInput; // the input params used to create base part of bid
    bool exercisable; // true if option can be exercised, false otherwise
    address bidder; // the bidder (buyer)
}

struct AcceptedOption {
    uint256 expiry;
    address seller;
}

struct AirdropInit {
    bytes32 merkleRoot;
    address token;
    uint256 totalAmount;
    uint256 initialUnlockBps;
}