// SPDX-License-Identifier: WISE

pragma solidity =0.8.13;

import "./Babylonian.sol";
import "./PoolHelper.sol";
import "./AccessControl.sol";
import "./LiquidEvents.sol";

contract LiquidPool is PoolHelper, AccessControl, LiquidEvents {

    /**
     * @dev Only the factory address can call functions with this modifier
    */
    modifier onlyFactory() {
        require(
            msg.sender == FACTORY_ADDRESS,
            "LiquidPool: INVALID_FACTORY"
        );
        _;
    }

    /**
     * @dev Only the router address can call functions with this modifier
    */
    modifier onlyRouter() {
        require(
            msg.sender == ROUTER_ADDRESS,
            "LiquidPool: INVALID_ROUTER"
        );
        _;
    }

    /**
     * @dev Runs the LASA (Lending Automated Scaling Algorithm) algorithm
    */
    modifier updateBorrowRate() {
        _;
        _updateUtilization();
        _newBorrowRate();

        if (_aboveThreshold() == true) {
            _scalingAlgorithm();
        }
    }

    /**
     * @dev Only allows to interract with recognized collections
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
     * @dev Sets the factory and router addresses on construction of contract. All contracts cloned by factory from
     * an implementation will also clone these values.
    */
    constructor(
        address _factoryAddress,
        address _routerAddress
    )
        PoolToken(
            "None",
            "None"
        )
        PoolHelper(
            _factoryAddress,
            _routerAddress
        )
    {
    }

    /**
     * @dev This initialize call is called after cloning a new contract with our factory.
     * Because we are using create2 to clone contracts, this initialize function replaces the constructor for initializing variables
     * @param _poolToken - erc20 token to be used by the pool
     * @param _nftAddresses - nft contracts which users can take loans against
     * @param _multisig - address that has settings permissions and receives fees
     * @param _multiplicationFactor - used for LASA interest rate scaling algorithm
     * @param _maxCollateralFactor - percentage of the nft's value that can be borrowed
     * @param _merkleRoots - Roots of the merkle trees containing specific price data for nft traits
     * @param _ipfsURL - Ipfs file path containing the current merkle tree for nft token prices
     * @param _tokenName - Name of erc20 token issued by this contract to represent shares in pool
     * @param _tokenSymbol - Symbol of erc20 token issued by this contract to represent shares in pool
     * @param _isExpandable - bool for possibility of adding collections to a pool lateron
     */
    function initialize(
        address _poolToken,
        address[] memory _nftAddresses,
        address _multisig,
        uint256 _multiplicationFactor,  // Determine how quickly the interest rate changes with changes to utilization and resonanceFactor
        uint256 _maxCollateralFactor,   // Maximal factor every NFT can be collateralized in this pool
        bytes32[] memory _merkleRoots,  // The merkleroot of a merkletree containing information about the amount to borrow for specific nfts in collection
        string[] memory _ipfsURL,
        string memory _tokenName,       // Name for erc20 representing shares of this pool
        string memory _tokenSymbol,     // Symbol for erc20 representing shares of this pool
        bool _isExpandable
    )
        external
        onlyFactory
    {
        for (uint64 i = 0; i < _nftAddresses.length; i++) {

            nftAddresses[_nftAddresses[i]] = true;
            merkleRoots[_nftAddresses[i]] = _merkleRoots[i];
            merkleIPFSURLs[_nftAddresses[i]] = _ipfsURL[i];

            emit CollectionAdded(
                _nftAddresses[i]
            );
        }

        isExpandable = _isExpandable;
        totalInternalShares = 1;
        pseudoTotalTokensHeld = 1;
        poolToken = _poolToken;
        multiplicativeFactor = _multiplicationFactor;
        maxCollateralFactor = _maxCollateralFactor;
        name = _tokenName;
        symbol = _tokenSymbol;

        _updateMultisig(
            _multisig
        );

        workers[_multisig] = true;
        workers[FACTORY_ADDRESS] = true;
        // Initializing variables for scaling algorithm and borrow rate calculation.
        // all numbers are of order 1E18

        // Depending on the individuel multiplication factor of each asset!
        // calculating lower bound for resonance factor
        minResonaceFactor = PRECISION_FACTOR_E18
            / 2
            + Babylonian.sqrt(PRECISION_FACTOR_E36/4
                + _multiplicationFactor
                    * PRECISION_FACTOR_E36
                    / UPPER_BOUND_MAX_RATE
            );

        // Calculating upper bound for resonance factor
        maxResonaceFactor = PRECISION_FACTOR_E18
            / 2
            + Babylonian.sqrt(PRECISION_FACTOR_E36/4
                + _multiplicationFactor
                    * PRECISION_FACTOR_E36
                    / LOWER_BOUND_MAX_RATE
            );

        // Calculating stepping size for algorithm
        deltaResonaceFactor = (maxResonaceFactor - minResonaceFactor)
            / NORM_FACTOR_SECONDS_IN_TWO_MONTH;

        // Setting start value as mean of min and max value
        resonanceFactor = (maxResonaceFactor + minResonaceFactor)
            / 2;

        // Initalize with 70%
        liquidationPercentage = 70;
    }

    /**
     * @dev Function permissioned to only be called from the router to deposit funds
     * Calls internal deposit funds function that does the real work.
     * Router makes sure that the _depositor variable is always the msg.sender to the router
     */
    function depositFunds(
        uint256 _amount,
        address _depositor
    )
        external
        onlyRouter
        updateBorrowRate
    {
        _preparationPool();

        uint256 currentPoolTokens = pseudoTotalTokensHeld;
        uint256 currentPoolShares = getCurrentPoolShares();

        uint256 shares = _calculateDepositShares(
            _amount,
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
            _amount
        );

        _increasePseudoTotalTokens(
            _amount
        );

        emit FundsDeposited(
            _depositor,
            _amount,
            shares,
            block.timestamp
        );
    }

    /**
     * @dev This function allows users to convert internal shares into tokenized shares for the pool.
     * Tokenized shares function the same as internal shares, but are explicitly represented by an erc20 token and tradable.
     */
    function tokenizeShares(
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

    function withdrawFunds(
        uint256 _shares,
        address _user
    )
        external
        onlyRouter
        updateBorrowRate
    {
        _preparationPool();

        uint256 userInternalShares = internalShares[_user];

        if (userInternalShares >= _shares) {
            _withdrawFundsShares(
                _shares,
                _user
            );

            return;
        }

        _withdrawFundsShares(
            userInternalShares,
            _user
        );

        _withdrawFundsTokens(
            _shares - userInternalShares,
            _user
        );
    }

    /**
     * @dev Withdraw funds from pool but only from internal shares, not token shares.
     */
    function _withdrawFundsShares(
        uint256 _shares,
        address _user
    )
        internal
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
    }

    /**
     * @dev Withdraw funds from pool but only from token shares, not internal shares.
     * Burns erc20 share tokens and transfers the deposit tokens to the user.
     */
    function _withdrawFundsTokens(
        uint256 _shares,
        address _user
    )
        internal
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
    }

    /**
     * @dev Take out a loan against an nft. This is a wrapper external function that calls the internal borrow funds function.
     * Only the router can call this function. Depositor will always be the msg.sender of the router.
     */
    function borrowFunds(
        uint256 _tokenAmountToBorrow,
        uint256 _timeIncrease,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata _merkleProof,
        uint256 _merklePrice,
        address _borrower,
        address _nftAddress
    )
        external
        onlyRouter
    {
        uint256[] memory params = new uint256[](5);

        params[0] = _tokenAmountToBorrow;
        params[1] = _timeIncrease;
        params[2] = _tokenId;
        params[3] = _index;
        params[4] = _merklePrice;

        _borrowFunds(
            params,
            _merkleProof,
            _borrower,
            _nftAddress
        );
    }

    /**
     * @dev Send a nft from the specified set to this contract in exchange for a loan.
     * Can use a merkle tree structure to verify price of individual tokens and traits of the nft set.
     * If merkle root is not initialized for the set then the tokensPerLoan variable is used to determine loan amount.
     * We predict the loans value at a specified date in the future using a markov chain. This uses a time series of
     * interest rates in this contract over time. Maximum time between payments is 35 days. This allows for monthly paybacks.
     * The loans predicted value for the specifed future date with _timeIncrease is not allowed to exceed the nft token's
     * collateralization value. (_timeIncrease is the number of seconds you want to increase by, capped at 35 days)
     * Can use a merkle tree structure to verify price of individual tokens and traits of the nft set
     * If merkle root is not initialized for the set then the tokensPerNft variable is used to determine loan amount.
     *
     * This function uses a parameters array instead of explicitly named local variables to avoid stack too deep errors.
     * The parameters in the parameters array are detailed below
     *
     * uint256 _tokenAmountToBorrow, -> params[0] --How many ERC20 tokens desired for the loan
     * uint256 _timeIncrease,  -> params[1]       --How many seconds the user would like to request until their next payment is due
     * uint256 _tokenId, -> params[2]             --Identifier of nft token to borrow against
     * uint256 _index, -> params[3]               --Index of nft token in merkle tree
     * uint256 _merklePrice, -> params[4]         --Price token of token in merkle tree. Must be correct in order for merkle tree to be verified
     */

    function _borrowFunds(
        uint256[] memory _params,
        bytes32[] calldata _merkleProof,
        address _borrower,
        address _nftAddress
    )
        internal
        updateBorrowRate
        knownCollection(_nftAddress)
    {
        _preparationPool();

        _params[1] = cutoffAtMaximumTimeIncrease(
            _params[1] // _timeIncrease
        );

        {
            // Markov mean is relative to 1 year so divide by seconds
            uint256 predictedFutureLoanValue = predictFutureLoanValue(
                _params[0], // _tokenAmountToBorrow
                _params[1]  // _timeIncrease
            );

            require(
                _checkCollateralValue(
                    _nftAddress,
                    _params[2],  // _tokenId
                    _params[3],  // _index
                    _merkleProof,
                    _params[4]   // _merklePrice
                ),
                'LiquidPool: INVALID_PROOF'
            );

            require(
                predictedFutureLoanValue <= getMaximumBorrow(_params[4]),
                "LiquidPool: LOAN_TOO_LARGE"
            );
        }

        uint256 borrowSharesGained = getBorrowShareAmount(
            _params[0] // _tokenAmountToBorrow
        );

        _increaseTotalBorrowShares(
            borrowSharesGained
        );

        _increaseTotalTokensDue(
            _params[0] // _tokenAmountToBorrow
        );

        _decreaseTotalPool(
            _params[0] // _tokenAmountToBorrow
        );

        _updateLoan(
            _nftAddress,
            _borrower,
            _params[2], // _tokenId
            _params[1], // _timeIncrease
            borrowSharesGained,
            _params[0], // _tokenAmountToBorrow
            block.timestamp
        );

        _safeTransfer(
            poolToken,
            _borrower,
            _params[0] // _tokenAmountToBorrow
        );

        emit FundsBorrowed(
            _nftAddress,
            _borrower,
            _params[2],
            block.timestamp + _params[1],
            _params[0],
            block.timestamp
        );
    }

    function paybackFunds(
        uint256 _principalPayoff,
        uint256 _timeIncrease,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata  _merkleProof,
        uint256 _merklePrice,
        address _nftAddress
    )
        external
        onlyRouter
        returns (uint256, uint256)
    {
        uint256[] memory params = new uint256[](5);

        params[0] = _principalPayoff;
        params[1] = _timeIncrease;
        params[2] = _tokenId;
        params[3] = _index;
        params[4] = _merklePrice;

        return _paybackFunds(
            params,
            _merkleProof,
            _nftAddress
        );
    }

    /**
     * @dev Interest on a loan must be paid back regularly.
     * This function will automatically make the user pay off the interest on a loan, with the option to also pay off some prinicipal as well
     * The maximum amount of time between payments will be set at 35 days to allow payments on the same day of each month.
     * The same prediction system described in borrow function documentation is used here as well,
     * predicted value of the nft at the specified time increase must not exceed collateralization value.
     * Time increase can be whatever a user wants, but funds must be payed back again by that many seconds into the future
     * or else the loan will start to go up for liquidation and incur penalties.
     * The maximum amount of time between payments will be set at 35 days to allow payments on the same day of each month
     * uint256 _principalPayoff, -> params[0]
     * uint256 _timeIncrease,    -> params[1]
     * uint256 _tokenId,         -> params[2]
     * uint256 _index,           -> params[3]
     * uint256 _merklePrice,     -> params[4]
     */
    function _paybackFunds(
        uint256[] memory _params,
        bytes32[] calldata _merkleProof,
        address _nftAddress
    )
        internal
        updateBorrowRate
        knownCollection(_nftAddress)
        returns(
            uint256 totalPayment,
            uint256 feeAmount
        )
    {
        _preparationPool();

        uint256 borrowSharesToDestroy;
        uint256 penaltyAmount;

        {
            Loan memory loanData = currentLoans[_nftAddress][_params[2]]; // _tokenId

            _params[1] = cutoffAtMaximumTimeIncrease(
                _params[1] // _timeIncrease
            );

            {
                uint256 currentLoanValue = getTokensFromBorrowShareAmount(
                    loanData.borrowShares
                );

                if (block.timestamp > loanData.nextPaymentDueTime) {
                    penaltyAmount = _getPenaltyAmount(
                        currentLoanValue,
                        (block.timestamp - loanData.nextPaymentDueTime) / SECONDS_IN_DAY
                    );
                }

                feeAmount = (currentLoanValue - loanData.principalTokens)
                    * fee
                    / PRECISION_FACTOR_E20;

                totalPayment = _params[0] // _principalPayoff
                    + currentLoanValue
                    - loanData.principalTokens;


                borrowSharesToDestroy = getBorrowShareAmount(
                    totalPayment
                );

                if (borrowSharesToDestroy >= loanData.borrowShares) {

                    _endLoan(
                        _params[2], // _tokenId
                        loanData,
                        penaltyAmount,
                        _nftAddress
                    );

                    return (currentLoanValue + penaltyAmount, feeAmount);
                }
            }

            require(
                _checkCollateralValue(
                   _nftAddress,
                   _params[2], // _tokenId
                   _params[3], // _index
                   _merkleProof,
                   _params[4] // _merklePrice
                ) == true,
                "LiquidPool: INVALID_PROOF"
            );

            require(
                predictFutureLoanValue(
                    loanData.principalTokens - _params[0], // _principalPayoff
                    _params[1]  // _timeIncrease
                ) <= getMaximumBorrow(_params[4]), // _merklePrice
                "LiquidPool: LOAN_TOO_LARGE"
            );

            _decreaseTotalBorrowShares(
                borrowSharesToDestroy
            );

            _decreaseTotalTokensDue(
                totalPayment
            );

            _increaseTotalPool(
                totalPayment + penaltyAmount
            );

            _increasePseudoTotalTokens(
                penaltyAmount
            );
        }

        _updateLoanPayback(
            _nftAddress,
            _params[2], // _tokenId
            _params[1], // _timeIncrease
            borrowSharesToDestroy,
            _params[0], // _principalPayoff
            block.timestamp
        );

        emit PaybackFunds(
            _nftAddress,
            currentLoans[_nftAddress][_params[2]].tokenOwner,
            totalPayment,
            block.timestamp + _params[1], // _timeIncrease
            penaltyAmount,
            _params[2], // _tokenId
            block.timestamp
        );

        return (
            totalPayment + penaltyAmount,
            feeAmount
        );
    }

    /**
     * @dev Liquidations of loans are allowed when a loan has no payment made for 7 days after their deadline.
     * These monthly regular payments help to keep liquid tokens flowing through the contract.
     * Handles the liquidation of a NFT loan with directly buying the NFT from the
     * pool. Liquidator gets the NFT for a discount price which is the sum
     * of the current borrow amount + penalties + liquidation fee.
     * Ideally this amount should be less as the actual NFT value so ppl
     * are incentivized to liquidate. User needs the token into her/his wallet.
     * After a period of two days the Multisig-Wallet can get the NFT with another function.
    */
    function liquidateNFT(
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata _merkleProof,
        uint256 _merklePrice,
        address _nftAddress
    )
        external
        updateBorrowRate
    {
        require(
            missedDeadline(
                _nftAddress,
                _tokenId
            ) == true,
            "LiquidPool: TOO_EARLY"
        );

        _preparationPool();

        Loan memory loanData = currentLoans[_nftAddress][_tokenId];

        uint256 openBorrowAmount = getTokensFromBorrowShareAmount(
            loanData.borrowShares
        );

        require(
            _checkCollateralValue(
                _nftAddress,
                _tokenId,
                _index,
                _merkleProof,
                _merklePrice
            ),
            "LiquidPool: INVALID_PROOF"
        );

        uint256 discountAmount = getLiquidationAmounts(
            _merklePrice,
            loanData.nextPaymentDueTime
        );

        require(
            discountAmount >= openBorrowAmount,
            "LiquidPool: DISCOUNT_TOO_LARGE"
        );

        _decreaseTotalBorrowShares(
            loanData.borrowShares
        );

        _decreaseTotalTokensDue(
            openBorrowAmount
        );

        _increaseTotalPool(
            openBorrowAmount
        );

        emit LiquidateNFTEvent(
            _nftAddress,
            currentLoans[_nftAddress][_tokenId].tokenOwner,
            msg.sender,
            discountAmount,
            _tokenId,
            block.timestamp
        );

        // Delete loan
        delete currentLoans[_nftAddress][_tokenId];

        // Liquidator pays discount for NFT
        _safeTransferFrom(
            poolToken,
            msg.sender,
            address(this),
            discountAmount
        );

        // Sending NFT to new owner
        _transferNFT(
            address(this),
            msg.sender,
            _nftAddress,
            _tokenId
        );

        // Sending fee + penalties from liquidation to multisig
        _safeTransfer(
            poolToken,
            multisig,
            discountAmount - openBorrowAmount
        );
    }

    /**
     * @dev After 9 days without payment or liquidation the multisig can take the nft token to auction on opensea.
     * Due to the signature nature of wyvern protocol and openseas use of it we cannot start an opensea listing directly from a contract.
     * Sending NFT to Multisig and changing loan owner to zero address.
     * This markes the loan as currently being auctioned externally.
     * This is a small point of centralization that is required to keep the contract functional in cases of bad debt,
     * and should only happen in rare cases.
    */
    function liquidateNFTMultisig(
        uint256 _tokenId,
        address _nftAddress
    )
        external
        onlyWorker
    {
        require(
            deadlineMultisig(
                _nftAddress,
                _tokenId
            ) == true,
            'LiquidPool: TOO_EARLY'
        );

        emit LiquidateNFTMultisigEvent(
            _nftAddress,
            currentLoans[_nftAddress][_tokenId].tokenOwner,
            multisig,
            _tokenId,
            block.timestamp
        );

        currentLoans[_nftAddress][_tokenId].tokenOwner = ZERO_ADDRESS;

        _transferNFT(
            address(this),
            multisig,
            _nftAddress,
            _tokenId
        );
    }

    /**
     * @dev pays back bad debt which accrued if any did accumulate. Can be called
     * by anyone since there is no downside in allowing public to payback baddebt.
    */
    function decreaseBadDebt(
        uint256 _amount
    )
        external
    {
        if (_amount == 0) revert("LiquidPool: AMOUNT_IS_ZERO");
        if (badDebt == 0) revert("LiquidPool: BAD_DEBT_IS_ZERO");

        uint256 amountToPayBack = _amount < badDebt
            ? _amount
            : badDebt;

        emit DecreaseBadDebt(
            badDebt,
            badDebt - amountToPayBack,
            amountToPayBack,
            block.timestamp
        );

        _increaseTotalPool(
            amountToPayBack
        );

        _decreaseBadDebt(
            amountToPayBack
        );

        _safeTransferFrom(
            poolToken,
            msg.sender,
            address(this),
            amountToPayBack
        );
    }

    /**
     * @dev returns funds from selling nft token externally
    */
    function returnFunds(
        uint256 _tokenId,
        uint256 _amount,
        address _nftAddress
    )
        external
        onlyWorker
        updateBorrowRate
    {
        _preparationPool();

        Loan memory loanData = currentLoans[_nftAddress][_tokenId];

        require(
            loanData.tokenOwner == ZERO_ADDRESS,
            'LiquidPool: LOAN_NOT_LIQUIDATED'
        );

        uint256 openAmount = getTokensFromBorrowShareAmount(
            loanData.borrowShares
        );

        // deleting all open shares as well as open
        // pseudo- and totalBorrow amount
        _decreaseTotalBorrowShares(
            loanData.borrowShares
        );

        _decreaseTotalTokensDue(
            openAmount
        );

        // Dealing how lending side gets updated.
        // Differs between those two cases
        bool badDebtCondition = openAmount > _amount;

        uint256 badDebtAmount = badDebtCondition
            ? openAmount - _amount
            : 0;

        uint256 transferAmount = badDebtCondition
            ? _badDebt(_amount, openAmount)
            : _payAllFundsBack(openAmount);

        emit FundingThePool(
            _nftAddress,
            _tokenId,
            transferAmount,
            badDebtAmount,
            block.timestamp
        );

        delete currentLoans[_nftAddress][_tokenId];

        // Paying back open funds from liquidation after selling NFT
        _safeTransferFrom(
            poolToken,
            msg.sender,
            address(this),
            transferAmount
        );
    }

    /**
     * @dev view function for returning the current apy of the system.
    */
    function getCurrentDepositAPY()
        public
        view
        returns (uint256)
    {
        return borrowRate
            * totalTokensDue
            / pseudoTotalTokensHeld;
    }

    function beginUpdateCollection(
        address _nftAddress,
        bytes32 _merkleRoot,
        string memory _ipfsURL
    )
        external
        onlyWorker
    {
        require(
            isExpandable || nftAddresses[_nftAddress],
            "LiquidPool: UPDATE_FORBIDDEN"
        );

        pendingCollections[_nftAddress] = Collection({
            unlockTime: block.timestamp + DEADLINE_DURATION,
            merkleRoot: _merkleRoot,
            ipfsUrl: _ipfsURL
        });

        emit UpdateStarted(
            block.timestamp + DEADLINE_DURATION,
            _merkleRoot,
            _ipfsURL,
            msg.sender
        );
    }

    function finishUpdateCollection(
        address _nftAddress
    )
        external
    {
        Collection memory collectionToAdd = pendingCollections[_nftAddress];
        uint256 unlockTime = collectionToAdd.unlockTime;

        require(
            _checkUnlockCondition(unlockTime) == true,
            "LiquidPool: TOO_EARLY"
        );

        bool newCollection;

        if (nftAddresses[_nftAddress] == false) {
            nftAddresses[_nftAddress] = true;
            newCollection = true;
        }

        merkleRoots[_nftAddress] = collectionToAdd.merkleRoot;
        merkleIPFSURLs[_nftAddress] = collectionToAdd.ipfsUrl;

        emit CollectionUpdated(
            _nftAddress,
            newCollection,
            merkleRoots[_nftAddress],
            merkleIPFSURLs[_nftAddress]
        );
    }

    /**
     * @dev
     * Worker can change the discount percentage for liqudation.
     * This results in a change of the overall liquidation fee which gets added on top the penalty amount.
     * Essentially this value is a factor which the merkletree price evaulation gets multiplied.
     */
    function updateDiscount(
        uint256 _percentage
    )
        external
        onlyWorker
    {
        require(
            _checkDiscountRangeConstraint(_percentage) == true,
            "LiquidPool: INVALID_RANGE"
        );

        require(
            _percentage < 100,
            "LiquidPool: INVALID_RANGE"
        );

        emit DiscountChanged(
            liquidationPercentage,
            _percentage
        );

        liquidationPercentage = _percentage;
    }

    /**
     * @dev Updates the usage fee for the system within a certain range.
     * Can only be called by worker address.
    */
    function updateFee(
        uint256 _newFee
    )
        external
        onlyWorker
    {
        require(
            fee >= MIN_FEE,
            "LiquidPool: FEE_TOO_LOW"
        );

        require(
            fee <= MAX_FEE,
            "LiquidPool: FEE_TOO_HIGH"
        );

        fee = _newFee;
    }

    /**
     * @dev
     * removes the ability to add collections to a global pool to decrease necessairy
     * trust levels
     */
    function revokeExpandability()
        onlyMultisig
        external
    {
        isExpandable = false;
    }
}