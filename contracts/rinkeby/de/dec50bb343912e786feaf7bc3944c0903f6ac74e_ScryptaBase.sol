/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

pragma solidity ^0.8.0;


//SPDX-License-Identifier: Unlicense

interface IScryptaBase {

    event TokenCreated(uint256 id);
    event TransferExecuted(bytes20 sender, bytes20 receiver, uint256 id, uint256 amount);

    function createToken(string calldata tokenData) external returns (uint256);

    function mint(bytes20 to, uint256 id, uint256 amount) external;
    function mintBatch(bytes20[] memory to, uint256[] memory ids, uint256[] memory amounts) external;

    function transfer(bytes20 from, bytes20 to, uint256 id, uint256 amount) external;
    function transferBatch(bytes20[] calldata from, bytes20[] calldata to, uint256[] calldata ids, uint256[] calldata amounts) external;

    function burn(bytes20 from, uint256 id, uint256 amount) external;
    function burnBatch(bytes20[] memory from, uint256[] memory ids, uint256[] memory amounts) external;

    function token(uint256 id) external view returns (string memory);
    function holdersOf(uint256 id) external view returns (bytes20[] memory);
    function balanceOf(uint256 id, bytes20 holder) external view returns (uint256);

}


interface IScryptaUpgradeableBase is IScryptaBase {

    function initialize(IScryptaUpgradeableBase scryptaBase) external;
    function state() external view returns (string[] memory, bytes20[][] memory, uint256[][] memory);

}


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)
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


// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)
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


contract ScryptaBase is IScryptaUpgradeableBase, Ownable, Initializable {

    string[] private _tokens; // id -> token (base64)
    mapping(uint256 => bytes20[]) private _holders; // id -> accounts
    mapping(uint256 => mapping(bytes20 => uint256)) private _balances; // id -> (account -> balance)

    function initialize(IScryptaUpgradeableBase scryptaBase) public override onlyOwner initializer {
        require(_tokens.length == 0, "ScryptaBase: the contract is already storing data and cannot be initialized");

        string[] memory tokens;
        bytes20[][] memory holders;
        uint256[][] memory balances;
        (tokens, holders, balances) = scryptaBase.state();

        for (uint256 id=0; id<tokens.length; id++) {
            _tokens.push(tokens[id]);
            _holders[id] = holders[id];
            for (uint256 i=0; i<holders[id].length; i++)
                _balances[id][holders[id][i]] = balances[id][i];
        }
    }

    function state() public view override returns (string[] memory, bytes20[][] memory, uint256[][] memory) {
        string[] memory tokens = _tokens;
        bytes20[][] memory holders = new bytes20[][](tokens.length);
        uint256[][] memory balances = new uint256[][](tokens.length);
        for (uint256 id=0; id<tokens.length; id++) {
            holders[id] = _holders[id];
            balances[id] = new uint256[](_holders[id].length);
            for (uint256 i=0; i<_holders[id].length; i++)
                balances[id][i] = _balances[id][_holders[id][i]];
        }
        return (tokens, holders, balances);
    }

    function createToken(string memory tokenData) public override onlyOwner returns (uint256) {
        _tokens.push(tokenData);
        emit TokenCreated(_tokens.length-1);
        return _tokens.length-1;
    }

    function mint(bytes20 to, uint256 id, uint256 amount) public override onlyOwner {
        require(to != 0x0, "ScryptaBase: mint to the zero address not allowed");
        _transfer(0x0, to, id, amount, false);
    }

    function mintBatch(bytes20[] memory to, uint256[] memory ids, uint256[] memory amounts) public override onlyOwner {
        for(uint256 i = 0; i < to.length; i++)
            require(to[i] != 0x0, "ScryptaBase: mint to the zero address not allowed");
        bytes20[] memory from = new bytes20[](to.length);
        _transferBatch(from, to, ids, amounts, false);
    }

    function transfer(bytes20 from, bytes20 to, uint256 id, uint256 amount) public override onlyOwner {
        _transfer(from, to, id, amount, true);
    }

    function transferBatch(bytes20[] memory from, bytes20[] memory to, uint256[] memory ids, uint256[] memory amounts) public override onlyOwner {
        _transferBatch(from, to, ids, amounts, true);
    }

    function burn(bytes20 from, uint256 id, uint256 amount) public override onlyOwner {
        require(from != 0x0, "ScryptaBase: burn from the zero address not allowed");
        _transfer(from, 0x0, id, amount, false);
    }

    function burnBatch(bytes20[] memory from, uint256[] memory ids, uint256[] memory amounts) public override onlyOwner {
        for(uint256 i = 0; i < from.length; i++)
            require(from[i] != 0x0, "ScryptaBase: burn from the zero address not allowed");
        bytes20[] memory to = new bytes20[](from.length);
        _transferBatch(from, to, ids, amounts, false);
    }

    function token(uint256 id) public view override returns (string memory) {
        return _tokens[id];
    }

    function holdersOf(uint256 id) public view override returns (bytes20[] memory) {
        return _holders[id];
    }

    function balanceOf(uint256 id, bytes20 holder) public view override returns (uint256) {
        return _balances[id][holder];
    }

    function _transfer(bytes20 from, bytes20 to, uint256 id, uint256 amount, bool safe) private {
        require(amount > 0, "ScryptaBase: amount cannot be zero");
        require(!safe || from != 0x0, "ScryptaBase: transfer from the zero address not allowed");
        require(!safe || to != 0x0, "ScryptaBase: transfer to the zero address not allowed");
        require(from == 0x0 || _balances[id][from] >= amount, "ScryptaBase: insufficient balance for transfer");

        if (to != 0x0) {
            _balances[id][to] += amount;
            _addHolderOf(id, to);
        }
        if (from != 0x0) {
            _balances[id][from] -= amount;
            if (_balances[id][from] == 0)
                _removeHolderOf(id, from);
        }

        emit TransferExecuted(from, to, id, amount);
    }

    function _transferBatch(bytes20[] memory from, bytes20[] memory to, uint256[] memory ids, uint256[] memory amounts, bool safe) private {
        require(from.length > 0, "ScryptaBase: no transfers to perform");
        require(from.length == to.length && to.length == ids.length && ids.length == amounts.length,
            "ScryptaBase: all input arrays must have the same number of elements"
        );
        for (uint256 i=0; i<from.length; i++)
            _transfer(from[i], to[i], ids[i], amounts[i], safe);
    }

    function _findHolderOf(uint256 id, bytes20 holder) private view returns(bool, uint256) {
        for (uint256 i=0; i<_holders[id].length; i++) {
            if (_holders[id][i] == holder)
                return (true, i);
        }
        return (false, 0);
    }

    function _addHolderOf(uint256 id, bytes20 holder) private {
        (bool found,) = _findHolderOf(id, holder);
        if (!found)
            _holders[id].push(holder);
    }

    function _removeHolderOf(uint256 id, bytes20 holder) private {
        (bool found, uint256 pos) = _findHolderOf(id, holder);
        if (found) {
            for (uint256 i=pos; i<_holders[id].length-1; i++)
                _holders[id][i] = _holders[id][i+1];
            _holders[id].pop();
        }
    }

}