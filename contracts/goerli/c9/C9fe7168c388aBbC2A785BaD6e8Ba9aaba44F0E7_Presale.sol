/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

pragma solidity ^0.8.13;

// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

error SaleOngoing(uint256 current, uint256 ends);
error SaleNotStarted(uint256 current, uint256 start);
error SaleEnded(uint256 current, uint256 ends);
error InvalidProof();
error AlreadyInitialised();
error NotInitialised();
error AlreadyClaimed();
error ClaimsNotOpen();
error PaymentCalcUnderflow();
error NotPaymentToken();
error ModularError(uint120 by, uint120 remainder);

interface IERC20 {
    function balanceOf(address) external returns (uint256);
    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external;
}

interface IPresale {
    event Initialised();
    event ClaimRootSet(bytes32 indexed root);
    event BuyOrder(
        address indexed buyer,
        address indexed paymentToken,
        uint256 indexed payment,
        uint256 tokens
    );
    event Claim(
        address indexed buyer,
        uint256 indexed filledTokens,
        uint256 unusedUsdc,
        uint256 unusedUsdt,
        uint256 unusedDai
    );
}

// --------------------------------------------------------------------------------------
//
// Presale | SPDX-License-Identifier: MIT
// Authored by, DeGatchi (https://github.com/DeGatchi).
//
// --------------------------------------------------------------------------------------
contract Presale is IPresale, Ownable {
    /// Whether the contract's variables have been set.
    bool public initialised;

    /// Tokens being used as payment.
    address public immutable dai;
    address public immutable usdt;
    address public immutable usdc;
    /// Token being sold.
    IERC20 public immutable token;
    
    /// When the sale begins.
    uint40 public start;
    /// How long the sale goes for.
    uint40 public duration;
    /// Total amount of tokens for sale.
    uint120 public supply;
    /// Total amount of tokens ordered.
    uint120 public supplyOrdered;
    /// Price per token ($0.5)
    uint256 public price;

    /// Root used to set the claim statistics.
    bytes32 public claimRoot;

    struct Receipt {
        uint120 dai; // Total DAI used as payment (18 decimals).
        uint120 usdt; // Total USDT used as payment (6 decimals).
        uint120 usdc; // Total USDC used as payment (6 decimals).
        uint120 tokens; // Total presale tokens ordered.
        bool claimed; // Whether the order has been claimed.
    }

    /// A record of EOAs and their corresponding order receipts.
    mapping(address => Receipt) public receipt;

    /// Enable use when contract has initialised.
    modifier onlyInit() {
        if (!initialised) revert NotInitialised();
        _;
    }

    /// Enable use when the sale has finished.
    modifier onlyEnd() {
        if (block.timestamp < start + duration)
            revert SaleOngoing(block.timestamp, start + duration);
        _;
    }

    /// @notice Sets up the contract addresses as immutable for gas saving.
    /// @param _dai ERC20 USDC token being used as payment (has 18 decimals).
    /// @param _usdt ERC20 USDC token being used as payment (has 6 decimals).
    /// @param _usdc ERC20 USDC token being used as payment (has 6 decimals).
    /// @param _token ERC20 token being sold for `_usdc`.
    constructor(
        address _dai,
        address _usdt,
        address _usdc,
        address _token
    ) {
        dai = _dai;
        usdt = _usdt;
        usdc = _usdc;
        token = IERC20(_token);
    }

    /// @notice Sets up the sale.
    /// @dev Requires the initialiser to send `_supply` of `_token` to this address.
    /// @param _start Timestamp of when the sale begins.
    /// @param _duration How long the sale goes for.
    /// @param _supply The amount of `_token` being sold.
    /// @param _price The `_usdc` payment value of each `_token`.
    function initialise(
        uint40 _start,
        uint40 _duration,
        uint120 _supply,
        uint256 _price
    ) external onlyOwner {
        if (initialised) revert AlreadyInitialised();

        token.transferFrom(msg.sender, address(this), _supply);

        initialised = true;

        start = _start;
        duration = _duration;
        supply = _supply;
        price = _price;

        emit Initialised();
    }

    /// @notice Allows owner to update the claim root to enable `claim()`.
    /// @dev Used to update the `claimRoot` to enable claiming.
    /// @param _newRoot Merkle root used after sale has ended to allow buyers to claim their tokens.
    function setClaimRoot(bytes32 _newRoot) public onlyOwner onlyEnd {
        if (block.timestamp < start)
            revert SaleNotStarted(block.timestamp, start);
        claimRoot = _newRoot;
        emit ClaimRootSet(_newRoot);
    }

    /// @notice Allows users to create an order to purchase presale tokens w/ USDC.
    /// @dev The buy event is used for the backend bot to determine the orders.
    /// @param _tokens Amount of presale tokens to purchase (where 1 = 1 token).
    /// @param _paymentToken Token paying with.
    function createBuyOrder(uint120 _tokens, address _paymentToken)
        external
        onlyInit
    {
        // Make sure the sale is ongoing.
        uint40 _start = start;
        if (block.timestamp < _start) revert SaleNotStarted(block.timestamp, _start);
        if (block.timestamp >= _start + duration) revert SaleEnded(block.timestamp, _start + duration);

        // Make sure they're buying a whole number of tokens.
        if (_tokens % 1e18 != 0) revert ModularError(1e18, _tokens % 1e18);

        // Calculate and record payment.
        uint256 _payment = (_tokens * price) / 1e18;
        Receipt storage _receipt = receipt[msg.sender];
        if (_paymentToken == dai) {
            _payment = (_tokens * (price * 1e12)) / 1e18;
            _receipt.dai += uint120(_payment);
        } else if (_paymentToken == usdt) {
            _receipt.usdt += uint120(_payment);
        } else if (_paymentToken == usdc) {
            _receipt.usdc += uint120(_payment);
        } else revert NotPaymentToken();

        // Failsale sanity check.
        if (_payment == 0) revert PaymentCalcUnderflow();

        // Send payment to this contract.
        IERC20(_paymentToken).transferFrom(msg.sender, address(this), _payment);

        // Record tokens bought.
        _receipt.tokens += _tokens;
        supplyOrdered += _tokens;

        // Record order for backend calculation.
        emit BuyOrder(msg.sender, _paymentToken, _payment, _tokens);
    }

    /// @notice When sale ends, users can redeem their allocation w/ the filler bot's output.
    /// @dev Set owner as the treasury claimer to receive all used USDC + unsold tokens.
    ///      E.g, 90/100 tokens sold for 45 usdc paid; owner claims 10 tokens + 45 USDC.
    /// @param _claimer The EOA claiming on behalf for by the caller.
    /// @param _filledTokens Total presale tokens being sent to `_claimer`.
    /// @param _unusedUsdc Total USDC tokens, that weren't used to buy `token`, being sent to `_claimer`.
    /// @param _unusedUsdt Total USDT tokens, that weren't used to buy `token`, being sent to `_claimer`.
    /// @param _unusedDai Total DAI tokens, that weren't used to buy `token`, being sent to `_claimer`.
    /// @param _proof Merkle tree verification path.
    function claim(
        address _claimer,
        uint120 _filledTokens,
        uint120 _unusedUsdc,
        uint120 _unusedUsdt,
        uint120 _unusedDai,
        bytes32[] memory _proof
    ) external onlyInit onlyEnd {
        if (claimRoot == bytes32(0)) revert ClaimsNotOpen();

        Receipt storage _receipt = receipt[_claimer];
        if (_receipt.claimed) revert AlreadyClaimed();

        bytes32 node = keccak256(
            abi.encode(
                _claimer,
                _filledTokens,
                _unusedUsdc,
                _unusedUsdt,
                _unusedDai
            )
        );
        if (!MerkleProof.verify(_proof, claimRoot, node)) revert InvalidProof();

        _receipt.claimed = true;

        if (_filledTokens > 0) token.transfer(_claimer, _filledTokens);
        if (_unusedUsdc > 0) IERC20(usdc).transfer(_claimer, _unusedUsdc);
        if (_unusedUsdt > 0) IERC20(usdt).transfer(_claimer, _unusedUsdt);
        if (_unusedDai > 0) IERC20(dai).transfer(_claimer, _unusedDai);

        emit Claim(
            _claimer,
            _filledTokens,
            _unusedUsdc,
            _unusedUsdt,
            _unusedDai
        );
    }
}