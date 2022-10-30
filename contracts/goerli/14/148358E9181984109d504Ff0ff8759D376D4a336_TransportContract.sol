// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author Robert Rongen for Smartys
/// @title Escrow contract for temperature monitored transport

import "@openzeppelin/contracts/interfaces/IERC777.sol";   
import "@openzeppelin/contracts/interfaces/IERC777Recipient.sol";   
import "@openzeppelin/contracts/interfaces/IERC777Sender.sol";   
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/utils/introspection/ERC1820Implementer.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TransportContract is IERC777Recipient, IERC777Sender, ERC1820Implementer {

    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    bytes32 constant public TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    IERC777 public smartysToken;
    using SafeMath for uint256;

    constructor (IERC777 tokenAddress) {
        smartysToken = IERC777(tokenAddress);
        _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    }

    function senderFor(address account) public {
        _registerInterfaceForAddress(TOKENS_SENDER_INTERFACE_HASH, account);
    }


    function bytesToUint(bytes memory userData) public pure returns (uint256 number) {
        number=0;
        for(uint i=0;i<userData.length;i++){
            number *= 256;
            number += uint(uint8(userData[i]));
        }
    }

    function uintToBytes(uint256 input) public pure returns (bytes memory output) {
        output = new bytes(32);
        for (uint i = 0; i < 32; i++) {
            output[i] = bytes1(uint8(input / (2**(8*(31 - i))))); 
        }
    }

    event DoneStuff(address operator, address from, address to, uint256 amount, bytes userData, bytes operatorData);

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) public {
        emit DoneStuff(operator, from, to, amount, userData, operatorData);
    }

    uint256 public transportID;
    bool transportDepositPaid = false;
    bool temperatureDepositPaid = false;
    bool goodsReceived = false;
    // bool sensorRegistered = false;
    bool transportEnded = false;
    bool clientQuits = false;
    bool supplierQuits = false;
    bool carrierQuits = false;

    struct TransportSteps {
        bool transportDepositPaid;
        bool temperatureDepositPaid;
        bool goodsReceived;
        bool transportEnded;
        bool sensorRegistered;
        bool clientQuits;
        bool supplierQuits;
        bool carrierQuits;
    }

    struct TransportConditions {
        int depositTempLow;
        int depositTempHigh;
        uint256 transportDeposit;
        uint256 temperatureDeposit;
        int minTemp;
        int maxTemp;
    }

    struct TransportData {
        string sessionUuid;
        uint256 orderID;
        address client;
        address supplier;
        address carrier;
        string sensorID; 
        TransportConditions conditions;
        TransportSteps step;
    }
    mapping (uint256 => TransportData) public transports;
    uint256[] public transportIDs;

    /// @notice Register transport parameters and store in struct
    /// @return	TransportID that is increased by 1 for every new transport registered
    event newTransport(uint256 transportID);
    function defineTransport(
        string memory _sessionUuid,
        uint256 _orderID,
        address _client_address,
        address _carrier_address,
        int _depositTempLow,
        int _depositTempHigh,
        uint256 _transportDeposit,
        uint256 _temperatureDeposit
    )
    public {
        require(_depositTempHigh - _depositTempLow >= 1, "Invalid condition: TempHigh is lower than TempLow");
        transportID++;
        transports[transportID].sessionUuid = _sessionUuid;
        transports[transportID].orderID = _orderID;
        transports[transportID].supplier = msg.sender;
        transports[transportID].client = _client_address;
        transports[transportID].carrier = _carrier_address;
        transports[transportID].conditions.depositTempLow = _depositTempLow;
        transports[transportID].conditions.depositTempHigh = _depositTempHigh;
        transports[transportID].conditions.transportDeposit = _transportDeposit;
        transports[transportID].conditions.temperatureDeposit = _temperatureDeposit;
        transportIDs.push(transportID);
        
        emit newTransport(transportID);
    }

    function getTransportIDs() view public returns(uint256[] memory){
        return transportIDs;
    }

    event orderDeposited(string text, uint transportID);
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external {
        require(msg.sender == address(smartysToken), "Simple777Recipient: Invalid token");
        emit DoneStuff(operator, from, to, amount, userData, operatorData);

        uint256 _transportID = bytesToUint(userData);
        emit orderDeposited("transportID", _transportID);

        registerDeposit(_transportID, from, amount);
    }

    event supplierDeposited(uint256 _transportID, bool _supplierDeposited);
    event carrierDeposited(uint256 _transportID, bool _carrierDeposited);
    function registerDeposit(uint256 _transportID, address _from, uint256 _amountReceived)  public {
        // check conditions
        require(transports[_transportID].step.transportEnded != true, "Order is already ended.");
 
        if (_from == transports[_transportID].supplier) {
            require(transports[_transportID].step.transportDepositPaid != true, "Deposit is already paid.");
            require(_amountReceived == transports[_transportID].conditions.transportDeposit, "Amount does not equal transport deposit set for this contract.");
            // register deposit
            transports[_transportID].step.transportDepositPaid = true;
            emit supplierDeposited(_transportID, transports[_transportID].step.transportDepositPaid);


        } else if (_from == transports[_transportID].carrier) {
            require(transports[_transportID].step.temperatureDepositPaid != true, "Deposit is already paid.");
            require(_amountReceived == transports[_transportID].conditions.temperatureDeposit, "Amount does not equal temperature deposit set for this contract.");
            // register deposit
            transports[_transportID].step.temperatureDepositPaid = true;
            emit carrierDeposited(_transportID, transports[_transportID].step.temperatureDepositPaid);

        } else {
            revert("Deposit not send by supplier or carrier");
        }
    }

    event SensorRegistered(bool _transportEnded);
    function quitTransport(uint256 _transportID, string memory _sensorID) internal {
        transports[_transportID].sensorID = _sensorID;
        transports[_transportID].step.sensorRegistered = true;
        emit SensorRegistered(transports[_transportID].step.sensorRegistered);
    }

    event TransportEnded(bool _transportEnded);
    function setTransportResults(bytes memory userData, int _minTemp, int _maxTemp) public {
        uint256 _transportID = bytesToUint(userData);
        address _client = transports[_transportID].client;
        address _carrier = transports[_transportID].carrier;
        uint256 _totalDeposit;
        int minTemp = _minTemp;
        int maxTemp = _maxTemp;

        require(msg.sender == transports[_transportID].client, "Only client can call this function.");
        require(transports[_transportID].step.goodsReceived == false, "Transport result already executed.");
        require(transports[_transportID].step.transportDepositPaid == true, "Escrow not paid by client for this transport.");
        require(transports[_transportID].step.temperatureDepositPaid == true, "Escrow not paid by carrier for this transport.");

        transports[_transportID].conditions.minTemp = minTemp;
        transports[_transportID].conditions.maxTemp = maxTemp;
        transports[_transportID].step.goodsReceived = true;

        if (_maxTemp < transports[_transportID].conditions.depositTempHigh && _minTemp > transports[_transportID].conditions.depositTempLow) {
            // Scenario green
            _totalDeposit = transports[_transportID].conditions.transportDeposit.add(transports[_transportID].conditions.temperatureDeposit);
            smartysToken.send(_carrier, _totalDeposit, userData);

        } else {
            // Scenario red
            smartysToken.send(_carrier, transports[_transportID].conditions.transportDeposit, userData);
            smartysToken.send(_client, transports[_transportID].conditions.temperatureDeposit, userData);
        }

        transports[_transportID].step.transportEnded = true;

        emit TransportEnded(transports[_transportID].step.transportEnded);
    }

    function quitTransport(uint256 _transportID) internal {
        address _supplier;
        address _carrier;
        bytes memory userData = uintToBytes(_transportID);
        _supplier = transports[_transportID].supplier;
        _carrier = transports[_transportID].carrier;
 
        smartysToken.send(_carrier, transports[_transportID].conditions.temperatureDeposit, userData);
        smartysToken.send(_supplier, transports[_transportID].conditions.transportDeposit, userData);
        transports[_transportID].step.transportEnded = true;
        emit TransportEnded(transports[_transportID].step.transportEnded);
    }

    function clientQuitsTransport(uint256 _transportID) public {
        require(msg.sender == transports[_transportID].client, "Only client can call this function.");
        transports[_transportID].step.clientQuits = true;
        if (
            (transports[_transportID].step.carrierQuits == true
            || transports[_transportID].step.supplierQuits == true
            ) && transports[_transportID].step.transportEnded != true
        ) {
        quitTransport(_transportID);
        }
    }

    function carrierQuitsTransport(uint256 _transportID) public {
        require(msg.sender == transports[_transportID].carrier, "Only carrier can call this function.");
        transports[_transportID].step.carrierQuits = true;
        if (
                (transports[_transportID].step.clientQuits == true
                || transports[_transportID].step.supplierQuits == true
                ) && transports[_transportID].step.transportEnded != true
        ) {
        quitTransport(_transportID);
        }
    }

    function supplierQuitsTransport(uint256 _transportID) public {
        require(msg.sender == transports[_transportID].supplier, "Only supplier can call this function.");
        transports[_transportID].step.supplierQuits = true;
        if (
                (transports[_transportID].step.clientQuits == true
                || transports[_transportID].step.carrierQuits == true
                ) && transports[_transportID].step.transportEnded != true
        ) {
            quitTransport(_transportID);
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC1820Implementer.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for an ERC1820 implementer, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820#interface-implementation-erc1820implementerinterface[EIP].
 * Used by contracts that will be registered as implementers in the
 * {IERC1820Registry}.
 */
interface IERC1820Implementer {
    /**
     * @dev Returns a special value (`ERC1820_ACCEPT_MAGIC`) if this contract
     * implements `interfaceHash` for `account`.
     *
     * See {IERC1820Registry-setInterfaceImplementer}.
     */
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address account) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC1820Implementer.sol)

pragma solidity ^0.8.0;

import "./IERC1820Implementer.sol";

/**
 * @dev Implementation of the {IERC1820Implementer} interface.
 *
 * Contracts may inherit from this and call {_registerInterfaceForAddress} to
 * declare their willingness to be implementers.
 * {IERC1820Registry-setInterfaceImplementer} should then be called for the
 * registration to be complete.
 */
contract ERC1820Implementer is IERC1820Implementer {
    bytes32 private constant _ERC1820_ACCEPT_MAGIC = keccak256("ERC1820_ACCEPT_MAGIC");

    mapping(bytes32 => mapping(address => bool)) private _supportedInterfaces;

    /**
     * @dev See {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address account)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        return _supportedInterfaces[interfaceHash][account] ? _ERC1820_ACCEPT_MAGIC : bytes32(0x00);
    }

    /**
     * @dev Declares the contract as willing to be an implementer of
     * `interfaceHash` for `account`.
     *
     * See {IERC1820Registry-setInterfaceImplementer} and
     * {IERC1820Registry-interfaceHash}.
     */
    function _registerInterfaceForAddress(bytes32 interfaceHash, address account) internal virtual {
        _supportedInterfaces[interfaceHash][account] = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Sender.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensSender standard as defined in the EIP.
 *
 * {IERC777} Token holders can be notified of operations performed on their
 * tokens by having a contract implement this interface (contract holders can be
 * their own implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Sender {
    /**
     * @dev Called by an {IERC777} token contract whenever a registered holder's
     * (`from`) tokens are about to be moved or destroyed. The type of operation
     * is conveyed by `to` being the zero address or not.
     *
     * This call occurs _before_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the pre-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC777Sender.sol)

pragma solidity ^0.8.0;

import "../token/ERC777/IERC777Sender.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC777Recipient.sol)

pragma solidity ^0.8.0;

import "../token/ERC777/IERC777Recipient.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC777.sol)

pragma solidity ^0.8.0;

import "../token/ERC777/IERC777.sol";