/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

pragma solidity 0.8.12;

contract Descriptor is Ownable {
  // attribute svgs
  string internal constant BEGINNING = "<image width='24' height='24' image-rendering='pixelated' preserveAspectRatio='xMidYMid' xlink:href='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAAXNSR0IArs4c6QAAA";
  string internal constant END = "'/>";

  string[] public body;
  string[] public mouths;
  string[] public accessories;
  string[] public head;
  string[] public eyes;

  function _addBody(string calldata _trait) internal {
    body.push(_trait);
  }

  function _addMouth(string calldata _trait) internal {
    mouths.push(_trait);
  }

  function _addAccessory(string calldata _trait) internal {
    accessories.push(_trait);
  }

  function _addHead(string calldata _trait) internal {
    head.push(_trait);
  }

  function _addEyes(string calldata _trait) internal {
    eyes.push(_trait);
  }

  // calldata input format: ["trait1","trait2","trait3",...]
  function addManyBody(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addBody(_traits[i]);
    }
  }

  function addManyMouths(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addMouth(_traits[i]);
    }
  }

  function addManyAccessories(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addAccessory(_traits[i]);
    }
  }

  function addManyHead(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addHead(_traits[i]);
    }
  }

  function addManyEyes(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addEyes(_traits[i]);
    }
  }

  function clearBody() external onlyOwner {
    delete body;
  }

  function clearMouths() external onlyOwner {
    delete mouths;
  }

  function clearAccessories() external onlyOwner {
    delete accessories;
  }

  function clearHead() external onlyOwner {
    delete head;
  }

  function clearEyes() external onlyOwner {
    delete eyes;
  }

  function renderBody(uint256 _body) 
    public 
    view 
    returns (bytes memory) 
  {
      return abi.encodePacked(BEGINNING, body[_body], END);
  }

  function renderMouth(uint256 _mouth) 
    external 
    view 
    returns (bytes memory) 
  {
      return abi.encodePacked(BEGINNING, mouths[_mouth], END);
  }

  function renderAccessory(uint256 _accessory)
    external
    view
    returns (bytes memory)
  {
    return abi.encodePacked(BEGINNING, accessories[_accessory], END);
  }

  function renderHead(uint256 _head)
    external
    view
    returns (bytes memory)
  {
    return abi.encodePacked(BEGINNING, head[_head], END);
  }

  function renderEyes(uint256 _eyes) external view returns (bytes memory) {
    return abi.encodePacked(BEGINNING, eyes[_eyes], END);
  }
}