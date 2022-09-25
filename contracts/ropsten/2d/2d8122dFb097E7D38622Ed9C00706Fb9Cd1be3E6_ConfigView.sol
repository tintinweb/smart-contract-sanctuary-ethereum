// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import './SafeOwnableInterface.sol';

/**
 * This is a contract copied from 'OwnableUpgradeable.sol'
 * It has the same fundation of Ownable, besides it accept pendingOwner for mor Safe Use
 */
abstract contract SafeOwnable is SafeOwnableInterface {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    function owner() public override view returns (address) {
        return _owner;
    }

    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function setPendingOwner(address _addr) public onlyOwner {
        _pendingOwner = _addr;
    }

    function acceptOwner() public {
        require(msg.sender == _pendingOwner, "Ownable: caller is not the pendingOwner"); 
        _transferOwnership(_pendingOwner);
        _pendingOwner = address(0);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

/**
 * This is a contract copied from 'OwnableUpgradeable.sol'
 * It has the same fundation of Ownable, besides it accept pendingOwner for mor Safe Use
 */
abstract contract SafeOwnableInterface {

    function owner() public virtual view returns (address);

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;
pragma abicoder v2;

import '../core/SafeOwnable.sol';

contract ConfigView is SafeOwnable {

    mapping(string => string[]) public configs;

    function addConfig(string memory _key, string[] memory _values) external onlyOwner {
        configs[_key] = _values;
    }

    function setConfig(string memory _key, uint _index, string memory _value) external onlyOwner {
        for (uint i = configs[_key].length; i <= _index; i ++) {
            configs[_key].push("");
        }
        configs[_key][_index] = _value;
    }

    function getConfig(string memory _key) external view returns (string[] memory) {
        return configs[_key];
    }

    function existConfig(string memory _key) external view returns (bool) {
        return configs[_key].length > 0;
    }
}