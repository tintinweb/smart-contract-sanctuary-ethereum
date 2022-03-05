// Cosmic Kiss Mixer
// https://cosmickiss.io/

// SPDX-License-Identifier: MIT


pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


import "ICosmicInstance.sol";
import "IERC20.sol";


contract CosmicRouter {


  event EncryptedNote(address indexed sender, bytes encryptedNote);
  event InstanceStateUpdate(ICosmicInstance indexed instance, InstanceState state);


  enum InstanceState { Disabled, Enabled }

  struct Instance {
    bool isERC20;
    IERC20 token;
    InstanceState state;
  }

  struct CosmicInstance {
    ICosmicInstance addr;
    Instance instance;
  }

  mapping(ICosmicInstance => Instance) public instances;

  constructor(
    CosmicInstance[] memory _instances
  ) public {

    for (uint256 i = 0; i < _instances.length; i++) {
      _updateInstance(_instances[i]);
    }
  }

  function deposit(
    ICosmicInstance _cosmic,
    bytes32 _commitment,
    bytes calldata _encryptedNote
) external payable {
    Instance memory instance = instances[_cosmic];
    require(instance.state != InstanceState.Disabled, "The instance is not supported");

    if (instance.isERC20) {
      instance.token.transferFrom(msg.sender, address(this), _cosmic.denomination());
    }
    _cosmic.deposit{ value: msg.value }(_commitment);

    emit EncryptedNote(msg.sender, _encryptedNote);
  }

  function withdraw(
    ICosmicInstance _cosmic,
    bytes calldata _proof,
    bytes32 _root,
    bytes32 _nullifierHash,
    address payable _recipient,
    address payable _relayer,
    uint256 _fee,
    uint256 _refund
  ) external payable {
    Instance memory instance = instances[_cosmic];
    require(instance.state != InstanceState.Disabled, "The instance is not supported");

    _cosmic.withdraw{ value: msg.value }(_proof, _root, _nullifierHash, _recipient, _relayer, _fee, _refund);
  }

  function backupNotes(bytes[] calldata _encryptedNotes) external {
    for (uint256 i = 0; i < _encryptedNotes.length; i++) {
      emit EncryptedNote(msg.sender, _encryptedNotes[i]);
    }
  }

  function updateInstance(CosmicInstance calldata _cosmic) external {
    _updateInstance(_cosmic);
  }
  
  function _updateInstance(CosmicInstance memory _cosmic) internal {
    instances[_cosmic.addr] = _cosmic.instance;
    if (_cosmic.instance.isERC20) {
      IERC20 token = IERC20(_cosmic.addr.token());
      require(token == _cosmic.instance.token, "Incorrect token");
      uint256 allowance = token.allowance(address(this), address(_cosmic.addr));

      if (_cosmic.instance.state != InstanceState.Disabled && allowance == 0) {
        token.approve(address(_cosmic.addr), uint256(-1));
      } else if (_cosmic.instance.state == InstanceState.Disabled && allowance != 0) {
        token.approve(address(_cosmic.addr), 0);
      }
    }
    emit InstanceStateUpdate(_cosmic.addr, _cosmic.instance.state);
  }
}