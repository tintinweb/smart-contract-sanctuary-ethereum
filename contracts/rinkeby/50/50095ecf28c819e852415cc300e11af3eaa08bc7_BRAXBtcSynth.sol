// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// ======================================================================
// |     ____  ____  ___   _  __    _______                             | 
// |    / __ )/ __ \/   | | |/ /   / ____(____  ____ _____  ________    | 
// |   / __  / /_/ / /| | |   /   / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / /_/ / _, _/ ___ |/   |   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_____/_/ |_/_/  |_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                    |
// ======================================================================
// ======================= BraxStableBTC (BRAX) =========================
// ======================================================================
// Brax Finance: https://github.com/BraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian
// Andrew Mitchell: https://github.com/mitche50

// Reviewer(s) / Contributor(s)
// Sam Sun: https://github.com/samczsun

import "../Common/Context.sol";
import "../ERC20/IERC20.sol";
import "../ERC20/ERC20Custom.sol";
import "../ERC20/ERC20.sol";
import "../Math/SafeMath.sol";
import "../Staking/Owned.sol";
import "../BXS/BXS.sol";
import "./Pools/BraxPoolV3.sol";
import "../Oracle/UniswapPairOracle.sol";
import "../Oracle/ChainlinkPriceConsumer.sol";
import "../Governance/AccessControl.sol";

contract BRAXBtcSynth is ERC20Custom, AccessControl, Owned {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    enum PriceChoice { BRAX, BXS }
    ChainlinkPriceConsumer private wbtcBtcPricer = ChainlinkPriceConsumer(0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23);
    uint8 private wbtcBtcPricerDecimals;
    UniswapPairOracle private braxWBtcOracle;
    UniswapPairOracle private bxsWBtcOracle;
    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    address public creatorAddress;
    address public timelockAddress; // Governance timelock address
    address public controllerAddress; // Controller contract to dynamically adjust system parameters automatically
    address public bxsAddress;
    address public braxWbtcOracleAddress;
    address public bxsWbtcOracleAddress;
    address public wbtcAddress;
    address public wbtcBtcConsumerAddress;
    uint256 public constant genesisSupply = 50e18; // 50 BRAX. This is to help with establishing the Uniswap pools, as they need liquidity

    // The addresses in this array are added by the oracle and these contracts are able to mint brax
    address[] public braxPoolsArray;

    // Mapping is also used for faster verification
    mapping(address => bool) public braxPools; 

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e8;
    
    uint256 public globalCollateralRatio; // 8 decimals of precision, e.g. 92410242 = 0.92410242
    uint256 public redemptionFee; // 8 decimals of precision, divide by 100000000 in calculations for fee
    uint256 public mintingFee; // 8 decimals of precision, divide by 100000000 in calculations for fee
    uint256 public braxStep; // Amount to change the collateralization ratio by upon refreshCollateralRatio()
    uint256 public refreshCooldown; // Seconds to wait before being able to run refreshCollateralRatio() again
    uint256 public priceTarget; // The price of BRAX at which the collateral ratio will respond to; this value is only used for the collateral ratio mechanism and not for minting and redeeming which are hardcoded at 1 BTC
    uint256 public priceBand; // The bound above and below the price target at which the refreshCollateralRatio() will not change the collateral ratio
    uint256 public MAX_COLLATERAL_RATIO = 1e8;

    address public DEFAULT_ADMIN_ADDRESS;
    bytes32 public constant COLLATERAL_RATIO_PAUSER = keccak256("COLLATERAL_RATIO_PAUSER");
    bool public collateralRatioPaused = false;

    // EIP2612 ERC20Permit implementation
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    mapping(address => uint) public nonces;
    bytes32 public DOMAIN_SEPARATOR;

    /* ========== MODIFIERS ========== */
    modifier onlyCollateralRatioPauser() {
        require(hasRole(COLLATERAL_RATIO_PAUSER, msg.sender), "!pauser");
        _;
    }
    modifier onlyPools() {
       require(braxPools[msg.sender] == true, "Only brax pools can call this function");
        _;
    } 
    modifier onlyByOwnerGovernanceOrController() {
        require(msg.sender == owner || msg.sender == timelockAddress || msg.sender == controllerAddress, "Not the owner, controller, or the governance timelock");
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    constructor (
        string memory _name,
        string memory _symbol,
        address _creatorAddress,
        address _timelockAddress
    ) Owned(_creatorAddress){
        require(_timelockAddress != address(0), "Zero address detected"); 
        name = _name;
        symbol = _symbol;
        if(_creatorAddress != address(0)) {
            creatorAddress = _creatorAddress;
        } else {
            creatorAddress = _msgSender();
        }
        
        timelockAddress = _timelockAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        DEFAULT_ADMIN_ADDRESS = _msgSender();
        _mint(creatorAddress, genesisSupply);
        grantRole(COLLATERAL_RATIO_PAUSER, creatorAddress);
        grantRole(COLLATERAL_RATIO_PAUSER, timelockAddress);
        braxStep = 250000; // 8 decimals of precision, equal to 0.25%
        globalCollateralRatio = 1e8; // brax system starts off fully collateralized (8 decimals of precision)
        refreshCooldown = 3600; // Refresh cooldown period is set to 1 hour (3600 seconds) at genesis
        priceTarget = 1e8; // Collateral ratio will adjust according to the 1 BTC price target at genesis (e8)
        priceBand = 500000; // Collateral ratio will not adjust if between 0.995 BTC and 1.005 BTC at genesis (e8)

        uint chainId;
        assembly {
            chainId := chainid()
        }
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes('1'));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                typeHash,
                hashedName,
                hashedVersion,
                chainId,
                address(this)
            )
        );
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Retrieves oracle price for the provided PriceChoice enum
     * @param choice Token to return pricing information for
     * @return price X tokens required for 1 BTC
     */
    function oraclePrice(PriceChoice choice) internal view returns (uint256 price) {
        uint256 priceVsWbtc = 0;
        uint256 pricerDecimals = 0;

        if (choice == PriceChoice.BRAX) {
            priceVsWbtc = uint256(braxWBtcOracle.consult(wbtcAddress, PRICE_PRECISION)); // How much BRAX if you put in PRICE_PRECISION WBTC
            pricerDecimals = braxWBtcOracle.decimals();
        }
        else if (choice == PriceChoice.BXS) {
            priceVsWbtc = uint256(bxsWBtcOracle.consult(wbtcAddress, PRICE_PRECISION)); // How much BXS if you put in PRICE_PRECISION WBTC
            pricerDecimals = bxsWBtcOracle.decimals();
        }
        else revert("INVALID PRICE CHOICE. Needs to be either BRAX or BXS");

        return uint256(wbtcBtcPricer.getLatestPrice()).mul(uint256(10) ** pricerDecimals).div(priceVsWbtc);
    }

    /// @return price X BRAX = 1 BTC
    function braxPrice() public view returns (uint256 price) {
        return oraclePrice(PriceChoice.BRAX);
    }

    /// @return price X BXS = 1 BTC
    function bxsPrice()  public view returns (uint256 price) {
        return oraclePrice(PriceChoice.BXS);
    }

    /**
     * @notice Return all info regarding BRAX
     * @dev This is needed to avoid costly repeat calls to different getter functions
     * @dev It is cheaper gas-wise to just dump everything and only use some of the info
     * @return priceOfBrax   Oracle price of BRAX
     * @return priceOfBxs    Oracle price of BXS
     * @return supply        Total supply of BRAX
     * @return gcr           Current global collateral ratio of BRAX
     * @return gcv           Current free value in the BRAX system
     * @return mintFee       Fee to mint BRAX
     * @return redeemFee     Fee to redeem BRAX
     */
    function braxInfo() public view returns (uint256 priceOfBrax, uint256 priceOfBxs, uint256 supply, uint256 gcr, uint256 gcv, uint256 mintFee, uint256 redeemFee) {
        return (
            oraclePrice(PriceChoice.BRAX), // braxPrice()
            oraclePrice(PriceChoice.BXS), // bxsPrice()
            totalSupply(), // totalSupply()
            globalCollateralRatio, // globalCollateralRatio()
            globalCollateralValue(), // globalCollateralValue
            mintingFee, // mintingFee()
            redemptionFee // redemptionFee()
        );
    }

    /**
     * @notice Iterate through all brax pools and calculate all value of collateral in all pools globally denominated in BTC
     * @return balance Balance of all pools denominated in BTC (e18)
     */
    function globalCollateralValue() public view returns (uint256 balance) {
        uint256 totalCollateralValueD18 = 0; 

        for (uint i = 0; i < braxPoolsArray.length; i++){ 
            // Exclude null addresses
            if (braxPoolsArray[i] != address(0)){
                totalCollateralValueD18 = totalCollateralValueD18.add(BraxPoolV3(braxPoolsArray[i]).collatBtcBalance());
            }
        }
        return totalCollateralValueD18;
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    
    /// @notice Last time the refreshCollateralRatio function was called
    uint256 public lastCallTime; 

    /**
     * @notice Update the collateral ratio based on the current price of BRAX
     * @dev lastCallTime limits updates to once per hour to prevent multiple calls per expansion
     */
    function refreshCollateralRatio() public {
        require(collateralRatioPaused == false, "Collateral Ratio has been paused");
        require(block.timestamp - lastCallTime >= refreshCooldown, "Must wait for the refresh cooldown since last refresh");
        uint256 braxPriceCur = braxPrice();

        // Step increments are 0.25% (upon genesis, changable by setBraxStep()) 
        if (braxPriceCur > priceTarget.add(priceBand)) { //decrease collateral ratio
            if(globalCollateralRatio <= braxStep){ //if within a step of 0, go to 0
                globalCollateralRatio = 0;
            } else {
                globalCollateralRatio = globalCollateralRatio.sub(braxStep);
            }
        } else if (braxPriceCur < priceTarget.sub(priceBand)) { //increase collateral ratio
            if(globalCollateralRatio.add(braxStep) >= MAX_COLLATERAL_RATIO){
                globalCollateralRatio = MAX_COLLATERAL_RATIO; // cap collateral ratio at 1.00000000
            } else {
                globalCollateralRatio = globalCollateralRatio.add(braxStep);
            }
        }

        lastCallTime = block.timestamp; // Set the time of the last expansion

        emit CollateralRatioRefreshed(globalCollateralRatio);
    }

    /**
     * @notice Nonces for permit
     * @param owner Token owner's address (Authorizer)
     * @return nonce next nonce
     */
    function permitNonces(address owner) external view returns (uint256 nonce) {
        return nonces[owner];
    }

    /**
     * @notice Verify a signed approval permit and execute if valid
     * @param owner     Token owner's address (Authorizer)
     * @param spender   Spender's address
     * @param value     Amount of allowance
     * @param deadline  The time at which this expires (unix time)
     * @param v         v of the signature
     * @param r         r of the signature
     * @param s         s of the signature
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "BRAX: permit is expired");

        bytes memory data = abi.encode(
            PERMIT_TYPEHASH,
            owner,
            spender,
            value,
            nonces[owner],
            deadline
        );
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(data)
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'BRAX: INVALID_SIGNATURE');

        _approve(owner, spender, value);
        nonces[owner] += 1;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // Potential improvement - create Burn Pool and send BRAX there which can be burnt by governance in batches
    // rather than opening up a burnFrom function which may be more dangerous.
    /**
     * @notice Burn BRAX as a step for releasing collateral
     * @param bAddress address of user to burn from
     * @param bAmount amount of tokens to burn
    */
    function poolBurnFrom(address bAddress, uint256 bAmount) public onlyPools {
        super._burnFrom(bAddress, bAmount);
        emit BRAXBurned(bAddress, msg.sender, bAmount);
    }

    /**
     * @notice Mint BRAX via pools after depositing collateral
     * @param mAddress address of user to mint to
     * @param mAmount amount of tokens to mint
    */
    function poolMint(address mAddress, uint256 mAmount) public onlyPools {
        super._mint(mAddress, mAmount);
        emit BRAXMinted(msg.sender, mAddress, mAmount);
    }

    /**
     * @notice Add a new pool to be used for collateral, such as wBTC and renBTC, must be ERC20 
     * @param poolAddress address of pool to add
    */
    function addPool(address poolAddress) public onlyByOwnerGovernanceOrController {
        require(poolAddress != address(0), "Zero address detected");

        require(braxPools[poolAddress] == false, "Address already exists");
        braxPools[poolAddress] = true; 
        braxPoolsArray.push(poolAddress);

        emit PoolAdded(poolAddress);
    }

    /**
     * @notice Remove a pool, leaving a 0x0 address in the index to retain the order of the other pools
     * @param poolAddress address of pool to remove
    */
    function removePool(address poolAddress) public onlyByOwnerGovernanceOrController {
        require(poolAddress != address(0), "Zero address detected");
        require(braxPools[poolAddress] == true, "Address nonexistant");
        
        // Delete from the mapping
        delete braxPools[poolAddress];

        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < braxPoolsArray.length; i++){ 
            if (braxPoolsArray[i] == poolAddress) {
                braxPoolsArray[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        emit PoolRemoved(poolAddress);
    }

    /**
     * @notice Set fee for redemption of BRAX to collateral
     * @param redFee fee in 8 decimal precision (e.g. 100000000 = 1% redemption fee)
    */
    function setRedemptionFee(uint256 redFee) public onlyByOwnerGovernanceOrController {
        redemptionFee = redFee;

        emit RedemptionFeeSet(redFee);
    }

    /**
     * @notice Set fee for minting BRAX from collateral
     * @param minFee fee in 8 decimal precision (e.g. 100000000 = 1% minting fee)
    */
    function setMintingFee(uint256 minFee) public onlyByOwnerGovernanceOrController {
        mintingFee = minFee;

        emit MintingFeeSet(minFee);
    }  

    /**
     * @notice Set the step that the collateral rate can be changed by
     * @param _newStep step in 8 decimal precision (e.g. 250000 = 0.25%)
    */
    function setBraxStep(uint256 _newStep) public onlyByOwnerGovernanceOrController {
        braxStep = _newStep;

        emit BraxStepSet(_newStep);
    }  

    /**
     * @notice Set the price target BRAX is aiming to stay at
     * @param _newPriceTarget price for BRAX to target in 8 decimals precision (e.g. 10000000 = 1 BTC)
    */
    function setPriceTarget(uint256 _newPriceTarget) public onlyByOwnerGovernanceOrController {
        priceTarget = _newPriceTarget;

        emit PriceTargetSet(_newPriceTarget);
    }

    /**
     * @notice Set the rate at which the collateral rate can be updated
     * @param _newCooldown cooldown length in seconds (e.g. 3600 = 1 hour)
    */
    function setRefreshCooldown(uint256 _newCooldown) public onlyByOwnerGovernanceOrController {
    	refreshCooldown = _newCooldown;

        emit RefreshCooldownSet(_newCooldown);
    }

    /**
     * @notice Set the address for BXS
     * @param _bxsAddress new address for BXS
    */
    function setBXSAddress(address _bxsAddress) public onlyByOwnerGovernanceOrController {
        require(_bxsAddress != address(0), "Zero address detected");

        bxsAddress = _bxsAddress;

        emit BXSAddressSet(_bxsAddress);
    }

    /**
     * @notice Set the wBTC / BTC Oracle
     * @param _wbtcBtcConsumerAddress new address for the oracle
    */
    function setWBTCBTCOracle(address _wbtcBtcConsumerAddress) public onlyByOwnerGovernanceOrController {
        require(_wbtcBtcConsumerAddress != address(0), "Zero address detected");

        wbtcBtcConsumerAddress = _wbtcBtcConsumerAddress;
        wbtcBtcPricer = ChainlinkPriceConsumer(wbtcBtcConsumerAddress);
        wbtcBtcPricerDecimals = wbtcBtcPricer.getDecimals();

        emit WBTCBTCOracleSet(_wbtcBtcConsumerAddress);
    }

    /**
     * @notice Set the governance timelock address
     * @param newTimelock new address for the timelock
    */
    function setTimelock(address newTimelock) external onlyByOwnerGovernanceOrController {
        require(newTimelock != address(0), "Zero address detected");

        timelockAddress = newTimelock;

        emit TimelockSet(newTimelock);
    }

    /**
     * @notice Set the controller address
     * @param _controllerAddress new address for the controller
    */
    function setController(address _controllerAddress) external onlyByOwnerGovernanceOrController {
        require(_controllerAddress != address(0), "Zero address detected");

        controllerAddress = _controllerAddress;

        emit ControllerSet(_controllerAddress);
    }

    /**
     * @notice Set the tolerance away from the target price in which the collateral rate cannot be updated
     * @param _priceBand new tolerance with 8 decimals precision (e.g. 500000 will not adjust if between 0.995 BTC and 1.005 BTC)
    */
    function setPriceBand(uint256 _priceBand) external onlyByOwnerGovernanceOrController {
        priceBand = _priceBand;

        emit PriceBandSet(_priceBand);
    }

    /**
     * @notice Set the BRAX / wBTC Oracle
     * @param _braxOracleAddr new address for the oracle
     * @param _wbtcAddress wBTC address for chain
    */
    function setBRAXWBtcOracle(address _braxOracleAddr, address _wbtcAddress) public onlyByOwnerGovernanceOrController {
        require((_braxOracleAddr != address(0)) && (_wbtcAddress != address(0)), "Zero address detected");
        braxWbtcOracleAddress = _braxOracleAddr;
        braxWBtcOracle = UniswapPairOracle(_braxOracleAddr); 
        wbtcAddress = _wbtcAddress;

        emit BRAXWBTCOracleSet(_braxOracleAddr, _wbtcAddress);
    }

    /**
     * @notice Set the BXS / wBTC Oracle
     * @param _bxsOracleAddr new address for the oracle
     * @param _wbtcAddress wBTC address for chain
    */
    function setBXSWBtcOracle(address _bxsOracleAddr, address _wbtcAddress) public onlyByOwnerGovernanceOrController {
        require((_bxsOracleAddr != address(0)) && (_wbtcAddress != address(0)), "Zero address detected");

        bxsWbtcOracleAddress = _bxsOracleAddr;
        bxsWBtcOracle = UniswapPairOracle(_bxsOracleAddr);
        wbtcAddress = _wbtcAddress;

        emit BXSWBTCOracleSet(_bxsOracleAddr, _wbtcAddress);
    }

    /// @notice Toggle if the Collateral Ratio should be able to be updated
    function toggleCollateralRatio() public onlyCollateralRatioPauser {
        collateralRatioPaused = !collateralRatioPaused;

        emit CollateralRatioToggled(collateralRatioPaused);
    }

    /* ========== EVENTS ========== */
    event BRAXBurned(address indexed from, address indexed to, uint256 amount);
    event BRAXMinted(address indexed from, address indexed to, uint256 amount);
    event CollateralRatioRefreshed(uint256 globalCollateralRatio);
    event PoolAdded(address poolAddress);
    event PoolRemoved(address poolAddress);
    event RedemptionFeeSet(uint256 redFee);
    event MintingFeeSet(uint256 minFee);
    event BraxStepSet(uint256 newStep);
    event PriceTargetSet(uint256 newPriceTarget);
    event RefreshCooldownSet(uint256 newCooldown);
    event BXSAddressSet(address _bxsAddress);
    event TimelockSet(address newTimelock);
    event ControllerSet(address controllerAddress);
    event PriceBandSet(uint256 priceBand);
    event WBTCBTCOracleSet(address wbtcOracleAddr);
    event BRAXWBTCOracleSet(address braxOracleAddr, address wbtcAddress);
    event BXSWBTCOracleSet(address bxsOracleAddr, address wbtcAddress);
    event CollateralRatioToggled(bool collateralRatioPaused);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import "../Common/Context.sol";
import "../Math/SafeMath.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
pragma solidity >=0.6.11;

import "../Common/Context.sol";
import "./IERC20.sol";
import "../Math/SafeMath.sol";
import "../Utils/Address.sol";

// Due to compiling issues, _name, _symbol, and _decimals were removed


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20Custom is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.approve(address spender, uint256 amount)
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

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
     * - the caller must have allowance for `accounts`'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }


    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import "../Common/Context.sol";
import "./IERC20.sol";
import "../Math/SafeMath.sol";
import "../Utils/Address.sol";


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
 
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory __name, string memory __symbol) public {
        _name = __name;
        _symbol = __symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.approve(address spender, uint256 amount)
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

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
     * - the caller must have allowance for `accounts`'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }


    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// https://docs.synthetix.io/contracts/Owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor (address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// ======================================================================
// |     ____  ____  ___   _  __    _______                             | 
// |    / __ )/ __ \/   | | |/ /   / ____(____  ____ _____  ________    | 
// |   / __  / /_/ / /| | |   /   / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / /_/ / _, _/ ___ |/   |   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_____/_/ |_/_/  |_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                    |
// ======================================================================
// ========================= BRAXShares (BXS) ===========================
// ======================================================================
// Brax Finance: https://github.com/BraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian
// Andrew Mitchell: https://github.com/mitche50

// Reviewer(s) / Contributor(s)
// Sam Sun: https://github.com/samczsun

import "../Common/Context.sol";
import "../ERC20/ERC20Custom.sol";
import "../ERC20/IERC20.sol";
import "../Brax/Brax.sol";
import "../Staking/Owned.sol";
import "../Math/SafeMath.sol";
import "../Governance/AccessControl.sol";

contract BRAXShares is ERC20Custom, AccessControl, Owned {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    
    uint256 public constant genesisSupply = 100000000e18; // 100M is printed upon genesis
    uint256 public BXS_DAO_MIN; // Minimum BXS required to join DAO groups 

    address public ownerAddress;
    address public oracleAddress;
    address public timelockAddress; // Governance timelock address
    BRAXBtcSynth private BRAX;

    bool public trackingVotes = true; // Tracking votes (only change if need to disable votes)

    // A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    // A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    // The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /* ========== MODIFIERS ========== */

    modifier onlyPools() {
       require(BRAX.braxPools(msg.sender) == true, "Only brax pools can mint new BXS");
        _;
    } 
    
    modifier onlyByOwnGov() {
        require(msg.sender == owner || msg.sender == timelockAddress, "Only owner or governance timelock");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor (
        string memory newName,
        string memory newSymbol, 
        address newOracleAddress,
        address newCreatorAddress,
        address newTimelockAddress
    ) Owned(newCreatorAddress){
        require((newOracleAddress != address(0)) && (newTimelockAddress != address(0)), "Zero address detected"); 
        name = newName;
        symbol = newSymbol;
        oracleAddress = newOracleAddress;
        timelockAddress = newTimelockAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _mint(newCreatorAddress, genesisSupply);

        // Do a checkpoint for the owner
        _writeCheckpoint(newCreatorAddress, 0, 0, uint96(genesisSupply));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Sets the oracle address for BXS
     * @param newOracle Address of the new BXS oracle
     */
    function setOracle(address newOracle) external onlyByOwnGov {
        require(newOracle != address(0), "Zero address detected");

        oracleAddress = newOracle;
    }

    /**
     * @notice Set a new timelock address
     * @param newTimelock Address of the new timelock
     */
    function setTimelock(address newTimelock) external onlyByOwnGov {
        require(newTimelock != address(0), "Timelock address cannot be 0");

        timelockAddress = newTimelock;
    }

    /**
     * @notice Set the address of BRAX
     * @param braxContractAddress Address of BRAX
     */
    function setBRAXAddress(address braxContractAddress) external onlyByOwnGov {
        require(braxContractAddress != address(0), "Zero address detected");

        BRAX = BRAXBtcSynth(braxContractAddress);

        emit BRAXAddressSet(braxContractAddress);
    }

    /// @notice Toggles tracking votes
    function toggleVotes() external onlyByOwnGov {
        trackingVotes = !trackingVotes;
    }

    /**
     * @notice Set the minimum amount of BXS required to join DAO
     * @param minBXS amount of BXS required to join DAO
     */
    function setBXSMinDAO(uint256 minBXS) external onlyByOwnGov {
        BXS_DAO_MIN = minBXS;
    }
    
    /**
     * @notice Mint new BXS
     * @param to Address to mint to
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) public onlyPools {
        _mint(to, amount);
    }
    
    /**
     * @notice Mint new BXS via pool
     * @param mAddress Address to mint to
     * @param mAmount Amount to mint
     */
    function poolMint(address mAddress, uint256 mAmount) external onlyPools {
        if(trackingVotes){
            uint32 srcRepNum = numCheckpoints[address(this)];
            uint96 srcRepOld = srcRepNum > 0 ? checkpoints[address(this)][srcRepNum - 1].votes : 0;
            uint96 srcRepNew = add96(srcRepOld, uint96(mAmount), "poolMint new votes overflows");
            _writeCheckpoint(address(this), srcRepNum, srcRepOld, srcRepNew); // mint new votes
            trackVotes(address(this), mAddress, uint96(mAmount));
        }

        super._mint(mAddress, mAmount);
        emit BXSMinted(address(this), mAddress, mAmount);
    }

    /**
     * @notice Burn BXS via pool
     * @param bAddress Address to burn from
     * @param bAmount Amount to burn
     */
    function poolBurnFrom(address bAddress, uint256 bAmount) external onlyPools {
        if(trackingVotes){
            trackVotes(bAddress, address(this), uint96(bAmount));
            uint32 srcRepNum = numCheckpoints[address(this)];
            uint96 srcRepOld = srcRepNum > 0 ? checkpoints[address(this)][srcRepNum - 1].votes : 0;
            uint96 srcRepNew = sub96(srcRepOld, uint96(bAmount), "poolBurnFrom new votes underflows");
            _writeCheckpoint(address(this), srcRepNum, srcRepOld, srcRepNew); // burn votes
        }

        super._burnFrom(bAddress, bAmount);
        emit BXSBurned(bAddress, address(this), bAmount);
    }

    /* ========== OVERRIDDEN PUBLIC FUNCTIONS ========== */

    /// @dev Overwritten to track votes
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if(trackingVotes){
            // Transfer votes
            trackVotes(_msgSender(), recipient, uint96(amount));
        }

        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /// @dev Overwritten to track votes
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        if(trackingVotes){
            // Transfer votes
            trackVotes(sender, recipient, uint96(amount));
        }

        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));

        return true;
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "BXS::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /// @dev From compound's _moveDelegates
    /// @dev Keep track of votes. "Delegates" is a misnomer here
    function trackVotes(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "BXS::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "BXS::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address voter, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "BXS::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[voter][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[voter][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[voter][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[voter] = nCheckpoints + 1;
      }

      emit VoterVotesChanged(voter, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /* ========== EVENTS ========== */
    
    /// @notice An event thats emitted when a voters account's vote balance changes
    event VoterVotesChanged(address indexed voter, uint previousBalance, uint newBalance);

    // Track BXS burned
    event BXSBurned(address indexed from, address indexed to, uint256 amount);

    // Track BXS minted
    event BXSMinted(address indexed from, address indexed to, uint256 amount);

    event BRAXAddressSet(address addr);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;


                                                                

// ======================================================================
// |     ____  ____  ___   _  __    _______                             | 
// |    / __ )/ __ \/   | | |/ /   / ____(____  ____ _____  ________    | 
// |   / __  / /_/ / /| | |   /   / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / /_/ / _, _/ ___ |/   |   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_____/_/ |_/_/  |_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                    |
// ======================================================================
// ============================ BraxPoolV3 ==============================
// ======================================================================
// Allows multiple btc sythns (fixed amount at initialization) as collateral
// wBTC, ibBTC and renBTC to start
// For this pool, the goal is to accept decentralized assets as collateral to limit
// government / regulatory risk (e.g. wBTC blacklisting until holders KYC)

// Brax Finance: https://github.com/BraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian
// Dennis: github.com/denett
// Hameed
// Andrew Mitchell: https://github.com/mitche50

import "../../Math/SafeMath.sol";
import '../../Uniswap/TransferHelper.sol';
import "../../Staking/Owned.sol";
import "../../BXS/IBxs.sol";
import "../../Brax/IBrax.sol";
import "../../Oracle/AggregatorV3Interface.sol";
import "../../Brax/IBraxAMOMinter.sol";
import "../../ERC20/ERC20.sol";

contract BraxPoolV3 is Owned {
    using SafeMath for uint256;
    // SafeMath automatically included in Solidity >= 8.0.0

    /* ========== STATE VARIABLES ========== */

    // Core
    address public timelockAddress;
    address public custodianAddress; // Custodian is an EOA (or msig) with pausing privileges only, in case of an emergency

    IBrax private BRAX;
    IBxs private BXS;

    mapping(address => bool) public amoMinterAddresses; // minter address -> is it enabled
    // TODO: Get aggregator
    // IMPORTANT - set to random chainlink contract for testing
    AggregatorV3Interface public priceFeedBRAXBTC = AggregatorV3Interface(0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23);
    // TODO: Get aggregator
    // IMPORTANT - set to random chainlink contract for testing
    AggregatorV3Interface public priceFeedBXSBTC = AggregatorV3Interface(0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23);
    uint256 private chainlinkBraxBtcDecimals;
    uint256 private chainlinkBxsBtcDecimals;

    // Collateral
    address[] public collateralAddresses;
    string[] public collateralSymbols;
    uint256[] public missingDecimals; // Number of decimals needed to get to E18. collateral index -> missingDecimals
    uint256[] public poolCeilings; // Total across all collaterals. Accounts for missingDecimals
    uint256[] public collateralPrices; // Stores price of the collateral, if price is paused.  Currently hardcoded at 1:1 BTC. CONSIDER ORACLES EVENTUALLY!!!
    mapping(address => uint256) public collateralAddrToIdx; // collateral addr -> collateral index
    mapping(address => bool) public enabledCollaterals; // collateral address -> is it enabled
    
    // Redeem related
    mapping (address => uint256) public redeemBXSBalances;
    mapping (address => mapping(uint256 => uint256)) public redeemCollateralBalances; // Address -> collateral index -> balance
    uint256[] public unclaimedPoolCollateral; // collateral index -> balance
    uint256 public unclaimedPoolBXS;
    mapping (address => uint256) public lastRedeemed; // Collateral independent
    uint256 public redemptionDelay = 2; // Number of blocks to wait before being able to collectRedemption()
    uint256 public redeemPriceThreshold = 99000000; // 0.99 BTC
    uint256 public mintPriceThreshold = 101000000; // 1.01 BTC
    
    // Buyback related
    mapping(uint256 => uint256) public bbkHourlyCum; // Epoch hour ->  Collat out in that hour (E18)
    uint256 public bbkMaxColE18OutPerHour = 1e18;

    // Recollat related
    mapping(uint256 => uint256) public rctHourlyCum; // Epoch hour ->  BXS out in that hour
    uint256 public rctMaxBxsOutPerHour = 1000e18;

    // Fees and rates
    // getters are in collateralInformation()
    uint256[] private mintingFee;
    uint256[] private redemptionFee;
    uint256[] private buybackFee;
    uint256[] private recollatFee;
    uint256 public bonusRate; // Bonus rate on BXS minted during recollateralize(); 6 decimals of precision, set to 0.75% on genesis
    
    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e8;

    // Pause variables
    // getters are in collateralInformation()
    bool[] private mintPaused; // Collateral-specific
    bool[] private redeemPaused; // Collateral-specific
    bool[] private recollateralizePaused; // Collateral-specific
    bool[] private buyBackPaused; // Collateral-specific
    bool[] private borrowingPaused; // Collateral-specific

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnGov() {
        require(msg.sender == timelockAddress || msg.sender == owner, "Not owner or timelock");
        _;
    }

    modifier onlyByOwnGovCust() {
        require(msg.sender == timelockAddress || msg.sender == owner || msg.sender == custodianAddress, "Not owner, tlck, or custd");
        _;
    }

    modifier onlyAMOMinters() {
        require(amoMinterAddresses[msg.sender], "Not an AMO Minter");
        _;
    }

    modifier collateralEnabled(uint256 colIdx) {
        require(enabledCollaterals[collateralAddresses[colIdx]], "Collateral disabled");
        _;
    }

    modifier validCollateral(uint256 colIdx) {
        require(collateralAddresses[colIdx] != address(0), "Invalid collateral");
        _;
    }
 
    /* ========== CONSTRUCTOR ========== */
    
    constructor (
        address poolManagerAddress,
        address newCustodianAddress,
        address newTimelockAddress,
        address[] memory newCollateralAddresses,
        uint256[] memory newPoolCeilings,
        uint256[] memory initialFees,
        address braxAddress,
        address bxsAddress
    ) Owned(poolManagerAddress){
        // Core
        timelockAddress = newTimelockAddress;
        custodianAddress = newCustodianAddress;

        // BRAX and BXS
        BRAX = IBrax(braxAddress);
        BXS = IBxs(bxsAddress);

        // Fill collateral info
        collateralAddresses = newCollateralAddresses;
        for (uint256 i = 0; i < newCollateralAddresses.length; i++){ 
            // For fast collateral address -> collateral idx lookups later
            collateralAddrToIdx[newCollateralAddresses[i]] = i;

            // Set all of the collaterals initially to disabled
            enabledCollaterals[newCollateralAddresses[i]] = false;

            // Add in the missing decimals
            missingDecimals.push(uint256(18).sub(ERC20(newCollateralAddresses[i]).decimals()));

            // Add in the collateral symbols
            collateralSymbols.push(ERC20(newCollateralAddresses[i]).symbol());

            // Initialize unclaimed pool collateral
            unclaimedPoolCollateral.push(0);

            // Initialize paused prices to 1 BTC as a backup
            collateralPrices.push(PRICE_PRECISION);

            // Handle the fees
            mintingFee.push(initialFees[0]);
            redemptionFee.push(initialFees[1]);
            buybackFee.push(initialFees[2]);
            recollatFee.push(initialFees[3]);

            // Handle the pauses
            mintPaused.push(false);
            redeemPaused.push(false);
            recollateralizePaused.push(false);
            buyBackPaused.push(false);
            borrowingPaused.push(false);
        }

        // Pool ceiling
        poolCeilings = newPoolCeilings;

        // Set the decimals
        chainlinkBraxBtcDecimals = priceFeedBRAXBTC.decimals();
        chainlinkBxsBtcDecimals = priceFeedBXSBTC.decimals();
    }

    /* ========== STRUCTS ========== */
    
    struct CollateralInformation {
        uint256 index;
        string symbol;
        address colAddr;
        bool isEnabled;
        uint256 missingDecs;
        uint256 price;
        uint256 poolCeiling;
        bool mintPaused;
        bool redeemPaused;
        bool recollatPaused;
        bool buybackPaused;
        bool borrowingPaused;
        uint256 mintingFee;
        uint256 redemptionFee;
        uint256 buybackFee;
        uint256 recollatFee;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Compute the threshold for buyback and recollateralization to throttle
     * @notice both in times of high volatility
     * @dev helper function to help limit volatility in calculations
     * @param cur Current amount already consumed in the current hour
     * @param max Maximum allowable in the current hour
     * @param theo Amount to theoretically distribute, used to check against available amounts
     * @return amount Amount allowable to distribute
     */
    function comboCalcBbkRct(uint256 cur, uint256 max, uint256 theo) internal pure returns (uint256 amount) {
        if (cur >= max) {
            // If the hourly limit has already been reached, return 0;
            return 0;
        }
        else {
            // Get the available amount
            uint256 available = max.sub(cur);

            if (theo >= available) {
                // If the the theoretical is more than the available, return the available
                return available;
            }
            else {
                // Otherwise, return the theoretical amount
                return theo;
            }
        }
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Return the collateral information for a provided address
     * @param collatAddress address of a type of collateral, e.g. wBTC or renBTC
     * @return returnData struct containing all data regarding the provided collateral address
     */
    function collateralInformation(address collatAddress) external view returns (CollateralInformation memory returnData){
        require(enabledCollaterals[collatAddress], "Invalid collateral");

        // Get the index
        uint256 idx = collateralAddrToIdx[collatAddress];
        
        returnData = CollateralInformation(
            idx, // [0]
            collateralSymbols[idx], // [1]
            collatAddress, // [2]
            enabledCollaterals[collatAddress], // [3]
            missingDecimals[idx], // [4]
            collateralPrices[idx], // [5]
            poolCeilings[idx], // [6]
            mintPaused[idx], // [7]
            redeemPaused[idx], // [8]
            recollateralizePaused[idx], // [9]
            buyBackPaused[idx], // [10]
            borrowingPaused[idx], // [11]
            mintingFee[idx], // [12]
            redemptionFee[idx], // [13]
            buybackFee[idx], // [14]
            recollatFee[idx] // [15]
        );
    }

    /**
     * @notice Returns a list of all collateral addresses
     * @return addresses list of all collateral addresses
     */
    function allCollaterals() external view returns (address[] memory addresses) {
        return collateralAddresses;
    }

    /**
     * @notice Return current price from chainlink feed for BRAX
     * @return braxPrice Current price of BRAX chainlink feed
     */
    function getBRAXPrice() public view returns (uint256 braxPrice) {
        (uint80 roundID, int price, , uint256 updatedAt, uint80 answeredInRound) = priceFeedBRAXBTC.latestRoundData();
        require(price >= 0 && updatedAt!= 0 && answeredInRound >= roundID, "Invalid chainlink price");

        return uint256(price).mul(PRICE_PRECISION).div(10 ** chainlinkBraxBtcDecimals);
    }

    /**
     * @notice Return current price from chainlink feed for BXS
     * @return bxsPrice Current price of BXS chainlink feed
     */
    function getBXSPrice() public view returns (uint256 bxsPrice) {
        (uint80 roundID, int price, , uint256 updatedAt, uint80 answeredInRound) = priceFeedBXSBTC.latestRoundData();
        require(price >= 0 && updatedAt!= 0 && answeredInRound >= roundID, "Invalid chainlink price");

        return uint256(price).mul(PRICE_PRECISION).div(10 ** chainlinkBxsBtcDecimals);
    }

    /**
     * @notice Return price of BRAX in the provided collateral token
     * @dev Note: pricing is returned in collateral precision.  For example,
     * @dev getting price for wBTC would be in 8 decimals
     * @param colIdx index of collateral token (e.g. 0 for wBTC, 1 for renBTC)
     * @param braxAmount amount of BRAX to get the equivalent price for
     * @return braxPrice price of BRAX in collateral (decimals are equivalent to collateral, not BRAX)
     */
    function getBRAXInCollateral(uint256 colIdx, uint256 braxAmount) public view returns (uint256 braxPrice) {
        require(collateralPrices[colIdx] > 0, "Price missing from collateral");

        return braxAmount.mul(PRICE_PRECISION).div(10 ** missingDecimals[colIdx]).div(collateralPrices[colIdx]);
    }

    /**
     * @notice Return amount of collateral balance not waiting to be redeemed
     * @param colIdx index of collateral token (e.g. 0 for wBTC, 1 for renBTC)
     * @return collatAmount amount of collateral not waiting to be redeemed (E18)
     */
    function freeCollatBalance(uint256 colIdx) public view validCollateral(colIdx) returns (uint256 collatAmount) {
        return ERC20(collateralAddresses[colIdx]).balanceOf(address(this)).sub(unclaimedPoolCollateral[colIdx]);
    }

    /**
     * @notice Returns BTC value of collateral held in this Brax pool, in E18
     * @return balanceTally total BTC value in pool (E18)
     */
    function collatBtcBalance() external view returns (uint256 balanceTally) {
        balanceTally = 0;

        for (uint256 i = 0; i < collateralAddresses.length; i++){
            // It's possible collateral has been removed, so skip any address(0) collateral
            if(collateralAddresses[i] == address(0)) {
                continue;
            }
            balanceTally += freeCollatBalance(i).mul(10 ** missingDecimals[i]).mul(collateralPrices[i]).div(PRICE_PRECISION);
        }
    }

    /**
     * @notice Returns the value of excess collateral (E18) held globally, compared to what is needed to maintain the global collateral ratio
     * @dev comboCalcBbkRct() is used to throttle buybacks to avoid dumps during periods of large volatility
     * @return total excess collateral in the system (E18)
     */
    function buybackAvailableCollat() public view returns (uint256) {
        uint256 totalSupply = BRAX.totalSupply();
        uint256 globalCollateralRatio = BRAX.globalCollateralRatio();
        uint256 globalCollatValue = BRAX.globalCollateralValue();

        if (globalCollateralRatio > PRICE_PRECISION) globalCollateralRatio = PRICE_PRECISION; // Handles an overcollateralized contract with CR > 1
        uint256 requiredCollatBTCValueD18 = (totalSupply.mul(globalCollateralRatio)).div(PRICE_PRECISION); // Calculates collateral needed to back each 1 BRAX with 1 BTC of collateral at current collat ratio
        
        if (globalCollatValue > requiredCollatBTCValueD18) {
            // Get the theoretical buyback amount
            uint256 theoreticalBbkAmt = globalCollatValue.sub(requiredCollatBTCValueD18);

            // See how much has collateral has been issued this hour
            uint256 currentHrBbk = bbkHourlyCum[curEpochHr()];

            // Account for the throttling
            return comboCalcBbkRct(currentHrBbk, bbkMaxColE18OutPerHour, theoreticalBbkAmt);
        }
        else return 0;
    }

    /**
     * @notice Returns the missing amount of collateral (in E18) needed to maintain the collateral ratio
     * @return balanceTally total BTC missing to maintain collateral ratio
     */
    function recollatTheoColAvailableE18() public view returns (uint256 balanceTally) {
        uint256 braxTotalSupply = BRAX.totalSupply();
        uint256 effectiveCollateralRatio = BRAX.globalCollateralValue().mul(PRICE_PRECISION).div(braxTotalSupply); // Returns it in 1e8
        
        uint256 desiredCollatE24 = (BRAX.globalCollateralRatio()).mul(braxTotalSupply);
        uint256 effectiveCollatE24 = effectiveCollateralRatio.mul(braxTotalSupply);

        // Return 0 if already overcollateralized
        // Otherwise, return the deficiency
        if (effectiveCollatE24 >= desiredCollatE24) return 0;
        else {
            return (desiredCollatE24.sub(effectiveCollatE24)).div(PRICE_PRECISION);
        }
    }

    /**
     * @notice Returns the value of BXS available to be used for recollats
     * @dev utilizes comboCalcBbkRct to throttle for periods of high volatility
     * @return total value of BXS available for recollateralization
     */
    function recollatAvailableBxs() public view returns (uint256) {
        uint256 bxsPrice = getBXSPrice();

        // Get the amount of collateral theoretically available
        uint256 recollatTheoAvailableE18 = recollatTheoColAvailableE18();

        // Return 0 if already overcollateralized
        if (recollatTheoAvailableE18 <= 0) return 0;

        // Get the amount of BXS theoretically outputtable
        uint256 bxsTheoOut = recollatTheoAvailableE18.mul(PRICE_PRECISION).div(bxsPrice);

        // See how much BXS has been issued this hour
        uint256 currentHrRct = rctHourlyCum[curEpochHr()];

        // Account for the throttling
        return comboCalcBbkRct(currentHrRct, rctMaxBxsOutPerHour, bxsTheoOut);
    }

    /// @return hour current epoch hour
    function curEpochHr() public view returns (uint256) {
        return (block.timestamp / 3600); // Truncation desired
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    /**
     * @notice Mint BRAX via collateral / BXS combination
     * @param colIdx integer value of the collateral index
     * @param braxAmt Amount of BRAX to mint
     * @param braxOutMin Minimum amount of BRAX to accept
     * @param maxCollatIn Maximum amount of collateral to use for minting
     * @param maxBxsIn Maximum amount of BXS to use for minting
     * @param oneToOneOverride Boolean flag to indicate using 1:1 BRAX:Collateral for 
     *   minting, ignoring current global collateral ratio of BRAX
     * @return totalBraxMint Amount of BRAX minted
     * @return collatNeeded Amount of collateral used
     * @return bxsNeeded Amount of BXS used
     */
     function mintBrax(
        uint256 colIdx, 
        uint256 braxAmt,
        uint256 braxOutMin,
        uint256 maxCollatIn,
        uint256 maxBxsIn,
        bool oneToOneOverride
    ) external collateralEnabled(colIdx) returns (
        uint256 totalBraxMint, 
        uint256 collatNeeded, 
        uint256 bxsNeeded
    ) {
        require(mintPaused[colIdx] == false, "Minting is paused");

        // Prevent unneccessary mints
        require(getBRAXPrice() >= mintPriceThreshold, "Brax price too low");

        uint256 globalCollateralRatio = BRAX.globalCollateralRatio();

        if (oneToOneOverride || globalCollateralRatio >= PRICE_PRECISION) { 
            // 1-to-1, overcollateralized, or user selects override
            collatNeeded = getBRAXInCollateral(colIdx, braxAmt);
            bxsNeeded = 0;
        } else if (globalCollateralRatio == 0) { 
            // Algorithmic
            collatNeeded = 0;
            bxsNeeded = braxAmt.mul(PRICE_PRECISION).div(getBXSPrice());
        } else { 
            // Fractional
            uint256 braxForCollat = braxAmt.mul(globalCollateralRatio).div(PRICE_PRECISION);
            uint256 braxForBxs = braxAmt.sub(braxForCollat);
            collatNeeded = getBRAXInCollateral(colIdx, braxForCollat);
            bxsNeeded = braxForBxs.mul(PRICE_PRECISION).div(getBXSPrice());
        }

        // Subtract the minting fee
        totalBraxMint = (braxAmt.mul(PRICE_PRECISION.sub(mintingFee[colIdx]))).div(PRICE_PRECISION);

        // Check slippages
        require((totalBraxMint >= braxOutMin), "BRAX slippage");
        require((collatNeeded <= maxCollatIn), "Collat slippage");
        require((bxsNeeded <= maxBxsIn), "BXS slippage");

        // Check the pool ceiling
        require(freeCollatBalance(colIdx).add(collatNeeded) <= poolCeilings[colIdx], "Pool ceiling");

        if(bxsNeeded > 0) {
            // Take the BXS and collateral first
            BXS.poolBurnFrom(msg.sender, bxsNeeded);
        }
        TransferHelper.safeTransferFrom(collateralAddresses[colIdx], msg.sender, address(this), collatNeeded);

        // Mint the BRAX
        BRAX.poolMint(msg.sender, totalBraxMint);
    }

    /**
     * @notice Redeem BRAX for BXS / Collateral combination
     * @param colIdx integer value of the collateral index
     * @param braxAmount Amount of BRAX to redeem
     * @param bxsOutMin Minimum amount of BXS to redeem for
     * @param colOutMin Minimum amount of collateral to redeem for
     * @return collatOut Amount of collateral redeemed
     * @return bxsOut Amount of BXS redeemed
     */
    function redeemBrax(
        uint256 colIdx, 
        uint256 braxAmount, 
        uint256 bxsOutMin, 
        uint256 colOutMin
    ) external collateralEnabled(colIdx) returns (
        uint256 collatOut, 
        uint256 bxsOut
    ) {
        require(redeemPaused[colIdx] == false, "Redeeming is paused");

        // Prevent unnecessary redemptions that could adversely affect the BXS price
        require(getBRAXPrice() <= redeemPriceThreshold, "Brax price too high");

        uint256 globalCollateralRatio = BRAX.globalCollateralRatio();
        uint256 braxAfterFee = (braxAmount.mul(PRICE_PRECISION.sub(redemptionFee[colIdx]))).div(PRICE_PRECISION);

        // Assumes 1 BTC BRAX in all cases
        if(globalCollateralRatio >= PRICE_PRECISION) { 
            // 1-to-1 or overcollateralized
            collatOut = getBRAXInCollateral(colIdx, braxAfterFee);
            bxsOut = 0;
        } else if (globalCollateralRatio == 0) { 
            // Algorithmic
            bxsOut = braxAfterFee
                            .mul(PRICE_PRECISION)
                            .div(getBXSPrice());
            collatOut = 0;
        } else { 
            // Fractional
            collatOut = getBRAXInCollateral(colIdx, braxAfterFee)
                            .mul(globalCollateralRatio)
                            .div(PRICE_PRECISION);
            bxsOut = braxAfterFee
                            .mul(PRICE_PRECISION.sub(globalCollateralRatio))
                            .div(getBXSPrice()); // PRICE_PRECISIONS CANCEL OUT
        }

        // Checks
        require(collatOut <= (ERC20(collateralAddresses[colIdx])).balanceOf(address(this)).sub(unclaimedPoolCollateral[colIdx]), "Insufficient pool collateral");
        require(collatOut >= colOutMin, "Collateral slippage");
        require(bxsOut >= bxsOutMin, "BXS slippage");

        // Account for the redeem delay
        redeemCollateralBalances[msg.sender][colIdx] = redeemCollateralBalances[msg.sender][colIdx].add(collatOut);
        unclaimedPoolCollateral[colIdx] = unclaimedPoolCollateral[colIdx].add(collatOut);

        redeemBXSBalances[msg.sender] = redeemBXSBalances[msg.sender].add(bxsOut);
        unclaimedPoolBXS = unclaimedPoolBXS.add(bxsOut);

        lastRedeemed[msg.sender] = block.number;
        
        BRAX.poolBurnFrom(msg.sender, braxAmount);
        if (bxsOut > 0) {
            BXS.poolMint(address(this), bxsOut);
        }
    }


    /**
     * @notice Collect collateral and BXS from redemption pool
     * @dev Redemption is split into two functions to prevent flash loans removing 
     * @dev BXS/collateral from the system, use an AMM to trade new price and then mint back
     * @param colIdx integer value of the collateral index
     * @return bxsAmount Amount of BXS redeemed
     * @return collateralAmount Amount of collateral redeemed
     */ 
    function collectRedemption(uint256 colIdx) external returns (uint256 bxsAmount, uint256 collateralAmount) {
        require(redeemPaused[colIdx] == false, "Redeeming is paused");
        require((lastRedeemed[msg.sender].add(redemptionDelay)) <= block.number, "Too soon");
        bool sendBXS = false;
        bool sendCollateral = false;

        // Use Checks-Effects-Interactions pattern
        if(redeemBXSBalances[msg.sender] > 0){
            bxsAmount = redeemBXSBalances[msg.sender];
            redeemBXSBalances[msg.sender] = 0;
            unclaimedPoolBXS = unclaimedPoolBXS.sub(bxsAmount);
            sendBXS = true;
        }
        
        if(redeemCollateralBalances[msg.sender][colIdx] > 0){
            collateralAmount = redeemCollateralBalances[msg.sender][colIdx];
            redeemCollateralBalances[msg.sender][colIdx] = 0;
            unclaimedPoolCollateral[colIdx] = unclaimedPoolCollateral[colIdx].sub(collateralAmount);
            sendCollateral = true;
        }

        // Send out the tokens
        if(sendBXS){
            TransferHelper.safeTransfer(address(BXS), msg.sender, bxsAmount);
        }
        if(sendCollateral){
            TransferHelper.safeTransfer(collateralAddresses[colIdx], msg.sender, collateralAmount);
        }
    }

    /**
     * @notice Trigger buy back of BXS with excess collateral from a desired collateral pool
     * @notice when the current collateralization rate > global collateral ratio
     * @param colIdx Index of the collateral to buy back with
     * @param bxsAmount Amount of BXS to buy back
     * @param colOutMin Minimum amount of collateral to use to buyback
     * @return colOut Amount of collateral used to purchase BXS
     */
    function buyBackBxs(uint256 colIdx, uint256 bxsAmount, uint256 colOutMin) external collateralEnabled(colIdx) returns (uint256 colOut) {
        require(buyBackPaused[colIdx] == false, "Buyback is paused");
        uint256 bxsPrice = getBXSPrice();
        uint256 availableExcessCollatDv = buybackAvailableCollat();

        // If the total collateral value is higher than the amount required at the current collateral ratio then buy back up to the possible BXS with the desired collateral
        require(availableExcessCollatDv > 0, "No Collat Avail For BBK");

        // Make sure not to take more than is available
        uint256 bxsBTCValueD18 = bxsAmount.mul(bxsPrice).div(PRICE_PRECISION);
        require(bxsBTCValueD18 <= availableExcessCollatDv, "Insuf Collat Avail For BBK");

        // Get the equivalent amount of collateral based on the market value of BXS provided 
        uint256 collateralEquivalentD18 = bxsBTCValueD18.mul(PRICE_PRECISION).div(collateralPrices[colIdx]);
        colOut = collateralEquivalentD18.div(10 ** missingDecimals[colIdx]); // In its natural decimals()

        // Subtract the buyback fee
        colOut = (colOut.mul(PRICE_PRECISION.sub(buybackFee[colIdx]))).div(PRICE_PRECISION);

        // Check for slippage
        require(colOut >= colOutMin, "Collateral slippage");

        // Take in and burn the BXS, then send out the collateral
        BXS.poolBurnFrom(msg.sender, bxsAmount);
        TransferHelper.safeTransfer(collateralAddresses[colIdx], msg.sender, colOut);

        // Increment the outbound collateral, in E18, for that hour
        // Used for buyback throttling
        bbkHourlyCum[curEpochHr()] += collateralEquivalentD18;
    }

    /**
     * @notice Reward users who send collateral to a pool with the same amount of BXS + set bonus rate
     * @notice Anyone can call this function to recollateralize the pool and get extra BXS
     * @param colIdx Index of the collateral to recollateralize
     * @param collateralAmount Amount of collateral being deposited
     * @param bxsOutMin Minimum amount of BXS to accept
     * @return bxsOut Amount of BXS distributed
     */
    function recollateralize(uint256 colIdx, uint256 collateralAmount, uint256 bxsOutMin) external collateralEnabled(colIdx) returns (uint256 bxsOut) {
        require(recollateralizePaused[colIdx] == false, "Recollat is paused");
        uint256 collateralAmountD18 = collateralAmount * (10 ** missingDecimals[colIdx]);
        uint256 bxsPrice = getBXSPrice();

        // Get the amount of BXS actually available (accounts for throttling)
        uint256 bxsActuallyAvailable = recollatAvailableBxs();

        // Calculated the attempted amount of BXS
        bxsOut = collateralAmountD18.mul(PRICE_PRECISION.add(bonusRate).sub(recollatFee[colIdx])).div(bxsPrice);

        // Make sure there is BXS available
        require(bxsOut <= bxsActuallyAvailable, "Insuf BXS Avail For RCT");

        // Check slippage
        require(bxsOut >= bxsOutMin, "BXS slippage");

        // Don't take in more collateral than the pool ceiling for this token allows
        require(freeCollatBalance(colIdx).add(collateralAmount) <= poolCeilings[colIdx], "Pool ceiling");

        // Take in the collateral and pay out the BXS
        TransferHelper.safeTransferFrom(collateralAddresses[colIdx], msg.sender, address(this), collateralAmount);
        BXS.poolMint(msg.sender, bxsOut);

        // Increment the outbound BXS, in E18
        // Used for recollat throttling
        rctHourlyCum[curEpochHr()] += bxsOut;
    }

    /* ========== RESTRICTED FUNCTIONS, MINTER ONLY ========== */

    /**
     * @notice Allow AMO Minters to borrow without gas intensive mint->redeem cycle
     * @param collateralAmount Amount of collateral the AMO minter will borrow
     */
    function amoMinterBorrow(uint256 collateralAmount) external onlyAMOMinters {
        // Checks the colIdx of the minter as an additional safety check
        uint256 minterColIdx = IBraxAMOMinter(msg.sender).colIdx();

        // Checks to see if borrowing is paused
        require(borrowingPaused[minterColIdx] == false, "Borrowing is paused");

        // Ensure collateral is enabled
        require(enabledCollaterals[collateralAddresses[minterColIdx]], "Collateral disabled");

        // Transfer
        TransferHelper.safeTransfer(collateralAddresses[minterColIdx], msg.sender, collateralAmount);
    }

    /* ========== RESTRICTED FUNCTIONS, CUSTODIAN CAN CALL TOO ========== */

    /**
     * @notice Toggles the pause status for different functions within the pool
     * @param colIdx Collateral to toggle data for
     * @param togIdx Specific value to toggle
     * @dev togIdx, 0 = mint, 1 = redeem, 2 = buyback, 3 = recollateralize, 4 = borrowing
     */
    function toggleMRBR(uint256 colIdx, uint8 togIdx) external onlyByOwnGovCust {
        require(togIdx <= 4, "Invalid togIdx");
        require(colIdx < collateralAddresses.length, "Invalid collateral");

        if (togIdx == 0) mintPaused[colIdx] = !mintPaused[colIdx];
        else if (togIdx == 1) redeemPaused[colIdx] = !redeemPaused[colIdx];
        else if (togIdx == 2) buyBackPaused[colIdx] = !buyBackPaused[colIdx];
        else if (togIdx == 3) recollateralizePaused[colIdx] = !recollateralizePaused[colIdx];
        else if (togIdx == 4) borrowingPaused[colIdx] = !borrowingPaused[colIdx];

        emit MRBRToggled(colIdx, togIdx);
    }

    /* ========== RESTRICTED FUNCTIONS, GOVERNANCE ONLY ========== */

    /// @notice Add an AMO Minter Address
    /// @param amoMinterAddr Address of the new AMO minter
    function addAMOMinter(address amoMinterAddr) external onlyByOwnGov {
        require(amoMinterAddr != address(0), "Zero address detected");

        // Make sure the AMO Minter has collatBtcBalance()
        uint256 collatValE18 = IBraxAMOMinter(amoMinterAddr).collatBtcBalance();
        require(collatValE18 >= 0, "Invalid AMO");

        amoMinterAddresses[amoMinterAddr] = true;

        emit AMOMinterAdded(amoMinterAddr);
    }

    /// @notice Remove an AMO Minter Address
    /// @param amoMinterAddr Address of the AMO minter to remove
    function removeAMOMinter(address amoMinterAddr) external onlyByOwnGov {
        require(amoMinterAddresses[amoMinterAddr] == true, "Minter not active");

        amoMinterAddresses[amoMinterAddr] = false;
        
        emit AMOMinterRemoved(amoMinterAddr);
    }

    /** 
     * @notice Set the collateral price for a specific collateral
     * @param colIdx Index of the collateral
     * @param newPrice New price of the collateral
     */
    function setCollateralPrice(uint256 colIdx, uint256 newPrice) external onlyByOwnGov validCollateral(colIdx) {
        require(collateralPrices[colIdx] != newPrice, "Same pricing");

        // Only to be used for collateral without chainlink price feed
        // Immediate priorty to get a price feed in place
        collateralPrices[colIdx] = newPrice;

        emit CollateralPriceSet(colIdx, newPrice);
    }

    /**
     * @notice Toggles collateral for use in the pool
     * @param colIdx Index of the collateral to be enabled
     */
    function toggleCollateral(uint256 colIdx) external onlyByOwnGov validCollateral(colIdx) {
        address colAddress = collateralAddresses[colIdx];
        enabledCollaterals[colAddress] = !enabledCollaterals[colAddress];

        emit CollateralToggled(colIdx, enabledCollaterals[colAddress]);
    }

    /**
     * @notice Set the ceiling of collateral allowed for minting
     * @param colIdx Index of the collateral to be modified
     * @param newCeiling New ceiling amount of collateral
     */
    function setPoolCeiling(uint256 colIdx, uint256 newCeiling) external onlyByOwnGov validCollateral(colIdx) {
        require(poolCeilings[colIdx] != newCeiling, "Same ceiling");
        poolCeilings[colIdx] = newCeiling;

        emit PoolCeilingSet(colIdx, newCeiling);
    }

    /**
     * @notice Set the fees of collateral allowed for minting
     * @param colIdx Index of the collateral to be modified
     * @param newMintFee New mint fee for collateral
     * @param newRedeemFee New redemption fee for collateral
     * @param newBuybackFee New buyback fee for collateral
     * @param newRecollatFee New recollateralization fee for collateral
     */
    function setFees(uint256 colIdx, uint256 newMintFee, uint256 newRedeemFee, uint256 newBuybackFee, uint256 newRecollatFee) external onlyByOwnGov validCollateral(colIdx) {
        mintingFee[colIdx] = newMintFee;
        redemptionFee[colIdx] = newRedeemFee;
        buybackFee[colIdx] = newBuybackFee;
        recollatFee[colIdx] = newRecollatFee;

        emit FeesSet(colIdx, newMintFee, newRedeemFee, newBuybackFee, newRecollatFee);
    }

    /**
     * @notice Set the parameters of the pool
     * @param newBonusRate Index of the collateral to be modified
     * @param newRedemptionDelay Number of blocks to wait before being able to collectRedemption()
     */
    function setPoolParameters(uint256 newBonusRate, uint256 newRedemptionDelay) external onlyByOwnGov {
        bonusRate = newBonusRate;
        redemptionDelay = newRedemptionDelay;
        emit PoolParametersSet(newBonusRate, newRedemptionDelay);
    }

    /**
     * @notice Set the price thresholds of the pool, preventing minting or redeeming when trading would be more effective
     * @param newMintPriceThreshold Price at which minting is allowed
     * @param newRedeemPriceThreshold Price at which redemptions are allowed
     */
    function setPriceThresholds(uint256 newMintPriceThreshold, uint256 newRedeemPriceThreshold) external onlyByOwnGov {
        mintPriceThreshold = newMintPriceThreshold;
        redeemPriceThreshold = newRedeemPriceThreshold;
        emit PriceThresholdsSet(newMintPriceThreshold, newRedeemPriceThreshold);
    }

    /**
     * @notice Set the buyback and recollateralization maximum amounts for the pool
     * @param newBbkMaxColE18OutPerHour Maximum amount of collateral per hour to be used for buyback
     * @param newBrctMaxBxsOutPerHour Maximum amount of BXS per hour allowed to be given for recollateralization
     */
    function setBbkRctPerHour(uint256 newBbkMaxColE18OutPerHour, uint256 newBrctMaxBxsOutPerHour) external onlyByOwnGov {
        bbkMaxColE18OutPerHour = newBbkMaxColE18OutPerHour;
        rctMaxBxsOutPerHour = newBrctMaxBxsOutPerHour;
        emit BbkRctPerHourSet(newBbkMaxColE18OutPerHour, newBrctMaxBxsOutPerHour);
    }

    /**
     * @notice Set the chainlink oracles for the pool
     * @param braxBtcChainlinkAddr BRAX / BTC chainlink oracle
     * @param bxsBtcChainlinkAddr BXS / BTC chainlink oracle
     */
    function setOracles(address braxBtcChainlinkAddr, address bxsBtcChainlinkAddr) external onlyByOwnGov {
        // Set the instances
        priceFeedBRAXBTC = AggregatorV3Interface(braxBtcChainlinkAddr);
        priceFeedBXSBTC = AggregatorV3Interface(bxsBtcChainlinkAddr);

        // Set the decimals
        chainlinkBraxBtcDecimals = priceFeedBRAXBTC.decimals();
        require(chainlinkBraxBtcDecimals > 0, "Invalid BRAX Oracle");
        chainlinkBxsBtcDecimals = priceFeedBXSBTC.decimals();
        require(chainlinkBxsBtcDecimals > 0, "Invalid BXS Oracle");
        
        emit OraclesSet(braxBtcChainlinkAddr, bxsBtcChainlinkAddr);
    }

    /**
     * @notice Set the custodian address for the pool
     * @param newCustodian New custodian address
     */
    function setCustodian(address newCustodian) external onlyByOwnGov {
        require(newCustodian != address(0), "Custodian zero address");
        custodianAddress = newCustodian;

        emit CustodianSet(newCustodian);
    }

    /**
     * @notice Set the timelock address for the pool
     * @param newTimelock New timelock address
     */
    function setTimelock(address newTimelock) external onlyByOwnGov {
        require(newTimelock != address(0), "Timelock zero address");
        timelockAddress = newTimelock;

        emit TimelockSet(newTimelock);
    }

    /* ========== EVENTS ========== */
    event CollateralToggled(uint256 colIdx, bool newState);
    event PoolCeilingSet(uint256 colIdx, uint256 newCeiling);
    event FeesSet(uint256 colIdx, uint256 newMintFee, uint256 newRedeemFee, uint256 newBuybackFee, uint256 newRecollatFee);
    event PoolParametersSet(uint256 newBonusRate, uint256 newRedemptionDelay);
    event PriceThresholdsSet(uint256 newBonusRate, uint256 newRedemptionDelay);
    event BbkRctPerHourSet(uint256 bbkMaxColE18OutPerHour, uint256 rctMaxBxsOutPerHour);
    event AMOMinterAdded(address amoMinterAddr);
    event AMOMinterRemoved(address amoMinterAddr);
    event OraclesSet(address braxBtcChainlinkAddr, address bxsBtcChainlinkAddr);
    event CustodianSet(address newCustodian);
    event TimelockSet(address newTimelock);
    event MRBRToggled(uint256 colIdx, uint8 togIdx);
    event CollateralPriceSet(uint256 colIdx, uint256 newPrice);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import '../Uniswap/Interfaces/IUniswapV2Factory.sol';
import '../Uniswap/Interfaces/IUniswapV2Pair.sol';
import '../Math/FixedPoint.sol';

import '../Uniswap/UniswapV2OracleLibrary.sol';
import '../Uniswap/UniswapV2Library.sol';
import "../Staking/Owned.sol";

// Fixed window oracle that recomputes the average price for the entire period once every period
// Note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract UniswapPairOracle is Owned {
    using FixedPoint for *;
    
    address timelock_address;

    uint public PERIOD = 3600; // 1 hour TWAP (time-weighted average price)
    uint public CONSULT_LENIENCY = 120; // Used for being able to consult past the period end
    bool public ALLOW_STALE_CONSULTS = false; // If false, consult() will fail if the TWAP is stale

    IUniswapV2Pair public immutable pair;
    address public immutable token0;
    address public immutable token1;

    uint    public price0CumulativeLast;
    uint    public price1CumulativeLast;
    uint32  public blockTimestampLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    uint8 public decimals = 18;

    modifier onlyByOwnGov() {
        require(msg.sender == owner || msg.sender == timelock_address, "You are not an owner or the governance timelock");
        _;
    }

    constructor (
        address factory, 
        address tokenA, 
        address tokenB, 
        address _owner_address, 
        address _timelock_address
    ) public Owned(_owner_address) {
        IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, tokenA, tokenB));
        pair = _pair;
        token0 = _pair.token0();
        token1 = _pair.token1();
        price0CumulativeLast = _pair.price0CumulativeLast(); // Fetch the current accumulated price value (1 / 0)
        price1CumulativeLast = _pair.price1CumulativeLast(); // Fetch the current accumulated price value (0 / 1)
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, 'UniswapPairOracle: NO_RESERVES'); // Ensure that there's liquidity in the pair

        timelock_address = _timelock_address;
    }

    function setTimelock(address _timelock_address) external onlyByOwnGov {
        timelock_address = _timelock_address;
    }

    function setPeriod(uint _period) external onlyByOwnGov {
        PERIOD = _period;
    }

    function setConsultLeniency(uint _consult_leniency) external onlyByOwnGov {
        CONSULT_LENIENCY = _consult_leniency;
    }

    function setAllowStaleConsults(bool _allow_stale_consults) external onlyByOwnGov {
        ALLOW_STALE_CONSULTS = _allow_stale_consults;
    }

    // Check if update() can be called instead of wasting gas calling it
    function canUpdate() public view returns (bool) {
        uint32 blockTimestamp = UniswapV2OracleLibrary.currentBlockTimestamp();
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // Overflow is desired
        return (timeElapsed >= PERIOD);
    }

    function update() external {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // Overflow is desired

        // Ensure that at least one full period has passed since the last update
        require(timeElapsed >= PERIOD, 'UniswapPairOracle: PERIOD_NOT_ELAPSED');

        // Overflow is desired, casting never truncates
        // Cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
        price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
    }

    // Note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint amountIn) public view returns (uint amountOut) {
        uint32 blockTimestamp = UniswapV2OracleLibrary.currentBlockTimestamp();
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // Overflow is desired

        // Ensure that the price is not stale
        require((timeElapsed < (PERIOD + CONSULT_LENIENCY)) || ALLOW_STALE_CONSULTS, 'UniswapPairOracle: PRICE_IS_STALE_NEED_TO_CALL_UPDATE');

        if (token == token0) {
            amountOut = price0Average.mul(amountIn).decode144();
        } else {
            require(token == token1, 'UniswapPairOracle: INVALID_TOKEN');
            amountOut = price1Average.mul(amountIn).decode144();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import "./AggregatorV3Interface.sol";

contract ChainlinkPriceConsumer {

    AggregatorV3Interface internal priceFeed;

    constructor (address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /**
     * @return price The latest price
     */
    function getLatestPrice() public view returns (int) {
        (uint80 roundID, int price, , uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();
        require(price >= 0 && updatedAt!= 0 && answeredInRound >= roundID, "Invalid chainlink price");
        
        return price;
    }

    /**
     * @return decimals Decimals of the price feed  
     */
    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

import "../Utils/EnumerableSet.sol";
import "../Utils/Address.sol";
import "../Common/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00; //bytes32(uint256(0x4B437D01b575618140442A4975db38850e3f8f5f) << 96);

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
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
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.9.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity >=0.6.11;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IBxs {
  function DEFAULT_ADMIN_ROLE() external view returns(bytes32);
  function BRAXBtcSynthAdd() external view returns(address);
  function BXS_DAO_MIN() external view returns(uint256);
  function allowance(address owner, address spender) external view returns(uint256);
  function approve(address spender, uint256 amount) external returns(bool);
  function balanceOf(address account) external view returns(uint256);
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
  function checkpoints(address, uint32) external view returns(uint32 fromBlock, uint96 votes);
  function decimals() external view returns(uint8);
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns(bool);
  function genesisSupply() external view returns(uint256);
  function getCurrentVotes(address account) external view returns(uint96);
  function getPriorVotes(address account, uint256 blockNumber) external view returns(uint96);
  function getRoleAdmin(bytes32 role) external view returns(bytes32);
  function getRoleMember(bytes32 role, uint256 index) external view returns(address);
  function getRoleMemberCount(bytes32 role) external view returns(uint256);
  function grantRole(bytes32 role, address account) external;
  function hasRole(bytes32 role, address account) external view returns(bool);
  function increaseAllowance(address spender, uint256 addedValue) external returns(bool);
  function mint(address to, uint256 amount) external;
  function name() external view returns(string memory);
  function numCheckpoints(address) external view returns(uint32);
  function oracleAddress() external view returns(address);
  function ownerAddress() external view returns(address);
  function poolBurnFrom(address bAddress, uint256 bAmount) external;
  function poolMint(address mAddress, uint256 mAmount) external;
  function renounceRole(bytes32 role, address account) external;
  function revokeRole(bytes32 role, address account) external;
  function setBRAXAddress(address braxContractAddress) external;
  function setBXSMinDAO(uint256 minBXS) external;
  function setOracle(address newOracle) external;
  function setOwner(address _ownerAddress) external;
  function setTimelock(address newTimelock) external;
  function symbol() external view returns(string memory);
  function timelockAddress() external view returns(address);
  function toggleVotes() external;
  function totalSupply() external view returns(uint256);
  function trackingVotes() external view returns(bool);
  function transfer(address recipient, uint256 amount) external returns(bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IBrax {
  function COLLATERAL_RATIO_PAUSER() external view returns (bytes32);
  function DEFAULT_ADMIN_ADDRESS() external view returns (address);
  function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
  function addPool(address poolAddress ) external;
  function allowance(address owner, address spender ) external view returns (uint256);
  function approve(address spender, uint256 amount ) external returns (bool);
  function balanceOf(address account ) external view returns (uint256);
  function burn(uint256 amount ) external;
  function burnFrom(address account, uint256 amount ) external;
  function collateralRatioPaused() external view returns (bool);
  function controllerAddress() external view returns (address);
  function creatorAddress() external view returns (address);
  function decimals() external view returns (uint8);
  function decreaseAllowance(address spender, uint256 subtractedValue ) external returns (bool);
  function wbtcBtcConsumerAddress() external view returns (address);
  function braxWbtcOracleAddress() external view returns (address);
  function braxInfo() external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
  function braxPools(address ) external view returns (bool);
  function braxPoolsArray(uint256 ) external view returns (address);
  function braxPrice() external view returns (uint256);
  function braxStep() external view returns (uint256);
  function bxsAddress() external view returns (address);
  function bxsWbtcOracleAddress() external view returns (address);
  function bxsPrice() external view returns (uint256);
  function genesisSupply() external view returns (uint256);
  function getRoleAdmin(bytes32 role ) external view returns (bytes32);
  function getRoleMember(bytes32 role, uint256 index ) external view returns (address);
  function getRoleMemberCount(bytes32 role ) external view returns (uint256);
  function globalCollateralValue() external view returns (uint256);
  function globalCollateralRatio() external view returns (uint256);
  function grantRole(bytes32 role, address account ) external;
  function hasRole(bytes32 role, address account ) external view returns (bool);
  function increaseAllowance(address spender, uint256 addedValue ) external returns (bool);
  function lastCallTime() external view returns (uint256);
  function mintingFee() external view returns (uint256);
  function name() external view returns (string memory);
  function ownerAddress() external view returns (address);
  function poolBurnFrom(address bAddress, uint256 bAmount ) external;
  function poolMint(address mAddress, uint256 mAmount ) external;
  function priceBand() external view returns (uint256);
  function priceTarget() external view returns (uint256);
  function redemptionFee() external view returns (uint256);
  function refreshCollateralRatio() external;
  function refreshCooldown() external view returns (uint256);
  function removePool(address poolAddress ) external;
  function renounceRole(bytes32 role, address account ) external;
  function revokeRole(bytes32 role, address account ) external;
  function setController(address _controllerAddress ) external;
  function setWBTCBTCOracle(address _wbtcBtcConsumerAddress ) external;
  function setBRAXWBtcOracle(address _brax_oracle_addr, address _wbtcAddress ) external;
  function setBXSAddress(address _bxs_address ) external;
  function setBXSBtcOracle(address _bxsOracleAddr, address _wbtcAddress ) external;
  function setBraxStep(uint256 _newStep ) external;
  function setMintingFee(uint256 minFee ) external;
  function setOwner(address _ownerAddress ) external;
  function setPriceBand(uint256 _priceBand ) external;
  function setPriceTarget(uint256 _newPriceTarget ) external;
  function setRedemptionFee(uint256 redFee ) external;
  function setRefreshCooldown(uint256 _newCooldown ) external;
  function setTimelock(address newTimelock ) external;
  function symbol() external view returns (string memory);
  function timelock_address() external view returns (address);
  function toggleCollateralRatio() external;
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount ) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
  function wbtcAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// MAY need to be updated
interface IBraxAMOMinter {
  function BRAX() external view returns(address);
  function BXS() external view returns(address);
  function acceptOwnership() external;
  function addAMO(address amo_address, bool sync_too) external;
  function allAMOAddresses() external view returns(address[] memory);
  function allAMOsLength() external view returns(uint256);
  function amos(address) external view returns(bool);
  function amosArray(uint256) external view returns(address);
  function burnBraxFromAMO(uint256 brax_amount) external;
  function burnBxsFromAMO(uint256 bxs_amount) external;
  function colIdx() external view returns(uint256);
  function collatBtcBalance() external view returns(uint256);
  function collatBtcBalanceStored() external view returns(uint256);
  function collatBorrowCap() external view returns(int256);
  function collatBorrowedBalances(address) external view returns(int256);
  function collatBorrowedSum() external view returns(int256);
  function collateralAddress() external view returns(address);
  function collateralToken() external view returns(address);
  function correctionOffsetsAmos(address, uint256) external view returns(int256);
  function custodianAddress() external view returns(address);
  function btcBalances() external view returns(uint256 brax_val_e18, uint256 collat_val_e18);
  // function execute(address _to, uint256 _value, bytes _data) external returns(bool, bytes);
  function braxBtcBalanceStored() external view returns(uint256);
  function braxTrackedAMO(address amo_address) external view returns(int256);
  function braxTrackedGlobal() external view returns(int256);
  function braxMintBalances(address) external view returns(int256);
  function braxMintCap() external view returns(int256);
  function braxMintSum() external view returns(int256);
  function bxsMintBalances(address) external view returns(int256);
  function bxsMintCap() external view returns(int256);
  function bxsMintSum() external view returns(int256);
  function giveCollatToAMO(address destination_amo, uint256 collat_amount) external;
  function minCr() external view returns(uint256);
  function mintBraxForAMO(address destination_amo, uint256 brax_amount) external;
  function mintBxsForAMO(address destination_amo, uint256 bxs_amount) external;
  function missingDecimals() external view returns(uint256);
  function nominateNewOwner(address _owner) external;
  function nominatedOwner() external view returns(address);
  function oldPoolCollectAndGive(address destination_amo) external;
  function oldPoolRedeem(uint256 brax_amount) external;
  function oldPool() external view returns(address);
  function owner() external view returns(address);
  function pool() external view returns(address);
  function receiveCollatFromAMO(uint256 usdc_amount) external;
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
  function removeAMO(address amo_address, bool sync_too) external;
  function setAMOCorrectionOffsets(address amo_address, int256 brax_e18_correction, int256 collat_e18_correction) external;
  function setCollatBorrowCap(uint256 _collat_borrow_cap) external;
  function setCustodian(address _custodian_address) external;
  function setBraxMintCap(uint256 _brax_mint_cap) external;
  function setBraxPool(address _pool_address) external;
  function setBxsMintCap(uint256 _bxs_mint_cap) external;
  function setMinimumCollateralRatio(uint256 _min_cr) external;
  function setTimelock(address new_timelock) external;
  function syncBtcBalances() external;
  function timelockAddress() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;












    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import './Babylonian.sol';

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint private constant Q112 = uint(1) << RESOLUTION;
    uint private constant Q224 = Q112 << RESOLUTION;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint: ZERO_RECIPROCAL');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import '../Uniswap/Interfaces/IUniswapV2Pair.sol';
import '../Math/FixedPoint.sol';

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import './Interfaces/IUniswapV2Pair.sol';
import './Interfaces/IUniswapV2Factory.sol';

import "../Math/SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // Less efficient than the CREATE2 method below
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = IUniswapV2Factory(factory).getPair(token0, token1);
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairForCreate2(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(bytes20(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))))); // this matches the CREATE2 in UniswapV2Factory.createPair
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i = 0; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
        return _add(set._inner, bytes32(bytes20(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(bytes20(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(bytes20(value)));
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
        return address(bytes20(_at(set._inner, index)));
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
}