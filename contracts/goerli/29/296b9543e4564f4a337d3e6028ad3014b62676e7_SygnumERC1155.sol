/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

/**
 * @title SygnumERC1155
 * @author Team 3301 <[email protected]>
 * @dev Implementation of the ERC1155 standard with permissioned minting and custom supply logic.
 */
pragma solidity 0.8.8;

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */

contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Error: "Initializable: Contract instance has already been initialized"
     */
    error InitializableContractAlreadyInitialized();

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        if (!initializing && !isConstructor() && initialized) revert InitializableContractAlreadyInitialized();

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    function isInitialized() public view virtual returns (bool) {
        return initialized;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

/**
 * @title Pausable
 * @author Team 3301 <[email protected]>
 * @dev Contract module which allows children to implement an emergency stop
 *      mechanism that can be triggered by an authorized account in the TraderOperatorable
 *      contract.
 */

/**
 * @title TraderOperatorable
 * @author Team 3301 <[email protected]>
 * @dev TraderOperatorable contract stores TraderOperators contract address, and modifiers for
 *      contracts.
 */

/**
 * @title ITraderOperators
 * @notice Interface for TraderOperators contract
 */

abstract contract ITraderOperators {
    function isTrader(address _account) external view virtual returns (bool);

    function addTrader(address _account) external virtual;

    function removeTrader(address _account) external virtual;
}

/**
 * @title Operatorable
 * @author Team 3301 <[email protected]>
 * @dev Operatorable contract stores the BaseOperators contract address, and modifiers for
 *       contracts.
 */

/**
 * @title IBaseOperators
 * @notice Interface for BaseOperators contract
 */

interface IBaseOperators {
    function isOperator(address _account) external view returns (bool);

    function isAdmin(address _account) external view returns (bool);

    function isSystem(address _account) external view returns (bool);

    function isRelay(address _account) external view returns (bool);

    function isMultisig(address _contract) external view returns (bool);

    function confirmFor(address _address) external;

    function addOperator(address _account) external;

    function removeOperator(address _account) external;

    function addAdmin(address _account) external;

    function removeAdmin(address _account) external;

    function addSystem(address _account) external;

    function removeSystem(address _account) external;

    function addRelay(address _account) external;

    function removeRelay(address _account) external;

    function addOperatorAndAdmin(address _account) external;

    function removeOperatorAndAdmin(address _account) external;
}

contract Operatorable is Initializable {
    IBaseOperators internal operatorsInst;
    address private operatorsPending;

    /**
     * @dev Error: "Operatorable: caller does not have the operator role"
     */
    error OperatorableCallerNotOperator();

    /**
     * @dev Error: "Operatorable: caller does not have the admin role"
     */
    error OperatorableCallerNotAdmin();

    /**
     * @dev Error: "Operatorable: caller does not have the system role"
     */
    error OperatorableCallerNotSystem();

    /**
     * @dev Error: "Operatorable: caller does not have the multisig role"
     */
    error OperatorableCallerNotMultisig();

    /**
     * @dev Error: "Operatorable: caller does not have the admin or system role"
     */
    error OperatorableCallerNotAdminOrSystem();

    /**
     * @dev Error: "Operatorable: caller does not have the operator role nor system"
     */
    error OperatorableCallerNotOperatorOrSystem();

    /**
     * @dev Error: "Operatorable: caller does not have the relay role"
     */
    error OperatorableCallerNotRelay();

    /**
     * @dev Error: "Operatorable: caller does not have the operator role nor relay"
     */
    error OperatorableCallerNotOperatorOrRelay();

    /**
     * @dev Error: "Operatorable: caller does not have the admin role nor relay"
     */
    error OperatorableCallerNotAdminOrRelay();

    /**
     * @dev Error: "Operatorable: caller does not have the operator role nor system nor relay"
     */
    error OperatorableCallerNotOperatorOrSystemOrRelay();

    /**
     * @dev Error: "OperatorableCallerNotOperator() nor admin nor relay"
     */
    error OperatorableCallerNotOperatorOrAdminOrRelay();

    /**
     * @dev Error: "Operatorable: address of new operators contract can not be zero"
     */
    error OperatorableNewOperatorsZeroAddress();

    /**
     * @dev Error: "Operatorable: should be called from new operators contract"
     */
    error OperatorableCallerNotOperatorsContract(address _caller);

    event OperatorsContractChanged(address indexed caller, address indexed operatorsAddress);
    event OperatorsContractPending(address indexed caller, address indexed operatorsAddress);

    /**
     * @dev Reverts if sender does not have operator role associated.
     */
    modifier onlyOperator() {
        if (!isOperator(msg.sender)) revert OperatorableCallerNotOperator();
        _;
    }

    /**
     * @dev Reverts if sender does not have admin role associated.
     */
    modifier onlyAdmin() {
        if (!isAdmin(msg.sender)) revert OperatorableCallerNotAdmin();
        _;
    }

    /**
     * @dev Reverts if sender does not have system role associated.
     */
    modifier onlySystem() {
        if (!isSystem(msg.sender)) revert OperatorableCallerNotSystem();
        _;
    }

    /**
     * @dev Reverts if sender does not have multisig privileges.
     */
    modifier onlyMultisig() {
        if (!isMultisig(msg.sender)) revert OperatorableCallerNotMultisig();
        _;
    }

    /**
     * @dev Reverts if sender does not have admin or system role associated.
     */
    modifier onlyAdminOrSystem() {
        if (!isAdminOrSystem(msg.sender)) revert OperatorableCallerNotAdminOrSystem();
        _;
    }

    /**
     * @dev Reverts if sender does not have operator or system role associated.
     */
    modifier onlyOperatorOrSystem() {
        if (!isOperatorOrSystem(msg.sender)) revert OperatorableCallerNotOperatorOrSystem();
        _;
    }

    /**
     * @dev Reverts if sender does not have the relay role associated.
     */
    modifier onlyRelay() {
        if (!isRelay(msg.sender)) revert OperatorableCallerNotRelay();
        _;
    }

    /**
     * @dev Reverts if sender does not have relay or operator role associated.
     */
    modifier onlyOperatorOrRelay() {
        if (!isOperator(msg.sender) && !isRelay(msg.sender)) revert OperatorableCallerNotOperatorOrRelay();
        _;
    }

    /**
     * @dev Reverts if sender does not have relay or admin role associated.
     */
    modifier onlyAdminOrRelay() {
        if (!isAdmin(msg.sender) && !isRelay(msg.sender)) revert OperatorableCallerNotAdminOrRelay();
        _;
    }

    /**
     * @dev Reverts if sender does not have the operator, or system, or relay role associated.
     */
    modifier onlyOperatorOrSystemOrRelay() {
        if (!isOperator(msg.sender) && !isSystem(msg.sender) && !isRelay(msg.sender))
            revert OperatorableCallerNotOperatorOrSystemOrRelay();
        _;
    }

    /**
     * @dev Reverts if sender does not have the operator, or admin, or relay role associated.
     */
    modifier onlyOperatorOrAdminOrRelay() {
        if (!isOperator(msg.sender) && !isAdmin(msg.sender) && !isRelay(msg.sender))
            revert OperatorableCallerNotOperatorOrAdminOrRelay();
        _;
    }

    /**
     * @dev Initialization instead of constructor, called once. The setOperatorsContract function can be called only by Admin role with
     *       confirmation through the operators contract.
     * @param _baseOperators BaseOperators contract address.
     */
    function initialize(address _baseOperators) public virtual initializer {
        _setOperatorsContract(_baseOperators);
    }

    /**
     * @dev Set the new the address of Operators contract, should be confirmed from operators contract by calling confirmFor(addr)
     *       where addr is the address of current contract instance. This is done to prevent the case when the new contract address is
     *       broken and control of the contract can be lost in such case
     * @param _baseOperators BaseOperators contract address.
     */
    function setOperatorsContract(address _baseOperators) public onlyAdmin {
        if (_baseOperators == address(0)) revert OperatorableNewOperatorsZeroAddress();

        operatorsPending = _baseOperators;
        emit OperatorsContractPending(msg.sender, _baseOperators);
    }

    /**
     * @dev The function should be called from new operators contract by admin to ensure that operatorsPending address
     *       is the real contract address.
     */
    function confirmOperatorsContract() public {
        if (operatorsPending == address(0)) revert OperatorableNewOperatorsZeroAddress();

        if (msg.sender != operatorsPending) revert OperatorableCallerNotOperatorsContract(msg.sender);

        _setOperatorsContract(operatorsPending);
    }

    /**
     * @return The address of the BaseOperators contract.
     */
    function getOperatorsContract() public view returns (address) {
        return address(operatorsInst);
    }

    /**
     * @return The pending address of the BaseOperators contract.
     */
    function getOperatorsPending() public view returns (address) {
        return operatorsPending;
    }

    /**
     * @return If '_account' has operator privileges.
     */
    function isOperator(address _account) public view returns (bool) {
        return operatorsInst.isOperator(_account);
    }

    /**
     * @return If '_account' has admin privileges.
     */
    function isAdmin(address _account) public view returns (bool) {
        return operatorsInst.isAdmin(_account);
    }

    /**
     * @return If '_account' has system privileges.
     */
    function isSystem(address _account) public view returns (bool) {
        return operatorsInst.isSystem(_account);
    }

    /**
     * @return If '_account' has relay privileges.
     */
    function isRelay(address _account) public view returns (bool) {
        return operatorsInst.isRelay(_account);
    }

    /**
     * @return If '_contract' has multisig privileges.
     */
    function isMultisig(address _contract) public view returns (bool) {
        return operatorsInst.isMultisig(_contract);
    }

    /**
     * @return If '_account' has admin or system privileges.
     */
    function isAdminOrSystem(address _account) public view returns (bool) {
        return (operatorsInst.isAdmin(_account) || operatorsInst.isSystem(_account));
    }

    /**
     * @return If '_account' has operator or system privileges.
     */
    function isOperatorOrSystem(address _account) public view returns (bool) {
        return (operatorsInst.isOperator(_account) || operatorsInst.isSystem(_account));
    }

    /** INTERNAL FUNCTIONS */
    function _setOperatorsContract(address _baseOperators) internal {
        if (_baseOperators == address(0)) revert OperatorableNewOperatorsZeroAddress();

        operatorsInst = IBaseOperators(_baseOperators);
        emit OperatorsContractChanged(msg.sender, _baseOperators);
    }
}

contract TraderOperatorable is Operatorable {
    ITraderOperators internal traderOperatorsInst;
    address private traderOperatorsPending;

    /**
     * @dev Error: "TraderOperatorable: caller is not trader"
     */
    error TraderOperatorableCallerNotTrader();

    /**
     * @dev Error: "TraderOperatorable: caller is not trader or operator or system"
     */
    error TraderOperatorableCallerNotTraderOrOperatorOrSystem();

    /**
     * @dev Error: "TraderOperatorable: address of new traderOperators contract can not be zero"
     */
    error TraderOperatorableNewTraderOperatorsAddressZero();

    /**
     * @dev Error: "TraderOperatorable: address of pending traderOperators contract can not be zero"
     */
    error TraderOperatorablePendingTraderOperatorsAddressZero();

    /**
     * @dev Error: "TraderOperatorable: should be called from new traderOperators contract"
     */
    error TraderOperatorableCallerNotNewTraderOperator();

    event TraderOperatorsContractChanged(address indexed caller, address indexed traderOperatorsAddress);
    event TraderOperatorsContractPending(address indexed caller, address indexed traderOperatorsAddress);

    /**
     * @dev Reverts if sender does not have the trader role associated.
     */
    modifier onlyTrader() {
        if (!isTrader(msg.sender)) revert TraderOperatorableCallerNotTrader();
        _;
    }

    /**
     * @dev Reverts if sender does not have the operator or trader role associated.
     */
    modifier onlyOperatorOrTraderOrSystem() {
        if (!isOperator(msg.sender) && !isTrader(msg.sender) && !isSystem(msg.sender))
            revert TraderOperatorableCallerNotTraderOrOperatorOrSystem();
        _;
    }

    /**
     * @dev Initialization instead of constructor, called once. The setTradersOperatorsContract function can be called only by Admin role with
     * confirmation through the operators contract.
     * @param _baseOperators BaseOperators contract address.
     * @param _traderOperators TraderOperators contract address.
     */
    function initialize(address _baseOperators, address _traderOperators) public virtual initializer {
        super.initialize(_baseOperators);
        _setTraderOperatorsContract(_traderOperators);
    }

    /**
     * @dev Set the new the address of Operators contract, should be confirmed from operators contract by calling confirmFor(addr)
     * where addr is the address of current contract instance. This is done to prevent the case when the new contract address is
     * broken and control of the contract can be lost in such case
     * @param _traderOperators TradeOperators contract address.
     */
    function setTraderOperatorsContract(address _traderOperators) public onlyAdmin {
        if (_traderOperators == address(0)) revert TraderOperatorableNewTraderOperatorsAddressZero();

        traderOperatorsPending = _traderOperators;
        emit TraderOperatorsContractPending(msg.sender, _traderOperators);
    }

    /**
     * @dev The function should be called from new operators contract by admin to insure that traderOperatorsPending address
     *       is the real contract address.
     */
    function confirmTraderOperatorsContract() public {
        if (traderOperatorsPending == address(0)) revert TraderOperatorablePendingTraderOperatorsAddressZero();
        if (msg.sender != traderOperatorsPending) revert TraderOperatorableCallerNotNewTraderOperator();

        _setTraderOperatorsContract(traderOperatorsPending);
    }

    /**
     * @return The address of the TraderOperators contract.
     */
    function getTraderOperatorsContract() public view returns (address) {
        return address(traderOperatorsInst);
    }

    /**
     * @return The pending TraderOperators contract address
     */
    function getTraderOperatorsPending() public view returns (address) {
        return traderOperatorsPending;
    }

    /**
     * @return If '_account' has trader privileges.
     */
    function isTrader(address _account) public view returns (bool) {
        return traderOperatorsInst.isTrader(_account);
    }

    /** INTERNAL FUNCTIONS */
    function _setTraderOperatorsContract(address _traderOperators) internal {
        if (_traderOperators == address(0)) revert TraderOperatorableNewTraderOperatorsAddressZero();

        traderOperatorsInst = ITraderOperators(_traderOperators);
        emit TraderOperatorsContractChanged(msg.sender, _traderOperators);
    }
}

abstract contract Pausable is TraderOperatorable {
    bool internal _paused;

    /**
     * @dev Error: "Pausable: paused"
     */
    error PausablePaused();

    /**
     * @dev Error: "Pausable: not paused"
     */
    error PausableNotPaused();

    event Paused(address indexed account);
    event Unpaused(address indexed account);

    // solhint-disable-next-line func-visibility
    constructor() {
        _paused = false;
    }

    /**
     * @dev Reverts if contract is paused.
     */
    modifier whenNotPaused() {
        if (_paused) revert PausablePaused();
        _;
    }

    /**
     * @dev Reverts if contract is paused.
     */
    modifier whenPaused() {
        if (!_paused) revert PausableNotPaused();
        _;
    }

    /**
     * @dev Called by operator to pause child contract. The contract
     *      must not already be paused.
     */
    function pause() public virtual onlyOperatorOrTraderOrSystem whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /** @dev Called by operator to pause child contract. The contract
     *       must already be paused.
     */
    function unpause() public virtual onlyOperatorOrTraderOrSystem whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @return If child contract is already paused or not.
     */
    function isPaused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @return If child contract is not paused.
     */
    function isNotPaused() public view virtual returns (bool) {
        return !_paused;
    }
}

/**
 * @title Sygnum implementation for the ERC1155 specification
 * @author Team 3301 <[email protected]>
 * @dev ERC1155 implementation with max token supplies in bytes hex format, initializer for proxy support,
 * as well as support for admin and operator roles
 */
contract SygnumERC1155 is Initializable, Operatorable, Pausable, ERC1155 {
    using Strings for uint256;

    event Initialized(uint256 _maxUniqueTokens, string _baseUri);

    error SygnumERC1155MintingNotStarted();
    error SygnumERC1155MintingEnded();
    error SygnumERC1155AmountExceedsMaxSupply();
    error SygnumERC1155InvalidTokenID();

    address public royaltyRecipient;
    mapping(uint256 => uint256) public tokenSupply;
    string public baseUri;

    // Launch date and minting period
    uint256 public startDate;
    uint256 public mintDuration;

    // Max amount of unique tokens
    uint256 public maxUniqueTokens;
    // Max amount of copies per token
    bytes public encodedMaxTokenSupplies;

    /**
     * @dev Function returning the maximum supply for a specific token ID, decoding it from the bytes hex format
     * @param tokenId The token ID
     * @return res The maximum supply for tokenId
     */
    function maxTokenSupply(uint256 tokenId) public view virtual returns (uint256 res) {
        res = uint16(
            bytes2(abi.encodePacked(encodedMaxTokenSupplies[2 * tokenId], encodedMaxTokenSupplies[2 * tokenId + 1]))
        );
    }

    /**
     * @dev Implements the safeTransferFrom function while checking whether the contract is paused
     * @param from Sender account
     * @param to Recipient account
     * @param id Token ID
     * @param amount Amount of tokens to send
     * @param data Calldata to pass if recipient is contract
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual override whenNotPaused {
        ERC1155.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev Implements the safeBatchTransferFrom function while checking whether the contract is paused
     * @param from Sender account
     * @param to Recipient account
     * @param ids Array of token IDs
     * @param amounts Array of amounts to send for each token
     * @param data Calldata to pass if recipient is contract
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override whenNotPaused {
        ERC1155.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Minting function which limits calls to operator accounts only
     * @param to Recipient account
     * @param id Token ID
     * @param amount Amount of tokens to mint
     * @param data Calldata to pass if recipient is contract
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external virtual onlyOperator {
        _mint(to, id, amount, data);
    }

    /**
     * @dev Batch minting function which limits calls to operator accounts only
     * @param to Recipient account
     * @param ids Array of token IDs
     * @param amounts Array of amounts to mint for each token
     * @param data Calldata to pass if recipient is contract
     */
    function batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external virtual onlyOperator {
        _batchMint(to, ids, amounts, data);
    }

    /**
     * @dev Internal minting function which limits minting to specified period (if startDate is 0, then mint is
     * always open, if mintDuration is 0 then sale is open-ended). Also checks whether token ID is valid and
     * whether minting exceeds max token supply
     * @param to Recipient account
     * @param id Token ID
     * @param amount Amount of tokens to mint
     * @param data Calldata to pass if recipient is contract
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        if (startDate > 0) {
            if (block.timestamp < startDate) revert SygnumERC1155MintingNotStarted();
            if (mintDuration > 0) {
                if (block.timestamp >= startDate + mintDuration) revert SygnumERC1155MintingEnded();
            }
        }

        if (id >= maxUniqueTokens) revert SygnumERC1155InvalidTokenID();
        if (tokenSupply[id] + amount > maxTokenSupply(id)) revert SygnumERC1155AmountExceedsMaxSupply();

        tokenSupply[id] += amount;
        ERC1155._mint(to, id, amount, data);
    }

    /**
     * @dev Internal batch minting function which limits minting to specified period (if startDate is 0, then mint
     * is always open, if mintDuration is 0 then sale is open-ended). Also checks whether token IDs are valid and
     * whether minting exceeds max token supply for each token
     * @param to Recipient account
     * @param ids Array of token IDs
     * @param amounts Array of amounts to mint for each token
     * @param data Calldata to pass if recipient is contract
     */
    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        if (startDate > 0) {
            if (block.timestamp < startDate) revert SygnumERC1155MintingNotStarted();
            if (mintDuration > 0) {
                if (block.timestamp >= startDate + mintDuration) revert SygnumERC1155MintingEnded();
            }
        }

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            if (id >= maxUniqueTokens) revert SygnumERC1155InvalidTokenID();
            if (tokenSupply[id] + amount > maxTokenSupply(id)) revert SygnumERC1155AmountExceedsMaxSupply();

            tokenSupply[id] += amount;
        }

        ERC1155._batchMint(to, ids, amounts, data);
    }

    /**
     * @dev Initializer for proxy use
     * @param _encodedMaxTokenSupplies max token supplies encoded in bytes hex format (one byte per token)
     * @param _royaltyRecipient address defined to receive royalty payments from secondary marketplaces
     * @param _baseOperators address of the BaseOperators contract (defined in solidity-base-contracts)
     * @param _baseUri base URI directing to the IPFS token data
     * @param _startDate start date for mint. If 0, then mint is always open
     * @param _mintDuration duration of the mint. If 0, then sale is open-ended starting on _startDate
     */
    function initialize(
        bytes calldata _encodedMaxTokenSupplies,
        address _royaltyRecipient,
        address _baseOperators,
        string memory _baseUri,
        uint256 _startDate,
        uint256 _mintDuration
    ) public initializer {
        encodedMaxTokenSupplies = _encodedMaxTokenSupplies;
        maxUniqueTokens = _encodedMaxTokenSupplies.length / 2;

        royaltyRecipient = _royaltyRecipient;
        baseUri = _baseUri;

        startDate = _startDate;
        mintDuration = _mintDuration;

        Operatorable.initialize(_baseOperators);
        emit Initialized(_encodedMaxTokenSupplies.length, _baseUri);
    }

    /**
     * @dev Function returning the URI to access token metadata
     * @param tokenId The token ID
     * @return string The corresponding URI in string format
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId < maxUniqueTokens, "SygnumERC1155: URI query for nonexistent token");

        string memory baseURI = baseUri;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }
}