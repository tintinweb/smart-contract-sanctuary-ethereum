// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FLBSPStaking is ERC1155Holder, Ownable{
    IERC1155 public nft;
        

    constructor() {
        address nftAddress = 0x3546395057F96484b4377B143A2933DF90bcAD13; // Mainnet BS Pass NFT
        nft = IERC1155(nftAddress);
    }


    // mapping of a staker to its corresponding struct properties
    mapping(address => Staker) public stakers;
    // all addresses that have staked
    address[] public stakerAddresses;

    struct Staker {
        // tokenIds staked for this Staker and corresponding points in time staked
        uint256[] tokenIds;
        uint256[] timestamps;
        address tokenOwner;
        // boolean whether Staker object already has staked once
        bool created;
    }

    // stake single token specified by id
    function stake(uint256 tokenId) external {
        require(tokenId > 0 && tokenId < 4, "invalid ID");
        // transfer tokens
        nft.safeTransferFrom(msg.sender, address(this), tokenId, 1, "");
        // get staker struct
        Staker storage staker = stakers[msg.sender];
        if(!staker.created) {
            // set token owner
            staker.tokenOwner = msg.sender;
            // toggle boolean created
            staker.created = true;
            // add address to array of addresses
            stakerAddresses.push(msg.sender);
        }
        staker.tokenIds.push(tokenId);
        staker.timestamps.push(block.timestamp);
    }
    // stake multiple tokens of different ids in format ([id = 1, id = 2], [quantity = 1, quantity = 4])
    function batchStake(uint256[] memory tokenId, uint256[] memory quantity) external{
        nft.safeBatchTransferFrom(msg.sender, address(this), tokenId, quantity, "");
        Staker storage staker = stakers[msg.sender];
        for(uint256 i = 0; i < tokenId.length; i++)
        {
            for(uint256 j = 0; j < quantity[i]; j++) {
            // push newly staked token to array
            staker.tokenIds.push(tokenId[i]);
            // push current timestamp to array (stores down time when the token rewards were claimed last time)
            staker.timestamps.push(block.timestamp);
        }
        }
    }


    // unstake single token, specified by id and timestamp 
    function unstake(uint256 tokenId, uint256 timestamp) public {
       //require(_tokenId <= stakeNFT.totalSupply(), "invalid TokenId");
        require(tokenId > 0 && tokenId < 4, "invalid TokenId");
        // get staker struct
        Staker storage staker = stakers[msg.sender];
        
        // get last index of array
        uint256 lastIndex = staker.timestamps.length - 1;
        // get (key)value of last index
        uint256 lastIndexKeyTokenId = staker.tokenIds[lastIndex];
        uint256 lastIndexKeyTimestamp = staker.timestamps[lastIndex];
        // get index of token to unstake
        uint256 tokenIdIndex = getIndexForTokenId(tokenId, timestamp);


        // replace unstaked tokenId with last stored tokenId 
        // (order does not matter since timestamps have been updated during withdrawal)
        staker.tokenIds[tokenIdIndex] = lastIndexKeyTokenId;
        staker.timestamps[tokenIdIndex] = lastIndexKeyTimestamp;

        // pop last value of array tokenIds, timestamps 
        staker.tokenIds.pop();
        staker.timestamps.pop();
        // transfer single token back to user
        nft.safeTransferFrom(address(this), msg.sender, tokenId, 1, "");
        
    }


    function batchUnstake(
        uint256[] memory tokenId,
        uint256[] memory timestamps
        )
    public {
        for(uint256 i = 0; i < tokenId.length; i++) {
            unstake(tokenId[i], timestamps[i]);     
        }
    }

    function getIndexForTokenId(uint256 _tokenId, uint256 _timestamp) internal view returns(uint256) {
        require(_tokenId <= 3, "invalid TokenId");
        require(_tokenId > 0, "invalid TokenId");
        Staker storage _staker = stakers[msg.sender];
        for(uint256 i = 0; i < _staker.tokenIds.length; i++) {
            if(_staker.tokenIds[i] == _tokenId && _staker.timestamps[i] == _timestamp) {
                return i;
            }
        }
        revert();
    }



    // *--* read functions *---* //

    // // returns array with that format: [# of gold tokens, # of silver tokens, # of bronze tokens]
    function getQuantitiesForAddress(address user) public view returns(uint256[] memory){
        Staker storage staker = stakers[user];
        uint256[] memory staked = new uint256[](3);
        uint256 gold = 0;
        uint256 silver = 0;
        uint256 bronze = 0;
        for(uint256 i = 0; i < staker.tokenIds.length; i++) {
            if(staker.tokenIds[i] == 3) {
                bronze += 1;
            }
            else if(staker.tokenIds[i] == 2) {
                silver += 1;
            }
            else {
                gold += 1;
            }
        }
        staked[0] = gold;
        staked[1] = silver;
        staked[2] = bronze;
        return staked;
    }

    

    // returns 2 arrays, first an array of staked token ids (uint),
    // second an array of the corresponding timestamps (uint)
    function getInfoForAddress(address user) public view returns(uint256[] memory, uint256[] memory) {
        Staker storage staker = stakers[user];
        uint256 len = staker.tokenIds.length;
        // get tokens
        uint256[] memory tokens = new uint256[](len);
        for(uint256 i = 0; i < len; i++){
            tokens[i] = staker.tokenIds[i];
        }
        uint256[] memory timestamps = new uint256[](len);
        for(uint256 i = 0; i < len; i++){
            timestamps[i] = staker.timestamps[i];
        }
        // get timestamps

        return (tokens, timestamps);
    }
    // returns array amount of staked tokens in format [gold, silver, bronze]
    function amountStaked() public view returns(uint256[] memory) {
        uint256[] memory staked = new uint256[](3);
        staked[0] = nft.balanceOf(address(this),1);
        staked[1] = nft.balanceOf(address(this),2);
        staked[2] = nft.balanceOf(address(this),3);
        return staked;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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