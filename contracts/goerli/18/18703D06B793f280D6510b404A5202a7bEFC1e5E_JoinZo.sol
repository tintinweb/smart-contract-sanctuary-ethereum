/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: MIT
// File: openzeppelin-solidity/contracts/utils/cryptography/MerkleProof.sol


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

// File: openzeppelin-solidity/contracts/security/ReentrancyGuard.sol


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

// File: openzeppelin-solidity/contracts/utils/Context.sol


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

// File: openzeppelin-solidity/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/JoinZo.sol


pragma solidity ^0.8.0;




interface IERC721Receiver {
    function onERC721Received(
        address operator, 
        address from, 
        uint256 tokenId, 
        bytes calldata data
    ) external returns (
        bytes4
    );
}

contract ERC721A {
    function mint(
    ) public payable {}
    
    function mintGrant(
        address[] calldata addresses, 
        uint256[] calldata amounts
    ) public {}
    
    function transferFrom(
        address from, 
        address to, 
        uint256 tokenId
    ) external {}
    
    function transferOwnership(
        address newOwner
    ) public virtual {}

    function balanceOf(
        address account
    ) public view virtual returns (
        uint256
    ) {}

    function tokenOfOwnerByIndex(
        address owner, 
        uint256 index
    ) public view returns (
        uint256
    ) {}
}


contract JoinZo is IERC721Receiver, Ownable {
    address private signingWallet;
    ERC721A private founderContract;
    uint256 private maxMintCount = 1;
    uint256 private minTokenId = 789;
    uint256 public pricePerMint = 0.25 ether;
    uint256 public mintStart;
    uint256 public tokenMintStart;
    uint256 public publicMintStart;

    uint256[321] private availableTokens;
    mapping(address => uint256) private mintedCount;

    
    constructor(
        address _signingWallet,
        address _founderContract
    ) {
        signingWallet = _signingWallet;
        founderContract = ERC721A(_founderContract);
    }

    function available(
    ) public view returns (
        uint256
    ) {
        return founderContract.balanceOf(
            address(this)
        );
    }
    
    function mintsAllowed(
        address _addr
    ) public view returns (
        uint256
    ) {
        if (mintedCount[_addr] >= maxMintCount) {
            return 0;
        } else {
            return maxMintCount - mintedCount[_addr];
        }
    }

    function mint(
        bytes memory _signature
    ) external payable {
        require(
            mintStart > 0, 
            "mint not started"
        );
        require(
            block.timestamp >= mintStart,
            "Mint not started"
        );
        require(
            verifyMessage(_msgSender(), _signature) == signingWallet,
            "signature mismatch"
        );
        uint256 _availableMints = available();
        uint256 _tokenId = getRandomToken(_availableMints);
        _mint(_tokenId, _availableMints);
    }

    function mintToken(
        uint256 _tokenId,
        bytes memory _signature
    ) external payable {
        require(
            tokenMintStart > 0, 
            "mint not started"
        );
        require(
            block.timestamp >= tokenMintStart,
            "Mint not started"
        );
        require(
            verifyMessage(_msgSender(), _signature) == signingWallet,
            "signature mismatch"
        );
        _mint(_tokenId, available());
    }

    function mintPublic(
    ) external payable {
        require(
            publicMintStart > 0, 
            "mint not started"
        );
        require(
            block.timestamp >= publicMintStart,
            "Mint not started"
        );
        uint256 _availableMints = available();
        uint256 _tokenId = getRandomToken(_availableMints);
        _mint(_tokenId, _availableMints);
    }
    
    function setPricePerMint(
        uint256 _price
    ) external onlyOwner {
        pricePerMint = _price;
    }
    
    function setSigningWallet(
        address _addr
    ) external onlyOwner {
        signingWallet = _addr;
    }
    
    function setMintTime(
        uint256 _timestamp
    ) external onlyOwner {
        mintStart = _timestamp;
    }
    
    function setMaxMintCount(
        uint256 _maxMint
    ) external onlyOwner {
        maxMintCount = _maxMint;
    }
    
    function setMinTokenId(
        uint256 _minTokenId
    ) external onlyOwner {
        minTokenId = _minTokenId;
    }
    
    function setPublicMintTime(
        uint256 _timestamp
    ) external onlyOwner {
        publicMintStart = _timestamp;
    }
    
    function setTokenMintTime(
        uint256 _timestamp
    ) external onlyOwner {
        tokenMintStart = _timestamp;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (
        bytes4
    ) {
        return this.onERC721Received.selector;
    }
    
    function withdrawAmount(
        uint256 _amount
    ) external onlyOwner {
        payable(
            _msgSender()
        ).transfer(
            _amount
        );
    }
    
    function withdrawFounder(
        uint256 _tokenId,
        address _addr
    ) external onlyOwner {
        updateAvailableTokens(_tokenId - minTokenId, available());
        founderContract.transferFrom(
            address(this), 
            _addr, 
            _tokenId
        );
    }
    
    function withdrawAllFounder(
        address _addr
    ) external onlyOwner {
        uint256 _available = available();
        uint256 tokenId;
        for (uint256 i = 0; i < _available; i++) {
            if (availableTokens[i] == 0) {
                tokenId = i + minTokenId;
            } else {
                tokenId = availableTokens[i] + minTokenId;
            }
            founderContract.transferFrom(
                address(this), 
                _addr, 
                tokenId
            );  
        }
    }

    function getRandomToken(
        uint256 _availableMints
    ) internal returns (
        uint256
    ) {
        uint256 indexToUse = random(_availableMints);
        return updateAvailableTokens(indexToUse, _availableMints);
    }

    function updateAvailableTokens(
        uint256 indexToUse,
        uint256 _availableMints
    ) internal returns (
        uint256
    ) {
        uint256 lastIndex = _availableMints - 1;
        uint256 valAtIndex = availableTokens[indexToUse];
        uint256 result;
        if (valAtIndex == 0) {
            result = indexToUse;
        } else {
            result = valAtIndex;
        }
        if (indexToUse != lastIndex) {
            uint256 lastValInArray = availableTokens[lastIndex];
            if (lastValInArray == 0) {
                availableTokens[indexToUse] = lastIndex;
            } else {
                availableTokens[indexToUse] = lastValInArray;
            }
        }
        return result + minTokenId;
    }

    function random(
        uint256 _maxNum
    ) internal view returns (
        uint256
    ) {
        uint256 randomnumber = uint256(
            keccak256(
                abi.encodePacked(
                    _msgSender(),
                    block.timestamp,
                    block.number,
                    block.coinbase,
                    blockhash(block.number - 1),
                    _maxNum
                )
            )
        ) % _maxNum;
        return randomnumber;
    }

    function splitSignature(
        bytes memory _signature
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(_signature.length == 65, "invalid signature length");
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }

    function getMessageHash(
        address _addr
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_addr));
    }

    function verifyMessage(
        address _addr, 
        bytes memory _signature
    ) internal pure returns (
        address
    ) {
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32", 
                getMessageHash(_addr)
            )
        );
        (bytes32 _r, bytes32 _s, uint8 _v) = splitSignature(_signature);
        address signer = ecrecover(
            prefixedHashMessage, _v, _r, _s
        );
        return signer;
    }

    function _mint(
        uint256 _tokenId,
        uint256 _availableMints
    ) internal {
        require(
            mintsAllowed(_msgSender()) > 0,
            "limit reached"
        );
        require(
            _availableMints > 0,
            "nothing left"
        );
        require(
            msg.value >= pricePerMint,
            "Not enough ETH sent"
        );
        mintedCount[_msgSender()] += 1;
        updateAvailableTokens(_tokenId - minTokenId, _availableMints);
        founderContract.transferFrom(
            address(this), 
            _msgSender(), 
            _tokenId
        );
    }

}