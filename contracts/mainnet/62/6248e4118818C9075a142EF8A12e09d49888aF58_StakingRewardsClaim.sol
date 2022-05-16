// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.13;

import { MerkleProof } from "@openzeppelin/contracts-4.6.0/utils/cryptography/MerkleProof.sol";
import { IERC20 } from "@openzeppelin/contracts-4.6.0/token/ERC20/IERC20.sol";

interface ITokenGovernance {
    function token() external view returns (IERC20);

    function mint(address to, uint256 amount) external;
}

interface IBancorNetworkV3 {
    function depositFor(
        address provider,
        address pool,
        uint256 tokenAmount
    ) external payable returns (uint256);
}

/**
 * @dev this contract allows claiming/staking V2.1 pending rewards
 */
contract StakingRewardsClaim {
    error AccessDenied();
    error AlreadyClaimed();
    error InvalidAddress();
    error InvalidClaim();
    error ZeroValue();

    // the V3 network contract
    IBancorNetworkV3 private immutable _networkV3;

    // the address of the BNT token governance
    ITokenGovernance private immutable _bntGovernance;

    // the address of the BNT token
    IERC20 private immutable _bnt;

    // the merkle root of the pending rewards merkle tree
    bytes32 private immutable _merkleRoot;

    // the total claimed amount
    uint256 private _totalClaimed;

    // a mapping of providers which have already claimed their rewards
    mapping(address => bool) private _claimed;

    /**
     * @dev triggered when rewards are claimed
     */
    event RewardsClaimed(address indexed provider, uint256 amount);

    /**
     * @dev triggered when rewards are staked
     */
    event RewardsStaked(address indexed provider, uint256 amount);

    modifier validAddress(address addr) {
        _validAddress(addr);

        _;
    }

    modifier greaterThanZero(uint256 value) {
        _greaterThanZero(value);

        _;
    }

    /**
     * @dev initializes the merkle-tree rewards airdrop contract
     */
    constructor(
        IBancorNetworkV3 initNetworkV3,
        ITokenGovernance initBNTGovernance,
        bytes32 initMerkleRoot
    ) validAddress(address(initNetworkV3)) validAddress(address(initBNTGovernance)) {
        _networkV3 = initNetworkV3;
        _bntGovernance = initBNTGovernance;
        _bnt = initBNTGovernance.token();

        _merkleRoot = initMerkleRoot;
    }

    /**
     * @dev returns the merkle root of the pending rewards merkle tree
     */
    function merkleRoot() external view returns (bytes32) {
        return _merkleRoot;
    }

    /**
     * @dev returns the total claimed amount
     */
    function totalClaimed() external view returns (uint256) {
        return _totalClaimed;
    }

    /**
     * @dev returns whether providers have already claimed their rewards
     */
    function hasClaimed(address account) external view returns (bool) {
        return _claimed[account];
    }

    /**
     * @dev claims rewards by providing a merkle proof (a { provider, amount } leaf and a merkle path)
     *
     * requirements:
     *
     * - the claim can be only made by the beneficiary of the reward
     */
    function claimRewards(
        address provider,
        uint256 fullAmount,
        bytes32[] calldata proof
    ) external greaterThanZero(fullAmount) {
        _claimRewards(msg.sender, provider, fullAmount, proof, false);
    }

    /**
     * @dev claims rewards by providing a merkle proof (a { provider, amount } leaf and a merkle path) and stakes them
     * in V3
     *
     * requirements:
     *
     * - the claim can be only made by the beneficiary of the reward
     */
    function stakeRewards(
        address provider,
        uint256 fullAmount,
        bytes32[] calldata proof
    ) external greaterThanZero(fullAmount) {
        _claimRewards(msg.sender, provider, fullAmount, proof, true);
    }

    /**
     * @dev claims or stakes rewards
     */
    function _claimRewards(
        address caller,
        address provider,
        uint256 fullAmount,
        bytes32[] calldata proof,
        bool stake
    ) private {
        // allow users to opt-it for receiving their rewards
        if (caller != provider) {
            revert AccessDenied();
        }

        // ensure that the user can't claim or stake rewards twice
        if (_claimed[provider]) {
            revert AlreadyClaimed();
        }

        // ensure that the claim is valid
        bytes32 leaf = keccak256(abi.encodePacked(provider, fullAmount));
        if (!MerkleProof.verify(proof, _merkleRoot, leaf)) {
            revert InvalidClaim();
        }

        _claimed[provider] = true;
        _totalClaimed += fullAmount;

        if (stake) {
            // mint the full rewards to the contract itself and deposit them on behalf of the provider
            _bntGovernance.mint(address(this), fullAmount);

            _bnt.approve(address(_networkV3), fullAmount);
            _networkV3.depositFor(provider, address(_bnt), fullAmount);

            emit RewardsStaked(provider, fullAmount);
        } else {
            // mint the rewards directly to the provider
            _bntGovernance.mint(provider, fullAmount);

            emit RewardsClaimed(provider, fullAmount);
        }
    }

    /**
     * @dev verifies that a given address is valid
     */
    function _validAddress(address addr) internal pure {
        if (addr == address(0)) {
            revert InvalidAddress();
        }
    }

    /**
     * @dev verifies that a given amount is greater than zero
     */
    function _greaterThanZero(uint256 value) internal pure {
        if (value == 0) {
            revert ZeroValue();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
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