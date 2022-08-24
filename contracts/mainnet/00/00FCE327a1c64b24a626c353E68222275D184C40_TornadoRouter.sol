// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./ITornadoInstance.sol";
import "./ENS.sol";
import "./InstanceRegistry.sol";
import "./RelayerRegistry.sol";

contract TornadoRouter is EnsResolve {
  using SafeERC20 for IERC20;

  event EncryptedNote(address indexed sender, bytes encryptedNote);
  event StakeBurned(address relayer, uint256 amountBurned);

  address public immutable governance;
  InstanceRegistry public immutable instanceRegistry;
  RelayerRegistry public immutable relayerRegistry;

  modifier onlyGovernance() {
    require(msg.sender == governance, "Not authorized");
    _;
  }

  modifier onlyInstanceRegistry() {
    require(msg.sender == address(instanceRegistry), "Not authorized");
    _;
  }

  constructor(
    address _governance,
    InstanceRegistry _instanceRegistry,
    RelayerRegistry _relayerRegistry
  ) public {
    governance = _governance;
    instanceRegistry = _instanceRegistry;
    relayerRegistry = _relayerRegistry;
  }

  function deposit(
    ITornadoInstance _tornado,
    bytes32 _commitment,
    bytes calldata _encryptedNote
  ) public payable virtual {
    (bool isERC20, IERC20 token, InstanceRegistry.InstanceState state, , ) = instanceRegistry.instances(_tornado);
    require(state != InstanceRegistry.InstanceState.DISABLED, "The instance is not supported");

    if (isERC20) {
      token.safeTransferFrom(msg.sender, address(this), _tornado.denomination());
    }
    _tornado.deposit{ value: msg.value }(_commitment);
    emit EncryptedNote(msg.sender, _encryptedNote);
  }

  function withdraw(
    ITornadoInstance _tornado,
    bytes calldata _proof,
    bytes32 _root,
    bytes32 _nullifierHash,
    address payable _recipient,
    address payable _relayer,
    uint256 _fee,
    uint256 _refund
  ) public payable virtual {
    (, , InstanceRegistry.InstanceState state, , ) = instanceRegistry.instances(_tornado);
    require(state != InstanceRegistry.InstanceState.DISABLED, "The instance is not supported");
    uint256 toBurn = relayerRegistry.feeManager().instanceFeeWithUpdate(_tornado);
    emit StakeBurned(_relayer, toBurn);

    _tornado.withdraw{ value: msg.value }(_proof, _root, _nullifierHash, _recipient, _relayer, _fee, _refund);
  }

  /**
   * @dev Sets `amount` allowance of `_spender` over the router's (this contract) tokens.
   */
  function approveExactToken(
    IERC20 _token,
    address _spender,
    uint256 _amount
  ) external onlyInstanceRegistry {
    _token.safeApprove(_spender, _amount);
  }

  /**
   * @notice Manually backup encrypted notes
   */
  function backupNotes(bytes[] calldata _encryptedNotes) external virtual {
    for (uint256 i = 0; i < _encryptedNotes.length; i++) {
      emit EncryptedNote(msg.sender, _encryptedNotes[i]);
    }
  }

  /// @dev Method to claim junk and accidentally sent tokens
  function rescueTokens(
    IERC20 _token,
    address payable _to,
    uint256 _amount
  ) external virtual onlyGovernance {
    require(_to != address(0), "TORN: can not send to zero address");

    if (_token == IERC20(0)) {
      // for Ether
      uint256 totalBalance = address(this).balance;
      uint256 balance = Math.min(totalBalance, _amount);
      _to.transfer(balance);
    } else {
      // any other erc20
      uint256 totalBalance = _token.balanceOf(address(this));
      uint256 balance = Math.min(totalBalance, _amount);
      require(balance > 0, "TORN: trying to send 0 balance");
      _token.safeTransfer(_to, balance);
    }
  }
}