// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./XillionIDOCommon.sol";

/**
 * @title Contract for the Master IDO
 * @notice This contract is deployed before the actual IDOs, and is used by the IDOs to outsource business logic
 */
contract XillionIDOMaster is XillionIDOCommon {

    using SafeERC20 for XillionPoolToken;

    /* ------------------------------------------------------------ VARIABLES ----------------------------------------------------------- */

    /**
     * @notice Max amount of investors we can accept into the IDO
     * Exceeding that amount may make the contract exceed the block gas limit on completion of the IDO (finish function)
     * This amount is including Xillion that have a reserved slot into the IDO
     */
    uint256 constant MAX_INVESTORS = 1000;

    /**
     * @notice Max amount of potential investors we can process at once in the manual whitelist
     * Exceeding that amount may make the contract exceed the block gas limit when updating the manual whitelist
     */
    uint256 constant MAX_MANUAL_WHITELIST_BATCH = 400;


    /* ----------------------------------------------------------- CONSTRUCTOR ---------------------------------------------------------- */

    /**
     * @notice Called on creation of the master IDO contract
     * @param ownerAddr_ Address of the owner of this contract (most likely a multi SIG wallet)
     */
    constructor(address ownerAddr_) {
        require(ownerAddr_ != address(0), "Invalid owner");
        // transfer ownership
        if (_msgSender() != ownerAddr_) {
            transferOwnership(ownerAddr_);
        }
    }

    /* --------------------------------------------------------- MAIN ACTIVITIES -------------------------------------------------------- */

    /**
     * @notice Creates or updates a sender's allocation size. An existing allocation size can only be increased, not decreased.
     */
    function joinOrRecalculateAllocation() external whenNotPaused {

        // whenAllocationsAreOpen
        require(allocationStartDate <= block.timestamp && block.timestamp < allocationEndDate, "Alloc closed");

        // request the sender's staking data

        // check they have stakes
        uint256 stakesLength = _stakingContract.getStakeCountForAddress(_msgSender());
        require(stakesLength > 0, "Not staking");

        uint256 amountStaked;
        address stakingToken = address(_stakingContract.stakingToken());

        // loop through stakes
        for (uint256 i; i < stakesLength; i++) {

            uint256 amount;
            uint256 daysLocked;
            uint256 releaseDate;
            bytes32 uid;
            address token;
            (amount, daysLocked, releaseDate, uid, token) = _stakingContract.getStakeForAddress(_msgSender(), i);

            // pass the tokens that are not the staking token // XIL-107 add a test to check this
            if (token != stakingToken) {
                continue;
            }

            // if the stake is past the releaseDate, increase the days locked according to how many extra days the stake stayed within the Staking contract
            if (releaseDate < block.timestamp) {
                daysLocked += ((block.timestamp - releaseDate) / 1 days);
            }

            // check the stake duration is at least the minimum required for this IDO
            if (daysLocked >= minStakingDays) {

                // add amount staked to the sender's total stake
                amountStaked += amount;

            }

        }


        // Determine the sender's allocation multiplier depending on how many XIL they are staking for the minimum staking period and according to the IDO's allocation tiers
        uint256 allocationTierMultiplier;

        // run allocation tiers from highest to smallest to determine which tier the sender's stake belongs to
        for (uint256 j = _allocationTiers.length; j > 0; j--) {

            uint256 index = j - 1;

            // check if the sender is staking more than this tier's minimum
            if (amountStaked >= _allocationTiers[index].minXILAmount) {

                // set the multiplier and exit the loop
                allocationTierMultiplier = _allocationTiers[index].allocationSizeMultiplier;
                break;

            }

        }

        require(allocationTierMultiplier > 0, "Insufficient staking");

        // calculate allocation size in Staking Token units
        uint256 allocationSize = amountStaked * allocationTierMultiplier / (10 ** getAllocationSizeMultiplierTierDecimals());

        // finally convert allocationSize from Staking Token to Chain Currency
        uint256 xilToChainCurrencyAllocationSizeRatio = factory.xilToChainCurrencyAllocationSizeRatio();
        allocationSize = allocationSize * xilToChainCurrencyAllocationSizeRatio / (10 ** getXilToChainCurrencyAllocationSizeRatioDecimals());

        // check we don't exceed the max investment amount per investor
        allocationSize = Math.min(allocationSize, maxInvestmentAmountPerInvestor);


        // if the sender doesn't have an existing allocation size, add the sender to the list of stakers
        if (_stakingAllocationSizeList[_msgSender()] == 0) {
            _stakers.push(_msgSender());
        }

        // if the allocation is bigger than the existing, or there is no existing, set allocation size and update total allocated amount
        if (allocationSize > _stakingAllocationSizeList[_msgSender()]) {

            // increase total allocation size and emit events if applicable (new allocation size is the highest of existing staking & manual whitelist)
            uint256 currentlyAllocatedAmount = Math.max(_manualAllocationSizeList[_msgSender()], _stakingAllocationSizeList[_msgSender()]);
            if (allocationSize > currentlyAllocatedAmount) {
                totalAllocatedAmount += (allocationSize - currentlyAllocatedAmount);
                emit AllocationSizeUpdated(_msgSender(), allocationSize);
                emit TotalAllocatedAmountUpdated(totalAllocatedAmount);
            }

            // set allocation size
            _stakingAllocationSizeList[_msgSender()] = allocationSize;

        }

    }

    // function calculateAllocation(uint256 _stakeAmount, uint256 _duration) public view returns(uint256){

    //     require(_duration == 7 || _duration == 14 || _duration == 28, "Incorrect duration");

    //     uint256 potentialAllocationSize;

    //     // Determine the sender's allocation multiplier depending on how many XIL they are staking for the minimum staking period and according to the IDO's allocation tiers
    //     uint256 allocationTierMultiplier;

    //    // run allocation tiers from highest to smallest to determine which tier the sender's stake belongs to
        
    //     for (uint256 j = _allocationTiers.length; j > 0; j--) {

    //         uint256 index = j - 1;

    //         // check if the sender is staking more than this tier's minimum
    //         if (_stakeAmount >= _allocationTiers[index].minXILAmount) {

    //             // set the multiplier and exit the loop
    //             allocationTierMultiplier = _allocationTiers[index].allocationSizeMultiplier;
    //             break;

    //         }

    //     }
    //     // calculate allocation size in Staking Token units
    //     potentialAllocationSize = _stakeAmount * allocationTierMultiplier / (10 ** getAllocationSizeMultiplierTierDecimals());

    //     // finally convert allocationSize from Staking Token to Chain Currency
    //     uint256 xilToChainCurrencyAllocationSizeRatio = factory.xilToChainCurrencyAllocationSizeRatio();
    //     potentialAllocationSize = potentialAllocationSize * xilToChainCurrencyAllocationSizeRatio / (10 ** getXilToChainCurrencyAllocationSizeRatioDecimals());

    //     if(_duration == 14){
    //        potentialAllocationSize = potentialAllocationSize * 2;
    //     }
    //     if(_duration == 28){
    //        potentialAllocationSize = potentialAllocationSize * 3;
    //     }

    //     if(potentialAllocationSize > 0){
    //         return potentialAllocationSize;
    //     }else{
    //         return 0;
    //     }
    // }


    /**
     * @notice Lets the sender invest into the IDO
     */
    function invest() external payable whenNotPaused {

        // whenSwapIsOpen
        require(swapStartDate <= block.timestamp && block.timestamp < swapEndDate, "Swap closed");

        // make sure we don't exceed the amount of investors - 999 + Xillion
        // existing investors won't take up another spot
        if (_msgSender() != _xillionWalletAddress && _investments[_msgSender()] == 0) {
            uint256 maxInvestors = MAX_INVESTORS;
            // if Xillion are not already in the investors list, make sure we reserve a spot for them
            if (_investments[_xillionWalletAddress] == 0) {
                maxInvestors--;
            }
            // make sure there is 1 spot left for the new investor
            require(_investors.length < maxInvestors, "Max investors reached");
        }

        // make sure the sender has an allocation
        uint256 allocationSize = Math.max(
            _manualAllocationSizeList[_msgSender()],
            _stakingAllocationSizeList[_msgSender()]
        );
        require(allocationSize > 0, "No allocation");

        // determine sender's investment
        uint256 newInvestment = msg.value;

        // add new amount to total invested amount and check the IDO cap hasn't been exceeded
        totalInvestedAmount += newInvestment;
        require(totalInvestedAmount <= idoValueCap, "Value cap exceeded");

        // add any existing investment to check allocation size
        uint256 existingInvestment = _investments[_msgSender()];
        if (existingInvestment > 0) {
            newInvestment += existingInvestment;
        } else {
            // if there is no existing investment, this is a new investor
            _investors.push(_msgSender());
        }

        // check the sender's total investment equals their allocation size
        require(newInvestment == allocationSize, "Incorrect amount");

        // set the sender's new investment
        _investments[_msgSender()] = newInvestment;
        emit InvestmentUpdated(_msgSender(), newInvestment, totalInvestedAmount);

    }

    /**
     * @notice Lets the sender invest into the IDO in ERC20 token
     */
    function investBEP20(uint256 _tokenAmount) external whenNotPaused {

        // whenSwapIsOpen
        require(swapStartDate <= block.timestamp && block.timestamp < swapEndDate, "Swap closed");

        // make sure we don't exceed the amount of investors - 999 + Xillion
        // existing investors won't take up another spot
        if (_msgSender() != _xillionWalletAddress && _investmentsInBEP20[_msgSender()] == 0) {
            uint256 maxInvestors = MAX_INVESTORS;
            // if Xillion are not already in the investorsOfERC20 list, make sure we reserve a spot for them
            if (_investmentsInBEP20[_xillionWalletAddress] == 0) {
                maxInvestors--;
            }
            // make sure there is 1 spot left for the new investorOfERC20
            require(_invesotrsOfBEP20.length < maxInvestors, "Max investors reached");
        }

        // make sure the sender has an allocationOfERC20
        uint256 allocationSize = Math.max(
            _manualAllocationSizeList[_msgSender()],
            _stakingAllocationSizeList[_msgSender()]
        ); 
         
        if(BEP20IdoTokenAddress == xillTokenAddress){
            allocationSize = (allocationSize * 10 ** getXilToChainCurrencyAllocationSizeRatioDecimals())/ factory.xilToChainCurrencyAllocationSizeRatio();
        }else{
            allocationSize = (allocationSize * 10 ** getXilToChainCurrencyAllocationSizeRatioDecimals())/ factory.busdToChainCurrencyAllocationSizeRatio();
        } 

        require(allocationSize > 0, "No allocation");
        IERC20 tokenInstance = IERC20(BEP20IdoTokenAddress);

        require(tokenInstance.balanceOf(_msgSender()) >= _tokenAmount, "Not enough tokens on balance");

        // determine sender's investmentOfERC20
        uint256 newInvestment = _tokenAmount;

        // check the sender's total investment equals their allocation size
        require(newInvestment == allocationSize, "Incorrect amount");


        // add new amount to total invested amount in ERC20 and check the IDO capInERC20 hasn't been exceeded
        totalInvestedAmountInBEP20 += newInvestment;

        require(totalInvestedAmountInBEP20 <= BEP20IdoValueCap, "Value cap exceeded");

        tokenInstance.transferFrom(msg.sender, address(this), _tokenAmount);

        // add any existing investmentInERC20 to check allocation size
        uint256 existingInvestment = _investmentsInBEP20[_msgSender()];
        if (existingInvestment > 0) {
            newInvestment += existingInvestment;
        } else {
            // if there is no existing investmentInERC20, this is a new investor
            _invesotrsOfBEP20.push(_msgSender());
        }


        // set the sender's new investment
        _investmentsInBEP20[_msgSender()] = newInvestment;
        emit InvestmentBEP20Updated(_msgSender(), newInvestment, totalInvestedAmountInBEP20, BEP20IdoTokenAddress);

    }

    /**
     * @notice Ends the Swap phase – it will either complete successfully or fail depending on the investment and success threshold
     */
    function finish() external onlyOwner nonReentrant {

        // onlyAfterSwapEnd
        require(block.timestamp > swapEndDate, "Swap open");

        // check if we reached the success threshold
        if (totalInvestedAmount >= idoValueCap * minInvestmentPercentForIDOCompletion / 100) {
            uint256 totalInvestedAmountOfIDOInChainCurrency;
            uint256 totalIdoValueCapInChainCurrency;

            // check if we reached the success threshold for ERC-20 invested tokens
            if (BEP20IdoTokenAddress != address(0)) {
                bool isSuccessfullyFunded;
                if (totalInvestedAmountInBEP20 < BEP20IdoValueCap * minInvestmentPercentOfBEP20ForIDOCompletion / 100) {
                    isSuccessfullyFunded = false;

                } else {
                    isSuccessfullyFunded = true;
                    uint256 xilToChainCurrencyAllocationSizeRatio = factory.xilToChainCurrencyAllocationSizeRatio();
                    uint256 busdToChainCurrencyAllocationSizeRatio = factory.busdToChainCurrencyAllocationSizeRatio();
                    uint256 tokenInvestendInChainCurrency;
                    uint256 tokenIdoValueCapInChainCurrency;
                    if (BEP20IdoTokenAddress == xillTokenAddress) {
                        tokenInvestendInChainCurrency = xilToChainCurrencyAllocationSizeRatio * totalInvestedAmountInBEP20;
                        tokenIdoValueCapInChainCurrency = xilToChainCurrencyAllocationSizeRatio * BEP20IdoValueCap;
                    } else {
                        tokenInvestendInChainCurrency = busdToChainCurrencyAllocationSizeRatio * totalInvestedAmountInBEP20;
                        tokenIdoValueCapInChainCurrency = busdToChainCurrencyAllocationSizeRatio * BEP20IdoValueCap;
                    }
                    totalInvestedAmountOfIDOInChainCurrency = totalInvestedAmount + tokenInvestendInChainCurrency;
                    totalIdoValueCapInChainCurrency = idoValueCap + tokenIdoValueCapInChainCurrency;
                }
                require(isSuccessfullyFunded, "Not all ERC20 tokens reached success threshold");
            }


            // set state to Claim
            _state = IDOState.Claim;
            emit IDOStateUpdated(IDOState.Claim);

            // calculate how many Pool Tokens are to be vested
            uint256 finalSupply = numberOfPoolTokens * totalInvestedAmountOfIDOInChainCurrency / totalIdoValueCapInChainCurrency;
            uint256 tokensToDistribute;

            // process investors' tokens first
            uint256 investorTokens = finalSupply * investorsPoolTokenSharePercent / 100;
            uint256 finalInvestorsAmount = Math.min(_investors.length, MAX_INVESTORS);
            for (uint256 i; i < finalInvestorsAmount; i++) {

                // calculate amount & release date for investor
                tokensToDistribute = investorTokens * _investments[_investors[i]] / totalInvestedAmount;
                // add shares for investor
                poolTokenShares[_investors[i]] = tokensToDistribute;
                // increment total shares
                totalShares += tokensToDistribute;

            }

            // calculate amount & release date for Little Phil
            tokensToDistribute = finalSupply * littlePhilPoolTokenSharePercent / 100;
            // add shares for Little Phil
            poolTokenShares[_littlePhilWalletAddress] += tokensToDistribute;
            // increment total shares
            totalShares += tokensToDistribute;

            // calculate amount & release date for the curator
            tokensToDistribute = finalSupply * curatorPoolTokenSharePercent / 100;
            // add shares for the curator
            poolTokenShares[_curatorWalletAddress] += tokensToDistribute;
            // increment total shares
            totalShares += tokensToDistribute;

            // calculate amount & release date for Xillion
            tokensToDistribute = finalSupply * xillionPoolTokenSharePercent / 100;
            // add shares for Xillion
            poolTokenShares[_xillionWalletAddress] += tokensToDistribute;
            // increment total shares
            totalShares += tokensToDistribute;

            // now burn remaining tokens that were not distributed
            uint256 tokensToBurn = _poolToken.balanceOf(address(this)) - totalShares;
            if (tokensToBurn > 0) {
                _poolToken.burn(tokensToBurn);
            }

        } else {

            // set state to Refund
            _state = IDOState.Refund;
            emit IDOStateUpdated(IDOState.Refund);

        }

    }


    /**
     * @notice Kills the IDO (i.e. refunds it) regardless of the investment and success threshold
     */
    function kill() external onlyOwner {

        // notClaimNorRefundState
        require(_state != IDOState.Claim && _state != IDOState.Refund, "Invalid state");

        // set swap end date to now
        swapEndDate = block.timestamp;

        // set state to Refund
        _state = IDOState.Refund;

        // emit event
        emit IDOKilled();

    }

    /**
     * @notice Lets investors, the curator, Xillion and Little Phil claim their Pool Tokens after the vesting period
     */
    function claimPoolTokens() external nonReentrant {

        onlyClaimState();

        uint256 amountVested = poolTokenShares[_msgSender()];
        require(amountVested > 0, "No vesting");

        uint256 releaseDate;
        if (_msgSender() == _xillionWalletAddress) {
            releaseDate = swapEndDate + (xillionPoolTokenVestingDays * 1 days);
        } else if (_msgSender() == _curatorWalletAddress) {
            releaseDate = swapEndDate + (curatorPoolTokenVestingDays * 1 days);
        } else if (_msgSender() == _littlePhilWalletAddress) {
            releaseDate = swapEndDate + (littlePhilPoolTokenVestingDays * 1 days);
        } else {
            releaseDate = swapEndDate + (investorsPoolTokenVestingDays * 1 days);
        }

        require(block.timestamp >= releaseDate, "Vesting ongoing");

        _poolToken.safeTransfer(_msgSender(), amountVested);

        delete poolTokenShares[_msgSender()];
        totalReleased += amountVested;

        emit PoolTokensClaimed(_msgSender(), amountVested);

    }

    /**
     * @notice Refunds invested Chain Currency if the IDO was refunded
     */
    function claimRefundedInvestment() external nonReentrant {

        // onlyRefundState
        require(_state == IDOState.Refund, "Invalid state");

        // retrieve investment in BEP20 token
        uint256 tokenAmount = _investmentsInBEP20[_msgSender()];

        // retrieve investment
        uint256 amount = _investments[_msgSender()];

        // onlyRefundState
        require(tokenAmount + amount > 0, "No investment");

        if (amount > 0) {
            // refund chain currency
            Address.sendValue(payable(_msgSender()), amount);
            emit RefundedInvestmentClaimed(_msgSender(), amount);

            // reset investment
            delete _investments[_msgSender()];
        }
        if (tokenAmount > 0) {
            // refund BEP20 tokens
            IERC20 tokenInstance = IERC20(BEP20IdoTokenAddress);
            tokenInstance.transfer(_msgSender(), tokenAmount);
            emit RefundedInvestmentClaimedInBEP20(_msgSender(), tokenAmount);

            // reset BEP20 investment
            delete _investmentsInBEP20[_msgSender()];
        }
    }

    /**
     * @notice Transfers the invested Chain Currency amount and ERC20 tokens to the Chain Currency recipient once the sale is closed
     */
    function claimTotalInvestedAmount() external nonReentrant {

        onlyClaimState();

        // onlyChainCurrencyRecipient
        require(_msgSender() == _chainCurrencyRecipientWalletAddress, "Invalid address");

        Address.sendValue(_chainCurrencyRecipientWalletAddress, totalInvestedAmount);

        // loop through all ERC20 invested tokens and transfer it to Chain Currency recipient
        IERC20 tokenInstance = IERC20(BEP20IdoTokenAddress);
        tokenInstance.transfer(_chainCurrencyRecipientWalletAddress, totalInvestedAmountInBEP20);

    }

    /* ------------------------------------------------------------- MUTATORS ----------------------------------------------------------- */

    /**
     * @notice Sets the Pool Token share percentages
     * @param poolTokenSharePercentages_ New Pool Token share percentages
     */
    function setPoolTokenSharePercentages(XillionIDOStructs.PoolTokenSharePercentage calldata poolTokenSharePercentages_) external onlyOwner {

        onlyBeforeSwapStartDate();

        require(
            poolTokenSharePercentages_.investors +
            poolTokenSharePercentages_.curator +
            poolTokenSharePercentages_.xillion +
            poolTokenSharePercentages_.littlePhil
            == 100,
            "Not 100%");

        investorsPoolTokenSharePercent = poolTokenSharePercentages_.investors;
        curatorPoolTokenSharePercent = poolTokenSharePercentages_.curator;
        xillionPoolTokenSharePercent = poolTokenSharePercentages_.xillion;
        littlePhilPoolTokenSharePercent = poolTokenSharePercentages_.littlePhil;

        emit PoolTokenSharePercentagesUpdated(
            poolTokenSharePercentages_.investors,
            poolTokenSharePercentages_.curator,
            poolTokenSharePercentages_.xillion,
            poolTokenSharePercentages_.littlePhil
        );

    }

    /**
     * @notice Sets the Pool Token vesting periods in days
     * @param poolTokenVestingDays_ New Pool Token vesting periods in days
     */
    function setPoolTokenVestingDays(XillionIDOStructs.PoolTokenVestingDays calldata poolTokenVestingDays_) external onlyOwner {

        onlyBeforeSwapStartDate();

        investorsPoolTokenVestingDays = poolTokenVestingDays_.investors;
        curatorPoolTokenVestingDays = poolTokenVestingDays_.curator;
        xillionPoolTokenVestingDays = poolTokenVestingDays_.xillion;
        littlePhilPoolTokenVestingDays = poolTokenVestingDays_.littlePhil;

        emit PoolTokenVestingDaysUpdated(
            poolTokenVestingDays_.investors,
            poolTokenVestingDays_.curator,
            poolTokenVestingDays_.xillion,
            poolTokenVestingDays_.littlePhil
        );

    }

    /**
     * @notice Sets the critical wallet addresses
     * @param walletAddresses_ New critical wallet addresses
     */
    function setWalletAddresses(XillionIDOStructs.WalletAddress calldata walletAddresses_) external onlyOwner {

        onlyBeforeSwapStartDate();

        require(
            walletAddresses_.chainCurrencyRecipient != address(0)
            && walletAddresses_.curator != address(0)
            && walletAddresses_.xillion != address(0)
            && walletAddresses_.littlePhil != address(0), "Invalid address");

        _chainCurrencyRecipientWalletAddress = payable(walletAddresses_.chainCurrencyRecipient);
        _curatorWalletAddress = walletAddresses_.curator;
        _xillionWalletAddress = walletAddresses_.xillion;
        _littlePhilWalletAddress = walletAddresses_.littlePhil;

    }

    /**
     * @notice Sets the allocation start date
     * @param allocationStartDate_ New allocation start date
     */
    function setAllocationStartDate(uint256 allocationStartDate_) external onlyOwner {

        notInClaimState();

        // do not proceed if current allocation start date is set and is in the past
        if (allocationStartDate != 0) {
            require(allocationStartDate > block.timestamp, "Forbidden");
        }

        require(allocationStartDate_ != 0, "Invalid date");

        // do not proceed if allocationStartDate_ is after allocationEndDate (if set)
        if (allocationEndDate != 0) {
            require(allocationStartDate_ < allocationEndDate, "Wrong order");
        }

        allocationStartDate = allocationStartDate_;
        emit AllocationStartDateUpdated(allocationStartDate_);

    }

    /**
     * @notice Sets the allocation end date
     * @param allocationEndDate_ New allocation end date
     */
    function setAllocationEndDate(uint256 allocationEndDate_) external onlyOwner {
        notInClaimState();
        require(allocationEndDate_ != 0 && allocationEndDate_ > allocationStartDate, "Invalid date");
        allocationEndDate = allocationEndDate_;
        emit AllocationEndDateUpdated(allocationEndDate_);
    }

    /**
     * @notice Sets the swap start date
     * @param swapStartDate_ New swap start date
     */
    function setSwapStartDate(uint256 swapStartDate_) external onlyOwner {

        notInClaimState();

        // do not proceed if current swap start date is set and is in the past
        if (swapStartDate != 0) {
            require(swapStartDate > block.timestamp, "Forbidden");
        }

        require(swapStartDate_ != 0, "Invalid date");

        // do not proceed if swapStartDate_ is after swapEndDate (if set)
        if (swapEndDate != 0) {
            require(swapStartDate_ < swapEndDate, "Wrong order");
        }

        swapStartDate = swapStartDate_;
        emit SwapStartDateUpdated(swapStartDate_);

    }

    /**
     * @notice Sets the swap end date
     * @param swapEndDate_ New swap end date
     */
    function setSwapEndDate(uint256 swapEndDate_) external onlyOwner {
        notInClaimState();
        require(swapEndDate_ != 0 && swapEndDate_ > swapStartDate, "Invalid date");
        swapEndDate = swapEndDate_;
        emit SwapEndDateUpdated(swapEndDate_);
    }

    /**
     * @notice Sets the allocation tiers and check they are sorted from lowest to highest tier
     * @param allocationTiers_ The new allocation tiers
     */
    function setAllocationTiers(XillionIDOStructs.AllocationTier[] calldata allocationTiers_) external onlyOwner {

        require(allocationTiers_.length > 0, "No tier");

        // reset the old array
        delete _allocationTiers;

        // push the first allocation tier
        _allocationTiers.push(allocationTiers_[0]);

        // loop through higher allocation tiers if any
        for (uint256 i = 1; i < allocationTiers_.length; i++) {

            // check that the allocation tiers are sorted from lowest to highest range
            require(
                allocationTiers_[i].minXILAmount > allocationTiers_[i - 1].minXILAmount,
                "Wrong order"
            );

            // push the allocation tier
            _allocationTiers.push(allocationTiers_[i]);

        }

        emit AllocationTiersUpdated(allocationTiers_);

    }

    /**
     * @notice Sets the investment details
     * @param investmentDetails_ New investment details
     */
    function setInvestmentDetails(XillionIDOStructs.InvestmentDetails calldata investmentDetails_) external onlyOwner {

        require(investmentDetails_.minInvestmentPercentForIDOCompletion <= 100,
            "Invalid percentages");

        maxInvestmentAmountPerInvestor = investmentDetails_.maxInvestmentAmountPerInvestor;
        minInvestmentPercentForIDOCompletion = investmentDetails_.minInvestmentPercentForIDOCompletion;

        minStakingDays = investmentDetails_.minStakingDays;
        _stakingContract = XillionAccessStaking(investmentDetails_.stakingContractAddress);

        emit InvestmentDetailsUpdated(
            investmentDetails_.maxInvestmentAmountPerInvestor,
            investmentDetails_.minInvestmentPercentForIDOCompletion,
            investmentDetails_.minStakingDays,
            investmentDetails_.stakingContractAddress
        );

    }

    /**
     * @notice Updates the list of manually whitelisted accounts and their arbitrary allocation size
     * This only updates a subset of entries (including removing by setting 0), it does not override the whole list
     * @param manualWhitelist_ The list of accounts that are manually whitelisted
     * @param manualAllocationSizeList_ The list of allocation size manually set to the whitelisted accounts
     */
    function updateManualAllocationSizeList(
        address[] calldata manualWhitelist_,
        uint256[] calldata manualAllocationSizeList_
    ) external onlyOwner {

        // we cannot go over MAX_MANUAL_WHITELIST_BATCH whitelisted potential investors at once otherwise we exceed the block gas limit
        require(manualWhitelist_.length <= MAX_MANUAL_WHITELIST_BATCH, "MAX_MANUAL_WHITELIST_BATCH");

        // we need to have the same bounds for the manualWhitelist and the manualAllocationSizeList
        require(manualWhitelist_.length == manualAllocationSizeList_.length, "Length mismatch");

        // loop through manually whitelisted accounts
        for (uint256 i; i < manualWhitelist_.length; i++) {

            address account = manualWhitelist_[i];
            uint256 newManualAllocationSize = manualAllocationSizeList_[i];
            uint256 originalManualAllocationSize = _manualAllocationSizeList[account];

            // check if the manual allocation has changed
            if (newManualAllocationSize != originalManualAllocationSize) {

                uint256 stakingAllocationSize = _stakingAllocationSizeList[account];
                uint256 newAllocationSize = Math.max(newManualAllocationSize, stakingAllocationSize);
                uint256 oldAllocationSize = Math.max(originalManualAllocationSize, stakingAllocationSize);

                // check if the allocation size has changed
                if (newAllocationSize > oldAllocationSize) {

                    totalAllocatedAmount += newAllocationSize - oldAllocationSize;
                    emit AllocationSizeUpdated(account, newAllocationSize);

                } else if (newAllocationSize < oldAllocationSize) {

                    totalAllocatedAmount -= oldAllocationSize - newAllocationSize;
                    emit AllocationSizeUpdated(account, newAllocationSize);

                }

                // update allocation size
                _manualAllocationSizeList[account] = newManualAllocationSize;

            }

        }

        emit TotalAllocatedAmountUpdated(totalAllocatedAmount);

    }

    /* ------------------------------------------------------------ MODIFIERS ----------------------------------------------------------- */
    /* --------------------------- Using private functions instead of modifiers to save on deployment size ------------------------------ */

    /**
     * @notice Guard to only proceed before the Swap phase (if it has been set)
     * @dev Requires that current time is before swapStartDate
     */
    function onlyBeforeSwapStartDate() private view {
        if (swapStartDate != 0) {
            require(block.timestamp < swapStartDate, "Swap started");
        }
    }

    /**
     * @notice Guard to only proceed when the IDO state is Claim
     */
    function onlyClaimState() private view {
        require(_state == IDOState.Claim, "Invalid state");
    }

    /**
     * @notice Guard to only proceed when the IDO state is NOT Claim
     */
    function notInClaimState() private view {
        require(_state != IDOState.Claim, "Invalid state");
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./libraries/XillionIDOStructs.sol";
import "./utils/OwnablePausable.sol";
import "./XillionAccessStaking.sol";
import "./XillionIDOFactory.sol";
import "./XillionPoolToken.sol";

/**
 * @title Common code for IDOs and Master IDO
 */
contract XillionIDOCommon is OwnablePausable, ReentrancyGuard {

    /* ------------------------------------------------------------ VARIABLES ----------------------------------------------------------- */

    /**
     * @notice IDO Factory that created this IDO
     */
    XillionIDOFactory public factory;

    /**
     * @notice IDO Factory that created this IDO
     */
    address public xillTokenAddress;

    /**
     * @notice Current status of the IDO
     */
    IDOState internal _state = IDOState.Computed;

    /**
     * @notice Max amount of Chain Currency the IDO can accept
     */
    uint256 public idoValueCap;

    /**
     * @notice Max amount of ERC20 token the IDO can accept
     */
    uint256 public BEP20IdoValueCap;

    /**
     * @notice All invested ERC20 tokens
     */
    address public BEP20IdoTokenAddress;

    /**
     * @notice Amount of Pool Tokens minted at the start of the IDO
     */
    uint256 public numberOfPoolTokens;

    /**
     * @notice Allocation start date
     */
    uint256 public allocationStartDate;

    /**
     * @notice Allocation end date
     */
    uint256 public allocationEndDate;

    /**
     * @notice Swap start date
     */
    uint256 public swapStartDate;

    /**
     * @notice Swap end date
     */
    uint256 public swapEndDate;

    /**
     * @notice Max investment amount per investor, in the chain currency's smallest denomination
     */
    uint256 public maxInvestmentAmountPerInvestor;

    /**
     * @notice Max investment amount per investor, in the ERC20 token smallest denomination
     */
    uint256 public maxInvestmentBEP20AmountPerInvestor;

    /**
     * @notice Min % investment for IDO successful completion
     */
    uint256 public minInvestmentPercentForIDOCompletion;

    /**
     * @notice Min % investment of ERC20 for IDO successful completion
     */
    uint256 public minInvestmentPercentOfBEP20ForIDOCompletion;

    /**
     * @notice Minimum staking duration
     */
    uint256 public minStakingDays;

    /**
     * @notice XIL Staking contract for IDO allocation
     */
    XillionAccessStaking internal _stakingContract;

    /**
     * @notice Share of the Pool Tokens that will be distributed to the IDO participants in %
     */
    uint256 public investorsPoolTokenSharePercent;

    /**
     * @notice Share of the Pool Tokens that will be distributed to the curator in %
     */
    uint256 public curatorPoolTokenSharePercent;

    /**
     * @notice Share of the Pool Tokens that will be distributed to Xillion in %
     */
    uint256 public xillionPoolTokenSharePercent;

    /**
     * @notice Share of the Pool Tokens that will be distributed to Little Phil in %
     */
    uint256 public littlePhilPoolTokenSharePercent;

    /**
     * @notice Vesting period of the Pool Tokens for IDO participants in days
     */
    uint256 public investorsPoolTokenVestingDays;

    /**
     * @notice Vesting period of the Pool Tokens for the curator in days
     */
    uint256 public curatorPoolTokenVestingDays;

    /**
     * @notice Vesting period of the Pool Tokens for Xillion in days
     */
    uint256 public xillionPoolTokenVestingDays;

    /**
     * @notice Vesting period of the Pool Tokens for Little Phil in days
     */
    uint256 public littlePhilPoolTokenVestingDays;

    /**
     * @notice Wallet address of the Chain Currency recipient
     */
    address payable internal _chainCurrencyRecipientWalletAddress;

    /**
     * @notice Wallet address of the curator
     */
    address internal _curatorWalletAddress;

    /**
     * @notice Wallet address of Xillion
     */
    address internal _xillionWalletAddress;

    /**
     * @notice Wallet address of Little Phil
     */
    address internal _littlePhilWalletAddress;

    /**
     * @notice Allocation rules/tiers
     * @dev (staking range mins and multipliers)
     */
    XillionIDOStructs.AllocationTier[] internal _allocationTiers;

    /**
     * @notice Manual "whitelist"
     * @dev (address -> allocation size in Chain Currency)
     */
    mapping(address => uint256) internal _manualAllocationSizeList;

    /**
     * @notice The ERC20 Pool Token created by the IDO that will be used to interact with the corresponding Pool of NFTs
     */
    XillionPoolToken internal _poolToken;

    /**
     * @notice List of addresses that chose to join the IDO through the staking program
     */
    address[] internal _stakers;

    /**
     * @notice Staking "whitelist"
     * @dev (address -> allocation size in Chain Currency)
     */
    mapping(address => uint256) internal _stakingAllocationSizeList;

    /**
     * @notice List of investors (people who sent Chain Currency to this contract)
     */
    address[] internal _investors;

    /**
     * @notice List of investors (people who sent ERC20 to this contract)
     */
    address[] public _invesotrsOfBEP20;

    /**
     * @notice List of total investments into this contract
     * @dev (wallet address => total Chain Currency amount invested)
     */
    mapping(address => uint256) internal _investments;

    /**
     * @notice List of total investments into this contract in ERC20 token
     * @dev (token address => user address => total ERC20 token amount invested)
     */
    mapping(address => uint256) public _investmentsInBEP20;

    /**
     * @notice Amount of Chain Currency sent into this contract
     */
    uint256 public totalInvestedAmount;

    /**
     * @notice Amount of BEP20 sent into this contract
     */
    uint256 public totalInvestedAmountInBEP20;

    /**
     * @notice Amount of Chain Currency allocated to potential investors
     */
    uint256 public totalAllocatedAmount;

    /**
     * @notice Mapping of Pool Token shares for payees
     * @dev Mapping (account -> amount of Pool Tokens)
     */
    mapping(address => uint256) public poolTokenShares;

    /**
     * @notice Total shares released from this contract
     */
    uint256 public totalReleased;

    /**
     * @notice Total shares issued to payees
     */
    uint256 public totalShares;

    /* -------------------------------------------------------------- VIEWS ------------------------------------------------------------- */

    /**
     * @return The decimal places of the allocation tier and lp multipliers
     * @dev The allocation tier and lp holder must have the same number of decimals
     */
    function getAllocationSizeMultiplierTierDecimals() public pure returns (uint256) {
        return 2;
    }

    /**
     * @return The decimals places of the XIL to Chain Currency allocation size ratio
     */
    function getXilToChainCurrencyAllocationSizeRatioDecimals() public pure returns (uint256) {
        return 18;
    }

    /* -------------------------------------------------------------- ENUMS ------------------------------------------------------------- */

    /**
     * @title State of the IDO
     * @property Computed The status is unknown and must be computed by analysing the different IDO dates
     * @property Registration The IDO is in the registration phase; investors cannot interact with the contract yet
     * @property Allocation The IDO is in the allocation phase; investors can only join, request and recalculate their allocation size
     * @property Swap The IDO is in the swap phase; investors can now invest into the IDO
     * @property Claim The IDO is in the claim phase; investors cannot invest anymore but any shareholder can claim their vested Pool Tokens past the vesting period
     * @property Refund The IDO is in the refund phase; investors cannot invest anymore but can claim their investment back
     */
    enum IDOState {Computed, Registration, Allocation, Swap, Claim, Refund}

    /* ------------------------------------------------------------- EVENTS ------------------------------------------------------------- */

    /**
     * @notice Event emitted when the Pool Token is minted
     */
    event PoolTokenMinted(address poolTokenAddress);

    /**
     * @notice Event emitted when an investor's allocation size is updated
     * @param investor Address of the staker/potential investor
     * @param allocationSize Size of the staker's allocation for this IDO
     */
    event AllocationSizeUpdated(address investor, uint256 allocationSize);

    /**
     * @notice Event emitted when the total allocated amount is updated
     * @param totalAllocatedAmount New total allocated amount
     */
    event TotalAllocatedAmountUpdated(uint256 totalAllocatedAmount);

    /**
     * @notice Event emitted when an investor's investment is updated
     * @param investor Address of the investor
     * @param investment Size of the investor's investment within this IDO
     * @param totalInvestedAmount Total invested amount within this IDO
     */
    event InvestmentUpdated(address investor, uint256 investment, uint256 totalInvestedAmount);

    /**
     * @notice Event emitted when an investor's BEP20 investment is updated
     * @param investor Address of the investor
     * @param investment Size of the investor's investment within this IDO
     * @param totalInvestedAmount Total invested amount within this IDO
     */
    event InvestmentBEP20Updated(address investor, uint256 investment, uint256 totalInvestedAmount, address _tokenAddress);

    /**
     * @notice Event emitted when the IDOState is updated
     * @param state New state of the IDO
     */
    event IDOStateUpdated(IDOState state);

    /**
     * @notice Event emitted when the IDO is killed
     */
    event IDOKilled();

    /**
     * @notice Event emitted when pool tokens are claimed
     * @param poolTokensHolder Address of the sender
     * @param amountClaimed Amount of pool tokens released
     */
    event PoolTokensClaimed(address poolTokensHolder, uint256 amountClaimed);

    /**
     * @notice Event emitted when pool tokens are claimed
     * @param investor Address of the investor
     * @param amountClaimed Amount of Chain Currency released
     */
    event RefundedInvestmentClaimed(address investor, uint256 amountClaimed);

    /**
     * @notice Event emitted when pool tokens are claimed
     * @param investor Address of the investor
     * @param amountClaimed Amount of BEP20 released
     */
    event RefundedInvestmentClaimedInBEP20(address investor, uint256 amountClaimed);

    /**
     * @notice Event emitted when the PoolTokenSharePercentages is updated
     * @param investors Pool Token Share Percentage of the investors
     * @param curator Pool Token Share Percentage of the curator
     * @param xillion Pool Token Share Percentage of Xillion
     * @param littlePhil Pool Token Share Percentage of Little Phil
     */
    event PoolTokenSharePercentagesUpdated(uint256 investors, uint256 curator, uint256 xillion, uint256 littlePhil);

    /**
     * @notice Event emitted when the PoolTokenVestingDays is updated
     * @param investors Pool Token Vesting Days of the investors
     * @param curator Pool Token Vesting Days of the curator
     * @param xillion Pool Token Vesting Days of Xillion
     * @param littlePhil Pool Token Vesting Days of Little Phil
     */
    event PoolTokenVestingDaysUpdated(uint256 investors, uint256 curator, uint256 xillion, uint256 littlePhil);

    /**
     * @notice Event emitted when the allocationStartDate is updated
     * @param allocationStartDate New allocation start date for the IDO
     */
    event AllocationStartDateUpdated(uint256 allocationStartDate);

    /**
     * @notice Event emitted when the allocationEndDate is updated
     * @param allocationEndDate New allocation end date for the IDO
     */
    event AllocationEndDateUpdated(uint256 allocationEndDate);

    /**
     * @notice Event emitted when the swapStartDate is updated
     * @param swapStartDate New swap start date for the IDO
     */
    event SwapStartDateUpdated(uint256 swapStartDate);

    /**
     * @notice Event emitted when the swapEndDate is updated
     * @param swapEndDate New swap end date for the IDO
     */
    event SwapEndDateUpdated(uint256 swapEndDate);

    /**
     * @notice Event emitted when the AllocationTiers is updated
     * @param allocationTiers New allocation tiers for the IDO
     */
    event AllocationTiersUpdated(XillionIDOStructs.AllocationTier[] allocationTiers);

    /**
     * @notice Event emitted when the InvestmentDetails is updated
     * @param maxInvestmentAmountPerInvestor New maxInvestmentAmountPerInvestor
     * @param minInvestmentPercentForIDOCompletion New minInvestmentPercentForIDOCompletion
     * @param minStakingDays New minStakingDays
     * @param stakingContract New staking contract address
     */
    event InvestmentDetailsUpdated(
        uint256 maxInvestmentAmountPerInvestor,
        uint256 minInvestmentPercentForIDOCompletion,
        uint256 minStakingDays,
        address stakingContract
    );

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
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

/**
 * @title Shared code for XillionIDO structs
 */
library XillionIDOStructs {

    /**
     * @title Allocation Tiers that define potential investors' allocation size
     * @dev It is defined as staking range mins and multipliers
     * @property minXILAmount Bottom range of the allocation tier (i.e. from x onwards)
     * @property allocationSizeMultiplier The multiplier that will be applied to the allocation size, initially calculated using the XIL -> Chain Currency ratio
     */
    struct AllocationTier {
        uint256 minXILAmount;
        uint256 allocationSizeMultiplier;
    }

    /**
     * @title Initial Details about an IDO
     * @property idoValueCap Max amount of Chain Currency the IDO can accept
     * @property numberOfPoolTokens Amount of Pool Tokens minted at the start of the IDO
     * @property poolTokenName Name of the Pool Token
     * @property poolTokenSymbol Symbol of the Pool Token
     * @property contractOwner Designated owner of the contract
     */
    struct InitialDetails {
        uint256 idoValueCap;
        uint256 numberOfPoolTokens;
        string poolTokenName;
        string poolTokenSymbol;
        address contractOwner;
        BEP20IDOTokenDetails bep20IdoTokenDetails;
        address xilTokenAddress;
    }

    /**
     * @title Initial dates of the IDO
     * @property allocationStartDate Allocation start date
     * @property allocationEndDate Allocation end date
     * @property swapStartDate Swap start date
     * @property swapEndDate Swap end date
     */
    struct IDODates {
        uint256 allocationStartDate;
        uint256 allocationEndDate;
        uint256 swapStartDate;
        uint256 swapEndDate;
    }

    /**
     * @title Investment Details about an IDO
     * @property maxInvestmentAmountPerInvestor Max investment amount per investor, in the chain currency's smallest denomination
     * @property minInvestmentPercentForIDOCompletion Min % investment for IDO successful completion
     * @property minStakingDays Minimum staking duration
     * @property stakingContractAddress Address of the XIL Staking contract for IDO allocation
     */
    struct InvestmentDetails {
        uint256 maxInvestmentAmountPerInvestor;
        uint256 minInvestmentPercentForIDOCompletion;
        uint256 minStakingDays;
        address stakingContractAddress;
        // uint256 maxInvestmentBEP20AmountPerInvestor;   // BEP20
        // uint256 minInvestmentPercentOfBEP20ForIDOCompletion;  //BEP20
    }

    /**
     * @title Investment Details about an IDO
     * @property maxInvestmentAmountPerInvestor Max investment amount per investor, in the chain currency's smallest denomination
     * @property minInvestmentPercentForIDOCompletion Min % investment for IDO successful completion
     */
    struct BEP20IDOTokenDetails {
        uint256 maxInvestmentBEP20AmountPerInvestor;
        address BEP20IdoTokenAddress;
        uint256 BEP20IdoValueCap;
        uint256 minInvestmentPercentOfBEP20ForIDOCompletion;
    }

    /**
     * @title Share of the Pool Tokens for different actors in %
     * @property investors Percentage of the Pool Tokens going to investors
     * @property curator Percentage of the Pool Tokens going to the curator
     * @property xillion Percentage of the Pool Tokens going to Xillion
     * @property littlePhil Percentage of the Pool Tokens going to Little Phil
     */
    struct PoolTokenSharePercentage {
        uint256 investors;
        uint256 curator;
        uint256 xillion;
        uint256 littlePhil;
    }

    /**
     * @title Vesting duration of the Pool Tokens for different actors in days
     * @property investors Vesting duration of the Pool Tokens going to investors
     * @property curator Vesting duration of the Pool Tokens going to the curator
     * @property xillion Vesting duration of the Pool Tokens going to Xillion
     * @property littlePhil Vesting duration of the Pool Tokens going to Little Phil
     */
    struct PoolTokenVestingDays {
        uint256 investors;
        uint256 curator;
        uint256 xillion;
        uint256 littlePhil;
    }

    /**
     * @title Critical actors' wallet address
     * @property chainCurrencyRecipient Wallet address of the Chain Currency recipient
     * @property curator Wallet address of the curator
     * @property xillion Wallet address of Xillion
     * @property littlePhil Wallet address of Little Phil
     */
    struct WalletAddress {
        address chainCurrencyRecipient;
        address curator;
        address xillion;
        address littlePhil;
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


/**
 * @title Contract with an owner that can be paused/unpaused by the owner
 */
contract OwnablePausable is Ownable, Pausable {

    /**
     * @notice Allows an admin to pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Allows an admin to unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./utils/OwnablePausable.sol";
import "./utils/ExtendableTokenTimelock.sol";

/**
 * @title XIL Staking Contract
 */
contract XillionAccessStaking is OwnablePausable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    /* ------------------------------------------------------------ VARIABLES ----------------------------------------------------------- */

    /**
     * @notice The Staking Token
     * @dev This is meant to be the XIL token, but we are reserving the right to change it in case we have need to release a V2 for security purposes for example
     */
    IERC20 public stakingToken;

    /**
     * @notice The minimum staking period enabled by this contract
     */
    uint256 public minimumStakingDays = 1;

    /**
     * @notice Record of all the stakes currently in this contract
     */
    mapping(address => Stake[]) public stakes;

    /**
     * @notice Nonce for generating unique IDs
     */
    uint256 private _stakeIdNonce;

    /* ----------------------------------------------------------- CONSTRUCTOR ---------------------------------------------------------- */

    /**
     * @notice Called on creation of the Staking contract
     * @param stakingTokenAddr Address of the Staking Token
     * @param ownerAddr Address of the owner of this contract (most likely a multi SIG wallet)
     */
    constructor(address stakingTokenAddr, address ownerAddr) {

        require(stakingTokenAddr != address(0) && ownerAddr != address(0), "Invalid address");

        stakingToken = IERC20(stakingTokenAddr);

        if (_msgSender() != ownerAddr) {
            transferOwnership(ownerAddr);
        }

    }

    /* --------------------------------------------------------- MAIN ACTIVITIES -------------------------------------------------------- */

    /**
     * @notice Holds the provided number of XIL tokens for the provided days in an ExtendableTokenTimelock.
     * @param amount Number of tokens to be staked in token decimals
     * @param daysToLock Number of days to lock tokens up for
     */
    function stake(uint256 amount, uint256 daysToLock) external whenNotPaused nonReentrant {

        // guards
        require(stakingToken != IERC20(address(0)), "Staking token has not been set");
        require(amount > 0, "Cannot stake 0");
        require(daysToLock >= minimumStakingDays, "Cannot stake for less than the minimum staking days");

        // create timelock and transfer funds
        uint256 releaseDate = block.timestamp + (daysToLock * 1 days);
        ExtendableTokenTimelock timelock = new ExtendableTokenTimelock(stakingToken, _msgSender(), releaseDate);
        stakingToken.safeTransferFrom(_msgSender(), address(timelock), amount);

        // create unique ID
        bytes32 uid = keccak256(abi.encodePacked(_msgSender(), amount, daysToLock, block.timestamp, block.number, _stakeIdNonce));
        _stakeIdNonce++;

        // record the stake
        Stake memory stakeRecord = Stake(uid, daysToLock, timelock);
        stakes[_msgSender()].push(stakeRecord);

        // emit event
        emit Staked(uid, _msgSender(), address(stakingToken), amount, releaseDate, daysToLock);

    }

    /**
     * @notice Extends the release date of one of the sender's stakes
     * @param stakeIndex Index of the stake in the sender's list of stakes
     * @param daysToAdd Number of days to extend the stake by
     */
    function extend(uint256 stakeIndex, uint256 daysToAdd) external whenNotPaused nonReentrant {

        // guard
        require(daysToAdd > 0, "daysToAdd must be greater than 0");

        // retrieve stake & timelock
        Stake memory stakeRecord = stakes[_msgSender()][stakeIndex];
        ExtendableTokenTimelock timelock = stakeRecord.timelock;

        // extend stake
        timelock.extend(daysToAdd * 1 days);
        stakes[_msgSender()][stakeIndex].daysLocked = stakeRecord.daysLocked + daysToAdd;

        // emit event
        IERC20 stakingTokenInTimelock = stakeRecord.timelock.token();
        emit Extended(
            stakeRecord.uid,
            _msgSender(),
            address(stakingTokenInTimelock),
            stakingTokenInTimelock.balanceOf(address(timelock)),
            timelock.releaseTime(),
            stakes[_msgSender()][stakeIndex].daysLocked
        );

    }

    /**
     * @notice Withdraws all stakes past their daysLocked
     * @dev This method is using the Swap & Delete strategy to remove released stakes to save on gas cost - we don't care about the order of stakes
     */
    function withdraw() external nonReentrant {

        // check amount of stakes
        uint256 stakesLength = stakes[_msgSender()].length;
        require(stakesLength > 0, "No stakes");

        // go through all of the sender's stakes
        uint256 i = 0;
        while (i < stakesLength) {

            Stake memory stakeRecord = stakes[_msgSender()][i];
            ExtendableTokenTimelock timelock = stakeRecord.timelock;

            // check if this stake is releasable
            if (block.timestamp >= timelock.releaseTime()) {

                IERC20 stakingTokenInTimelock = stakeRecord.timelock.token();
                uint256 amount = stakingTokenInTimelock.balanceOf(address(timelock));

                // release timelock
                timelock.release();

                // emit event
                emit Withdrawn(
                    stakeRecord.uid,
                    _msgSender(),
                    address(stakingTokenInTimelock),
                    amount,
                    timelock.releaseTime(),
                    stakeRecord.daysLocked
                );

                // swap with last element
                if (i < stakesLength - 1) {
                    stakes[_msgSender()][i] = stakes[_msgSender()][stakesLength - 1];
                }

                // pop array
                stakes[_msgSender()].pop();
                stakesLength--;

            } else {

                // not releasable, go to next stake
                i++;

            }

        }

    }

    /* ------------------------------------------------------------- MUTATORS ----------------------------------------------------------- */

    /**
     * @notice Overrides the token accepted for staking
     * @param stakingTokenAddr Address of the new staking token being set
     */
    function setStakingToken(address stakingTokenAddr) external onlyOwner {
        require(stakingTokenAddr != address(0), "Invalid address");
        emit StakingTokenUpdated(address(stakingToken), stakingTokenAddr);
        stakingToken = IERC20(stakingTokenAddr);
    }

    /**
     * @notice Overrides the minimum staking period
     * @param minimumStakingDays_ New minimum staking period in days
     */
    function setMinimumStakingDays(uint256 minimumStakingDays_) external onlyOwner {
        require(minimumStakingDays_ > 0, "Minimum Staking Days must be above 0");
        emit MinimumStakingDaysUpdated(minimumStakingDays, minimumStakingDays_);
        minimumStakingDays = minimumStakingDays_;
    }

    /* --------------------------------------------------------- VIEWS (PUBLIC) --------------------------------------------------------- */

    /**
     * @notice Returns the staking data for the stake at index for the sender
     * @param index - Index of the stake data to return
     * @return Amount staked
     * @return Days the stake initially was locked for (it may have stayed in the timelock for longer)
     * @return Release date of the timelock
     * @return UID of the stake
     * @return Address of the staking token
     */
    function getStake(uint256 index) external view returns (uint256, uint256, uint256, bytes32, address) {
        return getStakeForAddress(_msgSender(), index);
    }

    /**
     * @notice Returns the staking data for the provided staker at the provided index
     * @param staker - Address to look up stake for
     * @param index - Index of the stake data to return
     * @return Amount staked
     * @return Days the stake initially was locked for (it may have stayed in the timelock for longer)
     * @return Release date of the timelock
     * @return UID of the stake
     * @return Address of the staking token
     */
    function getStakeForAddress(address staker, uint256 index) public view returns (uint256, uint256, uint256, bytes32, address) {
        Stake memory stakeRecord = stakes[staker][index];
        IERC20 stakingTokenInTimelock = stakeRecord.timelock.token();
        uint256 amount = stakingTokenInTimelock.balanceOf(address(stakeRecord.timelock));
        uint256 releaseDate = stakeRecord.timelock.releaseTime();
        return (amount, stakeRecord.daysLocked, releaseDate, stakeRecord.uid, address(stakingTokenInTimelock));
    }

    /**
     * @return The number of stakes for the sender
     */
    function getStakeCount() external view returns (uint256) {
        return getStakeCountForAddress(_msgSender());
    }

    /**
     * @param staker - Address to look up stake count for
     * @return The number of stakes for the provided staker
     */
    function getStakeCountForAddress(address staker) public view returns (uint256) {
        return stakes[staker].length;
    }

    /* ------------------------------------------------------------- STRUCTS ------------------------------------------------------------ */

    /**
     * @title Struct describing an individual stake transaction to the contract
     * @property uid - Id of the stake, unique across all stakes (current or not)
     * @property daysLocked - Staking period in days
     * @property timelock - ExtendableTokenTimelock contract containing staked tokens
     */
    struct Stake {
        bytes32 uid;
        uint256 daysLocked;
        ExtendableTokenTimelock timelock;
    }

    /* ------------------------------------------------------------- EVENTS ------------------------------------------------------------- */

    /**
     * @notice Event emitted when a Stake is created
     * @param uid Unique ID of the stake
     * @param sender Address of the staker
     * @param stakingToken Address of the staking token
     * @param amount Amount staked
     * @param releaseDate Release date of the stake
     * @param daysLocked Duration of the token timelock
     */
    event Staked(bytes32 uid, address sender, address stakingToken, uint256 amount, uint256 releaseDate, uint256 daysLocked);

    /**
     * @notice Event emitted when a Stake is extended
     * @param uid Unique ID of the stake
     * @param sender Address of the staker
     * @param stakingToken Address of the staking token
     * @param amount Amount staked
     * @param newReleaseDate New release date of the stake
     * @param newDaysLocked New duration of the token timelock
     */
    event Extended(bytes32 uid, address sender, address stakingToken, uint256 amount, uint256 newReleaseDate, uint256 newDaysLocked);

    /**
     * @notice Event emitted when a Stake is withdrawn
     * @param uid Unique ID of the stake
     * @param sender Address of the staker
     * @param stakingToken Address of the staking token
     * @param amount Amount released
     * @param releaseDate Release date of the stake
     * @param daysLocked Duration of the token timelock
     */
    event Withdrawn(bytes32 uid, address sender, address stakingToken, uint256 amount, uint256 releaseDate, uint256 daysLocked);

    /**
     * @notice Event emitted when the staking token is updated
     * @param oldStakingToken Address of the previous staking token
     * @param newStakingToken Address of the new staking token
     */
    event StakingTokenUpdated(address oldStakingToken, address newStakingToken);

    /**
     * @notice Event emitted when the MinimumStakingDays is updated
     * @param oldMinimumStakingDays Address of the previous MinimumStakingDays
     * @param newMinimumStakingDays Address of the new MinimumStakingDays
     */
    event MinimumStakingDaysUpdated(uint256 oldMinimumStakingDays, uint256 newMinimumStakingDays);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./libraries/XillionIDOStructs.sol";
import "./utils/OwnablePausable.sol";
import "./XillionIDO.sol";


/**
 * @title Factory+Master/Slave Patterns contract to deploy an IDO
 */
contract XillionIDOFactory is OwnablePausable, ReentrancyGuard {

    /* ------------------------------------------------------------ VARIABLES ----------------------------------------------------------- */

    /**
     * @notice Address of the master IDO to be delegated calls to
     */
    address public masterIDOAddress;

    /**
     * @notice List of IDOs created by this factory
     */
    XillionIDO[] public idos;

    /**
     * @notice XIL -> Chain Currency allocation size ratio
     */
    uint256 public xilToChainCurrencyAllocationSizeRatio;

    /**
     * @notice BUSD -> Chain Currency allocation size ratio
     */
    uint256 public busdToChainCurrencyAllocationSizeRatio;

    /* ----------------------------------------------------------- CONSTRUCTOR ---------------------------------------------------------- */

    /**
     * @notice Creates the IDO Factory
     * @param ownerAddr_ Address of the owner of this contract (most likely a multi SIG wallet)
     * @param masterIDOAddress_ Address of the master IDO to be delegated calls to
     * @param xilToChainCurrencyAllocationSizeRatio_ XIL -> Chain Currency allocation size ratio
     * @param busdToChainCurrencyAllocationSizeRatio_ BUSD -> Chain Currency allocation size ratio
     */
    constructor(address ownerAddr_, address masterIDOAddress_, uint256 xilToChainCurrencyAllocationSizeRatio_, uint256 busdToChainCurrencyAllocationSizeRatio_) {

        require(ownerAddr_ != address(0), "Invalid owner");

        _checkAndUpdateMasterIDOAddress(masterIDOAddress_);

        setBEP20ToChainCurrencyAllocationSizeRatio(xilToChainCurrencyAllocationSizeRatio_, busdToChainCurrencyAllocationSizeRatio_);

        if (_msgSender() != ownerAddr_) {
            transferOwnership(ownerAddr_);
        }

    }

    /* --------------------------------------------------------- MAIN ACTIVITIES -------------------------------------------------------- */

    /**
     * @notice Deploys an IDO
     * @param initialDetails_ General Details about an IDO
     * @param dates_ Provisioned dates of the IDO
     * @param investmentDetails_ Investment Details about an IDO
     * @param poolTokenSharePercentages_ Share of the Pool Tokens for different actors in %
     * @param poolTokenVestingDays_ Vesting duration of the Pool Tokens for different actors in days
     * @param walletAddresses_ Critical actors' wallet address
     * @param allocationTiers_ Allocation rules/tiers (staking range mins and multipliers)
     */
    function createIDO(
        XillionIDOStructs.InitialDetails calldata initialDetails_,
        XillionIDOStructs.IDODates calldata dates_,
        XillionIDOStructs.InvestmentDetails calldata investmentDetails_,
        XillionIDOStructs.PoolTokenSharePercentage calldata poolTokenSharePercentages_,
        XillionIDOStructs.PoolTokenVestingDays calldata poolTokenVestingDays_,
        XillionIDOStructs.WalletAddress calldata walletAddresses_,
        XillionIDOStructs.AllocationTier[] calldata allocationTiers_
    ) external onlyOwner whenNotPaused nonReentrant {

        // create new IDO
        XillionIDO ido = new XillionIDO(
            address(this),
            initialDetails_
        );

        // initialise the IDO
        ido.initialise(
            dates_,
            investmentDetails_,
            poolTokenSharePercentages_,
            poolTokenVestingDays_,
            walletAddresses_,
            allocationTiers_
        );

        // transfer ownership
        ido.transferOwnership(initialDetails_.contractOwner);

        // add to array of IDOs
        idos.push(ido);

        // emit event
        emit IDOCreated(
            address(ido),
            initialDetails_,
            dates_,
            investmentDetails_,
            poolTokenSharePercentages_,
            poolTokenVestingDays_,
            walletAddresses_,
            allocationTiers_
        );

    }

    /* ------------------------------------------------------------- MUTATORS ----------------------------------------------------------- */

    /**
     * @notice Sets the master IDO address
     * @param masterIDOAddress_ Address of the new master IDO
     */
    function setMasterIDOAddress(address masterIDOAddress_) external onlyOwner whenPaused {
        _checkAndUpdateMasterIDOAddress(masterIDOAddress_);
    }

    /**
     * @notice Checks the master IDO address is valid and sets it in storage
     * @param masterIDOAddress_ Address of the new master IDO
     */
    function _checkAndUpdateMasterIDOAddress(address masterIDOAddress_) internal {
        require(masterIDOAddress_ != address(0), "Invalid masterIDOAddress");
        masterIDOAddress = masterIDOAddress_;
    }

    /**
     * @notice Sets the XIL and BUSD -> Chain Currency allocation size ratio
     * @param xilToChainCurrencyAllocationSizeRatio_ New XIL -> Chain Currency allocation size ratio
     * @param busdToChainCurrencyAllocationSizeRatio_ New BUSD -> Chain Currency allocation size ratio
     */
    function setBEP20ToChainCurrencyAllocationSizeRatio(uint256 xilToChainCurrencyAllocationSizeRatio_, uint256 busdToChainCurrencyAllocationSizeRatio_) public onlyOwner whenNotPaused {
        xilToChainCurrencyAllocationSizeRatio = xilToChainCurrencyAllocationSizeRatio_;
        busdToChainCurrencyAllocationSizeRatio = busdToChainCurrencyAllocationSizeRatio_;
        emit BEP20ToChainCurrencyAllocationSizeRatioUpdated(xilToChainCurrencyAllocationSizeRatio_, busdToChainCurrencyAllocationSizeRatio_);
    }

    /* --------------------------------------------------------- VIEWS (PUBLIC) --------------------------------------------------------- */

    /**
     * @return The amount of IDOs created by this factory
     */
    function getIDOsCount() external view returns (uint256) {
        return idos.length;
    }

    /* -------------------------------------------------------------- EVENTS ------------------------------------------------------------ */

    /**
     * @notice Emitted when an IDO is deployed
     * @param idoAddress Address of the IDO
     * @param initialDetails General Details about an IDO
     * @param dates Provisioned dates of the IDO
     * @param investmentDetails Investment Details about the IDO
     * @param poolTokenSharePercentages Share of the Pool Tokens for different actors in %
     * @param poolTokenVestingDays Vesting duration of the Pool Tokens for different actors in days
     * @param walletAddresses Critical actors' wallet address
     * @param allocationTiers Allocation rules/tiers (staking range mins and multipliers)
     */
    event IDOCreated(
        address idoAddress,
        XillionIDOStructs.InitialDetails initialDetails,
        XillionIDOStructs.IDODates dates,
        XillionIDOStructs.InvestmentDetails investmentDetails,
        XillionIDOStructs.PoolTokenSharePercentage poolTokenSharePercentages,
        XillionIDOStructs.PoolTokenVestingDays poolTokenVestingDays,
        XillionIDOStructs.WalletAddress walletAddresses,
        XillionIDOStructs.AllocationTier[] allocationTiers
    );

    /**
     * @notice Emitted when the XIL/BUSD -> Chain Currency allocation size ratio is updated
     * @param xilToChainCurrencyAllocationSizeRatio XIL -> Chain Currency allocation size ratio
     * @param busdToChainCurrencyAllocationSizeRatio BUSD -> Chain Currency allocation size ratio
     */
    event BEP20ToChainCurrencyAllocationSizeRatioUpdated(uint256 xilToChainCurrencyAllocationSizeRatio, uint256 busdToChainCurrencyAllocationSizeRatio);


}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

import "./utils/OwnablePausable.sol";

/**
 * @title Contract for a Xillion Pool Token
 * @notice This token can used by a Xillion IDO and/or a Xillion Pool
 */
contract XillionPoolToken is ERC20PresetFixedSupply, OwnablePausable {

    /**
     * @notice Creates a new Xillion Pool Token
     * @param name_ Name of the Pool Token
     * @param symbol_ Symbol of the Pool Token
     * @param initialSupply_ Initial Supply of the Pool Token (amount of tokens minted)
     * @param owner_ Designated owner of the Pool Token contract
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_,
        address owner_
    ) ERC20PresetFixedSupply(name_, symbol_, initialSupply_, owner_) {
        require(owner_ != address(0), "Invalid owner");
        if (owner_ != _msgSender()) {
            transferOwnership(owner_);
        }
    }

    /**
     * @notice Required getOwner function for the BEP20 standard.
     * @return the owner of the token contract
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @notice Prevents token transfers if the contract is paused
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     * Copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Pausable.sol
     * This could not be used in conjunction with ERC20PresetFixedSupply otherwise we get the following error message:
     * TypeError: Derived contract must override function "_beforeTokenTransfer". Two or more base classes define function with same name and parameter types.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "XillionPoolToken: token transfer while paused");
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/**
 * @notice A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time. That release time can be extended by the original token holder.
 *
 * Largely inspired from OpenZeppelin's TokenTimelock
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.2/contracts/token/ERC20/utils/TokenTimelock.sol
 */
contract ExtendableTokenTimelock is Ownable {

    using SafeERC20 for IERC20;

    /* ------------------------------------------------------------ VARIABLES ----------------------------------------------------------- */

    // ERC20 basic token contract being held
    IERC20 private immutable _token;

    // beneficiary of tokens after they are released
    address private immutable _beneficiary;

    // timestamp when token release is enabled
    uint256 private _releaseTime;

    /* ----------------------------------------------------------- CONSTRUCTOR ---------------------------------------------------------- */

    constructor(
        IERC20 token_,
        address beneficiary_,
        uint256 releaseTime_
    ) {
        require(releaseTime_ >= block.timestamp, "Invalid release time");
        require(beneficiary_ != address(0), "Invalid beneficiary");
        require(token_ != IERC20(address(0)), "Invalid token");
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
    }

    /* --------------------------------------------------------- MAIN ACTIVITIES -------------------------------------------------------- */

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() external {
        require(block.timestamp >= releaseTime(), "Forbidden");

        uint256 amount = token().balanceOf(address(this));
        require(amount > 0, "Timelock empty");

        token().safeTransfer(beneficiary(), amount);
    }


    /**
     * @notice Extends the time on the timelock
     * @param timeToAdd Time to add (in seconds)
     */
    function extend(uint256 timeToAdd) public onlyOwner {

        require(timeToAdd > 0, "Invalid timeToAdd");

        uint256 balance = token().balanceOf(address(this));

        require(balance > 0, "Timelock empty");

        uint256 oldReleaseTime = _releaseTime;

        _releaseTime += timeToAdd;

        emit TokenTimelockExtended(
            address(token()),
            _beneficiary,
            balance,
            oldReleaseTime,
            _releaseTime,
            timeToAdd
        );

    }

    /* --------------------------------------------------------- VIEWS (PUBLIC) --------------------------------------------------------- */

    /**
     * @return The token being held.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return The beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return The time when the tokens are released.
     */
    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    /* ------------------------------------------------------------- EVENTS ------------------------------------------------------------- */

    /**
     * @notice Event emitted when a TokenTimelock is extended
     * @param token Address of the tokens in the timelock
     * @param beneficiary Address of the beneficiary of the timelock
     * @param amountLocked Amount of tokens currently locked in the timelock
     * @param oldReleaseTime The previous release time
     * @param newReleaseTime The new release time with the extension
     * @param timeAdded The amount of seconds added to the previous release time
     */
    event TokenTimelockExtended(address token, address beneficiary, uint256 amountLocked, uint256 oldReleaseTime, uint256 newReleaseTime, uint256 timeAdded);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "./XillionIDOCommon.sol";

/**
 * @title Contract for an IDO
 */
contract XillionIDO is XillionIDOCommon {

    /* ----------------------------------------------------------- CONSTRUCTOR ---------------------------------------------------------- */
     
    /**
     * @notice Called on creation of the IDO contract
     * @param factoryAddress_ Address of the IDO Factory that created this IDO
     * @param initialDetails_ General Details about an IDO
     */

    constructor(
        address factoryAddress_,
        XillionIDOStructs.InitialDetails memory initialDetails_
    ) {

        // check "immutable data" is valid and set it
        require(initialDetails_.idoValueCap > 0 && initialDetails_.numberOfPoolTokens > 0, "Invalid amount");
        idoValueCap = initialDetails_.idoValueCap;
        numberOfPoolTokens = initialDetails_.numberOfPoolTokens;
         

         //determine Xil token Address
         xillTokenAddress = initialDetails_.xilTokenAddress;
        // store factory
        require(factoryAddress_ != address(0), "Invalid factory");
        factory = XillionIDOFactory(factoryAddress_);

        // BEP20TokenInit
         if(initialDetails_.bep20IdoTokenDetails.BEP20IdoTokenAddress != address(0)){
               maxInvestmentBEP20AmountPerInvestor = initialDetails_.bep20IdoTokenDetails.maxInvestmentBEP20AmountPerInvestor;
               BEP20IdoTokenAddress = initialDetails_.bep20IdoTokenDetails.BEP20IdoTokenAddress;
               BEP20IdoValueCap= initialDetails_.bep20IdoTokenDetails.BEP20IdoValueCap;
               minInvestmentPercentOfBEP20ForIDOCompletion = initialDetails_.bep20IdoTokenDetails.minInvestmentPercentOfBEP20ForIDOCompletion;   
         }

        // mint tokens
        require(bytes(initialDetails_.poolTokenName).length > 0 && bytes(initialDetails_.poolTokenSymbol).length > 0, "Invalid token details");
        _poolToken = new XillionPoolToken(initialDetails_.poolTokenName, initialDetails_.poolTokenSymbol, initialDetails_.numberOfPoolTokens, address(this));
        emit PoolTokenMinted(address(_poolToken));
    }
  
    /**
     * @notice Initialises an IDO with all required values
     * @dev This cannot be called from the constructor because it uses delegation, whereas the contract does not have a state yet within the constructor
     * @param dates_ Provisioned dates of the IDO
     * @param investmentDetails_ Investment Details about an IDO
     * @param poolTokenSharePercentages_ Share of the Pool Tokens for different actors in %
     * @param poolTokenVestingDays_ Vesting duration of the Pool Tokens for different actors in days
     * @param walletAddresses_ Critical actors' wallet address
     * @param allocationTiers_ Allocation rules/tiers (staking range mins and multipliers)
     */
    function initialise(
        XillionIDOStructs.IDODates memory dates_,
        XillionIDOStructs.InvestmentDetails memory investmentDetails_,
        XillionIDOStructs.PoolTokenSharePercentage memory poolTokenSharePercentages_,
        XillionIDOStructs.PoolTokenVestingDays memory poolTokenVestingDays_,
        XillionIDOStructs.WalletAddress memory walletAddresses_,
        XillionIDOStructs.AllocationTier[] memory allocationTiers_
    ) external onlyOwner {

        // check and set allocation tiers
        setAllocationTiers(allocationTiers_);

        // check and set investment details
        setInvestmentDetails(investmentDetails_);

        // check and set pool token share percentages
        setPoolTokenSharePercentages(poolTokenSharePercentages_);

        // check and set pool token vesting periods
        setPoolTokenVestingDays(poolTokenVestingDays_);

        // check and set critical wallet addresses
        setWalletAddresses(walletAddresses_);

        setAllocationStartDate(dates_.allocationStartDate);
        setAllocationEndDate(dates_.allocationEndDate);
        setSwapStartDate(dates_.swapStartDate);
        setSwapEndDate(dates_.swapEndDate);

    }

    /* --------------------------------------------------------- MAIN ACTIVITIES -------------------------------------------------------- */

    /**
     * @notice Returns the sender's allocation size
     * @dev It is the max between the staking allocation and the manual allocation
     * @return The sender's allocation size
     */
    function getAllocationSize() external view returns (uint256) {
        return Math.max(
            _manualAllocationSizeList[_msgSender()],
            _stakingAllocationSizeList[_msgSender()]
        );
    }

    /**
     * @notice Creates or updates a sender's allocation size. An existing allocation size can only be increased, not decreased.
     */
    function joinOrRecalculateAllocation() external {
        delegateFunctionCallToMaster("joinOrRecalculateAllocation()");
    }

    /**
     * @notice Lets the sender invest into the IDO
     */
    function invest() external payable {
        delegateFunctionCallToMaster("invest()");
    }

    function investBEP20(uint256 _tokenAmount) external{
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("investBEP20(uint256)", _tokenAmount));
        revertOnDelegateCallFailure(success, result);
    }


    /**
     * @notice Ends the Swap phase – it will either complete successfully or fail depending on the investment and success threshold
     */
    function finish() external {
        delegateFunctionCallToMaster("finish()");
    }

    /**
     * @notice Kills the IDO (i.e. refunds it) regardless of the investment and success threshold
     */
    function kill() external {
        delegateFunctionCallToMaster("kill()");
    }

    /**
     * @notice Lets investors, the curator, Xillion and Little Phil claim their Pool Tokens after the vesting period
     */
    function claimPoolTokens() external {
        delegateFunctionCallToMaster("claimPoolTokens()");
    }

    /**
     * @notice Refunds invested Chain Currency if the IDO was refunded
     */
    function claimRefundedInvestment() external {
        delegateFunctionCallToMaster("claimRefundedInvestment()");
    }
    /**
     * @notice Transfers the invested Chain Currency amount to the Chain Currency recipient once the sale is closed
     */
    function claimTotalInvestedAmount() external {
        delegateFunctionCallToMaster("claimTotalInvestedAmount()");
    }

    function delegateFunctionCallToMaster(string memory name) internal {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature(name));
        revertOnDelegateCallFailure(success, result);
    }

    /* ------------------------------------------------------------- MUTATORS ----------------------------------------------------------- */

    /**
     * @notice Sets the Pool Token share percentages
     * @param poolTokenSharePercentages_ New Pool Token share percentages
     */
    function setPoolTokenSharePercentages(XillionIDOStructs.PoolTokenSharePercentage memory poolTokenSharePercentages_) public {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("setPoolTokenSharePercentages((uint256,uint256,uint256,uint256))", poolTokenSharePercentages_));
        revertOnDelegateCallFailure(success, result);
    }

    // /**
    //  * @notice Sets the Pool Token share percentages
    //  * @param _stakeAmount Amount for potential stake
    //  * @param _duration Stake duration
    //  */
    // function calculateAllocation(uint256 _stakeAmount, uint256 _duration) public {
    //     (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("calculateAllocation(uint256,uint256)", _stakeAmount, _duration));
    //     revertOnDelegateCallFailure(success, result);
    // }

    /**
     * @notice Sets the Pool Token vesting periods in days
     * @param poolTokenVestingDays_ New Pool Token vesting periods in days
     */
    function setPoolTokenVestingDays(XillionIDOStructs.PoolTokenVestingDays memory poolTokenVestingDays_) public {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("setPoolTokenVestingDays((uint256,uint256,uint256,uint256))", poolTokenVestingDays_));
        revertOnDelegateCallFailure(success, result);
    }

    /**
     * @notice Sets the critical wallet addresses
     * @param walletAddresses_ New critical wallet addresses
     */
    function setWalletAddresses(XillionIDOStructs.WalletAddress memory walletAddresses_) public {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("setWalletAddresses((address,address,address,address))", walletAddresses_));
        revertOnDelegateCallFailure(success, result);
    }

    /**
     * @notice Sets the allocation start date
     * @param allocationStartDate_ New allocation start date
     */
    function setAllocationStartDate(uint256 allocationStartDate_) public {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("setAllocationStartDate(uint256)", allocationStartDate_));
        revertOnDelegateCallFailure(success, result);
    }

    /**
     * @notice Sets the allocation end date
     * @param allocationEndDate_ New allocation end date
     */
    function setAllocationEndDate(uint256 allocationEndDate_) public {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("setAllocationEndDate(uint256)", allocationEndDate_));
        revertOnDelegateCallFailure(success, result);
    }

    /**
     * @notice Sets the swap start date
     * @param swapStartDate_ New swap start date
     */
    function setSwapStartDate(uint256 swapStartDate_) public {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("setSwapStartDate(uint256)", swapStartDate_));
        revertOnDelegateCallFailure(success, result);
    }

    /**
     * @notice Sets the swap end date
     * @param swapEndDate_ New swap end date
     */
    function setSwapEndDate(uint256 swapEndDate_) public onlyOwner {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("setSwapEndDate(uint256)", swapEndDate_));
        revertOnDelegateCallFailure(success, result);
    }

    /**
     * @notice Sets the allocation tiers and check they are sorted from lowest to highest tier
     * @param allocationTiers_ The new allocation tiers
     */
    function setAllocationTiers(XillionIDOStructs.AllocationTier[] memory allocationTiers_) public {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("setAllocationTiers((uint256,uint256)[])", allocationTiers_));
        revertOnDelegateCallFailure(success, result);
    }

    /**
     * @notice Sets the investment details
     * @param investmentDetails_ New investment details
     */
    function setInvestmentDetails(XillionIDOStructs.InvestmentDetails memory investmentDetails_) public {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("setInvestmentDetails((uint256,uint256,uint256,address))", investmentDetails_));
        revertOnDelegateCallFailure(success, result);
    }

    /**
     * @notice Updates the list of manually whitelisted accounts and their arbitrary allocation size
     * This only updates a subset of entries (including removing by setting 0), it does not override the whole list
     * @param manualWhitelist_ The list of accounts that are manually whitelisted
     * @param manualAllocationSizeList_ The list of allocation size manually set to the whitelisted accounts
     */
    function updateManualAllocationSizeList(
        address[] calldata manualWhitelist_,
        uint256[] calldata manualAllocationSizeList_
    ) public {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("updateManualAllocationSizeList(address[],uint256[])", manualWhitelist_, manualAllocationSizeList_));
        revertOnDelegateCallFailure(success, result);
    }

    /* --------------------------------------------------------- VIEWS (PUBLIC) --------------------------------------------------------- */

    /**
     * @return The IDO's state value
     * @dev The _state variable is either Computer, Claim or Refund. For the former, we look at the dates to determine whether it should
     *  actually be Registration, Allocation or Swap
     */
    function getIDOState() external view returns (IDOState) {
        if (_state == IDOState.Claim || _state == IDOState.Refund) {
            return _state;
        } else if (swapStartDate > 0 && block.timestamp >= swapStartDate) {
            return IDOState.Swap;
        } else if (allocationStartDate > 0 && block.timestamp >= allocationStartDate) {
            return IDOState.Allocation;
        }
        return IDOState.Registration;
    }

    /**
     * @return The address of the Pool Token
     */
    function getPoolTokenAddress() external view returns (address) {
        return address(_poolToken);
    }

    /**
     * @return The amount of allocation tiers for this IDO
     */
    function getAllocationTiersCount() external view returns (uint256) {
        return _allocationTiers.length;
    }

    /**
     * @param index_ Index of the allocation tier to retrieve
     * @return The requested allocation tier
     */
    function getAllocationTier(uint256 index_) external view returns (uint256, uint256) {
        return (_allocationTiers[index_].minXILAmount, _allocationTiers[index_].allocationSizeMultiplier);
    }

    /**
     * @return The amount of investors
     */
    function getInvestorsCount() external view returns (uint256) {
        return _investors.length;
    }

    /**
     * @param index_ Index of the investor
     * @return The address of an investor
     */
    function getInvestorAddress(uint256 index_) external view returns (address) {
        return _investors[index_];
    }

    /**
     * @param account_ Address of the investor
     * @return The investment size for an investor
     */
    function getInvestmentSize(address account_) external view returns (uint256) {
        return _investments[account_];
    }

    /**
     * @return The address of this IDO's staking contract
     */
    function getStakingContractAddress() external view returns (address) {
        return address(_stakingContract);
    }

    /* --------------------------------------------------------- VIEWS (OWNER) ---------------------------------------------------------- */

    /**
     * @return This IDO's critical wallet addresses
     */
    function getCriticalWalletAddresses() external view onlyOwner returns (address, address, address, address) {
        return (
        _chainCurrencyRecipientWalletAddress,
        _curatorWalletAddress,
        _xillionWalletAddress,
        _littlePhilWalletAddress
        );
    }

    /**
     * @param account_ Address of the manually whitelisted account
     * @return The allocation size for a manually whitelisted address
     */
    function getManualAllocationSize(address account_) external view onlyOwner returns (uint256) {
        return _manualAllocationSizeList[account_];
    }


    /* -------------------------------------------------------------- UTILS ------------------------------------------------------------- */

    /**
     * @notice Helper to revert if a delegate calls failed in the callee
     */
    function revertOnDelegateCallFailure(bool success, bytes memory) private pure {
        if (!success) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }

    /**
     * @return the address of the master IDO, that is used to delegate calls for business logic
     */
    function getMasterIDOAddress() private view returns (address) {
        return factory.masterIDOAddress();
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../extensions/ERC20Burnable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - Preminted initial supply
 *  - Ability for holders to burn (destroy) their tokens
 *  - No access control mechanism (for minting/pausing) and hence no governance
 *
 * This contract uses {ERC20Burnable} to include burn capabilities - head to
 * its documentation for details.
 *
 * _Available since v3.4._
 */
contract ERC20PresetFixedSupply is ERC20Burnable {
    /**
     * @dev Mints `initialSupply` amount of token and transfers them to `owner`.
     *
     * See {ERC20-constructor}.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) {
        _mint(owner, initialSupply);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

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