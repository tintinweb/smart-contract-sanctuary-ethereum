// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./Owned.sol";
import "./Utils.sol";
import "./interfaces/IContractRegistry.sol";

/**
 * @dev This contract maintains contract addresses by name.
 *
 * The owner can update contract addresses so that a contract name always points to the latest version
 * of the given contract.
 *
 * Other contracts can query the registry to get updated addresses instead of depending on specific
 * addresses.
 *
 * Note that contract names are limited to 32 bytes UTF8 encoded ASCII strings to optimize gas costs
 */
contract ContractRegistry is IContractRegistry, Owned, Utils {
    struct RegistryItem {
        address contractAddress;
        uint256 nameIndex; // index of the item in the list of contract names
    }

    // the mapping between contract names and RegistryItem items
    mapping(bytes32 => RegistryItem) private _items;

    // the list of all registered contract names
    string[] private _contractNames;

    /**
     * @dev triggered when an address pointed to by a contract name is modified
     */
    event AddressUpdate(bytes32 indexed contractName, address contractAddress);

    /**
     * @dev returns the number of items in the registry
     */
    function itemCount() external view returns (uint256) {
        return _contractNames.length;
    }

    /**
     * @dev returns a registered contract name
     */
    function contractNames(uint256 index) external view returns (string memory) {
        return _contractNames[index];
    }

    /**
     * @dev returns the address associated with the given contract name
     */
    function addressOf(bytes32 contractName) public view override returns (address) {
        return _items[contractName].contractAddress;
    }

    /**
     * @dev registers a new address for the contract name in the registry
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     */
    function registerAddress(bytes32 contractName, address contractAddress)
        external
        ownerOnly
        validAddress(contractAddress)
    {
        require(contractName.length > 0, "ERR_INVALID_NAME");

        // check if any change is needed
        address currentAddress = _items[contractName].contractAddress;
        if (contractAddress == currentAddress) {
            return;
        }

        if (currentAddress == address(0)) {
            // update the item's index in the list
            _items[contractName].nameIndex = _contractNames.length;

            // add the contract name to the name list
            _contractNames.push(_bytes32ToString(contractName));
        }

        // update the address in the registry
        _items[contractName].contractAddress = contractAddress;

        // dispatch the address update event
        emit AddressUpdate(contractName, contractAddress);
    }

    /**
     * @dev removes an existing contract address from the registry
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     */
    function unregisterAddress(bytes32 contractName) public ownerOnly {
        require(contractName.length > 0, "ERR_INVALID_NAME");
        require(_items[contractName].contractAddress != address(0), "ERR_INVALID_NAME");

        // remove the address from the registry
        _items[contractName].contractAddress = address(0);

        // if there are multiple items in the registry, move the last element to the deleted element's position
        // and modify last element's registryItem.nameIndex in the items collection to point to the right position in contractNames
        if (_contractNames.length > 1) {
            string memory lastContractNameString = _contractNames[_contractNames.length - 1];
            uint256 unregisterIndex = _items[contractName].nameIndex;

            _contractNames[unregisterIndex] = lastContractNameString;
            bytes32 lastContractName = _stringToBytes32(lastContractNameString);
            RegistryItem storage registryItem = _items[lastContractName];
            registryItem.nameIndex = unregisterIndex;
        }

        // remove the last element from the name list
        _contractNames.pop();

        // zero the deleted element's index
        _items[contractName].nameIndex = 0;

        // dispatch the address update event
        emit AddressUpdate(contractName, address(0));
    }

    /**
     * @dev utility, converts bytes32 to a string
     *
     * note that the bytes32 argument is assumed to be UTF8 encoded ASCII string
     */
    function _bytes32ToString(bytes32 data) private pure returns (string memory) {
        bytes memory byteArray = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            byteArray[i] = data[i];
        }

        return string(byteArray);
    }

    /**
     * @dev utility, converts string to bytes32
     *
     * note that the bytes32 argument is assumed to be UTF8 encoded ASCII string
     */
    function _stringToBytes32(string memory str) private pure returns (bytes32) {
        bytes32 result;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := mload(add(str, 32))
        }

        return result;
    }

    /**
     * @dev deprecated, backward compatibility
     */
    function getAddress(bytes32 contractName) public view returns (address) {
        return addressOf(contractName);
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./interfaces/IOwned.sol";

/**
 * @dev This contract provides support and utilities for contract ownership.
 */
contract Owned is IOwned {
    address private _owner;
    address private _newOwner;

    /**
     * @dev triggered when the owner is updated
     */
    event OwnerUpdate(address indexed prevOwner, address indexed newOwner);

    /**
     * @dev initializes a new Owned instance
     */
    constructor() public {
        _owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly() {
        _ownerOnly();

        _;
    }

    // error message binary size optimization
    function _ownerOnly() private view {
        require(msg.sender == _owner, "ERR_ACCESS_DENIED");
    }

    /**
     * @dev allows transferring the contract ownership
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     *
     * note the new owner still needs to accept the transfer
     */
    function transferOwnership(address newOwner) public override ownerOnly {
        require(newOwner != _owner, "ERR_SAME_OWNER");

        _newOwner = newOwner;
    }

    /**
     * @dev used by a new owner to accept an ownership transfer
     */
    function acceptOwnership() public override {
        require(msg.sender == _newOwner, "ERR_ACCESS_DENIED");

        emit OwnerUpdate(_owner, _newOwner);

        _owner = _newOwner;
        _newOwner = address(0);
    }

    /**
     * @dev returns the address of the current owner
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @dev returns the address of the new owner candidate
     */
    function newOwner() external view returns (address) {
        return _newOwner;
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Utilities & Common Modifiers
 */
contract Utils {
    uint32 internal constant PPM_RESOLUTION = 1000000;

    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 value) {
        _greaterThanZero(value);

        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 value) internal pure {
        require(value > 0, "ERR_ZERO_VALUE");
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address addr) {
        _validAddress(addr);

        _;
    }

    // error message binary size optimization
    function _validAddress(address addr) internal pure {
        require(addr != address(0), "ERR_INVALID_ADDRESS");
    }

    // ensures that the portion is valid
    modifier validPortion(uint32 _portion) {
        _validPortion(_portion);

        _;
    }

    // error message binary size optimization
    function _validPortion(uint32 _portion) internal pure {
        require(_portion > 0 && _portion <= PPM_RESOLUTION, "ERR_INVALID_PORTION");
    }

    // validates an external address - currently only checks that it isn't null or this
    modifier validExternalAddress(address addr) {
        _validExternalAddress(addr);

        _;
    }

    // error message binary size optimization
    function _validExternalAddress(address addr) internal view {
        require(addr != address(0) && addr != address(this), "ERR_INVALID_EXTERNAL_ADDRESS");
    }

    // ensures that the fee is valid
    modifier validFee(uint32 fee) {
        _validFee(fee);

        _;
    }

    // error message binary size optimization
    function _validFee(uint32 fee) internal pure {
        require(fee <= PPM_RESOLUTION, "ERR_INVALID_FEE");
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev Contract Registry interface
 */
interface IContractRegistry {
    function addressOf(bytes32 contractName) external view returns (address);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/**
 * @dev Owned interface
 */
interface IOwned {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}