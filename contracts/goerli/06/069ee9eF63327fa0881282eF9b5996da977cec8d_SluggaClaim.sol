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
pragma solidity ^0.8;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
  function mint(address _to) external;

  function burn(uint256 _tokenId) external;

  function ownerOf(uint256 _tokenId) external view returns (address);
}

// must be granted burner role by access token
contract SluggaClaim is Ownable {
  address public accessToken;
  address public erc721Token;

  bool public claimStarted;

  /// @notice Constructor for the ONFT
  /// @param _accessToken address for the nft used to claim via burn
  /// @param _erc721Token address for nft to be minted
  constructor(address _accessToken, address _erc721Token) {
    accessToken = _accessToken;
    erc721Token = _erc721Token;
  }

  function claim(uint256 _tokenId) public {
    require(claimStarted, "Claim period has not begun");
    address owner = IERC721(accessToken).ownerOf(_tokenId);
    require(owner == msg.sender, "Must be access token owner");
    IERC721(accessToken).burn(_tokenId);
    issueToken(msg.sender);
  }

  function claimBatch(uint256[] memory _tokenIds) public {
    require(claimStarted, "Claim period has not begun");
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      address owner = IERC721(accessToken).ownerOf(_tokenIds[i]);
      require(owner == msg.sender, "Must be access token owner");
      IERC721(accessToken).burn(_tokenIds[i]);
      issueToken(msg.sender);
    }
  }

  function issueToken(address _to) internal {
    IERC721(erc721Token).mint(_to);
  }

  function setClaimStart(bool _isStarted) public onlyOwner {
    claimStarted = _isStarted;
  }

  function setERC721(address _erc721Token) public onlyOwner {
    erc721Token = _erc721Token;
  }

  function setAccessToken(address _accessToken) public onlyOwner {
    accessToken = _accessToken;
  }
}