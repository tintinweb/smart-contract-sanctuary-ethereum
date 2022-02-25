// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/// @dev Interfaces for safe transfer of NFTs
abstract contract ERC721Interface {
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual;
}

abstract contract ERC1155Interface {
  function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual;
}

/// @title A time-lock vault for NFTs with emergency unlock
/// @author Rick Liu

contract DiamondHand is Ownable, IERC721Receiver, IERC1155Receiver {
    uint256 constant ERC721     = 721;
    uint256 constant ERC1155    = 1155;
    address payable VAULT = payable(0x588634e63195380EC38ED2474Ea4EB692035ED5B);
    // uint256 constant secs = 86400; //seconds in a day

    using Counters for Counters.Counter;
    Counters.Counter private _diamondIds;
    
    /**
    * @dev Struct for NFT that is to be diamondhanded
    * @param dapp Address of the token contract (NFT to be diamondhanded)
    * @param tokenType Type of token (ERC721, ERC1155)
    * @param tokenID ID of token
    * @param blc Amount of ERC1155 tokens
    * @param data Other data
    */
    struct diamondStruct {
        address dapp;      
        uint256 tokenType;    
        uint256[] tokenId;      
        uint256[] blc;     
        bytes data;             
    }
    
    enum diamondStatus { Holding, Broken, Released} //Diamond Status (Holding for still diamondhanding, broken = used emergency break, released = claimed after time passed)

    /**
    * @dev Struct to hold diamond-hand information
    * @param id DiamondID (unique ID for each diamond-hand created)
    * @param diamondStartTime Timestamp of when this diamond-hand is initially created
    * @param releaseTime Timestamp of when this diamond-hand order is unlocked (when NFT becomes withdrawable)
    * @param beneficiary Address of the person creating this diamond-hand. The NFT will later be withdrawn to this address
    * @param breakPrice Price to unlock diamond-hand in case of emergency
    * @param status diamondStatus representing the status of this diamond-hand
    */
    struct diamondHands {
        uint256 id;
        uint256 diamondStartTime;
        uint256 releaseTime;
        address beneficiary;
        uint256 breakPrice;
        diamondStatus status;
    }
    
    mapping(uint256 => diamondStruct[]) diamondNFTs;    //NFT Mapping (maps a diamondhand ID to corresponding diamondStruct NFTs)
    mapping (address => diamondHands[]) diamondList;    //Mapping a user's address to their list of diamond hands
    mapping (uint256 => uint256) diamondMatch;      //Mapping diamondID to the index in a user's diamondList[address]
    
    // Events (indexed keyword allows us to filter through logs of events with the indexed parameter)
    event diamondEvent(uint256 indexed _diamondId, uint256 indexed _currentTime, uint256 _releaseTime, address indexed _creator, uint256 _breakPrice, diamondStatus _status);
    // event diamondEvent(diamondHands indexed _diamondHand, diamondStruct[] indexed _diamondStruct);

    /**
    * @notice Transfers NFT to contract and stores relevant diamond-hand information
    * @param _diamondHands diamondHands struct storing relevant information for this diamond-hand order (see struct declaration above)
    * @param _diamondNFT diamondStruct storing relevant information for the NFTs to be diamond-handed (see struct declaration above)
    * @param _releaseTime Timestamp when this diamond-hand is unlocked (when NFT becomes withdrawable)
    * @param _breakPrice Price to unlock diamond-hand in case of emergency
    * @return diamondID
    */
    function createDiamondHands(diamondHands memory _diamondHands, diamondStruct[] memory _diamondNFT, uint256 _releaseTime, uint256 _breakPrice) public returns (uint256) {
        require(_releaseTime > block.timestamp, "Release time is before current time");
        
        _diamondHands.id = _diamondIds.current();
        _diamondHands.beneficiary = msg.sender;
        _diamondHands.releaseTime = _releaseTime;
        _diamondHands.diamondStartTime = block.timestamp;
        _diamondHands.breakPrice = _breakPrice;
        _diamondHands.status = diamondStatus.Holding;
        
        diamondMatch[_diamondIds.current()] = diamondList[msg.sender].length; //Add to list of diamond-hands for this user
        diamondList[msg.sender].push(_diamondHands);

        uint256 i;
        //Add NFTs to list of diamond NFTs in contract
        for(i = 0; i < _diamondNFT.length; i++)
            diamondNFTs[_diamondHands.id].push(_diamondNFT[i]);
        
        for(i = 0; i < diamondNFTs[_diamondHands.id].length; i++) {
            if(diamondNFTs[_diamondHands.id][i].tokenType == ERC721) {
                ERC721Interface(diamondNFTs[_diamondHands.id][i].dapp).safeTransferFrom(_diamondHands.beneficiary, address(this), diamondNFTs[_diamondHands.id][i].tokenId[0], diamondNFTs[_diamondHands.id][i].data);
            }
            else if(diamondNFTs[_diamondHands.id][i].tokenType == ERC1155) {
                ERC1155Interface(diamondNFTs[_diamondHands.id][i].dapp).safeBatchTransferFrom(_diamondHands.beneficiary, address(this), diamondNFTs[_diamondHands.id][i].tokenId, diamondNFTs[_diamondHands.id][i].blc, diamondNFTs[_diamondHands.id][i].data);
            }
        }

        emit diamondEvent(_diamondHands.id, block.timestamp, _diamondHands.releaseTime, msg.sender, _diamondHands.breakPrice, _diamondHands.status);
        // emit diamondEvent(_diamondHands, _diamondNFT);
        _diamondIds.increment();
        return _diamondHands.id;
    }

    /**
    * @notice Release all the NFTs inside a specific diamondHand order (matched by _diamondId) if unlock time has passed
    * @param _diamondId Corresponding ID for the diamond-hand order and NFTs 
    */
    function releaseDiamond(uint _diamondId) public {
        diamondHands memory diamondHandOrder = getDiamondHandsByAddress(msg.sender, _diamondId);
        require(diamondHandOrder.status == diamondStatus.Holding, "This NFT is no longer being held");
        require(msg.sender == diamondHandOrder.beneficiary, "You must be the owner of this NFT to release it");
        require(block.timestamp >= diamondHandOrder.releaseTime, "Your NFT is not yet unlocked");

        //Release all the NFTs in this diamondHandOrder
        uint256 numNFTs = getDiamondStructSize(_diamondId);
        uint256 i;
        for (i = 0; i < numNFTs; i++){
            diamondStruct memory nftToRelease = getDiamondStruct(_diamondId, i);
            if (nftToRelease.tokenType == ERC721) {
                ERC721Interface(nftToRelease.dapp).safeTransferFrom(address(this), diamondHandOrder.beneficiary, nftToRelease.tokenId[0], nftToRelease.data);
            } else if (nftToRelease.tokenType == ERC1155) {
                ERC1155Interface(nftToRelease.dapp).safeBatchTransferFrom(address(this), diamondHandOrder.beneficiary, nftToRelease.tokenId, nftToRelease.blc, nftToRelease.data);
            }
        }
        //Update status
        diamondList[msg.sender][diamondMatch[_diamondId]].status = diamondStatus.Released;

        emit diamondEvent(_diamondId, block.timestamp, diamondHandOrder.releaseTime, msg.sender, diamondHandOrder.breakPrice, diamondStatus.Released);

        // emit diamondEvent(msg.sender, (block.timestamp-(block.timestamp%secs)), getDiamondHandsByAddress(msg.sender, _diamondId).status,getDiamondHandsByAddress(msg.sender, _diamondId).id);

    }

    /**
    * @notice Use emergency break to forcibly unlock (needs to pay what was specified)
    * @param _diamondId Corresponding ID for the diamond-hand order and NFTs 
    */
    function breakUnlock(uint _diamondId) payable public {
        //Check the diamondHand order of the corresponding id
        diamondHands memory diamondHandOrder = getDiamondHandsByAddress(msg.sender, _diamondId);
        require(diamondHandOrder.status == diamondStatus.Holding, "This NFT is no longer being held");
        require(msg.sender == diamondHandOrder.beneficiary, "You must be the owner of this NFT");
        require(msg.value >= diamondHandOrder.breakPrice, "Not enough WEI to unlock this NFT");
        
        //Release all the NFTs in this diamondHandOrder
        uint256 numNFTs = getDiamondStructSize(_diamondId);
        uint256 i;
        for (i = 0; i < numNFTs; i++){
            diamondStruct memory nftToRelease = getDiamondStruct(_diamondId, i);
            if (nftToRelease.tokenType == ERC721) {
                ERC721Interface(nftToRelease.dapp).safeTransferFrom(address(this), diamondHandOrder.beneficiary, nftToRelease.tokenId[0], nftToRelease.data);
            } else if (nftToRelease.tokenType == ERC1155) {
                ERC1155Interface(nftToRelease.dapp).safeBatchTransferFrom(address(this), diamondHandOrder.beneficiary, nftToRelease.tokenId, nftToRelease.blc, nftToRelease.data);
            }
        }
        //Transfer value to Vault
        VAULT.transfer(msg.value);

        //Update status
        diamondList[msg.sender][diamondMatch[_diamondId]].status = diamondStatus.Broken;
        emit diamondEvent(_diamondId, block.timestamp, diamondHandOrder.releaseTime, msg.sender, diamondHandOrder.breakPrice, diamondStatus.Broken);
        // emit diamondEvent(msg.sender, (block.timestamp-(block.timestamp%secs)), getDiamondHandsByAddress(msg.sender, _diamondId).status,getDiamondHandsByAddress(msg.sender, _diamondId).id);
    }

    /**
    * @dev Set Vault Address
    * @param _vault Address to be paid
    */
    function setVaultAddress(address payable _vault) public onlyOwner {
        VAULT = _vault ;
    }

    /**
    * @dev Get the list of diamond-hand orders an address has
    * @param _creator Address to get diamondlist for
    * @return Array of diamondHands
    */
    function getDiamondListOfAddress(address _creator) public view returns (diamondHands[] memory) {
        return diamondList[_creator];

    }

    /**
    * @dev Get diamondhand info by address and id
    * @param _creator Address to get diamondhand for
    * @param _diamondId Corresponding ID
    * @return diamondHand struct
    */
    function getDiamondHandsByAddress(address _creator, uint256 _diamondId) public view returns(diamondHands memory) {
        return diamondList[_creator][diamondMatch[_diamondId]];
    }
    
    /**
    * @dev Get length of diamondStruct by id
    * @param _diamondId Corresponding ID
    * @return uint256 number of NFTs being diamond-handed
    */
    function getDiamondStructSize(uint256 _diamondId) public view returns(uint256) {
        return diamondNFTs[_diamondId].length;
    }

    /**
    * @dev Get diamondStruct by ID and index
    * @param _diamondId Corresponding ID
    * @param _index Corresponding index within the list of NFTs being diamondhanded in this order
    * @return diamondStruct with relevant information about the NFT
    */
    function getDiamondStruct(uint256 _diamondId, uint256 _index) public view returns(diamondStruct memory) {
        return diamondNFTs[_diamondId][_index] ;
    }

    //Interface IERC721/IERC1155
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external override returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata id, uint256[] calldata value, bytes calldata data) external override returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return  interfaceID == 0x01ffc9a7 || interfaceID == 0x4e2312e0;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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