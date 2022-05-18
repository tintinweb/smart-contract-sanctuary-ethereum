// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IBetSlips.sol";
import "./Utility.sol";

contract DiceGame is Initializable, OwnableUpgradeable {
    enum DiceGameChoice {
        OVER,
        UNDER
    }

    struct DicePlayerChoice {
        DiceGameChoice choice;
        uint256 playerNumber;
    }

    struct BetLimit {
        uint256 min;
        uint256 max;
        uint256 defaultValue;
    }

    mapping(string => DicePlayerChoice) _playerChoices;

    mapping(address => BetLimit) _betLimits;

    mapping(uint256 => address) _betTokens;

    uint256 private _betTokenCount;

    address payable private _betSlipsAddr;

    uint256 private _rtp;

    uint256 constant MIN_LUCKY_NUMBER = 0;
    uint256 constant MAX_LUCKY_NUMBER = 99;
    uint256 constant LUCKY_NUMBERS_AMOUNT = 100;

    event betLimitSet(
        address token,
        uint256 min,
        uint256 max,
        uint256 defaultValue
    );

    function initialize(address betSlipsAddr, uint256 rtp) public initializer {
        _betSlipsAddr = payable(betSlipsAddr);
        _rtp = rtp;
        _betTokenCount = 0;
        __Ownable_init();
    }

    function setBetSlipsAddress(address betSlipsAddr) public onlyOwner {
        _betSlipsAddr = payable(betSlipsAddr);
    }

    function getBetSlipsAddress() public view returns (address) {
        return _betSlipsAddr;
    }

    function setRtp(uint256 rtp) public onlyOwner {
        _rtp = rtp;
    }

    function getRtp() public view returns (uint256) {
        return _rtp;
    }

    function setBetLimit(
        address token,
        uint256 min,
        uint256 max,
        uint256 defaultValue
    ) public onlyOwner {
        BetLimit memory betLimit = BetLimit(min, max, defaultValue);

        if (_betLimits[token].max > 0) {
            _betLimits[token] = betLimit;
        } else {
            _betTokenCount++;
            _betLimits[token] = betLimit;
            _betTokens[_betTokenCount] = token;
        }

        emit betLimitSet(token, min, max, defaultValue);
    }

    function getGameConfig() public view returns (string memory) {
        string memory rtp = string(
            abi.encodePacked('{"rtp":', Utility.uintToStr(_rtp), ",")
        );

        string memory betLimitsStr = string(abi.encodePacked('"betLimits": {'));

        for (uint256 i = 1; i <= _betTokenCount; i++) {
            address token = _betTokens[i];

            BetLimit memory betLimit = _betLimits[token];

            string memory tokenStr = string(
                abi.encodePacked('"', Utility.addressToStr(token), '": {')
            );

            string memory minStr = string(
                abi.encodePacked(
                    '"min": ',
                    Utility.uintToStr(betLimit.min),
                    ","
                )
            );

            string memory maxStr = string(
                abi.encodePacked(
                    '"max": ',
                    Utility.uintToStr(betLimit.max),
                    ","
                )
            );

            string memory defaultStr = string(
                abi.encodePacked(
                    '"default": ',
                    Utility.uintToStr(betLimit.defaultValue),
                    "}"
                )
            );

            if (i < _betTokenCount) {
                defaultStr = string(abi.encodePacked(defaultStr, ","));
            }

            betLimitsStr = string(
                abi.encodePacked(
                    betLimitsStr,
                    tokenStr,
                    minStr,
                    maxStr,
                    defaultStr
                )
            );
        }

        return string(abi.encodePacked(rtp, betLimitsStr, "}}"));
    }

    function getOdds(uint256 playerNumber, uint8 diceChoice)
        public
        view
        returns (uint256)
    {
        uint256 probability = 1;

        if (diceChoice == uint8(DiceGameChoice.OVER)) {
            probability = MAX_LUCKY_NUMBER - playerNumber;
        } else if (diceChoice == uint8(DiceGameChoice.UNDER)) {
            probability = playerNumber - MIN_LUCKY_NUMBER;
        }

        uint256 odds = (_rtp * LUCKY_NUMBERS_AMOUNT) / probability;

        return odds;
    }

    function revealSeed(string memory seedHash, string memory seed) public {
        require(Utility.compareSeed(seedHash, seed) == true, "Invalid seed");

        IBetSlips.BetSlip memory betSlip = IBetSlips(_betSlipsAddr).getBetSlip(
            seedHash
        );

        uint256 gameResult = getRandomNumber(seed);

        uint256 returnAmount = getReturnAmount(
            seedHash,
            betSlip.wagerAmount,
            betSlip.odds,
            gameResult
        );

        IBetSlips(_betSlipsAddr).completeBet(
            seedHash,
            seed,
            Utility.uintToStr(gameResult),
            returnAmount
        );
    }

    function placeBet(
        uint256 wagerAmount,
        uint256 playerNumber,
        string memory choice,
        string memory seedHash,
        address token
    ) public {
        IBetSlips(_betSlipsAddr).deposit(
            msg.sender,
            token,
            wagerAmount,
            seedHash
        );

        placeBetSlip(wagerAmount, playerNumber, choice, seedHash, token);
    }

    function placeBetWithPermit(
        uint256 wagerAmount,
        uint256 playerNumber,
        string memory choice,
        string memory seedHash,
        address token,
        uint256 deadLine,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        IBetSlips(_betSlipsAddr).depositWithPermit(
            msg.sender,
            token,
            wagerAmount,
            seedHash,
            deadLine,
            v,
            r,
            s
        );

        placeBetSlip(wagerAmount, playerNumber, choice, seedHash, token);
    }

    function placeBetSlip(
        uint256 wagerAmount,
        uint256 playerNumber,
        string memory choice,
        string memory seedHash,
        address token
    ) private {

        DiceGameChoice gameChoice;

        if (
            keccak256(abi.encodePacked((choice))) ==
            keccak256(abi.encodePacked(("OVER")))
        ) {
            gameChoice = DiceGameChoice.OVER;
            require(playerNumber >= 4 && playerNumber <= 98, "Invalid Number");
        } else if (
            keccak256(abi.encodePacked((choice))) ==
            keccak256(abi.encodePacked(("UNDER")))
        ) {
            gameChoice = DiceGameChoice.UNDER;
            require(playerNumber >= 1 && playerNumber <= 95, "Invalide Number");
        } else {
            revert("The choice is invalid");
        }

        uint256 minAmount = _betLimits[token].min;
        uint256 maxAmount = _betLimits[token].max;

        require(
            wagerAmount >= minAmount && wagerAmount <= maxAmount,
            "The WagerAmount is invalid"
        );

        uint256 odds = getOdds(playerNumber, uint8(gameChoice));

        string memory playerGameChoice = getDiceGameChoice(
            choice,
            playerNumber
        );

        IBetSlips(_betSlipsAddr).placeBetSlip(
            msg.sender,
            token,
            wagerAmount,
            "dice",
            playerGameChoice,
            seedHash,
            odds
        );

        _playerChoices[seedHash] = DicePlayerChoice(gameChoice, playerNumber);
    }

    function getReturnAmount(
        string memory seedHash,
        uint256 wagerAmount,
        uint256 odds,
        uint256 gameResult
    ) internal view returns (uint256) {
        DicePlayerChoice memory playerChoice = _playerChoices[seedHash];

        uint256 returnAmount;

        if (playerChoice.choice == DiceGameChoice.OVER) {
            if (playerChoice.playerNumber < gameResult) {
                returnAmount = (wagerAmount * odds) / 100;
            } else {
                returnAmount = 0;
            }
        } else if (playerChoice.choice == DiceGameChoice.UNDER) {
            if (playerChoice.playerNumber > gameResult) {
                returnAmount = (wagerAmount * odds) / 100;
            } else {
                returnAmount = 0;
            }
        }

        return returnAmount;
    }

    function getRandomNumber(string memory seed)
        internal
        pure
        returns (uint256)
    {
        bytes memory b = bytes(seed);
        uint256 sum = 0;

        for (uint256 i = 0; i < b.length; i++) {
            bytes1 char = b[i];

            sum += uint256(uint8(char));
        }

        return sum % 100;
    }

    function getDiceGameChoice(string memory choice, uint256 playerNumber)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"playerChoice":"',
                    choice,
                    '", "playerNumber":',
                    Utility.uintToStr(playerNumber),
                    "}"
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IBetSlips {
    enum Status {
        PLACED,
        COMPLETED,
        REVOKED
    }

    struct BetSlip {
        uint256 betId;
        address player;
        address token;
        string gameCode;
        string playerGameChoice;
        string gameResult;
        uint256 wagerAmount;
        uint256 returnAmount;
        uint256 odds;
        string seedHash;
        string seed;
        Status status;
        uint256 placedAt;
        uint256 completedAt;
    }

    event betSlipPlaced(
        uint256 betId,
        address player,
        address tokenAddress,
        string gameCode,
        string playerGameChoice,
        uint256 wagerAmount,
        string seedHash,
        uint256 odds,
        Status status
    );

    event betSlipCompleted(
        uint256 betId,
        address player,
        address tokenAddress,
        string gameCode,
        string playerGameChoice,
        uint256 wagerAmount,
        string seedHash,
        string gameResult,
        uint256 returnAmount,
        string seed,
        uint256 odds,
        Status status
    );

    function getBetSlip(string memory seedHash)
        external
        returns (BetSlip memory);

    function deposit(
        address player,
        address token,
        uint256 wagerAmount,
        string memory seedHash
    ) external;

    function depositWithPermit(
        address player,
        address token,
        uint256 wagerAmount,
        string memory seedHash,
        uint256 deadLine,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function placeBetSlip(
        address player,
        address token,
        uint256 wagerAmount,
        string memory gameCode,
        string memory playerGameChoice,
        string memory seedHash,
        uint256 odds
    ) external;

    function completeBet(
        string memory seedHash,
        string memory seed,
        string memory gameResult,
        uint256 returnAmount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library Utility {
    function bytes32ToString(bytes32 _bytes32)
        public
        pure
        returns (string memory)
    {
        bytes memory s = new bytes(64);

        for (uint8 i = 0; i < 32; i++) {
            bytes1 b = bytes1(_bytes32[i]);
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));

            if (hi < 0x0A) {
                s[i * 2] = bytes1(uint8(hi) + 0x30);
            } else {
                s[i * 2] = bytes1(uint8(hi) + 0x57);
            }

            if (lo < 0x0A) {
                s[i * 2 + 1] = bytes1(uint8(lo) + 0x30);
            } else {
                s[i * 2 + 1] = bytes1(uint8(lo) + 0x57);
            }
        }

        return string(s);
    }

    function strToUint(string memory _str) public pure returns (uint256 res) {
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if (
                (uint8(bytes(_str)[i]) - 48) < 0 ||
                (uint8(bytes(_str)[i]) - 48) > 9
            ) {
                return 0;
            }
            res +=
                (uint8(bytes(_str)[i]) - 48) *
                10**(bytes(_str).length - i - 1);
        }

        return res;
    }

    function uintToStr(uint256 _i)
        public
        pure
        returns (string memory _uintAsString)
    {
        uint256 number = _i;
        if (number == 0) {
            return "0";
        }
        uint256 j = number;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (number >= 10) {
            bstr[k--] = bytes1(uint8(48 + (number % 10)));
            number /= 10;
        }
        bstr[k] = bytes1(uint8(48 + (number % 10)));
        return string(bstr);
    }

    function addressToStr(address _address)
        public
        pure
        returns (string memory)
    {
        bytes32 _bytes = bytes32((uint256(uint160(_address))));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);

        _string[0] = "0";
        _string[1] = "x";

        for (uint256 i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_string);
    }

    function compareSeed(string memory seedHash, string memory seed)
        public
        pure
        returns (bool)
    {
        string memory hash = bytes32ToString(sha256(abi.encodePacked(seed)));

        if (
            keccak256(abi.encodePacked(hash)) ==
            keccak256(abi.encodePacked(seedHash))
        ) {
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}