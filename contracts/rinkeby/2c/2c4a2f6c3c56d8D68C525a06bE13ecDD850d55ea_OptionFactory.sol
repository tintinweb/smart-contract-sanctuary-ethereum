pragma solidity =0.8.4;


import {AddressBookInterface} from "../interfaces/AddressBookInterface.sol";
import {WhitelistInterface} from "../interfaces/WhitelistInterface.sol";

/**
 * SPDX-License-Identifier: UNLICENSED
 * @title A factory to create Opyn oTokens
 * @author Milk Team 
 * @notice Create new oTokens and keep track of all created tokens
 * @dev Calculate contract address before each creation with CREATE2
 * and deploy eip-1167 minimal proxies for oToken logic contract
 */
contract OptionFactory {
    // using SafeMath for uint256;
    /// @notice Opyn AddressBook contract that records the address of the Whitelist module and the Otoken impl address. */
    address public addressBook;

    /// @notice array of all created otokens */
    bytes32[] public options;


    mapping(bytes32 => Option) public idToOption;
    /// @dev max expiry that BokkyPooBahsDateTimeLibrary can handle. (2345/12/31)
    uint256 private constant MAX_EXPIRY = 11865398400;

    struct Option{
        address underlying;
        address strikeAsset;
        address collateral;
        uint256 strikePrice;
        uint256 expiry;
        bool isPut;
    }

    constructor(address _addressBook){
        addressBook = _addressBook;
    }

    /// @notice emitted when the factory creates a new Option
    event OptionCreated(
        bytes32 optionId,
        address creator,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    );

    /**
     * @notice create new option
     * @dev deploy an eip-1167 minimal proxy with CREATE2 and register it to the whitelist module
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAsset asset that is held as collateral against short/written options
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return newOtoken address of the newly created option
     */

    function createOption(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external returns (bytes32) {
        require(_expiry > block.timestamp, "OptionFactory: Can't create expired option");
        require(_expiry < MAX_EXPIRY, "OptionFactory: Can't create option with expiry > 2345/12/31");
        // 8 hours = 3600 * 8 = 28800 seconds
        // require(_expiry.sub(28800).mod(86400) == 0, "OptionFactory: Option has to expire 08:00 UTC");
        bytes32 id = getOptionId(_underlyingAsset, _strikeAsset, _collateralAsset, _strikePrice, _expiry, _isPut);
        require(idToOption[id].collateral == address(0), "OptionFactory: Option already created");
    
        Option memory option = Option(_underlyingAsset, _strikeAsset, _collateralAsset, _strikePrice, _expiry, _isPut);
        

        address whitelist = AddressBookInterface(addressBook).getWhitelist();
        require(
            WhitelistInterface(whitelist).isWhitelistedProduct(
                _underlyingAsset,
                _strikeAsset,
                _collateralAsset,
                _isPut
            ),
            "OptionFactory: Unsupported Product"
        );

        require(!_isPut || _strikePrice > 0, "OptionFactory: Can't create a $0 strike put option");

    
        idToOption[id] = option;
        options.push(id);

        WhitelistInterface(whitelist).whitelistOption(id);

        emit OptionCreated(
            id,
            msg.sender,
            _underlyingAsset,
            _strikeAsset,
            _collateralAsset,
            _strikePrice,
            _expiry,
            _isPut
        );

        return id;
    }

    /**
     * @notice get the total oTokens created by the factory
     * @return length of the oTokens array
     */
    function getOptionsLength() external view returns (uint256) {
        return options.length;
    }

  

    /**
     * @dev hash oToken parameters and return a unique option id
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAsset asset that is held as collateral against short/written options
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return id the unique id of an oToken
     */
    function getOptionId(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_underlyingAsset, _strikeAsset, _collateralAsset, _strikePrice, _expiry, _isPut)
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

interface AddressBookInterface {
    /* Getters */


    function getOptionFactory() external view returns (address);

    function getWhitelist() external view returns (address);

    function getController() external view returns (address);

    function getOracle() external view returns (address);

    function getMarginPool() external view returns (address);

    function getMarginCalculator() external view returns (address);

    function getLiquidationManager() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);
    
    function getExchange() external view returns (address);

    function getAssetManagement() external view returns (address);

    function getOptionSettlement() external view returns (address);
    

    /* Setters */


    function setOptionFactory(address _factory) external;

    function setOracleImpl(address _otokenImpl) external;

    function setWhitelist(address _whitelist) external;

    function setController(address _controller) external;

    function setMarginPool(address _marginPool) external;

    function setMarginCalculator(address _calculator) external;

    function setLiquidationManager(address _liquidationManager) external;

    function setAddress(bytes32 _id, address _newImpl) external;

    function setExchange(address _exchange) external;
    
    function setAssetManagement(address _assetManagement) external;

    function setOptionSettlement(address _optionSettlement) external;
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

interface WhitelistInterface {
    /* View functions */

    function addressBook() external view returns (address);

    function isWhitelistedProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external view returns (bool);

    function isWhitelistedCollateral(address _collateral) external view returns (bool);

    function isWhitelistedOption(address _option) external view returns (bool);

    function isWhitelistedCallee(address _callee) external view returns (bool);

    /* Admin / factory only functions */
    function whitelistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external;

    function blacklistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external;

    function whitelistCollateral(address _collateral) external;

    function blacklistCollateral(address _collateral) external;

    function whitelistOption(bytes32 _option) external;

    function blacklistOption(bytes32 _option) external;

    function whitelistCallee(address _callee) external;

    function blacklistCallee(address _callee) external;
}