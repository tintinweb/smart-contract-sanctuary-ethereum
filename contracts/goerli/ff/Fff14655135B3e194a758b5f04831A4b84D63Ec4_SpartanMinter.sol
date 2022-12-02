// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///@notice access control
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/ISpartan721A.sol";


/* 
    @title Spartan Minting Function
    @notice ERC721-ready Spartan contract
    @author cryptoware.eth | Spartan
*/
contract SpartanMinter is Ownable, ReentrancyGuard{

    /// @notice the spartan 1155 initial contract
    address payable private spartan721AContract;
    /// @notice the mint price of each NFT
    uint256 public mintPrice;
    /// @notice the minimum price of ethereum in dollars
    uint256 private minEthPriceInDollars;
    /// @notice the maximum price of etherum in dollars
    uint256 private maxEthPriceInDollars;
    /// @notice root of the new Merkle tree
    bytes32 private _merkleRoot;
    /// @notice mapping mints per user
    mapping(address => uint256) mintsPerUser;
    /// @notice mapping for mintIdUsed
    mapping(bytes16 => bool) mintId;


    /// @notice Mint event to be emitted upon NFT mint
    event Minted(
        address indexed to,
        uint256 indexed startToken,
        uint256 quantity
    );

    /// @notice Event that indicates which mint id has been used during minting
    event MintIdUsed(bytes16 indexed mintId);


    /**
     * @notice contructor
     * @param spartan721AContract_ the address of the spartan contract used for minting
     * @param minEthPriceInDollars_ the minimum eth price in dollars that the contract will be able to accept
     * @param maxEthPriceInDollars_ the maximum eth price in dollars that the contract will be able to accept
     * @param mintPrice_ the mint price of the Spartan NFT
     * @param root_ is the verification proof showing that the user is capable of minting
     */
    constructor(
        address payable spartan721AContract_,
        uint256 minEthPriceInDollars_,
        uint256 maxEthPriceInDollars_,
        uint256 mintPrice_,
        bytes32 root_
    ) Ownable() {
      spartan721AContract = spartan721AContract_;
      minEthPriceInDollars = minEthPriceInDollars_;
      maxEthPriceInDollars = maxEthPriceInDollars_;
      mintPrice = mintPrice_;
      _merkleRoot = root_;
    }

    /**
     * @notice mints tokens based on parameters
     * @param to address of the user minting
     * @param proof_ verify if msg.sender is allowed to mint
     * @param mintId_ mint id used to mint
     * @param currentEthPrice the current ehtereum price in dollars
     **/
    function mint(
        address to,
        bytes32[] memory proof_,
        bytes16 mintId_,
        uint256 currentEthPrice
    ) external payable nonReentrant{
        // The received wei the minter sent
        uint256 received = msg.value;
        // The dollars being sent 
        uint256 dollarsExpected = mintPrice;
        // The minimum price of the nft willing to be passed (Dollars)
        uint256 minDollarsExpected = dollarsExpected-(dollarsExpected/100);
        // The maximum price of the nft willing to be passed (Dollars)
        uint256 maxDollarsExpected = dollarsExpected+(dollarsExpected/100); //Dollar
        // The user address cannot be equal to zero
        require(to != address(0), "SPTN: Address cannot be 0");
        // The minimum price of ethereum in dollars that can be sendt as a currentEthPrice
        require(currentEthPrice>= minEthPriceInDollars, "SPTN: Invalid ETH Price");
        // The maximum price of ethereum in dollars that can be sent as a currentEthPrice
        require(currentEthPrice<= maxEthPriceInDollars, "SPTN: Invalid ETH Price");
        // Check if the msg.value sent by the user is less than the minimum set by the 
        require(
            minDollarsExpected <= (received*currentEthPrice/1000000000000000000), //Dollar
            "SPTN: Dollars sent is less than the minimum"
        );
        require(
            (received*currentEthPrice/1000000000000000000)<=maxDollarsExpected, //Dollar
            "SPTN: Dollars sent is more than the maximum"
        );
        require(
            ISpartan721A(spartan721AContract).totalSupply()+1 <= ISpartan721A(spartan721AContract).maxId(),
            "SPTN: max SPARTAN token limit exceeded"
        );
        require(
            ISpartan721A(spartan721AContract).mintsPerUser(to) + 1 <= ISpartan721A(spartan721AContract).mintingLimit(),
            "SPTN: Max NFT per address exceeded"
        );
        require(!ISpartan721A(spartan721AContract).mintId(mintId_), "SPTN: mint id already used");
        require(!mintId[mintId_], "SPTN: mint id already used");
        _merkleRoot > bytes32(0) && isAllowedToMint(proof_, mintId_);
        mintsPerUser[to] = ISpartan721A(spartan721AContract).mintsPerUser(to) + 1;
        mintId[mintId_] = true;

        ISpartan721A(spartan721AContract).adminMint(to, 1);

        spartan721AContract.transfer(msg.value);

        emit MintIdUsed(mintId_);
    }

    /**
     * @notice the public function validating addresses
     * @param proof_ hashes validating that a leaf exists inside merkle tree aka _merkleRoot
     * @param mintId_ Id sent from the db to check it this token number is minted or not
     **/
    function isAllowedToMint(bytes32[] memory proof_, bytes16 mintId_)
        internal
        view
        returns (bool)
    {
        require(
            MerkleProof.verify(
                proof_,
                _merkleRoot,
                keccak256(abi.encodePacked(mintId_))
            ),
            "SPTN: Please register before minting"
        );
        return true;
    }

    /**
     * @notice changes merkleRoot in case whitelist list updated
     * @param merkleRoot_ root of the Merkle tree
     **/

    function changeMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        require(
            merkleRoot_ != _merkleRoot,
            "SPTN: Merkle root cannot be same as previous"
        );
        _merkleRoot = merkleRoot_;
    }

    /**
     * @notice changes the minEthPrice in dollars
     * @param minEthPrice_  min price of eth
     **/
    function changeMinEthPrice(uint256 minEthPrice_) external onlyOwner {
        require(
            minEthPriceInDollars != minEthPrice_, 
            "SPTN: Min ETH Price should be different than the previous price"
        );
        minEthPriceInDollars = minEthPrice_;
    }

    /**
     * @notice changes the minEthPrice in dollars
     * @param maxEthPrice_  min price of eth
     **/
    function changeMaxEthPrice(uint256 maxEthPrice_) external onlyOwner {
        require(
            maxEthPriceInDollars != maxEthPrice_, 
            "SPTN: Max ETH Price should be different than the previous price"
        );
        maxEthPriceInDollars = maxEthPrice_;
    }

    /**
     * @notice changes the mint price of an already existing token ID
     * @param mintPrice_ new mint price of token
     **/
    function changeMintPriceOfToken(uint256 mintPrice_) external onlyOwner {
        require(
            mintPrice_ != mintPrice,
            "SPTN: Mint Price should be different than the previous price"
        );
        mintPrice = mintPrice_;
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @dev This is an interface whereby we can interact with the base ERC20 contract
interface ISpartan721A {
    function totalSupply() external returns(uint256);
    function maxId() external returns(uint256);
    function mintsPerUser(address user) external returns(uint256);
    function mintingLimit() external returns(uint256);
    function mintId(bytes16 mintId_) external returns (bool);
    function adminMint(address user, uint256 amount) external;

}