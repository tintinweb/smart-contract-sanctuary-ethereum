// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import "solmate/auth/Owned.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import "./AnonymiceLibrary.sol";
import "./ChainWavesGenerator.sol";

contract ChainWaves is ERC721, Owned {
    using AnonymiceLibrary for uint8;

    error SoldOut();
    error EthFail();
    error MaxThree();
    error PublicMinted();
    error SnowcrashMinted();
    error NotToad();
    error ToadMinted();
    error NotSnowcrashList();
    error SelfMintOnly();
    error NonExistantId();
    error Stap();
    error WithdrawFail();

    struct Trait {
        string traitName;
        string traitType;
    }

    struct HashNeeds {
        uint16 startHash;
        uint16 startNonce;
    }

    struct Palette {
        string bg;
        string colOne;
        string colTwo;
    }

    uint256 public constant MAX_SUPPLY = 512;
    uint256 public constant MINT_PRICE = 0.0256 ether;
    uint256 public constant SNOWCRASH_PRICE = 0.05 ether;
    uint256 public constant MAX_MINT = 3;

    uint256 public totalSupply;

    uint16 private SEED_NONCE = 3;
    // TODO: Set right address
    address private constant toadAddress =
        0x9ea04B953640223dbb8098ee89C28E7a3B448858;
    bool private toadMinted;

    mapping(address => bool) publicMinted;
    mapping(uint256 => HashNeeds) tokenIdToHashNeeds;
    mapping(uint256 => Trait[]) public traitTypes;
    mapping(address => uint256) lastWrite;

    //Mappings

    ChainWavesGenerator chainWavesGenerator;

    //uint arrays
    uint16[][6] private TIERS;

    constructor()
        ERC721("ChainWaves", "CA")
        Owned(0x9ea04B953640223dbb8098ee89C28E7a3B448858)
    {
        chainWavesGenerator = new ChainWavesGenerator();

        //Palette
        TIERS[0] = [1250, 1250, 1250, 1250, 1250, 1250, 1250, 1250];
        //Noise
        TIERS[1] = [1000, 4000, 4000, 1000];
        //Speed
        TIERS[2] = [1000, 4000, 4000, 1000];
        //Char set
        TIERS[3] = [2250, 2250, 2250, 2250, 600, 400];
        //Detail
        TIERS[4] = [1000, 6000, 3000];
        //NumCols
        TIERS[5] = [800, 6200, 2600, 400];
    }

    //prevents someone calling read functions the same block they mint
    modifier disallowIfStateIsChanging() {
        if (lastWrite[msg.sender] == block.number) revert Stap();
        _;
    }

    /**
     * @dev Converts a digit from 0 - 10000 into its corresponding rarity based on the given rarity tier.
     * @param _randinput The input from 0 - 10000 to use for rarity gen.
     * @param _rarityTier The tier to use.
     */
    function rarityGen(uint256 _randinput, uint8 _rarityTier)
        internal
        view
        returns (uint8)
    {
        uint16 currentLowerBound;
        uint256 tiersLength = TIERS[_rarityTier].length;
        for (uint8 i; i < tiersLength; ++i) {
            uint16 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    /**
     * @param _a The address to be used within the hash.
     */
    function hash(address _a) internal view returns (uint16) {
        uint16 _randinput = uint16(
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, block.difficulty, _a)
                )
            ) % 10000
        );

        return _randinput;
    }

    function normieMint(uint256 _amount) external payable {
        if (_amount > MAX_MINT) revert MaxThree();
        if (msg.value != MINT_PRICE * _amount) revert EthFail();
        if (publicMinted[msg.sender]) revert PublicMinted();

        publicMinted[msg.sender] = true;
        mintInternal(_amount);
    }

    function toadMint() external {
        //if (msg.sender != toadAddress) revert NotToad();
        if (toadMinted) revert ToadMinted();

        mintInternal(5);
    }

    function mintInternal(uint256 _amount) internal {
        if (totalSupply + _amount > MAX_SUPPLY) revert SoldOut();
        uint256 firstTokenId = totalSupply;

        for (uint256 i; i < _amount; ++i) {
            tokenIdToHashNeeds[i] = HashNeeds(hash(msg.sender), SEED_NONCE);
            _mint(msg.sender, firstTokenId);
            ++firstTokenId;
        }
        lastWrite[msg.sender] = block.number;
        SEED_NONCE += 10;
        totalSupply += _amount;
    }

    // hash stuff

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     * From anonymice
     */

    function buildHash(uint256 _t) internal view returns (string memory) {
        // This will generate a 4 character string.
        string memory currentHash = "";
        uint256 rInput = tokenIdToHashNeeds[_t].startHash;
        uint256 _nonce = tokenIdToHashNeeds[_t].startNonce;

        for (uint8 i; i < 6; ++i) {
            ++_nonce;
            uint16 _randinput = uint16(
                uint256(keccak256(abi.encodePacked(rInput, _t, _nonce))) % 10000
            );
            currentHash = string(
                abi.encodePacked(
                    currentHash,
                    rarityGen(_randinput, i).toString()
                )
            );
        }
        return currentHash;
    }

    // Views

    function hashToMetadata(string memory _hash)
        public
        view
        disallowIfStateIsChanging
        returns (string memory)
    {
        string memory metadataString;

        for (uint8 i; i < 6; ++i) {
            uint8 thisTraitIndex = AnonymiceLibrary.parseInt(
                AnonymiceLibrary.substring(_hash, i, i + 1)
            );

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    traitTypes[i][thisTraitIndex].traitType,
                    '","value":"',
                    traitTypes[i][thisTraitIndex].traitName,
                    '"}'
                )
            );

            if (i != 5)
                metadataString = string(abi.encodePacked(metadataString, ","));
        }

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    function _tokenIdToHash(uint256 _tokenId)
        public
        view
        disallowIfStateIsChanging
        returns (string memory tokenHash)
    {
        if (_tokenId >= totalSupply) revert NonExistantId();
        tokenHash = buildHash(_tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory _URI)
    {
        if (_tokenId >= totalSupply) revert NonExistantId();
        string memory _hash = _tokenIdToHash(_tokenId);
        _URI = string(
            abi.encodePacked(
                "data:application/json;base64,",
                AnonymiceLibrary.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "ChainWaves #',
                                AnonymiceLibrary.toString(_tokenId),
                                '","description": "Fully onchain generative art SVG collection. Created by McToady & Circolors."',
                                ',"image": "data:image/svg+xml;base64,',
                                AnonymiceLibrary.encode(
                                    bytes(
                                        abi.encodePacked(
                                            "<svg viewBox='0 0 20 20' width='600' height='600' xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMidYMin'><rect width='20' height='20' fill='#",
                                            chainWavesGenerator.buildSVG(
                                                _tokenId,
                                                _hash
                                            ),
                                            "</svg>"
                                        )
                                    )
                                ),
                                '","attributes":',
                                hashToMetadata(_hash),
                                "}"
                            )
                        )
                    )
                )
            )
        );
    }

    // Owner Functions
    /**
     * @dev Add a trait type
     * @param _traitTypeIndex The trait type index
     * @param traits Array of traits to add
     */

    function addTraitType(uint256 _traitTypeIndex, Trait[] memory traits)
        external
        payable
        onlyOwner
    {
        for (uint256 i; i < traits.length; ++i) {
            traitTypes[_traitTypeIndex].push(
                Trait(traits[i].traitName, traits[i].traitType)
            );
        }

        return;
    }

    function withdraw() external payable onlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        if (!sent) revert WithdrawFail();
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
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

import "./AnonymiceLibrary.sol";

contract ChainWavesGenerator {
    using AnonymiceLibrary for uint8;

    string[][8] private PALETTES;
    uint256[] private NOISE;
    uint256[] private SPEED;
    string[] private CHARS;
    uint256[] private TIGHTNESS;

    struct Traits {
        string[] palette;
        uint256 noise;
        uint256 speed;
        string charSet;
        uint256 tightness;
        uint256 numCols;
    }

    constructor() {
        //lava
        PALETTES[0] = ["d00000", "370617", "faa307", "e85d04", "03071e"];
        //flamingo
        PALETTES[1] = ["3a0ca3", "f72585", "4cc9f0", "7209b7", "4cc9f0"];
        //rioja
        PALETTES[2] = ["250902", "38040e", "640d14", "800e13", "ad2831"];
        //alien
        PALETTES[3] = ["013026", "a1ce3f", "107e57", "014760", "cbe58e"];
        //samba
        PALETTES[4] = ["009638", "F6D800", "002672", "fff", "f8961e"];
        //pepewaves
        PALETTES[5] = ["23B024", "F02423", "294AF6", "fff", "000"];
        //cow
        PALETTES[6] = ["aabf98", "1f1f1f", "f2f2f2", "b5caa3", "20251e"];
        //pastelize
        PALETTES[7] = ["7067cf", "b7c0ee", "cbf3d2", "f87575", "ef626c"];

        NOISE = [20, 35, 55, 85];

        SPEED = [95, 75, 50, 25];

        CHARS = ["#83!:", "@94?;", "W72a+", "N$50c", "0101/", "gm;)'"];

        TIGHTNESS = [2, 3, 5];
    }

    struct Palette {
        bytes3 bg;
        bytes3 colOne;
        bytes3 colTwo;
    }

    function buildLine(
        string memory _chars,
        uint256 _modJump,
        uint8 _x,
        uint8 _y
    ) public pure returns (string memory lineOut) {
        bytes memory byteChars = bytes(_chars);

        uint256 randomModulo = 1;
        lineOut = string(
            abi.encodePacked(
                "<text x ='-",
                _x.toString(),
                "' y='",
                _y.toString(),
                "'>"
            )
        );
        for (uint256 i; i < 12; ++i) {
            string memory charChoice = string(
                abi.encodePacked(byteChars[randomModulo % 4])
            );
            lineOut = string(abi.encodePacked(lineOut, charChoice));
            randomModulo += _modJump;
        }
        lineOut = string(abi.encodePacked(lineOut, "</text>"));
    }

    function buildXLines(
        string memory _chars,
        uint256 _modStart,
        uint256 numLines
    ) public pure returns (string memory lineOut) {
        uint8 x = 1;
        uint8 y;
        for (uint256 i; i < numLines; ++i) {
            lineOut = string(
                abi.encodePacked(lineOut, buildLine(_chars, _modStart, x, y))
            );
            _modStart += 7;
            y += 4;
            if (x == 1) {
                x = 3;
            } else {
                x = 1;
            }
        }
    }

    function buildSVG(uint256 _tokenId, string memory _hash)
        public
        view
        returns (string memory _svg)
    {
        // get traits from id
        Traits memory tokenTraits = buildTraits(_hash);

        uint256 modStart = tokenTraits.noise + tokenTraits.tightness;
        _svg = string(
            abi.encodePacked(
                tokenTraits.palette[0],
                "'/><defs><g id='chars' font-family='monospace'>",
                buildXLines(
                    tokenTraits.charSet,
                    modStart,
                    10 - tokenTraits.numCols
                ),
                "<animate attributeName='font-size' attributeType='XML' values='100%;",
                AnonymiceLibrary.toString(tokenTraits.speed),
                "%;100%' begin='0s' dur='15s' repeatCount='indefinite'/></g><filter id='turbulence'><feTurbulence type='turbulence' baseFrequency='0.",
                AnonymiceLibrary.toString(tokenTraits.noise),
                "' numOctaves='",
                AnonymiceLibrary.toString(tokenTraits.tightness),
                "' result='noise' seed='",
                AnonymiceLibrary.toString(_tokenId),
                buildUseLines(tokenTraits.palette, tokenTraits.numCols)
            )
        );
    }

    function buildTraits(string memory _hash)
        public
        view
        returns (Traits memory tokenTraits)
    {
        uint256[] memory traitArray = new uint256[](6);

        for (uint256 i; i < 6; ++i) {
            traitArray[i] = AnonymiceLibrary.parseInt(
                AnonymiceLibrary.substring(_hash, i, i + 1)
            );
        }
        tokenTraits = Traits(
            PALETTES[traitArray[0]],
            NOISE[traitArray[1]],
            SPEED[traitArray[2]],
            CHARS[traitArray[3]],
            TIGHTNESS[traitArray[4]],
            traitArray[5] + 1
        );
        // Go palettes array and return this palette
    }

    function buildUseLines(string[] memory _pal, uint256 _numCols)
        internal
        pure
        returns (string memory output)
    {
        output = "'/><feDisplacementMap in='SourceGraphic' in2='noise' scale='3' /></filter></defs>";
        uint256 y;

        for (uint256 i; i < _numCols; ++i) {
            output = string(
                abi.encodePacked(
                    output,
                    "<use href='#chars' y='",
                    AnonymiceLibrary.toString(y),
                    "' x='0' filter='url(#turbulence)' width='20' height='20' fill='#",
                    _pal[i + 1],
                    "'/>"
                )
            );

            y += 3;
        }
    }
}