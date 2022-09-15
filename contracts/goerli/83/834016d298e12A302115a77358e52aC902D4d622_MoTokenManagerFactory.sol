// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./MoToken.sol";
import "./MoTokenManager.sol";
import "./utils/StringUtil.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Factory contract for MoTokenManager
/** @notice This contract creates MoTokenManager for a given MoToken.
 *  This also gives us a way to get MoTokenManager give a token symbol.
 */
contract MoTokenManagerFactory is Ownable {
    /// @dev Mapping points to the token manager of a given token's symbol
    mapping(bytes32 => address) public symbolToTokenManager;

    /// @dev Holds all the mo token symbols
    bytes32[] public symbols;

    /// @dev Mapping points to the senior token symbol for a junior token symbol
    mapping(bytes32 => bytes32) public linkedSrTokenOf;

    /// @dev Index used while creating MoTokenManager
    uint16 public tokenId;

    event MoTokenManagerAdded(
        address indexed from,
        bytes32 indexed tokenSymbol,
        address indexed tokenManager
    );
    event JrTokenLinkedToSrToken(
        bytes32 indexed jrToken,
        bytes32 indexed srToken
    );

    /// @notice Adds MoTokenManager for a given MoToken
    /// @param _token Address of MoToken contract
    /// @param _tokenManager Address of MoTokenManager contract
    /// @param _stableCoin Stable coin contract address
    /// @param _initNAV Initial NAV value
    /// @param _rWADetails Address of RWADetails contract

    function addTokenManager(
        address _token,
        address _tokenManager,
        address _stableCoin,
        uint64 _initNAV,
        address _rWADetails
    ) external onlyOwner {
        MoToken mt = MoToken(_token);
        string memory tokenSymbol = mt.symbol();
        require((bytes(tokenSymbol).length > 0), "IT");

        bytes32 tokenBytes = StringUtil.stringToBytes32(tokenSymbol);
        require(symbolToTokenManager[tokenBytes] == address(0), "AE");

        tokenId = tokenId + 1;
        symbolToTokenManager[tokenBytes] = _tokenManager;

        MoTokenManager tManager = MoTokenManager(_tokenManager);
        tManager.initialize(
            tokenId,
            _token,
            _stableCoin,
            _initNAV,
            _rWADetails
        );

        symbols.push(tokenBytes);

        emit MoTokenManagerAdded(msg.sender, tokenBytes, _tokenManager);
    }

    /// @notice Links a Junior token to Senior token.
    /// @param _jrToken Symbol of MoJuniorToken
    /// @param _srToken Symbol of Senior MoToken

    function linkJrTokenToSrToken(bytes32 _jrToken, bytes32 _srToken)
        external
        onlyOwner
    {
        require(symbolToTokenManager[_jrToken] != address(0), "NT");
        require(symbolToTokenManager[_srToken] != address(0), "NT");

        address juniorTokenAddress = MoTokenManager(
            symbolToTokenManager[_jrToken]
        ).token();

        address seniorTokenAddress = MoTokenManager(
            symbolToTokenManager[_srToken]
        ).token();

        MoToken(juniorTokenAddress).linkToSeniorToken(seniorTokenAddress);
        MoToken(seniorTokenAddress).linkToJuniorToken(juniorTokenAddress);
        emit JrTokenLinkedToSrToken(_jrToken, _srToken);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

library StringUtil {
    function stringToBytes32(string memory source)
        public
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IERC20Basic {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
import "./interfaces/IERC20Basic.sol";
import "./MoToken.sol";
import "./CurrencyOracle.sol";

/// @title Stable coin manager
/// @notice This handles all stable coin operations related to the token

contract StableCoin {
    /// @dev All assets are stored with 4 decimal shift
    uint8 public constant MO_DECIMALS = 4;

    /// @dev Mapping points to the address where the stablecoin contract is deployed on chain
    mapping(bytes32 => address) public contractAddressOf;

    /// @dev Mapping points to the pipe address where the stablecoins to be converted to fiat are transferred
    mapping(bytes32 => address) public pipeAddressOf;

    /// @dev Array of all stablecoins added to the contract
    bytes32[] private stableCoinsAssociated;

    /// @dev OraclePriceExchange Address contract associated with the stable coin
    address public currencyOracleAddress;

    /// @dev platform fee currency associated with tokens
    bytes32 public platformFeeCurrency = "USDC";

    /// @dev Accrued fee amount charged by the platform
    uint256 public accruedPlatformFee;

    /// @dev Implements RWA manager and whitelist access
    address public accessControlManagerAddress;

    event CurrencyOracleAddressSet(address indexed currencyOracleAddress);
    event StableCoinAdded(
        bytes32 indexed symbol,
        address indexed contractAddress,
        address indexed pipeAddress
    );
    event StableCoinDeleted(bytes32 indexed symbol);
    event AccessControlManagerSet(address indexed accessControlAddress);

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

    /// @notice Access modifier to restrict access only to RWA manager addresses

    modifier onlyRWAManager() {
        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );
        require(acm.isRWAManager(msg.sender), "NR");
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

    /// @notice Allows setting currencyOracleAddress
    /// @param _currencyOracleAddress address of the currency oracle

    function setCurrencyOracleAddress(address _currencyOracleAddress)
        external
        onlyOwner
    {
        currencyOracleAddress = _currencyOracleAddress;
        emit CurrencyOracleAddressSet(currencyOracleAddress);
    }

    /// @notice Adds a new stablecoin
    /// @dev There can be no duplicate entries for same stablecoin symbol
    /// @param _symbol Stablecoin symbol
    /// @param _contractAddress Stablecoin contract address on chain
    /// @param _pipeAddress Pipe address associated with the stablecoin

    function addStableCoin(
        bytes32 _symbol,
        address _contractAddress,
        address _pipeAddress
    ) external onlyOwner {
        require(
            _symbol.length > 0 && contractAddressOf[_symbol] == address(0),
            "SCE"
        );
        contractAddressOf[_symbol] = _contractAddress;
        stableCoinsAssociated.push(_symbol);
        pipeAddressOf[_symbol] = _pipeAddress;
        emit StableCoinAdded(_symbol, _contractAddress, _pipeAddress);
    }

    /// @notice Deletes an existing stablecoin
    /// @param _symbol Stablecoin symbol

    function deleteStableCoin(bytes32 _symbol) external onlyOwner {
        require(contractAddressOf[_symbol] != address(0), "NC");
        delete contractAddressOf[_symbol];
        delete pipeAddressOf[_symbol];
        for (uint256 i = 0; i < stableCoinsAssociated.length; i++) {
            if (stableCoinsAssociated[i] == _symbol) {
                stableCoinsAssociated[i] = stableCoinsAssociated[
                    stableCoinsAssociated.length - 1
                ];
                stableCoinsAssociated.pop();
                break;
            }
        }
        emit StableCoinDeleted(_symbol);
    }

    /// @notice Getter for Stable coins associated
    /// @return bytes32[] Stable coins accepted by the token

    function getStableCoinsAssociated()
        external
        view
        returns (bytes32[] memory)
    {
        return stableCoinsAssociated;
    }

    /// @notice Get balance of the stablecoins in the wallet address
    /// @param _symbol Stablecoin symbol
    /// @param _address User address
    /// @return uint Returns the stablecoin balance

    function balanceOf(bytes32 _symbol, address _address)
        public
        view
        returns (uint256)
    {
        IERC20Basic ier = IERC20Basic(contractAddressOf[_symbol]);
        return ier.balanceOf(_address);
    }

    /// @notice Gets the decimals of the token
    /// @param _tokenSymbol Token symbol
    /// @return uint8 ERC20 decimals() value

    function decimals(bytes32 _tokenSymbol) public view returns (uint8) {
        IERC20Basic ier = IERC20Basic(contractAddressOf[_tokenSymbol]);
        return ier.decimals();
    }

    /// @notice Gets the total stablecoin balance associated with the MoToken
    /// @param _token Token address
    /// @param _fiatCurrency Fiat currency used
    /// @return balance Stablecoin balance

    function totalBalanceInFiat(address _token, bytes32 _fiatCurrency)
        public
        view
        returns (uint256 balance)
    {
        CurrencyOracle currencyOracle = CurrencyOracle(currencyOracleAddress);
        for (uint256 i = 0; i < stableCoinsAssociated.length; i++) {
            (uint64 stableToFiatConvRate, uint8 decimalsVal) = currencyOracle
                .getFeedLatestPriceAndDecimals(
                    stableCoinsAssociated[i],
                    _fiatCurrency
                );
            uint8 finalDecVal = decimalsVal +
                decimals(stableCoinsAssociated[i]) -
                MO_DECIMALS;
            balance +=
                (balanceOf(stableCoinsAssociated[i], _token) *
                    stableToFiatConvRate) /
                (10**finalDecVal);
            balance +=
                (balanceOf(
                    stableCoinsAssociated[i],
                    pipeAddressOf[stableCoinsAssociated[i]]
                ) * stableToFiatConvRate) /
                (10**finalDecVal);
        }
        balance -= accruedPlatformFee;
    }

    /// @notice Transfers tokens from an external address to the MoToken Address
    /// @param _token Token address
    /// @param _from Transfer tokens from this address
    /// @param _amount Amount to transfer
    /// @param _symbol Symbol of the tokens to transfer
    /// @return bool Boolean indicating transfer success/failure

    function initiateTransferFrom(
        address _token,
        address _from,
        uint256 _amount,
        bytes32 _symbol
    ) external returns (bool) {
        require(contractAddressOf[_symbol] != address(0), "NC");
        MoToken moToken = MoToken(_token);
        return (
            moToken.receiveStableCoins(
                contractAddressOf[_symbol],
                _from,
                _amount
            )
        );
    }

    /// @notice Transfers tokens from the MoToken address to the stablecoin pipe address
    /// @param _token Token address
    /// @param _amount Amount to transfer
    /// @param _symbol Symbol of the tokens to transfer
    /// @return bool Boolean indicating transfer success/failure

    function transferFundsToPipe(
        address _token,
        bytes32 _symbol,
        uint256 _amount
    ) external onlyRWAManager returns (bool) {
        checkForSufficientBalance(_token, _symbol, _amount);

        MoToken moToken = MoToken(_token);
        return (
            moToken.transferStableCoins(
                contractAddressOf[_symbol],
                pipeAddressOf[_symbol],
                _amount
            )
        );
    }

    /// @notice Check for sufficient balance
    /// @param _address Address holding the tokens
    /// @param _symbol Symbol of the token
    /// @param _amount amount to check

    function checkForSufficientBalance(
        address _address,
        bytes32 _symbol,
        uint256 _amount
    ) public view {
        uint256 balance = balanceOf(_symbol, _address);
        if (_symbol == platformFeeCurrency) {
            balance -= accruedPlatformFee;
        }
        require(_amount <= balance, "NF");
    }
}

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

import "./StableCoin.sol";
import "./MoToken.sol";
import "./RWADetails.sol";
import "./access/AccessControlManager.sol";

/// @title Token manager for open/senior token
/// @notice This is a token manager which handles all operations related to the token

contract MoTokenManager {
    /// @dev All assets are stored with 4 decimal shift
    uint8 public constant MO_DECIMALS = 4;

    /// @dev RWA Details contract address which stores real world asset details
    address public rWADetails;

    /// @dev Limits the total supply of the token.
    uint256 public tokenSupplyLimit;

    /// @dev Implements RWA manager and whitelist access
    address public accessControlManagerAddress;

    /// @dev Address of the associated MoToken
    address public token;

    /// @dev Holds exponential value for MO token decimals
    uint256 public tokenDecimals;

    /// @dev OraclePriceExchange Address contract associated with the stable coin
    address public currencyOracleAddress;

    /// @dev fiatCurrency associated with tokens
    bytes32 public fiatCurrency = "USD";

    /// @dev platform fee currency associated with tokens
    bytes32 public platformFeeCurrency = "USDC";

    /// @dev Accrued fee amount charged by the platform
    uint256 public accruedPlatformFee;

    /// @dev stableCoin Address contract used for stable coin operations
    address public stableCoinAddress;

    /// @dev Holds the corresponding senior RWA Unit ID of the junior token
    uint256 public linkedSrRwaUnitId;

    /** @notice This struct stores all the properties associated with the token
     *  id - MoToken id
     *  navDeviationAllowance - Percentage of NAV change allowed without approval flow
     *  daysInAYear - Number of days in a year, used to calculate fee
     *  platformFee - Platform fee in basis points
     *  navUpdateTimestamp - Timestamp when NAV was last updated
     *  navApprovalRequestTimestamp - Timestamp of last instance when NAV went to approval flow
     *  nav - NAV of the token
     *  navUnapproved - NAV unapproved value stored for approval flow
     *  pipeFiatStash - Fiat amount which is in transmission between the stable coin pipe and the RWA bank account
     *  fiatInTransit - Fiat amount in transit to stash
     */

    struct TokenDetails {
        uint16 id;
        uint16 navDeviationAllowance; // in percent
        uint16 daysInAYear;
        uint32 platformFee; // in basis points
        uint32 navUpdateTimestamp; // timestamp
        uint32 navApprovalRequestTimestamp;
        uint64 nav; // 4 decimal shifted
        uint64 navUnapproved;
        uint64 pipeFiatStash; // 4 decimal shifted
        uint64 fiatInTransit;
    }

    TokenDetails public tokenData;

    event Purchase(address indexed user, uint256 indexed tokens);
    event RWADetailsSet(address indexed rwaAddress);
    event FiatCurrencySet(bytes32 indexed currency);
    event FiatCredited(uint64 indexed amount, uint32 indexed date);
    event FiatDebited(uint64 indexed amount, uint32 indexed date);
    event NAVUpdated(uint64 indexed nav, uint32 indexed date);
    event TokenSupplyLimitSet(uint256 indexed tokenSupplyLimit);
    event NAVApprovalRequest(
        uint64 indexed navUnapproved,
        uint32 indexed stashUpdateDate
    );
    event PlatformFeeSet(uint32 indexed platformFee);
    event PlatformFeeCurrencySet(bytes32 indexed currency);
    event FeeTransferred(uint256 indexed fee);
    event AccessControlManagerSet(address indexed accessControlAddress);
    event CurrencyOracleAddressSet(address indexed currencyOracleAddress);
    event StableCoinAddressSet(address indexed stableCoinAddress);
    event dividend(address account, uint256 dividendAmount, uint256 moBal);

    /// @notice Constructor instantiates access control

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

    /// @notice Access modifier to restrict access only to RWA manager addresses

    modifier onlyRWAManager() {
        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );
        require(acm.isRWAManager(msg.sender), "NR");
        _;
    }

    /// @notice Access modifier to restrict access only to Admin addresses

    modifier onlyAdmin() {
        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );
        require(acm.isAdmin(msg.sender), "NA");
        _;
    }

    /// @notice Access modifier to restrict access only to Cron Admin addresses

    modifier onlyCronManager() {
        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );
        require(acm.isCronManager(msg.sender), "NC");
        _;
    }

    /// @notice returns the owner address

    function owner() public view returns (address) {
        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );
        return acm.owner();
    }

    /// @notice Initializes basic properties associated with the token
    /// @param _id MoToken Id
    /// @param _token token address
    /// @param _stableCoin StableCoin contract address
    /// @param _initNAV Initial NAV value
    /// @param _rWADetails RWADetails contract address

    function initialize(
        uint16 _id,
        address _token,
        address _stableCoin,
        uint64 _initNAV,
        address _rWADetails
    ) external {
        require(tokenData.id == 0, "AE");

        tokenData.id = _id;
        token = _token;
        tokenDecimals = 10**MO_DECIMALS;
        stableCoinAddress = _stableCoin;
        rWADetails = _rWADetails;
        tokenData.nav = _initNAV;
        tokenData.navDeviationAllowance = 10;
        tokenData.daysInAYear = 365;
        tokenData.navUpdateTimestamp =
            uint32(block.timestamp) -
            (uint32(block.timestamp) % 1 days);
    }

    /// @notice Setter for accessControlManagerAddress
    /// @param _accessControlManagerAddress Set accessControlManagerAddress to this address

    function setAccessControlManagerAddress(
        address _accessControlManagerAddress
    ) external onlyOwner {
        accessControlManagerAddress = _accessControlManagerAddress;
        emit AccessControlManagerSet(_accessControlManagerAddress);
    }

    /// @notice Setter for stableCoin
    /// @param _stableCoinAddress Set stableCoin to this address

    function setStableCoinAddress(address _stableCoinAddress)
        external
        onlyOwner
    {
        stableCoinAddress = _stableCoinAddress;
        emit StableCoinAddressSet(stableCoinAddress);
    }

    /// @notice Setter for RWADetails contract associated with the MoToken
    /// @param _rWADetails Address of contract storing RWADetails

    function setRWADetailsAddress(address _rWADetails) external onlyOwner {
        rWADetails = _rWADetails;
        emit RWADetailsSet(rWADetails);
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

    /// @notice Allows setting fiatCurrecy associated with tokens
    /// @param _fiatCurrency fiatCurrency

    function setFiatCurrency(bytes32 _fiatCurrency) external onlyOwner {
        fiatCurrency = _fiatCurrency;
        emit FiatCurrencySet(fiatCurrency);
    }

    /// @notice Setter for platform fee currency
    /// @param _feeCurrency platform fee currency

    function setPlatformFeeCurrency(bytes32 _feeCurrency)
        external
        onlyRWAManager
    {
        platformFeeCurrency = _feeCurrency;
        emit PlatformFeeCurrencySet(platformFeeCurrency);
    }

    /// @notice Setter for platform fee
    /// @param _fee platform fee

    function setFee(uint32 _fee) external onlyOwner {
        require(_fee < 10000, "NA");
        tokenData.platformFee = _fee;
        emit PlatformFeeSet(_fee);
    }

    /// @notice Allows setting tokenSupplyLimit associated with tokens
    /// @param _tokenSupplyLimit limit to be set for the token supply

    function setTokenSupplyLimit(uint256 _tokenSupplyLimit)
        external
        onlyRWAManager
    {
        tokenSupplyLimit = _tokenSupplyLimit;
        emit TokenSupplyLimitSet(tokenSupplyLimit);
    }

    /// @notice Allows setting NAV deviation allowance by Owner
    /// @param _value Allowed deviation limit (Eg: 10 for 10% deviation)

    function setNavDeviationAllowance(uint16 _value) external onlyOwner {
        tokenData.navDeviationAllowance = _value;
    }

    /// @notice Raise request for platform fee transfer to governor
    /// @param amount fee transfer amount in fiat currency

    function sweepFeeToGov(uint256 amount) external onlyAdmin {
        accruedPlatformFee -= amount;
        require(transferFeeToGovernor(amount), "TF");
        emit FeeTransferred(amount);
    }

    /// @notice Calculates the incremental platform fee the given timestamp and
    /// and updates the total accrued fee.
    /// @param _timestamp timestamp for fee accrual
    /// @param _totalAssetValue Total asset value of the token

    function accrueFee(uint32 _timestamp, uint256 _totalAssetValue) internal {
        uint256 calculatedFee = ((_timestamp - tokenData.navUpdateTimestamp) *
            tokenData.platformFee *
            _totalAssetValue) /
            10**MO_DECIMALS /
            tokenData.daysInAYear /
            1 days;
        accruedPlatformFee += calculatedFee;
    }

    /// @notice Returns the token id for the associated token.

    function getId() public view returns (uint16) {
        return tokenData.id;
    }

    /// @notice Sets days in a year to be used in fee calculation.

    function setDaysInAYear(uint16 _days) external onlyRWAManager {
        require(_days == 365 || _days == 366, "INV");
        tokenData.daysInAYear = _days;
    }

    /// @notice This function is called by the purchaser of MoH tokens. The protocol transfers _depositCurrency
    /// from the purchaser and mints and transfers MoH token to the purchaser
    /// @dev tokenData.nav has the NAV (in USD) of the MoH token. The number of MoH tokens to mint = _depositAmount (in USD) / NAV
    /// @param _depositAmount is the amount in stable coin (decimal shifted) that the purchaser wants to pay to buy MoH tokens
    /// @param _depositCurrency is the token that purchaser wants to pay with (eg: USDC, USDT etc)

    function purchase(uint256 _depositAmount, bytes32 _depositCurrency)
        external
    {
        uint256 tokensToMint = stableCoinToTokens(
            _depositAmount,
            _depositCurrency
        );

        MoToken moToken = MoToken(token);
        require(
            tokenSupplyLimit + moToken.balanceOf(token) >=
                moToken.totalSupply() + tokensToMint,
            "LE"
        );

        StableCoin sCoin = StableCoin(stableCoinAddress);
        require(
            sCoin.initiateTransferFrom({
                _token: token,
                _from: msg.sender,
                _amount: _depositAmount,
                _symbol: _depositCurrency
            }),
            "PF"
        );

        moToken.mint(msg.sender, tokensToMint);

        emit Purchase(msg.sender, tokensToMint);
    }

    /// @notice Converts stable coin amount to token amount
    /// @param _amount Stable coin amount
    /// @param _stableCoin Stable coin symbol
    /// @return tokens Calculated token amount

    function stableCoinToTokens(uint256 _amount, bytes32 _stableCoin)
        public
        view
        returns (uint256 tokens)
    {
        CurrencyOracle currencyOracle = CurrencyOracle(currencyOracleAddress);
        (uint64 stableToFiatConvRate, uint8 decimalsVal) = currencyOracle
            .getFeedLatestPriceAndDecimals(_stableCoin, fiatCurrency);

        StableCoin sCoin = StableCoin(stableCoinAddress);

        int8 decimalCorrection = int8(MO_DECIMALS) +
            int8(MO_DECIMALS) -
            int8(sCoin.decimals(_stableCoin)) -
            int8(decimalsVal);

        tokens = _amount * stableToFiatConvRate;
        if (decimalCorrection > -1) {
            tokens = tokens * 10**uint8(decimalCorrection);
        } else {
            decimalCorrection = -decimalCorrection;
            tokens = tokens / 10**uint8(decimalCorrection);
        }
        tokens = tokens / tokenData.nav;
    }

    /// @notice The function allows RWA manger to provide the increase in pipe fiat balances against the MoH token
    /// @param _amount the amount by which RWA manager is increasing the pipeFiatStash of the MoH token
    /// @param _date RWA manager is crediting pipe fiat for this date

    function creditPipeFiat(uint64 _amount, uint32 _date)
        external
        onlyCronManager
    {
        tokenData.pipeFiatStash += _amount;
        emit FiatCredited(tokenData.pipeFiatStash, _date);
    }

    /// @notice The function allows RWA manger to decrease pipe fiat balances against the MoH token
    /// @param _amount the amount by which RWA manager is decreasing the pipeFiatStash of the MoH token
    /// @param _date RWA manager is debiting pipe fiat for this date

    function debitPipeFiat(uint64 _amount, uint32 _date)
        external
        onlyCronManager
    {
        tokenData.pipeFiatStash -= _amount;
        emit FiatDebited(tokenData.pipeFiatStash, _date);
    }

    /// @notice Provides the NAV of the MoH token
    /// @return tokenData.nav NAV of the MoH token

    function getNAV() public view returns (uint64) {
        return tokenData.nav;
    }

    /// @notice The function allows the RWA manager to update the NAV. NAV = (Asset value of AFI _ pipe fiat stash in Fiat +
    /// stablecoin balance) / Total supply of the MoH token.
    /// @dev getTotalAssetValue gets value of all RWA units held by this MoH token plus stablecoin balances
    /// held by this MoH token. tokenData.pipeFiatStash gets the Fiat balances against this MoH token
    /// @param _timestamp Timestamp for which NAV is calculated

    function updateNav(uint32 _timestamp) external onlyCronManager {
        require(
            _timestamp >= tokenData.navUpdateTimestamp &&
                (uint32(block.timestamp) > _timestamp),
            "IT"
        );
        uint256 totalSupply = MoToken(token).totalSupply();
        require(totalSupply > 0, "ECT1");
        uint256 totalValue = uint128(getTotalAssetValue()); // 4 decimals shifted

        uint32 navCalculated = uint32(
            (totalValue * tokenDecimals) / totalSupply
        ); //nav should be 4 decimals shifted

        if (
            navCalculated >
            ((tokenData.nav * (100 + tokenData.navDeviationAllowance)) / 100) ||
            navCalculated <
            ((tokenData.nav * (100 - tokenData.navDeviationAllowance)) / 100)
        ) {
            tokenData.navUnapproved = navCalculated;
            tokenData.navApprovalRequestTimestamp = _timestamp;
            emit NAVApprovalRequest(tokenData.navUnapproved, _timestamp);
        } else {
            tokenData.nav = navCalculated;
            tokenData.navUnapproved = 0;
            accrueFee(_timestamp, totalValue);
            tokenData.navUpdateTimestamp = _timestamp;
            emit NAVUpdated(tokenData.nav, _timestamp);
        }
    }

    /// @notice If the change in NAV is more than navDeviationAllowance, it has to be approved by Admin

    function approveNav() external onlyRWAManager {
        require(tokenData.navUnapproved > 0, "NA");

        MoToken moToken = MoToken(token);

        tokenData.nav = tokenData.navUnapproved;
        tokenData.navUnapproved = 0;
        accrueFee(
            tokenData.navApprovalRequestTimestamp,
            tokenData.nav * moToken.totalSupply()
        );
        tokenData.navUpdateTimestamp = tokenData.navApprovalRequestTimestamp;
        emit NAVUpdated(tokenData.nav, tokenData.navUpdateTimestamp);
    }

    /// @notice Gets the summation of all the assets owned by the RWA fund that is associated with the MoToken in fiatCurrency
    /// @return totalRWAssetValue Value of all the assets associated with the MoToken

    function getTotalAssetValue()
        internal
        view
        returns (uint256 totalRWAssetValue)
    {
        RWADetails rWADetailsInstance = RWADetails(rWADetails);
        StableCoin sCoin = StableCoin(stableCoinAddress);

        totalRWAssetValue =
            rWADetailsInstance.getRWAValueByTokenId(
                tokenData.id,
                fiatCurrency
            ) +
            sCoin.totalBalanceInFiat(token, fiatCurrency) +
            tokenData.pipeFiatStash +
            tokenData.fiatInTransit -
            accruedPlatformFee; // 4 decimals shifted
    }

    /// @notice Transfers accrued fees to governor
    /// @param _amount amount in FiatCurrency
    /// @return bool Boolean indicating transfer success/failure

    function transferFeeToGovernor(uint256 _amount) internal returns (bool) {
        CurrencyOracle currencyOracle = CurrencyOracle(currencyOracleAddress);
        (uint64 stableToFiatConvRate, uint8 decimalsVal) = currencyOracle
            .getFeedLatestPriceAndDecimals(platformFeeCurrency, fiatCurrency);

        StableCoin sCoin = StableCoin(stableCoinAddress);
        uint8 finalDecVal = decimalsVal +
            sCoin.decimals(platformFeeCurrency) -
            MO_DECIMALS;
        uint256 amount = ((_amount * (10**finalDecVal)) / stableToFiatConvRate);

        MoToken moToken = MoToken(token);
        return (
            moToken.transferStableCoins(
                sCoin.contractAddressOf(platformFeeCurrency),
                owner(),
                amount
            )
        );
    }

    /// @notice Sets the RWA unit ID corresponding to the junior RWA Unit ID
    /// @param _unitId Senior RWA Unit ID

    function setLinkedSrRwaUnitId(uint256 _unitId) external onlyRWAManager {
        linkedSrRwaUnitId = _unitId;
    }

    /// @notice Sets fiat in transit amount
    /// @param _fiatAmount fiat amount (4 decimal shifted)

    function updateFiatInTransit(uint64 _fiatAmount) external onlyCronManager {
        tokenData.fiatInTransit = _fiatAmount;
    }

    /// @notice pays dividend to all the Mo Token holders, amount is total dividend amount for the current total token supply
    /// @param _amount stable coin amount (stable coin decimal shifted)

    function payoutDividend(uint256 _amount) external onlyRWAManager {
        StableCoin sCoin = StableCoin(stableCoinAddress);
        require((sCoin.balanceOf(platformFeeCurrency, token)) >= _amount);

        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );

        MoToken moToken = MoToken(token);

        uint256 dividendAmount = (_amount * (10**8)) / moToken.totalSupply();

        for (
            uint256 i = 0;
            i < acm.getRoleMemberCount(acm.WHITELIST_ROLE());
            ++i
        ) {
            address account = acm.getRoleMember(acm.WHITELIST_ROLE(), i);
            uint256 moBalance = moToken.balanceOf(account);
            if (moBalance > 0) {
                uint256 dividendToPay = (moBalance * dividendAmount) / (10**8);
                require(
                    moToken.transferStableCoins(
                        sCoin.contractAddressOf(platformFeeCurrency),
                        account,
                        dividendToPay
                    )
                );

                emit dividend(account, dividendToPay, moBalance);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "./interfaces/IERC20Basic.sol";
import "./access/AccessControlManager.sol";

/// @title The ERC20 token contract
/** @dev This contract is an extension of ERC20PresetMinterPauser which has implementations of ERC20, Burnable, Pausable,
 *  Access Control and Context.
 *  In addition to serve as the ERC20 implementation this also serves as a vault which will hold
 *  1. stablecoins transferred from the users during token purchase and
 *  2. tokens themselves which are transferred from the users while requesting for redemption
 *  3. restrict transfers to only whitelisted addresses
 */

contract MoToken is ERC20PresetMinterPauser {
    /// @dev Address of contract which manages whitelisted addresses
    address public accessControlManagerAddress;
    address public seniorTokenAddress;
    address public juniorTokenAddress;
    bool public isTradable;

    bytes32 public constant UNDERWRITER_ROLE = keccak256("UNDERWRITER_ROLE");

    event AccessControlManagerSet(address indexed accessControlAddress);
    event TradabilitySet(bool indexed tradable);
    event SeniorTokenLinked(address indexed token);
    event JuniorTokenLinked(address indexed token);

    /// @notice Constructor which only serves as passthrough for _tokenName and _tokenSymbol

    constructor(string memory _tokenName, string memory _tokenSymbol)
        ERC20PresetMinterPauser(_tokenName, _tokenSymbol)
    {
        isTradable = true;
    }

    /// @notice Returns if the address is an underwriter
    /// @param _account The address being checked
    /// @return bool Underwriter check success/failure

    function isUnderwriter(address _account) public view returns (bool) {
        return hasRole(UNDERWRITER_ROLE, _account);
    }

    /// @notice Overrides decimals() function to restrict decimals to 4
    /// @return uint8 returns number of decimals for display

    function decimals() public pure override returns (uint8) {
        return 4;
    }

    /// @notice Burns tokens from the given address
    /// @param _tokens The amount of tokens to burn
    /// @param _address The address which holds the tokens

    function burn(uint256 _tokens, address _address) external {
        require(hasRole(MINTER_ROLE, msg.sender), "NM");
        require(balanceOf(_address) >= _tokens, "NT");
        _burn(_address, _tokens);
    }

    /// @notice Transfers MoTokens from self to an external address
    /// @param _address External address to transfer tokens to
    /// @param _tokens The amount of tokens to transfer
    /// @return bool Boolean indicating whether the transfer was success/failure

    function transferTokens(address _address, uint256 _tokens)
        external
        returns (bool)
    {
        require(hasRole(MINTER_ROLE, msg.sender), "NM");
        IERC20Basic ier = IERC20Basic(address(this));
        return (ier.transfer(_address, _tokens));
    }

    /// @notice Transfers stablecoins from self to an external address
    /// @param _contractAddress Stablecoin contract address on chain
    /// @param _address External address to transfer stablecoins to
    /// @param _amount The amount of stablecoins to transfer
    /// @return bool Boolean indicating whether the transfer was success/failure

    function transferStableCoins(
        address _contractAddress,
        address _address,
        uint256 _amount
    ) external returns (bool) {
        require(hasRole(MINTER_ROLE, msg.sender), "NM");
        IERC20Basic ier = IERC20Basic(_contractAddress);
        return (ier.transfer(_address, _amount));
    }

    /// @notice Transfers MoTokens from an external address to self
    /// @param _address External address to transfer tokens from
    /// @param _tokens The amount of tokens to transfer
    /// @return bool Boolean indicating whether the transfer was success/failure

    function receiveTokens(address _address, uint256 _tokens)
        external
        returns (bool)
    {
        IERC20Basic ier = IERC20Basic(address(this));
        return (ier.transferFrom(_address, address(this), _tokens));
    }

    /// @notice Transfers stablecoins from an external address to self
    /// @param _contractAddress Stablecoin contract address on chain
    /// @param _address External address to transfer stablecoins from
    /// @param _amount The amount of stablecoins to transfer
    /// @return bool Boolean indicating whether the transfer was success/failure

    function receiveStableCoins(
        address _contractAddress,
        address _address,
        uint256 _amount
    ) external returns (bool) {
        IERC20Basic ier = IERC20Basic(_contractAddress);
        return (ier.transferFrom(_address, address(this), _amount));
    }

    /// @notice Checks if the given address is whitelisted
    /// @param _account External address to check

    function _onlywhitelisted(address _account) internal view {
        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );
        require(acm.isWhiteListed(_account), "NW");
    }

    /// @notice Hook that is called before any transfer of tokens
    /// @param from Extermal address from which tokens are transferred
    /// @param to External address to which tokesn are transferred
    /// @param amount Amount of tokens to be transferred

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (to == address(0) || to == address(this)) return;
        _onlywhitelisted(to);

        if (seniorTokenAddress != address(0)) {
            // Token is tradable and recipient is an underwriter
            require(isUnderwriter(to), "NU");
            if (from == address(0)) return;
            require(isTradable, "TNT");

            // Juniormost token is not tradable among underwriters
            if (juniorTokenAddress == address(0)) {
                require((from == address(this) || to == address(this)), "NA");
            }
        }
    }

    /// @notice Setter for isTradable
    /// @param tradable tradability set to true/false

    function setTradability(bool tradable) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NO");
        require(juniorTokenAddress != address(0), "NA");
        isTradable = tradable;
        emit TradabilitySet(tradable);
    }

    /// @notice Link to a Senior token
    /// @param seniorToken Token address

    function linkToSeniorToken(address seniorToken) external {
        require(hasRole(MINTER_ROLE, msg.sender), "NM");
        require(seniorTokenAddress == address(0), "NA");
        seniorTokenAddress = seniorToken;
        isTradable = false;
        emit SeniorTokenLinked(seniorToken);
    }

    /// @notice Link to a Junior token
    /// @param juniorToken Token address

    function linkToJuniorToken(address juniorToken) external {
        require(hasRole(MINTER_ROLE, msg.sender), "NM");
        juniorTokenAddress = juniorToken;
        emit JuniorTokenLinked(juniorToken);
    }

    /// @notice Setter for accessControlManagerAddress
    /// @param _address Set accessControlManagerAddress to this address

    function setAccessControlManagerAddress(address _address) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NO");
        accessControlManagerAddress = _address;
        emit AccessControlManagerSet(_address);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/presets/ERC20PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../extensions/ERC20Burnable.sol";
import "../extensions/ERC20Pausable.sol";
import "../../../access/AccessControlEnumerable.sol";
import "../../../utils/Context.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract ERC20PresetMinterPauser is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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