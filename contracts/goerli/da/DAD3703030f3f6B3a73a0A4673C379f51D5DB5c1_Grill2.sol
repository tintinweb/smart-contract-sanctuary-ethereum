//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

error CallerBlacklisted();
error CallerNotTokenOwner();
error CallerNotTokenStaker();
error StakingNotActive();
error ZeroEmissionRate();

/**
 * Interfaces astrobull contract
 */
interface ISUPER1155 {
  function balanceOf(address _owner, uint256 _id)
    external
    view
    returns (uint256);

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes calldata _data
  ) external;

  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) external;
}

/**
 * Interfaces old grill contract
 */
interface IGRILL {
  struct Stake {
    bool status;
    address staker;
    uint256 timestamp;
  }

  function getStake(uint256 _tokenId)
    external
    view
    returns (Stake memory _stake);

  function getIdsOfAddr(address _operator)
    external
    view
    returns (uint256[] memory _addrStakes);
}

/**
 * @title Grill2.0
 * @author Matt Carter, degendeveloper.eth
 * 6 June, 2022
 *
 * The purpose of this contract is to optimize gas consumption when adding new stakes and
 * removing previous stakes from the initial grill contract @ 0xE11AF478aF241FAb926f4c111d50139Ae003F7fd.
 *
 * Users will use this new grill contract when adding and removing stakes. This new contract
 * is also responsible for counting emission tokens and setting new emission rates.
 *
 * This contract is whitelisted to move the first grill's tokens via proxy registry in the super1155 contract.
 *
 * This contract should be set as the `proxyRegistryAddress` in the parent contract. This
 * allows the new grill to move tokens on behalf of the old grill.
 */
contract Grill2 is Ownable, ERC1155Holder {
  using Counters for Counters.Counter;
  uint256 internal constant MAX_INT = 2**256 - 1;
  /// contract instances ///
  ISUPER1155 public constant Parent =
    ISUPER1155(0x71B11Ac923C967CD5998F23F6dae0d779A6ac8Af);
  IGRILL public immutable OldGrill;
  /// the number of times the emission rate changes ///
  Counters.Counter internal emChanges;
  /// is adding stakes allowed ///
  bool public isStaking = true;
  /// the number of stakes added & removed by each account (this contract) ///
  mapping(address => Counters.Counter) internal stakesAddedPerAccount;
  mapping(address => Counters.Counter) internal stakesRemovedPerAccount;
  /// each Stake by tokenId (this contract) ///
  mapping(uint256 => Stake) public stakeStorage;
  /// each tokenId by index for an account (this contract) ///
  mapping(address => mapping(uint256 => uint256)) public accountStakes;
  /// each Emission by index (this contract) ///
  mapping(uint256 => Emission) public emissionStorage;
  /// the number of emission tokens earned be each account from removed stakes ///
  mapping(address => uint256) public unstakedClaims;
  /// accounts that can not add new stakes ///
  mapping(address => bool) public blacklist;
  /// list of new proxies for Parent tokens ///
  mapping(address => address) public proxies;

  /**
   * Stores information for an emission change
   * @param rate The number of seconds to earn 1 emission token
   * @param timestamp The block.timestamp this emission rate is set
   */
  struct Emission {
    uint256 rate;
    uint256 timestamp;
  }

  /**
   * Stores information for a stake
   * @param staker The address who creates this stake
   * @param timestamp The block.timestamp this stake is created
   * @param accountSlot The index for this stake in `accountStakes`
   */
  struct Stake {
    address staker;
    uint256 timestamp;
    uint256 accountSlot;
  }

  /// ============ CONSTRUCTOR ============ ///

  /**
   * Initializes contract instances and sets the initial emission rate
   * @param _grillAddr The address for the first grill contract
   * @notice `1652054400` is Mon, 09 May 2022 00:00:00 GMT
   * @notice '3600 * 24 * 45' is the number of seconds in 45 days
   */
  constructor(address _grillAddr) {
    OldGrill = IGRILL(_grillAddr);
    emissionStorage[emChanges.current()] = Emission(3600 * 24 * 45, 1652054400);
  }

  /// ============ OWNER ============ ///

  /**
   * Sets a proxy transferer for `account`s tokens
   * @param account The address whose tokens to move
   * @param operator The address being proxied as an approved operator for `account`
   * @notice The team will use this contract as a proxy for old grill tokens
   */
  function setProxyForAccount(address account, address operator)
    public
    onlyOwner
  {
    proxies[account] = operator;
  }

  /**
   * Removes a proxy transferer for `account`s tokens
   * @param account The address losing its proxy transferer
   */
  function removeProxyForAccount(address account) public onlyOwner {
    delete proxies[account];
  }

  /**
   * Allows/unallows the addition of new stakes
   */
  function toggleStaking() public onlyOwner {
    isStaking = !isStaking;
  }

  /**
   * Allows/unallows an account to add new stakes
   * @param account The address to set status for
   * @param status The status being set
   * @notice A staker is always able to remove their stakes regardless of blacklist status
   */
  function blacklistAccount(address account, bool status) public onlyOwner {
    blacklist[account] = status;
  }

  /**
   * Stops emission token counting by setting an emission rate of the max-int number of seconds
   * @notice No tokens can be earned with an emission rate this long
   * @notice To continue emissions counting, the owner must set a new emission rate
   */
  function pauseEmissions() public onlyOwner {
    _setEmissionRate(MAX_INT);
  }

  /**
   * Sets a new rate for earning emission tokens
   * @param _seconds The number of seconds a token must be staked for to earn 1 emission token
   */
  function setEmissionRate(uint256 _seconds) public onlyOwner {
    _setEmissionRate(_seconds);
  }

  /// ============ PUBLIC ============ ///

  /**
   * Stakes an array of tokenIds with this contract to earn emission tokens
   * @param tokenIds An array of tokenIds to stake
   * @param amounts An array of amounts of each tokenId to stake
   * @notice Caller must `setApprovalForAll()` to true in the parent contract using this contract's address
   * before it can move their tokens
   */
  function addStakes(uint256[] memory tokenIds, uint256[] memory amounts)
    public
  {
    if (!isStaking) {
      revert StakingNotActive();
    }
    if (blacklist[msg.sender]) {
      revert CallerBlacklisted();
    }
    /// @dev verifies caller owns each token ///
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      uint256 _tokenId = tokenIds[i];
      if (Parent.balanceOf(msg.sender, _tokenId) == 0) {
        revert CallerNotTokenOwner();
      }
      /// @dev sets contract state ///
      _addStake(msg.sender, _tokenId);
    }
    /// @dev transfers tokens from caller to this contract ///
    Parent.safeBatchTransferFrom(
      msg.sender,
      address(this),
      tokenIds,
      amounts,
      "0x00"
    );
  }

  /**
   * Removes an array of tokenIds staked in this contract and/or the old one
   * @param oldTokenIds The tokenIds being unstaked from the old contract
   * @param oldAmounts The number of each token being unstaked
   * @param newTokenIds The tokenIds being unstaked from this contract
   * @param newAmounts The number of each token being unstaked
   */
  function removeStakes(
    uint256[] memory oldTokenIds,
    uint256[] memory oldAmounts,
    uint256[] memory newTokenIds,
    uint256[] memory newAmounts
  ) public {
    if (oldTokenIds.length > 0) {
      /// @dev verifies caller staked each token ///
      for (uint256 i = 0; i < oldTokenIds.length; ++i) {
        uint256 _tokenId = oldTokenIds[i];
        IGRILL.Stake memory _thisStake = OldGrill.getStake(_tokenId);
        if (_thisStake.staker != msg.sender) {
          revert CallerNotTokenStaker();
        }
        /// @dev increments emissions earned for caller ///
        unstakedClaims[msg.sender] += countEmissions(_thisStake.timestamp);
      }
      /// @dev transfers tokens from old contract to caller ///
      Parent.safeBatchTransferFrom(
        address(OldGrill),
        msg.sender,
        oldTokenIds,
        oldAmounts,
        "0x00"
      );
    }
    if (newTokenIds.length > 0) {
      /// @dev verifies caller staked each token ///
      for (uint256 i = 0; i < newTokenIds.length; ++i) {
        uint256 _tokenId = newTokenIds[i];
        if (stakeStorage[_tokenId].staker != msg.sender) {
          revert CallerNotTokenStaker();
        }
        /// @dev sets contract state ///
        _removeStake(_tokenId);
      }
      /// @dev transfers tokens from this contract to caller ///
      Parent.safeBatchTransferFrom(
        address(this),
        msg.sender,
        newTokenIds,
        newAmounts,
        "0x00"
      );
    }
  }

  /**
   * Counts the number of emission tokens a timestamp has earned
   * @param _timestamp The timestamp a token was staked
   * @return _c The number of emission tokens a stake has earned since `_timestamp`
   */
  function countEmissions(uint256 _timestamp) public view returns (uint256 _c) {
    /// @dev if timestamp is before contract creation or later than now return 0 ///
    if (
      _timestamp < emissionStorage[0].timestamp || _timestamp > block.timestamp
    ) {
      _c = _timestamp;
    } else {
      /**
       * @dev finds the most recent emission rate _timestamp comes after
       * Example:
       *  emChanges: *0...........1............2.....................3...........*
       *  timeline:  *(deploy)....x............x.....(timestamp).....x......(now)*
       */
      uint256 minT;
      for (uint256 i = 1; i <= emChanges.current(); ++i) {
        if (emissionStorage[i].timestamp < _timestamp) {
          minT += 1;
        }
      }
      /// @dev counts all emissions earned starting from minT -> now  ///
      for (uint256 i = minT; i <= emChanges.current(); ++i) {
        uint256 tSmall = emissionStorage[i].timestamp;
        uint256 tBig = emissionStorage[i + 1].timestamp; // 0 if not set yet
        if (i == minT) {
          tSmall = _timestamp;
        }
        if (i == emChanges.current()) {
          tBig = block.timestamp;
        }
        _c += (tBig - tSmall) / emissionStorage[i].rate;
      }
    }
  }

  /// ============ INTERNAL ============ ///

  /**
   * Helper function that sets contract state when adding a stake to this contract
   * @param staker The address to make the stake for
   * @param tokenId The tokenId being staked
   */
  function _addStake(address staker, uint256 tokenId) internal {
    /// @dev increments slots filled by staker ///
    stakesAddedPerAccount[staker].increment();
    /// @dev fills new slot (account => index => tokenId) ///
    accountStakes[staker][stakesAddedPerAccount[staker].current()] = tokenId;
    /// @dev add new stake to storage ///
    stakeStorage[tokenId] = Stake(
      staker,
      block.timestamp,
      stakesAddedPerAccount[staker].current()
    );
  }

  /**
   * Helper function that sets contract state when removing a stake from this contract
   * @param tokenId The tokenId being un-staked
   * @notice This function is not called when removing stakes from the old contract
   */
  function _removeStake(uint256 tokenId) internal {
    /// @dev copies the stake being removed ///
    Stake memory _thisStake = stakeStorage[tokenId];
    /// @dev increments slots emptied by staker ///
    stakesRemovedPerAccount[_thisStake.staker].increment();
    /// @dev increments emissions earned for removing this stake ///
    unstakedClaims[_thisStake.staker] += countEmissions(_thisStake.timestamp);
    /// @dev empty staker's slot (account => index => 0) ///
    delete accountStakes[_thisStake.staker][_thisStake.accountSlot];
    /// @dev removes stake from storage ///
    delete stakeStorage[tokenId];
  }

  /**
   * Helper function that sets contract state when emission changes occur
   * @param _seconds The number of seconds a token must be staked for to earn 1 emission token
   * @notice The emission rate cannot be 0 seconds
   */
  function _setEmissionRate(uint256 _seconds) private {
    if (_seconds == 0) {
      revert ZeroEmissionRate();
    }
    emChanges.increment();
    emissionStorage[emChanges.current()] = Emission(_seconds, block.timestamp);
  }

  /**
   * Helper function that gets the number of stakes an account has active with this contract
   * @param account The address to lookup
   * @return _active The number stakes
   */
  function _activeStakesCountPerAccount(address account)
    internal
    view
    returns (uint256 _active)
  {
    _active =
      stakesAddedPerAccount[account].current() -
      stakesRemovedPerAccount[account].current();
  }

  /**
   * Helper function that gets the number of stakes an account has active with the old contract
   * @param account The address to lookup
   * @return _active The number of stakes not yet removed from the old contract
   */
  function _activeStakesCountPerAccountOld(address account)
    internal
    view
    returns (uint256 _active)
  {
    uint256[] memory oldStakes = OldGrill.getIdsOfAddr(account);
    for (uint256 i = 0; i < oldStakes.length; ++i) {
      if (Parent.balanceOf(address(OldGrill), oldStakes[i]) == 1) {
        _active += 1;
      }
    }
  }

  /// ============ READ-ONLY ============ ///

  /**
   * Gets tokenIds for `account`s active stakes in this contract
   * @param account The address to lookup
   * @return _ids Array of tokenIds
   */
  function stakedIdsPerAccount(address account)
    public
    view
    returns (uint256[] memory _ids)
  {
    _ids = new uint256[](_activeStakesCountPerAccount(account));
    /// @dev finds all slots still filled ///
    uint256 found;
    for (uint256 i = 1; i <= stakesAddedPerAccount[account].current(); ++i) {
      if (accountStakes[account][i] != 0) {
        _ids[found++] = accountStakes[account][i];
      }
    }
  }

  /**
   * Gets tokenIds for `account`s active stakes in the old contract
   * @param account The address to lookup
   * @return _ids Array of tokenIds
   */
  function stakedIdsPerAccountOld(address account)
    public
    view
    returns (uint256[] memory _ids)
  {
    /// @dev gets all tokenIds account had staked ///
    uint256[] memory oldStakes = OldGrill.getIdsOfAddr(account);
    /// @dev finds all tokenIds still active in old contract ///
    _ids = new uint256[](_activeStakesCountPerAccountOld(account));
    uint256 found;
    for (uint256 i = 0; i < oldStakes.length; ++i) {
      if (Parent.balanceOf(address(OldGrill), oldStakes[i]) == 1) {
        _ids[found++] = oldStakes[i];
      }
    }
  }

  /**
   * Gets the total number of emission changes to date
   * @return _changes The current number of changes to emission rates
   */
  function emissionChanges() external view returns (uint256 _changes) {
    _changes = emChanges.current();
  }

  /**
   * Gets the number of emission tokens `account` has earned from their active stakes
   * @param account The address to lookup
   * @return _earned The number of claims
   * @notice Uses stakes from new and old contract
   */
  function stakedClaims(address account) public view returns (uint256 _earned) {
    /// @dev counts emissions for each active stake in this contract ///
    uint256[] memory ownedIds = stakedIdsPerAccount(account);
    for (uint256 i; i < ownedIds.length; ++i) {
      _earned += countEmissions(stakeStorage[ownedIds[i]].timestamp);
    }
    /// @dev counts emissions for each active stake in old contract ///
    uint256[] memory ownedIdsOld = stakedIdsPerAccountOld(account);
    for (uint256 i; i < ownedIdsOld.length; ++i) {
      _earned += countEmissions(OldGrill.getStake(ownedIdsOld[i]).timestamp);
    }
  }

  /**
   * Gets the number of emission tokens `account` has earned from their active and removed stakes
   * @param account The address to lookup
   * @return _earned The number of emissions _operator has earned from all past and current stakes
   * @notice Uses stakes from new and old contract
   */
  function totalClaims(address account)
    external
    view
    returns (uint256 _earned)
  {
    _earned = unstakedClaims[account] + stakedClaims(account);
  }

  /**
   * Gets the Stake object from the old grill contract
   * @param tokenId The tokenId to get stake for
   * @return _og The old Stake object
   */
  function stakeStorageOld(uint256 tokenId)
    public
    view
    returns (IGRILL.Stake memory _og)
  {
    _og = OldGrill.getStake(tokenId);
  }
}

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}