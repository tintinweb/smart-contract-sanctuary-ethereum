/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: MIT LICENSE

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}





/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}



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



interface ICollection {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IYield {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract NFTPool is Ownable, IERC721Receiver, Pausable {

    // struct to store a collection data
    struct CollectionData {
        uint256 dailyYieldRate;
        address collection;
    }

    // struct to store a collection data
    struct StakerData {
        uint256 reward;
        uint256 lastUpdate;
        uint256[] tokenIds;
        mapping(uint256 => uint256) tokenIndexes; // to reduce gas when delete tokenId
    }

    event CollectionAdded(address collection);
    event NFTStaked(address collection, address owner, uint256 tokenId, uint256 value);
    event NFTUnstaked(address collection, uint256 tokenId, uint256 value);

    // reference to the token owner wallet
    address public wallet;
    // reference to the yield token contract for transfering reward earnings
    IYield public yield;

    // maps address to collection data
    mapping(address => CollectionData) public collectionDataMap;
    // maps collection, holder addresses to amount of reward
    mapping(address => mapping(address => StakerData)) public stakerDataMap;
    // maps tokenId of collection to owner
    mapping(address => mapping(uint256 => address)) public tokenOwner;

    // list of addresses of collection
    address[] public collectionList;

    /**
     * @param _collectiondata1~3 reference to collections
     * @param _wallet address of token wallet
     * @param _yield address of yield token
     */
    constructor(CollectionData memory _collectiondata1, CollectionData memory _collectiondata2, CollectionData memory _collectiondata3, address _wallet, address _yield) {
        setCollectionData(_collectiondata1);
        setCollectionData(_collectiondata2);
        setCollectionData(_collectiondata3);
        setWallet(_wallet);
        setYield(_yield);
    }

    /** STAKING */

    /**
     * adds NFTs to the Pool
     * @param collection the address of the collection
     * @param tokenIds the IDs of the NFTs to stake
     */
    function addManyToPool(address collection, uint16[] calldata tokenIds)
        external
    {
        require(tx.origin == _msgSender());

        _updateReward(collection, _msgSender());

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _addNFTToPool(collection, _msgSender(), tokenIds[i]);
        }
    }


    /** UNSTAKING */

    /**
     * realize yield earnings and optionally unstake tokens from the Pool
     * to unstake a NFT it will require it has cooldown worth of yield unclaimed
     * @param collection the address of the NFT collection
     * @param tokenIds the IDs of the tokens to claim earnings from
     */
    function unstakeManyFromPool(address collection, uint16[] calldata tokenIds)
        external
        whenNotPaused
    {
        require(tx.origin == _msgSender());

        _updateReward(collection, _msgSender());
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unstakeNFTFromPool(collection, tokenIds[i]);
            emit NFTUnstaked(collection, tokenIds[i], block.timestamp);
        }
    }


    /** HARVEST */

    /**
     * realize yield earnings and optionally unstake tokens from the Pool
     * to unstake a NFT it will require it has cooldown worth of yield unclaimed
     * @param collection the address of the NFT collection
     */
    function harvest(address collection)
        external
        whenNotPaused
    {
        require(tx.origin == _msgSender());

        _updateReward(collection, _msgSender());
        _getReward(collection, _msgSender());
    }


    // ** INTERNAL * //

    /**
     * update a staker data (reward, lastUpdate)
     * @param collection the address of the collection
     * @param account the address of the staker
     */
    function _updateReward(address collection, address account)
        internal
    {
		uint256 time = block.timestamp;

        stakerDataMap[collection][account].reward += stakerDataMap[collection][account].tokenIds.length * ((time - stakerDataMap[collection][account].lastUpdate) * collectionDataMap[collection].dailyYieldRate) / 1 days;
        stakerDataMap[collection][account].lastUpdate = time;
    }


    /**
     * adds a single NFT to the Pool
     * @param collection the address of the collection
     * @param account the address of the staker
     * @param tokenId the ID of the NFT to add to the Pool
     */
    function _addNFTToPool(address collection, address account, uint256 tokenId)
        internal
        whenNotPaused
    {
        ICollection(collection).transferFrom(account, address(this), tokenId); // send NFT to Pool
        
        stakerDataMap[collection][account].tokenIndexes[tokenId] = stakerDataMap[collection][account].tokenIds.length;
        stakerDataMap[collection][account].tokenIds.push(tokenId);

        tokenOwner[collection][tokenId] = account;
        
        emit NFTStaked(collection, account, tokenId, block.timestamp);
    }


    /**
     * realize yield earnings and optionally unstake tokens from the Pool
     * to unstake a NFT it will require it has cooldown worth of yield unclaimed
     * @param collection the address of the NFT collection
     * @param tokenId the ID of the NFT to claim earnings from
     */

    function _unstakeNFTFromPool(address collection, uint256 tokenId)
        internal
    {
        require(tokenOwner[collection][tokenId] == _msgSender(), "Not owner!");
                
        ICollection(collection).safeTransferFrom(
            address(this),
            _msgSender(),
            tokenId,
            ""
        ); // send back NFT
        
        // indexing, pop tokenId from tokenIds[]
        uint256 index = stakerDataMap[collection][_msgSender()].tokenIndexes[tokenId];
        
        stakerDataMap[collection][_msgSender()].tokenIds[index] = stakerDataMap[collection][_msgSender()].tokenIds[stakerDataMap[collection][_msgSender()].tokenIds.length - 1];
        stakerDataMap[collection][_msgSender()].tokenIds.pop();

        delete tokenOwner[collection][tokenId];
    }

    function _getReward(address collection, address _to) internal {
		uint256 reward = stakerDataMap[collection][_to].reward;
		if (reward > 0) {
            stakerDataMap[collection][_to].reward = 0;
            yield.transferFrom(wallet, _msgSender(), reward);
		}
	}


    /** VIEW */

    function getTotalClaimable(address collection, address account) external view returns(uint256) {
		uint256 time = block.timestamp;
		uint256 pending = stakerDataMap[collection][account].tokenIds.length * ((time - stakerDataMap[collection][account].lastUpdate) * collectionDataMap[collection].dailyYieldRate) / 1 days;
		return stakerDataMap[collection][account].reward + pending;
	}


    /** ADMIN */

    function setWallet(address _wallet) public onlyOwner {
        wallet = _wallet;
    }

    function setYield(address _yield) public onlyOwner {
        yield = IYield(_yield);
    }

    function setCollectionData(CollectionData memory _collectiondata) public onlyOwner {
        if (collectionDataMap[_collectiondata.collection].collection != _collectiondata.collection) {
            collectionList.push(_collectiondata.collection);
        }

        collectionDataMap[_collectiondata.collection] = CollectionData(
            _collectiondata.dailyYieldRate,
            _collectiondata.collection
            );

        emit CollectionAdded(_collectiondata.collection);
    }
    
    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    
    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to Pool directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}