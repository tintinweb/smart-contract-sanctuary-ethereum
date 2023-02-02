/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IMasterChefV1 {
  function withdraw(uint256 _pid, uint256 _amount) external;

  function deposit(uint256 _pid, uint256 _amount) external;
}

interface IBridgeAdapter {
  function bridge() external;

  function bridgeWithData(bytes calldata data) external;
}

/// @notice Contract to be inherited by implementation contract to provide methods for bridging Sushi to alternate networks
/// @dev Implementation must implement _bridge(bytes calldata data) method, data will be for most implementations 0x0 and not used
abstract contract BaseServer is Ownable {
  IMasterChefV1 public constant masterchefV1 = IMasterChefV1(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
  IERC20 public constant sushi = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);

  uint256 public immutable pid;
  address public immutable minichef;
  address public bridgeAdapter;
  uint256 public lastServe;

  event Harvested(uint256 indexed pid);
  event Withdrawn(uint256 indexed pid, uint256 indexed amount);
  event Deposited(uint256 indexed pid, uint256 indexed amount);
  event WithdrawnSushi(uint256 indexed pid, uint256 indexed amount);
  event WithdrawnDummyToken(uint256 indexed pid);
  event BridgeUpdated(address indexed newBridgeAdapter);
  event BridgedSushi(address indexed minichef, uint256 indexed amount); // make sure you fire event

  constructor(uint256 _pid, address _minichef) {
    pid = _pid;
    minichef = _minichef;
    bridgeAdapter = address(this);
  }

  // Perform harvest and bridge
  /// @dev harvests from MasterChefV1 and bridges to implemented network
  /// @param data bytes to be passed to _bridge(bytes calldata data) method, will be 0x0 for most
  function harvestAndBridge(bytes calldata data) public payable {
    masterchefV1.withdraw(pid, 0);
    bridge(data);
    emit Harvested(pid);
  }

  // Withdraw DummyToken from MasterChefV1
  /// @dev withdraws dummy token, used for harvesting Sushi, from MasterChefV1
  function withdraw() public onlyOwner {
    masterchefV1.withdraw(pid, 1);
    emit Withdrawn(pid, 1);
  }

  // Deposit DummyToken to MasterChefV1
  /// @dev deposits dummy token, used for harvesting Sushi, in MasterChefV1
  /// @param token address of dummy token to deposit
  function deposit(address token) public onlyOwner {
    IERC20(token).approve(address(masterchefV1), 1);
    masterchefV1.deposit(pid, 1);
    emit Deposited(pid, 1);
  }

  // Withdraw Sushi from this contract
  /// @dev withdraws Sushi from this contract
  /// @param recipient address to send withdrawn Sushi to
  function withdrawSushiToken(address recipient) public onlyOwner {
    uint256 sushiBalance = sushi.balanceOf(address(this));
    sushi.transfer(recipient, sushiBalance);
    emit WithdrawnSushi(pid, sushiBalance);
  }

  // Withdraw 1 unit of DummyToken from this contract
  /// @dev withdraws 1 unit of DummyToken from this contract
  /// @param token address of dummy token to withdraw
  /// @param recipient address to send withdrawn
  function withdrawDummyToken(address token, address recipient) public onlyOwner {
    IERC20(token).transfer(recipient, 1);
    emit WithdrawnDummyToken(pid);
  }

  // Update Bridge Adapter
  /// @dev updates or adds bridge adapter to update bridge call
  /// @param newBridgeAdapter address of new bridge adapter to set
  function updateBridgeAdapter(address newBridgeAdapter) public onlyOwner {
    require(newBridgeAdapter != address(0), "zero address");
    bridgeAdapter = newBridgeAdapter;
    emit BridgeUpdated(newBridgeAdapter);
  }

  // Bridge Sushi
  /// @dev bridges Sushi to alternate chain via implemented _bridge call
  /// @param data bytes to be passed to _bridge(bytes calldata data) method, will be 0x0 for most
  function bridge(bytes calldata data) public payable {
    if (bridgeAdapter == address(this)) {
      _bridge(data);
    } else {
      uint256 sushiBalance = sushi.balanceOf(address(this));
      sushi.transfer(bridgeAdapter, sushiBalance);
      IBridgeAdapter(bridgeAdapter).bridge();
    }
    lastServe = block.timestamp;
  }

  /// @dev virtual _bridge call to implement
  function _bridge(bytes calldata data) internal virtual;
}

interface IArbitrumBridge {
  function outboundTransferCustomRefund(
    address _l1Token,
    address _refundTo,
    address _to,
    uint256 _amount,
    uint256 _maxGas,
    uint256 _gasPriceBid,
    bytes calldata _data
  ) external payable returns (bytes memory);
}

/// @notice Contract bridges Sushi to arbitrum chains using their official bridge
/// @dev takes an operator address in constructor to guard _bridge call
contract ArbitrumServer is BaseServer {
  address public routerAddr;
  address public gatewayAddr;
  address public operatorAddr;

  error NotAuthorizedToBridge();

  constructor(
    uint256 _pid,
    address _minichef,
    address _routerAddr,
    address _gatewayAddr,
    address _operatorAddr
  ) BaseServer(_pid, _minichef) {
    routerAddr = _routerAddr;
    gatewayAddr = _gatewayAddr;
    operatorAddr = _operatorAddr;
  }

  /// @dev internal bridge call
  /// @param data is used: address refundTo, uint256 maxGas, uint256 gasPriceBid, bytes bridgeData
  function _bridge(bytes calldata data) internal override {
    if (msg.sender != operatorAddr) revert NotAuthorizedToBridge();

    (address refundTo, uint256 maxGas, uint256 gasPriceBid, bytes memory bridgeData) = abi.decode(
      data,
      (address, uint256, uint256, bytes)
    );

    uint256 sushiBalance = sushi.balanceOf(address(this));

    sushi.approve(gatewayAddr, sushiBalance);
    IArbitrumBridge(routerAddr).outboundTransferCustomRefund{value: msg.value}(
      address(sushi),
      refundTo,
      minichef,
      sushiBalance,
      maxGas,
      gasPriceBid,
      bridgeData
    );

    emit BridgedSushi(minichef, sushiBalance);
  }

  /// @dev set operator address, to guard _bridge call
  function setOperatorAddr(address newAddy) external onlyOwner {
    operatorAddr = newAddy;
  }
}