//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address _to, uint256 _amount) external returns (bool);
}

contract FeeSplitter is Ownable {
  event Received(address, uint);

  address public communityFundAddress = address(0);
  address public teamFundAddress = address(0);

  uint256 public communityFundRateMultiplier = 1;
  uint256 public communityFundRateDivider = 2;

  uint256 public totalFeeReceived = 0;
  uint256 public totalCommunityFundFeeReceived = 0;
  uint256 public totalTeamFundReceived = 0;

  constructor() {
  }

  function setCommunityFundAddress(address addr) public onlyOwner {
    communityFundAddress = addr;
  }

  function setTeamFundAddress(address addr) public onlyOwner {
    teamFundAddress = addr;
  }

  function setCommunityFundRateMultiplier(uint256 multiplier) public onlyOwner {
    communityFundRateMultiplier = multiplier;
  }

  function setCommunityFundRateDivider(uint256 divider) public onlyOwner {
    communityFundRateDivider = divider;
  }

  ////////////////////////////////////////////////////
  // Withdrawal, in case if there is something wrong
  ////////////////////////////////////////////////////

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawToken(address tokenAddress) public onlyOwner {
    IERC20 tokenContract = IERC20(tokenAddress);
    tokenContract.transfer(msg.sender, tokenContract.balanceOf(address(this)));
  }

  /////////////
  // Fallback
  /////////////

  receive() external payable {
    require(communityFundAddress != address(0), "Community fund address is not yet set");
    require(teamFundAddress != address(0), "Team fund address is not yet set");

    uint256 to_public_goods = msg.value * communityFundRateMultiplier / communityFundRateDivider;
    uint256 to_team = msg.value - to_public_goods;

    payable(communityFundAddress).transfer(to_public_goods);
    payable(teamFundAddress).transfer(to_team);

    totalFeeReceived = totalFeeReceived + msg.value;
    totalCommunityFundFeeReceived = totalCommunityFundFeeReceived + to_public_goods;
    totalTeamFundReceived = totalTeamFundReceived + to_team;

    emit Received(msg.sender, msg.value);
  }
}

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