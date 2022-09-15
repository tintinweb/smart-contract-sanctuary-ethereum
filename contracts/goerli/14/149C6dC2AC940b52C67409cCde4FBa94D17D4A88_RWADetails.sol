// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./access/AccessControlManager.sol";
import "./CurrencyOracle.sol";

/// @title Real World Asset Details
/// @notice This contract stores the real world assets for the protocol

contract RWADetails {
    /// @dev All assets are stored with 4 decimal shift unless specified
    uint128 public constant MO_DECIMALS = 10**4;
    uint256 public constant RWA_DECIMALS = 10**12;

    event RWAUnitCreated(uint256 indexed rWAUnitId);
    event RWAUnitAddedUnitsForTokenId(
        uint256 indexed rWAUnitId,
        uint16 indexed tokenId,
        uint64 units
    );
    event RWAUnitRedeemedUnitsForTokenId(
        uint256 indexed rWAUnitId,
        uint16 indexed tokenId,
        uint64 units
    );
    event RWAUnitDetailsUpdated(
        uint256 indexed rWAUnitId,
        uint128 indexed unitPrice,
        uint32 indexed priceUpdateDate,
        string portfolioDetailsLink
    );
    event RWAUnitSchemeDocumentLinkUpdated(
        uint256 indexed rWAUnitId,
        string schemeDocumentLink
    );
    event CurrencyOracleAddressSet(address indexed currencyOracleAddress);
    event AccessControlManagerSet(address indexed accessControlAddress);
    event SeniorDefaultUpdated(
        uint256 indexed rWAUnitId,
        bool indexed defaultFlag
    );
    event AutoCalcFlagUpdated(
        uint256 indexed rWAUnitId,
        bool indexed autoCalcFlag
    );
    event RWAUnitValueUpdated(
        uint256 indexed rWAUnitId,
        uint32 indexed priceUpdateDate,
        uint128 indexed unitPrice
    );
    event RWAUnitPayoutUpdated(
        uint256 indexed rWAUnitId,
        uint128 indexed payoutAmount,
        uint128 indexed unitPrice
    );

    /** @notice This variable (struct RWAUnit) stores details of real world asset (called RWAUnit).
     *  unit price, portfolio details link and price update date are refreshed regularly
     *  The units mapping stores how many real world asset units are held by MoH tokenId.
     *  apy stores daily compounding rate, shifted by 10 decimals.
     *  defaultFlag is used to indicate asset default.
     *  if autoCalcFlag is set to true then asset value is calculated using apy and time elapsed.
     *  apy is mandatory if autoCalculate is set to true.
     */
    /** @dev
     *  uint16 is sufficient for number of MoH tokens since its extremely unlikely to exceed 64k types of MoH tokens
     *  unint64 can hold 1600 trillion units of real world asset with 4 decimal places.
     *  uint32 can only hold 800k units of real world assets with 4 decimal places which might be insufficient
     *  (if each real world asset is $100, that is only $80m)
     *  since price is not 12 decimals shifted, increasing it to uint128
     */

    struct RWAUnit {
        bool autoCalcFlag;
        bool defaultFlag;
        uint16 tokenId;
        uint32 startDate;
        uint32 endDate;
        uint32 priceUpdateDate;
        uint64 apy; // RWA_DECIMALS shifted
        uint64 apyLeapYear; // RWA_DECIMALS shifted
        uint64 units;
        uint128 notionalValue; // RWA_DECIMALS shifted
        uint128 unitPrice; // RWA_DECIMALS shifted
        bytes32 fiatCurrency;
    }

    /** @notice This variable (struct RWAUnitDetail) stores additional details of real world asset (called RWAUnit).
     *  name is only updatable during creation.
     *  schemeDocumentLink is mostly static.
     *  portfolioDetailsLink is refreshed regularly
     */
    struct RWAUnitDetail {
        string name;
        string schemeDocumentLink;
        string portfolioDetailsLink;
    }

    /// @dev Currency Oracle Address contract associated with RWA unit
    address public currencyOracleAddress;

    /// @dev Implements RWA manager and whitelist access
    address public accessControlManagerAddress;

    /// @dev unique identifier for the rwa unit
    uint256 public rWAUnitId = 1;

    /// @dev used to determine number of days in asset value calculation
    bool public leapYear;

    /// @dev mapping between the id and the struct
    mapping(uint256 => RWAUnit) public rWAUnits;

    /// @dev mapping between unit id and additional details
    mapping(uint256 => RWAUnitDetail) public rWAUnitDetails;

    /// @dev mapping of tokenId to rWAUnitIds . Used for calculating asset value for a tokenId.
    mapping(uint256 => uint256[]) public tokenIdToRWAUnitId;

    constructor(address _accessControlManager) {
        accessControlManagerAddress = _accessControlManager;
        emit AccessControlManagerSet(_accessControlManager);
    }

    /// @notice Access modifier to restrict access only to owner

    modifier onlyOwner() {
        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );
        require(acm.isOwner(msg.sender), "NO");
        _;
    }

    /// @dev Access modifier to restrict access only to RWA manager addresses

    modifier onlyRWAManager() {
        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );
        require(acm.isRWAManager(msg.sender), "NR");
        _;
    }

    /// @dev Access modifier to restrict access only to RWA manager addresses

    modifier onlyCronManager() {
        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );
        require(acm.isCronManager(msg.sender), "NC");
        _;
    }

    /// @notice Setter for accessControlManagerAddress
    /// @param _accessControlManagerAddress Set accessControlManagerAddress to this address

    function setAccessControlManagerAddress(
        address _accessControlManagerAddress
    ) external onlyOwner {
        accessControlManagerAddress = _accessControlManagerAddress;
        emit AccessControlManagerSet(_accessControlManagerAddress);
    }

    /// @notice Setter for leapYear
    /// @param _leapYear whether current period is in a leap year

    function setLeapYear(bool _leapYear) external onlyRWAManager {
        leapYear = _leapYear;
    }

    /** @notice function createRWAUnit allows creation of a new Real World Asset type (RWA unit)
     *  It takes the name and scheme document as inputs along with initial price and date
     *  Checks on inputs include ensuring name is entered, link is provided for document and initial price is entered
     */
    /// @dev Explain to a developer any extra details
    /// @param _name is the name of the RWA scheme
    /// @param _schemeDocumentLink contains the link for the RWA scheme document
    /// @param _portfolioDetailsLink contains the link for the RWA portfolio details document
    /// @param _fiatCurrency  fiat currency for the unit
    /// @param _notionalValue initial value of a single RWA unit
    /// @param _autoCalcFlag specifies whether principal should be auto calculated. Only applicable for senior unit type
    /// @param _units number of units.
    /// @param _startDate specifies the start date for the rwa unit, mandatory input as this is the start for price calculation.
    /// @param _endDate specifies the end date for the rwa unit, place holder value, not used in any calculations.
    /// @param _tokenId specifies the mo token this unit is linked to. mandatory input as this cannot be set later for the unit.
    /// @param _apy daily compounding interest for the unit, used to update price when auto calculation is enabled for the unit.
    /// @param _apyLeapYear daily compounding interest for the unit during leap year

    function createRWAUnit(
        string memory _name,
        string memory _schemeDocumentLink,
        string memory _portfolioDetailsLink,
        bytes32 _fiatCurrency,
        uint128 _notionalValue,
        bool _autoCalcFlag,
        uint64 _units,
        uint32 _startDate,
        uint32 _endDate,
        uint16 _tokenId,
        uint64 _apy,
        uint64 _apyLeapYear
    ) external onlyRWAManager {
        require(
            (bytes(_name).length > 0) &&
                _tokenId > 0 &&
                _fiatCurrency != "" &&
                _notionalValue > 0 &&
                _startDate > 0,
            "BD"
        );
        if (_autoCalcFlag) {
            require(_apy > 0 && _apyLeapYear > 0, "WI");
        }

        uint256 id = rWAUnitId++;

        rWAUnits[id].fiatCurrency = _fiatCurrency;
        rWAUnits[id].unitPrice = _notionalValue;
        rWAUnits[id].tokenId = _tokenId;
        rWAUnits[id].autoCalcFlag = _autoCalcFlag;
        rWAUnits[id].startDate = _startDate;
        rWAUnits[id].priceUpdateDate = _startDate;
        rWAUnits[id].endDate = _endDate;
        rWAUnits[id].notionalValue = _notionalValue;
        rWAUnits[id].units = _units;
        rWAUnits[id].apy = _apy;
        rWAUnits[id].apyLeapYear = _apyLeapYear;

        tokenIdToRWAUnitId[_tokenId].push(id);

        rWAUnitDetails[id] = RWAUnitDetail({
            name: _name,
            schemeDocumentLink: _schemeDocumentLink,
            portfolioDetailsLink: _portfolioDetailsLink
        });

        emit RWAUnitCreated(id);
    }

    /** @notice Function allows adding RWA units to a particular RWA unit ID.
     */
    /** @dev Function emits the RWAUnitAddedUnitsForTokenId event which represents RWA id, MoH token id and number of units.
     *      It is read as given number of tokens of RWA id are added to MoH pool represnted by MoH token id
     *  @dev tokenIds stores the MoH token IDs holding units of this RWA.
     *      This mapping is specific to the RWA scheme represented by the struct
     */
    /// @param _id contains the id of the RWA unit being added
    /// @param _units contains the number of RWA units added to the MoH token

    function addRWAUnits(uint256 _id, uint64 _units) external onlyRWAManager {
        RWAUnit storage rWAUnit = rWAUnits[_id];
        rWAUnit.units += _units;
        emit RWAUnitAddedUnitsForTokenId(_id, rWAUnit.tokenId, _units);
    }

    /** @notice Function allows RWA manager to update redemption of RWA units. Redemption of RWA units leads to
     *  an increase in cash / stablecoin balances and reduction in RWA units held.
     *  The cash / stablecoin balances are not handled in this function
     */
    /** @dev Function emits the RWAUnitRedeemedUnitsForTokenId event which represents RWA id, MoH token id and number of units.
     *      It is read as given number of tokens of RWA id are subtracted from the MoH pool represnted by MoH token id
     */
    /// @param _id contains the id of the RWA unit being redeemed
    /// @param _units contains the number of RWA units redeemed from the MoH token

    function redeemRWAUnits(uint256 _id, uint64 _units)
        external
        onlyRWAManager
    {
        RWAUnit storage rWAUnit = rWAUnits[_id];
        require(rWAUnit.units >= _units, "ECA1");
        rWAUnit.units -= _units;
        emit RWAUnitRedeemedUnitsForTokenId(_id, rWAUnit.tokenId, _units);
    }

    /** @notice Function allows RWA Manager to update the RWA scheme documents which provides the parameter of the RWA scheme such as fees,
     *  how the scheme is run etc. This is not expected to be updated frequently
     */
    /// @dev Function emits RWAUnitSchemeDocumentLinkUpdated event which provides id of RWA scheme update and the updated scheme document link
    /// @param _schemeDocumentLink stores the link to the RWA scheme document
    /// @param _id contains the id of the RWA being updated

    function updateRWAUnitSchemeDocumentLink(
        uint256 _id,
        string memory _schemeDocumentLink
    ) external onlyRWAManager {
        require((bytes(_schemeDocumentLink)).length > 0, "ECC2");
        rWAUnitDetails[_id].schemeDocumentLink = _schemeDocumentLink;
        emit RWAUnitSchemeDocumentLinkUpdated(_id, _schemeDocumentLink);
    }

    /** @notice Function allows RWA Manager to update the details of the RWA portfolio.
     *  Changes in the portfolio holdings and / or price of holdings are updated via portfolio details link and
     *  the updated price of RWA is updated in _unitPrice field. This is expected to be updated regulatory
     */
    /// @dev Function emits RWAUnitDetailsUpdated event which provides id of RWA updated, unit price updated and price update date
    /// @param _id Refers to id of the RWA being updated
    /// @param _unitPrice stores the price of a single RWA unit
    /// @param _priceUpdateDate stores the last date on which the RWA unit price was updated by RWA Manager
    /// @param _portfolioDetailsLink stores the link to the file containing details of the RWA portfolio and unit price

    function updateRWAUnitDetails(
        uint256 _id,
        string memory _portfolioDetailsLink,
        uint128 _unitPrice,
        uint32 _priceUpdateDate
    ) external onlyRWAManager {
        require((bytes(_portfolioDetailsLink)).length > 0, "ECC2");

        RWAUnit storage rWAUnit = rWAUnits[_id];
        rWAUnit.unitPrice = _unitPrice;
        rWAUnitDetails[_id].portfolioDetailsLink = _portfolioDetailsLink;
        rWAUnit.priceUpdateDate = _priceUpdateDate;
        emit RWAUnitDetailsUpdated(
            _id,
            _unitPrice,
            _priceUpdateDate,
            _portfolioDetailsLink
        );
    }

    /// @notice Allows setting currencyOracleAddress
    /// @param _currencyOracleAddress address of the currency oracle

    function setCurrencyOracleAddress(address _currencyOracleAddress)
        external
        onlyOwner
    {
        currencyOracleAddress = _currencyOracleAddress;
        emit CurrencyOracleAddressSet(currencyOracleAddress);
    }

    /** @notice Function allows RWA Manager to update defaultFlag for a linked senior unit.
     */
    /// @dev Function emits SeniorDefaultUpdated event which provides value of defaultFlag for the unit id.
    /// @param _id Refers to id of the RWA being updated
    /// @param _defaultFlag boolean value to be set.

    function setSeniorDefault(uint256 _id, bool _defaultFlag)
        external
        onlyRWAManager
    {
        rWAUnits[_id].defaultFlag = _defaultFlag;
        emit SeniorDefaultUpdated(_id, _defaultFlag);
    }

    /** @notice Function allows RWA Manager to update autoCalcFlag for the RWA unit.
     * If value of autoCalcFlag is false then unitPrice and priceUpdateDate are mandatory.
     * If value of autoCalcFlag is true then apy and apyLeapYear can only be set if
     * values are not set for these attributes.
     */
    /// @dev Function emits AutoCalcFlagUpdated event which provides id of RWA updated and autoCalcFlag value set.
    /// @param _id Refers to id of the RWA being updated
    /// @param _autoCalcFlag Refers to autoCalcFlag of the RWA being updated
    /// @param _unitPrice Refers to unitPrice of the RWA being updated
    /// @param _priceUpdateDate Refers to priceUpdateDate of the RWA being updated
    /// @param _apy Refers to daily compounding interest of the RWA being updated

    function updateAutoCalc(
        uint256 _id,
        bool _autoCalcFlag,
        uint128 _unitPrice,
        uint32 _priceUpdateDate,
        uint64 _apy,
        uint64 _apyLeapYear
    ) external onlyRWAManager {
        require(
            _autoCalcFlag
                ? ((rWAUnits[_id].apy > 0 && rWAUnits[_id].apyLeapYear > 0) ||
                    (_apy > 0 && _apyLeapYear > 0))
                : (_unitPrice > 0 && _priceUpdateDate > 0),
            "WI"
        );

        rWAUnits[_id].autoCalcFlag = _autoCalcFlag;
        if (_autoCalcFlag) {
            if (rWAUnits[_id].apy == 0) {
                rWAUnits[_id].apy = _apy;
                rWAUnits[_id].apyLeapYear = _apyLeapYear;
            }
        } else {
            rWAUnits[_id].unitPrice = _unitPrice;
            rWAUnits[_id].priceUpdateDate = _priceUpdateDate;
        }
        emit AutoCalcFlagUpdated(_id, _autoCalcFlag);
    }

    /** @notice Function returns whether token redemption is allowed for the RWA unit id.
     *  Returns true only if units have been redeemed or outstanding amount is 0 and defaultFlag is false
     */
    /// @param _id Refers to id of the RWA unit
    /// @return redemptionAllowed Indicates whether the RWA unit can be redeemed.

    function isRedemptionAllowed(uint256 _id)
        external
        view
        returns (bool redemptionAllowed)
    {
        redemptionAllowed =
            (rWAUnits[_id].units == 0 || rWAUnits[_id].unitPrice == 0) &&
            !rWAUnits[_id].defaultFlag;
    }

    /** @notice Function is used to udpate the rwa unit value if auto calculation is enabled for the RWA unit id.
     *  apy is used to calculate and the udpate the latest unit price.
     */
    /// @param _id Refers to id of the RWA unit
    /// @param _date Date for which rwa asset value should be updated to.

    function updateRWAUnitValue(uint16 _id, uint32 _date)
        public
        onlyCronManager
    {
        RWAUnit storage rWAUnit = rWAUnits[_id];

        require(
            _date >= rWAUnit.priceUpdateDate &&
                rWAUnit.autoCalcFlag &&
                (uint32(block.timestamp) > _date),
            "IT"
        );

        uint256 calculatedAmount = uint256(rWAUnit.unitPrice);

        uint256 daysPassed = uint256(
            (_date - rWAUnit.priceUpdateDate) / 1 days
        );

        uint256 loops = daysPassed / 4; // looping to prevent overflow
        uint256 remainder = daysPassed % 4;

        uint256 interest = (RWA_DECIMALS +
            (leapYear ? rWAUnit.apyLeapYear : rWAUnit.apy))**4;

        for (uint256 i = 0; i < loops; i = i + 1) {
            calculatedAmount =
                (calculatedAmount * interest) /
                (RWA_DECIMALS**4);
        }

        if (remainder > 0) {
            interest =
                (RWA_DECIMALS +
                    (leapYear ? rWAUnit.apyLeapYear : rWAUnit.apy)) **
                    remainder;
            calculatedAmount =
                (calculatedAmount * interest) /
                (RWA_DECIMALS**remainder);
        }

        rWAUnit.priceUpdateDate = _date;
        rWAUnit.unitPrice = uint128(calculatedAmount);

        emit RWAUnitValueUpdated(_id, _date, rWAUnit.unitPrice);
    }

    /** @notice Function is used to register payout for the RWA unit id.
     *  RWA value is update to the date specified and then payout is subtracted to get latest price.
     */
    /// @param _id Refers to id of the RWA unit
    /// @param _date Date for which rwa asset value should be updated to.
    /// @param _payoutAmount payout amount to be subtracted from the unit price.

    function udpatePayout(
        uint16 _id,
        uint32 _date,
        uint128 _payoutAmount
    ) external onlyCronManager {
        RWAUnit storage rWAUnit = rWAUnits[_id];

        updateRWAUnitValue(_id, _date);
        if (rWAUnit.unitPrice <= _payoutAmount) {
            rWAUnit.unitPrice = 0;
        } else {
            rWAUnit.unitPrice = rWAUnit.unitPrice - _payoutAmount;
        }
        emit RWAUnitPayoutUpdated(_id, _payoutAmount, rWAUnit.unitPrice);
    }

    /** @notice Function returns the value of RWA units held by a given MoH token id.
     *  This is calculated as number of RWA units against the MoH token multiplied by unit price of an RWA token.
     */
    /// @dev Explain to a developer any extra details
    /// @param _tokenId is the MoH token Id for which value of RWA units is being calculated
    /// @param _inCurrency currency in which assetValue is to be returned
    /// @return assetValue real world asset value for the token as per the date in the requested currency.

    function getRWAValueByTokenId(uint16 _tokenId, bytes32 _inCurrency)
        external
        view
        returns (uint128 assetValue)
    {
        CurrencyOracle currencyOracle = CurrencyOracle(currencyOracleAddress);

        uint256[] memory tokenUnitIds = tokenIdToRWAUnitId[_tokenId];

        for (uint256 i = 0; i < tokenUnitIds.length; i++) {
            uint256 id = tokenUnitIds[i];
            RWAUnit storage rWAUnit = rWAUnits[id];

            if (rWAUnit.units == 0 || rWAUnit.unitPrice == 0) continue;

            uint128 calculatedAmount = rWAUnit.unitPrice * rWAUnit.units;

            // convert if necessary and add to assetValue
            if (rWAUnit.fiatCurrency == _inCurrency) {
                assetValue += calculatedAmount;
            } else {
                (uint64 convRate, uint8 decimalsVal) = currencyOracle
                    .getFeedLatestPriceAndDecimals(
                        rWAUnit.fiatCurrency,
                        _inCurrency
                    );
                assetValue += ((calculatedAmount * convRate) /
                    uint128(10**decimalsVal));
            }
        }
        // returning 4 decimal shifted asset value
        assetValue = assetValue / uint128(RWA_DECIMALS);
    }

    /** @notice Function returns RWA units for the token Id
     */
    /// @param _tokenId Refers to token id
    /// @return rWAUnitsByTokenId returns array of RWA Unit IDs associated to tokenId

    function getRWAUnitsForTokenId(uint256 _tokenId)
        external
        view
        returns (uint256[] memory rWAUnitsByTokenId)
    {
        rWAUnitsByTokenId = tokenIdToRWAUnitId[_tokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract AccessControlManager is AccessControlEnumerable {
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");
    bytes32 public constant RWA_MANAGER_ROLE = keccak256("RWA_MANAGER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant CRON_MANAGER_ROLE = keccak256("CRON_MANAGER_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(WHITELIST_ROLE, ADMIN_ROLE);
        _setRoleAdmin(RWA_MANAGER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(CRON_MANAGER_ROLE, ADMIN_ROLE);
    }

    function changeRoleAdmin(bytes32 role, bytes32 newAdminRole)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(role != DEFAULT_ADMIN_ROLE, "NA");
        _setRoleAdmin(role, newAdminRole);
    }

    function isOwner(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function isWhiteListed(address account) external view returns (bool) {
        return hasRole(WHITELIST_ROLE, account);
    }

    function isRWAManager(address account) external view returns (bool) {
        return hasRole(RWA_MANAGER_ROLE, account);
    }

    function isAdmin(address account) external view returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }

    function isCronManager(address account) external view returns (bool) {
        return hasRole(CRON_MANAGER_ROLE, account);
    }

    function owner() external view returns (address) {
        return
            getRoleMember(
                DEFAULT_ADMIN_ROLE,
                getRoleMemberCount(DEFAULT_ADMIN_ROLE) - 1
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title CurrencyOracle
/// @notice This handles all the operations related currency exchange

contract CurrencyOracle is Ownable {
    event feedAddressSet(
        address indexed feedAddress,
        bytes32 indexed fromCurrency,
        bytes32 indexed toCurrency
    );

    /// @dev mapping b/w encoded bytes32 of currecies and chainLink Date Feed proxy Address
    mapping(bytes32 => address) public dataFeedAddressMapper;

    /// @notice Allows adding mapping b/w encoded bytes32 of currecies and chainLink Date Feed proxy Address
    /// @param _fromCurrency _fromCurrency
    /// @param _toCurrency _toCurrency
    /// @param _feedAddress proxyaddress of chainLinkDataFeed

    function setOracleFeedAddress(
        bytes32 _fromCurrency,
        bytes32 _toCurrency,
        address _feedAddress
    ) external onlyOwner {
        dataFeedAddressMapper[
            keccak256(abi.encodePacked(_fromCurrency, _toCurrency))
        ] = _feedAddress;
        emit feedAddressSet(_feedAddress, _fromCurrency, _toCurrency);
    }

    /// @notice to get latest price and decimals
    /// @param _fromCurrency _fromCurrency
    /// @param _toCurrency _toCurrency
    /// @return lastestPrice  returns latest price of coversion
    /// @return decimals  returns decimals of  priceCoversion

    function getFeedLatestPriceAndDecimals(
        bytes32 _fromCurrency,
        bytes32 _toCurrency
    ) external view returns (uint64 lastestPrice, uint8 decimals) {
        address feedAddress = dataFeedAddressMapper[
            keccak256(abi.encodePacked(_fromCurrency, _toCurrency))
        ];
        require(feedAddress != address(0), "ECDE");
        AggregatorV3Interface prcieFeed = AggregatorV3Interface(feedAddress);
        (, int256 price, , , ) = prcieFeed.latestRoundData();
        return (uint64(uint256(price)), prcieFeed.decimals());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

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