// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "ReentrancyGuard.sol";
import "AggregatorV3Interface.sol";

contract GwinProtocol is Ownable, ReentrancyGuard {
    struct Bal {
        uint cBal;
        uint cPercent;
        uint hBal;
        uint hPercent;
    }

    // pool ID -> user address -> user balances struct
    mapping(uint => mapping(address => Bal)) public ethStakedBalance;

    // token address -> staker address -> amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    // staker address -> unique tokens staked
    mapping(address => uint256) public uniquePositions;
    // pool ID    ->   address  ->  isUnique
    mapping(uint => mapping(address => bool)) public isUniqueEthStaker;

    // aggregator key -> aggregator
    mapping(bytes32 => AggregatorV3Interface) public aggregators;

    // aggreagator key -> feed decimals
    mapping(bytes32 => uint8) public currencyKeyDecimals;

    // List of aggregator keys for convenient iteration
    bytes32[] public aggregatorKeys;

    //    pool ID --> struct
    mapping(uint => Pool) public pool;

    // pool ID --> array of ETH stakers
    mapping(uint => address[]) public ethStakers;
    // array of stakers
    address[] public stakers;
    // array of the allowed tokens
    address[] public allowedTokens;
    // array of pool IDs
    uint[] public poolIds;

    // ********* Decimal Values *********
    uint256 decimals = 10**18;
    uint8 usdDecimalsUint = 8;
    uint256 usdDecimals = 10**usdDecimalsUint;
    uint256 bps = 10**12;

    // ************* Values *************
    uint newPoolId = 0;

    struct Pool {
        uint256 lastSettledUsdPrice;
        uint256 currentUsdPrice;
        bytes32 basePriceFeedKey;
        bytes32 quotePriceFeedKey;
        uint256 hEthBal;
        uint256 cEthBal;
        int256 hRate;
        int256 cRate;
        uint8 poolType; // as in classic or modified
    }

    // Potential ISSUE if these can be changed, but I doubt that's the case

    // Storing the GWIN token as a global variable, IERC20 imported above, address passed into constructor
    IERC20 public gwinToken;

    // Right when we deploy this contract, we need to know the address of GWIN token
    constructor(address _gwinTokenAddress, address _link) public {
        // pass in the address from the GwinToken.sol contract
        gwinToken = IERC20(_gwinTokenAddress);
    }

    /// INITIALIZE-POOL /// - this deposits an equal amount to each tranche to initialize a pool
    function initializePool(
        uint8 _type,
        address _basePriceFeedAddress,
        bytes32 _baseCurrencyKey,
        address _quotePriceFeedAddress,
        bytes32 _quoteCurrencyKey,
        int _cRate,
        int _hRate
    ) external payable onlyOwner returns (uint) {
        // ADD require that pool ID is not taken
        poolIds.push(newPoolId);
        pool[newPoolId].poolType = _type;
        require(
            pool[newPoolId].cEthBal == 0 && pool[newPoolId].hEthBal == 0,
            "The Protocol already has funds deposited."
        );
        require(_cRate < 0 && _hRate > 0, "Rates_Must_Oppose");
        if (isUniqueEthStaker[newPoolId][msg.sender] == false) {
            ethStakers[newPoolId].push(msg.sender);
            isUniqueEthStaker[newPoolId][msg.sender] = true;
        }
        pool[newPoolId].cRate = _cRate;
        pool[newPoolId].hRate = _hRate;
        pool[newPoolId].basePriceFeedKey = _baseCurrencyKey;
        pool[newPoolId].quotePriceFeedKey = _quoteCurrencyKey;
        uint splitAmount = msg.value / 2;
        ethStakedBalance[newPoolId][msg.sender].cBal += splitAmount;
        ethStakedBalance[newPoolId][msg.sender].cPercent = bps;
        pool[newPoolId].cEthBal = splitAmount;
        ethStakedBalance[newPoolId][msg.sender].hBal += splitAmount;
        ethStakedBalance[newPoolId][msg.sender].hPercent = bps;
        pool[newPoolId].hEthBal = splitAmount;
        addAggregator(_baseCurrencyKey, _basePriceFeedAddress);
        if (_quotePriceFeedAddress != address(0x0)) {
            addAggregator(_quoteCurrencyKey, _quotePriceFeedAddress);
        }
        pool[newPoolId].currentUsdPrice = retrieveCurrentPrice(newPoolId);
        pool[newPoolId].lastSettledUsdPrice = pool[newPoolId].currentUsdPrice;
        newPoolId++;
        return newPoolId - 1;
    }

    function addAggregator(bytes32 currencyKey, address aggregatorAddress)
        private
        onlyOwner
    {
        AggregatorV3Interface aggregator = AggregatorV3Interface(
            aggregatorAddress
        );
        uint8 feedDecimals = aggregator.decimals();
        if (address(aggregators[currencyKey]) == address(0)) {
            aggregatorKeys.push(currencyKey);
        }
        aggregators[currencyKey] = aggregator;
        currencyKeyDecimals[currencyKey] = feedDecimals;
    }

    /// DEPOSIT /// - used to deposit to cooled or heated tranche, or both
    function depositToTranche(
        uint _poolId,
        bool _isCooled,
        bool _isHeated,
        uint _cAmount,
        uint _hAmount
    ) external payable {
        require(
            pool[_poolId].basePriceFeedKey != 0x0,
            "Pool_Is_Not_Initialized"
        );
        require(msg.value > 0, "Amount must be greater than zero.");
        require(_isCooled == true || _isHeated == true);
        require(_cAmount + _hAmount <= msg.value);

        // Interact to rebalance Tranches with new USD price
        interact(_poolId);
        // Re-adjust to update balances after price change
        reAdjust(_poolId, true, _isCooled, _isHeated);
        // Deposit ETH
        if (_isCooled == true && _isHeated == false) {
            ethStakedBalance[_poolId][msg.sender].cBal += msg.value;
            pool[_poolId].cEthBal += msg.value;
        } else if (_isCooled == false && _isHeated == true) {
            ethStakedBalance[_poolId][msg.sender].hBal += msg.value;
            pool[_poolId].hEthBal += msg.value;
        } else if (_isCooled == true && _isHeated == true) {
            ethStakedBalance[_poolId][msg.sender].cBal += _cAmount;
            pool[_poolId].cEthBal += _cAmount;
            ethStakedBalance[_poolId][msg.sender].hBal += _hAmount;
            pool[_poolId].hEthBal += _hAmount;
        }
        if (isUniqueEthStaker[_poolId][msg.sender] == false) {
            ethStakers[_poolId].push(msg.sender);
            isUniqueEthStaker[_poolId][msg.sender] = true;
        }
        // Re-Adjust user percentages
        reAdjust(_poolId, false, _isCooled, _isHeated);

        pool[_poolId].lastSettledUsdPrice = pool[_poolId].currentUsdPrice;
    }

    /// PREVIEW-USER-BALANCE /// - preview balance at the current ETH/USD price
    function previewUserBalance(uint _poolId) public view returns (uint, uint) {
        uint heatedBalance;
        uint cooledBalance;
        (heatedBalance, cooledBalance) = simulateInteract(
            _poolId,
            retrieveCurrentPrice(_poolId)
        );
        uint userHeatedBalance = (heatedBalance *
            ethStakedBalance[_poolId][msg.sender].hPercent) / bps;
        uint userCooledBalance = (cooledBalance *
            ethStakedBalance[_poolId][msg.sender].cPercent) / bps;
        return (userHeatedBalance, userCooledBalance);
    }

    /// WITHDRAW /// - used to withdraw from cooled or heated tranche, or both
    function withdrawFromTranche(
        uint _poolId,
        bool _isCooled,
        bool _isHeated,
        uint _cAmount,
        uint _hAmount,
        bool _isAll
    ) external nonReentrant {
        // TEMP || "or" ?
        require(
            pool[_poolId].cEthBal > 0 || pool[_poolId].hEthBal > 0,
            "Protocol_Funds_Insufficient"
        );
        if (_isAll == false) {
            require(_cAmount > 0 || _hAmount > 0, "Zero_Withdrawal_Amount");
        }
        require(_isCooled == true || _isHeated == true);

        // Interact to rebalance Tranches with new USD price
        interact(_poolId);
        // Re-adjust the user balances based on price change
        reAdjust(_poolId, true, _isCooled, _isHeated);

        if (_isAll == true) {
            if (_isCooled == true) {
                _cAmount = ethStakedBalance[_poolId][msg.sender].cBal;
            }
            if (_isHeated == true) {
                _hAmount = ethStakedBalance[_poolId][msg.sender].hBal;
            }
        }

        require(
            _cAmount <= ethStakedBalance[_poolId][msg.sender].cBal &&
                _hAmount <= ethStakedBalance[_poolId][msg.sender].hBal,
            "Insufficient_User_Funds"
        );

        // Withdraw ETH
        if (_cAmount > 0 && _hAmount > 0) {
            // Cooled and Heated
            ethStakedBalance[_poolId][msg.sender].cBal -= _cAmount;
            pool[_poolId].cEthBal -= _cAmount;
            ethStakedBalance[_poolId][msg.sender].hBal -= _hAmount;
            pool[_poolId].hEthBal -= _hAmount;
            payable(msg.sender).transfer(_cAmount + _hAmount);
        } else {
            if (_cAmount > 0 && _hAmount == 0) {
                // Cooled, No Heated
                ethStakedBalance[_poolId][msg.sender].cBal -= _cAmount;
                pool[_poolId].cEthBal -= _cAmount;
                payable(msg.sender).transfer(_cAmount);
            } else if (_cAmount == 0 && _hAmount > 0) {
                // Heated, No Cooled
                ethStakedBalance[_poolId][msg.sender].hBal -= _hAmount;
                pool[_poolId].hEthBal -= _hAmount;
                payable(msg.sender).transfer(_hAmount);
            }
        }

        // Re-Adjust user percentages
        reAdjust(_poolId, false, _isCooled, _isHeated);

        pool[_poolId].lastSettledUsdPrice = pool[_poolId].currentUsdPrice;
    }

    /// REMOVE-FROM-ARRAY /// - removes the staker from the array of ETH stakers
    // #indexRemovalProblem
    function removeFromArray(uint _poolId, uint index) private {
        ethStakers[_poolId][index] = ethStakers[_poolId][
            ethStakers[_poolId].length - 1
        ];
        ethStakers[_poolId].pop();
    }

    // RE-ADJUST /// - adjusts affected tranche percentages and balances
    function reAdjust(
        uint _poolId,
        bool _beforeTx,
        bool _isCooled,
        bool _isHeated
    ) private {
        if (_beforeTx == true) {
            // BEFORE deposit, only balances are affected based on percentages
            liquidateIfZero(_poolId);
            // ISSUE this could likely be optimized to avoid performing the for loops twice when liquidated
            for (
                uint256 ethStakersIndex = 0;
                ethStakersIndex < ethStakers[_poolId].length;
                ethStakersIndex++
            ) {
                address addrC = ethStakers[_poolId][ethStakersIndex];
                ethStakedBalance[_poolId][addrC].cBal =
                    (pool[_poolId].cEthBal *
                        ethStakedBalance[_poolId][addrC].cPercent) /
                    bps;
                ethStakedBalance[_poolId][addrC].hBal =
                    (pool[_poolId].hEthBal *
                        ethStakedBalance[_poolId][addrC].hPercent) /
                    bps;
            }
        } else {
            // AFTER tx, only affected tranche percentages change
            uint indexToRemove; // to track index of user in ethStakers array if account emptied
            bool indexNeedsRemoved = false; // to differentiate indexToRemove == 0 from default ethStakers[0]
            if (_isCooled == true && _isHeated == false) {
                // only Cooled tranche percentage numbers are affected by cooled tx
                for (
                    uint256 ethStakersIndex = 0;
                    ethStakersIndex < ethStakers[_poolId].length;
                    ethStakersIndex++
                ) {
                    address addrC = ethStakers[_poolId][ethStakersIndex];
                    ethStakedBalance[_poolId][addrC].cPercent =
                        (ethStakedBalance[_poolId][addrC].cBal * bps) /
                        pool[_poolId].cEthBal;
                    // Flags index and stores for removal AFTER calculations are finished
                    // #indexRemovalProblem
                    // if (
                    //     ethStakedBalance[_poolId][addrC].cBal <= 0 &&
                    //     ethStakedBalance[_poolId][addrC].hBal <= 0
                    // ) {
                    //     indexNeedsRemoved = true;
                    //     indexToRemove = ethStakersIndex;
                    // }
                }
            } else if (_isCooled == false && _isHeated == true) {
                // only Heated tranche percentage numbers are affected by heated tx
                for (
                    uint256 ethStakersIndex = 0;
                    ethStakersIndex < ethStakers[_poolId].length;
                    ethStakersIndex++
                ) {
                    address addrC = ethStakers[_poolId][ethStakersIndex];
                    ethStakedBalance[_poolId][addrC].hPercent =
                        (ethStakedBalance[_poolId][addrC].hBal * bps) /
                        pool[_poolId].hEthBal;
                    // #indexRemovalProblem
                    // Flags index and stores for removal AFTER calculations are finished
                    // if (
                    //     ethStakedBalance[_poolId][addrC].cBal <= 0 &&
                    //     ethStakedBalance[_poolId][addrC].hBal <= 0
                    // ) {
                    //     indexNeedsRemoved = true;
                    //     indexToRemove = ethStakersIndex;
                    // }
                }
            } else {
                // Cooled and Heated tranche percentage numbers are affected by tx
                for (
                    uint256 ethStakersIndex = 0;
                    ethStakersIndex < ethStakers[_poolId].length;
                    ethStakersIndex++
                ) {
                    address addrC = ethStakers[_poolId][ethStakersIndex];
                    ethStakedBalance[_poolId][addrC].cPercent =
                        (ethStakedBalance[_poolId][addrC].cBal * bps) /
                        pool[_poolId].cEthBal;
                    ethStakedBalance[_poolId][addrC].hPercent =
                        (ethStakedBalance[_poolId][addrC].hBal * bps) /
                        pool[_poolId].hEthBal;
                    // #indexRemovalProblem
                    // Flags index and stores for removal AFTER calculations are finished
                    // if (
                    //     ethStakedBalance[_poolId][addrC].cBal <= 0 &&
                    //     ethStakedBalance[_poolId][addrC].hBal <= 0
                    // ) {
                    //     indexNeedsRemoved = true;
                    //     indexToRemove = ethStakersIndex;
                    // }
                }
            }
            // Remove user if balances are empty, done after calculation so array indexes are not disrupted
            // #indexRemovalProblem
            // if (indexNeedsRemoved == true) {
            //     removeFromArray(_poolId, indexToRemove);
            // }
        }
    }

    /// LIQUIDATE-IF-ZERO /// - liquidates every user in a zero balance tranche
    function liquidateIfZero(uint _poolId) private {
        for (
            uint256 ethStakersIndex = 0;
            ethStakersIndex < ethStakers[_poolId].length;
            ethStakersIndex++
        ) {
            address addrC = ethStakers[_poolId][ethStakersIndex];
            if (pool[_poolId].cEthBal == 0) {
                // if tranche is liquidated, reset user to zero
                ethStakedBalance[_poolId][addrC].cPercent = 0;
                ethStakedBalance[_poolId][addrC].cBal = 0;
            }
            if (pool[_poolId].hEthBal == 0) {
                // if tranche is liquidated, reset user to zero
                ethStakedBalance[_poolId][addrC].hBal = 0;
                ethStakedBalance[_poolId][addrC].hPercent = 0;
            }
        }
    }

    /// VIEW-BALANCE-FUNCTIONS /// - check balances

    function retrieveCurrentPrice(uint _poolId) public view returns (uint) {
        // pool's priceFeedAddress is fed into the AggregatorV3Interface
        require(
            pool[_poolId].basePriceFeedKey != 0x0,
            "Pool_Is_Not_Initialized"
        );
        int price;
        if (pool[_poolId].quotePriceFeedKey == 0x0) {
            bytes32 aggregatorKey = pool[_poolId].basePriceFeedKey;
            address aggregatorAddress = address(aggregators[aggregatorKey]);
            AggregatorV3Interface priceFeed = AggregatorV3Interface(
                aggregatorAddress
            );
            (
                ,
                /*uint80 roundID*/
                price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
                ,
                ,

            ) = priceFeed.latestRoundData();
            // set number of decimals for token value
            uint priceFeedDecimals = 10**priceFeed.decimals();
            uint decimalDifference;
            if (priceFeedDecimals > usdDecimals) {
                // convert to native decimals for math
                decimalDifference = priceFeedDecimals / usdDecimals;
                price = price / int(decimalDifference);
            } else if (priceFeedDecimals < usdDecimals) {
                decimalDifference = usdDecimals / priceFeedDecimals;
                price = price * int(decimalDifference);
            }
            // return token price
            return uint256(price);
        } else {
            price = getDerivedPrice(
                address(aggregators[pool[_poolId].basePriceFeedKey]),
                address(aggregators[pool[_poolId].quotePriceFeedKey]),
                uint8(usdDecimalsUint)
            );
            return uint256(price);
        }
    }

    function getDerivedPrice(
        address _base,
        address _quote,
        uint8 _decimals
    ) public view returns (int256) {
        require(
            _decimals > uint8(0) && _decimals <= uint8(18),
            "Invalid _decimals"
        );
        int256 feedDecimals = int256(10**uint256(_decimals));
        (, int256 basePrice, , , ) = AggregatorV3Interface(_base)
            .latestRoundData();
        uint8 baseDecimals = AggregatorV3Interface(_base).decimals();
        basePrice = scalePrice(basePrice, baseDecimals, _decimals);

        (, int256 quotePrice, , , ) = AggregatorV3Interface(_quote)
            .latestRoundData();
        uint8 quoteDecimals = AggregatorV3Interface(_quote).decimals();
        quotePrice = scalePrice(quotePrice, quoteDecimals, _decimals);

        return (basePrice * feedDecimals) / quotePrice; //
    }

    function scalePrice(
        int256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) internal pure returns (int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10**uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10**uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

    function retrieveEthInContract() public view returns (uint) {
        return address(this).balance;
    }

    function retrieveCEthPercentBalance(uint _poolId, address _user)
        public
        view
        returns (uint)
    {
        return ethStakedBalance[_poolId][_user].cPercent;
    }

    function retrieveHEthPercentBalance(uint _poolId, address _user)
        public
        view
        returns (uint)
    {
        return ethStakedBalance[_poolId][_user].hPercent;
    }

    function retrieveCEthBalance(uint _poolId, address _user)
        public
        view
        returns (uint)
    {
        return ethStakedBalance[_poolId][_user].cBal;
    }

    function retrieveHEthBalance(uint _poolId, address _user)
        public
        view
        returns (uint)
    {
        return ethStakedBalance[_poolId][_user].hBal;
    }

    function retrieveAddressAtIndex(uint _poolId, uint _index)
        public
        view
        returns (address)
    {
        return ethStakers[_poolId][_index];
    }

    function retrieveProtocolCEthBalance(uint _poolId)
        public
        view
        returns (uint)
    {
        return pool[_poolId].cEthBal;
    }

    function retrieveProtocolHEthBalance(uint _poolId)
        public
        view
        returns (uint)
    {
        return pool[_poolId].hEthBal;
    }

    function retrieveProtocolEthPrice(
        uint _poolId //FIX
    ) public view returns (uint, uint) {
        return (
            pool[_poolId].currentUsdPrice,
            pool[_poolId].lastSettledUsdPrice
        );
    }

    /// STAKE-TOKENS /// - for future use with ERC-20s
    function stakeTokens(uint256 _amount, address _token) public {
        // Make sure that the amount to stake is more than 0
        require(_amount > 0, "Amount must be more than 0");
        // Check whether token is allowed by passing it to tokenIsAllowed()
        require(tokenIsAllowed(_token), "Token is not currently allowed.");

        // NOTES: transferFrom  --  ERC20s have transfer and transfer from.
        // Transfer only works if you call it from the wallet that owns the token

        // Transfer _amount of _token to the contract address
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        // Set the _token as one of the unique tokens staked by the staker
        updateUniquePositions(msg.sender, _token);
        // Update the staking balance for the staker
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        // If after this, the staker has just 1 token staked, then add the staker to stakers[] array
        if (uniquePositions[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    /// UPDATE-UNIQUE-POSITIONS /// - updates the mapping of user to tokens staked
    function updateUniquePositions(address _user, address _token) internal {
        // NOTES: I feel like it should be '>=' below instead

        // If the staking balance of the staker is less that or equal to 0 then...
        if (stakingBalance[_token][_user] <= 0) {
            // add 1 to the number of unique tokens staked
            uniquePositions[_user] = uniquePositions[_user] + 1;
        }
    }

    /// STAKE-TOKENS /// - add a token address to allowed tokens for staking, only owner can call
    function addAllowedTokens(address _token) public onlyOwner {
        // add token address to allowedTokens[] array
        allowedTokens.push(_token);
    }

    /// TOKEN-IS-ALLOWED /// - returns whether token is allowed
    function tokenIsAllowed(address _token) public view returns (bool) {
        // Loops through the array of allowedTokens[] for length of array
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            // If token at index matched the passed in token, return true
            if (allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }

    /// GET PROFIT /// - returns profit percentage in terms of basis points
    function getProfit(uint _poolId, uint256 _currentUsdPrice)
        public
        view
        returns (int256)
    {
        int256 profit = ((int(_currentUsdPrice) -
            int(pool[_poolId].lastSettledUsdPrice)) * int(bps)) /
            int(pool[_poolId].lastSettledUsdPrice);
        return profit;
    }

    /// TRANCHE SPECIFIC CALCS /// - calculates allocation difference for a tranche (also avoids 'stack too deep' error)
    function trancheSpecificCalcs(
        uint _poolId,
        bool _isCooled,
        int256 _assetUsdProfit,
        uint256 _currentAssetUsd
    )
        private
        view
        returns (
            int256,
            int256,
            uint256
        )
    {
        // TEMP
        // require(
        //     pool[_poolId].cEthBal > 0 || pool[_poolId].hEthBal > 0, // in Wei
        //     "Protocol must have funds in order to settle."
        // );
        uint256 trancheBal;
        int256 r;
        // get tranche balance and basis points for expected return
        if (_isCooled == true) {
            trancheBal = pool[_poolId].cEthBal; // in Wei
            r = pool[_poolId].cRate; // basis points
        } else {
            trancheBal = pool[_poolId].hEthBal; // in Wei
            r = pool[_poolId].hRate; // basis points
        }
        uint256 cooledRatio = ((pool[_poolId].cEthBal * bps) /
            (pool[_poolId].cEthBal + pool[_poolId].hEthBal));
        uint256 nonNaturalRatio = _assetUsdProfit > 0
            ? cooledRatio
            : ((1 * bps) - cooledRatio);
        // TEMP?
        // require(trancheBal > 0, "Tranche must have a balance.");
        int256 trancheChange = (int(trancheBal) * int(_currentAssetUsd)) -
            (int(trancheBal) * int(pool[_poolId].lastSettledUsdPrice));
        int256 expectedPayout;
        if (pool[_poolId].poolType == 0) {
            expectedPayout = (trancheChange * ((1 * int(bps)) + r)) / int(bps);
        } else if (pool[_poolId].poolType == 1) {
            if (cooledRatio > 50_0000000000) {
                expectedPayout =
                    (trancheChange * (int(bps) + ((r - int(cooledRatio))))) /
                    int(bps);
            } else {
                expectedPayout =
                    (trancheChange *
                        (int(bps) + ((r - (int(bps) - int(cooledRatio)))))) /
                    int(bps);
            }
        }
        int256 allocationDifference = expectedPayout - trancheChange;
        allocationDifference = allocationDifference / int(decimals);
        return (allocationDifference, trancheChange, nonNaturalRatio);
    }

    /// INTERACT /// - rebalances the cooled and heated tranches
    function interact(uint _poolId) private {
        uint256 currentAssetUsd = retrieveCurrentPrice(_poolId);
        pool[_poolId].currentUsdPrice = currentAssetUsd;
        int256 assetUsdProfit = getProfit(_poolId, currentAssetUsd); // returns ETH/USD profit in terms of basis points

        // find expected return and use it to calculate allocation difference for each tranche
        (
            int256 cooledAllocationDiff,
            int256 cooledChange,
            uint nonNaturalMultiplier
        ) = trancheSpecificCalcs(
                _poolId,
                true,
                assetUsdProfit,
                currentAssetUsd
            );
        (
            int256 heatedAllocationDiff,
            int256 heatedChange, // nonNaturalMultiplier excluded

        ) = trancheSpecificCalcs(
                _poolId,
                false,
                assetUsdProfit,
                currentAssetUsd
            );
        // use allocation differences to figure the absolute allocation total
        uint256 absAllocationTotal;
        {
            // scope to avoid 'stack too deep' error
            int256 absHeatedAllocationDiff = abs(heatedAllocationDiff);
            int256 absCooledAllocationDiff = abs(cooledAllocationDiff);
            int256 minAbsAllocation = absCooledAllocationDiff >
                absHeatedAllocationDiff
                ? absHeatedAllocationDiff
                : absCooledAllocationDiff;
            int256 nonNaturalDifference = heatedAllocationDiff +
                cooledAllocationDiff;

            uint256 adjNonNaturalDiff = (uint(abs(nonNaturalDifference)) *
                nonNaturalMultiplier) / bps;
            absAllocationTotal = uint(minAbsAllocation) + adjNonNaturalDiff;
        }
        // calculate the actual allocation for the cooled tranche
        int256 cooledAllocation;
        if (cooledAllocationDiff < 0) {
            if (
                // the cEthBal USD value - absAllocation (in usdDecimals)
                int((pool[_poolId].cEthBal * currentAssetUsd) / decimals) -
                    int(absAllocationTotal) >
                0
            ) {
                cooledAllocation = -int(absAllocationTotal);
            } else {
                cooledAllocation = -int(
                    (pool[_poolId].cEthBal * currentAssetUsd) / decimals
                ); // the cEthBal USD value (in UsDecimals * Decimals)
            }
        } else {
            if (
                int((pool[_poolId].hEthBal * currentAssetUsd) / decimals) -
                    int(absAllocationTotal) >
                0
            ) {
                cooledAllocation = int(absAllocationTotal); // absolute allocation in UsDecimals
            } else {
                cooledAllocation = int(
                    (pool[_poolId].hEthBal * currentAssetUsd) / decimals
                );
            }
        }

        reallocate(_poolId, currentAssetUsd, cooledChange, cooledAllocation); // reallocate the protocol ETH according to price movement
    }

    /// REALLOCATE /// - uses the USD values to calculate ETH balances of tranches
    function reallocate(
        uint _poolId,
        uint256 _currentAssetUsd, // in usdDecimal form
        int _cooledChange,
        int _cooledAllocation
    ) private {
        uint256 totalLockedUsd = ((pool[_poolId].cEthBal +
            pool[_poolId].hEthBal) * _currentAssetUsd) / decimals; // USD balance of protocol in usdDecimal terms
        int256 cooledBalAfterAllocation = ((int(
            pool[_poolId].cEthBal * pool[_poolId].lastSettledUsdPrice
        ) + _cooledChange) / int(decimals)) + _cooledAllocation;
        int256 heatedBalAfterAllocation = int(totalLockedUsd) - // heated USD balance in usdDecimal terms
            cooledBalAfterAllocation;
        pool[_poolId].cEthBal =
            (uint(cooledBalAfterAllocation) * decimals) /
            _currentAssetUsd; // new cEth Balance in Wei
        pool[_poolId].hEthBal =
            (uint(heatedBalAfterAllocation) * decimals) /
            _currentAssetUsd; // new hEth Balance in Wei
    }

    /// ABSOLUTE-VALUE /// - returns the absolute value of an int
    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }

    // /// SIMULATE INTERACT /// - view only of simulated rebalance of the cooled and heated tranches
    function simulateInteract(uint _poolId, uint _simAssetUsd)
        public
        view
        returns (uint, uint)
    {
        int256 assetUsdProfit = getProfit(_poolId, _simAssetUsd); // returns ETH/USD profit in terms of basis points

        // find expected return and use it to calculate allocation difference for each tranche
        (
            int256 cooledAllocationDiff,
            int256 cooledChange,
            uint nonNaturalMultiplier
        ) = trancheSpecificCalcs(_poolId, true, assetUsdProfit, _simAssetUsd);
        (
            int256 heatedAllocationDiff,
            int256 heatedChange,

        ) = trancheSpecificCalcs(_poolId, false, assetUsdProfit, _simAssetUsd);
        // use allocation differences to figure the absolute allocation total
        uint256 absAllocationTotal;
        {
            // scope to avoid 'stack too deep' error
            int256 absHeatedAllocationDiff = abs(heatedAllocationDiff);
            int256 absCooledAllocationDiff = abs(cooledAllocationDiff);
            int256 minAbsAllocation = absCooledAllocationDiff >
                absHeatedAllocationDiff
                ? absHeatedAllocationDiff
                : absCooledAllocationDiff;
            int256 nonNaturalDifference = heatedAllocationDiff +
                cooledAllocationDiff;

            uint256 adjNonNaturalDiff = (uint(abs(nonNaturalDifference)) *
                nonNaturalMultiplier) / bps;
            absAllocationTotal = uint(minAbsAllocation) + adjNonNaturalDiff;
        }

        return
            simulateReallocate(
                _poolId,
                _simAssetUsd,
                cooledChange,
                cooledAllocationDiff,
                absAllocationTotal
            ); // reallocate the protocol ETH according to price movement
    }

    /// REALLOCATE /// - uses the USD values to calculate ETH balances of tranches
    function simulateReallocate(
        uint _poolId,
        uint256 _simAssetUsd, // in usdDecimal form
        int _cooledChange,
        int _cooledAllocationDiff,
        uint _absAllocationTotal
    ) private view returns (uint, uint) {
        // calculate the actual allocation for the cooled tranche
        int256 cooledAllocation;
        if (_cooledAllocationDiff < 0) {
            if (
                // the cEthBal USD value - absAllocation (in usdDecimals)
                int((pool[_poolId].cEthBal * _simAssetUsd) / decimals) -
                    int(_absAllocationTotal) >
                0
            ) {
                cooledAllocation = -int(_absAllocationTotal);
            } else {
                cooledAllocation = -int(
                    (pool[_poolId].cEthBal * _simAssetUsd) / decimals
                ); // the cEthBal USD value (in UsDecimals * Decimals)
            }
        } else {
            if (
                int((pool[_poolId].hEthBal * _simAssetUsd) / decimals) -
                    int(_absAllocationTotal) >
                0
            ) {
                cooledAllocation = int(_absAllocationTotal); // absolute allocation in UsDecimals
            } else {
                cooledAllocation = int(
                    (pool[_poolId].hEthBal * _simAssetUsd) / decimals
                );
            }
        }
        uint256 totalLockedUsd = ((pool[_poolId].cEthBal +
            pool[_poolId].hEthBal) * _simAssetUsd) / decimals; // USD balance of protocol in usdDecimal terms
        int256 cooledBalAfterAllocation = ((int(
            pool[_poolId].cEthBal * pool[_poolId].lastSettledUsdPrice
        ) + _cooledChange) / int(decimals)) + cooledAllocation;
        int256 heatedBalAfterAllocation = int(totalLockedUsd) - // heated USD balance in usdDecimal terms
            cooledBalAfterAllocation;
        uint cEthSimBal = (uint(cooledBalAfterAllocation) * decimals) /
            _simAssetUsd; // new cEth Balance in Wei
        uint hEthSimBal = (uint(heatedBalAfterAllocation) * decimals) /
            _simAssetUsd; // new hEth Balance in Wei
        return (hEthSimBal, cEthSimBal);
    }

    function getRangeOfReturns(
        uint _poolId,
        address _address,
        bool _isCooled,
        bool _isAll
    ) public view returns (int[] memory) {
        uint assetUsdPrice = retrieveCurrentPrice(_poolId);
        int currentPercent = -50_0000000000;
        int assetUsdAtIndex;
        int[] memory estBals = new int[](11);
        for (uint index = 0; index < 11; index++) {
            assetUsdAtIndex =
                (int(assetUsdPrice) * (int(bps) + currentPercent)) /
                int(bps);
            uint hBalEst;
            uint cBalEst;
            (hBalEst, cBalEst) = simulateInteract(
                _poolId,
                uint(assetUsdAtIndex)
            );
            uint balanceRequested;
            if (_isCooled == false || _isAll == true) {
                balanceRequested =
                    (hBalEst * ethStakedBalance[_poolId][_address].hPercent) /
                    bps;
            }
            if (_isCooled == true || _isAll == true) {
                balanceRequested +=
                    (cBalEst * ethStakedBalance[_poolId][_address].cPercent) /
                    bps;
            }
            estBals[index] = int(balanceRequested);
            currentPercent += 10_0000000000;
        }

        return (estBals);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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