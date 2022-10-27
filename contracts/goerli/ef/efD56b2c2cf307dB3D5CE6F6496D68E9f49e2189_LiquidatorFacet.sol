// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibAppStorage, Modifiers} from "./../../shared/libraries/LibAppStorage.sol";
import {LibLiquidatorStorage} from "./../liquidator/LibLiquidatorStorage.sol";
import {LibLiquidator} from "./../liquidator/LibLiquidator.sol";
import {LibMarketStorage} from "./../market/libraries/LibMarketStorage.sol";
import {IMarketRegistry} from "./../../interfaces/IMarketRegistry.sol";
import {LibTokenMarket} from "./../market/libraries/LibTokenMarket.sol";
import {IUserTier} from "./../../interfaces/IUserTier.sol";
import {IPriceConsumer} from "./../../interfaces/IPriceConsumer.sol";
import {IClaimToken} from "./../../interfaces/IClaimToken.sol";
import {LibMarketProvider} from "./../market/libraries/LibMarketProvider.sol";
import {LibMeta} from "../../shared/libraries/LibMeta.sol";
import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";

contract LiquidatorFacet is Modifiers {
    using SafeERC20 for IERC20;

    function liquidatorFacetInit(address _liquidator1, address _liquidator2)
        external
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibLiquidatorStorage.LiquidatorStorage storage ls = LibLiquidatorStorage.liquidatorStorage();
        require(
            LibMeta.msgSender() == ds.contractOwner,
            "Must own the contract."
        );
        require(!ls.isInitializedLiquidator, "Already initialized Liquidator");
        LibLiquidator._makeDefaultApproved(_liquidator1, true);
        LibLiquidator._makeDefaultApproved(_liquidator2, true);
        ls.isInitializedLiquidator = true;
    }

    /**
     * @dev makes _newLiquidator as a whitelisted liquidator
     * @param _newLiquidators Address of the new liquidators
     * @param _liquidatorRole access variables for _newLiquidator
     */
    function setLiquidator(
        address[] memory _newLiquidators,
        bool[] memory _liquidatorRole
    ) external onlySuperAdmin(LibMeta.msgSender()) {
        for (uint256 i = 0; i < _newLiquidators.length; i++) {
            LibLiquidator._makeDefaultApproved(
                _newLiquidators[i],
                _liquidatorRole[i]
            );
        }
    }

    function getAllLiquidators() external view returns (address[] memory) {
        LibLiquidatorStorage.LiquidatorStorage storage ls = LibLiquidatorStorage
            .liquidatorStorage();

        return ls.whitelistedLiquidators;
    }

    function getLiquidatorAccess(address _liquidator)
        external
        view
        returns (bool)
    {
        LibLiquidatorStorage.LiquidatorStorage storage ls = LibLiquidatorStorage
            .liquidatorStorage();
        return ls.whitelistLiquidators[_liquidator];
    }

    // liquidate loan implementation

    /**
    @dev approve collaterals to the one inch aggregator v4
    @param _collateralTokens collateral tokens
    @param _amounts collateral token amont
     */
    function approveCollateralTo1inch(
        address[] memory _collateralTokens,
        uint256[] memory _amounts
    ) external onlyLiquidator(LibMeta.msgSender()) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();
        uint256 lengthCollaterals = _collateralTokens.length;
        require(
            lengthCollaterals == _amounts.length,
            "collateral and amount length mismatch"
        );
        for (uint256 i = 0; i < lengthCollaterals; i++) {
            IERC20(_collateralTokens[i]).approve(
                ms.aggregator1Inch,
                _amounts[i]
            );
        }
    }

    /**
    @dev liquidate call from the gov world liquidator
    @param _loanId loan id to check if its liqudation pending or loan term ended
    @param _swapData is the data getting from the 1inch swap api after approving token from smart contract
    */

    function liquidateLoanToken(uint256 _loanId, bytes[] calldata _swapData)
        external
        onlyLiquidator(LibMeta.msgSender())
    {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        LibMarketStorage.LoanDetailsToken memory loanDetails = ms
            .borrowerLoanToken[_loanId];
        LibMarketStorage.LenderDetails memory lenderDetails = ms
            .activatedLoanToken[_loanId];

        require(
            loanDetails.loanStatus == LibMarketStorage.LoanStatus.ACTIVE,
            "GLM, not active"
        );

        require(
            LibLiquidator.isLiquidationPending(_loanId),
            "GTM: Liquidation Error"
        );

        if (lenderDetails.autoSell) {
            LibLiquidator._liquidateCollateralAutoSellOn(_loanId, _swapData);
        } else {
            LibLiquidator._liquidateCollateralAutoSellOff(_loanId);
        }
    }

    /**
    @dev only super admin can withdraw stable coin which includes platform fee and unearned apyFee
    */
    function withdrawStable(
        address _tokenAddress,
        uint256 _amount,
        address _walletAddress
    ) external onlySuperAdmin(LibMeta.msgSender()) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();
        uint256 availableAmount = ms.stableCoinWithdrawable[_tokenAddress];
        require(availableAmount > 0, "GNM: stable not available");
        require(_amount <= availableAmount, "GNL: Amount Invalid");
        ms.stableCoinWithdrawable[_tokenAddress] -= _amount;
        IERC20(_tokenAddress).safeTransfer(_walletAddress, _amount);
        emit LibLiquidator.WithdrawStable(
            _tokenAddress,
            _walletAddress,
            _amount
        );
    }

    /**
    @dev only super admin can withdraw exceed altcoins upon liquidation when autsell was off
    */
    function withdrawExceedAltcoins(
        address _tokenAddress,
        uint256 _amount,
        address _walletAddress
    ) external onlySuperAdmin(LibMeta.msgSender()) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        uint256 availableAmount = ms.collateralsWithdrawableToken[
            _tokenAddress
        ];
        require(availableAmount > 0, "GNM: stable not available");
        require(_amount <= availableAmount, "GNL: Amount Invalid");
        ms.collateralsWithdrawableToken[_tokenAddress] -= _amount;
        IERC20(_tokenAddress).safeTransfer(_walletAddress, _amount);
        emit LibLiquidator.WithdrawAltcoin(
            _tokenAddress,
            _walletAddress,
            _amount
        );
    }

    /**
    @dev token loan payback partial
    if _paybackAmount is equal to the total loan amount in stable coins the loan concludes as full payback
     */
    function paybackToken(uint256 _loanId, uint256 _paybackAmount) public {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        LibMarketStorage.LoanDetailsToken memory loanDetails = ms
            .borrowerLoanToken[_loanId];
        LibMarketStorage.LenderDetails memory lenderDetails = ms
            .activatedLoanToken[_loanId];

        require(
            loanDetails.borrower == LibMeta.msgSender(),
            "GLM, not borrower"
        );
        require(
            loanDetails.loanStatus == LibMarketStorage.LoanStatus.ACTIVE,
            "GLM, not active"
        );
        require(
            _paybackAmount > 0 &&
                _paybackAmount <= loanDetails.loanAmountInBorrowed,
            "GLM: Invalid Payback Loan Amount"
        );
        require(
            !LibLiquidator.isLiquidationPending(_loanId),
            "GLM: you cannot payback this time"
        );

        uint256 totalPayback = _paybackAmount + loanDetails.paybackAmount;
        if (totalPayback >= loanDetails.loanAmountInBorrowed) {
            LibLiquidator.fullLoanPaybackTokenEarly(_loanId, _paybackAmount);
        }
        //partial loan paypack
        else {
            ms.borrowerLoanToken[_loanId].paybackAmount += _paybackAmount;

            uint256 remainingLoanAmount = loanDetails.loanAmountInBorrowed -
                totalPayback;
            uint256 newLtv = IPriceConsumer(address(this)).calculateLTV(
                loanDetails.stakedCollateralAmounts,
                loanDetails.stakedCollateralTokens,
                loanDetails.borrowStableCoin,
                remainingLoanAmount
            );
            require(
                newLtv > IMarketRegistry(address(this)).getLTVPercentage(),
                "GLM: new LTV exceeds threshold."
            );
            IERC20(loanDetails.borrowStableCoin).safeTransferFrom(
                loanDetails.borrower,
                address(this),
                _paybackAmount
            );

            emit LibLiquidator.PartialTokensLoanPaybacked(
                _loanId,
                LibMeta.msgSender(),
                lenderDetails.lender,
                _paybackAmount
            );
        }
    }

    function getLenderSUNTokenBalances(address _lender, address _sunToken)
        public
        view
        returns (uint256)
    {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        return ms.liquidatedSUNTokenbalances[_lender][_sunToken];
    }

    function getStableCoinWithdrawable(address _stable)
        external
        view
        returns (uint256)
    {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();
        return ms.stableCoinWithdrawable[_stable];
    }

    function getCollateralWithdrawableToken(address _collateral)
        external
        view
        returns (uint256)
    {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();
        return ms.collateralsWithdrawableToken[_collateral];
    }

    function getLTVToken(uint256 _loanIdToken) external view returns (uint256) {
        return LibLiquidator.getLtv(_loanIdToken);
    }

    function isLiquidationPendingToken(uint256 _loanIdToken)
        external
        view
        returns (bool)
    {
        return LibLiquidator.isLiquidationPending(_loanIdToken);
    }

    function getTotalPaybackAmountToken(uint256 _loanIdToken)
        external
        view
        returns (uint256 loanAmountwithEarnedAPYFee, uint256 earnedAPYFee)
    {
        return LibLiquidator.getTotalPaybackAmount(_loanIdToken);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IMarketRegistry {
    function getLoanActivateLimit() external view returns (uint256);

    function getLTVPercentage() external view returns (uint256);

    function isWhitelistedForActivation(address) external returns (bool);

    function getMinLoanAmountAllowed() external view returns (uint256);

    function getMultiCollateralLimit() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {LibPriceConsumerStorage} from "./../facets/oracle/LibPriceConsumerStorage.sol";

interface IPriceConsumer {
    /// @dev Use chainlink PriceAggrigator to fetch prices of the already added feeds.
    /// @param priceFeedToken price fee token address for getting the price
    /// @return int256 returns the price value  from the chainlink
    /// @return uint8 returns the decimal of the price feed toekn
    function getTokenPriceFromChainlink(address priceFeedToken)
        external
        view
        returns (int256, uint8);

    /// @dev multiple token prices fetch
    /// @param priceFeedToken multi token price fetch
    /// @return tokens returns the token address of the pricefeed token addresses
    /// @return prices returns the prices of each token in array
    /// @return decimals returns the token decimals in array
    function getTokensPriceFromChainlink(address[] memory priceFeedToken)
        external
        view
        returns (
            address[] memory tokens,
            int256[] memory prices,
            uint8[] memory decimals
        );

    /// @dev get the dex router swap data
    /// @param _collateralToken  collateral token address
    /// @param _collateralAmount collatera token amount in decimals
    /// @param _borrowStableCoin stable coin token address
    function getSwapData(
        address _collateralToken,
        uint256 _collateralAmount,
        address _borrowStableCoin
    ) external view returns (uint256, uint256);

    /// @dev get the swap interface contract address of the collateral token
    /// @return address returns the swap router contract
    function getSwapInterface(address _collateralTokenAddress)
        external
        view
        returns (address);

    /// @dev How much worth alt is in terms of stable coin passed (e.g. X ALT =  ? STABLE COIN)
    /// @param _stable address of stable coin
    /// @param _alt address of alt coin
    /// @param _amount address of alt
    /// @return uint256 returns the price of alt coin in stable in stable coin decimals
    function getTokenPriceFromDex(
        address _stable,
        address _alt,
        uint256 _amount,
        address _dexRouter
    ) external view returns (uint256);

    /// @dev check wether token feed for this token is enabled or not
    function isChainlinkFeedEnabled(address _tokenAddress)
        external
        view
        returns (bool);

    /// @dev get the chainlink Data feed of the token address
    /// @param _tokenAddress token address
    /// @return ChainlinkDataFeed returns the details chainlink data feed
    function getAggregatorData(address _tokenAddress)
        external
        view
        returns (LibPriceConsumerStorage.ChainlinkDataFeed memory);

    /// @dev get all the chainlink aggregators contract address
    /// @return address[] returns the array of the contract address
    function getAggregators() external view returns (address[] memory);

    /// @dev get all the gov aggregator tokens approved
    /// @return address[] returns the array of the gov aggregators contracts
    function getGovAggregatorTokens() external view returns (address[] memory);

    /// @dev returns the weth contract address
    function wethAddress() external view returns (address);

    /// @dev get the altcoin price in stable address
    /// @param _stableCoin address of the stable token address
    /// @param _altCoin address of the altcoin token address
    /// @param _collateralAmount collateral token amount in decimals
    /// @return uint256 returns the price of collateral in stable
    function getCollateralPriceinStable(
        address _stableCoin,
        address _altCoin,
        uint256 _collateralAmount
    ) external view returns (uint256);

    function getStablePriceInCollateral(
        address _altcoin,
        address _stableCoin,
        uint256 _stableCoinAmount
    ) external view returns (uint256);

    /// @dev returns the calculated ltv percentage
    /// @param _stakedCollateralAmounts staked collateral amounts array
    /// @param _stakedCollateralTokens collateral token addresses
    /// @param _borrowedToken stable coin address
    /// @param _loanAmount loan amount in stable coin decimals
    /// @return uint256 returns the calculated ltv percentage

    function calculateLTV(
        uint256[] memory _stakedCollateralAmounts,
        address[] memory _stakedCollateralTokens,
        address _borrowedToken,
        uint256 _loanAmount
    ) external view returns (uint256);

    /// @dev get the sun token price
    /// @param _claimToken address of the claim token
    /// @param _stable stable token address
    /// @param _sunToken address of the sun token
    /// @param _amount amount of sun token in decimals
    /// @return uint256 returns the price of the sun token
    function getSunTokenInStable(
        address _claimToken,
        address _stable,
        address _sunToken,
        uint256 _amount
    ) external view returns (uint256);

    function getStableInSunToken(
        address _stable,
        address _claimToken,
        address _sunToken,
        uint256 _amount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./../facets/govTier/LibGovTierStorage.sol";
import {LibMarketStorage} from "./../facets/market/libraries/LibMarketStorage.sol";

interface IUserTier {
    function getTierDatabyGovBalance(address userWalletAddress)
        external
        view
        returns (LibGovTierStorage.TierData memory _tierData);

    function getMaxLoanAmount(
        uint256 _collateralTokeninStable,
        uint256 _tierLevelLTVPercentage
    ) external pure returns (uint256);

    function getMaxLoanAmountToValue(
        uint256 _collateralTokeninStable,
        address _borrower,
        LibMarketStorage.TierType tierType
    ) external view returns (uint256);

    function isCreateLoanTokenUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 collateralInBorrowed,
        address[] memory stakedCollateralTokens,
        LibMarketStorage.TierType tierType
    ) external view returns (uint256);

    function isCreateLoanNftUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 collateralInBorrowed,
        address[] memory stakedCollateralTokens,
        LibMarketStorage.TierType tierType
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {LibClaimTokenStorage} from "./../facets/claimtoken/LibClaimTokenStorage.sol";

interface IClaimToken {
    function isClaimToken(address _claimTokenAddress)
        external
        view
        returns (bool);

    function getClaimTokensData(address _claimTokenAddress)
        external
        view
        returns (LibClaimTokenStorage.ClaimTokenData memory);

    function getClaimTokenofSUNToken(address _sunToken)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {LibDiamond} from "./../../shared/libraries/LibDiamond.sol";
import {LibAdminStorage} from "./../../facets/admin/LibAdminStorage.sol";
import {LibLiquidatorStorage} from "./../../facets/liquidator/LibLiquidatorStorage.sol";
import {LibProtocolStorage} from "./../../facets/protocolRegistry/LibProtocolStorage.sol";
import {LibPausable} from "./../../shared/libraries/LibPausable.sol";

struct AppStorage {
    address govToken;
    address govGovToken;
}

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlySuperAdmin(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(es.approvedAdminRoles[admin].superAdmin, "not super admin");
        _;
    }

    /// @dev modifer only admin with edit admin access can call functions
    modifier onlyEditTierLevelRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(
            es.approvedAdminRoles[admin].editGovAdmin,
            "not edit tier role"
        );
        _;
    }

    modifier onlyLiquidator(address _admin) {
        LibLiquidatorStorage.LiquidatorStorage storage es = LibLiquidatorStorage
            .liquidatorStorage();
        require(es.whitelistLiquidators[_admin], "not liquidator");
        _;
    }

    //modifier: only admin with AddTokenRole can add Token(s) or NFT(s)
    modifier onlyAddTokenRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(es.approvedAdminRoles[admin].addToken, "not add token role");
        _;
    }

    //modifier: only admin with EditTokenRole can update or remove Token(s)/NFT(s)
    modifier onlyEditTokenRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(es.approvedAdminRoles[admin].editToken, "not edit token role");
        _;
    }

    //modifier: only admin with AddSpAccessRole can add SP Wallet
    modifier onlyAddSpRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();
        require(es.approvedAdminRoles[admin].addSp, "not add sp role");
        _;
    }

    //modifier: only admin with EditSpAccess can update or remove SP Wallet
    modifier onlyEditSpRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();
        require(es.approvedAdminRoles[admin].editSp, "not edit sp role");
        _;
    }

    modifier whenNotPaused() {
        LibPausable.enforceNotPaused();
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LibAppStorage, AppStorage} from "./../../shared/libraries/LibAppStorage.sol";
import {IClaimToken} from "./../../interfaces/IClaimToken.sol";
import {IMarketRegistry} from "./../../interfaces/IMarketRegistry.sol";
import {IPriceConsumer} from "./../../interfaces/IPriceConsumer.sol";
import {IGToken} from "./../../interfaces/IGToken.sol";
import {IProtocolRegistry} from "./../../interfaces/IProtocolRegistry.sol";
import {IUniswapSwapInterface} from "./../../interfaces/IUniswapSwapInterface.sol";
import {LibMarketStorage} from "./../market/libraries/LibMarketStorage.sol";
import {LibMarketProvider} from "./../market/libraries/LibMarketProvider.sol";
import {LibProtocolStorage} from "./../protocolRegistry/LibProtocolStorage.sol";
import {LibLiquidatorStorage} from "./../../facets/liquidator/LibLiquidatorStorage.sol";

library LibLiquidator {
    using SafeERC20 for IERC20;

    event NewLiquidatorApproved(
        address indexed _newLiquidator,
        bool _liquidatorAccess
    );
    event AutoSellONLiquidated(
        uint256 _loanId,
        LibMarketStorage.LoanStatus loanStatus
    );
    event AutoSellOFFLiquidated(
        uint256 _loanId,
        LibMarketStorage.LoanStatus loanStatus
    );

    event WithdrawStable(
        address tokenAddress,
        address walletAddress,
        uint256 withdrawAmount
    );

    event WithdrawAltcoin(
        address tokenAddress,
        address walletAddress,
        uint256 withdrawAmount
    );

    event FullTokensLoanPaybacked(
        uint256 loanId,
        address _borrower,
        address _lender,
        uint256 _paybackAmount,
        LibMarketStorage.LoanStatus loanStatus,
        uint256 _earnedAPY
    );

    event PartialTokensLoanPaybacked(
        uint256 loanId,
        address _borrower,
        address _lender,
        uint256 paybackAmount
    );

    /**
     * @dev makes _newLiquidator an approved liquidator and emits the event
     * @param _newLiquidator Address of the new liquidator
     * @param _liquidatorAccess access variables for _newLiquidator
     */
    function _makeDefaultApproved(
        address _newLiquidator,
        bool _liquidatorAccess
    ) internal {
        LibLiquidatorStorage.LiquidatorStorage storage ls = LibLiquidatorStorage
            .liquidatorStorage();
        require(
            ls.whitelistLiquidators[_newLiquidator] != _liquidatorAccess,
            "GL: cannot assign same"
        );
        ls.whitelistLiquidators[_newLiquidator] = _liquidatorAccess;
        ls.whitelistedLiquidators.push(_newLiquidator);
        emit NewLiquidatorApproved(_newLiquidator, _liquidatorAccess);
    }

    // liquidate loan implementation

    function _liquidateCollateralAutoSellOn(
        uint256 _loanId,
        bytes[] calldata _swapData
    ) internal {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        ms.borrowerLoanToken[_loanId].loanStatus = LibMarketStorage
            .LoanStatus
            .LIQUIDATED;

        LibMarketStorage.LoanDetailsToken memory loanDetails = ms
            .borrowerLoanToken[_loanId];
        LibMarketStorage.LenderDetails memory lenderDetails = ms
            .activatedLoanToken[_loanId];

        (, uint256 earnedAPYFee) = getTotalPaybackAmount(_loanId);
        uint256 apyFeeOriginal = LibMarketProvider.getAPYFee(
            loanDetails.loanAmountInBorrowed,
            loanDetails.apyOffer,
            loanDetails.termsLengthInDays
        );

        //as we get the payback amount according to the days passed
        //let say if (days passed earned APY) is greater than the original APY,
        // then we only sent the earned apy fee amount to the lender
        // add unearned apy in stable coin to stableCoinWithdrawable mapping
        if (earnedAPYFee > apyFeeOriginal) {
            earnedAPYFee = apyFeeOriginal;
        }

        uint256 unEarnedAPYFee = apyFeeOriginal - earnedAPYFee;

        uint256 lengthCollaterals = loanDetails.stakedCollateralTokens.length;
        uint256 callDataLength = _swapData.length;
        require(
            callDataLength == lengthCollaterals,
            "swap call data and collateral length mismatch"
        );
        uint256 previousBalance = IERC20(loanDetails.borrowStableCoin)
            .balanceOf(address(this));

        for (uint256 i = 0; i < lengthCollaterals; i++) {
            LibProtocolStorage.Market memory market = IProtocolRegistry(
                address(this)
            ).getSingleApproveToken(loanDetails.stakedCollateralTokens[i]);
            if (loanDetails.isMintSp[i]) {
                IGToken(market.gToken).burnFrom(
                    loanDetails.borrower,
                    loanDetails.stakedCollateralAmounts[i]
                );
            }
            //inch swap
            //     address aggregator1Inch = marketRegistry.getOneInchAggregator();
            //     (bool success, ) = address(aggregator1Inch).call(_swapData[i]);
            //     require(success, "One 1Inch Swap Failed");
            address[] memory path = new address[](2);
            path[0] = loanDetails.stakedCollateralTokens[i];
            path[1] = loanDetails.borrowStableCoin;

            (uint256 amountIn, ) = IPriceConsumer(address(this)).getSwapData(
                path[0],
                loanDetails.stakedCollateralAmounts[i],
                path[1]
            );
            //transfer the swap stable coins to the liquidator contract address.
            IUniswapSwapInterface swapInterface = IUniswapSwapInterface(
                IPriceConsumer(address(this)).getSwapInterface(
                    loanDetails.stakedCollateralTokens[i]
                )
            );
            IERC20(loanDetails.stakedCollateralTokens[i]).approve(
                address(swapInterface),
                amountIn
            );
            swapInterface.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    amountIn,
                    0, //amountOut cause slippage while swapping
                    path,
                    address(this),
                    block.timestamp + 10 minutes
                );
        }
        //avoid stack too deep
        {
            uint256 newBalance = IERC20(loanDetails.borrowStableCoin).balanceOf(
                address(this)
            );
            uint256 totalSwapped = newBalance - previousBalance;

            uint256 autosellFeeinStable = LibMarketProvider.getautosellAPYFee(
                loanDetails.loanAmountInBorrowed,
                IProtocolRegistry(address(this)).getAutosellPercentage(),
                loanDetails.termsLengthInDays
            );

            uint256 leftAmount;
            if ((totalSwapped > loanDetails.loanAmountInBorrowed)) {
                leftAmount = totalSwapped - loanDetails.loanAmountInBorrowed;
            }

            ms.stableCoinWithdrawable[loanDetails.borrowStableCoin] +=
                autosellFeeinStable +
                leftAmount +
                unEarnedAPYFee;

            IERC20(loanDetails.borrowStableCoin).safeTransfer(
                lenderDetails.lender,
                (loanDetails.loanAmountInBorrowed + earnedAPYFee) -
                    (autosellFeeinStable)
            );
        }
        emit AutoSellONLiquidated(
            _loanId,
            LibMarketStorage.LoanStatus.LIQUIDATED
        );
    }

    function _liquidateCollateralAutoSellOff(uint256 _loanId) internal {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        //loan status is now liquidated

        ms.borrowerLoanToken[_loanId].loanStatus = LibMarketStorage
            .LoanStatus
            .LIQUIDATED;

        LibMarketStorage.LoanDetailsToken memory loanDetails = ms
            .borrowerLoanToken[_loanId];
        LibMarketStorage.LenderDetails memory lenderDetails = ms
            .activatedLoanToken[_loanId];

        (, uint256 earnedAPYFee) = getTotalPaybackAmount(_loanId);
        // uint256 thresholdFee = govProtocolRegistry.getThresholdPercentage();
        {
            uint256 apyFeeOriginal = LibMarketProvider.getAPYFee(
                loanDetails.loanAmountInBorrowed,
                loanDetails.apyOffer,
                loanDetails.termsLengthInDays
            );

            //as we get the payback amount according to the days passed
            //let say if (days passed earned APY) is greater than the original APY,
            // then we only sent the earned apy fee amount to the lender
            if (earnedAPYFee > apyFeeOriginal) {
                earnedAPYFee = apyFeeOriginal;
            }
        }
        uint256 thresholdFeeinStable = (loanDetails.loanAmountInBorrowed *
            IProtocolRegistry(address(this)).getThresholdPercentage()) / 10000;

        //send collateral tokens to the lender
        uint256 collateralAmountinStable;
        uint256 exceedAltcoinValue;
        bool isAllDone;

        for (
            uint256 i = 0;
            i < loanDetails.stakedCollateralTokens.length;
            i++
        ) {
            address claimToken = IClaimToken(address(this))
                .getClaimTokenofSUNToken(loanDetails.stakedCollateralTokens[i]);

            if (IClaimToken(address(this)).isClaimToken(claimToken)) {
                //get price
                uint256 priceofSunCollateral = IPriceConsumer(address(this))
                    .getSunTokenInStable(
                        claimToken,
                        loanDetails.borrowStableCoin,
                        loanDetails.stakedCollateralTokens[i],
                        loanDetails.stakedCollateralAmounts[i]
                    );
                ms.liquidatedSUNTokenbalances[lenderDetails.lender][
                        loanDetails.stakedCollateralTokens[i]
                    ] += loanDetails.stakedCollateralAmounts[i];
                collateralAmountinStable =
                    collateralAmountinStable +
                    priceofSunCollateral;
            } else {
                LibProtocolStorage.Market memory market = IProtocolRegistry(
                    address(this)
                ).getSingleApproveToken(loanDetails.stakedCollateralTokens[i]);
                if (loanDetails.isMintSp[i]) {
                    IGToken(market.gToken).burnFrom(
                        loanDetails.borrower,
                        loanDetails.stakedCollateralAmounts[i]
                    );
                }
                uint256 priceofCollateral = IPriceConsumer(address(this))
                    .getCollateralPriceinStable(
                        loanDetails.borrowStableCoin,
                        loanDetails.stakedCollateralTokens[i],
                        loanDetails.stakedCollateralAmounts[i]
                    );
                collateralAmountinStable =
                    collateralAmountinStable +
                    priceofCollateral;
            }

            if (
                collateralAmountinStable <=
                loanDetails.loanAmountInBorrowed + thresholdFeeinStable
            ) {
                IERC20(loanDetails.stakedCollateralTokens[i]).safeTransfer(
                    lenderDetails.lender,
                    loanDetails.stakedCollateralAmounts[i]
                );
            } else if (
                collateralAmountinStable >
                loanDetails.loanAmountInBorrowed + thresholdFeeinStable &&
                !isAllDone
            ) {
                if (IClaimToken(address(this)).isClaimToken(claimToken)) {
                    // get stable coin price in sun token
                    exceedAltcoinValue = IPriceConsumer(address(this))
                        .getStableInSunToken(
                            loanDetails.borrowStableCoin,
                            claimToken,
                            loanDetails.stakedCollateralTokens[i],
                            collateralAmountinStable -
                                (loanDetails.loanAmountInBorrowed +
                                    thresholdFeeinStable)
                        );
                } else {
                    exceedAltcoinValue = IPriceConsumer(address(this))
                        .getStablePriceInCollateral(
                            loanDetails.stakedCollateralTokens[i],
                            loanDetails.borrowStableCoin,
                            collateralAmountinStable -
                                (loanDetails.loanAmountInBorrowed +
                                    thresholdFeeinStable)
                        );
                }
                uint256 collateralToLender = loanDetails
                    .stakedCollateralAmounts[i] - exceedAltcoinValue;

                // adding exceed altcoin to the superadmin withdrawable collateral tokens
                ms.collateralsWithdrawableToken[
                    loanDetails.stakedCollateralTokens[i]
                ] += exceedAltcoinValue;

                IERC20(loanDetails.stakedCollateralTokens[i]).safeTransfer(
                    lenderDetails.lender,
                    collateralToLender
                );
                isAllDone = true;
            } else {
                // adding exceed altcoin to the superadmin withdrawable collateral tokens
                ms.collateralsWithdrawableToken[
                    loanDetails.stakedCollateralTokens[i]
                ] += loanDetails.stakedCollateralAmounts[i];
            }
        }

        //lender recieves the stable coins
        IERC20(loanDetails.borrowStableCoin).safeTransfer(
            lenderDetails.lender,
            earnedAPYFee
        );
        emit AutoSellOFFLiquidated(
            _loanId,
            LibMarketStorage.LoanStatus.LIQUIDATED
        );
    }

    /**
    @dev functino to get the LTV of the loan amount in borrowed of the staked colletral token
    @param _loanId loan ID for which ltv is getting
     */
    function getLtv(uint256 _loanId) internal view returns (uint256) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();
        LibMarketStorage.LoanDetailsToken memory loanDetails = ms
            .borrowerLoanToken[_loanId];

        //get individual collateral tokens for the loan id
        uint256[] memory stakedCollateralAmounts = loanDetails
            .stakedCollateralAmounts;
        address[] memory stakedCollateralTokens = loanDetails
            .stakedCollateralTokens;
        address borrowedToken = loanDetails.borrowStableCoin;
        return
            IPriceConsumer(address(this)).calculateLTV(
                stakedCollateralAmounts,
                stakedCollateralTokens,
                borrowedToken,
                loanDetails.loanAmountInBorrowed - loanDetails.paybackAmount
            );
    }

    /**
    @dev function to check the loan is pending for liqudation or not
    @param _loanId for which loan liquidation checking
     */
    function isLiquidationPending(uint256 _loanId)
        internal
        view
        returns (bool)
    {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        LibMarketStorage.LoanDetailsToken memory loanDetails = ms
            .borrowerLoanToken[_loanId];
        LibMarketStorage.LenderDetails memory lenderDetails = ms
            .activatedLoanToken[_loanId];

        // TODO: change from 600 to 86400

        uint256 loanTermLengthPassedInDays = (block.timestamp -
            lenderDetails.activationLoanTimeStamp) / 600;

        // @dev get LTV
        uint256 calulatedLTV = getLtv(_loanId);
        //@dev the collateral is less than liquidation threshold percentage/loan term length end ok for liquidation
        // @dev loanDetails.termsLengthInDays + 1 is which we are giving extra time to the borrower to payback the collateral
        if (
            calulatedLTV <= IMarketRegistry(address(this)).getLTVPercentage() ||
            (loanTermLengthPassedInDays >= loanDetails.termsLengthInDays + 1)
        ) return true;
        else return false;
    }

    function getTotalPaybackAmount(uint256 _loanId)
        internal
        view
        returns (uint256 loanAmountwithEarnedAPYFee, uint256 earnedAPYFee)
    {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();

        LibMarketStorage.LoanDetailsToken memory loanDetails = ms
            .borrowerLoanToken[_loanId];
        LibMarketStorage.LenderDetails memory lenderDetails = ms
            .activatedLoanToken[_loanId];

        // TODO: change from 600 to 86400
        uint256 loanTermLengthPassedInDays = (block.timestamp -
            (lenderDetails.activationLoanTimeStamp)) / 600;
        earnedAPYFee =
            ((loanDetails.loanAmountInBorrowed * loanDetails.apyOffer) /
                10000 /
                365) *
            loanTermLengthPassedInDays;
        return (loanDetails.loanAmountInBorrowed + earnedAPYFee, earnedAPYFee);
    }

    /**
    @dev payback loan full by the borrower to the lender
     */
    function fullLoanPaybackTokenEarly(uint256 _loanId, uint256 _paybackAmount)
        internal
    {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();
        ms.borrowerLoanToken[_loanId].loanStatus = LibMarketStorage
            .LoanStatus
            .CLOSED;

        LibMarketStorage.LoanDetailsToken memory loanDetails = ms
            .borrowerLoanToken[_loanId];
        LibMarketStorage.LenderDetails memory lenderDetails = ms
            .activatedLoanToken[_loanId];

        (
            uint256 finalPaybackAmounttoLender,
            uint256 earnedAPYFee
        ) = getTotalPaybackAmount(_loanId);

        uint256 apyFeeOriginal = LibMarketProvider.getAPYFee(
            loanDetails.loanAmountInBorrowed,
            loanDetails.apyOffer,
            loanDetails.termsLengthInDays
        );

        uint256 unEarnedAPYFee = apyFeeOriginal - earnedAPYFee;
        //adding the unearned APY in the contract stableCoinWithdrawable mapping
        //only superAdmin can withdraw this much amount
        ms.stableCoinWithdrawable[
            loanDetails.borrowStableCoin
        ] += unEarnedAPYFee;

        //first transferring the payback amount from borrower to the Gov Token Market
        IERC20(loanDetails.borrowStableCoin).safeTransferFrom(
            loanDetails.borrower,
            address(this),
            loanDetails.loanAmountInBorrowed - loanDetails.paybackAmount
        );
        IERC20(loanDetails.borrowStableCoin).safeTransfer(
            lenderDetails.lender,
            finalPaybackAmounttoLender
        );
        uint256 lengthCollateral = loanDetails.stakedCollateralTokens.length;

        //loop through all staked collateral tokens.
        for (uint256 i = 0; i < lengthCollateral; i++) {
            //contract will the repay staked collateral tokens to the borrower
            IERC20(loanDetails.stakedCollateralTokens[i]).safeTransfer(
                msg.sender,
                loanDetails.stakedCollateralAmounts[i]
            );
            LibProtocolStorage.Market memory market = IProtocolRegistry(
                address(this)
            ).getSingleApproveToken(loanDetails.stakedCollateralTokens[i]);
            IGToken gtoken = IGToken(market.gToken);
            if (
                market.tokenType == LibProtocolStorage.TokenType.ISVIP &&
                loanDetails.isMintSp[i]
            ) {
                gtoken.burnFrom(
                    loanDetails.borrower,
                    loanDetails.stakedCollateralAmounts[i]
                );
            }
        }

        ms.borrowerLoanToken[_loanId].paybackAmount += _paybackAmount;

        emit FullTokensLoanPaybacked(
            _loanId,
            msg.sender,
            lenderDetails.lender,
            loanDetails.loanAmountInBorrowed - loanDetails.paybackAmount,
            LibMarketStorage.LoanStatus.CLOSED,
            earnedAPYFee
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library LibLiquidatorStorage {
    bytes32 constant LIQUIDATOR_STORAGE =
        keccak256("diamond.standard.LIQUIDATOR.storage");
    struct LiquidatorStorage {
        mapping(address => bool) whitelistLiquidators; // list of already approved liquidators.
        mapping(address => mapping(address => uint256)) liquidatedSUNTokenbalances; //mapping of wallet address to track the approved claim token balances when loan is liquidated // wallet address lender => sunTokenAddress => balanceofSUNToken
        address[] whitelistedLiquidators; // list of all approved liquidator addresses. Stores the key for mapping approvedLiquidators
        address aggregator1Inch;
        bool isInitializedLiquidator;
    }

    function liquidatorStorage()
        internal
        pure
        returns (LiquidatorStorage storage ls)
    {
        bytes32 position = LIQUIDATOR_STORAGE;
        assembly {
            ls.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library LibMeta {
    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {LibMeta} from "./LibMeta.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferredDiamond(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferredDiamond(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            LibMeta.msgSender() == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    function addDiamondFunctions(
        address _diamondCutFacet,
        address _diamondLoupeFacet,
        address _ownershipFacet
    ) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[4] = IERC165.supportsInterface.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: _diamondLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        functionSelectors = new bytes4[](2);
        functionSelectors[0] = IERC173.transferOwnership.selector;
        functionSelectors[1] = IERC173.owner.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: _ownershipFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        diamondCut(cut, address(0), "");
    }

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint16 selectorPosition = uint16(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(
                _facetAddress,
                "LibDiamondCut: New facet has no code"
            );
            ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
                selector
            );
            ds
                .selectorToFacetAndPosition[selector]
                .facetAddress = _facetAddress;
            ds
                .selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint16 selectorPosition = uint16(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(
                _facetAddress,
                "LibDiamondCut: New facet has no code"
            );
            ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(oldFacetAddress, selector);
            // add function
            ds
                .selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
                selector
            );
            ds
                .selectorToFacetAndPosition[selector]
                .facetAddress = _facetAddress;
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (success == false) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize != 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LibAppStorage, AppStorage} from "./../../../shared/libraries/LibAppStorage.sol";
import {IClaimToken} from "./../../../interfaces/IClaimToken.sol";
import {IMarketRegistry} from "./../../../interfaces/IMarketRegistry.sol";
import {IPriceConsumer} from "./../../../interfaces/IPriceConsumer.sol";
import {IUserTier} from "./../../../interfaces/IUserTier.sol";
import {IGToken} from "./../../../interfaces/IGToken.sol";
import {LibMarketStorage} from "./../../market/libraries/LibMarketStorage.sol";
import "./../../../interfaces/IProtocolRegistry.sol";

library LibTokenMarket {
    using SafeERC20 for IERC20;

    event LoanOfferCreatedToken(
        uint256 _loanId,
        LibMarketStorage.LoanDetailsToken _loanDetailsToken
    );

    event LoanOfferAdjustedToken(
        uint256 _loanId,
        LibMarketStorage.LoanDetailsToken _loanDetails
    );

    event TokenLoanOfferActivated(
        uint256 loanId,
        address _lender,
        uint256 _stableCoinAmount,
        bool _autoSell
    );

    event LoanOfferCancelToken(
        uint256 loanId,
        address _borrower,
        LibMarketStorage.LoanStatus loanStatus
    );

    /// @dev internal function checking ERC20 collateral token approval
    /// @param _collateralTokens array of collateral token addresses
    /// @param _collateralAmounts array of collateral amounts
    /// @param isMintSp will be false for all the collateral tokens, and will be true at the time of activate loan
    /// @param borrower address of the borrower whose collateral approval is checking
    /// @return bool return the bool value true or false

    function checkApprovalCollaterals(
        address[] memory _collateralTokens,
        uint256[] memory _collateralAmounts,
        bool[] memory isMintSp,
        address borrower
    ) internal view returns (bool) {
        uint256 length = _collateralTokens.length;
        for (uint256 i = 0; i < length; i++) {
            address claimToken = IClaimToken(address(this))
                .getClaimTokenofSUNToken(_collateralTokens[i]);
            require(
                IProtocolRegistry(address(this)).isTokenApproved(
                    _collateralTokens[i]
                ) || IClaimToken(address(this)).isClaimToken(claimToken),
                "GLM: One or more tokens not approved."
            );
            require(
                IProtocolRegistry(address(this)).isTokenEnabledForCreateLoan(
                    _collateralTokens[i]
                ),
                "GTM: token not enabled"
            );
            require(!isMintSp[i], "GLM: mint error");
            uint256 allowance = IERC20(_collateralTokens[i]).allowance(
                borrower,
                address(this)
            );
            require(
                allowance >= _collateralAmounts[i],
                "GTM: Transfer amount exceeds allowance."
            );
        }

        return true;
    }

    /// @dev this function returns calulatedLTV Percentage, maxLoanAmountValue, and  collatetral Price In Borrowed Stable
    /// @param _stakedCollateralTokens addresses array of the staked collateral token by the borrower
    /// @param _stakedCollateralAmount collateral tokens amount array
    /// @param _borrowStableCoin stable coin address the borrower want to borrrower
    /// @param _loanAmountinStable loan amount in stable address decimals
    /// @param _borrower address of the borrower
    function getltvCalculations(
        address[] memory _stakedCollateralTokens,
        uint256[] memory _stakedCollateralAmount,
        address _borrowStableCoin,
        uint256 _loanAmountinStable,
        address _borrower,
        LibMarketStorage.TierType _tierType
    )
        internal
        view
        returns (
            uint256 calculatedLTV,
            uint256 maxLoanAmountValue,
            uint256 collatetralInBorrowed
        )
    {
        for (
            uint256 index = 0;
            index < _stakedCollateralAmount.length;
            index++
        ) {
            address claimToken = IClaimToken(address(this))
                .getClaimTokenofSUNToken(_stakedCollateralTokens[index]);
            if (IClaimToken(address(this)).isClaimToken(claimToken)) {
                collatetralInBorrowed =
                    collatetralInBorrowed +
                    (
                        IPriceConsumer(address(this)).getSunTokenInStable(
                            claimToken,
                            _borrowStableCoin,
                            _stakedCollateralTokens[index],
                            _stakedCollateralAmount[index]
                        )
                    );
            } else {
                collatetralInBorrowed =
                    collatetralInBorrowed +
                    (
                        IPriceConsumer(address(this))
                            .getCollateralPriceinStable(
                                _borrowStableCoin,
                                _stakedCollateralTokens[index],
                                _stakedCollateralAmount[index]
                            )
                    );
            }
        }
        calculatedLTV = IPriceConsumer(address(this)).calculateLTV(
            _stakedCollateralAmount,
            _stakedCollateralTokens,
            _borrowStableCoin,
            _loanAmountinStable
        );
        maxLoanAmountValue = IUserTier(address(this)).getMaxLoanAmountToValue(
            collatetralInBorrowed,
            _borrower,
            _tierType
        );

        return (calculatedLTV, maxLoanAmountValue, collatetralInBorrowed);
    }

    /// @dev check approve of tokens, transfer token to contract and mint synthetic token if mintVip is on for that collateral token
    /// @param _loanId using loanId to make isMintSp flag true in the create loan function
    /// @param collateralAddresses collateral token addresses array
    /// @param collateralAmounts collateral token amounts array
    /// @return bool return true if succesful check all the approval of token and transfer of collateral tokens, else returns false.
    function transferCollateralsandMintSynthetic(
        uint256 _loanId,
        address[] memory collateralAddresses,
        uint256[] memory collateralAmounts,
        address borrower
    ) internal returns (bool) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();
        uint256 length = collateralAddresses.length;
        for (uint256 k = 0; k < length; k++) {
            IERC20(collateralAddresses[k]).safeTransferFrom(
                borrower,
                address(this),
                collateralAmounts[k]
            );
            {
                (address gToken, , ) = IProtocolRegistry(address(this))
                    .getSingleApproveTokenData(collateralAddresses[k]);
                if (
                    IProtocolRegistry(address(this)).isSyntheticMintOn(
                        collateralAddresses[k]
                    )
                ) {
                    IGToken(gToken).mint(borrower, collateralAmounts[k]);
                    ms.borrowerLoanToken[_loanId].isMintSp[k] = true;
                }
            }
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library LibMarketStorage {
    bytes32 constant MARKET_STORAGE_POSITION =
        keccak256("diamond.standard.MARKET.storage");

    enum TierType {
        GOV_TIER,
        NFT_TIER,
        NFT_SP_TIER,
        VC_TIER
    }

    enum LoanStatus {
        ACTIVE,
        INACTIVE,
        CLOSED,
        CANCELLED,
        LIQUIDATED
    }

    enum LoanTypeToken {
        SINGLE_TOKEN,
        MULTI_TOKEN
    }

    enum LoanTypeNFT {
        SINGLE_NFT,
        MULTI_NFT
    }

    struct LenderDetails {
        address lender;
        uint256 activationLoanTimeStamp;
        bool autoSell;
    }

    struct LenderDetailsNFT {
        address lender;
        uint256 activationLoanTimeStamp;
    }

    struct LoanDetailsToken {
        uint256 loanAmountInBorrowed; //total Loan Amount in Borrowed stable coin
        uint256 termsLengthInDays; //user choose terms length in days
        uint32 apyOffer; //borrower given apy percentage
        LoanTypeToken loanType; //Single-ERC20, Multiple staked ERC20,
        bool isPrivate; //private loans will not appear on loan market
        bool isInsured; //Future use flag to insure funds as they go to protocol.
        address[] stakedCollateralTokens; //single - or multi token collateral tokens wrt tokenAddress
        uint256[] stakedCollateralAmounts; // collateral amounts
        address borrowStableCoin; // address of the stable coin borrow wants
        LoanStatus loanStatus; //current status of the loan
        address borrower; //borrower's address
        uint256 paybackAmount; // track the record of payback amount
        bool[] isMintSp; // flag for the mint VIP token at the time of creating loan
        TierType tierType;
    }

    struct LoanDetailsNFT {
        address[] stakedCollateralNFTsAddress; //single nft or multi nft addresses
        uint256[] stakedCollateralNFTId; //single nft id or multinft id
        uint256[] stakedNFTPrice; //single nft price or multi nft price //price fetch from the opensea or rarible or maunal input price
        uint256 loanAmountInBorrowed; //total Loan Amount in USD
        uint32 apyOffer; //borrower given apy percentage
        LoanTypeNFT loanType; //Single NFT and multiple staked NFT
        LoanStatus loanStatus; //current status of the loan
        uint56 termsLengthInDays; //user choose terms length in days
        bool isPrivate; //private loans will not appear on loan market
        bool isInsured; //Future use flag to insure funds as they go to protocol.
        address borrower; //borrower's address
        address borrowStableCoin; //borrower stable coin,
        TierType tierType;
    }

    struct LoanDetailsNetwork {
        uint256 loanAmountInBorrowed; //total Loan Amount in Borrowed stable coin
        uint256 termsLengthInDays; //user choose terms length in days
        uint32 apyOffer; //borrower given apy percentage
        bool isPrivate; //private loans will not appear on loan market
        bool isInsured; //Future use flag to insure funds as they go to protocol.
        uint256 collateralAmount; // collateral amount in native coin
        address borrowStableCoin; // address of the borrower requested stable coin
        LoanStatus loanStatus; //current status of the loan
        address payable borrower; //borrower's address
        uint256 paybackAmount; // paybacked amount of the indiviual loan
    }

    struct MarketStorage {
        mapping(uint256 => LoanDetailsToken) borrowerLoanToken; //saves the loan details for each loanId
        mapping(uint256 => LenderDetails) activatedLoanToken; //saves the information of the lender for each loanId of the token loan
        mapping(address => uint256[]) borrowerLoanIdsToken; //erc20 tokens loan offer mapping
        mapping(address => uint256[]) activatedLoanIdsToken; //mapping address of lender => loan Ids
        mapping(uint256 => LoanDetailsNFT) borrowerLoanNFT; //Single NFT or Multi NFT loan offers mapping
        mapping(uint256 => LenderDetailsNFT) activatedLoanNFT; //mapping saves the information of the lender across the active NFT Loan Ids
        mapping(address => uint256[]) borrowerLoanIdsNFT; //mapping of borrower address to the loan Ids of the NFT.
        mapping(address => uint256[]) activatedLoanIdsNFTs; //mapping address of the lender to the activated loan offers of NFT
        mapping(uint256 => LoanDetailsNetwork) borrowerLoanNetwork; //saves information in loanOffers when createLoan function is called
        mapping(uint256 => LenderDetails) activatedLoanNetwork; // mapping saves the information of the lender across the active loanId
        mapping(address => uint256[]) borrowerLoanIdsNetwork; // users loan offers Ids
        mapping(address => uint256[]) activatedLoanIdsNetwork; // mapping address of lender to the loan Ids
        mapping(address => uint256) stableCoinWithdrawable; // mapping for storing the plaform Fee and unearned APY Fee at the time of payback or liquidation     // [token or nft or network MarketFacet][stableCoinAddress] += platformFee OR Unearned APY Fee
        mapping(address => uint256) collateralsWithdrawableToken; // mapping to add the extra collateral token amount when autosell off,   [TokenMarket][collateralToken] += exceedaltcoins;  // liquidated collateral on autsell off
        mapping(address => uint256) collateralsWithdrawableNetwork; // mapping to add the exceeding collateral amount after transferring the lender amount,  when liquidation occurs on autosell off
        mapping(address => uint256) loanActivateLimit; // loan lend limit of each market for each wallet address
        uint256[] loanOfferIdsToken; //array of all loan offer ids of the ERC20 tokens Single or Multiple.
        uint256[] loanOfferIdsNFTs; //array of all loan offer ids of the NFT tokens Single or Multiple
        uint256[] loanOfferIdsNetwork; //array of all loan offer ids of the native coin
        uint256 loanIdToken;
        uint256 loanIdNft;
        uint256 loanIdNetwork;
        address aggregator1Inch;
        mapping(address => mapping(address => uint256)) liquidatedSUNTokenbalances; //mapping of wallet address to track the approved claim token balances when loan is liquidated // wallet address lender => sunTokenAddress => balanceofSUNToken
    }

    function marketStorage() internal pure returns (MarketStorage storage es) {
        bytes32 position = MARKET_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library LibMarketProvider {
    /// @dev function that will get AutoSell APY fee of the loan amount
    function getautosellAPYFee(
        uint256 loanAmount,
        uint256 autosellFee,
        uint256 loanterminDays
    ) internal pure returns (uint256) {
        return ((loanAmount * autosellFee) / 10000 / 365) * loanterminDays;
    }

    /// @dev function that will get APY fee of the loan amount in borrowed
    function getAPYFee(
        uint256 loanAmount,
        uint256 apyFee,
        uint256 loanterminDays
    ) internal pure returns (uint256) {
        return ((loanAmount * apyFee) / 10000 / 365) * loanterminDays;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./../../interfaces/IPriceConsumer.sol";
import "./../../interfaces/IUniswapV2Router02.sol";
import "./../../interfaces/IPriceConsumer.sol";
import "./../../interfaces/IClaimToken.sol";
import "./../../interfaces/IDexPair.sol";
import {IProtocolRegistry} from "./../../interfaces/IProtocolRegistry.sol";

library LibPriceConsumerStorage {
    bytes32 constant PRICECONSUMER_STORAGE_POSITION =
        keccak256("diamond.standard.PRICECONSUMER.storage");

    struct PairReservesDecimals {
        IDexPair pair;
        uint256 reserve0;
        uint256 reserve1;
        uint256 decimal0;
        uint256 decimal1;
    }

    struct ChainlinkDataFeed {
        AggregatorV3Interface usdPriceAggrigator;
        bool enabled;
        uint256 decimals;
    }

    struct PriceConsumerStorage {
        mapping(address => ChainlinkDataFeed) usdPriceAggrigators;
        address[] allFeedContractsChainlink; //chainlink feed contract addresses
        address[] allFeedTokenAddress; //chainlink feed ERC20 token contract addresses
        IUniswapV2Router02 swapRouterv2;
    }

    function priceConsumerStorage()
        internal
        pure
        returns (PriceConsumerStorage storage es)
    {
        bytes32 position = PRICECONSUMER_STORAGE_POSITION;
        assembly {
            es.slot := position
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./../facets/protocolRegistry/LibProtocolStorage.sol";

interface IProtocolRegistry {
    /// @dev check function if Token Contract address is already added
    /// @param _tokenAddress token address
    /// @return bool returns the true or false value
    function isTokenApproved(address _tokenAddress)
        external
        view
        returns (bool);

    /// @dev check fundtion token enable for staking as collateral
    /// @param _tokenAddress address of the collateral token address
    /// @return bool returns true or false value

    function isTokenEnabledForCreateLoan(address _tokenAddress)
        external
        view
        returns (bool);

    function getGovPlatformFee() external view returns (uint256);

    function getThresholdPercentage() external view returns (uint256);

    function getAutosellPercentage() external view returns (uint256);

    function getSingleApproveToken(address _tokenAddress)
        external
        view
        returns (LibProtocolStorage.Market memory);

    function getSingleApproveTokenData(address _tokenAddress)
        external
        view
        returns (
            address,
            bool,
            uint256
        );

    function isSyntheticMintOn(address _token) external view returns (bool);

    function getTokenMarket() external view returns (address[] memory);

    function getSingleTokenSps(address _tokenAddress)
        external
        view
        returns (address[] memory);

    function isAddedSPWallet(address _tokenAddress, address _walletAddress)
        external
        view
        returns (bool);

    function isStableApproved(address _stable) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IDexPair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library LibClaimTokenStorage {
    bytes32 constant CLAIMTOKEN_STORAGE_POSITION =
        keccak256("diamond.standard.CLAIMTOKEN.storage");

    struct ClaimTokenData {
        uint256 tokenType; // token type is used for token type sun or peg token
        address[] pegTokens; // addresses of the peg and sun tokens
        uint256[] pegTokensPricePercentage; // peg or sun token price percentages
        address dexRouter; //this address will get the price from the AMM DEX (uniswap, sushiswap etc...)
    }

    struct ClaimStorage {
        mapping(address => bool) approvedClaimTokens; // dev mapping for enable or disbale the claimToken
        mapping(address => ClaimTokenData) claimTokens;
        mapping(address => address) claimTokenofSUN; //sun token mapping to the claimToken
        address[] sunTokens;
    }

    function claimTokenStorage()
        internal
        pure
        returns (ClaimStorage storage es)
    {
        bytes32 position = CLAIMTOKEN_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library LibProtocolStorage {
    bytes32 constant PROTOCOLREGISTRY_STORAGE_POSITION =
        keccak256("diamond.standard.PROTOCOLREGISTRY.storage");

    enum TokenType {
        ISDEX,
        ISELITE,
        ISVIP
    }

    // Token Market Data
    struct Market {
        address dexRouter;
        address gToken;
        bool isMint;
        TokenType tokenType;
        bool isTokenEnabledAsCollateral;
    }

    struct ProtocolStorage {
        uint256 govPlatformFee;
        uint256 govAutosellFee;
        uint256 govThresholdFee;
        mapping(address => address[]) approvedSps; // tokenAddress => spWalletAddress
        mapping(address => Market) approvedTokens; // tokenContractAddress => Market struct
        mapping(address => bool) approveStable; // stable coin address enable or disable in protocol registry
        address[] allApprovedSps; // array of all approved SP Wallet Addresses
        address[] allapprovedTokenContracts; // array of all Approved ERC20 Token Contracts
    }

    function protocolRegistryStorage()
        internal
        pure
        returns (ProtocolStorage storage es)
    {
        bytes32 position = PROTOCOLREGISTRY_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library LibGovTierStorage {
    bytes32 constant GOVTIER_STORAGE_POSITION =
        keccak256("diamond.standard.GOVTIER.storage");

    struct TierData {
        uint256 govHoldings; // Gov  Holdings to check if it lies in that tier
        uint8 loantoValue; // LTV percentage of the Gov Holdings
        bool govIntel; //checks that if tier level have following access
        bool singleToken;
        bool multiToken;
        bool singleNFT;
        bool multiNFT;
        bool reverseLoan;
    }

    struct GovTierStorage {
        mapping(bytes32 => TierData) tierLevels; //data of the each tier level
        mapping(address => bytes32) tierLevelbyAddress;
        bytes32[] allTierLevelKeys; //list of all added tier levels. Stores the key for mapping => tierLevels
        address[] allTierLevelbyAddress;
        address addressProvider;
        bool isInitializedGovtier;
    }

    function govTierStorage()
        internal
        pure
        returns (GovTierStorage storage es)
    {
        bytes32 position = GOVTIER_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library LibAdminStorage {
    bytes32 constant ADMINREGISTRY_STORAGE_POSITION =
        keccak256("diamond.standard.ADMINREGISTRY.storage");

    struct AdminAccess {
        //access-modifier variables to add projects to gov-intel
        bool addGovIntel;
        bool editGovIntel;
        //access-modifier variables to add tokens to gov-world protocol
        bool addToken;
        bool editToken;
        //access-modifier variables to add strategic partners to gov-world protocol
        bool addSp;
        bool editSp;
        //access-modifier variables to add gov-world admins to gov-world protocol
        bool addGovAdmin;
        bool editGovAdmin;
        //access-modifier variables to add bridges to gov-world protocol
        bool addBridge;
        bool editBridge;
        //access-modifier variables to add pools to gov-world protocol
        bool addPool;
        bool editPool;
        //superAdmin role assigned only by the super admin
        bool superAdmin;
    }

    struct AdminStorage {
        mapping(address => AdminAccess) approvedAdminRoles; // approve admin roles for each address
        mapping(uint8 => mapping(address => AdminAccess)) pendingAdminRoles; // mapping of admin role keys to admin addresses to admin access roles
        mapping(uint8 => mapping(address => address[])) areByAdmins; // list of admins approved by other admins, for the specific key
        //admin role keys
        uint8 PENDING_ADD_ADMIN_KEY;
        uint8 PENDING_EDIT_ADMIN_KEY;
        uint8 PENDING_REMOVE_ADMIN_KEY;
        uint8[] PENDING_KEYS; // ADD: 0, EDIT: 1, REMOVE: 2
        address[] allApprovedAdmins; //list of all approved admin addresses
        address[][] pendingAdminKeys; //list of pending addresses for each key
        address superAdmin;
    }

    function adminRegistryStorage()
        internal
        pure
        returns (AdminStorage storage es)
    {
        bytes32 position = ADMINREGISTRY_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {LibMeta} from "./../../shared/libraries/LibMeta.sol";

/**
 * @dev Library version of the OpenZeppelin Pausable contract with Diamond storage.
 * See: https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable
 * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol
 */
library LibPausable {
    struct Storage {
        bool paused;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("diamond.standard.Pausable.storage");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Reverts when paused.
     */
    function enforceNotPaused() internal view {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Reverts when not paused.
     */
    function enforcePaused() internal view {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() internal view returns (bool) {
        return _storage().paused;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal {
        _storage().paused = true;
        emit Paused(LibMeta.msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal {
        _storage().paused = false;
        emit Unpaused(LibMeta.msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IGToken {
    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapSwapInterface {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
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