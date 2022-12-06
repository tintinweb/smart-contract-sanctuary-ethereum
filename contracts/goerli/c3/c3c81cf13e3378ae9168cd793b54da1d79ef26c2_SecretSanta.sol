// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;


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

interface IStockingsLike {

    function mint(address to) external;    

    function burn(uint256 tokenId) external;

    function minted(address owner) external returns(uint256);

    function ownerOf(uint256 tokenId) external returns(address);

    function rarity(uint256 tokenId) external returns(uint256);
}

interface IERC721Like {

    function transferFrom(address from, address to, uint256 tokenId) external;

}

contract SecretSanta is ERC721TokenReceiver {

    bytes32 private constant ADMIN_SLOT = bytes32(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103);

    /*//////////////////////////////////////////////////////////////
                        STORAGE
    //////////////////////////////////////////////////////////////*/

    address public stockings;

    uint256 public maxParticipants;
    uint256 public currentId;
    uint256 public randomness;

    bool    public open;
    bytes32 public merkleRoot;

    mapping(address => bool)    public allowedNFTs;
    mapping(uint256 => uint256) public bigIds;     // Storage reserved for ids that are too big for a uint96. In that case, we set the id to max and save in this storage.
    mapping(uint256 => NFT)     public nfts;

    uint16[] public list;

    struct NFT {
        address address_;
        uint88  id_;
        bool    premium_;
    }

    /*//////////////////////////////////////////////////////////////
                        PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function deposit(address nft, uint256 id, bytes32[] calldata proof_) external returns (uint256 internalId_) {
        require(open,                                              "NOT OPEN");
        require(allowedNFTs[nft],                                  "NOT ALLOWED");
        require(IStockingsLike(stockings).minted(msg.sender) == 0, "ALREADY DEPOSITED");

        // TODO uncomment this
        // require(MerkleProof.verify(proof_, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "NOT ON LIST");

        internalId_ = add(msg.sender, nft, id, false);
    }

    function draw(uint256 stockingId) external {
        require(open, "NOT OPEN");
        require(IStockingsLike(stockings).ownerOf(stockingId) == msg.sender, "NOT OWNER");

        uint256 rarity = IStockingsLike(stockings).rarity(stockingId);
        uint256 index  = uint256(keccak256(abi.encodePacked(stockingId, randomness, "FIRST PICK" ))) % list.length;

        if (rarity > 1 && !nfts[list[index]].premium_) {
            // A rare stocking can get a second pick if the first one is not rare
            index = uint256(keccak256(abi.encodePacked(stockingId, randomness, "SECOND PICK"))) % list.length;
        }

        if (rarity == 3 && !nfts[list[index]].premium_) {
            // A rare stocking can get a second pick if the first one is not rare
            index = uint256(keccak256(abi.encodePacked(stockingId, randomness, "THIRD PICK"))) % list.length;
        }

        NFT memory nft = nfts[list[index]];

        // Remove from array
        list[index] = list[list.length - 1];
        list.pop();

        // Burn the stocking
        IStockingsLike(stockings).burn(stockingId);

        // Transfer the NFT
        IERC721Like(nft.address_).transferFrom(address(this), msg.sender, nft.id_ == type(uint88).max ? bigIds[list[index]] : nft.id_);
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function initialize(address stockings_, uint256 maxParticipants_, bytes32 merkleRoot_) external {
        require(msg.sender == owner(), "NOT AUTHORIZED");
        stockings       = stockings_;
        maxParticipants = maxParticipants_;
        merkleRoot      = merkleRoot_;
    }

    function addPremiums(address[] calldata addresses, uint256[] calldata ids) external {
        require(msg.sender == owner(),          "NOT AUTHORIZED");
        require(addresses.length == ids.length, "LENGTHS NOT EQUAL");

        for (uint256 i = 0; i < addresses.length; i++) {
            add(msg.sender, addresses[i], ids[i], true);
        }
    }

    function setAllowedNFTs(address[] calldata _addresses, bool allowed) external {
        require(msg.sender == owner(), "NOT AUTHORIZED");

        for (uint256 i = 0; i < _addresses.length; i++) {
            allowedNFTs[_addresses[i]] = allowed;
        }
    }

    function setOpen(bool open_) external {
        require(msg.sender == owner(), "NOT AUTHORIZED");
        open = open_;
    }

    function setMerkeRoot(bytes32 merkleRoot_) external {
        require(msg.sender == owner(), "NOT AUTHORIZED");
        merkleRoot = merkleRoot_;
    }

    function setRandomness(uint256 randomness_) external {
        require(msg.sender == owner(), "NOT AUTHORIZED");
        randomness = randomness_;
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function owner() public view returns (address owner_) {
        return _getAddress(ADMIN_SLOT);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function add(address owner_, address nft, uint256 id, bool rare) internal returns (uint256 internalId) {

        uint88 usedId = id > type(uint88).max ? type(uint88).max : uint88(id);

        nfts[internalId = ++currentId] = NFT(nft, usedId, rare);

        if (usedId == type(uint88).max) bigIds[internalId] = id; // Save into the bigId, if necessary.

        list.push(uint16(internalId));

        // Mint a stocking
        IStockingsLike(stockings).mint(msg.sender);

        // Transfer the NFT
        IERC721Like(nft).transferFrom(owner_, address(this), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL UTILITIES
    //////////////////////////////////////////////////////////////*/

    function _toString(uint256 value) internal pure returns (string memory) {
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

    function _getId(uint256 internalId_) internal view returns (uint256 id) {
        id = nfts[internalId_].id_;

        if (id == type(uint96).max) id = bigIds[internalId_];
    }

    function _getAddress(bytes32 key) internal view returns (address add_) {
        add_ = address(uint160(uint256(_getSlotValue(key))));
    }

    function _getSlotValue(bytes32 slot_) internal view returns (bytes32 value_) {
        assembly {
            value_ := sload(slot_)
        }
    }
}

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