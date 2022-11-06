// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Dependencies/CheckContract.sol";

import "./Interfaces/IDfrancParameters.sol";

contract DfrancParameters is IDfrancParameters, Ownable, CheckContract {
    string public constant NAME = "DfrancParameters";

    uint256 public constant override DECIMAL_PRECISION = 1 ether;
    uint256 public constant override _100pct = 1 ether; // 1e18 == 100%

    uint256 public constant REDEMPTION_BLOCK_DAY = 14;

    uint256 public constant MCR_DEFAULT = 1100000000000000000; // 110%
    uint256 public constant CCR_DEFAULT = 1500000000000000000; // 150%
    uint256 public constant LIMIT_CR_DEFAULT = 1250000000000000000; // 125%
    uint256 public constant PERCENT_DIVISOR_DEFAULT = 100; // dividing by 100 yields 0.5%

    uint256 public constant BORROWING_FEE_FLOOR_DEFAULT = (DECIMAL_PRECISION / 1000) * 5; // 0.5%
    uint256 public constant MAX_BORROWING_FEE_DEFAULT = (DECIMAL_PRECISION / 100) * 5; // 5%

    uint256 public constant MIN_NET_DEBT_DEFAULT = 2000 ether;
    uint256 public constant REDEMPTION_FEE_FLOOR_DEFAULT = (DECIMAL_PRECISION / 1000) * 5; // 0.5%

    uint256 public constant TVL_CAP_DEFAULT = type(uint256).max;

    // Minimum collateral ratio for individual troves.
    mapping(address => uint256) public override MCR;
    // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
    mapping(address => uint256) public override CCR;
    // Limit system collateral ratio. If the system's total collateral ratio (TCR) falls below the LIMIT_CR, some functions can not be invoked.
    mapping(address => uint256) public override LIMIT_CR;
    // Borrow Cap for each asset, limit of DCHF that can be borrowed globally for a specific market.
    mapping(address => uint256) public override TVL_CAP;

    mapping(address => uint256) public override MIN_NET_DEBT; // Minimum amount of net DCHF debt a trove must have
    mapping(address => uint256) public override PERCENT_DIVISOR; // dividing by 200 yields 0.5%
    mapping(address => uint256) public override BORROWING_FEE_FLOOR;
    mapping(address => uint256) public override REDEMPTION_FEE_FLOOR;
    mapping(address => uint256) public override MAX_BORROWING_FEE;
    mapping(address => uint256) public override redemptionBlock;

    mapping(address => bool) internal hasCollateralConfigured;

    IActivePool public override activePool;
    IPriceFeed public override priceFeed;

    address public adminContract;

    bool public isInitialized;

    modifier isController() {
        require(msg.sender == owner() || msg.sender == adminContract, "Invalid Permissions");
        _;
    }

    function setAddresses(
        address _activePool,
        address _priceFeed,
        address _adminContract
    ) external override onlyOwner {
        require(!isInitialized, "Already initialized");
        checkContract(_activePool);
        checkContract(_priceFeed);
        checkContract(_adminContract);

        isInitialized = true;

        adminContract = _adminContract;
        activePool = IActivePool(_activePool);
        priceFeed = IPriceFeed(_priceFeed);
    }

    function setAdminContract(address _admin) external onlyOwner {
        require(_admin != address(0), "admin address is zero");
        checkContract(_admin);
        adminContract = _admin;
    }

    // NOTE caution with Oracle addition interface
    function setPriceFeed(address _priceFeed) external override onlyOwner {
        checkContract(_priceFeed);
        priceFeed = IPriceFeed(_priceFeed);

        emit PriceFeedChanged(_priceFeed);
    }

    function sanitizeParameters(address _asset) external {
        if (!hasCollateralConfigured[_asset]) {
            _setAsDefault(_asset);
        }
    }

    function setAsDefault(address _asset) external onlyOwner {
        _setAsDefault(_asset);
    }

    function setAsDefaultWithRedemptionBlock(address _asset, uint256 blockInDays) external isController {
        if (blockInDays > 14) {
            blockInDays = REDEMPTION_BLOCK_DAY;
        }

        if (redemptionBlock[_asset] == 0) {
            redemptionBlock[_asset] = block.timestamp + (blockInDays * 1 days);
        }

        _setAsDefault(_asset);
    }

    function _setAsDefault(address _asset) private {
        hasCollateralConfigured[_asset] = true;

        MCR[_asset] = MCR_DEFAULT;
        CCR[_asset] = CCR_DEFAULT;
        LIMIT_CR[_asset] = LIMIT_CR_DEFAULT;
        TVL_CAP[_asset] = TVL_CAP_DEFAULT;
        MIN_NET_DEBT[_asset] = MIN_NET_DEBT_DEFAULT;
        PERCENT_DIVISOR[_asset] = PERCENT_DIVISOR_DEFAULT;
        BORROWING_FEE_FLOOR[_asset] = BORROWING_FEE_FLOOR_DEFAULT;
        MAX_BORROWING_FEE[_asset] = MAX_BORROWING_FEE_DEFAULT;
        REDEMPTION_FEE_FLOOR[_asset] = REDEMPTION_FEE_FLOOR_DEFAULT;
    }

    function setCollateralParameters(
        address _asset,
        uint256 newMCR,
        uint256 newCCR,
        uint256 limitCR,
        uint256 tvlCap,
        uint256 minNetDebt,
        uint256 percentDivisor,
        uint256 borrowingFeeFloor,
        uint256 maxBorrowingFee,
        uint256 redemptionFeeFloor
    ) external onlyOwner {
        hasCollateralConfigured[_asset] = true;

        setMCR(_asset, newMCR);
        setCCR(_asset, newCCR);
        setLIMIT_CR(_asset, limitCR);
        setTVL_CAP(_asset, tvlCap);
        setMinNetDebt(_asset, minNetDebt);
        setPercentDivisor(_asset, percentDivisor);
        setMaxBorrowingFee(_asset, maxBorrowingFee);
        setBorrowingFeeFloor(_asset, borrowingFeeFloor);
        setRedemptionFeeFloor(_asset, redemptionFeeFloor);
    }

    function setMCR(address _asset, uint256 newMCR)
        public
        override
        onlyOwner
        safeCheck("MCR", _asset, newMCR, 1010000000000000000, 10000000000000000000) /// 101% - 1000%
    {
        uint256 oldMCR = MCR[_asset];
        MCR[_asset] = newMCR;

        emit MCRChanged(oldMCR, newMCR);
    }

    function setCCR(address _asset, uint256 newCCR)
        public
        override
        onlyOwner
        safeCheck("CCR", _asset, newCCR, 1010000000000000000, 10000000000000000000) /// 101% - 1000%
    {
        uint256 oldCCR = CCR[_asset];
        CCR[_asset] = newCCR;

        emit CCRChanged(oldCCR, newCCR);
    }

    function setLIMIT_CR(address _asset, uint256 newLIMIT_CR)
        public
        override
        onlyOwner
        safeCheck("LIMIT_CR", _asset, newLIMIT_CR, 1010000000000000000, 10000000000000000000) /// 101% - 1000%
    {
        uint256 oldLIMIT_CR = LIMIT_CR[_asset];
        LIMIT_CR[_asset] = newLIMIT_CR;

        emit LIMIT_CRChanged(oldLIMIT_CR, newLIMIT_CR);
    }

    function setTVL_CAP(address _asset, uint256 newTVL_CAP)
        public
        override
        onlyOwner
        safeCheck("TVL_CAP", _asset, newTVL_CAP, 1e22, 1e27) /// 10000 - 1000M
    {
        uint256 oldTVL_CAP = TVL_CAP[_asset];
        TVL_CAP[_asset] = newTVL_CAP;

        emit TVL_CAPChanged(oldTVL_CAP, newTVL_CAP);
    }

    function setPercentDivisor(address _asset, uint256 percentDivisor)
        public
        override
        onlyOwner
        safeCheck("Percent Divisor", _asset, percentDivisor, 2, 200)
    {
        uint256 oldPercent = PERCENT_DIVISOR[_asset];
        PERCENT_DIVISOR[_asset] = percentDivisor;

        emit PercentDivisorChanged(oldPercent, percentDivisor);
    }

    function setBorrowingFeeFloor(address _asset, uint256 borrowingFeeFloor)
        public
        override
        onlyOwner
        safeCheck("Borrowing Fee Floor", _asset, borrowingFeeFloor, 0, 1000) /// 0% - 10%
    {
        uint256 oldBorrowing = BORROWING_FEE_FLOOR[_asset];
        uint256 newBorrowingFee = (DECIMAL_PRECISION / 10000) * borrowingFeeFloor;

        BORROWING_FEE_FLOOR[_asset] = newBorrowingFee;
        require(MAX_BORROWING_FEE[_asset] > BORROWING_FEE_FLOOR[_asset], "Wrong inputs");

        emit BorrowingFeeFloorChanged(oldBorrowing, newBorrowingFee);
    }

    function setMaxBorrowingFee(address _asset, uint256 maxBorrowingFee)
        public
        override
        onlyOwner
        safeCheck("Max Borrowing Fee", _asset, maxBorrowingFee, 0, 1000) /// 0% - 10%
    {
        uint256 oldMaxBorrowingFee = MAX_BORROWING_FEE[_asset];
        uint256 newMaxBorrowingFee = (DECIMAL_PRECISION / 10000) * maxBorrowingFee;

        MAX_BORROWING_FEE[_asset] = newMaxBorrowingFee;
        require(MAX_BORROWING_FEE[_asset] > BORROWING_FEE_FLOOR[_asset], "Wrong inputs");

        emit MaxBorrowingFeeChanged(oldMaxBorrowingFee, newMaxBorrowingFee);
    }

    function setMinNetDebt(address _asset, uint256 minNetDebt)
        public
        override
        onlyOwner
        safeCheck("Min Net Debt", _asset, minNetDebt, 0, 10000 ether)
    {
        uint256 oldMinNet = MIN_NET_DEBT[_asset];
        MIN_NET_DEBT[_asset] = minNetDebt;

        emit MinNetDebtChanged(oldMinNet, minNetDebt);
    }

    function setRedemptionFeeFloor(address _asset, uint256 redemptionFeeFloor)
        public
        override
        onlyOwner
        safeCheck("Redemption Fee Floor", _asset, redemptionFeeFloor, 10, 1000) /// 0.10% - 10%
    {
        uint256 oldRedemptionFeeFloor = REDEMPTION_FEE_FLOOR[_asset];
        uint256 newRedemptionFeeFloor = (DECIMAL_PRECISION / 10000) * redemptionFeeFloor;

        REDEMPTION_FEE_FLOOR[_asset] = newRedemptionFeeFloor;
        emit RedemptionFeeFloorChanged(oldRedemptionFeeFloor, newRedemptionFeeFloor);
    }

    function removeRedemptionBlock(address _asset) external override onlyOwner {
        redemptionBlock[_asset] = block.timestamp;

        emit RedemptionBlockRemoved(_asset);
    }

    modifier safeCheck(
        string memory parameter,
        address _asset,
        uint256 enteredValue,
        uint256 min,
        uint256 max
    ) {
        require(
            hasCollateralConfigured[_asset],
            "Collateral is not configured, use setAsDefault or setCollateralParameters"
        );

        if (enteredValue < min || enteredValue > max) {
            revert SafeCheckError(parameter, enteredValue, min, max);
        }
        _;
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