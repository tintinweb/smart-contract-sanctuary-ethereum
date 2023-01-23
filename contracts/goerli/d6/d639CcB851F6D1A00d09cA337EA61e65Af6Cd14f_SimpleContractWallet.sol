// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IERC2771Recipient.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@opengsn/contracts/src/ERC2771Recipient.sol";


error Credit__TransferFailed();

contract SimpleContractWallet is ERC2771Recipient{
//It is an ABSOLUTE NEED to declare the tx and important funtions ass only usable for the contract owner. See Argent method ass example https://github.com/argentlabs/argent-contracts/blob/develop/contracts/modules/TransactionManager.sol
    
    // This HAS to be eliminated in the future, it now used to identify if theGSN integration is working correctlly
    address public lastCaller;

    // Events
    event SessionStarted(address addressTo, uint256 timeOfSession,uint256 creditInCard);
    event TransferMade(address transferTo, uint256 amountTransfered);
    event ClearedSession(address dapp);
    // Contructor
    // Initialize trusted forwarder
    constructor(address forwarder_) 
    {
    _setTrustedForwarder(forwarder_);
  }

    struct creditSession {
            uint256 time; // the dapp address
            uint256 cap;  // the cap chosen 
        }
    
    // Maps wallet to session
    mapping (address => creditSession) internal creditSessions;

    function startCreditSession(address _dapp, uint256 _time,uint256 _cap)  public {
        require(_time  > 0 , "not approved time");
        require(_cap > 0 , "not approved cap");
        creditSessions[_dapp] = creditSession(_time + block.timestamp, _cap );
        lastCaller = _msgSender();
        emit SessionStarted(_dapp,_time,_cap);
    }

    function stopCreditSession(address _dapp) public {
        require(creditSessions[_dapp].cap >0, "No credit session registered for that address");
        delete creditSessions[_dapp];
    }

    receive() external payable {}

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function fund() public payable{
        // function to fund from another address, mainly can be used to transfer from the owners EOA address
    }

    // this part has to change to the meta tranasction method with a relayer
    function transaction(address payable _dapp, uint256 _value) public {
        if (creditSessions[_dapp].cap > 0 ){
            require(block.timestamp < creditSessions[_dapp].time, "session ended" );
            require(creditSessions[_dapp].cap >= _value, "cap not enough");
            (bool success, ) = _dapp.call{value: _value}("");
            if (!success) {
            revert Credit__TransferFailed();
            }
            creditSessions[_dapp].cap = creditSessions[_dapp].cap - _value;
        } else {
        (bool success, ) = _dapp.call{value: _value}("");
        if (!success) {
        revert Credit__TransferFailed();
        }}
        lastCaller = _msgSender();
        emit TransferMade(_dapp,_value);
    }

    // Taken from argent to delete a session created
    function _clearSession(address _dapp) public {
        delete creditSessions[_dapp];
        emit ClearedSession(_dapp);
    }

    // View funtions
    

    function stablishedCap(address _dapp) public view returns(uint256){
        return creditSessions[_dapp].cap;
    }

    function stablishedTime(address _dapp) public view returns(uint256){
        return creditSessions[_dapp].time;
    }

    function timeLeftSession(address _dapp) public view returns(uint256){
        return creditSessions[_dapp].time - block.timestamp;
    }

    function isSmartWallet() public view returns(bool) {
    bool isASmartWallet = true;
    return isASmartWallet;
    }

    // string public override versionRecipient = "2.2.0"; According to https://docs.opengsn.org/faq/troubleshooting.html#my-contract-is-using-openzeppelin-how-do-i-add-gsn-support

}