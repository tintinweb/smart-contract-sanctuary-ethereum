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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/* solhint-disable indent */


struct MultiPartContract {
    string name_;
    bytes[] data_;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IStrings.sol";

struct SVGTemplatesContract {
    mapping(string => address) _templates;
    string[] _templateNames;
}

interface ISVG {
    function getSVG() external view returns (string memory);
}

interface ISVGTemplate {
    function createSVG(address sender, string memory _name) external returns (address _tplAddress);
    function svgs() external view returns (string[] memory);
    function svgName() external view returns (string memory _name);
    function svgString(string memory name) external view returns (string memory _data);
    function svgAddress(string memory name) external view returns (address _data);
    function svgBytes() external view returns (bytes[] memory _data);
    function clear() external;
    function add(string memory _data) external returns (uint256 _index);
    function addAll(string[] memory _data) external returns (uint256 _count);
    function buildSVG(Replacement[] memory replacements) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Replacement {
    string matchString;
    string replaceString;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";

import "../interfaces/ISVG.sol";
import "../interfaces/IStrings.sol";
import "../interfaces/IMultiPart.sol";

import "../libraries/StringsLib.sol";

import "../utilities/SVGTemplate.sol";

struct SaltStorage {
    uint256 salt;
}

struct SVGStorage {
    SVGTemplatesContract svgTemplates;
    SaltStorage salt;    
    address svgManager;
    MultiPartContract multiPart;
}

library SVGTemplatesLib {

    event SVGTemplateCreated(string name, address template);

    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.nextblock.bitgem.app.SVGStorage.storage");

    function svgStorage() internal pure returns (SVGStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    
    /// @notice get the stored template names in the contract
    /// @return the names of the templates
    function _svgs(SVGTemplatesContract storage self)
        internal
        view
        returns (string[] memory) { return self._templateNames; }

    /// @notice get the create2 address of the given name
    function _svgAddress(
        SVGTemplatesContract storage,
        string memory _name) 
        internal 
        view returns (address) {
        return Create2.computeAddress(
            keccak256(abi.encodePacked(_name)), 
            keccak256(type(SVGTemplate).creationCode)
        );  
    }

    /// @notice the svg string or an empty string
    function _svgString(
        SVGTemplatesContract storage self,
        string memory _name
    ) internal view returns (string memory data_) {
        try SVGTemplate(_svgAddress(self, _name)).svgString() returns (string memory _data) {
            data_ = _data;
        } catch (bytes memory) {}
    }

    /// @notice the sstored address for the name storage. empty is no svg
    function _svgData(
        SVGTemplatesContract storage self,
        string memory _name
    ) internal view returns (address) {
        return self._templates[_name];
    }

    /// @notice create a new SVG image with the given name
    function _createSVG(SVGTemplatesContract storage self, address sender, string memory _name)
        internal
        returns (address _tplAddress)
    {
        // make sure the name is unique
        require(
            self._templates[_name] == address(0),
            "template already deployed"
        );

        // get the address for the given name, create using create2,
        // then verify that create2 returned the expected address
        address targetTplAddress = _svgAddress(self, _name);
        _tplAddress = Create2.deploy(
            0,
            keccak256(abi.encodePacked(_name)),
            type(SVGTemplate).creationCode
        );
        require(targetTplAddress == _tplAddress, "template address mismatch");

        // transfer ownership to the creator and update storage
        Ownable(_tplAddress).transferOwnership(sender);
        self._templateNames.push(_name);
        self._templates[_name] = _tplAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IStrings.sol";

library StringsLib {

    function parseInt(string memory s) internal pure returns (uint256 res) {

        for (uint256 i = 0; i < bytes(s).length; i++) {
            if ((uint8(bytes(s)[i]) - 48) < 0 || (uint8(bytes(s)[i]) - 48) > 9) {
                return 0;
            }
            res += (uint8(bytes(s)[i]) - 48) * 10**(bytes(s).length - i - 1);
        }
        return res;

    }

    function startsWith(string memory haystack, string memory needle)
        internal
        pure
        returns (bool)
    {
        bytes memory haystackBytes = bytes(haystack);
        bytes memory needleBytes = bytes(needle);
        uint256 haystackLength = haystackBytes.length;
        uint256 needleLength = needleBytes.length;
        if (needleLength > haystackLength) {
            return false;
        }
        for (uint256 i = 0; i < needleLength; i++) {
            if (haystackBytes[i] != needleBytes[i]) {
                return false;
            }
        }
        return true;
    }

    function endsWith(string memory haystack, string memory needle)
        internal
        pure
        returns (bool)
    {
        bytes memory haystackBytes = bytes(haystack);
        bytes memory needleBytes = bytes(needle);
        uint256 haystackLength = haystackBytes.length;
        uint256 needleLength = needleBytes.length;
        if (needleLength > haystackLength) {
            return false;
        }
        for (uint256 i = 0; i < needleLength; i++) {
            if (
                haystackBytes[haystackLength - i - 1] !=
                needleBytes[needleLength - i - 1]
            ) {
                return false;
            }
        }
        return true;
    }

    function substring(string memory haystack, uint256 startpos)
        internal
        pure
        returns (string memory)
    {
        bytes memory haystackBytes = bytes(haystack);
        uint256 length = haystackBytes.length;
        uint256 endpos = length - startpos;
        bytes memory substringBytes = new bytes(endpos);
        for (uint256 i = 0; i < endpos; i++) {
            substringBytes[i] = haystackBytes[startpos + i];
        }
        return string(substringBytes);
    }

    function substring(string memory haystack, uint256 startpos, uint256 endpos)
        internal
        pure
        returns (string memory)
    {
        bytes memory haystackBytes = bytes(haystack);
        uint256 substringLength = endpos - startpos;
        bytes memory substringBytes = new bytes(substringLength);
        for (uint256 i = 0; i < substringLength; i++) {
            substringBytes[i] = haystackBytes[startpos + i];
        }
        return string(substringBytes);
    }

    function concat(string[] memory _strings)
        internal
        pure
        returns (string memory _concat)
    {
        _concat = "";
        for (uint256 i = 0; i < _strings.length; i++) {
            _concat = string(abi.encodePacked(_concat, _strings[i]));
        }
        return _concat;
    }

    function split(string memory _string, string memory _delimiter) internal pure returns (string[] memory _split) {
        _split = new string[](0);
        uint256 _delimiterLength = bytes(_delimiter).length;
        uint256 _stringLength = bytes(_string).length;
        uint256 _splitLength = 0;
        uint256 _splitIndex = 0;
        uint256 _startpos = 0;
        uint256 _endpos = 0;
        for (uint256 i = 0; i < _stringLength; i++) {
            if (bytes(_string)[i] == bytes(_delimiter)[0]) {
                _endpos = i;
                if (_endpos - _startpos > 0) {
                    _split[_splitIndex] = substring(_string, _startpos);
                    _splitIndex++;
                    _splitLength++;
                }
                _startpos = i + _delimiterLength;
            }
        }
        if (_startpos < _stringLength) {
            _split[_splitIndex] = substring(_string, _startpos);
            _splitIndex++;
            _splitLength++;
        }
        return _split;
    }

    function join(string[] memory _strings, string memory _delimiter) internal pure returns (string memory _joined) {
        for (uint256 i = 0; i < _strings.length; i++) {
            _joined = string(abi.encodePacked(_joined, _strings[i]));
            if (i < _strings.length - 1) {
                _joined = string(abi.encodePacked(_joined, _delimiter));
            }
        }
        return _joined;
    }

    function replace(string memory _string, string memory _search, string memory _replace) internal pure returns (string memory _replaced) {
        _replaced = _string;
        uint256 _searchLength = bytes(_search).length;
        uint256 _stringLength = bytes(_string).length;
        uint256 _replacedLength = _stringLength;
        uint256 _startpos = 0;
        uint256 _endpos = 0;
        for (uint256 i = 0; i < _stringLength; i++) {
            if (bytes(_string)[i] == bytes(_search)[0]) {
                _endpos = i;
                if (_endpos - _startpos > 0) {
                    _replaced = substring(_replaced, _startpos);
                    _replacedLength -= _endpos - _startpos;
                }
                _replaced = string(abi.encodePacked(_replaced, _replace));
                _replacedLength += bytes(_replace).length;
                _startpos = i + _searchLength;
            }
        }
        if (_startpos < _stringLength) {
            _replaced = substring(_replaced, _startpos);
            _replacedLength -= _stringLength - _startpos;
        }
        return _replaced;
    }

    function trim(string memory _string) internal pure returns (string memory _trimmed) {
        _trimmed = _string;
        uint256 _stringLength = bytes(_string).length;
        uint256 _startpos = 0;
        uint256 _endpos = 0;
        for (uint256 i = 0; i < _stringLength; i++) {
            if (bytes(_string)[i] != 0x20) {
                _startpos = i;
                break;
            }
        }
        for (uint256 i = _stringLength - 1; i >= 0; i--) {
            if (bytes(_string)[i] != 0x20) {
                _endpos = i;
                break;
            }
        }
        if (_startpos < _endpos) {
            _trimmed = substring(_trimmed, _startpos);
            _trimmed = substring(_trimmed, 0, _endpos - _startpos + 1);
        }
        return _trimmed;
    }

    function toUint16(string memory s) internal pure returns (uint16 res_) {
        uint256 res = 0;
        for (uint256 i = 0; i < bytes(s).length; i++) {
            if ((uint8(bytes(s)[i]) - 48) < 0 || (uint8(bytes(s)[i]) - 48) > 9) {
                return 0;
            }
            res += (uint8(bytes(s)[i]) - 48) * 10**(bytes(s).length - i - 1);
        }
        res_ = uint16(res);
    }


    function replace(string[] memory input, string memory matchTag, string[] memory repl) internal pure returns (string memory) {
        string memory svgBody;
        for(uint256 i = 0; i < input.length; i++) {
            string memory svgString = input[i];
            string memory outValue;
            if(StringsLib.startsWith(svgString, matchTag)) {
                string memory restOfLine = StringsLib.substring(svgString, bytes(matchTag).length);
                uint256 replIndex = StringsLib.parseInt(restOfLine);
                outValue = repl[replIndex];
            } else {
                outValue = svgString;
            }
            svgBody = string(abi.encodePacked(svgBody, outValue));
        }
        return svgBody;
    }

    function replace(bytes[] memory sourceBytes, Replacement[] memory replacements_) public pure returns (string memory) {
        //bytes[] memory sourceBytes = _getSourceBytes();
        string memory outputFile = "";
        for (uint256 i = 0; i < sourceBytes.length; i++) {
            bytes memory sourceByte = sourceBytes[i];
            string memory outputLine  = string(sourceBytes[i]);
            for (uint256 j = 0; j < replacements_.length; j++) {
                Replacement memory replacement = replacements_[j];
                if (keccak256(sourceByte) == keccak256(bytes(replacement.matchString))) {
                    outputLine = replacement.replaceString;
                }
            }
            outputFile = string(abi.encodePacked(outputFile, outputLine));
        }
        return outputFile;
    }    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../libraries/SVGTemplatesLib.sol";

import "../interfaces/IMultiPart.sol";

abstract contract MultipartData  {
    /// @notice add a new multipart to the contract
    /// @param _data the data of the multipart
    function _addData(bytes memory _data)
        internal returns (uint256 _index) {
        _index = SVGTemplatesLib.svgStorage().multiPart.data_.length;
        SVGTemplatesLib.svgStorage().multiPart.data_.push(_data);
    }

    /// @notice get the data of the given index
    /// @param _index the index of the data
    function _getData(uint256 _index)
        internal view  returns (bytes memory data) {
        data = SVGTemplatesLib.svgStorage().multiPart.data_[_index];
    }

    /// @notice get the data as a string
    function _fromBytes() internal view returns (string memory output) {
        string memory result = "";
        for (uint256 i = 0; i < SVGTemplatesLib.svgStorage().multiPart.data_.length; i++) {
            result = string(abi.encodePacked(result, SVGTemplatesLib.svgStorage().multiPart.data_[i]));
        }
        output = result;
    }

    /// @notice get the data as a  bytes array
    function data__() internal view returns (bytes[] storage) {
        return SVGTemplatesLib.svgStorage().multiPart.data_;
    }

    /// @notice clear the contents of the data array
    function _clear() internal {
        delete SVGTemplatesLib.svgStorage().multiPart.data_;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utilities/MultipartData.sol";

import "../libraries/StringsLib.sol";
import "../libraries/SVGTemplatesLib.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/// @notice a single SVG image
contract SVGTemplate is MultipartData, Ownable, Initializable {

    event SVGImageAdded(address indexed _from, address indexed _to, string _name, string _data);
    event SVGImagePartAdded(address indexed _from, address indexed _to, string _name, string _data);

    function initialize(string memory _name, string[] memory _svg) external initializer {
        MultiPartContract storage ds = SVGTemplatesLib.svgStorage().multiPart;
        ds.name_ = _name;
        for(uint i = 0; i < _svg.length; i++) {
            ds.data_.push(bytes(_svg[i]));
        }
    }

    /// @notice the name of the svg
    function svgName() external view returns (string memory _name) {
        MultiPartContract storage ds = SVGTemplatesLib.svgStorage().multiPart;
        _name = ds.name_;
    }

    /// @notice the data of the svg
    function svgString() external view returns (string memory _data) {
        _data = _fromBytes();
    }

    /// @notice the data of the svg
    function svgBytes() external view returns (bytes[] memory _data) {
        _data = data__();
    }
    
    /// @notice clear the data of the svg
    function clear() external onlyOwner {
        _clear();
    }

    /// @notice add data to the end of the data
    function add(string memory _data) external onlyOwner returns (uint256 _index) {
        _index = _addData(bytes(_data));
        emit SVGImagePartAdded(msg.sender, address(this), SVGTemplatesLib.svgStorage().multiPart.name_, _data);
    }

    /// @notice add all SVG lines at
    function addAll(string[] memory _data) external onlyOwner returns (uint256 _count) {
        for(uint256 i = 0; i < _data.length; i++) {
            _addData(bytes(_data[i]));
        }
        _count = _data.length;
        MultiPartContract storage ds = SVGTemplatesLib.svgStorage().multiPart;
        emit SVGImageAdded(msg.sender, address(this), ds.name_, _fromBytes());
    }

    /// @notice get the svg, replacing the data with the data from the given replacements
    function buildSVG(Replacement[] memory replacements) external view returns (string memory) {
        return StringsLib.replace(data__(), replacements);
    }
}