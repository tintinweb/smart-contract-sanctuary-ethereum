// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

import "./ILiquidInit.sol";

import "./LiquidPool.sol";
import "./LiquidRouter.sol";

/**
 * @dev LiquidFactory: Factory is responsible
 * for deploying new LiquidPools.
 */
contract PoolFactory {

    // Instance for router reference
    LiquidRouter immutable liquidRouter;

    // Liquid router that manages pools
    address public routerAddress;

    // Contract that all pools are cloned from
    address public defaultPoolTarget;

    // Address to manage protocol
    address public multisigAddress;

    // Simple useful counter
    uint256 public poolCount;

    /**
     * @dev Revert if msg.sender if not multisig
     */
    modifier onlyMultisig() {
        require(
            msg.sender == multisigAddress,
            "AccessControl: NOT_MULTISIG"
        );
        _;
    }

    /**
     * @dev Creates default pool target and sets router
     */
    constructor(
        address _chainLinkETH
    ) {
        multisigAddress = msg.sender;

        liquidRouter = new LiquidRouter(
            address(this),
            _chainLinkETH
        );

        routerAddress = address(
            liquidRouter
        );

        defaultPoolTarget = address(
            new LiquidPool()
        );
    }

    event PoolCreated(
        address indexed pool,
        address indexed token
    );

    /**
     * @dev Change the default target contract.
     * Only mutlisig address can do this.
     */
    function updateDefaultPoolTarget(
        address _newDefaultTarget
    )
        external
        onlyMultisig
    {
        defaultPoolTarget = _newDefaultTarget;
    }

    /**
     * @dev Creates a copy of bytecode of defaultPoolTarget with CREATE2 opcode
     * also calls initialise to set state variables
     */
    function createLiquidPool(
        address _poolTokenAddress,
        address _chainLinkFeedAddress,
        uint256 _multiplicationFactor,
        uint256 _maxCollateralFactor,
        address[] memory _nftAddresses,
        string memory _tokenName,
        string memory _tokenSymbol
    )
        external
        onlyMultisig
        returns (address poolAddress)
    {
        poolAddress = _generatePool(
            _poolTokenAddress
        );

        ILiquidInit(poolAddress).initialise(
            _poolTokenAddress,
            _chainLinkFeedAddress,
            _multiplicationFactor,
            _maxCollateralFactor,
            _nftAddresses,
            _tokenName,
            _tokenSymbol
        );

        liquidRouter.addLiquidPool(
            poolAddress
        );

        emit PoolCreated(
            poolAddress,
            _poolTokenAddress
        );
    }

    /**
     * @dev Deploys a pool with bytecode of defaultPoolTarget with CREATE2 opcode
     */
    function _generatePool(
        address _poolAddress
    )
        internal
        returns (address poolAddress)
    {
        bytes32 salt = keccak256(
            abi.encodePacked(
                poolCount++,
                _poolAddress
            )
        );

        bytes20 targetBytes = bytes20(
            defaultPoolTarget
        );

        assembly {

            let clone := mload(0x40)

            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )

            mstore(
                add(clone, 0x14),
                targetBytes
            )

            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            poolAddress := create2(
                0,
                clone,
                0x37,
                salt
            )
        }
    }

    /**
    * @dev Pre-compute what address a future pool will exist at.
     */
    function predictPoolAddress(
        uint256 _index,
        address _pool,
        address _factory,
        address _implementation
    )
        external
        pure
        returns (address predicted)
    {
        bytes32 salt = keccak256(
            abi.encodePacked(
                _index,
                _pool
            )
        );

        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, _implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, _factory))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

contract RouterEvents {

    event FundsDeposited(
        address indexed pool,
        address indexed user,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsWithdrawn(
        address indexed pool,
        address indexed user,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsBorrowed(
        address indexed pool,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 amount,
        address borrower,
        uint256 timestamp
    );

    event MoreFundsBorrowed(
        address indexed pool,
        address indexed nftAddress,
        address indexed borrower,
        uint256 tokenId,
        uint256 amount,
        uint256 timestamp
    );

    event FundsReturned(
        address indexed pool,
        address indexed nftAddress,
        address indexed tokenOwner,
        uint256 transferAmount,
        uint256 tokenId,
        uint256 timestamp
    );

    event LiquidPoolRegistered(
        address indexed pool,
        uint256 timestamp
    );

    event Liquidated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 discountAmount,
        address indexed liquidator,
        uint256 timestamp
    );

    event RootAnnounced(
        address caller,
        uint256 unlockTime,
        address indexed nftAddress,
        bytes32 indexed merkleRoot,
        string indexed ipfsAddress
    );

    event RootUpdated(
        address caller,
        uint256 updateTime,
        address indexed nftAddress,
        bytes32 indexed merkleRoot,
        string indexed ipfsAddress
    );

    event UpdateAnnounced(
        address caller,
        uint256 unlockTime,
        address indexed pool,
        address indexed nftAddress
    );

    event PoolUpdated(
        address caller,
        uint256 updateTime,
        address indexed pool,
        address indexed nftAddress
    );

    event FeeDestinatoinChanged(
        address indexed pool,
        address indexed newDestination
    );

    event ExpansionRevoked(
        address pool
    );
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

import "./PoolHelper.sol";

contract PoolViews is PoolHelper {

    /**
     * @dev External view function to get the current auction price of a NFT when
     * passing the correct merkle price from merkle tree.
     */
    function getCurrentAuctionPrice(
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external
        view
        returns (uint256)
    {
        return _getCurrentAuctionPrice(
            _nftAddress,
            _nftTokenId,
            _merkleIndex,
            _merklePrice,
            _merkleProof
        );
    }

    /**
     * @dev Merkleproof check if a claim for a tokenprice is correct
     */
    function checkCollateralValue(
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external
        view
        returns (bool)
    {
        return _checkCollateralValue(
            _nftAddress,
            _nftTokenId,
            _merkleIndex,
            _merklePrice,
            _merkleProof
        );
    }

    /**
     * @dev View function for returning
     * the current apy of the system.
     */
    function getCurrentDepositAPY()
        external
        view
        returns (uint256)
    {
        return borrowRate
            * (PRECISION_FACTOR_E18 - fee)
            * totalTokensDue
            / pseudoTotalTokensHeld
            / PRECISION_FACTOR_E18;
    }

    /**
     * @dev View function for UI for returning
     * borrowApy after utilization has been increased by borrowAmount
     */
    function getBorrowRateAfterBorrowAmount(
        uint256 _borrowAmount
    )
        external
        view
        returns (uint256)
    {
        if (_borrowAmount > totalPool) {
            revert("LiquidPool: AMOUNT_TOO_HIGH");
        }

        uint256 newUtilisation = PRECISION_FACTOR_E18 - (
            PRECISION_FACTOR_E18
            * (totalPool - _borrowAmount)
            / pseudoTotalTokensHeld
        );

        return multiplicativeFactor
            * newUtilisation
            * PRECISION_FACTOR_E18
            / ((pole - newUtilisation) * pole);
    }

    /**
     * @dev View function for UI for returning
     * the interest which would be payed back in case user triggers paybackfunds
     * deadline is the timestamp of when the transaction will be mined therfor
     * taking in delays between signing and mined transaction into account.
     */
    function getLoanInterest(
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _deadline
    )
        external
        view
        returns (uint256)
    {
        Loan memory loanData = currentLoans[_nftAddress][_nftTokenId];

        uint256 currentLoanValue = getTokensFromBorrowShares(
            loanData.borrowShares
        );

        uint256 timeChange = _deadline
            - block.timestamp;

        uint256 marginInterest = timeChange
            * borrowRate
            * totalTokensDue
            / ONE_YEAR_PRECISION_E18;

        return currentLoanValue
            + marginInterest
            - loanData.principalTokens;
    }

    /**
     * @dev Calculating help function
     * to factor in future predicted value check
     */
    function getMarkovAdjust(
        uint256 _timeAdjusted
    )
        public
        view
        returns (uint256)
    {
        return markovMean
            * _timeAdjusted
            + ONE_YEAR_PRECISION_E18;
    }

    /**
     * @dev UI help function to display borrowMax facotring in delay between
     * signing and mined transaction aswell as markov apy for
     * predicted future loan value check
     */
    function getBorrowMaximum(
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merklePrice,
        uint256 _deadline
    )
        external
        view
        returns (uint256)
    {
        uint256 maxBorrow = getMaximumBorrow(
            merklePriceInPoolToken(
                _merklePrice
            )
        );

        uint256 timeAdjusted = _deadline
            + TIME_BETWEEN_PAYMENTS
            - block.timestamp;

        address loanOwner = getLoanOwner(
            _nftAddress,
            _nftTokenId
        );

        if (loanOwner == EMPTY_ADDRESS) {
            return ONE_YEAR_PRECISION_E18
    	       * maxBorrow
    	       / getMarkovAdjust(timeAdjusted);
        }

        uint256 currentLoanValue = getTokensFromBorrowShares(
            getCurrentBorrowShares(
                _nftAddress,
                _nftTokenId
            )
        );

        if (currentLoanValue > maxBorrow) return 0;

        uint256 term1 = ONE_YEAR_PRECISION_E18
            * (maxBorrow - currentLoanValue);

        uint256 term2 = timeAdjusted
            * markovMean
            * currentLoanValue;

        if (term2 > term1) return 0;

        return (term1 - term2) / getMarkovAdjust(
            timeAdjusted
        );
    }


    /**
    * @dev UI help function to calculate min principal amount to be payed back
    * in order to extend loan facotring in delays in signing and mining aswell
    * as predictedFutureLoanValue and merkleprice
    */
    function getPrincipalPayBackMinimum(
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merklePrice,
        uint256 _deadline
    )
        external
        view
        returns (uint256)
    {
        uint256 timeAdjusted = _deadline
            + TIME_BETWEEN_PAYMENTS
            - block.timestamp;

        uint256 currentPrincipal = getPrincipalAmount(
            _nftAddress,
            _nftTokenId
        );

        uint256 maxBorrow = getMaximumBorrow(
            merklePriceInPoolToken(
                _merklePrice
            )
        );

        uint256 reductionTerm = maxBorrow
            * ONE_YEAR_PRECISION_E18
            / getMarkovAdjust(timeAdjusted);

        return
            currentPrincipal > reductionTerm ?
            currentPrincipal - reductionTerm : 0;
    }

    /**
     * @dev this functions is for helping UI
     */
    function maxWithdrawAmount(
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
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

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

pragma solidity =0.8.17;

import "./PoolBase.sol";
import "./PoolShareToken.sol";
import "./LiquidTransfer.sol";

contract PoolHelper is PoolBase, PoolShareToken, LiquidTransfer {

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
     * @dev calculates the sum of tokenised and internal shares
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
     * @dev Calculates the usage of the pool depending on the totalPool amount of token
     * inside the pool compared to the pseudoTotal amount
     */
    function _updateUtilisation()
        internal
    {
        utilisationRate = PRECISION_FACTOR_E18 - (totalPool
            * PRECISION_FACTOR_E18
            / pseudoTotalTokensHeld
        );
    }

    /**
     * @dev Calculates new markovMean (recurisive formula)
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
        uint256 baseMultipicator = pole
            * (pole - utilisationRate);

        borrowRate = multiplicativeFactor
            * utilisationRate
            * PRECISION_FACTOR_E18
            / baseMultipicator;

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
    function _updatePseudoTotalAmounts()
        internal
    {
        uint256 timeChange = block.timestamp
            - timeStampLastInteraction;

        uint256 amountInterest = timeChange
            * borrowRate
            * totalTokensDue
            / ONE_YEAR_PRECISION_E18;

        uint256 feeAmount = amountInterest
            * fee
            / PRECISION_FACTOR_E18;

        _increaseTotalTokensDue(
            amountInterest
        );

        if (badDebt > 0) {

            uint256 decreaseBadDebtAmount = badDebt < feeAmount
                ? badDebt
                : feeAmount;

            _decreaseBadDebt(
                decreaseBadDebtAmount
            );

            feeAmount -= decreaseBadDebtAmount;
            amountInterest -= decreaseBadDebtAmount;
        }

        _increasePseudoTotalTokens(
            amountInterest
        );

        timeStampLastInteraction = block.timestamp;

        if (feeAmount == 0) return;

        uint256 feeShares = feeAmount
            * getCurrentPoolShares()
            / (pseudoTotalTokensHeld - feeAmount);

        _increaseInternalShares(
            feeShares,
            feeDestinationAddress
        );

        _increaseTotalInternalShares(
            feeShares
        );
    }

    /**
     * @dev function that tries to maximise totalDepositShares of the pool. Reacting to negative and positive
     * feedback by changing the pole of the pool. Method similar to one parameter monte carlo methods
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

        _poleOutcome(totalShares) == true
            ? _resetPole(totalShares)
            : _updatePole(totalShares);

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
     * @dev sets the new max value in shares and saves the corresponding pole.
     */
    function _newMaxPoolShares(
        uint256 _amount
    )
        internal
    {
        maxPoolShares = _amount;
        bestPole = pole;
    }

    /**
     * @dev returns bool to determine if pole needs to be reset to last best value.
     */
    function _poleOutcome(
        uint256 _shareValue
    )
        internal
        view
        returns (bool)
    {
        return _shareValue < maxPoolShares
            * THRESHOLD_RESET_POLE
            / ONE_HUNDRED;
    }

    /**
     * @dev resettets pole to old best value when system evolves into too bad state.
     * sets current totalDepositShares amount to new maxPoolShares to exclude eternal loops and that
     * unorganic peaks do not set maxPoolShares forever
     */
    function _resetPole(
        uint256 _value
    )
        internal
    {
        maxPoolShares = _value;
        pole = bestPole;

        _revertDirectionSteppingState();
    }

    /**
     * @dev reverts the flag for stepping direction from scaling algorithm
     */
    function _revertDirectionSteppingState()
        internal
    {
        increasePole = !increasePole;
    }

    /**
     * @dev stepping function decresing the pole depending on the time past in the last
     * time interval. Checks if current pole undergoes the min value. If this is the case
     * sets current value to minimal value
     */
    function _decreasePole()
        internal
    {
        uint256 delta = deltaPole
            * (block.timestamp - timeStampLastAlgorithm);

        uint256 sub = pole
            - delta;

        pole = sub < minPole
            ? minPole
            : sub;
    }

    /**
     * @dev Stepping function increasing the pole
     * depending on the time past in the last time interval.
     * Checks if current pole is bigger than max value.
     */
    function _increasePole()
        internal
    {
        uint256 delta = deltaPole
            * (block.timestamp - timeStampLastAlgorithm);

        uint256 sum = pole
            + delta;

        pole = sum > maxPole
            ? maxPole
            : sum;
    }

    /**
     * @dev Does a revert stepping and swaps stepping state in opposite flag
     */
    function _reversedChangingPole()
        internal
    {
        increasePole
            ? _decreasePole()
            : _increasePole();

        _revertDirectionSteppingState();
    }

    /**
     * @dev Increasing or decresing pole depending on flag value.
     */
    function _changingPole()
        internal
    {
        increasePole
            ? _increasePole()
            : _decreasePole();
    }

    /**
     * @dev Function combining all possible stepping scenarios.
     * Depending how share values has changed compared to last time
     */
    function _updatePole(
        uint256 _shareValues
    )
        internal
    {
        _shareValues < previousValue * THRESHOLD_SWITCH_DIRECTION / ONE_HUNDRED
            ? _reversedChangingPole()
            : _changingPole();
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
    function getTokensFromBorrowShares(
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
     * @dev Adjust statevariables like shares and calls _deleteLoanData
     * to account for the fact that a loan has ended
     */
    function _endLoan(
        uint256 _borrowShares,
        address _tokenOwner,
        uint256 _nftTokenId,
        address _nftAddress
    )
        internal
    {
        uint256 tokenPaymentAmount = getTokensFromBorrowShares(
            _borrowShares
        );

        _decreaseTotalBorrowShares(
            _borrowShares
        );

        _decreaseTotalTokensDue(
            tokenPaymentAmount
        );

        _increaseTotalPool(
            tokenPaymentAmount
        );

        _deleteLoanData(
            _nftAddress,
            _nftTokenId
        );

        _transferNFT(
            address(this),
            _tokenOwner,
            _nftAddress,
            _nftTokenId
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

    /**
     * @dev Verifies claimed price of an NFT through merkleProof
     */
    function _checkCollateralValue(
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] memory _merkleProof
    )
        internal
        view
        returns (bool)
    {
        bytes32 node = keccak256(
            abi.encodePacked(
                _merkleIndex,
                _nftTokenId,
                _merklePrice
            )
        );

        return _verifyMerkleProof(
            _merkleProof,
            _getMerkleRoot(
                _nftAddress
            ),
            node
        );
    }

    /**
     * @dev Reads merkle root from the router
     * based on specific collection address
     */
    function _getMerkleRoot(
        address _nftAddress
    )
        internal
        view
        returns (bytes32)
    {
        return ROUTER.merkleRoot(
            _nftAddress
        );
    }

    /**
     * @dev Calculates maximum amount to borrow based on collateral factor and
     * merkleprice in ETH
     */
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

    /**
     * @dev Determines if duration since last payment exceeds allowed timeframe
     */
    function missedDeadline(
        address _nftAddress,
        uint256 _nftTokenId
    )
        public
        view
        returns (bool)
    {
        uint256 nextDueTime = getNextPaymentDueTime(
            _nftAddress,
            _nftTokenId
        );

        return
            nextDueTime > 0 &&
            nextDueTime < block.timestamp;
    }

    /**
     * @dev Removes any token discrepancies
     * or if tokens accidentally sent to pool.
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
                feeDestinationAddress,
                totalBalance - totalPool
            );
        }
    }

    /**
     * @dev Calculates the current NFT auction price from merkle data and checks for proof.
     */
    function _getCurrentAuctionPrice(
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        internal
        view
        returns (uint256)
    {
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

        if (missedDeadline(_nftAddress, _nftTokenId) == false) {
            return merklePriceInPoolToken(
                _merklePrice
            );
        }

        return _dutchAuctionPrice(
            getLastPaidTime(
                _nftAddress,
                _nftTokenId
            ),
            merklePriceInPoolToken(
                _merklePrice
            )
        );
    }

    /**
     * @dev Returns the current auction price of an NFT depending on the time and current merkle price
     */
    function _dutchAuctionPrice(
        uint256 _lastPaidTime,
        uint256 _merklePrice
    )
        internal
        view
        returns (uint256)
    {
        return _merklePrice
            * _getCurrentPercentage(
                _lastPaidTime
            )
            / PRECISION_FACTOR_E18;
    }

    /**
     * @dev Calculates current percantage from the merkle price of the NFT.
     * Decreasment is a linear function of time
     * and has the minimum of 50% after 42 hours.
     * Takes lastPaidTime plus TIME_BETWEEN_PAYMENTS as starting value
     */
    function _getCurrentPercentage(
        uint256 _lastPaidTime
    )
        internal
        view
        returns (uint256)
    {
        uint256 blockTime = block.timestamp;

        if (blockTime > _lastPaidTime + MAX_AUCTION_TIMEFRAME) {
            return FIFTY_PERCENT;
        }

        uint256 secondsPassed = blockTime
            - _lastPaidTime
            - TIME_BETWEEN_PAYMENTS;

        return PRECISION_FACTOR_E18 - secondsPassed
            * FIFTY_PERCENT
            / AUCTION_TIMEFRAME;
    }

    /**
     * @dev Helper function that updates necessairy parts
     * of the mapping to struct of a loan for a user
     */
    function _updateLoanBorrowMore(
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _additionalShares,
        uint256 _additionalTokens
    )
        internal
    {
        currentLoans[_nftAddress][_nftTokenId].borrowShares += _additionalShares;
        currentLoans[_nftAddress][_nftTokenId].principalTokens += _additionalTokens;
    }

    /**
     * @dev Deals with state variables in case of badDebt occuring
     * during liquidation
     */
    function _checkBadDebt(
        uint256 _auctionPrice,
        uint256 _openBorrowAmount
    )
        internal
    {
        if (_auctionPrice < _openBorrowAmount) {

            _increaseTotalPool(
                _auctionPrice
            );

            _increaseBadDebt(
                _openBorrowAmount - _auctionPrice
            );

            return;
        }

        _increaseTotalPool(
            _openBorrowAmount
        );

        if (badDebt > 0) {

            uint256 extraFunds = _auctionPrice
                - _openBorrowAmount;

            uint256 decreaseBadDebtAmount = badDebt < extraFunds
                ? badDebt
                : extraFunds;

            _increaseTotalPool(
                decreaseBadDebtAmount
            );

            _decreaseBadDebt(
                decreaseBadDebtAmount
            );
        }
    }

    /**
     * @dev Helper function that updates the mapping to struct of a loan for a user.
     * Since a few operations happen here, this is a useful obfuscation for readability and reuse.
     */
    function _updateLoanBorrow(
        address _nftAddress,
        uint256 _nftTokenId,
        address _nftBorrower,
        uint256 _newBorrowShares,
        uint256 _newPrincipalTokens
    )
        internal
    {
        currentLoans[_nftAddress][_nftTokenId] = Loan({
            tokenOwner: _nftBorrower,
            borrowShares: _newBorrowShares,
            principalTokens: _newPrincipalTokens,
            lastPaidTime: uint48(block.timestamp)
        });
    }

    /**
     * @dev Updates variables in the loanstruct during paybackfunds
     */
    function _updateLoanPayback(
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _borrowSharesToDestroy,
        uint256 _principalPayoff
    )
        internal
    {
        Loan memory loanData = currentLoans[_nftAddress][_nftTokenId];

        currentLoans[_nftAddress][_nftTokenId] = Loan({
            tokenOwner: loanData.tokenOwner,
            borrowShares: loanData.borrowShares - _borrowSharesToDestroy,
            principalTokens: loanData.principalTokens - _principalPayoff,
            lastPaidTime: uint48(block.timestamp)
        });
    }

    /**
     * Converts merkel price of NFTs
     * into corresponding pool token amount
     */
    function merklePriceInPoolToken(
        uint256 _merkelPriceETH
    )
        public
        view
        returns (uint256)
    {
        if (chainLinkFeedAddress == chainLinkETH) {
            return _merkelPriceETH;
        }

        if (chainLinkIsDead(chainLinkETH) == true) {
            revert("PoolHelper: DEAD_LINK_ETH");
        }

        if (chainLinkIsDead(chainLinkFeedAddress) == true) {
            revert("PoolHelper: DEAD_LINK_TOKEN");
        }

        uint256 valueETHinUSD = _merkelPriceETH
            * IChainLink(chainLinkETH).latestAnswer()
            / 10 ** IChainLink(chainLinkETH).decimals();

        return valueETHinUSD
            * 10 ** IChainLink(chainLinkFeedAddress).decimals()
            / IChainLink(chainLinkFeedAddress).latestAnswer()
            / 10 ** (DECIMALS_ETH - poolTokenDecimals);
    }

    /**
     * @dev Check if chainLink feed was
     * updated within expected timeframe
     */
    function chainLinkIsDead(
        address _feed
    )
        public
        view
        returns (bool)
    {
        (   ,
            ,
            ,
            uint256 upd
            ,
        ) = IChainLink(_feed).latestRoundData();

        upd = block.timestamp > upd
            ? block.timestamp - upd
            : block.timestamp;

        return upd > ROUTER.chainLinkHeartBeat(
            _feed
        );
    }
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

import "./IChainLink.sol";
import "./ILiquidRouter.sol";

interface IERC20 {

    /**
     * @dev ERC20 interface to get decimals of pool token for pool creation
    */
    function decimals()
        external
        returns (uint8);
}

interface IFactory {

    /**
     * @dev allows to get the address of the router during initialise call
    */
    function routerAddress()
        external
        view
        returns (address);
}

contract PoolBase {

    // Router Instance
    ILiquidRouter ROUTER;

    // Routes all calls
    address public ROUTER_ADDRESS;

    // ERC20 for loans
    address public poolToken;

    // Pool token decimals
    uint8 public poolTokenDecimals;

    // Address of fee destination
    address public feeDestinationAddress;

    // ChainLink feed address
    address public chainLinkETH;

    // ChainLink token feed address
    address public chainLinkFeedAddress;

    // Maximal factor every NFT can be collateralised in this pool
    uint256 public maxCollateralFactor;

    // Current usage of the pool. 1E18 <=> 100 %
    uint256 public utilisationRate;

    // Current actual number of token inside the contract
    uint256 public totalPool;

    // Current borrow rate of the pool;
    uint256 public borrowRate;

    // Current mean Markov value of the pool;
    uint256 public markovMean;

    // Bad debt amount in terms of poolToken correct decimals
    uint256 public badDebt;

    // This bool checks if the feeDestinationAddress should not be updateable anymore
    bool public permanentFeeDestination;

    // Tokens currently held by contract + all tokens out on loans
    uint256 public pseudoTotalTokensHeld;

    // Tokens currently being used in loans
    uint256 public totalTokensDue;

    // Shares representing tokens owed on a loan
    uint256 public totalBorrowShares;

    // Shares representing deposits that are not tokenised
    uint256 public totalInternalShares;

    // Borrow rates variables
    // ----------------------

    // Pool position of borrow rate functions (divergent at x = r) 1E18 <=> 1 and r > 1E18.
    uint256 public pole;

    // Value for single step
    uint256 public deltaPole;

    // Global minimum value for the pole
    uint256 public minPole;

    // Global maximum value for the pole
    uint256 public maxPole;

    // Individual multiplication factor scaling the y-axes (static after deployment of pool)
    uint256 public multiplicativeFactor;

    // Tracks the last interaction with the pool
    uint256 public timeStampLastInteraction;

    // Scaling algorithm variables
    // --------------------------

    // Tracks the pole which corsresponds to maxPoolShares
    uint256 public bestPole;

    // Tracks the maximal value of shares the pool has ever reached
    uint256 public maxPoolShares;

    // Tracks the previous shares value during algorithm last round execution
    uint256 public previousValue;

    // Tracks time when scaling algorithm has been triggerd last time
    uint256 public timeStampLastAlgorithm;

    // Switch for stepping directions
    bool public increasePole;

    // Global constants
    // ---------------

    uint8 constant DECIMALS_ETH = 18;
    uint256 constant THREE_HOURS = 3 hours;
    uint256 constant FIVE_PERCENT = 0.05 ether;
    uint256 constant FIFTY_PERCENT = 0.5 ether;

    uint256 constant PRECISION_FACTOR_E18 = 1 ether;
    uint256 constant PRECISION_FACTOR_E36 = 1 ether * 1 ether;
    uint256 constant ONE_YEAR_PRECISION_E18 = 52 weeks * 1 ether;

    uint256 constant ONE_HUNDRED = 100;
    uint256 constant SECONDS_IN_DAY = 3600; // 86400;
    address constant EMPTY_ADDRESS = address(0x0);

    // Earning fee
    uint256 public fee;

    // Value determing weight of new value in markov chain (1% <=> 1E16)
    uint256 constant MARKOV_FRACTION = 0.02 ether;

    // Absulute max value for borrow rate
    uint256 constant UPPER_BOUND_MAX_RATE = 5 ether;

    // Lower max value for borrow rate
    uint256 constant LOWER_BOUND_MAX_RATE = 1.5 ether;

    // Timeframe for normalisation
    uint256 constant NORMALISATION_FACTOR = 8 weeks;

    // Threshold for reverting stepping cirection
    uint256 constant THRESHOLD_SWITCH_DIRECTION = 90;

    // Threshold for resetting pole
    uint256 constant THRESHOLD_RESET_POLE = 75;

    // Expecting user to payback the loan in 35 days
    uint256 constant public TIME_BETWEEN_PAYMENTS = 35 days;

    // Auction reaches minimum after 42 hours
    uint256 constant public AUCTION_TIMEFRAME = 42 hours;

    // Relates minimum time of auction to lastPaidTime
    uint256 constant public MAX_AUCTION_TIMEFRAME = TIME_BETWEEN_PAYMENTS + AUCTION_TIMEFRAME;

    struct Loan {
        uint48 lastPaidTime;
        address tokenOwner;
        uint256 borrowShares;
        uint256 principalTokens;
    }

    // Storing known collections
    mapping(address => bool) public nftAddresses;

    // Keeping internal shares of each user
    mapping(address => uint256) public internalShares;

    // NFT address => tokenID => loan data
    mapping(address => mapping(uint256 => Loan)) public currentLoans;

    // Base functions

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
     * @dev Helper function to increase bad debt
     */
    function _increaseBadDebt(
        uint256 _amount
    )
        internal
    {
        badDebt =
        badDebt + _amount;
    }

    /**
     * @dev Helper function to decrease bad debt
     */
    function _decreaseBadDebt(
        uint256 _amount
    )
        internal
    {
        badDebt =
        badDebt - _amount;
    }

    /**
     * @dev helping UI display principal Amount of loan
     */
    function getPrincipalAmount(
        address _nftAddress,
        uint256 _nftTokenId
    )
        public
        view
        returns (uint256)
    {
        return currentLoans[_nftAddress][_nftTokenId].principalTokens;
    }

    /**
    * @dev displays current borrowshares of a loan
    */
    function getCurrentBorrowShares(
        address _nftAddress,
        uint256 _nftTokenId
    )
        public
        view
        returns (uint256)
    {
        return currentLoans[_nftAddress][_nftTokenId].borrowShares;
    }

    /**
     * @dev function for helping router emit events with lessgas cost
     */
    function getLoanOwner(
        address _nftAddress,
        uint256 _nftTokenId
    )
        public
        view
        returns (address)
    {
        return currentLoans[_nftAddress][_nftTokenId].tokenOwner;
    }

    function getLastPaidTime(
        address _nftAddress,
        uint256 _nftTokenId
    )
        public
        view
        returns (uint256)
    {
        return currentLoans[_nftAddress][_nftTokenId].lastPaidTime;
    }

    function getNextPaymentDueTime(
        address _nftAddress,
        uint256 _nftTokenId
    )
        public
        view
        returns (uint256)
    {
        return getLastPaidTime(
            _nftAddress,
            _nftTokenId
        ) + TIME_BETWEEN_PAYMENTS;
    }

    function _deleteLoanData(
        address _nftAddress,
        uint256 _nftTokenId
    )
        internal
    {
        delete currentLoans[_nftAddress][_nftTokenId];
    }
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

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
            "safeTransferFrom(address,address,uint256)",
            _from,
            _to,
            _tokenId
        );

        (bool success,) = address(_tokenAddress).call(
            data
        );

        require(
            success,
            "LiquidTransfer: NFT_TRANSFER_FAILED"
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
            "safeTransferFrom(address,address,uint256)",
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
                "transfer(address,uint256)"
            )
        )
    );

    /**
     * @dev encoding for transferFrom
     */
    bytes4 constant TRANSFER_FROM = bytes4(
        keccak256(
            bytes(
                "transferFrom(address,address,uint256)"
            )
        )
    );

    /**
     * @dev encoding for balanceOf
     */
    bytes4 private constant BALANCE_OF = bytes4(
        keccak256(
            bytes(
                "balanceOf(address)"
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
            "LiquidTransfer: TRANSFER_FAILED"
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
            "LiquidTransfer: TRANSFER_FROM_FAILED"
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

pragma solidity =0.8.17;

import "./ILiquidPool.sol";
import "./RouterEvents.sol";
import "./AccessControl.sol";
import "./LiquidTransfer.sol";
import "./IChainLink.sol";

contract LiquidRouter is LiquidTransfer, AccessControl, RouterEvents {

    // Factory contract that clones liquid pools
    address public factoryAddress;

    // Oracel address for ETH
    address public immutable chainLinkETH;

    // Minimum time for a new merkleRoot to be updated
    uint256 public constant UPDATE_DURATION = 72 hours;

    // Number of last rounds which are checked for heartbeatlength
    uint80 public constant MAX_ROUND_COUNT = 50;

    // Official pools that are added to the router
    mapping(address => bool) public registeredPools;

    // NFT address => merkle root
    mapping(address => bytes32) public merkleRoot;

    // NFT address => merkle root IPFS address
    mapping(address => string) public merkleIPFS;

    // Mapping for ability to expand pools
    mapping(address => bool) public expansionRevoked;

    // Stores the time between chainLink heartbeats
    mapping(address => uint256) public chainLinkHeartBeat;

    // Mapping for updates of merkle roots
    mapping(address => UpdateRoot) public pendingRoots;

    // Mapping for pool expansion with collections
    mapping(address => ExpandPool) public pendingPools;

    // Data object for merkleRoot updates
    struct UpdateRoot {
        uint256 updateTime;
        bytes32 merkleRoot;
        string ipfsAddress;
    }

    // Data object for pool expansion
    struct ExpandPool {
        uint256 updateTime;
        address nftAddress;
    }

    // Marker to avoid unknown pools
    modifier onlyKnownPools(
        address _pool
    ) {
        require(
            registeredPools[_pool] == true,
            "LiquidRouter: UNKNOWN_POOL"
        );
        _;
    }

    // Avoids expansion if denied
    modifier onlyExpandable(
        address _pool
    ) {
        require(
            expansionRevoked[_pool] == false,
            "LiquidRouter: NOT_EXPANDABLE"
        );
        _;
    }

    /**
     * @dev Set the address of the factory, and chainLinkETH oracleAddress
     */
    constructor(
        address _factoryAddress,
        address _chainLinkETH
    ) {
        factoryAddress = _factoryAddress;
        chainLinkETH = _chainLinkETH;
    }

    /**
     * @dev Calls liquidateNFT on a specific pool. More info see PoolHelper
     * liquidateNFT
     */
    function liquidateNFT(
        address _pool,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external
    {
        uint256 auctionPrice = ILiquidPool(_pool).liquidateNFT(
            msg.sender,
            _nftAddress,
            _nftTokenId,
            _merkleIndex,
            _merklePrice,
            _merkleProof
        );

        _safeTransferFrom(
            ILiquidPool(_pool).poolToken(),
            msg.sender,
            _pool,
            auctionPrice
        );

        emit Liquidated(
            _nftAddress,
            _nftTokenId,
            auctionPrice,
            msg.sender,
            block.timestamp
        );
    }

    /**
     * @dev Register an address as officially known pool
     */
    function addLiquidPool(
        address _pool
    )
        external
    {
        require(
            msg.sender == factoryAddress,
            "LiquidRouter: NOT_FACTORY"
        );

        registeredPools[_pool] = true;

        _addWorker(
            _pool,
            multisig
        );

        emit LiquidPoolRegistered(
            _pool,
            block.timestamp
        );
    }

    /**
     * @dev Register initial root for upcoming new collection
     */
    function addMerkleRoot(
        address _nftAddress,
        bytes32 _merkleRoot,
        string memory _ipfsAddress
    )
        external
        onlyMultisig
    {
        require(
            merkleRoot[_nftAddress] == 0,
            "LiquidRouter: OVERWRITE_DENIED"
        );

        _addWorker(
            _nftAddress,
            msg.sender
        );

        merkleRoot[_nftAddress] = _merkleRoot;
        merkleIPFS[_nftAddress] = _ipfsAddress;
    }

    /**
     * @dev Initialise merkle root update for existing collection
     */
    function startUpdateRoot(
        address _nftAddress,
        bytes32 _merkleRoot,
        string memory _ipfsAddress
    )
        external
        onlyWiseWorker(_nftAddress)
    {
        require(
            _merkleRoot > 0,
            "LiquidRouter: INVALID_ROOT"
        );

        uint256 unlockTime = block.timestamp
            + UPDATE_DURATION;

        pendingRoots[_nftAddress] = UpdateRoot({
            updateTime: unlockTime,
            merkleRoot: _merkleRoot,
            ipfsAddress: _ipfsAddress
        });

        emit RootAnnounced(
            msg.sender,
            unlockTime,
            _nftAddress,
            _merkleRoot,
            _ipfsAddress
        );
    }

    /**
     * @dev Finish merkle root update for existing collection after time lock
     */
    function finishUpdateRoot(
        address _nftAddress
    )
        external
    {
        UpdateRoot memory update = pendingRoots[_nftAddress];

        require(
            update.updateTime > 0,
            "LiquidRouter: INVALID_TIME"
        );

        require(
            block.timestamp > update.updateTime,
            "LiquidRouter: TOO_EARLY"
        );

        merkleRoot[_nftAddress] = update.merkleRoot;
        merkleIPFS[_nftAddress] = update.ipfsAddress;

        delete pendingRoots[_nftAddress];

        emit RootUpdated(
            msg.sender,
            block.timestamp,
            _nftAddress,
            update.merkleRoot,
            update.ipfsAddress
        );
    }

    /**
     * @dev Initialise expansion of the pool if allowed and root was announced
     */
    function startExpandPool(
        address _pool,
        address _nftAddress
    )
        external
        onlyExpandable(_pool)
        onlyWiseWorker(_pool)
    {
        require(
            merkleRoot[_nftAddress] > 0,
            "LiquidRouter: ROOT_NOT_FOUND"
        );

        uint256 updateTime = block.timestamp
            + UPDATE_DURATION;

        pendingPools[_pool] = ExpandPool({
            updateTime: updateTime,
            nftAddress: _nftAddress
        });

        emit UpdateAnnounced(
            msg.sender,
            updateTime,
            _pool,
            _nftAddress
        );
    }

    /**
     * @dev Finish introducing new collection to the pool
     */
    function finishExpandPool(
        address _pool
    )
        external
        onlyExpandable(_pool)
    {
        ExpandPool memory update = pendingPools[_pool];

        require(
            update.updateTime > 0,
            "LiquidRouter: INVALID_TIME"
        );

        require(
            block.timestamp > update.updateTime,
            "LiquidRouter: TOO_EARLY"
        );

        ILiquidPool(_pool).addCollection(
            update.nftAddress
        );

        delete pendingPools[_pool];

        emit PoolUpdated(
            msg.sender,
            block.timestamp,
            _pool,
            update.nftAddress
        );
    }

    /**
     * @dev remove expandability from the pool
     */
    function revokeExpansion(
        address _pool
    )
        external
        onlyMultisig
    {
        expansionRevoked[_pool] = true;

        emit ExpansionRevoked(
            _pool
        );
    }

    /**
     * @dev Calls the depositFunds function of a specific pool.
     * Also handle the transferring of tokens here, only have to approve router
     * Check that pool is registered
     */
    function depositFunds(
        uint256 _amount,
        address _pool
    )
        public
        onlyKnownPools(_pool)
    {
        uint256 shares = ILiquidPool(_pool).depositFunds(
            _amount,
            msg.sender
        );

        _safeTransferFrom(
            ILiquidPool(_pool).poolToken(),
            msg.sender,
            _pool,
            _amount
        );

        emit FundsDeposited(
            _pool,
            msg.sender,
            _amount,
            shares,
            block.timestamp
        );
    }

    /**
     * @dev Calls the withdrawFunds function of a specific pool.
     * more info see LiquidPool withdrawFunds
     */
    function withdrawFunds(
        uint256 _shares,
        address _pool
    )
        public
        onlyKnownPools(_pool)
    {
        uint256 withdrawAmount = ILiquidPool(_pool).withdrawFunds(
            _shares,
            msg.sender
        );

        emit FundsWithdrawn(
            _pool,
            msg.sender,
            withdrawAmount,
            _shares,
            block.timestamp
        );
    }

    /**
     * @dev moves funds as lender from one registered pool
     * to another with requirement being same poolToken
     * uses internalShares and no tokenized Shares
     */
    function moveFunds(
        uint256 _shares,
        address _poolToExit,
        address _poolToEnter
    )
        external
    {
        require(
            ILiquidPool(_poolToExit).poolToken() ==
            ILiquidPool(_poolToEnter).poolToken(),
            "LiquidRouter: TOKENS_MISMATCH"
        );

        uint256 amountToDeposit = ILiquidPool(
            _poolToExit
        ).calculateWithdrawAmount(
            _shares
        );

        withdrawFunds(
            _shares,
            _poolToExit
        );

        depositFunds(
            amountToDeposit,
            _poolToEnter
        );
    }

    /**
     * @dev Calls the borrowFunds function of a specific pool.
     * more info in LiquidPool borrowFunds
     */
    function borrowFunds(
        address _pool,
        uint256 _takeAmount,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external
        onlyKnownPools(_pool)
    {
        _transferFromNFT(
            msg.sender,
            _pool,
            _nftAddress,
            _nftTokenId
        );

        ILiquidPool(_pool).borrowFunds(
            msg.sender,
            _takeAmount,
            _nftAddress,
            _nftTokenId,
            _merkleIndex,
            _merklePrice,
            _merkleProof
        );

        emit FundsBorrowed(
            _pool,
            _nftAddress,
            _nftTokenId,
            _takeAmount,
            msg.sender,
            block.timestamp
        );
    }

    /**
     * @dev Calls the borrowMoreFunds function of a specific pool.
     * more info in LiquidPool borrowMoreFunds
     */
    function borrowMoreFunds(
        address _pool,
        uint256 _takeAmount,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external
        onlyKnownPools(_pool)
    {
        ILiquidPool(_pool).borrowMoreFunds(
            msg.sender,
            _takeAmount,
            _nftAddress,
            _nftTokenId,
            _merkleIndex,
            _merklePrice,
            _merkleProof
        );

        emit MoreFundsBorrowed(
            _pool,
            _nftAddress,
            msg.sender,
            _nftTokenId,
            _takeAmount,
            block.timestamp
        );
    }

    /**
     * @dev Calls paybackfunds for a specific pool
     * more info see LiquidPool paybackFunds
     */
    function paybackFunds(
        address _pool,
        uint256 _payAmount,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external
        onlyKnownPools(_pool)
    {
        uint256 transferAmount = ILiquidPool(_pool).paybackFunds(
            _payAmount,
            _nftAddress,
            _nftTokenId,
            _merkleIndex,
            _merklePrice,
            _merkleProof
        );

        address loanOwner = ILiquidPool(_pool).getLoanOwner(
            _nftAddress,
            _nftTokenId
        );

        _safeTransferFrom(
            ILiquidPool(_pool).poolToken(),
            msg.sender,
            _pool,
            transferAmount
        );

        emit FundsReturned(
            _pool,
            _nftAddress,
            loanOwner,
            transferAmount,
            _nftTokenId,
            block.timestamp
        );
    }

    /**
     * @dev Changes the address which
     * receives fees deonominated in shares bulk (internal)
     */
    function lockFeeDestination(
        address[] calldata _pools
    )
        external
        onlyMultisig
    {
        for (uint32 i = 0; i < _pools.length; i++) {
            ILiquidPool(_pools[i]).lockFeeDestination();
        }
    }

    /**
     * @dev Changes the address which
     * receives fees deonominated in shares bulk
     */
    function changeFeeDestinationAddress(
        address[] calldata _pools,
        address[] calldata _newFeeDestinationAddress
    )
        external
        onlyMultisig
    {
        for (uint32 i = 0; i < _pools.length; i++) {
            ILiquidPool(_pools[i]).changeFeeDestinationAddress(
                _newFeeDestinationAddress[i]
            );
        }
    }

    /**
     * @dev
     * Allows to withdraw accumulated fees
     * storing them in the router contract
     */
    function withdrawFees(
        address[] calldata _pools,
        uint256[] calldata _shares
    )
        external
    {
        for (uint32 i = 0; i < _pools.length; i++) {
            ILiquidPool(_pools[i]).withdrawFunds(
                _shares[i],
                address(this)
            );
        }
    }

    /**
     * @dev
     * Removes any tokens accumulated
     * by the router including fees
     */
    function removeToken(
        address _tokenAddress,
        address _depositAddress
    )
        external
        onlyMultisig
    {
        uint256 tokenBalance = _safeBalance(
            _tokenAddress,
            address(this)
        );

        _safeTransfer(
            _tokenAddress,
            _depositAddress,
            tokenBalance
        );
    }

    /**
     * @dev Determines info for the heartbeat update mechanism for chainlink
     * oracles (roundIds)
     */
    function getLatestAggregatorRoundId(
        address _feed
    )
        public
        view
        returns (uint80)
    {
        (   uint80 roundId,
            ,
            ,
            ,
        ) = IChainLink(_feed).latestRoundData();

        return uint64(roundId);
    }

    /**
     * @dev Determines info for the heartbeat update mechanism for chainlink
     * oracles (shifted round Ids)
     */
    function getRoundIdByByteShift(
        uint16 _phaseId,
        uint80 _aggregatorRoundId
    )
        public
        pure
        returns (uint80)
    {
        return uint80(uint256(_phaseId) << 64 | _aggregatorRoundId);
    }

    /**
     * @dev View function to determine the heartbeat to see if updating heartbeat
     * is necessairy or not (compare to current value).
     * Looks at the maximal last 50 rounds and takes second highest value to
     * avoid counting offline time of chainlink as valid heartbeat
     */
    function recalibratePreview(
        address _feed
    )
        public
        view
        returns (uint256)
    {
        uint80 latestAggregatorRoundId = getLatestAggregatorRoundId(
            _feed
        );

        uint80 iterationCount = _getIterationCount(
            latestAggregatorRoundId
        );

        if (iterationCount < 2) {
            revert("LiquidRouter: SMALL_SAMPLE");
        }

        uint16 phaseId = IChainLink(_feed).phaseId();
        uint256 latestTimestamp = _getRoundTimestamp(
            _feed,
            phaseId,
            latestAggregatorRoundId
        );

        uint256 currentDiff;
        uint256 currentBiggest;
        uint256 currentSecondBiggest;

        for (uint80 i = 1; i < iterationCount; i++) {

            uint256 currentTimestamp = _getRoundTimestamp(
                _feed,
                phaseId,
                latestAggregatorRoundId - i
            );

            currentDiff = latestTimestamp
                - currentTimestamp;

            latestTimestamp = currentTimestamp;

            if (currentDiff >= currentBiggest) {
                currentSecondBiggest = currentBiggest;
                currentBiggest = currentDiff;
            } else if (currentDiff > currentSecondBiggest && currentDiff < currentBiggest) {
                currentSecondBiggest = currentDiff;
            }
        }

        return currentSecondBiggest;
    }

    /**
     * @dev Determines number of iterations necessairy during recalibrating
     * heartbeat.
     */
    function _getIterationCount(
        uint80 _latestAggregatorRoundId
    )
        internal
        pure
        returns (uint80)
    {
        return _latestAggregatorRoundId > MAX_ROUND_COUNT
            ? MAX_ROUND_COUNT
            : _latestAggregatorRoundId;
    }

    /**
     * @dev fetches timestamp of a byteshifted aggregatorRound with specific
     * phaseID. For more info see chainlink historical price data documentation
     */
    function _getRoundTimestamp(
        address _feed,
        uint16 _phaseId,
        uint80 _aggregatorRoundId
    )
        internal
        view
        returns (uint256)
    {
        (
            ,
            ,
            ,
            uint256 timestamp,
        ) = IChainLink(_feed).getRoundData(
            getRoundIdByByteShift(
                _phaseId,
                _aggregatorRoundId
            )
        );

        return timestamp;
    }

    /**
     * @dev Function to recalibrate the heartbeat for a specific feed
     */
    function recalibrate(
        address _feed
    )
        external
    {
        chainLinkHeartBeat[_feed] = recalibratePreview(_feed);
    }
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

import "./Babylonian.sol";

import "./PoolViews.sol";
import "./LiquidEvents.sol";

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
     * @dev Sets statevariables for a pool more info in IliquidInit.sol
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

        // Initialise with 20%
        fee = 20
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
     * exisiting (same LTV constraint).
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
     * @dev External functiojn to update the borrow rate of the pool
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

// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

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
        uint256 indexed nftTokenId,
        address indexed borrower,
        uint256 amount,
        uint256 timestamp
    );

    event MoreFundsBorrowed(
        address indexed nftAddress,
        uint256 indexed nftTokenId,
        address indexed borrower,
        uint256 amount,
        uint256 timestamp
    );

    event FundsReturned(
        address indexed nftAddress,
        address indexed tokenOwner,
        uint256 totalPayment,
        uint256 nftTokenId,
        uint256 timestamp
    );

    event DiscountChanged(
        uint256 oldFactor,
        uint256 newFactor
    );

    event Liquidated(
        address indexed nftAddress,
        uint256 nftTokenId,
        address previousOwner,
        address currentOwner,
        uint256 discountAmount,
        uint256 timestamp
    );

    event PoolFunded(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 badDebt,
        uint256 timestamp
    );

    event DecreaseBadDebt(
        uint256 newBadDebt,
        uint256 paybackAmount,
        uint256 timestamp
    );

    event ManualSyncPool(
        uint256 indexed updateTime
    );
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

interface ILiquidRouter {

    /**
     * @dev Router interface to get merkleRoot for specific collection
    */
    function merkleRoot(
        address _nftAddress
    )
        external
        view
        returns (bytes32);

    /**
     * @dev Router interface to get chainlink ETH address for pool creation
    */
    function chainLinkETH()
        external
        view
        returns (address);

    /**
     * @dev Router interface to get chainlink Heartbeat for a specific feed
    */
    function chainLinkHeartBeat(
        address _feedAddress
    )
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

interface ILiquidPool {

    function depositFunds(
        uint256 _amount,
        address _depositor
    )
        external
        returns (uint256);

    function withdrawFunds(
        uint256 _shares,
        address _user
    )
        external
        returns (uint256);

    function borrowFunds(
        address _borrowAddress,
        uint256 _borrowAmount,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external;

    function borrowMoreFunds(
        address _borrowAddress,
        uint256 _borrowAmount,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external;

    function paybackFunds(
        uint256 _payAmount,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external
        returns (uint256);

    function liquidateNFT(
        address _liquidator,
        address _nftAddress,
        uint256 _nftTokenId,
        uint256 _merkleIndex,
        uint256 _merklePrice,
        bytes32[] calldata _merkleProof
    )
        external
        returns (uint256);

    function getLoanOwner(
        address _nft,
        uint256 _tokenID
    )
        external
        view
        returns (address);

    function withdrawFee()
        external;

    function poolToken()
        external
        view
        returns (address);

    function calculateWithdrawAmount(
        uint256 _shares
    )
        external
        view
        returns (uint256);

    function lockFeeDestination()
        external;

    function changeFeeDestinationAddress(
        address _newFeeDestinationAddress
    )
        external;

    function expandPool(
        address _nftAddress
    )
        external;

    function addCollection(
        address _nftAddress
    )
        external;
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

interface ILiquidInit {

    function initialise(
        // ERC20 for loans
        address _poolToken,
        // Address used for Chainlink oracle
        address _chainLinkFeedAddress,
        // Determine how quickly the interest rate changes
        uint256 _multiplicationFactor,
        // Maximal factor every NFT can be collateralised
        uint256 _maxCollateralFactor,
        // Address of the NFT contract
        address[] memory _nftAddresses,
        // Name for ERC20 representing shares of this pool
        string memory _tokenName,
        // Symbol for ERC20 representing shares of this pool
        string memory _tokenSymbol
    )
        external;
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

interface IChainLink {

    function decimals()
        external
        view
        returns (uint8);

    function latestAnswer()
        external
        view
        returns (uint256);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answerdInRound
        );

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function phaseId()
        external
        view
        returns(
            uint16 phaseId
        );

    function aggregator()
        external
        view
        returns (address);
}

// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

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

pragma solidity =0.8.17;

contract AccessControl {

    // Managed by WISE
    address public multisig;

    // Mapping to store authorised workers
    mapping(address => mapping(address => bool)) public workers;

    event MultisigUpdated(
        address newMultisig
    );

    event WorkerAdded(
        address wiseGroup,
        address newWorker
    );

    event WorkerRemoved(
        address wiseGroup,
        address existingWorker
    );

    /**
     * @dev Set to address that deploys Factory
     */
    constructor() {
        multisig = tx.origin;
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
     * @dev requires that sender is authorised
     */
    modifier onlyWiseWorker(
        address _group
    ) {
        require(
            workers[_group][msg.sender] == true,
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
        multisig = _newMultisig;

        emit MultisigUpdated(
            _newMultisig
        );
    }

    /**
     * @dev Add a worker address to the system.
     * Set the bool for the worker to true.
     */
    function addWorker(
        address _group,
        address _worker
    )
        external
        onlyMultisig
    {
        _addWorker(
            _group,
            _worker
        );
    }

    function _addWorker(
        address _group,
        address _worker
    )
        internal
    {
        workers[_group][_worker] = true;

        emit WorkerAdded(
            _group,
            _worker
        );
    }

    /**
     * @dev Remove a worker address from the system.
     * Set the bool for the worker to false.
     */
    function removeWorker(
        address _group,
        address _worker
    )
        external
        onlyMultisig
    {
        workers[_group][_worker] = false;

        emit WorkerRemoved(
            _group,
            _worker
        );
    }
}