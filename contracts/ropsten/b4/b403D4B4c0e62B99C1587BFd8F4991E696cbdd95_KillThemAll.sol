// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// TODO: remove that before deployment
// import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/Timers.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./utils/Coordinate.sol";

// TODO: add user badges and rewards (backend)
// TODO: add most travelling user as weekly reward (maybe)
// TODO: add most killing user as weekly reward (maybe)
// TODO: add items to diversity, (decrease mana consumption, add attack, add resistance etc.)
// NOTE: town and item as a nft (maybe)
// TODO: add town war
// TODO: add town pool
// TODO: add user energy (movement)
// TODO: add delay to user movement (like scheduled) and cancel this movement
// NOTE: roles in town (major, leader etc.) (maybe)
// NOTE: burn or withdraw the tokens (maybe should relate with its own percentages)
// NOTE: add arrive time to move (maybe)
// TODO: setter to (onlyLeader) clan recruitment, price, mode, status etc
// TODO: settleTimer, voyageTimer etc.
/**
 * @title Kill Them All
 * @author Emre Tepe (@emretepedev)
 * @custom:security-contact [email protected]
 */
contract KillThemAll is Ownable {
    // libraries
    using Timers for Timers.Timestamp;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using Coordinates for Coordinates.Coordinate;

    // enums
    enum TownStatus {
        NULL,
        VOYAGE,
        SETTLE,
        ABANDON
    }

    enum TownMode {
        NORMAL,
        OFFENSIVE,
        DEFENSIVE
    }

    enum UserStatus {
        NULL,
        ALIVE,
        DEAD
    }

    enum Direction {
        UP,
        RIGHT,
        DOWN,
        LEFT
    }

    // structs
    struct Setting {
        PriceSetting price;
        TimeSetting time;
        ManaSetting mana;
        RateSetting rate;
        MinSetting min;
        MaxSetting max;
        ExpSetting exp;
        MultiplierSetting multiplier;
    }

    struct PrivateSetting {
        uint256 numberDigits;
    }

    struct PriceSetting {
        uint256 revive;
        uint256 register;
        uint256 health;
        uint256 mana;
        uint256 armor;
        uint256 teleport;
        uint256 createTown;
        uint256 settleTown;
        uint256 teleportToTown;
    }

    struct TimeSetting {
        uint256 revive;
        uint256 getMana;
        uint256 teleport;
        uint256 teleportToTown;
    }

    struct ManaSetting {
        uint256 attack;
        uint256 movement;
    }

    struct RateSetting {
        uint256 registerReferralReward;
        uint256 getMana;
        uint256 armorAbsorption;
    }

    struct MinSetting {
        uint256 userName;
        uint256 townName;
        uint256 createTownLevel;
        uint256 townAreaRadius;
    }

    struct MaxSetting {
        uint256 userName;
        uint256 townName;
        uint256 teleportDistance;
        uint256 health;
        uint256 mana;
        uint256 armor;
        uint256 safeTownDistance;
    }

    struct MultiplierSetting {
        uint256 attack;
        uint256 resistance;
    }

    struct ExpSetting {
        uint256 kill;
        uint256 referrerKill;
    }

    struct Town {
        Coordinates.Coordinate coordinate;
        string name;
        address leader;
        address[] citizens;
        uint256 exp;
        uint256 levelId;
        uint256 price;
        bool recruitment;
        TownStatus status;
        TownMode mode;
    }

    struct User {
        Coordinates.Coordinate coordinate;
        string name;
        uint256 health;
        uint256 mana;
        uint256 armor;
        uint256 exp;
        uint256 levelId;
        uint256 townId;
        uint256 citizenshipId;
        address referrer;
        UserStatus status;
        UserTimer timer;
    }

    struct UserTimer {
        Timers.Timestamp getMana;
        Timers.Timestamp revive;
        Timers.Timestamp teleport;
        Timers.Timestamp teleportToTown;
    }

    struct UserLevel {
        uint256 min;
        uint256 max;
    }

    struct TownLevel {
        uint256 maxUser;
    }

    // mappings
    mapping(address => User) public userByAddress;
    mapping(uint256 => Town) public townById;
    mapping(int256 => mapping(int256 => bool)) public coordinateTownExistence;

    // constants
    // solhint-disable var-name-mixedcase
    IERC20 private immutable KTA_TOKEN;
    // solhint-enable var-name-mixedcase

    // variables
    Setting public settings;
    UserLevel[] public userLevels;
    TownLevel[] public townLevels;

    PrivateSetting private _settings;
    uint256 private _nonce;

    Counters.Counter internal _townId;

    // events
    event UserAttacked(
        address defender,
        uint256 healthDamage,
        uint256 armorDamage
    );
    event UserMissed(
        address defender,
        uint256 attackPower,
        uint256 resistancePower
    );
    event UserRegistered();
    event TownCreated();
    event TownSettled();
    event UserJoinedTown();
    event UserKilled(address user);
    event UserArmorBroken(address owner);
    event LevelUp();
    event ReferrerLevelUp(address referrer);

    // errors
    error NameMustOnlyAlphaChars(string invalidChar);
    error UserCanNotGetManaYet(uint256 remainingTime);
    error UserCanNotTeleportYet(uint256 remainingTime);
    error UserCanNotTeleportToTownYet(uint256 remainingTime);
    error UserCanNotReviveYet(uint256 remainingTime);
    error UserMustRegistered();
    error UserMustAlive();
    error UserHasNotEnoughMana();
    error InvalidNameLength(uint256 min, uint256 max);
    error TooMuchDistance(uint256 current, uint256 max);
    error TooMuchHealth();
    error TooMuchMana();
    error TooMuchArmor();
    error InsufficientLevel();

    // modifiers
    modifier onlyRegisteredUser() {
        // slither-disable-next-line incorrect-equality
        if (UserStatus.NULL == userByAddress[msg.sender].status)
            revert UserMustRegistered();
        _;
    }

    modifier onlyAliveUser() {
        if (UserStatus.ALIVE != userByAddress[msg.sender].status)
            revert UserMustAlive();
        _;
    }

    modifier onlyUserHasEnoughMana(uint256 amount) {
        if (amount > userByAddress[msg.sender].mana)
            revert UserHasNotEnoughMana();
        _;
    }

    constructor(
        address tokenAddressKTA,
        uint256[] memory settings_,
        uint256[] memory _settings_,
        uint256[] memory userLevelLimits,
        uint256[] memory townLevelLimits
    ) {
        townLevels.push(new TownLevel[](1)[0]);
        userLevels.push(new UserLevel[](1)[0]);

        KTA_TOKEN = IERC20(tokenAddressKTA);

        updateSettings(settings_);
        updatePrivateSettings(_settings_);

        for (uint256 i = 0; i < userLevelLimits.length - 1; i++) {
            createUserLevel(userLevelLimits[i], userLevelLimits[i + 1]);
        }

        for (uint256 i = 0; i < townLevelLimits.length - 1; i++) {
            createTownLevel(townLevelLimits[i]);
        }
    }

    function register(string calldata name, address referrer) external {
        // NOTE: remove to reduce bytecode ~.300
        uint256 len = bytes(name).length;
        if (len < settings.min.userName || len > settings.max.userName)
            revert InvalidNameLength({
                min: settings.min.userName,
                max: settings.max.userName
            });

        bytes memory name_ = bytes(name);
        for (uint256 i = 0; i < len; i++) {
            bytes1 char = name_[i];

            if (
                !(char >= 0x61 && char <= 0x7A) && // a-z
                !(char >= 0x41 && char <= 0x5A) // A-Z
            ) {
                bytes memory char_;
                char_[0] = char;
                revert NameMustOnlyAlphaChars({ invalidChar: string(char_) });
            }
        }

        // slither-disable-next-line incorrect-equality
        require(
            UserStatus.NULL == userByAddress[msg.sender].status,
            "User already exists"
        );

        uint256 refRegisterReward = 0;
        if (address(0) != referrer) {
            require(
                UserStatus.NULL != userByAddress[referrer].status,
                "Referral User must be registered"
            );

            refRegisterReward =
                settings.price.register /
                settings.rate.registerReferralReward;

            // slither-disable-next-line reentrancy-no-eth
            KTA_TOKEN.safeTransferFrom(msg.sender, referrer, refRegisterReward);
        }

        User storage user = userByAddress[msg.sender];
        user.name = name;
        user.health = settings.max.health;
        user.mana = settings.max.mana;
        user.levelId = 1;
        user.referrer = referrer;
        user.status = UserStatus.ALIVE;
        // solhint-disable not-rely-on-time
        user.timer.getMana = Timers.Timestamp({
            _deadline: uint64(block.timestamp)
        });
        user.timer.teleport = Timers.Timestamp({
            _deadline: uint64(block.timestamp)
        });
        user.timer.teleportToTown = Timers.Timestamp({
            _deadline: uint64(block.timestamp)
        });
        // solhint-enable not-rely-on-time

        emit UserRegistered();

        KTA_TOKEN.safeTransferFrom(
            msg.sender,
            address(this),
            settings.price.register - refRegisterReward
        );
    }

    // TODO: attack target town
    function createTown(string calldata name, uint256 price)
        external
        onlyRegisteredUser
    {
        // NOTE: remove to reduce bytecode ~.300
        uint256 len = bytes(name).length;
        if (len < settings.min.townName || len > settings.max.townName)
            revert InvalidNameLength({
                min: settings.min.townName,
                max: settings.max.townName
            });

        bytes memory name_ = bytes(name);
        for (uint256 i = 0; i < len; i++) {
            bytes1 char = name_[i];

            if (
                !(char >= 0x61 && char <= 0x7A) && // a-z
                !(char >= 0x41 && char <= 0x5A) // A-Z
            ) {
                bytes memory char_;
                char_[0] = char;
                revert NameMustOnlyAlphaChars({ invalidChar: string(char_) });
            }
        }

        User storage leader = userByAddress[msg.sender];

        require(0 == leader.townId, "User already has town");

        if (leader.levelId < settings.min.createTownLevel)
            revert InsufficientLevel();

        _townId.increment();
        leader.townId = _townId.current();

        Town storage town = townById[_townId.current()];
        town.name = name;
        town.leader = msg.sender;
        town.levelId = 1;
        town.status = TownStatus.VOYAGE;
        town.price = price;
        town.citizens.push(msg.sender);

        emit TownCreated();

        KTA_TOKEN.safeTransferFrom(
            msg.sender,
            address(this),
            settings.price.createTown
        );
    }

    function settleTown() external onlyRegisteredUser onlyAliveUser {
        User memory leader = userByAddress[msg.sender]; // NOTE: remove to reduce bytecode ~.350
        Town storage town = townById[leader.townId];

        require(TownStatus.NULL != town.status, "Town must be exists");
        require(TownStatus.VOYAGE == town.status, "Town status must be voyage");
        require(town.leader == msg.sender, "Only leaders can settle the town");

        int256 minScanX = userByAddress[msg.sender].coordinate.currentX() -
            int256(settings.min.townAreaRadius);
        int256 maxScanX = userByAddress[msg.sender].coordinate.currentX() +
            int256(settings.min.townAreaRadius);
        int256 minScanY = userByAddress[msg.sender].coordinate.currentY() -
            int256(settings.min.townAreaRadius);
        int256 maxScanY = userByAddress[msg.sender].coordinate.currentY() +
            int256(settings.min.townAreaRadius);

        for (int256 i = minScanX; i <= maxScanX; i++) {
            for (int256 j = minScanY; j <= maxScanY; j++) {
                require(
                    !coordinateTownExistence[i][j],
                    "There is already a town nearby"
                );
            }
        }

        coordinateTownExistence[
            userByAddress[msg.sender].coordinate.currentX()
        ][userByAddress[msg.sender].coordinate.currentY()] = true;
        town.coordinate.set(leader.coordinate);
        town.status = TownStatus.SETTLE;

        emit TownSettled();

        KTA_TOKEN.safeTransferFrom(
            msg.sender,
            address(this),
            settings.price.settleTown
        );
    }

    function joinTown(uint256 townId)
        external
        onlyRegisteredUser
        onlyAliveUser
    {
        Town storage town = townById[townId];
        require(TownStatus.NULL != town.status, "Town must be exists");
        require(
            TownStatus.SETTLE == town.status,
            "Town status must be settled"
        );
        require(town.recruitment, "Town recruitment must be open");
        require(
            town.citizens.length < townLevels[town.levelId].maxUser,
            "Town's maximum limit reached"
        );

        User storage user = userByAddress[msg.sender];
        require(0 == user.townId, "User already has a town");

        user.townId = townId;
        user.citizenshipId = town.citizens.length;
        town.citizens.push(msg.sender);

        emit UserJoinedTown();

        KTA_TOKEN.safeTransferFrom(msg.sender, address(this), town.price);
    }

    function leaveTown() external onlyRegisteredUser {
        User storage user = userByAddress[msg.sender];
        Town storage town = townById[user.townId];

        require(TownStatus.NULL != town.status, "Town must be exists");
        require(town.leader != msg.sender, "Leaders cannot leave the town");

        userByAddress[town.citizens[town.citizens.length - 1]]
            .citizenshipId = user.citizenshipId;
        town.citizens[user.citizenshipId] = town.citizens[
            town.citizens.length - 1
        ];
        town.citizens.pop();
        user.townId = 0;
        user.citizenshipId = 0;
    }

    function exileCitizen(address citizen_) external onlyRegisteredUser {
        User memory leader = userByAddress[msg.sender]; // NOTE: remove to reduce bytecode ~.400
        Town storage town = townById[leader.townId];

        require(TownStatus.NULL != town.status, "Town must be exists");
        require(town.leader == msg.sender, "Only leaders can settle the town");

        User storage citizen = userByAddress[citizen_];
        require(
            UserStatus.NULL != citizen.status,
            "Citizen must be registered"
        );
        require(
            leader.townId == citizen.townId,
            "Citizen does not belong to town"
        );

        userByAddress[town.citizens[town.citizens.length - 1]]
            .citizenshipId = citizen.citizenshipId;
        town.citizens[citizen.citizenshipId] = town.citizens[
            town.citizens.length - 1
        ];
        town.citizens.pop();
        citizen.townId = 0;
        citizen.citizenshipId = 0;
    }

    function attack(address target)
        external
        onlyRegisteredUser
        onlyAliveUser
        onlyUserHasEnoughMana(settings.mana.attack)
    {
        require(msg.sender != target, "Users cannot attack yourself");

        User storage targetUser = userByAddress[target];
        require(
            UserStatus.NULL != targetUser.status,
            "Target User must be registered"
        );
        require(
            UserStatus.ALIVE == targetUser.status,
            "Target User must be alive"
        );

        if (
            0 != targetUser.townId &&
            TownStatus.SETTLE == townById[targetUser.townId].status
        ) {
            require(
                townById[targetUser.townId].coordinate.getDistance(
                    targetUser.coordinate
                ) <= settings.max.safeTownDistance,
                "Target is very close to own town"
            );
        }

        User storage user = userByAddress[msg.sender];
        require(
            5 >= abs(int256(user.levelId) - int256(targetUser.levelId)),
            "Level diff must equal or less 5"
        );

        uint256 distance = user.coordinate.getDistance(targetUser.coordinate);
        require(distance <= 1, "Target is too far");

        uint256 attackPower = settings.multiplier.attack *
            user.levelId +
            (distance == 0 ? getRandomDigit() : 0);
        uint256 resistancePower = settings.multiplier.resistance *
            targetUser.levelId;

        user.mana -= settings.mana.attack;

        if (resistancePower > attackPower) {
            emit UserMissed({
                defender: target,
                attackPower: attackPower,
                resistancePower: resistancePower
            });

            return;
        }

        uint256 damage = attackPower - resistancePower;
        uint256 healthDamage = damage;
        uint256 armorDamage = 0;

        if (0 != targetUser.armor) {
            armorDamage = healthDamage / settings.rate.armorAbsorption;
            healthDamage -= armorDamage;

            if (armorDamage > targetUser.armor) {
                armorDamage -= targetUser.armor;
                healthDamage += armorDamage;
                targetUser.armor = 0;

                emit UserArmorBroken({ owner: target });
            } else {
                targetUser.armor -= armorDamage;
            }
        }

        targetUser.health = healthDamage > targetUser.health
            ? 0
            : targetUser.health -= healthDamage;

        emit UserAttacked({
            defender: target,
            healthDamage: healthDamage,
            armorDamage: armorDamage
        });

        // TODO: add armor to attacker for kill reward
        if (0 == targetUser.health) {
            targetUser.armor = 0;
            targetUser.status = UserStatus.DEAD;

            if (
                0 != targetUser.townId &&
                TownStatus.SETTLE == townById[targetUser.townId].status
            ) {
                targetUser.coordinate.set(
                    townById[targetUser.townId].coordinate
                );
            }

            user.exp += settings.exp.kill * user.levelId;
            uint256 maxUserLevelId = userLevels.length - 1;
            UserLevel memory maxUserLevel = userLevels[maxUserLevelId];

            if (user.exp > maxUserLevel.max) user.exp = maxUserLevel.max;

            while (userLevels[user.levelId].max <= user.exp) {
                if (maxUserLevelId == user.levelId) break;

                user.levelId++;

                emit LevelUp();
            }

            if (address(0) != user.referrer && 0 != settings.exp.referrerKill) {
                User storage referrer = userByAddress[user.referrer];
                referrer.exp += settings.exp.referrerKill * referrer.levelId;

                if (referrer.exp > maxUserLevel.max)
                    referrer.exp = maxUserLevel.max;

                while (userLevels[referrer.levelId].max <= referrer.exp) {
                    if (maxUserLevelId == referrer.levelId) break;

                    referrer.levelId++;

                    emit ReferrerLevelUp(user.referrer);
                }
            }

            targetUser.timer.revive.setDeadline(
                // solhint-disable-next-line not-rely-on-time
                uint64(block.timestamp + settings.time.revive)
            );

            emit UserKilled({ user: target });
        }
    }

    function move(Direction direction)
        external
        onlyRegisteredUser
        onlyAliveUser
        onlyUserHasEnoughMana(settings.mana.movement)
    {
        User storage user = userByAddress[msg.sender];
        user.mana -= settings.mana.movement;

        if (Direction.UP == direction) user.coordinate.moveUp();
        else if (Direction.RIGHT == direction) user.coordinate.moveRight();
        else if (Direction.DOWN == direction) user.coordinate.moveDown();
        else if (Direction.LEFT == direction) user.coordinate.moveLeft();
    }

    function teleport(int256 x, int256 y)
        external
        onlyRegisteredUser
        onlyAliveUser
    {
        User storage user = userByAddress[msg.sender];

        if (!user.timer.teleport.isExpired()) {
            // solhint-disable not-rely-on-time
            revert UserCanNotTeleportYet({
                remainingTime: user.timer.teleport.getDeadline() -
                    block.timestamp
            });
            // solhint-enable not-rely-on-time
        }

        uint256 distance = user.coordinate.getDistance(x, y);

        require(0 != distance, "User already here");

        if (settings.max.teleportDistance < distance) {
            revert TooMuchDistance({
                current: distance,
                max: settings.max.teleportDistance
            });
        }

        user.mana -= settings.mana.movement * distance;

        user.coordinate.set(x, y);

        user.timer.teleport.setDeadline(
            // solhint-disable-next-line not-rely-on-time
            uint64(block.timestamp + settings.time.teleport)
        );

        KTA_TOKEN.safeTransferFrom(
            msg.sender,
            address(this),
            settings.price.teleport * distance
        );
    }

    function teleportToTown() external onlyRegisteredUser onlyAliveUser {
        User storage user = userByAddress[msg.sender];

        require(0 != user.townId, "User must join a town");

        if (!user.timer.teleportToTown.isExpired()) {
            // solhint-disable not-rely-on-time
            revert UserCanNotTeleportToTownYet({
                remainingTime: user.timer.teleportToTown.getDeadline() -
                    block.timestamp
            });
            // solhint-enable not-rely-on-time
        }

        Town memory town = townById[user.townId];
        require(TownStatus.SETTLE == town.status, "Town status must be settle");

        user.coordinate.set(town.coordinate);

        user.timer.teleport.setDeadline(
            // solhint-disable-next-line not-rely-on-time
            uint64(block.timestamp + settings.time.teleportToTown)
        );

        KTA_TOKEN.safeTransferFrom(
            msg.sender,
            address(this),
            settings.price.teleportToTown
        );
    }

    function revive() external onlyRegisteredUser {
        User storage user = userByAddress[msg.sender];
        require(UserStatus.DEAD == user.status, "User must be dead");
        require(!user.timer.revive.isUnset(), "Timer must be set");

        if (!user.timer.revive.isExpired()) {
            // solhint-disable not-rely-on-time
            revert UserCanNotReviveYet({
                remainingTime: user.timer.revive.getDeadline() - block.timestamp
            });
            // solhint-enable not-rely-on-time
        }

        user.health = settings.max.health;
        user.status = UserStatus.ALIVE;
        user.timer.revive.reset();

        KTA_TOKEN.safeTransferFrom(
            msg.sender,
            address(this),
            settings.price.revive
        );
    }

    function getMana() external onlyRegisteredUser onlyAliveUser {
        User storage user = userByAddress[msg.sender];

        if (!user.timer.getMana.isExpired()) {
            // solhint-disable not-rely-on-time
            revert UserCanNotGetManaYet({
                remainingTime: user.timer.getMana.getDeadline() -
                    block.timestamp
            });
            // solhint-enable not-rely-on-time
        }

        // solhint-disable-next-line not-rely-on-time
        uint256 amount = (block.timestamp +
            settings.time.getMana -
            user.timer.getMana.getDeadline()) / settings.rate.getMana;

        require(0 != amount, "Mana not ready yet");

        user.mana += amount;

        // NOTE: avoid mana missing (maybe)
        // user.timer.getMana = block.timestamp + settings.time.getMana + remainingAmount * settings.rate.getMana
        if (settings.max.mana < user.mana) {
            user.mana = settings.max.mana;
        }

        user.timer.getMana.setDeadline(
            // solhint-disable-next-line not-rely-on-time
            uint64(block.timestamp + settings.time.getMana)
        );
    }

    function buyHealth(uint256 amount)
        external
        onlyRegisteredUser
        onlyAliveUser
    {
        User storage user = userByAddress[msg.sender];
        if (settings.max.health < user.health + amount) revert TooMuchHealth();

        user.health += amount;

        KTA_TOKEN.safeTransferFrom(
            msg.sender,
            address(this),
            settings.price.health * amount
        );
    }

    function buyMana(uint256 amount) external onlyRegisteredUser onlyAliveUser {
        User storage user = userByAddress[msg.sender];
        if (settings.max.mana < user.mana + amount) revert TooMuchMana();

        user.mana += amount;

        KTA_TOKEN.safeTransferFrom(
            msg.sender,
            address(this),
            settings.price.mana * amount
        );
    }

    function buyArmor(uint256 amount)
        external
        onlyRegisteredUser
        onlyAliveUser
    {
        User storage user = userByAddress[msg.sender];
        if (settings.max.armor < user.armor + amount) revert TooMuchArmor();

        user.armor += amount;

        KTA_TOKEN.safeTransferFrom(
            msg.sender,
            address(this),
            settings.price.armor * amount
        );
    }

    function checkAttackChance(address target)
        external
        view
        onlyRegisteredUser
        returns (uint256)
    {
        User storage targetUser = userByAddress[target];
        require(
            UserStatus.NULL != targetUser.status,
            "Target User must be registered"
        );

        User storage user = userByAddress[msg.sender];

        uint256 attackPower = settings.multiplier.attack * user.levelId;
        uint256 resistancePower = settings.multiplier.resistance *
            targetUser.levelId;

        if (attackPower > resistancePower) return 100;
        if (user.coordinate.getDistance(targetUser.coordinate) != 0) return 0;

        uint256 maxRandomNumber = 10**_settings.numberDigits - 1;

        return
            (100 * ((maxRandomNumber + attackPower) - resistancePower)) /
            (maxRandomNumber + 1);
    }

    function createUserLevel(uint256 min, uint256 max) public onlyOwner {
        require(min < max, "Min must be less than Max value");

        uint256 len = userLevels.length;

        require(
            userLevels[len - 1].max == min,
            "Min must be equal to max of last"
        );

        userLevels.push(UserLevel({ min: min, max: max }));
    }

    function createTownLevel(uint256 maxUser) public onlyOwner {
        uint256 len = townLevels.length;

        require(
            townLevels[len - 1].maxUser < maxUser,
            "Max must greater than last max"
        );

        townLevels.push(TownLevel({ maxUser: maxUser }));
    }

    function updateSettings(uint256[] memory settings_) public onlyOwner {
        uint256 i = 0;

        settings = Setting({
            price: PriceSetting({
                revive: settings_[i++],
                register: settings_[i++],
                health: settings_[i++],
                mana: settings_[i++],
                armor: settings_[i++],
                teleport: settings_[i++],
                createTown: settings_[i++],
                settleTown: settings_[i++],
                teleportToTown: settings_[i++]
            }),
            time: TimeSetting({
                revive: settings_[i++],
                getMana: settings_[i++],
                teleport: settings_[i++],
                teleportToTown: settings_[i++]
            }),
            mana: ManaSetting({
                attack: settings_[i++],
                movement: settings_[i++]
            }),
            rate: RateSetting({
                registerReferralReward: settings_[i++],
                getMana: settings_[i++],
                armorAbsorption: settings_[i++]
            }),
            min: MinSetting({
                userName: settings_[i++],
                townName: settings_[i++],
                createTownLevel: settings_[i++],
                townAreaRadius: settings_[i++]
            }),
            max: MaxSetting({
                userName: settings_[i++],
                townName: settings_[i++],
                teleportDistance: settings_[i++],
                health: settings_[i++],
                mana: settings_[i++],
                armor: settings_[i++],
                safeTownDistance: settings_[i++]
            }),
            exp: ExpSetting({
                kill: settings_[i++],
                referrerKill: settings_[i++]
            }),
            multiplier: MultiplierSetting({
                attack: settings_[i++],
                resistance: settings_[i++]
            })
        });
    }

    function updatePrivateSettings(uint256[] memory _settings_)
        public
        onlyOwner
    {
        uint256 i = 0;

        _settings = PrivateSetting({ numberDigits: _settings_[i++] });
    }

    function getRandomDigit() internal returns (uint256) {
        unchecked {
            ++_nonce;
        }

        // slither-disable-next-line weak-prng
        return
            mulmod(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            // solhint-disable-next-line not-rely-on-time
                            block.timestamp,
                            block.difficulty,
                            _nonce
                        )
                    )
                ),
                1,
                10**_settings.numberDigits
            );
    }

    function getUserLevels() external view returns (UserLevel[] memory) {
        return userLevels;
    }

    function getTownLevels() external view returns (TownLevel[] memory) {
        return townLevels;
    }

    function abs(int256 x) private pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Timers.sol)

pragma solidity ^0.8.0;

/**
 * @dev Tooling for timepoints, timers and delays
 */
library Timers {
    struct Timestamp {
        uint64 _deadline;
    }

    function getDeadline(Timestamp memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(Timestamp storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(Timestamp storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(Timestamp memory timer) internal view returns (bool) {
        return timer._deadline > block.timestamp;
    }

    function isExpired(Timestamp memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.timestamp;
    }

    struct BlockNumber {
        uint64 _deadline;
    }

    function getDeadline(BlockNumber memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(BlockNumber storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(BlockNumber storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(BlockNumber memory timer) internal view returns (bool) {
        return timer._deadline > block.number;
    }

    function isExpired(BlockNumber memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.number;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Coordinates
 * @author Emre Tepe (@emretepedev)
 * @dev The 2D Cartesian coordinate system management
 *
 * Include with `using Coordinates for Coordinates.Coordinate;`
 *
 */
library Coordinates {
    struct Coordinate {
        int256 _x;
        int256 _y;
    }

    function current(Coordinate storage coordinate)
        internal
        view
        returns (int256, int256)
    {
        return (coordinate._x, coordinate._y);
    }

    function currentX(Coordinate storage coordinate)
        internal
        view
        returns (int256)
    {
        return coordinate._x;
    }

    function currentY(Coordinate storage coordinate)
        internal
        view
        returns (int256)
    {
        return coordinate._y;
    }

    function setX(Coordinate storage coordinate, int256 x) internal {
        coordinate._x = x;
    }

    function setY(Coordinate storage coordinate, int256 y) internal {
        coordinate._y = y;
    }

    function set(
        Coordinate storage coordinate,
        int256 x,
        int256 y
    ) internal {
        coordinate._x = x;
        coordinate._y = y;
    }

    function set(Coordinate storage coordinate, Coordinate memory _coordinate)
        internal
    {
        coordinate._x = _coordinate._x;
        coordinate._y = _coordinate._y;
    }

    function moveUp(Coordinate storage coordinate) internal {
        unchecked {
            ++coordinate._y;
        }
    }

    function moveUpRight(Coordinate storage coordinate) internal {
        unchecked {
            ++coordinate._x;
            ++coordinate._y;
        }
    }

    function moveRight(Coordinate storage coordinate) internal {
        unchecked {
            ++coordinate._x;
        }
    }

    function moveDownRight(Coordinate storage coordinate) internal {
        unchecked {
            ++coordinate._x;
            ++coordinate._y;
        }
    }

    function moveDown(Coordinate storage coordinate) internal {
        unchecked {
            --coordinate._y;
        }
    }

    function moveDownLeft(Coordinate storage coordinate) internal {
        unchecked {
            --coordinate._x;
            --coordinate._y;
        }
    }

    function moveLeft(Coordinate storage coordinate) internal {
        unchecked {
            --coordinate._x;
        }
    }

    function moveUpLeft(Coordinate storage coordinate) internal {
        unchecked {
            --coordinate._x;
            --coordinate._y;
        }
    }

    function reset(Coordinate storage coordinate) internal {
        coordinate._x = 0;
        coordinate._y = 0;
    }

    function getDistance(
        Coordinate storage coordinate,
        int256 x,
        int256 y
    ) internal view returns (uint256) {
        return _sqrt(uint256((coordinate._x - x)**2 + (coordinate._y - y)**2));
    }

    function getDistance(
        Coordinate storage coordinate,
        Coordinate memory _coordinate
    ) internal view returns (uint256) {
        return
            _sqrt(
                uint256(
                    (coordinate._x - _coordinate._x)**2 +
                        (coordinate._y - _coordinate._y)**2
                )
            );
    }

    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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