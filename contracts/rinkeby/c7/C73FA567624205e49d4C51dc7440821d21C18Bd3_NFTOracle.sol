// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {VersionedInitializable} from '../protocol/libraries/aave-upgradeability/VersionedInitializable.sol';
import {INFTOracle} from '../interfaces/INFTOracle.sol';

/**
 * @title NFTOracle
 * @author Vinci
 **/
contract NFTOracle is INFTOracle, VersionedInitializable {
  address internal oracleUpdater;

  // batch update
  struct Input {
    uint64[4] prices;
    address[4] addresses;
    uint64 id;
  }

  // asset address
  struct Location {
    uint64 id;
    uint64 index;
  }
  mapping (address => Location) internal locations;
  address[] internal addressList;
  uint64 internal locationId;
  uint64 internal locationIndex;

  // price
  struct Price {
    uint64 v1;
    uint64 v2;
    uint64 v3;
    uint64 v4;
  }
  mapping (uint256 => Price) internal prices;

  /**
   * @dev returns the revision of the implementation contract
   */
  function getRevision() internal pure override virtual returns (uint256) {
    return 1;
  }

  function revision() external pure returns (uint256) {
    return getRevision();
  }

  modifier onlyUpdater() {
    require(msg.sender == oracleUpdater);
    _;
  }

  function _addAssets(address[] memory addresses) internal {
    uint64 id = locationId;
    uint64 index = locationIndex;
    for (uint256 i = 0; i < addresses.length; i++) {
      address _asset = addresses[i];
      Location memory cacheLocation = locations[_asset];
      if (cacheLocation.id == 0) {
        if (index >= 4) {
          index = 0;
          id++;
        }
        index++;
        addressList.push(_asset);
        cacheLocation.id = id + 1;
        cacheLocation.index = index;
        locations[_asset] = cacheLocation;
      }
    }
    locationId = id;
    locationIndex = index;
  }

  /**
   * @dev initializes the contract upon assignment to the InitializableAdminUpgradeabilityProxy
   */
  function initialize(address _oracleUpdater, address[] memory addresses) external initializer {
    oracleUpdater = _oracleUpdater;
    _addAssets(addresses);
  }

  /**
   * @dev Returns the address of the Updater
  */
  function getOracleUpdater() public view returns (address) {
    return oracleUpdater;
  }

  function updateOracleUpdater(address _newOracleUpdater) external onlyUpdater {
    oracleUpdater = _newOracleUpdater;
    emit OracleUpdaterChange(_newOracleUpdater);
  }

  function getAddressList() external view returns(address[] memory) {
    return addressList;
  }

  function getLocation(address _asset) public view returns (uint64, uint64) {
    Location memory cacheLocation = locations[_asset];
    return (cacheLocation.id, cacheLocation.index);
  }

  function _getAssetPrice(address _asset) internal virtual view returns (uint64) {
    Location memory location = locations[_asset];
    Price storage price = prices[location.id];
    if (location.index == 1) {
      return price.v1;
    } else if (location.index == 2) {
      return price.v2;
    } else if (location.index == 3) {
      return price.v3;
    } else if (location.index == 4) {
      return price.v4;
    }
  }

  function _setAssetPrice(address _asset, uint64 _price) internal virtual {
    Location memory location = locations[_asset];
    Price storage price = prices[location.id];
    if (location.index == 1) {
      price.v1 = _price;
    } else if (location.index == 2) {
      price.v2 = _price;
    } else if (location.index == 3) {
      price.v3 = _price;
    } else if (location.index == 4) {
      price.v4 = _price;
    }
  }

  function _setAllPrice(uint256 _id, uint64[4] memory _prices) private {
    Price storage price = prices[_id];
    price.v1 = _prices[0];
    price.v2 = _prices[1];
    price.v3 = _prices[2];
    price.v4 = _prices[3];
  }

  function addAssets(address[] memory _assets) external onlyUpdater {
    _addAssets(_assets);
  }

  function batchSetAssetPrice(Input[] calldata input) external onlyUpdater {
    for (uint256 i = 0; i < input.length; i++) {
      Input memory cacheInput = input[i];
      uint64[4] memory _prices = cacheInput.prices;
      _setAllPrice(cacheInput.id, _prices);
      emit BatchSetAssetData(cacheInput.addresses, _prices, block.timestamp);
    }
  }

  // set in GWei
  function setAssetPrice(address _asset, uint64 _price) external onlyUpdater {
    _setAssetPrice(_asset, _price);
    emit SetAssetData(_asset, _price, block.timestamp);
  }

  // return in Wei
  function getAssetPrice(address _asset) external view returns (uint256) {
    uint64 _price = _getAssetPrice(_asset);
    return uint256(_price) * 1e9;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 */
abstract contract VersionedInitializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  uint256 private lastInitializedRevision = 0;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    uint256 revision = getRevision();
    require(
      initializing || isConstructor() || revision > lastInitializedRevision,
      'Contract instance has already been initialized'
    );

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      lastInitializedRevision = revision;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /**
   * @dev returns the revision number of the contract
   * Needs to be defined in the inherited class as a constant.
   **/
  function getRevision() internal pure virtual returns (uint256);

  /**
   * @dev Returns true if and only if the function is running in the constructor
   **/
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    //solium-disable-next-line
    assembly {
      cs := extcodesize(address())
    }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

/************
@title INFTOracle interface
@notice Interface for the NFT price oracle.*/
interface INFTOracle {

  event OracleUpdaterChange(address newOracleUpdater);
  event SetAssetData(address indexed asset, uint64 price, uint256 timestamp);
  event BatchSetAssetData(address[4] addresses,  uint64[4] prices, uint256 timestamp);

  /***********
    @dev returns the nft asset price in wei
     */
  function getAssetPrice(address asset) external view returns (uint256);

}