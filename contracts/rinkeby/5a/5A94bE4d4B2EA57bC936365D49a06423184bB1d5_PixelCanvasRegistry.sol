// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./utils/Uint256Array.sol";
import "./protocols/IDeployRegistry.sol";
import "./protocols/IPixelCanvasRegistry.sol";
import "./PixelCanvasVault.sol";
import "./PixelCanvasApplicationType.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PixelCanvasRegistry is IPixelCanvasRegistry, Ownable {

    event EventUpdatePaginationLimit(
        uint256 indexed from,
        uint256 indexed to
    );

    event EventUpdateCost(
        string indexed operation,
        uint256 from,
        uint256 to
    );

    event EventUpdatePixelSupply(
        address indexed pixelContract,
        uint256 supply
    );

    event EventAddOption(
        uint256 indexed optionId,
        address indexed pixelContract,
        uint256 amount
    );

     event EventUpdateOption(
        uint256 indexed optionId,
        address indexed pixelContract,
        uint256 amount
    );

    event EventRemoveOption(
        uint256 indexed optionId
    );

    uint256 private constant CONST_PAGINATION_LIMIT_DEFAULT = 10;

    IDeployRegistry private immutable _privateDeployRegistry;
    address private immutable _privateProxyRegistry;
    PixelCanvasVault private immutable _privateVault;

    uint256 _privatePaginationLimit;
    mapping(address => mapping(string => uint256)) private _privateCosts;
    mapping(address => uint256) private _privatePixelSupply;
    mapping(uint256 => Option) private _privateOptionByIdentifier;
    uint256[] private _privateOptionsIdentifiers;


    constructor(IDeployRegistry _deployRegistry, address _proxyRegistry) {
        _privateDeployRegistry = _deployRegistry;
        _privateProxyRegistry = _proxyRegistry;
        _privateVault = new PixelCanvasVault();
        _privatePaginationLimit = CONST_PAGINATION_LIMIT_DEFAULT;
    }

    //Common

    function proxyRegistry() override public view returns (address) {
        return _privateProxyRegistry;
    }

    //Paging

    function paginationLimit() override public view returns (uint256) {
        return _privatePaginationLimit;
    }

    function updatePaginationLimit(uint256 limit) override public onlyOwner {
        require(limit > 0, "Limit should be above zero");
        
        uint256 previousPaginationLimit = _privatePaginationLimit;
        _privatePaginationLimit = limit;
        emit EventUpdatePaginationLimit(previousPaginationLimit, _privatePaginationLimit);
    }

    //Costs

    function getCost(address _address, string memory operation) override public view returns (uint256) {
        return _privateCosts[_address][operation];
    }

    function updateCost(address _address, string memory operation, uint256 cost) override public onlyOwner {
        uint256 previousCost = _privateCosts[_address][operation];
        _privateCosts[_address][operation] = cost;
        emit EventUpdateCost(operation, previousCost, cost);
    }

    // Pixel Supply
    
    function getPixelSupply(address _address) override public view returns (uint256) {
        _requireValidPixel(_address, false);
        return _privatePixelSupply[_address];
    }

    function updatePixelSupply(address _address, uint256 supply) override public onlyOwner {
        _requireValidPixel(_address, false);
        _privatePixelSupply[_address] = supply;
        emit EventUpdatePixelSupply(_address, supply);
    }

    //Options

    function getNumberOfOptions() override public view returns (uint256) {
        return _privateOptionsIdentifiers.length;
    }

    function getOptionsIdentifiers() override public view returns (uint256[] memory) {
        return _privateOptionsIdentifiers;
    }

    function getOption(uint256 optionId) override public view returns (Option memory) {
        return _privateOptionByIdentifier[optionId];
    }

    function hasOption(uint256 optionId) override public view returns (bool) {
        return Uint256Array.valueExistsInArray(_privateOptionsIdentifiers, optionId);
    }

    function updateOption(uint256 optionId, address pixelAddress, uint256 amount) override public onlyOwner {
        _requireValidPixel(pixelAddress, true);

        Option memory option;
        option.pixelContract = pixelAddress;
        option.amount = amount;
        _privateOptionByIdentifier[optionId] = option;

        if (!Uint256Array.valueExistsInArray(_privateOptionsIdentifiers, optionId)) {
            _privateOptionsIdentifiers.push(optionId);
            emit EventAddOption(optionId, pixelAddress, amount);
        } else if (address(pixelAddress) == address(0)) {
            bool success = Uint256Array.removeValueFromArray(_privateOptionsIdentifiers, optionId);
            if (success) {
                emit EventRemoveOption(optionId);
            }
        } else {
            emit EventUpdateOption(optionId, pixelAddress, amount);
        }
    }

    //Payments

    function paymentsAmount() override public view onlyOwner returns (uint256) {
        return _privateVault.amount();
    }

    function paymentsDeposit() override public payable {
        return _privateVault.deposit{value: msg.value}();
    }

    function paymentsWithdraw(address payable recepient, uint256 amountLimit) override public onlyOwner {
        _privateVault.withdraw(recepient, amountLimit);
    }

    //Private

    function _requireValidPixel(address pixelContract, bool allowsZero) private view {
        bool hasPixel = _privateDeployRegistry.has(PixelCanvasApplicationType.PIXEL, pixelContract);
        require(hasPixel || (allowsZero && (pixelContract == address(0))), "Not a pixel");
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Uint256Array {

    function valueExistsInArray(uint256[] storage _array, uint256 _value) internal view returns (bool) {
        return (indexOfValueInArray(_array, _value) < _array.length);
    }

    function indexOfValueInArray(uint256[] storage _array, uint256 _value) internal view returns (uint256) {
        for (uint256 index = 0; index < _array.length; index++) {
            if (_array[index] == _value) {
                return index;
            }
        }
        return _array.length;
    }

    //Don't preserve order
    function removeValueByIndexFromArray(uint256[] storage _array, uint256 _index) internal {
        require(_index < _array.length, 'Index is out of bounds');
        _array[_index] = _array[_array.length - 1];
        _array.pop();
    }

    function removeValueFromArray(uint256[] storage _array, uint256 _value) internal returns (bool) {
        uint256 index = indexOfValueInArray(_array, _value);
        if (index < _array.length) {
            removeValueByIndexFromArray(_array, index);
            return true;
        } else {
            return false;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDeployRegistry {
    
    function list(uint256 _type) external view returns (address[] memory);

    function get(uint256 _type, uint256 _index) external view returns (address);

    function length(uint256 _type) external view returns (uint256);

    function has(uint256 _type, address _address) external view returns (bool);

    function add(uint256 _type, address _address) external returns (bool);

    function remove(uint256 _type, address _address) external returns (bool);

    function clear(uint256 _type) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPixelCanvasRegistry {

    struct Option {
        address pixelContract;
        uint256 amount;
    }

    //Common

    function proxyRegistry() external view returns (address);

    //Paging

    function paginationLimit() external view returns (uint256);

    function updatePaginationLimit(uint256 limit) external;

    //Costs

    function getCost(address _address, string memory operation) external view returns (uint256);

    function updateCost(address _address, string memory operation, uint256 cost) external;

    // Pixel Supply
    
    function getPixelSupply(address _address) external view returns (uint256);

    function updatePixelSupply(address _address, uint256 supply) external;

    //Options

    function getNumberOfOptions() external view returns (uint256);

    function getOptionsIdentifiers() external view returns (uint256[] memory);

    function getOption(uint256 optionId) external view returns (Option memory);

    function hasOption(uint256 optionId) external view returns (bool);

    function updateOption(uint256 optionId, address pixelAddress, uint256 amount) external;

    //Payments

    function paymentsAmount() external view returns (uint256);

    function paymentsDeposit() external payable;

    function paymentsWithdraw(address payable recepient, uint256 amountLimit) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
openzeppelin-contracts/contracts/utils/escrow/Escrow.sol
*/
 
contract PixelCanvasVault is Ownable {
    using Address for address payable;

    event Deposited(uint256 weiAmount);
    event Withdrawn(uint256 weiAmount);

    uint256 private _depositAmount;

    function amount() public view onlyOwner returns (uint256) {
        return _depositAmount;
    }

    function deposit() public payable onlyOwner {
        uint256 payment = msg.value;
        _depositAmount += payment;
        emit Deposited(payment);
    }

    function withdraw(address payable _recepient, uint256 _amountLimit) public onlyOwner {
        uint256 payment;
        if ((_amountLimit == 0) || (_amountLimit >= _depositAmount)) {
            payment = _depositAmount;
        } else {
            payment = _amountLimit;
        }
        _depositAmount -= payment;
        _recepient.sendValue(payment);
        emit Withdrawn(payment);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library PixelCanvasApplicationType {
    
    uint256 constant REGISTRY = 0;
    uint256 constant PIXEL = 1;
    uint256 constant CANVAS = 2;
    uint256 constant FACTORY = 3;

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