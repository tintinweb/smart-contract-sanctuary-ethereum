// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Descriptor is Ownable {
  // attribute svgs
  string internal constant BEGINNING =
    "<image href='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQAAAAEA";
  string internal constant END = "'/>";
  string internal constant F = '<g filter="url(#a)">';
  string internal constant V = '<g class="vibe">';
  string internal constant F_E = "</g>";
  string internal constant DEFS =
    '<defs><filter id="a"><feTurbulence baseFrequency=".01" type="fractalNoise" numOctaves="7" seed="3"><animate attributeName="baseFrequency" dur="0.02s" values="0.015; 0.015; 0.015; 0.025; 0.03; 0.025; 0.02; 0.015" repeatCount="indefinite"/></feTurbulence><feDisplacementMap in="SourceGraphic" scale="10" yChannelSelector="A"/></filter></defs>';

  string[] public backs;
  string[] public mouths;
  string[] public accessories;
  string[] public backgrounds;
  string[] public bottoms;
  string[] public clothes;
  string[] public eyes;
  string[] public headgears;
  string[] public legendaries;

  function legendariesLengthCheck() public view returns(uint) {  
        uint x = legendaries.length;
        return x; 
    } 

  function _addBack(string calldata _trait) internal {
    backs.push(_trait);
  }

  function _addMouth(string calldata _trait) internal {
    mouths.push(_trait);
  }

  function _addAccessory(string calldata _trait) internal {
    accessories.push(_trait);
  }

  function _addBackground(string calldata _trait) internal {
    backgrounds.push(_trait);
  }

  function _addBottom(string calldata _trait) internal {
    bottoms.push(_trait);
  }

  function _addClothes(string calldata _trait) internal {
    clothes.push(_trait);
  }

  function _addEyes(string calldata _trait) internal {
    eyes.push(_trait);
  }

  function _addHeadgear(string calldata _trait) internal {
    headgears.push(_trait);
  }

  function _addLegendary(string calldata _trait) internal {
    legendaries.push(_trait);
  }

  // calldata input format: ["trait1","trait2","trait3",...]
  function addManyBacks(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addBack(_traits[i]);
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

  function addManyBackgrounds(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addBackground(_traits[i]);
    }
  }

  function addManyBottoms(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addBottom(_traits[i]);
    }
  }

  function addManyClothes(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addClothes(_traits[i]);
    }
  }

  function addManyEyes(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addEyes(_traits[i]);
    }
  }

  function addManyHeadgears(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addHeadgear(_traits[i]);
    }
  }

  function addManyLegendaries(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addLegendary(_traits[i]);
    }
  }  

  function clearBacks() external onlyOwner {
    delete backs;
  }

  function clearMouths() external onlyOwner {
    delete mouths;
  }

  function clearAccessories() external onlyOwner {
    delete accessories;
  }

  function clearBackgrounds() external onlyOwner {
    delete backgrounds;
  }

  function clearBottoms() external onlyOwner {
    delete bottoms;
  }

  function clearClothes() external onlyOwner {
    delete clothes;
  }

  function clearEyes() external onlyOwner {
    delete eyes;
  }

  function clearHeadgears() external onlyOwner {
    delete headgears;
  }

  function clearLegendaries() external onlyOwner {
    delete legendaries;
  }  

  function renderBack(uint256 _trait) public view returns (bytes memory) {
    //hellhog
    if (_trait != 22) {
      return abi.encodePacked(V, BEGINNING, string(backs[_trait]), END, F_E);
    } else {
      return abi.encodePacked(V, F, BEGINNING, backs[_trait], END, F_E, F_E, DEFS);
    }
  }

  function renderMouth(uint256 _mouth) external view returns (bytes memory) {
    //laser
    if (_mouth != 24) {
      return abi.encodePacked(V, BEGINNING, mouths[_mouth], END, F_E);
    } else {
      return abi.encodePacked(V, F, BEGINNING, mouths[_mouth], END, F_E, F_E, DEFS);
    }
  }

  function renderAccessory(uint256 _accessory)
    external
    view
    returns (bytes memory)
  {
    return abi.encodePacked(BEGINNING, accessories[_accessory], END);
  }

  function renderBackground(uint256 _background)
    external
    view
    returns (bytes memory)
  {
    return abi.encodePacked(backgrounds[_background]);
  }

  function renderBottom(uint256 _bottom) external view returns (bytes memory) {
    return abi.encodePacked(BEGINNING, bottoms[_bottom], END);
  }

  function renderClothes(uint256 _clothes)
    external
    view
    returns (bytes memory)
  {
    return abi.encodePacked(BEGINNING, clothes[_clothes], END);
  }

  function renderEyes(uint256 _eyes) external view returns (bytes memory) {
    //laser
    if (_eyes != 33) {
      return abi.encodePacked(V, BEGINNING, eyes[_eyes], END, F_E);
    } else {
      return abi.encodePacked(V, F, BEGINNING, eyes[_eyes], END, F_E, F_E, DEFS);
    }
  }

  function renderHeadgear(uint256 _headgear)
    external
    view
    returns (bytes memory)
  {
    return abi.encodePacked(V, BEGINNING, headgears[_headgear], END, F_E);
  }

  function renderLegendary(uint256 _legendary)
    external
    view
    returns (bytes memory)
  {
    return abi.encodePacked(legendaries[_legendary]);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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