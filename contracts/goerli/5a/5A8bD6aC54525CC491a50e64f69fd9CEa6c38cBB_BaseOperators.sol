// Sources flattened with hardhat v2.10.2 https://hardhat.org

// File contracts/role/Roles.sol

pragma solidity ^0.8.8;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Error: "Roles: account already has role"
     */
    error RolesAccountAlreadyHasRole(address _account);

    /**
     * @dev Error: "Roles: account does not have role"
     */
    error RolesAccountDoesNotHaveRole(address _account);

    /**
     * @dev Error: "Roles: account is the zero address"
     */
    error RolesAccountIsZeroAddress();

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        if (has(role, account)) revert RolesAccountAlreadyHasRole(account);
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        if (!has(role, account)) revert RolesAccountDoesNotHaveRole(account);
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        if (account == address(0)) revert RolesAccountIsZeroAddress();
        return role.bearer[account];
    }
}


// File contracts/role/interface/IBaseOperators.sol

/**
 * @title IBaseOperators
 * @notice Interface for BaseOperators contract
 */

pragma solidity ^0.8.0;

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


// File contracts/helpers/Initializable.sol

// SPDX-License-Identifier: UNLICENSED

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

pragma solidity ^0.8.0;

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


// File contracts/role/base/Operatorable.sol

/**
 * @title Operatorable
 * @author Team 3301 <[email protected]>
 * @dev Operatorable contract stores the BaseOperators contract address, and modifiers for
 *       contracts.
 */

pragma solidity 0.8.8;


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


// File contracts/role/base/BaseOperators.sol

/**
 * @title BaseOperators
 * @author Team 3301 <[email protected]>
 * @dev For managing operators, admins, and system accounts.
 */

pragma solidity ^0.8.0;


contract BaseOperators {
    using Roles for Roles.Role;

    address private _multisig;
    Roles.Role private _operators;
    Roles.Role private _admins;
    Roles.Role private _systems;
    Roles.Role private _relays;

    /**
     * @dev Error: "BaseOperators: caller does not have the admin role"
     */
    error BaseOperatorsCallerNotAdmin();

    /**
     * @dev Error: "BaseOperators: caller does not have multisig role"
     */
    error BaseOperatorsCallerNotMultisig();

    /**
     * @dev Error: "BaseOperators: caller does not have the admin role nor relay"
     */
    error BaseOperatorsCallerNotAdminOrRelay();

    /**
     * @dev Error: "BaseOperators: address cannot be empty."
     */
    error BaseOperatorsZeroAddress();

    /**
     * @dev Error: "BaseOperators: admin can not remove himself"
     */
    error BaseOperatorsAdminRemoveSelf();

    /**
     * @dev Error: "BaseOperators: cannot assign new multisig when multisig already assigned"
     */
    error BaseOperatorsMultisigAlreadyAssigned();

    /**
     * @dev Error: "BaseOperators: multisig has to be contract"
     */
    error BaseOperatorsMultisigNotContract();

    event OperatorAdded(address indexed caller, address indexed account);
    event OperatorRemoved(address indexed caller, address indexed account);
    event AdminAdded(address indexed caller, address indexed account);
    event AdminRemoved(address indexed caller, address indexed account);
    event SystemAdded(address indexed caller, address indexed account);
    event SystemRemoved(address indexed caller, address indexed account);
    event RelayAdded(address indexed caller, address indexed relay);
    event RelayRemoved(address indexed caller, address indexed relay);
    event MultisigChanged(address indexed caller, address indexed multisig);

    /**
     * @dev Reverts if caller does not have admin role associated.
     */
    modifier onlyAdmin() {
        if (!isAdmin(msg.sender)) revert BaseOperatorsCallerNotAdmin();
        _;
    }

    /**
     * @dev Reverts if caller does not have multisig privileges;
     */
    modifier onlyMultisig() {
        if (!isMultisig(msg.sender)) revert BaseOperatorsCallerNotMultisig();
        _;
    }

    /**
     * @dev Reverts if caller does not have admin or relay role associated.
     */
    modifier onlyAdminOrRelay() {
        if (!isAdmin(msg.sender) && !isRelay(msg.sender)) revert BaseOperatorsCallerNotAdminOrRelay();
        _;
    }

    constructor(address _admin) {
        _addAdmin(_admin);
    }

    /**
     * @dev Confirms operator contract address once active.
     * @param _address Operatorable contract addres.
     */
    function confirmFor(address _address) public onlyAdmin {
        if (_address == address(0)) revert BaseOperatorsZeroAddress();
        Operatorable(_address).confirmOperatorsContract();
    }

    /**
     * @return If '_account' has operator privileges.
     */
    function isOperator(address _account) public view returns (bool) {
        return _operators.has(_account);
    }

    /**
     * @dev Admin can give '_account' address operator privileges.
     * @param _account address that should be given operator privileges.
     */
    function addOperator(address _account) public onlyAdminOrRelay {
        _addOperator(_account);
    }

    /**
     * @dev Admin can revoke '_account' address operator privileges.
     * @param _account address that should be revoked operator privileges.
     */
    function removeOperator(address _account) public onlyAdminOrRelay {
        _removeOperator(_account);
    }

    /**
     * @return If '_account' has operator privileges.
     */
    function isAdmin(address _account) public view returns (bool) {
        return _admins.has(_account);
    }

    /**
     * @dev Admin can give '_account' address admin privileges.
     * @param _account address that should be given admin privileges.
     */
    function addAdmin(address _account) public onlyAdminOrRelay {
        _addAdmin(_account);
    }

    /**
     * @dev Admin can revoke '_account' address admin privileges.
     * @param _account address that should be revoked admin privileges.
     */
    function removeAdmin(address _account) public onlyAdminOrRelay {
        if (_account == msg.sender) revert BaseOperatorsAdminRemoveSelf();
        _removeAdmin(_account);
    }

    /**
     * @return If '_account' has admin or operator privileges.
     */
    function isOperatorOrAdmin(address _account) public view returns (bool) {
        return (isAdmin(_account) || isOperator(_account));
    }

    /**
     * @return If '_account' has admin and operator privileges, also known as a Super Admin.
     */
    function isOperatorAndAdmin(address _account) public view returns (bool) {
        return (isAdmin(_account) && isOperator(_account));
    }

    /**
     * @return If '_account' has system privileges.
     */
    function isSystem(address _account) public view returns (bool) {
        return _systems.has(_account);
    }

    /**
     * @dev Admin account or relay contract can give '_account' address system privileges.
     * @param _account address that should be given system privileges.
     */
    function addSystem(address _account) public onlyAdminOrRelay {
        _addSystem(_account);
    }

    /**
     * @dev Admin account or relay contract can revoke '_account' address system privileges.
     * @param _account address that should be revoked system privileges.
     */
    function removeSystem(address _account) public onlyAdminOrRelay {
        _removeSystem(_account);
    }

    /**
     * @return If '_account' has relay privileges.
     */
    function isRelay(address _account) public view returns (bool) {
        return _relays.has(_account);
    }

    /**
     * @dev Operator can give '_account' address relay privileges.
     * @param _account address that should be given relay privileges.
     */
    function addRelay(address _account) public onlyAdmin {
        _addRelay(_account);
    }

    /**
     * @dev Operator can revoke '_account' address relay privileges.
     * @param _account address that should be revoked relay privileges.
     */
    function removeRelay(address _account) public onlyAdmin {
        _removeRelay(_account);
    }

    /**
     * @return If '_contract' has multisig privileges.
     */
    function isMultisig(address _contract) public view returns (bool) {
        return _multisig == _contract;
    }

    /**
     * @dev Admin can give '_contract' address multisig privileges.
     * @param _contract address that should be given multisig privileges.
     */
    function addMultisig(address _contract) public onlyAdmin {
        if (_multisig != address(0)) revert BaseOperatorsMultisigAlreadyAssigned();
        _changeMultisig(_contract);
    }

    /**
     * @dev Multisig can change multisig privileges to new multisig '_contract'.
     * @param _contract address that should be the new multisig.
     */
    function changeMultisig(address _contract) public onlyMultisig {
        _changeMultisig(_contract);
    }

    /**
     * @dev Admin can give '_account' address operator and admin privileges making the '_account' a super admin, whereby they can call operator and admin functions.
     * @param _account address that should be given operator and admin privileges.
     */
    function addOperatorAndAdmin(address _account) public onlyAdminOrRelay {
        _addAdmin(_account);
        _addOperator(_account);
    }

    /**
     * @dev Admin can revoke '_account' address operator and admin privileges.
     * @param _account address that should be revoked operator and admin privileges.
     */
    function removeOperatorAndAdmin(address _account) public onlyAdminOrRelay {
        if (_account == msg.sender) revert BaseOperatorsAdminRemoveSelf();
        _removeAdmin(_account);
        _removeOperator(_account);
    }

    /**
     * @dev Admin can change '_account' admin privileges to an operator privileges.
     * @param _account address that should be given operator and admin privileges.
     */
    function changeToOperator(address _account) public onlyAdmin {
        if (_account == msg.sender) revert BaseOperatorsAdminRemoveSelf();
        _removeAdmin(_account);
        _addOperator(_account);
    }

    /**
     * @dev Admin can change '_account' operator privileges to admin privileges.
     * @param _account address that should be given operator and admin privileges.
     */
    function changeToAdmin(address _account) public onlyAdmin {
        _addAdmin(_account);
        _removeOperator(_account);
    }

    /** INTERNAL FUNCTIONS */
    function _addOperator(address _account) internal {
        _operators.add(_account);
        emit OperatorAdded(msg.sender, _account);
    }

    function _removeOperator(address _account) internal {
        _operators.remove(_account);
        emit OperatorRemoved(msg.sender, _account);
    }

    function _addAdmin(address _account) internal {
        _admins.add(_account);
        emit AdminAdded(msg.sender, _account);
    }

    function _removeAdmin(address _account) internal {
        _admins.remove(_account);
        emit AdminRemoved(msg.sender, _account);
    }

    function _addSystem(address _account) internal {
        _systems.add(_account);
        emit SystemAdded(msg.sender, _account);
    }

    function _removeSystem(address _account) internal {
        _systems.remove(_account);
        emit SystemRemoved(msg.sender, _account);
    }

    function _addRelay(address _account) internal {
        _relays.add(_account);
        emit RelayAdded(msg.sender, _account);
    }

    function _removeRelay(address _account) internal {
        _relays.remove(_account);
        emit RelayRemoved(msg.sender, _account);
    }

    function _changeMultisig(address _contract) internal {
        if (_contract == address(0)) revert BaseOperatorsZeroAddress();
        if (isMultisig(msg.sender)) {
            uint32 size;
            // solhint-disable-next-line
            assembly {
                size := extcodesize(_contract)
            }
            if (size == 0) revert BaseOperatorsMultisigNotContract();
        }
        _multisig = _contract;
        emit MultisigChanged(msg.sender, _contract);
    }
}