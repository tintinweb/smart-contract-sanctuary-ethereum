/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT
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

// File: contracts/oracle/interfaces/IOracle.sol


pragma solidity ^0.8.4;

interface IOracle {
    struct Asset {
      address addr;
      uint256 subId;
    }
    function addAsset(Asset calldata asset) external returns(bool);
    function addAssets(Asset[] calldata assets) external returns(bool);
    // function removeAsset(Asset calldata asset) external returns(bool);
    // function removeAssets(Asset[] calldata assets) external returns(bool);
    function setAssetPriceData(bytes calldata data) external returns(bool);
    function getAssetPriceData(Asset calldata asset) external view returns (uint256 price,uint256 updateAt);
    function getAssetPriceDataByPeriod(Asset calldata asset,uint256 period) external view returns (uint256[2][] memory);
    function getMinAssetPriceDataByPeriod(Asset calldata asset,uint256 period) external view returns(uint256 price,uint256 updateAt);
}

// File: contracts/oracle/AssetPriceOracle.sol


pragma solidity ^0.8.4;


// import "./utils/Bytes.sol";

contract AssetPriceOracle is IOracle, Ownable {
    event AdminUpdated(address indexed admin);
    event AddAsset(address addr,uint256 subId,uint256 index);
    event AssetPriceDataUpdated(uint256 roundId, uint256 timestamp, bytes data);
    struct AssetPriceData {
        uint256 updateAt;
        bytes data;
    }
    uint256 private constant DATA_SIZE= 1008;
    uint256 private constant ASSET_PRICE_DATA_BYTES = 4;
    address public admin;
    Asset[] public assets;
    mapping(address => mapping(uint256 => uint256)) public assetIndexMap;
    // uint256 public lastAssetIndex; 
    AssetPriceData[DATA_SIZE] public assetDataList;
    uint256 public roundId; // start 0

    constructor(){
      admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(_msgSender() == admin, "NFTOracle: !admin");
        _;
    }

    modifier checkRoundId(){
       require(roundId > 0,"Oracle:no round data");
      _;
    }

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
        emit AdminUpdated(_admin);
    }

    function isExistedAsset(Asset calldata asset) private view returns (bool) {
      uint256 assetIndex = assetIndexMap[asset.addr][asset.subId];
      return assetIndex > 0;
    }

    function getAssets() external view returns(Asset[] memory) {
      return assets;
    }

    function addAsset(Asset calldata asset) external override onlyAdmin returns(bool) {
      return _addAsset(asset);
    }
    function _addAsset(Asset calldata asset) internal returns(bool){
      require(!isExistedAsset(asset),"Oracle: asset existed");
      assets.push(asset);
      uint256 assetIndex = assets.length;
      // assetIndexMap[asset.addr][asset.subId] = ++lastAssetIndex; // start 1
      // emit AddAsset(asset.addr,asset.subId,lastAssetIndex);
      assetIndexMap[asset.addr][asset.subId] = assetIndex; // start 1
      emit AddAsset(asset.addr,asset.subId,assetIndex);
      return true;
    }

    function addAssets(Asset[] calldata _assets) external override onlyAdmin returns(bool) {
      uint256 len = _assets.length;
      for(uint256 i =0; i < len; i++){
          _addAsset(_assets[i]); 
      }
      return true;
    }
    // function removeAsset(Asset calldata asset) external returns(bool) {
    //   require(isExistedAsset(asset),"Oracle: asset not existed");
    //   uint256 assetIndex = assetIndexMap[asset.addr][asset.subId];
    //   delete assets[assetIndex-1];
    //   return true;
    // }

    // function removeAssets(Asset[] calldata assets) external returns(bool) {

    // }

    function setAssetPriceData(bytes calldata data)
        external
        override
        onlyAdmin
        returns (bool)
    {
        require(data.length > 0 && data.length % ASSET_PRICE_DATA_BYTES == 0,"Oracle: data error");
        // require(lastAssetIndex * ASSET_DATA_BYTES == data.length,"Oracle: asset and data length disaccord");
        uint256 _blockTimestamp = block.timestamp;
        uint256 index = roundId++ % DATA_SIZE;
        AssetPriceData storage priceData = assetDataList[index];
        priceData.updateAt = _blockTimestamp;
        priceData.data = data;
        emit AssetPriceDataUpdated(roundId, _blockTimestamp, data);
        return true;
    }

    function _getAssetPriceData(uint256 assetIndex,uint256 _roundId) internal view returns (uint256 price,uint256 updateAt){
      uint256 index = (_roundId - 1) % DATA_SIZE;
      AssetPriceData storage priceData = assetDataList[index];
      uint256 startIndex = (assetIndex - 1) * ASSET_PRICE_DATA_BYTES;
      uint256 endIndex = startIndex + ASSET_PRICE_DATA_BYTES;
      if(endIndex > priceData.data.length) {
        return  (0,priceData.updateAt);
      }
      uint256 number;
      uint256 k = 0;
      for(uint i = startIndex; i < endIndex; i++){
          number = number + uint8(priceData.data[i])*(2**(8*(ASSET_PRICE_DATA_BYTES-(k+1))));
          k++;
      }
      return (number,priceData.updateAt);
      // bytes memory priceBytes = new bytes(ASSET_DATA_BYTES);
      // uint256 projectPriceIndex = 0;
      // for(uint256 i = startIndex; i < endIndex;i++){
      //   priceBytes[projectPriceIndex] = priceData.data[i];
      //   projectPriceIndex++;
      // } 
      // return (Bytes.bytesToUint(priceBytes),priceData.updateAt);
    }

    function getAssetPriceData(Asset calldata asset) external override view checkRoundId returns (uint256 price,uint256 updateAt){
      require(isExistedAsset(asset),"Oracle: asset not existed");
      uint256 assetIndex = assetIndexMap[asset.addr][asset.subId];
      return _getAssetPriceData(assetIndex,roundId);
    }
    
    function getAssetPriceDataByPeriod(Asset calldata asset,uint256 period) external override view checkRoundId  returns(uint256[2][] memory) {
       require(isExistedAsset(asset),"Oracle: asset not existed");
       uint256 assetIndex = assetIndexMap[asset.addr][asset.subId];
       uint256 t = block.timestamp - period * 3600000;
       uint256 startRoundId = roundId;
       uint256 index = 0;
       AssetPriceData storage priceData;
       while( startRoundId >  0) {
        index = (startRoundId - 1) % DATA_SIZE;
        priceData = assetDataList[index];
        if(priceData.updateAt < t) {
          break;
        }
        startRoundId--;
       }
       uint256[2][] memory returnArr = new uint256[2][](roundId - startRoundId);
       uint256 returnIndex = 0;
       for(uint256 i = startRoundId + 1; i <= roundId; i++){
          (uint256 price,uint256 updateAt) = _getAssetPriceData(assetIndex,i);
          returnArr[returnIndex++] = [price,updateAt];
       }
      return returnArr;
    }
    function getMinAssetPriceDataByPeriod(Asset calldata asset,uint256 period) external view  override checkRoundId returns(uint256 data,uint256 updateAt) {
      require(isExistedAsset(asset),"Oracle: asset not existed");
      uint256[2][] memory arr = this.getAssetPriceDataByPeriod(asset,period);
      uint256[2] memory min = arr[0];
      uint256 len = arr.length;
      if(len > 1){
        for(uint256 i = 1; i < len; i++){
          if(arr[i][0] < min[0]) {
            min = arr[i];
          }
        }
      }
      return (min[0],min[1]);
    }
}