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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IKitBag {
  function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
  function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes calldata data) external;
}

interface IMPL {
  function balanceOf(address account) external view returns (uint256);
}

function getOneArray(uint256 length) pure returns (uint256[] memory arr) {
  arr = new uint[](length);
  for (uint i = 0; i < length; i++) {
    arr[i] = 1;
  }
}

contract RedCard is Ownable, Pausable {

    IKitBag public kitBag;  // KitBag contract
    IMPL public mpl; // MPL contract

    uint8[2] public cutoffs = [5, 11]; // MPL balance cutoffs to receive multiple comics (1 / 2 / 3)
    uint8[2] public odds = [169, 225]; // Odds of receiving different comics. We use the same odds across comics
    mapping(uint8 => bool) baseIds; // Base IDs of comic covers that can be minted (comic covers come in threes)
    mapping(uint8 => mapping(address => bool)) public claimed; // Whether addresses have claimed different comics

    bool public allowMultipleClaims = false; // Whether users can claim multiple comics

    constructor(
        address _kitBag, address _mpl, uint8[] memory _baseIds
    ) {
        kitBag = IKitBag(_kitBag);
        mpl = IMPL(_mpl);

        for (uint8 i = 0; i < _baseIds.length; i++) {
            baseIds[_baseIds[i]] = true;
        }
    }

    function setBaseId(uint8 _baseId, bool _setting) external onlyOwner {
      baseIds[_baseId] = _setting;
    }

    function setCutoffs(uint8[2] memory _cutoffs) external onlyOwner {
      require(_cutoffs[0] < _cutoffs[1], "RedCard: invalid cutoffs");
      cutoffs = _cutoffs;
    }

    function setOdds(uint8[2] memory _odds) external onlyOwner {
      require(_odds[0] < _odds[1], "Redcard: invalid odds");
      odds = _odds;
    }

    function setAllowMultipleClaims(bool _allowMultipleClaims) external onlyOwner {
      allowMultipleClaims = _allowMultipleClaims;
    }
  
    function mint(uint8 baseId) public whenNotPaused {
      require(baseIds[baseId], "RedCard: not a valid baseId");
      require(!claimed[baseId][msg.sender] || allowMultipleClaims, "RedCard: already claimed");

      uint256 balance = mpl.balanceOf(msg.sender);
      require(balance > 0, "RedCard: no MPLs!");

      uint256 pseudoRandom = uint8(uint256(keccak256(abi.encode(blockhash(block.number-1), address(this), msg.sender))));

      uint256 randomId;
      
      if(balance < cutoffs[0]) {

        if(pseudoRandom < odds[0]) {
          randomId = baseId;
        } else if (pseudoRandom < odds[1]) {
          randomId = baseId + 1;
        } else {
          randomId = baseId + 2;
        }

        kitBag.mint(msg.sender, randomId, 1, "0x");
      } else if (balance < cutoffs[1]) {
        randomId = pseudoRandom < odds[0] ? baseId + 1 : baseId + 2;
        uint[] memory ids = new uint[](2);
        ids[0] = baseId;
        ids[1] = randomId;
        kitBag.mintBatch(msg.sender, ids, getOneArray(2), "0x");
      } else {
        uint[] memory ids = new uint[](3);
        ids[0] = baseId;
        ids[1] = baseId + 1;
        ids[2] = baseId + 2;
        kitBag.mintBatch(msg.sender, ids, getOneArray(3), "0x");
      }
      
      claimed[baseId][msg.sender] = true;
    }

    function setPaused(bool _bPaused) external onlyOwner {
        if (_bPaused) _pause();
        else _unpause();
    }

}