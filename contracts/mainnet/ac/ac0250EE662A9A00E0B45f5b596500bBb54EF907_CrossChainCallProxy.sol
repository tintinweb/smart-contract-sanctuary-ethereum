// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IAnyCallProxy.sol";
import "./interfaces/ICrossChainCallProxy.sol";

/// @dev This is a proxy contract to relay cross chain call to AnyCallProxy contract.
///      This contract should have the same address in all evm compatible chain.
contract CrossChainCallProxy is Ownable, ICrossChainCallProxy {
  event UpdateWhitelist(address indexed _account, bool _status);
  event UpdateAnyCallProxy(address indexed _anyCallProxy);

  /// @notice The address of AnyCallProxy.
  address public anyCallProxy;
  /// @notice Keep track the whitelist contracts.
  mapping(address => bool) public whitelist;

  modifier onlyWhitelist() {
    // solhint-disable-next-line reason-string
    require(whitelist[msg.sender], "CrossChainCallProxy: only whitelist");
    _;
  }

  constructor(address _anyCallProxy) {
    // solhint-disable-next-line reason-string
    require(_anyCallProxy != address(0), "CrossChainCallProxy: zero address");

    anyCallProxy = _anyCallProxy;
  }

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  /********************************** Mutated Functions **********************************/

  /// @notice Relay cross chain call to AnyCallProxy contract.
  /// @param _to The recipient of the cross chain call on `_toChainID`.
  /// @param _data The calldata supplied for the interaction with `_to`
  /// @param _fallback The address to call back on the originating chain if the cross chain interaction fails.
  /// @param _toChainID The target chain id to interact with
  function crossChainCall(
    address _to,
    bytes memory _data,
    address _fallback,
    uint256 _toChainID
  ) external override onlyWhitelist {
    IAnyCallProxy(anyCallProxy).anyCall(_to, _data, _fallback, _toChainID);
  }

  /********************************** Restricted Functions **********************************/

  /// @notice Withdraw execution budget from AnyCallProxy contract.
  /// @param _amount The amount of budget to withdraw.
  function withdraw(uint256 _amount) external onlyOwner {
    IAnyCallProxy(anyCallProxy).withdraw(_amount);

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = msg.sender.call{ value: _amount }("");
    // solhint-disable-next-line reason-string
    require(success, "CrossChainCallProxy: transfer failed");
  }

  /// @notice Update AnyCallProxy contract.
  /// @param _anyCallProxy The address to update.
  function updateAnyCallProxy(address _anyCallProxy) external onlyOwner {
    // solhint-disable-next-line reason-string
    require(_anyCallProxy != address(0), "CrossChainCallProxy: zero address");

    anyCallProxy = _anyCallProxy;

    emit UpdateAnyCallProxy(_anyCallProxy);
  }

  /// @notice Update whitelist contract can call `crossChainCall`.
  /// @param _whitelist The list of whitelist address to update.
  /// @param _status The status to update.
  function updateWhitelist(address[] memory _whitelist, bool _status) external onlyOwner {
    for (uint256 i = 0; i < _whitelist.length; i++) {
      whitelist[_whitelist[i]] = _status;

      emit UpdateWhitelist(_whitelist[i], _status);
    }
  }

  /// @notice Execute calls on behalf of contract in case of emergency
  /// @param _to The address of contract to call.
  /// @param _value The amount of ETH passing to the contract.
  /// @param _data The data passing to the contract.
  function execute(
    address _to,
    uint256 _value,
    bytes calldata _data
  ) external onlyOwner returns (bool, bytes memory) {
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory result) = _to.call{ value: _value }(_data);
    return (success, result);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.6;

interface IAnyCallProxy {
  event LogAnyCall(address indexed from, address indexed to, bytes data, address _fallback, uint256 indexed toChainID);

  event LogAnyExec(
    address indexed from,
    address indexed to,
    bytes data,
    bool success,
    bytes result,
    address _fallback,
    uint256 indexed fromChainID
  );

  function setWhitelist(
    address _from,
    address _to,
    uint256 _toChainID,
    bool _flag
  ) external;

  function anyCall(
    address _to,
    bytes calldata _data,
    address _fallback,
    uint256 _toChainID
  ) external;

  function anyExec(
    address _from,
    address _to,
    bytes calldata _data,
    address _fallback,
    uint256 _fromChainID
  ) external;

  function withdraw(uint256 _amount) external;

  function deposit(address _account) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface ICrossChainCallProxy {
  function crossChainCall(
    address _to,
    bytes memory _data,
    address _fallback,
    uint256 _toChainID
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}