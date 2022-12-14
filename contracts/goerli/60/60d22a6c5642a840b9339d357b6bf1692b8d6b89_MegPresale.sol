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

pragma solidity 0.8.4;

interface IMintableNFT {
  function mint(address _to, uint256 _id) external; /* onlyRole(MINTER_ROLE) */

  function bulkMint(address _to, uint256[] memory _ids) external; /* onlyRole(MINTER_ROLE) */

  function changeLandToPremium(uint256 _id) external; /* onlyRole(MINTER_ROLE) */

  function bulkChangeLandToPremium(uint256[] memory _ids) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IMintableNFT.sol";
import "./utils/blacklist.sol";

contract MegPresale is OwnableUpgradeable, Blacklist {
  /// @dev Address of NFT contract
  IMintableNFT public megNFT;
  /// @dev Start date of presale
  uint256 public startTime;
  /// @dev End date of presale
  uint256 public endTime;
  /// @dev From NFT Id
  uint256 public fromId;
  /// @dev To NFT Id
  uint256 public toId;
  /// @dev Total participants
  uint256 public totalParticipant;
  /// @dev Total NFTs minted
  uint256 public totalNFT;

  event Buy(address indexed user, uint256 id);
  event WithdrawETHBalance(address _sender, uint256 _balance);

  /**
   * @dev Constructor
   * @param _megNFT Address of meg NFT
   * @param _startTime Start date of presale
   * @param _endTime End date of presale
   * @param _fromId From NFT Id
   * @param _toId To NFT Id
   */
  function __MegPresale_init(
    IMintableNFT _megNFT,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _fromId,
    uint256 _toId
  )  external initializer {
    __Ownable_init();
    megNFT = _megNFT;
    startTime = _startTime;
    endTime = _endTime;
    fromId = _fromId;
    toId = _toId;
  }

  /**
   * @dev Change the address of the meg NFT
   * @param _megNFT Address of meg NFT Token
   */
  function changeNFT(IMintableNFT _megNFT) external onlyOwner {
    megNFT = _megNFT;
  }

  /**
   * @dev Change dates of pre sales
   * @param _startTime Start date of presale
   * @param _endTime End date of presale
   */
  function changeDates(uint256 _startTime, uint256 _endTime) external onlyOwner {
    startTime = _startTime;
    endTime = _endTime;
  }

  /**
   * @dev Change from and to Id
   * @param _fromId From NFT Id
   * @param _toId To NFT Id
   */
  function changeFromAndToId(uint256 _fromId, uint256 _toId) external onlyOwner {
    fromId = _fromId;
    toId = _toId;
  }

  /**
   * @dev Owner can withdraw all ETH
   */
  function withdrawETHBalance() external onlyOwner {
    address payable sender = payable(_msgSender());

    uint256 balance = address(this).balance;
    sender.transfer(balance);

    // Emit event
    emit WithdrawETHBalance(sender, balance);
  }

  /**
   * @dev Add blacklist to the contract
   * @param _addresses Array of addresses
   */
  function addBlacklist(address[] memory _addresses) external onlyOwner {
    _addBlacklist(_addresses);
  }

  /**
   * @dev Remove blacklist from the contract
   * @param _addresses Array of addresses
   */
  function removeBlacklist(address[] memory _addresses) external onlyOwner {
    _removeBlacklist(_addresses);
  }

  /**
   * @dev Return true if presale started
   */
  function isStart() public view returns (bool) {
    return block.timestamp >= startTime && block.timestamp <= endTime;
  }

  /**
   * @dev Buy a presale NFT
   * @param _amount Token id of NFT
   * Required Statements
   * - MNR:_buy01 Address is in blacklist
   * - MNR:_buy02 Prsale is not started
   * - MNR:_buy03 Invalid amount
   */
  function _buy(uint256 _amount) internal {
    address sender_ = _msgSender();
    require(blacklist[sender_] == false, "MNR:_buy01");
    require(isStart(), "MNR:_buy02");
    require((fromId + totalNFT + _amount) - 1 <= toId, "MNR:_buy03");

    uint256 count_;
    for (uint256 id_ = fromId + totalNFT; count_ < _amount && id_ <= toId; id_++) {
      megNFT.mint(sender_, id_);
      totalNFT = totalNFT + 1;
      count_ = count_ + 1;
      emit Buy(sender_, id_);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title Blacklist
 *
 * @notice This contract is the implementation of blacklist
 *
 * @dev This contract contains logic is only used by owner */

contract Blacklist {
  /// @dev blacklist map
  mapping(address => bool) public blacklist;

  event AddBlackList(address[] _addresses);
  event RemoveBlackList(address[] _addresses);

  /**
   * @dev Add blacklist to the contract
   * @param _addresses Array of addresses
   */
  function _addBlacklist(address[] memory _addresses) internal {
    uint256 addressesLength_ = _addresses.length;
    for (uint256 i; i < addressesLength_; i++) {
      blacklist[_addresses[i]] = true;
    }
    emit AddBlackList(_addresses);
  }

  /**
   * @dev Remove blacklist from the contract
   * @param _addresses Array of addresses
   */
  function _removeBlacklist(address[] memory _addresses) internal {
    uint256 addressesLength_ = _addresses.length;
    for (uint256 i; i < addressesLength_; i++) {
      blacklist[_addresses[i]] = false;
    }
    emit RemoveBlackList(_addresses);
  }
}