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

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';

import './interfaces/ITheFarmGameMint.sol';

contract Randomizer is Ownable {
  uint256 private randomResult;

  ITheFarmGameMint private theFarmGameMint; // Ref to TheFarmGameMint contract

  constructor() {
    randomResult = uint256(keccak256(abi.encodePacked(blockhash(block.number - 5))));
  }

  function random() external view returns (uint256) {
    uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), randomResult)));
    return seed;
  }

  function randomToken(uint256 _tokenId) external view returns (uint256) {
    uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), randomResult, _tokenId)));
    return seed;
  }

  function updateCommitRand() external {
    randomResult = uint256(keccak256(abi.encodePacked(blockhash(block.number - 3))));
    uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), randomResult)));
    theFarmGameMint.addCommitRandom(seed);
  }

  function getRand() external view returns (uint256) {
    return randomResult;
  }

  function setTheFarmGameMint(address _address) external onlyOwner {
    theFarmGameMint = ITheFarmGameMint(_address);
  }
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface ITheFarmGameMint {
  function addCommitRandom(uint256 seed) external;

  function canMint() external view returns (bool);

  function getSaleStatus() external view returns (string memory);

  function mint(uint256 quantity, bool stake) external payable;

  function mintCommit(uint256 quantity, bool stake) external;

  function mintCostEGG(uint256 tokenId) external view returns (uint256);

  function mintReveal() external;

  function paused() external view returns (bool);

  function preSaleMint(
    uint256 quantity,
    bool stake,
    bytes32[] memory merkleProof,
    uint256 maxQuantity,
    uint256 priceInWei
  ) external payable;

  function preSaleTokens() external view returns (uint256);

  function preSalePrice() external view returns (uint256);
}