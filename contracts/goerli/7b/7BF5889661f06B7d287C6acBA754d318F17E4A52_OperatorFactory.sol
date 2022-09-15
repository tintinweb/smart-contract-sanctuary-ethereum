// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import { IOperatorFactory } from "./interfaces/IOperatorFactory.sol";
import { IOperatorLogicRegistry } from "./interfaces/IOperatorLogicRegistry.sol";
import { IAddressBook } from "@theorderbookdex/addressbook/contracts/interfaces/IAddressBook.sol";
import { Operator } from "./Operator.sol";

/**
 * Operator factory.
 *
 * All operators created by this factory use the same operator logic registry and
 * address book.
 */
contract OperatorFactory is IOperatorFactory {
    /**
     * The operator logic registry.
     */
    IOperatorLogicRegistry private immutable _logicRegistry;

    /**
     * The address book.
     */
    IAddressBook private immutable _addressBook;

    /**
     * Addresses of operators.
     */
    mapping(address => address) _operator;

    /**
     * Constructor.
     *
     * @param logicRegistry_ the operator logic registry
     * @param addressBook_   the address book
     */
    constructor(IOperatorLogicRegistry logicRegistry_, IAddressBook addressBook_) {
        _logicRegistry = logicRegistry_;
        _addressBook = addressBook_;
    }

    function createOperator() external returns (address) {
        address owner = msg.sender;
        if (_operator[owner] != address(0)) {
            revert OperatorAlreadyCreated();
        }
        address newOperator = address(new Operator(owner, _logicRegistry, _addressBook));
        _operator[owner] = newOperator;
        emit OperatorCreated(owner, newOperator);
        return newOperator;
    }

    function logicRegistry() external view returns (IOperatorLogicRegistry) {
        return _logicRegistry;
    }

    function addressBook() external view returns (IAddressBook) {
        return _addressBook;
    }

    function operator(address owner) external view returns (address) {
        return _operator[owner];
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import { IOperatorLogicRegistry } from "./IOperatorLogicRegistry.sol";
import { IAddressBook } from "@theorderbookdex/addressbook/contracts/interfaces/IAddressBook.sol";

/**
 * Operator factory.
 *
 * All operators created by this factory use the same operator logic registry and
 * address book.
 */
interface IOperatorFactory {
    /**
     * Event emitted when an operator is created.
     *
     * @param owner     the owner of the operator
     * @param operator  the address of the operator
     */
    event OperatorCreated(address owner, address operator);

    /**
     * Error thrown when trying to create an operator and the caller has created
     * one already.
     */
    error OperatorAlreadyCreated();

    /**
     * Create an operator.
     *
     * Will fail if the caller has already created an operator.
     *
     * @return the address of the operator
     */
    function createOperator() external returns (address);

    /**
     * The operator logic registry.
     *
     * @return the operator logic registry
     */
    function logicRegistry() external view returns (IOperatorLogicRegistry);

    /**
     * The address book.
     *
     * @return the address book
     */
    function addressBook() external view returns (IAddressBook);

    /**
     * Addresses of operators.
     *
     * @param owner the owner of the operator
     * @return      the address of the operator
     */
    function operator(address owner) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * Registry of OperatorLogic for each orderbook version.
 *
 * Once a version has been registered, it cannot be changed.
 */
interface IOperatorLogicRegistry {
    /**
     * Register the OperatorLogic of an orderbook version.
     *
     * Once a version has been registered, it cannot be changed.
     *
     * @param version the orderbook version
     * @param logic   the address of the OperatorLogic
     */
    function register(uint32 version, address logic) external;

    /**
     * The owner of the registry (the deployer).
     *
     * @return the owner of the registry (the deployer)
     */
    function owner() external view returns(address);

    /**
     * The operator logic registry.
     *
     * @param version the orderbook version
     * @return the address of the operator logic
     */
    function operatorLogic(uint32 version) external view returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Contract that keeps an address book.
 *
 * The address book maps addresses to 32 bits ids so that they can be used to reference
 * an address using less data.
 */
interface IAddressBook {
    /**
     * Event emitted when an address is registered in the address book.
     *
     * @param addr  the address
     * @param id    the id
     */
    event Registered(address indexed addr, uint40 indexed id);

    /**
     * Error thrown when an address has already been registered.
     */
    error AlreadyRegistered();

    /**
     * Register the address of the caller in the address book.
     *
     * @return  the id
     */
    function register() external returns (uint40);

    /**
     * The id of the last registered address.
     *
     * @return  the id of the last registered address
     */
    function lastId() external view returns (uint40);

    /**
     * The id matching an address.
     *
     * @param  addr the address
     * @return      the id
     */
    function id(address addr) external view returns (uint40);

    /**
     * The address matching an id.
     *
     * @param  id   the id
     * @return      the address
     */
    function addr(uint40 id) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import { IOperatorBase, ERC20AndAmount } from "./interfaces/IOperatorBase.sol";
import { IOperatorLogicRegistry } from "./interfaces/IOperatorLogicRegistry.sol";
import { IAddressBook } from "@theorderbookdex/addressbook/contracts/interfaces/IAddressBook.sol";
import { IOrderbook } from "@theorderbookdex/orderbook-dex/contracts/interfaces/IOrderbook.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// TODO add withdrawERC721
// TODO add withdrawERC1155

/**
 * Operator.
 *
 * This contract interacts with orderbooks on behalf of an user, providing
 * a more user friendly interface. It acts as wallet for assets to be traded,
 * the user has to transfer the funds they want to trade with to the operator.
 *
 * All functions can only be called by the owner.
 */
contract Operator is IOperatorBase {
    using Address for address;

    /**
     * The owner of the operator.
     */
    address private immutable _owner;

    /**
     * The operator logic registry used by the operator.
     */
    IOperatorLogicRegistry private immutable _logicRegistry;

    /**
     * Constructor.
     *
     * The operator registers itself to the address book on creation.
     *
     * @param owner_         the owner of the operator
     * @param logicRegistry_ the operator logic registry used by the operator
     * @param addressBook    the address book
     */
    constructor(address owner_, IOperatorLogicRegistry logicRegistry_, IAddressBook addressBook) {
        _owner = owner_;
        _logicRegistry = logicRegistry_;
        addressBook.register();
    }

    function withdrawERC20(ERC20AndAmount[] calldata tokensAndAmounts) external {
        if (msg.sender != _owner) {
            revert Unauthorized();
        }
        for (uint256 i = 0; i < tokensAndAmounts.length; i++) {
            tokensAndAmounts[i].token.transfer(msg.sender, tokensAndAmounts[i].amount);
        }
    }

    function owner() external view returns(address) {
        return _owner;
    }

    function logicRegistry() external view returns(IOperatorLogicRegistry) {
        return _logicRegistry;
    }

    fallback(bytes calldata input) external returns (bytes memory) {
        if (msg.sender != _owner) {
            revert Unauthorized();
        }
        // First argument should always be the orderbook address
        IOrderbook orderbook = IOrderbook(abi.decode(input[4:], (address)));
        // Get the operator logic for the orderbook version
        address operatorLogic = _logicRegistry.operatorLogic(orderbook.version());
        if (operatorLogic == address(0)) {
            revert OrderbookVersionNotSupported();
        }
        return operatorLogic.functionDelegateCall(input);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import { IOperatorLogicRegistry } from "./IOperatorLogicRegistry.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * A ERC20 token and amount tuple.
 */
struct ERC20AndAmount {
    IERC20 token;
    uint256 amount;
}

/**
 * Operator base functionality.
 *
 * These are all the functions that the operator must provide itself, not proxy
 * to the OperatorLogic.
 */
interface IOperatorBase {
    /**
     * Error thrown when a function is called by someone not allowed to.
     */
    error Unauthorized();

    /**
     * Error thrown when the orderbook version is not yet supported by the operator.
     */
    error OrderbookVersionNotSupported();

    /**
     * Withdraw ERC20 tokens from the operator.
     *
     * @param tokensAndAmounts the tokens and amounts to withdraw
     */
    function withdrawERC20(ERC20AndAmount[] calldata tokensAndAmounts) external;

    /**
     * The owner of the operator.
     *
     * @return the owner of the operator
     */
    function owner() external view returns(address);

    /**
     * The operator logic registry used by the operator.
     *
     * @return the operator logic registry used by the operator
     */
    function logicRegistry() external view returns(IOperatorLogicRegistry);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * Orderbook exchange for a token pair.
 */
interface IOrderbook {
    /**
     * The orderbook version.
     *
     * From right to left, the first two digits is the patch version, the second two digits the minor version,
     * and the rest is the major version, for example the value 10203 corresponds to version 1.2.3.
     *
     * @return the orderbook version
     */
    function version() external view returns (uint32);

    /**
     * The token being traded.
     *
     * @return  the token being traded
     */
    function tradedToken() external view returns (IERC20);

    /**
     * The token given in exchange and used for pricing.
     *
     * @return  the token given in exchange and used for pricing
     */
    function baseToken() external view returns (IERC20);

    /**
     * The size of a contract in tradedToken.
     *
     * @return  the size of a contract in tradedToken
     */
    function contractSize() external view returns (uint256);

    /**
     * The price tick in baseToken.
     *
     * All prices are multiples of this value.
     *
     * @return  the price tick in baseToken
     */
    function priceTick() external view returns (uint256);
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