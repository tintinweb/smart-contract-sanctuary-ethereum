// SPDX-License-Identifier: MIT
//  ___   _  __   __  ______   _______  _______  _______  ___  
// |   | | ||  | |  ||      | |   _   ||       ||   _   ||   | 
// |   |_| ||  | |  ||  _    ||  |_|  ||  _____||  |_|  ||   | 
// |      _||  |_|  || | |   ||       || |_____ |       ||   | 
// |     |_ |       || |_|   ||       ||_____  ||       ||   | 
// |    _  ||       ||       ||   _   | _____| ||   _   ||   | 
// |___| |_||_______||______| |__| |__||_______||__| |__||___| 
//  __   __  ___   __    _  _______  _______  ______           
// |  |_|  ||   | |  |  | ||       ||       ||    _ |          
// |       ||   | |   |_| ||_     _||    ___||   | ||          
// |       ||   | |       |  |   |  |   |___ |   |_||_         
// |       ||   | |  _    |  |   |  |    ___||    __  |        
// | ||_|| ||   | | | |   |  |   |  |   |___ |   |  | |        
// |_|   |_||___| |_|  |__|  |___|  |_______||___|  |_|        

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface Kudasai {
    function mintKudasai(address _to, uint256 _quantity) external;
    function mintReserve(address _to, uint256[] memory _ids) external;
}
interface Hidden {
    function check(address _to, uint256 _quantity, bytes32 _code) external view returns (bool);
}

contract KudasaiMinter is Ownable {
    mapping(address => mapping(uint256 => uint256)) public kudasaiCounter;
    uint256 public kantsuCounter;
    mapping(uint256 => bool) public kudasaiHolderClaimed;
    mapping(uint256 => bool) public ticketHolderClaimed;
    uint256 private immutable _maxWalletPerToken;
    address private immutable _onchainKudasai;
    address private immutable _ticketNFT;
    address private immutable _kudasaiNFT;
    address private _hidden;
    uint256 public proofRound;
    bytes32 public kudasaiListMerkleRoot;
    uint256 public mintCost = 0.1 ether;

    constructor(uint256 maxWalletPerToken_, address onchainKudasai_, address kudasaiNFT_, address ticketNFT_, bytes32 kudasaiListMerkleRoot_) {
        _maxWalletPerToken = maxWalletPerToken_;
        _onchainKudasai = onchainKudasai_;
        _kudasaiNFT = kudasaiNFT_;
        _ticketNFT = ticketNFT_;
        kudasaiListMerkleRoot = kudasaiListMerkleRoot_;
    }

    modifier validateKudasaiAddress(bytes32[] calldata _merkleProof) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, kudasaiListMerkleRoot, leaf), "You are not a Kudasai list");
        _;
    }
    
    modifier onlyKudasaiHolder(uint256[] memory _ids) {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(kudasaiHolderClaimed[_ids[i]] == false, "Already claimed");
            require(IERC721(address(_onchainKudasai)).ownerOf(_ids[i]) == msg.sender, "You do not have Kudasai NFTs");
            kudasaiHolderClaimed[_ids[i]] = true;
        }
        _;
    }
    
    modifier onlyTicketHolder(uint256[] memory _ids) {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(ticketHolderClaimed[_ids[i]] == false, "Already claimed");
            require(IERC721(address(_ticketNFT)).ownerOf(_ids[i]) == msg.sender, "You do not have Kudasai NFTs");
            ticketHolderClaimed[_ids[i]] = true;
        }
        _;
    }

    modifier isNotContract() {
        require(tx.origin == msg.sender, "Reentrancy Guard is watching");
        _;
    }

    function setKudasaiListMerkleRoot(bytes32 _merkleRoot, uint256 _round, uint256 _mintCost) external onlyOwner {
        kudasaiListMerkleRoot = _merkleRoot;
        mintCost = _mintCost;
        proofRound = _round;
    }

    function setHidden(address _contract) external onlyOwner {
        _hidden = _contract;
    }

    function refreshHidden() external onlyOwner {
        _hidden = address(0);
    }

    function banbanban(uint256[] memory _ids) external onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            kudasaiHolderClaimed[_ids[i]] = true;
        }
    }

    function agemasu(uint256[] memory _ids, uint256 _quantity) external onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            address owner = IERC721(address(_onchainKudasai)).ownerOf(_ids[i]);
            Kudasai(_kudasaiNFT).mintKudasai(owner, _quantity);
        }
    }

    function kantsuEnable() view public returns(bool) {
        if (kantsuCounter < 10) {
            return true;
        }
        return false;
    }

    function kantsu(uint256 _quantity, bytes32 _code) external payable isNotContract {
        require(msg.value == mintCost * _quantity, "Mint cost is insufficient");
        require(_hidden != address(0) && Hidden(_hidden).check(msg.sender, _quantity, _code), "Your address is Blacklisted!");
        require(kudasaiCounter[msg.sender][proofRound] + _quantity <= _maxWalletPerToken, "No More Kudasai");
        require(kantsuEnable(), "No More Kantsu");

        kudasaiCounter[msg.sender][proofRound] += _quantity;
        kantsuCounter++;
        Kudasai(_kudasaiNFT).mintKudasai(msg.sender, _quantity);
    }

    function holderClaim(uint256[] memory _ids) external onlyKudasaiHolder(_ids) isNotContract {
        Kudasai(_kudasaiNFT).mintReserve(msg.sender, _ids);
        for (uint256 i = 0; i < _ids.length; i++) {
            IERC721(address(_onchainKudasai)).safeTransferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), _ids[i]);
        }
    }

    function ticketClaim(uint256[] memory _ids) external onlyTicketHolder(_ids) isNotContract {
        Kudasai(_kudasaiNFT).mintKudasai(msg.sender, _ids.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            IERC721(address(_ticketNFT)).safeTransferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), _ids[i]);
        }
    }

    function kudasai(uint256 _quantity, bytes32[] calldata _proof) external payable validateKudasaiAddress(_proof) isNotContract {
        require(msg.value == mintCost * _quantity, "Mint cost is insufficient");
        require(kudasaiCounter[msg.sender][proofRound] + _quantity <= _maxWalletPerToken, "No More Kudasai");

        kudasaiCounter[msg.sender][proofRound] += _quantity;
        Kudasai(_kudasaiNFT).mintKudasai(msg.sender, _quantity);
    }

    function holderClaimAndKudasai(uint256 _quantity, bytes32[] calldata _proof, uint256[] memory _ids) external payable validateKudasaiAddress(_proof) isNotContract {
        require(msg.value == mintCost * _quantity, "Mint cost is insufficient");
        require(kudasaiCounter[msg.sender][proofRound] + _quantity <= _maxWalletPerToken, "No More Kudasai");

        kudasaiCounter[msg.sender][proofRound] += _quantity;
        Kudasai(_kudasaiNFT).mintKudasai(msg.sender, _quantity);
        Kudasai(_kudasaiNFT).mintReserve(msg.sender, _ids);
        for (uint256 i = 0; i < _ids.length; i++) {
            IERC721(address(_onchainKudasai)).safeTransferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), _ids[i]);
        }
    }

    function ownerMint(uint256 _quantity) external onlyOwner {
        Kudasai(_kudasaiNFT).mintKudasai(owner(), _quantity);
    }

    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
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
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
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
     * @dev Calldata version of {processMultiProof}
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