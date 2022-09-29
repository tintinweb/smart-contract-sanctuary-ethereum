// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {ProxyAdmin} from './oz/proxy/transparent/ProxyAdmin.sol';
import {TransparentUpgradeableProxy} from './oz/proxy/transparent/TransparentUpgradeableProxy.sol';
import {ZeroToken} from './ZeroToken.sol';

contract ZeroTokenFactory {
  event NewZeroToken(
    address indexed proxyAdmin,
    address indexed zeroTokenProxy,
    address indexed zeroTokenImpl
  );
  event NewZeroTokenWithMint(
    address indexed proxyAdmin,
    address indexed zeroTokenProxy,
    address indexed zeroTokenImpl,
    address to,
    uint256 amount
  );

  function createZeroToken(string calldata name, string calldata symbol)
    external
    returns (ProxyAdmin, TransparentUpgradeableProxy)
  {
    (
      ProxyAdmin proxyAdmin,
      TransparentUpgradeableProxy zeroTokenProxy,
      ZeroToken zeroTokenImpl
    ) = _createZeroToken(name, symbol);
    _transferOwnership(
      proxyAdmin,
      ZeroToken(address(zeroTokenProxy)),
      zeroTokenImpl,
      msg.sender
    );

    emit NewZeroToken(
      address(proxyAdmin),
      address(zeroTokenProxy),
      address(zeroTokenImpl)
    );
    return (proxyAdmin, zeroTokenProxy);
  }

  function createZeroTokenWithMint(
    string calldata name,
    string calldata symbol,
    address to,
    uint256 amount
  ) external returns (ProxyAdmin, TransparentUpgradeableProxy) {
    (
      ProxyAdmin proxyAdmin,
      TransparentUpgradeableProxy zeroTokenProxy,
      ZeroToken zeroTokenImpl
    ) = _createZeroToken(name, symbol);

    ZeroToken zeroTokenProxyAs = ZeroToken(address(zeroTokenProxy));
    zeroTokenProxyAs.mint(to, amount);

    _transferOwnership(proxyAdmin, zeroTokenProxyAs, zeroTokenImpl, to);

    emit NewZeroTokenWithMint(
      address(proxyAdmin),
      address(zeroTokenProxy),
      address(zeroTokenImpl),
      to,
      amount
    );
    return (proxyAdmin, zeroTokenProxy);
  }

  function _createProxy(
    address _logic,
    address _admin,
    bytes memory _data
  ) internal returns (address payable) {
    return
      payable(
        address(
          new TransparentUpgradeableProxy{
            salt: keccak256(abi.encodePacked(block.number, _data))
          }(_logic, _admin, _data)
        )
      );
  }

  function _createZeroToken(string memory name, string calldata symbol)
    internal
    returns (
      ProxyAdmin proxyAdmin,
      TransparentUpgradeableProxy zeroTokenProxy,
      ZeroToken zeroTokenImpl
    )
  {
    proxyAdmin = new ProxyAdmin();

    zeroTokenImpl = new ZeroToken();

    // zeroTokenProxy = TransparentUpgradeableProxy(
    //   _createProxy(
    //     address(zeroTokenImpl),
    //     address(proxyAdmin),
    //     abi.encodeWithSelector(ZeroToken.initialize.selector, name, symbol)
    //   )
    // );

    zeroTokenProxy = new TransparentUpgradeableProxy(
      address(zeroTokenImpl),
      address(proxyAdmin),
      abi.encodeWithSelector(ZeroToken.initialize.selector, name, symbol)
    );
  }

  function _transferOwnership(
    ProxyAdmin proxyAdmin,
    ZeroToken zeroTokenProxy,
    ZeroToken zeroTokenImpl,
    address newOwner
  ) internal {
    // proxyAdmin.transferOwnership(newOwner);
    // zeroTokenProxy.transferOwnership(newOwner);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// Slight modifiations from base Open Zeppelin Contracts
// Consult /oz/README.md for more information
import './oz/token/ERC20/ERC20Upgradeable.sol';
import './oz/token/ERC20/ERC20SnapshotUpgradeable.sol';
import './oz/token/ERC20/ERC20PausableUpgradeable.sol';
import './oz/access/OwnableUpgradeable.sol';

contract ZeroToken is
  OwnableUpgradeable,
  ERC20Upgradeable,
  ERC20PausableUpgradeable,
  ERC20SnapshotUpgradeable
{
  event AuthorizedSnapshotter(address account);
  event DeauthorizedSnapshotter(address account);

  // Mapping which stores all addresses allowed to snapshot
  mapping(address => bool) authorizedToSnapshot;

  function initialize(string memory name, string memory symbol)
    public
    initializer
  {
    __Ownable_init();
    __ERC20_init(name, symbol);
    __ERC20Snapshot_init();
    __ERC20Pausable_init();
  }

  // Call this on the implementation contract (not the proxy)
  function initializeImplementation() public initializer {
    __Ownable_init();
    _pause();
  }

  /**
   * Mints new tokens.
   * @param account the account to mint the tokens for
   * @param amount the amount of tokens to mint.
   */
  function mint(address account, uint256 amount) external onlyOwner {
    _mint(account, amount);
  }

  /**
   * Burns tokens from an address.
   * @param account the account to mint the tokens for
   * @param amount the amount of tokens to mint.
   */
  function burn(address account, uint256 amount) external onlyOwner {
    _burn(account, amount);
  }

  /**
   * Pauses the token contract preventing any token mint/transfer/burn operations.
   * Can only be called if the contract is unpaused.
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * Unpauses the token contract preventing any token mint/transfer/burn operations
   * Can only be called if the contract is paused.
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * Creates a token balance snapshot. Ideally this would be called by the
   * controlling DAO whenever a proposal is made.
   */
  function snapshot() external returns (uint256) {
    require(
      authorizedToSnapshot[_msgSender()] || _msgSender() == owner(),
      'zDAOToken: Not authorized to snapshot'
    );
    return _snapshot();
  }

  /**
   * Authorizes an account to take snapshots
   * @param account The account to authorize
   */
  function authorizeSnapshotter(address account) external onlyOwner {
    require(
      !authorizedToSnapshot[account],
      'zDAOToken: Account already authorized'
    );

    authorizedToSnapshot[account] = true;
    emit AuthorizedSnapshotter(account);
  }

  /**
   * Deauthorizes an account to take snapshots
   * @param account The account to de-authorize
   */
  function deauthorizeSnapshotter(address account) external onlyOwner {
    require(authorizedToSnapshot[account], 'zDAOToken: Account not authorized');

    authorizedToSnapshot[account] = false;
    emit DeauthorizedSnapshotter(account);
  }

  /**
   * Utility function to transfer tokens to many addresses at once.
   * @param recipients The addresses to send tokens to
   * @param amount The amount of tokens to send
   * @return Boolean if the transfer was a success
   */
  function transferBulk(address[] calldata recipients, uint256 amount)
    external
    returns (bool)
  {
    address sender = _msgSender();

    uint256 total = amount * recipients.length;
    require(
      _balances[sender] >= total,
      'ERC20: transfer amount exceeds balance'
    );

    require(!paused(), 'ERC20Pausable: token transfer while paused');

    _balances[sender] -= total;
    _updateAccountSnapshot(sender);

    for (uint256 i = 0; i < recipients.length; ++i) {
      address recipient = recipients[i];
      require(recipient != address(0), 'ERC20: transfer to the zero address');

      // Note: _beforeTokenTransfer isn't called here
      // This function emulates what it would do (paused and snapshot)

      _balances[recipient] += amount;

      _updateAccountSnapshot(recipient);

      emit Transfer(sender, recipient, amount);
    }

    return true;
  }

  /**
   * Utility function to transfer tokens to many addresses at once.
   * @param sender The address to send the tokens from
   * @param recipients The addresses to send tokens to
   * @param amount The amount of tokens to send
   * @return Boolean if the transfer was a success
   */
  function transferFromBulk(
    address sender,
    address[] calldata recipients,
    uint256 amount
  ) external returns (bool) {
    require(!paused(), 'ERC20Pausable: token transfer while paused');

    uint256 total = amount * recipients.length;
    require(
      _balances[sender] >= total,
      'ERC20: transfer amount exceeds balance'
    );

    // Ensure enough allowance
    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(
      currentAllowance >= total,
      'ERC20: transfer total exceeds allowance'
    );
    _approve(sender, _msgSender(), currentAllowance - total);

    _balances[sender] -= total;
    _updateAccountSnapshot(sender);

    for (uint256 i = 0; i < recipients.length; ++i) {
      address recipient = recipients[i];
      require(recipient != address(0), 'ERC20: transfer to the zero address');

      // Note: _beforeTokenTransfer isn't called here
      // This function emulates what it would do (paused and snapshot)

      _balances[recipient] += amount;

      _updateAccountSnapshot(recipient);

      emit Transfer(sender, recipient, amount);
    }

    return true;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  )
    internal
    virtual
    override(
      ERC20PausableUpgradeable,
      ERC20SnapshotUpgradeable,
      ERC20Upgradeable
    )
  {
    super._beforeTokenTransfer(from, to, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";
import "../../access/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {

    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(TransparentUpgradeableProxy proxy, address implementation, bytes memory data) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../ERC1967/ERC1967Proxy.sol';

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
  /**
   * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
   * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
   */
  constructor(
    address _logic,
    address admin_,
    bytes memory _data
  ) payable ERC1967Proxy(_logic, _data) {
    assert(
      _ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    );
    _setAdmin(admin_);
  }

  /**
   * @dev Emitted when the admin account has changed.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 private constant _ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
   */
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * @dev Returns the current admin.
   *
   * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
   *
   * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
   * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
   * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
   */
  function admin() external ifAdmin returns (address admin_) {
    admin_ = _admin();
  }

  /**
   * @dev Returns the current implementation.
   *
   * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
   *
   * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
   * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
   * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
   */
  function implementation() external ifAdmin returns (address implementation_) {
    implementation_ = _implementation();
  }

  /**
   * @dev Changes the admin of the proxy.
   *
   * Emits an {AdminChanged} event.
   *
   * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
   */
  function changeAdmin(address newAdmin) external virtual ifAdmin {
    require(
      newAdmin != address(0),
      'TransparentUpgradeableProxy: new admin is the zero address'
    );
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev Upgrade the implementation of the proxy.
   *
   * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
   */
  function upgradeTo(address newImplementation) external virtual ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
   * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
   * proxied contract.
   *
   * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data)
    external
    payable
    virtual
    ifAdmin
  {
    _upgradeTo(newImplementation);
    Address.functionDelegateCall(newImplementation, data);
  }

  /**
   * @dev Returns the current admin.
   */
  function _admin() internal view virtual returns (address adm) {
    bytes32 slot = _ADMIN_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Stores a new address in the EIP1967 admin slot.
   */
  function _setAdmin(address newAdmin) private {
    bytes32 slot = _ADMIN_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newAdmin)
    }
  }

  /**
   * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
   */
  function _beforeFallback() internal virtual override {
    require(
      msg.sender != _admin(),
      'TransparentUpgradeableProxy: admin cannot fallback to proxy target'
    );
    super._beforeFallback();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../utils/ContextUpgradeable.sol';
import '../proxy/utils/Initializable.sol';

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

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  function __Ownable_init() internal initializer {
    __Context_init_unchained();
    __Ownable_init_unchained();
  }

  function __Ownable_init_unchained() internal initializer {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
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
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC20Upgradeable.sol';
import '../../utils/ArraysUpgradeable.sol';
import '../../utils/CountersUpgradeable.sol';
import '../../proxy/utils/Initializable.sol';

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */
abstract contract ERC20SnapshotUpgradeable is Initializable, ERC20Upgradeable {
  function __ERC20Snapshot_init() internal initializer {
    __Context_init_unchained();
    __ERC20Snapshot_init_unchained();
  }

  function __ERC20Snapshot_init_unchained() internal initializer {}

  // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
  // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

  using ArraysUpgradeable for uint256[];
  using CountersUpgradeable for CountersUpgradeable.Counter;

  // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
  // Snapshot struct, but that would impede usage of functions that work on an array.
  struct Snapshots {
    uint256[] ids;
    uint256[] values;
  }

  mapping(address => Snapshots) private _accountBalanceSnapshots;
  Snapshots private _totalSupplySnapshots;

  // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
  CountersUpgradeable.Counter private _currentSnapshotId;

  /**
   * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
   */
  event Snapshot(uint256 id);

  /**
   * @dev Creates a new snapshot and returns its snapshot id.
   *
   * Emits a {Snapshot} event that contains the same id.
   *
   * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
   * set of accounts, for example using {AccessControl}, or it may be open to the public.
   *
   * [WARNING]
   * ====
   * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
   * you must consider that it can potentially be used by attackers in two ways.
   *
   * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
   * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
   * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
   * section above.
   *
   * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
   * ====
   */
  function _snapshot() internal virtual returns (uint256) {
    _currentSnapshotId.increment();

    uint256 currentId = _currentSnapshotId.current();
    emit Snapshot(currentId);
    return currentId;
  }

  /**
   * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
   */
  function balanceOfAt(address account, uint256 snapshotId)
    public
    view
    virtual
    returns (uint256)
  {
    (bool snapshotted, uint256 value) = _valueAt(
      snapshotId,
      _accountBalanceSnapshots[account]
    );

    return snapshotted ? value : balanceOf(account);
  }

  /**
   * @dev Retrieves the total supply at the time `snapshotId` was created.
   */
  function totalSupplyAt(uint256 snapshotId)
    public
    view
    virtual
    returns (uint256)
  {
    (bool snapshotted, uint256 value) = _valueAt(
      snapshotId,
      _totalSupplySnapshots
    );

    return snapshotted ? value : totalSupply();
  }

  // Update balance and/or total supply snapshots before the values are modified. This is implemented
  // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    if (from == address(0)) {
      // mint
      _updateAccountSnapshot(to);
      _updateTotalSupplySnapshot();
    } else if (to == address(0)) {
      // burn
      _updateAccountSnapshot(from);
      _updateTotalSupplySnapshot();
    } else {
      // transfer
      _updateAccountSnapshot(from);
      _updateAccountSnapshot(to);
    }
  }

  function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
    private
    view
    returns (bool, uint256)
  {
    require(snapshotId > 0, 'ERC20Snapshot: id is 0');
    // solhint-disable-next-line max-line-length
    require(
      snapshotId <= _currentSnapshotId.current(),
      'ERC20Snapshot: nonexistent id'
    );

    // When a valid snapshot is queried, there are three possibilities:
    //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
    //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
    //  to this id is the current one.
    //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
    //  requested id, and its value is the one to return.
    //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
    //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
    //  larger than the requested one.
    //
    // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
    // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
    // exactly this.

    uint256 index = snapshots.ids.findUpperBound(snapshotId);

    if (index == snapshots.ids.length) {
      return (false, 0);
    } else {
      return (true, snapshots.values[index]);
    }
  }

  function _updateAccountSnapshot(address account) internal {
    _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
  }

  function _updateTotalSupplySnapshot() internal {
    _updateSnapshot(_totalSupplySnapshots, totalSupply());
  }

  function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue)
    private
  {
    uint256 currentId = _currentSnapshotId.current();
    if (_lastSnapshotId(snapshots.ids) < currentId) {
      snapshots.ids.push(currentId);
      snapshots.values.push(currentValue);
    }
  }

  function _lastSnapshotId(uint256[] storage ids)
    private
    view
    returns (uint256)
  {
    if (ids.length == 0) {
      return 0;
    } else {
      return ids[ids.length - 1];
    }
  }

  uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC20Upgradeable.sol';
import '../../security/PausableUpgradeable.sol';
import '../../proxy/utils/Initializable.sol';

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeable is
  Initializable,
  ERC20Upgradeable,
  PausableUpgradeable
{
  function __ERC20Pausable_init() internal initializer {
    __Context_init_unchained();
    __Pausable_init_unchained();
    __ERC20Pausable_init_unchained();
  }

  function __ERC20Pausable_init_unchained() internal initializer {}

  /**
   * @dev See {ERC20-_beforeTokenTransfer}.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    require(!paused(), 'ERC20Pausable: token transfer while paused');
  }

  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IERC20Upgradeable.sol';
import '../../utils/ContextUpgradeable.sol';
import '../../proxy/utils/Initializable.sol';

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is
  Initializable,
  ContextUpgradeable,
  IERC20Upgradeable
{
  // Diff from Open Zeppelin Standard
  mapping(address => uint256) internal _balances;

  mapping(address => mapping(address => uint256)) internal _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;

  /**
   * @dev Sets the values for {name} and {symbol}.
   *
   * The defaut value of {decimals} is 18. To select a different value for
   * {decimals} you should overload it.
   *
   * All three of these values are immutable: they can only be set once during
   * construction.
   */
  function __ERC20_init(string memory name_, string memory symbol_)
    internal
    initializer
  {
    __Context_init_unchained();
    __ERC20_init_unchained(name_, symbol_);
  }

  function __ERC20_init_unchained(string memory name_, string memory symbol_)
    internal
    initializer
  {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view virtual returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view virtual returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless this function is
   * overloaded;
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view virtual returns (uint8) {
    return 18;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(
      currentAllowance >= amount,
      'ERC20: transfer amount exceeds allowance'
    );
    _approve(sender, _msgSender(), currentAllowance - amount);

    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender] + addedValue
    );
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(
      currentAllowance >= subtractedValue,
      'ERC20: decreased allowance below zero'
    );
    _approve(_msgSender(), spender, currentAllowance - subtractedValue);

    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, 'ERC20: transfer amount exceeds balance');
    _balances[sender] = senderBalance - amount;
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: mint to the zero address');

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, 'ERC20: burn amount exceeds balance');
    _balances[account] = accountBalance - amount;
    _totalSupply -= amount;

    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be to transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import '../proxy/utils/Initializable.sol';

/*
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

  function __Context_init_unchained() internal initializer {}

  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }

  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev Collection of functions related to array types.
 */
library ArraysUpgradeable {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../utils/ContextUpgradeable.sol';
import '../proxy/utils/Initializable.sol';

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event Unpaused(address account);

  bool private _paused;

  /**
   * @dev Initializes the contract in unpaused state.
   */
  function __Pausable_init() internal initializer {
    __Context_init_unchained();
    __Pausable_init_unchained();
  }

  function __Pausable_init_unchained() internal initializer {
    _paused = false;
  }

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view virtual returns (bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  modifier whenNotPaused() {
    require(!paused(), 'Pausable: paused');
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  modifier whenPaused() {
    require(paused(), 'Pausable: not paused');
    _;
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function _pause() internal virtual whenNotPaused {
    _paused = true;
    emit Paused(_msgSender());
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function _unpause() internal virtual whenPaused {
    _paused = false;
    emit Unpaused(_msgSender());
  }

  uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../Proxy.sol';
import '../../utils/Address.sol';

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract ERC1967Proxy is Proxy {
  /**
   * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
   *
   * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
   * function call, and allows initializating the storage of the proxy like a Solidity constructor.
   */
  constructor(address _logic, bytes memory _data) payable {
    assert(
      _IMPLEMENTATION_SLOT ==
        bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    );
    _setImplementation(_logic);
    if (_data.length > 0) {
      Address.functionDelegateCall(_logic, _data);
    }
  }

  /**
   * @dev Emitted when the implementation is upgraded.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 private constant _IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation address.
   */
  function _implementation()
    internal
    view
    virtual
    override
    returns (address impl)
  {
    bytes32 slot = _IMPLEMENTATION_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   *
   * Emits an {Upgraded} event.
   */
  function _upgradeTo(address newImplementation) internal virtual {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Stores a new address in the EIP1967 implementation slot.
   */
  function _setImplementation(address newImplementation) private {
    require(
      Address.isContract(newImplementation),
      'ERC1967Proxy: new implementation is not a contract'
    );

    bytes32 slot = _IMPLEMENTATION_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newImplementation)
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}