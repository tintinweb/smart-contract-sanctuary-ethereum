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
pragma solidity >=0.8.4;
import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);
}

interface IERC721 {
  function transferFrom(address from, address to, uint256 tokenId) external;

  function ownerOf(uint256 tokenId) external view returns (address);

  function setApprovalForAll(address operator, bool approved) external;
}

interface IOfficialApeStaking {
  struct SingleNft {
    uint32 tokenId;
    uint224 amount;
  }

  function depositBAYC(SingleNft[] calldata _nfts) external;

  function depositMAYC(SingleNft[] calldata _nfts) external;

  function claimSelfBAYC(uint256[] calldata _nfts) external;

  function claimSelfMAYC(uint256[] calldata _nfts) external;

  function withdrawSelfBAYC(SingleNft[] calldata _nfts) external;

  function withdrawSelfMAYC(SingleNft[] calldata _nfts) external;
}

contract ApeStaking is Ownable {
  address public constant BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
  address public constant MAYC = 0x60E4d786628Fea6478F785A6d7e704777c86a7c6;
  address public constant OfficialStaking = 0x5954aB967Bc958940b7EB73ee84797Dc8a2AFbb9;
  address public constant ApeCoin = 0x4d224452801ACEd8B2F0aebE155379bb5D594381;
  uint256 public constant BAYCApeAmount = 10094 * 1e18;
  uint256 public constant MAYCApeAmount = 2042 * 1e18;
  uint256 public constant funderShare = 70;
  address public funder;
  address public funderRewardReceiver;
  address public apeHolderRewardReceiver;

  constructor(address _apeHolder, address _apeHolderRewardReceiver, address _funder, address _funderRewardReceiver) {
    apeHolderRewardReceiver = _apeHolderRewardReceiver;
    funder = _funder;
    funderRewardReceiver = _funderRewardReceiver;

    IERC20(ApeCoin).approve(OfficialStaking, type(uint256).max);
    transferOwnership(_apeHolder);
  }

  modifier onlyAdmin() {
    require(msg.sender == owner() || msg.sender == funder, "Not authorized");
    _;
  }

  function register(address project, uint256 tokenId) external onlyAdmin {
    IOfficialApeStaking.SingleNft[] memory nfts = new IOfficialApeStaking.SingleNft[](1);
    nfts[0].tokenId = uint32(tokenId);
    if (project == BAYC) {
      nfts[0].amount = uint224(BAYCApeAmount);
      IERC20(ApeCoin).transferFrom(funder, address(this), BAYCApeAmount);
      IERC721(BAYC).transferFrom(owner(), address(this), tokenId);
      IOfficialApeStaking(OfficialStaking).depositBAYC(nfts);
    } else if (project == MAYC) {
      nfts[0].amount = uint224(MAYCApeAmount);
      IERC20(ApeCoin).transferFrom(funder, address(this), MAYCApeAmount);
      IERC721(MAYC).transferFrom(owner(), address(this), tokenId);
      IOfficialApeStaking(OfficialStaking).depositMAYC(nfts);
    }
  }

  function withdraw(address project, uint256 tokenId) external onlyAdmin {
    IOfficialApeStaking.SingleNft[] memory nfts = new IOfficialApeStaking.SingleNft[](1);
    nfts[0].tokenId = uint32(tokenId);
    if (project == BAYC) {
      nfts[0].amount = uint224(BAYCApeAmount);
      IOfficialApeStaking(OfficialStaking).withdrawSelfBAYC(nfts);
      IERC20(ApeCoin).transfer(funder, BAYCApeAmount);
    } else if (project == MAYC) {
      nfts[0].amount = uint224(MAYCApeAmount);
      IOfficialApeStaking(OfficialStaking).withdrawSelfMAYC(nfts);
      IERC20(ApeCoin).transfer(funder, MAYCApeAmount);
    }
    _distributeReward(IERC20(ApeCoin).balanceOf(address(this)));
    IERC721(project).transferFrom(address(this), owner(), tokenId);
  }

  function claim(address project, uint256 tokenId) external {
    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = tokenId;
    if (project == BAYC) {
      IOfficialApeStaking(OfficialStaking).claimSelfBAYC(tokenIds);
    } else if (project == MAYC) {
      IOfficialApeStaking(OfficialStaking).claimSelfMAYC(tokenIds);
    }
    _distributeReward(IERC20(ApeCoin).balanceOf(address(this)));
  }

  function _distributeReward(uint256 rewardAmount) internal {
    if (rewardAmount == 0) return;
    uint256 rewardToFunder = (rewardAmount * funderShare) / 100;
    uint256 rewardToApeHolder = rewardAmount - rewardToFunder;
    IERC20(ApeCoin).transfer(funderRewardReceiver, rewardToFunder);
    IERC20(ApeCoin).transfer(apeHolderRewardReceiver, rewardToApeHolder);
  }
}

contract ApeStakingFactory {
  mapping(address => address) public stakingsContracts;
  event Create(address indexed apeHolder, address funder, address stakingContract);

  function create(
    address _apeHolder,
    address _apeHolderRewardReceiver,
    address _funder,
    address _funderRewardReceiver
  ) external returns (address) {
    require(stakingsContracts[_apeHolder] == address(0), "Already created");
    ApeStaking apeStaking = new ApeStaking(_apeHolder, _apeHolderRewardReceiver, _funder, _funderRewardReceiver);
    stakingsContracts[_apeHolder] = address(apeStaking);
    emit Create(_apeHolder, _funder, address(apeStaking));
    return address(apeStaking);
  }
}