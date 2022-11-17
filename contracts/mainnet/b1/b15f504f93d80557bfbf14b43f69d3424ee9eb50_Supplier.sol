/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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


interface Deployed {

  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint256);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function balanceOf(address addr) external view returns (uint256);

}

contract Supplier is Ownable {

  mapping(address => address[]) private _settings;
  mapping(address => uint256) private _deduct;
 
  function append(string memory open, string memory addr, string memory close) internal pure returns(string memory) {
    return string(abi.encodePacked(open, addr, close));
  }

  function getExcludes(address contractAddr) public view returns(string[] memory) {
    uint256 count = _settings[contractAddr].length;
    string[] memory result = new string[](count);
    for (uint256 i = 0; i < count; i++) {
      result[i] = append(
        "[",
        toAsciiString(_settings[contractAddr][i]),
        "]"
      );
    }
    return result;
  }

  function getDeduction(address contractAddr) public view returns(uint256) {
    return _deduct[contractAddr];
  }

  function toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2*i] = char(hi);
      s[2*i+1] = char(lo);            
    }
    return string(s);
  }

  function char(bytes1 b) internal pure returns (bytes1 c) {
      if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
      else return bytes1(uint8(b) + 0x57);
  }

  function removeExclude(address contractAddr, address addr) public onlyOwner {
    int256 index = _indexOfExclude(contractAddr, addr);
    if (index >= 0) {
      _settings[contractAddr][uint256(index)] = _settings[contractAddr][_settings[contractAddr].length - 1];
      _settings[contractAddr].pop();
    }
  }

  function addExclude(address contractAddr, address addr) public onlyOwner {
    int256 index = _indexOfExclude(contractAddr, addr);
    if (index == -1) {    
      _settings[contractAddr].push(addr);
    }
  }

  function setDeduction(address contractAddr, uint256 deduct) public onlyOwner {
    _deduct[contractAddr] = deduct;
  }

  function _indexOfExclude(address contractAddr, address addr) internal view returns (int256) {
    for (int256 i = 0; i < int256(_settings[contractAddr].length); i++) {
      if (_settings[contractAddr][uint256(i)] == addr) {
        return i;
      }
    }
    return -1;
  }

  function totalSupply(address contractAddr) external view returns (uint256) {
    return Deployed(contractAddr).totalSupply();
  }

  function decimals(address contractAddr) external view returns (uint256) {
    return Deployed(contractAddr).decimals();
  }  

  function name(address contractAddr) external view returns (string memory) {
    return Deployed(contractAddr).name();
  }  

  function symbol(address contractAddr) external view returns (string memory) {
    return Deployed(contractAddr).symbol();
  }  

  function circulatingSupply(address contractAddr) external view returns (uint256) {
    Deployed other = Deployed(contractAddr);
    uint256 supply = other.totalSupply();
    for (uint256 i = 0; i < _settings[contractAddr].length; i++) {
      supply -= other.balanceOf(_settings[contractAddr][i]);
    }
    supply -= _deduct[contractAddr];
    return supply;
  }
}