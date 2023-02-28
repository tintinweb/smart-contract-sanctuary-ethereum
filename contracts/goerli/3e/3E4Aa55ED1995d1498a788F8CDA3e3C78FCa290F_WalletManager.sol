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

// wallet manager that has to be deployed once to store the addressess of the smart wallets deployed by every user

import "@opengsn/contracts/src/ERC2771Recipient.sol";

contract WalletManager is ERC2771Recipient {
    /// @notice Mapping of EOA address to the wallets it deployed.
    mapping(address => address[]) internal _eoas;

    /// @notice Constructor that determines owner and forwarder address for GSN usage.
    /// @dev GSN is a network of relay servers to make gasless transactions.
    /// @custom:bigchange For relayed calls, _msgSender() not msg.sender has to be be used.
    constructor(address forwarder) {
        _setTrustedForwarder(forwarder);
    }

    /// @notice Function to add a wallet to a walletOwner.
    /// @param walletOwner is the owner address of the wallet.
    /// @param newWallet is the wallet address deployed.
    function addWallet(address walletOwner, address newWallet) public {
        _eoas[walletOwner].push(newWallet);
    }

    /// @notice deletes the wallet in the mapping.
    /// @param lastOwner is the owner stated on the _eoas mapping of the wallet.
    /// @param index is the index in the _eoas mapping in which the walletAddress is stored.
    function deleteAddress(
        address walletAddress,
        address lastOwner,
        uint8 index
    ) public {
        require(_eoas[lastOwner][index] == walletAddress, "Wallet not in index or owner");
        delete _eoas[lastOwner][index];
    }

    function checkWalletAddress(address walletOwner, uint8 index) public view returns (address) {
        return _eoas[walletOwner][index];
    }

    function amountOfWallets(address walletOwner) public view returns (uint256) {
        return _eoas[walletOwner].length;
    }
}