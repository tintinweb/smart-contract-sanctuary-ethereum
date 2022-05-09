// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// TODO: remove that before deployment
// import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/Timers.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// TODO: add user badges and rewards (in backend)
// TODO: add most travelling user as weekly reward (maybe)
// TODO: add most killing user as weekly reward (maybe)
// TODO: add items to diversity, (decrease mana consumption, add attack, add resistance etc.)
// TODO: add safe zone or town zone (maybe)
// TODO: add town war etc.
// TODO: when dead teleportToTown
// TODO: add town
// TODO: burn or withdraw the tokens (maybe should relate with its own percentages)
// NOTE: add safeMath if it is necessary
contract KillThemAll is Ownable {
    // libraries
    using Timers for Timers.Timestamp;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    // enums
    enum UserStatus {
        ALIVE,
        DEAD
    }

    // structs
    struct Setting {
        PriceSetting price;
        TimeSetting time;
        ManaSetting mana;
        RateSetting rate;
        MinSetting min;
        MaxSetting max;
    }

    struct PrivateSetting {
        MultiplierPrivateSetting multiplier;
        ExpPrivateSetting exp;
        RatePrivateSetting rate;
        MaxPrivateSetting max;
    }

    struct PriceSetting {
        uint256 revive;
        uint256 register;
        uint256 health;
        uint256 mana;
        uint256 armor;
        uint256 teleport;
    }

    struct TimeSetting {
        uint256 revive;
        uint256 getMana;
    }

    struct ManaSetting {
        uint256 attack;
        uint256 movement;
    }

    struct RateSetting {
        uint256 registerReferralReward;
        uint256 getMana;
    }

    struct MinSetting {
        uint256 userName;
    }

    struct MaxSetting {
        uint256 userName;
        uint256 teleportDistance;
    }

    struct MultiplierPrivateSetting {
        uint256 attack;
        uint256 resistance;
    }

    struct ExpPrivateSetting {
        uint256 kill;
    }

    struct RatePrivateSetting {
        uint256 armorAbsorption;
    }

    struct MaxPrivateSetting {
        uint256 numberDigits;
    }

    struct User {
        string name;
        int256 x;
        int256 y;
        uint256 health;
        uint256 mana;
        uint256 armor;
        uint256 exp;
        uint256 level;
        UserStatus status;
        bool isRegistered;
        Timers.Timestamp getManaTimer;
        Timers.Timestamp reviveTimer;
    }

    struct Level {
        uint256 value;
        uint256 min;
        uint256 max;
    }

    // mappings
    mapping(address => User) public userByAddress;
    mapping(uint256 => Level) public levelById;

    // constants
    IERC20 private immutable _tokenKTA;

    // variables
    Setting public settings;
    Counters.Counter public levelId;

    PrivateSetting private _settings;
    uint256 private _nonce;

    // events
    event UserAttacked(
        address defender,
        uint256 healthDamage,
        uint256 armorDamage
    );
    event UserRegistered();
    event UserKilled(address user);
    event UserArmorBroken(address owner);
    event LevelUp();

    // errors
    error NameMustOnlyAlphaChars(string invalidChar);
    error UserCanNotGetManaYet(uint256 remainingTime);
    error UserCanNotReviveYet(uint256 remainingTime);
    error UserMustRegistered();
    error UserMustAlive();
    error UserHasNotEnoughMana();
    error InvalidNameLength(uint256 min, uint256 max);
    error InvalidDirection();

    // modifiers
    modifier onlyRegisteredUser() {
        if (!userByAddress[_msgSender()].isRegistered)
            revert UserMustRegistered();
        _;
    }

    modifier onlyAliveUser() {
        if (UserStatus.ALIVE != userByAddress[_msgSender()].status)
            revert UserMustAlive();
        _;
    }

    modifier onlyHasEnoughMana(uint256 amount) {
        if (amount > userByAddress[_msgSender()].mana)
            revert UserHasNotEnoughMana();
        _;
    }

    constructor(
        address tokenAddressKTA,
        uint256[] memory settings_,
        uint256[] memory _settings_,
        uint16[] memory levelMinLimits,
        uint16[] memory levelMaxLimits
    ) {
        for (uint256 i; i < levelMinLimits.length; i++) {
            addNewLevel(levelMinLimits[i], levelMaxLimits[i]);
        }

        updateSettings(settings_);
        updatePrivateSettings(_settings_);
        _tokenKTA = IERC20(tokenAddressKTA);
    }

    function register(string calldata name, address referrer) external {
        uint256 nameLen = bytes(name).length;
        if (nameLen < settings.min.userName || nameLen > settings.max.userName)
            revert InvalidNameLength({
                min: settings.min.userName,
                max: settings.max.userName
            });

        bytes memory name_ = bytes(name);
        for (uint256 i; i < nameLen; i++) {
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

        require(
            !userByAddress[_msgSender()].isRegistered,
            "User already exists"
        );

        uint256 refRegisterReward;
        if (address(0) != referrer) {
            require(
                userByAddress[referrer].isRegistered,
                "Referral User must be registered"
            );

            refRegisterReward =
                settings.price.register /
                settings.rate.registerReferralReward;

            _tokenKTA.safeTransferFrom(
                _msgSender(),
                referrer,
                refRegisterReward
            );
        }

        _tokenKTA.safeTransferFrom(
            _msgSender(),
            address(this),
            settings.price.register - refRegisterReward
        );

        User memory user;
        user.name = name;
        user.health = 100;
        user.mana = 100;
        user.level = levelById[1].value;
        user.isRegistered = true;
        // solhint-disable not-rely-on-time
        user.getManaTimer = Timers.Timestamp({
            _deadline: uint64(block.timestamp + settings.time.getMana)
        });
        // solhint-enable not-rely-on-time

        userByAddress[_msgSender()] = user;

        emit UserRegistered();
    }

    function attack(address target)
        external
        onlyRegisteredUser
        onlyHasEnoughMana(settings.mana.attack)
        onlyAliveUser
    {
        require(_msgSender() != target, "Users cannot attack yourself");

        User storage targetUser = userByAddress[target];
        require(targetUser.isRegistered, "Target User must be registered");
        require(
            UserStatus.ALIVE == targetUser.status,
            "Target User must be alive"
        );

        User storage user = userByAddress[_msgSender()];
        require(
            5 >= abs(int256(user.level) - int256(targetUser.level)),
            "Level diff must equal or less 5"
        );

        uint256 distance = getDistance(
            user.x,
            user.y,
            targetUser.x,
            targetUser.y
        );
        require(distance <= 1, "Target is too far");

        uint256 attackPower = _settings.multiplier.attack *
            user.level +
            (distance < 1 ? getRandomDigit(_settings.max.numberDigits) : 0);
        uint256 resistancePower = _settings.multiplier.resistance *
            targetUser.level;
        // TODO: add miss chance to check by the user before attack
        // TODO: if attack is miss, decrease attacker mana (risk)
        require(attackPower > resistancePower, "Miss");

        user.mana -= settings.mana.attack;

        uint256 damage = attackPower - resistancePower;
        uint256 healthDamage = damage;
        uint256 armorDamage;

        if (targetUser.armor > 0) {
            armorDamage = healthDamage / _settings.rate.armorAbsorption;
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
            // TODO: also add exp to referrer
            user.exp += _settings.exp.kill;
            Level memory maxLevel = levelById[levelId.current()];

            if (user.exp > maxLevel.max) user.exp = maxLevel.max;

            while (levelById[user.level].max <= user.exp) {
                if (maxLevel.value == levelById[user.level].value) break;

                user.level = levelById[user.level + 1].value;
                emit LevelUp();
            }

            targetUser.reviveTimer.setDeadline(
                // solhint-disable-next-line not-rely-on-time
                uint64(block.timestamp + settings.time.revive)
            );

            emit UserKilled({ user: target });
        }
    }

    function teleport(int256 x, int256 y)
        external
        onlyRegisteredUser
        onlyAliveUser
    {
        User storage user = userByAddress[_msgSender()];
        uint256 distance = getDistance(user.x, user.y, x, y);

        require(
            distance > 0 && distance <= settings.max.teleportDistance,
            "Distance must be in valid range"
        );

        _tokenKTA.safeTransferFrom(
            _msgSender(),
            address(this),
            settings.price.teleport * distance
        );

        user.mana -= settings.mana.movement * distance;
        user.y++;
    }

    function move(string calldata direction)
        external
        onlyRegisteredUser
        onlyHasEnoughMana(settings.mana.movement)
        onlyAliveUser
    {
        User storage user = userByAddress[_msgSender()];
        user.mana -= settings.mana.movement;

        if (compareStrings("up", direction)) {
            user.y++;
        } else if (compareStrings("down", direction)) {
            user.y--;
        } else if (compareStrings("right", direction)) {
            user.x++;
        } else if (compareStrings("left", direction)) {
            user.x--;
        } else {
            revert InvalidDirection();
        }
    }

    function revive() external onlyRegisteredUser {
        User storage user = userByAddress[_msgSender()];
        require(UserStatus.DEAD == user.status, "User must be dead");
        require(!user.reviveTimer.isUnset(), "Timer must be set");

        if (!user.reviveTimer.isExpired()) {
            // solhint-disable not-rely-on-time
            revert UserCanNotReviveYet({
                remainingTime: user.reviveTimer.getDeadline() - block.timestamp
            });
            // solhint-enable not-rely-on-time
        }

        _tokenKTA.safeTransferFrom(
            _msgSender(),
            address(this),
            settings.price.revive
        );

        user.health = 100;
        user.status = UserStatus.ALIVE;
        user.reviveTimer.reset();
    }

    function getMana() external onlyRegisteredUser onlyAliveUser {
        User storage user = userByAddress[_msgSender()];
        require(!user.getManaTimer.isUnset(), "Timer must be set");

        if (!user.getManaTimer.isExpired()) {
            // solhint-disable not-rely-on-time
            revert UserCanNotGetManaYet({
                remainingTime: user.getManaTimer.getDeadline() - block.timestamp
            });
            // solhint-enable not-rely-on-time
        }

        user.mana +=
            // solhint-disable-next-line not-rely-on-time
            (block.timestamp -
                user.getManaTimer.getDeadline() -
                settings.time.getMana) /
            settings.rate.getMana;

        // NOTE: avoid missing mana (maybe)
        if (user.mana > 100) {
            user.mana = 100;
        }

        // solhint-disable not-rely-on-time
        user.getManaTimer = Timers.Timestamp({
            _deadline: uint64(block.timestamp + settings.time.getMana)
        });
        // solhint-enable not-rely-on-time
    }

    function buyHealth(uint256 amount)
        external
        onlyRegisteredUser
        onlyAliveUser
    {
        User storage user = userByAddress[_msgSender()];
        require(100 >= user.health + amount, "Health must equal or less 100");

        _tokenKTA.safeTransferFrom(
            _msgSender(),
            address(this),
            settings.price.health * amount
        );

        user.health += amount;
    }

    function buyMana(uint256 amount) external onlyRegisteredUser onlyAliveUser {
        User storage user = userByAddress[_msgSender()];
        require(100 >= user.mana + amount, "Mana must equal or less 100");

        _tokenKTA.safeTransferFrom(
            _msgSender(),
            address(this),
            settings.price.mana * amount
        );

        user.mana += amount;
    }

    function buyArmor(uint256 amount)
        external
        onlyRegisteredUser
        onlyAliveUser
    {
        User storage user = userByAddress[_msgSender()];
        require(100 >= user.armor + amount, "Armor must equal or less 100");

        _tokenKTA.safeTransferFrom(
            _msgSender(),
            address(this),
            settings.price.armor * amount
        );

        user.armor += amount;
    }

    function addNewLevel(uint256 min, uint256 max) public onlyOwner {
        require(min < max, "Min must be less than Max value");

        Level memory lastLevel = levelById[levelId.current()];
        require(lastLevel.max == min, "Min must be equal to max of last");

        levelId.increment();

        levelById[levelId.current()] = Level({
            value: levelId.current(),
            min: min,
            max: max
        });
    }

    function updateSettings(uint256[] memory _settings_) public onlyOwner {
        settings = Setting({
            price: PriceSetting({
                revive: _settings_[0],
                register: _settings_[1],
                health: _settings_[2],
                mana: _settings_[3],
                armor: _settings_[4],
                teleport: _settings_[5]
            }),
            time: TimeSetting({
                revive: _settings_[6],
                getMana: _settings_[7]
            }),
            mana: ManaSetting({
                attack: _settings_[8],
                movement: _settings_[9]
            }),
            rate: RateSetting({
                registerReferralReward: _settings_[10],
                getMana: _settings_[11]
            }),
            min: MinSetting({ userName: _settings_[12] }),
            max: MaxSetting({
                userName: _settings_[13],
                teleportDistance: _settings_[14]
            })
        });
    }

    function updatePrivateSettings(uint256[] memory settings_)
        public
        onlyOwner
    {
        _settings = PrivateSetting({
            multiplier: MultiplierPrivateSetting({
                attack: settings_[0],
                resistance: settings_[1]
            }),
            exp: ExpPrivateSetting({ kill: settings_[2] }),
            rate: RatePrivateSetting({ armorAbsorption: settings_[3] }),
            max: MaxPrivateSetting({ numberDigits: settings_[4] })
        });
    }

    function getRandomDigit(uint256 nbDigits) internal returns (uint256) {
        unchecked {
            _nonce++;
        }

        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        // solhint-disable-next-line not-rely-on-time
                        block.timestamp,
                        block.difficulty,
                        _nonce
                    )
                )
            ) % 10**nbDigits;
    }

    function getDistance(
        int256 x1,
        int256 y1,
        int256 x2,
        int256 y2
    ) internal pure returns (uint256) {
        return sqrt(abs(x1 - x2)**2 + abs(y1 - y2)**2);
    }

    function abs(int256 x) private pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }

    function sqrt(uint256 x) private pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function compareStrings(string memory a, string calldata b)
        private
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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