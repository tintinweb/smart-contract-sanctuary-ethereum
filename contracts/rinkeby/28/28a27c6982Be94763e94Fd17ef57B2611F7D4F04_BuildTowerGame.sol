// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// contract ReentrancyGuard {
//     uint256 private constant _NOT_ENTERED = 1;
//     uint256 private constant _ENTERED = 2;

//     uint256 private _status;

//     constructor() {
//         _status = _NOT_ENTERED;
//     }

//     modifier nonReentrant() {
//         require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
//         _status = _ENTERED;
//         _;
//         _status = _NOT_ENTERED;
//     }
// }

contract BuildTowerGame {
    enum RentLevelState {
        NOT_GRANTED,
        PENDING,
        GRANTED
    }

    struct User {
        uint256 id;
        uint256 registrationTimestamp;
        uint256 referrals;
        address referrer;
        // uint missedReferralPayoutSum; // хз зачем этот тут
        mapping(uint8 => UserLevelInfo) levels;
    }

    struct UserLevelInfo {
        uint256 rewardSum;
        uint256 referralPayoutSum;
        uint256 buyLevelTime;
        uint16 activationTimes;
        uint16 payouts;
        bool active;
        mapping(uint16 => Rent) levelRents; //
    }

    struct Rent {
        //
        uint256 timeStampReceived;
        RentLevelState rentLevelState;
    }

    struct GlobalStat {
        uint256 members;
        uint256 transactions;
        uint256 turnover;
    }
    bool private _status;

    modifier nonReentrant() {
        require(!_status, "ReentrancyGuard: reentrant call");
        _status = true;
        _;
        _status = false;
    }

    modifier onlyOwner() {
        require(
            (msg.sender == owner) || (msg.sender == tokenBurner),
            "Not an owner"
        );
        _;
    }

    // User related events
    // Поля помеченные indexed получают индексацию, к которой можно обратиться через ethers.js
    event BuyLevel(uint256 indexed userId, uint8 level); // тут
    event LevelPayout(
        uint256 userId,
        uint8 level,
        uint256 rewardValue,
        uint256 fromUserId
    );
    event LevelDeactivation(uint256 userId, uint8 level);
    event IncreaseLevelMaxPayouts(
        uint256 userId,
        uint8 level,
        uint16 newMaxPayouts
    );

    // Referrer related events
    event UserRegistration(uint256 indexed referralId, uint256 referrerId); // тут
    event ReferralPayout(
        uint256 referrerId,
        uint256 referralId,
        uint8 level,
        uint256 rewardValue
    ); // тут
    event MissedReferralPayout(
        uint256 referrerId,
        uint256 referralId,
        uint8 level,
        uint256 rewardValue
    );

    // Constants
    uint8 public constant REWARDPAYOUTS = 3;
    // Referral system (24%)
    uint256[] public referralRewardPercents = [
        0, // none line
        8, // 1st line
        5, // 2nd line
        3, // 3rd line
        2, // 4th line
        1, // 5th line
        1, // 6th line
        1, // 7th line
        1, // 8th line
        1, // 9th line
        1 // 10th line
    ];
    uint256 rewardableLines = referralRewardPercents.length - 1;

    // Addresses
    address payable public owner;
    address payable public tokenBurner;

    // Levels
    uint256[] public levelPrice = [
        0 ether, // none level
        0.05 ether, // Level 1
        0.07 ether, // Level 2
        0.1 ether, // Level 3
        0.14 ether, // Level 4
        0.2 ether, // Level 5
        0.28 ether, // Level 6
        0.4 ether, // Level 7
        0.55 ether, // Level 8
        0.8 ether, // Level 9
        1.1 ether, // Level 10
        1.6 ether, // Level 11
        2.2 ether, // Level 12
        3.2 ether, // Level 13
        4.4 ether, // Level 14
        6.5 ether, // Level 15
        8 ether, // Level 16
        10 ether, // Level 17
        12.5 ether, // Level 18
        16 ether, // Level 19
        20 ether // Level 20
    ];

    uint256 totalLevels = levelPrice.length;

    // State variables
    mapping(address => User) users;
    mapping(uint256 => address) usersAddressById;
    mapping(uint8 => address[]) levelQueue;
    mapping(uint8 => uint256) headIndex;
    GlobalStat globalStat;

    constructor(address payable _tokenBurner) {
        owner = payable(msg.sender);
        tokenBurner = _tokenBurner;

        // Register owner
        users[owner].id = 1;
        users[owner].registrationTimestamp = block.timestamp;
        users[owner].referrer = address(0);
        usersAddressById[1] = owner;
        globalStat.members++;
        globalStat.transactions++;

        for (uint8 level = 1; level <= totalLevels; level++) {
            users[owner].levels[level].active = true;
            levelQueue[level].push(owner);
        }
    }

    receive() external payable {
        if (!isUserRegistered(msg.sender)) {
            register();
            return;
        }

        for (uint8 level = 1; level <= totalLevels; level++) {
            if (levelPrice[level] == msg.value) {
                buyLevel(level);
                return;
            }
        }
        revert("Can't find level to buy. Maybe sent value is invalid.");
    }

    function transferPayout(uint8 level) public payable {
        require(isUserRegistered(msg.sender), "Please, register");
        require(
            block.timestamp >=
                users[msg.sender].levels[level].buyLevelTime + 1 minutes,
            "24 hours did not expire yet"
        ); // для тестов минута, так надо день ждать
        require(
            users[msg.sender].levels[level].active,
            "You have not bought this level"
        );

        uint256 timeForRentPayout = users[msg.sender]
            .levels[level]
            .buyLevelTime;
        uint256 onePercent = levelPrice[level] / 100;
        uint256 reward = onePercent * 74; // REWARD_PERCENTS

        for (uint16 i = 0; i < REWARDPAYOUTS; i++) {
            if (
                users[msg.sender].levels[level].levelRents[i].rentLevelState ==
                RentLevelState.GRANTED
            ) {
                timeForRentPayout = users[msg.sender]
                    .levels[level]
                    .levelRents[i]
                    .timeStampReceived;
                continue;
            }

            require(
                users[msg.sender].levels[level].levelRents[i].rentLevelState ==
                    RentLevelState.PENDING,
                "Not granted"
            ); //тот кто может получить награду
            require(
                block.timestamp >= timeForRentPayout + 1 minutes,
                "1 minute did not expire yet"
            ); // для тестов минута, так надо день ждать

            bool sent = payable(msg.sender).send(reward); // от себя отправляем деньги
            if (sent) {
                // Update head user statistic
                users[msg.sender]
                    .levels[level]
                    .levelRents[i]
                    .timeStampReceived = block.timestamp;
                users[msg.sender]
                    .levels[level]
                    .levelRents[i]
                    .rentLevelState = RentLevelState.GRANTED;
                users[msg.sender].levels[level].rewardSum += reward;
                users[msg.sender].levels[level].payouts++;
                emit LevelPayout(
                    users[msg.sender].id,
                    level,
                    reward,
                    users[msg.sender].id
                );
            } else {
                // Only if rewardAddress is smart contract (not a common case)
                owner.transfer(reward);
            }
            break;
        }
    }

    function register() public payable {
        registerWithReferrer(owner);
    }

    function registerWithReferrer(address referrer) public payable {
        require(msg.value == 0.025 ether, "Invalid value sent");
        // require(isUserRegistered(referrer), "Referrer is not registered");
        require(!isUserRegistered(msg.sender), "User already registered");
        require(!isContract(msg.sender), "Can not be a contract");

        globalStat.members++;
        users[msg.sender].id = globalStat.members;
        users[msg.sender].registrationTimestamp = block.timestamp;
        users[msg.sender].referrer = referrer;
        usersAddressById[users[msg.sender].id] = msg.sender;

        uint8 line = 1;
        address ref = referrer;
        while (line <= rewardableLines && ref != address(0)) {
            users[ref].referrals++;
            ref = users[ref].referrer;
            line++;
        }

        (bool success, ) = tokenBurner.call{value: msg.value}("");
        require(success, "token burn failed while registration");

        globalStat.transactions++;
        emit UserRegistration(users[msg.sender].id, users[referrer].id);
    }

    function check_levels(address sender, uint256 level) private view {
        //проверяем все этажи до вызываемого, активны ли они. если нет то выдаем ошибк
        for (uint8 l = 1; l < level; l++) {
            require(
                users[sender].levels[l].active,
                "All previous levels must be active"
            );
        }
    }

    function set_status(address sender, uint8 level) private {
        for (uint16 j = 0; j < 3; j++) {
            users[sender]
                .levels[level]
                .levelRents[j]
                .rentLevelState = RentLevelState.NOT_GRANTED; //всем 3м выплатам этажа присвоить статус not granted
        }
    }

    function move_queue(uint8 level) private {
        for (uint256 s = 0; s < levelQueue[level].length - 1; s++) {
            address temp = levelQueue[level][s];
            levelQueue[level][s] = levelQueue[level][s + 1];
            levelQueue[level][s + 1] = temp;
        }
    }

    function buyLevel(uint8 level) public payable nonReentrant returns (bool) {
        require(isUserRegistered(msg.sender), "User is not registered");
        require(level > 0 && level <= totalLevels, "Invalid level");
        require(levelPrice[level] == msg.value, "Invalid BNB value");
        require(!isContract(msg.sender), "Can not be a contract");
        check_levels(msg.sender, level);

        // Update global stat
        globalStat.transactions++; //в глобальном стейте у нас members, transactions, turnover
        globalStat.turnover += msg.value; //увеличиваем показатель оборота в глобальном стейте на сумму покупки

        // If sender level is not active
        if (!users[msg.sender].levels[level].active) {
            // Activate level
            users[msg.sender].levels[level].active = true; //активируем этаж
            users[msg.sender].levels[level].buyLevelTime = block.timestamp; //присваиваем время покупки
            set_status(msg.sender, level);
            // Add user to level queue
            levelQueue[level].push(msg.sender); //добавить покупателя в очередь этажа
            emit BuyLevel(users[msg.sender].id, level);
        } else {
            revert("Level is already bought");
        }

        address firstUserInQueue = levelQueue[level][0];

        // Increase user level maxPayouts
        if (firstUserInQueue != owner) {
            users[firstUserInQueue]
                .levels[level]
                .levelRents[
                    users[firstUserInQueue].levels[level].activationTimes
                ]
                .rentLevelState = RentLevelState.PENDING; // !! этаж активен, переводим статус выплаты в ожидание
            users[firstUserInQueue].levels[level].activationTimes++; // увеличиваем количество активаций на 1

            if (
                users[firstUserInQueue].levels[level].activationTimes ==
                REWARDPAYOUTS
            ) {
                users[firstUserInQueue].levels[level].active = false;
                users[firstUserInQueue].levels[level].activationTimes = 0;

                set_status(firstUserInQueue, level);
                emit LevelDeactivation(users[firstUserInQueue].id, level);
            }
        }
        move_queue(level);
        // If head user is not sender (user can't get a reward from himself)
        // Send referral payouts
        uint256 onePercent = levelPrice[level] / 100;

        for (uint8 line = 1; line <= rewardableLines; line++) {
            uint256 rewardValue = onePercent * referralRewardPercents[line];
            sendRewardToReferrer(msg.sender, line, level, rewardValue);
        }
        // // Buy and burn tokens
        (bool success, ) = tokenBurner.call{value: onePercent * 2}(""); // TOKEN_BURNER_PERCENTS
        require(success, "token burn failed to buy level");
        return true;
    }

    function getLevelsTime() public view returns (uint256[] memory, uint256) {
        uint256[] memory timestamps = new uint256[](totalLevels + 1);
        for (uint8 level = 0; level <= totalLevels; level++) {
            timestamps[level] = users[msg.sender].levels[level].buyLevelTime;
            for (uint8 rent = 0; rent <= 2; rent++) {
                if (
                    users[msg.sender]
                        .levels[level]
                        .levelRents[rent]
                        .rentLevelState == RentLevelState.GRANTED
                ) {
                    timestamps[level] = users[msg.sender]
                        .levels[level]
                        .levelRents[rent]
                        .timeStampReceived;
                }
            }
        }
        return (timestamps, block.timestamp);
    }

    function find_referrer(address userAddress, uint256 line)
        public
        view
        returns (address refer)
    {
        uint256 curLine = 1;
        address referrer = users[userAddress].referrer;
        while (curLine != line && referrer != owner) {
            referrer = users[referrer].referrer;
            curLine++;
        }
        return refer;
    }

    function sendRewardToReferrer(
        address userAddress,
        uint256 line,
        uint8 level,
        uint256 rewardValue
    ) private {
        require(line > 0, "Line must be greater than zero");

        address referrer = find_referrer(userAddress, line);
        bool sent = payable(referrer).send(rewardValue);

        if (sent) {
            users[referrer].levels[level].referralPayoutSum += rewardValue;
            emit ReferralPayout(
                users[referrer].id,
                users[userAddress].id,
                level,
                rewardValue
            );
        } else {
            owner.transfer(rewardValue);
        }
    }

    // In case if we would like to migrate to Pancake Router V3
    function setTokenBurner(address payable _tokenBurner) internal onlyOwner {
        tokenBurner = _tokenBurner;
    }

    function getUserAndRewardInfo()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 levelsReward;
        uint256 referrersReward;
        for (uint8 level = 1; level <= totalLevels; level++) {
            levelsReward += users[msg.sender].levels[level].rewardSum;
            referrersReward += users[msg.sender]
                .levels[level]
                .referralPayoutSum;
        }

        return (
            users[msg.sender].id,
            users[msg.sender].registrationTimestamp,
            users[users[msg.sender].referrer].id,
            users[msg.sender].referrer,
            users[msg.sender].referrals,
            levelsReward,
            referrersReward
        );
    }

    function getUserLevelsInfo()
        public
        view
        returns (
            bool[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        bool[] memory activations = new bool[](totalLevels + 1);
        uint256[] memory activationTimes = new uint256[](totalLevels + 1);

        for (uint8 level = 1; level <= totalLevels; level++) {
            activations[level] = users[msg.sender].levels[level].active;
            activationTimes[level] = users[msg.sender]
                .levels[level]
                .activationTimes;
        }
        return (activations, activationTimes, levelPrice);
    }

    function getGlobalStatistic()
        public
        view
        returns (uint256[3] memory result)
    {
        return [
            globalStat.members,
            globalStat.transactions,
            globalStat.turnover
        ];
    }

    function getBalanceOf(address user) public view returns (uint256) {
        return user.balance;
    }

    function collectFunds(uint256 amount)
        public
        payable
        onlyOwner
        returns (bool)
    {
        bool result = payable(msg.sender).send(amount);
        return result;
    }

    function isUserRegistered(address addr) public view returns (bool) {
        return users[addr].id != 0;
    }

    function getUserAddressById(uint256 userId) public view returns (address) {
        return usersAddressById[userId];
    }

    function getUserIdByAddress(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].id;
    }

    function getReferrerId(address userAddress) public view returns (uint256) {
        address referrerAddress = users[userAddress].referrer;
        return users[referrerAddress].id;
    }

    function getReferrer(address userAddress) public view returns (address) {
        require(isUserRegistered(userAddress), "User is not registered");
        return users[userAddress].referrer;
    }

    function getQueueOrder(uint8 level) public view returns (uint256[] memory) {
        uint256[] memory usersIds = new uint256[](levelQueue[level].length);
        for (uint256 i = 0; i < levelQueue[level].length; i++) {
            usersIds[i] = users[levelQueue[level][i]].id;
        }
        return usersIds;
    }

    function isContract(address addr) public view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return size != 0;
    }
}