// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/VaultERC20.sol";
import "src/VaultERC721.sol";
import "src/VaultETH.sol";
import "src/VaultExecute.sol";
import "src/VaultNewReceivers.sol";
import "src/VaultIssueERC721.sol";


contract Vault is
  VaultERC20,
  VaultERC721,
  VaultETH,
  VaultExecute,
  VaultNewReceivers,
  VaultIssueERC721
{
  constructor()
    VaultERC20(1, 2)
    VaultERC721(3)
    VaultETH(4, 5)
    VaultExecute(6, 7)
    VaultNewReceivers(8)
    VaultIssueERC721(9)
    Pausable(10)
  {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/interfaces/IERC20.sol";

import "src/commons/receiver/ReceiverHub.sol";

import "src/commons/Permissions.sol";
import "src/commons/Pausable.sol";

import "src/utils/SafeERC20.sol";


abstract contract VaultERC20 is ReceiverHub, Permissions, Pausable {
  using SafeERC20 for IERC20;

  error ErrorSweepingERC20(address _token, address _receiver, uint256 _amount, bytes _result);
  error ArrayLengthMismatchERC20(uint256 _array1, uint256 _array2);

  uint8 public immutable PERMISSION_SWEEP_ERC20;
  uint8 public immutable PERMISSION_SEND_ERC20;

  constructor (uint8 _sweepErc20Permission, uint8 _sendErc20Permission) {
    PERMISSION_SWEEP_ERC20 = _sweepErc20Permission;
    PERMISSION_SEND_ERC20 = _sendErc20Permission;

    _registerPermission(PERMISSION_SWEEP_ERC20);
    _registerPermission(PERMISSION_SEND_ERC20);
  }

  function sweepERC20(
    IERC20 _token,
    uint256 _id
  ) external notPaused onlyPermissioned(PERMISSION_SWEEP_ERC20) {
    _sweepERC20(_token, _id);
  }

  function sweepBatchERC20(
    IERC20 _token,
    uint256[] calldata _ids
  ) external notPaused onlyPermissioned(PERMISSION_SWEEP_ERC20) {
    unchecked {
      uint256 idsLength = _ids.length;
      for (uint256 i = 0; i < idsLength; ++i) {
        _sweepERC20(_token, _ids[i]);
      }
    }
  }

  function _sweepERC20(
    IERC20 _token,
    uint256 _id
  ) internal {
    Receiver receiver = receiverFor(_id);
    uint256 balance = _token.balanceOf(address(receiver));

    if (balance != 0) {
      createIfNeeded(receiver, _id);

      bytes memory res = executeOnReceiver(receiver, address(_token), 0, abi.encodeWithSelector(
        IERC20.transfer.selector,
        address(this),
        balance
      ));

      if (!SafeERC20.optionalReturnsTrue(res)) {
        revert ErrorSweepingERC20(address(_token), address(receiver), balance, res);
      }
    }
  }

  function sendERC20(
    IERC20 _token,
    address _to,
    uint256 _amount
  ) external notPaused onlyPermissioned(PERMISSION_SEND_ERC20) {
    _token.safeTransfer(_to, _amount);
  }

  function sendBatchERC20(
    IERC20 _token,
    address[] calldata _to,
    uint256[] calldata _amounts
  ) external notPaused onlyPermissioned(PERMISSION_SEND_ERC20) {
    uint256 toLength = _to.length;
    if (toLength != _amounts.length) {
      revert ArrayLengthMismatchERC20(toLength, _amounts.length);
    }

    unchecked {
      for (uint256 i = 0; i < toLength; ++i) {
        _token.safeTransfer(_to[i], _amounts[i]);
      }
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/interfaces/IERC721.sol";

import "src/commons/receiver/ReceiverHub.sol";
import "src/commons/Permissions.sol";
import "src/commons/Pausable.sol";


abstract contract VaultERC721 is ReceiverHub, Permissions, Pausable {
  uint8 public immutable PERMISSION_SEND_ERC721;

  error ArrayLengthMismatchERC721(uint256 _array1, uint256 _array2, uint256 _array3);

  constructor (uint8 _sendErc721Permission) {
    PERMISSION_SEND_ERC721 = _sendErc721Permission;

    _registerPermission(PERMISSION_SEND_ERC721);
  }

  function sendERC721(
    IERC721 _token,
    uint256 _from,
    address _to,
    uint256 _id
  ) external notPaused onlyPermissioned(PERMISSION_SEND_ERC721) {
    Receiver receiver = useReceiver(_from);

    executeOnReceiver(receiver, address(_token), 0, abi.encodeWithSelector(
        _token.transferFrom.selector,
        address(receiver),
        _to,
        _id
      )
    );
  }

  function sendBatchERC721(
    IERC721 _token,
    uint256[] calldata _ids,
    address[] calldata _tos,
    uint256[] calldata _tokenIds
  ) external notPaused onlyPermissioned(PERMISSION_SEND_ERC721) {
    unchecked {
      uint256 idsLength = _ids.length;

      if (idsLength != _tos.length || idsLength != _tokenIds.length) {
        revert ArrayLengthMismatchERC721(idsLength, _tos.length, _tokenIds.length);
      }

      for (uint256 i = 0; i < idsLength; ++i) {
        Receiver receiver = useReceiver(_ids[i]);
        executeOnReceiver(receiver, address(_token), 0, abi.encodeWithSelector(
            _token.transferFrom.selector,
            address(receiver),
            _tos[i],
            _tokenIds[i]
          )
        );
      }
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/commons/receiver/ReceiverHub.sol";
import "src/commons/Permissions.sol";
import "src/commons/Pausable.sol";


abstract contract VaultETH is ReceiverHub, Permissions, Pausable {
  error ErrorSendingETH(address _to, uint256 _amount, bytes _result);
  error ArrayLengthMismatchETH(uint256 _array1, uint256 _array2);

  uint8 public immutable PERMISSION_SWEEP_ETH;
  uint8 public immutable PERMISSION_SEND_ETH;

  constructor (uint8 _sweepETHPermission, uint8 _sendETHPermission) {
    PERMISSION_SWEEP_ETH = _sweepETHPermission;
    PERMISSION_SEND_ETH = _sendETHPermission;

    _registerPermission(PERMISSION_SWEEP_ETH);
    _registerPermission(PERMISSION_SEND_ETH);
  }

  function sweepETH(
    uint256 _id
  ) external notPaused onlyPermissioned(PERMISSION_SWEEP_ETH) {
    _sweepETH(_id);
  }

  function sweepBatchETH(
    uint256[] calldata _ids
  ) external notPaused onlyPermissioned(PERMISSION_SWEEP_ETH) {
    unchecked {
      uint256 idsLength = _ids.length;
      for (uint256 i = 0; i < idsLength; ++i) {
        _sweepETH(_ids[i]);
      }
    }
  }

  function _sweepETH(uint256 _id) internal {
    Receiver receiver = receiverFor(_id);
    uint256 balance = address(receiver).balance;
    if (balance != 0) {
      createIfNeeded(receiver, _id);
      executeOnReceiver(receiver, address(this), balance, bytes(""));
    }
  }

  function sendETH(
    address payable _to,
    uint256 _amount
  ) external notPaused onlyPermissioned(PERMISSION_SEND_ETH) {
    (bool succeed, bytes memory result) = _to.call{ value: _amount }("");
    if (!succeed) { revert ErrorSendingETH(_to, _amount, result); }
  }

  function sendBatchETH(
    address payable[] calldata  _tos,
    uint256[] calldata _amounts
  ) external notPaused onlyPermissioned(PERMISSION_SEND_ETH) {
    uint256 toLength = _tos.length;
    if (toLength != _amounts.length) {
      revert ArrayLengthMismatchETH(toLength, _amounts.length);
    }

    unchecked {
      for (uint256 i = 0; i < toLength; ++i) {
        (bool succeed, bytes memory result) = _tos[i].call{ value: _amounts[i] }("");
        if (!succeed) { revert ErrorSendingETH(_tos[i], _amounts[i], result); }
      }
    }
  }

  receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/commons/receiver/ReceiverHub.sol";
import "src/commons/Permissions.sol";
import "src/commons/Pausable.sol";


abstract contract VaultExecute is ReceiverHub, Permissions, Pausable {
  uint8 public immutable PERMISSION_EXECUTE_ON_RECEIVER;
  uint8 public immutable PERMISSION_EXECUTE;

  error CallError(address _to, uint256 _value, bytes _data, bytes _result);

  constructor(
    uint8 _executeOnReceiverPermission,
    uint8 _executePermission
  ) {
    PERMISSION_EXECUTE_ON_RECEIVER = _executeOnReceiverPermission;
    PERMISSION_EXECUTE = _executePermission;

    _registerPermission(PERMISSION_EXECUTE_ON_RECEIVER);
    _registerPermission(PERMISSION_EXECUTE);
  }

  function executeOnReceiver(
    uint256 _id,
    address payable _to,
    uint256 _value,
    bytes calldata _data
  ) external notPaused onlyPermissioned(PERMISSION_EXECUTE_ON_RECEIVER) returns (bytes memory) {
    return executeOnReceiver(_id, _to, _value, _data);
  }

  function execute(
    address payable _to,
    uint256 _value,
    bytes calldata _data
  ) external notPaused onlyPermissioned(PERMISSION_EXECUTE) returns (bytes memory) {
    (bool res, bytes memory result) = _to.call{ value: _value }(_data);
    if (!res) revert CallError(_to, _value, _data, result);
    return result;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/commons/Permissions.sol";
import "src/commons/Pausable.sol";

import "src/interfaces/IERC721Deterministic.sol";


abstract contract VaultIssueERC721 is Permissions, Pausable {
  uint8 public immutable PERMISSION_ISSUE_ERC721;

  error ArrayLengthMismatchIssueERC721(uint256 _array1, uint256 _array2, uint256 _array3);

  constructor (uint8 _issueERC721Permission) {
    PERMISSION_ISSUE_ERC721 = _issueERC721Permission;

    _registerPermission(PERMISSION_ISSUE_ERC721);
  }

  function issueERC721(
    address _beneficiary,
    IERC721Deterministic _contract,
    uint256 _optionId,
    uint256 _issuedId
  ) external notPaused onlyPermissioned(PERMISSION_ISSUE_ERC721) {
    _contract.issueToken(_beneficiary, _optionId, _issuedId);
  }

  function issueBatchERC721(
    address _beneficiary,
    IERC721Deterministic[] calldata _contracts,
    uint256[] calldata _optionIds,
    uint256[] calldata _issuedIds
  ) external notPaused onlyPermissioned(PERMISSION_ISSUE_ERC721) {
    unchecked {
      uint256 contractsLength = _contracts.length;

      if (contractsLength != _optionIds.length || contractsLength != _issuedIds.length) {
        revert ArrayLengthMismatchIssueERC721(contractsLength, _optionIds.length, _issuedIds.length);
      }

      for (uint256 i = 0; i < contractsLength; ++i) {
        _contracts[i].issueToken(_beneficiary, _optionIds[i], _issuedIds[i]);
      }
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/commons/receiver/ReceiverHub.sol";
import "src/commons/Permissions.sol";
import "src/commons/Pausable.sol";


abstract contract VaultNewReceivers is ReceiverHub, Permissions, Pausable {
  uint8 public immutable PERMISSION_DEPLOY_RECEIVER;

  constructor (uint8 _deployReceiverPermission) {
    PERMISSION_DEPLOY_RECEIVER = _deployReceiverPermission;

    _registerPermission(PERMISSION_DEPLOY_RECEIVER);
  }

  function deployReceivers(
    uint256[] calldata _receivers
  ) external notPaused onlyPermissioned(PERMISSION_DEPLOY_RECEIVER) {
    unchecked {
      uint256 receiversLength = _receivers.length;

      for (uint256 i = 0; i < receiversLength; ++i) {
        useReceiver(_receivers[i]);
      }
    }
  }

  function deployReceiversRange(
    uint256 _from,
    uint256 _to
  ) external notPaused onlyPermissioned(PERMISSION_DEPLOY_RECEIVER) {
    unchecked {
      for (uint256 i = _from; i < _to; ++i) {
        useReceiver(i);
      }
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/interfaces/IERC173.sol";


contract Ownable is IERC173 {
  error NotOwner(address _sender, address _owner);
  error InvalidNewOwner();

  address public owner;

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
  }

  modifier onlyOwner() {
    if (!isOwner(msg.sender)) revert NotOwner(msg.sender, owner);
    _;
  }

  function isOwner(address _owner) public view returns (bool) {
    return _owner == owner && _owner != address(0);
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    if (_newOwner == address(0)) revert InvalidNewOwner();

    owner = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function rennounceOwnership() external onlyOwner {
    owner = address(0);
    emit OwnershipTransferred(msg.sender, address(0));
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/commons/Ownable.sol";
import "src/commons/Permissions.sol";


contract Pausable is Ownable, Permissions {
  error ContractPaused();

  event Unpaused(address _sender);
  event Paused(address _sender);

  enum State { Invalid, Unpaused, Paused }

  State internal _state = State.Unpaused;
  uint8 public immutable PERMISSION_PAUSE;

  constructor(uint8 _permissionPause) {
    PERMISSION_PAUSE = _permissionPause;
  }

  modifier notPaused() {
    if (_state == State.Paused) {
      revert ContractPaused();
    }

    _;
  }

  function isPaused() public view returns (bool) {
    return _state == State.Paused;
  }

  function pause() external onlyPermissioned(PERMISSION_PAUSE) {
    _state = State.Paused;
    emit Paused(msg.sender);
  }

  function unpause() external onlyOwner {
    _state = State.Unpaused;
    emit Unpaused(msg.sender);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/commons/Ownable.sol";


contract Permissions is Ownable {
  error PermissionDenied(address _sender, uint8 _permission);
  error DuplicatedPermission(uint8 _permission);

  mapping (address => bytes32) public permissions;
  mapping (uint8 => bool) public permissionExists;

  event AddPermission(address indexed _addr, uint8 _permission);
  event DelPermission(address indexed _addr, uint8 _permission);
  event ClearPermissions(address indexed _addr);

  modifier onlyPermissioned(uint8 _permission) {
    if (!hasPermission(msg.sender, _permission) && !isOwner(msg.sender)) {
      revert PermissionDenied(msg.sender, _permission);
    }

    _;
  }

  function _registerPermission(uint8 _permission) internal {
    if (permissionExists[_permission]) {
      revert DuplicatedPermission(_permission);
    }

    permissionExists[_permission] = true;
  }

  function hasPermission(address _addr, uint8 _permission) public view returns (bool) {
    return (permissions[_addr] & _maskForPermission(_permission)) != 0;
  }

  function addPermission(address _addr, uint8 _permission) external virtual onlyOwner {
    _addPermission(_addr, _permission);
  }

  function addPermissions(address _addr, uint8[] calldata _permissions) external virtual onlyOwner {
    _addPermissions(_addr, _permissions);
  }

  function delPermission(address _addr, uint8 _permission) external virtual onlyOwner {
    _delPermission(_addr, _permission);
  }

  function clearPermissions(address _addr) external virtual onlyOwner {
    _clearPermissions(_addr);
  }

  function _maskForPermission(uint8 _permission) internal pure returns (bytes32) {
    return bytes32(1 << _permission);
  }

  function _addPermission(address _addr, uint8 _permission) internal {
    permissions[_addr] |= _maskForPermission(_permission);
    emit AddPermission(_addr, _permission);
  }

  function _addPermissions(address _addr, uint8[] calldata _permissions) internal {
    unchecked {
      for (uint256 i = 0; i < _permissions.length; ++i) {
        _addPermission(_addr, _permissions[i]);
      }
    }
  }

  function _delPermission(address _addr, uint8 _permission) internal {
    permissions[_addr] &= ~_maskForPermission(_permission);
    emit DelPermission(_addr, _permission);
  }

  function _clearPermissions(address _addr) internal {
    delete permissions[_addr];
    emit ClearPermissions(_addr);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/interfaces/IERC721Receiver.sol";


contract Receiver is IERC721Receiver {
  error NotAuthorized(address _sender);

  address immutable private owner;

  constructor () {
    owner = msg.sender;
  }

  function execute(address payable _to, uint256 _value, bytes calldata _data) external returns (bool, bytes memory) {
    if (msg.sender != owner) revert NotAuthorized(msg.sender);
    return _to.call{ value: _value }(_data);
  }

  function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
    // return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
    return 0x150b7a02;
  }

  receive() external payable { }
  fallback() external payable { }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/libs/CREATE2.sol";
import "src/utils/Proxy.sol";

import "src/commons/receiver/Receiver.sol";


contract ReceiverHub {
  error ReceiverCallError(address _receiver, address _to, uint256 _value, bytes _data, bytes _result);
  
  address immutable public receiverTemplate;
  bytes32 immutable private receiverTemplateCreationCodeHash;

  constructor () {
    receiverTemplate = address(new Receiver());
    receiverTemplateCreationCodeHash = keccak256(Proxy.creationCode(address(receiverTemplate)));
  }

  function receiverFor(uint256 _id) public view returns (Receiver) {
    return Receiver(CREATE2.addressOf(address(this), _id, receiverTemplateCreationCodeHash));
  }

  function createReceiver(uint256 _id) internal returns (Receiver) {
    return Receiver(CREATE2.deploy(_id, Proxy.creationCode(receiverTemplate)));
  }

  function createIfNeeded(Receiver receiver, uint256 _id) internal returns (Receiver) {
    uint256 receiverCodeSize; assembly { receiverCodeSize := extcodesize(receiver) }
    if (receiverCodeSize != 0) {
      return receiver;
    }

    return createReceiver(_id);
  }

  function useReceiver(uint256 _id) internal returns (Receiver) {
    return createIfNeeded(receiverFor(_id), _id);
  }

  function executeOnReceiver(uint256 _id, address _to, uint256 _value, bytes memory _data) internal returns (bytes memory) {
    return executeOnReceiver(useReceiver(_id), _to, _value, _data);
  }

  function executeOnReceiver(Receiver _receiver, address _to, uint256 _value, bytes memory _data) internal returns (bytes memory) {
    (bool succeed, bytes memory result) = _receiver.execute(payable(_to), _value, _data);
    if (!succeed) revert ReceiverCallError(address(_receiver), _to, _value, _data, result);

    return result;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;


interface IERC173 {
  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
  function owner() view external returns(address);
  function transferOwnership(address _newOwner) external;	
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;


interface IERC20 {
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function totalSupply() external view returns (uint256);
  function balanceOf(address _account) external view returns (uint256);
  function transfer(address _to, uint256 _amount) external returns (bool);
  function allowance(address _owner, address _spender) external view returns (uint256);
  function approve(address _spender, uint256 _amount) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;


interface IERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function approve(address _approved, uint256 _tokenId) external payable;
  function setApprovalForAll(address _operator, bool _approved) external;
  function getApproved(uint256 _tokenId) external view returns (address);
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;


interface IERC721Deterministic {
  function issueToken(address _beneficiary, uint256 _optionId, uint256 _issuedId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;


interface IERC721Receiver {
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;


library CREATE2 {
  error ContractNotCreated();

  function addressOf(address _creator, uint256 _salt, bytes32 _creationCodeHash) internal pure returns (address payable) {
    return payable(
        address(
        uint160(
          uint256(
            keccak256(
              abi.encodePacked(
                bytes1(0xff),
                _creator,
                _salt,
                _creationCodeHash
              )
            )
          )
        )
      )
    );
  }

  function deploy(uint256 _salt, bytes memory _creationCode) internal returns (address payable _contract) {
    assembly {
      _contract := create2(callvalue(), add(_creationCode, 32), mload(_creationCode), _salt)
    }

    if (_contract == address(0)) {
      revert ContractNotCreated();
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

library Proxy {
  function creationCode(address _target) internal pure returns (bytes memory result) {
    return abi.encodePacked(
      hex'3d602d80600a3d3981f3363d3d373d3d3d363d73',
      _target,
      hex'5af43d82803e903d91602b57fd5bf3'
    );
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/interfaces/IERC20.sol";


library SafeERC20 {
  error ErrorSendingERC20(address _token, address _to, uint256 _amount, bytes _result);

  function safeTransfer(IERC20 _token, address _to, uint256 _amount) internal {
    (bool success, bytes memory result) = address(_token).call(abi.encodeWithSelector(
      IERC20.transfer.selector,
      _to,
      _amount
    ));

    if (!success || !optionalReturnsTrue(result)) {
      revert ErrorSendingERC20(address(_token), _to, _amount, result);
    }
  }

  function optionalReturnsTrue(bytes memory _return) internal pure returns (bool) {
    return _return.length == 0 || abi.decode(_return, (bool));
  }
}