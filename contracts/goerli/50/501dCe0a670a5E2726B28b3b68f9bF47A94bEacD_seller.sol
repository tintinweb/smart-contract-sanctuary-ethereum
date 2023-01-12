/**
 *Submitted for verification at Etherscan.io on 2023-01-12
*/

// SPDX-License-Identifier: MIT

// File: test/contracts/buy packs/interfaces/IERC1155.sol


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

    function getAuthStatus(address account) external view returns (bool);
}
// File: test/contracts/buy packs/interfaces/IERC20.sol


pragma solidity ^0.8.0;

interface IERC20 
{
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// File: test/contracts/buy packs/packSeller.sol


pragma solidity ^0.8.6;




contract seller is Ownable
{
    modifier isInActive(IERC20 token, uint _packId)
    {
        require(!config[token][_packId].active, "To modify existing config you have to mark config as inactive before");
        _;
    }

    constructor(IERC1155 _parentNFT)
    {
        parentNFT = _parentNFT;
    }
    
    struct packConfig
    {
        uint    packPrice;              // price setted by value of token (decimals must be considered)
        uint    unlockTime;             // 0 if available initially
        uint16  availableTotalCount;   // number of packs that can be purchased for all users (by default it will be 0)
        uint8   availableCountPerAccount; // number of packs available for purchasing per 1 account
        bool    active;
    }

    event packPurchased(address owner, uint packId, uint amount);
    event packConfigIsActive(IERC20 token, uint packId);
    event packConfigIsInactive(IERC20 token, uint packId);

    IERC1155 private parentNFT;
    mapping(IERC20 => mapping(uint => packConfig)) config;
    mapping(IERC20 => mapping(uint256 => uint256)) private index2PackId; // (owner, index) => packId
    mapping(IERC20 => mapping(uint256 => uint256)) private packId2Index; // packId => index in config array
    mapping(IERC20 => uint256) private packsConfigCount;

    // to follow up user purchases 
    mapping(address => mapping(IERC20 => mapping(uint => uint8))) public accountPurchasing;

    function buyPackWithTokens(IERC20 token, uint packId, uint8 amount)public
    {
        address owner = msg.sender;
        require(amount > 0, "The number of packs must be greater than 0");

        if(config[token][packId].packPrice > 0)
            token.transferFrom(owner, address(this), config[token][packId].packPrice * amount);
    
        _buyPack(owner, token, packId, amount);
    }
    
    function buyPackWithNativeToken(uint packId, uint8 amount)public payable
    {   
        // instead of token address will be a contract address to match config for native token
        IERC20 token = IERC20(address(this));
        address owner = msg.sender;
        uint value = msg.value; // 18 decimals

        require(amount > 0, "The number of packs must be greater than 0");
        require(config[token][packId].packPrice * amount == value, "Invalid value for this pack price");

        _buyPack(owner, token, packId, amount);
    }

    function _buyPack(address owner, IERC20 token, uint packId, uint8 amount) private
    {
        packConfig memory currentConfig = config[token][packId];

        require(currentConfig.active, "This pack config is inactive");
        require(currentConfig.unlockTime <= block.timestamp, "This pack config has not started yet");
        require(currentConfig.availableTotalCount >= amount, "There is no available packs to buy in this amount");
        require(accountPurchasing[owner][token][packId] + amount  <= currentConfig.availableCountPerAccount,
            "The buyer has bought the maximum allowed number of packs for this configuration");
        require(parentNFT.getAuthStatus(address(this)), "packSeller contract is not authorized within the collection" );

        // if(token != IERC20(address(this)))
        // {
        //     require(token.allowance(owner, address(this)) == currentConfig.packPrice * amount,
        //         "The buyer must approve amount of tokens equal to pack price * amount");
        // }

        parentNFT.mint(owner, packId, amount, '0x00');
        config[token][packId].availableTotalCount -= amount;
        accountPurchasing[owner][token][packId] += amount;

        emit packPurchased(owner, packId, amount);
    }       
    // ---------------------------- ADMIN ------------------------
    
    function setPackPrice(IERC20 token, uint packId, uint newPrice)public onlyOwner isInActive(token, packId)
    {
        config[token][packId].packPrice = newPrice;
    }

    function setUnlockTime(IERC20 token, uint packId, uint newUnlockTime)public onlyOwner isInActive(token, packId)
    {
        config[token][packId].unlockTime = newUnlockTime;
    }

    function setavAilableCountPerAccount(IERC20 token, uint packId, uint8 newAvailableCountPerAccount)public onlyOwner isInActive(token, packId)
    {
        config[token][packId].availableCountPerAccount = newAvailableCountPerAccount;
    }

    function setAvailableTotalCount(IERC20 token, uint packId, uint16 newAvailableTotalCount)public onlyOwner isInActive(token, packId)
    {
        config[token][packId].availableTotalCount = newAvailableTotalCount;
    }

    function revertConfigStatus(IERC20 token, uint _packId)public onlyOwner
    {
        config[token][_packId].active = !config[token][_packId].active;

        if(config[token][_packId].active)
        {
            require(config[token][_packId].availableTotalCount > 0, "availableTotalCount was not initilized");
            require(config[token][_packId].availableCountPerAccount > 0, "availableCountPerAccount was not initilized");

            emit packConfigIsActive(token, _packId);
            _addPackConfigEnumeration(token, _packId);
        }
        else
        {
            emit packConfigIsInactive(token, _packId);
            _removePackConfigFromEnumeration(token, _packId);
            
        }
    }

    function deleteConfig(IERC20 token, uint packId)public onlyOwner
    {
        delete config[token][packId];
    }

    function fixOwnerPurchasing(address owner, IERC20 token, uint packId, uint8 fixeAmount)public onlyOwner
    {
        accountPurchasing[owner][token][packId] = fixeAmount;
    }

    function withdrawNativeToken(address payable to, uint amount)public onlyOwner
    {
        to.transfer(amount);
    }

    function withdrawToken(IERC20 token, address to, uint amount)public onlyOwner
    {
        token.transfer(to, amount);
    }

    // ------------------- GET ----------------------------------

    function getConfig(IERC20 token, uint256 packId)public view returns(packConfig memory)
    {
        return config[token][packId];
    }

    function getPacksConfigCount(IERC20 token)public view returns(uint256)
    {
        return packsConfigCount[token];
    }

    function getIndex2PackId(IERC20 token, uint256 index)public view returns(uint256)
    {
        return index2PackId[token][index];
    }
    // -----------------------------------------------------------



    // ------------------------ HELP FUNCTIONS -------------------

    // adding info for mapping to track configs
    function _addPackConfigEnumeration(IERC20 token, uint256 _packId) private 
    {
        index2PackId[token][packsConfigCount[token]] = _packId;
        packId2Index[token][_packId] = packsConfigCount[token];
        ++packsConfigCount[token];
    }

    // removing info from mapping abount staked tokens
    function _removePackConfigFromEnumeration(IERC20 token, uint256 _packId) private 
    {
        uint256 lastTokenIndex = packsConfigCount[token] - 1;
        uint256 tokenIndex = packId2Index[token][_packId];

        if (tokenIndex != lastTokenIndex) 
        {
            uint256 lastTokenId = index2PackId[token][lastTokenIndex];

            index2PackId[token][tokenIndex] = lastTokenId;
            packId2Index[token][lastTokenId] = tokenIndex;
        }

        delete packId2Index[token][_packId];
        delete index2PackId[token][lastTokenIndex];
        --packsConfigCount[token];
    }
    // ---------------------------------------------------------
}