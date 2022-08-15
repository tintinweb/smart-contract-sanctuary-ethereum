// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../admin/interfaces/IAdminRegistry.sol";
import "../interfaces/ITokenMarket.sol";
import "../interfaces/ITokenMarketRegistry.sol";
import "../../oracle/IPriceConsumer.sol";
import "../../interfaces/IUniswapSwapInterface.sol";
import "../../admin/interfaces/IProtocolRegistry.sol";
import "../../claimtoken/IClaimToken.sol";
import "./LiquidatorBase.sol";
import "../library/TokenLoanData.sol";
import "../../admin/SuperAdminControl.sol";
import "../../addressprovider/IAddressProvider.sol";

interface IGToken {
    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

contract Liquidator is LiquidatorBase, SuperAdminControl {
    using TokenLoanData for *;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public _tokenMarket;
    address public addressProvider;

    address public govAdminRegistry;
    ITokenMarket public govTokenMarket;
    IPriceConsumer public govPriceConsumer;
    IProtocolRegistry public govProtocolRegistry;
    IClaimToken public govClaimToken;
    ITokenMarketRegistry public marketRegistry;

    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    function initialize(
        address _liquidator1,
        address _liquidator2
    ) external initializer {
        __Ownable_init();
        //owner becomes the default admin.
        _makeDefaultApproved(_liquidator1, true);
        _makeDefaultApproved(_liquidator2, true);
    }

    function updateAddresses() external onlyOwner {
        govPriceConsumer = IPriceConsumer(
            IAddressProvider(addressProvider).getPriceConsumer()
        );
        govClaimToken = IClaimToken(
            IAddressProvider(addressProvider).getClaimTokenContract()
        );
        marketRegistry = ITokenMarketRegistry(
            IAddressProvider(addressProvider).getTokenMarketRegistry()
        );
        govAdminRegistry = IAddressProvider(addressProvider).getAdminRegistry();
        govProtocolRegistry = IProtocolRegistry(
            IAddressProvider(addressProvider).getProtocolRegistry()
        );
        govTokenMarket = ITokenMarket(
            IAddressProvider(addressProvider).getTokenMarket()
        );
    }

    function setAddressProvider(address _addressProvider) external onlyOwner {
        require(_addressProvider != address(0), "zero address");
        addressProvider = _addressProvider;
    }

    /**
     * @dev This function is used to Set Token Market Address
     *
     * @param _tokenMarketAddress Address of the Media Contract to set
     */
    function configureTokenMarket(address _tokenMarketAddress)
        external
        onlySuperAdmin(govAdminRegistry, msg.sender)
    {
        require(
            _tokenMarketAddress != address(0),
            "GL: Invalid Media Contract Address!"
        );
        _tokenMarket = _tokenMarketAddress;
        govTokenMarket = ITokenMarket(_tokenMarket);
    }

    //modifier: only liquidators can liquidate pending liquidation calls
    modifier onlyLiquidatorRole(address liquidator) {
        require(
            this.isLiquidateAccess(liquidator),
            "GL: Not a Gov Liquidator."
        );
        _;
    }

    modifier onlyTokenMarket() {
        require(msg.sender == _tokenMarket, "GL: Unauthorized Access!");
        _;
    }

    //mapping of wallet address to track the approved claim token balances when loan is liquidated
    // wallet address lender => sunTokenAddress => balanceofSUNToken
    mapping(address => mapping(address => uint256))
        public liquidatedSUNTokenbalances;

    event WithdrawNetworkCoin(address walletAddress, uint256 withdrawAmount);

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

    /**
     * @dev makes _newLiquidator as a whitelisted liquidator
     * @param _newLiquidators Address of the new liquidators
     * @param _liquidatorRole access variables for _newLiquidator
     */
    function setLiquidator(
        address[] memory _newLiquidators,
        bool[] memory _liquidatorRole
    ) external onlySuperAdmin(govAdminRegistry, msg.sender) {
        for (uint256 i = 0; i < _newLiquidators.length; i++) {
            require(
                whitelistLiquidators[_newLiquidators[i]] != _liquidatorRole[i],
                "GL: cannot assign same"
            );
            _makeDefaultApproved(_newLiquidators[i], _liquidatorRole[i]);
        }
    }

    function _liquidateCollateralAutoSellOn(
        uint256 _loanId,
        bytes[] calldata _swapData
    ) internal {

        govTokenMarket.updateLoanStatus(
            _loanId,
            TokenLoanData.LoanStatus.LIQUIDATED
        );
        
        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        TokenLoanData.LenderDetails memory lenderDetails = govTokenMarket
            .getActivatedLoanDetails(_loanId);

        (, uint256 earnedAPYFee) = this.getTotalPaybackAmount(_loanId);

        uint256 apyFeeOriginal = marketRegistry.getAPYFee(
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

        //adding the unearned APY in the contract stableCoinWithdrawable mapping
        //only superAdmin can withdraw this much amount
        stableCoinWithdrawable[address(this)][
            loanDetails.borrowStableCoin
        ] += unEarnedAPYFee;

        uint256 lengthCollaterals = loanDetails.stakedCollateralTokens.length;
        uint256 callDataLength = _swapData.length;
        address aggregator1Inch = marketRegistry.getOneInchAggregator();
        require(
            callDataLength == lengthCollaterals,
            "swap call data and collateral length mismatch"
        );
        for (uint256 i = 0; i < lengthCollaterals; i++) {
            Market memory market = IProtocolRegistry(govProtocolRegistry)
                .getSingleApproveToken(loanDetails.stakedCollateralTokens[i]);
            if (loanDetails.isMintSp[i]) {
                IGToken(market.gToken).burnFrom(
                    loanDetails.borrower,
                    loanDetails.stakedCollateralAmounts[i]
                );
            }
            //inch swap
            (bool success, ) = address(aggregator1Inch).call(_swapData[i]);
            require(success, "One 1Inch Swap Failed");
           
    
        }

        uint256 autosellFeeinStable = marketRegistry.getautosellAPYFee(
            loanDetails.loanAmountInBorrowed,
            govProtocolRegistry.getAutosellPercentage(),
            loanDetails.termsLengthInDays
        );
        uint256 finalAmountToLender = (loanDetails.loanAmountInBorrowed +
            earnedAPYFee) - (autosellFeeinStable);

        stableCoinWithdrawable[address(this)][
            loanDetails.borrowStableCoin
        ] += autosellFeeinStable;

        IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransfer(
            lenderDetails.lender,
            finalAmountToLender
        );
        
        emit AutoSellONLiquidated(_loanId, TokenLoanData.LoanStatus.LIQUIDATED);
    }

    function _liquidateCollateralAutSellOff(uint256 _loanId) internal {

         //loan status is now liquidated
        govTokenMarket.updateLoanStatus(
            _loanId,
            TokenLoanData.LoanStatus.LIQUIDATED
        );

        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        TokenLoanData.LenderDetails memory lenderDetails = govTokenMarket
            .getActivatedLoanDetails(_loanId);

        (, uint256 earnedAPYFee) = this.getTotalPaybackAmount(_loanId);
        // uint256 thresholdFee = govProtocolRegistry.getThresholdPercentage();
        uint256 apyFeeOriginal = marketRegistry.getAPYFee(
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
        uint256 thresholdFeeinStable = (loanDetails.loanAmountInBorrowed *
            govProtocolRegistry.getThresholdPercentage()) / 10000;

        //threshold Fee will be cover from the platform Fee.
        uint256 lenderAmountinStable = earnedAPYFee + thresholdFeeinStable;

        //removing the thresholdFee from the stableCoinwithdrawable mapping to maintain the balances after deductions on autosell off liquidation
        stableCoinWithdrawable[address(this)][
            loanDetails.borrowStableCoin
        ] -= thresholdFeeinStable;

        //send collateral tokens to the lender
        uint256 collateralAmountinStable;

        for (
            uint256 i = 0;
            i < loanDetails.stakedCollateralTokens.length;
            i++
        ) {
            uint256 priceofCollateral;
            address claimToken = IClaimToken(govClaimToken)
                .getClaimTokenofSUNToken(loanDetails.stakedCollateralTokens[i]);

            if (govClaimToken.isClaimToken(claimToken)) {
                IERC20Upgradeable(loanDetails.stakedCollateralTokens[i])
                    .safeTransfer(
                        lenderDetails.lender,
                        loanDetails.stakedCollateralAmounts[i]
                    );
                liquidatedSUNTokenbalances[lenderDetails.lender][
                    loanDetails.stakedCollateralTokens[i]
                ] += loanDetails.stakedCollateralAmounts[i];
            } else {
                Market memory market = IProtocolRegistry(govProtocolRegistry)
                    .getSingleApproveToken(
                        loanDetails.stakedCollateralTokens[i]
                    );
                if (loanDetails.isMintSp[i]) {
                    IGToken(market.gToken).burnFrom(
                        loanDetails.borrower,
                        loanDetails.stakedCollateralAmounts[i]
                    );
                }
                priceofCollateral = govPriceConsumer.getAltCoinPriceinStable(
                    loanDetails.borrowStableCoin,
                    loanDetails.stakedCollateralTokens[i],
                    loanDetails.stakedCollateralAmounts[i]
                );
                collateralAmountinStable =
                    collateralAmountinStable +
                    priceofCollateral;

                if (
                    collateralAmountinStable <= loanDetails.loanAmountInBorrowed
                ) {
                    IERC20Upgradeable(loanDetails.stakedCollateralTokens[i])
                        .safeTransfer(
                            lenderDetails.lender,
                            loanDetails.stakedCollateralAmounts[i]
                        );
                } else if (
                    collateralAmountinStable > loanDetails.loanAmountInBorrowed
                ) {
                    uint256 exceedAltcoinValue = govPriceConsumer
                        .getAltCoinPriceinStable(
                            loanDetails.stakedCollateralTokens[i],
                            loanDetails.borrowStableCoin,
                            collateralAmountinStable -
                                loanDetails.loanAmountInBorrowed
                        );
                    uint256 collateralToLender = loanDetails
                        .stakedCollateralAmounts[i] - exceedAltcoinValue;

                    // adding exceed altcoin to the superadmin withdrawable collateral tokens
                    collateralsWithdrawable[address(this)][
                        loanDetails.stakedCollateralTokens[i]
                    ] += exceedAltcoinValue;

                    IERC20Upgradeable(loanDetails.stakedCollateralTokens[i])
                        .safeTransfer(lenderDetails.lender, collateralToLender);
                    break;
                }
            }
        }
       
        //lender recieves the stable coins
        IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransfer(
            lenderDetails.lender,
            lenderAmountinStable
        );
        emit AutoSellOFFLiquidated(
            _loanId,
            TokenLoanData.LoanStatus.LIQUIDATED
        );
    }

    /**
    @dev approve collaterals to the one inch aggregator v4
    @param _collateralTokens collateral tokens
    @param _amounts collateral token amont
     */
    function approveCollateralToOneInch(
        address[] memory _collateralTokens,
        uint256[] memory _amounts
    ) external onlyLiquidatorRole(msg.sender) {
        uint256 lengthCollaterals = _collateralTokens.length;
        require(
            lengthCollaterals == _amounts.length,
            "collateral and amount length mismatch"
        );
        address oneInchAggregator = marketRegistry.getOneInchAggregator();
        for (uint256 i = 0; i < lengthCollaterals; i++) {
            IERC20(_collateralTokens[i]).approve(
                oneInchAggregator,
                _amounts[i]
            );
        }
    }
    
    /**
    @dev liquidate call from the gov world liquidator
    @param _loanId loan id to check if its liqudation pending or loan term ended
    @param _swapData is the data getting from the 1inch swap api after approving token from smart contract
    */
    
    function liquidateLoan(
        uint256 _loanId,
        bytes[] calldata _swapData
    ) external override onlyLiquidatorRole(msg.sender) {
        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        TokenLoanData.LenderDetails memory lenderDetails = govTokenMarket
            .getActivatedLoanDetails(_loanId);

        require(
            loanDetails.loanStatus == TokenLoanData.LoanStatus.ACTIVE,
            "GLM, not active"
        );

        require(this.isLiquidationPending(_loanId), "GTM: Liquidation Error");

        if (lenderDetails.autoSell) {
            _liquidateCollateralAutoSellOn(_loanId, _swapData);
        } else {
            _liquidateCollateralAutSellOff(_loanId);
        }
    }

    function addPlatformFee(address _stableCoin, uint256 _platformFee)
        external
        override
        onlyTokenMarket
    {
        stableCoinWithdrawable[address(this)][_stableCoin] += _platformFee;
    }

    function getAllLiquidators() external view returns (address[] memory) {
        return whitelistedLiquidators;
    }

    function getLiquidatorAccess(address _liquidator)
        external
        view
        returns (bool)
    {
        return whitelistLiquidators[_liquidator];
    }

    //only super admin can withdraw coins
    function withdrawCoin(
        uint256 _withdrawAmount,
        address payable _walletAddress
    ) external onlySuperAdmin(govAdminRegistry, msg.sender) {
        require(
            _withdrawAmount <= address(this).balance,
            "GTM: Amount Invalid"
        );
        (bool success, ) = payable(_walletAddress).call{value: _withdrawAmount}(
            ""
        );
        require(success, "GLC: ETH transfer failed");
        emit WithdrawNetworkCoin(_walletAddress, _withdrawAmount);
    }

    /**
    @dev only super admin can withdraw stable coin which includes platform fee and unearned apyFee
    */
    function withdrawStable(
        address _tokenAddress,
        uint256 _amount,
        address _walletAddress
    ) external onlySuperAdmin(govAdminRegistry, msg.sender) {
        uint256 availableAmount = stableCoinWithdrawable[address(this)][
            _tokenAddress
        ];
        require(availableAmount > 0, "GNM: stable not available");
        require(_amount <= availableAmount, "GNL: Amount Invalid");
        stableCoinWithdrawable[address(this)][_tokenAddress] -= _amount;
        IERC20Upgradeable(_tokenAddress).safeTransfer(_walletAddress, _amount);
        emit WithdrawStable(_tokenAddress, _walletAddress, _amount);
    }

    /**
    @dev only super admin can withdraw exceed altcoins upon liquidation when autsell was off
    */
    function withdrawExceedAltcoins(
        address _tokenAddress,
        uint256 _amount,
        address _walletAddress
    ) external onlySuperAdmin(govAdminRegistry, msg.sender) {
        uint256 availableAmount = collateralsWithdrawable[address(this)][
            _tokenAddress
        ];
        require(availableAmount > 0, "GNM: stable not available");
        require(_amount <= availableAmount, "GNL: Amount Invalid");
        collateralsWithdrawable[address(this)][_tokenAddress] -= _amount;
        IERC20Upgradeable(_tokenAddress).safeTransfer(_walletAddress, _amount);
        emit WithdrawAltcoin(_tokenAddress, _walletAddress, _amount);
    }

    /**
    @dev functino to get the LTV of the loan amount in borrowed of the staked colletral token
    @param _loanId loan ID for which ltv is getting
     */
    function getLtv(uint256 _loanId) external view override returns (uint256) {
        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        //get individual collateral tokens for the loan id
        uint256[] memory stakedCollateralAmounts = loanDetails
            .stakedCollateralAmounts;
        address[] memory stakedCollateralTokens = loanDetails
            .stakedCollateralTokens;
        address borrowedToken = loanDetails.borrowStableCoin;
        return
            govPriceConsumer.calculateLTV(
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
        external
        view
        override
        returns (bool)
    {
        TokenLoanData.LenderDetails memory lenderDetails = govTokenMarket
            .getActivatedLoanDetails(_loanId);
        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);

        uint256 loanTermLengthPassedInDays = (block.timestamp -
            lenderDetails.activationLoanTimeStamp) / 86400;

        // @dev get LTV
        uint256 calulatedLTV = this.getLtv(_loanId);
        //@dev the collateral is less than liquidation threshold percentage/loan term length end ok for liquidation
        // @dev loanDetails.termsLengthInDays + 1 is which we are giving extra time to the borrower to payback the collateral
        if (
            calulatedLTV <= marketRegistry.getLTVPercentage() ||
            (loanTermLengthPassedInDays >= loanDetails.termsLengthInDays + 1)
        ) return true;
        else return false;
    }

    function getTotalPaybackAmount(uint256 _loanId)
        external
        view
        returns (uint256, uint256)
    {
        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        uint256 loanTermLengthPassedInDays = (block.timestamp -
            (
                govTokenMarket
                    .getActivatedLoanDetails(_loanId)
                    .activationLoanTimeStamp
            )) / 86400;
        uint256 earnedAPYFee = ((loanDetails.loanAmountInBorrowed *
            loanDetails.apyOffer) /
            10000 /
            365) * loanTermLengthPassedInDays;
        return (loanDetails.loanAmountInBorrowed + earnedAPYFee, earnedAPYFee);
    }

    /**
    @dev payback loan full by the borrower to the lender
     */
    function fullLoanPaybackEarly(uint256 _loanId, uint256 _paybackAmount)
        internal
    {
        govTokenMarket.updateLoanStatus(
            _loanId,
            TokenLoanData.LoanStatus.CLOSED
        );
        
        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        TokenLoanData.LenderDetails memory lenderDetails = govTokenMarket
            .getActivatedLoanDetails(_loanId);

        (uint256 finalPaybackAmounttoLender, uint256 earnedAPYFee) = this
            .getTotalPaybackAmount(_loanId);

        uint256 apyFeeOriginal = marketRegistry.getAPYFee(
            loanDetails.loanAmountInBorrowed,
            loanDetails.apyOffer,
            loanDetails.termsLengthInDays
        );

        uint256 unEarnedAPYFee = apyFeeOriginal - earnedAPYFee;
        //adding the unearned APY in the contract stableCoinWithdrawable mapping
        //only superAdmin can withdraw this much amount
        stableCoinWithdrawable[address(this)][
            loanDetails.borrowStableCoin
        ] += unEarnedAPYFee;

        //first transferring the payback amount from borrower to the Gov Token Market
        IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransferFrom(
            loanDetails.borrower,
            address(this),
            loanDetails.loanAmountInBorrowed - loanDetails.paybackAmount
        );
        IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransfer(
            lenderDetails.lender,
            finalPaybackAmounttoLender
        );
        uint256 lengthCollateral = loanDetails.stakedCollateralTokens.length;

        //loop through all staked collateral tokens.
        for (uint256 i = 0; i < lengthCollateral; i++) {
            //contract will the repay staked collateral tokens to the borrower
            IERC20Upgradeable(loanDetails.stakedCollateralTokens[i])
                .safeTransfer(
                    msg.sender,
                    loanDetails.stakedCollateralAmounts[i]
                );
            Market memory market = IProtocolRegistry(govProtocolRegistry)
                .getSingleApproveToken(loanDetails.stakedCollateralTokens[i]);
            IGToken gtoken = IGToken(market.gToken);
            if (
                market.tokenType == TokenType.ISVIP && loanDetails.isMintSp[i]
            ) {
                gtoken.burnFrom(
                    loanDetails.borrower,
                    loanDetails.stakedCollateralAmounts[i]
                );
            }
        }

        govTokenMarket.updatePaybackAmount(_loanId, _paybackAmount);
        

        emit FullTokensLoanPaybacked(
            _loanId,
            msg.sender,
            lenderDetails.lender,
            loanDetails.loanAmountInBorrowed - loanDetails.paybackAmount,
            earnedAPYFee
        );
    }

    /**
    @dev token loan payback partial
    if _paybackAmount is equal to the total loan amount in stable coins the loan concludes as full payback
     */
    function payback(uint256 _loanId, uint256 _paybackAmount) public override {
        TokenLoanData.LoanDetails memory loanDetails = govTokenMarket
            .getLoanOffersToken(_loanId);
        TokenLoanData.LenderDetails memory lenderDetails = govTokenMarket
            .getActivatedLoanDetails(_loanId);

        require(loanDetails.borrower == msg.sender, "GLM, not borrower");
        require(
            loanDetails.loanStatus == TokenLoanData.LoanStatus.ACTIVE,
            "GLM, not active"
        );
        require(
            _paybackAmount > 0 &&
                _paybackAmount <= loanDetails.loanAmountInBorrowed,
            "GLM: Invalid Payback Loan Amount"
        );
        require(
            !this.isLiquidationPending(_loanId),
            "GLM: you cannot payback this time"
        );
        
        uint256 totalPayback = _paybackAmount + loanDetails.paybackAmount;
        if (totalPayback >= loanDetails.loanAmountInBorrowed) {
            fullLoanPaybackEarly(_loanId, _paybackAmount);
        }
        //partial loan paypack
        else {
            
            govTokenMarket.updatePaybackAmount(_loanId, _paybackAmount);

            uint256 remainingLoanAmount = loanDetails.loanAmountInBorrowed -
                totalPayback;
            uint256 newLtv = IPriceConsumer(govPriceConsumer).calculateLTV(
                loanDetails.stakedCollateralAmounts,
                loanDetails.stakedCollateralTokens,
                loanDetails.borrowStableCoin,
                remainingLoanAmount
            );
            require(
                newLtv > marketRegistry.getLTVPercentage(),
                "GLM: new LTV exceeds threshold."
            );
            IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransferFrom(
                loanDetails.borrower,
                address(this),
                _paybackAmount
            );

            emit PartialTokensLoanPaybacked(
                _loanId,
                msg.sender,
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
        return liquidatedSUNTokenbalances[_lender][_sunToken];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safePermit(
        IERC20PermitUpgradeable token,
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    //using this function in loan smart contracts to withdraw network balance
    function isSuperAdminAccess(address admin) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "../library/TokenLoanData.sol";

interface ITokenMarket {

    /**
    @dev get activated loan details of the lender, termslength and autosell boolean (true or false)
     */
    function getActivatedLoanDetails(uint256 _loanId)
        external
        view
        returns (TokenLoanData.LenderDetails memory);

    /**
    @dev get loan details of the single or multi-token
    */
    function getLoanOffersToken(uint256 _loanId)
        external
        view
        returns (TokenLoanData.LoanDetails memory);

    function updatePaybackAmount(uint256 _loanId, uint256 _paybackAmount)
        external;

    function updateLoanStatus(
        uint256 _loanId,
        TokenLoanData.LoanStatus loanStatus
    ) external;

    event LoanOfferCreatedToken(
        uint256 _loanId,
        TokenLoanData.LoanDetails _loanDetailsToken
    );

    event LoanOfferAdjustedToken(
        uint256 _loanId,
        TokenLoanData.LoanDetails _loanDetails
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
        TokenLoanData.LoanStatus loanStatus
    );

    event FullTokensLoanPaybacked(
        uint256 loanId,
        address _borrower,
        address _lender,
        uint256 _paybackAmount,
        TokenLoanData.LoanStatus loanStatus,
        uint256 _earnedAPY
    );

    event PartialTokensLoanPaybacked(
        uint256 loanId,
        address _borrower,
        address _lender,
        uint256 paybackAmount
    );

    event AutoLiquidated(uint256 _loanId, TokenLoanData.LoanStatus loanStatus);

    event LiquidatedCollaterals(
        uint256 _loanId,
        TokenLoanData.LoanStatus loanStatus
    );

    event WithdrawNetworkCoin(address walletAddress, uint256 withdrawAmount);

    event WithdrawToken(
        address tokenAddress,
        address walletAddress,
        uint256 withdrawAmount
    );
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

    function getLoanActivateLimit() external view returns (uint256);

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

    function getMinLoanAmountAllowed() external view returns (uint256);
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
        returns (Market memory);

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

pragma solidity ^0.8.3;

struct ClaimTokenData {
    // token type is used for token type sun or peg token
    uint256 tokenType;
    address[] pegTokens;
    uint256[] pegTokensPricePercentage;
    address dexRouter; //this address will get the price from the AMM DEX (uniswap, sushiswap etc...)
}

interface IClaimToken {
    function isClaimToken(address _claimTokenAddress)
        external
        view
        returns (bool);

    function getClaimTokensData(address _claimTokenAddress)
        external
        view
        returns (ClaimTokenData memory);

    function getClaimTokenofSUNToken(address _sunToken)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../market/liquidator/ILiquidator.sol";

abstract contract LiquidatorBase is OwnableUpgradeable, ILiquidator {
    /// @dev list of already approved liquidators.
    mapping(address => bool) public whitelistLiquidators;

    /// @dev list of all approved liquidator addresses. Stores the key for mapping approvedLiquidators
    address[] public whitelistedLiquidators;

    /// @dev mapping for storing the plaform Fee and unearned APY Fee at the time of payback or liquidation
    // add the value in the mapping like that
    // [TokenMarket][stableCoinAddress] += platformFee OR Unearned APY Fee
    mapping(address => mapping(address => uint256))
        public stableCoinWithdrawable;

    /// @dev mapping to add the collateral token amount when autosell off
    // remaining tokens will be added to the collateralsWithdrawable mapping
    // [TokenMarket][collateralToken] += exceedaltcoins;  // liquidated collateral on autsell off
    mapping(address => mapping(address => uint256))
        public collateralsWithdrawable;

    event NewLiquidatorApproved(
        address indexed _newLiquidator,
        bool _liquidatorAccess
    );
    event AutoSellONLiquidated(
        uint256 _loanId,
        TokenLoanData.LoanStatus loanStatus
    );
    event AutoSellOFFLiquidated(
        uint256 _loanId,
        TokenLoanData.LoanStatus loanStatus
    );
    event FullTokensLoanPaybacked(uint256, address, address, uint256, uint256);
    event PartialTokensLoanPaybacked(uint256, address, address, uint256);

    /**
    @dev function to check if address have liquidate role option
     */
    function isLiquidateAccess(address liquidator)
        external
        view
        override
        returns (bool)
    {
        return whitelistLiquidators[liquidator];
    }

    /**
     * @dev makes _newLiquidator an approved liquidator and emits the event
     * @param _newLiquidator Address of the new liquidator
     * @param _liquidatorAccess access variables for _newLiquidator
     */
    function _makeDefaultApproved(
        address _newLiquidator,
        bool _liquidatorAccess
    ) internal {
        whitelistLiquidators[_newLiquidator] = _liquidatorAccess;
        whitelistedLiquidators.push(_newLiquidator);
        emit NewLiquidatorApproved(_newLiquidator, _liquidatorAccess);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

library TokenLoanData {
    enum LoanStatus {
        ACTIVE,
        INACTIVE,
        CLOSED,
        CANCELLED,
        LIQUIDATED
    }

    enum LoanType {
        SINGLE_TOKEN,
        MULTI_TOKEN
    }

    struct LenderDetails {
        address lender;
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
        //Single-ERC20, Multiple staked ERC20,
        LoanType loanType;
        //private loans will not appear on loan market
        bool isPrivate;
        //Future use flag to insure funds as they go to protocol.
        bool isInsured;
        //single - or multi token collateral tokens wrt tokenAddress
        address[] stakedCollateralTokens;
        // collateral amounts
        uint256[] stakedCollateralAmounts;
        // address of the stable coin borrow wants
        address borrowStableCoin;
        //current status of the loan
        LoanStatus loanStatus;
        //borrower's address
        address borrower;
        // track the record of payback amount
        uint256 paybackAmount;
        // flag for the mint VIP token at the time of creating loan
        bool[] isMintSp;
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
            "not super admin"
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../library/TokenLoanData.sol";

interface ILiquidator {
    /// @dev using this function externally in the Token, Network Loan and NFT Loan Market Smart Contract
    function isLiquidateAccess(address liquidator) external view returns (bool);

    function liquidateLoan(
        uint256 _loanId,
        bytes[] calldata _swapData
    ) external;

    // function liquidateLoan(uint256 _loanId) external;

    function getLtv(uint256 _loanId) external view returns (uint256);

    function isLiquidationPending(uint256 _loanId) external view returns (bool);

    function payback(uint256 _loanId, uint256 _paybackAmount) external;

    function addPlatformFee(address _stable, uint256 _platformFee) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}