// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./DiamondVault.sol";
import "./DiamondProxy.sol";

/// @title A factory to create DiamondVaults (Used for Diamond-Handing assets through time-locks) 
/// @author Momo Labs

contract DiamondHandFactory is Ownable {
    using Counters for Counters.Counter;
    /// @dev Number of DiamondVaults
    Counters.Counter private vaultCount;

    /// @dev Mapping of vault number to vault contract address
    mapping(uint256 => address) vaults;

    /// @dev Mapping of user's wallet to vault number
    mapping(address => uint256) userToVault;

    /// @dev the DiamondVault logic contract
    address public immutable logic;

    address public DIAMONDPASS; //Address of DiamondPass NFT. Holders can create Diamond-Hands for free
    uint256 public PRICE = 0.01 ether;
    uint256 public minBreakPrice = 0.1 ether;   //Minimum emergency unlock price
    mapping (bytes32 => bool) isDiamondSpecial;    //Mapping an NFT project's contract address to whether or not they are on the diamondSpecial. Can be used to reward top communities with free Diamond-Hand usage

    event DiamondVaultCreated(address indexed vaultAddress, uint256 indexed vaultCount);
    event ReceivedPayment(address indexed sender);

    constructor() {
        logic = address(new DiamondVault());
    }

    /**
    * @notice Creates a DiamondVault through initializing proxy
    * @return address of the created DiamondVault
    */
    function createDiamondVault() external returns(address) {
        bytes memory _initializationCalldata =
        abi.encodeWithSignature(
            "initialize(uint256,address,address)",
            vaultCount.current(),
            msg.sender,
            address(this)
        );

        address vaultAddress = address(new DiamondProxy(logic, _initializationCalldata));

        emit DiamondVaultCreated(vaultAddress, vaultCount.current());
        
        vaults[vaultCount.current()] = vaultAddress;
        userToVault[msg.sender] = vaultCount.current();
        vaultCount.increment();
        return vaultAddress;
    }

    receive() external payable {
        emit ReceivedPayment(msg.sender);
    }

    /**
    * @dev Fetch user's vault address
    * @param _walletAddress Address of user
    * @return address of user's vault
    */
    function getVaultAddress(address _walletAddress) public view returns(address) {
        return vaults[userToVault[_walletAddress]];
    }

    /**
    * @dev Fetch total number of vaults
    * @return uint256 number of vaults
    */
    function getVaultCount() public view returns(uint256) {
        return vaultCount.current();
    }

    /**
    * @dev See if specified contract address isDiamondSpecial
    * @param _contractAddress NFT's contract address
    * @param _tokenId Token ID of NFT (used for ERC1155 NFTs)
    * @return bool If address isDiamondSpecial
    */
    function checkDiamondSpecial(address _contractAddress, uint256 _tokenId) public view returns(bool) {
        return isDiamondSpecial[keccak256(abi.encodePacked(_contractAddress, _tokenId))];
    }

    /**
    * @dev Withdraw ETH
    */
    function withdraw() external onlyOwner(){
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /**
    * @dev Set a list of NFT contract addresses as true/false for isDiamondSpecial
    * @param _contractAddresses Array of contract addresses
    * @param _tokenIds Array of token IDs (used for ERC1155 NFTs)
    * @param isOnList Boolean, whether or not these addresses should be mapped to true or false in isDiamondSpecial
    */
    function setDiamondSpecial(address[] memory  _contractAddresses, uint256[] memory _tokenIds, bool isOnList) external onlyOwner {
        uint256 i;
        for (i = 0; i < _contractAddresses.length; i ++){
            isDiamondSpecial[keccak256(abi.encodePacked(_contractAddresses[i], _tokenIds[i]))] = isOnList;
        }
    }

     /**
    * @dev Set DIAMONDPASS NFT Address
    * @param _newAddress New address to be set
    */
    function setDiamondPassAddress(address _newAddress) external onlyOwner {
        DIAMONDPASS = _newAddress;
    }

    /**
    * @dev Set Price of Creating Diamond-Hand
    * @param _price of creating Diamond-Hand
    */
    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price ;
    }

    /**
    * @dev Set minimum emergency unlock price when Diamond-Handing
    * @param _minPrice New minimum emergency unlock price when creating a Diamond-Hand
    */
    function setMinBreakPrice(uint256 _minPrice) external onlyOwner {
        minBreakPrice = _minPrice ;
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

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IFactory {
    function DIAMONDPASS() external view returns (address);
    function PRICE() external view returns (uint256);
    function minBreakPrice() external view returns (uint256);
    function checkDiamondSpecial(address _contractAddress, uint256 _tokenId) external view returns(bool);
}

abstract contract ERC721Interface {
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public virtual;
  function balanceOf(address _owner) public virtual view returns (uint256);
}

abstract contract ERC1155Interface {
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) public virtual;
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory i_ds, uint256[] memory _amounts, bytes memory _data) public virtual;
  function balanceOf(address _owner, uint256 _id) external virtual view returns (uint256);
}

/// @title A time-locked vault for ERC721, ERC1155, ERC20 and ETH with emergency unlock functionality. Supports withdrawal of airdropped tokens
/// @author Momo Labs

contract DiamondVault is Initializable, ReentrancyGuard, ERC721Holder, ERC1155Holder {
    address payable factoryContractAddress;     //Address of factory contract that deployed this vault
    address public vaultOwner;                  
    uint256 public vaultNumber;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    Counters.Counter private diamondIds;

    /** Structs & Enums **/
    enum diamondStatus { Holding, Broken, Released} //Diamond Status (Holding for still diamond-handing, broken = used emergency break, released = claimed after time passed)
    enum assetType { ERC721, ERC1155, ERC20, ETH} //Type of asset being diamond-handed

    /**
    * @dev Struct for asset that is to be diamond-handed
    * @param contractAddress Address of the token contract that is to be diamond-handed
    * @param tokenType AssetType referring to type of asset being diamond-handed (ERC721, ERC1155, ERC20, or ETH)
    * @param tokenID ID of token
    * @param quantity Amount (for ERC1155 tokens, ERC20, and ETH)
    * @param data Other data
    */
    struct diamondStruct {
        address contractAddress;      
        assetType tokenType;    
        uint256[] tokenId;      
        uint256[] quantity;     
        bytes data;             
    }

     /**
    * @dev Struct to hold diamond-hand information
    * @param id DiamondID (unique ID for each diamond-hand created)
    * @param diamondStartTime Timestamp of when this diamond-hand is initially created
    * @param releaseTime Timestamp of when this diamond-hand order is unlocked (when asset becomes withdrawable)
    * @param breakPrice Price to unlock diamond-hand in case of emergency
    * @param status diamondStatus representing the status of this diamond-hand
    */
    struct diamondHands {
        uint256 id;
        uint256 diamondStartTime;
        uint256 releaseTime;
        uint256 breakPrice;
        diamondStatus status;
    }

    /**
    * @dev Struct to store information of NFTs on the diamondSpecial list. diamondSpecial can be used to reward certain communities with free Diamond-Hand usage
    * @param contractAddress Address of the NFT
    * @param tokenId tokenId of the NFT
    * @param tokenType Type of the NFT (ERC721 or ERC1155)
    */
    struct diamondSpecialStruct {
        address contractAddress;
        uint256 tokenId;
        assetType tokenType;
    }
    
    //MAPPINGS 
    mapping (uint256 => diamondStruct[]) private diamondAssets;    //Asset Mapping (maps a diamondhand ID to corresponding diamondStruct asset)
    mapping (uint256 => diamondHands) private diamondList;    //Mapping a diamondhand ID to corresponding diamondHand information
    mapping (bytes32 => bool) private currentlyDiamondHanding;    //Mapping to check if an asset is currently being diamondHanded (used to separate assets when claiming airdrops)
    mapping (bytes32 => uint256) private currentlyDiamondHandingQuantities;    //Mapping to check quantities of an asset being diamondhanded (ERC1155, ERC20, ETH)

    /** EVENTS **/
    event DiamondHandCreated(uint256 indexed _diamondId, uint256 _currentTime, uint256 indexed _releaseTime, uint256 _breakPrice, diamondStatus _status);
    event DiamondHandBroken(uint256 indexed _diamondId, uint256 indexed _currentTime, uint256 _releaseTime, uint256 _breakPrice, diamondStatus _status);
    event DiamondHandReleased(uint256 indexed _diamondId, uint256 indexed _currentTime, uint256 _releaseTime, uint256 _breakPrice, diamondStatus _status);
    event WithdrawnERC20(address indexed _contractAddress);
    event WithdrawnERC721(address indexed _contractAddress, uint256 indexed _tokenId);
    event WithdrawnERC1155(address indexed _contractAddress, uint256 indexed _tokenId);
    event WithdrawnETH();
    event ReceivedEther(address indexed sender);


    
      /**
    * @notice Initializer to initialize proxy from factory
    * @param _vaultNumber The vault number of this proxy
    * @param _vaultOwner The owner of this vault (set to whoever called createDiamondVault in factory contract)
    * @param _vaultFactoryContractAddress The address of factory contract
    */
    function initialize(
        uint256 _vaultNumber,
        address _vaultOwner,
        address _vaultFactoryContractAddress
    ) public initializer {
        vaultNumber = _vaultNumber;
        vaultOwner = _vaultOwner;
        factoryContractAddress = payable(_vaultFactoryContractAddress);
    }

    /**
    * @dev Modifier for functions to restrict to vaultOwner
    */
    modifier onlyVaultOwner() {
        require(
            msg.sender == vaultOwner,
            "Must be owner"
        );
        _;
    }

    /**
    * @notice Transfers asset to contract and stores relevant diamond-hand information
    * @param _diamondAsset diamondStruct storing relevant information for the asset to be diamond-handed (see struct declaration above)
    * @param _releaseTime Timestamp when this diamond-hand is unlocked (when asset becomes withdrawable)
    * @param _breakPrice Price to unlock diamond-hand in case of emergency
    * @param _diamondSpecial diamondSpecialStruct, if user owns an NFT that is on the diamondSpecial list, they can createDiamondHands for free
    */
    function createDiamondHands(diamondStruct memory _diamondAsset, uint256 _releaseTime, uint256 _breakPrice, diamondSpecialStruct memory _diamondSpecial) payable external nonReentrant onlyVaultOwner {
        require(_releaseTime > block.timestamp, "Release time in the past");
        require(_breakPrice >= getMinBreakPrice(), "Break price too low");

        bool needsPayment = false;
        if (ERC721Interface(getDiamondPassAddress()).balanceOf(msg.sender) == 0){
            //If caller does not have a diamond pass
            if (checkDiamondSpecial(_diamondSpecial.contractAddress, _diamondSpecial.tokenId)){
                if(_diamondSpecial.tokenType == assetType.ERC721){
                    if(ERC721Interface(_diamondSpecial.contractAddress).balanceOf(msg.sender) == 0 ){
                        //If caller claims they have an NFT that is on the diamondSpecial but actually doesn't
                        require(msg.value >= getPrice(), "Not enough ETH");
                        needsPayment = true;
                    }
                } else if (_diamondSpecial.tokenType == assetType.ERC1155){
                    if(ERC1155Interface(_diamondSpecial.contractAddress).balanceOf(msg.sender, _diamondSpecial.tokenId) == 0){
                        //If caller claims they have an NFT that is on the diamondSpecial but actually doesn't
                        require(msg.value >= getPrice(), "Not enough ETH");
                        needsPayment = true;
                    }
                }
            } else {
                //If caller does not have an NFT on diamondSpecial
                require(msg.value >= getPrice(), "Not enough ETH");
                needsPayment = true;
            }
        }
        //Create diamondHand information
        diamondHands memory _diamondHands;
        
        _diamondHands.id = diamondIds.current();
        _diamondHands.releaseTime = _releaseTime;
        _diamondHands.diamondStartTime = block.timestamp;
        _diamondHands.breakPrice = _breakPrice;
        _diamondHands.status = diamondStatus.Holding;

        diamondList[_diamondHands.id] = (_diamondHands);

        uint256 depositedETH;   //Used to keep track of additional ETH deposited by user (if they choose to diamond-hand ETH)
        
        //Add assets to list of diamondAssets in contract
        require(_diamondAsset.tokenType == assetType.ERC721 || _diamondAsset.tokenType == assetType.ERC1155 || _diamondAsset.tokenType == assetType.ERC20 || _diamondAsset.tokenType == assetType.ETH, "diamondAsset not supported");
        require(_diamondAsset.tokenId.length == _diamondAsset.quantity.length, "tokenId & quantity mismatch");
        diamondAssets[_diamondHands.id].push(_diamondAsset);

        //Transfer asset to vault for storage
        if(_diamondAsset.tokenType == assetType.ERC721) {
            require(_diamondAsset.tokenId.length == 1, "Invalid tokenId quantity");
            currentlyDiamondHanding[keccak256(abi.encodePacked(_diamondAsset.contractAddress, _diamondAsset.tokenId[0]))] = true;
            ERC721Interface(_diamondAsset.contractAddress).safeTransferFrom(msg.sender, address(this), _diamondAsset.tokenId[0], _diamondAsset.data);
        }
        else if(_diamondAsset.tokenType == assetType.ERC1155) {
            for(uint256 i; i < _diamondAsset.tokenId.length; i++){
                currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(_diamondAsset.contractAddress, _diamondAsset.tokenId[i]))] += _diamondAsset.quantity[i];
            }
            ERC1155Interface(_diamondAsset.contractAddress).safeBatchTransferFrom(msg.sender, address(this), _diamondAsset.tokenId, _diamondAsset.quantity, _diamondAsset.data);
        }
        else if (_diamondAsset.tokenType == assetType.ERC20){
            require(_diamondAsset.quantity.length == 1, "Invalid quantity input");
            currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(_diamondAsset.contractAddress))] += _diamondAsset.quantity[0];
            IERC20(_diamondAsset.contractAddress).safeTransferFrom(msg.sender, address(this), _diamondAsset.quantity[0]);
        }
        else if (_diamondAsset.tokenType == assetType.ETH){
            if (needsPayment){
                require(msg.value == getPrice() + _diamondAsset.quantity[0], "ETH amount mismatch");
            } else {
                require(msg.value == _diamondAsset.quantity[0], "ETH amount mismatch");
            }
            currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(assetType.ETH))] += _diamondAsset.quantity[0];
            depositedETH += _diamondAsset.quantity[0];
        }

        //Transfer payment (payment = msg value - any deposited ETH)
        (bool success, ) = factoryContractAddress.call{value: msg.value - depositedETH}("");
        require(success, "ETH payment failed");

        emit DiamondHandCreated(_diamondHands.id, block.timestamp, _diamondHands.releaseTime, _diamondHands.breakPrice, _diamondHands.status);
        diamondIds.increment();
    }

     /**
    * @notice Transfers assets to contract and stores relevant diamond-hand information (in batch)
    * @param _diamondAsset diamondStruct storing relevant information for the assets to be diamond-handed (see struct declaration above)
    * @param _releaseTime Timestamp when this diamond-hand is unlocked (when asset becomes withdrawable)
    * @param _breakPrice Price to unlock diamond-hand in case of emergency
    * @param _diamondSpecial diamondSpecialStruct, if user owns an asset that is on the diamondSpecial list, they can createDiamondHands for free
    */
    function createDiamondHandsBatch(diamondStruct[] memory _diamondAsset, uint256 _releaseTime, uint256 _breakPrice, diamondSpecialStruct memory _diamondSpecial) payable external nonReentrant {
        require(_releaseTime > block.timestamp, "Release time in the past");
        require(_breakPrice >= getMinBreakPrice(), "Break price too low");
        require(_diamondAsset.length > 0, "Empty diamondAsset");

        bool needsPayment = false;
        if (ERC721Interface(getDiamondPassAddress()).balanceOf(msg.sender) == 0){
            //If caller does not have a diamond pass
            if (checkDiamondSpecial(_diamondSpecial.contractAddress, _diamondSpecial.tokenId)){
                if(_diamondSpecial.tokenType == assetType.ERC721){
                    if(ERC721Interface(_diamondSpecial.contractAddress).balanceOf(msg.sender) == 0 ){
                        //If caller claims they have an NFT that is on the diamondSpecial but actually doesn't
                        require(msg.value >= getPrice(), "Not enough ETH");
                        needsPayment = true;
                    }
                } else if (_diamondSpecial.tokenType == assetType.ERC1155){
                    if(ERC1155Interface(_diamondSpecial.contractAddress).balanceOf(msg.sender, _diamondSpecial.tokenId) == 0){
                        //If caller claims they have an NFT that is on the diamondSpecial but actually doesn't
                        require(msg.value >= getPrice(), "Not enough ETH");
                        needsPayment = true;
                    }
                }
            } else {
                //If caller does not have an NFT on diamondSpecial
                require(msg.value >= getPrice(), "Not enough ETH");
                needsPayment = true;
            }
        }
        //Create diamondHand information
        diamondHands memory _diamondHands;
        
        _diamondHands.id = diamondIds.current();
        _diamondHands.releaseTime = _releaseTime;
        _diamondHands.diamondStartTime = block.timestamp;
        _diamondHands.breakPrice = _breakPrice;
        _diamondHands.status = diamondStatus.Holding;
        
        diamondList[_diamondHands.id] = (_diamondHands);

        uint256 depositedETH;   //Used to keep track of additional ETH deposited by user (if they choose to diamond-hand ETH)
        uint256 i;
        //Add assets to list of diamondAssets in contract
        for(i = 0; i < _diamondAsset.length; i++) {
            require(_diamondAsset[i].tokenType == assetType.ERC721 || _diamondAsset[i].tokenType == assetType.ERC1155 || _diamondAsset[i].tokenType == assetType.ERC20 || _diamondAsset[i].tokenType == assetType.ETH, "diamondAsset not supported");
            require(_diamondAsset[i].tokenId.length == _diamondAsset[i].quantity.length, "tokenId & quantity mismatch");
            diamondAssets[_diamondHands.id].push(_diamondAsset[i]);
        }
        
        //Transfer each asset in array into vault for storage
        for(i = 0; i < _diamondAsset.length; i++) {
            if(_diamondAsset[i].tokenType == assetType.ERC721) {
                require(_diamondAsset[i].tokenId.length == 1, "Invalid tokenId quantity");
                currentlyDiamondHanding[keccak256(abi.encodePacked(_diamondAsset[i].contractAddress, _diamondAsset[i].tokenId[0]))] = true;
                ERC721Interface(_diamondAsset[i].contractAddress).safeTransferFrom(msg.sender, address(this), _diamondAsset[i].tokenId[0], _diamondAsset[i].data);

            }
            else if(_diamondAsset[i].tokenType == assetType.ERC1155) {
                for(uint256 j; j < _diamondAsset[i].tokenId.length; j++){
                    currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(_diamondAsset[i].contractAddress, _diamondAsset[i].tokenId[j]))] += _diamondAsset[i].quantity[j];
                }
                ERC1155Interface(_diamondAsset[i].contractAddress).safeBatchTransferFrom(msg.sender, address(this), _diamondAsset[i].tokenId, _diamondAsset[i].quantity, _diamondAsset[i].data);
            }
            else if (_diamondAsset[i].tokenType == assetType.ERC20){
                currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(_diamondAsset[i].contractAddress))] += _diamondAsset[i].quantity[0];
                IERC20(_diamondAsset[i].contractAddress).safeTransferFrom(msg.sender, address(this), _diamondAsset[i].quantity[0]);
            }
            else if (_diamondAsset[i].tokenType == assetType.ETH){
                if (needsPayment){
                    require(msg.value == getPrice() + _diamondAsset[i].quantity[0], "ETH amount mismatch");
                } else {
                    require(msg.value == _diamondAsset[i].quantity[0], "ETH amount mismatch");
                }
                currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(assetType.ETH))] += _diamondAsset[i].quantity[0];
                depositedETH += _diamondAsset[i].quantity[0];
            }
        }

        //Transfer payment (payment = msg value - any deposited ETH)
        (bool success, ) = factoryContractAddress.call{value: msg.value - depositedETH}("");
        require(success, "ETH payment failed");

        emit DiamondHandCreated(_diamondHands.id, block.timestamp, _diamondHands.releaseTime, _diamondHands.breakPrice, _diamondHands.status);
        diamondIds.increment();
    }

    /**
    * @notice Release all the assets inside a specific diamondHand order (matched by _diamondId) if unlock time has passed
    * @param _diamondId Corresponding ID for the diamond-hand order 
    */
    function releaseDiamond(uint _diamondId) external nonReentrant onlyVaultOwner{
        require(_diamondId < diamondIds.current(), "Invalid diamondId");
        diamondHands memory diamondHandOrder = getDiamondHand(_diamondId);
        require(diamondHandOrder.status == diamondStatus.Holding, "Asset no longer held");
        require(block.timestamp >= diamondHandOrder.releaseTime, "Asset not yet unlocked");

        //Update status
        diamondList[_diamondId].status = diamondStatus.Released;
        
        //Release all the assets in this diamondHandOrder
        uint256 numAssets = getDiamondStructSize(_diamondId);
        uint256 i;
        for (i = 0; i < numAssets; i++){
            diamondStruct memory assetToRelease = getDiamondStruct(_diamondId, i);
            if (assetToRelease.tokenType == assetType.ERC721) {
                currentlyDiamondHanding[keccak256(abi.encodePacked(assetToRelease.contractAddress, assetToRelease.tokenId[0]))] = false;
                ERC721Interface(assetToRelease.contractAddress).safeTransferFrom(address(this), msg.sender, assetToRelease.tokenId[0], assetToRelease.data);
            } else if (assetToRelease.tokenType == assetType.ERC1155) {
                for(uint256 j; j < assetToRelease.tokenId.length; j++){
                    currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(assetToRelease.contractAddress, assetToRelease.tokenId[j]))] -= assetToRelease.quantity[j];
                }
                ERC1155Interface(assetToRelease.contractAddress).safeBatchTransferFrom(address(this), msg.sender, assetToRelease.tokenId, assetToRelease.quantity, assetToRelease.data);
            } else if (assetToRelease.tokenType == assetType.ERC20) {
                currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(assetToRelease.contractAddress))] -= assetToRelease.quantity[0];
                IERC20(assetToRelease.contractAddress).safeTransfer(msg.sender, assetToRelease.quantity[0]);
            } else if (assetToRelease.tokenType == assetType.ETH) {
                currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(assetType.ETH))] -= assetToRelease.quantity[0];
                (bool success, ) = msg.sender.call{value: assetToRelease.quantity[0]}("");
                require(success, "ETH withdrawal failed");
            }
        }

        emit DiamondHandReleased(_diamondId, block.timestamp, diamondHandOrder.releaseTime, diamondHandOrder.breakPrice, diamondStatus.Released);
    }

    /**
    * @notice Use emergency break to forcibly unlock (needs to pay what was specified by vaultOwner upon locking the asset)
    * @param _diamondId Corresponding ID for the diamond-hand order 
    */
    function breakUnlock(uint _diamondId) payable external nonReentrant onlyVaultOwner{
        require(_diamondId < diamondIds.current(), "Invalid diamondId");
        diamondHands memory diamondHandOrder = getDiamondHand(_diamondId);
        require(diamondHandOrder.status == diamondStatus.Holding, "Asset no longer held");
        require(msg.value == diamondHandOrder.breakPrice, "Incorrect ETH amount");
        
        //Update status
        diamondList[_diamondId].status = diamondStatus.Broken;
        
         //Release all the assets in this diamondHandOrder
        uint256 numAssets = getDiamondStructSize(_diamondId);
        uint256 i;
        for (i = 0; i < numAssets; i++){
            diamondStruct memory assetToRelease = getDiamondStruct(_diamondId, i);
            if (assetToRelease.tokenType == assetType.ERC721) {
                currentlyDiamondHanding[keccak256(abi.encodePacked(assetToRelease.contractAddress, assetToRelease.tokenId[0]))] = false;
                ERC721Interface(assetToRelease.contractAddress).safeTransferFrom(address(this), msg.sender, assetToRelease.tokenId[0], assetToRelease.data);
            } else if (assetToRelease.tokenType == assetType.ERC1155) {
                for(uint256 j; j < assetToRelease.tokenId.length; j++){
                    currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(assetToRelease.contractAddress, assetToRelease.tokenId[j]))] -= assetToRelease.quantity[j];
                }
                ERC1155Interface(assetToRelease.contractAddress).safeBatchTransferFrom(address(this), msg.sender, assetToRelease.tokenId, assetToRelease.quantity, assetToRelease.data);
            } else if (assetToRelease.tokenType == assetType.ERC20) {
                currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(assetToRelease.contractAddress))] -= assetToRelease.quantity[0];
                IERC20(assetToRelease.contractAddress).safeTransfer(msg.sender, assetToRelease.quantity[0]);
            } else if (assetToRelease.tokenType == assetType.ETH) {
                currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(assetType.ETH))] -= assetToRelease.quantity[0];
                (bool success, ) = msg.sender.call{value: assetToRelease.quantity[0]}("");
                require(success, "ETH withdrawal failed");
            }
        }

        //Transfer value to factory
        (bool paymentSuccess, ) = factoryContractAddress.call{value: msg.value}("");
        require(paymentSuccess, "ETH payment failed");

        emit DiamondHandBroken(_diamondId, block.timestamp, diamondHandOrder.releaseTime, diamondHandOrder.breakPrice, diamondStatus.Broken);
    }


    /**CLAIMING AIRDROPS **/
    /// @notice withdraw an ERC721 token (not currently diamond-handing) from this contract
    /// @param _contractAddress the address of the NFT you are withdrawing
    /// @param _tokenId the ID of the NFT you are withdrawing
    function withdrawERC721(address _contractAddress, uint256 _tokenId) external nonReentrant onlyVaultOwner {
        require(!currentlyDiamondHanding[keccak256(abi.encodePacked(_contractAddress, _tokenId))], "Currently diamond-handing");
        ERC721Interface(_contractAddress).safeTransferFrom(address(this), msg.sender, _tokenId, "");
        emit WithdrawnERC721(_contractAddress, _tokenId);
    }

    /// @notice withdraw ERC1155 tokens (not currently diamond-handing) from this contract
    /// @param _contractAddress the address of the NFT you are withdrawing
    /// @param _tokenId the ID of the NFT you are withdrawing
    function withdrawERC1155(address _contractAddress, uint256 _tokenId) external nonReentrant onlyVaultOwner{
        require(ERC1155Interface(_contractAddress).balanceOf(address(this), _tokenId) > currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(_contractAddress, _tokenId))], "Currently diamond-handing");
        ERC1155Interface(_contractAddress).safeTransferFrom(address(this), msg.sender, _tokenId, ERC1155Interface(_contractAddress).balanceOf(address(this), _tokenId) - currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(_contractAddress, _tokenId))], "");
        emit WithdrawnERC1155(_contractAddress, _tokenId);
    }

    /// @notice withdraw ERC20 (not currently diamond-handing) from this contract
    function withdrawERC20(address _contractAddress) external nonReentrant onlyVaultOwner{
        require(IERC20(_contractAddress).balanceOf(address(this)) > currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(_contractAddress))], "No excess ERC20 to withdraw");
        IERC20(_contractAddress).safeTransfer(msg.sender, IERC20(_contractAddress).balanceOf(address(this)) - currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(_contractAddress))]);

        emit WithdrawnERC20(_contractAddress);
    }

    /// @notice withdraw ETH (not currently diamond-handing) from this contract
    function withdrawETH() external nonReentrant onlyVaultOwner{
        require(address(this).balance > currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(assetType.ETH))], "No excess ETH to withdraw");
        (bool success, ) = msg.sender.call{value: address(this).balance - currentlyDiamondHandingQuantities[keccak256(abi.encodePacked(assetType.ETH))]}("");
        require(success, "ETH withdrawal failed");

        emit WithdrawnETH();
    }

    receive() external payable {
        emit ReceivedEther(msg.sender);
    }

    /** GETTING INFORMATION FROM FACTORY **/

    function getPrice() internal view returns(uint256) {
        return IFactory(factoryContractAddress).PRICE();
    }
    function getMinBreakPrice() internal view returns(uint256) {
        return IFactory(factoryContractAddress).minBreakPrice();
    }
    function getDiamondPassAddress() internal view returns(address) {
        return IFactory(factoryContractAddress).DIAMONDPASS();
    }
    function checkDiamondSpecial(address _contractAddress, uint256 _tokenId) internal view returns(bool) {
        return IFactory(factoryContractAddress).checkDiamondSpecial(_contractAddress, _tokenId);
    }
    
    /** GETTERS **/
    /**
    * @dev Get the diamond-hand order given a diamondId
    * @param _diamondId diamondId to fetch diamondHand information for
    * @return diamondHands
    */
    function getDiamondHand(uint256 _diamondId) public view returns (diamondHands memory) {
        return diamondList[_diamondId];

    }

    /**
    * @dev Get all the diamondHand information of this vault
    * @return diamondHands[] All diamondHand information in this vault
    */
    function getDiamondList() public view returns (diamondHands[] memory) {
        require(diamondIds.current() > 0, "No diamondHand record");
        diamondHands[] memory allDiamondHands = new diamondHands[](diamondIds.current());
        for(uint256 i; i < diamondIds.current(); i++){
            allDiamondHands[i] = (getDiamondHand(i));
        }
        return allDiamondHands;
    }
    
    /**
    * @dev Get length of diamondStruct by id
    * @param _diamondId Corresponding ID
    * @return uint256 number of assets being diamond-handed
    */
    function getDiamondStructSize(uint256 _diamondId) public view returns(uint256) {
        return diamondAssets[_diamondId].length;
    }

    /**
    * @dev Get diamondStruct by ID and index
    * @param _diamondId Corresponding ID
    * @param _index Corresponding index within the list of assets being diamondhanded in this order
    * @return diamondStruct with relevant information about the asset
    */
    function getDiamondStruct(uint256 _diamondId, uint256 _index) public view returns(diamondStruct memory) {
        return diamondAssets[_diamondId][_index] ;
    }
    
    /** SUPPORTS ERC721, ERC1155 **/
    function supportsInterface(bytes4 interfaceID) public view virtual override(ERC1155Receiver) returns (bool) {
        return  interfaceID == 0x01ffc9a7 || interfaceID == 0x4e2312e0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title A proxy to create DiamondVaults
/// @author Momo Labs

contract DiamondProxy is Proxy{
    // address of logic contract
    address public immutable logic;
    constructor(
        address _logic,
        bytes memory _initializationCalldata
    ) {
        logic = _logic;
        // Delegatecall into the logic contract, supplying initialization calldata
        Address.functionDelegateCall(_logic, _initializationCalldata);
    }

    function _implementation() internal view virtual override returns (address){
        return logic;
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}