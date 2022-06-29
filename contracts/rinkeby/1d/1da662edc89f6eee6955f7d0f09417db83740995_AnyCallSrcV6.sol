/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// Sources flattened with hardhat v2.9.5 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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


// File contracts/AnyCallSrcV6.sol

pragma solidity ^0.8.0;

interface CallProxy{
  function anyCall(
      address _to,
      bytes calldata _data,
      address _fallback,
      uint256 _toChainID,
      uint256 _flags
  ) external;
}

contract AnyCallSrcV6 is Initializable {

  address private _anyCallProxy;
  address private _owner;
  address private _anyCallDst;
  uint private _chainIdDst;
  uint private _flags;
  address private _fallback; // maybe 0x0

  event NewMsg(string msg);

  modifier onlyOwner {
    require(msg.sender == _owner, 'Not owner');
    _;
  }

  function getOwner() view external returns(address) {
    return _owner;
  }

  function getAnyCallProxy() view external returns(address) {
    return _anyCallProxy;
  }

  function getChainIdDst() view external returns(uint) {
    return _chainIdDst;
  }

  function getFlags() view external returns(uint) {
    return _flags;
  }

  function getAnyCallDst() view external returns(address) {
    return _anyCallDst;
  }

  function setFlags(uint flags) onlyOwner external {
    _flags = flags;
  }

  function setAnyCallDst(address anyCallDst) onlyOwner external {
    _anyCallDst = anyCallDst;
  }

  function setChainIdDst(uint chainIdDst) onlyOwner external {
    _chainIdDst = chainIdDst;
  }

  function setFallback(address fallbck) onlyOwner external {
    _fallback = fallbck;
  }

  function setAnyCallProxy(address anyCallProxy) onlyOwner external {
    _anyCallProxy = anyCallProxy;
  }

  function initialize(
    address anyCallProxy,
    address anyCallDst, // receiver contract
    uint chainIdDst, 
    address fallback_,
    uint flags
  ) initializer public {
    _anyCallProxy = anyCallProxy;
    _owner = msg.sender;
    _anyCallDst = anyCallDst;
    _chainIdDst = chainIdDst;
    _fallback  = fallback_;
    _flags = flags;
  }

  function step1_initiateAnyCallSimple(string calldata message) external {
    emit NewMsg(message);
    if (msg.sender == _owner){
      CallProxy(_anyCallProxy).anyCall(
        _anyCallDst,
        abi.encode(message),
        address(_fallback),
        _chainIdDst,
        _flags
      );        
    }
  }
}