// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../LSDBase.sol";
import "../../interface/owner/ILSDOwner.sol";
import "../../interface/ILSDStorage.sol";

contract LSDOwner is Ownable, LSDBase, ILSDOwner {
    // Events
    event ContractUpgraded(
        bytes32 indexed name,
        address indexed oldAddress,
        address indexed newAddress,
        uint256 time
    );
    event ContractAdded(
        bytes32 indexed name,
        address indexed newAddress,
        uint256 time
    );
    event ABIUpgraded(bytes32 indexed name, uint256 time);
    event ABIAdded(bytes32 indexed name, uint256 time);

    // The namespace for any data in the owner setting
    string private constant ownerSettingNameSpace = "owner.setting";

    // Construct
    constructor(ILSDStorage _lsdStorageAddress) LSDBase(_lsdStorageAddress) {
        // Version
        version = 1;
    }

    // Get the annual profit
    function getApy() public view override returns (uint256) {
        return
            getUint(keccak256(abi.encodePacked(ownerSettingNameSpace, "apy")));
    }

    // Get the LIDO Apy
    function getLIDOApy() public view override returns (uint256) {
        return
            getUint(
                keccak256(abi.encodePacked(ownerSettingNameSpace, "lido.apy"))
            );
    }

    // Get the RP Apy
    function getRPApy() public view override returns (uint256) {
        return
            getUint(
                keccak256(abi.encodePacked(ownerSettingNameSpace, "rp.apy"))
            );
    }

    // Get the SWISE Apy
    function getSWISEApy() public view override returns (uint256) {
        return
            getUint(
                keccak256(abi.encodePacked(ownerSettingNameSpace, "swise.apy"))
            );
    }

    // Get the annual profit Unit
    function getApyUnit() public view override returns (uint256) {
        return
            getUint(
                keccak256(abi.encodePacked(ownerSettingNameSpace, "apy.unit"))
            );
    }

    // Get the protocol fee
    function getProtocolFee() public view override returns (uint256) {
        return
            getUint(
                keccak256(
                    abi.encodePacked(ownerSettingNameSpace, "protocol.fee")
                )
            );
    }

    // Get the multiplier
    function getMultiplier() public view override returns (uint256) {
        return
            getUint(
                keccak256(abi.encodePacked(ownerSettingNameSpace, "multiplier"))
            );
    }

    // Get the multiplier unit
    function getMultiplierUnit() public view override returns (uint256) {
        return
            getUint(
                keccak256(
                    abi.encodePacked(ownerSettingNameSpace, "multiplier.unit")
                )
            );
    }

    // Get the minimum deposit amount
    function getMinimumDepositAmount() public view override returns (uint256) {
        return
            getUint(
                keccak256(
                    abi.encodePacked(
                        ownerSettingNameSpace,
                        "minimum.deposit.amount"
                    )
                )
            );
    }

    // Get the deposit enabled
    function getDepositEnabled() public view override returns (bool) {
        return
            getBool(
                keccak256(
                    abi.encodePacked(ownerSettingNameSpace, "deposit.enabled")
                )
            );
    }

    // Get the LSD Token Lock/Unlock
    function getIsLock() public view override returns (bool) {
        return
            getBool(keccak256(abi.encodePacked(ownerSettingNameSpace, "lock")));
    }

    // Set the annual profit
    function setApy(uint256 _apy) public override onlyOwner {
        setUint(
            keccak256(abi.encodePacked(ownerSettingNameSpace, "apy")),
            _apy
        );
    }

    // Set the annual profit unit
    function setApyUnit(uint256 _apyUnit) public override onlyOwner {
        setUint(
            keccak256(abi.encodePacked(ownerSettingNameSpace, "apy.unit")),
            _apyUnit
        );
    }

    // Set the protocol fee
    function setProtocolFee(uint256 _protocalFee) public override onlyOwner {
        setUint(
            keccak256(abi.encodePacked(ownerSettingNameSpace, "protocol.fee")),
            _protocalFee
        );
    }

    // Set the minimum deposit amount
    function setMinimumDepositAmount(uint256 _minimumDepositAmount)
        public
        override
        onlyOwner
    {
        setUint(
            keccak256(
                abi.encodePacked(
                    ownerSettingNameSpace,
                    "minimum.deposit.amount"
                )
            ),
            _minimumDepositAmount
        );
    }

    // Set the deposit enabled
    function setDepositEnabled(bool _depositEnabled) public override onlyOwner {
        setBool(
            keccak256(
                abi.encodePacked(ownerSettingNameSpace, "deposit.enabled")
            ),
            _depositEnabled
        );
    }

    // Set the LSD Token Lock/Unlock
    function setIsLock(bool _isLock) public override onlyOwner {
        setBool(
            keccak256(abi.encodePacked(ownerSettingNameSpace, "lock")),
            _isLock
        );
    }

    // Set the multiplier
    function setMultiplier(uint256 _multiplier) public override onlyOwner {
        setUint(
            keccak256(abi.encodePacked(ownerSettingNameSpace, "multiplier")),
            _multiplier
        );
    }

    // Set the multiplier unit
    function setMultiplierUnit(uint256 _multiplierUnit)
        public
        override
        onlyOwner
    {
        setUint(
            keccak256(
                abi.encodePacked(ownerSettingNameSpace, "multiplier.unit")
            ),
            _multiplierUnit
        );
    }

    // Set the LIDO Apy
    function setLIDOApy(uint256 _lidoApy) public override onlyOwner {
        setUint(
            keccak256(abi.encodePacked(ownerSettingNameSpace, "lido.apy")),
            _lidoApy
        );
    }

    // Set the RP Apy
    function setRPApy(uint256 _rpApy) public override onlyOwner {
        setUint(
            keccak256(abi.encodePacked(ownerSettingNameSpace, "rp.apy")),
            _rpApy
        );
    }

    // Set the SWISE Apy
    function setSWISEApy(uint256 _swiseApy) public override onlyOwner {
        setUint(
            keccak256(abi.encodePacked(ownerSettingNameSpace, "swise.apy")),
            _swiseApy
        );
    }

    // Main accessor for performing an upgrade, be it a contract or abi for a contract
    function upgrade(
        string memory _type,
        string memory _name,
        string memory _contractAbi,
        address _contractAddress
    ) external override onlyOwner {
        // What action are we performing?
        bytes32 typeHash = keccak256(abi.encodePacked(_type));
        // Lets do it!
        if (typeHash == keccak256(abi.encodePacked("upgradeContract")))
            _upgradeContract(_name, _contractAddress, _contractAbi);
        if (typeHash == keccak256(abi.encodePacked("addContract")))
            _addContract(_name, _contractAddress, _contractAbi);
        if (typeHash == keccak256(abi.encodePacked("upgradeABI")))
            _upgradeABI(_name, _contractAbi);
        if (typeHash == keccak256(abi.encodePacked("addABI")))
            _addABI(_name, _contractAbi);
    }

    /*** Internal Upgrade Methods for the Owner ****************/
    // Add a new network contract
    function _addContract(
        string memory _name,
        address _contractAddress,
        string memory _contractAbi
    ) internal {
        // Check contract name
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        require(bytes(_name).length > 0, "Invalid contract name");
        // Cannot add contract if it already exists (use upgradeContract instead)
        require(
            getAddress(
                keccak256(abi.encodePacked("contract.address", _name))
            ) == address(0x0),
            "Contract name is already in use"
        );
        // Cannot add contract if already in use as ABI only
        string memory existingAbi = getString(
            keccak256(abi.encodePacked("contract.abi", _name))
        );
        require(
            bytes(existingAbi).length == 0,
            "Contract name is already in use"
        );
        // Check contract address
        require(_contractAddress != address(0x0), "Invalid contract address");
        require(
            !getBool(
                keccak256(abi.encodePacked("contract.exists", _contractAddress))
            ),
            "Contract address is already in use"
        );
        // Check ABI isn't empty
        require(bytes(_contractAbi).length > 0, "Empty ABI is invalid");
        // Register contract
        setBool(
            keccak256(abi.encodePacked("contract.exists", _contractAddress)),
            true
        );
        setString(
            keccak256(abi.encodePacked("contract.name", _contractAddress)),
            _name
        );
        setAddress(
            keccak256(abi.encodePacked("contract.address", _name)),
            _contractAddress
        );
        setString(
            keccak256(abi.encodePacked("contract.abi", _name)),
            _contractAbi
        );
        // Emit contract added event
        emit ContractAdded(nameHash, _contractAddress, block.timestamp);
    }

    // Add a new network contract ABI
    function _addABI(string memory _name, string memory _contractAbi) internal {
        // Check ABI name
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        require(bytes(_name).length > 0, "Invalid ABI name");
        // Sanity check
        require(bytes(_contractAbi).length > 0, "Empty ABI is invalid");
        // Cannot add ABI if name is already used for an existing network contract
        require(
            getAddress(
                keccak256(abi.encodePacked("contract.address", _name))
            ) == address(0x0),
            "ABI name is already in use"
        );
        // Cannot add ABI if ABI already exists for this name (use upgradeABI instead)
        string memory existingAbi = getString(
            keccak256(abi.encodePacked("contract.abi", _name))
        );
        require(bytes(existingAbi).length == 0, "ABI name is already in use");
        // Set ABI
        setString(
            keccak256(abi.encodePacked("contract.abi", _name)),
            _contractAbi
        );
        // Emit ABI added event
        emit ABIAdded(nameHash, block.timestamp);
    }

    // Upgrade a network contract ABI
    function _upgradeABI(string memory _name, string memory _contractAbi)
        internal
    {
        // Check ABI exists
        string memory existingAbi = getString(
            keccak256(abi.encodePacked("contract.abi", _name))
        );
        require(bytes(existingAbi).length > 0, "ABI does not exist");
        // Sanity checks
        require(bytes(_contractAbi).length > 0, "Empty ABI is invalid");
        require(
            keccak256(bytes(existingAbi)) != keccak256(bytes(_contractAbi)),
            "ABIs are identical"
        );
        // Set ABI
        setString(
            keccak256(abi.encodePacked("contract.abi", _name)),
            _contractAbi
        );
        // Emit ABI upgraded event
        emit ABIUpgraded(keccak256(abi.encodePacked(_name)), block.timestamp);
    }

    // Upgrade a network contract
    function _upgradeContract(string memory _name, address _contractAddress, string memory _contractAbi) internal {
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        // Get old contract address & check contract exists
        address oldContractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _name)));
        require(oldContractAddress != address(0x0), "Contract does not exist");
        // Check new contract address
        require(_contractAddress != address(0x0), "Invalid contract address");
        require(_contractAddress != oldContractAddress, "The contract address cannot be set to its current address");
        require(!getBool(keccak256(abi.encodePacked("contract.exists", _contractAddress))), "Contract address is already in use");
        // Check ABI isn't empty
        require(bytes(_contractAbi).length > 0, "Empty ABI is invalid");
        // Register new contract
        setBool(keccak256(abi.encodePacked("contract.exists", _contractAddress)), true);
        setString(keccak256(abi.encodePacked("contract.name", _contractAddress)), _name);
        setAddress(keccak256(abi.encodePacked("contract.address", _name)), _contractAddress);
        setString(keccak256(abi.encodePacked("contract.abi", _name)), _contractAbi);
        // Deregister old contract
        deleteString(keccak256(abi.encodePacked("contract.name", oldContractAddress)));
        deleteBool(keccak256(abi.encodePacked("contract.exists", oldContractAddress)));
        // Emit contract upgraded event
        emit ContractUpgraded(nameHash, oldContractAddress, _contractAddress, block.timestamp);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ILSDStorage {
    // Depoly status
    function getDeployedStatus() external view returns (bool);

    // Guardian
    function getGuardian() external view returns (address);

    function setGuardian(address _newAddress) external;

    function confirmGuardian() external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);

    function getUint(bytes32 _key) external view returns (uint256);

    function getString(bytes32 _key) external view returns (string memory);

    function getBytes(bytes32 _key) external view returns (bytes memory);

    function getBool(bytes32 _key) external view returns (bool);

    function getInt(bytes32 _key) external view returns (int256);

    function getBytes32(bytes32 _key) external view returns (bytes32);

    // Setters
    function setAddress(bytes32 _key, address _value) external;

    function setUint(bytes32 _key, uint256 _value) external;

    function setString(bytes32 _key, string calldata _value) external;

    function setBytes(bytes32 _key, bytes calldata _value) external;

    function setBool(bytes32 _key, bool _value) external;

    function setInt(bytes32 _key, int256 _value) external;

    function setBytes32(bytes32 _key, bytes32 _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;

    function deleteUint(bytes32 _key) external;

    function deleteString(bytes32 _key) external;

    function deleteBytes(bytes32 _key) external;

    function deleteBool(bytes32 _key) external;

    function deleteInt(bytes32 _key) external;

    function deleteBytes32(bytes32 _key) external;

    // Arithmetic
    function addUint(bytes32 _key, uint256 _amount) external;

    function subUint(bytes32 _key, uint256 _amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ILSDOwner {
    function getDepositEnabled() external view returns (bool);

    function getIsLock() external view returns (bool);

    function getApy() external view returns (uint256);

    function getMultiplier() external view returns (uint256);

    function getMultiplierUnit() external view returns (uint256);

    function getApyUnit() external view returns (uint256);

    function getLIDOApy() external view returns (uint256);

    function getRPApy() external view returns (uint256);

    function getSWISEApy() external view returns (uint256);

    function getProtocolFee() external view returns (uint256);

    function getMinimumDepositAmount() external view returns (uint256);

    function setDepositEnabled(bool _depositEnabled) external;

    function setIsLock(bool _isLock) external;

    function setApy(uint256 _apy) external;

    function setApyUnit(uint256 _apyUnit) external;

    function setMultiplier(uint256 _multiplier) external;

    function setMultiplierUnit(uint256 _multiplierUnit) external;

    function setRPApy(uint256 _rpApy) external;

    function setLIDOApy(uint256 _lidoApy) external;

    function setSWISEApy(uint256 _swiseApy) external;

    function setProtocolFee(uint256 _protocalFee) external;

    function setMinimumDepositAmount(uint256 _minimumDepositAmount) external;

    function upgrade(string memory _type, string memory _name, string memory _contractAbi, address _contractAddress) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../interface/ILSDStorage.sol";

/// @title Base settings / modifiers for each contract in LSD

abstract contract LSDBase {
    // Calculate using this as the base
    uint256 constant calcBase = 1 ether;

    // Version of the contract
    uint8 public version;

    // The main storage contact where primary persistant storage is maintained
    ILSDStorage lsdStorage;

    /*** Modifiers ***********************************************************/

    /**
     * @dev Throws if called by any sender that doesn't match a LSD network contract
     */
    modifier onlyLSDNetworkContract() {
        require(
            getBool(
                keccak256(abi.encodePacked("contract.exists", msg.sender))
            ),
            "Invalid contract"
        );
        _;
    }

    /**
     * @dev Throws if called by any sender that doesn't match one of the supplied contract
     */
    modifier onlyLSDContract(
        string memory _contractName,
        address _contractAddress
    ) {
        require(
            _contractAddress ==
                getAddress(
                    keccak256(
                        abi.encodePacked("contract.address", _contractName)
                    )
                ),
            "Invalid contract"
        );
        _;
    }

    /*** Methods **********************************************************************/

    /// @dev Set the main LSD storage address
    constructor(ILSDStorage _lsdStorageAddress) {
        // Update the contract address
        lsdStorage = ILSDStorage(_lsdStorageAddress);
    }

    /// @dev Get the address of a network contract by name
    function getContractAddress(string memory _contractName)
        internal
        view
        returns (address)
    {
        // Get the current contract address
        address contractAddress = getAddress(
            keccak256(abi.encodePacked("contract.address", _contractName))
        );
        // Check it
        require(contractAddress != address(0x0), "Contract not found");
        return contractAddress;
    }

    /// @dev Get the name of a network contract by address
    function getContractName(address _contractAddress)
        internal
        view
        returns (string memory)
    {
        // Get the contract name
        string memory contractName = getString(
            keccak256(abi.encodePacked("contract.name", _contractAddress))
        );
        // Check it
        require(bytes(contractName).length > 0, "Contract not found");
        // Return
        return contractName;
    }

    /// @dev Get revert error message from a .call method
    function getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        assembly {
            // Slice the sighash
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /*** LSD Storage Methods ********************************************************/

    // Note: Uused helpers have been removed to keep contract sizes down

    /// @dev Storage get methods
    function getAddress(bytes32 _key) internal view returns (address) {
        return lsdStorage.getAddress(_key);
    }

    function getUint(bytes32 _key) internal view returns (uint256) {
        return lsdStorage.getUint(_key);
    }

    function getString(bytes32 _key) internal view returns (string memory) {
        return lsdStorage.getString(_key);
    }

    function getBytes(bytes32 _key) internal view returns (bytes memory) {
        return lsdStorage.getBytes(_key);
    }

    function getBool(bytes32 _key) internal view returns (bool) {
        return lsdStorage.getBool(_key);
    }

    function getInt(bytes32 _key) internal view returns (int256) {
        return lsdStorage.getInt(_key);
    }

    function getBytes32(bytes32 _key) internal view returns (bytes32) {
        return lsdStorage.getBytes32(_key);
    }

    /// @dev Storage set methods
    function setAddress(bytes32 _key, address _value) internal {
        lsdStorage.setAddress(_key, _value);
    }

    function setUint(bytes32 _key, uint256 _value) internal {
        lsdStorage.setUint(_key, _value);
    }

    function setString(bytes32 _key, string memory _value) internal {
        lsdStorage.setString(_key, _value);
    }

    function setBytes(bytes32 _key, bytes memory _value) internal {
        lsdStorage.setBytes(_key, _value);
    }

    function setBool(bytes32 _key, bool _value) internal {
        lsdStorage.setBool(_key, _value);
    }

    function setInt(bytes32 _key, int256 _value) internal {
        lsdStorage.setInt(_key, _value);
    }

    function setBytes32(bytes32 _key, bytes32 _value) internal {
        lsdStorage.setBytes32(_key, _value);
    }

    /// @dev Storage delete methods
    function deleteAddress(bytes32 _key) internal {
        lsdStorage.deleteAddress(_key);
    }

    function deleteUint(bytes32 _key) internal {
        lsdStorage.deleteUint(_key);
    }

    function deleteString(bytes32 _key) internal {
        lsdStorage.deleteString(_key);
    }

    function deleteBytes(bytes32 _key) internal {
        lsdStorage.deleteBytes(_key);
    }

    function deleteBool(bytes32 _key) internal {
        lsdStorage.deleteBool(_key);
    }

    function deleteInt(bytes32 _key) internal {
        lsdStorage.deleteInt(_key);
    }

    function deleteBytes32(bytes32 _key) internal {
        lsdStorage.deleteBytes32(_key);
    }

    /// @dev Storage arithmetic methods
    function addUint(bytes32 _key, uint256 _amount) internal {
        lsdStorage.addUint(_key, _amount);
    }

    function subUint(bytes32 _key, uint256 _amount) internal {
        lsdStorage.subUint(_key, _amount);
    }
}

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