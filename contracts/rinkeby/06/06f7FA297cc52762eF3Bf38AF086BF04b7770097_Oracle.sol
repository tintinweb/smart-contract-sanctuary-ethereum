// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// contracts
import {IncreOwnable} from "./utils/IncreOwnable.sol";

// interfaces
import {IOracle} from "./interfaces/IOracle.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @notice Oracle contract relying on Chainlink for price
contract Oracle is IOracle, IncreOwnable {
    uint8 internal constant PROTOCOL_PRECISION = 18;
    uint256 public override heartBeat = 25 hours;

    mapping(address => AggregatorV3Interface) public assetToChainLinkAggregator;
    mapping(address => int256) public assetToFixedPrice;

    /* ****************** */
    /*     Governance     */
    /* ****************** */

    /// @notice Add or update an oracle address
    function setOracle(address asset, AggregatorV3Interface aggregator) external override onlyGovernance {
        if (address(asset) == address(0)) revert Oracle_AssetZeroAddress();
        if (address(aggregator) == address(0)) revert Oracle_AggregatorZeroAddress();

        assetToChainLinkAggregator[asset] = aggregator;
    }

    /// @notice A safety mechanism, to be used only if the chainlink get compromised or stops working
    function setFixedPrice(address asset, int256 fixedPrice) external override onlyGovernance {
        if (address(assetToChainLinkAggregator[asset]) == address(0)) revert Oracle_UnsupportedAsset();

        assetToFixedPrice[asset] = fixedPrice;
    }

    function setHeartBeat(uint256 newHeartBeat) external override onlyGovernance {
        heartBeat = newHeartBeat;

        emit HeartBeatUpdated(newHeartBeat);
    }

    /* ****************** */
    /*   Global getter    */
    /* ****************** */

    /// @notice Get latest chainlink price, except if a fixed price is defined for this asset
    function getPrice(address asset) external view override returns (int256) {
        if (assetToFixedPrice[asset] != 0) {
            return assetToFixedPrice[asset];
        }

        return _getChainlinkPrice(assetToChainLinkAggregator[asset]);
    }

    /* ****************** */
    /* internal getter    */
    /* ****************** */

    /// @notice Get latest chainlink price
    function _getChainlinkPrice(AggregatorV3Interface aggregator) internal view returns (int256) {
        (, int256 roundPrice, , uint256 roundTimestamp, ) = aggregator.latestRoundData();

        // If the round is not complete yet, timestamp is 0
        if (roundTimestamp <= 0) revert Oracle_InvalidRoundTimestamp();
        if (roundPrice <= 0) revert Oracle_InvalidRoundPrice();

        if (roundTimestamp + heartBeat < block.timestamp) revert Oracle_DataNotFresh();

        return _scalePrice(roundPrice, aggregator.decimals());
    }

    /// @notice Scale price up or down depending on the precision of the asset
    function _scalePrice(int256 price, uint8 assetPrecision) internal pure returns (int256) {
        if (assetPrecision < PROTOCOL_PRECISION) {
            return price * int256(10**uint256(PROTOCOL_PRECISION - assetPrecision));
        } else if (assetPrecision == PROTOCOL_PRECISION) {
            return price;
        }

        return price / int256(10**uint256(assetPrecision - PROTOCOL_PRECISION));
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

interface IIncreOwnable {
    /* ****************** */
    /*     Errors         */
    /* ****************** */

    /// @notice Emitted when the sender is not the owner
    error IncreOwnable_NotOwner();

    /// @notice Emitted when the sender is not the pending owner
    error IncreOwnable_NotPendingOwner();

    /// @notice Emitted when the proposed owner is equal to the zero address
    error IncreOwnable_TransferZeroAddress();

    /* ****************** */
    /*     Events         */
    /* ****************** */

    /// @notice Emitted when ownership is directly transferred to new address
    /// @param sender Address transferring ownership
    /// @param recipient Address of new owner
    event TransferOwner(address indexed sender, address indexed recipient);

    /// @notice Emitted when ownership is claimed
    /// @param sender Address transferring ownership
    /// @param recipient Address of new owner
    event TransferOwnerClaim(address indexed sender, address indexed recipient);

    /* ****************** */
    /*     Viewer         */
    /* ****************** */

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function claimOwner() external;

    function transferOwner(address recipient, bool direct) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @notice Oracle interface created to ease oracle contract switch
interface IOracle {
    /* ****************** */
    /*     Events         */
    /* ****************** */

    /// @notice Emitted when oracle heart beat is updated
    /// @param newHeartBeat New heart beat value
    event HeartBeatUpdated(uint256 newHeartBeat);

    /* ****************** */
    /*     Errors         */
    /* ****************** */

    /// @notice Emitted when the latest round is incomplete
    error Oracle_InvalidRoundTimestamp();

    /// @notice Emitted when the latest round's price is invalid
    error Oracle_InvalidRoundPrice();

    /// @notice Emitted when the latest round's data is older than the oracle's max refresh time
    error Oracle_DataNotFresh();

    /// @notice Emitted when the proposed asset address is equal to the zero address
    error Oracle_AssetZeroAddress();

    /// @notice Emitted when the proposed aggregator address is equal to the zero address
    error Oracle_AggregatorZeroAddress();

    /// @notice Emitted when owner tries to set fixed price to an unsupported asset
    error Oracle_UnsupportedAsset();

    /* ****************** */
    /*     Viewer         */
    /* ****************** */

    function heartBeat() external view returns (uint256);

    function getPrice(address asset) external view returns (int256);

    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function setOracle(address asset, AggregatorV3Interface aggregator) external;

    function setFixedPrice(address asset, int256 fixedPrice) external;

    function setHeartBeat(uint256 newHeartBeat) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {IIncreOwnable} from "../interfaces/IIncreOwnable.sol";

/// @notice Increment access control contract.
/// @author Adapted from https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringOwnable.sol, License-Identifier: MIT.
/// @author Adapted from https://github.com/sushiswap/trident/blob/master/contracts/utils/TridentOwnable.sol, License-Identifier: GPL-3.0-or-later
contract IncreOwnable is IIncreOwnable {
    address public override owner;
    address public override pendingOwner;

    /// @notice Initialize and grant deployer account (`msg.sender`) `owner` access role.
    constructor() {
        owner = msg.sender;
        emit TransferOwner(address(0), msg.sender);
    }

    /// @notice Access control modifier that requires modified function to be called by the governance, i.e. the `owner` account
    modifier onlyGovernance() {
        if (msg.sender != owner) revert IncreOwnable_NotOwner();
        _;
    }

    /// @notice `pendingOwner` can claim `owner` account.
    function claimOwner() external override {
        if (msg.sender != pendingOwner) revert IncreOwnable_NotPendingOwner();
        emit TransferOwner(owner, msg.sender);
        owner = msg.sender;
        pendingOwner = address(0);
    }

    /// @notice Transfer `owner` account.
    /// @param recipient Account granted `owner` access control.
    /// @param direct If 'true', ownership is directly transferred.
    function transferOwner(address recipient, bool direct) external override onlyGovernance {
        if (recipient == address(0)) revert IncreOwnable_TransferZeroAddress();
        if (direct) {
            owner = recipient;
            emit TransferOwner(msg.sender, recipient);
        } else {
            pendingOwner = recipient;
            emit TransferOwnerClaim(msg.sender, recipient);
        }
    }
}