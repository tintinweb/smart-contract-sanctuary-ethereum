// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract MetaAndMagicSale {

    uint256 constant PS_MAX  = 1;

    uint8   public stage; // 0 -> init, 1 -> hero wl, 2 -> hero ps  3 -> item wl sale, 4 -> items hero sale ,5 -> items public sale 
    bytes32 public root;

    Sale public heroes;
    Sale public items;

    struct Sale { address token; uint16  left; uint16 amtPs; uint32  priceWl; uint32  pricePS; }

    function initialize(address heroes_, address items_) external {
        require(msg.sender == _owner(), "not allowed");

        heroes = Sale(heroes_, 3_000, 1, 15, 20);
        items  = Sale(items_,  9_863, 5, 5, 8);
    }

    // ADMIN FUNCTION
    function moveStage() external {
        require(msg.sender == _owner(), "not allowed");
        stage++;
    }

    function setRoot(bytes32 root_) external {
        require(msg.sender == _owner(), "not allowed");
        root = root_;
    }

    function withdraw(address destination) external {
        require(msg.sender == _owner(), "not allowed");

        (bool succ, ) = destination.call{value: address(this).balance}("");
        require(succ, "failed");
    }

    function ownerMint(address token, address destination, uint256 quantity) external {
        require(msg.sender == _owner(), "not allowed");

        if (token == heroes.token) {
            heroes.left -= uint16(quantity);
        } else if (token == items.token) {
            items.left -= uint16(quantity);
        }
        IERC721MM(token).mint(destination, quantity, 2);
    }

    function mint(uint256 amt) external payable returns(uint256 id) {
        uint256 cacheStage = stage; 

        require(cacheStage == 2 ||cacheStage == 5, "not on public sale");

        Sale memory sale = cacheStage == 5 ? items : heroes;
        
        // Make sure use sent enough money
        require(uint256(sale.pricePS) * amt * 1e16 == msg.value, "not enough sent");

        // Make sure that user is only minting the allowed amount
        uint256 minted  = IERC721MM(sale.token).publicMinted(msg.sender);
        require(minted + amt <= sale.amtPs, "already minted");

        // Effects
        sale.left -= uint16(amt);   

        if (cacheStage == 5) {
            items  = sale;
        } else {
            heroes = sale;
        }

        // Interactions
        id = IERC721MM(sale.token).mint(msg.sender, amt, 2);
    }

    function mint(uint256 allowedAmount, uint8 stage_, uint256 amount,  bytes32[] calldata proof_) external payable returns(uint256 id){
        uint256 cacheStage = stage; 
        Sale memory sale   = cacheStage >= 3 ? items : heroes;

        // Make sure use sent enough money 
        require(amount > 0, "zero amount");
        require(uint256(sale.priceWl) * 1e16 * amount == msg.value, "not enough sent");

        // Make sure sale is open
        require(stage_ == cacheStage, "wrong stage");

        // Make sure that user is only minting the allowed amount
        uint256 minted  = IERC721MM(sale.token).listMinted(msg.sender);
        require(minted + amount <= allowedAmount, "already minted");

        bytes32 leaf_ = keccak256(abi.encode(allowedAmount, stage_, msg.sender));
        require(_verify(proof_, root, leaf_), "not on list");

        // Effects
        sale.left -= uint16(amount);

        if (cacheStage >= 3) {
            items = sale;
        } else {
            heroes = sale;
        }

        id = IERC721MM(sale.token).mint(msg.sender, amount, 1);
    }

    function _verify(bytes32[] memory proof_, bytes32 root_, bytes32 leaf_) internal pure returns (bool allowed) {
       allowed =  MerkleProof.verify(proof_, root_, leaf_);
    }

    function _owner() internal view returns (address owner_) {
        bytes32 slot = bytes32(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103);
        assembly {
            owner_ := sload(slot)
        }
    }

}

interface IERC721MM {
    function mint(address to, uint256 amount, uint256 stage) external returns (uint256 id);
    function listMinted(address to) external returns (uint256 minted);
    function publicMinted(address to) external returns (uint256 minted);
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