// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import "solmate/utils/LibString.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "./AnonymiceLibrary.sol";
import "./HexAnonsGenerator.sol";
import "./HexAnonsErrors.sol";

contract HexAnons is HexAnonsErrors, ERC721, Ownable {
    using LibString for uint256;

    uint256 public constant MAX_SUPPLY = 64;
    uint256 public constant MINT_START = 1; // FIXME: this needs to be set to a real time

    uint256 public constant AUCTION_START = MINT_START + 24 hours;
    uint256 public constant AUCTION_START_PRICE = 0.1 ether;
    uint256 public constant AUCTION_RESTING_PRICE = 0;
    // 15 minutes
    uint256 public constant AUCTION_PRICE_DROP_FREQ = 15 * 60;
    uint256 public constant AUCTION_PRICE_DROP_AMOUNT = 0.01 ether;
    
    bytes32 constant MINT_ROOT =
        0xea35e50958ff75fe96e04a6dd792de75a26dd0c2a2d12e8a4c485d938961eb39;

    uint256 public totalSupply;

    string[] ogCols;

    mapping(address => bool) addressMinted;
    mapping(uint256 => TokenInfo) tokenIdToTokenInfo;

    HexAnonsGenerator hexAnonsGenerator;

    modifier onlyBeforeAuctionStart() {
        if (block.timestamp > AUCTION_START) revert AuctionStarted();
        _;
    }

    modifier onlyAfterAuctionStart() {
        if (block.timestamp < AUCTION_START) revert AuctionNotStarted();
        _;
    }

    modifier paintYourOwn(uint256 _tokenId) {
        if (msg.sender != ownerOf(_tokenId)) revert PaintYourOwn();
        _;
    }

    constructor() ERC721("HexAnons", "HEXA") {
        hexAnonsGenerator = new HexAnonsGenerator();
        ogCols = ["5C3432", "F5F3EF", "EEAA48", "38845A", "E86D67", "B9EEF0"];
    }

    /**
     * @param _a The address to be used within the hash.
     * @param _tokenId, the tokenId the hash is for
     */
    function hashPattern(
        address _a,
        uint256 _tokenId
    ) internal view returns (TokenInfo memory) {
        uint32 _hash = uint32(
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        _a,
                        _tokenId
                    )
                )
            )
        );

        uint8 _pattern = uint8(
            uint256(keccak256(abi.encodePacked(_a, _tokenId))) % 20
        );

        return TokenInfo(_pattern, _hash, ogCols);
    }

    function calculatePrice()
        public
        view
        onlyAfterAuctionStart
        returns (uint256 price)
    {
        if (totalSupply >= MAX_SUPPLY) revert SoldOut();

        uint256 auctionStartPrice = AUCTION_START_PRICE;
        uint256 auctionPriceDrop = ((block.timestamp - AUCTION_START) / AUCTION_PRICE_DROP_FREQ) * AUCTION_PRICE_DROP_AMOUNT;

        price = auctionStartPrice > auctionPriceDrop ? (auctionStartPrice - auctionPriceDrop) : 0;
    }

    function auctionMint() external payable onlyAfterAuctionStart {
        uint256 _mintPrice = calculatePrice();
        if (msg.value < _mintPrice) revert WrongPrice();

        mintInternal();
        if (msg.value > _mintPrice) {
            uint256 refundDue = msg.value - _mintPrice;
            (bool sent, ) = msg.sender.call{value: refundDue}("");
            require(sent, "Failed to send Ether");
        }
    }

    function allowlistMint(
        bytes32[] calldata merkleProof
    ) external payable onlyBeforeAuctionStart {
        if (addressMinted[msg.sender]) revert AddressMinted();
        if (block.timestamp < MINT_START) revert NotOpen();

        bytes32 node = keccak256(abi.encodePacked(msg.sender));

        if (!MerkleProof.verify(merkleProof, MINT_ROOT, node))
            revert NotAllowlisted();

        addressMinted[msg.sender] = true;

        mintInternal();
    }

    function mintInternal() internal {
        if (totalSupply >= MAX_SUPPLY) revert SoldOut();
        uint256 nextTokenId = totalSupply;

        tokenIdToTokenInfo[nextTokenId] = hashPattern(msg.sender, nextTokenId);
        ++totalSupply;

        _mint(msg.sender, nextTokenId);
    }

    // Views

    function getTokenInfo(
        uint256 _tokenId
    ) external view returns (TokenInfo memory) {
        TokenInfo memory _info = tokenIdToTokenInfo[_tokenId];
        return _info;
    }

    function lickOfPaint(
        uint256 _tokenId,
        string[] memory _cols
    ) external paintYourOwn(_tokenId) {
        tokenIdToTokenInfo[_tokenId].cols = _cols;
    }

    function scrubPaint(uint256 _tokenId) external paintYourOwn(_tokenId) {
        tokenIdToTokenInfo[_tokenId].cols = ogCols;
    }

    function trialPaintJob(
        uint256 _tokenId,
        string[] memory _cols
    ) external view returns (string memory) {
        // FIXME: there are no tests for this
        if (_tokenId >= totalSupply) revert NonExistantId();
        TokenInfo memory _info = tokenIdToTokenInfo[_tokenId];
        _info.cols = _cols;
        return hexAnonsGenerator.buildSVG(_info);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory _URI) {
        if (_tokenId >= totalSupply) revert NonExistantId();
        TokenInfo memory _info = tokenIdToTokenInfo[_tokenId];
        return hexAnonsGenerator.buildToken(_tokenId, _info);
    }

    function withdraw() external payable onlyOwner {
        uint256 five = address(this).balance / 20;
        (bool sentI, ) = payable(
            address(0x4533d1F65906368ebfd61259dAee561DF3f3559D)
        ).call{value: five * 3}("");
        if (!sentI) revert WithdrawFail();
        (bool sentC, ) = payable(
            address(0x888f8AA938dbb18b28bdD111fa4A0D3B8e10C871)
        ).call{value: five * 10}("");
        if (!sentC) revert WithdrawFail();
        (bool sentT, ) = payable(
            address(0xE4260Df86f5261A41D19c2066f1Eb2Eb4F009e84)
        ).call{value: address(this).balance}(""); // 35%
        if (!sentT) revert WithdrawFail();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(int256 value) internal pure returns (string memory str) {
        if (value >= 0) return toString(uint256(value));

        unchecked {
            str = toString(uint256(-value));

            /// @solidity memory-safe-assembly
            assembly {
                // Note: This is only safe because we over-allocate memory
                // and write the string from right to left in toString(uint256),
                // and thus can be sure that sub(str, 1) is an unused memory location.

                let length := mload(str) // Load the string length.
                // Put the - character at the start of the string contents.
                mstore(str, 45) // 45 is the ASCII code for the - character.
                str := sub(str, 1) // Move back the string pointer by a byte.
                mstore(str, add(length, 1)) // Update the string length.
            }
        }
    }

    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
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
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
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
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
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
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
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
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
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
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
pragma solidity ^0.8.0;

library AnonymiceLibrary {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/utils/LibString.sol";
import "./HexAnons.sol";
import "./AnonymiceLibrary.sol";

struct Counts {
    uint64 count;
    uint64 viewCount;
    uint64 colCount;
    uint32 randPos;
}

struct TokenInfo {
    uint8 pattern;
    uint32 seed;
    string[] cols;
}

contract HexAnonsGenerator {
    using LibString for uint256;

    function getPointTwo(
        uint256 _x,
        uint256 _y,
        uint256 count,
        uint256 seed
    ) public pure returns (string memory _pointTwo) {
        uint256 rand = seed * 2 + count;
        uint256 x2 = _x - 14 + (rand % 5);
        uint256 y2 = _y + 29 + (rand % 4);

        _pointTwo = string(
            abi.encodePacked(x2.toString(), ",", y2.toString(), " ")
        );
    }

    function getPointThree(
        uint256 _x,
        uint256 _y,
        uint256 count,
        uint256 seed
    ) public pure returns (string memory _pointThree) {
        uint256 rand = seed * 3 + count;
        uint256 x3 = _x + (rand % 5);
        uint256 y3 = _y + 58 + (rand % 4);

        _pointThree = string(
            abi.encodePacked(x3.toString(), ",", y3.toString(), " ")
        );
    }

    function getPointFour(
        uint256 _x,
        uint256 _y,
        uint256 count,
        uint256 seed
    ) public pure returns (string memory _pointFour) {
        uint256 rand = seed * 4 + count;
        uint256 x4 = _x + 36 + (rand % 5);
        uint256 y4 = _y + 58 + (rand % 4);

        _pointFour = string(
            abi.encodePacked(x4.toString(), ",", y4.toString(), " ")
        );
    }

    function getPointFive(
        uint256 _x,
        uint256 _y,
        uint256 count,
        uint256 seed
    ) public pure returns (string memory _pointFive) {
        uint256 rand = seed * 5 + count;
        uint256 x5 = _x + 50 + (rand % 5);
        uint256 y5 = _y + 29 + (rand % 4);

        _pointFive = string(
            abi.encodePacked(x5.toString(), ",", y5.toString(), " ")
        );
    }

    function getPointSix(
        uint256 _x,
        uint256 _y,
        uint256 count,
        uint256 seed
    ) public pure returns (string memory _pointSix) {
        uint256 rand = seed * 6 + count;
        uint256 x6 = _x + 36 + (rand % 5);
        uint256 y6 = _y + (rand % 4);

        _pointSix = string(abi.encodePacked(x6.toString(), ",", y6.toString()));
    }

    function drawHex(
        uint256 _x,
        uint256 _y,
        string calldata col,
        uint128 face,
        uint256 count,
        uint32 seed
    ) public pure returns (string memory _hex) {

        _hex = string(
            abi.encodePacked(
                "<polygon points='",
                _x.toString(),
                ",",
                _y.toString(),
                " ",
                getPointTwo(_x, _y, count, seed),
                getPointThree(_x, _y, count, seed),
                getPointFour(_x, _y, count, seed),
                getPointFive(_x, _y, count, seed),
                getPointSix(_x, _y, count, seed)
            )
        );

        _hex = string(
            abi.encodePacked(
                _hex,
                "' stroke-width='4' fill='#",
                col,
                "'/><text x='",
                drawFace(_x, _y, face)
            )
        );
    }

    function drawFace(
        uint256 _x,
        uint256 _y,
        uint128 _face
    ) public pure returns (string memory face) {
        string memory faceChoice;
        if (_face == 1) {
            faceChoice = "'-'";
        } else {
            faceChoice = "^-^";
        }

        uint256 xText = _x + 15;
        uint256 yText = _y + 38;

        face = string(
            abi.encodePacked(
                xText.toString(),
                "' y='",
                yText.toString(),
                "'>",
                faceChoice,
                "</text>"
            )
        );
    }

    function drawGrid(
        TokenInfo calldata _info
    ) public pure returns (string memory _grid) {
        Counts memory counts = Counts(0, 0, 0, 12);
        uint128 xFlip;
        uint128 face = 1;

        for (uint256 y = 0; y <= 805; y += 35) {
            for (uint256 x = 50; x < 840; x += 120) {
                if (counts.count % 2 == 0) {
                    xFlip = 1;
                } else {
                    xFlip = 0;
                }

                if (counts.viewCount == counts.randPos) {
                    face = 2;
                } else {
                    face = 1;
                }
                uint256 xPos = x + (xFlip * 6000) / 100;
                _grid = string(
                    abi.encodePacked(
                        _grid,
                        drawHex(
                            xPos,
                            y,
                            _info.cols[counts.colCount],
                            face,
                            counts.count,
                            _info.seed
                        )
                    )
                );
                ++counts.viewCount;
                if (counts.viewCount % _info.pattern == 0) {
                    counts.colCount = ++counts.colCount % uint64(_info.cols.length);
                }
            }
            ++counts.count;
            counts.colCount = ++counts.colCount % uint64(_info.cols.length);
        }
    }

    function buildSVG(TokenInfo calldata _info) public pure returns(string memory _svg) {
        _svg = string(
            abi.encodePacked(
                '"data:image/svg+xml;base64,',
                AnonymiceLibrary.encode(
                    bytes(
                        abi.encodePacked(
                            '<svg width="800" height="800" viewBox="0 0 800 800" style="background-color:white" xmlns="http://www.w3.org/2000/svg"><defs><g id="hexrow" font-family="monospace" stroke="black" transform="none" font-size="130%" font-weight="bold">',
                            drawGrid(_info),
                            '</g></defs><use href="#hexrow" y="-35" x="-50"/></svg>'
                        )
                    )
                )
        ));
    }

    function buildToken(
        uint256 _tokenId,
        TokenInfo calldata _info
    ) external pure returns (string memory _URI) {
        _URI = string(
            abi.encodePacked(
                "data:application/json;base64,",
                AnonymiceLibrary.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "Hexanons #',
                                AnonymiceLibrary.toString(_tokenId),
                                '","description": "Fully onchain generative art SVG collection. Created by McToady & Circolors."',
                                ',"image":',
                                buildSVG(_info),
                                '"}'
                            )
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface HexAnonsErrors {
    error AuctionStarted();
    error AuctionNotStarted();
    error AddressMinted();
    error NotAllowlisted();
    error NotOpen();
    error NonExistantId();
    error SoldOut();
    error PaintYourOwn();
    error PaintSixColors();
    error WithdrawFail();
    error WrongPrice();
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