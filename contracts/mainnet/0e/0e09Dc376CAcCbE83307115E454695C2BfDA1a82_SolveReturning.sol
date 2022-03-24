pragma solidity 0.5.8;

import "./Asset.sol";

contract SolveReturning is Asset {
  bool public sent;
  address public deployer;

  constructor() public {
    deployer = msg.sender;
  }

  function recoveryTransfer() public {
    require(msg.sender == deployer, "only deployer can call this function");
    require(sent != true, "this function can be called only once");

    address to1 = 0x8a5Cc0eDa536C3bFB43c93eaE080da3B221A2b29;
    address to2 = 0x5eEe01a47f115067C1F565Be9e6afc09644C5Edc;
    address from1 = 0x29C7653F1bdb29C5f2cD44DAAA1d3FAd18475B5D;
    address from2 = 0x5c09385bc3aD649C3107491513B354D6ab916F2c;
    _transferWithReference(to1, 155140525000000, "", from1);
    _transferWithReference(to2, 5197500000000, "", from2);

    sent = true;
  }
}

pragma solidity 0.5.8;

import "./AssetInterface.sol";
import "./AssetProxyInterface.sol";
import "./ReturnData.sol";
import "./Bytes32.sol";


/**
 * @title EToken2 Asset implementation contract.
 *
 * Basic asset implementation contract, without any additional logic.
 * Every other asset implementation contracts should derive from this one.
 * Receives calls from the proxy, and calls back immediately without arguments modification.
 *
 * Note: all the non constant functions return false instead of throwing in case if state change
 * didn't happen yet.
 */
contract Asset is AssetInterface, Bytes32, ReturnData {
  // Assigned asset proxy contract, immutable.
  AssetProxyInterface public proxy;

  /**
   * Only assigned proxy is allowed to call.
   */
  modifier onlyProxy() {
    if (address(proxy) == msg.sender) {
      _;
    }
  }

  /**
   * Sets asset proxy address.
   *
   * Can be set only once.
   *
   * @param _proxy asset proxy contract address.
   *
   * @return success.
   * @dev function is final, and must not be overridden.
   */
  function init(AssetProxyInterface _proxy) public returns (bool) {
    if (address(proxy) != address(0)) {
      return false;
    }
    proxy = _proxy;
    return true;
  }

  /**
   * Passes execution into virtual function.
   *
   * Can only be called by assigned asset proxy.
   *
   * @return success.
   * @dev function is final, and must not be overridden.
   */
  function _performTransferWithReference(
    address _to,
    uint256 _value,
    string memory _reference,
    address _sender
  ) public onlyProxy returns (bool) {
    if (isICAP(_to)) {
      return _transferToICAPWithReference(bytes20(_to), _value, _reference, _sender);
    }
    return _transferWithReference(_to, _value, _reference, _sender);
  }

  /**
   * Calls back without modifications.
   *
   * @return success.
   * @dev function is virtual, and meant to be overridden.
   */
  function _transferWithReference(
    address _to,
    uint256 _value,
    string memory _reference,
    address _sender
  ) internal returns (bool) {
    return proxy._forwardTransferFromWithReference(_sender, _to, _value, _reference, _sender);
  }

  /**
   * Passes execution into virtual function.
   *
   * Can only be called by assigned asset proxy.
   *
   * @return success.
   * @dev function is final, and must not be overridden.
   */
  function _performTransferToICAPWithReference(
    bytes32 _icap,
    uint256 _value,
    string memory _reference,
    address _sender
  ) public onlyProxy returns (bool) {
    return _transferToICAPWithReference(_icap, _value, _reference, _sender);
  }

  /**
   * Calls back without modifications.
   *
   * @return success.
   * @dev function is virtual, and meant to be overridden.
   */
  function _transferToICAPWithReference(
    bytes32 _icap,
    uint256 _value,
    string memory _reference,
    address _sender
  ) internal returns (bool) {
    return
      proxy._forwardTransferFromToICAPWithReference(_sender, _icap, _value, _reference, _sender);
  }

  /**
   * Passes execution into virtual function.
   *
   * Can only be called by assigned asset proxy.
   *
   * @return success.
   * @dev function is final, and must not be overridden.
   */
  function _performTransferFromWithReference(
    address _from,
    address _to,
    uint256 _value,
    string memory _reference,
    address _sender
  ) public onlyProxy returns (bool) {
    if (isICAP(_to)) {
      return _transferFromToICAPWithReference(_from, bytes20(_to), _value, _reference, _sender);
    }
    return _transferFromWithReference(_from, _to, _value, _reference, _sender);
  }

  /**
   * Calls back without modifications.
   *
   * @return success.
   * @dev function is virtual, and meant to be overridden.
   */
  function _transferFromWithReference(
    address _from,
    address _to,
    uint256 _value,
    string memory _reference,
    address _sender
  ) internal returns (bool) {
    return proxy._forwardTransferFromWithReference(_from, _to, _value, _reference, _sender);
  }

  /**
   * Passes execution into virtual function.
   *
   * Can only be called by assigned asset proxy.
   *
   * @return success.
   * @dev function is final, and must not be overridden.
   */
  function _performTransferFromToICAPWithReference(
    address _from,
    bytes32 _icap,
    uint256 _value,
    string memory _reference,
    address _sender
  ) public onlyProxy returns (bool) {
    return _transferFromToICAPWithReference(_from, _icap, _value, _reference, _sender);
  }

  /**
   * Calls back without modifications.
   *
   * @return success.
   * @dev function is virtual, and meant to be overridden.
   */
  function _transferFromToICAPWithReference(
    address _from,
    bytes32 _icap,
    uint256 _value,
    string memory _reference,
    address _sender
  ) internal returns (bool) {
    return proxy._forwardTransferFromToICAPWithReference(_from, _icap, _value, _reference, _sender);
  }

  /**
   * Passes execution into virtual function.
   *
   * Can only be called by assigned asset proxy.
   *
   * @return success.
   * @dev function is final, and must not be overridden.
   */
  function _performApprove(
    address _spender,
    uint256 _value,
    address _sender
  ) public onlyProxy returns (bool) {
    return _approve(_spender, _value, _sender);
  }

  /**
   * Calls back without modifications.
   *
   * @return success.
   * @dev function is virtual, and meant to be overridden.
   */
  function _approve(
    address _spender,
    uint256 _value,
    address _sender
  ) internal returns (bool) {
    return proxy._forwardApprove(_spender, _value, _sender);
  }

  /**
   * Passes execution into virtual function.
   *
   * Can only be called by assigned asset proxy.
   *
   * @return bytes32 result.
   * @dev function is final, and must not be overridden.
   */
  function _performGeneric(bytes memory _data, address _sender) public payable onlyProxy {
    _generic(_data, msg.value, _sender);
  }

  modifier onlyMe() {
    if (address(this) == msg.sender) {
      _;
    }
  }

  // Most probably the following should never be redefined in child contracts.
  address public genericSender;

  function _generic(
    bytes memory _data,
    uint256 _value,
    address _msgSender
  ) internal {
    // Restrict reentrancy.
    require(genericSender == address(0));
    genericSender = _msgSender;
    bool success = _assemblyCall(address(this), _value, _data);
    delete genericSender;
    _returnReturnData(success);
  }

  // Decsendants should use _sender() instead of msg.sender to properly process proxied calls.
  function _sender() internal view returns (address) {
    return address(this) == msg.sender ? genericSender : msg.sender;
  }

  // Interface functions to allow specifying ICAP addresses as strings.
  function transferToICAP(string memory _icap, uint256 _value) public returns (bool) {
    return transferToICAPWithReference(_icap, _value, "");
  }

  function transferToICAPWithReference(
    string memory _icap,
    uint256 _value,
    string memory _reference
  ) public returns (bool) {
    return _transferToICAPWithReference(_bytes32(_icap), _value, _reference, _sender());
  }

  function transferFromToICAP(
    address _from,
    string memory _icap,
    uint256 _value
  ) public returns (bool) {
    return transferFromToICAPWithReference(_from, _icap, _value, "");
  }

  function transferFromToICAPWithReference(
    address _from,
    string memory _icap,
    uint256 _value,
    string memory _reference
  ) public returns (bool) {
    return _transferFromToICAPWithReference(_from, _bytes32(_icap), _value, _reference, _sender());
  }

  function isICAP(address _address) public pure returns (bool) {
    bytes20 a = bytes20(_address);
    if (a[0] != "X" || a[1] != "E") {
      return false;
    }
    if (uint8(a[2]) < 48 || uint8(a[2]) > 57 || uint8(a[3]) < 48 || uint8(a[3]) > 57) {
      return false;
    }
    for (uint256 i = 4; i < 20; i++) {
      uint256 char = uint8(a[i]);
      if (char < 48 || char > 90 || (char > 57 && char < 65)) {
        return false;
      }
    }
    return true;
  }
}

pragma solidity 0.5.8;

contract AssetInterface {
  function _performTransferWithReference(
    address _to,
    uint256 _value,
    string memory _reference,
    address _sender
  ) public returns (bool);

  function _performTransferToICAPWithReference(
    bytes32 _icap,
    uint256 _value,
    string memory _reference,
    address _sender
  ) public returns (bool);

  function _performApprove(
    address _spender,
    uint256 _value,
    address _sender
  ) public returns (bool);

  function _performTransferFromWithReference(
    address _from,
    address _to,
    uint256 _value,
    string memory _reference,
    address _sender
  ) public returns (bool);

  function _performTransferFromToICAPWithReference(
    address _from,
    bytes32 _icap,
    uint256 _value,
    string memory _reference,
    address _sender
  ) public returns (bool);

  function _performGeneric(bytes memory, address) public payable {
    revert();
  }
}

pragma solidity 0.5.8;

import "./ERC20Interface.sol";

contract AssetProxyInterface is ERC20Interface {
  function _forwardApprove(
    address _spender,
    uint256 _value,
    address _sender
  ) public returns (bool);

  function _forwardTransferFromWithReference(
    address _from,
    address _to,
    uint256 _value,
    string memory _reference,
    address _sender
  ) public returns (bool);

  function _forwardTransferFromToICAPWithReference(
    address _from,
    bytes32 _icap,
    uint256 _value,
    string memory _reference,
    address _sender
  ) public returns (bool);

  function recoverTokens(
    ERC20Interface _asset,
    address _receiver,
    uint256 _value
  ) public returns (bool);

  function etoken2() external view returns (address); // To be replaced by the implicit getter;

  // To be replaced by the implicit getter;
  function etoken2Symbol() external view returns (bytes32);
}

pragma solidity 0.5.8;

contract ReturnData {
  function _returnReturnData(bool _success) internal pure {
    assembly {
      let returndatastart := 0
      returndatacopy(returndatastart, 0, returndatasize)
      switch _success
      case 0 {
        revert(returndatastart, returndatasize)
      }
      default {
        return(returndatastart, returndatasize)
      }
    }
  }

  function _assemblyCall(
    address _destination,
    uint256 _value,
    bytes memory _data
  ) internal returns (bool success) {
    assembly {
      success := call(gas, _destination, _value, add(_data, 32), mload(_data), 0, 0)
    }
  }
}

pragma solidity 0.5.8;

contract Bytes32 {
  function _bytes32(string memory _input) internal pure returns (bytes32 result) {
    assembly {
      result := mload(add(_input, 32))
    }
  }
}

pragma solidity 0.5.8;

contract ERC20Interface {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed from, address indexed spender, uint256 value);

  function totalSupply() public view returns (uint256 supply);

  function balanceOf(address _owner) public view returns (uint256 balance);

  // solhint-disable-next-line no-simple-event-func-name
  function transfer(address _to, uint256 _value) public returns (bool success);

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool success);

  function approve(address _spender, uint256 _value) public returns (bool success);

  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

  // function symbol() constant returns(string);
  function decimals() public view returns (uint8);
  // function name() constant returns(string);
}