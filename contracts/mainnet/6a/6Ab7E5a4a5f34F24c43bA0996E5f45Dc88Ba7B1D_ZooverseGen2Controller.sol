// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./BaseMint.sol";

/**
    Conditions:
        - Genesis and Whitelist happens same time
        - Addresses in claim gets a free mint, they can mint up to 2 at price .12
        - Addresses in diamond hand can mint up to 3 at price .12
        - Addresses in genesis can mint up to 2 at price .12
        - Addresses in whitelist can mint up to 1 at price .15
        - Addresses in waitlist can mint up to 1 at price .15
        - Public no sales, cannot mint through another contract, at price .18
 */

contract ZooverseGen2Controller is BaseMint {
    mapping(uint256 => mapping(address => bool)) private _whitelist;
    mapping (address => bool) private _claimed;

    uint256 private genesisLimit = 2;
    uint256 public genesisPrice = 0.12 ether;
    uint256 public whitelistPrice = 0.15 ether;
    uint256 private _lastSaleType;

    struct Sale {
        uint256 limit;
        uint256 liveIndex;
        bytes32 root;
    }

    mapping(uint256 => Sale) public sales;

    constructor() {
        // claim
        sales[1] = Sale(genesisLimit, 1, 0xe8673ee234e7ce0840f0c8b2df7486e7cad1433368b49d67ef3b6eac282ddb2d);
        // diamondhand
        sales[2] = Sale(genesisLimit + 1, 1, 0xb1915c4f45866c50eafd6e31b50005f7ee6e36130b2205d844d63be98e6ebcc1);
        // genesis
        sales[3] = Sale(genesisLimit, 1, 0xf9b463e9c56dd6e2cea744dd5e699ced04b36fd7c327b2614baaaedb38afa4fc);
        // whitelist
        sales[4] = Sale(1, 1, 0x1dd3a4f211ca8e7a0839f666370a647628d51b1718ffa362ce5d11b24bcfceda); 
        // waitlist
        sales[5] = Sale(1, 2, 0x8b357472e382e324c75a0b5af28d470e59c0c5c1d358315f512d967c1a3dca5d);
        _lastSaleType = 5;
    }

    modifier correctMintConditions(uint256 saleType, uint256 quantity, bytes32[] calldata proof) {
        require(currentStage == sales[saleType].liveIndex, "Not Live");
        require(nft.getAux(msg.sender) + quantity <= sales[saleType].limit, "Exceeds limit");
        require(isPermitted(saleType, msg.sender, proof), "Not verified user");        
        _;
    }

    function salesMint(uint256 quantity, bytes32[] calldata proof, uint256 saleType) 
        external 
        payable 
        callerIsUser
        correctMintConditions(saleType, quantity, proof) 
    {
        uint256 mintQuantity = quantity;
        if(saleType == 1) {
            if(!_claimed[msg.sender]) {
                unchecked {
                    mintQuantity++;
                }
                _claimed[msg.sender] = true;
            }
        }        
        require(msg.value >= quantity * discountedPrice(saleType), "Not enough eth");
        nft.setAux(msg.sender, uint64(nft.getAux(msg.sender) + quantity));
        _mint(mintQuantity, msg.sender);
    }

    function _verify(uint256 saleType, address account, bytes32[] calldata proof) internal view returns (bool) {
        return MerkleProof.verify(proof, sales[saleType].root, keccak256(abi.encodePacked(account)));
    }

    function isPermitted(uint256 saleType, address account, bytes32[] calldata proof) public view returns (bool) {
        return _verify(saleType, account, proof) || _whitelist[saleType][account];
    }

    function getSaleType(address account, bytes32[] calldata proof) public view returns (uint256) {        
        for(uint256 i = 1; i <= _lastSaleType;) {
            if(isPermitted(i, account, proof)) return i;
            unchecked {
                i++;   
            }
        }
        return 0;
    }

    function availableToMint(address account, bytes32[] calldata proof) public view returns (uint256) {
        if(currentStage == 1 || currentStage == 2) {
            uint256 balance = nft.getAux(account);
            uint256 saleType = getSaleType(account, proof);
            if(saleType == 0) return 0;
            return sales[saleType].limit - balance;
        }
        if(currentStage == 3) return maxPerTx;
        return 0;
    }

    function discountedPrice(uint256 saleType) public view returns (uint256) {
        if(saleType > 3) return whitelistPrice;
        return genesisPrice;
    }

    function updateSale(uint256 saleType, uint256 limit, uint256 liveIndex, bytes32 root) external adminOnly {
        require(saleType <= _lastSaleType || _lastSaleType + 1 == saleType, "Sale error");        
        Sale memory newSale;
        newSale.limit = limit;
        newSale.liveIndex = liveIndex;
        newSale.root = root;
        sales[saleType] = newSale;
        if(saleType > _lastSaleType) _lastSaleType = saleType;
    }

    function updateGenesisPrice(uint256 _price) external adminOnly {
        genesisPrice = _price;
    }

    function updateWhitelistPrice(uint256 _price) external adminOnly {
        whitelistPrice = _price;
    }

    function updateRoot(uint256 saleType, bytes32 _root) external adminOnly {
        sales[saleType].root = _root;
    }

    function addToWhitelist(uint256 saleType, address[] calldata to, bool[] calldata value) external adminOnly {
        uint256 total = to.length;
        for(uint256 i = 0; i < total;) {
            _whitelist[saleType][to[i]] = value[i];
            unchecked {
                i++;   
            }         
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./AdminController.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IERC721Token.sol";

contract BaseMint is AdminController {
    IERC721Token public nft;
    uint256 public price = 0.18 ether;
    uint256 public maxPerTx = 5;
    uint256 public currentStage;
    address public treasury = 0x6745a0b4fDF94Fb0AeD81FE7aC73bDF85aCF8310;

    function publicMint(uint256 quantity) payable external callerIsUser enoughPrice(quantity, price) {
        require(currentStage == 3, "Not Live");
        require(quantity <= maxPerTx, "Exceeds Limit");
        _mint(quantity, msg.sender);
    }

    function _mint(uint256 quantity, address to) internal {
        nft.mint(to, quantity);
    }

    function setNFT(IERC721Token _nft) public adminOnly {
        nft = _nft;
    }

    function setPrice(uint256 _price) public adminOnly {
        price = _price;
    }

    function setMaxPerTx(uint256 _max) public adminOnly {
        maxPerTx = _max;
    }

    function changeCurrentStage(uint256 stage) public adminOnly {
        currentStage = stage;
    }
    
    modifier callerIsUser {
        require(tx.origin == msg.sender, "Caller is not user");
        _;
    }

    modifier enoughPrice(uint256 quantity, uint256 mintCost) {
        require(msg.value >= quantity * mintCost, "Not enough eth");
        _;
    }

    function changeTreasury(address _treasury) external adminOnly {
        treasury = _treasury;
    }

    function withdraw() external adminOnly {
        uint256 balance = address(this).balance;
        payable(treasury).transfer(balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IAdminController.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract AdminController is IAdminController, Ownable {
    mapping(address => bool) public _admins;

    constructor() {
        _admins[msg.sender] = true;
    }    

    function isAdmin(address to) public view returns (bool) {
        return _admins[to];
    }

    modifier adminOnly() {
        require(_admins[msg.sender] || msg.sender == owner(), "Not authorised");
        _;
    }

    function setAdmins(address to, bool value) public adminOnly {
        _admins[to] = value;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./IAdminController.sol";

interface IERC721Token is IAdminController {
    function initialize(string memory _name, string memory _symbol, uint256 _supply, address owner) external;
    function mint(address to, uint256 quantity) external;
    function tokenURI(uint256) external view returns (string memory);
    function setURI(string memory) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function totalSupply() external view returns (uint256);
    function owner() external view returns (address);
    function supply() external view returns (uint256);
    function setSupply() external;
    function numberMinted(address) external view returns (uint256);
    function getAux(address) external view returns (uint256);
    function setAux(address, uint64) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IAdminController {
    function setAdmins(address to, bool value) external;
    function isAdmin(address) external view returns (bool);
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