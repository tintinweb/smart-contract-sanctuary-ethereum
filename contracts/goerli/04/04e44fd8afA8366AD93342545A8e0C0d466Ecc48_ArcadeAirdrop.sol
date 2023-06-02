// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "../external/council/libraries/Authorizable.sol";

import "../libraries/ArcadeMerkleRewards.sol";

import { AA_ClaimingNotExpired, AA_ZeroAddress } from "../errors/Airdrop.sol";

/**
 * @title Arcade Airdrop
 * @author Non-Fungible Technologies, Inc.
 *
 * This contract receives tokens from the ArcadeTokenDistributor and facilitates airdrop claims.
 * The contract is ownable, where the owner can reclaim any remaining tokens once the airdrop is
 * over and also change the merkle root at their discretion.
 */
contract ArcadeAirdrop is ArcadeMerkleRewards, Authorizable {
    // ========================================== CONSTRUCTOR ===========================================

    /**
     * @notice Initiate the contract with a merkle tree root, a token for distribution,
     *         an expiration time for claims, and the voting vault that tokens will be
     *         airdropped into. In addition, set a governance parameter for the address that
     *         can reclaim tokens after expiry.
     *
     * @param _governance           The address that can reclaim tokens after expiry
     * @param _merkleRoot           The merkle root with deposits encoded into it as hash [address, amount]
     * @param _token                The token to airdrop
     * @param _expiration           The expiration of the airdrop
     * @param _votingVault         The voting vault to deposit tokens to
     */
    constructor(
        address _governance,
        bytes32 _merkleRoot,
        IERC20 _token,
        uint256 _expiration,
        INFTBoostVault _votingVault
    ) ArcadeMerkleRewards(_merkleRoot, _token, _expiration, _votingVault) {
        if (_governance == address(0)) revert AA_ZeroAddress();

        setOwner(_governance);
    }

    // ===================================== ADMIN FUNCTIONALITY ========================================

    /**
     * @notice Allows governance to remove the funds in this contract once the airdrop is over.
     *         This function can only be called after the expiration time.
     *
     * @param destination        The address which will receive the remaining tokens
     */
    function reclaim(address destination) external onlyOwner {
        if (block.timestamp <= expiration) revert AA_ClaimingNotExpired();
        if (destination == address(0)) revert AA_ZeroAddress();

        uint256 unclaimed = token.balanceOf(address(this));
        token.transfer(destination, unclaimed);
    }

    /**
     * @notice Allows the owner to change the merkle root.
     *
     * @param _merkleRoot        The new merkle root
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        rewardsRoot = _merkleRoot;
    }
}

// SPDX-License-Identifier: MIT

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
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title AirdropErrors
 * @author Non-Fungible Technologies, Inc.
 *
 * This file contains all custom errors for the Arcade Token airdrop contract.
 * All errors are prefixed by  "AA_" for ArcadeAirdrop. Errors located in one place
 * to make it possible to holistically look at all the failure cases.
 */

// ==================================== ARCADE AIRDROP ======================================
/// @notice All errors prefixed with AA_, to separate from other contracts in governance.

/**
 * @notice Ensure airdrop claim period has expired before reclaiming tokens.
 */
error AA_ClaimingNotExpired();

/**
 * @notice Cannot claim tokens after airdrop has expired.
 */
error AA_ClaimingExpired();

/**
 * @notice Cannot claim tokens multiple times.
 */
error AA_AlreadyClaimed();

/**
 * @notice Airdropped tokens cannot be claimed to a users wallet.
 */
error AA_NoClaiming();

/**
 * @notice Merkle proof not verified. User is not a participant in the airdrop.
 */
error AA_NonParticipant();

/**
 * @notice Thrown when a zero address is passed in as a parameter.
 */
error AA_ZeroAddress();

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0;

contract Authorizable {
    // This contract allows a flexible authorization scheme

    // The owner who can change authorization status
    address public owner;
    // A mapping from an address to its authorization status
    mapping(address => bool) public authorized;

    /// @dev We set the deployer to the owner
    constructor() {
        owner = msg.sender;
    }

    /// @dev This modifier checks if the msg.sender is the owner
    modifier onlyOwner() {

        require(msg.sender == owner, "Sender not owner");
        _;

    }

    /// @dev This modifier checks if an address is authorized
    modifier onlyAuthorized() {
        require(isAuthorized(msg.sender), "Sender not Authorized");
        _;
    }

    /// @dev Returns true if an address is authorized
    /// @param who the address to check
    /// @return true if authorized false if not
    function isAuthorized(address who) public view returns (bool) {
        return authorized[who];
    }

    /// @dev Privileged function authorize an address
    /// @param who the address to authorize
    function authorize(address who) external onlyOwner() {
        _authorize(who);
    }

    /// @dev Privileged function to de authorize an address
    /// @param who The address to remove authorization from
    function deauthorize(address who) external onlyOwner() {
        authorized[who] = false;
    }

    /// @dev Function to change owner
    /// @param who The new owner address
    function setOwner(address who) public onlyOwner() {
        owner = who;
    }

    /// @dev Inheritable function which authorizes someone
    /// @param who the address to authorize
    function _authorize(address who) internal {
        authorized[who] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "../libraries/NFTBoostVaultStorage.sol";

interface INFTBoostVault {
    /**
     * @notice Events
     */
    event MultiplierSet(address tokenAddress, uint128 tokenId, uint128 multiplier);
    event WithdrawalsUnlocked();

    /**
     * @notice View functions
     */
    function getIsLocked() external view returns (uint256);

    function getRegistration(address who) external view returns (NFTBoostVaultStorage.Registration memory);

    function getMultiplier(address tokenAddress, uint128 tokenId) external view returns (uint256);

    /**
     * @notice NFT boost vault functionality
     */
    function addNftAndDelegate(
        address user,
        uint128 amount,
        uint128 tokenId,
        address tokenAddress,
        address delegatee
    ) external;

    function delegate(address to) external;

    function withdraw(uint128 amount) external;

    function addTokens(uint128 amount) external;

    function withdrawNft() external;

    function updateNft(uint128 newTokenId, address newTokenAddress) external;

    function updateVotingPower(address[] memory userAddresses) external;

    /**
     * @notice Only Manager function
     */
    function setMultiplier(address tokenAddress, uint128 tokenId, uint128 multiplierValue) external;

    /**
     * @notice Only Timelock function
     */
    function unlock() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/INFTBoostVault.sol";

import { AA_ClaimingExpired, AA_AlreadyClaimed, AA_NonParticipant, AA_ZeroAddress } from "../errors/Airdrop.sol";

/**
 * @title Arcade Merkle Rewards
 * @author Non-Fungible Technologies, Inc.
 *
 * This contract validates merkle proofs and allows users to claim their airdrop. It is designed to
 * be inherited by other contracts. This contract does not have a way to transfer tokens out of it
 * or change the merkle root.
 *
 * As users claim their tokens, this contract will deposit them into a voting vault for use in
 * Arcade Governance. When claiming, the user can delegate voting power to themselves or another
 * account.
 */
contract ArcadeMerkleRewards {
    // ============================================ STATE ==============================================

    // =================== Immutable references =====================

    /// @notice the token to airdrop
    IERC20 public immutable token;
    /// @notice the expiration of the airdrop
    uint256 public immutable expiration;

    // ==================== Reward Claim State ======================

    /// @notice the merkle root with deposits encoded into it as hash [address, amount]
    bytes32 public rewardsRoot;

    /// @notice past user claims
    mapping(address => uint256) public claimed;

    /// @notice the locking vault to deposit tokens to
    INFTBoostVault public votingVault;

    // ========================================== CONSTRUCTOR ===========================================

    /**
     * @notice Initiate the contract with a merkle tree root, a token for distribution,
     *         an expiration time for claims, and the voting vault that tokens will be
     *         airdropped into.
     *
     * @param _rewardsRoot           The merkle root with deposits encoded into it as hash [address, amount]
     * @param _token                 The token to airdrop
     * @param _expiration            The expiration of the airdrop
     * @param _votingVault          The locking vault to deposit tokens to
     */
    constructor(bytes32 _rewardsRoot, IERC20 _token, uint256 _expiration, INFTBoostVault _votingVault) {
        if (_expiration <= block.timestamp) revert AA_ClaimingExpired();
        if (address(_token) == address(0)) revert AA_ZeroAddress();
        if (address(_votingVault) == address(0)) revert AA_ZeroAddress();

        rewardsRoot = _rewardsRoot;
        token = _token;
        expiration = _expiration;
        votingVault = _votingVault;
    }

    // ===================================== CLAIM FUNCTIONALITY ========================================

    /**
     * @notice Claims an amount of tokens in the tree and delegates to governance.
     *
     * @param delegate               The address the user will delegate to
     * @param totalGrant             The total amount of tokens the user was granted
     * @param merkleProof            The merkle proof showing the user is in the merkle tree
     */
    function claimAndDelegate(address delegate, uint256 totalGrant, bytes32[] calldata merkleProof) external {
        // must be before the expiration time
        if (block.timestamp > expiration) revert AA_ClaimingExpired();
        // no delegating to zero address
        if (delegate == address(0)) revert AA_ZeroAddress();
        // validate the withdraw
        _validateWithdraw(totalGrant, merkleProof);

        // approve the voting vault to transfer tokens
        token.approve(address(votingVault), totalGrant);
        // deposit tokens in voting vault for this msg.sender and delegate
        votingVault.addNftAndDelegate(msg.sender, uint128(totalGrant), 0, address(0), delegate);
    }

    // =========================================== HELPERS ==============================================

    /**
     * @notice Validate a withdraw attempt by checking merkle proof and ensuring the user has not
     *         previously withdrawn.
     *
     * @param totalGrant             The total amount of tokens the user was granted
     * @param merkleProof            The merkle proof showing the user is in the merkle tree
     */
    function _validateWithdraw(uint256 totalGrant, bytes32[] memory merkleProof) internal {
        // validate proof and leaf hash
        bytes32 leafHash = keccak256(abi.encodePacked(msg.sender, totalGrant));
        if (!MerkleProof.verify(merkleProof, rewardsRoot, leafHash)) revert AA_NonParticipant();

        // ensure the user has not already claimed the airdrop
        if (claimed[msg.sender] != 0) revert AA_AlreadyClaimed();
        claimed[msg.sender] = totalGrant;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title NFTBoostVaultStorage
 * @author Non-Fungible Technologies, Inc.
 *
 * Contract based on Council's `Storage.sol` with modified scope to match the NFTBoostVault
 * requirements. This library allows for secure storage pointers across proxy
 * implementations and will return storage pointers based on a hashed name and type string.
 */
library NFTBoostVaultStorage {
    /**
    * This library follows a pattern which if solidity had higher level
    * type or macro support would condense quite a bit.

    * Each basic type which does not support storage locations is encoded as
    * a struct of the same name capitalized and has functions 'load' and 'set'
    * which load the data and set the data respectively.

    * All types will have a function of the form 'typename'Ptr('name') -> storage ptr
    * which will return a storage version of the type with slot which is the hash of
    * the variable name and type string. This pointer allows easy state management between
    * upgrades and overrides the default solidity storage slot system.
    */

    /// @dev struct which represents 1 packed storage location (Registration)
    struct Registration {
        uint128 amount; // token amount
        uint128 latestVotingPower;
        uint128 withdrawn; // amount of tokens withdrawn from voting vault
        uint128 tokenId; // ERC1155 token id
        address tokenAddress; // the address of the ERC1155 token
        address delegatee;
    }

    /// @dev represents 1 packed storage location with a compressed uint128 pair
    struct AddressUintUint {
        uint128 tokenId;
        uint128 multiplier;
    }

    /**
     * @notice Returns the storage pointer for a named mapping of address to registration data
     *
     * @param name                      The variable name for the pointer.
     *
     * @return data                     The mapping pointer.
     */
    function mappingAddressToRegistrationPtr(
        string memory name
    ) internal pure returns (mapping(address => Registration) storage data) {
        bytes32 typehash = keccak256("mapping(address => Registration)");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }

    /**
     * @notice Returns the storage pointer for a named mapping of address to uint128 pair
     *
     * @param name                      The variable name for the pointer.
     *
     * @return data                     The mapping pointer.
     */
    function mappingAddressToPackedUintUint(
        string memory name
    ) internal pure returns (mapping(address => mapping(uint128 => AddressUintUint)) storage data) {
        bytes32 typehash = keccak256("mapping(address => mapping(uint128 => AddressUintUint))");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }
}