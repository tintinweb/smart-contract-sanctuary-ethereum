// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract GenesisLock {
    uint256 public startTime;
    uint256 public periodTime;// = 2592000; //60*60*24*30 = 2592000

    /**
    * userType:
    * 1 community pool,
    * 2 private sale,
    * 3 team,
    * 4 Ecosystem foundation
    */
    mapping(address => uint256) public userType;
    //user's lock-up amount
    mapping(address => uint256) public userLockedAmount;
    //time of user's first locked time length
    mapping(address => uint256) public firstPeriodLockedTime;
    //user's total period amount of locked Asset
    mapping(address => uint256) public lockedPeriodAmount;
    //user's current time after claim
    mapping(address => uint256) public currentTimestamp;
    //user's claimed Period
    mapping(address => uint256) public claimedPeriod;

    // records about rights changing operation, oldOwner => newOwner;
    mapping(address => address) public rightsChanging;

    event LockRecordAppened(address indexed _owner, uint _typeId, uint _lockAmount, uint _firstLockTime, uint _lockPeriod);
    event ReleaseClaimed(address indexed _owner, uint _claimedPeriodCount, uint _claimedAmount);
    event RightsChanging(address indexed _fromOwner, address indexed _toOwner);
    event RightsAccepted(address indexed _fromOwner, address indexed _toOwner);

    function initialize(uint256 _periodTime) external {
        require(block.number == 0, "need gensis block");
        require(periodTime == 0, "already initialized");
        require(_periodTime > 0, "invalid periodTime");
        periodTime = _periodTime;
    }
    /**
    *   init the data of all users
    *   The input parameters are 5 equal-length arrays, which store the user's account address, userType, userLockedAmount, firstPeriodLockedTime, and lockedPeriodAmount.
    *   The elements of the above 5 arrays need to be strictly indexed to prevent data errors
    */
    function init(
        address[] memory userAddress,
        uint256[] memory typeId,
        uint256[] memory lockedAmount,
        uint256[] memory lockedTime,
        uint256[] memory periodAmount
    ) external {
        require(block.number == 0, "need gensis block");
        require(periodTime > 0, "not initialized");

        require(userAddress.length == typeId.length, "typeId length must equal userAddress");
        require(userAddress.length == lockedAmount.length, "lockedAmount length must equal userAddress");
        require(userAddress.length == lockedTime.length, "lockedTime length must equal userAddress");
        require(userAddress.length == periodAmount.length, "periodAmount length must equal userAddress");
        for (uint256 i = 0; i < userAddress.length; i++) {
            address userAddr = userAddress[i];
            require(userLockedAmount[userAddr] == 0, "user address already exists");

            userType[userAddr] = typeId[i];
            userLockedAmount[userAddr] = lockedAmount[i];
            firstPeriodLockedTime[userAddr] = lockedTime[i];
            lockedPeriodAmount[userAddr] = periodAmount[i];
        }
        startTime = block.timestamp;
    }

    // @dev append new locking record to a given user.
    function appendLockRecord(address _userAddr, uint256 _typeId, uint256 _firstLockTime, uint256 _lockPeriodCnt) external payable {
        require(msg.value > 100 ether, "too trivial");
        require(_userAddr != address(0), "zero address");
        require(_typeId > 0, "need a type id for human read");
        require(_firstLockTime <= 366 days, "firstLockTime violating WhitePaper rules");
        require(_lockPeriodCnt > 0 && _lockPeriodCnt <= 48, "lockPeriodCnt violating WhitePaper rules");
        require(userLockedAmount[_userAddr] == 0, "user address already have lock-up");

        userType[_userAddr] = _typeId;
        userLockedAmount[_userAddr] = msg.value;
        firstPeriodLockedTime[_userAddr] = _firstLockTime;
        lockedPeriodAmount[_userAddr] = _lockPeriodCnt;

        emit LockRecordAppened(_userAddr, _typeId, msg.value, _firstLockTime, _lockPeriodCnt);
    }

    /**
    *   user claim the unlocked asset
    */
    function claim() external {
        (uint256 claimableAmt,uint256 period) = getClaimableAmount(msg.sender);
        require(claimableAmt > 0 && period > 0, "Have no token released");

        uint256 startTimestamp = startTime + firstPeriodLockedTime[msg.sender];

        if (currentTimestamp[msg.sender] == 0) {
            currentTimestamp[msg.sender] = startTimestamp + periodTime * period;
        } else {
            currentTimestamp[msg.sender] = currentTimestamp[msg.sender] + periodTime * period;
        }
        claimedPeriod[msg.sender] += period;

        (bool success,) = msg.sender.call{value : claimableAmt}(new bytes(0));
        require(success, "transfer failed!");
        emit ReleaseClaimed(msg.sender, period, claimableAmt);
    }

    // query the Claimable Amount 
    function getClaimableAmount(address account) public view returns (uint256 claimableAmt, uint256 period) {
        period = getClaimablePeriod(account);
        if (claimedPeriod[account] + period == lockedPeriodAmount[account]) {
            uint256 alreadyClaimed = (userLockedAmount[account] / lockedPeriodAmount[account]) * claimedPeriod[account];
            claimableAmt = userLockedAmount[account] - alreadyClaimed;
        } else {
            claimableAmt = userLockedAmount[account] / lockedPeriodAmount[account] * period;
        }
    }

    // query the Claimable Period
    function getClaimablePeriod(address account) public view returns (uint256 period){
        period = 0;
        uint256 startTimestamp = startTime + firstPeriodLockedTime[account];
        uint256 maxClaimablePeriod = lockedPeriodAmount[account] - claimedPeriod[account];
        if (maxClaimablePeriod > 0) {
            if (currentTimestamp[account] >= startTimestamp) {
                if (block.timestamp > currentTimestamp[account]) {
                    period = (block.timestamp - currentTimestamp[account]) / periodTime;
                }
            } else {
                if (block.timestamp > startTimestamp) {
                    period = (block.timestamp - startTimestamp) / periodTime;
                }
            }

            if (period > maxClaimablePeriod) {
                period = maxClaimablePeriod;
            }
        }
    }

    /**
    * query the released 
    */
    function getUserReleasedPeriod(address account) internal view returns (uint256 period) {
        uint256 startTimestamp = startTime + firstPeriodLockedTime[account];
        if (block.timestamp > startTimestamp) {
            period = (block.timestamp - startTimestamp) / periodTime;
            if (period > lockedPeriodAmount[account]) {
                period = lockedPeriodAmount[account];
            }
        }
    }

    // @dev start changing all rights to a new address.
    function changeAllRights(address _to) public {
        require(userLockedAmount[msg.sender] > 0, "sender have no lock-up");
        require(userLockedAmount[_to] == 0, "_to address already have lock-up");
        require(lockedPeriodAmount[msg.sender] > claimedPeriod[msg.sender], "all claimed, no need to do anything");

        // If there's an ongoing changing record, we allow just to overwrite it.
        // and there's no need to check the _to address, because the _to address need to do an acceptance.
        rightsChanging[msg.sender] = _to;
        emit RightsChanging(msg.sender, _to);
    }
    // @dev accept all rights from an old address.
    function acceptAllRights(address _from) public {
        require(rightsChanging[_from] == msg.sender, "no changing record");
        require(userLockedAmount[msg.sender] == 0, "sender already have lock-up");

        delete rightsChanging[_from];

        userType[msg.sender] = userType[_from];
        userLockedAmount[msg.sender] = userLockedAmount[_from];
        firstPeriodLockedTime[msg.sender] = firstPeriodLockedTime[_from];
        lockedPeriodAmount[msg.sender] = lockedPeriodAmount[_from];
        currentTimestamp[msg.sender] = currentTimestamp[_from];
        claimedPeriod[msg.sender] = claimedPeriod[_from];
        delete userType[_from];
        delete userLockedAmount[_from];
        delete firstPeriodLockedTime[_from];
        delete lockedPeriodAmount[_from];
        delete currentTimestamp[_from];
        delete claimedPeriod[_from];

        emit RightsAccepted(_from, msg.sender);
    }

    /**
    * query the base info
    */
    function getUserInfo(address account) external view returns (
        uint256 typId,
        uint256 lockedAount,
        uint256 firstLockTime,
        uint256 totalPeriod,
        uint256 alreadyClaimed,
        uint256 releases
    ) {
        typId = userType[account];
        lockedAount = userLockedAmount[account];
        firstLockTime = firstPeriodLockedTime[account];
        totalPeriod = lockedPeriodAmount[account];
        alreadyClaimed = claimedPeriod[account];
        releases = getUserReleasedPeriod(account);
    }

}