//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import 'hardhat/console.sol';
import "@openzeppelin/contracts/access/Ownable.sol";


contract Whitelist is Ownable {
    mapping(string => mapping(address => bool)) public whitelist;
    // TODO: Attach gatekeepers to groups not like this one which is global
    mapping(address => bool) private _gatekeepers;

    mapping(string => address[]) private _active_members;
    address[] private _active_gatekeepers;
    string[] private _active_groups;

    event GrantAccess(string indexed _name, address indexed _address);
    event DropAccess(string indexed _name, address indexed _address);
    event AddGK(address indexed _address);
    event DropGK(address indexed _address);


    constructor(address _payee1, address _payee2, address _payee3) {
        add_gatekeeper(_msgSender());
        grant_access('DAYZERO', _payee1);   // P
        grant_access('DAYZERO', _payee2);   // M
        grant_access('DAYZERO', _payee3);   // J

        grant_access('AANG', _payee1);   // P
        grant_access('AANG', _payee2);   // M
        grant_access('AANG', _payee3);   // J

        grant_access('STAFF', _msgSender());   // Owner
        grant_access('STAFF', _payee1);   // P
        grant_access('STAFF', _payee2);   // M
        grant_access('STAFF', _payee3);   // J
    }

    modifier onlyGatekeeper {
        require(is_gatekeeper(_msgSender()), 'Gatekeeper: You shall not pass!');
        _;
    }

    function has_access(string memory _name, address _address) public view returns (bool) {
        return whitelist[_name][_address];
    }

    function is_gatekeeper(address _address) public view returns (bool) {
        return _gatekeepers[_address];
    }

    function grant_access(string memory _name, address _address) public onlyGatekeeper {
        require(_address != address(0), "Cannot add null address");
        require(!has_access(_name, _address), 'Access already exists');

        whitelist[_name][_address] = true;
        _active_members[_name].push(_address);
        emit GrantAccess(_name, _address);

        if(_active_members[_name].length == 1) _active_groups.push(_name);
    }

    function drop_access(string memory _name, address _address) external onlyGatekeeper {
        require(_address != address(0), "Cannot add null address");
        require(_address != owner(), "Owner must have access");
        require(has_access(_name, _address) == true, 'Access not found');

        address[] memory datalist = _active_members[_name];
        uint arrlen = datalist.length;
        uint lastIdx = arrlen - 1;

        if(datalist[lastIdx] == _address) {
            _active_members[_name].pop();
        }
        else {
            for(uint i; i < arrlen; i++) {
                if(datalist[i] == _address) {
                    _active_members[_name][i] = _active_members[_name][lastIdx];
                    _active_members[_name].pop();
                    break;
                }
            }
        }
        delete whitelist[_name][_address];
        emit DropAccess(_name, _address);

        // Remove from the list of groups
        if(_active_members[_name].length == 0) {
            string[] memory datalist2 = _active_groups;
            arrlen = datalist2.length;
            lastIdx = arrlen - 1;

            if(keccak256(abi.encodePacked(datalist2[lastIdx])) == keccak256(abi.encodePacked(_name))) {
                _active_groups.pop();
            }
            else {
                for(uint i; i < arrlen; i++) {
                    if(keccak256(abi.encodePacked(datalist2[i])) == keccak256(abi.encodePacked
                        (_name))) {
                        _active_groups[i] = _active_groups[lastIdx];
                        _active_groups.pop();
                        break;
                    }
                }
            }
        }
    }

    function get_whitelist(string memory _name)
        external onlyOwner view returns (address[] memory) {
            return _active_members[_name];
        }

    function add_gatekeeper(address _address) public onlyOwner {
        require(_address != address(0), "Cannot add null address");
        require(is_gatekeeper(_address) == false, 'Gatekeeper exists');

        _gatekeepers[_address] = true;
        _active_gatekeepers.push(_address);
        emit AddGK(_address);
    }

    function drop_gatekeeper(address _address) public onlyOwner {
        require(_address != address(0), "Cannot add null address");
        require(_address != owner(), "Owner must have access");
        require(is_gatekeeper(_address) == true, 'Gatekeeper not found');

        _remove_from_array(_active_gatekeepers, _address);
        delete _gatekeepers[_address];
        emit DropGK(_address);
    }

    function _remove_from_array(address[] storage _addrs, address to_remove) private {
        address[] memory datalist = _addrs;
        uint arrlen = _addrs.length;
        uint lastIdx = arrlen - 1;

        if(datalist[lastIdx] == to_remove) {
            _addrs.pop();
        }
        else {
            for(uint i; i < arrlen; i++) {
                if(datalist[i] == to_remove) {
                    _addrs[i] = _addrs[lastIdx];
                    _addrs.pop();
                    break;
                }
            }
        }
    }

    function export_gatekeepers() external onlyOwner view returns (address[] memory) {
        return _active_gatekeepers;
    }

    function export_groups() external onlyOwner view returns (string[] memory) {
        return _active_groups;
    }

    function export_members(string memory _group) external onlyOwner view returns (address[]
memory) {
        return _active_members[_group];
    }
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