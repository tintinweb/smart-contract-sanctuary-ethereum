//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IMAILDeployer.sol";

import "./MAIL.sol";
import "./BridgeTokens.sol";

/**
 * @notice It is meant to run on Ethereum
 */
contract MAILDeployer is Ownable, BridgeTokens, IMAILDeployer {
    /*///////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/

    uint256 private constant INITIAL_MAX_LTV = 0.5e18;

    //solhint-disable-next-line var-name-mixedcase
    address public immutable ORACLE;

    //solhint-disable-next-line var-name-mixedcase
    address public immutable ROUTER;

    address public riskyToken;

    // Address to collect the reserve funds
    address public treasury;

    // % of interest rate to be collected by the treasury
    uint256 public reserveFactor;

    // Contract to calculate borrow and supply rate for the risky token
    address public riskyTokenInterestRateModel;

    uint256 public riskyTokenLTV;

    uint256 public liquidationFee;

    uint256 public liquidatorPortion;

    // Risky Token => Market Contract
    mapping(address => address) public getMarket;

    // Token => Interest Rate Model (BTC/USDC/USDT/BRIDGE_TOKEN)
    mapping(address => address) public getInterestRateModel;

    // Token => LTV
    mapping(address => uint256) public maxLTVOf;

    // FEE -> BOOL A mapping to prevent duplicates to the `_fees` array
    mapping(uint256 => bool) private _hasFee;

    // Array containing all the current _fees supported by Uniswap V3
    uint24[] private _fees;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @param oracle The oracle used by MAIL lending markets
     * @param _treasury The address that will collect all protocol _fees
     * @param _reserveFactor The % of the interest rate that will be sent to the treasury. It is a 18 mantissa number
     * @param modelData Data about the interest rate models for usdc, btc, wrappedNativeToken, usdt and risky token
     *
     * Requirements:
     *
     * - None of the tokens, interest rate models and oracle can be the zero address
     */
    constructor(
        address oracle,
        address _router,
        address _treasury,
        uint256 _reserveFactor,
        bytes memory modelData
    ) {
        // Update Global state
        ORACLE = oracle;
        ROUTER = _router;

        treasury = _treasury;
        reserveFactor = _reserveFactor;
        liquidatorPortion = 0.98e18; // 98%
        liquidationFee = 0.15e18; // 15%

        _initializeModels(modelData);

        _initializeMaxLTV();
    }

    /*///////////////////////////////////////////////////////////////
                                    VIEW 
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Total amount of _fees supported by UniswapV3
     * @return uint256 The number of _fees
     */
    function getFeesLength() external view returns (uint256) {
        return _fees.length;
    }

    /**
     * @dev Computes the address of a market address for the a `riskyToken`.
     *
     * @param _riskytoken Market address for this token will be returned
     * @return address The market address for the `riskytoken`.
     */
    function predictMarketAddress(address _riskytoken)
        external
        view
        returns (address)
    {
        address deployer = address(this);
        bytes32 salt = keccak256(abi.encodePacked(_riskytoken));
        bytes32 initCodeHash = keccak256(
            abi.encodePacked(type(MAILMarket).creationCode)
        );

        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                deployer,
                                salt,
                                initCodeHash
                            )
                        )
                    )
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                        MUTATIVE FUNCTIONS  
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev It deploys a MAIL market for the `risky` token
     *
     * @param _riskyToken Any ERC20 token with a pool in UniswapV3
     * @return market the address of the new deployed market.
     *
     * Requirements:
     *
     * - Risky token cannot be BTC, BRIDGE_TOKEN, USDC, USDT or the zero address
     * - Risky token must have a pool in UniswapV3
     * - There is no deployed market for this `_riskyToken`.
     */
    function deploy(address _riskyToken) external returns (address market) {
        // Make sure the `riskytoken` is different than BTC, BRIDGE_TOKEN, USDC, USDT, zero address
        require(_riskyToken != BTC, "MD: cannot be BTC");
        require(_riskyToken != WETH, "MD: cannot be WETH");
        require(_riskyToken != USDC, "MD: cannot be USDC");
        require(_riskyToken != USDT, "MD: cannot be USDT");
        require(_riskyToken != address(0), "MD: no zero address");

        // Checks that no market has been deployed for the `riskyToken`.
        require(
            getMarket[_riskyToken] == address(0),
            "MD: market already deployed"
        );
        riskyToken = _riskyToken;

        // Deploy the market
        market = address(
            new MAILMarket{salt: keccak256(abi.encodePacked(_riskyToken))}()
        );

        riskyToken = address(0);
        // Update global state
        getMarket[_riskyToken] = market;

        emit MarketCreated(market);
    }

    /*///////////////////////////////////////////////////////////////
                        PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                        PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev An initializer to set the max ltv per asset. Done to avoid stack local variable limit
     */
    function _initializeMaxLTV() private {
        // Set Initial LTV
        maxLTVOf[BTC] = INITIAL_MAX_LTV;
        maxLTVOf[USDC] = INITIAL_MAX_LTV;
        maxLTVOf[USDT] = INITIAL_MAX_LTV;
        maxLTVOf[WETH] = INITIAL_MAX_LTV;
        riskyTokenLTV = INITIAL_MAX_LTV;
    }

    /**
     * @dev An initializer to set the interest rate models of the assets. Done to avoid stack local variable limit
     */
    function _initializeModels(bytes memory modelData) private {
        (
            address btcModel,
            address usdcModel,
            address ethModel,
            address usdtModel,
            address riskytokenModel
        ) = abi.decode(
                modelData,
                (address, address, address, address, address)
            );

        // Protect agaisnt wrongly passing the zero address
        require(btcModel != address(0), "btc: no zero address");
        require(usdcModel != address(0), "usdc: no zero address");
        require(usdtModel != address(0), "usdt: no zero address");
        require(ethModel != address(0), "eth: no zero address");
        require(riskytokenModel != address(0), "ra: no zero address");

        // Map the token to the right interest rate model
        getInterestRateModel[BTC] = btcModel;
        getInterestRateModel[USDC] = usdcModel;
        getInterestRateModel[USDT] = usdtModel;
        getInterestRateModel[WETH] = ethModel;
        riskyTokenInterestRateModel = riskytokenModel;
    }

    /*///////////////////////////////////////////////////////////////
                        OWNER ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Updates the % of the interest rate that is sent to the treasury
     *
     * @param amount A number with 18 mantissa
     *
     * Requirements:
     *
     * - `amount` cannot be greater than 25%.
     * - Only the Int Governance can update this value.
     */
    function setReserveFactor(uint256 amount) external onlyOwner {
        require(amount <= 0.25 ether, "MD: too  high");
        reserveFactor = amount;
        emit SetReserveFactor(amount);
    }

    /**
     * @dev Updates the treasury address
     *
     * @param account The new treasury address
     */
    function setTreasury(address account) external onlyOwner {
        treasury = account;
        emit SetTreasury(account);
    }

    /**
     * @dev Updates the interest rate model for a `token`.
     *
     * @param token The token that will be assigned a new `interestRateModel`
     * @param interestRateModel The new interesr rate model for `token`
     *
     * Requirements:
     *
     * - Only the Int Governance can update this value.
     * - Interest rate model and token cannot be the address zero
     */
    function setInterestRateModel(address token, address interestRateModel)
        external
        onlyOwner
    {
        require(address(token) != address(0), "MD: no zero address");
        require(interestRateModel != address(0), "MD: no zero address");
        getInterestRateModel[token] = interestRateModel;
        emit SetInterestRateModel(token, interestRateModel);
    }

    /**
     * @dev This updates the interest rate model for the risky token
     *
     * @param interestRateModel The interest rate model for the risky token
     *
     * Requirements:
     *
     * - Only the Int Governance can update this value.
     * - Interest rate model and token cannot be the address zero
     */
    function setRiskyTokenInterestRateModel(address interestRateModel)
        external
        onlyOwner
    {
        require(interestRateModel != address(0), "MD: no zero address");
        riskyTokenInterestRateModel = interestRateModel;
        emit SetInterestRateModel(address(0), interestRateModel);
    }

    /**
     * @dev Allows the Int Governance to update tokens' max LTV.
     *
     * @param token The ERC20 that will have a new LTV
     * @param amount The new LTV
     *
     * Requirements:
     *
     * - Only the owner can update this value to protect the markets agaisnt volatility
     * - MAX LTV is 90% for BTC, Native Token, USDC, USDT
     */
    function setTokenLTV(address token, uint256 amount) external onlyOwner {
        require(0.9e18 >= amount, "MD: LTV too high");
        maxLTVOf[token] = amount;

        emit SetNewTokenLTV(token, amount);
    }

    /**
     * @dev Allows the Int Governance to update the max LTV for the risky asser.
     *
     * @param amount The new LTV
     *
     * Requirements:
     *
     * - Only the owner can update this value to protect the markets agaisnt volatility
     * - MAX LTV is 70% for risky assets.
     */
    function setRiskyTokenLTV(uint256 amount) external onlyOwner {
        require(0.7e18 >= amount, "MD: LTV too high");

        riskyTokenLTV = amount;

        emit SetNewTokenLTV(address(0), amount);
    }

    /**
     * @dev Allows the Int Governance to update the liquidation fee.
     *
     * @param fee The new liquidation fee
     *
     * Requirements:
     *
     * - Only Int Governance can update this value
     */
    function setLiquidationFee(uint256 fee) external onlyOwner {
        require(fee > 0 && fee <= 0.3e18, "MD: fee out of bounds");
        liquidationFee = fee;

        emit SetLiquidationFee(fee);
    }

    /**
     * @dev Allows the Int Governance to update the liquidator portion
     *
     * @param portion The new liquidator portion
     *
     * Requirements:
     *
     * - Only Int Governance can update this value
     */
    function setLiquidatorPortion(uint256 portion) external onlyOwner {
        require(portion > 0.95e18, "MD: too low");
        liquidatorPortion = portion;

        emit SetLiquidatorPortion(portion);
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IMAILDeployer {
    //solhint-disable-next-line func-name-mixedcase
    function ROUTER() external view returns (address);

    //solhint-disable-next-line func-name-mixedcase
    function ORACLE() external view returns (address);

    function riskyToken() external view returns (address);

    function getInterestRateModel(address token)
        external
        view
        returns (address);

    function predictMarketAddress(address _riskytoken)
        external
        view
        returns (address);

    function getMarket(address token) external view returns (address);

    function treasury() external view returns (address);

    function reserveFactor() external view returns (uint256);

    function riskyTokenInterestRateModel() external view returns (address);

    function getFeesLength() external view returns (uint256);

    function riskyTokenLTV() external view returns (uint256);

    function maxLTVOf(address token) external view returns (uint256);

    function liquidationFee() external view returns (uint256);

    function liquidatorPortion() external view returns (uint256);

    event MarketCreated(address indexed market);

    event SetReserveFactor(uint256 amount);

    event SetTreasury(address indexed account);

    event SetInterestRateModel(
        address indexed token,
        address indexed interestRateModel
    );

    event NewUniSwapFee(uint256 indexed fee);

    event SetNewTokenLTV(address indexed token, uint256 amount);

    event SetLiquidationFee(uint256 indexed fee);

    event SetLiquidatorPortion(uint256 indexed portion);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IMAILDeployer.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/InterestRateModelInterface.sol";
import "./interfaces/IOwnable.sol";

import "./lib/Rebase.sol";
import "./lib/IntMath.sol";
import "./lib/IntERC20.sol";

import {Market, Account} from "./Structs.sol";

/**
 * @dev We scale all numbers to 18 decimals to easily work with IntMath library. The toBase functions reads the decimals and scales them. And the fromBase puts them back to their original decimal houses.
 */
contract MAILMarket {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Accrue(
        address indexed token,
        uint256 cash,
        uint256 interestAccumulated,
        uint256 totalShares,
        uint256 totalBorrow
    );

    event Deposit(
        address indexed from,
        address indexed to,
        address indexed token,
        uint256 amount,
        uint256 rewards
    );

    event Withdraw(
        address indexed from,
        address indexed to,
        address indexed token,
        uint256 amount,
        uint256 rewards
    );

    event GetReserves(
        address indexed token,
        address indexed treasury,
        uint256 indexed amount
    );

    event DepositReserves(
        address indexed token,
        address indexed donor,
        uint256 indexed amount
    );

    event Borrow(
        address indexed borrower,
        address indexed recipient,
        address indexed token,
        uint256 principal,
        uint256 amount
    );

    event Repay(
        address indexed from,
        address indexed account,
        address indexed token,
        uint256 principal,
        uint256 amount
    );

    event Liquidate(
        address indexed borrower,
        address indexed borrowToken,
        address collateralToken,
        uint256 debt,
        uint256 collateralAmount,
        address indexed recipient,
        uint256 reservesAmount
    );

    /*///////////////////////////////////////////////////////////////
                                LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using SafeCast for uint256;
    using RebaseLibrary for Rebase;
    using IntMath for uint256;
    using SafeERC20 for IERC20;
    using IntERC20 for address;

    /*///////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/

    //solhint-disable-next-line var-name-mixedcase
    address public immutable RISKY_TOKEN;

    // Token => User => Collateral Balance
    mapping(address => mapping(address => uint256)) public balanceOf;

    // Token => User => Borrow Balance
    mapping(address => mapping(address => uint256)) public borrowOf;

    // Token => Market
    mapping(address => Market) public marketOf;

    // Token => Bool
    mapping(address => bool) public isMarket;

    // Token => User => Account
    mapping(address => mapping(address => Account)) public accountOf;

    // Token => Total Supply
    mapping(address => uint256) public totalSupplyOf;

    /**
     * @notice Maximum borrow rate that can ever be applied (.0005% / block)
     * @notice Taken directly from Compound https://github.com/compound-finance/compound-protocol/blob/master/contracts/CTokenInterfaces.sol
     */
    uint256 private constant BORROW_RATE_MAX_MANTISSA = 0.0005e16;

    //solhint-disable-next-line var-name-mixedcase
    address private constant WETH = 0xbA8d9f4d5c14f2CC644CcC06bB298FbD6DaC349C;

    // Requests
    uint8 private constant ADD_COLLATERAL_REQUEST = 0;

    uint8 private constant WITHDRAW_COLLATERAL_REQUEST = 1;

    uint8 private constant BORROW_REQUEST = 2;

    uint8 private constant REPAY_REQUEST = 3;

    //solhint-disable-next-line var-name-mixedcase
    address private immutable MAIL_DEPLOYER; // Deployer of this contract

    //solhint-disable-next-line var-name-mixedcase
    address private immutable ORACLE;

    //solhint-disable-next-line var-name-mixedcase
    address private immutable ROUTER;

    //solhint-disable-next-line var-name-mixedcase
    address[] private MARKETS;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        // Type the `msg.sender` to IMAILDeployer
        IMAILDeployer mailDeployer = IMAILDeployer(msg.sender);

        // Get the token addresses from the MAIL Deployer
        address riskyToken = mailDeployer.riskyToken();

        // Update the Global state
        RISKY_TOKEN = riskyToken;
        ORACLE = mailDeployer.ORACLE();
        MAIL_DEPLOYER = msg.sender;
        ROUTER = mailDeployer.ROUTER();

        // Whitelist all tokens supported by this contract

        // BTC
        isMarket[0xbdBFEBE240a4606119bC950Eec3e0Ed05719d739] = true;
        // USDT
        isMarket[0xb306ee3d2092166cb942D1AE2210A7641f73c11F] = true;
        // USDC
        isMarket[0xf3706E14c4aE1bd94f65909f9aB9e30D8C1b7B16] = true;
        // WETH
        isMarket[0xbA8d9f4d5c14f2CC644CcC06bB298FbD6DaC349C] = true;
        // Risky Token
        isMarket[riskyToken] = true;

        // Update the tokens array to easily fetch data about all markets
        // BTC
        MARKETS.push(0xbdBFEBE240a4606119bC950Eec3e0Ed05719d739);
        // USDT
        MARKETS.push(0xb306ee3d2092166cb942D1AE2210A7641f73c11F);
        // USDC
        MARKETS.push(0xf3706E14c4aE1bd94f65909f9aB9e30D8C1b7B16);
        // WETH
        MARKETS.push(WETH);
        // Risky Token
        MARKETS.push(riskyToken);
    }

    /*///////////////////////////////////////////////////////////////
                            MODIFIER
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev It guards the contract to only accept supported assets.
     *
     * @param token The token that must be whitelisted.
     */
    modifier isMarketListed(address token) {
        require(isMarket[token], "MAIL: token not listed");
        _;
    }

    /**
     * @dev It guarantees that the user remains solvent after all operations.
     */
    modifier isSolvent() {
        _;
        require(_isSolvent(msg.sender), "MAIL: account is insolvent");
    }

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the current balance of `token` this contract has.
     *
     * @notice It includes reserves
     *
     * @param token The address of the token that we will check the current balance
     * @return uint256 The current balance
     */
    function getCash(address token) public view returns (uint256) {
        return _getBaseAmount(token, IERC20(token).balanceOf(address(this)));
    }

    /*///////////////////////////////////////////////////////////////
                            MUTATIVE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Allows the `MAIL_DEPLOYER` owner transfer reserves to the treasury.
     *
     * @param token The reserves for a specific asset supported by this contract.
     * @param amount The number of tokens in the reserves to be withdrawn
     *
     * Requirements:
     *
     * - Only the `MAIL_DEPLOYER` owner can withdraw tokens to the treasury.
     * - Only tokens supported by this pool can be withdrawn.
     */
    function getReserves(address token, uint256 amount)
        external
        isMarketListed(token)
    {
        // Type the `MAIL_DEPLOYER` to access its functions
        IMAILDeployer mailDeployer = IMAILDeployer(MAIL_DEPLOYER);

        // Only the owner of `mailDeployer` can send reserves to the treasury as they reduce liquidity and earnings.
        require(
            msg.sender == IOwnable(address(mailDeployer)).owner(),
            "MAIL: only owner"
        );

        // Save storage in memory to save gas.
        Market memory market = marketOf[token];

        // Convert to 18 decimal base number
        uint256 baseAmount = _getBaseAmount(token, amount);

        // Make sure there is enough liquidity in the market
        require(getCash(token) >= baseAmount, "MAIL: not enough cash");
        // Make sure the owner can only take tokens from the reserves
        require(
            market.totalReserves >= baseAmount,
            "MAIL: not enough reserves"
        );

        // Update the total reserves
        market.totalReserves -= baseAmount.toUint128();

        // Update the storage
        marketOf[token] = market;

        // Save the treasury address in memory
        address treasury = mailDeployer.treasury();

        // Transfer the token in the unbase amount to the treasury
        IERC20(token).safeTransfer(treasury, amount);

        // Emit the event
        emit GetReserves(token, treasury, amount);
    }

    /**
     * @dev It allows anyone to deposit directly into the reserves to help the protocol
     *
     * @param token The token, which the donor wants to add to the reserves
     * @param amount The number of `token` that will be added to the reserves.
     *
     * Requirements:
     *
     * - The `msg.sender` must provide allowance beforehand.
     * - Only tokens supported by this pool can be donated to the reserves.
     */
    function depositReserves(address token, uint256 amount)
        external
        isMarketListed(token)
    {
        // Save the market information in memory
        Market memory market = marketOf[token];

        // Convert the amount to a base amount
        uint256 baseAmount = _getBaseAmount(token, amount);

        // Get the tokens from the `msg.sender` in amount.
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Update the market in information in memory
        market.totalReserves += baseAmount.toUint128();

        // Update in storage
        marketOf[token] = market;

        // Emit the event
        emit DepositReserves(token, msg.sender, amount);
    }

    /**
     * @dev Allows nyone to update the loan data of a market.
     *
     * @param token The market that will have its loan information updated.
     *
     * Requirements:
     *
     * - Token must be listed in this pool; otherwise makes no sense to update an unlisted market.
     */
    function accrue(address token) external isMarketListed(token) {
        // Call the internal {_accrue}.
        _accrue(token);
    }

    /**
     * @dev It allows any account to deposit tokens for the `to` address.
     *
     * @param token The ERC20 the `msg.sender` wishes to deposit
     * @param amount The number of `token` that will be deposited
     * @param to The address that the deposit will be assigned to
     *
     * Requirements:
     *
     * - The `token` must be supported by this contract
     * - The amount cannot be zero
     * - The `to` must not be the zero address to avoid loss of funds
     * - The `token` must be supported by this market.
     * - The `msg.sender` must provide an allowance greater than `amount` to use this function.
     */
    function deposit(
        address token,
        uint256 amount,
        address to
    ) external isMarketListed(token) {
        _deposit(token, amount, msg.sender, to);
    }

    /**
     * @dev Allows the `from` to withdraw `from` his/her tokens or the `router` from `MAIL_DEPLOYER`.
     *
     * @param token The ERC20 token the `msg.sender` wishes to withdraw
     * @param amount The number of `token` the `msg.sender` wishes to withdraw
     * @param to The account, which will receive the tokens
     *
     * Requirements:
     *
     * - Only the `msg.sender` or the `router` can withdraw tokens
     * - The amount has to be greater than 0
     * - The market must have enough liquidity
     * - The `token` must be supported by this market.
     */
    function withdraw(
        address token,
        uint256 amount,
        address to
    ) external isMarketListed(token) isSolvent {
        // Accumulate interest and rewards.
        _accrue(token);

        _withdraw(token, amount, msg.sender, to);
    }

    /**
     * @dev It allows the `msg.sender` or the router to open a loan position for the `from` address.
     *
     * @param token The loan will be issued in this token
     * @param amount Indicates how many `token` the `from` will loan.
     * @param to The account, which will receive the tokens
     *
     * Requirements:
     *
     * - The `from` must be the `msg.sender` or the router.
     * - The `amount` cannot be the zero address
     * - The `token` must be supported by this market.
     * - There must be ebough liquidity to be borrowed.
     */
    function borrow(
        address token,
        uint256 amount,
        address to
    ) external isMarketListed(token) isSolvent {
        // Update the debt and rewards
        _accrue(token);

        _borrow(token, amount, msg.sender, to);
    }

    /**
     * @dev It allows a `msg.sender` to pay the debt of the `to` address
     *
     * @param token The token in which the loan is denominated in
     * @param principal How many shares of the loan will be paid by the `msg.sender`
     * @param to The account, which will have its loan  paid for.
     *
     * Requirements:
     *
     * - The `to` address cannot be the zero address
     * - The `principal` cannot be the zero address
     * - The token must be supported by this contract
     * - The `msg.sender` must approve this contract to use this function
     */
    function repay(
        address token,
        uint256 principal,
        address to
    ) external isMarketListed(token) {
        // Update the debt and rewards
        _accrue(token);

        _repay(token, principal, msg.sender, to);
    }

    function request(
        address from,
        uint8[] calldata requests,
        bytes[] calldata requestArgs
    ) external {
        require(
            msg.sender == from || msg.sender == ROUTER,
            "MAIL: not authorized"
        );
        bool checkForSolvency;

        for (uint256 i; i < requests.length; i++) {
            uint8 requestAction = requests[i];

            if (_checkForSolvency(requestAction) && !checkForSolvency)
                checkForSolvency = true;

            _request(from, requestAction, requestArgs[i]);
        }

        if (checkForSolvency)
            require(_isSolvent(from), "MAIL: from is insolvent");
    }

    /**
     * @dev This account allows a `msg.sender` to repay an amount of a loan underwater. The `msg.sender` must indicate which collateral token the entity being liquidated will be used to cover the loan. The `msg.sender` must provide the same amount of tokens used to close the account.
     *
     * @param borrower The account that will be liquidated
     * @param borrowToken The market of the loan that will be liquidated
     * @param principal The amount of the loan to be repaid in shares
     * @param collateralToken The market in which the `borrower` has enough collateral to cover the `principal`.
     * @param recipient The account which will be rewarded with this liquidation
     *
     * Requirements:
     *
     * - The `msg.sender` must have enough tokens to cover the `principal` in nominal amount.
     * - This function must liquidate a user. So `principal` has to be greater than 0.
     * - The `borrowToken` must be supported by this market.
     * - The `collateralToken` must be supported by this market.
     */
    function liquidate(
        address borrower,
        address borrowToken,
        uint256 principal,
        address collateralToken,
        address recipient
    ) external {
        // Tokens must exist in the market
        require(isMarket[borrowToken], "MAIL: borrowToken not listed");
        require(isMarket[collateralToken], "MAIL: collateralToken not listed");
        require(recipient != address(0), "MAIL: no zero address recipient");
        require(principal > 0, "MAIL: no zero principal");

        // Update the rewards and debt for this market
        _accrue(borrowToken);

        // Solvent users cannot be liquidated
        require(!_isSolvent(borrower), "MAIL: borrower is solvent");

        // Save total amount nominal amount owed.
        uint256 debt;

        // Uniswap style block scope
        {
            // Store the actual amount to repay
            uint256 principalToRepay;

            // Save storage loan info to memory
            Market memory borrowMarket = marketOf[borrowToken];
            Rebase memory loan = borrowMarket.loan;

            // Uniswap style block scope
            {
                // Save borrower account info in memory
                Account memory account = accountOf[borrowToken][borrower];

                principal = _getBaseAmount(borrowToken, principal);

                // It is impossible to repay more than what the `borrower` owes
                principalToRepay = principal > account.principal
                    ? account.principal
                    : principal;

                // Repays the loan
                account.principal -= principalToRepay.toUint128();

                // Update the global state
                accountOf[borrowToken][borrower] = account;
            }

            // Calculate how much collateral is owed in borrowed tokens.
            debt = loan.toElastic(principalToRepay, false);

            // Uniswap style block scope
            {
                // `msg.sender` must provide enough tokens to keep the balance sheet
                IERC20(borrowToken).safeTransferFrom(
                    msg.sender,
                    address(this),
                    debt.fromBase(borrowToken.safeDecimals())
                );

                // update the loan information and treats rounding issues.
                if (principalToRepay == loan.base) {
                    loan.sub(loan.base, loan.elastic);
                } else {
                    loan.sub(principalToRepay, debt);
                }

                // Update the state
                borrowMarket.loan = loan;
                marketOf[borrowToken] = borrowMarket;
            }
        }

        // Uniswap style block scope
        {
            uint256 collateralToCover;
            uint256 fee = debt.bmul(
                IMAILDeployer(MAIL_DEPLOYER).liquidationFee()
            );

            // if the borrow and collateral token are the same we do not need to do a price convertion.
            if (borrowToken == collateralToken) {
                collateralToCover = debt + fee;
            } else {
                // Fetch the price of the total debt in ETH
                uint256 amountOwedInETH = _getTokenPrice(
                    borrowToken,
                    debt + fee
                );

                // Find the price of one `collateralToken` in ETH.
                uint256 collateralTokenPriceInETH = _getTokenPrice(
                    collateralToken,
                    1 ether
                );

                // Calculate how many collateral tokens we need to cover `amountOwedInETH`.
                collateralToCover = amountOwedInETH.bdiv(
                    collateralTokenPriceInETH
                );
            }

            // Save borrower and recipient collateral market account info in memory
            Account memory borrowerCollateralAccount = accountOf[
                collateralToken
            ][borrower];

            Account memory recipientCollateralAccount = accountOf[
                collateralToken
            ][recipient];

            Market memory collateralMarket = marketOf[collateralToken];

            // Protocol charges a fee for reserves
            uint256 recipientNewAmount = collateralToCover.bmul(
                IMAILDeployer(MAIL_DEPLOYER).liquidatorPortion()
            );

            // Liquidate the borrower and reward the liquidator.
            borrowerCollateralAccount.balance -= collateralToCover.toUint128();
            recipientCollateralAccount.balance += recipientNewAmount
                .toUint128();

            // Pay the reserves
            collateralMarket.totalReserves += (collateralToCover -
                recipientNewAmount).toUint128();

            // Update global state
            marketOf[collateralToken] = collateralMarket;
            accountOf[collateralToken][borrower] = borrowerCollateralAccount;
            accountOf[collateralToken][recipient] = recipientCollateralAccount;

            emit Liquidate(
                borrower,
                borrowToken,
                collateralToken,
                debt,
                collateralToCover,
                recipient,
                collateralToCover - recipientNewAmount
            );
        }
    }

    /*///////////////////////////////////////////////////////////////
                            PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _request(
        address from,
        uint8 requestAction,
        bytes calldata data
    ) private {
        if (requestAction == ADD_COLLATERAL_REQUEST) {
            (address token, uint256 amount, address to) = abi.decode(
                data,
                (address, uint256, address)
            );
            require(isMarket[token], "MAIL: token not listed");
            _deposit(token, amount, from, to);
            return;
        }

        if (requestAction == WITHDRAW_COLLATERAL_REQUEST) {
            (address token, uint256 amount, address to) = abi.decode(
                data,
                (address, uint256, address)
            );
            require(isMarket[token], "MAIL: token not listed");
            _accrue(token);
            _withdraw(token, amount, from, to);
            return;
        }

        if (requestAction == REPAY_REQUEST) {
            (address token, uint256 principal, address to) = abi.decode(
                data,
                (address, uint256, address)
            );
            require(isMarket[token], "MAIL: token not listed");
            _accrue(token);
            _repay(token, principal, from, to);
            return;
        }

        if (requestAction == BORROW_REQUEST) {
            (address token, uint256 amount, address to) = abi.decode(
                data,
                (address, uint256, address)
            );
            require(isMarket[token], "MAIL: token not listed");
            _accrue(token);
            _borrow(token, amount, from, to);
            return;
        }

        revert("MAIL: invalid request");
    }

    /**
     * @dev Helper function to check if we should check for solvency in the request functions
     *
     * @param __request The request action
     * @return bool if true the function should check for solvency
     */
    function _checkForSolvency(uint8 __request) private pure returns (bool) {
        if (__request == WITHDRAW_COLLATERAL_REQUEST) return true;
        if (__request == BORROW_REQUEST) return true;

        return false;
    }

    /**
     * @dev It allows any account to deposit tokens for the `to` address.
     *
     * @param token The ERC20 the `msg.sender` wishes to deposit
     * @param amount The number of `token` that will be deposited
     * @param from The account that is transferring the tokens
     * @param to The address that the deposit will be assigned to
     *
     * Requirements:
     *
     * - The amount cannot be zero
     * - The `to` must not be the zero address to avoid loss of funds
     * - The `from` must provide an allowance greater than `amount` to use this function.
     */
    function _deposit(
        address token,
        uint256 amount,
        address from,
        address to
    ) private {
        require(amount > 0, "MAIL: no zero deposits");
        require(to != address(0), "MAIL: no zero address deposits");

        // Save storage in memory to save gas
        uint256 totalSupply = totalSupplyOf[token];
        Account memory account = accountOf[token][to];
        uint256 _totalRewards = marketOf[token].totalRewardsPerToken;

        // If the market is empty. There are no rewards or if it is the `to` first deposit.
        uint256 rewards;

        // If the`to` has deposited before. We update the rewards.
        if (account.balance > 0) {
            rewards =
                uint256(account.balance).bmul(_totalRewards) -
                account.rewardDebt;
        }

        // Get tokens from `msg.sender`. It does not have to be the `to` address.
        IERC20(token).safeTransferFrom(from, address(this), amount);

        // All values in this contract use decimals 18.
        uint256 baseAmount = _getBaseAmount(token, amount);

        // We "compound" the rewards to the user to be readily avaliable to be lent.
        uint256 newAmount = baseAmount + rewards;

        // Update Local State
        account.balance += newAmount.toUint128();
        account.rewardDebt = uint256(account.balance).bmul(_totalRewards);
        totalSupply += newAmount;

        // Update Global state
        totalSupplyOf[token] = totalSupply;
        accountOf[token][to] = account;

        // Emit event
        emit Deposit(from, to, token, amount, rewards);
    }

    /**
     * @dev Allows the `from` to withdraw `from` his/her tokens or the `router` from `MAIL_DEPLOYER`.
     *
     * @param token The ERC20 token the `msg.sender` wishes to withdraw
     * @param amount The number of `token` the `msg.sender` wishes to withdraw
     * @param from The account, which will have its token withdrawn
     * @param to The account, which will receive the withdrawn tokens
     *
     * Requirements:
     *
     * - The amount has to be greater than 0
     * - The market must have enough liquidity
     */
    function _withdraw(
        address token,
        uint256 amount,
        address from,
        address to
    ) private {
        // Security checks
        require(amount > 0, "MAIL: no zero withdraws");
        require(to != address(0), "MAIL: no zero address");

        // Save storage in memory to save gas
        uint256 totalSupply = totalSupplyOf[token];
        Account memory account = accountOf[token][from];
        uint256 _totalRewards = marketOf[token].totalRewardsPerToken;

        // Calculate the rewards for the `to` address.
        uint256 rewards = uint256(account.balance).bmul(_totalRewards) -
            account.rewardDebt;

        // All values in this contract use decimals 18
        uint256 baseAmount = _getBaseAmount(token, amount);

        // Make sure the market has enough liquidity
        require(getCash(token) >= baseAmount, "MAIL: not enough cash");

        // Update state in memory
        account.balance -= baseAmount.toUint128();
        account.rewardDebt = uint256(account.balance).bmul(_totalRewards);
        totalSupply -= baseAmount;

        // Update state in storage
        totalSupplyOf[token] = totalSupply;
        accountOf[token][from] = account;

        // Send tokens to `msg.sender`.
        IERC20(token).safeTransfer(
            to,
            amount + rewards.fromBase(token.safeDecimals())
        );

        // emit event
        emit Withdraw(from, to, token, amount, rewards);
    }

    /**
     * @dev It allows the `msg.sender` or the router to open a loan position for the `from` address.
     *
     * @param token The loan will be issued in this token
     * @param amount Indicates how many `token` the `from` will loan.
     * @param from The account that is opening the loan
     * @param to The account, which will receive the tokens
     *
     * Requirements:
     *
     * - The `from` must be the `msg.sender` or the router.
     * - The `amount` cannot be the zero address
     * - The `token` must be supported by this market.
     * - There must be ebough liquidity to be borrowed.
     */
    function _borrow(
        address token,
        uint256 amount,
        address from,
        address to
    ) private {
        // Security checks
        require(amount > 0, "MAIL: no zero withdraws");

        // Make sure the amount has 18 decimals
        uint256 baseAmount = _getBaseAmount(token, amount);

        // Make sure the market has enough liquidity
        require(getCash(token) >= baseAmount, "MAIL: not enough cash");

        // Read from memory
        Account memory account = accountOf[token][from];
        Market memory market = marketOf[token];
        Rebase memory loan = market.loan;

        uint256 principal;

        // Update the state in memory
        (market.loan, principal) = loan.add(baseAmount, true);

        // Update memory
        account.principal += principal.toUint128();

        //  Update storage
        accountOf[token][from] = account;
        marketOf[token] = market;

        // Transfer the loan `token` to the `msg.sender`.
        IERC20(token).safeTransfer(to, amount);

        // Emit event
        emit Borrow(from, to, token, principal, amount);
    }

    /**
     * @dev It allows a `msg.sender` to pay the debt of the `to` address
     *
     * @param token The token in which the loan is denominated in
     * @param principal How many shares of the loan will be paid by the `msg.sender`
     * @param from The account that is paying.
     * @param to The account, which will have its loan  paid for.
     *
     * Requirements:
     *
     * - The `to` address cannot be the zero address
     * - The `principal` cannot be the zero address
     * - The token must be supported by this contract
     * - The `msg.sender` must approve this contract to use this function
     */
    function _repay(
        address token,
        uint256 principal,
        address from,
        address to
    ) private {
        // Security checks read above
        require(principal > 0, "MAIL: principal cannot be 0");
        require(to != address(0), "MAIL: no to zero address");

        // Save storage in memory to save gas
        Market memory market = marketOf[token];
        Rebase memory loan = market.loan;
        Account memory account = accountOf[token][to];
        (Rebase memory _loan, uint256 debt) = loan.sub(principal, true);

        // Get the tokens from `msg.sender`
        IERC20(token).safeTransferFrom(
            from,
            address(this),
            debt.fromBase(token.safeDecimals())
        );

        // Update the state in memory
        market.loan = _loan;
        account.principal -= principal.toUint128();

        // Update the state in storage
        marketOf[token] = market;
        accountOf[token][to] = account;

        // Emit event
        emit Repay(from, to, token, principal, debt);
    }

    /**
     * @dev Helper function to fetch a `token` price from the oracle for an `amount`.
     *
     * @param token An ERC20 token, that we wish to get the price for
     * @param amount The amount of `token` to calculate the price
     * @return The price with 18 decimals in USD for the `token`
     */
    function _getTokenPrice(address token, uint256 amount)
        private
        view
        returns (uint256)
    {
        if (token == WETH) return amount;

        // Risky token uses a different Oracle function
        if (token == RISKY_TOKEN)
            return IOracle(ORACLE).getUNIV3Price(token, amount);

        return IOracle(ORACLE).getETHPrice(token, amount);
    }

    /**
     * @dev Helper function to see if a user has enough collateral * LTV to cover his/her loan.
     *
     * @param user The user that is solvent or not
     * @return bool Indicates if a user is solvent or not
     */
    function _isSolvent(address user) private view returns (bool) {
        // Save storage to memory to save gas
        address[] memory tokens = MARKETS;
        address mailDeployer = MAIL_DEPLOYER;
        address riskyToken = RISKY_TOKEN;
        IOracle oracle = IOracle(ORACLE);

        // Total amount of loans in ETH
        uint256 totalDebtInETH;
        // Total collateral in ETH
        uint256 totalCollateralInETH;

        // Need to iterate through all markets to know the total balance sheet of a user.
        for (uint256 i; i < tokens.length; i++) {
            address token = tokens[i];
            Account memory account = accountOf[token][user];

            // If a user does not have any loans or balance we do not need to do anything
            if (account.balance == 0 && account.principal == 0) continue;

            // If the user does has any balance, we need to up his/her collateral.
            if (account.balance > 0) {
                if (token == riskyToken) {
                    // Need to reduce the collateral by the ltv ratio
                    uint256 ltvRatio = IMAILDeployer(mailDeployer)
                        .riskyTokenLTV();
                    totalCollateralInETH += oracle
                        .getUNIV3Price(token, uint256(account.balance))
                        .bmul(ltvRatio);
                } else if (token == WETH) {
                    uint256 ltvRatio = IMAILDeployer(mailDeployer).maxLTVOf(
                        token
                    );
                    totalCollateralInETH += uint256(account.balance).bmul(
                        ltvRatio
                    );
                } else {
                    // Need to reduce the collateral by the ltv ratio
                    uint256 ltvRatio = IMAILDeployer(mailDeployer).maxLTVOf(
                        token
                    );
                    totalCollateralInETH += oracle
                        .getETHPrice(token, uint256(account.balance))
                        .bmul(ltvRatio);
                }
            }

            // If the user does not have any open loans, we do not need to do any further calculations.
            if (account.principal == 0) continue;

            Market memory market = marketOf[token];

            // If we already accrued in this block. We do not need to accrue again.
            if (market.lastAccruedBlock != block.number) {
                // If the user has loans. We need to accrue the market first.
                // We get the accrued values without actually accrueing to save gas.
                (market, ) = _viewAccrue(
                    mailDeployer,
                    market,
                    token,
                    getCash(token)
                );
            }

            Rebase memory loan = market.loan;

            // Find out how much the user owes.
            uint256 amountOwed = loan.toElastic(account.principal, true);

            // Update the collateral and debt depending if it is a risky token or not.
            if (token == riskyToken) {
                totalDebtInETH += oracle.getUNIV3Price(riskyToken, amountOwed);
            } else if (token == WETH) {
                totalDebtInETH += amountOwed;
            } else {
                totalDebtInETH += oracle.getETHPrice(token, amountOwed);
            }
        }

        // If the user has no debt, he is solvent.
        return
            totalDebtInETH == 0 ? true : totalCollateralInETH > totalDebtInETH;
    }

    /**
     * @dev A helper function to scale a number to 18 decimals to easily interact with IntMath
     *
     * @param token The ERC20 associated with the amount. We will read its decimals and scale to 18 decimals
     * @param amount The number to scale up or down
     * @return uint256 The number of tokens with 18 decimals
     */
    function _getBaseAmount(address token, uint256 amount)
        private
        view
        returns (uint256)
    {
        return amount.toBase(token.safeDecimals());
    }

    /**
     * @dev Helper function to update the loan data of the `token` market.
     *
     * @param token The market token
     */
    function _accrue(address token) private {
        // Save storage in memory to save gas
        Market memory market = marketOf[token];
        // If this function is called in the same block. There is nothing to do. As it is updated already.
        if (block.number == market.lastAccruedBlock) return;

        Rebase memory loan = market.loan;

        // If there are no loans. There is nothing else to do. We simply update the storage and return.
        if (loan.base == 0) {
            // Update the lastAccruedBlock in memory to the current block.
            market.lastAccruedBlock = block.number.toUint128();
            marketOf[token] = market;
            return;
        }

        // Find out how much cash we currently have.
        uint256 cash = getCash(token);

        // Interest accumulated for logging purposes.
        uint256 interestAccumulated;

        // Calculate the accrue value and update the storage and update the interest accumulated
        (market, interestAccumulated) = _viewAccrue(
            MAIL_DEPLOYER,
            market,
            token,
            cash
        );

        // Indicate that we have calculated all needed information up to this block.
        market.lastAccruedBlock = block.number.toUint128();

        // Update the storage
        marketOf[token] = market;

        // Emit event
        emit Accrue(token, cash, interestAccumulated, loan.base, loan.elastic);
    }

    /**
     * @dev Helper function to encapsulate the accrue logic in view function to save gas on the {_isSolvent}.
     *
     * @param mailDeployer the deployer of all Mail Pools
     * @param market The current market we wish to know the loan after accrueing the interest rate
     * @param token The token of the `market`.
     * @param cash The current cash in this pool.
     * @return (market, interestAccumulated) The market with its loan updated and the interest accumulated
     */
    function _viewAccrue(
        address mailDeployer,
        Market memory market,
        address token,
        uint256 cash
    ) private view returns (Market memory, uint256) {
        // Save loan in memory
        Rebase memory loan = market.loan;

        // Get the interest rate model for the `token`.
        InterestRateModelInterface interestRateModel = InterestRateModelInterface(
                IMAILDeployer(mailDeployer).getInterestRateModel(token)
            );

        // Calculate the borrow rate per block
        uint256 borrowRatePerBlock = interestRateModel.getBorrowRatePerBlock(
            cash,
            loan.elastic,
            market.totalReserves
        );

        // Make sure it is not very high
        require(
            BORROW_RATE_MAX_MANTISSA > borrowRatePerBlock,
            "MAIL: borrow rate too high"
        );

        // Uniswap block scope style
        {
            // Calculate borrow rate per block with the number of blocks since the last update
            uint256 interestAccumulated = (block.number -
                market.lastAccruedBlock) * borrowRatePerBlock;

            // Calculate the supply rate per block with the number of blocks since the last update
            uint256 rewardsInterestAccumulated = (block.number -
                market.lastAccruedBlock) *
                interestRateModel.getSupplyRatePerBlock(
                    cash,
                    loan.elastic,
                    market.totalReserves,
                    IMAILDeployer(mailDeployer).reserveFactor()
                );

            // Multiply the borrow rate by the total elastic loan to get the nominal value
            uint256 newDebt = interestAccumulated.bmul(loan.elastic);

            // Multiply the supply rate by the total elastic loan to get the nominal value
            uint256 newRewards = rewardsInterestAccumulated.bmul(loan.elastic);

            // The borrow rate total collected must always be higher than the rewards
            assert(newDebt > newRewards);

            // Update the loanin memory.
            loan.elastic += newDebt.toUint128();

            // Save storage in memory
            uint256 totalSupply = totalSupplyOf[token];

            // If we have open loans, the total supply must be greater than 0
            assert(totalSupply > 0);

            // Difference between borrow rate and supply rate is the reserves
            market.totalReserves += (newDebt - newRewards).toUint128();
            // Update the calculated information
            market.loan = loan;
            market.totalRewardsPerToken += newRewards.bdiv(totalSupply);

            // Return the pair
            return (market, interestAccumulated);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract BridgeTokens {
    address internal constant BTC = 0xbdBFEBE240a4606119bC950Eec3e0Ed05719d739;

    address internal constant WETH = 0xbA8d9f4d5c14f2CC644CcC06bB298FbD6DaC349C;

    address internal constant USDC = 0xf3706E14c4aE1bd94f65909f9aB9e30D8C1b7B16;

    address internal constant USDT = 0xb306ee3d2092166cb942D1AE2210A7641f73c11F;

    //solhint-disable-next-line var-name-mixedcase
    address[] internal BRIDGE_TOKENS_ARRAY = [
        0xbdBFEBE240a4606119bC950Eec3e0Ed05719d739, // BTC
        0xbA8d9f4d5c14f2CC644CcC06bB298FbD6DaC349C, // WETH
        0xf3706E14c4aE1bd94f65909f9aB9e30D8C1b7B16, // USDC
        0xb306ee3d2092166cb942D1AE2210A7641f73c11F // USDT
    ];
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IOracle {
    function getETHPrice(address token, uint256 amount)
        external
        view
        returns (uint256);

    function getUNIV3Price(address riskytoken, uint256 amount)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface InterestRateModelInterface {
    function getBorrowRatePerBlock(
        uint256 cash,
        uint256 totalBorrowAmount,
        uint256 reserves
    ) external view returns (uint256);

    function getSupplyRatePerBlock(
        uint256 cash,
        uint256 totalBorrowAmount,
        uint256 reserves,
        uint256 reserveFactor
    ) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IOwnable {
    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./IntMath.sol";

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/**
 *
 * @dev This library provides a collection of functions to manipulate a base and elastic values saved in a Rebase struct.
 * In a pool context, the base represents the amount of tokens deposited or withdrawn from an investor.
 * The elastic value represents how the pool tokens performed over time by incurring losses or profits.
 * With this library, one can easily calculate how much loss or profit each investor incurred based on their tokens
 * invested.
 *
 * @notice We use the {SafeCast} Open Zeppelin library for safely converting from uint256 to uint128 memory storage efficiency.
 * Therefore, it is important to keep in mind of the upperbound limit number this library supports.
 *
 */
library RebaseLibrary {
    using SafeCast for uint256;
    using IntMath for uint256;

    /**
     * @dev Calculates a base value from an elastic value using the ratio of a {Rebase} struct.
     *
     * @param total {Rebase} struct, which represents a base/elastic pair.
     * @param elastic The new base is calculated from this elastic.
     * @param roundUp Rounding logic due to solidity always rounding down.
     * @return base The calculated base.
     *
     */
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = elastic.mulDiv(total.base, total.elastic);
            if (roundUp && base.mulDiv(total.elastic, total.base) < elastic) {
                base += 1;
            }
        }
    }

    /**
     * @dev Calculates the elastic value from a base value using the ratio of a {Rebase} struct.
     *
     * @param total {Rebase} struct, which represents a base/elastic pair.
     * @param base The new base, which the new elastic will be calculated from.
     * @param roundUp Rounding logic due to solidity always rounding down.
     * @return elastic The calculated elastic.
     *
     */
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = base.mulDiv(total.elastic, total.base);
            if (roundUp && elastic.mulDiv(total.base, total.elastic) < base) {
                elastic += 1;
            }
        }
    }

    /**
     * @dev Calculates new values to a {Rebase} pair by incrementing the elastic value.
     * This function maintains the ratio of the current pair.
     *
     * @param total {Rebase} struct which represents a base/elastic pair.
     * @param elastic The new elastic to be added to the pair.
     * A new base will be calculated based on the new elastic using {toBase} function.
     * @param roundUp Rounding logic due to solidity always rounding down.
     * @return (total, base) A pair of the new {Rebase} pair values and new calculated base.
     *
     */
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic += elastic.toUint128();
        total.base += base.toUint128();
        return (total, base);
    }

    /**
     * @dev Calculates new values to a {Rebase} pair by reducing the base.
     * This function maintains the ratio of the current pair.
     *
     * @param total {Rebase} struct, which represents a base/elastic pair.
     * @param base The number to be subtracted from the base.
     * The new elastic will be calculated based on the new base value via the {toElastic} function.
     * @param roundUp Rounding logic due to solidity always rounding down.
     * @return (total, elastic) A pair of the new {Rebase} pair values and the new elastic based on the updated base.
     *
     */
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic -= elastic.toUint128();
        total.base -= base.toUint128();
        return (total, elastic);
    }

    /**
     * @dev Increases the base and elastic from a {Rebase} pair without keeping a specific ratio.
     *
     * @param total {Rebase} struct which represents a base/elastic pair that will be updated.
     * @param base The value to be added to the `total.base`.
     * @param elastic The value to be added to the `total.elastic`.
     * @return total The new {Rebase} pair calculated by adding the `base` and `elastic` values.
     *
     */
    function add(
        Rebase memory total,
        uint256 base,
        uint256 elastic
    ) internal pure returns (Rebase memory) {
        total.base += base.toUint128();
        total.elastic += elastic.toUint128();
        return total;
    }

    /**
     * @dev Decreases the base and elastic from a {Rebase} pair without keeping a specific ratio.
     *
     * @param total The base/elastic pair that will be updated.
     * @param base The value to be decreased from the `total.base`.
     * @param elastic The value to be decreased from the `total.elastic`.
     * @return total The new {Rebase} calculated by decreasing the base and pair from `total`.
     *
     */
    function sub(
        Rebase memory total,
        uint256 base,
        uint256 elastic
    ) internal pure returns (Rebase memory) {
        total.base -= base.toUint128();
        total.elastic -= elastic.toUint128();
        return total;
    }

    /**
     * @dev Adds elastic to a {Rebase} pair.
     *
     * @notice The `total` parameter is saved in storage. This will update the global state of the caller contract.
     *
     * @param total The {Rebase} struct, which will have its' elastic increased.
     * @param elastic The value to be added to the elastic of `total`.
     * @return newElastic The new elastic value after reducing `elastic` from `total.elastic`.
     *
     */
    function addElastic(Rebase storage total, uint256 elastic)
        internal
        returns (uint256 newElastic)
    {
        newElastic = total.elastic += elastic.toUint128();
    }

    /**
     * @dev Reduces the elastic of a {Rebase} pair.
     *
     * @notice The `total` parameter is saved in storage. The caller contract will have its' storage updated.
     *
     * @param total The {Rebase} struct to be updated.
     * @param elastic The value to be removed from the `total` elastic.
     * @return newElastic The new elastic after decreasing `elastic` from `total.elastic`.
     *
     */
    function subElastic(Rebase storage total, uint256 elastic)
        internal
        returns (uint256 newElastic)
    {
        newElastic = total.elastic -= elastic.toUint128();
    }
}

// SPDX-License-Identifier: CC-BY-4.0
pragma solidity 0.8.13;

/**
 * @dev We assume that all numbers passed to {bmul} and {bdiv} have a mantissa of 1e18
 *
 * @notice We copied from https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/FullMath.sol
 * @notice We modified line 67 per this post https://ethereum.stackexchange.com/questions/96642/unary-operator-cannot-be-applied-to-type-uint256
 */
// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library IntMath {
    // Base Mantissa of all numbers in Interest Protocol
    uint256 private constant BASE = 1e18;

    /**
     * @dev Adjusts the price to have 18 decimal houses to work easier with most {ERC20}.
     *
     * @param price The price of the token
     * @param decimals The current decimals the price has
     * @return uint256 the new price supporting 18 decimal houses
     */
    function toBase(uint256 price, uint8 decimals)
        internal
        pure
        returns (uint256)
    {
        uint256 baseDecimals = 18;

        if (decimals == baseDecimals) return price;

        if (decimals < baseDecimals)
            return price * 10**(baseDecimals - decimals);

        return price / 10**(decimals - baseDecimals);
    }

    /**
     * @dev Adjusts the price to have `decimal` houses to work easier with most {ERC20}.
     *
     * @param price The price of the token
     * @param decimals The current decimals the price has
     * @return uint256 the new price supporting `decimals` decimal houses
     */
    function fromBase(uint256 price, uint8 decimals)
        internal
        pure
        returns (uint256)
    {
        uint256 baseDecimals = 18;

        if (decimals == baseDecimals) return price;

        if (decimals < baseDecimals)
            return price / 10**(baseDecimals - decimals);

        return price * 10**(decimals - baseDecimals);
    }

    /**
     * @dev Function ensures that the return value keeps the right mantissa
     */
    function bmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDiv(x, y, BASE);
    }

    /**
     * @dev Function ensures that the return value keeps the right mantissa
     */
    function bdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDiv(x, BASE, y);
    }

    /**
     * @dev Returns the smallest of two numbers.
     * Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    //solhint-disable
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = denominator & (~denominator + 1);
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /**
     * @notice This was copied from Uniswap without any modifications.
     * https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/Math.sol
     * babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev All credits to boring crypto https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/libraries/BoringERC20.sol
 */
library IntERC20 {
    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(address token) internal view returns (uint8) {
        require(isContract(token), "IntERC20: not a contract");

        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function returnDataToString(bytes memory data)
        internal
        pure
        returns (string memory)
    {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(address token) internal view returns (string memory) {
        require(isContract(token), "IntERC20: not a contract");

        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Metadata.symbol.selector)
        );
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeName(address token) internal view returns (string memory) {
        require(isContract(token), "IntERC20: not a contract");

        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Metadata.name.selector)
        );
        return success ? returnDataToString(data) : "???";
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./lib/Rebase.sol";

struct Market {
    uint128 lastAccruedBlock;
    uint128 totalReserves;
    uint256 totalRewardsPerToken;
    Rebase loan;
}

struct Account {
    uint256 rewardDebt;
    uint128 balance;
    uint128 principal;
}

struct MailData {
    uint128 usdPrice;
    uint128 supply;
    uint128 borrow;
    uint128 totalSupply;
    uint128 totalElastic;
    uint128 totalBase;
    uint128 supplyRate;
    uint128 borrowRate;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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