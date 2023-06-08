// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.15;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./TransferHelper.sol";
import "../access/AccessControl.sol";
import "../interfaces/ITokenUpgrade.sol";
import "../utils/Cast.sol";
import "../utils/Math.sol";

/*  
    By signing this Release and clicking "I Agree" on the web interface at https://yieldprotocol.com/ and accessing 
    the smart contract to redeem my [existing LP Tokens] for [updated LP Tokens], I and any protocol I represent hereby 
    irrevocably and unconditionally release all claims I and any protocol I represent (or other separate related or 
    affiliated legal entities) ("Releasing Parties") may have against Yield, Inc. and any of its agents, affiliates, 
    officers, employees, or principals ("Released Parties") related to this matter whether such claims are known or 
    unknown at this time and regardless of how such claims arise and the laws governing such claims (which shall include 
    but not be limited to any claims arising out of Yield Protocol's terms of use). This release constitutes an express 
    and voluntary binding waiver and relinquishment to the fullest extent permitted by law. Releasing Parties further 
    agree to indemnify the Released Parties from any and all third-party claims arising or related to this matter, including
    damages, attorneys' fees, and any other costs related to those claims. If I am acting for or on behalf of a company 
    (or other such separate related or affiliated legal entity), by signing this Release, clicking "I Agree" on the web 
    interface at https://yieldprotocol.com/ or executing the smart contract and accepting the redemption, I confirm that I 
    am duly authorized to enter into this contract on its behalf. I and any Releasing Parties I represent further acknowledge 
    and agree that the Released Parties are not the issuer of the [updated LP Tokens] that I may redeem through the smart 
    contracts accessible at https://yieldprotocol.com/, the Released Parties are not issuing such [updated LP Token] to me, 
    and I have no expectations from or rights with respect to any Released Party with respect to the [updated LP Token]. This 
    agreement and all disputes relating to or arising under this agreement (including the interpretation, validity or 
    enforcement thereof) will be governed by and subject to Yield, Inc.'s Terms of Service, including, but not limited to, the 
    Limitation of Liability, Dispute Resolution by Binding Arbitration, and General provisions within the Terms of Service. 
    To the extent that the terms of this release are inconsistent with any previous agreement and/or Yield, Inc.'s Terms of 
    Service, I accept that these terms take priority and, where necessary, replace the previous terms.
*/

/// @dev TokenUpgrade is a contract that can be used upgrade tokens at a fixed rate, with
/// the aim of completely replacing the supply of a token by the funds supplied to
/// this contract. It is meant to be used as a token upgrade, when other mechanisms fail.
/// @dev This contract is currently under audit and not eligible for any bounties.
contract TokenUpgrade is AccessControl {
    using Cast for uint256;
    using Math for uint256;
    using TransferHelper for IERC20;

    error SameToken(address token);
    error TokenInNotRegistered(address tokenIn);
    error TokenInAlreadyRegistered(address tokenIn);
    error TokenOutNotRegistered(address tokenOut);
    error TokenOutAlreadyRegistered(address tokenOut);
    error InvalidAcceptanceToken();
    error AlreadyClaimed();
    error NotInMerkleTree();

    event Registered(
        IERC20 indexed tokenIn, 
        IERC20 indexed tokenOut, 
        uint256 tokenInBalance, 
        uint256 tokenOutBalance, 
        uint96 ratio, 
        bytes32 merkleRoot
    );
    event Unregistered(
        IERC20 indexed tokenIn, 
        IERC20 indexed tokenOut, 
        uint256 tokenInBalance, 
        uint256 tokenOutBalance
    );
    event Upgraded(
        IERC20 indexed tokenIn, 
        IERC20 indexed tokenOut, 
        uint256 tokenInAmount, 
        uint256 tokenOutAmount
    );
    event Extracted(IERC20 indexed tokenIn, uint256 tokenInBalance);
    event Recovered(IERC20 indexed token, uint256 recovered);

    struct TokenIn {
        IERC20 reverse;
        uint96 ratio;
        uint256 balance;
        bytes32 merkleRoot;
    }

    struct TokenOut {
        IERC20 reverse;
        uint256 balance;
    }

    // Hash of the above terms of service
    bytes32 tosHash = 0x9f6699a0964b1bd6fe6c9fb8bebea236c08311ddd25781bbf5d372d00d32936b;

    mapping(IERC20 => TokenIn) public tokensIn;
    mapping(IERC20 => TokenOut) public tokensOut;
    mapping(bytes32 => bool) public isClaimed;

    /// @dev Register a token to be replaced, and the token to replace it with.
    /// The ratio is calculated as the funds of the replacement token divided by the supply of the token to be replaced.
    /// The tokens used as a replacement must have been sent to the contract before this call.
    /// @param tokenIn_ The token to be replaced
    /// @param tokenOut_ The token to replace it with
    /// @param merkleRoot_ the root of the merkle tree for tokenIn_
    function register(IERC20 tokenIn_, IERC20 tokenOut_, bytes32 merkleRoot_) external auth {
        if (address(tokenIn_) == address(tokenOut_)) revert SameToken(address(tokenIn_));
        if (address(tokensIn[tokenIn_].reverse) != address(0)) revert TokenInAlreadyRegistered(address(tokenIn_));
        if (address(tokensOut[tokenOut_].reverse) != address(0)) revert TokenOutAlreadyRegistered(address(tokenOut_));

        uint96 ratio = tokenOut_.balanceOf(address(this)).wdiv(tokenIn_.totalSupply()).u96();
        uint256 tokenInBalance = tokenIn_.balanceOf(address(this));
        uint256 tokenOutBalance = tokenOut_.balanceOf(address(this));
        tokensIn[tokenIn_] = TokenIn(tokenOut_, ratio, tokenInBalance, merkleRoot_);
        tokensOut[tokenOut_] = TokenOut(tokenIn_, tokenOutBalance);

        emit Registered(tokenIn_, tokenOut_, tokenInBalance, tokenOutBalance, ratio, merkleRoot_);
    }

    /// @dev Unregister a token to be replaced, and the token to replace it with. Send all related tokens to a given address.
    /// @param tokenIn_ The token to be replaced
    /// @param to The address to send all tokens to
    function unregister(IERC20 tokenIn_, address to) external auth {
        TokenIn memory tokenIn = tokensIn[tokenIn_];
        if (address(tokenIn.reverse) == address(0)) revert TokenInNotRegistered(address(tokenIn_));
        IERC20 tokenOut_ = tokenIn.reverse;

        delete tokensIn[tokenIn_];
        delete tokensOut[tokenOut_];

        // We send all related funds to the given address to make sure it's a clean sweep, not just the tracked balances.
        uint256 tokenInBalance = tokenIn_.balanceOf(address(this));
        uint256 tokenOutBalance = tokenOut_.balanceOf(address(this));
        tokenIn_.safeTransfer(to, tokenInBalance);
        tokenOut_.safeTransfer(to, tokenOutBalance);

        emit Unregistered(tokenIn_, tokenOut_, tokenInBalance, tokenOutBalance);
    }

    /// @dev Extract tokens replaced by this contract.
    /// @param tokenIn_ The token to be replaced
    /// @param to The address to send the tokens to
    function extract(IERC20 tokenIn_, address to) external auth {
        TokenIn memory tokenIn = tokensIn[tokenIn_];
        if (address(tokenIn.reverse) == address(0)) revert TokenInNotRegistered(address(tokenIn_));

        tokensIn[tokenIn_].balance = 0;
        tokenIn_.safeTransfer(to, tokenIn.balance);

        emit Extracted(tokenIn_, tokenIn.balance);
    }

    /// @dev Recover tokens deposited to the contract by mistake
    /// Be careful, the address passed on as a token is not verified to be a valid ERC20 token.
    /// @param token The token to be recovered
    /// @param to The address to send the tokens to
    function recover(IERC20 token, address to) external auth {
        if (address(tokensIn[token].reverse) != address(0)) revert TokenInAlreadyRegistered(address(token));
        if (address(tokensOut[token].reverse) != address(0)) revert TokenOutAlreadyRegistered(address(token));
        uint256 recovered = token.balanceOf(address(this));
        token.safeTransfer(to, recovered);

        emit Recovered(token, recovered);
    }

    /// @dev Upgrade a token for its replacement, at the registered ratio.
    /// The rounding for tokenOutAmount means that the TokenUpgrade contract
    /// gets the left over wei.
    /// @param tokenIn_ The token to be replaced
    /// @param acceptanceToken The acceptance token for the terms of service
    /// @param from The owner of tokenIn_
    /// @param tokenInAmount The amount of tokenIn_ to upgrade
    /// @param proof The merkle proof to verify the upgrade
    function upgrade(IERC20 tokenIn_, bytes32 acceptanceToken, address from, uint256 tokenInAmount, bytes32[] calldata proof)
        external
    {
        if (acceptanceToken != keccak256(abi.encodePacked(from, tosHash))) revert InvalidAcceptanceToken();

        TokenIn memory tokenIn = tokensIn[tokenIn_];
        if (address(tokenIn.reverse) == address(0)) revert TokenInNotRegistered(address(tokenIn_));
        IERC20 tokenOut_ = tokenIn.reverse;

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(from, tokenInAmount))));
        if (isClaimed[leaf]) revert AlreadyClaimed();
        isClaimed[leaf] = true;
        bool isValidLeaf = MerkleProof.verifyCalldata(proof, tokenIn.merkleRoot, leaf);
        if (!isValidLeaf) revert NotInMerkleTree();

        tokenIn_.safeTransferFrom(from, address(this), tokenInAmount);
        uint256 tokenOutAmount = tokenInAmount.wmul(tokenIn.ratio);

        tokensIn[tokenIn_].balance += tokenInAmount;
        tokensOut[tokenOut_].balance -= tokenOutAmount;

        tokenOut_.safeTransfer(from, tokenOutAmount);

        emit Upgraded(tokenIn_, tokenOut_, tokenInAmount, tokenOutAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
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
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
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
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/Uniswap/uniswap-lib/blob/master/src/libraries/TransferHelper.sol
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../utils/RevertMsgExtractor.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
// USDT is a well known token that returns nothing for its transfer, transferFrom, and approve functions
// and part of the reason this library exists
library TransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        if (!(success && _returnTrueOrNothing(data))) revert(RevertMsgExtractor.getRevertMsg(data));
    }

    /// @notice Approves a spender to transfer tokens from msg.sender
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param token The contract address of the token which will be approved
    /// @param spender The approved spender
    /// @param value The value of the allowance
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.approve.selector, spender, value));
        if (!(success && _returnTrueOrNothing(data))) revert(RevertMsgExtractor.getRevertMsg(data));
    }

    /// @notice Transfers tokens from the targeted address to the given destination
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        if (!(success && _returnTrueOrNothing(data))) revert(RevertMsgExtractor.getRevertMsg(data));
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Errors with the underlying revert message if transfer fails
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address payable to, uint256 value) internal {
        (bool success, bytes memory data) = to.call{value: value}(new bytes(0));
        if (!success) revert(RevertMsgExtractor.getRevertMsg(data));
    }

    function _returnTrueOrNothing(bytes memory data) internal pure returns(bool) {
        return (data.length == 0 || abi.decode(data, (bool)));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IAccessControl } from "./IAccessControl.sol";
import { IERC20 } from "../token/IERC20.sol";

interface ITokenUpgrade is IAccessControl {
    struct TokenIn {
        IERC20 reverse;
        uint96 ratio;
        uint256 balance;
    }

    struct TokenOut {
        IERC20 reverse;
        uint256 balance;     
    }

    function tokensIn(IERC20 tokenIn) external view returns (TokenIn memory);
    function tokensOut(IERC20 tokenOut) external view returns (TokenOut memory);
    function register(IERC20 tokenIn, IERC20 tokenOut) external;
    function unregister(IERC20 tokenIn, address to) external;
    function swap(IERC20 tokenIn, address to) external;
    function extract(IERC20 tokenIn, address to) external;
    function recover(IERC20 token, address to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes4` identifier. These are expected to be the 
 * signatures for all the functions in the contract. Special roles should be exposed
 * in the external API and be unique:
 *
 * ```
 * bytes4 public constant ROOT = 0x00000000;
 * ```
 *
 * Roles represent restricted access to a function call. For that purpose, use {auth}:
 *
 * ```
 * function foo() public auth {
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `ROOT`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {setRoleAdmin}.
 *
 * WARNING: The `ROOT` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
contract AccessControl {
    struct RoleData {
        mapping (address => bool) members;
        bytes4 adminRole;
    }

    mapping (bytes4 => RoleData) private _roles;

    bytes4 public constant ROOT = 0x00000000;
    bytes4 public constant ROOT4146650865 = 0x00000000; // Collision protection for ROOT, test with ROOT12007226833()
    bytes4 public constant LOCK = 0xFFFFFFFF;           // Used to disable further permissioning of a function
    bytes4 public constant LOCK8605463013 = 0xFFFFFFFF; // Collision protection for LOCK, test with LOCK10462387368()

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role
     *
     * `ROOT` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes4 indexed role, bytes4 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call.
     */
    event RoleGranted(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Give msg.sender the ROOT role and create a LOCK role with itself as the admin role and no members. 
     * Calling setRoleAdmin(msg.sig, LOCK) means no one can grant that msg.sig role anymore.
     */
    constructor () {
        _grantRole(ROOT, msg.sender);   // Grant ROOT to msg.sender
        _setRoleAdmin(LOCK, LOCK);      // Create the LOCK role by setting itself as its own admin, creating an independent role tree
    }

    /**
     * @dev Each function in the contract has its own role, identified by their msg.sig signature.
     * ROOT can give and remove access to each function, lock any further access being granted to
     * a specific action, or even create other roles to delegate admin control over a function.
     */
    modifier auth() {
        require (_hasRole(msg.sig, msg.sender), "Access denied");
        _;
    }

    /**
     * @dev Allow only if the caller has been granted the admin role of `role`.
     */
    modifier admin(bytes4 role) {
        require (_hasRole(_getRoleAdmin(role), msg.sender), "Only admin");
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes4 role, address account) external view returns (bool) {
        return _hasRole(role, account);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes4 role) external view returns (bytes4) {
        return _getRoleAdmin(role);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.

     * If ``role``'s admin role is not `adminRole` emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setRoleAdmin(bytes4 role, bytes4 adminRole) external virtual admin(role) {
        _setRoleAdmin(role, adminRole);
    }

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
    function grantRole(bytes4 role, address account) external virtual admin(role) {
        _grantRole(role, account);
    }

    
    /**
     * @dev Grants all of `role` in `roles` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function grantRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _grantRole(roles[i], account);
        }
    }

    /**
     * @dev Sets LOCK as ``role``'s admin role. LOCK has no members, so this disables admin management of ``role``.

     * Emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function lockRole(bytes4 role) external virtual admin(role) {
        _setRoleAdmin(role, LOCK);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes4 role, address account) external virtual admin(role) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes all of `role` in `roles` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function revokeRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _revokeRole(roles[i], account);
        }
    }

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
    function renounceRole(bytes4 role, address account) external virtual {
        require(account == msg.sender, "Renounce only for self");

        _revokeRole(role, account);
    }

    function _hasRole(bytes4 role, address account) internal view returns (bool) {
        return _roles[role].members[account];
    }

    function _getRoleAdmin(bytes4 role) internal view returns (bytes4) {
        return _roles[role].adminRole;
    }

    function _setRoleAdmin(bytes4 role, bytes4 adminRole) internal virtual {
        if (_getRoleAdmin(role) != adminRole) {
            _roles[role].adminRole = adminRole;
            emit RoleAdminChanged(role, adminRole);
        }
    }

    function _grantRole(bytes4 role, address account) internal {
        if (!_hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes4 role, address account) internal {
        if (_hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

library Cast {
    ///@dev library for safe casting of value types

    function b12(bytes32 x) internal pure returns (bytes12 y) {
        require(bytes32(y = bytes12(x)) == x, "Cast overflow");
    }

    function b6(bytes32 x) internal pure returns (bytes6 y) {
        require(bytes32(y = bytes6(x)) == x, "Cast overflow");
    }

    function u256(int256 x) internal pure returns (uint256 y) {
        require(x >= 0, "Cast overflow");
        y = uint256(x);
    }

    function i256(uint256 x) internal pure returns (int256 y) {
        require(x <= uint256(type(int256).max), "Cast overflow");
        y = int256(x);
    }

    function u128(uint256 x) internal pure returns (uint128 y) {
        require(x <= type(uint128).max, "Cast overflow");
        y = uint128(x);
    }

    function u128(int256 x) internal pure returns (uint128 y) {
        require(x >= 0, "Cast overflow");
        y = uint128(uint256(x));
    }

    function i128(uint256 x) internal pure returns (int128) {
        require(x <= uint256(int256(type(int128).max)), "Cast overflow");
        return int128(int256(x));
    }

    function i128(int256 x) internal pure returns (int128) {
        require(x <= type(int128).max, "Cast overflow");
        require(x >= type(int128).min, "Cast overflow");
        return int128(x);
    }

    function u112(uint256 x) internal pure returns (uint112 y) {
        require(x <= type(uint112).max, "Cast overflow");
        y = uint112(x);
    }

    function u104(uint256 x) internal pure returns (uint104 y) {
        require(x <= type(uint104).max, "Cast overflow");
        y = uint104(x);
    }

    function u96(uint256 x) internal pure returns (uint96 y) {
        require(x <= type(uint96).max, "Cast overflow");
        y = uint96(x);
    }

    function u32(uint256 x) internal pure returns (uint32 y) {
        require(x <= type(uint32).max, "Cast overflow");
        y = uint32(x);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

library Math {
    // Taken from https://github.com/usmfum/USM/blob/master/src/WadMath.sol
    /// @dev Multiply an amount by a fixed point factor with 18 decimals, rounds down.
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        unchecked {
            z /= 1e18;
        }
    }

    // Taken from https://github.com/usmfum/USM/blob/master/src/WadMath.sol
    /// @dev Multiply x and y, with y being fixed point. If both are integers, the result is a fixed point factor. Rounds up.
    function wmulup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y + 1e18 - 1; // Rounds up.  So (again imagining 2 decimal places):
        unchecked {
            z /= 1e18;
        } // 383 (3.83) * 235 (2.35) -> 90005 (9.0005), + 99 (0.0099) -> 90104, / 100 -> 901 (9.01).
    }

    // Taken from https://github.com/usmfum/USM/blob/master/src/WadMath.sol
    /// @dev Divide an amount by a fixed point factor with 18 decimals
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * 1e18) / y;
    }

    // Taken from https://github.com/usmfum/USM/blob/master/src/WadMath.sol
    /// @dev Divide x and y, with y being fixed point. If both are integers, the result is a fixed point factor. Rounds up.
    function wdivup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * 1e18 + y; // 101 (1.01) / 1000 (10) -> (101 * 100 + 1000 - 1) / 1000 -> 11 (0.11 = 0.101 rounded up).
        unchecked {
            z -= 1;
        } // Can do unchecked subtraction since division in next line will catch y = 0 case anyway
        z /= y;
    }

    // Taken from https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol
    /// @dev $x ^ $n; $x is 18-decimals fixed point number
    function wpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        uint256 baseUnit = 1e18;
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := baseUnit
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store baseUnit in z for now.
                    z := baseUnit
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, baseUnit)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) { revert(0, 0) }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) { revert(0, 0) }

                    // Set x to scaled xxRound.
                    x := div(xxRound, baseUnit)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) { revert(0, 0) }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) { revert(0, 0) }

                        // Return properly scaled zxRound.
                        z := div(zxRound, baseUnit)
                    }
                }
            }
        }
    }

    /// @dev Divide an amount by a fixed point factor with 27 decimals
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * 1e27) / y;
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
// Taken from https://github.com/sushiswap/BoringSolidity/blob/441e51c0544cf2451e6116fe00515e71d7c42e2c/src/BoringBatchable.sol

pragma solidity >=0.6.0;


library RevertMsgExtractor {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function getRevertMsg(bytes memory returnData)
        internal pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            returnData := add(returnData, 0x04)
        }
        return abi.decode(returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IAccessControl {
    struct RoleData {
        mapping (address => bool) members;
        bytes4 adminRole;
    }

    event RoleAdminChanged(bytes4 indexed role, bytes4 indexed newAdminRole);
    event RoleGranted(bytes4 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes4 indexed role, address indexed account, address indexed sender);

    function ROOT() external view returns (bytes4);
    function LOCK() external view returns (bytes4);
    function hasRole(bytes4 role, address account) external view returns (bool);
    function getRoleAdmin(bytes4 role) external view returns (bytes4);
    function setRoleAdmin(bytes4 role, bytes4 adminRole) external;
    function grantRole(bytes4 role, address account) external;
    function grantRoles(bytes4[] memory roles, address account) external;
    function lockRole(bytes4 role) external;
    function revokeRole(bytes4 role, address account) external;
    function revokeRoles(bytes4[] memory roles, address account) external;
    function renounceRole(bytes4 role, address account) external;
}