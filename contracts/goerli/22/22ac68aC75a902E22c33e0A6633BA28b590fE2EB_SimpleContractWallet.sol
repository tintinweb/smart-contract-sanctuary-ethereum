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

error CreditTransferFailed();

/// @title A smart contract wallet.
/// @author Vicente Munoz @ Invisible Lab.
/// @notice Not ready for mainnet use.
/// @dev Optimization needed for cheaper deployment.
contract SimpleContractWallet is ERC2771Recipient {
    /// @notice Data stored for each session created.
    struct CreditSession {
        uint256 time;
        uint256 cap;
    }

    address private _owner;
    /// @notice Signatures needed and done by the guardians to make a owner change.
    uint8 private _signaturesNeeded = 0;
    uint8 private _signaturesDone = 0;

    /// @notice Mapping guardians created by wallet owner to its level.
    /// @dev Level 1 guardians can change owner with no signatures, level 2 or above need to first sign in signOwnerChange().
    mapping(address => uint8) public guardianLevel;

    // Maps wallet to session
    mapping(address => CreditSession) private _creditSessions;

    /// @notice mapps credit address to credit in wei.
    mapping(address => uint256) public creditCards;

    // Events
    event SessionStarted(address addressTo, uint256 timeOfSession, uint256 creditInCard);
    event TransferMade(address transferTo, uint256 amountTransfered);
    event ClearedSession(address dapp);
    event GuardianCreated(address guardian, uint8 level);
    event OwnerChanged(address newOwner);
    event OwnerChangeSigning(address guardianSigned);
    event CreditCardCreated(address creditCardAddress, uint256 initialCredit);
    event Received(address, uint256);

    /// @notice Modifier for only owner application on functions.
    /// @dev _msgSender is used because of GSN relay and forwarder integration.
    modifier onlyOwner() {
        require(_msgSender() == _owner, "Not owner");
        _;
    }

    /// @notice Modifier for only guardian can call function.
    modifier onlyGuardian() {
        require(guardianLevel[msg.sender] > 0, "Not a guardian");
        _;
    }

    /// @notice Constructor that determines owner and forwarder address for GSN usage. GSN is a network of relay servers to make gasless transactions.
    /// @custom:bigchange For relayed calls, _msgSender() not msg.sender has to be be used.
    /// @param owner Defines the owner of the wallet.
    /// @param forwarder Set the trusted forwarder for GSN requests.
    constructor(address owner, address forwarder) {
        require(owner != address(0), "SCW: invalid owner address");
        require(forwarder != address(0), "SCW: invalid forwarder address");
        _owner = owner;
        _setTrustedForwarder(forwarder);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /// @notice Call another smart contract function or make raw transaction. https://docs.soliditylang.org/en/v0.8.17/types.html#members-of-addresses
    /// @dev _msgSender is used and not msg.sender because its a function that should be realyed if called.
    /// @param data should be the hash of the transaction.
    /// @return Returns data of transaction.
    function callAnotherContract(address to, bytes memory data) external returns (bytes memory) {
        require(to != address(0), "SCW: invalid address");
        require(_msgSender() == _owner, "Only owner can call function");
        (bool success, bytes memory returnData) = to.call(data);
        require(success, "SCW: call must be successful");
        return (returnData);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Function callable by owner to create guardians for wallet recovery.
    /// @dev Level 1 guardian can change owner with no signatures needed. Level 2 or above need for every guardian to sign to be able to change owner. _msgSender is used and not msg.sender because its a function that should be realyed if called.
    /// @param guardian is the address of the guardian.
    function createGuardian(address guardian, uint8 level) public onlyOwner {
        require(level > 0, "Level must be > 0");
        guardianLevel[guardian] = level;
        _signaturesNeeded += 1;
        emit GuardianCreated(guardian, level);
    }

    /// @notice Function to sign owner change, only callable by guardians. Does a double check if address is guardian (TODO: is it necesary?)
    /// @dev msg.sender is used because the signatures are made by the guardians, they can be normal EOA wallets or smart wallets.
    function signOwnerChange() public onlyGuardian {
        _signaturesDone += 1;
        emit OwnerChangeSigning(msg.sender);
    }

    /// @notice Owner change function that can only be made by a guardian. TODO: add a time to activate change for possible bad actors usage.
    /// @dev It can only change owner if all signatures are made or caller is guardian level 1.
    /// @dev msg.sender is used because the signatures are made by the guardians, they can be normal EOA wallets or smart wallets
    function changeOwner(address newOwner) public onlyGuardian {
        require(newOwner != address(0), "SCW: invalid address");
        if (guardianLevel[msg.sender] > 1) {
            require(_signaturesDone >= _signaturesNeeded, "Not enough signatures done");
        }
        _owner = newOwner;
        _signaturesDone = 0;
        emit OwnerChanged(newOwner);
    }

    /// @notice Creation of session to limit transfers to specific dapp.
    /// @dev The idea is to perfect this function or replace with EOA credit wallets creation.  _msgSender is used and not msg.sender because its a function that should be realyed if called.
    /// @param dapp is the EOA or smart contract address of the dapp or user that the owner wants to create a session for.
    /// @param time is the total time in which the session is active
    /// @param cap is the budget allocated to the session.
    function startCreditSession(
        address dapp,
        uint256 time,
        uint256 cap
    ) public onlyOwner {
        require(time > 0, "not approved time");
        require(cap > 0, "not approved cap");
        _creditSessions[dapp] = CreditSession(time + block.timestamp, cap);
        emit SessionStarted(dapp, time, cap);
    }

    /// @notice Stops the session if active.
    function stopCreditSession(address dapp) public onlyOwner {
        require(_creditSessions[dapp].cap > 0, "No credit session registered");
        delete _creditSessions[dapp];
        emit ClearedSession(dapp);
    }

    /// @notice Function to create smart credit card.
    /// @dev This would be the alternative to startCreditSession. This one should be used on WC request logic.  _msgSender is used and not msg.sender because its a function that should be realyed if called.
    /// @param card is the address of the EOA created, should be an empty account.
    /// @param credit is the credit allocated to the card.
    function createCreditCard(address card, uint256 credit) public onlyOwner {
        require(credit > 0, "Not possible credit");
        creditCards[card] = credit;
        emit CreditCardCreated(card, credit);
    }

    /// @notice Empties the smart credit card allocated credit.
    /// @dev _msgSender is used and not msg.sender because its a function that should be realyed if called.
    function endCreditCard(address card) public onlyOwner {
        require(creditCards[card] > 0, "Credit already 0");
        creditCards[card] = 0;
    }

    /// @notice Basic transfer of funds to another address.
    /// @dev _msgSender is used and not msg.sender because its a function that should be realyed if called.
    /// @param dapp Address of contract or EOA the transaction is made to.
    /// @param value Amount of eth in wei.
    function transaction(address payable dapp, uint256 value) public onlyOwner {
        bool success = false;
        emit TransferMade(dapp, value);
        if (_creditSessions[dapp].cap > 0 && _creditSessions[dapp].time > 0) {
            require(block.timestamp < _creditSessions[dapp].time, "session ended");
            require(_creditSessions[dapp].cap >= value, "cap not enough");
            _creditSessions[dapp].cap = _creditSessions[dapp].cap - value;
            (success, ) = dapp.call{value: value}("");
            if (!success) {
                revert CreditTransferFailed();
            }
        } else {
            (success, ) = dapp.call{value: value}("");
            if (!success) {
                revert CreditTransferFailed();
            }
        }
    }

    function viewOwner() public view returns (address) {
        return (_owner);
    }

    function stablishedCap(address dapp) public view returns (uint256) {
        return _creditSessions[dapp].cap;
    }

    function stablishedTime(address dapp) public view returns (uint256) {
        return _creditSessions[dapp].time;
    }

    function timeLeftSession(address dapp) public view returns (uint256) {
        return _creditSessions[dapp].time - block.timestamp;
    }

    function signaturesNeeded() public view returns (uint8) {
        return _signaturesNeeded;
    }

    function signaturesDone() public view returns (uint8) {
        return _signaturesDone;
    }

    // string public override versionRecipient = "2.2.0"; According to https://docs.opengsn.org/faq/troubleshooting.html#my-contract-is-using-openzeppelin-how-do-i-add-gsn-support
}