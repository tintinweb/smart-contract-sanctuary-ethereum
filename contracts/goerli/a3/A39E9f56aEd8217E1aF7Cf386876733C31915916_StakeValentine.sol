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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

interface Valentine {
  function ownerOf(uint256 tokenId) external view returns (address);
  function transferFrom(address sender, address recipient, uint256 tokenId) external;    
  function balanceOf(address owner) external view returns (uint256);
}

contract StakeValentine is Ownable {
  Valentine private ValentineERC721;

  bool private canWhalesStake = false;
  bool private canHoldersStake = false;
  uint256 private minimumStakeDurationInSeconds;

  struct StakeMetadata {
    uint256 tokenId;
    uint256 startTimestamp;
    uint256 minimumStakeDurationEndTimestamp;
    address stakedBy;
    bool active;
  }
  
  mapping(uint256 => StakeMetadata) public stakedTokens;

  event Staked(address indexed from, StakeMetadata stakedInfo);
  event Claimed(address indexed from, StakeMetadata stakedInfo);

  constructor(address _valentineAddress, uint256 _minimumStakeDurationInSeconds) {
    require(_valentineAddress != address(0), "Valentine to stake needs to have non-zero address.");                
    ValentineERC721 = Valentine(_valentineAddress);
    minimumStakeDurationInSeconds = _minimumStakeDurationInSeconds;
  }

  function stakeToken(uint256[] calldata _tokenIds) external {
    require(_tokenIds.length > 0, "NFT's to stake should be greater than 0");
    require(canHoldersStake || (canWhalesStake && ValentineERC721.balanceOf(msg.sender) >= 5));

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      require(ValentineERC721.ownerOf(_tokenIds[i]) == msg.sender);

      StakeMetadata memory stakeInfo = StakeMetadata({                
        startTimestamp: block.timestamp,
        minimumStakeDurationEndTimestamp: block.timestamp + minimumStakeDurationInSeconds,
        stakedBy: msg.sender,
        tokenId: _tokenIds[i],
        active: true
      });

      stakedTokens[_tokenIds[i]] = stakeInfo;

      ValentineERC721.transferFrom(msg.sender, address(this), _tokenIds[i]);

      emit Staked(msg.sender, stakeInfo);
    }
  }    

  function withdrawToken(uint256[] calldata _tokenIds) external {
    require(_tokenIds.length > 0, "NFT's to withdraw should be greater than 0");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      StakeMetadata memory stakeInfo = stakedTokens[_tokenIds[i]];
      require(stakeInfo.active == true, "This token is not staked");
      require((stakeInfo.stakedBy == msg.sender && stakeInfo.minimumStakeDurationEndTimestamp < block.timestamp) 
      || msg.sender == owner());

      StakeMetadata memory defaultStakeInfo;
      stakedTokens[_tokenIds[i]] = defaultStakeInfo;

      ValentineERC721.transferFrom(address(this), stakeInfo.stakedBy, _tokenIds[i]);

      emit Claimed(stakeInfo.stakedBy, stakeInfo);
    }
  }

  function setCanWhalesStake(bool _can) external onlyOwner {
    canWhalesStake = _can;
  }

  function getCanWhalesStake() external view returns (bool) {
    return canWhalesStake;
  }

  function setCanHoldersStake(bool _can) external onlyOwner {
    canHoldersStake = _can;
  }

  function getCanHoldersStake() external view returns (bool) {
    return canHoldersStake;
  }

  function setMinimumStakeDuration(uint256 _durationInSeconds) external onlyOwner {
    minimumStakeDurationInSeconds = _durationInSeconds;
  }

  function getMinimumStakeDuration() external view returns (uint256) {
    return minimumStakeDurationInSeconds;
  }
}