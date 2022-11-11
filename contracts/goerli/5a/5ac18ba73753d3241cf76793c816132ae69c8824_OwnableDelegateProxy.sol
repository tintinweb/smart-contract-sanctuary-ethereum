/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Ownable {
  address public owner;
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor()  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

interface  ERC20  {

  event Transfer(address indexed from, address indexed to, uint256 value);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  //function approve(address spender, uint256 value) external returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract TokenRecipient  {
    event ReceivedEther(address indexed sender, uint amount);
    event ReceivedTokens(address indexed from, uint256 value, address indexed token, bytes extraData);

    /**
     * @dev Receive tokens and generate a log event
     * @param from Address from which to transfer tokens
     * @param value Amount of tokens to transfer
     * @param token Address of token
     * @param extraData Additional data to log
     */
    function receiveApproval(address from, uint256 value, address token, bytes memory extraData) public {
        ERC20 t = ERC20(token);
        require(t.transferFrom(from, address(this), value));
        emit ReceivedTokens(from, value, token, extraData);
    }

    /**
     * @dev Receive Ether and generate a log event
     */
    fallback() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }

    receive() external payable {
        // custom function code
    }
}


contract OwnedUpgradeabilityStorage {

  address internal _cimplementation;

  // Owner of the contract
  address private _upgradeabilityOwner;

  /**
   * @dev Tells the address of the owner
   * @return the address of the owner
   */
  function upgradeabilityOwner() public view returns (address) {
    return _upgradeabilityOwner;
  }

  /**
   * @dev Sets the address of the owner
   */
  function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
    _upgradeabilityOwner = newUpgradeabilityOwner;
  }

  function implementation() public view returns (address) {
    return _cimplementation;
  }

  function proxyType() public pure returns (uint256 proxyTypeId) {
    uint256 two = 2;
    return two;
  }
}

contract OwnedUpgradeabilityProxy is  OwnedUpgradeabilityStorage {

  event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    fallback() external payable {   
    address _impl = implementation();
    require(_impl != address(0));

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize())
      let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
      let size := returndatasize()
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }

    receive() external payable {
        // custom function code
    }


  event Upgraded(address ximplementation);


  function _upgradeTo(address ximplementation) internal {
    require(_cimplementation != ximplementation);
    _cimplementation = ximplementation;
    emit Upgraded(ximplementation);
  }


  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner());
    _;
  }

  function proxyOwner() public view returns (address) {
    return upgradeabilityOwner();
  }

  function transferProxyOwnership(address newOwner) public onlyProxyOwner {
    require(newOwner != address(0));
    emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
    setUpgradeabilityOwner(newOwner);
  }


  function upgradeTo(address ximplementation) public onlyProxyOwner {
    _upgradeTo(ximplementation);
  }


  function upgradeToAndCall(address ximplementation, bytes memory data) payable public onlyProxyOwner {
    upgradeTo(ximplementation);
    (bool flag, ) = address(this).delegatecall(data);
    require(flag);
  }
  
}

contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {

    constructor(address owner, address initialImplementation, bytes memory _calldata)
    {
        setUpgradeabilityOwner(owner);
        _upgradeTo(initialImplementation);
        (bool flag, ) = initialImplementation.delegatecall(_calldata);
        require(flag);
    }

}