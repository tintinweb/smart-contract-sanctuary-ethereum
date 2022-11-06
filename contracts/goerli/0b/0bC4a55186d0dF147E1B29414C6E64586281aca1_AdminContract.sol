// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Dependencies/CheckContract.sol";

import "./Interfaces/IDfrancParameters.sol";

contract AdminContract is Ownable {
    string public constant NAME = "AdminContract";

    bool public isInitialized;

    IDfrancParameters private dfrancParameters;

    address borrowerOperationsAddress;
    address troveManagerAddress;
    address dchfTokenAddress;
    address sortedTrovesAddress;

    function setAddresses(
        address _parameters,
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _dchfTokenAddress,
        address _sortedTrovesAddress
    ) external onlyOwner {
        require(!isInitialized, "Already initialized");
        CheckContract(_parameters);
        CheckContract(_borrowerOperationsAddress);
        CheckContract(_troveManagerAddress);
        CheckContract(_dchfTokenAddress);
        CheckContract(_sortedTrovesAddress);

        isInitialized = true;

        borrowerOperationsAddress = _borrowerOperationsAddress;
        troveManagerAddress = _troveManagerAddress;
        dchfTokenAddress = _dchfTokenAddress;
        sortedTrovesAddress = _sortedTrovesAddress;

        dfrancParameters = IDfrancParameters(_parameters);
    }

    // NOTE caution with Oracle addition interface
    function addNewCollateral(
        address _asset,
        address _chainlinkOracle,
        address _chainlinkIndex,
        uint256 redemptionLockInDay
    ) external onlyOwner {
        dfrancParameters.priceFeed().addOracle(_asset, _chainlinkOracle, _chainlinkIndex);
        dfrancParameters.setAsDefaultWithRedemptionBlock(_asset, redemptionLockInDay);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

contract CheckContract {
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        assembly {
            size := extcodesize(_account)
        }
        require(size > 0, "Account code size cannot be zero");
    }
}

pragma solidity 0.8.14;

import "./IActivePool.sol";
import "./IPriceFeed.sol";
import "./IDfrancBase.sol";

interface IDfrancParameters {
    error SafeCheckError(string parameter, uint256 valueEntered, uint256 minValue, uint256 maxValue);

    event MCRChanged(uint256 oldMCR, uint256 newMCR);
    event CCRChanged(uint256 oldCCR, uint256 newCCR);
    event LIMIT_CRChanged(uint256 oldLIMIT_CR, uint256 newLIMIT_CR);
    event TVL_CAPChanged(uint256 oldTVL_CAP, uint256 newTVL_CAP);
    event MinNetDebtChanged(uint256 oldMinNet, uint256 newMinNet);
    event PercentDivisorChanged(uint256 oldPercentDiv, uint256 newPercentDiv);
    event BorrowingFeeFloorChanged(uint256 oldBorrowingFloorFee, uint256 newBorrowingFloorFee);
    event MaxBorrowingFeeChanged(uint256 oldMaxBorrowingFee, uint256 newMaxBorrowingFee);
    event RedemptionFeeFloorChanged(uint256 oldRedemptionFeeFloor, uint256 newRedemptionFeeFloor);
    event RedemptionBlockRemoved(address _asset);
    event PriceFeedChanged(address indexed addr);

    function DECIMAL_PRECISION() external view returns (uint256);

    function _100pct() external view returns (uint256);

    // Minimum collateral ratio for individual troves.
    function MCR(address _collateral) external view returns (uint256);

    // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
    function CCR(address _collateral) external view returns (uint256);

    function LIMIT_CR(address _collateral) external view returns (uint256);

    function TVL_CAP(address _collateral) external view returns (uint256);

    function MIN_NET_DEBT(address _collateral) external view returns (uint256);

    function PERCENT_DIVISOR(address _collateral) external view returns (uint256);

    function BORROWING_FEE_FLOOR(address _collateral) external view returns (uint256);

    function REDEMPTION_FEE_FLOOR(address _collateral) external view returns (uint256);

    function MAX_BORROWING_FEE(address _collateral) external view returns (uint256);

    function redemptionBlock(address _collateral) external view returns (uint256);

    function activePool() external view returns (IActivePool);

    function priceFeed() external view returns (IPriceFeed);

    function setAddresses(
        address _activePool,
        address _priceFeed,
        address _adminContract
    ) external;

    function setPriceFeed(address _priceFeed) external;

    function setMCR(address _asset, uint256 newMCR) external;

    function setCCR(address _asset, uint256 newCCR) external;

    function setLIMIT_CR(address _asset, uint256 newLIMIT_CR) external;

    function setTVL_CAP(address _asset, uint256 newTVL_CAP) external;

    function sanitizeParameters(address _asset) external;

    function setAsDefault(address _asset) external;

    function setAsDefaultWithRedemptionBlock(address _asset, uint256 blockInDays) external;

    function setMinNetDebt(address _asset, uint256 minNetDebt) external;

    function setPercentDivisor(address _asset, uint256 percentDivisor) external;

    function setBorrowingFeeFloor(address _asset, uint256 borrowingFeeFloor) external;

    function setMaxBorrowingFee(address _asset, uint256 maxBorrowingFee) external;

    function setRedemptionFeeFloor(address _asset, uint256 redemptionFeeFloor) external;

    function removeRedemptionBlock(address _asset) external;
}

// SPDX-License-Identifier: MIT

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

pragma solidity 0.8.14;

import "./IPool.sol";

interface IActivePool is IPool {
    // --- Events --- //
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolDCHFDebtUpdated(address _asset, uint256 _DCHFDebt);
    event ActivePoolAssetBalanceUpdated(address _asset, uint256 _balance);

    // --- Functions --- //
    function sendAsset(
        address _asset,
        address _account,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

pragma solidity 0.8.14;

interface IPriceFeed {
    struct ChainlinkResponse {
        uint80 roundId;
        int256 answer;
        uint256 timestamp;
        bool success;
        uint8 decimals;
    }

    struct RegisterOracle {
        AggregatorV3Interface chainLinkOracle;
        AggregatorV3Interface chainLinkIndex;
        bool isRegistered;
    }

    enum Status {
        chainlinkWorking,
        chainlinkUntrusted
    }

    // --- Events ---
    event PriceFeedStatusChanged(Status newStatus);
    event LastGoodPriceUpdated(address indexed token, uint256 _lastGoodPrice);
    event LastGoodIndexUpdated(address indexed token, uint256 _lastGoodIndex);
    event RegisteredNewOracle(address token, address chainLinkAggregator, address chianLinkIndex);

    // --- Function ---
    function addOracle(
        address _token,
        address _chainlinkOracle,
        address _chainlinkIndexOracle
    ) external;

    function fetchPrice(address _token) external returns (uint256);

    function getDirectPrice(address _asset) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IDfrancParameters.sol";

interface IDfrancBase {
    event VaultParametersBaseChanged(address indexed newAddress);

    function dfrancParams() external view returns (IDfrancParameters);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IDeposit.sol";

// Common interface for the Pools.
interface IPool is IDeposit {
    // --- Events --- //

    event AssetBalanceUpdated(uint256 _newBalance);
    event DCHFBalanceUpdated(uint256 _newBalance);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event AssetAddressChanged(address _assetAddress);
    event AssetSent(address _to, address indexed _asset, uint256 _amount);

    // --- Functions --- //

    function getAssetBalance(address _asset) external view returns (uint256);

    function getDCHFDebt(address _asset) external view returns (uint256);

    function increaseDCHFDebt(address _asset, uint256 _amount) external;

    function decreaseDCHFDebt(address _asset, uint256 _amount) external;
}

pragma solidity 0.8.14;

interface IDeposit {
    function receivedERC20(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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