// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

// Libraries
import "./Babylonian.sol";

// Inheritance Contacts
import "./PoolViews.sol";
import "./LiquidEvents.sol";

/**
 * @author René Hochmuth
 * @author Vitally Marinchenko
 * @author Christoph Krpoun
 */

contract LiquidPool is PoolViews, LiquidEvents {

    /**
     * @dev Modifier for functions that can
     * only be called through the router contract
    */
    modifier onlyRouter() {
        require(
            msg.sender == ROUTER_ADDRESS,
            "LiquidPool: NOT_ROUTER"
        );
        _;
    }

    /**
     * @dev Modifier for functions that can
     * only be used on known collections
    */
    modifier knownCollection(
        address _address
    ) {
        require(
            nftAddresses[_address] == true,
            "LiquidPool: UNKNOWN_COLLECTION"
        );
        _;
    }

    /**
     * @dev Runs the LASA algorithm aka
     * Lending Automated Scaling Algorithm
    */
    modifier syncPool() {
        _cleanUp();
        _updatePseudoTotalAmounts();
        _;
        _updateUtilisation();
        _newBorrowRate();

        if (_aboveThreshold() == true) {
            _scalingAlgorithm();
        }
    }

    /**
     * @dev Sets state variables for a pool more info in ILiquidInit.sol
     * gets called during creating the pool through router
    */
    function initialise(
        address _poolToken,
        address _chainLinkFeedAddress,
        uint256 _multiplicationFactor,
        uint256 _maxCollateralFactor,
        address[] memory _nftAddresses,
        string memory _tokenName,
        string memory _tokenSymbol
    )
        external
    {
        require(
            poolToken == EMPTY_ADDRESS,
            "LiquidPool: POOL_DEFINED"
        );

        ROUTER_ADDRESS = IFactory(
            msg.sender
        ).routerAddress();

        ROUTER = ILiquidRouter(
            ROUTER_ADDRESS
        );

        for (uint32 i = 0; i < _nftAddresses.length; i++) {
            nftAddresses[_nftAddresses[i]] = true;
        }

        poolToken = _poolToken;

        totalInternalShares = 1;
        pseudoTotalTokensHeld = 1;

        uint256 timeNow = block.timestamp;

        timeStampLastAlgorithm = timeNow;
        timeStampLastInteraction = timeNow;

        maxCollateralFactor = _maxCollateralFactor;
        multiplicativeFactor = _multiplicationFactor;
        chainLinkFeedAddress = _chainLinkFeedAddress;

        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = DECIMALS_ETH;

        chainLinkETH = ROUTER.chainLinkETH();
        poolTokenDecimals = IERC20(_poolToken).decimals();

        require(
            poolTokenDecimals <= DECIMALS_ETH,
            "LiquidPool: WEIRD_TOKEN"
        );

        // Calculating lower bound for the pole
        minPole = PRECISION_FACTOR_E18 / 2
            + Babylonian.sqrt(PRECISION_FACTOR_E36 / 4
                + _multiplicationFactor
                    * PRECISION_FACTOR_E36
                    / UPPER_BOUND_MAX_RATE
            );

        // Calculating upper bound for the pole
        maxPole = PRECISION_FACTOR_E18 / 2
            + Babylonian.sqrt(PRECISION_FACTOR_E36 / 4
                + _multiplicationFactor
                    * PRECISION_FACTOR_E36
                    / LOWER_BOUND_MAX_RATE
            );

        // Calculating fraction for algorithm step
        deltaPole = (maxPole - minPole)
            / NORMALISATION_FACTOR;

        // Setting start value as mean of min and max value
        pole = (maxPole + minPole)
            / 2;

        feeDestinationAddress = ROUTER_ADDRESS;

        // Initialise with 10%
        fee = 10
            * PRECISION_FACTOR_E18
            / ONE_HUNDRED;
    }

    /**
     * @dev Function permissioned to only be called from the router.
     * Calls internal deposit funds function that does the real work.
     */
    function depositFunds(
        uint256 _depositAmount,
        address _depositor
    )
        external
        syncPool
        onlyRouter
        returns (uint256)
    {
        uint256 currentPoolTokens = pseudoTotalTokensHeld;
        uint256 currentPoolShares = getCurrentPoolShares();

        uint256 shares = calculateDepositShares(
            _depositAmount,
            currentPoolTokens,
            currentPoolShares
        );

        _increaseInternalShares(
            shares,
            _depositor
        );

        _increaseTotalInternalShares(
            shares
        );

        _increaseTotalPool(
            _depositAmount
        );

        _increasePseudoTotalTokens(
            _depositAmount
        );

        return shares;
    }

    /**
     * @dev This function allows users to
     * convert internal shares into tokens.
     */
    function tokeniseShares(
        uint256 _shares
    )
        external
    {
        _decreaseInternalShares(
            _shares,
            msg.sender
        );

        _decreaseTotalInternalShares(
            _shares
        );

        _mint(
            msg.sender,
            _shares
        );
    }

    /**
     * @dev This function allows users to withdraw lended funds based on
     * internalShares.
     */
    function withdrawFunds(
        uint256 _shares,
        address _user
    )
        external
        syncPool
        onlyRouter
        returns (uint256 withdrawAmount)
    {
        uint256 userInternalShares = internalShares[_user];

        if (userInternalShares >= _shares) {
            withdrawAmount = _withdrawFundsShares(
                _shares,
                _user
            );

            return withdrawAmount;
        }

        withdrawAmount = _withdrawFundsShares(
            userInternalShares,
            _user
        );

        withdrawAmount += _withdrawFundsTokens(
            _shares - userInternalShares,
            _user
        );

        return withdrawAmount;
    }

    /**
     * @dev internal withdraw funds from pool but only from internal shares
     */
    function _withdrawFundsShares(
        uint256 _shares,
        address _user
    )
        internal
        returns (uint256)
    {
        uint256 withdrawAmount = calculateWithdrawAmount(
            _shares
        );

        _decreaseInternalShares(
            _shares,
            _user
        );

        _decreaseTotalInternalShares(
            _shares
        );

        _decreasePseudoTotalTokens(
            withdrawAmount
        );

        _decreaseTotalPool(
            withdrawAmount
        );

        _safeTransfer(
            poolToken,
            _user,
            withdrawAmount
        );

        emit FundsWithdrawn(
            _user,
            withdrawAmount,
            _shares,
            block.timestamp
        );

        return withdrawAmount;
    }

    /**
     * @dev Internal withdraw funds from pool but only from token shares.
     * Burns ERC20 share tokens and transfers the deposit tokens.
     */
    function _withdrawFundsTokens(
        uint256 _shares,
        address _user
    )
        internal
        returns (uint256)
    {
        uint256 withdrawAmount = calculateWithdrawAmount(
            _shares
        );

        _burn(
            _user,
            _shares
        );

        _decreasePseudoTotalTokens(
            withdrawAmount
        );

        _decreaseTotalPool(
            withdrawAmount
        );

        _safeTransfer(
            poolToken,
            _user,
            withdrawAmount
        );

        emit FundsWithdrawn(
            _user,
            withdrawAmount,
            _shares,
            block.timestamp
        );

        return withdrawAmount;
    }

    /**
     * @dev Take out a loan against an NFT.
     * This is a wrapper external function that
     * calls the internal borrow funds function.
     */
    function borrowFunds(
        address _borrowAddress,
        uint256 _borrowAmount,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external
        syncPool
        onlyRouter
        knownCollection(_nftAddress)
    {
        uint256 predictedFutureLoanValue = predictFutureLoanValue(
            _borrowAmount
        );

        require(
            _checkCollateralValue(
                _nftAddress,
                _nftTokenId,
                _merkleIndex,
                _merklePrice,
                _merkleProof
            ),
            "LiquidPool: INVALID_PROOF"
        );

        require(
            predictedFutureLoanValue <= getMaximumBorrow(
                merklePriceInPoolToken(
                    _merklePrice
                )
            ),
            "LiquidPool: LOAN_TOO_LARGE"
        );

        _increaseTotalBorrowShares(
            getBorrowShareAmount(
                _borrowAmount
            )
        );

        _increaseTotalTokensDue(
            _borrowAmount
        );

        _decreaseTotalPool(
            _borrowAmount
        );

        _updateLoanBorrow(
            _nftAddress,
            _nftTokenId,
            _borrowAddress,
            getBorrowShareAmount(
                _borrowAmount
            ),
            _borrowAmount
        );

        _safeTransfer(
            poolToken,
            _borrowAddress,
            _borrowAmount
        );

        emit FundsBorrowed(
            _nftAddress,
            _nftTokenId,
            _borrowAddress,
            _borrowAmount,
            block.timestamp
        );
    }

    /**
     * @dev This gives users ability to
     * borrow more funds after loan is already
     * existing (same LTV constraint).
     * Not possible if loan is already outside of TIME_BETWEEN_PAYMENTS
     */
    function borrowMoreFunds(
        address _borrowAddress,
        uint256 _borrowAmount,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external
        syncPool
        onlyRouter
        knownCollection(_nftAddress)
    {
        Loan memory loanData = currentLoans[_nftAddress][_nftTokenId];

        require(
            _borrowAddress == loanData.tokenOwner,
            "LiquidPool: NOT_OWNER"
        );

        require(
            getNextPaymentDueTime(_nftAddress, _nftTokenId) > block.timestamp,
            "LiquidPool: PAYBACK_FIRST"
        );

        uint256 predictedFutureLoanValue = predictFutureLoanValue(
            _borrowAmount + getTokensFromBorrowShares(
                loanData.borrowShares
            )
        );

        require(
            _checkCollateralValue(
                _nftAddress,
                _nftTokenId,
                _merkleIndex,
                _merklePrice,
                _merkleProof
            ),
            "LiquidPool: INVALID_PROOF"
        );

        require(
            predictedFutureLoanValue <= getMaximumBorrow(
                merklePriceInPoolToken(
                    _merklePrice
                )
            ),
            "LiquidPool: LOAN_TOO_LARGE"
        );

        _increaseTotalBorrowShares(
            getBorrowShareAmount(
                _borrowAmount
            )
        );

        _increaseTotalTokensDue(
            _borrowAmount
        );

        _decreaseTotalPool(
            _borrowAmount
        );

        _updateLoanBorrowMore(
            _nftAddress,
            _nftTokenId,
            getBorrowShareAmount(
                _borrowAmount
            ),
            _borrowAmount
        );

        _safeTransfer(
            poolToken,
            _borrowAddress,
            _borrowAmount
        );

        emit MoreFundsBorrowed(
            _nftAddress,
            _nftTokenId,
            _borrowAddress,
            _borrowAmount,
            block.timestamp
        );
    }

    /**
     * @dev Interest on a loan must be paid back regularly
     * either pays partial amount or full amount of principal
     * which will end the loan.
     */
    function paybackFunds(
        uint256 _payAmount,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external
        syncPool
        onlyRouter
        knownCollection(_nftAddress)
        returns (uint256 transferAmount)
    {
        Loan memory loanData = currentLoans[_nftAddress][_nftTokenId];

        uint256 currentLoanValue = getTokensFromBorrowShares(
            loanData.borrowShares
        );

        transferAmount = _payAmount
            + currentLoanValue
            - loanData.principalTokens;

        if (getBorrowShareAmount(transferAmount) >= loanData.borrowShares) {
            _endLoan(
                loanData.borrowShares,
                loanData.tokenOwner,
                _nftTokenId,
                _nftAddress
            );

            return currentLoanValue;
        }

        require(
            _checkCollateralValue(
               _nftAddress,
               _nftTokenId,
               _merkleIndex,
               _merklePrice,
               _merkleProof
            ) == true,
            "LiquidPool: INVALID_PROOF"
        );

        require(
            predictFutureLoanValue(
                loanData.principalTokens - _payAmount
            ) <= getMaximumBorrow(
                merklePriceInPoolToken(
                    _merklePrice
                )
            ),
            "LiquidPool: LOAN_TOO_LARGE"
        );

        _decreaseTotalBorrowShares(
            getBorrowShareAmount(
                transferAmount
            )
        );

        _decreaseTotalTokensDue(
            transferAmount
        );

        _increaseTotalPool(
            transferAmount
        );

        _updateLoanPayback(
            _nftAddress,
            _nftTokenId,
            getBorrowShareAmount(
                transferAmount
            ),
            _payAmount
        );

        emit FundsReturned(
            _nftAddress,
            loanData.tokenOwner,
            transferAmount,
            _nftTokenId,
            block.timestamp
        );

        return transferAmount;
    }

    /**
     * @dev Liquidations of loans when TIME_BETWEEN_PAYMENTS is reached. Auction mode is
     * a dutch auction style. Profits are used to payback bad debt when exists. Otherwise
     * tokens just wait in contract and get send with next cleanup call to reward address.
     */
    function liquidateNFT(
        address _liquidator,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external
        syncPool
        onlyRouter
        returns (uint256 auctionPrice)
    {
        require(
            missedDeadline(
                _nftAddress,
                _nftTokenId
            ) == true,
            "LiquidPool: TOO_EARLY"
        );

        Loan memory loanData = currentLoans[_nftAddress][_nftTokenId];

        uint256 openBorrowAmount = getTokensFromBorrowShares(
            loanData.borrowShares
        );

        auctionPrice = _getCurrentAuctionPrice(
            _nftAddress,
            _nftTokenId,
            _merkleIndex,
            _merklePrice,
            _merkleProof
        );

        _decreaseTotalBorrowShares(
            loanData.borrowShares
        );

        _decreaseTotalTokensDue(
            openBorrowAmount
        );

        _checkBadDebt(
            auctionPrice,
            openBorrowAmount
        );

        _deleteLoanData(
            _nftAddress,
            _nftTokenId
        );

        _transferNFT(
            address(this),
            _liquidator,
            _nftAddress,
            _nftTokenId
        );

        emit Liquidated(
            _nftAddress,
            _nftTokenId,
            loanData.tokenOwner,
            _liquidator,
            auctionPrice,
            block.timestamp
        );
    }

    /**
     * @dev pays back bad debt which
     * accrued if any did accumulate.
     */
    function decreaseBadDebt(
        uint256 _paybackAmount
    )
        external
    {
        _increaseTotalPool(
            _paybackAmount
        );

        _decreaseBadDebt(
            _paybackAmount
        );

        _safeTransferFrom(
            poolToken,
            msg.sender,
            address(this),
            _paybackAmount
        );

        emit DecreaseBadDebt(
            badDebt,
            _paybackAmount,
            block.timestamp
        );
    }

    /**
     * @dev
     * Fixes in the fee destination forever
     */
    function lockFeeDestination()
        external
        onlyRouter
    {
        permanentFeeDestination = true;
    }

    /**
     * @dev
     * changes the address which gets fees assigned only callable by router
     */
    function changeFeeDestinationAddress(
        address _newFeeDestinationAddress
    )
        external
        onlyRouter
    {
        require(
            permanentFeeDestination == false,
            "LiquidPool: CHANGE_NOT_ALLOWED"
        );

        feeDestinationAddress = _newFeeDestinationAddress;
    }

    /**
     * @dev gets called during finishExpandPool from router to later bypass
     * knownCollection modifier for expandable pools
     */
    function addCollection(
        address _nftAddress
    )
        external
        onlyRouter
    {
        nftAddresses[_nftAddress] = true;
    }

    /**
     * @dev makes cleanUp publicly callable aswell. More info see PoolHelper
     * _cleanup
     */
    function cleanUp()
        external
    {
        _cleanUp();
    }

    /**
     * @dev Rescues accidentally sent
     * tokens which are not the poolToken
     */
    function rescueToken(
        address _tokenAddress
    )
        external
    {
        if (_tokenAddress == poolToken) {
            revert("LiquidPool: NOT_ALLOWED");
        }

        uint256 tokenBalance = _safeBalance(
            _tokenAddress,
            address(this)
        );

        _safeTransfer(
            _tokenAddress,
            ROUTER_ADDRESS,
            tokenBalance
        );
    }

    /**
     * @dev External function to update the borrow rate of the pool
     * without any other interaction. Can be used by a bot to keep the
     * rates updated when usage is low
     */
    function manualSyncPool()
        external
        syncPool
    {
        emit ManualSyncPool(
            block.timestamp
        );
    }
}