/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract PoolMatrixGame {

    uint constant LEVELS_COUNT = 20;
    uint constant ROOT_WALLETS_COUNT = 4;
    uint constant SECONDS_IN_DAY = 24 * 3600;
    uint constant SECONDS_IN_DAY_HALF = 12 * 3600;

    uint[] levelIntervals = [
        0 hours,   // level 1-13:00 ; 0d*24 + 0h
        3 hours,   // level 2-16:00 ; 0d*24 + 3h
        6 hours,   // level 3-19:00 ; 0d*24 + 6h
        24 hours,  // level 4-13:00 ; 1d*24 + 0h
        27 hours,  // level 5-16:00 ; 1d*24 + 3h
        30 hours,  // level 6-19:00 ; 1d*24 + 6h
        48 hours,  // level 7-13:00 ; 2d*24 + 0h
        54 hours,  // level 8-19:00 ; 2d*24 + 6h
        72 hours,  // level 9-13:00 ; 3d*24 + 0h
        78 hours,  // level 10-19:00 ; 3d*24 + 6h
        101 hours, // level 11-18:00 ; 4d*24 + 5h
        125 hours, // level 12-18:00 ; 5d*24 + 5h
        149 hours, // level 13-18:00 ; 6d*24 + 5h
        173 hours, // level 14-18:00 ; 7d*24 + 5h
        197 hours, // level 15-18:00 ; 8d*24 + 5h
        221 hours, // level 16-18:00 ; 9d*24 + 5h
        245 hours, // level 17-18:00 ; 10d*24 + 5h
        269 hours, // level 18-18:00 ; 11d*24 + 5h
        293 hours, // level 19-18:00 ; 12d*24 + 5h
        317 hours  // level 20-18:00 ; 13d*24 + 5h
    ];

    //----------------------------------------------------------------------------------------------------------------------
    //  Config for testing
    //----------------------------------------------------------------------------------------------------------------------
    
    uint[] levelPrices = [
        0.001 * 1e18, //  1 POOL = 0.001 ETH 
        0.002 * 1e18, //  2 POOL = 0.002 ETH 
        0.003 * 1e18, //  3 POOL = 0.003 ETH 
        0.004 * 1e18, //  4 POOL = 0.004 ETH 
        0.005 * 1e18, //  5 POOL = 0.005 ETH 
        0.006 * 1e18, //  6 POOL = 0.006 ETH 
        0.007 * 1e18, //  7 POOL = 0.007 ETH 
        0.008 * 1e18, //  8 POOL = 0.008 ETH 
        0.009 * 1e18, //  9 POOL = 0.009 ETH 
        0.010 * 1e18, // 10 POOL = 0.010 ETH 
        0.011 * 1e18, // 11 POOL = 0.011 ETH 
        0.012 * 1e18, // 12 POOL = 0.012 ETH 
        0.013 * 1e18, // 13 POOL = 0.013 ETH 
        0.014 * 1e18, // 14 POOL = 0.014 ETH 
        0.015 * 1e18, // 15 POOL = 0.015 ETH 
        0.016 * 1e18, // 16 POOL = 0.016 ETH 
        0.017 * 1e18, // 17 POOL = 0.017 ETH 
        0.018 * 1e18, // 18 POOL = 0.018 ETH 
        0.019 * 1e18, // 19 POOL = 0.019 ETH 
        0.020 * 1e18  // 20 POOL = 0.020 ETH 
    ];

    uint constant REGISTRATION_PRICE = 0.001 * 1e18; // 0.001 ETH
    uint constant LEVEL_FEE_PERCENTS = 2; // 2% fee
    uint constant USER_REWARD_PERCENTS = 74; // 74% reward

    uint[] referrerPercents = [
        14, // 14% to 1st referrer
        7,  // 7% to 2nd referrer
        3   // 3% to 3rd refrrer
    ];
    //----------------------------------------------------------------------------------------------------------------------
    //  END OF: Config for testing
    //----------------------------------------------------------------------------------------------------------------------

    //----------------------------------------------------------------------------------------------------------------------
    //  Config for production
    //----------------------------------------------------------------------------------------------------------------------

    /*uint[] levelPrices = [
        0.05 * 1e18, //  1 POOL = 0.05 BNB
        0.07 * 1e18, //  2 POOL = 0.07 BNB
        0.10 * 1e18, //  3 POOL = 0.10 BNB
        0.13 * 1e18, //  4 POOL = 0.13 BNB
        0.16 * 1e18, //  5 POOL = 0.16 BNB
        0.25 * 1e18, //  6 POOL = 0.25 BNB
        0.30 * 1e18, //  7 POOL = 0.30 BNB
        0.35 * 1e18, //  8 POOL = 0.35 BNB
        0.40 * 1e18, //  9 POOL = 0.40 BNB
        0.45 * 1e18, // 10 POOL = 0.45 BNB
        0.75 * 1e18, // 11 POOL = 0.75 BNB
        0.90 * 1e18, // 12 POOL = 0.90 BNB
        1.05 * 1e18, // 13 POOL = 1.05 BNB
        1.20 * 1e18, // 14 POOL = 1.20 BNB
        1.35 * 1e18, // 15 POOL = 1.35 BNB
        2.00 * 1e18, // 16 POOL = 2.00 BNB
        2.50 * 1e18, // 17 POOL = 2.50 BNB
        3.00 * 1e18, // 18 POOL = 3.00 BNB
        3.50 * 1e18, // 19 POOL = 3.50 BNB
        4.00 * 1e18  // 20 POOL = 4.00 BNB
    ];

    uint constant REGISTRATION_PRICE = 0.05 * 1e18; // 0.05 BNB
    uint constant LEVEL_FEE_PERCENTS = 2; // 2% fee
    uint constant USER_REWARD_PERCENTS = 74; // 74% reward

    uint[] referrerPercents = [
        14, // 14% to 1st referrer
        7,  // 7% to 2nd referrer
        3   // 3% to 3rd refrrer
    ];*/
    //----------------------------------------------------------------------------------------------------------------------
    //  END OF: Config for production
    //----------------------------------------------------------------------------------------------------------------------

    struct User {
        uint id;
        address userAddr;
        address referrer;
        uint regDate;
        UserLevelInfo[] levels;
        uint maxLevel;
        uint debit;
        uint credit;
        uint referralReward;
        uint lastReferralReward;
        uint levelProfit;
        uint line1;
        uint line2;
        uint line3;
    }

    struct UserLevelInfo {
        uint openState; // 0 - closed, 1 - closed (opened once), 2 - opened
        uint payouts;
        uint missedProfit;
        uint partnerBonus;
        uint poolProfit;
    }

    address private adminWallet;
    address private regFeeWallet;
    address private marketingWallet;
    uint private initialDate;
    mapping (address => User) private users;
    address[] private userAddresses;
    uint private userCount;
    address private rootWallet1;
    address private rootWallet2;
    address private rootWallet3;
    address private rootWallet4;
    mapping(uint => address[]) private levelQueue;
    mapping(uint => uint) private headIndex;
    uint private marketingBalance;
    uint private transactionCounter;
    uint private turnoverAmount;
    uint private stats1date;
    uint private stats2date;
    uint private stats1totalUsers;
    uint private stats2totalUsers;
    uint private stats1totalTransactions;
    uint private stats2totalTransactions;
    uint private stats1totalTurnover;
    uint private stats2totalTurnover;
    uint private mode; // 0 - default, 1 - disable complex algorithms, 2 - suspended

    event Test(string msg, uint value);

    constructor(bytes memory data) {
        uint level;

        // Capture the creation date and time
        initialDate = block.timestamp;

        // Defining wallets
        adminWallet = msg.sender;
        regFeeWallet = readAddress(data, 0x15);
        marketingWallet = readAddress(data, 0x29);
        rootWallet1 = readAddress(data, 0x3d);
        rootWallet2 = readAddress(data, 0x51);
        rootWallet3 = readAddress(data, 0x65);
        rootWallet4 = readAddress(data, 0x79);

        // Adding root users to the users table
        for (uint i = 0; i < ROOT_WALLETS_COUNT; i++) {
            address addr;
            address reff;
            if (i == 0) {
                addr = rootWallet1;
                reff = rootWallet2;
            }
            else if (i == 1) {
                addr = rootWallet2;
                reff = rootWallet3;
            }
            else if (i == 2) {
                addr = rootWallet3;
                reff = rootWallet4;
            }
            else {
                addr = rootWallet4;
                reff = rootWallet1;
            }
            
            users[addr].id = userCount;
            users[addr].userAddr = addr;
            users[addr].referrer = reff;
            users[addr].regDate = block.timestamp;
            users[addr].maxLevel = LEVELS_COUNT;
            //users[addr].debit = 0;
            //users[addr].credit = 0;
            //users[addr].referralReward = 0;
            //users[addr].lastReferralReward = 0;
            //users[addr].levelProfit = 0;
            //users[addr].line1 = 0;
            //users[addr].line2 = 0;
            //users[addr].line3 = 0;
            userAddresses.push(addr);
            userCount++;

            for (level = 0; level < LEVELS_COUNT; level++) {
                users[addr].levels.push(UserLevelInfo({
                    openState: 2, // opened
                    payouts: 0,
                    missedProfit: 0,
                    partnerBonus: 0,
                    poolProfit: 0
                }));
            }
        }

        // Filling levels queue with initial values
        for (level = 0; level < LEVELS_COUNT; level++) {
            levelQueue[level].push(rootWallet1);
            levelQueue[level].push(rootWallet2);
            levelQueue[level].push(rootWallet3);
            levelQueue[level].push(rootWallet4);
        }
    }

    receive() external payable {
        uint restOfAmount = msg.value;
        if (users[msg.sender].regDate == 0) {
            register(rootWallet1, restOfAmount);
            restOfAmount -= REGISTRATION_PRICE;
        }
        buyLevel(users[msg.sender].maxLevel, restOfAmount);
        transactionCounter++;
    }

    fallback() external payable {
        bytes memory data = msg.data;
        uint8 action;
        address referrer;
        uint8 levelNumber;
       
        // Reading action
        assembly {
            action := mload(add(data, 1))
        }

        // Executing the action
        uint restOfAmount = msg.value;
        if (action == 1) { // Register and buy level
            assembly {
                referrer := mload(add(data, 21))
            }
            register(referrer, restOfAmount);
            restOfAmount -= REGISTRATION_PRICE;
            buyLevel(0, restOfAmount);
            transactionCounter++;
        }
        else if (action == 2) { // Buy the level
            assembly {
                levelNumber := mload(add(data, 2))
            }
            buyLevel(levelNumber, restOfAmount);
            transactionCounter++;
        }
    }

    function readAddress(bytes memory data, uint offs) pure internal returns (address) {
        address addr;
        assembly {
            addr := mload(add(data, offs))
        }
        return addr;
    }

    function isContract(address addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return (size > 0);
    }

    function getSchedule() public view returns(uint date, uint[] memory intervals) {
        return (initialDate, levelIntervals);
    }

    function setSchedule(uint date, uint[] memory intervals) public {
        require(msg.sender == adminWallet);
        initialDate = date;
        for (uint i = 0; i < LEVELS_COUNT; i++)
            levelIntervals[i] = intervals[i];
    }

    function register(address referrer, uint investAmount) public payable {
        require(mode != 2); // Check if contract is not suspended
        require(investAmount >= REGISTRATION_PRICE); // Check if receive the right amount
        require(users[msg.sender].regDate == 0); // Check if user is already registered
        require(!isContract(msg.sender)); // This should be user wallet, not contract or other bot

        // If referrer is not valid then set it to default
        if (referrer == msg.sender && referrer == address(0) && users[referrer].id == 0)
            referrer = rootWallet1;

        // Adding user to the users table
        users[msg.sender].id = userCount;
        users[msg.sender].userAddr = msg.sender;
        users[msg.sender].referrer = referrer;
        users[msg.sender].regDate = block.timestamp;
        //users[msg.sender].maxLevel = 0;
        //users[msg.sender].debit = 0;
        //users[msg.sender].credit = 0;
        //users[msg.sender].referralReward = 0;
        //users[msg.sender].lastReferralReward = 0;
        //users[msg.sender].levelProfit = 0;
        //users[msg.sender].line1 = 0;
        //users[msg.sender].line2 = 0;
        //users[msg.sender].line3 = 0;
        userAddresses.push(msg.sender);
        userCount++;

        // Creating levels for the user
        for (uint level = 0; level < LEVELS_COUNT; level++) {
            users[msg.sender].levels.push(UserLevelInfo({
                openState: 0, // closed
                payouts: 0,
                missedProfit: 0,
                partnerBonus: 0,
                poolProfit: 0
            }));
        }

        // Filling referrer lines
        address currRef = users[msg.sender].referrer;
        users[currRef].line1++;
        currRef = users[currRef].referrer;
        users[currRef].line2++;
        currRef = users[currRef].referrer;
        users[currRef].line3++;

        // Sending the money to the project wallet
        payable(regFeeWallet).transfer(REGISTRATION_PRICE);

        // Storing substracted amount
        users[msg.sender].credit += REGISTRATION_PRICE;
        turnoverAmount += REGISTRATION_PRICE;

        // Updating increments
        uint half = (block.timestamp / SECONDS_IN_DAY_HALF) % 2;
        stats24hNormalize(half);
        if (half == 0) {
            stats1totalUsers++;
            stats1totalTurnover += REGISTRATION_PRICE;
        }
        else {
            stats2totalUsers++;
            stats2totalTurnover += REGISTRATION_PRICE;
        }
    }

    function buyLevel(uint level, uint investAmount) public payable {
        // Prepare the data
        uint levelPrice = levelPrices[level];

        //require(level >= 0 && level < LEVELS_COUNT); // Check if level number is valid
        require(mode != 2); // Check if contract is not suspended
        require(investAmount >= levelPrice); // Check if receive the right amount
        require(users[msg.sender].regDate > 0); // Check if user is exists
        require(level <= users[msg.sender].maxLevel); // Check if level is allowed
        require(block.timestamp >= initialDate + levelIntervals[level]); // Check if level is available
        require(users[msg.sender].levels[level].openState != 2); // Check if level is not opened

        // Updating increments
        uint half = (block.timestamp / SECONDS_IN_DAY_HALF) % 2;
        stats24hNormalize(half);
        if (half == 0) {
            stats1totalTransactions++;
            stats1totalTurnover += investAmount;
        }
        else {
            stats2totalTransactions++;
            stats2totalTurnover += investAmount;
        }

        // Storing substracted amount
        users[msg.sender].credit += investAmount;
        turnoverAmount += investAmount;

        // Sending fee for buying level
        uint levelFee = levelPrice * LEVEL_FEE_PERCENTS / 100;
        payable(marketingWallet).transfer(levelFee);
        marketingBalance += levelFee;
        investAmount -= levelFee;

        // Sending rewards to top referrers
        address referrer = users[msg.sender].referrer;
        for (uint i = 0; i < 3; i++) {
            // Calculating the value to invest to current referrer
            uint value = levelPrice * referrerPercents[i] / 100;

            // Skipping all the referres that does not have this level previoisly opened
            while (users[referrer].levels[level].openState == 0) {
                users[referrer].levels[level].missedProfit += value;
                referrer = users[referrer].referrer;
            }

            // If it is not root user than we sending money to it, otherwice we collecting the rest of money
            payable(referrer).transfer(value);
            users[referrer].debit += value;
            users[referrer].referralReward += value;
            users[referrer].lastReferralReward = value;
            users[referrer].levels[level].partnerBonus += value;
            investAmount -= value;

            // Switching to the next referrer (if we can)
            referrer = users[referrer].referrer;
        }

        // Sending reward to first user in the queue of this level
        address rewardAddress = levelQueue[level][headIndex[level]];
        if (rewardAddress != msg.sender) {
            uint reward = levelPrice * USER_REWARD_PERCENTS / 100;
            bool sent = payable(rewardAddress).send(reward);
            if (sent) {
                investAmount -= reward;
                users[rewardAddress].debit += reward;
                users[rewardAddress].levelProfit += reward;
                users[rewardAddress].levels[level].poolProfit += reward;
                users[rewardAddress].levels[level].payouts++;
                if (users[rewardAddress].levels[level].payouts >= 2 && users[rewardAddress].id >= ROOT_WALLETS_COUNT) {
                    users[rewardAddress].levels[level].openState = 1; // closed (opened once)
                    users[rewardAddress].levels[level].payouts = 0;
                }
                else {
                    levelQueue[level].push(rewardAddress);
                }
                headIndex[level]++;
            }
        }

        if (investAmount > 0) {
            payable(marketingWallet).transfer(investAmount); 
            marketingBalance += investAmount;
        }

        // Activating level
        if (users[msg.sender].levels[level].payouts == 0 || mode == 1) { // In high load the complex insertion algorithms can be disabled
            levelQueue[level].push(msg.sender);
        }
        else {
            levelQueue[level].push(address(0));
            uint len = levelQueue[level].length;
            uint pos = headIndex[level] + block.timestamp % (len - headIndex[level]);
            for (uint i = len - 2; i >= pos; i--)
                levelQueue[level][i + 1] = levelQueue[level][i];
            levelQueue[level][pos] = msg.sender;
        }
        users[msg.sender].levels[level].openState = 2;
        users[msg.sender].levels[level].missedProfit = 0;
        if (level >= users[msg.sender].maxLevel)
            users[msg.sender].maxLevel = level + 1;
    }

    function stats24hNormalize(uint half) internal {
        uint date = block.timestamp / SECONDS_IN_DAY;
        if (half == 0) {
            if (stats1date != date) {
                stats1date = date;
                stats1totalUsers = 0;
                stats1totalTransactions = 0;
                stats1totalTurnover = 0;
            }
        }
        else {
            if (stats2date != date) {
                stats2date = date;
                stats2totalUsers = 0;
                stats2totalTransactions = 0;
                stats2totalTurnover = 0;
            }
        }
    }

    function getUserAddresses() public view returns(address[] memory) {
        return userAddresses;
    }

    function getUserCount() public view returns(uint) {
        return userCount;
    }

    function getUsersFragment(uint start, uint end) public view returns(User[] memory) {
        User[] memory list = new User[](end - start);
        for (uint i = start; i < end; i++)
            list[i] = users[userAddresses[i]];

        return list;
    }

    function getUser(address userAddr) public view returns(User memory) {
        return users[userAddr];
    }

    function getUserByID(uint id) public view returns(User memory) {
        return getUser(userAddresses[id]);
    }

    function hasUser(address userAddr) public view returns(bool) {
        return users[userAddr].regDate > 0;
    }

    function getQueueSize(uint level) public view returns (uint) {
        return levelQueue[level].length - headIndex[level];
    }

    function getQueueFragment(uint level, uint start, uint end) public view returns (address[] memory) {
        if (end == 0)
            end = getQueueSize(level);

        address[] memory queue = new address[](end - start);
        uint index = 0;
        uint i = headIndex[level] + start;
        uint n = i + end;
        for (; i < n; i++) {
            queue[index] = levelQueue[level][i];
            index++;
        }

        return queue;
    }

    function getQueueForLevel(uint level) public view returns (address[] memory addresses, uint[] memory payouts) {
        uint queueSize = levelQueue[level].length - headIndex[level];
        address[] memory addressQueue = new address[](queueSize);
        uint[] memory payoutsQueue = new uint[](queueSize);

        uint index = 0;
        uint n = levelQueue[level].length;
        for (uint i = headIndex[level]; i < n; i++) {
            address addr = levelQueue[level][i];
            addressQueue[index] = addr;
            payoutsQueue[index] = users[addr].levels[level].payouts;
            index++;
        }

        return (addressQueue, payoutsQueue);
    }

    function getSlots(address userAddr) public view returns(int256[] memory slots, uint[] memory partnerBonuses, uint[] memory poolProfits, uint[] memory missedProfits) {
        int[] memory slotList = new int[](LEVELS_COUNT);
        uint[] memory partnerBonusList = new uint[](LEVELS_COUNT);
        uint[] memory poolProfitList = new uint[](LEVELS_COUNT);
        uint[] memory missedProfitList = new uint[](LEVELS_COUNT);
        for (uint level = 0; level < LEVELS_COUNT; level++) {
            if (block.timestamp < initialDate + levelIntervals[level]) {
                slotList[level] = 10; // Not availabled yet (user need to wait some time once it bacome available)
                continue;
            }

			if (users[userAddr].levels[level].missedProfit > 0)
                missedProfitList[level] = users[userAddr].levels[level].missedProfit;

            if (level > users[userAddr].maxLevel) {
                slotList[level] = 20; // Not allowed yet (previous level is not opened)
                continue;
            }

            partnerBonusList[level] = users[userAddr].levels[level].partnerBonus;
            poolProfitList[level] = users[userAddr].levels[level].poolProfit;

            if (users[userAddr].levels[level].openState != 2) {
                if (users[userAddr].levels[level].openState == 0)
                    slotList[level] = 30; // Available for opening
                else
                    slotList[level] = 40; // Available for reopening

                continue;
            }

            int place = 0;
            for (uint i = headIndex[level]; i < levelQueue[level].length; i++) {
                place++;
                if (levelQueue[level][i] == userAddr) {
                    int n = int(levelQueue[level].length - headIndex[level]);
                    slotList[level] = -int((n - place + 1) * 1000 / n); // Slot is opened
                    break;
                }
            }
        }

        return (slotList, partnerBonusList, poolProfitList, missedProfitList);
    }

    function levelIsOpened(address userAddr, uint level) public view returns(bool) {
        return users[userAddr].levels[level].openState == 2;
    }

    function getBalances(uint start, uint end) public view returns (uint counter, uint marketingFee, address[] memory wallets, address[] memory referrers, uint[] memory debits, uint[] memory credits) {
        if (start == 0 && end == 0)
            end = userCount;
        
        uint n = end - start;
        address[] memory referrerList = new address[](n);
        uint[] memory debitList = new uint[](n);
        uint[] memory creditList = new uint[](n);
        for (uint i = start; i < end; i++) {
            address addr = userAddresses[i];
            referrerList[i] = users[addr].referrer;
            debitList[i] = users[addr].debit;
            creditList[i] = users[addr].credit;
        }
        return (transactionCounter, marketingBalance, userAddresses, referrerList, debitList, creditList);
    }

    function withdraw(uint amount, address payable destAddr) public {
        require(msg.sender == adminWallet);
        destAddr.transfer(amount);
    }

    function getTotalInfo() public view returns(uint totalUsers, uint totalTransactions, uint totalTurnover, uint totalUsersIncrement, uint totalTransactionsIncrement, uint totalTurnoverIncrement) {
        return (
            userCount,
            transactionCounter,
            turnoverAmount,
            stats1totalUsers + stats2totalUsers,
            stats1totalTransactions + stats2totalTransactions,
            stats1totalTurnover + stats2totalTurnover
        );
    }

    function getUserAddrByID(uint id) public view returns(address) {
        return userAddresses[id];
    }

    function getUserIDByAddr(address userAddr) public view returns(uint) {
        return users[userAddr].id;
    }

    function importClean() public {
        require(msg.sender == adminWallet);
        for (uint level = 0; level < LEVELS_COUNT; level++) {
            while (levelQueue[level].length > 0)
                levelQueue[level].pop();
            headIndex[level] = 0;
        }
        for (uint i = 0; i < userCount; i++)
            userAddresses.pop();
        userCount = 0;
    }

    function importUsers(User[] memory newUsers) public {
        require(msg.sender == adminWallet);
        for (uint i = 0; i < newUsers.length; i++) {
            User memory newUser = newUsers[i];
            address addr = newUser.userAddr; 
            User storage destUser = users[addr];

            if (users[addr].regDate == 0) {
                destUser.id = userCount;
                userCount++;
                destUser.userAddr = addr;
                userAddresses.push(addr);
                while (users[addr].levels.length > 0)
                    users[addr].levels.pop();
            }

            destUser.referrer = newUser.referrer;
            destUser.regDate = newUser.regDate;
            destUser.maxLevel = newUser.maxLevel;
            destUser.debit = newUser.debit;
            destUser.credit = newUser.credit;
            destUser.referralReward = newUser.referralReward;
            destUser.lastReferralReward = newUser.lastReferralReward;
            destUser.levelProfit = newUser.levelProfit;
            destUser.line1 = newUser.line1;
            destUser.line2 = newUser.line2;
            destUser.line3 = newUser.line3;
            
            for (uint level = 0; level < LEVELS_COUNT; level++) {
                users[addr].levels.push(UserLevelInfo({
                    openState: newUser.levels[level].openState,
                    payouts: newUser.levels[level].payouts,
                    missedProfit: newUser.levels[level].missedProfit,
                    partnerBonus: newUser.levels[level].partnerBonus,
                    poolProfit: newUser.levels[level].poolProfit
                }));
            }
        }
    }

    function importLevels(address[][] memory addrs) public {
        require(msg.sender == adminWallet);
        for (uint level = 0; level < LEVELS_COUNT; level++) {
            if (addrs[level].length == 0)
                continue;

            // Cleaning old queue
            while (levelQueue[level].length > 0)
                levelQueue[level].pop();
            headIndex[level] = 0;

            // Inserting new queue
            for (uint i = 0; i < addrs.length; i++) {
                address addr = addrs[level][i];
                if (users[addr].regDate > 0)
                    levelQueue[level].push(addr);
            }
        }
    }

    function setMode(uint newMode) public {
        require(msg.sender == adminWallet);
        mode = newMode;
    }

    function setParams(uint totalTransactions, uint totalTurnover, uint users24h1, uint users24h2, uint transactions24h1, uint transactions24h2, uint turnover24h1, uint turnover24h2) public {
        require(msg.sender == adminWallet);
        /*transactionCounter = totalTransactions;
        turnoverAmount = totalTurnover;
        stats1totalUsers = users24h1;
        stats2totalUsers = users24h2;
        stats1totalTransactions = transactions24h1;
        stats2totalTransactions = transactions24h2;
        stats1totalTurnover = turnover24h1;
        stats2totalTurnover = turnover24h2;*/
    }

}