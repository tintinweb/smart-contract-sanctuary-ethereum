// SPDX-License-Identifier: WISE

pragma solidity =0.8.13;

import "./Babylonian.sol";
import "./PoolHelper.sol";
import "./LiquidEvents.sol";

contract LiquidPool is PoolHelper, LiquidEvents {

    address public immutable ROUTER_ADDRESS;
    address public immutable FACTORY_ADDRESS;

    /**
     * @dev Only the router address can call functions with this modifier
    */
    modifier onlyRouter() {
        require(
            msg.sender == ROUTER_ADDRESS,
            "LiquidPool: NOT_ROUTER"
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
    {
        FACTORY_ADDRESS = _factoryAddress;
        ROUTER_ADDRESS = _routerAddress;
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
        address _multisig,
        uint256 _multiplicationFactor,
        uint256 _maxCollateralFactor,
        address[] memory _nftAddresses,
        bytes32[] memory _merkleRoots,
        string[] memory _ipfsURL,
        string memory _tokenName,
        string memory _tokenSymbol,
        bool _isExpandable
    )
        external
    {
        require(
            msg.sender == FACTORY_ADDRESS,
            "LiquidPool: NOT_FACTORY"
        );

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

        // Calculating lower bound for resonance factor
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
        uint256 _depositAmount,
        address _depositor
    )
        external
        onlyRouter
        updateBorrowRate
        returns (uint256)
    {
        _preparationPool();

        uint256 currentPoolTokens = pseudoTotalTokensHeld;
        uint256 currentPoolShares = getCurrentPoolShares();

        uint256 shares = _calculateDepositShares(
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
        returns (uint256 withdrawAmount)
    {
        _preparationPool();

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
     * @dev Withdraw funds from pool but only from internal shares, not token shares.
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
     * @dev Withdraw funds from pool but only from token shares, not internal shares.
     * Burns erc20 share tokens and transfers the deposit tokens to the user.
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
     * @dev Take out a loan against an nft. This is a wrapper external function that calls the internal borrow funds function.
     * Only the router can call this function. Depositor will always be the msg.sender of the router.
     */
    function borrowFunds(
        uint256 _borrowAmount,
        uint256 _timeIncrease,
        uint256 _tokenId,
        uint256 _merkleIndex,
        bytes32[] calldata _merkleProof,
        uint256 _merklePrice,
        address _borrower,
        address _nftAddress
    )
        external
        onlyRouter
        updateBorrowRate
        knownCollection(_nftAddress)
    {
        _preparationPool();

        {
            require(
                _timeIncrease <= maximumTimeBetweenPayments,
                "LiquidPool: EXCEEDS_MAXIMUM_TIME"
            );

            uint256 predictedFutureLoanValue = predictFutureLoanValue(
                _borrowAmount,
                _timeIncrease
            );

            require(
                _checkCollateralValue(
                    _nftAddress,
                    _tokenId,
                    _merkleIndex,
                    _merkleProof,
                    _merklePrice
                ),
                "LiquidPool: INVALID_PROOF"
            );

            require(
                predictedFutureLoanValue <= getMaximumBorrow(_merklePrice),
                "LiquidPool: LOAN_TOO_LARGE"
            );
        }

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

        _updateLoan(
            _nftAddress,
            _borrower,
            _tokenId,
            _timeIncrease,
            getBorrowShareAmount(
                _borrowAmount
            ),
            _borrowAmount
        );

        _safeTransfer(
            poolToken,
            _borrower,
            _borrowAmount
        );

        emit FundsBorrowed(
            _nftAddress,
            _borrower,
            _tokenId,
            _timeIncrease,
            _borrowAmount,
            block.timestamp
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
     */
    function paybackFunds(
        uint256 _principalPayoff,
        uint256 _timeIncrease,
        uint256 _tokenId,
        uint256 _merkleIndex,
        bytes32[] calldata  _merkleProof,
        uint256 _merklePrice,
        address _nftAddress
    )
        external
        onlyRouter
        updateBorrowRate
        knownCollection(_nftAddress)
        returns (uint256 transferAmount)
    {
        _preparationPool();
        uint256 penaltyAmount;

        {
            Loan memory loanData = currentLoans[_nftAddress][_tokenId];
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

                transferAmount = _principalPayoff
                    + currentLoanValue
                    - loanData.principalTokens;

                if (getBorrowShareAmount(
                    transferAmount
                ) >= loanData.borrowShares) {

                    _endLoan(
                        loanData,
                        _tokenId,
                        penaltyAmount,
                        _nftAddress
                    );

                    // maybe emit event

                    return currentLoanValue + penaltyAmount;
                }
            }

            require(
                _checkCollateralValue(
                   _nftAddress,
                   _tokenId,
                   _merkleIndex,
                   _merkleProof,
                   _merklePrice
                ) == true,
                "LiquidPool: INVALID_PROOF"
            );

            require(
                predictFutureLoanValue(
                    loanData.principalTokens - _principalPayoff,
                    _timeIncrease
                ) <= getMaximumBorrow(_merklePrice),
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
                transferAmount + penaltyAmount
            );

            _increasePseudoTotalTokens(
                penaltyAmount
            );
        }

        _updateLoanPayback(
            _nftAddress,
            _tokenId,
            _timeIncrease,
            getBorrowShareAmount(
                transferAmount
            ),
            _principalPayoff
        );

        emit FundsReturned(
            _nftAddress,
            currentLoans[_nftAddress][_tokenId].tokenOwner,
            transferAmount,
            _timeIncrease,
            penaltyAmount,
            _tokenId,
            block.timestamp
        );

        return transferAmount + penaltyAmount;
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
        uint256 _merkleIndex,
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

        require(
            _checkCollateralValue(
                _nftAddress,
                _tokenId,
                _merkleIndex,
                _merkleProof,
                _merklePrice
            ),
            "LiquidPool: INVALID_PROOF"
        );

        _preparationPool();

        Loan memory loanData = currentLoans[_nftAddress][_tokenId];

        uint256 openBorrowAmount = getTokensFromBorrowShareAmount(
            loanData.borrowShares
        );

        uint256 discountAmount = getLiquidationAmounts(
            _merklePrice
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

        emit LiquidateNFT(
            _nftAddress,
            loanData.tokenOwner,
            msg.sender,
            discountAmount,
            _tokenId,
            block.timestamp
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
        address _nftAddress,
        address _nftDestinationAddress
    )
        external
        onlyWorker
    {
        require(
            deadlineMultisig(
                _nftAddress,
                _tokenId
            ) == true,
            "LiquidPool: TOO_EARLY"
        );

        emit LiquidateNFTMultisigEvent(
            _nftAddress,
            currentLoans[_nftAddress][_tokenId].tokenOwner,
            _nftDestinationAddress,
            _tokenId,
            block.timestamp
        );

        currentLoans[_nftAddress][_tokenId].tokenOwner = ZERO_ADDRESS;

        _transferNFT(
            address(this),
            _nftDestinationAddress,
            _nftAddress,
            _tokenId
        );
    }

    /**
     * @dev pays back bad debt which accrued if any did accumulate. Can be called
     * by anyone since there is no downside in allowing public to payback baddebt.
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
     * @dev returns funds from selling nft token externally
    */
    function returnFunds(
        uint256 _tokenId,
        uint256 _amountReturned,
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
            "LiquidPool: LOAN_NOT_LIQUIDATED"
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
        bool badDebtCondition = openAmount > _amountReturned;

        uint256 badDebtAmount = badDebtCondition
            ? openAmount - _amountReturned
            : 0;

        uint256 transferAmount = badDebtCondition
            ? _badDebt(_amountReturned, openAmount)
            : _payAllFundsBack(openAmount);

        delete currentLoans[_nftAddress][_tokenId];

        // Paying back open funds from liquidation after selling NFT
        _safeTransferFrom(
            poolToken,
            msg.sender,
            address(this),
            transferAmount
        );

        emit FundingThePool(
            _nftAddress,
            _tokenId,
            transferAmount,
            badDebtAmount,
            block.timestamp
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

    function beginAddCollection(
        address _nftAddress,
        bytes32 _merkleRoot,
        string memory _ipfsURL
    )
        external
        onlyWorker
    {
        require(
            isExpandable == true,
            "LiquidPool: NOT_EXPANDABLE"
        );

        _prepareUpdate(
            _nftAddress,
            _merkleRoot,
            _ipfsURL
        );
    }

    function beginUpdateCollection(
        address _nftAddress,
        bytes32 _merkleRoot,
        string memory _ipfsURL
    )
        external
        onlyWorker
        knownCollection(_nftAddress)
    {
        _prepareUpdate(
            _nftAddress,
            _merkleRoot,
            _ipfsURL
        );
    }

    function _prepareUpdate(
        address _nftAddress,
        bytes32 _merkleRoot,
        string memory _ipfsURL
    )
        internal
    {
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
            merkleIPFSURLs[_nftAddress],
            block.timestamp
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
        onlyMultisig
    {
        require(
            _checkDiscountRangeConstraint(_percentage) == true,
            "LiquidPool: INVALID_RANGE"
        );

        require(
            _percentage < ONE_HUNDRED,
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
        onlyMultisig
    {
        require(
            _newFee >= MIN_FEE,
            "LiquidPool: FEE_TOO_LOW"
        );

        require(
            _newFee <= MAX_FEE,
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

    function removeOddToken(
        address _tokenAddress
    )
        external
    {
        if (_tokenAddress == poolToken) {
            revert("LiquidPool: NOT_ALLOWED");
        }

        uint256 balance = _safeBalance(
            _tokenAddress,
            address(this)
        );

        _safeTransfer(
            _tokenAddress,
            multisig,
            balance
        );
    }
}