// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.11;

import "./interfaces/IAaveV2StablecoinCellar.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./interfaces/ILendingPool.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/MathUtils.sol";
import "./interfaces/IAaveIncentivesController.sol";
import "./interfaces/IStakedTokenV2.sol";
import "./interfaces/ISushiSwapRouter.sol";
import "./interfaces/IGravity.sol";

/**
 * @title Sommelier AaveV2 Stablecoin Cellar contract
 * @notice AaveV2StablecoinCellar contract for Sommelier Network
 * @author Sommelier Finance
 */
contract AaveV2StablecoinCellar is IAaveV2StablecoinCellar, ERC20, ReentrancyGuard, Ownable {
    using SafeTransferLib for ERC20;

    struct UserDeposit {
        uint256 assets;
        uint256 shares;
        uint256 timeDeposited;
    }

    // Uniswap Router V3 contract
    ISwapRouter public immutable uniswapRouter; // 0xE592427A0AEce92De3Edee1F18E0157C05861564
    // SushiSwap Router V2 contract
    ISushiSwapRouter public immutable sushiSwapRouter; // 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F
    // Aave Lending Pool V2 contract
    ILendingPool public immutable lendingPool; // 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9
    // Aave Incentives Controller V2 contract
    IAaveIncentivesController public immutable incentivesController; // 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5
    // Cosmos Gravity Bridge contract
    Gravity public immutable gravityBridge; // 0x69592e6f9d21989a043646fE8225da2600e5A0f7
    // Cosmos address of fee distributor
    bytes32 public feesDistributor; // TBD
    IStakedTokenV2 public immutable stkAAVE; // 0x4da27a545c0c5B758a6BA100e3a049001de870f5

    address public immutable AAVE; // 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9
    address public immutable WETH; // 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    address public immutable USDC; // 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48

    // Declare the variables and mappings.
    mapping(address => bool) public inputTokens;
    // The address of the token of the current lending position
    address public currentLendingToken;
    address public currentAToken;
    // Track user user deposits to determine active/inactive shares.
    mapping(address => UserDeposit[]) public userDeposits;
    // Last time inactive funds were entered into a strategy and made active.
    uint256 public lastTimeEnteredStrategy;

    // Restrict liquidity and deposits per wallet until after security audits.
    // TODO: fix this
    uint256 public maxDeposit = 50_000e18; // $50k
    uint256 public maxLiquidity = 5_000_000e18; // $5m

    uint24 public constant POOL_FEE = 3000;

    uint256 public constant DENOMINATOR = 10_000;
    uint256 public constant SECS_PER_YEAR = 31_556_952;
    uint256 public constant PLATFORM_FEE = 100;
    uint256 public constant PERFORMANCE_FEE = 500;

    uint256 public lastTimeAccruedPlatformFees;
    // Fees are taken in shares and redeemed for assets at the time they are transferred.
    uint256 public accruedPlatformFees;
    uint256 public accruedPerformanceFees;

    // Emergency states in case of contract malfunction.
    bool public isPaused;
    bool public isShutdown;

    /**
     * @param _uniswapRouter Uniswap V3 swap router address
     * @param _lendingPool Aave V2 lending pool address
     * @param _incentivesController _incentivesController
     * @param _gravityBridge Cosmos Gravity Bridge address
     * @param _stkAAVE stkAAVE address
     * @param _AAVE AAVE address
     * @param _WETH WETH address
     * @param _currentLendingToken token of lending pool where the cellar has its liquidity deposited
     */
    constructor(
        ISwapRouter _uniswapRouter,
        ISushiSwapRouter _sushiSwapRouter,
        ILendingPool _lendingPool,
        IAaveIncentivesController _incentivesController,
        Gravity _gravityBridge,
        IStakedTokenV2 _stkAAVE,
        address _AAVE,
        address _WETH,
        address _USDC,
        address _currentLendingToken
    ) ERC20("Sommelier Aave V2 Stablecoin Cellar LP Token", "sommSAAVE", 18) Ownable() {
        uniswapRouter =  _uniswapRouter;
        sushiSwapRouter = _sushiSwapRouter;
        lendingPool = _lendingPool;
        incentivesController = _incentivesController;
        gravityBridge = _gravityBridge;
        stkAAVE = _stkAAVE;
        AAVE = _AAVE;
        WETH = _WETH;
        USDC = _USDC;

        _updateLendingPosition(_currentLendingToken);

        lastTimeAccruedPlatformFees = block.timestamp;
    }

    // NOTE: For beta only
    function setFeeDistributor(bytes32 _newFeeDistributor) external onlyOwner {
        feesDistributor = _newFeeDistributor;
    }

    /**
     * @notice Deposit supported tokens into the cellar.
     * @param token address of the supported token to deposit
     * @param assets amount of assets to deposit
     * @param minAssetsIn minimum amount of assets cellar should receive after swap (if applicable)
     * @param receiver address that should receive shares
     * @return shares amount of shares minted to receiver
     */
    function deposit(
        address token,
        uint256 assets,
        uint256 minAssetsIn,
        address receiver
    ) public nonReentrant returns (uint256 shares) {
        if (isPaused) revert ContractPaused();
        if (isShutdown) revert ContractShutdown();

        if (!inputTokens[token]) revert UnapprovedToken(token);
        if (maxLiquidity != 0 && assets + totalAssets() > maxLiquidity)
            revert LiquidityRestricted(totalAssets(), maxLiquidity);
        if (maxDeposit != 0 && ERC20(token).balanceOf(msg.sender) + assets > maxDeposit)
            revert DepositRestricted(ERC20(token).balanceOf(msg.sender), maxDeposit);

        uint256 balance = ERC20(token).balanceOf(msg.sender);
        if (assets > balance) assets = balance;

        ERC20(token).safeTransferFrom(msg.sender, address(this), assets);

        if (token != currentLendingToken) {
            assets = _swap(token, currentLendingToken, assets, minAssetsIn);
        }

        // Must calculate shares as if assets were not yet transfered in.
        if ((shares = _convertToShares(assets, assets)) == 0) revert ZeroAssets();

        _mint(receiver, shares);

        UserDeposit[] storage deposits = userDeposits[receiver];
        deposits.push(UserDeposit({
            assets: assets,
            shares: shares,
            timeDeposited: block.timestamp
        }));

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function deposit(uint256 assets) external returns (uint256) {
        return deposit(currentLendingToken, assets, assets, msg.sender);
    }

    /// @dev For ERC4626 compatibility.
    function deposit(uint256 assets, address receiver) external returns (uint256) {
        return deposit(currentLendingToken, assets, assets, receiver);
    }

    /**
     * @notice Withdraw from the cellar.
     * @param assets amount of assets to withdraw
     * @param receiver address that should receive assets
     * @param owner address that should own the shares
     * @return shares amount of shares burned from owner
     */
    function withdraw(uint256 assets, address receiver, address owner) public returns (uint256 shares) {
        if (assets == 0) revert ZeroAssets();
        if (balanceOf[owner] == 0) revert ZeroShares();

        uint256 withdrawnActiveShares;
        uint256 withdrawnInactiveShares;
        uint256 withdrawnInactiveAssets;
        uint256 originalDepositedAssets; // Used for calculating performance fees.

        // Saves gas by avoiding calling `convertToAssets` on active shares during each loop.
        uint256 exchangeRate = convertToAssets(1e18);

        UserDeposit[] storage deposits = userDeposits[owner];

        uint256 leftToWithdraw = assets;
        for (uint256 i = deposits.length - 1; i + 1 != 0; i--) {
            UserDeposit storage d = deposits[i];

            uint256 dAssets = d.assets;
            if (dAssets != 0) {
                uint256 dShares = d.shares;

                uint256 withdrawnAssets;
                uint256 withdrawnShares;

                // Check if deposit shares are active or inactive.
                if (d.timeDeposited < lastTimeEnteredStrategy) {
                    // Active:
                    dAssets = exchangeRate * dShares / 1e18;
                    withdrawnAssets = MathUtils.min(leftToWithdraw, dAssets);
                    withdrawnShares = MathUtils.mulDivUp(dShares, withdrawnAssets, dAssets);

                    uint256 originalDepositWithdrawn = MathUtils.mulDivUp(d.assets, withdrawnShares, dShares);
                    // Store to calculate performance fees on future withdraws.
                    d.assets -= originalDepositWithdrawn;

                    originalDepositedAssets += originalDepositWithdrawn;
                    withdrawnActiveShares += withdrawnShares;
                } else {
                    // Inactive:
                    withdrawnAssets = MathUtils.min(leftToWithdraw, dAssets);
                    withdrawnShares = MathUtils.mulDivUp(dShares, withdrawnAssets, dAssets);

                    d.assets -= withdrawnAssets;

                    withdrawnInactiveShares += withdrawnShares;
                    withdrawnInactiveAssets += withdrawnAssets;
                }

                d.shares -= withdrawnShares;

                leftToWithdraw -= withdrawnAssets;
            }

            if (i == 0 || leftToWithdraw == 0) break;
        }

        shares = withdrawnActiveShares + withdrawnInactiveShares;

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        uint256 withdrawnActiveAssets = exchangeRate * withdrawnActiveShares / 1e18;

        // Take performance fees.
        if (withdrawnActiveAssets > 0) {
            uint256 gain = withdrawnActiveAssets - originalDepositedAssets;
            uint256 feeInAssets = gain * PERFORMANCE_FEE / DENOMINATOR;
            uint256 fees = convertToShares(feeInAssets);

            if (fees > 0) {
                accruedPerformanceFees += fees;
                withdrawnActiveAssets -= feeInAssets;

                _mint(address(this), fees);
            }
        }

        _burn(owner, shares);

        if (withdrawnActiveAssets > 0) {
            if (!isShutdown) {
                // Withdraw tokens from Aave to receiver.
                lendingPool.withdraw(currentLendingToken, withdrawnActiveAssets, receiver);
            } else {
                ERC20(currentLendingToken).transfer(receiver, withdrawnActiveAssets);
            }
        }

        if (withdrawnInactiveAssets > 0) {
            ERC20(currentLendingToken).transfer(receiver, withdrawnInactiveAssets);
        }

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function withdraw(uint256 assets) external returns (uint256 shares) {
        return withdraw(assets, msg.sender, msg.sender);
    }

    /**
     * @notice Enters Aave stablecoin strategy.
     */
    function enterStrategy() external onlyOwner {
        if (isShutdown) revert ContractShutdown();

        _depositToAave(currentLendingToken, inactiveAssets());

        lastTimeEnteredStrategy = block.timestamp;
    }

    /**
     * @notice Reinvest stkAAVE rewards back into cellar's current position on Aave.
     * @dev Must be called in the 2 day unstake period started 10 days after claimAndUnstake was run.
     * @param amount amount of stkAAVE to redeem and reinvest
     * @param minAssetsOut minimum amount of assets cellar should receive after swap
     */
    // auction model:
    // - send stkaave to the bridge
    // - add functionality to distribute SOMM rewards
    function reinvest(uint256 amount, uint256 minAssetsOut) public onlyOwner {
        stkAAVE.redeem(address(this), amount);

        address[] memory path = new address[](3);
        path[0] = AAVE;
        path[1] = WETH;
        path[2] = currentLendingToken;

        uint256 amountIn = ERC20(AAVE).balanceOf(address(this));

        // Due to the lack of liquidity for AAVE on Uniswap, we use Sushiswap instead here.
        uint256 amountOut = _sushiswap(path, amountIn, minAssetsOut);

        if (!isShutdown) {
            _depositToAave(currentLendingToken, amountOut);
        }
    }

    function reinvest(uint256 minAssetsOut) external onlyOwner {
        reinvest(type(uint256).max, minAssetsOut);
    }

    /**
     * @notice Claim stkAAVE rewards from Aave and begin cooldown period to unstake.
     * @param amount amount of rewards to claim
     * @return claimed amount of rewards claimed from Aave
     */
    function claimAndUnstake(uint256 amount) public onlyOwner returns (uint256 claimed) {
        // Necessary as claimRewards accepts a dynamic array as first param.
        address[] memory aToken = new address[](1);
        aToken[0] = currentAToken;

        claimed = incentivesController.claimRewards(aToken, amount, address(this));

        stkAAVE.cooldown();
    }

    function claimAndUnstake() external onlyOwner returns (uint256) {
        return claimAndUnstake(type(uint256).max);
    }

    /**
     * @notice Deposits cellar holdings into Aave lending pool.
     * @param token the address of the token
     * @param assets the amount of token to be deposited
     */
    function _depositToAave(address token, uint256 assets) internal {
        ERC20(token).safeApprove(address(lendingPool), assets);

        // Deposit token to Aave protocol.
        lendingPool.deposit(token, assets, address(this), 0);

        emit DepositToAave(token, assets);
    }

    /**
     * @notice Redeems a token from Aave protocol.
     * @param token the address of the token
     * @param amount the token amount being redeemed
     * @return withdrawnAmount the withdrawn amount from Aave
     */
    function _redeemFromAave(address token, uint256 amount) internal returns (uint256 withdrawnAmount) {
        // Withdraw token from Aave protocol
        withdrawnAmount = lendingPool.withdraw(token, amount, address(this));

        emit RedeemFromAave(token, withdrawnAmount);
    }

    /**
     * @notice Rebalances of Aave lending position.
     * @param newLendingToken the address of the token of the new lending position
     */
    function rebalance(address newLendingToken, uint256 minNewLendingTokenAmount) external onlyOwner {
        if (!inputTokens[newLendingToken]) revert UnapprovedToken(newLendingToken);
        if (isShutdown) revert ContractShutdown();

        if(newLendingToken == currentLendingToken) revert SameLendingToken(newLendingToken);

        uint256 lendingPositionBalance = _redeemFromAave(currentLendingToken, type(uint256).max);

        address[] memory path = new address[](2);
        path[0] = currentLendingToken;
        path[1] = newLendingToken;

        uint256 newLendingTokenAmount = _multihopSwap(
            path,
            lendingPositionBalance,
            minNewLendingTokenAmount
        );

        _updateLendingPosition(newLendingToken);

        _depositToAave(newLendingToken, newLendingTokenAmount);

        emit Rebalance(newLendingToken, newLendingTokenAmount);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        if (from != msg.sender) {
            uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;
        }

        balanceOf[from] -= amount;

        UserDeposit[] storage depositsFrom = userDeposits[from];
        UserDeposit[] storage depositsTo = userDeposits[to];

        // NOTE: Flag this for auditors.
        uint256 leftToTransfer = amount;
        for (uint256 i = depositsFrom.length - 1; i + 1 != 0; i--) {
            UserDeposit storage dFrom = depositsFrom[i];

            uint256 dFromShares = dFrom.shares;
            if (dFromShares != 0) {
                uint256 transferShares = MathUtils.min(leftToTransfer, dFromShares);
                uint256 transferAssets = MathUtils.mulDivUp(dFrom.assets, transferShares, dFromShares);

                dFrom.shares -= transferShares;
                dFrom.assets -= transferAssets;

                depositsTo.push(UserDeposit({
                    assets: transferAssets,
                    shares: transferShares,
                    timeDeposited: dFrom.timeDeposited
                }));

                leftToTransfer -= transferShares;
            }

            if (i == 0 || leftToTransfer == 0) break;
        }

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /// @notice Take platform fees off of cellar's active assets.
    function accruePlatformFees() external {
        uint256 elapsedTime = block.timestamp - lastTimeAccruedPlatformFees;
        uint256 feeInAssets = (activeAssets() * elapsedTime * PLATFORM_FEE) / DENOMINATOR / SECS_PER_YEAR;
        uint256 fees = convertToShares(feeInAssets);

        _mint(address(this), fees);

        accruedPlatformFees += fees;
    }

    /// @notice Transfer accrued fees to Cosmos to distribute.
    function transferFees() external onlyOwner {
        uint256 fees = accruedPerformanceFees + accruedPlatformFees;
        uint256 feeInAssets = convertToAssets(fees);

        // Only withdraw from Aave if holding pool does not contain enough funds.
        uint256 holdingPoolAssets = inactiveAssets();
        if (holdingPoolAssets < feeInAssets) {
            _redeemFromAave(currentLendingToken, feeInAssets - holdingPoolAssets);
        }

        _burn(address(this), fees);

        ERC20(currentLendingToken).approve(address(gravityBridge), feeInAssets);
        gravityBridge.sendToCosmos(currentLendingToken, feesDistributor, feeInAssets);

        accruedPlatformFees = 0;
        accruedPerformanceFees = 0;

        emit TransferFees(fees, feeInAssets);
    }

    /**
     * @notice Set approval for a token to be deposited into the cellar.
     * @param token the address of the supported token
     */
    function setInputToken(address token, bool isApproved) external onlyOwner {
        _validateTokenOnAave(token); // Only allow input tokens supported by Aave.

        inputTokens[token] = isApproved;

        emit SetInputToken(token, isApproved);
    }

    /// @notice Removes initial liquidity restriction.
    function removeLiquidityRestriction() external onlyOwner {
        delete maxDeposit;
        delete maxLiquidity;

        emit LiquidityRestrictionRemoved();
    }

    /**
     * @notice Pause the contract, prevents depositing.
     * @param _isPaused whether the contract should be paused
     */
    function setPause(bool _isPaused) external onlyOwner {
        if (isShutdown) revert ContractShutdown();

        isPaused = _isPaused;

        emit Pause(msg.sender, _isPaused);
    }

    /**
     * @notice Stops the contract - this is irreversible. Should only be used in an emergency,
     *         for example an irreversible accounting bug or an exploit.
     */
    function shutdown() external onlyOwner {
        if (isShutdown) revert AlreadyShutdown();

        // Update state and put in irreversible emergency mode.
        isShutdown = true;

        // Ensure contract is not paused.
        isPaused = false;

        if (activeAssets() > 0) {
            // Withdraw everything from Aave.
            _redeemFromAave(currentLendingToken, type(uint256).max);
        }

        emit Shutdown(msg.sender);
    }

    /**
     * @notice Removes tokens from this cellar that are not the type of token managed
     *         by this cellar. This may be used in case of accidentally sending the
     *         wrong kind of token to this contract.
     * @param token address of token to transfer out of this cellar
     */
    function sweep(address token) external onlyOwner {
        if (inputTokens[token] || token == currentAToken || token == address(this))
            revert ProtectedToken(token);

        uint256 amount = ERC20(token).balanceOf(address(this));
        ERC20(token).safeTransfer(msg.sender, amount);

        emit Sweep(token, amount);
    }

    /**
     * @notice Swaps input token by Uniswap V3.
     * @param tokenIn the address of the incoming token
     * @param tokenOut the address of the outgoing token
     * @param amountIn the amount of tokens to be swapped
     * @param amountOutMinimum the minimum amount of tokens returned
     * @return amountOut the amount of tokens received after swap
     */
    function _swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) internal returns (uint256 amountOut) {
        // Approve the router to spend tokenIn.
        ERC20(tokenIn).safeApprove(address(uniswapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: POOL_FEE,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap.
        amountOut = uniswapRouter.exactInputSingle(params);

        emit Swapped(tokenIn, amountIn, tokenOut, amountOut);
    }

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) external onlyOwner returns (uint256 amountOut) {
        return _swap(tokenIn, tokenOut, amountIn, amountOutMinimum);
    }

    /**
     * @notice Swaps tokens by multihop swap in Uniswap V3.
     * @param path the token swap path (token addresses)
     * @param amountIn the amount of tokens to be swapped
     * @param amountOutMinimum the minimum amount of tokens returned
     * @return amountOut the amount of tokens received after swap
     */
    function _multihopSwap(
        address[] memory path,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) internal returns (uint256 amountOut) {
        // Approve the router to spend first token in path.
        address tokenIn = path[0];
        ERC20(tokenIn).safeApprove(address(uniswapRouter), amountIn);

        bytes memory encodePackedPath = abi.encodePacked(tokenIn);
        for (uint256 i = 1; i < path.length; i++) {
            encodePackedPath = abi.encodePacked(
                encodePackedPath,
                POOL_FEE,
                path[i]
            );
        }

        // Multiple pool swaps are encoded through bytes called a `path`. A path
        // is a sequence of token addresses and poolFees that define the pools
        // used in the swaps. The format for pool encoding is (tokenIn, fee,
        // tokenOut/tokenIn, fee, tokenOut) where tokenIn/tokenOut parameter is
        // the shared token across the pools.
        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: encodePackedPath,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum
            });

        // Executes the swap.
        amountOut = uniswapRouter.exactInput(params);

        emit Swapped(tokenIn, amountIn, path[path.length - 1], amountOut);
    }

    function multihopSwap(
        address[] memory path,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) external onlyOwner returns (uint256) {
        return _multihopSwap(path, amountIn, amountOutMinimum);
    }

    /**
     * @notice Swaps tokens by SushiSwap Router.
     * @param path the token swap path (token addresses)
     * @param amountIn the amount of tokens to be swapped
     * @param amountOutMinimum the minimum amount of tokens returned
     * @return amountOut the amount of tokens received after swap
     */
    function _sushiswap(
        address[] memory path,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) internal returns (uint256 amountOut) {
        address tokenIn = path[0];

        // Approve the router to spend first token in path.
        ERC20(tokenIn).safeApprove(address(sushiSwapRouter), amountIn);

        uint256[] memory amounts = sushiSwapRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMinimum,
            path,
            address(this),
            block.timestamp + 60
        );

        amountOut = amounts[amounts.length - 1];

        emit Swapped(tokenIn, amountIn, path[path.length - 1], amountOut);
    }

    function sushiswap(
        address[] memory path,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) external onlyOwner returns (uint256) {
        return _sushiswap(path, amountIn, amountOutMinimum);
    }


    /// @notice Total amount of inactive asset waiting in a holding pool to be entered into a strategy.
    function inactiveAssets() public view returns (uint256) {
        return ERC20(currentLendingToken).balanceOf(address(this));
    }

    /// @notice Total amount of active asset entered into a strategy.
    function activeAssets() public view returns (uint256) {
        // The aTokens' value is pegged to the value of the corresponding deposited
        // asset at a 1:1 ratio, so we can find the amount of assets active in a
        // strategy simply by taking balance of aTokens cellar holds.
        return ERC20(currentAToken).balanceOf(address(this));
    }

    /// @notice Total amount of the underlying asset that is managed by cellar.
    function totalAssets() public view returns (uint256) {
        return activeAssets() + inactiveAssets();
    }

    /**
     * @notice The amount of shares that the cellar would exchange for the amount of assets provided.
     * @param assets amount of assets to convert
     * @param offset amount to negatively offset total assets during calculation
     */
    function _convertToShares(uint256 assets, uint256 offset) internal view returns (uint256) {
        return totalSupply == 0 ? assets : MathUtils.mulDivDown(assets, totalSupply, totalAssets() - offset);
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        return _convertToShares(assets, 0);
    }

    /**
     * @notice The amount of assets that the cellar would exchange for the amount of shares provided.
     * @param shares amount of shares to convert
     */
    function convertToAssets(uint256 shares) public view returns (uint256) {
        return totalSupply == 0 ? shares : MathUtils.mulDivDown(shares, totalAssets(), totalSupply);
    }

    /**
     * @notice Check if a token is being supported by Aave.
     * @param token address of the token being checked
     * @return aTokenAddress address of the token's aToken version on Aave
     */
    function _validateTokenOnAave(address token) internal view returns (address aTokenAddress) {
        (, , , , , , , aTokenAddress, , , , ) = lendingPool.getReserveData(token);

        if (aTokenAddress == address(0)) revert TokenIsNotSupportedByAave(token);
    }

    /**
     * @notice Update the current lending tokening and current aToken.
     * @param newLendingToken address of the new lending token
     */
    function _updateLendingPosition(address newLendingToken) internal {
        address aTokenAddress = _validateTokenOnAave(newLendingToken);

        currentLendingToken = newLendingToken;
        currentAToken = aTokenAddress;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.11;

/// @title interface for AaveV2StablecoinCellar
interface IAaveV2StablecoinCellar {
    /**
     * @notice Emitted when assets are deposited into cellar.
     * @param caller the address of the caller
     * @param owner the address of the owner of shares
     * @param assets the amount of assets being deposited
     * @param shares the amount of shares minted to owner
     */
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    /**
     * @notice Emitted when assets are withdrawn from cellar.
     * @param caller the address of the caller
     * @param owner the address of the owner of shares
     * @param assets the amount of assets being withdrawn
     * @param shares the amount of shares burned from owner
     */
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @notice Emitted when tokens swapped.
     * @param tokenIn the address of the tokenIn
     * @param amountIn the amount of the tokenIn
     * @param tokenOut the address of the tokenOut
     * @param amountOut the amount of the tokenOut
     */
    event Swapped(
        address indexed tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut
    );

    /**
     * @notice Emitted on deposit to Aave.
     * @param token the address of the token of the lending position
     * @param assets the amount that has been deposited
     */
    event DepositToAave(
        address indexed token,
        uint256 assets
    );

    /**
     * @notice Emitted on redeem from Aave.
     * @param token the address of the redeemed token
     * @param assets the amount that has been redeemed
     */
    event RedeemFromAave(
        address indexed token,
        uint256 assets
    );

    /**
     * @notice Emitted on rebalance of Aave lending position.
     * @param token the address of the token of the new lending position
     * @param assets the amount that has been deposited
     */
    event Rebalance(
        address indexed token,
        uint256 assets
    );

    /**
     * @notice Emitted when platform fees are transferred to Cosmos.
     * @param feeInShares amount of fees transferred (in shares)
     * @param feeInAssets amount of fees transferred (in assets)
     */
    event TransferFees(uint256 feeInShares, uint256 feeInAssets);

    /**
     * @notice Emitted when liquidity restriction removed.
     */
    event LiquidityRestrictionRemoved();

    /**
     * @notice Emitted when tokens accidently sent to cellar are recovered.
     * @param token the address of the token
     * @param amount amount transferred out
     */
    event Sweep(address indexed token, uint256 amount);

    /**
     * @notice Emitted when an input token is approved or unapproved.
     * @param token the address of the token
     * @param isApproved whether it is approved
     */
    event SetInputToken(address token, bool isApproved);

    /**
     * @notice Emitted when cellar is paused.
     * @param caller address that set the pause
     * @param isPaused whether the contract is paused
     */
    event Pause(address caller, bool isPaused);

    /**
     * @notice Emitted when cellar is shutdown.
     * @param caller address that called the shutdown
     */
    event Shutdown(address caller);

    /**
     * @notice Attempted an action with a token that is not approved.
     * @param unapprovedToken address of the unapproved token
     */
    error UnapprovedToken(address unapprovedToken);

    /**
     * @notice Attempted an action with zero assets.
     */
    error ZeroAssets();

    /**
     * @notice Attempted an action with zero shares.
     */
    error ZeroShares();

    /**
     * @notice Attempted deposit more liquidity over the liquidity limit.
     * @param currentLiquidity the current liquidity
     * @param maxLiquidity the max liquidity
     */
    error LiquidityRestricted(uint256 currentLiquidity, uint256 maxLiquidity);

    /**
     * @notice Attempted deposit more than the per wallet limit.
     * @param currentDeposit the current deposit
     * @param maxDeposit the max deposit
     */
    error DepositRestricted(uint256 currentDeposit, uint256 maxDeposit);

    /**
     * @notice Current lending token is updated to an asset not supported by Aave.
     * @param unsupportedToken address of the unsupported token
     */
    error TokenIsNotSupportedByAave(address unsupportedToken);

    /**
     * @notice Attempted to sweep an asset that is managed by the cellar.
     * @param protectedToken address of the unsupported token
     */
    error ProtectedToken(address protectedToken);

    /**
     * @notice Attempted rebalance into the same lending token.
     * @param lendingToken address of the lending token
     */
    error SameLendingToken(address lendingToken);

    /**
     * @notice Attempted action was prevented due to contract being shutdown.
     */
    error ContractShutdown();

    /**
     * @notice Attempted action was prevented due to contract being paused.
     */
    error ContractPaused();

    /**
     * @notice Attempted to shutdown the contract when it was already shutdown.
     */
    error AlreadyShutdown();

    function deposit(
        address token,
        uint256 assets,
        uint256 minAssetsIn,
        address receiver
    ) external returns (uint256 shares);

    function deposit(uint256 assets) external returns (uint256);

    function deposit(uint256 assets, address receiver) external returns (uint256);

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    function withdraw(uint256 assets) external returns (uint256 shares);

    function inactiveAssets() external view returns (uint256);

    function activeAssets() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) external returns (uint256 amountOut);

    function multihopSwap(
        address[] memory path,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) external returns (uint256);

    function sushiswap(
        address[] memory path,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) external returns (uint256);

    function enterStrategy() external;

    function reinvest(uint256 amount, uint256 minAssetsOut) external;

    function reinvest(uint256 minAssetsOut) external;

    function claimAndUnstake(uint256 amount) external returns (uint256 claimed);

    function claimAndUnstake() external returns (uint256);

    function rebalance(address newLendingToken, uint256 minNewLendingTokenAmount) external;

    function accruePlatformFees() external;

    function transferFees() external;

    function setInputToken(address token, bool isApproved) external;

    function removeLiquidityRestriction() external;

    function sweep(address token) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.11;

/**
 * @dev Partial interface for a Aave LendingPool contract,
 * which is the main point of interaction with an Aave protocol's market
 **/
interface ILendingPool {
    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (
            //stores the reserve configuration
            //bit 0-15: LTV
            //bit 16-31: Liq. threshold
            //bit 32-47: Liq. bonus
            //bit 48-55: Decimals
            //bit 56: Reserve is active
            //bit 57: reserve is frozen
            //bit 58: borrowing is enabled
            //bit 59: stable rate borrowing enabled
            //bit 60-63: reserved
            //bit 64-79: reserve factor
            uint256 configuration,
            //the liquidity index. Expressed in ray
            uint128 liquidityIndex,
            //variable borrow index. Expressed in ray
            uint128 variableBorrowIndex,
            //the current supply rate. Expressed in ray
            uint128 currentLiquidityRate,
            //the current variable borrow rate. Expressed in ray
            uint128 currentVariableBorrowRate,
            //the current stable borrow rate. Expressed in ray
            uint128 currentStableBorrowRate,
            uint40 lastUpdateTimestamp,
            //tokens addresses
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress,
            //address of the interest rate strategy
            address interestRateStrategyAddress,
            //the id of the reserve. Represents the position in the list of the active reserves
            uint8 id
        );
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    modifier nonReentrant() {
        require(reentrancyStatus == 1, "REENTRANCY");

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
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

pragma solidity 0.8.11;

library MathUtils {
    uint256 internal constant RAY = 1e27;

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // From Solmate's FixedPointMathLib
    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.8.11;

interface IAaveIncentivesController {
  event RewardsAccrued(address indexed user, uint256 amount);

  event RewardsClaimed(address indexed user, address indexed to, uint256 amount);

  event RewardsClaimed(
    address indexed user,
    address indexed to,
    address indexed claimer,
    uint256 amount
  );

  event ClaimerSet(address indexed user, address indexed claimer);

  /*
   * @dev Returns the configuration of the distribution for a certain asset
   * @param asset The address of the reference asset of the distribution
   * @return The asset index, the emission per second and the last updated timestamp
   **/
  function getAssetData(address asset)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  /*
   * LEGACY **************************
   * @dev Returns the configuration of the distribution for a certain asset
   * @param asset The address of the reference asset of the distribution
   * @return The asset index, the emission per second and the last updated timestamp
   **/
  function assets(address asset)
    external
    view
    returns (
      uint128,
      uint128,
      uint256
    );

  /**
   * @dev Whitelists an address to claim the rewards on behalf of another address
   * @param user The address of the user
   * @param claimer The address of the claimer
   */
  function setClaimer(address user, address claimer) external;

  /**
   * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
   * @param user The address of the user
   * @return The claimer address
   */
  function getClaimer(address user) external view returns (address);

  /**
   * @dev Configure assets for a certain rewards emission
   * @param assets The assets to incentivize
   * @param emissionsPerSecond The emission for each asset
   */
  function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond)
    external;

  /**
   * @dev Called by the corresponding asset on any update that affects the rewards distribution
   * @param asset The address of the user
   * @param userBalance The balance of the user of the asset in the lending pool
   * @param totalSupply The total supply of the asset in the lending pool
   **/
  function handleAction(
    address asset,
    uint256 userBalance,
    uint256 totalSupply
  ) external;

  /**
   * @dev Returns the total of rewards of an user, already accrued + not yet accrued
   * @param user The address of the user
   * @return The rewards
   **/
  function getRewardsBalance(address[] calldata assets, address user)
    external
    view
    returns (uint256);

  /**
   * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
   * @param amount Amount of rewards to claim
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
   * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param amount Amount of rewards to claim
   * @param user Address to check and claim rewards
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint256 amount,
    address user,
    address to
  ) external returns (uint256);

  /**
   * @dev returns the unclaimed rewards of the user
   * @param user the address of the user
   * @return the unclaimed user rewards
   */
  function getUserUnclaimedRewards(address user) external view returns (uint256);

  /**
   * @dev returns the unclaimed rewards of the user
   * @param user the address of the user
   * @param asset The asset to incentivize
   * @return the user index for the asset
   */
  function getUserAssetData(address user, address asset) external view returns (uint256);

  /**
   * @dev for backward compatibility with previous implementation of the Incentives controller
   */
  function REWARD_TOKEN() external view returns (address);

  /**
   * @dev for backward compatibility with previous implementation of the Incentives controller
   */
  function PRECISION() external view returns (uint8);

  /**
   * @dev Gets the distribution end timestamp of the emissions
   */
  function DISTRIBUTION_END() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.8.11;

interface IStakedTokenV2 {
  function stake(address to, uint256 amount) external;

  function redeem(address to, uint256 amount) external;

  function cooldown() external;

  function claimRewards(address to, uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.11;

/**
 * @notice Partial interface for a SushiSwap Router contract
 **/
interface ISushiSwapRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.11;

interface Gravity {
    function sendToCosmos(address _tokenContract, bytes32 _destination, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
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