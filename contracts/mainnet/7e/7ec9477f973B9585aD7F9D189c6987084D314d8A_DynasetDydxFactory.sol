// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/* ========== External Inheritance ========== */
import "./AbstractDynasetFactory.sol";
import "./DynasetDydx.sol";
import "./interfaces/IDynasetContract.sol";

/**
 * @title DynasetFactory
 * @author singdaodev
 */
contract DynasetDydxFactory is AbstractDynasetFactory {
    constructor(address gnosis)
        AbstractDynasetFactory(gnosis) {
    }

    /* ==========  External Functions  ========== */

    /**   @notice Creates new dynaset contract
     * @dev dam and controller can can not be zero as the checks are
            added to constructor of Dynaset contract
     * @param dam us the asset manager of the new deployed dynaset.
     * @param controller will is the BLACK_SMITH role user for dynaset contract.
     * @param name, @param symbol will be used for dynaset ERC20 token
     */
    function deployDynaset(
        address dam,
        address controller,
        string calldata name,
        string calldata symbol
    ) external override onlyOwner {
        DynasetDydx dynaset = new DynasetDydx(
            address(this),
            dam,
            controller,
            name,
            symbol
        );
        dynasetList[address(dynaset)] = DynasetEntity({
            name: name,
            bound: true,
            initialised: false,
            forge: address(0),
            dynaddress: address(dynaset),
            performanceFee: 0,
            managementFee: 0,
            timelock: block.timestamp + 30 days,
            tvlSnapshot: 0
        });
        dynasets.push(address(dynaset));
        emit NewDynaset(address(dynaset), dam, controller);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./AbstractDynaset.sol";

contract DynasetDydx is AbstractDynaset {
    using SafeERC20 for IERC20;

    constructor(
        address factoryContract,
        address dam,
        address controller_,
        string memory name,
        string memory symbol
    ) AbstractDynaset(factoryContract, dam, controller_, name, symbol) {
    }

    function depositFromDam(address token, uint256 amount) external {
        onlyDigitalAssetManager();
        require(
            IERC20(token).balanceOf(msg.sender) >= amount,
            "ERR_INSUFFICIENT_AMOUNT"
        );
        IERC20(token).safeTransferFrom(
            digitalAssetManager,
            address(this),
            amount
        );
        records[token].balance = IERC20(token).balanceOf(address(this));
    }

    function withdrawToDam(address token, uint256 amount) external {
        onlyDigitalAssetManager();
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "ERR_INSUFFICIENT_AMOUNT"
        );
        IERC20(token).safeTransfer(digitalAssetManager, amount);
        records[token].balance = IERC20(token).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/* ========== External Inheritance ========== */
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDynasetTvlOracle.sol";
import "./interfaces/IDynasetContract.sol";

/**
 * @title DynasetFactory
 * @author singdaodev
 */
abstract contract AbstractDynasetFactory is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /* ==========  Constants  ========== */
    
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 public constant WITHDRAW_FEE_FACTOR = 10000;
    // Performance fee should be less than 25%
    uint16 public constant MAX_PERFORMANCE_FEE_FACTOR = 2500;
    // Management fee should be less than 5%
    uint16 public constant MAX_MANAGEMENT_FEE_FACTOR = 500;

    /* ==========  Storage  ========== */

    struct DynasetEntity {
        string name;
        bool bound;
        bool initialised;
        address forge;
        address dynaddress;
        uint16 performanceFee;
        uint16 managementFee;
        uint256 timelock;
        uint256 tvlSnapshot;
    }
    // multisig contract where performance fee is collected
    address public gnosisSafe;
    address[] public dynasets;
    mapping(address => DynasetEntity) internal dynasetList;
    mapping(address => address) internal oracleList;

    /* ==========  Events  ========== */

    /** @dev Emitted when dynaset is deployed. */
    event NewDynaset(
        address indexed dynaset,
        address indexed dam,
        address indexed controller
    );
    event FeeCollected(address indexed dynaset, uint256 indexed amount);
    event OracleAssigned(
        address indexed dynaset,
        address indexed oracleAddress
    );
    event InitialiseDynaset(
        address indexed dynasetAddress,
        address[] tokens,
        address indexed tokenProvider,
        uint16 performanceFee,
        uint16 managementFee
    );
    event DynasetTvlSet(address indexed dynaset, uint256 indexed tvl);

    /* ========== Dynaset Deployment  ========== */

    /**
     * @dev Deploys a dynaset
     *
     * Note: To support future interfaces, this does not initialize or
     * configure the pool, this must be executed by the controller.
     *
     * Note: Must be called by an approved admin.
     *
     */
    constructor(address gnosis) {
        require(gnosis != address(0), "ERR_ZERO_ADDRESS");
        gnosisSafe = gnosis;
    }

    /* ==========  External Functions  ========== */

    /**   @notice Creates new dynaset contract
     * @dev dam and controller can can not be zero as the checks are
            added to constructor of Dynaset contract
     * @param dam us the asset manager of the new deployed dynaset.
     * @param controller will is the BLACK_SMITH role user for dynaset contract.
     * @param name, @param symbol will be used for dynaset ERC20 token
     */
    function deployDynaset(
        address dam,
        address controller,
        string calldata name,
        string calldata symbol
    ) external virtual;

    /**
     * @notice initializes the dynaset contract with tokens.
     * @param dynasetAddress is the dynaset contract address.
     * @param  tokens is the tokens list that will be initialized.
     * @param balances are the initial balance for initialized tokens.
     * @param balances and @param tokens length should be same.
     * the balances for initialization will be transfered from
     * @param tokenProvider address
     * @dev all @param tokens for @param balance must be approved first.
     */
    function initialiseDynaset(
        address dynasetAddress,
        address[] calldata tokens,
        uint256[] calldata balances,
        address tokenProvider,
        uint16 performanceFeeFactor,
        uint16 managementFeeFactor
    ) external onlyOwner {
        // require(_dynasetlist[_dynaset].dynaddress, "ERR_NOT_AUTH");
        require(dynasetList[dynasetAddress].bound, "ADDRESS_NOT_DYNASET");
        require(
            performanceFeeFactor <= MAX_PERFORMANCE_FEE_FACTOR,
            "ERR_HIGH_PERFORMANCE_FEE"
        );
        require(
            managementFeeFactor <= MAX_MANAGEMENT_FEE_FACTOR,
            "ERR_HIGH_MANAGEMENT_FEE"
        );
        require(
            !dynasetList[dynasetAddress].initialised,
            "ERR_ALREADY_INITIALISED"
        );

        IDynasetContract dynaset = IDynasetContract(dynasetAddress);
        dynasetList[dynasetAddress].initialised = true;
        dynasetList[dynasetAddress].performanceFee = performanceFeeFactor;
        dynasetList[dynasetAddress].managementFee = managementFeeFactor;
        dynaset.initialize(tokens, balances, tokenProvider);

        emit InitialiseDynaset(
            dynasetAddress,
            tokens,
            tokenProvider,
            performanceFeeFactor,
            managementFeeFactor
        );
    }

    /**
     * @dev assign which oracle to use for calculating tvl.
     * @notice this function can be called to update the oracle of dynaset as well
     * @param dynaset is the dynasetContract address
     * @param oracle is the DynasetTvlOracle contract which has to be initialized
     * using the @param dynaset address
     */
    function assignTvlOracle(address dynaset, address oracle)
        external
        onlyOwner
        nonReentrant
    {
        require(dynasetList[dynaset].bound, "ADDRESS_NOT_DYNASET");
        oracleList[dynaset] = oracle;
        IDynasetContract(dynaset).setDynasetOracle(oracle);
        emit OracleAssigned(dynaset, oracle);
    }

    function assignTvlSnapshot(address dynasetAddress)
        external
        onlyOwner
        nonReentrant
    {
        require(dynasetList[dynasetAddress].bound, "ADDRESS_NOT_DYNASET");
        require(
            dynasetList[dynasetAddress].tvlSnapshot == 0,
            "ERR_SNAPSHOT_SET"
        );
        uint256 totalvalue = IDynasetTvlOracle(getDynasetOracle(dynasetAddress))
            .dynasetTvlUsdc();

        dynasetList[dynasetAddress].tvlSnapshot = totalvalue;
        emit DynasetTvlSet(dynasetAddress, totalvalue);
    }

    /**  @notice collects fee from dynaset contract.
    * Fee can only be collected after atleast 30 days.
    * total fee collected will be performanceFee + managementFee
     @dev collected fee is in USDC token.
     @param dynasetAddress is address of dynaset contract.
    */
    function collectFee(address dynasetAddress)
        external
        onlyOwner
        nonReentrant
    {
        require(dynasetList[dynasetAddress].bound, "ADDRESS_NOT_DYNASET");
        uint256 feeLock = dynasetList[dynasetAddress].timelock;
        require(block.timestamp >= feeLock, "ERR_FEE_PRRIOD_LOCKED");

        uint256 snapshot = dynasetList[dynasetAddress].tvlSnapshot;
        require(snapshot > 0, "ERR_TVL_NOT_SET");
        uint256 totalValue = IDynasetTvlOracle(getDynasetOracle(dynasetAddress))
            .dynasetTvlUsdc();
        uint256 withdrawFee_;

        if (totalValue > snapshot) {
            // withdrawFee_ = (performance * (performanceFeeFactor) ) / 10,000
            withdrawFee_ =
                ((totalValue - snapshot) *
                    dynasetList[dynasetAddress].performanceFee) /
                (WITHDRAW_FEE_FACTOR);
        }

        uint256 managementFee = (totalValue *
            dynasetList[dynasetAddress].managementFee) / (WITHDRAW_FEE_FACTOR);
        uint256 timeSinceLastFeeCollection = block.timestamp -
            (dynasetList[dynasetAddress].timelock - 30 days);

        // managementFee = (0-5 % of tvl) * (no. sec from last fee collection / no. sec in year);
        uint256 managementFeeAnnualised = (managementFee *
            (timeSinceLastFeeCollection)) / (365 days);
        uint256 finalFee = managementFeeAnnualised + withdrawFee_;

        require(
            IERC20(USDC).balanceOf(dynasetAddress) >= finalFee,
            "ERR_INSUFFICIENT_USDC"
        );
        dynasetList[dynasetAddress].timelock = block.timestamp + 30 days;
        IDynasetContract(dynasetAddress).withdrawFee(USDC, finalFee);
        emit FeeCollected(dynasetAddress, finalFee);
    }

    /**  @notice fee collected from dynasets is transfered to
     * externaly owned account.
     * the account is set in constructor gnosisSafe.
     * NOTE NO user funds are transfered or withdrawn.
     * only the fee collected from dynasets is transfered
     */
    function withdrawFee(address tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        require(amount > 0, "ERR_INVALID_AMOUNT");
        IERC20 token = IERC20(tokenAddress);
        require(
            token.balanceOf(address(this)) >= amount,
            "ERR_INSUFFICUENT_BALANCE"
        );
        token.safeTransfer(gnosisSafe, amount);
    }

    function updateGnosisSafe(address newGnosisSafe) external onlyOwner {
        require(newGnosisSafe != address(0), "ERR_ZERO_ADDRESS");
        gnosisSafe = newGnosisSafe;
    }

    /* ==========  Public Functions  ========== */

    function getDynasetOracle(address dynaset)
        public
        view
        returns (address oracle)
    {
        require(oracleList[dynaset] != address(0), "ERR_ORACLE_UNASSIGNED");
        return oracleList[dynaset];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IDynasetContract {
    /**
     * @dev Token record data structure
     * @param bound is token bound to pool
     * @param ready has token been initialized
     * @param lastDenormUpdate timestamp of last denorm change
     * @param desiredDenorm desired denormalized weight (used for incremental changes)
     * @param index of address in tokens array
     * @param balance token balance
     */
    struct Record {
        bool bound; // is token bound to dynaset
        bool ready;
        uint256 index; // private
        uint256 balance;
    }

    event LOG_SWAP(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 tokenAmountIn,
        uint256 tokenAmountOut
    );

    event LOG_JOIN(
        address indexed tokenIn,
        address indexed caller,
        uint256 tokenAmountIn
    );

    event LOG_EXIT(
        address indexed caller,
        address indexed tokenOut,
        uint256 tokenAmountOut
    );

    event LOG_DENORM_UPDATED(address indexed token, uint256 newDenorm);

    event LOG_DESIRED_DENORM_SET(address indexed token, uint256 desiredDenorm);

    event LOG_MINIMUM_BALANCE_UPDATED(address token, uint256 minimumBalance);

    event LOG_TOKEN_READY(address indexed token);

    event LOG_PUBLIC_SWAP_TOGGLED(bool enabled);

    function initialize(
        address[] calldata tokens,
        uint256[] calldata balances,
        address tokenProvider
    ) external;

    function joinDynaset(uint256 _amount) external returns (uint256);

    function exitDynaset(uint256 _amount) external;

    function getController() external view returns (address);

    function isBound(address t) external view returns (bool);

    function getNumTokens() external view returns (uint256);

    function getCurrentTokens() external view returns (address[] memory tokens);

    function getTokenRecord(address token)
        external
        view
        returns (Record memory record);

    function getBalance(address token) external view returns (uint256);

    function setDynasetOracle(address oracle) external;
    
    function withdrawFee(address token, uint256 amount) external;

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/* ========== Internal Inheritance ========== */
import {DToken} from "./DToken.sol";

/* ========== Internal Interfaces ========== */
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IDynasetContract.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IDynasetTvlOracle.sol";
import "./balancer/BNum.sol";

/************************************************************************************************
Originally from https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash f4ed5d65362a8d6cec21662fb6eae233b0babc1f.

Subject to the GPL-3.0 license 
*************************************************************************************************/
abstract contract AbstractDynaset is DToken, BNum, IDynasetContract, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /* ==========  Storage  ========== */

    // Account with CONTROL role.
    // set mint/burn forges.
    address internal controller;

    address internal factory;

    address internal digitalAssetManager;

    mapping(address => bool) internal mintForges;
    mapping(address => bool) internal burnForges;
    // Array of underlying tokens in the dynaset.
    address[] internal dynasetTokens;
    // Internal records of the dynaset's underlying tokens
    mapping(address => Record) internal records;
    address internal dynasetTvlOracle;

    /* ==========  Events  ========== */

    event LogTokenAdded(address indexed tokenIn, address indexed provider);
    event LogTokenRemoved(address indexed tokenOut);
    event DynasetInitialized(
        address[] indexed tokens,
        uint256[] balances,
        address indexed tokenProvider
    );
    event MintForge(address indexed forgeAddress);
    event BurnForge(address indexed forgeAddress);
    event WithdrawalFee(address token, uint256 indexed amount);

    /* ==========  Access Modifiers (changed to internal functions to decrease contract size)  ========== */

    function onlyFactory() internal view {
        require(msg.sender == factory, "ERR_NOT_FACTORY");
    }

    function onlyController() internal view {
        require(msg.sender == controller, "ERR_NOT_CONTROLLER");
    }

    function onlyDigitalAssetManager() internal view {
        require(msg.sender == digitalAssetManager, "ERR_NOT_DAM");
    }

    /* ==========  Constructor  ========== */
    constructor(
        address factoryContract,
        address dam,
        address controller_,
        string memory name,
        string memory symbol
    ) {
        require(
            factoryContract != address(0) &&
                dam != address(0) &&
                controller_ != address(0),
            "ERR_ZERO_ADDRESS"
        );
        factory = factoryContract;
        controller = controller_;
        digitalAssetManager = dam;
        _initializeToken(name, symbol);
    }

    /* ==========  External Functions  ========== */
    /**
     * @dev Sets up the initial assets for the pool.
     *
     * Note: `tokenProvider` must have approved the pool to transfer the
     * corresponding `balances` of `tokens`.
     *
     * @param tokens Underlying tokens to initialize the pool with
     * @param balances Initial balances to transfer
     * @param tokenProvider Address to transfer the balances from
     */
    function initialize(
        address[] calldata tokens,
        uint256[] calldata balances,
        address tokenProvider
    ) external nonReentrant override {
        onlyFactory();
        require(dynasetTokens.length == 0, "ERR_INITIALIZED");
        require(tokenProvider != address(0), "INVALID_TOKEN_PROVIDER");
        uint256 len = tokens.length;
        require(len >= MIN_BOUND_TOKENS, "ERR_MIN_TOKENS");
        require(len <= MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");
        _mint(INIT_POOL_SUPPLY);
        address token;
        uint256 balance;
        for (uint256 i = 0; i < len; i++) {
            token = tokens[i];
            require(token != address(0), "INVALID_TOKEN");
            balance = balances[i];
            require(balance > 0, "ERR_MIN_BALANCE");
            records[token] = Record({
                bound: true,
                ready: true,
                index: uint8(i),
                balance: balance
            });

            dynasetTokens.push(token);
            // ! external interaction
            _pullUnderlying(token, tokenProvider, balance);
        }
        _push(tokenProvider, INIT_POOL_SUPPLY);
        emit DynasetInitialized(tokens, balances, tokenProvider);
    }

    function addToken(
        address token,
        uint256 minimumBalance,
        address tokenProvider
    ) external nonReentrant {
        onlyDigitalAssetManager();
        require(token != address(0), "ERR_ZERO_TOKEN");
        require(dynasetTokens.length < MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");
        require(tokenProvider != address(0), "ERR_ZERO_TOKEN_PROVIDER");
        require(!records[token].bound, "ERR_IS_BOUND");
        require(minimumBalance > 0, "ERR_MIN_BALANCE");
        require(
            IERC20(token).allowance(address(tokenProvider), address(this)) >=
                minimumBalance,
            "ERR_INSUFFICIENT_ALLOWANCE"
        );
        records[token] = Record({
            bound: true,
            ready: true,
            index: uint8(dynasetTokens.length),
            balance: minimumBalance
        });
        dynasetTokens.push(token);
        _pullUnderlying(token, tokenProvider, minimumBalance);
        emit LogTokenAdded(token, tokenProvider);
    }

    function removeToken(address token) external nonReentrant {
        onlyDigitalAssetManager();
        require(dynasetTokens.length > MIN_BOUND_TOKENS, "ERR_MIN_TOKENS");
        Record memory record = records[token];
        uint256 tokenBalance = record.balance;
        require(tokenBalance == 0, "ERR_CAN_NOT_REMOVE_TOKEN");
        // Swap the token-to-unbind with the last token,
        // then delete the last token
        uint256 index = record.index;
        uint256 last = dynasetTokens.length - 1;
        // Only swap the token with the last token if it is not
        // already at the end of the array.
        if (index != last) {
            dynasetTokens[index] = dynasetTokens[last];
            records[dynasetTokens[index]].index = uint8(index);
            records[dynasetTokens[index]].balance = records[dynasetTokens[last]]
                .balance;
        }
        dynasetTokens.pop();
        records[token] = Record({
            bound: false,
            ready: false,
            index: 0,
            balance: 0
        });
        emit LogTokenRemoved(token);
    }

    function setMintForge(address newMintForge) external {
        onlyController();
        require(!mintForges[newMintForge], "ERR_FORGE_ALREADY_ADDED");
        mintForges[newMintForge] = true;
        emit MintForge(newMintForge);
    }

    function setBurnForge(address newBurnForge) external {
        onlyController();
        require(!burnForges[newBurnForge], "ERR_FORGE_ALREADY_ADDED");
        burnForges[newBurnForge] = true;
        emit BurnForge(newBurnForge);
    }

    function setDynasetOracle(address oracleAddress) external {
        onlyFactory();
        dynasetTvlOracle = oracleAddress;
    }

    /**
    NOTE The function can only be called using dynaset factory contract.
    * It is made sure that fee is not taken too frequently or 
    * not more than 25% more details can be found in DynasetFactory contract 
    * collectFee funciton.
    */
    function withdrawFee(address token, uint256 amount) external {
        onlyFactory();
        IERC20 token_ = IERC20(token);
        token_.safeTransfer(msg.sender, amount);
        emit WithdrawalFee(token, amount);
    }

    /**
     *
     * @param amount is number of dynaset amount
     * @return tokens returns the tokens list in the dynasets and
     * their respective @return amounts which combines make same
     * usd value as the amount of dynasets
     */
    function calcTokensForAmount(uint256 amount)
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        uint256 dynasetTotal = totalSupply();
        uint256 ratio = bdiv(amount, dynasetTotal);
        require(ratio != 0, "ERR_MATH_APPROX");
        tokens = dynasetTokens;
        amounts = new uint256[](dynasetTokens.length);
        uint256 tokenAmountIn;
        for (uint256 i = 0; i < dynasetTokens.length; i++) {
            (Record memory record, ) = _getInputToken(tokens[i]);
            tokenAmountIn = bmul(ratio, record.balance);
            amounts[i] = tokenAmountIn;
        }
    }

    function getTokenAmounts()
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        tokens = dynasetTokens;
        amounts = new uint256[](dynasetTokens.length);
        for (uint256 i = 0; i < dynasetTokens.length; i++) {
            amounts[i] = records[tokens[i]].balance;
        }
    }

    /**
     * @dev Returns the controller address.
     */
    function getController() external view override returns (address) {
        return controller;
    }

    /**
     * @dev Check if a token is bound to the dynaset.
     */
    function isBound(address token) external view override returns (bool) {
        return records[token].bound;
    }

    /**
     * @dev Get the number of tokens bound to the dynaset.
     */
    function getNumTokens() external view override returns (uint256) {
        return dynasetTokens.length;
    }

    /**
     * @dev Returns the record for a token bound to the dynaset.
     */
    function getTokenRecord(address token)
        external
        view
        override
        returns (Record memory record)
    {
        record = records[token];
        require(record.bound, "ERR_NOT_BOUND");
    }

    /**
     * @dev Returns the stored balance of a bound token.
     */
    function getBalance(address token)
        external
        view
        override
        returns (uint256)
    {
        Record memory record = records[token];
        require(record.bound, "ERR_NOT_BOUND");
        return record.balance;
    }

    /**
     * @dev Get all bound tokens.
     */
    function getCurrentTokens()
        external
        view
        override
        returns (address[] memory tokens)
    {
        tokens = dynasetTokens;
    }

    /* ==========  Public Functions  ========== */
    /**
     * @dev Absorb any tokens that have been sent to the dynaset.
     * If the token is not bound, it will be sent to the unbound
     * token handler.
     */
    function updateAfterSwap(address tokenIn, address tokenOut) public {
        uint256 balanceIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 balanceOut = IERC20(tokenOut).balanceOf(address(this));

        records[tokenIn].balance = balanceIn;
        records[tokenOut].balance = balanceOut;
    }

    /*
     * @dev Mint new dynaset tokens by providing the proportional amount of each
     * underlying token's balance relative to the proportion of dynaset tokens minted.
     *
     * NOTE: function can only be called by the forge contracts and min/max amounts checks are
     * implemented in forge contracts.
     * For any underlying tokens which are not initialized, the caller must provide
     * the proportional share of the minimum balance for the token rather than the
     * actual balance.
     *
     * @param dynasetAmountOut Amount of dynaset tokens to mint
     * order as the dynaset's dynasetTokens list.
     */
    function joinDynaset(uint256 expectedSharesToMint)
        external
        override
        nonReentrant
        returns (uint256 sharesToMint)
    {
        require(mintForges[msg.sender], "ERR_NOT_FORGE");
        require(dynasetTvlOracle != address(0), "ERR_DYNASET_ORACLE_NOT_SET");
        sharesToMint = expectedSharesToMint;
        uint256 dynasetTotal = totalSupply();
        uint256 ratio = bdiv(sharesToMint, dynasetTotal);
        require(ratio != 0, "ERR_MATH_APPROX");
        uint256 tokenAmountIn;
        address token;
        uint256 dynaset_usd_value_before_join = IDynasetTvlOracle(dynasetTvlOracle).dynasetTvlUsdc();
        for (uint256 i = 0; i < dynasetTokens.length; i++) {
            token = dynasetTokens[i];
            (, uint256 realBalance) = _getInputToken(token);
            tokenAmountIn = bmul(ratio, realBalance);
            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            uint256 forgeTokenBalance = IERC20(token).balanceOf(msg.sender);
            if (forgeTokenBalance < tokenAmountIn) {
                tokenAmountIn = forgeTokenBalance;
            }
            uint256 forgeTokenAllowance = IERC20(token).allowance(msg.sender, address(this));
            if (forgeTokenAllowance < tokenAmountIn) {
               tokenAmountIn = forgeTokenAllowance;
            }
            _updateInputToken(token, badd(realBalance, tokenAmountIn));
            _pullUnderlying(token, msg.sender, tokenAmountIn);
            emit LOG_JOIN(token, msg.sender, tokenAmountIn);
        }
        // calculate correct sharesToMint
        uint256 dynaset_added_value = IDynasetTvlOracle(dynasetTvlOracle).dynasetTvlUsdc() 
                                      - dynaset_usd_value_before_join;
        sharesToMint = dynaset_added_value * dynasetTotal / dynaset_usd_value_before_join;
        require(sharesToMint > 0, "MINT_ZERO_DYNASETS");
        _mint(sharesToMint);
        _push(msg.sender, sharesToMint);
    }

    /**
     * @dev Burns `_amount` dynaset tokens in exchange for the amounts of each
     * underlying token's balance proportional to the ratio of tokens burned to
     * total dynaset supply.
     *
     * @param dynasetAmountIn Exact amount of dynaset tokens to burn
     */
    function exitDynaset(uint256 dynasetAmountIn)
        external
        override
        nonReentrant
    {
        require(burnForges[msg.sender], "ERR_NOT_FORGE");
        uint256 dynasetTotal = totalSupply();
        uint256 ratio = bdiv(dynasetAmountIn, dynasetTotal);
        require(ratio != 0, "ERR_MATH_APPROX");
        _pull(msg.sender, dynasetAmountIn);
        _burn(dynasetAmountIn);
        address token;
        Record memory record;
        uint256 tokenAmountOut;
        for (uint256 i = 0; i < dynasetTokens.length; i++) {
            token = dynasetTokens[i];
            record = records[token];
            require(record.ready, "ERR_OUT_NOT_READY");
            tokenAmountOut = bmul(ratio, record.balance);
            require(tokenAmountOut != 0, "ERR_MATH_APPROX");

            records[token].balance = bsub(record.balance, tokenAmountOut);
            _pushUnderlying(token, msg.sender, tokenAmountOut);
            emit LOG_EXIT(msg.sender, token, tokenAmountOut);
        }
    }

    /* ==========  Underlying Token Internal Functions  ========== */
    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    function _pullUnderlying(
        address erc20,
        address from,
        uint256 amount
    ) internal {
        IERC20(erc20).safeTransferFrom(from, address(this), amount);
    }

    function _pushUnderlying(
        address erc20,
        address to,
        uint256 amount
    ) internal {
        IERC20(erc20).safeTransfer(to, amount);
    }

    /* ==========  Token Management Internal Functions  ========== */

    /**
     * @dev Handles weight changes and initialization of an
     * input token.
     * @param token Address of the input token
     * @param realBalance real balance is set to the records for token
     * and weight if the token was uninitialized.
     */
    function _updateInputToken(address token, uint256 realBalance) internal {
        records[token].balance = realBalance;
    }

    /* ==========  Token Query Internal Functions  ========== */

    /**
     * @dev Get the record for a token.
     * The token must be bound to the dynaset. If the token is not
     * initialized (meaning it does not have the minimum balance)
     * this function will return the actual balance of the token
     */
    function _getInputToken(address token)
        internal
        view
        returns (Record memory record, uint256 realBalance)
    {
        record = records[token];
        require(record.bound, "ERR_NOT_BOUND");
        realBalance = record.balance;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "./interfaces/IERC20.sol";

/************************************************************************************************
Originally from https://github.com/balancer-labs/balancer-core/blob/master/contracts/BToken.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash f4ed5d65362a8d6cec21662fb6eae233b0babc1f.

Subject to the GPL-3.0 license
*************************************************************************************************/

contract DTokenBase {
    mapping(address => uint256) internal _balance;
    mapping(address => mapping(address => uint256)) internal _allowance;
    uint256 internal _totalSupply;

    event Transfer(address indexed src, address indexed dst, uint256 amt);

    function _mint(uint256 amt) internal {
        _balance[address(this)] = (_balance[address(this)] + amt);
        _totalSupply = (_totalSupply + amt);
        emit Transfer(address(0), address(this), amt);
    }

    function _burn(uint256 amt) internal {
        require(_balance[address(this)] >= amt, "ERR_INSUFFICIENT_BAL");
        _balance[address(this)] = (_balance[address(this)] - amt);
        _totalSupply = (_totalSupply - amt);
        emit Transfer(address(this), address(0), amt);
    }

    function _move(
        address src,
        address dst,
        uint256 amt
    ) internal {
        require(_balance[src] >= amt, "ERR_INSUFFICIENT_BAL");
        _balance[src] = (_balance[src] - amt);
        _balance[dst] = (_balance[dst] + amt);
        emit Transfer(src, dst, amt);
    }

    function _push(address to, uint256 amt) internal {
        _move(address(this), to, amt);
    }

    function _pull(address from, uint256 amt) internal {
        _move(from, address(this), amt);
    }
}

contract DToken is DTokenBase, IERC20 {
    uint8 private constant DECIMALS = 18;
    string private _name;
    string private _symbol;

    function _initializeToken(string memory name_, string memory symbol_)
        internal
    {
        require(
            bytes(_name).length == 0 &&
                bytes(name_).length != 0 &&
                bytes(symbol_).length != 0,
            "ERR_BTOKEN_INITIALIZED"
        );
        _name = name_;
        _symbol = symbol_;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    function allowance(address src, address dst)
        external
        view
        override
        returns (uint256)
    {
        return _allowance[src][dst];
    }

    function balanceOf(address whom) external view override returns (uint256) {
        return _balance[whom];
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function approve(address dst, uint256 amt)
        external
        override
        returns (bool)
    {
        _allowance[msg.sender][dst] = amt;
        emit Approval(msg.sender, dst, amt);
        return true;
    }

    function increaseApproval(address dst, uint256 amt)
        external
        returns (bool)
    {
        _allowance[msg.sender][dst] = (_allowance[msg.sender][dst] + amt);
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function decreaseApproval(address dst, uint256 amt)
        external
        returns (bool)
    {
        uint256 oldValue = _allowance[msg.sender][dst];
        if (amt > oldValue) {
            _allowance[msg.sender][dst] = 0;
        } else {
            _allowance[msg.sender][dst] = (oldValue - amt);
        }
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function transfer(address dst, uint256 amt)
        external
        override
        returns (bool)
    {
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external override returns (bool) {
        require(
            msg.sender == src || amt <= _allowance[src][msg.sender],
            "ERR_BTOKEN_BAD_CALLER"
        );
        _move(src, dst, amt);
        if (
            msg.sender != src &&
            _allowance[src][msg.sender] != type(uint128).max
        ) {
            _allowance[src][msg.sender] = (_allowance[src][msg.sender] - amt);
            emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        //amount of tokens we are sending in
        uint256 amountIn,
        //the minimum amount of tokens we want out of the trade
        uint256 amountOutMin,
        //list of token addresses we are going to trade in.  this is necessary to calculate amounts
        address[] calldata path,
        //this is the address we are going to send the output tokens to
        address to,
        //the last time that the trade is valid for
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "./BConst.sol";

/************************************************************************************************
Originally from https://github.com/balancer-labs/balancer-core/blob/master/contracts/BNum.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash f4ed5d65362a8d6cec21662fb6eae233b0babc1f.

Subject to the GPL-3.0 license
*************************************************************************************************/

contract BNum is BConst {
    function btoi(uint256 a) internal pure returns (uint256) {
        return a / BONE;
    }

    function bfloor(uint256 a) internal pure returns (uint256) {
        return btoi(a) * BONE;
    }

    function badd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
        (uint256 c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint256 a, uint256 b)
        internal
        pure
        returns (uint256, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint256 c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint256 c2 = c1 / BONE;
        return c2;
    }

    function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ERR_DIV_ZERO");
        uint256 c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint256 c2 = c1 / b;
        return c2;
    }

    // DSMath.wpow
    function bpowi(uint256 a, uint256 n) internal pure returns (uint256) {
        uint256 z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
        return z;
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `bpowi` for `b^e` and `bpowK` for k iterations
    // of approximation of b^0.w
    function bpow(uint256 base, uint256 exp) internal pure returns (uint256) {
        require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint256 whole = bfloor(exp);
        uint256 remain = bsub(exp, whole);

        uint256 wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint256 partialResult = bpowApprox(base, remain, BPOW_PRECISION);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(
        uint256 base,
        uint256 exp,
        uint256 precision
    ) internal pure returns (uint256) {
        // term 0:
        uint256 a = exp;
        (uint256 x, bool xneg) = bsubSign(base, BONE);
        uint256 term = BONE;
        uint256 sum = term;
        bool negative = false;

        // term(k) = numer / denom
        //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint256 i = 1; term >= precision; i++) {
            uint256 bigK = i * BONE;
            (uint256 c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = bsub(sum, term);
            } else {
                sum = badd(sum, term);
            }
        }

        return sum;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IDynasetTvlOracle {
    function dynasetTvlUsdc() external view returns (uint256 total_usd);

    function tokenUsdcValue(address _tokenIn, uint256 _amount) external view returns (uint256);

    function dynasetUsdcValuePerShare() external view returns (uint256);

    function dynasetTokenUsdcRatios() external view returns (address[] memory, uint256[] memory, uint256);
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IERC20 {
    event Approval(address indexed _src, address indexed _dst, uint256 _amount);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _whom) external view returns (uint256);

    function allowance(address _src, address _dst)
        external
        view
        returns (uint256);

    function approve(address _dst, uint256 _amount) external returns (bool);

    function transfer(address _dst, uint256 _amount) external returns (bool);

    function transferFrom(
        address _src,
        address _dst,
        uint256 _amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/************************************************************************************************
Originally from https://github.com/balancer-labs/balancer-core/blob/master/contracts/BConst.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash f4ed5d65362a8d6cec21662fb6eae233b0babc1f.

Subject to the GPL-3.0 license
*************************************************************************************************/

contract BConst {
    uint256 public constant VERSION_NUMBER = 1;

    /* ---  Weight Updates  --- */

    // Minimum time passed between each weight update for a token.
    uint256 internal constant WEIGHT_UPDATE_DELAY = 1 hours;

    // Maximum percent by which a weight can adjust at a time
    // relative to the current weight.
    // The number of iterations needed to move from weight A to weight B is the floor of:
    // (A > B): (ln(A) - ln(B)) / ln(1.01)
    // (B > A): (ln(A) - ln(B)) / ln(0.99)
    uint256 internal constant WEIGHT_CHANGE_PCT = BONE / 100;

    uint256 internal constant BONE = 10**18;

    uint256 internal constant MIN_BOUND_TOKENS = 2;
    uint256 internal constant MAX_BOUND_TOKENS = 20;
    // Minimum swap fee.
    uint256 internal constant MIN_FEE = BONE / 10**6;
    // Maximum swap or exit fee.
    uint256 internal constant MAX_FEE = BONE / 10;
    // Actual exit fee.
    uint256 internal constant EXIT_FEE = 5e15;

    // Minimum weight for any token (1/100).
    uint256 internal constant MIN_WEIGHT = BONE;
    uint256 internal constant MAX_WEIGHT = BONE * 50;
    // Maximum total weight.
    uint256 internal constant MAX_TOTAL_WEIGHT = BONE * 50;
    // Minimum balance for a token (only applied at initialization)
    // uint256 internal constant MIN_BALANCE = BONE / 10**12;
    // Initial pool tokens
    uint256 internal constant INIT_POOL_SUPPLY = BONE * 100;

    uint256 internal constant MIN_BPOW_BASE = 1 wei;
    uint256 internal constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
    uint256 internal constant BPOW_PRECISION = BONE / 10**10;

    // Maximum ratio of input tokens to balance for swaps.
    uint256 internal constant MAX_IN_RATIO = BONE / 2;
    // Maximum ratio of output tokens to balance for swaps.
    uint256 internal constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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