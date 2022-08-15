// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../pausable/PausableImplementation.sol";
import "../base/NftMarketBase.sol";
import "../../admin/SuperAdminControl.sol";
import "../../addressprovider/IAddressProvider.sol";
import "../../admin/tierLevel/interfaces/IUserTier.sol";
import "../interfaces/ITokenMarketRegistry.sol";

interface IGovLiquidator {
    function isLiquidateAccess(address liquidator) external view returns (bool);
}

interface IProtocolRegistry {
    function isStableApproved(address _stable) external view returns (bool);

    function getGovPlatformFee() external view returns (uint256);
}

contract NftMarket is
    NftMarketBase,
    ERC721Holder,
    PausableImplementation,
    SuperAdminControl
{
    //Load library structs into contract
    using NftLoanData for *;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IGovLiquidator public Liquidator;
    IProtocolRegistry public ProtocolRegistry;
    IUserTier public TierLevel;

    address public govAdminRegistry;
    address public addressProvider;
    address public marketRegistry;
    uint256 public loanIdNFT;

    uint256 public loanActivateLimit;
    mapping(address => bool) public whitelistAddress;
    mapping(address => uint256) public loanLendLimit;

    function initialize() external initializer {
        __Ownable_init();
    }

    modifier onlyLiquidator(address _admin) {
        require(
            IGovLiquidator(Liquidator).isLiquidateAccess(_admin),
            "GTM: not liquidator"
        );
        _;
    }

    /// @dev function to receive the native coins
    receive() external payable {}

    /// @dev this function update all the address that are needed to run the token market

    function updateAddresses() external onlyOwner {
        Liquidator = IGovLiquidator(
            IAddressProvider(addressProvider).getLiquidator()
        );
        ProtocolRegistry = IProtocolRegistry(
            IAddressProvider(addressProvider).getProtocolRegistry()
        );
        TierLevel = IUserTier(IAddressProvider(addressProvider).getUserTier());
        govAdminRegistry = IAddressProvider(addressProvider).getAdminRegistry();
        marketRegistry = IAddressProvider(addressProvider)
            .getTokenMarketRegistry();
    }

    /// @dev function to set the address provider contract

    function setAddressProvider(address _addressProvider) external onlyOwner {
        require(_addressProvider != address(0), "zero address");
        addressProvider = _addressProvider;
    }

    /// @dev set the loan activation limit for the nft market loans
    /// @param _loansLimit loan limit set the lenders
    function setloanActivateLimit(uint256 _loansLimit)
        external
        onlySuperAdmin(govAdminRegistry, msg.sender)
    {
        require(_loansLimit > 0, "GTM: loanlimit error");
        loanActivateLimit = _loansLimit;
        emit LoanActivateLimitUpdated(_loansLimit);
    }

    /// @dev set the whitelist addresses that can lend unlimited loans
    /// @param _lender address of the lender
    function setWhilelistAddress(address _lender)
        external
        onlySuperAdmin(govAdminRegistry, msg.sender)
    {
        require(_lender != address(0x0), "GTM: null address error");
        whitelistAddress[_lender] = true;
    }

    /// @dev modifier: only liquidators can liqudate pending liquidation calls
    modifier onlyLiquidatorRole(address liquidator) {
        require(
            Liquidator.isLiquidateAccess(liquidator),
            "GNM: Not a Gov Liquidator."
        );
        _;
    }

    /// @dev function to create Single || Multi NFT Loan Offer by the BORROWER
    /// @param  loanDetailsNFT {see NftLoanData.sol}

    function createLoan(NftLoanData.LoanDetailsNFT memory loanDetailsNFT)
        public
        whenNotPaused
    {
        require(
            ProtocolRegistry.isStableApproved(loanDetailsNFT.borrowStableCoin),
            "GLM: not approved stable coin"
        );

        uint256 newLoanIdNFT = _getNextLoanIdNFT();
        uint256 stableCoinDecimals = IERC20Metadata(
            loanDetailsNFT.borrowStableCoin
        ).decimals();
        require(
            loanDetailsNFT.loanAmountInBorrowed >=
                (ITokenMarketRegistry(marketRegistry)
                    .getMinLoanAmountAllowed() * (10**stableCoinDecimals)),
            "GLM: min loan amount invalid"
        );

        uint256 collateralLength = loanDetailsNFT
            .stakedCollateralNFTsAddress
            .length;
        require(
            (loanDetailsNFT.stakedCollateralNFTsAddress.length ==
                loanDetailsNFT.stakedCollateralNFTId.length) ==
                (loanDetailsNFT.stakedCollateralNFTId.length ==
                    loanDetailsNFT.stakedNFTPrice.length),
            "GLM: Length not equal"
        );

        if (NftLoanData.LoanType.SINGLE_NFT == loanDetailsNFT.loanType) {
            require(collateralLength == 1, "GLM: MULTI-NFTs not allowed");
        }
        uint256 collatetralInBorrowed = 0;
        for (uint256 index = 0; index < collateralLength; index++) {
            collatetralInBorrowed += loanDetailsNFT.stakedNFTPrice[index];
        }
        uint256 response = TierLevel.isCreateLoanNftUnderTier(
            msg.sender,
            loanDetailsNFT.loanAmountInBorrowed,
            collatetralInBorrowed,
            loanDetailsNFT.stakedCollateralNFTsAddress
        );
        require(response == 200, "NMT: Invalid tier loan");
        borrowerloanOffersNFTs[msg.sender].push(newLoanIdNFT);
        loanOfferIdsNFTs.push(newLoanIdNFT);
        //loop through all staked collateral NFTs.
        require(
            checkApprovalNFTs(
                loanDetailsNFT.stakedCollateralNFTsAddress,
                loanDetailsNFT.stakedCollateralNFTId
            ),
            "GLM: one or more nfts not approved"
        );

        loanOffersNFT[newLoanIdNFT] = NftLoanData.LoanDetailsNFT(
            loanDetailsNFT.stakedCollateralNFTsAddress,
            loanDetailsNFT.stakedCollateralNFTId,
            loanDetailsNFT.stakedNFTPrice,
            loanDetailsNFT.loanAmountInBorrowed,
            loanDetailsNFT.apyOffer,
            loanDetailsNFT.loanType,
            NftLoanData.LoanStatus.INACTIVE,
            loanDetailsNFT.termsLengthInDays,
            loanDetailsNFT.isPrivate,
            loanDetailsNFT.isInsured,
            msg.sender,
            loanDetailsNFT.borrowStableCoin
        );

        emit LoanOfferCreatedNFT(newLoanIdNFT, loanOffersNFT[newLoanIdNFT]);

        _incrementLoanIdNFT();
    }

    /// @dev function to cancel the created laon offer for token type Single || Multi NFT Colletrals
    /// @param _nftloanId loan Id which is being cancelled/removed, will delete all the loan details from the mapping

    function nftloanOfferCancel(uint256 _nftloanId) public whenNotPaused {
       
        require(
            loanOffersNFT[_nftloanId].loanStatus ==
                NftLoanData.LoanStatus.INACTIVE,
            "GLM, cannot be cancel"
        );
        require(
            loanOffersNFT[_nftloanId].borrower == msg.sender,
            "GLM, only borrower can cancel"
        );

        loanOffersNFT[_nftloanId].loanStatus = NftLoanData.LoanStatus.CANCELLED;

        emit LoanOfferCancelNFT(
            _nftloanId,
            msg.sender,
            loanOffersNFT[_nftloanId].loanStatus
        );
    }

    // @dev cancel multiple loans by liquidator
    /// @dev function to cancel loans which are invalid,
    /// @dev because of low ltv or max loan amount below the collateral value, or duplicated loans on same collateral amount
    function loanCancelBulk(uint256[] memory _loanIds)
        external
        onlyLiquidator(msg.sender)
    {
        uint256 loanIdsLength = _loanIds.length;
        for (uint256 i = 0; i < loanIdsLength; i++) {
            require(
                loanOffersNFT[_loanIds[i]].loanStatus ==
                    NftLoanData.LoanStatus.INACTIVE,
                "GLM, Loan cannot be cancel"
            );

            loanOffersNFT[_loanIds[i]].loanStatus = NftLoanData
                .LoanStatus
                .CANCELLED;
            emit LoanOfferCancelNFT(
                _loanIds[i],
                loanOffersNFT[_loanIds[i]].borrower,
                loanOffersNFT[_loanIds[i]].loanStatus
            );
        }
    }

    /// @dev function to adjust already created loan offer, while in inactive state
    /// @param  _nftloanIdAdjusted, the existing loan id which is being adjusted while in inactive state
    /// @param _newLoanAmountBorrowed, the new loan amount borrower is requesting
    /// @param _newTermsLengthInDays, borrower changing the loan term in days
    /// @param _newAPYOffer, percentage of the APY offer borrower is adjusting for the lender
    /// @param _isPrivate, boolena value of true if private otherwise false
    /// @param _isInsured, isinsured true or false

    function nftLoanOfferAdjusted(
        uint256 _nftloanIdAdjusted,
        uint256 _newLoanAmountBorrowed,
        uint56 _newTermsLengthInDays,
        uint32 _newAPYOffer,
        bool _isPrivate,
        bool _isInsured
    ) public whenNotPaused {
    
        require(
            loanOffersNFT[_nftloanIdAdjusted].loanStatus ==
                NftLoanData.LoanStatus.INACTIVE,
            "GLM, Loan cannot adjusted"
        );
        require(
            loanOffersNFT[_nftloanIdAdjusted].borrower == msg.sender,
            "GLM, only borrower can adjust own loan"
        );

        uint256 collatetralInBorrowed = 0;
        for (
            uint256 index = 0;
            index < loanOffersNFT[_nftloanIdAdjusted].stakedNFTPrice.length;
            index++
        ) {
            collatetralInBorrowed += loanOffersNFT[_nftloanIdAdjusted]
                .stakedNFTPrice[index];
        }

        uint256 response = TierLevel.isCreateLoanNftUnderTier(
            msg.sender,
            _newLoanAmountBorrowed,
            collatetralInBorrowed,
            loanOffersNFT[_nftloanIdAdjusted].stakedCollateralNFTsAddress
        );
        require(response == 200, "NMT: Invalid tier loan");
        loanOffersNFT[_nftloanIdAdjusted] = NftLoanData.LoanDetailsNFT(
            loanOffersNFT[_nftloanIdAdjusted].stakedCollateralNFTsAddress,
            loanOffersNFT[_nftloanIdAdjusted].stakedCollateralNFTId,
            loanOffersNFT[_nftloanIdAdjusted].stakedNFTPrice,
            _newLoanAmountBorrowed,
            _newAPYOffer,
            loanOffersNFT[_nftloanIdAdjusted].loanType,
            NftLoanData.LoanStatus.INACTIVE,
            _newTermsLengthInDays,
            _isPrivate,
            _isInsured,
            msg.sender,
            loanOffersNFT[_nftloanIdAdjusted].borrowStableCoin
        );

        emit NFTLoanOfferAdjusted(
            _nftloanIdAdjusted,
            loanOffersNFT[_nftloanIdAdjusted]
        );
    }

    /// @dev function for lender to activate loan offer by the borrower
    /// @param _nftloanId loan id which is going to be activated
    /// @param _stableCoinAmount amount of stable coin requested by the borrower

    function activateNFTLoan(uint256 _nftloanId, uint256 _stableCoinAmount)
        public
        whenNotPaused
    {
        NftLoanData.LoanDetailsNFT memory loanDetailsNFT = loanOffersNFT[
            _nftloanId
        ];

        require(
            loanDetailsNFT.loanStatus == NftLoanData.LoanStatus.INACTIVE,
            "GLM, loan should be InActive"
        );
        require(
            loanDetailsNFT.borrower != msg.sender,
            "GLM, only Lenders can Active"
        );
        require(
            loanDetailsNFT.loanAmountInBorrowed == _stableCoinAmount,
            "GLM, amount not equal to borrow amount"
        );

        if (!whitelistAddress[msg.sender]) {
            require(
                loanLendLimit[msg.sender] + 1 <= loanActivateLimit,
                "GTM: you cannot lend more loans"
            );
            loanLendLimit[msg.sender]++;
        }

        loanOffersNFT[_nftloanId].loanStatus = NftLoanData.LoanStatus.ACTIVE;

        //push active loan ids to the lendersactivatedloanIds mapping
        lenderActivatedLoansNFTs[msg.sender].push(_nftloanId);

        // checking again the collateral tokens approval from the borrower
        // contract will now hold the staked collateral tokens after safeTransferFrom executes
        require(
            checkAppovedandTransferNFTs(
                loanDetailsNFT.stakedCollateralNFTsAddress,
                loanDetailsNFT.stakedCollateralNFTId,
                loanDetailsNFT.borrower
            ),
            "GTM: Transfer Failed"
        );

        uint256 apyFee = this.getAPYFeeNFT(loanDetailsNFT);
        uint256 platformFee = (loanDetailsNFT.loanAmountInBorrowed *
            (ProtocolRegistry.getGovPlatformFee())) / 10000;
        uint256 loanAmountAfterCut = loanDetailsNFT.loanAmountInBorrowed -
            (apyFee + platformFee);
        stableCoinWithdrawable[address(this)][
            loanDetailsNFT.borrowStableCoin
        ] += platformFee;

        require(
            (apyFee + loanAmountAfterCut + platformFee) ==
                loanDetailsNFT.loanAmountInBorrowed,
            "GLM, invalid amount"
        );

        /// @dev lender transfer the stable coins to the nft market contract
        IERC20Upgradeable(loanDetailsNFT.borrowStableCoin).safeTransferFrom(
            msg.sender,
            address(this),
            loanDetailsNFT.loanAmountInBorrowed
        );

        /// @dev loan amount transfer to borrower after the loan amount cut
        IERC20Upgradeable(loanDetailsNFT.borrowStableCoin).safeTransfer(
            loanDetailsNFT.borrower,
            loanAmountAfterCut
        );

        //activated loan id to the lender details
        activatedNFTLoanOffers[_nftloanId] = NftLoanData.LenderDetailsNFT({
            lender: msg.sender,
            activationLoanTimeStamp: block.timestamp
        });

        emit NFTLoanOfferActivated(
            _nftloanId,
            msg.sender,
            loanDetailsNFT.loanAmountInBorrowed,
            loanDetailsNFT.termsLengthInDays,
            loanDetailsNFT.apyOffer,
            loanDetailsNFT.stakedCollateralNFTsAddress,
            loanDetailsNFT.stakedCollateralNFTId,
            loanDetailsNFT.stakedNFTPrice,
            loanDetailsNFT.loanType,
            loanDetailsNFT.isPrivate,
            loanDetailsNFT.borrowStableCoin
        );
    }

    /// @dev payback loan full by the borrower to the lender
    /// @param _nftLoanId nft loan Id of the borrower
    function nftLoanPaybackBeforeTermEnd(uint256 _nftLoanId)
        public
        whenNotPaused
    {
        address borrower = msg.sender;

        NftLoanData.LoanDetailsNFT memory loanDetailsNFT = loanOffersNFT[
            _nftLoanId
        ];

        require(
            loanDetailsNFT.borrower == borrower,
            "GLM, only borrower can payback"
        );
        require(
            loanDetailsNFT.loanStatus == NftLoanData.LoanStatus.ACTIVE,
            "GLM, loan should be Active"
        );

        uint256 loanTermLengthPassed = block.timestamp -
            activatedNFTLoanOffers[_nftLoanId].activationLoanTimeStamp;
        uint256 loanTermLengthPassedInDays = loanTermLengthPassed / 86400; //86400 == 1 day
        require(
            loanTermLengthPassedInDays <= loanDetailsNFT.termsLengthInDays,
            "GLM: Loan already paybacked or liquidated"
        );
        uint256 apyFeeOriginal = this.getAPYFeeNFT(loanDetailsNFT);

        uint256 earnedAPY = ((loanDetailsNFT.loanAmountInBorrowed *
            loanDetailsNFT.apyOffer) /
            10000 /
            365) * loanTermLengthPassedInDays;

        if (earnedAPY > apyFeeOriginal) {
            earnedAPY = apyFeeOriginal;
        }

        uint256 finalAmounttoLender = loanDetailsNFT.loanAmountInBorrowed +
            earnedAPY;

        uint256 unEarnedAPYFee = apyFeeOriginal - earnedAPY;

        stableCoinWithdrawable[address(this)][
            loanDetailsNFT.borrowStableCoin
        ] += unEarnedAPYFee;

        loanOffersNFT[_nftLoanId].loanStatus = NftLoanData.LoanStatus.CLOSED;

        IERC20Upgradeable(loanDetailsNFT.borrowStableCoin).safeTransferFrom(
            loanDetailsNFT.borrower,
            address(this),
            loanDetailsNFT.loanAmountInBorrowed
        );

        IERC20Upgradeable(loanDetailsNFT.borrowStableCoin).safeTransfer(
            activatedNFTLoanOffers[_nftLoanId].lender,
            finalAmounttoLender
        );

        //loop through all staked collateral nft tokens.
        uint256 collateralNFTlength = loanDetailsNFT
            .stakedCollateralNFTsAddress
            .length;
        for (uint256 i = 0; i < collateralNFTlength; i++) {
            /// @dev contract will the repay staked collateral tokens to the borrower
            IERC721Upgradeable(loanDetailsNFT.stakedCollateralNFTsAddress[i])
                .safeTransferFrom(
                    address(this),
                    borrower,
                    loanDetailsNFT.stakedCollateralNFTId[i]
                );
        }


        emit NFTLoanPaybacked(
            _nftLoanId,
            borrower,
            NftLoanData.LoanStatus.CLOSED
        );
    }

    /// @dev liquidate call by the gov world liqudatior address
    /// @param _loanId loan id to check if its loan term ended

    function liquidateBorrowerNFT(uint256 _loanId)
        public
        onlyLiquidatorRole(msg.sender)
    {
        require(
            loanOffersNFT[_loanId].loanStatus == NftLoanData.LoanStatus.ACTIVE,
            "GLM, loan should be Active"
        );
        NftLoanData.LoanDetailsNFT memory loanDetails = loanOffersNFT[_loanId];
        NftLoanData.LenderDetailsNFT memory lenderDetails = activatedNFTLoanOffers[_loanId];

        require(lenderDetails.activationLoanTimeStamp != 0, "GLM: loan not activated");

        uint256 loanTermLengthPassed = block.timestamp -
            lenderDetails.activationLoanTimeStamp;
        uint256 loanTermLengthPassedInDays = loanTermLengthPassed / 86400;
        require(
            loanTermLengthPassedInDays >= loanDetails.termsLengthInDays + 1,
            "GNM: Loan not ready for liquidation"
        );

        //send collateral nfts to the lender
        uint256 collateralNFTlength = loanDetails
            .stakedCollateralNFTsAddress
            .length;
        for (uint256 i = 0; i < collateralNFTlength; i++) {
            //contract will the repay staked collateral tokens to the borrower
            IERC721Upgradeable(loanDetails.stakedCollateralNFTsAddress[i])
                .safeTransferFrom(
                    address(this),
                    lenderDetails.lender,
                    loanDetails.stakedCollateralNFTId[i]
                );
        }

        loanOffersNFT[_loanId].loanStatus = NftLoanData.LoanStatus.LIQUIDATED;

        emit AutoLiquidatedNFT(_loanId, NftLoanData.LoanStatus.LIQUIDATED);
    }

    /// @dev check approval of nfts from the borrower to the nft market
    /// @param nftAddresses ERC721 NFT contract addresses
    /// @param nftIds nft token ids
    /// @return bool returns the true or false for the nft approvals
    function checkApprovalNFTs(
        address[] memory nftAddresses,
        uint256[] memory nftIds
    ) internal view returns (bool) {
        uint256 length = nftAddresses.length;

        for (uint256 i = 0; i < length; i++) {
            //borrower will approved the tokens staking as collateral
            require(
                IERC721Upgradeable(nftAddresses[i]).getApproved(nftIds[i]) ==
                    address(this),
                "GLM: Approval Error"
            );
        }
        return true;
    }

    /// @dev function that receive an array of addresses to check approval of NFTs
    /// @param nftAddresses contract addresses of ERC721
    /// @param nftIds token ids of nft contracts
    /// @param borrower address of the borrower

    function checkAppovedandTransferNFTs(
        address[] memory nftAddresses,
        uint256[] memory nftIds,
        address borrower
    ) internal returns (bool) {
        for (uint256 i = 0; i < nftAddresses.length; i++) {
            require(
                IERC721Upgradeable(nftAddresses[i]).getApproved(nftIds[i]) ==
                    address(this),
                "GLM: Approval Error"
            );
            IERC721Upgradeable(nftAddresses[i]).safeTransferFrom(
                borrower,
                address(this),
                nftIds[i]
            );
        }

        return true;
    }

    /// @dev only super admin can withdraw coins
    function withdrawCoin(
        uint256 _withdrawAmount,
        address payable _walletAddress
    ) public onlySuperAdmin(govAdminRegistry, msg.sender) {
        require(
            _withdrawAmount <= address(this).balance,
            "GNM: Amount Invalid"
        );
        (bool success, ) = payable(_walletAddress).call{value: _withdrawAmount}(
            ""
        );
        require(success, "GNM: ETH transfer failed");
        emit WithdrawNetworkCoin(_walletAddress, _withdrawAmount);
    }

    /// @dev only super admin can withdraw tokens
    /// @param _tokenAddress token Address of the stable coin, superAdmin wants to withdraw
    /// @param _amount desired amount to withdraw
    /// @param _walletAddress wallet address of the admin
    function withdrawToken(
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
        emit WithdrawToken(_tokenAddress, _walletAddress, _amount);
    }

    /**
    @dev function to get the next nft loan Id after creating the loan offer in NFT case
     */
    function _getNextLoanIdNFT() public view returns (uint256) {
        return loanIdNFT + 1;
    }

    /**
    @dev returns the current loan id of the nft loans
     */
    function getCurrentLoanIdNFT() public view returns (uint256) {
        return loanIdNFT;
    }

    /**
    @dev will increment loan id after creating loan offer
     */
    function _incrementLoanIdNFT() private {
        loanIdNFT++;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
pragma abicoder v2;

import "../library/NftLoanData.sol";
import "../interfaces/INftMarket.sol";

abstract contract NftMarketBase is INftMarket {
    //Load library structs into contract
    using NftLoanData for *;
    using NftLoanData for bytes32;

    //Single NFT or Multi NFT loan offers mapping
    mapping(uint256 => NftLoanData.LoanDetailsNFT) public loanOffersNFT;

    //mapping saves the information of the lender across the active NFT Loan Ids
    mapping(uint256 => NftLoanData.LenderDetailsNFT)
        public activatedNFTLoanOffers;

    //array of all loan offer ids of the NFT tokens.
    uint256[] public loanOfferIdsNFTs;

    //mapping of borrower address to the loan Ids of the NFT.
    mapping(address => uint256[]) public borrowerloanOffersNFTs;

    //mapping address of the lender to the activated loan offers of NFT
    mapping(address => uint256[]) public lenderActivatedLoansNFTs;

    //mapping address stable to the APY Fee of stable
    mapping(address => mapping(address => uint256))
        public stableCoinWithdrawable;

    /// @dev function returns the APY fee of the loan amount in borrow stable coin
    /// @param _loanDetailsNFT loan details to get the apy fee
    function getAPYFeeNFT(NftLoanData.LoanDetailsNFT memory _loanDetailsNFT)
        external
        pure
        returns (uint256)
    {
        // APY Fee Formula
        uint256 apyFee = ((_loanDetailsNFT.loanAmountInBorrowed *
            _loanDetailsNFT.apyOffer) /
            10000 /
            365) * _loanDetailsNFT.termsLengthInDays;
        return apyFee;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

library NftLoanData {
    enum LoanStatus {
        ACTIVE,
        INACTIVE,
        CLOSED,
        CANCELLED,
        LIQUIDATED
    }

    enum LoanType {
        SINGLE_NFT,
        MULTI_NFT
    }

    struct LenderDetailsNFT {
        address lender;
        uint256 activationLoanTimeStamp;
    }

    struct LoanDetailsNFT {
        //single nft or multi nft addresses
        address[] stakedCollateralNFTsAddress;
        //single nft id or multinft id
        uint256[] stakedCollateralNFTId;
        //single nft price or multi nft price //price fetch from the opensea or rarible
        uint256[] stakedNFTPrice;
        //total Loan Amount in USD
        uint256 loanAmountInBorrowed;
        //borrower given apy percentage
        uint32 apyOffer;
        //Single NFT and multiple staked NFT
        LoanType loanType;
        //current status of the loan
        LoanStatus loanStatus;
        //user choose terms length in days
        uint56 termsLengthInDays;
        //private loans will not appear on loan market
        bool isPrivate;
        //Future use flag to insure funds as they go to protocol.
        bool isInsured;
        //borrower's address
        address borrower;
        //borrower stable coin
        address borrowStableCoin;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "../library/NftLoanData.sol";

interface INftMarket {
    event LoanOfferCreatedNFT(
        uint256 _loanId,
        NftLoanData.LoanDetailsNFT _loanDetailsNFT
    );

    event NFTLoanOfferActivated(
        uint256 nftLoanId,
        address _lender,
        uint256 _loanAmount,
        uint256 _termsLengthInDays,
        uint256 _APYOffer,
        address[] stakedCollateralNFTsAddress,
        uint256[] stakedCollateralNFTId,
        uint256[] stakedNFTPrice,
        NftLoanData.LoanType _loanType,
        bool _isPrivate,
        address _borrowStableCoin
    );

    event NFTLoanOfferAdjusted(
        uint256 _loanId,
        NftLoanData.LoanDetailsNFT _loanDetailsNFT
    );

    event LoanOfferCancelNFT(
        uint256 nftloanId,
        address _borrower,
        NftLoanData.LoanStatus loanStatus
    );

    event NFTLoanPaybacked(
        uint256 nftLoanId,
        address _borrower,
        NftLoanData.LoanStatus loanStatus
    );

    event AutoLiquidatedNFT(
        uint256 nftLoanId,
        NftLoanData.LoanStatus loanStatus
    );

    event WithdrawNetworkCoin(address walletAddress, uint256 withdrawAmount);

    event WithdrawToken(
        address tokenAddress,
        address walletAddress,
        uint256 withdrawAmount
    );

    event LoanActivateLimitUpdated(uint256 loansActivateLimit);
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