// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../admin/tierLevel/interfaces/IUserTier.sol";
import "../base/NetworkLoanBase.sol";
import "../library/NetworkLoanData.sol";
import "../../oracle/IPriceConsumer.sol";
import "../../interfaces/IUniswapSwapInterface.sol";
import "../../market/pausable/PausableImplementation.sol";
import "../../admin/SuperAdminControl.sol";
import "../../addressprovider/IAddressProvider.sol";
import "../../market/interfaces/ITokenMarketRegistry.sol";

interface ILiquidator {
    function isLiquidateAccess(address liquidator) external view returns (bool);
}

interface IProtocolRegistry {
    function getThresholdPercentage() external view returns (uint256);

    function getAutosellPercentage() external view returns (uint256);

    function getGovPlatformFee() external view returns (uint256);

    function isStableApproved(address _stable) external view returns (bool);
}

contract NetworkLoan is
    NetworkLoanBase,
    PausableImplementation,
    SuperAdminControl
{
    //Load library structs into contract
    using NetworkLoanData for *;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    ILiquidator public Liquidator;
    IProtocolRegistry public ProtocolRegistry;
    IUserTier public TierLevel;
    IPriceConsumer public PriceConsumer;
    address public AdminRegistry;
    address public addressProvider;
    address public aggregator1Inch;
    address public marketRegistry;


    /// @dev variable which represents the loan Id
    uint256 public loanId;

    uint256 public loanActivateLimit;
    mapping(address => bool) public whitelistAddress;
    mapping(address => uint256) public loanLendLimit;

    uint256 public ltvPercentage;

    function initialize() external initializer {
        __Ownable_init();
        ltvPercentage = 125;
    }

    receive() external payable {}

    /// @dev function to set the loan Activate limit
    function setloanActivateLimit(uint256 _loansLimit)
        public
        onlySuperAdmin(AdminRegistry, msg.sender)
    {
        require(_loansLimit > 0, "GTM: loanlimit error");
        loanActivateLimit = _loansLimit;
        emit LoanActivateLimitUpdated(_loansLimit);
    }

    function setLTVPercentage(uint256 _ltvPercentage)
        public
        onlySuperAdmin(AdminRegistry, msg.sender)
    {
        require(_ltvPercentage > 0, "GTM: ltv percentage error");
        ltvPercentage = _ltvPercentage;
        emit LTVPercentageUpdated(_ltvPercentage);
    }

    function updateAddresses() external onlyOwner {
        Liquidator = ILiquidator(
            IAddressProvider(addressProvider).getLiquidator()
        );
        ProtocolRegistry = IProtocolRegistry(
            IAddressProvider(addressProvider).getProtocolRegistry()
        );
        TierLevel = IUserTier(IAddressProvider(addressProvider).getUserTier());
        PriceConsumer = IPriceConsumer(
            IAddressProvider(addressProvider).getPriceConsumer()
        );
        AdminRegistry = IAddressProvider(addressProvider).getAdminRegistry();
        marketRegistry = IAddressProvider(addressProvider).getTokenMarketRegistry();

    }

    /// @dev set address of 1inch aggregator v4
    function set1InchAggregator(address _1inchAggregatorV4)
        external
        onlySuperAdmin(AdminRegistry, msg.sender)
    {
        require(_1inchAggregatorV4 != address(0), "aggregator address zero");
        aggregator1Inch = _1inchAggregatorV4;
    }

    /// @dev set address of lender for the unlimited loan activation
    function setWhilelistAddress(address _lender)
        public
        onlySuperAdmin(AdminRegistry, msg.sender)
    {
        require(_lender != address(0x0), "GTM: null address error");
        whitelistAddress[_lender] = true;
    }

    /// @dev set the address provider address
    function setAddressProvider(address _addressProvider) external onlyOwner {
        require(_addressProvider != address(0), "zero address");
        addressProvider = _addressProvider;
    }

    //modifier: only liquidators can liqudate pending liquidation calls.
    modifier onlyLiquidatorRole(address liquidator) {
        require(
            Liquidator.isLiquidateAccess(liquidator),
            "GNM: Not a  Liquidator."
        );
        _;
    }

    /**
    /// @dev function to create Single || Multi (ERC20) Loan Offer by the BORROWER
    /// @param loanDetails {see: NetworkLoanData}

    */
    function createLoan(NetworkLoanData.LoanDetails memory loanDetails)
        public
        payable
        whenNotPaused
    {
        uint256 newLoanId = _getNextLoanId();

         uint256 stableCoinDecimals = IERC20Metadata(loanDetails.borrowStableCoin).decimals();
        require(loanDetails.loanAmountInBorrowed >= (ITokenMarketRegistry(marketRegistry).getMinLoanAmountAllowed() * (10 ** stableCoinDecimals)), "GLM: min loan amount invalid");

        require(
            loanDetails.paybackAmount == 0,
            "GNM: payback amount should be zero"
        );
        require(
            msg.value >= loanDetails.collateralAmount,
            "GNM: Loan Amount Invalid"
        );
        require(
            ProtocolRegistry.isStableApproved(loanDetails.borrowStableCoin),
            "GTM: not approved stable coin"
        );

        uint256 ltv = this.calculateLTV(
            loanDetails.collateralAmount,
            loanDetails.borrowStableCoin,
            loanDetails.loanAmountInBorrowed
        );
        uint256 maxLtv = this.getMaxLoanAmount(
            this.getAltCoinPriceinStable(
                loanDetails.borrowStableCoin,
                loanDetails.collateralAmount
            ),
            msg.sender
        );

        require(
            loanDetails.loanAmountInBorrowed <= maxLtv,
            "GNM: LTV not allowed."
        );
        require(
            ltv > ltvPercentage,
            "GNM: Can not create loan at liquidation level."
        );

        borrowerloanOfferIds[msg.sender].push(newLoanId);
        loanOfferIds.push(newLoanId);

        borrowerOffers[newLoanId] = NetworkLoanData.LoanDetails(
            loanDetails.loanAmountInBorrowed,
            loanDetails.termsLengthInDays,
            loanDetails.apyOffer,
            loanDetails.isPrivate,
            loanDetails.isInsured,
            loanDetails.collateralAmount,
            loanDetails.borrowStableCoin,
            NetworkLoanData.LoanStatus.INACTIVE,
            payable(msg.sender),
            loanDetails.paybackAmount
        );

        emit LoanOfferCreated(newLoanId, borrowerOffers[newLoanId]);
        loanId++;
    }

    /**
    @dev function to adjust already created loan offer, while in inactive state
    @param  _loanIdAdjusted, the existing loan id which is being adjusted while in inactive state
    @param _newLoanAmountBorrowed, the new loan amount borrower is requesting
    @param _newTermsLengthInDays, borrower changing the loan term in days
    @param _newAPYOffer, percentage of the APY offer borrower is adjusting for the lender
    @param _isPrivate, boolena value of true if private otherwise false
    @param _isInsured, isinsured true or false
     */
    function loanAdjusted(
        uint256 _loanIdAdjusted,
        uint256 _newLoanAmountBorrowed,
        uint56 _newTermsLengthInDays,
        uint32 _newAPYOffer,
        bool _isPrivate,
        bool _isInsured
    ) public whenNotPaused {
        require(
            borrowerOffers[_loanIdAdjusted].loanStatus ==
                NetworkLoanData.LoanStatus.INACTIVE,
            "GNM, Loan cannot adjusted"
        );
        require(
            borrowerOffers[_loanIdAdjusted].borrower == msg.sender,
            "GNM, Only Borrow Adjust Loan"
        );

        uint256 ltv = this.calculateLTV(
            borrowerOffers[_loanIdAdjusted].collateralAmount,
            borrowerOffers[_loanIdAdjusted].borrowStableCoin,
            _newLoanAmountBorrowed
        );
        uint256 maxLtv = this.getMaxLoanAmount(
            this.getAltCoinPriceinStable(
                borrowerOffers[_loanIdAdjusted].borrowStableCoin,
                _newLoanAmountBorrowed
            ),
            msg.sender
        );

        require(_newLoanAmountBorrowed <= maxLtv, "GNM: LTV not allowed.");
        require(
            ltv > ltvPercentage,
            "GNM: can not adjust loan to liquidation level."
        );

        borrowerOffers[_loanIdAdjusted] = NetworkLoanData.LoanDetails(
            _newLoanAmountBorrowed,
            _newTermsLengthInDays,
            _newAPYOffer,
            _isPrivate,
            _isInsured,
            borrowerOffers[_loanIdAdjusted].collateralAmount,
            borrowerOffers[_loanIdAdjusted].borrowStableCoin,
            NetworkLoanData.LoanStatus.INACTIVE,
            payable(msg.sender),
            borrowerOffers[_loanIdAdjusted].paybackAmount
        );

        emit LoanOfferAdjusted(
            _loanIdAdjusted,
            borrowerOffers[_loanIdAdjusted]
        );
    }

    /**
    @dev function to cancel the created laon offer for  type Single || Multi  Colletrals
    @param _loanId loan Id which is being cancelled/removed, will delete all the loan details from the mapping
     */
    function loanOfferCancel(uint256 _loanId) public whenNotPaused {
        require(
            borrowerOffers[_loanId].loanStatus ==
                NetworkLoanData.LoanStatus.INACTIVE,
            "GNM, Loan cannot be cancel"
        );
        require(
            borrowerOffers[_loanId].borrower == msg.sender,
            "GNM, Only Borrow can cancel"
        );

        (bool success, ) = payable(msg.sender).call{
            value: borrowerOffers[_loanId].collateralAmount
        }("");
        require(success, "GLC: ETH transfer failed");

        borrowerOffers[_loanId].loanStatus = NetworkLoanData
            .LoanStatus
            .CANCELLED;
        emit LoanOfferCancel(
            _loanId,
            msg.sender,
            borrowerOffers[_loanId].loanStatus
        );
    }

    /**
    @dev function for lender to activate loan offer by the borrower
    @param _loanId loan id which is going to be activated
    @param _stableCoinAmount amount of stable coin requested by the borrower
     */
    function activateLoan(
        uint256 _loanId,
        uint256 _stableCoinAmount,
        bool _autoSell
    ) public whenNotPaused {
        require(
            borrowerOffers[_loanId].loanStatus ==
                NetworkLoanData.LoanStatus.INACTIVE,
            "GNM, not inactive"
        );
        require(
            borrowerOffers[_loanId].borrower != msg.sender,
            "GNM, self activation not allowed"
        );

        if (!whitelistAddress[msg.sender]) {
            require(
                loanLendLimit[msg.sender] + 1 <= loanActivateLimit,
                "GTM: you cannot lend more loans"
            );
            loanLendLimit[msg.sender]++;
        }

        uint256 calulatedLTV = this.getLtv(_loanId);

        require(
            calulatedLTV > ltvPercentage,
            "Can not activate loan at liquidation level"
        );

        uint256 maxLoanAmount = this.getMaxLoanAmount(
            this.getAltCoinPriceinStable(
                borrowerOffers[_loanId].borrowStableCoin,
                borrowerOffers[_loanId].collateralAmount
            ),
            borrowerOffers[_loanId].borrower
        );

        require(maxLoanAmount != 0, "GNM: borrower not eligible, no tierLevel");

        if (maxLoanAmount >= borrowerOffers[_loanId].loanAmountInBorrowed) {
            require(
                borrowerOffers[_loanId].loanAmountInBorrowed ==
                    _stableCoinAmount,
                "GNM, not borrower requrested loan amount"
            );
            borrowerOffers[_loanId].loanAmountInBorrowed = _stableCoinAmount;
        } else if (
            maxLoanAmount < borrowerOffers[_loanId].loanAmountInBorrowed
        ) {
            // maxLoanAmount is now assigning in the loan Details struct
            require(
                _stableCoinAmount == maxLoanAmount,
                "GNM: loan amount not equal maxLoanAmount"
            );
            borrowerOffers[_loanId].loanAmountInBorrowed == maxLoanAmount;
        }

        uint256 apyFee = this.getAPYFee(borrowerOffers[_loanId]);
        uint256 platformFee = (borrowerOffers[loanId].loanAmountInBorrowed *
            (ProtocolRegistry.getGovPlatformFee())) / (10000);
        uint256 loanAmountAfterCut = borrowerOffers[loanId]
            .loanAmountInBorrowed - (apyFee + platformFee);

        /// @dev adding platform fee for the  Network Loan Contract in stableCoinWithdrawable,
        /// which can be withdrawable by the superadmin from the Network Loan Contract
        stableCoinWithdrawable[address(this)][
            borrowerOffers[loanId].borrowStableCoin
        ] += platformFee;

        require(
            (apyFee + loanAmountAfterCut + platformFee) ==
                borrowerOffers[loanId].loanAmountInBorrowed,
            "GNM, invalid amount"
        );

        /// @dev approving the loan amount from the front end
        /// @dev keep the APYFEE  in the contract  before  transfering the stable coins to borrower.
        IERC20Upgradeable(borrowerOffers[_loanId].borrowStableCoin)
            .safeTransferFrom(
                msg.sender,
                address(this),
                borrowerOffers[_loanId].loanAmountInBorrowed
            );
        /// @dev loan amount sending to borrower
        IERC20Upgradeable(borrowerOffers[_loanId].borrowStableCoin)
            .safeTransfer(borrowerOffers[_loanId].borrower, loanAmountAfterCut);
        borrowerOffers[_loanId].loanStatus = NetworkLoanData.LoanStatus.ACTIVE;

        //push active loan ids to the lendersactivatedloanIds mapping
        lenderActivatedLoanIds[msg.sender].push(_loanId);

        /// @dev save the activated loan id to the lender details mapping
        activatedLoanByLenders[_loanId] = NetworkLoanData.LenderDetails({
            lender: payable(msg.sender),
            activationLoanTimeStamp: block.timestamp,
            autoSell: _autoSell
        });

        emit LoanOfferActivated(
            _loanId,
            msg.sender,
            _stableCoinAmount,
            _autoSell
        );
    }

    /// @dev function getting the total payback amount and earned apy amount to the lender
    /// @param _loanId loanId of the activated loans
    function getTotalPaybackAmount(uint256 _loanId)
        external
        view
        returns (uint256, uint256)
    {
        NetworkLoanData.LoanDetails memory loanDetails = borrowerOffers[
            _loanId
        ];

        uint256 loanTermLengthPassed = block.timestamp -
            (activatedLoanByLenders[_loanId].activationLoanTimeStamp);
        uint256 loanTermLengthPassedInDays = loanTermLengthPassed / 86400;

        uint256 earnedAPYFee = ((loanDetails.loanAmountInBorrowed *
            loanDetails.apyOffer) /
            10000 /
            365) * loanTermLengthPassedInDays;

        return (loanDetails.loanAmountInBorrowed + earnedAPYFee, earnedAPYFee);
    }

    /**
    @dev payback loan full by the borrower to the lender

     */
    function fullLoanPaybackEarly(uint256 _loanId) internal {
        NetworkLoanData.LenderDetails
            memory lenderDetails = activatedLoanByLenders[_loanId];

        (uint256 finalPaybackAmounttoLender, uint256 earnedAPYFee) = this
            .getTotalPaybackAmount(_loanId);

        uint256 apyFeeOriginal = this.getAPYFee(borrowerOffers[_loanId]);

        if (earnedAPYFee > apyFeeOriginal) {
            earnedAPYFee = apyFeeOriginal;
        }

        uint256 unEarnedAPYFee = apyFeeOriginal - earnedAPYFee;
        // adding the unearned APY in the contract stableCoinWithdrawable mapping
        // only superAdmin can withdraw this much amount
        stableCoinWithdrawable[address(this)][
            borrowerOffers[_loanId].borrowStableCoin
        ] += unEarnedAPYFee;

        //we will first transfer the loan payback amount from borrower to the contract address.
        IERC20Upgradeable(borrowerOffers[_loanId].borrowStableCoin)
            .safeTransferFrom(
                borrowerOffers[_loanId].borrower,
                address(this),
                borrowerOffers[_loanId].loanAmountInBorrowed -
                    borrowerOffers[_loanId].paybackAmount
            );
        IERC20Upgradeable(borrowerOffers[_loanId].borrowStableCoin)
            .safeTransfer(lenderDetails.lender, finalPaybackAmounttoLender);

        //contract will the repay staked collateral  to the borrower after receiving the loan payback amount
        (bool success, ) = payable(msg.sender).call{
            value: borrowerOffers[_loanId].collateralAmount
        }("");
        require(success, "GNM: ETH transfer failed");

        borrowerOffers[_loanId].paybackAmount = finalPaybackAmounttoLender;
        borrowerOffers[_loanId].loanStatus = NetworkLoanData.LoanStatus.CLOSED;
        emit FullLoanPaybacked(
            _loanId,
            msg.sender,
            NetworkLoanData.LoanStatus.CLOSED
        );
    }

    /**
    @dev  loan payback partial
    if _paybackAmount is equal to the total loan amount in stable coins the loan concludes as full payback
     */
    function payback(uint256 _loanId, uint256 _paybackAmount)
        public
        whenNotPaused
    {
        NetworkLoanData.LoanDetails memory loanDetails = borrowerOffers[
            _loanId
        ];

        require(
            borrowerOffers[_loanId].borrower == payable(msg.sender),
            "GNM, not borrower"
        );
        require(
            borrowerOffers[_loanId].loanStatus ==
                NetworkLoanData.LoanStatus.ACTIVE,
            "GNM, not active"
        );
        require(
            _paybackAmount > 0 &&
                _paybackAmount <= borrowerOffers[_loanId].loanAmountInBorrowed,
            "GNM: Invalid Loan Amount"
        );

        require(
            !this.isLiquidationPending(_loanId),
            "GNM: Loan Already Payback or Liquidated"
        );

        uint256 totalPayback = _paybackAmount + loanDetails.paybackAmount;
        if (totalPayback >= loanDetails.loanAmountInBorrowed) {
            fullLoanPaybackEarly(_loanId);
        } else {
            uint256 remainingLoanAmount = loanDetails.loanAmountInBorrowed -
                totalPayback;
            uint256 newLtv = this.calculateLTV(
                loanDetails.collateralAmount,
                loanDetails.borrowStableCoin,
                remainingLoanAmount
            );
            require(newLtv > ltvPercentage, "GNM: new LTV exceeds threshold.");
            IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransferFrom(
                payable(msg.sender),
                address(this),
                _paybackAmount
            );
            borrowerOffers[_loanId].paybackAmount =
                borrowerOffers[_loanId].paybackAmount +
                _paybackAmount;
            loanDetails.loanStatus = NetworkLoanData.LoanStatus.ACTIVE;
            emit PartialLoanPaybacked(
                loanId,
                _paybackAmount,
                payable(msg.sender)
            );
        }
    }

    /**
    @dev liquidate call from the  world liquidator
    @param _loanId loan id to check if its liqudation pending or loan term ended
     */
    // TODO: implement new logic for 1inch swap

    // function liquidateLoan(uint256 _loanId, uint256 _typeOfSwap, bytes memory _swapData)
    function liquidateLoan(uint256 _loanId)
        public
        payable
        onlyLiquidatorRole(msg.sender)
    {
        require(
            borrowerOffers[_loanId].loanStatus ==
                NetworkLoanData.LoanStatus.ACTIVE,
            "GNM, not active, not available loan id, payback or liquidated"
        );
        NetworkLoanData.LoanDetails memory loanDetails = borrowerOffers[
            _loanId
        ];
        NetworkLoanData.LenderDetails
            memory lenderDetails = activatedLoanByLenders[_loanId];

        (, uint256 earnedAPYFee) = this.getTotalPaybackAmount(_loanId);
        uint256 apyFeeOriginal = this.getAPYFee(borrowerOffers[_loanId]);
        /// @dev as we get the payback amount according to the days passed...
        // let say if (days passed earned APY) is greater than the original APY,
        // then we only sent the earned apy fee amount to the lender
        if (earnedAPYFee > apyFeeOriginal) {
            earnedAPYFee = apyFeeOriginal;
        }

        uint256 unEarnedAPYFee = apyFeeOriginal - earnedAPYFee;

        /// @dev adding the unearned APY in the contract stableCoinWithdrawable mapping
        // only superAdmin can withdraw this much amount
        stableCoinWithdrawable[address(this)][
            loanDetails.borrowStableCoin
        ] += unEarnedAPYFee;

        require(this.isLiquidationPending(_loanId), "GNM: Liquidation Error");

        if (lenderDetails.autoSell) {
            // if(_typeOfSwap == 0) {
            //     (bool success,) = address(aggregator1Inch).call(_swapData);
            //     require(success, "One 1Inch Swap Failed");
            // } else {
            address[] memory path = new address[](2);
            path[0] = PriceConsumer.WETHAddress();
            path[1] = loanDetails.borrowStableCoin;

            (uint256 amountIn, uint256 amountOut) = PriceConsumer
                .getNetworkCoinSwapData(
                    loanDetails.collateralAmount,
                    loanDetails.borrowStableCoin
                );

            IUniswapSwapInterface swapInterface = IUniswapSwapInterface(
                PriceConsumer.getSwapInterfaceForETH()
            );
            swapInterface.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: amountIn
            }(amountOut, path, address(this), block.timestamp + 5 minutes);
            // }

            uint256 autosellFeeinStable = this.getautosellAPYFee(
                loanDetails.loanAmountInBorrowed,
                ProtocolRegistry.getAutosellPercentage(),
                loanDetails.termsLengthInDays
            );
            uint256 finalAmountToLender = (loanDetails.loanAmountInBorrowed +
                earnedAPYFee) - (autosellFeeinStable);

            IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransfer(
                lenderDetails.lender,
                finalAmountToLender
            );

            borrowerOffers[_loanId].loanStatus = NetworkLoanData
                .LoanStatus
                .LIQUIDATED;
            emit AutoLiquidated(_loanId, NetworkLoanData.LoanStatus.LIQUIDATED);
        } else {
            //send collateral  to the lender

            uint256 thresholdFeeinStable = (loanDetails.loanAmountInBorrowed *
                ProtocolRegistry.getThresholdPercentage()) / 10000;
            uint256 lenderAmountinStable = earnedAPYFee + thresholdFeeinStable;
            stableCoinWithdrawable[address(this)][
                loanDetails.borrowStableCoin
            ] -= thresholdFeeinStable;

            //network loan market will the repay staked collateral  to the borrower
            uint256 collateralAmountinStable = this.getAltCoinPriceinStable(
                loanDetails.borrowStableCoin,
                loanDetails.collateralAmount
            );

            if (collateralAmountinStable <= loanDetails.loanAmountInBorrowed) {
                (bool success, ) = payable(msg.sender).call{
                    value: loanDetails.collateralAmount
                }("");
                require(success, "GLC: ETH transfer failed");
            } else if (
                collateralAmountinStable > loanDetails.loanAmountInBorrowed
            ) {
                uint256 exceedAltcoinValue = this.getStablePriceinAltcoin(
                    loanDetails.borrowStableCoin,
                    collateralAmountinStable - loanDetails.loanAmountInBorrowed
                );
                uint256 collateralToLender = loanDetails.collateralAmount -
                    exceedAltcoinValue;
                collateralsWithdrawable[address(this)] += exceedAltcoinValue;

                (bool success, ) = payable(msg.sender).call{
                    value: collateralToLender
                }("");
                require(success, "GLC: ETH transfer failed");
            }

            IERC20Upgradeable(loanDetails.borrowStableCoin).transfer(
                lenderDetails.lender,
                lenderAmountinStable
            );
            borrowerOffers[_loanId].loanStatus = NetworkLoanData
                .LoanStatus
                .LIQUIDATED;
            emit LiquidatedCollaterals(
                _loanId,
                NetworkLoanData.LoanStatus.LIQUIDATED
            );
        }
    }

    /// @dev function to get the max loan amount according to the borrower tier level
    /// @param collateralInBorrowed amount of collateral in stable coin DAI, USDT
    /// @param borrower address of the borrower who holds some tier level
    function getMaxLoanAmount(uint256 collateralInBorrowed, address borrower)
        external
        view
        returns (uint256)
    {
        TierData memory tierData = TierLevel.getTierDatabyGovBalance(borrower);
        return (collateralInBorrowed * tierData.loantoValue) / 100;
    }

    /**
    @dev function to get altcoin (native coin collateral)  amount in stable coin.
    @param _stableCoin of the altcoin
    @param _collateralAmount amount of altcoin
     */
    function getAltCoinPriceinStable(
        address _stableCoin,
        uint256 _collateralAmount
    ) external view override returns (uint256) {
        uint256 collateralAmountinStable;
        if (
            PriceConsumer.isChainlinFeedEnabled(PriceConsumer.WETHAddress()) &&
            PriceConsumer.isChainlinFeedEnabled(_stableCoin)
        ) {
            int256 collateralChainlinkUsd = PriceConsumer
                .getNetworkPriceFromChainlinkinUSD();
            uint256 collateralUsd = (uint256(collateralChainlinkUsd) *
                _collateralAmount) / 8;
            (
                int256 priceFromChainLinkinStable,
                uint8 stableDecimals
            ) = PriceConsumer.getLatestUsdPriceFromChainlink(_stableCoin);
            collateralAmountinStable =
                collateralAmountinStable +
                ((collateralUsd / (uint256(priceFromChainLinkinStable))) *
                    (stableDecimals));
            return collateralAmountinStable;
        } else {
            collateralAmountinStable =
                collateralAmountinStable +
                (
                    PriceConsumer.getETHPriceFromDex(
                        _stableCoin,
                        PriceConsumer.WETHAddress(),
                        _collateralAmount
                    )
                );
            return collateralAmountinStable;
        }
    }

    /// @dev function to get stablecoin price in altcoin
    /// using this function is the liqudation autosell off
    function getStablePriceinAltcoin(
        address _stableCoin,
        uint256 _collateralAmount
    ) external view returns (uint256) {
        return
            PriceConsumer.getETHPriceFromDex(
                PriceConsumer.WETHAddress(),
                _stableCoin,
                _collateralAmount
            );
    }

    /**
    @dev returns the LTV percentage of the loan amount in borrowed of the staked colletral 
    @param _loanId loan ID for which ltv we are getting
     */
    function getLtv(uint256 _loanId) external view override returns (uint256) {
        NetworkLoanData.LoanDetails memory loanDetails = borrowerOffers[
            _loanId
        ];
        return
            this.calculateLTV(
                loanDetails.collateralAmount,
                loanDetails.borrowStableCoin,
                loanDetails.loanAmountInBorrowed - (loanDetails.paybackAmount)
            );
    }

    /**
    @dev Calculates LTV based on DEX price
    @param _stakedCollateralAmount amount of staked collateral of Network Coin
    @param _loanAmount total borrower loan amount in borrowed .
     */
    function calculateLTV(
        uint256 _stakedCollateralAmount,
        address _borrowed,
        uint256 _loanAmount
    ) external view returns (uint256) {
        uint256 priceofCollateral = this.getAltCoinPriceinStable(
            _borrowed,
            _stakedCollateralAmount
        );

        return (priceofCollateral * 100) / _loanAmount;
    }

    /**
    @dev function to check the loan is pending for liqudation or not
    @param _loanId for which loan liquidation checking
     */
    function isLiquidationPending(uint256 _loanId)
        external
        view
        override
        returns (bool)
    {
        NetworkLoanData.LenderDetails
            memory lenderDetails = activatedLoanByLenders[_loanId];
        NetworkLoanData.LoanDetails memory loanDetails = borrowerOffers[
            _loanId
        ];

        uint256 loanTermLengthPassedInDays = (block.timestamp -
            lenderDetails.activationLoanTimeStamp) / 86400;

        // @dev get the LTV percentage
        uint256 calulatedLTV = this.getLtv(_loanId);
        /// @dev the collateral is less than liquidation threshold percentage/loan term length end ok for liquidation
        ///  @dev loanDetails.termsLengthInDays + 1 is which we are giving extra time to the borrower to payback the collateral
        if (
            calulatedLTV <= ltvPercentage ||
            (loanTermLengthPassedInDays >= loanDetails.termsLengthInDays + 1)
        ) return true;
        else return false;
    }

    /**
    @dev function to get the next loan id after creating the loan offer in  case
     */
    function _getNextLoanId() private view returns (uint256) {
        return loanId + 1;
    }

    /**
    @dev get loan details of the single or multi-
     */
    function getborrowerOffers(uint256 _loanId)
        public
        view
        returns (NetworkLoanData.LoanDetails memory)
    {
        return borrowerOffers[_loanId];
    }

    /**
    @dev get activated loan details of the lender, termslength and autosell boolean (true or false)
     */
    function getActivatedLoanDetails(uint256 _loanId)
        public
        view
        returns (NetworkLoanData.LenderDetails memory)
    {
        return activatedLoanByLenders[_loanId];
    }

    /// @dev only super admin can withdraw coins
    function withdrawCoin(
        uint256 _withdrawAmount,
        address payable _walletAddress
    ) public onlySuperAdmin(AdminRegistry, msg.sender) {
        uint256 availableAmount = collateralsWithdrawable[address(this)];
        require(availableAmount > 0, "GNM: collateral not available");
        require(_withdrawAmount <= availableAmount, "GNL: Amount Invalid");
        collateralsWithdrawable[address(this)] -= _withdrawAmount;
        (bool success, ) = payable(_walletAddress).call{value: _withdrawAmount}(
            ""
        );
        require(success, "GLC: ETH transfer failed");
        emit WithdrawNetworkCoin(_walletAddress, _withdrawAmount);
    }

    /// @dev only super admin can withdraw tokens
    function withdrawToken(
        address _tokenAddress,
        uint256 _amount,
        address payable _walletAddress
    ) public onlySuperAdmin(AdminRegistry, msg.sender) {
        uint256 availableAmount = stableCoinWithdrawable[address(this)][
            _tokenAddress
        ];
        require(availableAmount > 0, "GNM: stable not available");
        require(_amount <= availableAmount, "GNL: Amount Invalid");
        stableCoinWithdrawable[address(this)][_tokenAddress] -= _amount;
        IERC20Upgradeable(_tokenAddress).safeTransfer(_walletAddress, _amount);
        emit WithdrawToken(_tokenAddress, _walletAddress, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
pragma solidity ^0.8.3;

import "../../tierLevel/interfaces/IGovTier.sol";

interface IUserTier {
    function getTierDatabyGovBalance(address userWalletAddress)
        external
        view
        returns (TierData memory _tierData);

    function getMaxLoanAmount(
        uint256 _collateralTokeninStable,
        uint256 _tierLevelLTVPercentage
    ) external pure returns (uint256);

    function getMaxLoanAmountToValue(
        uint256 _collateralTokeninStable,
        address _borrower
    ) external view returns (uint256);

    function isCreateLoanTokenUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 collateralInBorrowed,
        address[] memory stakedCollateralTokens
    ) external view returns (uint256);

    function isCreateLoanNftUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 collateralInBorrowed,
        address[] memory stakedCollateralTokens
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma abicoder v2;

import "../library/NetworkLoanData.sol";
import "../interfaces/INetworkLoan.sol";

abstract contract NetworkLoanBase is INetworkLoan {
    ///@dev Load library structs into contract
    using NetworkLoanData for *;

    ///@dev saves information in loanOffers when createLoan function is called
    mapping(uint256 => NetworkLoanData.LoanDetails) public borrowerOffers;

    ///@dev mapping saves the information of the lender across the active loanId
    mapping(uint256 => NetworkLoanData.LenderDetails)
        public activatedLoanByLenders;

    //array of all loan offer ids of the ERC20 tokens.
    uint256[] public loanOfferIds;

    ///@dev users loan offers Ids
    mapping(address => uint256[]) public borrowerloanOfferIds;

    ///@dev mapping address of lender to the loan Ids
    mapping(address => uint256[]) public lenderActivatedLoanIds;

    /// @dev mapping for storing the plaform Fee and unearned APY Fee at the time of payback or liquidation
    /// @dev add the value in the mapping like that:
    // [networkMarket][stableCoinAddress] += platformFee OR Unearned APY Fee
    mapping(address => mapping(address => uint256))
        public stableCoinWithdrawable;

    /// @dev mapping to add the collateral token amount when autosell off
    /// @dev remaining tokens will be added to the collateralsWithdrawable mapping, while liquidation
    mapping(address => uint256) public collateralsWithdrawable;

    /**
    @dev function that will get APY fee of the loan amount in borrowed
     */
    function getAPYFee(NetworkLoanData.LoanDetails memory _loanDetails)
        external
        pure
        override
        returns (uint256)
    {
        /// @dev APY Fee Formula for the autoSell Fee
        return
            ((_loanDetails.loanAmountInBorrowed * _loanDetails.apyOffer) /
                10000 /
                365) * _loanDetails.termsLengthInDays;
    }

    /**
    @dev function that will get AutoSell APY fee of the loan amount
     */
    function getautosellAPYFee(
        uint256 loanAmount,
        uint256 autosellAPY,
        uint256 loanterminDays
    ) external pure override returns (uint256) {
        /// @dev APY Fee Formula for the autoSell fee
        return ((loanAmount * autosellAPY) / 10000 / 365) * loanterminDays;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

library NetworkLoanData {
    enum LoanStatus {
        ACTIVE,
        INACTIVE,
        CLOSED,
        CANCELLED,
        LIQUIDATED
    }

    struct LenderDetails {
        address payable lender;
        uint256 activationLoanTimeStamp;
        bool autoSell;
    }

    struct LoanDetails {
        //total Loan Amount in Borrowed stable coin
        uint256 loanAmountInBorrowed;
        //user choose terms length in days
        uint256 termsLengthInDays;
        //borrower given apy percentage
        uint32 apyOffer;
        //private loans will not appear on loan market
        bool isPrivate;
        //Future use flag to insure funds as they go to protocol.
        bool isInsured;
        uint256 collateralAmount;
        address borrowStableCoin;
        //current status of the loan
        LoanStatus loanStatus;
        //borrower's address
        address payable borrower;
        uint256 paybackAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

struct ChainlinkDataFeed {
    AggregatorV3Interface usdPriceAggrigator;
    bool enabled;
    uint256 decimals;
}

interface IPriceConsumer {
    event PriceFeedAdded(
        address indexed token,
        address indexed usdPriceAggrigator,
        bool enabled,
        uint256 decimals
    );
    event PriceFeedAddedBulk(
        address[] indexed tokens,
        address[] indexed chainlinkFeedAddress,
        bool[] enabled,
        uint256[] decimals
    );
    event PriceFeedStatusUpdated(address indexed token, bool indexed status);

    event PathAdded(address _tokenAddress, address[] indexed _pathRoute);

    /// @dev Use chainlink PriceAggrigator to fetch prices of the already added feeds.
    /// @param priceFeedToken price fee token address for getting the price
    /// @return int256 returns the price value  from the chainlink
    /// @return uint8 returns the decimal of the price feed toekn
    function getLatestUsdPriceFromChainlink(address priceFeedToken)
        external
        view
        returns (int256, uint8);

    /// @dev multiple token prices fetch
    /// @param priceFeedToken multi token price fetch
    /// @return tokens returns the token address of the pricefeed token addresses
    /// @return prices returns the prices of each token in array
    /// @return decimals returns the token decimals in array
    function getLatestUsdPricesFromChainlink(address[] memory priceFeedToken)
        external
        view
        returns (
            address[] memory tokens,
            int256[] memory prices,
            uint8[] memory decimals
        );

    /// @dev get the network coin price from the chainlink
    function getNetworkPriceFromChainlinkinUSD() external view returns (int256);

    /// @dev get the dex router swap data
    /// @param _collateralToken  collateral token address
    /// @param _collateralAmount collatera token amount in decimals
    /// @param _borrowStableCoin stable coin token address
    function getSwapData(
        address _collateralToken,
        uint256 _collateralAmount,
        address _borrowStableCoin
    ) external view returns (uint256, uint256);

    /// @dev get the network coin swap data from the dex router
    /// @param _collateralAmount collater token amount
    /// @param _borrowStableCoin stable coin token address
    /// @return uint256 returns the amounts In from dex router
    /// @return uint256 returns the amounts Out from dex router
    function getNetworkCoinSwapData(
        uint256 _collateralAmount,
        address _borrowStableCoin
    ) external view returns (uint256, uint256);

    /// @dev get the swap interface contract address of the collateral token
    /// @return address returns the swap router contract
    function getSwapInterface(address _collateralTokenAddress)
        external
        view
        returns (address);

    function getSwapInterfaceForETH() external view returns (address);

    /// @dev How much worth alt is in terms of stable coin passed (e.g. X ALT =  ? STABLE COIN)
    /// @param _stable address of stable coin
    /// @param _alt address of alt coin
    /// @param _amount address of alt
    /// @return uint256 returns the price of alt coin in stable in stable coin decimals
    function getDexTokenPrice(
        address _stable,
        address _alt,
        uint256 _amount
    ) external view returns (uint256);

    function getETHPriceFromDex(
        address _stable,
        address _alt,
        uint256 _amount
    ) external view returns (uint256);

    /// @dev check wether token feed for this token is enabled or not
    function isChainlinFeedEnabled(address _tokenAddress)
        external
        view
        returns (bool);

    /// @dev get the chainlink Data feed of the token address
    /// @param _tokenAddress token address
    /// @return ChainlinkDataFeed returns the details chainlink data feed
    function getusdPriceAggrigators(address _tokenAddress)
        external
        view
        returns (ChainlinkDataFeed memory);

    /// @dev get all the chainlink aggregators contract address
    /// @return address[] returns the array of the contract address
    function getAllChainlinkAggiratorsContract()
        external
        view
        returns (address[] memory);

    /// @dev get all the gov aggregator tokens approved
    /// @return address[] returns the array of the gov aggregators contracts
    function getAllGovAggiratorsTokens()
        external
        view
        returns (address[] memory);

    /// @dev returns the weth contract address
    function WETHAddress() external view returns (address);

    /// @dev get the altcoin price in stable address
    /// @param _stableCoin address of the stable token address
    /// @param _altCoin address of the altcoin token address
    /// @param _collateralAmount collateral token amount in decimals
    /// @return uint256 returns the price of collateral in stable
    function getAltCoinPriceinStable(
        address _stableCoin,
        address _altCoin,
        uint256 _collateralAmount
    ) external view returns (uint256);

    /// @dev get the claim token price
    /// @param _stable address of the stable coin address
    /// @param _alt address of the collateral sun token address
    /// @param _amount amount of _alt in decimals
    /// @return uint256 the claim token price
    function getClaimTokenPrice(
        address _stable,
        address _alt,
        uint256 _amount
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
    function getSUNTokenPrice(
        address _claimToken,
        address _stable,
        address _sunToken,
        uint256 _amount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

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
pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @dev contract used in the token market, NFT market, and network loan market
abstract contract PausableImplementation is
    PausableUpgradeable,
    OwnableUpgradeable
{
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../admin/interfaces/IAdminRegistry.sol";

abstract contract SuperAdminControl {
    /// @dev modifier: onlySuper admin is allowed
    modifier onlySuperAdmin(address govAdminRegistry, address admin) {
        require(
            IAdminRegistry(govAdminRegistry).isSuperAdminAccess(admin),
            ": not super admin"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

/// @dev interface use in all the gov platform contracts
interface IAddressProvider {
    function getAdminRegistry() external view returns (address);

    function getProtocolRegistry() external view returns (address);

    function getPriceConsumer() external view returns (address);

    function getClaimTokenContract() external view returns (address);

    function getGTokenFactory() external view returns (address);

    function getLiquidator() external view returns (address);

    function getTokenMarketRegistry() external view returns (address);

    function getTokenMarket() external view returns (address);

    function getNftMarket() external view returns (address);

    function getNetworkMarket() external view returns (address);

    function govTokenAddress() external view returns (address);

    function getGovTier() external view returns (address);

    function getgovGovToken() external view returns (address);

    function getGovNFTTier() external view returns (address);

    function getVCTier() external view returns (address);

    function getUserTier() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface ITokenMarketRegistry {
    /**
    @dev function that will get Total Earned APY fee of the loan amount in borrower
     */
    function getAPYFee(
        uint256 _loanAmountInBorrowed,
        uint256 _apyOffer,
        uint256 _termsLengthInDays
    ) external returns (uint256);

    /**
    @dev function that will get AutoSell APY fee of the loan amount
     */
    function getautosellAPYFee(
        uint256 loanAmount,
        uint256 autosellAPY,
        uint256 loanterminDays
    ) external returns (uint256);

    function getLoanActivateLimitt() external view returns (uint256);

    function getLTVPercentage() external view returns (uint256);

    function isWhitelistedForActivation(address) external returns (bool);

    function isSuperAdminAccess(address) external returns (bool);

    function isTokenApproved(address) external returns (bool);

    function isTokenEnabledForCreateLoan(address) external returns (bool);

    function getGovPlatformFee() external view returns (uint256);

    function getSingleApproveTokenData(address _tokenAddress)
        external
        view
        returns (
            address,
            bool,
            uint256
        );

    function isSyntheticMintOn(address _token) external view returns (bool);

    function isStableApproved(address _stable) external view returns (bool);

    function getOneInchAggregator() external view returns (address);
    
    function getMinLoanAmountAllowed() external view returns(uint256);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
pragma solidity ^0.8.3;

struct TierData {
    // Gov  Holdings to check if it lies in that tier
    uint256 govHoldings;
    // LTV percentage of the Gov Holdings
    uint8 loantoValue;
    //checks that if tier level have following access
    bool govIntel;
    bool singleToken;
    bool multiToken;
    bool singleNFT;
    bool multiNFT;
    bool reverseLoan;
}

interface IGovTier {
    function getSingleTierData(bytes32 _tierLevelKey)
        external
        view
        returns (TierData memory);

    function isAlreadyTierLevel(bytes32 _tierLevel)
        external
        view
        returns (bool);

    function getGovTierLevelKeys() external view returns (bytes32[] memory);

    function getWalletTier(address _userAddress)
        external
        view
        returns (bytes32 _tierLevel);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "../library/NetworkLoanData.sol";

interface INetworkLoan {
    function getLtv(uint256 _loanId) external view returns (uint256);

    function isLiquidationPending(uint256 _loanId) external view returns (bool);

    function getAltCoinPriceinStable(
        address _stableCoin,
        uint256 _collateralAmount
    ) external view returns (uint256);

    /**
    @dev function that will get APY fee of the loan amount in borrower
     */
    function getAPYFee(NetworkLoanData.LoanDetails memory _loanDetails)
        external
        returns (uint256);

    /**
    @dev function that will get AutoSell APY fee of the loan amount
     */
    function getautosellAPYFee(
        uint256 loanAmount,
        uint256 autosellAPY,
        uint256 loanterminDays
    ) external returns (uint256);

    event LoanOfferCreated(
        uint256 _loanId,
        NetworkLoanData.LoanDetails _loanDetails
    );

    event LoanOfferAdjusted(
        uint256 _loanId,
        NetworkLoanData.LoanDetails _loanDetails
    );

    event LoanOfferActivated(
        uint256 loanId,
        address _lender,
        uint256 _stableCoinAmount,
        bool _autoSell
    );

    event LoanOfferCancel(
        uint256 loanId,
        address _borrower,
        NetworkLoanData.LoanStatus loanStatus
    );

    event FullLoanPaybacked(
        uint256 loanId,
        address _borrower,
        NetworkLoanData.LoanStatus loanStatus
    );

    event PartialLoanPaybacked(
        uint256 loanId,
        uint256 paybackAmount,
        address _borrower
    );

    event AutoLiquidated(
        uint256 _loanId,
        NetworkLoanData.LoanStatus loanStatus
    );

    event LiquidatedCollaterals(
        uint256 _loanId,
        NetworkLoanData.LoanStatus loanStatus
    );

    event WithdrawNetworkCoin(address walletAddress, uint256 withdrawAmount);

    event WithdrawToken(
        address tokenAddress,
        address walletAddress,
        uint256 withdrawAmount
    );

    event LoanActivateLimitUpdated(uint256 loansActivateLimit);
    event LTVPercentageUpdated(uint256 ltvPercentage);
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IAdminRegistry {
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

    function isAddGovAdminRole(address admin) external view returns (bool);

    //using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(address admin)
        external
        view
        returns (bool);

    //using this function externally in other Smart Contracts
    function isAddTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isAddSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditAPYPerAccess(address admin) external view returns (bool);

    //using this function in loan smart contracts to withdraw network balance
    function isSuperAdminAccess(address admin) external view returns (bool);
}