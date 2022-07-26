/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// SPDX-License-Identifier: MIT
// File: test/contracts/unpacker v3/interfaces/IERC1155.sol


pragma solidity ^0.8.7;

interface IERC1155
{
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function burn(
        uint256 id,
        uint256 amount
    ) external;

    function getAuthStatus(address account) external view returns (bool);
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: test/contracts/unpacker v3/unpacker.sol


pragma solidity ^0.8.7;




contract unpacker is Ownable
{
    modifier isInActive(uint _packId)
    {
        require(!config[_packId].active, "To modify existing config you have to mark config as inactive before");
        _;
    }

    struct packConfig
    {
        bool           active;
        uint256        unlockTime;   
    }

    struct result
    {
        uint256     packId;
        address     owner;
        bool        error;
        reward[]    rewards;
    }

    struct reward
    {
        uint256 tokenId;
        uint256 amount;
    }

    mapping(uint256 => packConfig)  private config;
    mapping(uint256 => uint256) private index2PackId; // (owner, index) => packId
    mapping(uint256 => uint256) private packId2Index; // packId => index in config array

    mapping(uint256 => result) private requestResults;
    uint256 private unboxedPacks;
    uint256 private packsConfigCount;

    // to interact with collection
    IERC1155 private parentNFT;

    constructor(IERC1155 _parentNFT)
    {
        parentNFT = _parentNFT;
        unboxedPacks = 0;
        packsConfigCount = 0;
    }

    event unboxStarted(address owner, uint256 tokenId, uint256 requestId);
    event resultsReceived(uint256 requestId, reward[] rewards, bool error);
    event resultsClaimed(address owner, uint256 requestId, reward[] rewards);
    event receivePackBack(address owner, uint256 packId, uint256 requestId);

    function unbox(uint _packId) public returns(uint256)
    {
        packConfig memory mr_packConfig = config[_packId];
        address sender = msg.sender;

        require(parentNFT.getAuthStatus(address(this)) == true, "Unpacker contract is not authorized within the collection");
        require(mr_packConfig.active, "Config for this pack is inactive or has not been initialized");
        require(block.timestamp >= mr_packConfig.unlockTime, "The pack has not unlocked yet");

        parentNFT.safeTransferFrom(sender, address(this), _packId, 1, "0x00");

        uint request_id = ++unboxedPacks;
        requestResults[request_id].packId = _packId;
        requestResults[request_id].owner = sender;

        emit unboxStarted(sender, _packId, request_id);

        return request_id;
    }

    function claim(uint256 requestId)public
    {
        address owner = msg.sender;
        result memory res = requestResults[requestId];
        require(owner == res.owner, "Missing authorization of owner");

        if(!res.error)
        {
            require(res.rewards.length > 0, "Rewards is not initialized or has been claimed");
        
            for(uint256 i = 0; i < res.rewards.length; ++i)
            {
                parentNFT.mint(owner, res.rewards[i].tokenId, res.rewards[i].amount, '0x00');
            }

            emit resultsClaimed(owner, requestId, res.rewards);
            parentNFT.burn(res.packId, 1);
        }
        else
        {
            parentNFT.safeTransferFrom(address(this), owner, res.packId, 1, "0x00");
            emit receivePackBack(owner, res.packId, requestId);
        }

        delete requestResults[requestId];
    }

    // ------------------- SAFE --------------------

    function withdrawAssets(uint256 tokenId, uint256 amount, address withdrawAddr) public onlyOwner
    {
        parentNFT.safeTransferFrom(address(this), withdrawAddr, tokenId, amount, "0x00");
    }

    function burnAsset(uint256 tokenId, uint256 amount)public onlyOwner
    {
        parentNFT.burn(tokenId, amount);
    }

    function clearResults(uint256 request_id)public onlyOwner
    {
        delete requestResults[request_id];
    }

    // ---------------------------------------------


    // ------------------- GET ---------------------

    function getConfig(uint256 _packId)public view returns(packConfig memory)
    {
        return config[_packId];
    }

    function getRequest(uint256 request_id)public view returns(result memory)
    {
        return requestResults[request_id];
    }

    function getUnboxedCount()public view returns(uint256)
    {
        return unboxedPacks;
    }

    function getPacksConfigCount()public view returns(uint256)
    {
        return packsConfigCount;
    }

    function getIndex2PackId(uint256 index)public view returns(uint256)
    {
        return index2PackId[index];
    }
    // ---------------------------------------------


    // ------------------- SETUP -------------------

    function setUnlockTime(uint _packId, uint newUnlockTime)public onlyOwner isInActive(_packId)
    {
        config[_packId].unlockTime = newUnlockTime;
    }

    function revertConfigStatus(uint _packId)public onlyOwner
    {
        config[_packId].active = !config[_packId].active;

        if(config[_packId].active)
        {
            _addPackConfigEnumeration(_packId);
        }
        else
        {
            _removePackConfigFromEnumeration(_packId);
        }
    }

    function deleteConfig(uint256 _packId)public onlyOwner isInActive(_packId)
    {
        delete config[_packId];
    }

    function dropResults(uint256 request_id, reward[] memory rewards, bool error)public onlyOwner
    {
        result storage res = requestResults[request_id];
        if(res.rewards.length > 0)  delete res.rewards;
        for(uint i = 0; i < rewards.length; ++i)
        {
            res.rewards.push(rewards[i]);
        }

        // if error == true, owner will have opportunity to return pack
        res.error = error;

        emit resultsReceived(request_id, rewards, error);
    }

    // ---------------------------------------------

    // adding info for mapping to track configs
    function _addPackConfigEnumeration(uint256 _packId) private 
    {
        index2PackId[packsConfigCount] = _packId;
        packId2Index[_packId] = packsConfigCount;
        ++packsConfigCount;
    }

    // removing info from mapping abount staked tokens
    function _removePackConfigFromEnumeration(uint256 _packId) private 
    {
        uint256 lastTokenIndex = packsConfigCount - 1;
        uint256 tokenIndex = packId2Index[_packId];

        if (tokenIndex != lastTokenIndex) 
        {
            uint256 lastTokenId = index2PackId[lastTokenIndex];

            index2PackId[tokenIndex] = lastTokenId;
            packId2Index[lastTokenId] = tokenIndex;
        }

        delete packId2Index[_packId];
        delete index2PackId[lastTokenIndex];
        --packsConfigCount;
    }
    
    function onERC1155Received(
        address ,
        address ,
        uint256 ,
        uint256 ,
        bytes calldata 
    ) external virtual returns (bytes4) 
    {
        return this.onERC1155Received.selector;
    }
}