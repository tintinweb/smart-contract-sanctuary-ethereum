/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// File: @opengsn/contracts/src/interfaces/IERC2771Recipient.sol


pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}

// File: @opengsn/contracts/src/ERC2771Recipient.sol


// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;


/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// File: contracts/SignIn.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


// ----------------------------------------------------------------------------
// Ownable Contract
// ----------------------------------------------------------------------------
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  
  // The Ownable constructor sets the original `owner` of the contract to the sender account
  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // Allows the current owner to transfer control of the contract to a newOwner.
  // @param newOwner The address to transfer ownership to.
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


contract SignInContract is Ownable, ERC2771Recipient {
    mapping(address => uint) roster;
  
    event UserRecordChanged(address indexed owner, uint256 numbers);


     constructor(address _trustedForwarder) {
        _setTrustedForwarder(_trustedForwarder);
    }


    function setTrustedForwarder(address _trustedForwarder) public onlyOwner {
        _setTrustedForwarder(_trustedForwarder);
    }


    // function setTrustedForwarder(address _trustedForwarder) public onlyOwner {
    //     trustedForwarder = _trustedForwarder;
    // }
    
    /** 
     * Override this function.
     * This version is to keep track of BaseRelayRecipient you are using
     * in your contract. 
     */
    function getUserRecord(address user) public view returns (uint num) {
        return roster[user];
    }

    function setUserRecord(address user, uint num) public onlyOwner {
        roster[user] = num;
        emit UserRecordChanged(user,num);
    }

    function userSignIn() public {
        roster[_msgSender()]++;
    }

    function getMyRecord() public view returns (uint num) {
        return roster[_msgSender()];
    }
}