/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol



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
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol



pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: contracts/ERC1155Minter.sol


pragma solidity ^0.8.7;



struct Collection {
    uint price;
    uint transactionLimit;
    uint mintLimit;
    bool saleStart;
    bool presaleStart;
    bytes32 merkleRoot;
}

interface IERC1155Burnable {
    function balanceOf(address account, uint256 id ) external view returns(uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount,  bytes calldata data) external;
    function burn(address account, uint256[] calldata tokenIds, uint256[] calldata amounts) external;
}

contract RareMFersMinter is ERC1155Holder {
    address public manifoldContract;
    address public owner;
    address private constant _admin = 0x8DFdD0FF4661abd44B06b1204C6334eACc8575af;

    mapping(uint => Collection) public collections;
    mapping(bytes32 => uint256) private minted;
    
    bool public adminAccess = true;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyTeam {
        require(msg.sender == owner || msg.sender == admin(), "Not team");
        _;
    }
    
    function mint(uint collectionId, uint qty) public payable {
        require(collections[collectionId].saleStart, "Sale not started");
        require(msg.value == collections[collectionId].price * qty, "ETH value");
        if(collections[collectionId].transactionLimit != 0){ require(qty <= collections[collectionId].transactionLimit); }
        if(collections[collectionId].mintLimit != 0){ 
            bytes32 collectionKey = keccak256(abi.encode(msg.sender, collectionId, manifoldContract));
            require(qty + minted[collectionKey] <= collections[collectionId].mintLimit, "Mint limit");
            minted[collectionKey] += qty;
        }
        
        IERC1155Burnable(manifoldContract).safeTransferFrom(address(this), msg.sender, collectionId, qty, "");
    }
    
    function mint(uint collectionId, uint qty, bytes32[] calldata _merkleProof) public payable {
        require(collections[collectionId].presaleStart, "Sale not started");
        require(msg.value == collections[collectionId].price * qty, "ETH value");
        if(collections[collectionId].transactionLimit != 0){ require(qty <= collections[collectionId].transactionLimit); }
        if(collections[collectionId].mintLimit != 0){ 
            bytes32 collectionKey = keccak256(abi.encode(msg.sender, collectionId, manifoldContract));
            require(qty + minted[collectionKey] <= collections[collectionId].mintLimit, "Mint limit");
            minted[collectionKey] += qty;
        }
        require(MerkleProof.verify(_merkleProof, collections[collectionId].merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Address not on list");
        
        
        IERC1155Burnable(manifoldContract).safeTransferFrom(address(this), msg.sender, collectionId, qty, "");
    }

    function burn(uint[] calldata collectionIds, uint[] calldata amounts) public onlyTeam {
        IERC1155Burnable(manifoldContract).burn(address(this), collectionIds, amounts);
    }

    function airdrop(uint collectionId, address[] memory recievers, uint[] memory amounts) public onlyTeam {
        require(recievers.length == amounts.length, "Bad input");
        for(uint i = 0; i < recievers.length; ++i){
            IERC1155Burnable(manifoldContract).safeTransferFrom(address(this), recievers[i], collectionId, amounts[i], "");
        }
    }

    function balanceOf(uint collectionId) public view returns(uint) {
        return IERC1155Burnable(manifoldContract).balanceOf(address(this), collectionId);
    }

    function admin() public view returns(address){
        return adminAccess? _admin : owner;
    }

    function toggleAdminAccess() external {
        require(msg.sender == owner, "Not owner");
        adminAccess = !adminAccess;
    }

    function addCollection(uint collectionId, uint price, uint transactionLimit, uint mintLimit) public onlyTeam {
       Collection memory newCollection =  Collection({ 
           price: price, 
           transactionLimit: transactionLimit,  
           mintLimit: mintLimit, 
           saleStart: false, 
           presaleStart: false,
           merkleRoot: 0x0000000000000000000000000000000000000000000000000000000000000000
        });
       
        collections[collectionId] = newCollection;
    }

    function getMinted(uint collectionId, address minter) public view returns(uint) {
        return minted[keccak256(abi.encode(minter, collectionId, manifoldContract))];
    }

    function setManifoldContract(address contractAddress) public onlyTeam {
        manifoldContract = contractAddress;
    }

    function updatePrice(uint collectionId, uint price) public onlyTeam {
        collections[collectionId].price = price;
    }

    function updatetransactionLimit(uint collectionId, uint limit) public onlyTeam {
        collections[collectionId].transactionLimit = limit;
    }

    function updateMintLimit(uint collectionId, uint limit) public onlyTeam {
        collections[collectionId].mintLimit = limit;
    }

    function toggleSale(uint collectionId) public onlyTeam {
        collections[collectionId].saleStart = !collections[collectionId].saleStart;
    }

    function togglePresale(uint collectionId) public onlyTeam {
        collections[collectionId].presaleStart = !collections[collectionId].presaleStart;
    }

    function updateMerkleRoot(uint collectionId, bytes32 root) public onlyTeam {
        collections[collectionId].merkleRoot = root;
    }

    function withdraw() external onlyTeam{
        payable(owner).transfer(address(this).balance);
    }

    fallback() payable external {}
    receive() payable external {}
}