// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IMetaStreetApesNFT.sol";

contract MetaStreetApesPresale is
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable
{
  struct Config {
    uint256 startTime;
    uint256 endTime;
    uint256 supply;
    uint256 price;
    uint256 maxNFTAllowed;
  }

  Config public privateConfig;
  Config public publicConfig;
  mapping(address => uint256) public userPrivateCount;
  mapping(address => uint256) public userPublicCount;

  uint256 public privateCount;
  uint256 public publicCount;

  IMetaStreetApesNFT public nft;

  event SetSaleConfig(uint256 _startTime, uint256 _endTime, uint256 _supply, uint256 _price);
  event WithdrawETH(address indexed _sender, uint256 _balance);
  event Buy(address indexed _sender, uint256 _numberOfNft);

  /**
   * @dev Upgradable initializer
   */
  function __MetaStreetApesPresale_init(IMetaStreetApesNFT _nft) external initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    nft = _nft;
  }

  /**
   * @notice Set parameters for private sale
   * @dev Only callable by owner
   * @param _startTime Start time of sale
   * @param _endTime End time of sale
   * @param _supply Total Supply
   * @param _price Price of round
   * @param _maxNFTAllowed Max allowed NFT by user
   */
  function setPrivateSaleConfig(
    uint256 _startTime,
    uint256 _endTime,
    uint256 _supply,
    uint256 _price,
    uint256 _maxNFTAllowed
  ) external onlyOwner {
    privateConfig = Config(_startTime, _endTime, _supply, _price, _maxNFTAllowed);
    emit SetSaleConfig(_startTime, _endTime, _supply, _price);
  }

  /**
   * @notice Set parameters for public sale
   * @dev Only callable by owner
   * @param _startTime Start time of sale
   * @param _endTime End time of sale
   * @param _supply Total Supply
   * @param _price Price of round
   * @param _maxNFTAllowed Max allowed NFT by user
   */
  function setPublicSaleConfig(
    uint256 _startTime,
    uint256 _endTime,
    uint256 _supply,
    uint256 _price,
    uint256 _maxNFTAllowed
  ) external onlyOwner {
    publicConfig = Config(_startTime, _endTime, _supply, _price, _maxNFTAllowed);

    emit SetSaleConfig(_startTime, _endTime, _supply, _price);
  }

  /**
   * @notice Withdraw all Eth
   * @dev Only callable by owner
   */
  function withdrawETH() external onlyOwner {
    address payable sender_ = payable(_msgSender());

    uint256 balance_ = address(this).balance;
    sender_.transfer(balance_);

    emit WithdrawETH(sender_, balance_);
  }

  /**
   * @notice buy NFT in Private round
   * @dev Anyone can call this function
   * @param _numberOfNft Total number nft to buy
   * @dev Error Details
   * - 0x1: User in black list
   * - 0x2: There is no public sale running
   * - 0x3: Invalid price
   * - 0x4: User can't be muy more than max nft allowed
   * - 0x5: User can't buy more than public supply
   */
  function buyPrivate(uint256 _numberOfNft) external payable nonReentrant {
    address sender_ = _msgSender();
    require(block.timestamp > privateConfig.startTime && block.timestamp < privateConfig.endTime, "0x2");
    require(msg.value >= privateConfig.price * _numberOfNft, "0x3");
    require(userPrivateCount[sender_] + _numberOfNft <= privateConfig.maxNFTAllowed, "0x4");
    require(privateCount + _numberOfNft <= privateConfig.supply, "0x5");

    nft.bulkMint(_numberOfNft, sender_);
    userPrivateCount[sender_] = userPrivateCount[sender_] + _numberOfNft;
    privateCount = privateCount + _numberOfNft;

    emit Buy(sender_, _numberOfNft);
  }

  /**
   * @notice buy NFT in Private round
   * @dev Anyone can call this function
   * @param _numberOfNft Total number nft to buy
   * @dev Error Details
   * - 0x1: User in black list
   * - 0x2: There is no public sale running
   * - 0x3: Invalid price
   * - 0x4: User can't be muy more than max nft allowed
   * - 0x5: User can't buy more than public supply
   */
  function buyPublic(uint256 _numberOfNft) external payable nonReentrant {
    address sender_ = _msgSender();
    require(block.timestamp > publicConfig.startTime && block.timestamp < publicConfig.endTime, "0x2");
    require(msg.value >= publicConfig.price * _numberOfNft, "0x3");
    require(userPublicCount[sender_] + _numberOfNft <= publicConfig.maxNFTAllowed, "0x4");
    require(publicCount + _numberOfNft <= publicConfig.supply, "0x5");

    nft.bulkMint(_numberOfNft, sender_);
    userPublicCount[sender_] = userPublicCount[sender_] + _numberOfNft;
    publicCount = publicCount + _numberOfNft;

    emit Buy(sender_, _numberOfNft);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IMetaStreetApesNFT {
  function mint(address _to) external returns (uint256);

  function bulkMint(uint256 _numberOfNft, address _to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}