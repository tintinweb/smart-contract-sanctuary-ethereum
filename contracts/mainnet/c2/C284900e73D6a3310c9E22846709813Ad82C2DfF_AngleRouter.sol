// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IFeeDistributor.sol";
import "../interfaces/ILiquidityGauge.sol";
import "../interfaces/ISanToken.sol";
import "../interfaces/IStableMaster.sol";
import "../interfaces/IStableMasterFront.sol";
import "../interfaces/IVeANGLE.sol";
import "../interfaces/external/IWETH9.sol";
import "../interfaces/external/uniswap/IUniswapRouter.sol";

/// @title Angle Router
/// @author Angle Core Team
/// @notice The `AngleRouter` contract facilitates interactions for users with the protocol. It was built to reduce the number
/// of approvals required to users and the number of transactions needed to perform some complex actions: like deposit and stake
/// in just one transaction
/// @dev Interfaces were designed for both advanced users which know the addresses of the protocol's contract, but most of the time
/// users which only know addresses of the stablecoins and collateral types of the protocol can perform the actions they want without
/// needing to understand what's happening under the hood
contract AngleRouter is Initializable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    /// @notice Base used for params
    uint256 public constant BASE_PARAMS = 10**9;

    /// @notice Base used for params
    uint256 private constant _MAX_TOKENS = 10;
    // @notice Wrapped ETH contract
    IWETH9 public constant WETH9 = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // @notice ANGLE contract
    IERC20 public constant ANGLE = IERC20(0x31429d1856aD1377A8A0079410B297e1a9e214c2);
    // @notice veANGLE contract
    IVeANGLE public constant VEANGLE = IVeANGLE(0x0C462Dbb9EC8cD1630f1728B2CFD2769d09f0dd5);

    // =========================== Structs and Enums ===============================

    /// @notice Action types
    enum ActionType {
        claimRewards,
        claimWeeklyInterest,
        gaugeDeposit,
        withdraw,
        mint,
        deposit,
        openPerpetual,
        addToPerpetual,
        veANGLEDeposit
    }

    /// @notice All possible swaps
    enum SwapType {
        UniswapV3,
        oneINCH
    }

    /// @notice Params for swaps
    /// @param inToken Token to swap
    /// @param collateral Token to swap for
    /// @param amountIn Amount of token to sell
    /// @param minAmountOut Minimum amount of collateral to receive for the swap to not revert
    /// @param args Either the path for Uniswap or the payload for 1Inch
    /// @param swapType Which swap route to take
    struct ParamsSwapType {
        IERC20 inToken;
        address collateral;
        uint256 amountIn;
        uint256 minAmountOut;
        bytes args;
        SwapType swapType;
    }

    /// @notice Params for direct collateral transfer
    /// @param inToken Token to transfer
    /// @param amountIn Amount of token transfer
    struct TransferType {
        IERC20 inToken;
        uint256 amountIn;
    }

    /// @notice References to the contracts associated to a collateral for a stablecoin
    struct Pairs {
        IPoolManager poolManager;
        IPerpetualManagerFrontWithClaim perpetualManager;
        ISanToken sanToken;
        ILiquidityGauge gauge;
    }

    /// @notice Data needed to get permits
    struct PermitType {
        address token;
        address owner;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // =============================== Events ======================================

    event AdminChanged(address indexed admin, bool setGovernor);
    event StablecoinAdded(address indexed stableMaster);
    event StablecoinRemoved(address indexed stableMaster);
    event CollateralToggled(address indexed stableMaster, address indexed poolManager, address indexed liquidityGauge);
    event SanTokenLiquidityGaugeUpdated(address indexed sanToken, address indexed newLiquidityGauge);
    event Recovered(address indexed tokenAddress, address indexed to, uint256 amount);

    // =============================== Mappings ====================================

    /// @notice Maps an agToken to its counterpart `StableMaster`
    mapping(IERC20 => IStableMasterFront) public mapStableMasters;
    /// @notice Maps a `StableMaster` to a mapping of collateral token to its counterpart `PoolManager`
    mapping(IStableMasterFront => mapping(IERC20 => Pairs)) public mapPoolManagers;
    /// @notice Whether the token was already approved on Uniswap router
    mapping(IERC20 => bool) public uniAllowedToken;
    /// @notice Whether the token was already approved on 1Inch
    mapping(IERC20 => bool) public oneInchAllowedToken;

    // =============================== References ==================================

    /// @notice Governor address
    address public governor;
    /// @notice Guardian address
    address public guardian;
    /// @notice Address of the router used for swaps
    IUniswapV3Router public uniswapV3Router;
    /// @notice Address of 1Inch router used for swaps
    address public oneInch;

    uint256[50] private __gap;

    constructor() initializer {}

    /// @notice Deploys the `AngleRouter` contract
    /// @param _governor Governor address
    /// @param _guardian Guardian address
    /// @param _uniswapV3Router UniswapV3 router address
    /// @param _oneInch 1Inch aggregator address
    /// @param existingStableMaster Address of the existing `StableMaster`
    /// @param existingPoolManagers Addresses of the associated poolManagers
    /// @param existingLiquidityGauges Addresses of liquidity gauge contracts associated to sanTokens
    /// @dev Be cautious with safe approvals, all tokens will have unlimited approvals within the protocol or
    /// UniswapV3 and 1Inch
    function initialize(
        address _governor,
        address _guardian,
        IUniswapV3Router _uniswapV3Router,
        address _oneInch,
        IStableMasterFront existingStableMaster,
        IPoolManager[] calldata existingPoolManagers,
        ILiquidityGauge[] calldata existingLiquidityGauges
    ) public initializer {
        // Checking the parameters passed
        require(
            address(_uniswapV3Router) != address(0) &&
                _oneInch != address(0) &&
                _governor != address(0) &&
                _guardian != address(0),
            "0"
        );
        require(_governor != _guardian, "49");
        require(existingPoolManagers.length == existingLiquidityGauges.length, "104");
        // Fetching the stablecoin and mapping it to the `StableMaster`
        mapStableMasters[
            IERC20(address(IStableMaster(address(existingStableMaster)).agToken()))
        ] = existingStableMaster;
        // Setting roles
        governor = _governor;
        guardian = _guardian;
        uniswapV3Router = _uniswapV3Router;
        oneInch = _oneInch;

        // for veANGLEDeposit action
        ANGLE.safeApprove(address(VEANGLE), type(uint256).max);

        for (uint256 i = 0; i < existingPoolManagers.length; i++) {
            _addPair(existingStableMaster, existingPoolManagers[i], existingLiquidityGauges[i]);
        }
    }

    // ============================== Modifiers ====================================

    /// @notice Checks to see if it is the `governor` or `guardian` calling this contract
    /// @dev There is no Access Control here, because it can be handled cheaply through this modifier
    /// @dev In this contract, the `governor` and the `guardian` address have exactly similar rights
    modifier onlyGovernorOrGuardian() {
        require(msg.sender == governor || msg.sender == guardian, "115");
        _;
    }

    // =========================== Governance utilities ============================

    /// @notice Changes the guardian or the governor address
    /// @param admin New guardian or guardian address
    /// @param setGovernor Whether to set Governor if true, or Guardian if false
    /// @dev There can only be one guardian and one governor address in the router
    /// and both need to be different
    function setGovernorOrGuardian(address admin, bool setGovernor) external onlyGovernorOrGuardian {
        require(admin != address(0), "0");
        require(guardian != admin && governor != admin, "49");
        if (setGovernor) governor = admin;
        else guardian = admin;
        emit AdminChanged(admin, setGovernor);
    }

    /// @notice Adds a new `StableMaster`
    /// @param stablecoin Address of the new stablecoin
    /// @param stableMaster Address of the new `StableMaster`
    function addStableMaster(IERC20 stablecoin, IStableMasterFront stableMaster) external onlyGovernorOrGuardian {
        // No need to check if the `stableMaster` address is a zero address as otherwise the call to `stableMaster.agToken()`
        // would revert
        require(address(stablecoin) != address(0), "0");
        require(address(mapStableMasters[stablecoin]) == address(0), "114");
        require(stableMaster.agToken() == address(stablecoin), "20");
        mapStableMasters[stablecoin] = stableMaster;
        emit StablecoinAdded(address(stableMaster));
    }

    /// @notice Removes a `StableMaster`
    /// @param stablecoin Address of the associated stablecoin
    /// @dev Before calling this function, governor or guardian should remove first all pairs
    /// from the `mapPoolManagers[stableMaster]`. It is assumed that the governor or guardian calling this function
    /// will act correctly here, it indeed avoids storing a list of all pairs for each `StableMaster`
    function removeStableMaster(IERC20 stablecoin) external onlyGovernorOrGuardian {
        IStableMasterFront stableMaster = mapStableMasters[stablecoin];
        delete mapStableMasters[stablecoin];
        emit StablecoinRemoved(address(stableMaster));
    }

    /// @notice Adds new collateral types to specific stablecoins
    /// @param stablecoins Addresses of the stablecoins associated to the `StableMaster` of interest
    /// @param poolManagers Addresses of the `PoolManager` contracts associated to the pair (stablecoin,collateral)
    /// @param liquidityGauges Addresses of liquidity gauges contract associated to sanToken
    function addPairs(
        IERC20[] calldata stablecoins,
        IPoolManager[] calldata poolManagers,
        ILiquidityGauge[] calldata liquidityGauges
    ) external onlyGovernorOrGuardian {
        require(poolManagers.length == stablecoins.length && liquidityGauges.length == stablecoins.length, "104");
        for (uint256 i = 0; i < stablecoins.length; i++) {
            IStableMasterFront stableMaster = mapStableMasters[stablecoins[i]];
            _addPair(stableMaster, poolManagers[i], liquidityGauges[i]);
        }
    }

    /// @notice Removes collateral types from specific `StableMaster` contracts using the address
    /// of the associated stablecoins
    /// @param stablecoins Addresses of the stablecoins
    /// @param collaterals Addresses of the collaterals
    /// @param stableMasters List of the associated `StableMaster` contracts
    /// @dev In the lists, if a `stableMaster` address is null in `stableMasters` then this means that the associated
    /// `stablecoins` address (at the same index) should be non null
    function removePairs(
        IERC20[] calldata stablecoins,
        IERC20[] calldata collaterals,
        IStableMasterFront[] calldata stableMasters
    ) external onlyGovernorOrGuardian {
        require(collaterals.length == stablecoins.length && stableMasters.length == collaterals.length, "104");
        Pairs memory pairs;
        IStableMasterFront stableMaster;
        for (uint256 i = 0; i < stablecoins.length; i++) {
            if (address(stableMasters[i]) == address(0))
                // In this case `collaterals[i]` is a collateral address
                (stableMaster, pairs) = _getInternalContracts(stablecoins[i], collaterals[i]);
            else {
                // In this case `collaterals[i]` is a `PoolManager` address
                stableMaster = stableMasters[i];
                pairs = mapPoolManagers[stableMaster][collaterals[i]];
            }
            delete mapPoolManagers[stableMaster][collaterals[i]];
            _changeAllowance(collaterals[i], address(stableMaster), 0);
            _changeAllowance(collaterals[i], address(pairs.perpetualManager), 0);
            if (address(pairs.gauge) != address(0)) pairs.sanToken.approve(address(pairs.gauge), 0);
            emit CollateralToggled(address(stableMaster), address(pairs.poolManager), address(pairs.gauge));
        }
    }

    /// @notice Sets new `liquidityGauge` contract for the associated sanTokens
    /// @param stablecoins Addresses of the stablecoins
    /// @param collaterals Addresses of the collaterals
    /// @param newLiquidityGauges Addresses of the new liquidity gauges contract
    /// @dev If `newLiquidityGauge` is null, this means that there is no liquidity gauge for this pair
    /// @dev This function could be used to simply revoke the approval to a liquidity gauge
    function setLiquidityGauges(
        IERC20[] calldata stablecoins,
        IERC20[] calldata collaterals,
        ILiquidityGauge[] calldata newLiquidityGauges
    ) external onlyGovernorOrGuardian {
        require(collaterals.length == stablecoins.length && newLiquidityGauges.length == stablecoins.length, "104");
        for (uint256 i = 0; i < stablecoins.length; i++) {
            IStableMasterFront stableMaster = mapStableMasters[stablecoins[i]];
            Pairs storage pairs = mapPoolManagers[stableMaster][collaterals[i]];
            ILiquidityGauge gauge = pairs.gauge;
            ISanToken sanToken = pairs.sanToken;
            require(address(stableMaster) != address(0) && address(pairs.poolManager) != address(0), "0");
            pairs.gauge = newLiquidityGauges[i];
            if (address(gauge) != address(0)) {
                sanToken.approve(address(gauge), 0);
            }
            if (address(newLiquidityGauges[i]) != address(0)) {
                // Checking compatibility of the staking token: it should be the sanToken
                require(address(newLiquidityGauges[i].staking_token()) == address(sanToken), "20");
                sanToken.approve(address(newLiquidityGauges[i]), type(uint256).max);
            }
            emit SanTokenLiquidityGaugeUpdated(address(sanToken), address(newLiquidityGauges[i]));
        }
    }

    /// @notice Change allowance for a contract.
    /// @param tokens Addresses of the tokens to allow
    /// @param spenders Addresses to allow transfer
    /// @param amounts Amounts to allow
    /// @dev Approvals are normally given in the `addGauges` method, in the initializer and in
    /// the internal functions to process swaps with Uniswap and 1Inch
    function changeAllowance(
        IERC20[] calldata tokens,
        address[] calldata spenders,
        uint256[] calldata amounts
    ) external onlyGovernorOrGuardian {
        require(tokens.length == spenders.length && tokens.length == amounts.length, "104");
        for (uint256 i = 0; i < tokens.length; i++) {
            _changeAllowance(tokens[i], spenders[i], amounts[i]);
        }
    }

    /// @notice Supports recovering any tokens as the router does not own any other tokens than
    /// the one mistakenly sent
    /// @param tokenAddress Address of the token to transfer
    /// @param to Address to give tokens to
    /// @param tokenAmount Amount of tokens to transfer
    /// @dev If tokens are mistakenly sent to this contract, any address can take advantage of the `mixer` function
    /// below to get the funds back
    function recoverERC20(
        address tokenAddress,
        address to,
        uint256 tokenAmount
    ) external onlyGovernorOrGuardian {
        IERC20(tokenAddress).safeTransfer(to, tokenAmount);
        emit Recovered(tokenAddress, to, tokenAmount);
    }

    // =========================== Router Functionalities =========================

    /// @notice Wrapper n°1 built on top of the _claimRewards function
    /// Allows to claim rewards for multiple gauges and perpetuals at once
    /// @param gaugeUser Address for which to fetch the rewards from the gauges
    /// @param liquidityGauges Gauges to claim on
    /// @param perpetualIDs Perpetual IDs to claim rewards for
    /// @param stablecoins Stablecoin contracts linked to the perpetualsIDs
    /// @param collaterals Collateral contracts linked to the perpetualsIDs or `perpetualManager`
    /// @dev If the caller wants to send the rewards to another account it first needs to
    /// call `set_rewards_receiver(otherAccount)` on each `liquidityGauge`
    function claimRewards(
        address gaugeUser,
        address[] memory liquidityGauges,
        uint256[] memory perpetualIDs,
        address[] memory stablecoins,
        address[] memory collaterals
    ) external nonReentrant {
        _claimRewards(gaugeUser, liquidityGauges, perpetualIDs, false, stablecoins, collaterals);
    }

    /// @notice Wrapper n°2 (a little more gas efficient than n°1) built on top of the _claimRewards function
    /// Allows to claim rewards for multiple gauges and perpetuals at once
    /// @param user Address to which the contract should send the rewards from gauges (not perpetuals)
    /// @param liquidityGauges Contracts to claim for
    /// @param perpetualIDs Perpetual IDs to claim rewards for
    /// @param perpetualManagers `perpetualManager` contracts for every perp to claim
    /// @dev If the caller wants to send the rewards to another account it first needs to
    /// call `set_rewards_receiver(otherAccount)` on each `liquidityGauge`
    function claimRewards(
        address user,
        address[] memory liquidityGauges,
        uint256[] memory perpetualIDs,
        address[] memory perpetualManagers
    ) external nonReentrant {
        _claimRewards(user, liquidityGauges, perpetualIDs, true, new address[](perpetualIDs.length), perpetualManagers);
    }

    /// @notice Wrapper built on top of the `_gaugeDeposit` method to deposit collateral in a gauge
    /// @param token On top of the parameters of the internal function, users need to specify the token associated
    /// to the gauge they want to deposit in
    /// @dev The function will revert if the token does not correspond to the gauge
    function gaugeDeposit(
        address user,
        uint256 amount,
        ILiquidityGauge gauge,
        bool shouldClaimRewards,
        IERC20 token
    ) external nonReentrant {
        token.safeTransferFrom(msg.sender, address(this), amount);
        _gaugeDeposit(user, amount, gauge, shouldClaimRewards);
    }

    /// @notice Wrapper n°1 built on top of the `_mint` method to mint stablecoins
    /// @param user Address to send the stablecoins to
    /// @param amount Amount of collateral to use for the mint
    /// @param minStableAmount Minimum stablecoin minted for the tx not to revert
    /// @param stablecoin Address of the stablecoin to mint
    /// @param collateral Collateral to mint from
    function mint(
        address user,
        uint256 amount,
        uint256 minStableAmount,
        address stablecoin,
        address collateral
    ) external nonReentrant {
        IERC20(collateral).safeTransferFrom(msg.sender, address(this), amount);
        _mint(user, amount, minStableAmount, false, stablecoin, collateral, IPoolManager(address(0)));
    }

    /// @notice Wrapper n°2 (a little more gas efficient than n°1) built on top of the `_mint` method to mint stablecoins
    /// @param user Address to send the stablecoins to
    /// @param amount Amount of collateral to use for the mint
    /// @param minStableAmount Minimum stablecoin minted for the tx not to revert
    /// @param stableMaster Address of the stableMaster managing the stablecoin to mint
    /// @param collateral Collateral to mint from
    /// @param poolManager PoolManager associated to the `collateral`
    function mint(
        address user,
        uint256 amount,
        uint256 minStableAmount,
        address stableMaster,
        address collateral,
        address poolManager
    ) external nonReentrant {
        IERC20(collateral).safeTransferFrom(msg.sender, address(this), amount);
        _mint(user, amount, minStableAmount, true, stableMaster, collateral, IPoolManager(poolManager));
    }

    /// @notice Wrapper built on top of the `_burn` method to burn stablecoins
    /// @param dest Address to send the collateral to
    /// @param amount Amount of stablecoins to use for the burn
    /// @param minCollatAmount Minimum collateral amount received for the tx not to revert
    /// @param stablecoin Address of the stablecoin to mint
    /// @param collateral Collateral to mint from
    function burn(
        address dest,
        uint256 amount,
        uint256 minCollatAmount,
        address stablecoin,
        address collateral
    ) external nonReentrant {
        _burn(dest, amount, minCollatAmount, false, stablecoin, collateral, IPoolManager(address(0)));
    }

    /// @notice Wrapper n°1 built on top of the `_deposit` method to deposit collateral as a SLP in the protocol
    /// Allows to deposit a collateral within the protocol
    /// @param user Address where to send the resulting sanTokens, if this address is the router address then it means
    /// that the intention is to stake the sanTokens obtained in a subsequent `gaugeDeposit` action
    /// @param amount Amount of collateral to deposit
    /// @param stablecoin `StableMaster` associated to the sanToken
    /// @param collateral Token to deposit
    /// @dev Contrary to the `mint` action, the `deposit` action can be used in composition with other actions, like
    /// `deposit` and then `stake
    function deposit(
        address user,
        uint256 amount,
        address stablecoin,
        address collateral
    ) external nonReentrant {
        IERC20(collateral).safeTransferFrom(msg.sender, address(this), amount);
        _deposit(user, amount, false, stablecoin, collateral, IPoolManager(address(0)), ISanToken(address(0)));
    }

    /// @notice Wrapper n°2 (a little more gas efficient than n°1) built on top of the `_deposit` method to deposit collateral as a SLP in the protocol
    /// Allows to deposit a collateral within the protocol
    /// @param user Address where to send the resulting sanTokens, if this address is the router address then it means
    /// that the intention is to stake the sanTokens obtained in a subsequent `gaugeDeposit` action
    /// @param amount Amount of collateral to deposit
    /// @param stableMaster `StableMaster` associated to the sanToken
    /// @param collateral Token to deposit
    /// @param poolManager PoolManager associated to the sanToken
    /// @param sanToken SanToken associated to the `collateral` and `stableMaster`
    /// @dev Contrary to the `mint` action, the `deposit` action can be used in composition with other actions, like
    /// `deposit` and then `stake`
    function deposit(
        address user,
        uint256 amount,
        address stableMaster,
        address collateral,
        IPoolManager poolManager,
        ISanToken sanToken
    ) external nonReentrant {
        IERC20(collateral).safeTransferFrom(msg.sender, address(this), amount);
        _deposit(user, amount, true, stableMaster, collateral, poolManager, sanToken);
    }

    /// @notice Wrapper built on top of the `_openPerpetual` method to open a perpetual with the protocol
    /// @param collateral Here the collateral should not be null (even if `addressProcessed` is true) for the router
    /// to be able to know how to deposit collateral
    /// @dev `stablecoinOrPerpetualManager` should be the address of the agToken (= stablecoin) is `addressProcessed` is false
    ///  and the associated `perpetualManager` otherwise
    function openPerpetual(
        address owner,
        uint256 margin,
        uint256 amountCommitted,
        uint256 maxOracleRate,
        uint256 minNetMargin,
        bool addressProcessed,
        address stablecoinOrPerpetualManager,
        address collateral
    ) external nonReentrant {
        IERC20(collateral).safeTransferFrom(msg.sender, address(this), margin);
        _openPerpetual(
            owner,
            margin,
            amountCommitted,
            maxOracleRate,
            minNetMargin,
            addressProcessed,
            stablecoinOrPerpetualManager,
            collateral
        );
    }

    /// @notice Wrapper built on top of the `_addToPerpetual` method to add collateral to a perpetual with the protocol
    /// @param collateral Here the collateral should not be null (even if `addressProcessed is true) for the router
    /// to be able to know how to deposit collateral
    /// @dev `stablecoinOrPerpetualManager` should be the address of the agToken is `addressProcessed` is false and the associated
    /// `perpetualManager` otherwise
    function addToPerpetual(
        uint256 margin,
        uint256 perpetualID,
        bool addressProcessed,
        address stablecoinOrPerpetualManager,
        address collateral
    ) external nonReentrant {
        IERC20(collateral).safeTransferFrom(msg.sender, address(this), margin);
        _addToPerpetual(margin, perpetualID, addressProcessed, stablecoinOrPerpetualManager, collateral);
    }

    /// @notice Allows composable calls to different functions within the protocol
    /// @param paramsPermit Array of params `PermitType` used to do a 1 tx to approve the router on each token (can be done once by
    /// setting high approved amounts) which supports the `permit` standard. Users willing to interact with the contract
    /// with tokens that do not support permit should approve the contract for these tokens prior to interacting with it
    /// @param paramsTransfer Array of params `TransferType` used to transfer tokens to the router
    /// @param paramsSwap Array of params `ParamsSwapType` used to swap tokens
    /// @param actions List of actions to be performed by the router (in order of execution): make sure to read for each action the
    /// associated internal function
    /// @param datas Array of encoded data for each of the actions performed in this mixer. This is where the bytes-encoded parameters
    /// for a given action are stored
    /// @dev This function first fills the router balances via transfers and swaps. It then proceeds with each
    /// action in the order at which they are given
    /// @dev With this function, users can specify paths to swap tokens to the desired token of their choice. Yet the protocol
    /// does not verify the payload given and cannot check that the swap performed by users actually gives the desired
    /// out token: in this case funds will be lost by the user
    /// @dev For some actions (`mint`, `deposit`, `openPerpetual`, `addToPerpetual`, `withdraw`), users are
    /// required to give a proportion of the amount of token they have brought to the router within the transaction (through
    /// a direct transfer or a swap) they want to use for the operation. If you want to use all the USDC you have brought (through an ETH -> USDC)
    /// swap to mint stablecoins for instance, you should use `BASE_PARAMS` as a proportion.
    /// @dev The proportion that is specified for an action is a proportion of what is left. If you want to use 50% of your USDC for a `mint`
    /// and the rest for an `openPerpetual`, proportion used for the `mint` should be 50% (that is `BASE_PARAMS/2`), and proportion
    /// for the `openPerpetual` should be all that is left that is 100% (= `BASE_PARAMS`).
    /// @dev For each action here, make sure to read the documentation of the associated internal function to know how to correctly
    /// specify parameters
    function mixer(
        PermitType[] memory paramsPermit,
        TransferType[] memory paramsTransfer,
        ParamsSwapType[] memory paramsSwap,
        ActionType[] memory actions,
        bytes[] calldata datas
    ) external payable nonReentrant {
        // Do all the permits once for all: if all tokens have already been approved, there's no need for this step
        for (uint256 i = 0; i < paramsPermit.length; i++) {
            IERC20PermitUpgradeable(paramsPermit[i].token).permit(
                paramsPermit[i].owner,
                address(this),
                paramsPermit[i].value,
                paramsPermit[i].deadline,
                paramsPermit[i].v,
                paramsPermit[i].r,
                paramsPermit[i].s
            );
        }

        // Then, do all the transfer to load all needed funds into the router
        // This function is limited to 10 different assets to be spent on the protocol (agTokens, collaterals, sanTokens)
        address[_MAX_TOKENS] memory listTokens;
        uint256[_MAX_TOKENS] memory balanceTokens;

        for (uint256 i = 0; i < paramsTransfer.length; i++) {
            paramsTransfer[i].inToken.safeTransferFrom(msg.sender, address(this), paramsTransfer[i].amountIn);
            _addToList(listTokens, balanceTokens, address(paramsTransfer[i].inToken), paramsTransfer[i].amountIn);
        }

        for (uint256 i = 0; i < paramsSwap.length; i++) {
            // Caution here: if the args are not set such that end token is the params `paramsSwap[i].collateral`,
            // then the funds will be lost, and any user could take advantage of it to fetch the funds
            uint256 amountOut = _transferAndSwap(
                paramsSwap[i].inToken,
                paramsSwap[i].amountIn,
                paramsSwap[i].minAmountOut,
                paramsSwap[i].swapType,
                paramsSwap[i].args
            );
            _addToList(listTokens, balanceTokens, address(paramsSwap[i].collateral), amountOut);
        }

        // Performing actions one after the others
        for (uint256 i = 0; i < actions.length; i++) {
            if (actions[i] == ActionType.claimRewards) {
                (
                    address user,
                    uint256 proportionToBeTransferred,
                    address[] memory claimLiquidityGauges,
                    uint256[] memory claimPerpetualIDs,
                    bool addressProcessed,
                    address[] memory stablecoins,
                    address[] memory collateralsOrPerpetualManagers
                ) = abi.decode(datas[i], (address, uint256, address[], uint256[], bool, address[], address[]));

                uint256 amount = ANGLE.balanceOf(user);

                _claimRewards(
                    user,
                    claimLiquidityGauges,
                    claimPerpetualIDs,
                    addressProcessed,
                    stablecoins,
                    collateralsOrPerpetualManagers
                );
                if (proportionToBeTransferred > 0) {
                    amount = ANGLE.balanceOf(user) - amount;
                    amount = (amount * proportionToBeTransferred) / BASE_PARAMS;
                    ANGLE.safeTransferFrom(msg.sender, address(this), amount);
                    _addToList(listTokens, balanceTokens, address(ANGLE), amount);
                }
            } else if (actions[i] == ActionType.claimWeeklyInterest) {
                (address user, address feeDistributor, bool letInContract) = abi.decode(
                    datas[i],
                    (address, address, bool)
                );

                (uint256 amount, IERC20 token) = _claimWeeklyInterest(
                    user,
                    IFeeDistributorFront(feeDistributor),
                    letInContract
                );
                if (address(token) != address(0)) _addToList(listTokens, balanceTokens, address(token), amount);
                // In all the following action, the `amount` variable represents the proportion of the
                // balance that needs to be used for this action (in `BASE_PARAMS`)
                // We name it `amount` here to save some new variable declaration costs
            } else if (actions[i] == ActionType.veANGLEDeposit) {
                (address user, uint256 amount) = abi.decode(datas[i], (address, uint256));

                amount = _computeProportion(amount, listTokens, balanceTokens, address(ANGLE));
                _depositOnLocker(user, amount);
            } else if (actions[i] == ActionType.gaugeDeposit) {
                (address user, uint256 amount, address stakedToken, address gauge, bool shouldClaimRewards) = abi
                    .decode(datas[i], (address, uint256, address, address, bool));

                amount = _computeProportion(amount, listTokens, balanceTokens, stakedToken);
                _gaugeDeposit(user, amount, ILiquidityGauge(gauge), shouldClaimRewards);
            } else if (actions[i] == ActionType.deposit) {
                (
                    address user,
                    uint256 amount,
                    bool addressProcessed,
                    address stablecoinOrStableMaster,
                    address collateral,
                    address poolManager,
                    address sanToken
                ) = abi.decode(datas[i], (address, uint256, bool, address, address, address, address));

                amount = _computeProportion(amount, listTokens, balanceTokens, collateral);
                (amount, sanToken) = _deposit(
                    user,
                    amount,
                    addressProcessed,
                    stablecoinOrStableMaster,
                    collateral,
                    IPoolManager(poolManager),
                    ISanToken(sanToken)
                );

                if (amount > 0) _addToList(listTokens, balanceTokens, sanToken, amount);
            } else if (actions[i] == ActionType.withdraw) {
                (
                    uint256 amount,
                    bool addressProcessed,
                    address stablecoinOrStableMaster,
                    address collateralOrPoolManager,
                    address sanToken
                ) = abi.decode(datas[i], (uint256, bool, address, address, address));

                amount = _computeProportion(amount, listTokens, balanceTokens, sanToken);
                // Reusing the `collateralOrPoolManager` variable to save some variable declarations
                (amount, collateralOrPoolManager) = _withdraw(
                    amount,
                    addressProcessed,
                    stablecoinOrStableMaster,
                    collateralOrPoolManager
                );
                _addToList(listTokens, balanceTokens, collateralOrPoolManager, amount);
            } else if (actions[i] == ActionType.mint) {
                (
                    address user,
                    uint256 amount,
                    uint256 minStableAmount,
                    bool addressProcessed,
                    address stablecoinOrStableMaster,
                    address collateral,
                    address poolManager
                ) = abi.decode(datas[i], (address, uint256, uint256, bool, address, address, address));

                amount = _computeProportion(amount, listTokens, balanceTokens, collateral);
                _mint(
                    user,
                    amount,
                    minStableAmount,
                    addressProcessed,
                    stablecoinOrStableMaster,
                    collateral,
                    IPoolManager(poolManager)
                );
            } else if (actions[i] == ActionType.openPerpetual) {
                (
                    address user,
                    uint256 amount,
                    uint256 amountCommitted,
                    uint256 extremeRateOracle,
                    uint256 minNetMargin,
                    bool addressProcessed,
                    address stablecoinOrPerpetualManager,
                    address collateral
                ) = abi.decode(datas[i], (address, uint256, uint256, uint256, uint256, bool, address, address));

                amount = _computeProportion(amount, listTokens, balanceTokens, collateral);

                _openPerpetual(
                    user,
                    amount,
                    amountCommitted,
                    extremeRateOracle,
                    minNetMargin,
                    addressProcessed,
                    stablecoinOrPerpetualManager,
                    collateral
                );
            } else if (actions[i] == ActionType.addToPerpetual) {
                (
                    uint256 amount,
                    uint256 perpetualID,
                    bool addressProcessed,
                    address stablecoinOrPerpetualManager,
                    address collateral
                ) = abi.decode(datas[i], (uint256, uint256, bool, address, address));

                amount = _computeProportion(amount, listTokens, balanceTokens, collateral);
                _addToPerpetual(amount, perpetualID, addressProcessed, stablecoinOrPerpetualManager, collateral);
            }
        }

        // Once all actions have been performed, the router sends back the unused funds from users
        // If a user sends funds (through a swap) but specifies incorrectly the collateral associated to it, then the mixer will revert
        // When trying to send remaining funds back
        for (uint256 i = 0; i < balanceTokens.length; i++) {
            if (balanceTokens[i] > 0) IERC20(listTokens[i]).safeTransfer(msg.sender, balanceTokens[i]);
        }
    }

    receive() external payable {}

    // ======================== Internal Utility Functions =========================
    // Most internal utility functions have a wrapper built on top of it

    /// @notice Internal version of the `claimRewards` function
    /// Allows to claim rewards for multiple gauges and perpetuals at once
    /// @param gaugeUser Address for which to fetch the rewards from the gauges
    /// @param liquidityGauges Gauges to claim on
    /// @param perpetualIDs Perpetual IDs to claim rewards for
    /// @param addressProcessed Whether `PerpetualManager` list is already accessible in `collateralsOrPerpetualManagers`vor if it should be
    /// retrieved from `stablecoins` and `collateralsOrPerpetualManagers`
    /// @param stablecoins Stablecoin contracts linked to the perpetualsIDs. Array of zero addresses if addressProcessed is true
    /// @param collateralsOrPerpetualManagers Collateral contracts linked to the perpetualsIDs or `perpetualManager` contracts if
    /// `addressProcessed` is true
    /// @dev If the caller wants to send the rewards to another account than `gaugeUser` it first needs to
    /// call `set_rewards_receiver(otherAccount)` on each `liquidityGauge`
    /// @dev The function only takes rewards received by users,
    function _claimRewards(
        address gaugeUser,
        address[] memory liquidityGauges,
        uint256[] memory perpetualIDs,
        bool addressProcessed,
        address[] memory stablecoins,
        address[] memory collateralsOrPerpetualManagers
    ) internal {
        require(
            stablecoins.length == perpetualIDs.length && collateralsOrPerpetualManagers.length == perpetualIDs.length,
            "104"
        );

        for (uint256 i = 0; i < liquidityGauges.length; i++) {
            ILiquidityGauge(liquidityGauges[i]).claim_rewards(gaugeUser);
        }

        for (uint256 i = 0; i < perpetualIDs.length; i++) {
            IPerpetualManagerFrontWithClaim perpManager;
            if (addressProcessed) perpManager = IPerpetualManagerFrontWithClaim(collateralsOrPerpetualManagers[i]);
            else {
                (, Pairs memory pairs) = _getInternalContracts(
                    IERC20(stablecoins[i]),
                    IERC20(collateralsOrPerpetualManagers[i])
                );
                perpManager = pairs.perpetualManager;
            }
            perpManager.getReward(perpetualIDs[i]);
        }
    }

    /// @notice Allows to deposit ANGLE on an existing locker
    /// @param user Address to deposit for
    /// @param amount Amount to deposit
    function _depositOnLocker(address user, uint256 amount) internal {
        VEANGLE.deposit_for(user, amount);
    }

    /// @notice Allows to claim weekly interest distribution and if wanted to transfer it to the `angleRouter` for future use
    /// @param user Address to claim for
    /// @param _feeDistributor Address of the fee distributor to claim to
    /// @dev If funds are transferred to the router, this action cannot be an end in itself, otherwise funds will be lost:
    /// typically we expect people to call for this action before doing a deposit
    /// @dev If `letInContract` (and hence if funds are transferred to the router), you should approve the `angleRouter` to
    /// transfer the token claimed from the `feeDistributor`
    function _claimWeeklyInterest(
        address user,
        IFeeDistributorFront _feeDistributor,
        bool letInContract
    ) internal returns (uint256 amount, IERC20 token) {
        amount = _feeDistributor.claim(user);
        if (letInContract) {
            // Fetching info from the `FeeDistributor` to process correctly the withdrawal
            token = IERC20(_feeDistributor.token());
            token.safeTransferFrom(msg.sender, address(this), amount);
        } else {
            amount = 0;
        }
    }

    /// @notice Internal version of the `gaugeDeposit` function
    /// Allows to deposit tokens into a gauge
    /// @param user Address on behalf of which deposit should be made in the gauge
    /// @param amount Amount to stake
    /// @param gauge LiquidityGauge to stake in
    /// @param shouldClaimRewards Whether to claim or not previously accumulated rewards
    /// @dev You should be cautious on who will receive the rewards (if `shouldClaimRewards` is true)
    /// It can be set on each gauge
    /// @dev In the `mixer`, before calling for this action, user should have made sure to get in the router
    /// the associated token (by like a  `deposit` action)
    /// @dev The function will revert if the gauge has not already been approved by the contract
    function _gaugeDeposit(
        address user,
        uint256 amount,
        ILiquidityGauge gauge,
        bool shouldClaimRewards
    ) internal {
        gauge.deposit(amount, user, shouldClaimRewards);
    }

    /// @notice Internal version of the `mint` functions
    /// Mints stablecoins from the protocol
    /// @param user Address to send the stablecoins to
    /// @param amount Amount of collateral to use for the mint
    /// @param minStableAmount Minimum stablecoin minted for the tx not to revert
    /// @param addressProcessed Whether `msg.sender` provided the contracts address or the tokens one
    /// @param stablecoinOrStableMaster Token associated to a `StableMaster` (if `addressProcessed` is false)
    /// or directly the `StableMaster` contract if `addressProcessed`
    /// @param collateral Collateral to mint from: it can be null if `addressProcessed` is true but in the corresponding
    /// action, the `mixer` needs to get a correct address to compute the amount of tokens to use for the mint
    /// @param poolManager PoolManager associated to the `collateral` (null if `addressProcessed` is not true)
    /// @dev This function is not designed to be composable with other actions of the router after it's called: like
    /// stablecoins obtained from it cannot be used for other operations: as such the `user` address should not be the router
    /// address
    function _mint(
        address user,
        uint256 amount,
        uint256 minStableAmount,
        bool addressProcessed,
        address stablecoinOrStableMaster,
        address collateral,
        IPoolManager poolManager
    ) internal {
        IStableMasterFront stableMaster;
        (stableMaster, poolManager) = _mintBurnContracts(
            addressProcessed,
            stablecoinOrStableMaster,
            collateral,
            poolManager
        );
        stableMaster.mint(amount, user, poolManager, minStableAmount);
    }

    /// @notice Burns stablecoins from the protocol
    /// @param dest Address who will receive the proceeds
    /// @param amount Amount of collateral to use for the mint
    /// @param minCollatAmount Minimum Collateral minted for the tx not to revert
    /// @param addressProcessed Whether `msg.sender` provided the contracts address or the tokens one
    /// @param stablecoinOrStableMaster Token associated to a `StableMaster` (if `addressProcessed` is false)
    /// or directly the `StableMaster` contract if `addressProcessed`
    /// @param collateral Collateral to mint from: it can be null if `addressProcessed` is true but in the corresponding
    /// action, the `mixer` needs to get a correct address to compute the amount of tokens to use for the mint
    /// @param poolManager PoolManager associated to the `collateral` (null if `addressProcessed` is not true)
    function _burn(
        address dest,
        uint256 amount,
        uint256 minCollatAmount,
        bool addressProcessed,
        address stablecoinOrStableMaster,
        address collateral,
        IPoolManager poolManager
    ) internal {
        IStableMasterFront stableMaster;
        (stableMaster, poolManager) = _mintBurnContracts(
            addressProcessed,
            stablecoinOrStableMaster,
            collateral,
            poolManager
        );
        stableMaster.burn(amount, msg.sender, dest, poolManager, minCollatAmount);
    }

    /// @notice Internal version of the `deposit` functions
    /// Allows to deposit a collateral within the protocol
    /// @param user Address where to send the resulting sanTokens, if this address is the router address then it means
    /// that the intention is to stake the sanTokens obtained in a subsequent `gaugeDeposit` action
    /// @param amount Amount of collateral to deposit
    /// @param addressProcessed Whether `msg.sender` provided the contracts addresses or the tokens ones
    /// @param stablecoinOrStableMaster Token associated to a `StableMaster` (if `addressProcessed` is false)
    /// or directly the `StableMaster` contract if `addressProcessed`
    /// @param collateral Token to deposit: it can be null if `addressProcessed` is true but in the corresponding
    /// action, the `mixer` needs to get a correct address to compute the amount of tokens to use for the deposit
    /// @param poolManager PoolManager associated to the `collateral` (null if `addressProcessed` is not true)
    /// @param sanToken SanToken associated to the `collateral` (null if `addressProcessed` is not true)
    /// @dev Contrary to the `mint` action, the `deposit` action can be used in composition with other actions, like
    /// `deposit` and then `stake`
    function _deposit(
        address user,
        uint256 amount,
        bool addressProcessed,
        address stablecoinOrStableMaster,
        address collateral,
        IPoolManager poolManager,
        ISanToken sanToken
    ) internal returns (uint256 addedAmount, address) {
        IStableMasterFront stableMaster;
        if (addressProcessed) {
            stableMaster = IStableMasterFront(stablecoinOrStableMaster);
        } else {
            Pairs memory pairs;
            (stableMaster, pairs) = _getInternalContracts(IERC20(stablecoinOrStableMaster), IERC20(collateral));
            poolManager = pairs.poolManager;
            sanToken = pairs.sanToken;
        }

        if (user == address(this)) {
            // Computing the amount of sanTokens obtained
            addedAmount = sanToken.balanceOf(address(this));
            stableMaster.deposit(amount, address(this), poolManager);
            addedAmount = sanToken.balanceOf(address(this)) - addedAmount;
        } else {
            stableMaster.deposit(amount, user, poolManager);
        }
        return (addedAmount, address(sanToken));
    }

    /// @notice Withdraws sanTokens from the protocol
    /// @param amount Amount of sanTokens to withdraw
    /// @param addressProcessed Whether `msg.sender` provided the contracts addresses or the tokens ones
    /// @param stablecoinOrStableMaster Token associated to a `StableMaster` (if `addressProcessed` is false)
    /// or directly the `StableMaster` contract if `addressProcessed`
    /// @param collateralOrPoolManager Collateral to withdraw (if `addressProcessed` is false) or directly
    /// the `PoolManager` contract if `addressProcessed`
    function _withdraw(
        uint256 amount,
        bool addressProcessed,
        address stablecoinOrStableMaster,
        address collateralOrPoolManager
    ) internal returns (uint256 withdrawnAmount, address) {
        IStableMasterFront stableMaster;
        // Stores the address of the `poolManager`, while `collateralOrPoolManager` is used in the function
        // to store the `collateral` address
        IPoolManager poolManager;
        if (addressProcessed) {
            stableMaster = IStableMasterFront(stablecoinOrStableMaster);
            poolManager = IPoolManager(collateralOrPoolManager);
            collateralOrPoolManager = poolManager.token();
        } else {
            Pairs memory pairs;
            (stableMaster, pairs) = _getInternalContracts(
                IERC20(stablecoinOrStableMaster),
                IERC20(collateralOrPoolManager)
            );
            poolManager = pairs.poolManager;
        }
        // Here reusing the `withdrawnAmount` variable to avoid a stack too deep problem
        withdrawnAmount = IERC20(collateralOrPoolManager).balanceOf(address(this));

        // This call will increase our collateral balance
        stableMaster.withdraw(amount, address(this), address(this), poolManager);

        // We compute the difference between our collateral balance after and before the `withdraw` call
        withdrawnAmount = IERC20(collateralOrPoolManager).balanceOf(address(this)) - withdrawnAmount;

        return (withdrawnAmount, collateralOrPoolManager);
    }

    /// @notice Internal version of the `openPerpetual` function
    /// Opens a perpetual within Angle
    /// @param owner Address to mint perpetual for
    /// @param margin Margin to open the perpetual with
    /// @param amountCommitted Commit amount in the perpetual
    /// @param maxOracleRate Maximum oracle rate required to have a leverage position opened
    /// @param minNetMargin Minimum net margin required to have a leverage position opened
    /// @param addressProcessed Whether msg.sender provided the contracts addresses or the tokens ones
    /// @param stablecoinOrPerpetualManager Token associated to the `StableMaster` (iif `addressProcessed` is false)
    /// or address of the desired `PerpetualManager` (if `addressProcessed` is true)
    /// @param collateral Collateral to mint from (it can be null if `addressProcessed` is true): it can be null if `addressProcessed` is true but in the corresponding
    /// action, the `mixer` needs to get a correct address to compute the amount of tokens to use for the deposit
    function _openPerpetual(
        address owner,
        uint256 margin,
        uint256 amountCommitted,
        uint256 maxOracleRate,
        uint256 minNetMargin,
        bool addressProcessed,
        address stablecoinOrPerpetualManager,
        address collateral
    ) internal returns (uint256 perpetualID) {
        if (!addressProcessed) {
            (, Pairs memory pairs) = _getInternalContracts(IERC20(stablecoinOrPerpetualManager), IERC20(collateral));
            stablecoinOrPerpetualManager = address(pairs.perpetualManager);
        }

        return
            IPerpetualManagerFrontWithClaim(stablecoinOrPerpetualManager).openPerpetual(
                owner,
                margin,
                amountCommitted,
                maxOracleRate,
                minNetMargin
            );
    }

    /// @notice Internal version of the `addToPerpetual` function
    /// Adds collateral to a perpetual
    /// @param margin Amount of collateral to add
    /// @param perpetualID Perpetual to add collateral to
    /// @param addressProcessed Whether msg.sender provided the contracts addresses or the tokens ones
    /// @param stablecoinOrPerpetualManager Token associated to the `StableMaster` (iif `addressProcessed` is false)
    /// or address of the desired `PerpetualManager` (if `addressProcessed` is true)
    /// @param collateral Collateral to mint from (it can be null if `addressProcessed` is true): it can be null if `addressProcessed` is true but in the corresponding
    /// action, the `mixer` needs to get a correct address to compute the amount of tokens to use for the deposit
    function _addToPerpetual(
        uint256 margin,
        uint256 perpetualID,
        bool addressProcessed,
        address stablecoinOrPerpetualManager,
        address collateral
    ) internal {
        if (!addressProcessed) {
            (, Pairs memory pairs) = _getInternalContracts(IERC20(stablecoinOrPerpetualManager), IERC20(collateral));
            stablecoinOrPerpetualManager = address(pairs.perpetualManager);
        }
        IPerpetualManagerFrontWithClaim(stablecoinOrPerpetualManager).addToPerpetual(perpetualID, margin);
    }

    // ======================== Internal Utility Functions =========================

    /// @notice Checks if collateral in the list
    /// @param list List of addresses
    /// @param searchFor Address of interest
    /// @return index Place of the address in the list if it is in or current length otherwise
    function _searchList(address[_MAX_TOKENS] memory list, address searchFor) internal pure returns (uint256 index) {
        uint256 i;
        while (i < list.length && list[i] != address(0)) {
            if (list[i] == searchFor) return i;
            i++;
        }
        return i;
    }

    /// @notice Modifies stored balances for a given collateral
    /// @param list List of collateral addresses
    /// @param balances List of balances for the different supported collateral types
    /// @param searchFor Address of the collateral of interest
    /// @param amount Amount to add in the balance for this collateral
    function _addToList(
        address[_MAX_TOKENS] memory list,
        uint256[_MAX_TOKENS] memory balances,
        address searchFor,
        uint256 amount
    ) internal pure {
        uint256 index = _searchList(list, searchFor);
        // add it to the list if non existent and we add tokens
        if (list[index] == address(0)) list[index] = searchFor;
        balances[index] += amount;
    }

    /// @notice Computes the proportion of the collateral leftover balance to use for a given action
    /// @param proportion Ratio to take from balance
    /// @param list Collateral list
    /// @param balances Balances of each collateral asset in the collateral list
    /// @param searchFor Collateral to look for
    /// @return amount Amount to use for the action (based on the proportion given)
    /// @dev To use all the collateral balance available for an action, users should give `proportion` a value of
    /// `BASE_PARAMS`
    function _computeProportion(
        uint256 proportion,
        address[_MAX_TOKENS] memory list,
        uint256[_MAX_TOKENS] memory balances,
        address searchFor
    ) internal pure returns (uint256 amount) {
        uint256 index = _searchList(list, searchFor);

        // Reverts if the index was not found
        require(list[index] != address(0), "33");

        amount = (proportion * balances[index]) / BASE_PARAMS;
        balances[index] -= amount;
    }

    /// @notice Gets Angle contracts associated to a pair (stablecoin, collateral)
    /// @param stablecoin Token associated to a `StableMaster`
    /// @param collateral Collateral to mint/deposit/open perpetual or add collateral from
    /// @dev This function is used to check that the parameters passed by people calling some of the main
    /// router functions are correct
    function _getInternalContracts(IERC20 stablecoin, IERC20 collateral)
        internal
        view
        returns (IStableMasterFront stableMaster, Pairs memory pairs)
    {
        stableMaster = mapStableMasters[stablecoin];
        pairs = mapPoolManagers[stableMaster][collateral];
        // If `stablecoin` is zero then this necessarily means that `stableMaster` here will be 0
        // Similarly, if `collateral` is zero, then this means that `pairs.perpetualManager`, `pairs.poolManager`
        // and `pairs.sanToken` will be zero
        // Last, if any of `pairs.perpetualManager`, `pairs.poolManager` or `pairs.sanToken` is zero, this means
        // that all others should be null from the `addPairs` and `removePairs` functions which keep this invariant
        require(address(stableMaster) != address(0) && address(pairs.poolManager) != address(0), "0");

        return (stableMaster, pairs);
    }

    /// @notice Get contracts for mint and burn actions
    /// @param addressProcessed Whether `msg.sender` provided the contracts address or the tokens one
    /// @param stablecoinOrStableMaster Token associated to a `StableMaster` (if `addressProcessed` is false)
    /// or directly the `StableMaster` contract if `addressProcessed`
    /// @param collateral Collateral to mint from: it can be null if `addressProcessed` is true but in the corresponding
    /// action, the `mixer` needs to get a correct address to compute the amount of tokens to use for the mint
    /// @param poolManager PoolManager associated to the `collateral` (null if `addressProcessed` is not true)
    function _mintBurnContracts(
        bool addressProcessed,
        address stablecoinOrStableMaster,
        address collateral,
        IPoolManager poolManager
    ) internal view returns (IStableMasterFront, IPoolManager) {
        IStableMasterFront stableMaster;
        if (addressProcessed) {
            stableMaster = IStableMasterFront(stablecoinOrStableMaster);
        } else {
            Pairs memory pairs;
            (stableMaster, pairs) = _getInternalContracts(IERC20(stablecoinOrStableMaster), IERC20(collateral));
            poolManager = pairs.poolManager;
        }
        return (stableMaster, poolManager);
    }

    /// @notice Adds new collateral type to specific stablecoin
    /// @param stableMaster Address of the `StableMaster` associated to the stablecoin of interest
    /// @param poolManager Address of the `PoolManager` contract associated to the pair (stablecoin,collateral)
    /// @param liquidityGauge Address of liquidity gauge contract associated to sanToken
    function _addPair(
        IStableMasterFront stableMaster,
        IPoolManager poolManager,
        ILiquidityGauge liquidityGauge
    ) internal {
        // Fetching the associated `sanToken` and `perpetualManager` from the contract
        (IERC20 collateral, ISanToken sanToken, IPerpetualManager perpetualManager, , , , , , ) = IStableMaster(
            address(stableMaster)
        ).collateralMap(poolManager);

        Pairs storage _pairs = mapPoolManagers[stableMaster][collateral];
        // Checking if the pair has not already been initialized: if yes we need to make the function revert
        // otherwise we could end up with still approved `PoolManager` and `PerpetualManager` contracts
        require(address(_pairs.poolManager) == address(0), "114");

        _pairs.poolManager = poolManager;
        _pairs.perpetualManager = IPerpetualManagerFrontWithClaim(address(perpetualManager));
        _pairs.sanToken = sanToken;
        // In the future, it is possible that sanTokens do not have an associated liquidity gauge
        if (address(liquidityGauge) != address(0)) {
            require(address(sanToken) == liquidityGauge.staking_token(), "20");
            _pairs.gauge = liquidityGauge;
            sanToken.approve(address(liquidityGauge), type(uint256).max);
        }
        _changeAllowance(collateral, address(stableMaster), type(uint256).max);
        _changeAllowance(collateral, address(perpetualManager), type(uint256).max);
        emit CollateralToggled(address(stableMaster), address(poolManager), address(liquidityGauge));
    }

    /// @notice Changes allowance of this contract for a given token
    /// @param token Address of the token to change allowance
    /// @param spender Address to change the allowance of
    /// @param amount Amount allowed
    function _changeAllowance(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = token.allowance(address(this), spender);
        if (currentAllowance < amount) {
            token.safeIncreaseAllowance(spender, amount - currentAllowance);
        } else if (currentAllowance > amount) {
            token.safeDecreaseAllowance(spender, currentAllowance - amount);
        }
    }

    /// @notice Transfers collateral or an arbitrary token which is then swapped on UniswapV3 or on 1Inch
    /// @param inToken Token to swap for the collateral
    /// @param amount Amount of in token to swap for the collateral
    /// @param minAmountOut Minimum amount accepted for the swap to happen
    /// @param swapType Choice on which contracts to swap
    /// @param args Bytes representing either the path to swap your input token to the accepted collateral on Uniswap or payload for 1Inch
    /// @dev The `path` provided is not checked, meaning people could swap for a token A and declare that they've swapped for another token B.
    /// However, the mixer manipulates its token balance only through the addresses registered in `listTokens`, so any subsequent mixer action
    /// trying to transfer funds B will do it through address of token A and revert as A is not actually funded.
    /// In case there is not subsequent action, `mixer` will revert when trying to send back what appears to be remaining tokens A.
    function _transferAndSwap(
        IERC20 inToken,
        uint256 amount,
        uint256 minAmountOut,
        SwapType swapType,
        bytes memory args
    ) internal returns (uint256 amountOut) {
        if (address(inToken) == address(WETH9) && address(this).balance >= amount) {
            WETH9.deposit{ value: amount }(); // wrap only what is needed to pay
        } else {
            inToken.safeTransferFrom(msg.sender, address(this), amount);
        }
        if (swapType == SwapType.UniswapV3) amountOut = _swapOnUniswapV3(inToken, amount, minAmountOut, args);
        else if (swapType == SwapType.oneINCH) amountOut = _swapOn1Inch(inToken, minAmountOut, args);
        else require(false, "3");

        return amountOut;
    }

    /// @notice Allows to swap any token to an accepted collateral via UniswapV3 (if there is a path)
    /// @param inToken Address token used as entrance of the swap
    /// @param amount Amount of in token to swap for the accepted collateral
    /// @param minAmountOut Minimum amount accepted for the swap to happen
    /// @param path Bytes representing the path to swap your input token to the accepted collateral
    function _swapOnUniswapV3(
        IERC20 inToken,
        uint256 amount,
        uint256 minAmountOut,
        bytes memory path
    ) internal returns (uint256 amountOut) {
        // Approve transfer to the `uniswapV3Router` if it is the first time that the token is used
        if (!uniAllowedToken[inToken]) {
            inToken.safeIncreaseAllowance(address(uniswapV3Router), type(uint256).max);
            uniAllowedToken[inToken] = true;
        }
        amountOut = uniswapV3Router.exactInput(
            ExactInputParams(path, address(this), block.timestamp, amount, minAmountOut)
        );
    }

    /// @notice Allows to swap any token to an accepted collateral via 1Inch API
    /// @param minAmountOut Minimum amount accepted for the swap to happen
    /// @param payload Bytes needed for 1Inch API
    function _swapOn1Inch(
        IERC20 inToken,
        uint256 minAmountOut,
        bytes memory payload
    ) internal returns (uint256 amountOut) {
        // Approve transfer to the `oneInch` router if it is the first time the token is used
        if (!oneInchAllowedToken[inToken]) {
            inToken.safeIncreaseAllowance(address(oneInch), type(uint256).max);
            oneInchAllowedToken[inToken] = true;
        }

        //solhint-disable-next-line
        (bool success, bytes memory result) = oneInch.call(payload);
        if (!success) _revertBytes(result);

        amountOut = abi.decode(result, (uint256));
        require(amountOut >= minAmountOut, "15");
    }

    /// @notice Internal function used for error handling
    function _revertBytes(bytes memory errMsg) internal pure {
        if (errMsg.length > 0) {
            //solhint-disable-next-line
            assembly {
                revert(add(32, errMsg), mload(errMsg))
            }
        }
        revert("117");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/// @title IFeeDistributor
/// @author Interface of the `FeeDistributor` contract
/// @dev This interface is used by the `SurplusConverter` contract to send funds to the `FeeDistributor`
interface IFeeDistributor {
    function burn(address token) external;
}

/// @title IFeeDistributorFront
/// @author Interface for public use of the `FeeDistributor` contract
/// @dev This interface is used for user related function
interface IFeeDistributorFront {
    function token() external returns (address);

    function claim(address _addr) external returns (uint256);

    function claim(address[20] memory _addr) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface ILiquidityGauge {
    // solhint-disable-next-line
    function staking_token() external returns (address stakingToken);

    // solhint-disable-next-line
    function deposit_reward_token(address _rewardToken, uint256 _amount) external;

    function deposit(
        uint256 _value,
        address _addr,
        // solhint-disable-next-line
        bool _claim_rewards
    ) external;

    // solhint-disable-next-line
    function claim_rewards(address _addr) external;

    // solhint-disable-next-line
    function claim_rewards(address _addr, address _receiver) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title ISanToken
/// @author Angle Core Team
/// @notice Interface for Angle's `SanToken` contract that handles sanTokens, tokens that are given to SLPs
/// contributing to a collateral for a given stablecoin
interface ISanToken is IERC20Upgradeable {
    // ================================== StableMaster =============================

    function mint(address account, uint256 amount) external;

    function burnFrom(
        uint256 amount,
        address burner,
        address sender
    ) external;

    function burnSelf(uint256 amount, address burner) external;

    function stableMaster() external view returns (address);

    function poolManager() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Normally just importing `IPoolManager` should be sufficient, but for clarity here
// we prefer to import all concerned interfaces
import "./IPoolManager.sol";
import "./IOracle.sol";
import "./IPerpetualManager.sol";
import "./ISanToken.sol";

// Struct to handle all the parameters to manage the fees
// related to a given collateral pool (associated to the stablecoin)
struct MintBurnData {
    // Values of the thresholds to compute the minting fees
    // depending on HA hedge (scaled by `BASE_PARAMS`)
    uint64[] xFeeMint;
    // Values of the fees at thresholds (scaled by `BASE_PARAMS`)
    uint64[] yFeeMint;
    // Values of the thresholds to compute the burning fees
    // depending on HA hedge (scaled by `BASE_PARAMS`)
    uint64[] xFeeBurn;
    // Values of the fees at thresholds (scaled by `BASE_PARAMS`)
    uint64[] yFeeBurn;
    // Max proportion of collateral from users that can be covered by HAs
    // It is exactly the same as the parameter of the same name in `PerpetualManager`, whenever one is updated
    // the other changes accordingly
    uint64 targetHAHedge;
    // Minting fees correction set by the `FeeManager` contract: they are going to be multiplied
    // to the value of the fees computed using the hedge curve
    // Scaled by `BASE_PARAMS`
    uint64 bonusMalusMint;
    // Burning fees correction set by the `FeeManager` contract: they are going to be multiplied
    // to the value of the fees computed using the hedge curve
    // Scaled by `BASE_PARAMS`
    uint64 bonusMalusBurn;
    // Parameter used to limit the number of stablecoins that can be issued using the concerned collateral
    uint256 capOnStableMinted;
}

// Struct to handle all the variables and parameters to handle SLPs in the protocol
// including the fraction of interests they receive or the fees to be distributed to
// them
struct SLPData {
    // Last timestamp at which the `sanRate` has been updated for SLPs
    uint256 lastBlockUpdated;
    // Fees accumulated from previous blocks and to be distributed to SLPs
    uint256 lockedInterests;
    // Max interests used to update the `sanRate` in a single block
    // Should be in collateral token base
    uint256 maxInterestsDistributed;
    // Amount of fees left aside for SLPs and that will be distributed
    // when the protocol is collateralized back again
    uint256 feesAside;
    // Part of the fees normally going to SLPs that is left aside
    // before the protocol is collateralized back again (depends on collateral ratio)
    // Updated by keepers and scaled by `BASE_PARAMS`
    uint64 slippageFee;
    // Portion of the fees from users minting and burning
    // that goes to SLPs (the rest goes to surplus)
    uint64 feesForSLPs;
    // Slippage factor that's applied to SLPs exiting (depends on collateral ratio)
    // If `slippage = BASE_PARAMS`, SLPs can get nothing, if `slippage = 0` they get their full claim
    // Updated by keepers and scaled by `BASE_PARAMS`
    uint64 slippage;
    // Portion of the interests from lending
    // that goes to SLPs (the rest goes to surplus)
    uint64 interestsForSLPs;
}

/// @title IStableMasterFunctions
/// @author Angle Core Team
/// @notice Interface for the `StableMaster` contract
interface IStableMasterFunctions {
    function deploy(
        address[] memory _governorList,
        address _guardian,
        address _agToken
    ) external;

    // ============================== Lending ======================================

    function accumulateInterest(uint256 gain) external;

    function signalLoss(uint256 loss) external;

    // ============================== HAs ==========================================

    function getStocksUsers() external view returns (uint256 maxCAmountInStable);

    function convertToSLP(uint256 amount, address user) external;

    // ============================== Keepers ======================================

    function getCollateralRatio() external returns (uint256);

    function setFeeKeeper(
        uint64 feeMint,
        uint64 feeBurn,
        uint64 _slippage,
        uint64 _slippageFee
    ) external;

    // ============================== AgToken ======================================

    function updateStocksUsers(uint256 amount, address poolManager) external;

    // ============================= Governance ====================================

    function setCore(address newCore) external;

    function addGovernor(address _governor) external;

    function removeGovernor(address _governor) external;

    function setGuardian(address newGuardian, address oldGuardian) external;

    function revokeGuardian(address oldGuardian) external;

    function setCapOnStableAndMaxInterests(
        uint256 _capOnStableMinted,
        uint256 _maxInterestsDistributed,
        IPoolManager poolManager
    ) external;

    function setIncentivesForSLPs(
        uint64 _feesForSLPs,
        uint64 _interestsForSLPs,
        IPoolManager poolManager
    ) external;

    function setUserFees(
        IPoolManager poolManager,
        uint64[] memory _xFee,
        uint64[] memory _yFee,
        uint8 _mint
    ) external;

    function setTargetHAHedge(uint64 _targetHAHedge) external;

    function pause(bytes32 agent, IPoolManager poolManager) external;

    function unpause(bytes32 agent, IPoolManager poolManager) external;
}

/// @title IStableMaster
/// @author Angle Core Team
/// @notice Previous interface with additionnal getters for public variables and mappings
interface IStableMaster is IStableMasterFunctions {
    function agToken() external view returns (address);

    function collateralMap(IPoolManager poolManager)
        external
        view
        returns (
            IERC20 token,
            ISanToken sanToken,
            IPerpetualManager perpetualManager,
            IOracle oracle,
            uint256 stocksUsers,
            uint256 sanRate,
            uint256 collatBase,
            SLPData memory slpData,
            MintBurnData memory feeData
        );
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "../interfaces/IPoolManager.sol";

/// @title IStableMasterFront
/// @author Angle Core Team
/// @dev Front interface, meaning only user-facing functions
interface IStableMasterFront {
    function mint(
        uint256 amount,
        address user,
        IPoolManager poolManager,
        uint256 minStableAmount
    ) external;

    function burn(
        uint256 amount,
        address burner,
        address dest,
        IPoolManager poolManager,
        uint256 minCollatAmount
    ) external;

    function deposit(
        uint256 amount,
        address user,
        IPoolManager poolManager
    ) external;

    function withdraw(
        uint256 amount,
        address burner,
        address dest,
        IPoolManager poolManager
    ) external;

    function agToken() external returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title IVeANGLE
/// @author Angle Core Team
/// @notice Interface for the `VeANGLE` contract
interface IVeANGLE {
    // solhint-disable-next-line func-name-mixedcase
    function deposit_for(address addr, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
}

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IUniswapV3Router {
    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

/// @title Router for price estimation functionality
/// @notice Functions for getting the price of one token with respect to another using Uniswap V2
/// @dev This interface is only used for non critical elements of the protocol
interface IUniswapV2Router {
    /// @notice Given an input asset amount, returns the maximum output amount of the
    /// other asset (accounting for fees) given reserves.
    /// @param path Addresses of the pools used to get prices
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 swapAmount,
        uint256 minExpected,
        address[] calldata path,
        address receiver,
        uint256 swapDeadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IFeeManager.sol";
import "./IPerpetualManager.sol";
import "./IOracle.sol";

// Struct for the parameters associated to a strategy interacting with a collateral `PoolManager`
// contract
struct StrategyParams {
    // Timestamp of last report made by this strategy
    // It is also used to check if a strategy has been initialized
    uint256 lastReport;
    // Total amount the strategy is expected to have
    uint256 totalStrategyDebt;
    // The share of the total assets in the `PoolManager` contract that the `strategy` can access to.
    uint256 debtRatio;
}

/// @title IPoolManagerFunctions
/// @author Angle Core Team
/// @notice Interface for the collateral poolManager contracts handling each one type of collateral for
/// a given stablecoin
/// @dev Only the functions used in other contracts of the protocol are left here
interface IPoolManagerFunctions {
    // ============================ Constructor ====================================

    function deployCollateral(
        address[] memory governorList,
        address guardian,
        IPerpetualManager _perpetualManager,
        IFeeManager feeManager,
        IOracle oracle
    ) external;

    // ============================ Yield Farming ==================================

    function creditAvailable() external view returns (uint256);

    function debtOutstanding() external view returns (uint256);

    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external;

    // ============================ Governance =====================================

    function addGovernor(address _governor) external;

    function removeGovernor(address _governor) external;

    function setGuardian(address _guardian, address guardian) external;

    function revokeGuardian(address guardian) external;

    function setFeeManager(IFeeManager _feeManager) external;

    // ============================= Getters =======================================

    function getBalance() external view returns (uint256);

    function getTotalAsset() external view returns (uint256);
}

/// @title IPoolManager
/// @author Angle Core Team
/// @notice Previous interface with additionnal getters for public variables and mappings
/// @dev Used in other contracts of the protocol
interface IPoolManager is IPoolManagerFunctions {
    function stableMaster() external view returns (address);

    function perpetualManager() external view returns (address);

    function token() external view returns (address);

    function feeManager() external view returns (address);

    function totalDebt() external view returns (uint256);

    function strategies(address _strategy) external view returns (StrategyParams memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/// @title IOracle
/// @author Angle Core Team
/// @notice Interface for Angle's oracle contracts reading oracle rates from both UniswapV3 and Chainlink
/// from just UniswapV3 or from just Chainlink
interface IOracle {
    function read() external view returns (uint256);

    function readAll() external view returns (uint256 lowerRate, uint256 upperRate);

    function readLower() external view returns (uint256);

    function readUpper() external view returns (uint256);

    function readQuote(uint256 baseAmount) external view returns (uint256);

    function readQuoteLower(uint256 baseAmount) external view returns (uint256);

    function inBase() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IERC721.sol";
import "./IFeeManager.sol";
import "./IOracle.sol";
import "./IAccessControl.sol";

/// @title Interface of the contract managing perpetuals
/// @author Angle Core Team
/// @dev Front interface, meaning only user-facing functions
interface IPerpetualManagerFront is IERC721Metadata {
    function openPerpetual(
        address owner,
        uint256 amountBrought,
        uint256 amountCommitted,
        uint256 maxOracleRate,
        uint256 minNetMargin
    ) external returns (uint256 perpetualID);

    function closePerpetual(
        uint256 perpetualID,
        address to,
        uint256 minCashOutAmount
    ) external;

    function addToPerpetual(uint256 perpetualID, uint256 amount) external;

    function removeFromPerpetual(
        uint256 perpetualID,
        uint256 amount,
        address to
    ) external;

    function liquidatePerpetuals(uint256[] memory perpetualIDs) external;

    function forceClosePerpetuals(uint256[] memory perpetualIDs) external;

    // ========================= External View Functions =============================

    function getCashOutAmount(uint256 perpetualID, uint256 rate) external view returns (uint256, uint256);

    function isApprovedOrOwner(address spender, uint256 perpetualID) external view returns (bool);
}

/// @title Interface of the contract managing perpetuals
/// @author Angle Core Team
/// @dev This interface does not contain user facing functions, it just has functions that are
/// interacted with in other parts of the protocol
interface IPerpetualManagerFunctions is IAccessControl {
    // ================================= Governance ================================

    function deployCollateral(
        address[] memory governorList,
        address guardian,
        IFeeManager feeManager,
        IOracle oracle_
    ) external;

    function setFeeManager(IFeeManager feeManager_) external;

    function setHAFees(
        uint64[] memory _xHAFees,
        uint64[] memory _yHAFees,
        uint8 deposit
    ) external;

    function setTargetAndLimitHAHedge(uint64 _targetHAHedge, uint64 _limitHAHedge) external;

    function setKeeperFeesLiquidationRatio(uint64 _keeperFeesLiquidationRatio) external;

    function setKeeperFeesCap(uint256 _keeperFeesLiquidationCap, uint256 _keeperFeesClosingCap) external;

    function setKeeperFeesClosing(uint64[] memory _xKeeperFeesClosing, uint64[] memory _yKeeperFeesClosing) external;

    function setLockTime(uint64 _lockTime) external;

    function setBoundsPerpetual(uint64 _maxLeverage, uint64 _maintenanceMargin) external;

    function pause() external;

    function unpause() external;

    // ==================================== Keepers ================================

    function setFeeKeeper(uint64 feeDeposit, uint64 feesWithdraw) external;

    // =============================== StableMaster ================================

    function setOracle(IOracle _oracle) external;
}

/// @title IPerpetualManager
/// @author Angle Core Team
/// @notice Previous interface with additionnal getters for public variables
interface IPerpetualManager is IPerpetualManagerFunctions {
    function poolManager() external view returns (address);

    function oracle() external view returns (address);

    function targetHAHedge() external view returns (uint64);

    function totalHedgeAmount() external view returns (uint256);
}

/// @title Interface of the contract managing perpetuals with claim function
/// @author Angle Core Team
/// @dev Front interface with rewards function, meaning only user-facing functions
interface IPerpetualManagerFrontWithClaim is IPerpetualManagerFront, IPerpetualManager {
    function getReward(uint256 perpetualID) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IAccessControl.sol";

/// @title IFeeManagerFunctions
/// @author Angle Core Team
/// @dev Interface for the `FeeManager` contract
interface IFeeManagerFunctions is IAccessControl {
    // ================================= Keepers ===================================

    function updateUsersSLP() external;

    function updateHA() external;

    // ================================= Governance ================================

    function deployCollateral(
        address[] memory governorList,
        address guardian,
        address _perpetualManager
    ) external;

    function setFees(
        uint256[] memory xArray,
        uint64[] memory yArray,
        uint8 typeChange
    ) external;

    function setHAFees(uint64 _haFeeDeposit, uint64 _haFeeWithdraw) external;
}

/// @title IFeeManager
/// @author Angle Core Team
/// @notice Previous interface with additionnal getters for public variables and mappings
/// @dev We need these getters as they are used in other contracts of the protocol
interface IFeeManager is IFeeManagerFunctions {
    function stableMaster() external view returns (address);

    function perpetualManager() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/// @title IAccessControl
/// @author Forked from OpenZeppelin
/// @notice Interface for `AccessControl` contracts
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

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