// SPDX-License-Identifier: WISE

pragma solidity =0.8.15;

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
        uint8 _tokenDecimals,
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
        decimals = _tokenDecimals;

        _updateMultisig(
            _multisig
        );

        workers[_multisig] = true;

        // Calculating lower bound for resonance factor
        minResonaceFactor = PRECISION_FACTOR_E18
            / 2
            + Babylonian.sqrt(PRECISION_FACTOR_E36 / 4
                + _multiplicationFactor
                    * PRECISION_FACTOR_E36
                    / UPPER_BOUND_MAX_RATE
            );

        // Calculating upper bound for resonance factor
        maxResonaceFactor = PRECISION_FACTOR_E18
            / 2
            + Babylonian.sqrt(PRECISION_FACTOR_E36 / 4
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
        feeDestinationAddress = multisig;
        fee = 20
            * PRECISION_FACTOR_E18
            / ONE_HUNDRED;
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
            uint256 predictedFutureLoanValue = predictFutureLoanValue(
                _borrowAmount
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
                        loanData.borrowShares,
                        loanData.tokenOwner,
                        _tokenId,
                        penaltyAmount,
                        _nftAddress
                    );

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
                    loanData.principalTokens - _principalPayoff
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
            getBorrowShareAmount(
                transferAmount
            ),
            _principalPayoff
        );

        emit FundsReturned(
            _nftAddress,
            currentLoans[_nftAddress][_tokenId].tokenOwner,
            transferAmount,
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

        _safeTransferFrom(
            poolToken,
            msg.sender,
            address(this),
            discountAmount
        );

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
            * fee
            * totalTokensDue
            / pseudoTotalTokensHeld
            / PRECISION_FACTOR_E18;
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

    /**  @dev
     *  Fixes in the fee destination forever
     */
    function lockCurrentFeeDestination()
        external
        onlyMultisig
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

    /**
     * @dev
     * removes accidentally sent tokens which are not the poolToken to multisig
     */
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

// SPDX-License-Identifier: --WISE---

pragma solidity =0.8.15;

contract PoolShareToken {

    string public name;
    string public symbol;

    uint8 public decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint) public nonces;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(
        address _account
    )
        public
        view
        returns (uint256)
    {
        return _balances[_account];
    }

    function transfer(
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool)
    {
        _transfer(
            msg.sender,
            _recipient,
            _amount
        );

        return true;
    }

    function allowance(
        address _owner,
        address _spender
    )
        external
        view
        returns (uint256)
    {
        return _allowances[_owner][_spender];
    }

    function approve(
        address _spender,
        uint256 _amount
    )
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            _spender,
            _amount
        );

        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        public
        returns (bool)
    {
        _approve(
            _sender,
            msg.sender,
            _allowances[_sender][msg.sender] - _amount
        );

        _transfer(
            _sender,
            _recipient,
            _amount
        );

        return true;
    }

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
    {
        require(
            _deadline >= block.timestamp,
            "Token: PERMIT_CALL_EXPIRED"
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        _owner,
                        _spender,
                        _value,
                        nonces[_owner]++,
                        _deadline
                    )
                )
            )
        );

        address recoveredAddress = ecrecover(
            digest,
            _v,
            _r,
            _s
        );

        require(
            recoveredAddress != address(0) &&
            recoveredAddress == _owner,
            "PoolToken: INVALID_SIGNATURE"
        );

        _approve(
            _owner,
            _spender,
            _value
        );
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        internal
    {
        _balances[_sender] =
        _balances[_sender] - _amount;

        _balances[_recipient] =
        _balances[_recipient] + _amount;

        emit Transfer(
            _sender,
            _recipient,
            _amount
        );
    }

    function _mint(
        address _recipient,
        uint256 _amount
    )
        internal
    {
        _totalSupply =
        _totalSupply + _amount;

        unchecked {
            _balances[_recipient] =
            _balances[_recipient] + _amount;
        }

        emit Transfer(
            address(0),
            _recipient,
            _amount
        );
    }

    function _burn(
        address _account,
        uint256 _amount
    )
        internal
    {
        _balances[_account] =
        _balances[_account] - _amount;

        unchecked {
            _totalSupply =
            _totalSupply - _amount;
        }

        emit Transfer(
            _account,
            address(0),
            _amount
        );
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    )
        internal
    {
        _allowances[_owner][_spender] = _amount;

        emit Approval(
            _owner,
            _spender,
            _amount
        );
    }
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.15;

import "./PoolBase.sol";
import "./PoolShareToken.sol";
import "./LiquidTransfer.sol";

contract PoolHelper is PoolBase, PoolShareToken, LiquidTransfer {

    /**
     * @dev Helper function to add specified value to pseudoTotalTokensHeld
     */
    function _increasePseudoTotalTokens(
        uint256 _amount
    )
        internal
    {
        pseudoTotalTokensHeld =
        pseudoTotalTokensHeld + _amount;
    }

    /**
     * @dev Helper function to determine if enough time has passed for an update
     * to a collection
     */
    function _checkUnlockCondition(
        uint256 _unlocktime
    )
        internal
        view
        returns (bool)
    {
        return block.timestamp > _unlocktime && _unlocktime > 0;
    }

    /**
     * @dev Helper function to check constraint on changing discount percentage
     */
    function _checkDiscountRangeConstraint(
        uint256 _percentage
    )
        internal
        view
        returns (bool)
    {
        return _percentage > (maxCollateralFactor + FIVE_PERCENT) / PRECISION_FACTOR_E16;
    }

    /**
     * @dev Helper function to subtract specified value from pseudoTotalTokensHeld
     */
    function _decreasePseudoTotalTokens(
        uint256 _amount
    )
        internal
    {
        pseudoTotalTokensHeld =
        pseudoTotalTokensHeld - _amount;
    }

    /**
     * @dev Helper function to add specified value to totalPool
     */
    function _increaseTotalPool(
        uint256 _amount
    )
        internal
    {
        totalPool =
        totalPool + _amount;
    }

    /**
     * @dev Helper function to subtract specified value from totalPool
     */
    function _decreaseTotalPool(
        uint256 _amount
    )
        internal
    {
        totalPool =
        totalPool - _amount;
    }

    /**
     * @dev Helper function to add specified value to totalInternalShares
     */
    function _increaseTotalInternalShares(
        uint256 _amount
    )
        internal
    {
        totalInternalShares =
        totalInternalShares + _amount;
    }

    /**
     * @dev Helper function to subtract specified value from totalInternalShares
     */
    function _decreaseTotalInternalShares(
        uint256 _amount
    )
        internal
    {
        totalInternalShares =
        totalInternalShares - _amount;
    }

    /**
     * @dev Helper function to add value to a specific users internal shares
     */
    function _increaseInternalShares(
        uint256 _amount,
        address _user
    )
        internal
    {
        internalShares[_user] =
        internalShares[_user] + _amount;
    }

    /**
     * @dev Helper function to subtract value a specific users internal shares
     */
    function _decreaseInternalShares(
        uint256 _amount,
        address _user
    )
        internal
    {
        internalShares[_user] =
        internalShares[_user] - _amount;
    }

    /**
     * @dev Helper function to add specified value to totalBorrowShares
     */
    function _increaseTotalBorrowShares(
        uint256 _amount
    )
        internal
    {
        totalBorrowShares =
        totalBorrowShares + _amount;
    }

    /**
     * @dev Helper function to subtract specified value from totalBorrowShares
     */
    function _decreaseTotalBorrowShares(
        uint256 _amount
    )
        internal
    {
        totalBorrowShares =
        totalBorrowShares - _amount;
    }

    /**
     * @dev Helper function to add specified value to totalTokensDue
     */
    function _increaseTotalTokensDue(
        uint256 _amount
    )
        internal
    {
        totalTokensDue =
        totalTokensDue + _amount;
    }

    /**
     * @dev Helper function to subtract specified value from totalTokensDue
     */
    function _decreaseTotalTokensDue(
        uint256 _amount
    )
        internal
    {
        totalTokensDue =
        totalTokensDue - _amount;
    }

    /**
     * @dev Pure function that calculates how many borrow shares a specified amount of tokens are worth
     * Given the current number of shares and tokens in the pool.
     */
    function _calculateDepositShares(
        uint256 _amount,
        uint256 _currentPoolTokens,
        uint256 _currentPoolShares
    )
        internal
        pure
        returns (uint256)
    {
        return _amount
            * _currentPoolShares
            / _currentPoolTokens;
    }

    /**
     * @dev function for helping router emit events with lessgas cost
     */
    function loanOwner(
        address _nftAddress,
        uint256 _tokenID
    )
        external
        view
        returns (address)
    {
        return currentLoans[_nftAddress][_tokenID].tokenOwner;
    }

    /**
     * @dev function for UI if user wants x amount in tokens to withdraw thus
     * calculates approriate shares to withdraw (in total including tokenized)
     */
    function calculateDepositShares(
        uint256 _amount
    )
        external
        view
        returns (uint256)
    {
        return _amount
            * getCurrentPoolShares()
            / pseudoTotalTokensHeld;
    }

    /**
     * @dev calculates the sum of tokenized and internal shares
     *
     */
    function getCurrentPoolShares()
        public
        view
        returns (uint256)
    {
        return totalInternalShares + totalSupply();
    }

    /**
     * @dev Function to calculate how many tokens a specified amount of deposits shares is worth
     * Considers both internal and token shares in this calculation.
     */
    function calculateWithdrawAmount(
        uint256 _shares
    )
        public
        view
        returns (uint256)
    {
        return _shares
            * pseudoTotalTokensHeld
            / getCurrentPoolShares();
    }

    /**
     * @dev this functions is for helping UI
     */
    function maximumWithdrawableAmountByUser(
        address _user
    )
        external
        view
        returns (
            uint256 returnValue,
            uint256 withdrawAmount
        )
    {
        withdrawAmount = calculateWithdrawAmount(
            internalShares[_user]
        );

        returnValue = withdrawAmount >= totalPool
            ? totalPool
            : withdrawAmount;
    }

    /**
     * @dev this functions looks if user have mistakenly sent token directly to the contract.
     * if this is the case it gets compared to the tracked amount totalPool and
     * increases about the difference
     */
    function _cleanUp()
        internal
    {
        uint256 totalBalance = _safeBalance(
            poolToken,
            address(this)
        );

        if (totalBalance > totalPool) {
            _safeTransfer(
                poolToken,
                multisig,
                totalBalance - totalPool
            );
        }
    }

    function cleanUp()
        external
    {
        _cleanUp();
    }

    /**
     * @dev calculates the usage of the pool depending on the totalPool amount of token
     * inside the pool compared to the pseudoTotal amount
     */
    function _updateUtilization()
        internal
    {
        utilization = PRECISION_FACTOR_E18 - (
            PRECISION_FACTOR_E18
            * totalPool
            / pseudoTotalTokensHeld
        );
    }

    /**
     * @dev calculates new markovMean (recurisive formula)
     */
    function _newMarkovMean(
        uint256 _amount
    )
        internal
    {
        uint256 newValue = _amount
            * (PRECISION_FACTOR_E18 - MARKOV_FRACTION)
            + (markovMean * MARKOV_FRACTION);

        markovMean = newValue
            / PRECISION_FACTOR_E18;
    }

    /**
     * @dev sets and calculates the new borrow rate
     */
    function _newBorrowRate()
        internal
    {
        borrowRate = multiplicativeFactor
            * utilization
            * PRECISION_FACTOR_E16
            / ((resonanceFactor - utilization) * resonanceFactor);

        _newMarkovMean(
            borrowRate
        );
    }

    /**
     * @dev checking time threshold for scaling algorithm. Time bettwen to iterations >= 3 hours
     */
    function _aboveThreshold()
        internal
        view
        returns (bool)
    {
        return block.timestamp - timeStampLastAlgorithm >= THREE_HOURS;
    }

    /**
     * @dev increases the pseudo total amounts for loaned and deposited token
     * interest generated is the same for both pools. borrower have to pay back the
     * new interest amount and lender get this same amount as rewards
     */
    function _updatePseudoTotalAmounts(
        uint256 _currentTime
    )
        internal
    {
        uint256 timeChange = _currentTime
            - timeStampLastInteraction;

        uint256 amountInterest = borrowRate
            * totalTokensDue
            * timeChange
            / ONE_YEAR_PRECISION_E18;

        uint256 amountFee = amountInterest
            * fee
            / PRECISION_FACTOR_E18;

        _increasePseudoTotalTokens(
            amountInterest
        );

        _increaseTotalTokensDue(
            amountInterest
        );

        uint256 feeShares = amountFee
            * totalInternalShares
            / (pseudoTotalTokensHeld - amountFee);

        _increaseInternalShares(
            feeShares,
            feeDestinationAddress
        );

        _increaseTotalInternalShares(
            feeShares
        );

        timeStampLastInteraction = _currentTime;
    }

    /**
     * @dev combining several steps which are necessary for the borrowrate mechanism
     * want latest pseudo amounts to translate shares and amount in the right way
     */
    function _preparationPool()
        internal
    {
        _cleanUp();

        _updatePseudoTotalAmounts(
            block.timestamp
        );
    }

    /**
     * @dev function that tries to maximize totalDepositShares of the pool. Reacting to negative and positive
     * feedback by changing the resonance factor of the pool. Method similar to one parameter monte carlo methods
     */
    function _scalingAlgorithm()
        internal
    {
        uint256 totalShares = getCurrentPoolShares();

        if (maxPoolShares <= totalShares) {

            _newMaxPoolShares(
                totalShares
            );

            _saveUp(
                totalShares
            );

            return;
        }

        _resonanceOutcome(totalShares) == true
            ? _resetResonanceFactor(totalShares)
            : _updateResonanceFactor(totalShares);

        _saveUp(
            totalShares
        );
    }

    function _saveUp(
        uint256 _totalShares
    )
        internal
    {
        previousValue = _totalShares;
        timeStampLastAlgorithm = block.timestamp;
    }

    /**
     * @dev sets the new max value in shares and saves the corresponding resonance factor.
     */
    function _newMaxPoolShares(
        uint256 _amount
    )
        internal
    {
        maxPoolShares = _amount;
        bestResonanceFactor = resonanceFactor;
    }

    /**
     * @dev returns bool to determine if resonance factor needs to be reset to last best value.
     */
    function _resonanceOutcome(
        uint256 _shareValue
    )
        internal
        view
        returns (bool)
    {
        return _shareValue < THRESHOLD_RESET_RESONANCE_FACTOR
            * maxPoolShares
            / ONE_HUNDRED;
    }

    /**
     * @dev resettets resonance factor to old best value when system evolves into too bad state.
     * sets current totalDepositShares amount to new maxPoolShares to exclude eternal loops and that
     * unorganic peaks do not set maxPoolShares forever
     */
    function _resetResonanceFactor(
        uint256 _value
    )
        internal
    {
        resonanceFactor = bestResonanceFactor;
        maxPoolShares = _value;

        _revertDirectionSteppingState();
    }

    /**
     * @dev reverts the flag for stepping direction from scaling algorithm
     */
    function _revertDirectionSteppingState()
        internal
    {
        increaseResonanceFactor = !increaseResonanceFactor;
    }

    /**
     * @dev stepping function decresing the resonance factor depending on the time past in the last
     * time interval. Checks if current resonance factor undergoes the min value. If this is the case
     * sets current value to minimal value
     */
    function _decreaseresonanceFactor()
        internal
    {
        uint256 delta = deltaResonaceFactor
            * (block.timestamp - timeStampLastAlgorithm);

        uint256 sub = resonanceFactor
            - delta;

        resonanceFactor = sub < minResonaceFactor
            ? minResonaceFactor
            : sub;
    }

    /**
     * @dev stepping function increasing the resonance factor depending on the time past in the last
     * time interval. checks if current resonance factor is bigger than max value. If this is the case
     * sets current value to maximal value
     */
    function _increaseResonanceFactor()
        internal
    {
        uint256 delta = deltaResonaceFactor
            * (block.timestamp - timeStampLastAlgorithm);

        uint256 sum = resonanceFactor
            + delta;

        resonanceFactor = sum > maxResonaceFactor
            ? maxResonaceFactor
            : sum;
    }

    /**
     * @dev does a revert stepping and swaps stepping state in opposite flag
     */
    function _reversedChangingResonanceFactor()
        internal
    {
        increaseResonanceFactor
            ? _decreaseresonanceFactor()
            : _increaseResonanceFactor();

        _revertDirectionSteppingState();
    }

    /**
     * @dev increasing or decresing resonance factor depending on flag value
    */
    function _changingResonanceFactor()
        internal
    {
        increaseResonanceFactor
            ? _increaseResonanceFactor()
            : _decreaseresonanceFactor();
    }

    /**
     * @dev function combining all possible stepping scenarios. Depending
     * how share values has changed compared to last time
     */
    function _updateResonanceFactor(
        uint256 _shareValues
    )
        internal
    {
        _shareValues < THRESHOLD_SWITCH_DIRECTION * previousValue / ONE_HUNDRED
            ? _reversedChangingResonanceFactor()
            : _changingResonanceFactor();
    }

    /**
     * @dev converts token amount to borrow share amount
     */
    function getBorrowShareAmount(
        uint256 _numTokensForLoan
    )
        public
        view
        returns (uint256)
    {
        return totalTokensDue == 0
            ? _numTokensForLoan
            : _numTokensForLoan * totalBorrowShares / totalTokensDue;
    }

    /**
     * @dev Math to convert borrow shares to tokens
     */
    function getTokensFromBorrowShareAmount(
        uint256 _numBorrowShares
    )
        public
        view
        returns (uint256)
    {
        return _numBorrowShares
            * totalTokensDue
            / totalBorrowShares;
    }

    /**
     * @dev Attempts transfer of all remaining balance of a user then returns nft to that user if successful.
     * Also update state variables appropriately for ending a loan.
     */
    function _endLoan(
        uint256 _borrowShares,
        address _tokenOwner,
        uint256 _tokenId,
        uint256 _penalty,
        address _nftAddress
    )
        internal
    {
        uint256 tokenPaymentAmount = getTokensFromBorrowShareAmount(
            _borrowShares
        );

        _decreaseTotalBorrowShares(
            _borrowShares
        );

        _decreaseTotalTokensDue(
            tokenPaymentAmount
        );

        _increaseTotalPool(
            tokenPaymentAmount + _penalty
        );

        _increasePseudoTotalTokens(
            _penalty
        );

        delete currentLoans[_nftAddress][_tokenId];

        _transferNFT(
            address(this),
            _tokenOwner,
            _nftAddress,
            _tokenId
        );
    }

    /**
     * @dev Calculate what we expect a loan's future value to be using our markovMean as the average interest rate
     * For more information look up markov chains
     */
    function predictFutureLoanValue(
        uint256 _tokenValue
    )
        public
        view
        returns (uint256)
    {
        return _tokenValue
            * TIME_BETWEEN_PAYMENTS
            * markovMean
            / ONE_YEAR_PRECISION_E18
            + _tokenValue;
    }

    /**
     * @dev Calculate penalties. .5% for first 4 days and 1% for each day after the 4th
     */
    function _getPenaltyAmount(
        uint256 _totalCollected,
        uint256 _lateDaysAmount
    )
        internal
        pure
        returns (uint256 penalty)
    {
        penalty = _totalCollected
            * _daysBase(_lateDaysAmount)
            / 200;
    }

    /**
     * @dev Helper for the days math of calcualte penalties.
     * Returns +1 per day before the 4th day and +2 for each day after the 4th day
     */
    function _daysBase(
        uint256 _daysAmount
    )
        internal
        pure
        returns (uint256 res)
    {
        // cap the maximum penalty amount to 10% after 7 days
        if (_daysAmount > 7) return 10;

        res = _daysAmount > 4
            ? _daysAmount * 2 - 4
            : _daysAmount;
    }

    /**
     * @dev Compute hashes to verify merkle proof for input price
     */
    function _verifyMerkleProof(
        bytes32[] memory _proof,
        bytes32 _root,
        bytes32 _leaf
    )
        internal
        pure
        returns (bool)
    {
        bytes32 computedHash = _leaf;

        for (uint256 i = 0; i < _proof.length; i++) {

            bytes32 proofElement = _proof[i];

            computedHash = computedHash <= proofElement
                ? keccak256(abi.encodePacked(computedHash, proofElement))
                : keccak256(abi.encodePacked(proofElement, computedHash));
        }

        return computedHash == _root;
    }

    function getMaximumBorrow(
        uint256 _merklePrice
    )
        public
        view
        returns (uint256)
    {
        return _merklePrice
            * maxCollateralFactor
            / PRECISION_FACTOR_E18;
    }

    function checkCollateralValue(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _merkleIndex,
        bytes32[] calldata _merkleProof,
        uint256 _merklePrice
    )
        external
        view
        returns (bool)
    {
        return _checkCollateralValue(
            _nftAddress,
            _tokenId,
            _merkleIndex,
            _merkleProof,
            _merklePrice
        );
    }

    function _checkCollateralValue(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] memory _merkleProof,
        uint256 _merklePrice
    )
        internal
        view
        returns (bool)
    {
        bytes32 node = keccak256(
            abi.encodePacked(
                _index,
                _tokenId,
                _merklePrice
            )
        );

        return _verifyMerkleProof(
            _merkleProof,
            merkleRoots[_nftAddress],
            node
        );
    }

    /**
     * @dev Check if a particular loan/borrower has not made a payment on their loan
     * within 7 days after the next due time. Used to determine if loans are eligible for liquidation.
     */
    function missedDeadline(
        address _nftAddress,
        uint256 _tokenId
    )
        public
        view
        returns (bool)
    {
        uint256 nextDueTime = getNextPaymentDueTime(
            _nftAddress,
            _tokenId
        );

        return
            nextDueTime > 0 &&
            nextDueTime + DEADLINE_DURATION < block.timestamp;
    }

    /**
     * @dev Check if the multisig liquidation deadline has passed.
     * This is 9 days currently, meaning that there are 2 days for a loan to be liquidated naturally
     * before the multisig can call the multisig liquidate function to auction nft externally
     */
    function deadlineMultisig(
        address _nftAddress,
        uint256 _tokenId
    )
        public
        view
        returns (bool)
    {
        uint256 nextDueTime = getNextPaymentDueTime(
            _nftAddress,
            _tokenId
        );

        return
            nextDueTime > 0 &&
            nextDueTime + DEADLINE_DURATION_MULTISIG < block.timestamp;
    }

    function getNextPaymentDueTime(
        address _nftAddress,
        uint256 _tokenId
    )
        public
        view
        returns (uint256)
    {
        return currentLoans[_nftAddress][_tokenId].nextPaymentDueTime;
    }

    /**
     * @dev Calculates how many tokens must be paid in order to liquidate a loan.
     * This is based on the maximum borrow allowed for the token, liquidation percentage, and how much in
     * penalties the loan has incurred
     */
    function getLiquidationAmounts(
        uint256 _merklePrice
    )
        public
        view
        returns (uint256)
    {
        return _merklePrice
            * liquidationPercentage
            / ONE_HUNDRED;
    }

    /**
     * @dev Handles state updates if a token does not sell for as much as its expected value
     * when the multisig auctions it externally. The difference in value must be accounted for.
     * This is unfortunately a loss for the system when this happens, but must be accounted for in
     * all current defi lending and borrowing protocols.
     */
    function _badDebt(
        uint256 _amount,
        uint256 _openAmount
    )
        internal
        returns (uint256)
    {
        _increaseTotalPool(
            _amount
        );

        _increaseBadDebt(
            _openAmount - _amount
        );

        return _amount;
    }

    function _increaseBadDebt(
        uint256 _amount
    )
        internal
    {
        badDebt =
        badDebt + _amount;
    }

    function _decreaseBadDebt(
        uint256 _amount
    )
        internal
    {
        badDebt =
        badDebt - _amount;
    }

    /**
     * @dev Update state for a normal payback from multisig. If there are extra tokens from the sale,
     * the multisig liquidation will exactly pay off the number of tokens that are due for that loan,
     * and keep the rest.
     */
    function _payAllFundsBack(
        uint256 _amount
    )
        internal
        returns (uint256)
    {
        _increaseTotalPool(
            _amount
        );

        return _amount;
    }

    /**
     * @dev Helper function that updates the mapping to struct of a loan for a user.
     * Since a few operations happen here, this is a useful obfuscation for readability and reuse.
     */
    function _updateLoan(
        address _nftAddress,
        address _borrower,
        uint256 _tokenId,
        uint256 _newBorrowShares,
        uint256 _newPrincipalTokens
    )
        internal
    {
        currentLoans[_nftAddress][_tokenId] = Loan({
            tokenOwner: _borrower,
            borrowShares: _newBorrowShares,
            principalTokens: _newPrincipalTokens,
            lastPaidTime: uint48(block.timestamp),
            nextPaymentDueTime: uint48(block.timestamp + TIME_BETWEEN_PAYMENTS)
        });
    }

    function _updateLoanPayback(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _borrowSharesToDestroy,
        uint256 _principalPayoff
    )
        internal
    {
        Loan memory loanData = currentLoans[_nftAddress][_tokenId];

        currentLoans[_nftAddress][_tokenId] = Loan({
            tokenOwner: loanData.tokenOwner,
            borrowShares: loanData.borrowShares - _borrowSharesToDestroy,
            principalTokens: loanData.principalTokens - _principalPayoff,
            lastPaidTime: uint48(block.timestamp),
            nextPaymentDueTime: uint48(block.timestamp + TIME_BETWEEN_PAYMENTS)
        });
    }
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.15;

import "./AccessControl.sol";

contract PoolBase is AccessControl {

    // ERC20 deposits and use for loans
    address public poolToken;

    // Address of fee destination
    address public feeDestinationAddress;

    // Maximal factor every NFT can be collateralized in this pool
    uint256 public maxCollateralFactor;

    // Discount percentage for the liquidator when buying the NFT
    uint256 public liquidationPercentage;

    // Current usage of the pool. 1E18 <=> 100 %
    uint256 public utilization;

    // Current actual number of token inside the contract
    uint256 public totalPool;

    // Current borrow rate of the pool;
    uint256 public borrowRate;

    // Current mean Markov value of the pool;
    uint256 public markovMean;

    // Bad debt amount in terms of poolToken correct decimals
    uint256 public badDebt;

    // Borrow rates variables
    // ----------------------

    // Pool position of borrow rate functions (divergent at x = r) 1E18 <=> 1 and r > 1E18.
    uint256 public resonanceFactor;

    // Stepping size
    uint256 public deltaResonaceFactor;

    // Global minimum value for the resonance factor
    uint256 public minResonaceFactor;

    // Global maximum value for the resonance factor
    uint256 public maxResonaceFactor;

    // Individual multiplication factor scaling the y-axes (static after deployment of pool)
    uint256 public multiplicativeFactor;

    // Tracks the last interaction with the pool
    uint256 public timeStampLastInteraction;

    // Scaling algorithm variables
    // --------------------------

    // Tracks the resonance factor which corsresponds to maxPoolShares
    uint256 public bestResonanceFactor;

    // Tracks the maximal value of shares the pool has ever reached
    uint256 public maxPoolShares;

    // Tracks the previous shares value during algorithm last round execution
    uint256 public previousValue;

    // Tracks time when scaling algorithm has been triggerd last time
    uint256 public timeStampLastAlgorithm;

    // Switch for stepping directions
    bool public increaseResonanceFactor;

    // Should it be possible to expand the pool
    bool public isExpandable;

    // Global constants
    // ----------------

    uint256 constant ONE_YEAR = 52 weeks;
    uint256 constant THREE_HOURS = 3 hours;
    uint256 constant FIVE_PERCENT = 0.05 ether;

    uint256 constant NORM_FACTOR_SECONDS_IN_TWO_MONTH = 8 weeks;

    uint256 constant PRECISION_FACTOR_E16 = 0.01 ether;
    uint256 constant PRECISION_FACTOR_E18 = 1 ether;
    uint256 constant PRECISION_FACTOR_E36 = 1 ether * 1 ether;

    uint256 constant ONE_YEAR_PRECISION_E18 = ONE_YEAR * 1 ether;

    uint256 constant ONE_HUNDRED = 100;
    uint256 constant SECONDS_IN_DAY = 86400;

    // Expecting user to payback the loan in 35 days (+5 days incurring penalty) or extend again
    uint256 constant public TIME_BETWEEN_PAYMENTS = 35 days;

    // Value determing weight of new value in markov chain (1% <=> 1E16)
    uint256 constant MARKOV_FRACTION = 0.02 ether;

    // Threshold for resetting resonance factor
    uint256 constant THRESHOLD_RESET_RESONANCE_FACTOR = 75;

    // Threshold for reverting stepping cirection
    uint256 constant THRESHOLD_SWITCH_DIRECTION = 90;

    // Absulute max value for borrow rate
    uint256 constant UPPER_BOUND_MAX_RATE = 5 ether;

    // Lower max value for borrow rate
    uint256 constant LOWER_BOUND_MAX_RATE = 1.5 ether;

    // Timeframe for normalization
    uint256 constant NORM_FACTOR = 8 weeks;

    // For reference to a zero address
    address constant ZERO_ADDRESS = address(0x0);

    // Fee in percentage, scaled by 1e18 (1% <=> 1E16) that will be taken on interest generated by the system for the wise ecosystem
    uint256 public fee;

    // This bool checks if the feeDestinationAddress should not be updateable anymore
    bool public permanentFeeDestination;

    // Minimum allowable fee in percentage (1% <=> 1E16) if the fee is changed in the future by the multisig/worker
    uint256 public constant MIN_FEE = 0.01 ether;

    // Maximum allowable fee in percentage (1% <=> 1E16) if the fee is changed in the future by the multisig/worker
    uint256 public constant MAX_FEE = 0.5 ether;

    // Tokens currently held by contract + all tokens out on loans
    uint256 public pseudoTotalTokensHeld;

    // Tokens currently being used in loans
    uint256 public totalTokensDue;

    // Shares representing tokens owed on a loan
    uint256 public totalBorrowShares;

    // Shares representing deposits that are not tokenized
    uint256 public totalInternalShares;

    // Minimum duration until user gets liquidated
    uint256 constant DEADLINE_DURATION = 7 days;

    // Minimum duration until the multisig/worker can manually grab the nft token for external auction
    uint256 constant DEADLINE_DURATION_MULTISIG = 9 days;

    struct Loan {
        uint48 nextPaymentDueTime;
        uint48 lastPaidTime;
        address tokenOwner;
        uint256 borrowShares;
        uint256 principalTokens;
    }

    struct Collection {
        uint256 unlockTime;
        bytes32 merkleRoot;
        string ipfsUrl;
    }

    mapping(address => bool) public nftAddresses;
    mapping(address => string) public merkleIPFSURLs;
    mapping(address => uint256) public internalShares;
    mapping(address => Collection) public pendingCollections;

    // NFT address => merkle root
    mapping(address => bytes32) public merkleRoots;

    // NFT address => tokenID => loan data
    mapping(address => mapping(uint256 => Loan)) public currentLoans;
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.15;

contract LiquidTransfer {

    /* @dev
    * Checks if contract is nonstandard, does transfer according to contract implementation
    */
    function _transferNFT(
        address _from,
        address _to,
        address _tokenAddress,
        uint256 _tokenId
    )
        internal
    {
        bytes memory data = abi.encodeWithSignature(
            'safeTransferFrom(address,address,uint256)',
            _from,
            _to,
            _tokenId
        );

        (bool success,) = address(_tokenAddress).call(
            data
        );

        require(
            success,
            'LiquidTransfer: NFT_TRANSFER_FAILED'
        );
    }

    /* @dev
    * Checks if contract is nonstandard, does transferFrom according to contract implementation
    */
    function _transferFromNFT(
        address _from,
        address _to,
        address _tokenAddress,
        uint256 _tokenId
    )
        internal
    {
        bytes memory data = abi.encodeWithSignature(
            'safeTransferFrom(address,address,uint256)',
            _from,
            _to,
            _tokenId
        );

        (bool success, bytes memory resultData) = address(_tokenAddress).call(
            data
        );

        require(
            success,
            string(resultData)
        );
    }

    /**
     * @dev encoding for transfer
     */
    bytes4 constant TRANSFER = bytes4(
        keccak256(
            bytes(
                'transfer(address,uint256)'
            )
        )
    );

    /**
     * @dev encoding for transferFrom
     */
    bytes4 constant TRANSFER_FROM = bytes4(
        keccak256(
            bytes(
                'transferFrom(address,address,uint256)'
            )
        )
    );

    /**
     * @dev encoding for balanceOf
     */
    bytes4 private constant BALANCE_OF = bytes4(
        keccak256(
            bytes(
                'balanceOf(address)'
            )
        )
    );

    /**
     * @dev does an erc20 transfer then check for success
     */
    function _safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER,
                _to,
                _value
            )
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))),
            'LiquidTransfer: TRANSFER_FAILED'
        );
    }

    /**
     * @dev does an erc20 transferFrom then check for success
     */
    function _safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER_FROM,
                _from,
                _to,
                _value
            )
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'LiquidTransfer: TRANSFER_FROM_FAILED'
        );
    }

    /**
     * @dev does an erc20 balanceOf then check for success
     */
    function _safeBalance(
        address _token,
        address _owner
    )
        internal
        returns (uint256)
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                BALANCE_OF,
                _owner
            )
        );

        if (success == false) return 0;

        return abi.decode(
            data,
            (uint256)
        );
    }

    event ERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes data
    );

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        returns (bytes4)
    {
        emit ERC721Received(
            _operator,
            _from,
            _tokenId,
            _data
        );

        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.15;

contract LiquidEvents {

    event CollectionAdded(
        address nftAddress
    );

    event FundsDeposited(
        address indexed user,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsWithdrawn(
        address indexed user,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsBorrowed(
        address indexed nftAddress,
        address indexed borrower,
        uint256 tokenID,
        uint256 amount,
        uint256 timestamp
    );

    event FundsReturned(
        address indexed nftAddress,
        address indexed tokenOwner,
        uint256 totalPayment,
        uint256 penaltyAmount,
        uint256 tokenID,
        uint256 timestamp
    );

    event UpdateStarted(
        uint256 unlockTime,
        bytes32 merkleRoot,
        string ipfsUrl,
        address indexed caller
    );

    event DiscountChanged(
        uint256 oldFactor,
        uint256 newFactor
    );

    event LiquidateNFT(
        address indexed nftAddress,
        address indexed previousOwner,
        address indexed liquidator,
        uint256 discountAmount,
        uint256 tokenID,
        uint256 timestamp
    );

    event LiquidateNFTMultisigEvent(
        address indexed nftAddress,
        address indexed previousOwner,
        address nftDestinationAddress,
        uint256 indexed tokenID,
        uint256 timestamp
    );

    event FundingThePool(
        address indexed nftAddress,
        uint256 indexed tokenID,
        uint256 amount,
        uint256 badDebt,
        uint256 timestamp
    );

    event DecreaseBadDebt(
        uint256 newBadDebt,
        uint256 paybackAmount,
        uint256 timestamp
    );

    event CollectionUpdated(
        address indexed nftAddress,
        bool indexed newCollection,
        bytes32 merkleRoot,
        string ipfsUrl,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.15;

library Babylonian {

    function sqrt(
        uint256 x
    )
        internal
        pure
        returns (uint256)
    {
        if (x == 0) return 0;

        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;

        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.15;

contract AccessControl {

    address public multisig;

    mapping(address => bool) public workers;

    event MultisigUpdated(
        address newMultisig
    );

    event WorkerAdded(
        address newWorker
    );

    event WorkerRemoved(
        address existingWorker
    );

    /**
     * @dev set the msg.sender as multisig, set msg.sender as worker
     */
    constructor() {
        workers[msg.sender] = true;
        _updateMultisig(
            msg.sender
        );
    }

    /**
     * @dev Revert if msg.sender if not multisig
     */
    modifier onlyMultisig() {
        require(
            msg.sender == multisig,
            "AccessControl: NOT_MULTISIG"
        );
        _;
    }

    /**
     * @dev require that sender is authorized in the worker mapping
     */
    modifier onlyWorker() {
        require(
            workers[msg.sender] == true,
            "AccessControl: NOT_WORKER"
        );
        _;
    }

    /**
     * @dev Transfer Multisig permission
     * Call internal function that does the work
     */
    function updateMultisig(
        address _newMultisig
    )
        external
        onlyMultisig
    {
        _updateMultisig(
            _newMultisig
        );
    }

    /**
     * @dev Internal function that handles the logic of updating the multisig
     */
    function _updateMultisig(
        address _newMultisig
    )
        internal
    {
        multisig = _newMultisig;

        emit MultisigUpdated(
            _newMultisig
        );
    }

    /**
     * @dev Add a worker address to the system. Set the bool for the worker to true
     * Only multisig can do this
     */
    function addWorker(
        address _newWorker
    )
        external
        onlyMultisig
    {
        workers[_newWorker] = true;

        emit WorkerAdded(
            _newWorker
        );
    }

    /**
    * @dev Remove a worker address from the system. Set the bool for the worker to false
     * Only multisig can do this
     */
    function removeWorker(
        address _worker
    )
        external
        onlyMultisig
    {
        workers[_worker] = false;

        emit WorkerRemoved(
            _worker
        );
    }
}