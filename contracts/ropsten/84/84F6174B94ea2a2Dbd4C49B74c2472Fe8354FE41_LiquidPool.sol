// SPDX-License-Identifier: WISE

pragma solidity ^0.8.13;

import "./PoolHelper.sol";
import "./AccessControl.sol";
import "./Babylonian.sol";

contract LiquidPool is PoolHelper, AccessControl {

    event CollectionAdded(
        address indexed collection
    );

    /**
     * @dev Only the factory address can call functions with this modifier
    */
    modifier onlyFromFactory() {
        require(
            msg.sender == FACTORY_ADDRESS,
            "LiquidPool: INVALID_FACTORY"
        );
        _;
    }

    /**
     * @dev Only the router address can call functions with this modifier
    */
    modifier onlyFromRouter() {
        require(
            msg.sender == ROUTER_ADDRESS,
            "LiquidPool: INVALID_ROUTER"
        );
        _;
    }

    /**
     * @dev Runs the LASA algorithm when someone interacts with the contract to obtain a new interest rate
    */
    modifier updateBorrowRate() {
        _;
        _updateUtilization();
        _newBorrowRate();

        if (_aboveThreshold() == true) {
            _scalingAlgorithm();
        }
    }

    modifier isValidNftAddress(address _address){
        require(
            nftAddresses[_address],
            "LIQUIDPOOL: Unsupported Collection"
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
        ERC20(
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
     * @param _maxTokensPerNft - maximum allowed loan value in units of poolToken
     * @param _multiplicationFactor - used for LASA interest rate scaling algorithm
     * @param _maxCollatFactor - percentage of the nft's value that can be borrowed
     * @param _merkleRoots - Roots of the merkle trees containing specific price data for nft traits
     * @param _ipfsURL - Ipfs file path containing the current merkle tree for nft token prices
     * @param _tokenName - Name of erc20 token issued by this contract to represent shares in pool
     * @param _tokenSymbol - Symbol of erc20 token issued by this contract to represent shares in pool
     */

    function initialize(
        address _poolToken,
        address[] memory _nftAddresses,
        address _multisig,
        uint256[] memory _maxTokensPerNft,
        uint256 _multiplicationFactor,  //Determine how quickly the interest rate changes with changes to utilization and resonanzFactor
        uint256 _maxCollatFactor,       //Maximal factor every NFT can be collateralized in this pool
        bytes32[] memory _merkleRoots,            //The merkleroot of a merkletree containing information about the amount to borrow for specific nfts in collection
        string[] memory _ipfsURL,
        string memory _tokenName,       //Name for erc20 representing shares of this pool
        string memory _tokenSymbol,      //Symbol for erc20 representing shares of this pool
        bool _isExpandable
    )
        external
        onlyFromFactory
    {

        for(uint64 i=0; i < _nftAddresses.length; i++){
            nftAddresses[_nftAddresses[i]] = true;
            tokensPerNfts[_nftAddresses[i]] = _maxTokensPerNft[i];
            merkleRoots[_nftAddresses[i]] = _merkleRoots[i];
            merkleIPFSURLs[_nftAddresses[i]] = _ipfsURL[i];
            emit CollectionAdded(_nftAddresses[i]);
        }

        isExpandable = _isExpandable;

        poolToken = _poolToken;
        multiplicativeFactor = _multiplicationFactor;
        maxCollatFactor = _maxCollatFactor;
        _name = _tokenName;
        _symbol = _tokenSymbol;

        //set multisig here because of factory cloning model
        _updateMultisig(_multisig);
        workers[_multisig] = true;
        // Initializing variables for scaling algorithm and borrow rate calculation.
        // all numbers are of order 1E18

        // Depending on the individuel multiplication factor of each asset!
        // dalculating lower bound for resonanz factor
        minResonanzFactor = PRECISION_FACTOR_E18
            / 2
            + Babylonian.sqrt(PRECISION_FACTOR_E36/4
                + _multiplicationFactor 
                    * PRECISION_FACTOR_E36
                    / UPPER_BOUND_MAX_RATE
            );

        // Calculating upper bound for resonanz factor
        maxResonanzFactor = PRECISION_FACTOR_E18
            / 2
            + Babylonian.sqrt(PRECISION_FACTOR_E36/4
                + _multiplicationFactor 
                    * PRECISION_FACTOR_E36
                    / LOWER_BOUND_MAX_RATE
            );

        // Calculating stepping size for algorithm
        deltaResonanzFactor = (maxResonanzFactor - minResonanzFactor)
            / NORM_FACTOR_SECONDS_IN_TWO_MONTH;

        // Setting start value as mean of min and max value
        resonanzFactor = (maxResonanzFactor + minResonanzFactor) / 2;

        // Initalize with 70%
        liquidationPercentage = 70;
    }

    /**
     * @dev
     * Multisig or worker can change the discount percentage for liqudation.
     * This results in a change of the overall liquidation fee which gets added on top the penalty amount.
     * Essentially this value is how much less a liquidator is able to buy the nft from the contract for
     */
    function changeDiscountPercLiqudandFee(
        uint256 _percentage
    )
        external
        onlyWorker
    {
        require(
            _percentage > (maxCollatFactor + 5e18) / PRECISION_FACTOR_E18,
            "LiquidPool: INVALID_RANGE"
        );

        require(
            _percentage < 100,
            "LiquidPool: INVALID_RANGE"
        );

        liquidationPercentage = _percentage;
    }

    /**
     * @dev Function permissioned to only be called from the router to deposit funds
     * Calls internal deposit funds function that does the real work.
     * Router makes sure that the _depositor variable is always the msg.sender to the router
     */
    function depositFundsRouter(
        uint256 _amount,
        address _depositor
    )
        external
        onlyFromRouter
    {
        _depositFunds(
            _amount,
            _depositor
        );
    }

    /**
     * @dev External depositFunds function to directly deposit funds bypassing the router
     * Require explicit approval of tokens for this pool. Calls internal deposit funds function.
     */
    function depositFunds(
        uint256 _amount
    )
        external
    {
        _depositFunds(
            _amount,
            msg.sender
        );

        _safeTransferFrom(
            poolToken,
            msg.sender,
            address(this),
            _amount
        );
    }

    /**
     * @dev Add funds to the contract for other users to borrow.
     * Upon deposit user will receive internal shares representing their share of the pool
     * These shares can be tokenized later into an erc20 denomination if the user desires after a certain amount of time.
     * Share system keeps track of a users percentage of the tokens in the pool, so it grows as interest added.
     */
    function _depositFunds(
        uint256 _amount,
        address _depositor
    )
        internal
        updateBorrowRate
    {
        // Checking of tokens have falsely been send directly to the contract
        // and update for latest interest gained
        _preparationPool();

        // local variables save gas over going function calls and storage accesses
        uint256 currentPoolTokens = pseudoTotalTokensHeld;
        uint256 currentPoolShares = totalSupply()
            + totalInternalShares;

        if (currentPoolShares == 0 || currentPoolTokens == 0) {

            _increaseInternalShares(
                _amount,
                _depositor
            );

            _increaseTotalInternalShares(
                _amount
            );
        }
            else
        {
            uint256 newShares = _calculateDepositShares(
                _amount,
                currentPoolTokens,
                currentPoolShares
            );

            _increaseInternalShares(
                newShares,
                _depositor
            );

            _increaseTotalInternalShares(
                newShares
            );
        }

        _increaseTotalPool(
            _amount
        );

        _increasePseudoTotalTokens(
            _amount
        );

        //flashloan protection
        lastDepositTime[_depositor] = block.timestamp;
    }

    /**
     * @dev This function allows users to convert internal shares into tokenized shares for the pool.
     * 3 hours must have passed since the user's last deposit for this action to occur.
     * Tokenized shares function the same as internal shares, but are explicitly represented by an erc20 token and tradable.
     */
    function tokenizeShares(
        uint256 _shares
    )
        external
    {
        require(
            // convert this to a view and call it here
            lastDepositTime[msg.sender] + THREE_HOURS <= block.timestamp,
            "LiquidPool: TOO_SOON_AFTER_DEPOSIT"
        );

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

    function withdrawFundsSmart(
        uint256 _shares
    )
        external
    {
        _withdrawFundsSmart(
            _shares,
            msg.sender
        );
    }

    function withdrawFundsSmartRouter(
        uint256 _shares,
        address _user
    )
        external
        onlyFromRouter
    {
        _withdrawFundsSmart(
            _shares,
            _user
        );
    }

    function withdrawFundsInternalShares(
        uint256 _shares
    )
        external
    {
        _withdrawFundsInternalShares(
            _shares,
            msg.sender
        );
    }

    function withdrawFundsInternalSharesRouter(
        uint256 _shares,
        address _user
    )
        external
        onlyFromRouter
    {
        _withdrawFundsInternalShares(
            _shares,
            _user
        );
    }

    function withdrawFundsTokenShares(
        uint256 _shares
    )
        external
    {
        _withdrawFundsTokenShares(
            _shares,
            msg.sender
        );
    }

    function withdrawFundsTokenSharesRouter(
        uint256 _shares,
        address _user
    )
        external
        onlyFromRouter
    {
        _withdrawFundsTokenShares(
            _shares,
            _user
        );
    }

    /**
     * @dev Since we have both internal and tokenized shares, they need to be withdrawn differently
     * This function will smartly withdraw from internal shares first, then take from tokenized shares the remainder requested
     */
    function _withdrawFundsSmart(
        uint256 _shares,
        address _user
    )
        internal
    {
        uint256 userInternalShares = internalShares[_user];

        if (userInternalShares >= _shares) {
            _withdrawFundsInternalShares(
                _shares,
                _user
            );

            return;
        }

        _withdrawFundsInternalShares(
            userInternalShares,
            _user
        );

        _withdrawFundsTokenShares(
            _shares - userInternalShares,
            _user
        );
    }

    /**
     * @dev Withdraw funds from pool but only from internal shares, not token shares.
     * Do a check to make sure user has waited 3 hours since depositing tokens, to prevent people from front running
     * big payments as easily.
     */
    function _withdrawFundsInternalShares(
        uint256 _shares,
        address _user
    )
        internal
        updateBorrowRate
    {

        require( // convert to a view
            lastDepositTime[_user] + THREE_HOURS <= block.timestamp,
            "LiquidPool: TOO_SOON_AFTER_DEPOSIT"
        );

        // checking of tokane have falsely been send directly to the contract
        // and update for latest interest gained
        _preparationPool();

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
    }

    /**
     * @dev Withdraw funds from pool but only from token shares, not internal shares.
     * Burns erc20 share tokens and transfers the deposit tokens to the user.
     */
    function _withdrawFundsTokenShares(
        uint256 _shares,
        address _user
    )
        internal
        updateBorrowRate
    {
        // checking of tokens have falsely been send directly to the contract
        // and update for latest interest gained
        _preparationPool();

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
    }

    /**
     * @dev Take out a loan against an nft. This is a wrapper external function that calls the internal borrow funds function.
     * Only the router can call this function. Depositor will always be the msg.sender of the router.
     */
    function borrowFundsRouter(
        uint256 _tokenAmountToBorrow,
        uint256 _timeIncrease,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata merkleProof,
        uint256 merklePrice,
        address _borrower,
        address _nftAddress
    )
        external
        onlyFromRouter
    {
        uint256[] memory args = new uint256[](5);

        args[0] = _tokenAmountToBorrow;
        args[1] = _timeIncrease;
        args[2] = _tokenId;
        args[3] = _index;
        args[4] = merklePrice;

        _borrowFunds(
            args,
            merkleProof,
            _borrower,
            _nftAddress
        );
    }

    /**
     * @dev External function for taking out a loan against an nft. Calls internal borrow funds.
     * Transfers nft from user before proceeding. Approval for for nft token to this specific pool is needed.
     */
    function borrowFunds(
        uint256 _tokenAmountToBorrow,
        uint256 _timeIncrease,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata merkleProof,
        uint256 merklePrice,
        address _nftAddress
    )
        external
    {
        _transferFromNFT(
            msg.sender,
            address(this),
            _nftAddress,
            _tokenId
        );

        uint256[] memory args = new uint256[](5);

        args[0] = _tokenAmountToBorrow;
        args[1] = _timeIncrease;
        args[2] = _tokenId;
        args[3] = _index;
        args[4] = merklePrice;

        _borrowFunds(
            args,
            merkleProof,
            msg.sender,
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
     * collateralization value. (_timeIncrease is the number of seconds you want to increase by, capped at 35 days.
     * Can use a merkle tree structure to verify price of individual tokens and traits of the nft set
     * If merkle root is not initialized for the set then the tokensPerNft variable is used to determine loan amount
     *
     * This function uses a parameters array instead of explicitly named local variables to avoid stack too deep errors.
     * The parameters in the parameters array are detailed below
     *
     *         uint256 _tokenAmountToBorrow, -> params[0]      --How many ERC20 tokens desired for the loan
     *         uint256 _timeIncrease,  -> params[1]            --How many seconds the user would like to request until their next payment is due
     *         uint256 _tokenId, -> params[2]                  --Identifier of nft token to borrow against
     *         uint256 _index, -> params[3]                    --Index of nft token in merkle tree
     *         uint256 _merklePrice, -> params[4]              --Price token of token in merkle tree. Must be correct in order for merkle tree to be verified
     */
    function _borrowFunds(
        uint256[] memory params,
        bytes32[] calldata merkleProof,
        address _borrower,
        address _nftAddress
    )
        internal
        updateBorrowRate
        isValidNftAddress(_nftAddress)
    {
        _preparationPool();

        params[1] = cutoffAtMaximumTimeIncrease( // _timeIncrease
            params[1] // _timeIncrease
        );

        {
        // Should we add a factor of 1.1 here to give people a 10% margin between liquidation if they are on the edge?
        // Markov mean is relative to 1 year so divide by seconds
        uint256 predictedFutureLoanValue = predictFutureLoanValue(
            params[0], // _tokenAmountToBorrow
            params[1] // _timeIncrease
        );

        require(
            predictedFutureLoanValue <= getMaximumBorrow(
                _nftAddress,
                params[2],  // _tokenId
                params[3], // _index
                merkleProof,
                params[4] // _merklePrice
            ),
            "LiquidPool: LOAN_TOO_LARGE"
        );
        }

        uint256 borrowSharesGained = getBorrowShareAmount(
            params[0] // _tokenAmountToBorrow
        );

        _increaseTotalBorrowShares(
            borrowSharesGained
        );

        _increaseTotalTokensDue(
            params[0] // _tokenAmountToBorrow
        );

        _decreaseTotalPool(
            params[0] // _tokenAmountToBorrow
        );

        _updateLoan(
            _nftAddress,
            _borrower,
            params[2], // _tokenId
            params[1], // _timeIncrease
            borrowSharesGained,
            params[0], // _tokenAmountToBorrow
            block.timestamp
        );

        _safeTransfer(
            poolToken,
            _borrower,
            params[0] // _tokenAmountToBorrow
        );
    }


    function paybackFundsRouter(
        uint256 _principalPayoff,
        uint256 _timeIncrease,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata merkleProof,
        uint256 _merklePrice,
        address _nftAddress
    )
        external
        onlyFromRouter
        returns (uint256, uint256)
    {
        uint256[] memory args = new uint256[](5);

        args[0] = _principalPayoff;
        args[1] = _timeIncrease;
        args[2] = _tokenId;
        args[3] = _index;
        args[4] = _merklePrice;

        return _paybackFunds(
            args,
            merkleProof,
            _nftAddress
        );
    }


    function paybackFunds(
        uint256 _principalPayoff,
        uint256 _timeIncrease,
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata merkleProof,
        uint256 _merklePrice,
        address _nftAddress
    )
        external
    {
        uint256[] memory args = new uint256[](5);

        args[0] = _principalPayoff;
        args[1] = _timeIncrease;
        args[2] = _tokenId;
        args[3] = _index;
        args[4] = _merklePrice;

        (uint256 totalPayment, uint256 feeAmount) = _paybackFunds(
            args,
            merkleProof,
            _nftAddress
        );

        _safeTransferFrom(
            poolToken,
            msg.sender,
            address(this),
            totalPayment
        );

        _safeTransferFrom(
            poolToken,
            msg.sender,
            multisig,
            feeAmount
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
     *   uint256 _principalPayoff,   -> args[0]
     *   uint256 _timeIncrease,      -> args[1]
     *   uint256 _tokenId,           -> args[2]
     *   uint256 _index,             -> args[3]
     *   uint256 _merklePrice,        -> args[4]
     */
    function _paybackFunds(
        uint256[] memory args,
        bytes32[] calldata merkleProof,
        address _nftAddress
    )
        internal
        updateBorrowRate
        isValidNftAddress(_nftAddress)
        returns(uint256 totalPayment, uint256 feeAmount)
    {
        _preparationPool();

        uint256 borrowSharesToDestroy;
        uint256 penaltyAmount;

        {
        Loan memory loanData = currentLoans[_nftAddress][args[2]]; // _tokenId

        args[1] = cutoffAtMaximumTimeIncrease( // _timeIncrease
            args[1] // _timeIncrease
        );

        {
        uint256 currentLoanValue = getTokensFromBorrowShareAmount(loanData.borrowShares);

        if (block.timestamp > loanData.nextPaymentDueTime) {
            penaltyAmount = _getPenaltyAmount(
                currentLoanValue,
                (block.timestamp - loanData.nextPaymentDueTime) / SECONDS_IN_DAY
            );
        }

        feeAmount = (currentLoanValue - loanData.principalTokens)
            * fee
            / PRECISION_FACTOR_E20;

        totalPayment = args[0] // _principalPayoff
            + currentLoanValue
            - loanData.principalTokens;


        borrowSharesToDestroy = getBorrowShareAmount(
            totalPayment
        );

        if (borrowSharesToDestroy >= loanData.borrowShares) {
            _endloan(
                args[2], // _tokenId
                loanData,
                penaltyAmount,
                _nftAddress
            );

            return (currentLoanValue + penaltyAmount, feeAmount);

        }
        }

        //Ended review here

        require(
            predictFutureLoanValue(
                loanData.principalTokens - args[0], // _principalPayoff
                args[1] // _timeIncrease
            )
            <= getMaximumBorrow(
                _nftAddress,
                args[2], // _tokenId
                args[3], // _index
                merkleProof,
                args[4] // _merklePrice
            ),
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
            args[2], // _tokenId
            args[1], // _timeIncrease
            borrowSharesToDestroy,
            args[0], // _principalPayoff
            block.timestamp
        );

        return (totalPayment + penaltyAmount, feeAmount);

    }

    /**
     * @dev Liquidations of loans are allowed when a loan has no payment made for 7 days after their deadline.
     * These monthly regular payments help to keep liquid tokens flowing through the contract.
     * Handles the liquidation of a NFT loan with directly buying the NFT from the
     * liquidator. Liquidator gets the NFT for a discount price which is the sum
     * of the current borrow amount + penalties + liquidation fee.
     * Ideally this amount should be less as the actual NFT value so ppl
     * are incentivized to liquidate. User needs the token into her/his wallet.
     * After a period of two days the Multisig-Wallet can get the NFT with another function.
    */
    // Handling the liqudation of a NFT loan with directly buying the NFT from the
    // liquidator. Liquidator gets the NFT for a discount price which is the sum
    // of the current borrow amount + penalties + liquidation fee.
    // Ideally this amount should be less as the actual NFT value so ppl
    // are incentivized to liquidate. User needs the token into her/his wallet.
    // After a periode of two days the Multisig-Wallet can get the NFT with another function
    function liquidateNFT(
        uint256 _tokenId,
        uint256 _index,
        bytes32[] calldata merkleProof,
        uint256 merklePrice,
        address _nftAddress
    )
        external
        updateBorrowRate
    {

        require(
            missedDeadline(_nftAddress, _tokenId) == true,
            'LiquidPool: TOO_EARLY'
        );

        _preparationPool();

        Loan memory loanData = currentLoans[_nftAddress][_tokenId];

        uint256 openBorrowAmount = getTokensFromBorrowShareAmount(
            loanData.borrowShares
        );

        uint256 discountAmount = getLiquidationAmounts(
            getNftCollateralValue(
                _nftAddress,
                _tokenId,
                _index,
                merkleProof,
                merklePrice
            ),
            loanData.nextPaymentDueTime
        );

        require(
            discountAmount >= openBorrowAmount,
            "LIQUIDPOOL: Discount Too Large"
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
            deadlineMultisig(_nftAddress, _tokenId) == true,
            'LiquidPool: TOO_EARLY'
        );

        currentLoans[_nftAddress][_tokenId].tokenOwner = ZERO_ADDRESS;

        // Sending NFT to multisig
        _transferNFT(
            address(this),
            multisig,
            _nftAddress,
            _tokenId
        );
    }

    /**
     * @dev Multisig returns funds from selling nft token externally, and contract update state variables.
    */
    function putFundsBackFromSellingNFT(
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

        // dealing how lending side gets updated. Differs
        // between those two cases
        uint256 transfereAmount = openAmount > _amount
            ? _badDebt(_amount, openAmount)
            : _payAllFundsBack(openAmount);

        delete currentLoans[_nftAddress][_tokenId];

        // Paying back open funds from liquidation after selling NFT
        _safeTransferFrom(
            poolToken,
            msg.sender,
            address(this),
            transfereAmount
        );
    }

    /**
     * @dev View function for returning the current apy of the system.
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
        uint256 _tokenPerNft,
        bytes32 _merkleRoot,
        string memory _ipfsURL
    )
        external
        onlyWorker
    {

        //Pool must either be expandable or collection must already be allowed in this pool
        require(
            isExpandable || nftAddresses[_nftAddress],
            "LIQUIDPOOL: Update Forbidden"
        );

        pendingCollections[_nftAddress] = Collection({
            unlockTime : block.timestamp + DEADLINE_TIME,
            maxBorrowTokens : _tokenPerNft,
            merkleRoot: _merkleRoot,
            ipfsUrl : _ipfsURL
        });
    }

    function finishUpdateCollection(
        address _nftAddress
    )
        external
    {
        Collection memory collectionToAdd = pendingCollections[_nftAddress];

        //Check unlock time is not uninitialized, or anyone could essentially add collections with bad data
        require(
            block.timestamp > collectionToAdd.unlockTime && collectionToAdd.unlockTime != 0,
            "LiquidPool: TOO_EARLY"
        );

        if(!nftAddresses[_nftAddress]){
            nftAddresses[_nftAddress] = true;
            emit CollectionAdded(_nftAddress);
        }
        tokensPerNfts[_nftAddress] = collectionToAdd.maxBorrowTokens;
        merkleRoots[_nftAddress] = collectionToAdd.merkleRoot;
        merkleIPFSURLs[_nftAddress] = collectionToAdd.ipfsUrl;

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
}