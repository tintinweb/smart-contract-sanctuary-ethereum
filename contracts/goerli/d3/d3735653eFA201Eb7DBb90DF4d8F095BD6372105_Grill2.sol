//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

error CallerBlacklisted();
error CallerNotTokenOwner();
error CallerNotTokenStaker();
error ContractBailed();
error ContractNotBailed();
error InvalidTokenAmount();
error TokenAlreadyStaked();
error TokenNotStaked();
error StakingNotActive();
error ZeroEmissionRate();

/**
 * Interfaces SuperFarm's Super1155 contract
 * See example contracts: https://etherscan.io/address/0x71B11Ac923C967CD5998F23F6dae0d779A6ac8Af#code,
 * https://etherscan.io/address/0xc7b9D8483FD01C379a4141B2Ee7c39442172b259#code
 *
 * @notice To stake tokens an account must setApprovalForAll() using the address of this contract in the above contracts
 */
interface Super1155 {
  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) external;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes calldata _data
  ) external;

  function balanceOf(address _owner, uint256 _id)
    external
    view
    returns (uint256);

  function isApprovedForAll(address _owner, address _operator)
    external
    view
    returns (bool);
}

/**
 * Interfaces the old grill contract
 * https://etherscan.io/address/0xe11af478af241fab926f4c111d50139ae003f7fd#code
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

contract Grill2 is Ownable, ERC1155Holder {
  using Counters for Counters.Counter;
  uint256 internal constant MAX_INT = 2**256 - 1;
  IGRILL internal immutable OldGrill;
  address public immutable oldGrillAddress;
  Super1155 internal immutable Parent;
  address public immutable parentAddress;
  /// number of times the emission rate changes ///
  Counters.Counter internal emChanges;
  /// is staking allowed & has contract been bailed out ///
  bool public isStaking;
  bool public isBailed;
  /// total number of stakes added & removed (this contract) ///
  uint256 internal stakesAdded;
  uint256 internal stakesRemoved;
  /// total number of stakes added & removed by an account (this contract) ///
  mapping(address => uint256) internal accountStakesAdded;
  mapping(address => uint256) internal accountStakesRemoved;
  /// each Stake() by tokenId (this contract) ///
  mapping(uint256 => Stake) public stakeStorage;
  /// each tokenId by index (tokenId is 0 if stake is removed) ///
  mapping(uint256 => uint256) public contractStakes;
  /// each tokenId by index for an account (tokenId is 0 if stake is removed) ///
  mapping(address => mapping(uint256 => uint256)) public accountStakes;
  /// each Emission() by index ///
  mapping(uint256 => Emission) public emissions;
  /// total number of emission tokens earned for each address ///
  mapping(address => uint256) public unstakedClaims;
  /// blacklisted addresses can not add new stakes ///
  mapping(address => bool) public blacklist;
  /// list of new proxies for Parent tokens ///
  mapping(address => address) public proxies;

  /**
   * Stores information about a stake
   * @param staker The address who created the staek
   * @param timestamp The block.timestamp the stake was created
   * @param globalSlot The index for this stake in `contractStakes`
   * @param accountSlot The index for this stake in `accountStakes`
   */
  struct Stake {
    address staker;
    uint256 timestamp;
    uint256 globalSlot;
    uint256 accountSlot;
  }
  /**
   * Stores information about each emission rate
   * @param rate The number of seconds to earn 1 emission token
   * @param timestamp The block.timestamp this emission rate was set
   */
  struct Emission {
    uint256 rate;
    uint256 timestamp;
  }

  /// ============ CONSTRUCTOR ============ ///

  /**
   * Initializes contract instances, sets initial emission rate, activates staking,
   * @param _parentAddr The contract address to allow staking from
   */
  constructor(address _parentAddr, address _grillAddr) {
    Parent = Super1155(_parentAddr);
    parentAddress = _parentAddr;
    OldGrill = IGRILL(_grillAddr);
    oldGrillAddress = _grillAddr;
    uint256 secondsIn45Days = 3600 * 24 * 45;
    emissions[emChanges.current()] = Emission(secondsIn45Days, 1652054408);
    isStaking = true;
  }

  /// ============ OWNER ============ ///

  /**
   * For setting a proxy transferer in the parent contract
   * Will set this contract as a proxy for old grill tokens
   * @param owner The address whose tokens are to be moved
   * @param operator The address being proxied to move `owner`s tokens
   */
  function setProxyForAccount(address owner, address operator)
    public
    onlyOwner
  {
    proxies[owner] = operator;
  }

  /**
   * For allowing/unallowing the addition of new stakes
   * @notice This function is disabled once toggleBailout() is called
   */
  function toggleStaking() public onlyOwner {
    if (isBailed) {
      revert ContractBailed();
    }
    isStaking = !isStaking;
  }

  /**
   * Start to bailout sequence. Ends staking/emission counting permanently
   * @notice This function is only callable once and all state changes are final
   * @notice It must be called before bailoutAllStakes() or bailoutSingleStake()
   */
  function toggleBailout() public onlyOwner {
    if (isBailed) {
      revert ContractBailed();
    }
    isStaking = false;
    isBailed = true;
    _setEmissionRate(MAX_INT);
  }

  /**
   * For allowing/unallowing an account to add new stakes
   * @notice A staker is always able to remove their stakes regardless of blacklist status
   * @param account The address to set status for
   * @param status The status being set
   */
  function blacklistAccount(address account, bool status) public onlyOwner {
    if (isBailed) {
      revert ContractBailed();
    }
    blacklist[account] = status;
  }

  /**
   * Stops counting of emission tokens by setting a new emission rate of a very larger number of seconds
   * @notice No tokens can be earned with an emission rate this long
   * @notice To continue emissions counting, the owner must set a new emission rate
   */
  function pauseEmissions() public onlyOwner {
    if (isBailed) {
      revert ContractBailed();
    }
    _setEmissionRate(MAX_INT);
  }

  /**
   * Sets new emission rate
   * @param _seconds The number of seconds a token must be staked for to earn 1 emission token
   */
  function setEmissionRate(uint256 _seconds) public onlyOwner {
    if (isBailed) {
      revert ContractBailed();
    }
    _setEmissionRate(_seconds);
  }

  /**
   * Removes all active stakes and sends tokens back to their stakers
   */
  function bailoutAll() public onlyOwner {
    if (!isBailed) {
      revert ContractNotBailed();
    }
    uint256[] memory allIds = activeStakeIds();
    for (uint256 i = 0; i < allIds.length; ++i) {
      /// @dev copy og staker before deletion ///
      address staker = stakeStorage[allIds[i]].staker;
      /// @dev reset contract state ///
      _removeStake(staker, allIds[i]);
      /// @dev transfer token to staker ///
      Parent.safeTransferFrom(address(this), staker, allIds[i], 1, "0x00");
    }
  }

  /**
   * Removes and batch of stakes and sends tokens back to their stakers
   * @param tokenIds An array of tokenIds whose stakes to remove
   */
  function bailoutBatch(uint256[] memory tokenIds) public onlyOwner {
    if (!isBailed) {
      revert ContractNotBailed();
    }
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      Stake memory thisStake = stakeStorage[tokenIds[i]];
      if (thisStake.timestamp == 0) {
        revert TokenNotStaked();
      }

      _removeStake(thisStake.staker, tokenIds[i]);

      Parent.safeTransferFrom(
        address(this),
        thisStake.staker,
        tokenIds[i],
        1,
        "0x00"
      );
    }
  }

  /// ============ PUBLIC ============ ///

  function addStakes(uint256[] memory tokenIds, uint256[] memory amounts)
    public
  {
    if (!isStaking) {
      revert StakingNotActive();
    }
    if (isBailed) {
      revert ContractBailed();
    }
    if (blacklist[msg.sender]) {
      revert CallerBlacklisted();
    }
    if (tokenIds.length == 0) {
      revert InvalidTokenAmount();
    }
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      if (Parent.balanceOf(msg.sender, tokenIds[i]) == 0) {
        revert CallerNotTokenOwner();
      }
      if (stakeStorage[tokenIds[i]].timestamp > 0) {
        revert TokenAlreadyStaked();
      }
      _addStake(msg.sender, tokenIds[i], block.timestamp);
    }
    /// @dev transfer tokens to contract ///
    Parent.safeBatchTransferFrom(
      msg.sender,
      address(this),
      tokenIds,
      amounts,
      "0x00"
    );
  }

  function removeStakes(
    uint256[] memory oldTokenIds,
    uint256[] memory oldAmounts,
    uint256[] memory newTokenIds,
    uint256[] memory newAmounts
  ) public {
    if (oldTokenIds.length > 0) {
      for (uint256 i = 0; i < oldTokenIds.length; ++i) {
        if (Parent.balanceOf(oldGrillAddress, oldTokenIds[i]) != 1) {
          revert TokenNotStaked();
        }
        if (OldGrill.getStake(oldTokenIds[i]).staker != msg.sender) {
          revert CallerNotTokenStaker();
        }
        /// @dev increment emissions earned for staker from removing this stake ///
        unstakedClaims[msg.sender] += countEmissions(
          OldGrill.getStake(oldTokenIds[i]).timestamp
        );
      }
      /// @dev transfer tokens to caller ///
      Parent.safeBatchTransferFrom(
        oldGrillAddress,
        msg.sender,
        oldTokenIds,
        oldAmounts,
        "0x00"
      );
    }
    if (newTokenIds.length > 0) {
      for (uint256 i = 0; i < newTokenIds.length; ++i) {
        if (Parent.balanceOf(address(this), newTokenIds[i]) != 1) {
          revert TokenNotStaked();
        }
        if (stakeStorage[newTokenIds[i]].staker != msg.sender) {
          revert CallerNotTokenStaker();
        }
        _removeStake(msg.sender, newTokenIds[i]);
      }
      /// @dev transfer tokens to caller ///
      Parent.safeBatchTransferFrom(
        address(this),
        msg.sender,
        newTokenIds,
        newAmounts,
        "0x00"
      );
    }
  }

  /// ============ INTERNAL ============ ///

  /**
   * Helper function for setting contract state when adding a stake
   * @param staker The address to make the stake for
   * @param tokenId The tokenId being staked
   * @param timestamp The time the stake was created
   */
  function _addStake(
    address staker,
    uint256 tokenId,
    uint256 timestamp
  ) internal {
    /// @dev increment slots filled in contract ///
    stakesAdded += 1;
    /// @dev increment slots filled by staker ///
    accountStakesAdded[staker] += 1;
    /// @dev fill contract's slot (index => tokenId) ///
    contractStakes[stakesAdded] = tokenId;
    /// @dev fill staker's slot (account => index => tokenId) ///
    accountStakes[staker][accountStakesAdded[staker]] = tokenId;
    /// @dev add new stake to storage ///
    stakeStorage[tokenId] = Stake(
      staker,
      timestamp,
      stakesAdded,
      accountStakesAdded[staker]
    );
  }

  /**
   * Helper function for setting contract state when removing a stake from this contract
   * @notice This function is not called when removing stakes from the old contract
   * @param staker The address whose stake is being removed
   * @param tokenId The tokenId being un-staked
   */
  function _removeStake(address staker, uint256 tokenId) internal {
    /// @dev increment slots emptied by contract ///
    stakesRemoved += 1;
    /// @dev increment slots emptied by staker ///
    accountStakesRemoved[staker] += 1;
    /// @dev the stake being removed
    Stake memory thisStake = stakeStorage[tokenId];
    /// @dev increment emissions earned for staker by removing this stake ///
    unstakedClaims[staker] += countEmissions(thisStake.timestamp);
    /// @dev empty contract's slot (index => 0) ///
    delete contractStakes[thisStake.globalSlot];
    /// @dev empty staker's slot (account => index => 0) ///
    delete accountStakes[staker][thisStake.accountSlot];
    /// @dev remove stake from storage ///
    delete stakeStorage[tokenId];
  }

  /**
   * Helper function for setting contract state when emission changes occur
   * @param _seconds The number of seconds a token must be staked for to earn 1 emission token
   * @notice The emission rate cannot be 0 seconds
   */
  function _setEmissionRate(uint256 _seconds) private {
    if (_seconds == 0) {
      revert ZeroEmissionRate();
    }
    emChanges.increment();
    emissions[emChanges.current()] = Emission(_seconds, block.timestamp);
  }

  /**
   * Gets the number of stakes an account has active with this contract
   * @param account The address to lookup
   * @return _active The number stakes
   */
  function _activeStakesCountPerAccount(address account)
    internal
    view
    returns (uint256 _active)
  {
    _active = accountStakesAdded[account] - accountStakesRemoved[account];
  }

  /**
   * Gets the number of stakes an account has active in the old contract
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
      if (Parent.balanceOf(oldGrillAddress, oldStakes[i]) == 1) {
        _active += 1;
      }
    }
  }

  /// ============ HELPER ============ ///

  /**
   * Count the number of emission tokens a token has earned based on its timestamp
   * @param _timestamp The block.timestamp the token was staked
   */
  function countEmissions(uint256 _timestamp) public view returns (uint256 _c) {
    if (_timestamp == 0) {
      _c = _timestamp;
    } else {
      /// @dev finds the first emission rate _tokenId was staked during ///
      uint256 minT;
      for (uint256 i = 1; i <= emChanges.current(); ++i) {
        if (emissions[i].timestamp < _timestamp) {
          minT += i;
          break;
        }
      }
      /// @dev counts all emissions earned starting from minT -> now
      for (uint256 i = minT; i <= emChanges.current(); ++i) {
        uint256 tSmall = emissions[i].timestamp;
        uint256 tBig = emissions[i + 1].timestamp;
        if (i == minT) {
          tSmall = _timestamp;
        }
        if (i == emChanges.current()) {
          tBig = block.timestamp;
        }
        _c += (tBig - tSmall) / emissions[i].rate;
      }
    }
  }

  /// ============ READ-ONLY ============ ///

  /**
   * Gets the number of stakes active in this contract
   * @return _active The number of `stakesAdded` - `stakesRemoved`
   */
  function activeStakesCount() public view returns (uint256 _active) {
    /// @dev slots filled - slots emptied ///
    _active = stakesAdded - stakesRemoved;
  }

  /**
   * Gets tokenIds for active stakes with this contract
   * @return _ids An array of tokenIds
   */
  function activeStakeIds() public view returns (uint256[] memory _ids) {
    _ids = new uint256[](activeStakesCount());
    /// @dev finds all slots still filled ///
    uint256 found;
    for (uint256 i = 1; i <= stakesAdded; ++i) {
      if (contractStakes[i] != 0) {
        _ids[found] = contractStakes[i];
        found += 1;
      }
    }
  }

  /**
   * Gets tokenIds for an account's active stakes with this contract
   * @param account The address to lookup
   * @return _ids An array of tokenIds
   */
  function activeStakeIdsPerAccount(address account)
    public
    view
    returns (uint256[] memory _ids)
  {
    _ids = new uint256[](_activeStakesCountPerAccount(account));
    /// @dev finds all slots still filled ///
    uint256 found;
    for (uint256 i = 1; i <= accountStakesAdded[account]; ++i) {
      if (accountStakes[account][i] != 0) {
        _ids[found] = accountStakes[account][i];
        found += 1;
      }
    }
  }

  /**
   * Gets tokenIds for an account's active stakes with the old contract
   * @param account The address to lookup
   * @return _ids Array of tokenIds
   */
  function activeStakeIdsPerAccountOld(address account)
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
      if (Parent.balanceOf(oldGrillAddress, oldStakes[i]) == 1) {
        _ids[found] = oldStakes[i];
        found += 1;
      }
    }
  }

  /**
   * Gets the total number of emission changes to date
   * @return _changes The current number of changes to emission rates
   */
  function emissionChangesCount() external view returns (uint256 _changes) {
    _changes = emChanges.current();
  }

  /**
   * Gets details for an emission change
   * @param index The index to lookup
   * @return _emission The emission object for `index`
   */
  function emissionDetails(uint256 index)
    external
    view
    returns (Emission memory _emission)
  {
    _emission = emissions[index];
  }

  /**
   * Gets the number of emission tokens an account has earned from their active stakes
   * @notice Gets stakes from old grill contract as well
   * @param account The address to lookup
   * @return _earned The number of claims
   */
  function getStakedClaims(address account)
    public
    view
    returns (uint256 _earned)
  {
    /// @dev counts emissions for each active stake in this contract ///
    uint256[] memory ownedIds = activeStakeIdsPerAccount(account);
    for (uint256 i; i < ownedIds.length; ++i) {
      _earned += countEmissions(stakeStorage[ownedIds[i]].timestamp);
    }
    /// @dev counts emissions for each active stake in old contract ///
    uint256[] memory ownedIdsOld = activeStakeIdsPerAccountOld(account);
    for (uint256 i; i < ownedIdsOld.length; ++i) {
      _earned += countEmissions(OldGrill.getStake(ownedIdsOld[i]).timestamp);
    }
  }

  /**
   * Gets the number of emission tokens an account has earned from all of their stakes, active and removed
   * @param account The address to lookup
   * @return _earned The number of emissions _operator has earned from all past and current stakes
   */
  function getTotalClaims(address account)
    external
    view
    returns (uint256 _earned)
  {
    _earned = unstakedClaims[account] + getStakedClaims(account);
  }

  /**
   * Get the balance for a specifc tokenId in the parent contract
   * @param _operator The address to lookup
   * @param _tokenId The token id to check balance of
   * @return _c The _tokenId balance of _operator
   */
  function parentBalance(address _operator, uint256 _tokenId)
    public
    view
    returns (uint256 _c)
  {
    _c = Parent.balanceOf(_operator, _tokenId);
  }

  /**
   * Gets Stake() from old contract
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