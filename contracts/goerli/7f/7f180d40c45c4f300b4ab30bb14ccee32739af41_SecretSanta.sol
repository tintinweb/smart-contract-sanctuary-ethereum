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

interface IJollySwapLike {

    function mint(address to) external;    

    function burn(address owner, uint256 tokenId) external;

    function minted(address owner) external returns(uint256);

    function ownerOf(uint256 tokenId) external returns(address);

    function rarity(uint256 tokenId) external returns(uint256);
}

interface IERC721Like {

    function transferFrom(address from, address to, uint256 tokenId) external;

}

contract SecretSanta is ERC721TokenReceiver {

    bytes32 private constant ADMIN_SLOT = bytes32(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103);

    uint256 public constant MAX_MINT = 1;

    uint256 private _locked;
    
    /*//////////////////////////////////////////////////////////////
                        STORAGE
    //////////////////////////////////////////////////////////////*/

    address public jolly;

    uint256 public maxParticipants;
    uint256 public currentId;
    uint256 public randomness;

    bytes32 public allowListMerkleRoot;
    bytes32 public tokensMerkleRoot;

    mapping(uint256 => uint256) public bigIds;     // Storage reserved for ids that are too big for a uint96. In that case, we set the id to max and save in this storage.
    mapping(uint256 => NFT)     public nfts;

    uint16[] public list;

    State public state;

    enum State { CONFIG, DEPOSIT, REVEAL, WITHDRAW }

    struct NFT {
        address address_;
        uint88  id_;
        bool    premium_;
    }

    /*//////////////////////////////////////////////////////////////
                        MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier inState(State state_) {
        require(state == state_, "INVALID STATE");
        _;
    }

    modifier nonReentrant() {
        require(_locked == 1, "LOCKED");

        _locked = 2;
        _;
        _locked = 1;
    }

    /*//////////////////////////////////////////////////////////////
                        PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function deposit(address nft, uint256 id, bytes32[] calldata tokensProof_, bytes32[] calldata allowListProof_) external inState(State.DEPOSIT) nonReentrant returns (uint256 internalId_) {
        require(IJollySwapLike(jolly).minted(msg.sender) < MAX_MINT, "ALREADY DEPOSITED");
        require(MerkleProof.verify(allowListProof_, allowListMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "NOT ON ALLOW LIST");
        require(MerkleProof.verify(tokensProof_,    tokensMerkleRoot,    keccak256(abi.encodePacked(nft))),        "NOT ALLOWED NFT");

        internalId_ = add(msg.sender, nft, id, false);
    }

    function draw(uint256 jollyId) external inState(State.WITHDRAW) nonReentrant() {
        require(IJollySwapLike(jolly).ownerOf(jollyId) == msg.sender, "NOT OWNER");
        require(randomness != 0,                                      "RANDOMNESS NOT SET");

        uint256 rarity = IJollySwapLike(jolly).rarity(jollyId);
        uint256 rolls  = rarity <= 1 ? 1 : rarity == 2 ? 5 : 10;
        uint256 index;

        for (uint256 i = 0; i < rolls; i++) {
            index = roll(jollyId, i + 1);

            if (nfts[list[index]].premium_) break;
        }

        NFT memory nft = nfts[list[index]];

        // Remove from array
        list[index] = list[list.length - 1];
        list.pop();

        // Burn the jolly
        IJollySwapLike(jolly).burn(msg.sender, jollyId);

        // Transfer the NFT
        IERC721Like(nft.address_).transferFrom(address(this), msg.sender, nft.id_ == type(uint88).max ? bigIds[list[index]] : nft.id_);
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function initialize(address jolly_, uint256 maxParticipants_, bytes32 allowListMerkleRoot_, bytes32 tokensMerkleRoot_) external {
        require(msg.sender == owner(), "NOT AUTHORIZED");
        jolly               = jolly_;
        maxParticipants     = maxParticipants_;
        allowListMerkleRoot = allowListMerkleRoot_;
        tokensMerkleRoot    = tokensMerkleRoot_;

        _locked = 1;
    }

    function addPremiums(address[] calldata addresses, uint256[] calldata ids) external {
        require(msg.sender == owner(),          "NOT AUTHORIZED");
        require(addresses.length == ids.length, "LENGTHS NOT EQUAL");

        for (uint256 i = 0; i < addresses.length; i++) {
            add(msg.sender, addresses[i], ids[i], true);
        }
    }

    function setMerkleRoots(bytes32 allowListmerkleRoot_, bytes32 tokensMerkleRoot_) external {
        require(msg.sender == owner(), "NOT AUTHORIZED");
        allowListMerkleRoot = allowListmerkleRoot_;
        tokensMerkleRoot    = tokensMerkleRoot_;
    }

    function setRandomness(uint256 randomness_) external inState(State.REVEAL) {
        require(msg.sender == owner(), "NOT AUTHORIZED");

        randomness = randomness_;
        state = State.WITHDRAW;
    }

    function openForDeposits() external inState(State.CONFIG) {
        require(msg.sender == owner(), "NOT AUTHORIZED");
        
        state = State.DEPOSIT;
    }

    function closeDeposits() external inState(State.DEPOSIT) {
        require(msg.sender == owner(), "NOT AUTHORIZED");
        
        state = State.REVEAL;
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function listLength() external view returns (uint256 length_) {
        length_ = list.length;
    }

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

        // Mint a jolly
        IJollySwapLike(jolly).mint(msg.sender);

        // Transfer the NFT
        IERC721Like(nft).transferFrom(owner_, address(this), id);
    }

    function roll(uint256 jollySwapId, uint256 salt) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(jollySwapId, randomness, salt))) % list.length;
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