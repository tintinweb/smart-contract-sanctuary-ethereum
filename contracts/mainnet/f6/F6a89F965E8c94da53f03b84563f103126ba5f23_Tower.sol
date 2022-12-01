// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./TwoStepOwnable.sol";

/// @title Tower
/// @notice Utility contract that stores addresses of any contracts
contract Tower is TwoStepOwnable {
    mapping(bytes32 => address) private _coordinates;

    error AddressZero();
    error KeyIsTaken();
    error EmptyCoordinates();

    event NewCoordinates(string key, address indexed newContract);
    event UpdateCoordinates(string key, address indexed newContract);
    event RemovedCoordinates(string key);

    /// @param _key string key
    /// @return address coordinates for the `_key`
    function coordinates(string calldata _key) external view virtual returns (address) {
        return _coordinates[makeKey(_key)];
    }

    /// @param _key raw bytes32 key
    /// @return address coordinates for the raw `_key`
    function rawCoordinates(bytes32 _key) external view virtual returns (address) {
        return _coordinates[_key];
    }

    /// @dev Registering new contract
    /// @param _key key under which contract will be stored
    /// @param _contract contract address
    function register(string calldata _key, address _contract) external virtual onlyOwner {
        bytes32 key = makeKey(_key);
        if (_coordinates[key] != address(0)) revert KeyIsTaken();
        if (_contract == address(0)) revert AddressZero();

        _coordinates[key] = _contract;
        emit NewCoordinates(_key, _contract);
    }

    /// @dev Removing coordinates
    /// @param _key key to remove
    function unregister(string calldata _key) external virtual onlyOwner {
        bytes32 key = makeKey(_key);
        if (_coordinates[key] == address(0)) revert EmptyCoordinates();

        _coordinates[key] = address(0);
        emit RemovedCoordinates(_key);
    }

    /// @dev Update key with new contract address
    /// @param _key key under which new contract will be stored
    /// @param _contract contract address
    function update(string calldata _key, address _contract) external virtual onlyOwner {
        bytes32 key = makeKey(_key);
        if (_coordinates[key] == address(0)) revert EmptyCoordinates();
        if (_contract == address(0)) revert AddressZero();

        _coordinates[key] = _contract;
        emit UpdateCoordinates(_key, _contract);
    }

    /// @dev generating mapping key based on string
    /// @param _key string key
    /// @return bytes32 representation of the `_key`
    function makeKey(string calldata _key) public pure virtual returns (bytes32) {
        return keccak256(abi.encodePacked(_key));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;

/// @title TwoStepOwnable
/// @notice Contract that implements the same functionality as popular Ownable contract from openzeppelin library.
/// The only difference is that it adds a possibility to transfer ownership in two steps. Single step ownership
/// transfer is still supported.
/// @dev Two step ownership transfer is meant to be used by humans to avoid human error. Single step ownership
/// transfer is meant to be used by smart contracts to avoid over-complicated two step integration. For that reason,
/// both ways are supported.
abstract contract TwoStepOwnable {
    /// @dev current owner
    address private _owner;
    /// @dev candidate to an owner
    address private _pendingOwner;

    /// @notice Emitted when ownership is transferred on `transferOwnership` and `acceptOwnership`
    /// @param newOwner new owner
    event OwnershipTransferred(address indexed newOwner);
    /// @notice Emitted when ownership transfer is proposed, aka pending owner is set
    /// @param newPendingOwner new proposed/pending owner
    event OwnershipPending(address indexed newPendingOwner);

    /**
     *  error OnlyOwner();
     *  error OnlyPendingOwner();
     *  error OwnerIsZero();
     */

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (owner() != msg.sender) revert("OnlyOwner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert("OwnerIsZero");
        _setOwner(newOwner);
    }

    /**
     * @dev Transfers pending ownership of the contract to a new account (`newPendingOwner`) and clears any existing
     * pending ownership.
     * Can only be called by the current owner.
     */
    function transferPendingOwnership(address newPendingOwner) public virtual onlyOwner {
        _setPendingOwner(newPendingOwner);
    }

    /**
     * @dev Clears the pending ownership.
     * Can only be called by the current owner.
     */
    function removePendingOwnership() public virtual onlyOwner {
        _setPendingOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a pending owner
     * Can only be called by the pending owner.
     */
    function acceptOwnership() public virtual {
        if (msg.sender != pendingOwner()) revert("OnlyPendingOwner");
        _setOwner(pendingOwner());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Sets the new owner and emits the corresponding event.
     */
    function _setOwner(address newOwner) private {
        if (_owner == newOwner) revert("OwnerDidNotChange");

        _owner = newOwner;
        emit OwnershipTransferred(newOwner);

        if (_pendingOwner != address(0)) {
            _setPendingOwner(address(0));
        }
    }

    /**
     * @dev Sets the new pending owner and emits the corresponding event.
     */
    function _setPendingOwner(address newPendingOwner) private {
        if (_pendingOwner == newPendingOwner) revert("PendingOwnerDidNotChange");

        _pendingOwner = newPendingOwner;
        emit OwnershipPending(newPendingOwner);
    }
}