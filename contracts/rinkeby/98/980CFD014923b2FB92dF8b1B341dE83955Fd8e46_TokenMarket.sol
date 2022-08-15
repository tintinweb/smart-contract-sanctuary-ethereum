// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../base/TokenMarketBase.sol";
import "../../oracle/IPriceConsumer.sol";
import "../../claimtoken/IClaimToken.sol";
import "../interfaces/ITokenMarketRegistry.sol";
import "../library/TokenLoanData.sol";
import "../pausable/PausableImplementation.sol";
import "../../addressprovider/IAddressProvider.sol";
import "../../admin/tierLevel/interfaces/IUserTier.sol";

interface IGToken {
    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

interface ILiquidator {
    function addPlatformFee(address _stableCoin, uint256 _platformFee) external;

    function isLiquidateAccess(address liquidator) external view returns (bool);
}

contract TokenMarket is TokenMarketBase, PausableImplementation {
    //Load library structs into contract
    using TokenLoanData for *;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev state variables for the token market

    address public Liquidator;
    address public TierLevel;
    address public PriceConsumer;
    address public ClaimToken;
    address public marketRegistry;
    address public addressProvider;
    uint256 public loanId;

    mapping(address => uint256) public loanLendLimit;

    function initialize() external initializer {
        __Ownable_init();
    }

    /// @dev this function update all the address that are needed to run the token market
    function updateAddresses() external onlyOwner {
        Liquidator = IAddressProvider(addressProvider).getLiquidator();
        TierLevel = IAddressProvider(addressProvider).getUserTier();
        PriceConsumer = IAddressProvider(addressProvider).getPriceConsumer();
        ClaimToken = IAddressProvider(addressProvider).getClaimTokenContract();
        marketRegistry = IAddressProvider(addressProvider)
            .getTokenMarketRegistry();
    }

    /// @dev function to set the address provider contract
    function setAddressProvider(address _addressProvider) external onlyOwner {
        require(_addressProvider != address(0), "zero address");
        addressProvider = _addressProvider;
    }
    
    modifier onlySuperAdmin(address _admin) {
        require(
            ITokenMarketRegistry(marketRegistry).isSuperAdminAccess(_admin),
            "GTM: Not a  Super Admin."
        );
        _;
    }

    modifier onlyLiquidator(address _admin) {
        require(
            ILiquidator(Liquidator).isLiquidateAccess(_admin),
            "GTM: not liquidator"
        );
        _;
    }

    /// @dev receive native token in the contract
    receive() external payable {}

    /// @dev function to create Single || Multi Token(ERC20) Loan Offer by the BORROWER
    /// @param loanDetails loan details borrower is making for the loan
    function createLoan(TokenLoanData.LoanDetails memory loanDetails)
        public
        whenNotPaused
    {
        require(
            ITokenMarketRegistry(marketRegistry).isStableApproved(
                loanDetails.borrowStableCoin
            ),
            "GTM: not approved stable coin"
        );

        uint256 newLoanId = loanId + 1;
        uint256 collateralTokenLength = loanDetails
            .stakedCollateralTokens
            .length;
        uint256 stableCoinDecimals = IERC20Metadata(
            loanDetails.borrowStableCoin
        ).decimals();
        require(
            loanDetails.loanAmountInBorrowed >=
                (ITokenMarketRegistry(marketRegistry)
                    .getMinLoanAmountAllowed() * (10**stableCoinDecimals)),
            "GLM: min loan amount invalid"
        );
        require(
            loanDetails.stakedCollateralTokens.length ==
                loanDetails.stakedCollateralAmounts.length &&
                loanDetails.stakedCollateralTokens.length ==
                loanDetails.isMintSp.length,
            "GLM: Tokens and amounts length must be same"
        );

        if (TokenLoanData.LoanType.SINGLE_TOKEN == loanDetails.loanType) {
            //for single tokens collateral length must be one.
            require(
                collateralTokenLength == 1,
                "GLM: Multi-tokens not allowed in SINGLE TOKEN loan type."
            );
        }

        require(
            checkApprovalCollaterals(
                loanDetails.stakedCollateralTokens,
                loanDetails.stakedCollateralAmounts,
                loanDetails.isMintSp,
                loanDetails.borrower
            ),
            "Collateral Approval Error"
        );

        (
            uint256 collateralLTVPercentage,
            ,
            uint256 collatetralInBorrowed
        ) = this.getltvCalculations(
                loanDetails.stakedCollateralTokens,
                loanDetails.stakedCollateralAmounts,
                loanDetails.borrowStableCoin,
                loanDetails.loanAmountInBorrowed,
                loanDetails.borrower
            );
        require(
            collateralLTVPercentage >
                ITokenMarketRegistry(marketRegistry).getLTVPercentage(),
            "GLM: Can not create loan at liquidation level."
        );

        uint256 response = IUserTier(TierLevel).isCreateLoanTokenUnderTier(
            msg.sender,
            loanDetails.loanAmountInBorrowed,
            collatetralInBorrowed,
            loanDetails.stakedCollateralTokens
        );
        require(response == 200, "GLM: Invalid Tier Loan");

        borrowerloanOfferIds[msg.sender].push(newLoanId);
        loanOfferIds.push(newLoanId);
        //loop through all staked collateral tokens.
        loanOffersToken[newLoanId] = TokenLoanData.LoanDetails(
            loanDetails.loanAmountInBorrowed,
            loanDetails.termsLengthInDays,
            loanDetails.apyOffer,
            loanDetails.loanType,
            loanDetails.isPrivate,
            loanDetails.isInsured,
            loanDetails.stakedCollateralTokens,
            loanDetails.stakedCollateralAmounts,
            loanDetails.borrowStableCoin,
            TokenLoanData.LoanStatus.INACTIVE,
            msg.sender,
            0,
            loanDetails.isMintSp
        );

        emit LoanOfferCreatedToken(newLoanId, loanOffersToken[newLoanId]);
        loanId++;
    }

    /// @dev function to adjust already created loan offer, while in inactive state
    /// @param  _loanIdAdjusted, the existing loan id which is being adjusted while in inactive state
    /// @param _newLoanAmountBorrowed, the new loan amount borrower is requesting
    /// @param _newTermsLengthInDays, borrower changing the loan term in days
    /// @param _newAPYOffer, percentage of the APY offer borrower is adjusting for the lender
    /// @param _isPrivate, boolena value of true if private otherwise false
    /// @param _isInsured, isinsured true or false

    function loanAdjusted(
        uint256 _loanIdAdjusted,
        uint256 _newLoanAmountBorrowed,
        uint56 _newTermsLengthInDays,
        uint32 _newAPYOffer,
        bool _isPrivate,
        bool _isInsured
    ) public whenNotPaused {
        TokenLoanData.LoanDetails memory loanDetails = loanOffersToken[
            _loanIdAdjusted
        ];

        require(
            loanDetails.loanStatus == TokenLoanData.LoanStatus.INACTIVE,
            "GLM, Loan cannot adjusted"
        );
        require(
            loanDetails.borrower == msg.sender,
            "GLM, Only Borrow Adjust Loan"
        );

        (
            uint256 collateralLTVPercentage,
            ,
            uint256 collatetralInBorrowed
        ) = this.getltvCalculations(
                loanDetails.stakedCollateralTokens,
                loanDetails.stakedCollateralAmounts,
                loanDetails.borrowStableCoin,
                loanDetails.loanAmountInBorrowed,
                loanDetails.borrower
            );
        
        uint256 response = IUserTier(TierLevel).isCreateLoanTokenUnderTier(
            msg.sender,
            _newLoanAmountBorrowed,
            collatetralInBorrowed,
            loanDetails.stakedCollateralTokens
        );
        require(response == 200, "GLM: Invalid Tier Loan");
        require(
            collateralLTVPercentage >
                ITokenMarketRegistry(marketRegistry).getLTVPercentage(),
            "GLM: can not adjust loan at liquidation level."
        );

        loanDetails = TokenLoanData.LoanDetails(
            _newLoanAmountBorrowed,
            _newTermsLengthInDays,
            _newAPYOffer,
            loanDetails.loanType,
            _isPrivate,
            _isInsured,
            loanDetails.stakedCollateralTokens,
            loanDetails.stakedCollateralAmounts,
            loanDetails.borrowStableCoin,
            TokenLoanData.LoanStatus.INACTIVE,
            msg.sender,
            0,
            loanDetails.isMintSp
        );

        loanOffersToken[_loanIdAdjusted] = loanDetails;

        emit LoanOfferAdjustedToken(_loanIdAdjusted, loanDetails);
    }

    /// @dev function to cancel the created laon offer for token type Single || Multi Token Colletrals
    /// @param _loanId loan Id which is being cancelled/removed, will update the status of the loan details from the mapping

    function loanOfferCancel(uint256 _loanId) public whenNotPaused {
        require(
            loanOffersToken[_loanId].loanStatus ==
                TokenLoanData.LoanStatus.INACTIVE,
            "GLM, Loan cannot be cancel"
        );
        require(
            loanOffersToken[_loanId].borrower == msg.sender,
            "GLM, Only Borrow can cancel"
        );

        loanOffersToken[_loanId].loanStatus = TokenLoanData
            .LoanStatus
            .CANCELLED;
        emit LoanOfferCancelToken(
            _loanId,
            msg.sender,
            loanOffersToken[_loanId].loanStatus
        );
    }

    /// @dev cancel multiple loans by liquidator
    /// @dev function to cancel loans which are invalid,
    /// @dev because of low ltv or max loan amount below the collateral value, or duplicated loans on same collateral amount

    function loanCancelBulk(uint256[] memory _loanIds)
        external
        onlyLiquidator(msg.sender)
    {
        uint256 loanIdsLength = _loanIds.length;
        for (uint256 i = 0; i < loanIdsLength; i++) {
            require(
                loanOffersToken[_loanIds[i]].loanStatus ==
                    TokenLoanData.LoanStatus.INACTIVE,
                "GLM, Loan cannot be cancel"
            );

            loanOffersToken[_loanIds[i]].loanStatus = TokenLoanData
                .LoanStatus
                .CANCELLED;
            emit LoanOfferCancelToken(
                _loanIds[i],
                loanOffersToken[_loanIds[i]].borrower,
                loanOffersToken[_loanIds[i]].loanStatus
            );
        }
    }

    /// @dev function for lender to activate loan offer by the borrower
    /// @param loanIds array of loan ids which are going to be activated
    /// @param stableCoinAmounts amounts of stable coin requested by the borrower for the specific loan Id
    /// @param _autoSell if autosell, then loan will be autosell at the time of liquidation through the DEX

    function activateLoan(
        uint256[] memory loanIds,
        uint256[] memory stableCoinAmounts,
        bool[] memory _autoSell
    ) public whenNotPaused {
        for (uint256 i = 0; i < loanIds.length; i++) {
            require(
                loanIds.length == stableCoinAmounts.length &&
                    loanIds.length == _autoSell.length,
                "GLM: length not match"
            );

            TokenLoanData.LoanDetails storage loanDetails = loanOffersToken[
                loanIds[i]
            ];

            require(
                loanDetails.loanStatus == TokenLoanData.LoanStatus.INACTIVE,
                "GLM, not inactive"
            );
            require(
                loanDetails.borrower != msg.sender,
                "GLM, self activation forbidden"
            );
            if (
                !ITokenMarketRegistry(marketRegistry)
                    .isWhitelistedForActivation(msg.sender)
            ) {
                require(
                    loanLendLimit[msg.sender] + 1 <=
                        ITokenMarketRegistry(marketRegistry)
                            .getLoanActivateLimit(),
                    "GTM: you cannot lend more loans"
                );
                loanLendLimit[msg.sender]++;
            }

            if (
                IClaimToken(ClaimToken).isClaimToken(
                    IClaimToken(ClaimToken).getClaimTokenofSUNToken(
                        loanDetails.stakedCollateralTokens[i]
                    )
                )
            ) {
                require(
                    !_autoSell[i],
                    "GTM: autosell should be false for SUN Collateral Token"
                );
            }

            (uint256 collateralLTVPercentage, uint256 maxLoanAmount, ) = this
                .getltvCalculations(
                    loanDetails.stakedCollateralTokens,
                    loanDetails.stakedCollateralAmounts,
                    loanDetails.borrowStableCoin,
                    stableCoinAmounts[i],
                    loanDetails.borrower
                );

            require(
                maxLoanAmount != 0,
                "GTM: borrower not eligible, no tierLevel"
            );
            
            require(
                collateralLTVPercentage >
                    ITokenMarketRegistry(marketRegistry).getLTVPercentage(),
                "GLM: Can not activate loan at liquidation level."
            );

            loanDetails.loanStatus = TokenLoanData.LoanStatus.ACTIVE;

                //push active loan ids to the lendersactivatedloanIds mapping
            lenderActivatedLoanIds[msg.sender].push(loanIds[i]);

            /// @dev  if maxLoanAmount is greater then we will keep setting the borrower loan offer amount in the loan Details

            if (maxLoanAmount >= loanDetails.loanAmountInBorrowed) {
                require(
                    loanDetails.loanAmountInBorrowed == stableCoinAmounts[i],
                    "GLM, not borrower requrested loan amount"
                );
                loanDetails.loanAmountInBorrowed = stableCoinAmounts[i];
            } else if (maxLoanAmount < loanDetails.loanAmountInBorrowed) {
                // maxLoanAmount is now assigning in the loan Details struct
                require(
                    stableCoinAmounts[i] == maxLoanAmount,
                    "GLM: loan amount not equal maxLoanAmount"
                );
                loanDetails.loanAmountInBorrowed == maxLoanAmount;
            }


            uint256 apyFee = ITokenMarketRegistry(marketRegistry).getAPYFee(
                loanDetails.loanAmountInBorrowed,
                loanDetails.apyOffer,
                loanDetails.termsLengthInDays
            );
            uint256 platformFee = (loanDetails.loanAmountInBorrowed *
                (ITokenMarketRegistry(marketRegistry).getGovPlatformFee())) /
                (10000);

            //adding platform in the liquidator contract
            ILiquidator(Liquidator).addPlatformFee(
                loanDetails.borrowStableCoin,
                platformFee
            );

            {
                //checking again the collateral tokens approval from the borrower
                //contract will now hold the staked collateral tokens
                require(
                    checkApprovedTransferCollateralsandMintSynthetic(
                        loanIds[i],
                        loanDetails.stakedCollateralTokens,
                        loanDetails.stakedCollateralAmounts,
                        loanDetails.borrower
                    ),
                    "Transfer Collateral Failed"
                );

                /// @dev approving erc20 stable token from the front end
                /// @dev transfer platform fee and apy fee to th liquidator contract, before  transfering the stable coins to borrower.
                IERC20Upgradeable(loanDetails.borrowStableCoin)
                    .safeTransferFrom(
                        msg.sender,
                        address(this),
                        loanDetails.loanAmountInBorrowed
                    );

                /// @dev APY Fee + Platform Fee transfer to the liquidator contract
                IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransfer(
                    Liquidator,
                    apyFee + platformFee
                );

                /// @dev loan amount transfer after cut to borrower
                IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransfer(
                    loanDetails.borrower,
                    (loanDetails.loanAmountInBorrowed - (apyFee + platformFee))
                );

                //activated loan id to the lender details
                activatedLoanOffers[loanIds[i]] = TokenLoanData.LenderDetails({
                    lender: msg.sender,
                    activationLoanTimeStamp: block.timestamp,
                    autoSell: _autoSell[i]
                });
            }

            emit TokenLoanOfferActivated(
                loanIds[i],
                msg.sender,
                stableCoinAmounts[i],
                _autoSell[i]
            );
        }
    }

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
    ) internal returns (bool) {
        uint256 length = _collateralTokens.length;
        for (uint256 i = 0; i < length; i++) {
            address claimToken = IClaimToken(ClaimToken)
                .getClaimTokenofSUNToken(_collateralTokens[i]);
            require(
                ITokenMarketRegistry(marketRegistry).isTokenApproved(
                    _collateralTokens[i]
                ) || IClaimToken(ClaimToken).isClaimToken(claimToken),
                "GLM: One or more tokens not approved."
            );
            require(
                ITokenMarketRegistry(marketRegistry)
                    .isTokenEnabledForCreateLoan(_collateralTokens[i]),
                "GTM: token not enabled"
            );
            require(!isMintSp[i], "GLM: mint error");
            uint256 allowance = IERC20Upgradeable(_collateralTokens[i])
                .allowance(borrower, address(this));
            require(
                allowance >= _collateralAmounts[i],
                "GTM: Transfer amount exceeds allowance."
            );
        }

        return true;
    }

    /// @dev check approve of tokens, transfer token to contract and mint synthetic token if mintVip is on for that collateral token
    /// @param _loanId using loanId to make isMintSp flag true in the create loan function
    /// @param collateralAddresses collateral token addresses array
    /// @param collateralAmounts collateral token amounts array
    /// @return bool return true if succesful check all the approval of token and transfer of collateral tokens, else returns false.
    function checkApprovedTransferCollateralsandMintSynthetic(
        uint256 _loanId,
        address[] memory collateralAddresses,
        uint256[] memory collateralAmounts,
        address borrower
    ) internal returns (bool) {
        uint256 length = collateralAddresses.length;
        for (uint256 k = 0; k < length; k++) {
            require(
                IERC20Upgradeable(collateralAddresses[k]).allowance(
                    borrower,
                    address(this)
                ) >= collateralAmounts[k],
                "GLM: Transfer amount exceeds allowance."
            );

            IERC20Upgradeable(collateralAddresses[k]).safeTransferFrom(
                borrower,
                Liquidator,
                collateralAmounts[k]
            );
            {
                (address gToken, , ) = ITokenMarketRegistry(marketRegistry)
                    .getSingleApproveTokenData(collateralAddresses[k]);
                if (
                    ITokenMarketRegistry(marketRegistry).isSyntheticMintOn(
                        collateralAddresses[k]
                    )
                ) {
                    IGToken(gToken).mint(borrower, collateralAmounts[k]);
                    loanOffersToken[_loanId].isMintSp[k] = true;
                }
            }
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
        address _borrower
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 collatetralInBorrowed = 0;
        IPriceConsumer _priceConsumer = IPriceConsumer(PriceConsumer);

        for (
            uint256 index = 0;
            index < _stakedCollateralAmount.length;
            index++
        ) {
            address claimToken = IClaimToken(ClaimToken)
                .getClaimTokenofSUNToken(_stakedCollateralTokens[index]);
            if (IClaimToken(ClaimToken).isClaimToken(claimToken)) {
                collatetralInBorrowed =
                    collatetralInBorrowed +
                    (
                        _priceConsumer.getSUNTokenPrice(
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
                        _priceConsumer.getAltCoinPriceinStable(
                            _borrowStableCoin,
                            _stakedCollateralTokens[index],
                            _stakedCollateralAmount[index]
                        )
                    );
            }
        }
        uint256 calulatedLTV = _priceConsumer.calculateLTV(
            _stakedCollateralAmount,
            _stakedCollateralTokens,
            _borrowStableCoin,
            _loanAmountinStable
        );
        uint256 maxLoanAmountValue = IUserTier(TierLevel)
            .getMaxLoanAmountToValue(collatetralInBorrowed, _borrower);

        return (calulatedLTV, maxLoanAmountValue, collatetralInBorrowed);
    }

    /// @dev update the payback Amount in the Liquidator contract
    /// @dev caller of this function will be liquidator contract
    /// @param _loanId loan Id of the borrower whose payback amount is updating
    /// @param _paybackAmount payback amount passed in the liquidator contract while payback function execution from the borrower
    function updatePaybackAmount(uint256 _loanId, uint256 _paybackAmount)
        external
        override
    {
        require(msg.sender == Liquidator, "GTM: Caller not liquidator");
        loanOffersToken[_loanId].paybackAmount += _paybackAmount;
    }

    /// @dev update the loan status in the token market by the liqudator contract
    /// @param _loanId loan Id of the borrower
    /// @param _status loan status if the loan offer is being payback or liquidated in the liquidator contract
    function updateLoanStatus(uint256 _loanId, TokenLoanData.LoanStatus _status)
        external
        override
    {
        require(msg.sender == Liquidator, "GTM: Caller not liquidator");

        loanOffersToken[_loanId].loanStatus = _status;
    }

    /// @dev only super admin can withdraw coins
    /// @param _withdrawAmount value input by the super admin whichever amount receive in the token market contract
    /// @param _walletAddress wallet address of the receiver of native coin
    function withdrawCoin(
        uint256 _withdrawAmount,
        address payable _walletAddress
    ) public onlySuperAdmin(msg.sender) {
        require(
            _withdrawAmount <= address(this).balance,
            "GTM: Amount Invalid"
        );
        (bool success, ) = payable(_walletAddress).call{value: _withdrawAmount}(
            ""
        );
        require(success, "GTM: ETH transfer failed");
        emit WithdrawNetworkCoin(_walletAddress, _withdrawAmount);
    }

    /// @dev get activated loan details of the lender, termslength and autosell boolean (true or false)
    /// @param _loanId loan Id of the borrower
    /// @return TokenLoanData.LenderDetails returns the activate loan detail
    function getActivatedLoanDetails(uint256 _loanId)
        external
        view
        override
        returns (TokenLoanData.LenderDetails memory)
    {
        return activatedLoanOffers[_loanId];
    }

    /// @dev get loan details of the single or multi-token
    /// @param _loanId loan Id of the borrower
    /// @return TokenLoanData returns the activate loan detail
    function getLoanOffersToken(uint256 _loanId)
        external
        view
        override
        returns (TokenLoanData.LoanDetails memory)
    {
        return loanOffersToken[_loanId];
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
pragma abicoder v2;

import "../library/TokenLoanData.sol";
import "../interfaces/ITokenMarket.sol";

abstract contract TokenMarketBase is ITokenMarket {
    //Load library structs into contract
    using TokenLoanData for *;
    //saves the transaction hash of the create loan offer transaction as loanId
    mapping(uint256 => TokenLoanData.LoanDetails) public loanOffersToken;

    //mapping saves the information of the lender across the active loanId
    mapping(uint256 => TokenLoanData.LenderDetails) public activatedLoanOffers;

    //array of all loan offer ids of the ERC20 tokens.
    uint256[] public loanOfferIds;

    //erc20 tokens loan offer mapping
    mapping(address => uint256[]) public borrowerloanOfferIds;

    //mapping address of lender => loan Ids
    mapping(address => uint256[]) public lenderActivatedLoanIds;

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

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @dev contract used in the token market, NFT market, and network loan market
abstract contract PausableImplementation is
    PausableUpgradeable,
    OwnableUpgradeable
{
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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