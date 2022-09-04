/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

contract PoolMatrixGame {

    //======================================================================================================================
    //  Config for testing
    //======================================================================================================================
    uint constant levelsCount = 20;

    uint256[] levelPrices = [
        0.001 * 1e18, //  1 POOL = 0.001 ETH 
        0.001 * 1e18, //  2 POOL = 0.001 ETH 
        0.001 * 1e18, //  3 POOL = 0.001 ETH 
        0.001 * 1e18, //  4 POOL = 0.001 ETH 
        0.001 * 1e18, //  5 POOL = 0.001 ETH 
        0.001 * 1e18, //  6 POOL = 0.001 ETH 
        0.001 * 1e18, //  7 POOL = 0.001 ETH 
        0.001 * 1e18, //  8 POOL = 0.001 ETH 
        0.001 * 1e18, //  9 POOL = 0.001 ETH 
        0.001 * 1e18, // 10 POOL = 0.001 ETH 
        0.001 * 1e18, // 11 POOL = 0.001 ETH 
        0.001 * 1e18, // 12 POOL = 0.001 ETH 
        0.001 * 1e18, // 13 POOL = 0.001 ETH 
        0.001 * 1e18, // 14 POOL = 0.001 ETH 
        0.001 * 1e18, // 15 POOL = 0.001 ETH 
        0.001 * 1e18, // 16 POOL = 0.001 ETH 
        0.001 * 1e18, // 17 POOL = 0.001 ETH 
        0.001 * 1e18, // 18 POOL = 0.001 ETH 
        0.001 * 1e18, // 19 POOL = 0.001 ETH 
        0.001 * 1e18  // 20 POOL = 0.001 ETH 
    ];

    uint256[] referrerPercents = [
        14, // 14% to 1st referrer
        7,  // 7% to 2nd referrer
        3   // 3% to 3rd refrrer
    ];

    uint256 constant REGISTRATION_PRICE = 0.001 * 1e18; // 0.001 eth
    uint256 constant LEVEL_FEE_PERCENTS = 2; // 2% fee
    uint256 constant PER_5_LEVELS_INTERVAL = 10 minutes; // Each 5 levels are opened in 10 minutes
    uint256 constant PER_LEVEL_INTERVAL = 1 minutes; // Each next level (from 5 levels) is opened in 1 minute after previous one
    //======================================================================================================================
    //  END OF: Config for testing
    //======================================================================================================================

    //======================================================================================================================
    //  Config for production
    //======================================================================================================================
    /*
    uint constant levelsCount = 20;

    uint256[] levelPrices = [
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

    uint256[] referrerPercents = [
        14, // 14% to 1st referrer
        7,  // 7% to 2nd referrer
        3   // 3% to 3rd refrrer
    ];

    uint256 constant REGISTRATION_PRICE = 0.05 * 1e18; // 0.05 bnb
    uint256 constant LEVEL_FEE_PERCENTS = 2; // 2% fee
    uint256 constant PER_5_LEVELS_INTERVAL = 12 hours; // Each 5 levels are opened in 12 hours
    uint256 constant PER_LEVEL_INTERVAL = 1 hours; // Each next level (from 5 levels) is opened in 1 hour after previous one
    */
    //======================================================================================================================
    //  END OF: Config for production
    //======================================================================================================================

    struct User {
        bool registered;
        uint registrationTimestamp;
        address userAddr;
        address referrer;
        uint256 balance;
        UserLevelInfo[] levels;
    }

    struct UserLevelInfo {
        bool opened;
        uint payouts;
    }

    address public adminWallet; // The wallet from which contract has been created
    address public registrationWallet; // For registration rewards
    address public marketingWallet; // For fees for buying levels
    
    uint creationTimestamp;
    mapping (address => User) internal users;
    address[] internal userAddresses;
    mapping(uint8 => address[]) internal levelQueue;
    mapping(uint8 => uint) internal headIndex;

    event ContractCreated(string msg, uint timestamp);
    event UserRegistered(address indexed userAddr);
    event LevelActivated(address indexed userAddr, uint8 level);
    event LevelDeactivated(address indexed userAddr, uint8 level);

    constructor() {
        uint i;
        uint8 level;

        // Defining wallets
        adminWallet = msg.sender;
        marketingWallet = 0xce072faC1888c6A272546e28020d3293B30b9Ff6;
        registrationWallet = 0x3C94E1C74f22d23E0334716BAE213F508a7A7907;

        // Capture the creation date and time
        creationTimestamp = block.timestamp;

        // Define root users
        address[] memory rootWallets = new address[](4);
        rootWallets[0] = 0x3bBa5c2540A15f70EB5edAD16b8fB4584Dc4D5A2; // Root wallet #1
        rootWallets[1] = 0xB910B076b73C79c1a5ac6C7bde5a81D4CCeee902; // Root wallet #2
        rootWallets[2] = 0x751A89adaa8d6E0f51A63E44dDD804eDCA1FFF5a; // Root wallet #3
        rootWallets[3] = 0xfEF80e1D7C168504D5168835e503694a9A2af007; // Root wallet #4

        // Adding root users to the users table
        for (i = 0; i < rootWallets.length; i++) {
            address addr = rootWallets[i];
            
            users[addr].registered = true;
            users[addr].registrationTimestamp = block.timestamp;
            users[addr].userAddr = addr;
            users[addr].referrer = address(0);
            users[addr].balance = 0;
            userAddresses.push(addr);

            for (level = 0; level < levelsCount; level++) {
                users[addr].levels.push(UserLevelInfo({
                    opened: true,
                    payouts: 0
                }));
            }
        }

        // Filling levels queue with initial values
        for (level = 0; level < levelsCount; level++) {
            for (i = 0; i < rootWallets.length; i++)
                levelQueue[level].push(rootWallets[i]);
        }
       
        emit ContractCreated("Contract has been created", creationTimestamp);
    }

    receive() external payable {
        
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
        uint256 restOfAmount = msg.value;
        if (action == 1) { // Register
            assembly {
                referrer := mload(add(data, 21))
            }
            register(referrer, restOfAmount);
        }
        else if (action == 2) { // Register and buy level
            assembly {
                referrer := mload(add(data, 21))
                levelNumber := mload(add(data, 22))
            }
            register(referrer, restOfAmount);
            restOfAmount -= REGISTRATION_PRICE;
            buyLevel(levelNumber, restOfAmount);
        }
        else if (action == 3) { // Buy the level
            assembly {
                levelNumber := mload(add(data, 2))
            }
            buyLevel(levelNumber, restOfAmount);
        }
    }

    function register(address referrer, uint256 investAmount) public payable {
        // Check if receive the right amount
        require(investAmount >= REGISTRATION_PRICE, "Low amount received");

        // Check if referrer address is valid
        require(referrer != msg.sender && referrer != address(0), "Invalid referrer");

        // Check if user is already registered
        require(users[msg.sender].registered == false, "User is already registered");

        // Adding user to the users table
        users[msg.sender].registered = true;
        users[msg.sender].registrationTimestamp = block.timestamp;
        users[msg.sender].userAddr = msg.sender;
        users[msg.sender].referrer = referrer;
        users[msg.sender].balance = 0;
        userAddresses.push(msg.sender);

        // Creating levels for the user
        for (uint level = 0; level < levelsCount; level++) {
            users[msg.sender].levels.push(UserLevelInfo({
                opened: false,
                payouts: 0
            }));
        }

        // Sending the money to the project wallet
        payable(registrationWallet).transfer(REGISTRATION_PRICE);

        // Tell that registration was sucessfully completed
        emit UserRegistered(msg.sender);
    }

    function buyLevel(uint8 level, uint256 investAmount) public payable {
        // Check if level number is valid
        require(level >= 1 && level <= levelsCount, "Invalid level number");

        // Check if receive the right amount
        require(investAmount >= levelPrices[level - 1], "Low amount received");

        // Check if user is exists and it has a referrer
        require(users[msg.sender].referrer != address(0), "User not exist");

        // Check if slot is avalilable
        require(checkSlotAvailable(msg.sender, level), "Slot is not available yet");

        // Prepare the data
        level--;
        uint256 restOfAmount = investAmount;

        // Sending fee for buying level
        uint256 levelFee = investAmount * LEVEL_FEE_PERCENTS / 100;
        payable(marketingWallet).transfer(levelFee);
        restOfAmount -= levelFee;

        // Sending rewards to top referrers
        bool isRootUser = false;
        uint256 amountForRootUser = 0;
        address referrer = users[msg.sender].referrer;
        for (uint i = 0; i < 3; i++) {
            // Calculating the value to invest to current referrer
            uint256 value = investAmount * referrerPercents[i] / 100;

            // Check if referrer is root user
            isRootUser = (users[referrer].referrer == address(0));

            // If it is not root user than we sending money to it, otherwice we collecting the rest of money
            if (!isRootUser)
                payable(referrer).transfer(value);
            else
                amountForRootUser += value;
                
            // Updating balances
            users[referrer].balance += value;
            restOfAmount -= value;

            // Switching to the next referrer (if we can)
            if (!isRootUser)
                referrer = users[referrer].referrer;
        }
        // If we ended on the root user then we send rest of money to him
        if (isRootUser)
            payable(referrer).transfer(amountForRootUser);
        
        // Activating level
        if (!users[msg.sender].levels[level].opened) {
            users[msg.sender].levels[level].opened = true;
            levelQueue[level].push(msg.sender);
            emit LevelActivated(msg.sender, level + 1);
        }

        // Sending reward to first user in the queue of this level
        address rewardAddress = levelQueue[level][headIndex[level]];
        if (rewardAddress != msg.sender) {
            bool sent = payable(rewardAddress).send(restOfAmount);
            if (sent) {
                users[rewardAddress].levels[level].payouts++;
                if (users[rewardAddress].levels[level].payouts >= 2) {
                    users[rewardAddress].levels[level].opened = false;
                    users[rewardAddress].levels[level].payouts = 0;
                    emit LevelDeactivated(msg.sender, level);
                }
                else {
                    levelQueue[level].push(rewardAddress);
                }
                delete levelQueue[level][headIndex[level]];
                headIndex[level]++;
            }
            else {
                payable(marketingWallet).transfer(restOfAmount);
            }
        }
        else {
            payable(marketingWallet).transfer(restOfAmount);
        }
    }

    function getUserAddresses() public view returns(address[] memory) {
        return userAddresses;
    }

    function getUsers() public view returns(User[] memory) {
        User[] memory list = new User[](userAddresses.length);

        for (uint i = 0; i < userAddresses.length; i++)
            list[i] = users[userAddresses[i]];

        return list;
    }

    function getUser(address userAddr) public view returns(bool registered, uint registrationTimestamp, address userAddress, address referrer, uint256 balance, UserLevelInfo[] memory levels) {
        require (users[userAddr].registered, "Invalid user");
        User memory user = users[userAddr];
        return (
            user.registered,
            user.registrationTimestamp,
            user.userAddr,
            user.referrer,
            user.balance,
            user.levels
        );
    }

    function hasUser(address userAddr) public view returns(bool) {
        return users[userAddr].registered;
    }

    function getQueueForLevel(uint8 level) public view returns (address[] memory) {
        require (level >= 1 && level <= levelsCount, "Invalid level");
        level--;
        address[] memory queue = new address[](levelQueue[level].length - headIndex[level]);
        uint index = 0;
        uint n = levelQueue[level].length;
        for (uint i = headIndex[level]; i < n; i++) {
            queue[index] = levelQueue[level][i];
            index++;
        }
        return queue;
    }

    function getPlaceInQueue(address userAddr, uint8 level) public view returns(uint, uint) {
        require (users[userAddr].registered, "Invalid user");
        require (level >= 1 && level <= levelsCount, "Invalid level");
        level--;

        if (!users[userAddr].levels[level].opened)
            return (0, 0);

        uint place = 0;
        for (uint i = headIndex[level]; i < levelQueue[level].length; i++) {
            place++;
            if (levelQueue[level][i] == userAddr)
                return (place, levelQueue[level].length - headIndex[level]);
        }

        revert();
    }

    function checkSlotAvailable(address userAddr, uint8 level) public view returns (bool) {
        require (users[userAddr].registered, "Invalid user");
        require (level >= 1 && level <= levelsCount, "Invalid level");
        level--;
        uint currentSlotOpenDate = users[userAddr].registrationTimestamp;
        currentSlotOpenDate += (level / 5) * PER_5_LEVELS_INTERVAL;
        currentSlotOpenDate += (level % 5) * PER_LEVEL_INTERVAL;
        return block.timestamp >= currentSlotOpenDate;
    }

    function withdraw(uint amount, address payable destAddr) public {
        require(msg.sender == adminWallet, "Only owner can withdraw");
        destAddr.transfer(amount);
    }

    function reset() public {
        uint i;
        uint j;
        uint8 level;

        for (i = 0; i < userAddresses.length; i++) {
            address addr = userAddresses[i];
            users[addr].registered = false;
            users[addr].registrationTimestamp = 0;
            users[addr].userAddr = address(0);
            users[addr].referrer = address(0);
            users[addr].balance = 0;
            for (j = 0; j < levelsCount; j++)
                users[addr].levels.pop();
        }
        while (userAddresses.length > 0)
            userAddresses.pop();

        for (level = 0; level < levelsCount; i++) {
            while (headIndex[level] < levelQueue[level].length) {
                delete levelQueue[level][headIndex[level]];
                headIndex[level]++;
            }
        }

        // Define root users
        address[] memory rootWallets = new address[](4);
        rootWallets[0] = 0x3bBa5c2540A15f70EB5edAD16b8fB4584Dc4D5A2; // Root wallet #1
        rootWallets[1] = 0xB910B076b73C79c1a5ac6C7bde5a81D4CCeee902; // Root wallet #2
        rootWallets[2] = 0x751A89adaa8d6E0f51A63E44dDD804eDCA1FFF5a; // Root wallet #3
        rootWallets[3] = 0xfEF80e1D7C168504D5168835e503694a9A2af007; // Root wallet #4

        // Adding root users to the users table
        for (i = 0; i < rootWallets.length; i++) {
            address addr = rootWallets[i];
            
            users[addr].registered = true;
            users[addr].registrationTimestamp = block.timestamp;
            users[addr].userAddr = addr;
            users[addr].referrer = address(0);
            users[addr].balance = 0;
            userAddresses.push(addr);

            for (level = 0; level < levelsCount; level++) {
                users[addr].levels.push(UserLevelInfo({
                    opened: true,
                    payouts: 0
                }));
            }
        }

        // Filling levels queue with initial values
        for (level = 0; level < levelsCount; level++) {
            for (i = 0; i < rootWallets.length; i++)
                levelQueue[level].push(rootWallets[i]);
        }
       
        emit ContractCreated("Contract has been recreated", creationTimestamp);
    }

}