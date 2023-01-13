// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../libs/CellData.sol";
import "./interfaces/IRandom.sol";
import "./interfaces/ISeed.sol";

contract Random is IRandom, ISeed, OwnableUpgradeable {
    uint8 private constant MAX_LEVEL_OF_EVOLUTION = 100;
    uint256 private constant INVERSE_BASIS_POINT = 10000;
    uint256 private constant HUNDRED_PERCENT = 10000;

    struct Group {
        uint256 startBlock;
        uint256 step;
        uint128 stages;
    }

    uint256 private mSeed;

    function initialize(address owner) external initializer {
        require(owner != address(0), "Address should not be empty");
        __Ownable_init();
        transferOwnership(owner);
    }

    function getSeed() external view override onlyOwner returns (uint256) {
        return mSeed;
    }

    function setSeed(uint256 seed) external override onlyOwner {
        mSeed = seed;
    }

    function getRandomVariant() external view override returns (uint256) {
        uint256 number = random() % (HUNDRED_PERCENT / 2);
        if (number == 0) {
            number = 1;
        }
        return number;
    }

    function getRandomClass() external view override returns (uint8) {
        uint256 number = random();
        return uint8(_getChosenClass(number %= INVERSE_BASIS_POINT, 0));
    }

    event GetSplittableWithIncreaseChance(
        uint256 randomNumber,
        uint256 probability,
        uint256 inverseBase,
        uint256 increasedChanceSplitNanoCell
    );

    function getSplittableWithIncreaseChance(
        uint256 probability,
        uint256 increasedChanceSplitNanoCell
    ) external override returns (uint8) {
        // since in class 100%=1000 but probability calculates as 100% = 100
        uint256 subMultiplier = INVERSE_BASIS_POINT / 100;
        probability = probability * subMultiplier;
        increasedChanceSplitNanoCell =
            increasedChanceSplitNanoCell *
            subMultiplier;

        emitRandomData();
        uint256 number = random();
        emit GetSplittableWithIncreaseChance(
            number,
            probability,
            INVERSE_BASIS_POINT,
            increasedChanceSplitNanoCell
        );
        number %= (INVERSE_BASIS_POINT + increasedChanceSplitNanoCell);

        if (number+probability > 9999) {
            if (number >= 0 && number <= 999) {
                return uint8(CellData.Class.SPLITTABLE_BIOMETA);
            } else if (number >= 1000 && number <= 4999) {
                return uint8(CellData.Class.SPLITTABLE_ENHANCER);
            } else if (
                number >= 5000 && number <= 9999 + increasedChanceSplitNanoCell
            ) {
                return uint8(CellData.Class.SPLITTABLE_NANO);
            }
        }
        return
            uint8(
                _getChosenClass(
                    number + probability,
                    increasedChanceSplitNanoCell
                )
            );
    }

    function getRandomStage(uint256 _stage, uint256 probabilityIncrease)
        external
        view
        override
        returns (uint256)
    {
        require(_stage <= MAX_LEVEL_OF_EVOLUTION, "Invalid Stage");
        uint256 number = random() % HUNDRED_PERCENT;
        number = number + (probabilityIncrease * 10);

        if (number <= 6999) {
            _stage = _stage + 1;
        } else if (number >= 7000 && number <= 8999) {
            _stage = _stage + 2;
        } else if (number >= 9000 && number <= 9499) {
            _stage = _stage + 3;
        } else if (number >= 9500 && number <= 9799) {
            _stage = _stage + 4;
        } else if (number >= 9800) {
            _stage = _stage + 5;
        }

        // overflow case
        if (_stage > MAX_LEVEL_OF_EVOLUTION) {
            _stage = MAX_LEVEL_OF_EVOLUTION;
        }

        return _stage;
    }

    function getEvolutionTime(uint256 decreasedRate)
        external
        override
        returns (uint256)
    {
        uint256 currentBlock = block.number;

        uint256 number = random() % HUNDRED_PERCENT;
        Group memory group = getGroup(number);
        uint256 stage = random() % HUNDRED_PERCENT / 1000;

        if (stage == 0) {
            stage = stage + 1;
        }

        uint256 blockAmount = group.startBlock + (group.step * stage);
        uint256 decreasedBlockAmount = (blockAmount * decreasedRate) / 100;

        blockAmount -= decreasedBlockAmount;

        currentBlock = currentBlock + blockAmount;
        return currentBlock;
    }

    function getGroup(uint256 number) private returns (Group memory group) {
        if (number >= 6000 && number <= 8999) {
            group.startBlock = 138;//74000;
            group.step = 2638;//10000;
        } else if (number >= 9000 && number <= 10000) {
            group.startBlock = 138;//24000;
            group.step = 2638;//5000;
        } else {
            group.startBlock = 138;//174000;
            group.step = 2638;//10000;
        }
        emit GetGroup(number, group);
    }

    event GetGroup(uint256 number, Group group);

    // Get randomly chosen image from stage range of images
    // Random is limited by two borders: left and right
    // Borders represent imageID in _tokenURIs mapping
    function _getChosenClass(
        uint256 number,
        uint256 increasedChanceSplitNanoCell
    ) private pure returns (CellData.Class class) {
        if (number >= 0 && number <= 9499) {
            return CellData.Class.COMMON;
        } else if (number >= 9500 && number <= 9549) {
            return CellData.Class.SPLITTABLE_BIOMETA;
        } else if (number >= 9550 && number <= 9749) {
            return CellData.Class.SPLITTABLE_ENHANCER;
        } else if (
            number >= 9750 &&
            number <= 9999 + (increasedChanceSplitNanoCell / 5)
        ) {
            return CellData.Class.SPLITTABLE_NANO;
        }
    }

    function random() private view returns (uint256 randomNumber) {
        randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    msg.sender,
                    mSeed
                )
            )
        );
    }

    function emitRandomData() internal {
        emit RandomData(blockhash(block.number - 1), msg.sender, mSeed);
    }

    event RandomData(bytes32 blockHash, address caller, uint256 seed);

    function randomByDifficulty() private view returns (uint256 randomNumber) {
        randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    block.number
                )
            )
        );
    }

    function randomRateSplitBiometaToken()
        external
        view
        override
        returns (uint256 amount)
    {
        uint256 _random = random();
        uint256 _randomByDifficulty = randomByDifficulty();
        uint256 typeAmount = _random % HUNDRED_PERCENT;
        if (typeAmount <= 8999) {
            amount =
                ((_randomByDifficulty - typeAmount * HUNDRED_PERCENT) % 91) +
                10;
        } else if (typeAmount >= 9000 && typeAmount <= 9699) {
            amount =
                ((_randomByDifficulty - typeAmount * HUNDRED_PERCENT) % 901) +
                100;
        } else {
            amount =
                ((_randomByDifficulty - typeAmount * HUNDRED_PERCENT) % 9001) +
                1000;
        }
    }

    function randomEnhancerId(uint256 limit)
        external
        view
        override
        returns (uint256 randomId)
    {
        randomId = (random() % limit) + 1;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface ISeed {
    /**
     * @dev Returns seed
     */
    function getSeed() external view returns (uint256);

    /**
     * @dev Sets seed value
     */
    function setSeed(uint256 seed) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

interface IRandom {
    /**
     * @dev Picks random image depends on the token stage
     */
    function getRandomVariant() external view returns (uint256);

    /**
     * @dev Picks random class for token during evolution from
     * [COMMON, SPLITTABLE_NANO, SPLITTABLE_BIOMETA, FINISHED]
     */
    function getRandomClass() external view returns (uint8);

    /**
     * @dev Check whether token could be splittable
     */
    function getSplittableWithIncreaseChance(uint256 probability, uint256 increasedChanceSplitNanoCell)
        external
        returns (uint8);

    /**
     * @dev Generates next stage for token during evoution
     * in rage of [0;5]
     */
    function getRandomStage(uint256 _stage, uint256 probabilityIncrease)
        external
        view
        returns (uint256);

    /**
     * @dev Generates evolution time
     */
    function getEvolutionTime(uint256 decreasedRate) external returns (uint256);

    function randomEnhancerId(uint256 limit) external view returns (uint256 randomId);

    function randomRateSplitBiometaToken() external view returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/**
 * @title Representation of cell with it fields
 */
library CellData {
    /**
     *  Represents the standart roles
     *  on which cell can be divided
     */
    enum Class {
        INIT,
        COMMON,
        SPLITTABLE_NANO,
        SPLITTABLE_BIOMETA,
        SPLITTABLE_ENHANCER,
        FINISHED
    }

    function isSplittable(Class _class) internal pure returns (bool) {
        return
            _class == Class.SPLITTABLE_NANO ||
            _class == Class.SPLITTABLE_BIOMETA ||
            _class == Class.SPLITTABLE_ENHANCER;
    }

    /**
     *  Represents the basic parameters that describes cell
     */
    struct Cell {
        uint256 tokenId;
        address user;
        Class class;
        uint256 stage;
        uint256 nextEvolutionBlock;
        uint256 variant;
        bool onSale;
        uint256 price;
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
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