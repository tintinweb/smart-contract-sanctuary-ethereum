/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



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

interface IDelegatedMintable {
  function mint(address recipient, uint256 tokenId) external;
  function mintMany(address recipient, uint256 tokenIdStart, uint256 count) external;
  function totalSupply() external view returns(uint256);
}

contract FCFSMinter is Ownable {
  /**
   * @notice Thrown when the price sent is incorrect.
   */
  error IncorrectPrice();

  /**
   * @notice Thrown when minting is paused.
   */
  error Paused();

  /**
   * @notice Thrown when there are no more tokens left.
   */
  error SupplyExhausted();

  /**
   * @notice The token we are minting.
   */
  IDelegatedMintable public token;

  /**
   * @notice The price per token.
   */
  uint256 public price;

  /**
   * @notice Amount of tokens remaining.
   */
  uint256 public remainingSupply;

  /**
   * @notice Whether or not minting is paused.
   */
  bool public paused;

  /**
   * @notice The beneficiary of minting proceeds.
   */
  address public beneficiary;

  constructor(
    address _token,
    uint256 _price,
    address _beneficiary,
    uint256 _supply
  ) {
    token = IDelegatedMintable(_token);
    remainingSupply = _supply;
    price = _price;
    beneficiary = _beneficiary;
  }

  function mint(uint256 amount) external payable {
    if (paused) {
      revert Paused();
    }

    if (amount > remainingSupply) {
      revert SupplyExhausted();
    }

    if (msg.value != price * amount) {
      revert IncorrectPrice();
    }

    remainingSupply -= amount;
    token.mintMany(msg.sender, token.totalSupply(), amount);
  }

  /**
   * @notice Pause or unpause the contract.
   */
  function setPaused(bool pause) external onlyOwner {
    paused = pause;
  }

  /**
   * @notice Set the mint price.
   */
  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  /**
   * @notice Set the remaining supply. The new remaining supply must be lower than
   * the current remaining supply.
   */
  function setRemainingSupply(uint256 _remaingSupply) external onlyOwner {
    require(_remaingSupply < remainingSupply);
    remainingSupply = _remaingSupply;
  }

  /**
   * @notice Withdraw funds to the beneficiary address.
   */
  function withdraw() external onlyOwner {
    (bool success,) = beneficiary.call{value: address(this).balance}("");
    require(success);
  }
}