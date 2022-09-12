/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

pragma solidity ^0.8.11;

// SPDX-License-Identifier: MIT
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


interface ve {
  function balanceOfNFT(uint _tokenId) external view returns (uint);
  function ownerOf(uint _tokenId) external view returns (address);
}

contract TreasuryVoter is Ownable {
  address public _ve;

  uint public totalVotes;

  mapping(address => uint) public votesPerPool;
  mapping(uint => uint) public votesPerNft;
  mapping(uint => bool) public isNftVoted;

  // white list for LD
  mapping(address => bool) public LDWhiteList;

  constructor(address __ve) {
    _ve = __ve;
  }

  // vote
  function vote(address _pool, uint _tokenId) public {
    require(LDWhiteList[_pool], "NOT in white list");
    require(!isNftVoted[_tokenId], "NFT ID voted");
    require(ve(_ve).ownerOf(_tokenId) == msg.sender, "Not owner");

    uint256 userBalance = ve(_ve).balanceOfNFT(_tokenId);
    require(userBalance > 0, "0 vote");

    votesPerPool[_pool] = votesPerPool[_pool] + userBalance;
    totalVotes += userBalance;
    votesPerNft[_tokenId] = userBalance;
    isNftVoted[_tokenId] = true;
  }

  // unvote
  function unvote(address _pool, uint _tokenId) public {
    require(isNftVoted[_tokenId], "NFT ID not voted");
    require(ve(_ve).ownerOf(_tokenId) == msg.sender, "Not owner");

    votesPerPool[_pool] = votesPerPool[_pool] - votesPerNft[_tokenId];
    totalVotes -= votesPerNft[_tokenId];

    votesPerNft[_tokenId] = 0;
    isNftVoted[_tokenId] = false;
  }

  // allow re-vote or update ve vote balance
  function revote(address _poolOld, uint _tokenId, address _poolNew) external {
    unvote(_poolOld, _tokenId);
    vote(_poolNew, _tokenId);
  }

  function updateWhiteList(address _LD, bool _status) external onlyOwner {
    LDWhiteList[_LD] = _status;
  }
}