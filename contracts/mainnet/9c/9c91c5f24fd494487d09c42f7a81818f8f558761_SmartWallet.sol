// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;
import './TransferHelper.sol';
import './ERC20Interface.sol';
import './IForwarder.sol';

/** ERC721, ERC1155 imports */
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol';

/**
 *
 * SmartWallet
 * ============
 *
 * Basic multi-signer wallet designed for use in a co-signing environment where 2 signatures are required to move funds.
 * Typically used in a 2-of-3 signing configuration. Uses ecrecover to allow for 2 signatures in a single transaction.
 *
 * The first signature is created on the operation hash (see Data Formats) and passed to sendMultiSig/sendMultiSigToken
 * The signer is determined by verifyMultiSig().
 *
 * The second signature is created by the submitter of the transaction and determined by msg.signer.
 *
 * Data Formats
 * ============
 *
 * The signature is created with ethereumjs-util.ecsign(operationHash).
 * Like the eth_sign RPC call, it packs the values as a 65-byte array of [r, s, v].
 * Unlike eth_sign, the message is not prefixed.
 *
 * The operationHash the result of keccak256(prefix, toAddress, value, data, expireTime).
 * For ether transactions, `prefix` is "ETHER".
 * For token transaction, `prefix` is "ERC20" and `data` is the tokenContractAddress.
 *
 *
 */
contract SmartWallet is IERC721Receiver, ERC1155Receiver {
    // Events
    event Deposited(address from, uint256 value, bytes data);
    event SafeModeActivated(address msgSender);
    event SafeModeDeActivated(address msgSender);
    event Transacted(
        address msgSender, // Address of the sender of the message initiating the transaction
        address otherSigner, // Address of the signer (second signature) used to initiate the transaction
        bytes32 operation, // Operation hash (see Data Formats)
        address toAddress, // The address the transaction was sent to
        uint256 value, // Amount of Wei sent to the address
        bytes data // Data sent when invoking the transaction
    );

    event BatchTransfer(address sender, address recipient, uint256 value);
    // this event shows the other signer and the operation hash that they signed
    // specific batch transfer events are emitted in Batcher
    event BatchTransacted(
        address msgSender, // Address of the sender of the message initiating the transaction
        address otherSigner, // Address of the signer (second signature) used to initiate the transaction
        bytes32 operation // Operation hash (see Data Formats)
    );

    // Public fields
    mapping(address => bool) public signers; // The addresses that can co-sign transactions on the wallet
    bool public safeMode = false; // When active, wallet may only send to signer addresses
    bool public initialized = false; // True if the contract has been initialized

    // Internal fields
    uint256 private constant MAX_SEQUENCE_ID_INCREASE = 10000;
    uint256 constant SEQUENCE_ID_WINDOW_SIZE = 10;
    uint256[SEQUENCE_ID_WINDOW_SIZE] recentSequenceIds;

    /**
     * Set up a simple multi-sig wallet by specifying the signers allowed to be used on this wallet.
     * 2 signers will be required to send a transaction from this wallet.
     * Note: The sender is NOT automatically added to the list of signers.
     * Signers CANNOT be changed once they are set
     *
     * @param allowedSigners An array of signers on the wallet
     */
    function init(address[] calldata allowedSigners)
        external
        onlyUninitialized
    {
        require(allowedSigners.length == 3, 'Invalid number of signers');

        for (uint8 i = 0; i < allowedSigners.length; i++) {
            require(allowedSigners[i] != address(0), 'Invalid signer');
            signers[allowedSigners[i]] = true;
        }

        initialized = true;
    }

    /**
     * Get the network identifier that signers must sign over
     * This provides protection signatures being replayed on other chains
     * This must be a virtual function because chain-specific contracts will need
     *    to override with their own network ids. It also can't be a field
     *    to allow this contract to be used by proxy with delegatecall, which will
     *    not pick up on state variables
     */
    function getNetworkId() internal pure virtual returns (string memory) {
        return 'ETHER';
    }

    /**
     * Get the network identifier that signers must sign over for token transfers
     * This provides protection signatures being replayed on other chains
     * This must be a virtual function because chain-specific contracts will need
     *    to override with their own network ids. It also can't be a field
     *    to allow this contract to be used by proxy with delegatecall, which will
     *    not pick up on state variables
     */
    function getTokenNetworkId() internal pure virtual returns (string memory) {
        return 'ERC20';
    }

    /**
     * Get the network identifier that signers must sign over for batch transfers
     * This provides protection signatures being replayed on other chains
     * This must be a virtual function because chain-specific contracts will need
     *    to override with their own network ids. It also can't be a field
     *    to allow this contract to be used by proxy with delegatecall, which will
     *    not pick up on state variables
     */
    function getBatchNetworkId() internal pure virtual returns (string memory) {
        return 'ETHER-Batch';
    }

    /**
     * Determine if an address is a signer on this wallet
     * @param signer address to check
     * returns boolean indicating whether address is signer or not
     */
    function isSigner(address signer) public view returns (bool) {
        return signers[signer];
    }

    /**
     * Modifier that will execute internal code block only if the sender is an authorized signer on this wallet
     */
    modifier onlySigner() {
        require(isSigner(msg.sender), 'Non-signer in onlySigner method');
        _;
    }

    /**
     * Modifier that will execute internal code block only if the contract has not been initialized yet
     */
    modifier onlyUninitialized() {
        require(!initialized, 'Contract already initialized');
        _;
    }

    /**
     * Gets called when a transaction is received with data that does not match any other method
     */
    fallback() external payable {
        if (msg.value > 0) {
            // Fire deposited event if we are receiving funds
            emit Deposited(msg.sender, msg.value, msg.data);
        }
    }

    /**
     * Gets called when a transaction is received with ether and no data
     */
    receive() external payable {
        if (msg.value > 0) {
            // Fire deposited event if we are receiving funds
            // message data is always empty for receive. If there is data it is sent to fallback function.
            emit Deposited(msg.sender, msg.value, '');
        }
    }

    /**
     * Execute a multi-signature transaction from this wallet using 2 signers: one from msg.sender and the other from ecrecover.
     * Sequence IDs are numbers starting from 1. They are used to prevent replay attacks and may not be repeated.
     *
     * @param toAddress the destination address to send an outgoing transaction
     * @param value the amount in Wei to be sent
     * @param data the data to send to the toAddress when invoking the transaction
     * @param expireTime the number of seconds since 1970 for which this transaction is valid
     * @param sequenceId the unique sequence id obtainable from getNextSequenceId
     * @param signature see Data Formats
     */
    function sendMultiSig(
        address toAddress,
        uint256 value,
        bytes calldata data,
        uint256 expireTime,
        uint256 sequenceId,
        bytes calldata signature
    ) external onlySigner {
        // Verify the other signer
        bytes32 operationHash = keccak256(
            abi.encodePacked(
                getNetworkId(),
                toAddress,
                value,
                data,
                expireTime,
                sequenceId
            )
        );

        address otherSigner = verifyMultiSig(
            toAddress,
            operationHash,
            signature,
            expireTime,
            sequenceId
        );

        // Success, send the transaction
        (bool success, ) = toAddress.call{value: value}(data);
        require(success, 'Call execution failed');

        emit Transacted(
            msg.sender,
            otherSigner,
            operationHash,
            toAddress,
            value,
            data
        );
    }

    /**
     * Execute a batched multi-signature transaction from this wallet using 2 signers: one from msg.sender and the other from ecrecover.
     * Sequence IDs are numbers starting from 1. They are used to prevent replay attacks and may not be repeated.
     * The recipients and values to send are encoded in two arrays, where for index i, recipients[i] will be sent values[i].
     *
     * @param recipients The list of recipients to send to
     * @param values The list of values to send to
     * @param expireTime the number of seconds since 1970 for which this transaction is valid
     * @param sequenceId the unique sequence id obtainable from getNextSequenceId
     * @param signature see Data Formats
     */
    function sendMultiSigBatch(
        address[] calldata recipients,
        uint256[] calldata values,
        uint256 expireTime,
        uint256 sequenceId,
        bytes calldata signature
    ) external onlySigner {
        require(recipients.length != 0, 'Not enough recipients');
        require(
            recipients.length == values.length,
            'Unequal recipients and values'
        );
        require(recipients.length < 256, 'Too many recipients, max 255');

        // Verify the other signer
        bytes32 operationHash = keccak256(
            abi.encodePacked(
                getBatchNetworkId(),
                recipients,
                values,
                expireTime,
                sequenceId
            )
        );

        // the first parameter (toAddress) is used to ensure transactions in safe mode only go to a signer
        // if in safe mode, we should use normal sendMultiSig to recover, so this check will always fail if in safe mode
        require(!safeMode, 'Batch in safe mode');
        address otherSigner = verifyMultiSig(
            address(0x0),
            operationHash,
            signature,
            expireTime,
            sequenceId
        );

        batchTransfer(recipients, values);
        emit BatchTransacted(msg.sender, otherSigner, operationHash);
    }

    /**
     * Transfer funds in a batch to each of recipients
     * @param recipients The list of recipients to send to
     * @param values The list of values to send to recipients.
     *  The recipient with index i in recipients array will be sent values[i].
     *  Thus, recipients and values must be the same length
     */
    function batchTransfer(
        address[] calldata recipients,
        uint256[] calldata values
    ) internal {
        for (uint256 i = 0; i < recipients.length; i++) {
            require(address(this).balance >= values[i], 'Insufficient funds');

            (bool success, ) = recipients[i].call{value: values[i]}('');
            require(success, 'Call failed');

            emit BatchTransfer(msg.sender, recipients[i], values[i]);
        }
    }

    /**
     * Execute a multi-signature token transfer from this wallet using 2 signers: one from msg.sender and the other from ecrecover.
     * Sequence IDs are numbers starting from 1. They are used to prevent replay attacks and may not be repeated.
     *
     * @param toAddress the destination address to send an outgoing transaction
     * @param value the amount in tokens to be sent
     * @param tokenContractAddress the address of the erc20 token contract
     * @param expireTime the number of seconds since 1970 for which this transaction is valid
     * @param sequenceId the unique sequence id obtainable from getNextSequenceId
     * @param signature see Data Formats
     */
    function sendMultiSigToken(
        address toAddress,
        uint256 value,
        address tokenContractAddress,
        uint256 expireTime,
        uint256 sequenceId,
        bytes calldata signature
    ) external onlySigner {
        // Verify the other signer
        bytes32 operationHash = keccak256(
            abi.encodePacked(
                getTokenNetworkId(),
                toAddress,
                value,
                tokenContractAddress,
                expireTime,
                sequenceId
            )
        );

        verifyMultiSig(
            toAddress,
            operationHash,
            signature,
            expireTime,
            sequenceId
        );

        TransferHelper.safeTransfer(tokenContractAddress, toAddress, value);
    }

    /**
     * Execute a token flush from one of the forwarder addresses. This transfer needs only a single signature and can be done by any signer
     *
     * @param forwarderAddress the address of the forwarder address to flush the tokens from
     * @param tokenContractAddress the address of the erc20 token contract
     */
    function flushForwarderTokens(
        address payable forwarderAddress,
        address tokenContractAddress
    ) external onlySigner {
        ERC20Interface instance = ERC20Interface(tokenContractAddress);
        uint256 forwarderBalance = instance.balanceOf(forwarderAddress);
        if (forwarderBalance == 0) {
            return;
        }
        IForwarder forwarder = IForwarder(forwarderAddress);
        forwarder.flushTokens(tokenContractAddress);
    }

    /**
     * Execute a ERC721 token flush from one of the forwarder addresses. This transfer needs only a single signature and can be done by any signer
     *
     * @param forwarderAddress the address of the forwarder address to flush the tokens from
     * @param tokenContractAddress the address of the erc20 token contract
     */
    function flushERC721ForwarderTokens(
        address payable forwarderAddress,
        address tokenContractAddress,
        uint256 tokenId
    ) external onlySigner {
        IForwarder forwarder = IForwarder(forwarderAddress);
        forwarder.flushERC721Token(tokenContractAddress, tokenId);
    }

    /**
     * Execute a ERC1155 batch token flush from one of the forwarder addresses.
     * This transfer needs only a single signature and can be done by any signer.
     *
     * @param forwarderAddress the address of the forwarder address to flush the tokens from
     * @param tokenContractAddress the address of the erc1155 token contract
     */
    function batchFlushERC1155ForwarderTokens(
        address payable forwarderAddress,
        address tokenContractAddress,
        uint256[] calldata tokenIds
    ) external onlySigner {
        IForwarder forwarder = IForwarder(forwarderAddress);
        forwarder.batchFlushERC1155Tokens(tokenContractAddress, tokenIds);
    }

    /**
     * Execute a ERC1155 token flush from one of the forwarder addresses.
     * This transfer needs only a single signature and can be done by any signer.
     *
     * @param forwarderAddress the address of the forwarder address to flush the tokens from
     * @param tokenContractAddress the address of the erc1155 token contract
     * @param tokenId the token id associated with the ERC1155
     */
    function flushERC1155ForwarderTokens(
        address payable forwarderAddress,
        address tokenContractAddress,
        uint256 tokenId
    ) external onlySigner {
        IForwarder forwarder = IForwarder(forwarderAddress);
        forwarder.flushERC1155Tokens(tokenContractAddress, tokenId);
    }

    /**
     * Sets the autoflush 721 parameter on the forwarder.
     *
     * @param forwarderAddress the address of the forwarder to toggle.
     * @param autoFlush whether to autoflush erc721 tokens
     */
    function setAutoFlush721(address forwarderAddress, bool autoFlush)
        external
        onlySigner
    {
        IForwarder forwarder = IForwarder(forwarderAddress);
        forwarder.setAutoFlush721(autoFlush);
    }

    /**
     * Sets the autoflush 721 parameter on the forwarder.
     *
     * @param forwarderAddress the address of the forwarder to toggle.
     * @param autoFlush whether to autoflush erc1155 tokens
     */
    function setAutoFlush1155(address forwarderAddress, bool autoFlush)
        external
        onlySigner
    {
        IForwarder forwarder = IForwarder(forwarderAddress);
        forwarder.setAutoFlush1155(autoFlush);
    }

    /**
     * Do common multisig verification for both eth sends and erc20token transfers
     *
     * @param toAddress the destination address to send an outgoing transaction
     * @param operationHash see Data Formats
     * @param signature see Data Formats
     * @param expireTime the number of seconds since 1970 for which this transaction is valid
     * @param sequenceId the unique sequence id obtainable from getNextSequenceId
     * returns address that has created the signature
     */
    function verifyMultiSig(
        address toAddress,
        bytes32 operationHash,
        bytes calldata signature,
        uint256 expireTime,
        uint256 sequenceId
    ) private returns (address) {
        address otherSigner = recoverAddressFromSignature(
            operationHash,
            signature
        );

        // Verify if we are in safe mode. In safe mode, the wallet can only send to signers
        require(
            !safeMode || isSigner(toAddress),
            'External transfer in safe mode'
        );

        // Verify that the transaction has not expired
        require(expireTime >= block.timestamp, 'Transaction expired');

        // Try to insert the sequence ID. Will revert if the sequence id was invalid
        tryInsertSequenceId(sequenceId);

        require(isSigner(otherSigner), 'Invalid signer');

        require(otherSigner != msg.sender, 'Signers cannot be equal');

        return otherSigner;
    }

    /**
     * ERC721 standard callback function for when a ERC721 is transfered.
     *
     * @param _operator The address of the nft contract
     * @param _from The address of the sender
     * @param _tokenId The token id of the nft
     * @param _data Additional data with no specified format, sent in call to `_to`
     */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @inheritdoc IERC1155Receiver
     */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @inheritdoc IERC1155Receiver
     */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * Irrevocably puts contract into safe mode. When in this mode, transactions may only be sent to signing addresses.
     */
    function activateSafeMode() external onlySigner {
        require(bool(safeMode) == false, 'safeMode already activated');
        safeMode = true;
        emit SafeModeActivated(msg.sender);
    }

    /**
     * deactivate safe-mode, transactions can be sent to any addresses.
     */
    function deactivateSafeMode() external onlySigner {
        require(bool(safeMode) == true, 'safeMode is not activated');
        safeMode = false;
        emit SafeModeDeActivated(msg.sender);
    }

    /**
     * Gets signer's address using ecrecover
     * @param operationHash see Data Formats
     * @param signature see Data Formats
     * returns address recovered from the signature
     */
    function recoverAddressFromSignature(
        bytes32 operationHash,
        bytes memory signature
    ) private pure returns (address) {
        require(signature.length == 65, 'Invalid signature - wrong length');

        // We need to unpack the signature, which is given as an array of 65 bytes (like eth.sign)
        bytes32 r;
        bytes32 s;
        uint8 v;

        // solhint-disable-next-line
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }
        if (v < 27) {
            v += 27; // Ethereum versions are 27 or 28 as opposed to 0 or 1 which is submitted by some signing libs
        }

        // protect against signature malleability
        // S value must be in the lower half orader
        // reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/051d340171a93a3d401aaaea46b4b62fa81e5d7c/contracts/cryptography/ECDSA.sol#L53
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );

        // note that this returns 0 if the signature is invalid
        // Since 0x0 can never be a signer, when the recovered signer address
        // is checked against our signer list, that 0x0 will cause an invalid signer failure
        return ecrecover(operationHash, v, r, s);
    }

    /**
     * Verify that the sequence id has not been used before and inserts it. Throws if the sequence ID was not accepted.
     * We collect a window of up to 10 recent sequence ids, and allow any sequence id that is not in the window and
     * greater than the minimum element in the window.
     * @param sequenceId to insert into array of stored ids
     */
    function tryInsertSequenceId(uint256 sequenceId) private onlySigner {
        // Keep a pointer to the lowest value element in the window
        uint256 lowestValueIndex = 0;
        // fetch recentSequenceIds into memory for function context to avoid unnecessary sloads

        uint256[SEQUENCE_ID_WINDOW_SIZE]
            memory _recentSequenceIds = recentSequenceIds;
        for (uint256 i = 0; i < SEQUENCE_ID_WINDOW_SIZE; i++) {
            require(
                _recentSequenceIds[i] != sequenceId,
                'Sequence ID already used'
            );

            if (_recentSequenceIds[i] < _recentSequenceIds[lowestValueIndex]) {
                lowestValueIndex = i;
            }
        }

        // The sequence ID being used is lower than the lowest value in the window
        // so we cannot accept it as it may have been used before
        require(
            sequenceId > _recentSequenceIds[lowestValueIndex],
            'Sequence ID below window'
        );

        // Block sequence IDs which are much higher than the lowest value
        // This prevents people blocking the contract by using very large sequence IDs quickly
        require(
            sequenceId <=
                (_recentSequenceIds[lowestValueIndex] +
                    MAX_SEQUENCE_ID_INCREASE),
            'Sequence ID above maximum'
        );

        recentSequenceIds[lowestValueIndex] = sequenceId;
    }

    /**
     * Gets the next available sequence ID for signing when using executeAndConfirm
     * returns the sequenceId one higher than the highest currently stored
     */
    function getNextSequenceId() external view returns (uint256) {
        uint256 highestSequenceId = 0;
        for (uint256 i = 0; i < SEQUENCE_ID_WINDOW_SIZE; i++) {
            if (recentSequenceIds[i] > highestSequenceId) {
                highestSequenceId = recentSequenceIds[i];
            }
        }
        return highestSequenceId + 1;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// source: https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/TransferHelper.sol
pragma solidity 0.8.17;

import '@openzeppelin/contracts/utils/Address.sol';

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory returndata) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        Address.verifyCallResult(
            success,
            returndata,
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * Contract that exposes the needed erc20 token functions
 */

abstract contract ERC20Interface {
    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value)
        public
        virtual
        returns (bool success);

    // Get the account balance of another account with address _owner
    function balanceOf(address _owner)
        public
        view
        virtual
        returns (uint256 balance);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface IForwarder is IERC165 {
    /**
     * Sets the autoflush721 parameter.
     *
     * @param autoFlush whether to autoflush erc721 tokens
     */
    function setAutoFlush721(bool autoFlush) external;

    /**
     * Sets the autoflush1155 parameter.
     *
     * @param autoFlush whether to autoflush erc1155 tokens
     */
    function setAutoFlush1155(bool autoFlush) external;

    /**
     * Execute a token transfer of the full balance from the forwarder token to the parent address
     *
     * @param tokenContractAddress the address of the erc20 token contract
     */
    function flushTokens(address tokenContractAddress) external;

    /**
     * Execute a nft transfer from the forwarder to the parent address
     *
     * @param tokenContractAddress the address of the ERC721 NFT contract
     * @param tokenId The token id of the nft
     */
    function flushERC721Token(address tokenContractAddress, uint256 tokenId)
        external;

    /**
     * Execute a nft transfer from the forwarder to the parent address.
     *
     * @param tokenContractAddress the address of the ERC1155 NFT contract
     * @param tokenId The token id of the nft
     */
    function flushERC1155Tokens(address tokenContractAddress, uint256 tokenId)
        external;

    /**
     * Execute a batch nft transfer from the forwarder to the parent address.
     *
     * @param tokenContractAddress the address of the ERC1155 NFT contract
     * @param tokenIds The token ids of the nfts
     */
    function batchFlushERC1155Tokens(
        address tokenContractAddress,
        uint256[] calldata tokenIds
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}