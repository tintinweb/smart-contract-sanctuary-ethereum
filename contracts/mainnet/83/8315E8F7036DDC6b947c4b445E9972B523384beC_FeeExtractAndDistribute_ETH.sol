/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "IUniswapV2Router.sol";
import "IBZx.sol";
import "IPriceFeeds.sol";
import "IStakingV2.sol";
import "ICurve3Pool.sol";
import "SafeERC20.sol";
import "PausableGuardian_0_8.sol";
import "IBridge.sol";

contract FeeExtractAndDistribute_ETH is PausableGuardian_0_8 {
    using SafeERC20 for IERC20;
    address public implementation;
    IStakingV2 public constant STAKING =
        IStakingV2(0x16f179f5C344cc29672A58Ea327A26F64B941a63);

    address public constant OOKI = 0x0De05F6447ab4D22c8827449EE4bA2D5C288379B;
    IERC20 public constant CURVE_3CRV =
        IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public constant BUYBACK =
        0x12EBd8263A54751Aaf9d8C2c74740A8e62C0AfBe;
    address public constant BRIDGE = 0x5427FEFA711Eff984124bFBB1AB6fbf5E3DA1820;
    uint64 public constant DEST_CHAINID = 137; //polygon

    IUniswapV2Router public constant UNISWAP_ROUTER =
        IUniswapV2Router(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // sushiswap
    ICurve3Pool public constant CURVE_3POOL =
        ICurve3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    IBZx public constant BZX = IBZx(0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f);

    mapping(address => address[]) public swapPaths;
    mapping(address => uint256) public stakingRewards;
    address[] public feeTokens;
    uint256 public buybackPercent;

    uint32 public slippage = 10000;

    event ExtractAndDistribute();

    event WithdrawFees(address indexed sender);

    event DistributeFees(
        address indexed sender,
        uint256 bzrxRewards,
        uint256 stableCoinRewards
    );

    event ConvertFees(
        address indexed sender,
        uint256 bzrxOutput,
        uint256 stableCoinOutput
    );

    // Fee Conversion Logic //

    function sweepFees()
        public
        pausable
        returns (uint256 bzrxRewards, uint256 crv3Rewards)
    {
        uint256[] memory amounts = _withdrawFees(feeTokens);
        _convertFees(feeTokens, amounts);
        (bzrxRewards, crv3Rewards) = _distributeFees();
    }

    function sweepFees(address[] memory assets)
        public
        pausable
        returns (uint256 bzrxRewards, uint256 crv3Rewards)
    {
        uint256[] memory amounts = _withdrawFees(assets);
        _convertFees(assets, amounts);
        (bzrxRewards, crv3Rewards) = _distributeFees();
    }

    function _withdrawFees(address[] memory assets)
        internal
        returns (uint256[] memory)
    {
        uint256[] memory amounts = BZX.withdrawFees(
            assets,
            address(this),
            IBZx.FeeClaimType.All
        );

        for (uint256 i = 0; i < assets.length; i++) {
            stakingRewards[assets[i]] += amounts[i];
        }

        emit WithdrawFees(msg.sender);

        return amounts;
    }

    function _convertFees(address[] memory assets, uint256[] memory amounts)
        internal
        returns (uint256 bzrxOutput, uint256 crv3Output)
    {
        require(assets.length == amounts.length, "count mismatch");

        IPriceFeeds priceFeeds = IPriceFeeds(BZX.priceFeeds());
        //(uint256 bzrxRate, ) = priceFeeds.queryRate(OOKI, WETH);
        uint256 maxDisagreement = 1e18;
        address asset;
        uint256 daiAmount;
        uint256 usdcAmount;
        uint256 usdtAmount;
        for (uint256 i = 0; i < assets.length; i++) {
            asset = assets[i];
            if (asset == OOKI) {
                continue;
            } else if (asset == DAI) {
                daiAmount += amounts[i];
                continue;
            } else if (asset == USDC) {
                usdcAmount += amounts[i];
                continue;
            } else if (asset == USDT) {
                usdtAmount += amounts[i];
                continue;
            }

            if (amounts[i] != 0) {
                bzrxOutput += _convertFeeWithUniswap(
                    asset,
                    amounts[i],
                    priceFeeds,
                    0, /*bzrxRate*/
                    maxDisagreement
                );
            }
        }
        if (bzrxOutput != 0) {
            stakingRewards[OOKI] += bzrxOutput;
        }

        if (daiAmount != 0 || usdcAmount != 0 || usdtAmount != 0) {
            crv3Output = _convertFeesWithCurve(
                daiAmount,
                usdcAmount,
                usdtAmount
            );
            stakingRewards[address(CURVE_3CRV)] += crv3Output;
        }

        emit ConvertFees(msg.sender, bzrxOutput, crv3Output);
    }

    function _distributeFees()
        internal
        returns (uint256 bzrxRewards, uint256 crv3Rewards)
    {
        bzrxRewards = stakingRewards[OOKI];
        crv3Rewards = stakingRewards[address(CURVE_3CRV)];
        uint256 USDCBridge = 0;
        if (bzrxRewards != 0 || crv3Rewards != 0) {
            address _fundsWallet = 0xfedC4dD5247B93feb41e899A09C44cFaBec29Cbc;
            uint256 rewardAmount;
            uint256 callerReward;
            uint256 bridgeRewards;
            if (bzrxRewards != 0) {
                stakingRewards[OOKI] = 0;
                callerReward = bzrxRewards / 100;
                IERC20(OOKI).transfer(msg.sender, callerReward);
                bzrxRewards = bzrxRewards - (callerReward);
                bridgeRewards = (bzrxRewards * (buybackPercent)) / (1e20);
                USDCBridge = _convertToUSDCUniswap(bridgeRewards);
                rewardAmount = (bzrxRewards * (50e18)) / (1e20);
                IERC20(OOKI).transfer(
                    _fundsWallet,
                    bzrxRewards - rewardAmount - bridgeRewards
                );
                bzrxRewards = rewardAmount;
            }
            if (crv3Rewards != 0) {
                stakingRewards[address(CURVE_3CRV)] = 0;
                callerReward = crv3Rewards / 100;
                CURVE_3CRV.transfer(msg.sender, callerReward);
                crv3Rewards = crv3Rewards - (callerReward);
                bridgeRewards = (crv3Rewards * (buybackPercent)) / (1e20);
                USDCBridge += _convertToUSDCCurve(bridgeRewards);
                rewardAmount = (crv3Rewards * (50e18)) / (1e20);
                CURVE_3CRV.transfer(
                    _fundsWallet,
                    crv3Rewards - rewardAmount - bridgeRewards
                );
                crv3Rewards = rewardAmount;
            }
            STAKING.addRewards(bzrxRewards, crv3Rewards);
            _bridgeFeesToPolygon(USDCBridge);
        }

        emit DistributeFees(msg.sender, bzrxRewards, crv3Rewards);
    }

    function _bridgeFeesToPolygon(uint256 bridgeAmount) internal {
        IBridge(BRIDGE).send(
            BUYBACK,
            USDC,
            bridgeAmount,
            DEST_CHAINID,
            uint64(block.timestamp),
            slippage
        );
    }

    function _convertToUSDCUniswap(uint256 amount)
        internal
        returns (uint256 returnAmount)
    {
        address[] memory path = new address[](3);
        path[0] = OOKI;
        path[1] = WETH;
        path[2] = USDC;
        uint256[] memory amounts = UNISWAP_ROUTER.swapExactTokensForTokens(
            amount,
            1, // amountOutMin
            path,
            address(this),
            block.timestamp
        );

        returnAmount = amounts[amounts.length - 1];
        IPriceFeeds priceFeeds = IPriceFeeds(BZX.priceFeeds());
        //(uint256 bzrxRate, ) = priceFeeds.queryRate(OOKI, WETH);
        /*_checkUniDisagreement(
            OOKI,
			USDC,
            amount,
            returnAmount,
            STAKING.maxUniswapDisagreement()
        );*/
    }

    function _convertFeeWithUniswap(
        address asset,
        uint256 amount,
        IPriceFeeds priceFeeds,
        uint256 bzrxRate,
        uint256 maxDisagreement
    ) internal returns (uint256 returnAmount) {
        uint256 stakingReward = stakingRewards[asset];
        if (stakingReward != 0) {
            if (amount > stakingReward) {
                amount = stakingReward;
            }
            stakingRewards[asset] = stakingReward - (amount);

            uint256[] memory amounts = UNISWAP_ROUTER.swapExactTokensForTokens(
                amount,
                1, // amountOutMin
                swapPaths[asset],
                address(this),
                block.timestamp
            );

            returnAmount = amounts[amounts.length - 1];

            // will revert if disagreement found
            /*_checkUniDisagreement(
                asset,
				OOKI,
                amount,
                returnAmount,
                maxDisagreement
            );*/
        }
    }

    function _convertToUSDCCurve(uint256 amount)
        internal
        returns (uint256 returnAmount)
    {
        uint256 beforeBalance = IERC20(USDC).balanceOf(address(this));
        CURVE_3POOL.remove_liquidity_one_coin(amount, 1, 1); //does not need to be checked for disagreement as liquidity add handles that
        returnAmount = IERC20(USDC).balanceOf(address(this)) - beforeBalance; //does not underflow as USDC is not being transferred out
    }

    function _convertFeesWithCurve(
        uint256 daiAmount,
        uint256 usdcAmount,
        uint256 usdtAmount
    ) internal returns (uint256 returnAmount) {
        uint256[3] memory curveAmounts;
        uint256 curveTotal;
        uint256 stakingReward;

        if (daiAmount != 0) {
            stakingReward = stakingRewards[DAI];
            if (stakingReward != 0) {
                if (daiAmount > stakingReward) {
                    daiAmount = stakingReward;
                }
                stakingRewards[DAI] = stakingReward - (daiAmount);
                curveAmounts[0] = daiAmount;
                curveTotal = daiAmount;
            }
        }
        if (usdcAmount != 0) {
            stakingReward = stakingRewards[USDC];
            if (stakingReward != 0) {
                if (usdcAmount > stakingReward) {
                    usdcAmount = stakingReward;
                }
                stakingRewards[USDC] = stakingReward - (usdcAmount);
                curveAmounts[1] = usdcAmount;
                curveTotal += usdcAmount * 1e12; // normalize to 18 decimals
            }
        }
        if (usdtAmount != 0) {
            stakingReward = stakingRewards[USDT];
            if (stakingReward != 0) {
                if (usdtAmount > stakingReward) {
                    usdtAmount = stakingReward;
                }
                stakingRewards[USDT] = stakingReward - (usdtAmount);
                curveAmounts[2] = usdtAmount;
                curveTotal += usdtAmount * 1e12; // normalize to 18 decimals
            }
        }

        uint256 beforeBalance = CURVE_3CRV.balanceOf(address(this));
        CURVE_3POOL.add_liquidity(
            curveAmounts,
            (curveTotal * 1e18 / CURVE_3POOL.get_virtual_price())*995/1000
        );
        returnAmount = CURVE_3CRV.balanceOf(address(this)) - beforeBalance;
    }

    function _checkUniDisagreement(
        address asset,
        address recvAsset,
        uint256 assetAmount,
        uint256 recvAmount,
        uint256 maxDisagreement
    ) internal view {
        uint256 estAmountOut = IPriceFeeds(BZX.priceFeeds()).queryReturn(
            asset,
            recvAsset,
            assetAmount
        );

        uint256 spreadValue = estAmountOut > recvAmount
            ? estAmountOut - recvAmount
            : recvAmount - estAmountOut;
        if (spreadValue != 0) {
            spreadValue = (spreadValue * 1e20) / estAmountOut;

            require(
                spreadValue <= maxDisagreement,
                "uniswap price disagreement"
            );
        }
    }

    function setApprovals() external onlyOwner {
        IERC20(DAI).safeApprove(address(CURVE_3POOL), type(uint256).max);
        IERC20(USDC).safeApprove(address(CURVE_3POOL), type(uint256).max);
        IERC20(USDC).safeApprove(BRIDGE, type(uint256).max);
        IERC20(USDT).safeApprove(address(CURVE_3POOL), 0);
        IERC20(USDT).safeApprove(address(CURVE_3POOL), type(uint256).max);
        

        IERC20(OOKI).safeApprove(address(STAKING), type(uint256).max);
        IERC20(OOKI).safeApprove(address(UNISWAP_ROUTER), type(uint256).max);
        CURVE_3CRV.safeApprove(address(STAKING), type(uint256).max);
    }

    // path should start with the asset to swap and end with OOKI
    // only one path allowed per asset
    // ex: asset -> WETH -> OOKI
    function setPaths(address[][] calldata paths) external onlyOwner {
        address[] memory path;
        for (uint256 i = 0; i < paths.length; i++) {
            path = paths[i];
            require(
                path.length >= 2 &&
                    path[0] != path[path.length - 1] &&
                    path[path.length - 1] == OOKI,
                "invalid path"
            );

            // check that the path exists
            uint256[] memory amountsOut = UNISWAP_ROUTER.getAmountsOut(
                1e10,
                path
            );
            require(
                amountsOut[amountsOut.length - 1] != 0,
                "path does not exist"
            );

            swapPaths[path[0]] = path;
            IERC20(path[0]).safeApprove(address(UNISWAP_ROUTER), 0);
            IERC20(path[0]).safeApprove(address(UNISWAP_ROUTER), type(uint256).max);
        }
    }

    function setBuybackSettings(uint256 amount) external onlyOwner {
        buybackPercent = amount;
    }

    function setFeeTokens(address[] calldata tokens) external onlyOwner {
        feeTokens = tokens;
    }

    function setSlippage(uint32 newSlippage) external onlyGuardian {
        slippage = newSlippage;
    }

    function requestRefund(bytes calldata wdmsg, bytes[] calldata sigs, address[] calldata signers, uint256[] calldata powers) external onlyGuardian {
        IBridge(BRIDGE).withdraw(wdmsg, sigs, signers, powers);
    }

    function guardianBridge() external onlyGuardian {
        _bridgeFeesToPolygon(IERC20(USDC).balanceOf(address(this)));
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.6.0;


interface IUniswapV2Router {
    // 0x38ed1739
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline)
        external
        returns (uint256[] memory amounts);

    // 0x8803dbee
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline)
        external
        returns (uint256[] memory amounts);

    // 0x1f00ca74
    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    // 0xd06ca61f
    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache-2.0
 */
// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;

/// @title A proxy interface for The Protocol
/// @author bZeroX
/// @notice This is just an interface, not to be deployed itself.
/// @dev This interface is to be used for the protocol interactions.
interface IBZx {
    ////// Protocol //////

    /// @dev adds or replaces existing proxy module
    /// @param target target proxy module address
    function replaceContract(address target) external;

    /// @dev updates all proxy modules addreses and function signatures.
    /// sigsArr and targetsArr should be of equal length
    /// @param sigsArr array of function signatures
    /// @param targetsArr array of target proxy module addresses
    function setTargets(
        string[] calldata sigsArr,
        address[] calldata targetsArr
    ) external;

    /// @dev returns protocol module address given a function signature
    /// @return module address
    function getTarget(string calldata sig) external view returns (address);

    ////// Protocol Settings //////

    /// @dev sets price feed contract address. The contract on the addres should implement IPriceFeeds interface
    /// @param newContract module address for the IPriceFeeds implementation
    function setPriceFeedContract(address newContract) external;

    /// @dev sets swaps contract address. The contract on the addres should implement ISwapsImpl interface
    /// @param newContract module address for the ISwapsImpl implementation
    function setSwapsImplContract(address newContract) external;

    /// @dev sets loan pool with assets. Accepts two arrays of equal length
    /// @param pools array of address of pools
    /// @param assets array of addresses of assets
    function setLoanPool(address[] calldata pools, address[] calldata assets)
        external;

    /// @dev updates list of supported tokens, it can be use also to disable or enable particualr token
    /// @param addrs array of address of pools
    /// @param toggles array of addresses of assets
    /// @param withApprovals resets tokens to unlimited approval with the swaps integration (kyber, etc.)
    function setSupportedTokens(
        address[] calldata addrs,
        bool[] calldata toggles,
        bool withApprovals
    ) external;

    /// @dev sets lending fee with WEI_PERCENT_PRECISION
    /// @param newValue lending fee percent
    function setLendingFeePercent(uint256 newValue) external;

    /// @dev sets trading fee with WEI_PERCENT_PRECISION
    /// @param newValue trading fee percent
    function setTradingFeePercent(uint256 newValue) external;

    /// @dev sets borrowing fee with WEI_PERCENT_PRECISION
    /// @param newValue borrowing fee percent
    function setBorrowingFeePercent(uint256 newValue) external;

    /// @dev sets affiliate fee with WEI_PERCENT_PRECISION
    /// @param newValue affiliate fee percent
    function setAffiliateFeePercent(uint256 newValue) external;

    /// @dev sets liquidation inncetive percent per loan per token. This is the profit percent
    /// that liquidator gets in the process of liquidating.
    /// @param loanTokens array list of loan tokens
    /// @param collateralTokens array list of collateral tokens
    /// @param amounts array list of liquidation inncetive amount
    function setLiquidationIncentivePercent(
        address[] calldata loanTokens,
        address[] calldata collateralTokens,
        uint256[] calldata amounts
    ) external;

    /// @dev sets max swap rate slippage percent.
    /// @param newAmount max swap rate slippage percent.
    function setMaxDisagreement(uint256 newAmount) external;

    /// TODO
    function setSourceBufferPercent(uint256 newAmount) external;

    /// @dev sets maximum supported swap size in ETH
    /// @param newAmount max swap size in ETH.
    function setMaxSwapSize(uint256 newAmount) external;

    /// @dev sets fee controller address
    /// @param newController address of the new fees controller
    function setFeesController(address newController) external;

    /// @dev withdraws lending fees to receiver. Only can be called by feesController address
    /// @param tokens array of token addresses.
    /// @param receiver fees receiver address
    /// @return amounts array of amounts withdrawn
    function withdrawFees(
        address[] calldata tokens,
        address receiver,
        FeeClaimType feeType
    ) external returns (uint256[] memory amounts);

    /*
    Targets still exist, but functions are decommissioned:

    /// @dev withdraw protocol token (BZRX) from vesting contract vBZRX
    /// @param receiver address of BZRX tokens claimed
    /// @param amount of BZRX token to be claimed. max is claimed if amount is greater than balance.
    /// @return rewardToken reward token address
    /// @return withdrawAmount amount
    function withdrawProtocolToken(address receiver, uint256 amount)
        external
        returns (address rewardToken, uint256 withdrawAmount);

    /// @dev depozit protocol token (BZRX)
    /// @param amount address of BZRX tokens to deposit
    function depositProtocolToken(uint256 amount) external;

    function grantRewards(address[] calldata users, uint256[] calldata amounts)
        external
        returns (uint256 totalAmount);*/

    // NOTE: this doesn't sanitize inputs -> inaccurate values may be returned if there are duplicate token inputs
    function queryFees(address[] calldata tokens, FeeClaimType feeType)
        external
        view
        returns (uint256[] memory amountsHeld, uint256[] memory amountsPaid);

    function priceFeeds() external view returns (address);

    function swapsImpl() external view returns (address);

    function logicTargets(bytes4) external view returns (address);

    function loans(bytes32) external view returns (Loan memory);

    function loanParams(bytes32) external view returns (LoanParams memory);

    // we don't use this yet
    // function lenderOrders(address, bytes32) external returns (Order memory);
    // function borrowerOrders(address, bytes32) external returns (Order memory);

    function delegatedManagers(bytes32, address) external view returns (bool);

    function lenderInterest(address, address)
        external
        view
        returns (LenderInterest memory);

    function loanInterest(bytes32) external view returns (LoanInterest memory);

    function feesController() external view returns (address);

    function lendingFeePercent() external view returns (uint256);

    function lendingFeeTokensHeld(address) external view returns (uint256);

    function lendingFeeTokensPaid(address) external view returns (uint256);

    function borrowingFeePercent() external view returns (uint256);

    function borrowingFeeTokensHeld(address) external view returns (uint256);

    function borrowingFeeTokensPaid(address) external view returns (uint256);

    function protocolTokenHeld() external view returns (uint256);

    function protocolTokenPaid() external view returns (uint256);

    function affiliateFeePercent() external view returns (uint256);

    function liquidationIncentivePercent(address, address)
        external
        view
        returns (uint256);

    function loanPoolToUnderlying(address) external view returns (address);

    function underlyingToLoanPool(address) external view returns (address);

    function supportedTokens(address) external view returns (bool);

    function maxDisagreement() external view returns (uint256);

    function sourceBufferPercent() external view returns (uint256);

    function maxSwapSize() external view returns (uint256);

    /// @dev get list of loan pools in the system. Ordering is not guaranteed
    /// @param start start index
    /// @param count number of pools to return
    /// @return loanPoolsList array of loan pools
    function getLoanPoolsList(uint256 start, uint256 count)
        external
        view
        returns (address[] memory loanPoolsList);

    /// @dev checks whether addreess is a loan pool address
    /// @return boolean
    function isLoanPool(address loanPool) external view returns (bool);

    ////// Loan Settings //////

    /// @dev creates new loan param settings
    /// @param loanParamsList array of LoanParams
    /// @return loanParamsIdList array of loan ids created
    function setupLoanParams(LoanParams[] calldata loanParamsList)
        external
        returns (bytes32[] memory loanParamsIdList);

    function setupLoanPoolTWAI(address pool) external;

    function setTWAISettings(uint32 delta, uint32 secondsAgo) external;

    /// @dev Deactivates LoanParams for future loans. Active loans using it are unaffected.
    /// @param loanParamsIdList array of loan ids
    function disableLoanParams(bytes32[] calldata loanParamsIdList) external;

    /// @dev gets array of LoanParams by given ids
    /// @param loanParamsIdList array of loan ids
    /// @return loanParamsList array of LoanParams
    function getLoanParams(bytes32[] calldata loanParamsIdList)
        external
        view
        returns (LoanParams[] memory loanParamsList);

    /// @dev Enumerates LoanParams in the system by owner
    /// @param owner of the loan params
    /// @param start number of loans to return
    /// @param count total number of the items
    /// @return loanParamsList array of LoanParams
    function getLoanParamsList(
        address owner,
        uint256 start,
        uint256 count
    ) external view returns (bytes32[] memory loanParamsList);

    /// @dev returns total loan principal for token address
    /// @param lender address
    /// @param loanToken address
    /// @return total principal of the loan
    function getTotalPrincipal(address lender, address loanToken)
        external
        view
        returns (uint256);

    /// @dev returns total principal for a loan pool that was last settled
    /// @param pool address
    /// @return total stored principal of the loan
    function getPoolPrincipalStored(address pool)
        external
        view
        returns (uint256);

    /// @dev returns the last interest rate founnd during interest settlement
    /// @param pool address
    /// @return the last interset rate
    function getPoolLastInterestRate(address pool)
        external
        view
        returns (uint256);

    ////// Loan Openings //////

    /// @dev This is THE function that borrows or trades on the protocol
    /// @param loanParamsId id of the LoanParam created beforehand by setupLoanParams function
    /// @param loanId id of existing loan, if 0, start a new loan
    /// @param isTorqueLoan boolean whether it is toreque or non torque loan
    /// @param initialMargin in WEI_PERCENT_PRECISION
    /// @param sentAddresses array of size 4:
    ///         lender: must match loan if loanId provided
    ///         borrower: must match loan if loanId provided
    ///         receiver: receiver of funds (address(0) assumes borrower address)
    ///         manager: delegated manager of loan unless address(0)
    /// @param sentValues array of size 5:
    ///         newRate: new loan interest rate
    ///         newPrincipal: new loan size (borrowAmount + any borrowed interest)
    ///         torqueInterest: new amount of interest to escrow for Torque loan (determines initial loan length)
    ///         loanTokenReceived: total loanToken deposit (amount not sent to borrower in the case of Torque loans)
    ///         collateralTokenReceived: total collateralToken deposit
    /// @param loanDataBytes required when sending ether
    /// @return principal of the loan and collateral amount
    function borrowOrTradeFromPool(
        bytes32 loanParamsId,
        bytes32 loanId,
        bool isTorqueLoan,
        uint256 initialMargin,
        address[4] calldata sentAddresses,
        uint256[5] calldata sentValues,
        bytes calldata loanDataBytes
    ) external payable returns (LoanOpenData memory);

    /// @dev sets/disables/enables the delegated manager for the loan
    /// @param loanId id of the loan
    /// @param delegated delegated manager address
    /// @param toggle boolean set enabled or disabled
    function setDelegatedManager(
        bytes32 loanId,
        address delegated,
        bool toggle
    ) external;

    /// @dev calculates required collateral for simulated position
    /// @param loanToken address of loan token
    /// @param collateralToken address of collateral token
    /// @param newPrincipal principal amount of the loan
    /// @param marginAmount margin amount of the loan
    /// @param isTorqueLoan boolean torque or non torque loan
    /// @return collateralAmountRequired amount required
    function getRequiredCollateral(
        address loanToken,
        address collateralToken,
        uint256 newPrincipal,
        uint256 marginAmount,
        bool isTorqueLoan
    ) external view returns (uint256 collateralAmountRequired);

    function getRequiredCollateralByParams(
        bytes32 loanParamsId,
        uint256 newPrincipal
    ) external view returns (uint256 collateralAmountRequired);

    /// @dev calculates borrow amount for simulated position
    /// @param loanToken address of loan token
    /// @param collateralToken address of collateral token
    /// @param collateralTokenAmount amount of collateral token sent
    /// @param marginAmount margin amount
    /// @param isTorqueLoan boolean torque or non torque loan
    /// @return borrowAmount possible borrow amount
    function getBorrowAmount(
        address loanToken,
        address collateralToken,
        uint256 collateralTokenAmount,
        uint256 marginAmount,
        bool isTorqueLoan
    ) external view returns (uint256 borrowAmount);

    function getBorrowAmountByParams(
        bytes32 loanParamsId,
        uint256 collateralTokenAmount
    ) external view returns (uint256 borrowAmount);

    ////// Loan Closings //////

    /// @dev liquidates unhealty loans
    /// @param loanId id of the loan
    /// @param receiver address receiving liquidated loan collateral
    /// @param closeAmount amount to close denominated in loanToken
    /// @return loanCloseAmount amount of the collateral token of the loan
    /// @return seizedAmount sezied amount in the collateral token
    /// @return seizedToken loan token address
    function liquidate(
        bytes32 loanId,
        address receiver,
        uint256 closeAmount
    )
        external
        payable
        returns (
            uint256 loanCloseAmount,
            uint256 seizedAmount,
            address seizedToken
        );

    /// @dev close position with loan token deposit
    /// @param loanId id of the loan
    /// @param receiver collateral token reciever address
    /// @param depositAmount amount of loan token to deposit
    /// @return loanCloseAmount loan close amount
    /// @return withdrawAmount loan token withdraw amount
    /// @return withdrawToken loan token address
    function closeWithDeposit(
        bytes32 loanId,
        address receiver,
        uint256 depositAmount // denominated in loanToken
    )
        external
        payable
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        );

    /// @dev close position with swap
    /// @param loanId id of the loan
    /// @param receiver collateral token reciever address
    /// @param swapAmount amount of loan token to swap
    /// @param returnTokenIsCollateral boolean whether to return tokens is collateral
    /// @param loanDataBytes custom payload for specifying swap implementation and data to pass
    /// @return loanCloseAmount loan close amount
    /// @return withdrawAmount loan token withdraw amount
    /// @return withdrawToken loan token address
    function closeWithSwap(
        bytes32 loanId,
        address receiver,
        uint256 swapAmount, // denominated in collateralToken
        bool returnTokenIsCollateral, // true: withdraws collateralToken, false: withdraws loanToken
        bytes calldata loanDataBytes
    )
        external
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        );

    ////// Loan Closings With Gas Token //////

    /// @dev liquidates unhealty loans by using Gas token
    /// @param loanId id of the loan
    /// @param receiver address receiving liquidated loan collateral
    /// @param gasTokenUser user address of the GAS token
    /// @param closeAmount amount to close denominated in loanToken
    /// @return loanCloseAmount loan close amount
    /// @return seizedAmount loan token withdraw amount
    /// @return seizedToken loan token address
    function liquidateWithGasToken(
        bytes32 loanId,
        address receiver,
        address gasTokenUser,
        uint256 closeAmount // denominated in loanToken
    )
        external
        payable
        returns (
            uint256 loanCloseAmount,
            uint256 seizedAmount,
            address seizedToken
        );

    /// @dev close position with loan token deposit
    /// @param loanId id of the loan
    /// @param receiver collateral token reciever address
    /// @param gasTokenUser user address of the GAS token
    /// @param depositAmount amount of loan token to deposit denominated in loanToken
    /// @return loanCloseAmount loan close amount
    /// @return withdrawAmount loan token withdraw amount
    /// @return withdrawToken loan token address
    function closeWithDepositWithGasToken(
        bytes32 loanId,
        address receiver,
        address gasTokenUser,
        uint256 depositAmount
    )
        external
        payable
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        );

    /// @dev close position with swap
    /// @param loanId id of the loan
    /// @param receiver collateral token reciever address
    /// @param gasTokenUser user address of the GAS token
    /// @param swapAmount amount of loan token to swap denominated in collateralToken
    /// @param returnTokenIsCollateral  true: withdraws collateralToken, false: withdraws loanToken
    /// @return loanCloseAmount loan close amount
    /// @return withdrawAmount loan token withdraw amount
    /// @return withdrawToken loan token address
    function closeWithSwapWithGasToken(
        bytes32 loanId,
        address receiver,
        address gasTokenUser,
        uint256 swapAmount,
        bool returnTokenIsCollateral,
        bytes calldata loanDataBytes
    )
        external
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        );

    ////// Loan Maintenance //////

    /// @dev deposit collateral to existing loan
    /// @param loanId existing loan id
    /// @param depositAmount amount to deposit which must match msg.value if ether is sent
    function depositCollateral(bytes32 loanId, uint256 depositAmount)
        external
        payable;

    /// @dev withdraw collateral from existing loan
    /// @param loanId existing loan id
    /// @param receiver address of withdrawn tokens
    /// @param withdrawAmount amount to withdraw
    /// @return actualWithdrawAmount actual amount withdrawn
    function withdrawCollateral(
        bytes32 loanId,
        address receiver,
        uint256 withdrawAmount
    ) external returns (uint256 actualWithdrawAmount);

    /// @dev settles accrued interest for all active loans from a loan pool
    /// @param loanId existing loan id
    function settleInterest(bytes32 loanId) external;

    function setDepositAmount(
        bytes32 loanId,
        uint256 depositValueAsLoanToken,
        uint256 depositValueAsCollateralToken
    ) external;

    function transferLoan(bytes32 loanId, address newOwner) external;

    // Decommissioned function, but leave interface to allow remaining claims
    function claimRewards(address receiver)
        external
        returns (uint256 claimAmount);

    // Decommissioned function, but leave interface to allow remaining claims
    function rewardsBalanceOf(address user)
        external
        view
        returns (uint256 rewardsBalance);

    function getInterestModelValues(
        address pool,
        bytes32 loanId)
        external
        view
        returns (
        uint256 _poolLastUpdateTime,
        uint256 _poolPrincipalTotal,
        uint256 _poolInterestTotal,
        uint256 _poolRatePerTokenStored,
        uint256 _poolLastInterestRate,
        uint256 _loanPrincipalTotal,
        uint256 _loanInterestTotal,
        uint256 _loanRatePerTokenPaid
        );
    
    function getTWAI(
        address pool)
        external
        view returns (
            uint256 benchmarkRate
        );

    /// @dev gets list of loans of particular user address
    /// @param user address of the loans
    /// @param start of the index
    /// @param count number of loans to return
    /// @param loanType type of the loan: All(0), Margin(1), NonMargin(2)
    /// @param isLender whether to list lender loans or borrower loans
    /// @param unsafeOnly booleat if true return only unsafe loans that are open for liquidation
    /// @return loansData LoanReturnData array of loans
    function getUserLoans(
        address user,
        uint256 start,
        uint256 count,
        LoanType loanType,
        bool isLender,
        bool unsafeOnly
    ) external view returns (LoanReturnData[] memory loansData);

    function getUserLoansCount(address user, bool isLender)
        external
        view
        returns (uint256);

    /// @dev gets existing loan
    /// @param loanId id of existing loan
    /// @return loanData array of loans
    function getLoan(bytes32 loanId)
        external
        view
        returns (LoanReturnData memory loanData);

    /// @dev gets loan principal including interest
    /// @param loanId id of existing loan
    /// @return principal
    function getLoanPrincipal(bytes32 loanId)
        external
        view
        returns (uint256 principal);

    /// @dev gets loan outstanding interest
    /// @param loanId id of existing loan
    /// @return interest
    function getLoanInterestOutstanding(bytes32 loanId)
        external
        view
        returns (uint256 interest);


    /// @dev get current active loans in the system
    /// @param start of the index
    /// @param count number of loans to return
    /// @param unsafeOnly boolean if true return unsafe loan only (open for liquidation)
    function getActiveLoans(
        uint256 start,
        uint256 count,
        bool unsafeOnly
    ) external view returns (LoanReturnData[] memory loansData);

    /// @dev get current active loans in the system
    /// @param start of the index
    /// @param count number of loans to return
    /// @param unsafeOnly boolean if true return unsafe loan only (open for liquidation)
    /// @param isLiquidatable boolean if true return liquidatable loans only
    function getActiveLoansAdvanced(
        uint256 start,
        uint256 count,
        bool unsafeOnly,
        bool isLiquidatable
    ) external view returns (LoanReturnData[] memory loansData);

    function getActiveLoansCount() external view returns (uint256);

    ////// Swap External //////

    /// @dev swap thru external integration
    /// @param sourceToken source token address
    /// @param destToken destintaion token address
    /// @param receiver address to receive tokens
    /// @param returnToSender TODO
    /// @param sourceTokenAmount source token amount
    /// @param requiredDestTokenAmount destination token amount
    /// @param swapData TODO
    /// @return destTokenAmountReceived destination token received
    /// @return sourceTokenAmountUsed source token amount used
    function swapExternal(
        address sourceToken,
        address destToken,
        address receiver,
        address returnToSender,
        uint256 sourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bytes calldata swapData
    )
        external
        payable
        returns (
            uint256 destTokenAmountReceived,
            uint256 sourceTokenAmountUsed
        );

    /// @dev swap thru external integration using GAS
    /// @param sourceToken source token address
    /// @param destToken destintaion token address
    /// @param receiver address to receive tokens
    /// @param returnToSender TODO
    /// @param gasTokenUser user address of the GAS token
    /// @param sourceTokenAmount source token amount
    /// @param requiredDestTokenAmount destination token amount
    /// @param swapData TODO
    /// @return destTokenAmountReceived destination token received
    /// @return sourceTokenAmountUsed source token amount used
    function swapExternalWithGasToken(
        address sourceToken,
        address destToken,
        address receiver,
        address returnToSender,
        address gasTokenUser,
        uint256 sourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bytes calldata swapData
    )
        external
        payable
        returns (
            uint256 destTokenAmountReceived,
            uint256 sourceTokenAmountUsed
        );

    /// @dev calculate simulated return of swap
    /// @param sourceToken source token address
    /// @param destToken destination token address
    /// @param sourceTokenAmount source token amount
    /// @return amoun denominated in destination token
    // TODO remove as soon as deployed on all chains
    function getSwapExpectedReturn(
        address sourceToken,
        address destToken,
        uint256 sourceTokenAmount,
        bytes calldata swapData
    ) external view returns (uint256);

    function getSwapExpectedReturn(
        address trader,
        address sourceToken,
        address destToken,
        uint256 sourceTokenAmount,
        bytes calldata payload)
        external
        returns (uint256);

    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;


    /// Guardian Interface

    function _isPaused(bytes4 sig) external view returns (bool isPaused);

    function toggleFunctionPause(bytes4 sig) external;

    function toggleFunctionUnPause(bytes4 sig) external;

    function pause(bytes4 [] calldata sig) external;

    function unpause(bytes4 [] calldata sig) external;

    function changeGuardian(address newGuardian) external;

    function getGuardian() external view returns (address guardian);

    /// Loan Cleanup Interface

    function cleanupLoans(
        address loanToken,
        bytes32[] calldata loanIds)
        external
        payable
        returns (uint256 totalPrincipalIn);

    struct LoanParams {
        bytes32 id;
        bool active;
        address owner;
        address loanToken;
        address collateralToken;
        uint256 minInitialMargin;
        uint256 maintenanceMargin;
        uint256 maxLoanTerm;
    }

    struct LoanOpenData {
        bytes32 loanId;
        uint256 principal;
        uint256 collateral;
    }

    enum LoanType {
        All,
        Margin,
        NonMargin
    }

    struct LoanReturnData {
        bytes32 loanId;
        uint96 endTimestamp;
        address loanToken;
        address collateralToken;
        uint256 principal;
        uint256 collateral;
        uint256 interestOwedPerDay;
        uint256 interestDepositRemaining;
        uint256 startRate;
        uint256 startMargin;
        uint256 maintenanceMargin;
        uint256 currentMargin;
        uint256 maxLoanTerm;
        uint256 maxLiquidatable;
        uint256 maxSeizable;
        uint256 depositValueAsLoanToken;
        uint256 depositValueAsCollateralToken;
    }

    enum FeeClaimType {
        All,
        Lending,
        Trading,
        Borrowing
    }

    struct Loan {
        bytes32 id; // id of the loan
        bytes32 loanParamsId; // the linked loan params id
        bytes32 pendingTradesId; // the linked pending trades id
        uint256 principal; // total borrowed amount outstanding
        uint256 collateral; // total collateral escrowed for the loan
        uint256 startTimestamp; // loan start time
        uint256 endTimestamp; // for active loans, this is the expected loan end time, for in-active loans, is the actual (past) end time
        uint256 startMargin; // initial margin when the loan opened
        uint256 startRate; // reference rate when the loan opened for converting collateralToken to loanToken
        address borrower; // borrower of this loan
        address lender; // lender of this loan
        bool active; // if false, the loan has been fully closed
    }

    struct LenderInterest {
        uint256 principalTotal; // total borrowed amount outstanding of asset
        uint256 owedPerDay; // interest owed per day for all loans of asset
        uint256 owedTotal; // total interest owed for all loans of asset (assuming they go to full term)
        uint256 paidTotal; // total interest paid so far for asset
        uint256 updatedTimestamp; // last update
    }

    struct LoanInterest {
        uint256 owedPerDay; // interest owed per day for loan
        uint256 depositTotal; // total escrowed interest for loan
        uint256 updatedTimestamp; // last update
    }
	
	////// Flash Borrow Fees //////
    function payFlashBorrowFees(
        address user,
        uint256 borrowAmount,
        uint256 flashBorrowFeePercent)
        external;
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.9.0;


interface IPriceFeeds {
    function queryRate(
        address sourceToken,
        address destToken)
        external
        view
        returns (uint256 rate, uint256 precision);

    function queryPrecision(
        address sourceToken,
        address destToken)
        external
        view
        returns (uint256 precision);

    function queryReturn(
        address sourceToken,
        address destToken,
        uint256 sourceAmount)
        external
        view
        returns (uint256 destAmount);

    function checkPriceDisagreement(
        address sourceToken,
        address destToken,
        uint256 sourceAmount,
        uint256 destAmount,
        uint256 maxSlippage)
        external
        view
        returns (uint256 sourceToDestSwapRate);

    function amountInEth(
        address Token,
        uint256 amount)
        external
        view
        returns (uint256 ethAmount);

    function getMaxDrawdown(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        external
        view
        returns (uint256);

    function getCurrentMarginAndCollateralSize(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralInEthAmount);

    function getCurrentMargin(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralToLoanRate);

    function shouldLiquidate(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        external
        view
        returns (bool);

    function getFastGasPrice(
        address payToken)
        external
        view
        returns (uint256);
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IStakingV2 {
    struct ProposalState {
        uint256 proposalTime;
        uint256 iOOKIWeight;
        uint256 lpOOKIBalance;
        uint256 lpTotalSupply;
    }

    struct AltRewardsUserInfo {
        uint256 stakingStartBlock;
        uint256 pending;
    }

    function getCurrentFeeTokens() external view returns (address[] memory);

    function maxUniswapDisagreement() external view returns (uint256);

    function fundsWallet() external view returns (address);

    function callerRewardDivisor() external view returns (uint256);

    function maxCurveDisagreement() external view returns (uint256);

    function rewardPercent() external view returns (uint256);

    function addRewards(uint256 newOOKI, uint256 newStableCoin) external;

    function stake(address[] calldata tokens, uint256[] calldata values) external;

    function unstake(address[] calldata tokens, uint256[] calldata values) external;

    function earned(address account)
        external
        view
        returns (
            uint256 bzrxRewardsEarned,
            uint256 stableCoinRewardsEarned,
            uint256 bzrxRewardsVesting,
            uint256 stableCoinRewardsVesting,
            uint256 sushiRewardsEarned
        );

    function pendingCrvRewards(address account)
        external
        view
        returns (
            uint256 bzrxRewardsEarned,
            uint256 stableCoinRewardsEarned,
            uint256 bzrxRewardsVesting,
            uint256 stableCoinRewardsVesting,
            uint256 sushiRewardsEarned
        );

    function getVariableWeights()
        external
        view
        returns (
            uint256 vBZRXWeight,
            uint256 iOOKIWeight,
            uint256 LPTokenWeight
        );

    function balanceOfByAsset(address token, address account) external view returns (uint256 balance);

    function balanceOfByAssets(address account)
        external
        view
        returns (
            uint256 bzrxBalance,
            uint256 iOOKIBalance,
            uint256 vBZRXBalance,
            uint256 LPTokenBalance
        );

    function balanceOfStored(address account) external view returns (uint256 vestedBalance, uint256 vestingBalance);

    function totalSupplyStored() external view returns (uint256 supply);

    function vestedBalanceForAmount(
        uint256 tokenBalance,
        uint256 lastUpdate,
        uint256 vestingEndTime
    ) external view returns (uint256 vested);

    function votingBalanceOf(address account, uint256 proposalId) external view returns (uint256 totalVotes);

    function votingBalanceOfNow(address account) external view returns (uint256 totalVotes);

    function votingFromStakedBalanceOf(address account) external view returns (uint256 totalVotes);

    function _setProposalVals(address account, uint256 proposalId) external returns (uint256);

    function exit() external;

    function addAltRewards(address token, uint256 amount) external;

    function governor() external view returns (address);

    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function claim(bool restake) external;

    function claimAltRewards() external;

    function _totalSupplyPerToken(address) external view returns(uint256);
    

    /// Guardian Interface

    function _isPaused(bytes4 sig) external view returns (bool isPaused);

    function toggleFunctionPause(bytes4 sig) external;

    function toggleFunctionUnPause(bytes4 sig) external;

    function changeGuardian(address newGuardian) external;

    function getGuardian() external view returns (address guardian);

    // Admin functions

    // Withdraw all from sushi masterchef
    function exitSushi() external;

    function setGovernor(address _governor) external;

    function setApprovals(
        address _token,
        address _spender,
        uint256 _value
    ) external;

    function setVoteDelegator(address stakingGovernance) external;

    function updateSettings(address settingsTarget, bytes calldata callData) external;

    function claimSushi() external returns (uint256 sushiRewardsEarned);

    function totalSupplyByAsset(address token)
        external
        view
        returns (uint256);

    function vestingLastSync(address user) external view returns(uint256);
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.9.0;

interface ICurve3Pool {
    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
        external;

    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function get_virtual_price() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity ^0.8.0;

import "Ownable.sol";

contract PausableGuardian_0_8 is Ownable {
    // keccak256("Pausable_FunctionPause")
    bytes32 internal constant Pausable_FunctionPause = 0xa7143c84d793a15503da6f19bf9119a2dac94448ca45d77c8bf08f57b2e91047;

    // keccak256("Pausable_GuardianAddress")
    bytes32 internal constant Pausable_GuardianAddress = 0x80e6706973d0c59541550537fd6a33b971efad732635e6c3b99fb01006803cdf;

    modifier pausable() {
        require(!_isPaused(msg.sig) || msg.sender == getGuardian(), "paused");
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender==owner() || msg.sender==getGuardian(), "unauthorized");_;
    }

    function _isPaused(bytes4 sig) public view returns (bool isPaused) {
        bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
        assembly {
            isPaused := sload(slot)
        }
    }

    function toggleFunctionPause(bytes4 sig) public {
        require(msg.sender == getGuardian() || msg.sender == owner(), "unauthorized");
        bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
        assembly {
            sstore(slot, 1)
        }
    }

    function toggleFunctionUnPause(bytes4 sig) public {
        // only DAO can unpause, and adding guardian temporarily
        require(msg.sender == getGuardian() || msg.sender == owner(), "unauthorized");
        bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
        assembly {
            sstore(slot, 0)
        }
    }

    function changeGuardian(address newGuardian) public {
        require(msg.sender == getGuardian() || msg.sender == owner(), "unauthorized");
        assembly {
            sstore(Pausable_GuardianAddress, newGuardian)
        }
    }

    function getGuardian() public view returns (address guardian) {
        assembly {
            guardian := sload(Pausable_GuardianAddress)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IBridge {
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external;

    function relay(
        bytes calldata _relayRequest,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    function transfers(bytes32 transferId) external view returns (bool);

    function withdraws(bytes32 withdrawId) external view returns (bool);

    function withdraw(
        bytes calldata _wdmsg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    /**
     * @notice Verifies that a message is signed by a quorum among the signers.
     * @param _msg signed message
     * @param _sigs list of signatures sorted by signer addresses in ascending order
     * @param _signers sorted list of current signers
     * @param _powers powers of current signers
     */
    function verifySigs(
        bytes memory _msg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external view;
}