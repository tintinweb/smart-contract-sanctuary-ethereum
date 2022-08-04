// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Base} from "./Base.sol";

library RoleMemberSet {
    struct Record {
        address[] values;
        mapping(address => uint256) indexes; // value to index
    }

    function add(Record storage _record, address _value) internal {
        if (contains(_record, _value)) return; // exist
        _record.values.push(_value);
        _record.indexes[_value] = _record.values.length;
    }

    function remove(Record storage _record, address _value) internal {
        uint256 valueIndex = _record.indexes[_value];
        if (valueIndex == 0) return; // removed non-exist value
        uint256 toDeleteIndex = valueIndex - 1; // dealing with out of bounds
        uint256 lastIndex = _record.values.length - 1;
        if (lastIndex != toDeleteIndex) {
            address lastvalue = _record.values[lastIndex];
            _record.values[toDeleteIndex] = lastvalue;
            _record.indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
        }
        _record.values.pop();
        _record.indexes[_value] = 0; // set to 0
    }

    function contains(Record storage _record, address _value)
        internal
        view
        returns (bool)
    {
        return _record.indexes[_value] != 0;
    }

    function size(Record storage _record) internal view returns (uint256) {
        return _record.values.length;
    }

    function at(Record storage _record, uint256 _index)
        internal
        view
        returns (address)
    {
        return _record.values[_index];
    }
}

contract LightLinkAccessControl is Base {
    using RoleMemberSet for RoleMemberSet.Record;

    // variables

    // contract => list addresses
    mapping(address => RoleMemberSet.Record) master;

    // role => list addresses
    mapping(bytes => RoleMemberSet.Record) roleMembers;

    constructor() {
        accessControlProvider = address(this);
    }

    /**
     * @dev Grant roles
     * {grantRoles}.
     *
     * allow an account can access method of a contract (that contract need call function from here to check)
     * _methodInfo ie: setData(uint256,uint256) (no space)
     */
    // verified
    function grantRoles(
        address _account,
        address _contract,
        string[] memory _methodsInfo
    ) external onlyRoler("grantRoles") {
        bytes memory role;
        for (uint256 i = 0; i < _methodsInfo.length; i++) {
            role = abi.encode(_contract, _methodsInfo[i]);
            roleMembers[role].add(_account);
        }
    }

    // verified
    function revokeRoles(
        address _account,
        address _contract,
        string[] memory _methodsInfo
    ) external onlyRoler("revokeRoles") {
        bytes memory role;
        for (uint256 i = 0; i < _methodsInfo.length; i++) {
            role = abi.encode(_contract, _methodsInfo[i]);
            roleMembers[role].remove(_account);
        }
    }

    // verified
    function grantMaster(address _account, address _contract)
        external
        onlyRoler("grantMaster")
    {
        master[_contract].add(_account);
    }

    // verified
    function revokeMaster(address _account, address _contract)
        external
        onlyRoler("revokeMaster")
    {
        master[_contract].remove(_account);
    }

    // View
    // verified
    function hasRole(
        address _account,
        address _contract,
        string memory _methodInfo
    ) public view returns (bool) {
        return
            master[_contract].contains(_account) ||
            roleMembers[abi.encode(_contract, _methodInfo)].contains(_account);
    }

    // verified
    function getMembersByRole(address _contract, string memory _methodInfo)
        public
        view
        returns (address[] memory)
    {
        uint256 size = roleMembers[abi.encode(_contract, _methodInfo)].size();
        address[] memory records = new address[](size);

        for (uint256 i = 0; i < size; i++) {
            records[i] = roleMembers[abi.encode(_contract, _methodInfo)].at(i);
        }
        return records;
    }

    // verified
    function getMemberOfRoleByIndex(
        address _contract,
        string memory _methodInfo,
        uint256 _index
    ) public view returns (address) {
        return roleMembers[abi.encode(_contract, _methodInfo)].at(_index);
    }

    // verified
    function getMastersByRole(address _contract)
        public
        view
        returns (address[] memory)
    {
        uint256 size = master[_contract].size();
        address[] memory records = new address[](size);

        for (uint256 i = 0; i < size; i++) {
            records[i] = master[_contract].at(i);
        }
        return records;
    }

    // verified
    function getMasterOfRoleByIndex(address _contract, uint256 _index)
        public
        view
        returns (address)
    {
        return master[_contract].at(_index);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Pellar + LightLink 2022

abstract contract Base is Ownable {
    // variable
    address public accessControlProvider;

    constructor() {}

    // verified
    modifier onlyRoler(string memory _methodInfo) {
        require(
            _msgSender() == owner() ||
                IAccessControl(accessControlProvider).hasRole(
                    _msgSender(),
                    address(this),
                    _methodInfo
                ),
            "Caller does not have permission"
        );
        _;
    }

    // verified
    function setAccessControlProvider(address _contract)
        external
        onlyRoler("setAccessControlProvider")
    {
        accessControlProvider = _contract;
    }
}

interface IAccessControl {
    function hasRole(
        address _account,
        address _contract,
        string memory _methodInfo
    ) external view returns (bool);
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