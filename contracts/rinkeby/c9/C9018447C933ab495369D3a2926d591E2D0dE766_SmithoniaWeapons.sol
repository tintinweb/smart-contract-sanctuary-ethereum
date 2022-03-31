// SPDX-License-Identifier: Unlicense


///////////////////////////////////////////////////////////////////////////////////////////
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░//
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░//
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██▓██▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░//
//░░░░░░░░░░░░░░░░▒░░▒░░░░░▒░░▒░░░░░░░░░░▓█▓▓▓██░░░░░░░░░░░▒░░▒░░░░▒░░▒░░░░░░░░░░░░░░░░░░//
//░░░░░░░░░░░░░▒▒▒░░░░▒▒░░░░░░░░▒▒▒▒▓▒▒▒▓██▓▓▓███▓▒▒▓▒▒▒▒░░░░░░░░░▓▒░░░▒▒▒░░░░░░░░░░░░░░░//
//░░░░░░░░░░░▒▒░▓▓░░░▒▓▒░░░░▒▓░░░░▓▓██▓▓▓██▓▓▓▓█▓▓▓███▓▒░░░▒▓░░░░░▓▓░░░▒▓▒░▒▒░░░░░░░░░░░░//
//░░░░░░░░▒▒▒░░▒▓▓▒░░░▓▒░░░▒▓░░▒▓███▓▓▒▒▓██▓▓▓██▒▒▒▒▓▓██▓▒░░▒▓░░░░▓▓░░░▓▓▓░░░▒▒░░░░░░░░░░//
//░░░░░░░▓▒▒▒▒░░▓▓▓▒▒▒▓▓▒░▒▓▒▒▓██▓▓▒▒░░░▒██▓▓▓██▒▒▒▒▒▒▓▓██▓▒░▓▓░▒▓▓▒▒▒▓▓▓▒░░▒▓▒▒▒░░░░░░░░//
//░░░░░▒▒░▒▓▓▓▓▓▓▓██▓▓▓██▓▓█▓███▓▓▒░░░░░░███▓▓█▓░░▒▒▒▒▒▒▓▓██▓▓█▓▓█▓▓▓██▓▓▓▓▓▓▓▒░░▓░░░░░░░//
//░░░░░▒░░░░▒▒▓▓██████████████▓▓▓▒░░░░░░░▓██▓██▓░░░░▒▒▒▒▒▓▓███████████████▓▓▒▒░░░░▒░░░░░░//
//░░░░▓▒▓▒▒▒▒▒▓█▓▓▒▒▒▒▒▒▓▓████▓▓▒▒▒▒░░░░░▒▓███▓▒░░░░░▒▒▒▒▒▓▓████▓▓▒▒▒▒▒▒▓█▓▓▒▒▒▒▓▓▓░░░░░░//
//░░░▓▒░▒▓▓▓███░░░░░░░░░░░▒██▓▓▒▒▒▒▒▒░░░░░░▒▒▒░░░░░░▒▒▒▒▒▒▒▓███░░░░░░░░░░░▓██▓▓▓▒░░▓░░░░░//
//░░░█░▒▒▒▒▒▓█░░░░░░░░░░░░░▒█▓▓▓▒▒▒▒▓▓▓▒▒▒░░░░░░▒▒▓▓▓▓▒▒▒▓▓▓██░░░░░░░░░░░░░▓█▓▒▒▒▒▒▓▒░░░░//
//░░░█░▒▒▒▒▓█▓░░░▒░░░▒░░░░░▒█▓░▒▓▓▓▓▒▒░▒▓▓▒▒▒▒▒▓▓▒▒░▒▒▓▓▓▒▒▒██░░░░░░▒░░▒░░░░█▓▒▒▒▒░▓▒░░░░//
//░░░█░░░▒▓▓█▓░░▓▓▒▒▒░▒▒░░░▒█▓░▓▓▓▓▓▓▓▓▒▒▒▒▒▓▓▒▒▒▒▓▓▓▓▓██▓▒▒▓█░░░░▒▒░▒▒▓▓▒░░█▓▓▒▒░░▓▒░░░░//
//░░░▓▒▒▒░░▒▓▓▓░░░█▒▒▒▒▒▒░░▒█▒▓▒░░▒▓▓▓▓▓▓▓▓▒▒▒▒▓▓▓▓▓▓▓▓▒░▒▓▓▓█░░░▓▓▒▒▒▓▓░░▒█▓▓░░░▒▒█░░░░░//
//░░░░▓▓▒▒▓▓▓▒▓██▓▓▓▒▒▓▓▒░░▒█▒▒▒▒▓▓▒░▒▓▓▓▓▒▒▒▒▓▓▓▓▓▓▒░▒▓▓▒▒▒▓█░░░▓█▒▒▓▓▓██▓▓▒▓▓▓▒▒█▒░░░░░//
//░░░░░▓██▓▒░▓▒▒▓█▒▒▓███░░░▒█▒▒▒▒▒▒▒▓▒░▒▒▒▒▒▒▒▒▓▓▓░░▒▓▒▒▒▒▒▒▓█░░░▒███▓▒▓▓▒░▓▒▒▒▓██▓░░░░░░//
//░░░░░░▒▓█▓▓█▓▒▓█████▒░░░░▒█▒▒▒▒▒▒░░▓▒░▒▓▒▒▒▒▒▒▓░▒▓▒░▒▒▒▒▒▒▓█░░░░░▓█████▓▓██▓██▓▒░░░░░░░//
//░░░░░░░░░▒▒▓▓▓▓▒▒▒░░░░░░░▓█▓▒▒▒▒▒▒░▒▓▒▒▓▒▒▒▒▓▓▓░▒▓░▒▒▒▒▒▒▒▓█░░░░░░░░▒▒▓▓▓▓▒▒░░░░░░░░░░░//
//░░░░░░░░░░░░░░░░░░░░░░░░░█▓▓▒▒▒▒▒▒▒░█▒░▒▒▒░▒▒▒▓░▒▓░▒▒▒▒▒▒▒▓█▓░░░░░░░░░░░░░░░░░░░░░░░░░░//
//░░░░░░░░░░░░░░░░░░░░░░░░▓█▓▓▒▒▒▒▒▒▒░█▒░▒▒░▒▒▒▒▒░▒▓░▒▒▒▒▒▒▓▓██░░░░░░░░░░░░░░░░░░░░░░░░░░//
//░░░░░░░░░░░░░░░░░░░░░░░▓██▓▓▓▒▒▒▒▒▒░█▒░▒░░░▒▒▒▒░▒▓░▒▒▒▒▒▒▓▓███░░░░░░░░░░░░░░░░░░░░░░░░░//
//░░░░░░░░░░░░░░░░░░░░▒▒████▓▓▓▓▒▒▒▒▒░█▒░▒░░░▒▒▒░░▒▓░▒▒▒▒▒▓▓▓▓███▓▒▒░░░░░░░░░░░░░░░░░░░░░//
//░░░░░░░░░░░░░░░░░░░▒█▓███▓▓▓▓▓▓▒▒▒▒░█▒░▒▒▒▒▒▒▒░▒▒▓▒▒▒▒▒▓▓▓▓▓▓███▓█░░░░░░░░░░░░░░░░░░░░░//
//░░░░░░░░░░░░░░░░░░░░▒███▓██▓▓▓▓▓▒▒▒▒█▒▒▓▓▓▓▓▓▓█▒▓▓▒▒▒▓▓▓▓▓▓▓█▓██▓░░░░░░░░░░░░░░░░░░░░░░//
//░░░░░░░░░░░░░░░░░░░░░░░▓██▓▓▓▓▓▓▓▓▒▒▓▓▒▒░░░░░░▓▒▓▒▒▓▓▓▓▓▓▓▓██▓▒░░░░░░░░░░░░░░░░░░░░░░░░//
//░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓██████▓▓▓▓▒▒░░░░░░▓▒█▒▓███████▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░//
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▓▓██▓▒░░░░░░▓▓██▓▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░//
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░//
//░░░░░▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒░░░░░░░░░//
//░░░▓▓██▓▓▓█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒█▓▓▒░░░░░░░░//
//░░▒▓▓█░░░▓█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒█▓█▓▒░░░░░░░░//
//░░░▓▓▓▓▒▒░▒▓▓▓▓░░░▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓▓▓▓▒▓▓▓▓▒▓▓▓▓▓▒▓▓▓▒▒▒█▓▓▓▓█▓▓▓▓░░░█▓███▒▓░░░░░░░//
//░░░░▒▓▓▓▓▓▓░▓█▓▓░▓▓▓▓▒░░▓▓▓▒▓▒░▓▓▓░▒▓▒█▓█▒▒▓▓▓█▓▓▒▒▓█▓▓▓█▓▓▓▓▓▓▓░▓█▓▓░░░▓█▓▓▓▓▓▒▒░░░░░░//
//░░▓▓░░░░▓▓█▓▓██▓▓▓█▓▓▒░░▓▓▓░░░░▓▓▓░░░░▓▓▓▓▓▓▓▓█▓▓░░░█▓▓▒█▓██▓▓▓▒░▒█▓▓░░▒█▓▓▒▒██▓▒▒░░░░░//
//░░▓▓▓▒▒▒▓██▓▓█▒▓▓█▒▓▓▓▒░▓▓▓░░░░▓▓▓░░░░▓▓▓░░▓▓▓██▓▒░░▓▓▒░█▓▒▒██▓▓░▒█▓▓▒▒█▓▓▓░░▓█▓▓▓▒▒░░░//
//░░░▒▒▓▓▓▓▒▒▓▓▓▓▒▓▒▒▓▓▓▓▓▓▓▓▓░░▒▓▓▓▓░░▓▓▓▓▒▒▓▓▓▒▒▓▓▓▓▒░▒▓▓▓▓░░▒▓▒▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▒░░░//
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░//
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░//
///////////////////////////////////////////////////////////////////////////////////////////


pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721I.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Security {
    modifier onlySender() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
}

contract SmithoniaWeapons is Ownable, ERC721I, Security {
    uint256 public maxSupply = 12300;
    bool public mintIsActive = false;
    bool public publicMintIsActive = false;
    address public magicAddress;
    uint256 public minimumAmount;
    string private _baseTokenURI;
    mapping(address => bool) private minter;
    bytes32 public merkleRoot;

    constructor() ERC721I("Smithonia Weapons", "SMITHWEP") {}

    function mintWl(bytes32[] calldata _merkleProof) external onlySender {
        require(mintIsActive, "Blacksmith sleeping");
        require(maxSupply > totalSupply, "Armory empty");
        require(minimumAmount > 0, "Magic amount is not set");
        uint256 magicBalance = IERC20(magicAddress).balanceOf(
            address(msg.sender)
        );
        require(magicBalance >= minimumAmount, "Not enough magic");
        require(!minter[msg.sender], "You have already minted");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Not allowed to enter Smithonia"
        );
        minter[msg.sender] = true;
        uint256 id = totalSupply + 1;
        _mint(msg.sender, id);
        totalSupply++;
    }

    function publicMint() external onlySender {
        require(mintIsActive && publicMintIsActive, "Blacksmith sleeping");
        require(maxSupply > totalSupply, "Armory empty");
        require(!minter[msg.sender], "You have already minted");
        minter[msg.sender] = true;
        uint256 id = totalSupply + 1;
        _mint(msg.sender, id);
        totalSupply++;
    }

    /* ADMIN ESSENTIALS */

    function adminMint(uint256 quantity, address _target) external onlyOwner {
        require(maxSupply >= totalSupply + quantity, "Sold out");
        uint256 startId = totalSupply + 1;
        for (uint256 i = 0; i < quantity; i++) {
            _mint(_target, startId + i);
        }
        totalSupply += quantity;
    }

    function setBaseTokenURI(string memory baseURI) external onlyOwner {
        _setBaseTokenURI(baseURI);
    }

    function setMagicAddress(address _magicAddress) external onlyOwner {
        magicAddress = _magicAddress;
    }

    function setMinimumAmount(uint256 _minimumAmount) external onlyOwner {
        minimumAmount = _minimumAmount;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function toggleSale() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function togglePublicSale() public onlyOwner {
        publicMintIsActive = !publicMintIsActive;
    }
    /* ADMIN ESSENTIALS */

    function hasMinted(address _addr) public view returns (bool) {
        return minter[_addr];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* ERC721I - ERC721I (ERC721 0xInuarashi Edition) - Gas Optimized
    Open Source: with the efforts of the [0x Collective] <3 */

contract ERC721I {

    string public name; string public symbol;
    string internal baseTokenURI; string internal baseTokenURI_EXT;
    constructor(string memory name_, string memory symbol_) {
        name = name_; symbol = symbol_; 
    }

    uint256 public totalSupply; 
    mapping(uint256 => address) public ownerOf; 
    mapping(address => uint256) public balanceOf; 

    mapping(uint256 => address) public getApproved; 
    mapping(address => mapping(address => bool)) public isApprovedForAll; 

    // Events
    event Transfer(address indexed from, address indexed to, 
    uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, 
    uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, 
    bool approved);

    // // internal write functions
    // mint
    function _mint(address to_, uint256 tokenId_) internal virtual {
        require(to_ != address(0x0), 
            "ERC721I: _mint() Mint to Zero Address");
        require(ownerOf[tokenId_] == address(0x0), 
            "ERC721I: _mint() Token to Mint Already Exists!");

        balanceOf[to_]++;
        ownerOf[tokenId_] = to_;

        emit Transfer(address(0x0), to_, tokenId_);
    }

    // transfer
    function _transfer(address from_, address to_, uint256 tokenId_) internal virtual {
        require(from_ == ownerOf[tokenId_], 
            "ERC721I: _transfer() Transfer Not Owner of Token!");
        require(to_ != address(0x0), 
            "ERC721I: _transfer() Transfer to Zero Address!");

        // checks if there is an approved address clears it if there is
        if (getApproved[tokenId_] != address(0x0)) { 
            _approve(address(0x0), tokenId_); 
        } 

        ownerOf[tokenId_] = to_; 
        balanceOf[from_]--;
        balanceOf[to_]++;

        emit Transfer(from_, to_, tokenId_);
    }

    // approve
    function _approve(address to_, uint256 tokenId_) internal virtual {
        if (getApproved[tokenId_] != to_) {
            getApproved[tokenId_] = to_;
            emit Approval(ownerOf[tokenId_], to_, tokenId_);
        }
    }
    function _setApprovalForAll(address owner_, address operator_, bool approved_)
    internal virtual {
        require(owner_ != operator_, 
            "ERC721I: _setApprovalForAll() Owner must not be the Operator!");
        isApprovedForAll[owner_][operator_] = approved_;
        emit ApprovalForAll(owner_, operator_, approved_);
    }

    // token uri
    function _setBaseTokenURI(string memory uri_) internal virtual {
        baseTokenURI = uri_;
    }
    function _setBaseTokenURI_EXT(string memory ext_) internal virtual {
        baseTokenURI_EXT = ext_;
    }

    // // Internal View Functions
    // Embedded Libraries
    function _toString(uint256 value_) internal pure returns (string memory) {
        if (value_ == 0) { return "0"; }
        uint256 _iterate = value_; uint256 _digits;
        while (_iterate != 0) { _digits++; _iterate /= 10; } // get digits in value_
        bytes memory _buffer = new bytes(_digits);
        while (value_ != 0) { _digits--; _buffer[_digits] = bytes1(uint8(
            48 + uint256(value_ % 10 ))); value_ /= 10; } // create bytes of value_
        return string(_buffer); // return string converted bytes of value_
    }

    // Functional Views
    function _isApprovedOrOwner(address spender_, uint256 tokenId_) internal 
    view virtual returns (bool) {
        require(ownerOf[tokenId_] != address(0x0), 
            "ERC721I: _isApprovedOrOwner() Owner is Zero Address!");
        address _owner = ownerOf[tokenId_];
        return (spender_ == _owner 
            || spender_ == getApproved[tokenId_] 
            || isApprovedForAll[_owner][spender_]);
    }
    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        return ownerOf[tokenId_] != address(0x0);
    }

    // // public write functions
    function approve(address to_, uint256 tokenId_) public virtual {
        address _owner = ownerOf[tokenId_];
        require(to_ != _owner, 
            "ERC721I: approve() Cannot approve yourself!");
        require(msg.sender == _owner || isApprovedForAll[_owner][msg.sender],
            "ERC721I: Caller not owner or Approved!");
        _approve(to_, tokenId_);
    }
    function setApprovalForAll(address operator_, bool approved_) public virtual {
        _setApprovalForAll(msg.sender, operator_, approved_);
    }

    function transferFrom(address from_, address to_, uint256 tokenId_) 
    public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId_), 
            "ERC721I: transferFrom() _isApprovedOrOwner = false!");
        _transfer(from_, to_, tokenId_);
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_, 
    bytes memory data_) public virtual {
        transferFrom(from_, to_, tokenId_);
        if (to_.code.length != 0) {
            (, bytes memory _returned) = to_.staticcall(abi.encodeWithSelector(
                0x150b7a02, msg.sender, from_, tokenId_, data_));
            bytes4 _selector = abi.decode(_returned, (bytes4));
            require(_selector == 0x150b7a02, 
                "ERC721I: safeTransferFrom() to_ not ERC721Receivable!");
        }
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_) 
    public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    // 0xInuarashi Custom Functions
    function multiTransferFrom(address from_, address to_, 
    uint256[] memory tokenIds_) public virtual {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            transferFrom(from_, to_, tokenIds_[i]);
        }
    }
    function multiSafeTransferFrom(address from_, address to_, 
    uint256[] memory tokenIds_, bytes memory data_) public virtual {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            safeTransferFrom(from_, to_, tokenIds_[i], data_);
        }
    }

    // OZ Standard Stuff
    function supportsInterface(bytes4 interfaceId_) public pure returns (bool) {
        return (interfaceId_ == 0x80ac58cd || interfaceId_ == 0x5b5e139f);
    }

    function tokenURI(uint256 tokenId_) public view virtual returns (string memory) {
        require(ownerOf[tokenId_] != address(0x0), 
            "ERC721I: tokenURI() Token does not exist!");
        return string(abi.encodePacked(
            baseTokenURI, _toString(tokenId_), baseTokenURI_EXT));
    }
    // // public view functions
    // never use these for functions ever, they are expensive af and for view only 
    function walletOfOwner(address address_) public virtual view 
    returns (uint256[] memory) {
        uint256 _balance = balanceOf[address_];
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply;
        for (uint256 i = 0; i < _loopThrough; i++) {
            if (ownerOf[i] == address(0x0) && _tokens[_balance - 1] == 0) {
                _loopThrough++; 
            }
            if (ownerOf[i] == address_) { 
                _tokens[_index] = i; _index++; 
            }
        }
        return _tokens;
    }

    // not sure when this will ever be needed but it conforms to erc721 enumerable
    function tokenOfOwnerByIndex(address address_, uint256 index_) public 
    virtual view returns (uint256) {
        uint256[] memory _wallet = walletOfOwner(address_);
        return _wallet[index_];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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