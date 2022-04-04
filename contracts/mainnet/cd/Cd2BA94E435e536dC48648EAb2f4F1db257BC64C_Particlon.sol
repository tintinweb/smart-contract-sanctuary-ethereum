/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: MIT
// If you think you may have found a vulnerability
// File: @opengsn/contracts/src/interfaces/IRelayRecipient.sol


pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}

// File: @opengsn/contracts/src/BaseRelayRecipient.sol


// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;


/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
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

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// File: contracts/lib/RelayRecipient.sol



pragma solidity ^0.8.0;

// import "@opengsn/gsn/contracts/BaseRelayRecipient.sol";


contract RelayRecipient is BaseRelayRecipient {
    function versionRecipient() external pure override returns (string memory) {
        return "1.0.0-beta.1/charged-particles.relay.recipient";
    }
}

// File: contracts/lib/TokenInfo.sol



// TokenInfo.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.0;

library TokenInfo {
    /**
     * @dev Returns true if `account` is a contract.
     * @dev Taken from OpenZeppelin library
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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     * @dev Taken from OpenZeppelin library
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
    function sendValue(
        address payable recipient,
        uint256 amount,
        uint256 gasLimit
    ) internal {
        require(
            address(this).balance >= amount,
            "TokenInfo: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = (gasLimit > 0)
            ? recipient.call{value: amount, gas: gasLimit}("")
            : recipient.call{value: amount}("");
        require(
            success,
            "TokenInfo: unable to send value, recipient may have reverted"
        );
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/interfaces/ISignatureVerifier.sol


pragma solidity ^0.8.0;

interface ISignatureVerifier {
    function verify(
        address _signer,
        address _to,
        uint256 _amount,
        uint256 _nonce,
        bytes memory signature
    ) external pure returns (bool);
}

// File: contracts/interfaces/IChargedParticles.sol



// IChargedParticles.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.0;

/**
 * @notice Interface for Charged Particles
 */
interface IChargedParticles {
    /***********************************|
    |             Public API            |
    |__________________________________*/

    function getStateAddress() external view returns (address stateAddress);

    function getSettingsAddress()
        external
        view
        returns (address settingsAddress);

    function getManagersAddress()
        external
        view
        returns (address managersAddress);

    function getFeesForDeposit(uint256 assetAmount)
        external
        view
        returns (uint256 protocolFee);

    function baseParticleMass(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    ) external returns (uint256);

    function currentParticleCharge(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    ) external returns (uint256);

    function currentParticleKinetics(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    ) external returns (uint256);

    function currentParticleCovalentBonds(
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId
    ) external view returns (uint256);

    /***********************************|
    |        Particle Mechanics         |
    |__________________________________*/

    function energizeParticle(
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken,
        uint256 assetAmount,
        address referrer
    ) external returns (uint256 yieldTokensAmount);

    function dischargeParticle(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    ) external returns (uint256 creatorAmount, uint256 receiverAmount);

    function dischargeParticleAmount(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken,
        uint256 assetAmount
    ) external returns (uint256 creatorAmount, uint256 receiverAmount);

    function dischargeParticleForCreator(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken,
        uint256 assetAmount
    ) external returns (uint256 receiverAmount);

    function releaseParticle(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken
    ) external returns (uint256 creatorAmount, uint256 receiverAmount);

    function releaseParticleAmount(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata walletManagerId,
        address assetToken,
        uint256 assetAmount
    ) external returns (uint256 creatorAmount, uint256 receiverAmount);

    function covalentBond(
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId,
        address nftTokenAddress,
        uint256 nftTokenId
    ) external returns (bool success);

    function breakCovalentBond(
        address receiver,
        address contractAddress,
        uint256 tokenId,
        string calldata basketManagerId,
        address nftTokenAddress,
        uint256 nftTokenId
    ) external returns (bool success);

    /***********************************|
    |          Particle Events          |
    |__________________________________*/

    event Initialized(address indexed initiator);
    event ControllerSet(address indexed controllerAddress, string controllerId);
    event DepositFeeSet(uint256 depositFee);
    event ProtocolFeesCollected(
        address indexed assetToken,
        uint256 depositAmount,
        uint256 feesCollected
    );
}

// File: contracts/interfaces/IChargedState.sol



// IChargedSettings.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.0;

/**
 * @notice Interface for Charged State
 */
interface IChargedState {
    /***********************************|
    |      Only NFT Owner/Operator      |
    |__________________________________*/

    function setDischargeApproval(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external;

    function setReleaseApproval(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external;

    function setBreakBondApproval(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external;

    function setTimelockApproval(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external;

    function setApprovalForAll(
        address contractAddress,
        uint256 tokenId,
        address operator
    ) external;

    function setPermsForRestrictCharge(
        address contractAddress,
        uint256 tokenId,
        bool state
    ) external;

    function setPermsForAllowDischarge(
        address contractAddress,
        uint256 tokenId,
        bool state
    ) external;

    function setPermsForAllowRelease(
        address contractAddress,
        uint256 tokenId,
        bool state
    ) external;

    function setPermsForRestrictBond(
        address contractAddress,
        uint256 tokenId,
        bool state
    ) external;

    function setPermsForAllowBreakBond(
        address contractAddress,
        uint256 tokenId,
        bool state
    ) external;

    function setDischargeTimelock(
        address contractAddress,
        uint256 tokenId,
        uint256 unlockBlock
    ) external;

    function setReleaseTimelock(
        address contractAddress,
        uint256 tokenId,
        uint256 unlockBlock
    ) external;

    function setBreakBondTimelock(
        address contractAddress,
        uint256 tokenId,
        uint256 unlockBlock
    ) external;

    /***********************************|
    |         Only NFT Contract         |
    |__________________________________*/

    function setTemporaryLock(
        address contractAddress,
        uint256 tokenId,
        bool isLocked
    ) external;
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: contracts/interfaces/IERC721Consumable.sol


pragma solidity ^0.8.0;


/// @title ERC-721 Consumer Role extension
///  Note: the ERC-165 identifier for this interface is 0x953c8dfa
interface IERC721Consumable is IERC721 {
    /// @notice Emitted when `owner` changes the `consumer` of an NFT
    /// The zero address for consumer indicates that there is no consumer address
    /// When a Transfer event emits, this also indicates that the consumer address
    /// for that NFT (if any) is set to none
    event ConsumerChanged(
        address indexed owner,
        address indexed consumer,
        uint256 indexed tokenId
    );

    /// @notice Get the consumer address of an NFT
    /// @dev The zero address indicates that there is no consumer
    /// Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to get the consumer address for
    /// @return The consumer address for this NFT, or the zero address if there is none
    function consumerOf(uint256 _tokenId) external view returns (address);

    /// @notice Change or reaffirm the consumer address for an NFT
    /// @dev The zero address indicates there is no consumer address
    /// Throws unless `msg.sender` is the current NFT owner, an authorised
    /// operator of the current owner or approved address
    /// Throws if `_tokenId` is not valid NFT
    /// @param _consumer The new consumer of the NFT
    function changeConsumer(address _consumer, uint256 _tokenId) external;
}

// File: contracts/interfaces/IParticlon.sol



// Particlon.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.0;

// pragma experimental ABIEncoderV2;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// import "./BlackholePrevention.sol";
// import "./RelayRecipient.sol";


interface IParticlon is IERC721 {
    enum EMintPhase {
        CLOSED,
        CLAIM,
        WHITELIST,
        PUBLIC
    }
    /// @notice Andy was here
    event NewBaseURI(string indexed _uri);
    event NewSignerAddress(address indexed signer);
    event NewMintPhase(EMintPhase indexed mintPhase);
    event NewMintPrice(uint256 price);

    event AssetTokenSet(address indexed assetToken);
    event ChargedStateSet(address indexed chargedState);
    event ChargedSettingsSet(address indexed chargedSettings);
    event ChargedParticlesSet(address indexed chargedParticles);

    event SalePriceSet(uint256 indexed tokenId, uint256 salePrice);
    event CreatorRoyaltiesSet(uint256 indexed tokenId, uint256 royaltiesPct);
    event ParticlonSold(
        uint256 indexed tokenId,
        address indexed oldOwner,
        address indexed newOwner,
        uint256 salePrice,
        address creator,
        uint256 creatorRoyalties
    );
    event RoyaltiesClaimed(address indexed receiver, uint256 amountClaimed);

    /***********************************|
    |              Public               |
    |__________________________________*/

    function creatorOf(uint256 tokenId) external view returns (address);

    function getSalePrice(uint256 tokenId) external view returns (uint256);

    function getLastSellPrice(uint256 tokenId) external view returns (uint256);

    function getCreatorRoyalties(address account)
        external
        view
        returns (uint256);

    function getCreatorRoyaltiesPct(uint256 tokenId)
        external
        view
        returns (uint256);

    function getCreatorRoyaltiesReceiver(uint256 tokenId)
        external
        view
        returns (address);

    function buyParticlon(uint256 tokenId, uint256 gasLimit)
        external
        payable
        returns (bool);

    function claimCreatorRoyalties() external returns (uint256);

    // function createParticlonForSale(
    //     address creator,
    //     address receiver,
    //     // string memory tokenMetaUri,
    //     uint256 royaltiesPercent,
    //     uint256 salePrice
    // ) external returns (uint256 newTokenId);

    function mint(uint256 amount) external payable returns (bool);

    function mintWhitelist(
        uint256 amountMint,
        uint256 amountAllowed,
        uint256 nonce,
        bytes calldata signature
    ) external payable returns (bool);

    function mintFree(
        uint256 amountMint,
        uint256 amountAllowed,
        uint256 nonce,
        bytes calldata signature
    ) external returns (bool);

    // function batchParticlonsForSale(
    //     address creator,
    //     uint256 annuityPercent,
    //     uint256 royaltiesPercent,
    //     uint256[] calldata salePrices
    // ) external;

    // function createParticlonsForSale(
    //     address creator,
    //     address receiver,
    //     uint256 royaltiesPercent,
    //     // string[] calldata tokenMetaUris,
    //     uint256[] calldata salePrices
    // ) external returns (bool);

    // Andy was here

    /***********************************|
    |     Only Token Creator/Owner      |
    |__________________________________*/

    function setSalePrice(uint256 tokenId, uint256 salePrice) external;

    function setRoyaltiesPct(uint256 tokenId, uint256 royaltiesPct) external;

    function setCreatorRoyaltiesReceiver(uint256 tokenId, address receiver)
        external;
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: contracts/lib/ERC721A.sol


// Creator: Chiru Labs

pragma solidity ^0.8.4;








error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 1;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId)
        internal
        view
        returns (TokenOwnership memory)
    {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (
            to.isContract() &&
            !_checkContractOnERC721Received(from, to, tokenId, _data)
        ) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex &&
            !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (
                        !_checkContractOnERC721Received(
                            address(0),
                            to,
                            updatedIndex++,
                            _data
                        )
                    ) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        /// @dev Andy was here, made it internal virtual to work with Charged Particles
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev This is equivalent to _burn(tokenId, false)
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try
            IERC721Receiver(to).onERC721Received(
                _msgSender(),
                from,
                tokenId,
                _data
            )
        returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/lib/BlackholePrevention.sol



// BlackholePrevention.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.0;






/**
 * @notice Prevents ETH or Tokens from getting stuck in a contract by allowing
 *  the Owner/DAO to pull them out on behalf of a user
 * This is only meant to contracts that are not expected to hold tokens, but do handle transferring them.
 */
contract BlackholePrevention {
    using Address for address payable;
    using SafeERC20 for IERC20;

    event WithdrawStuckEther(address indexed receiver, uint256 amount);
    event WithdrawStuckERC20(
        address indexed receiver,
        address indexed tokenAddress,
        uint256 amount
    );
    event WithdrawStuckERC721(
        address indexed receiver,
        address indexed tokenAddress,
        uint256 indexed tokenId
    );
    event WithdrawStuckERC1155(
        address indexed receiver,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 amount
    );

    function _withdrawEther(address payable receiver, uint256 amount)
        internal
        virtual
    {
        require(receiver != address(0x0), "BHP:E-403");
        if (address(this).balance >= amount) {
            receiver.sendValue(amount);
            emit WithdrawStuckEther(receiver, amount);
        }
    }

    function _withdrawERC20(
        address payable receiver,
        address tokenAddress,
        uint256 amount
    ) internal virtual {
        require(receiver != address(0x0), "BHP:E-403");
        if (IERC20(tokenAddress).balanceOf(address(this)) >= amount) {
            IERC20(tokenAddress).safeTransfer(receiver, amount);
            emit WithdrawStuckERC20(receiver, tokenAddress, amount);
        }
    }

    function _withdrawERC721(
        address payable receiver,
        address tokenAddress,
        uint256 tokenId
    ) internal virtual {
        require(receiver != address(0x0), "BHP:E-403");
        if (IERC721(tokenAddress).ownerOf(tokenId) == address(this)) {
            IERC721(tokenAddress).transferFrom(
                address(this),
                receiver,
                tokenId
            );
            emit WithdrawStuckERC721(receiver, tokenAddress, tokenId);
        }
    }

    function _withdrawERC1155(
        address payable receiver,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        require(receiver != address(0x0), "BHP:E-403");
        if (
            IERC1155(tokenAddress).balanceOf(address(this), tokenId) >= amount
        ) {
            IERC1155(tokenAddress).safeTransferFrom(
                address(this),
                receiver,
                tokenId,
                amount,
                ""
            );
            emit WithdrawStuckERC1155(receiver, tokenAddress, tokenId, amount);
        }
    }
}

// File: contracts/Particlon.sol



// ParticlonB.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity ^0.8.0;
















contract Particlon is
    IParticlon,
    ERC721A,
    IERC721Consumable,
    Ownable,
    Pausable,
    RelayRecipient,
    ReentrancyGuard,
    BlackholePrevention
{
    // using SafeMath for uint256; // not needed since solidity 0.8
    using TokenInfo for address payable;
    using Strings for uint256;

    /// @dev In case we want to revoke the consumer part
    bool internal _revokeConsumerOnTransfer;

    /// @notice Address used to generate cryptographic signatures for whitelisted addresses
    address internal _signer = 0xE8cF9826C7702411bb916c447D759E0E631d2e68;

    uint256 internal _nonceClaim = 69;
    uint256 internal _nonceWL = 420;

    uint256 public constant MAX_SUPPLY = 10069;
    uint256 public constant INITIAL_PRICE = 0.15 ether;

    uint256 internal constant PERCENTAGE_SCALE = 1e4; // 10000  (100%)
    uint256 internal constant MAX_ROYALTIES = 8e3; // 8000   (80%)

    // Charged Particles V1 mainnet

    IChargedState internal _chargedState =
        IChargedState(0xB29256073C63960daAa398f1227D0adBC574341C);
    // IChargedSettings internal _chargedSettings;
    IChargedParticles internal _chargedParticles =
        IChargedParticles(0xaB1a1410EA40930755C1330Cc0fB3367897C8c41);

    /// @notice This needs to be set using the setAssetToken in order to get approved
    address internal _assetToken;

    // This right here drops the size so it doesn't break the limitation
    // Enable optimization also has to be tured on!
    ISignatureVerifier internal constant _signatureVerifier =
        ISignatureVerifier(0x47a0915747565E8264296457b894068fe5CA9186);

    uint256 internal _mintPrice;

    string internal _baseUri =
        "ipfs://QmQrdG1cESrBenNUaTmxckFm4gJwgLdkqTGxNLuh4t5vo8/";

    // Mapping from token ID to consumer address
    mapping(uint256 => address) _tokenConsumers;

    mapping(uint256 => address) internal _tokenCreator;
    mapping(uint256 => uint256) internal _tokenCreatorRoyaltiesPct;
    mapping(uint256 => address) internal _tokenCreatorRoyaltiesRedirect;
    mapping(address => uint256) internal _tokenCreatorClaimableRoyalties;

    mapping(uint256 => uint256) internal _tokenSalePrice;
    mapping(uint256 => uint256) internal _tokenLastSellPrice;

    /// @notice Adhere to limits per whitelisted wallet for claim mint phase
    mapping(address => uint256) internal _mintPassMinted;

    /// @notice Adhere to limits per whitelisted wallet for whitelist mint phase
    mapping(address => uint256) internal _whitelistedAddressMinted;

    /// @notice set to CLOSED by default
    EMintPhase public mintPhase;

    /***********************************|
    |          Initialization           |
    |__________________________________*/

    constructor() ERC721A("Particlon", "PART") {
        _mintPrice = INITIAL_PRICE;
    }

    /***********************************|
    |              Public               |
    |__________________________________*/

    // Define an "onlyOwner" switch
    function setRevokeConsumerOnTransfer(bool state) external onlyOwner {
        _revokeConsumerOnTransfer = state;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC721A)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Consumable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Consumable-consumerOf}
     */
    function consumerOf(uint256 _tokenId) external view returns (address) {
        require(
            _exists(_tokenId),
            "ERC721Consumable: consumer query for nonexistent token"
        );
        return _tokenConsumers[_tokenId];
    }

    function creatorOf(uint256 tokenId)
        external
        view
        override
        returns (address)
    {
        return _tokenCreator[tokenId];
    }

    function getSalePrice(uint256 tokenId)
        external
        view
        override
        returns (uint256)
    {
        return _tokenSalePrice[tokenId];
    }

    function getLastSellPrice(uint256 tokenId)
        external
        view
        override
        returns (uint256)
    {
        return _tokenLastSellPrice[tokenId];
    }

    function getCreatorRoyalties(address account)
        external
        view
        override
        returns (uint256)
    {
        return _tokenCreatorClaimableRoyalties[account];
    }

    function getCreatorRoyaltiesPct(uint256 tokenId)
        external
        view
        override
        returns (uint256)
    {
        return _tokenCreatorRoyaltiesPct[tokenId];
    }

    function getCreatorRoyaltiesReceiver(uint256 tokenId)
        external
        view
        override
        returns (address)
    {
        return _creatorRoyaltiesReceiver(tokenId);
    }

    function claimCreatorRoyalties()
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        return _claimCreatorRoyalties(_msgSender());
    }

    /***********************************|
    |      Create Multiple Particlons   |
    |__________________________________*/

    /// @notice Andy was here
    function mint(uint256 amount)
        external
        payable
        override
        nonReentrant
        whenNotPaused
        notBeforePhase(EMintPhase.PUBLIC)
        whenRemainingSupply
        requirePayment(amount)
        returns (bool)
    {
        // They may have minted 10, but if only 2 remain in supply, then they will only get 2, so only pay for 2
        uint256 actualPrice = _mintAmount(amount, _msgSender());
        _refundOverpayment(actualPrice, 0); // dont worry about gasLimit here as the "minter" could only hook themselves
        return true;
    }

    /// @notice Andy was here
    function mintWhitelist(
        uint256 amountMint,
        uint256 amountAllowed,
        uint256 nonce,
        bytes calldata signature
    )
        external
        payable
        override
        nonReentrant
        whenNotPaused
        notBeforePhase(EMintPhase.WHITELIST)
        whenRemainingSupply
        requirePayment(amountMint)
        requireWhitelist(amountMint, amountAllowed, nonce, signature)
        returns (bool)
    {
        // They may have been whitelisted to mint 10, but if only 2 remain in supply, then they will only get 2, so only pay for 2
        uint256 actualPrice = _mintAmount(amountMint, _msgSender());
        _refundOverpayment(actualPrice, 0);
        return true;
    }

    function mintFree(
        uint256 amountMint,
        uint256 amountAllowed,
        uint256 nonce,
        bytes calldata signature
    )
        external
        override
        whenNotPaused
        notBeforePhase(EMintPhase.CLAIM)
        whenRemainingSupply
        requirePass(amountMint, amountAllowed, nonce, signature)
        returns (bool)
    {
        // They may have been whitelisted to mint 10, but if only 2 remain in supply, then they will only get 2
        _mintAmount(amountMint, _msgSender());
        return true;
    }

    /***********************************|
    |           Buy Particlons          |
    |__________________________________*/

    function buyParticlon(uint256 tokenId, uint256 gasLimit)
        external
        payable
        override
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        _buyParticlon(tokenId, gasLimit);
        return true;
    }

    /***********************************|
    |     Only Token Creator/Owner      |
    |__________________________________*/

    function setSalePrice(uint256 tokenId, uint256 salePrice)
        external
        override
        whenNotPaused
        onlyTokenOwnerOrApproved(tokenId)
    {
        _setSalePrice(tokenId, salePrice);
    }

    function setRoyaltiesPct(uint256 tokenId, uint256 royaltiesPct)
        external
        override
        whenNotPaused
        onlyTokenCreator(tokenId)
        onlyTokenOwnerOrApproved(tokenId)
    {
        _setRoyaltiesPct(tokenId, royaltiesPct);
    }

    function setCreatorRoyaltiesReceiver(uint256 tokenId, address receiver)
        external
        override
        whenNotPaused
        onlyTokenCreator(tokenId)
    {
        _tokenCreatorRoyaltiesRedirect[tokenId] = receiver;
    }

    /**
     * @dev See {IERC721Consumable-changeConsumer}
     */
    function changeConsumer(address _consumer, uint256 _tokenId) external {
        address owner = this.ownerOf(_tokenId);
        require(
            _msgSender() == owner ||
                _msgSender() == getApproved(_tokenId) ||
                isApprovedForAll(owner, _msgSender()),
            "ERC721Consumable: changeConsumer caller is not owner nor approved"
        );
        _changeConsumer(owner, _consumer, _tokenId);
    }

    /***********************************|
    |          Only Admin/DAO           |
    |__________________________________*/

    // Andy was here (Andy is everywhere)

    function setSignerAddress(address signer) external onlyOwner {
        _signer = signer;
        emit NewSignerAddress(signer);
    }

    // In case we need to "undo" a signature/prevent it from being used,
    // This is easier than changing the signer
    // we would also need to remake all unused signatures
    function setNonces(uint256 nonceClaim, uint256 nonceWL) external onlyOwner {
        _nonceClaim = nonceClaim;
        _nonceWL = nonceWL;
    }

    function setAssetToken(address assetToken) external onlyOwner {
        _assetToken = assetToken;
        // Need to Approve Charged Particles to transfer Assets from Particlon
        IERC20(assetToken).approve(
            address(_chargedParticles),
            type(uint256).max
        );
        emit AssetTokenSet(assetToken);
    }

    function setMintPrice(uint256 price) external onlyOwner {
        _mintPrice = price;
        emit NewMintPrice(price);
    }

    /// @notice This is needed for the reveal
    function setURI(string memory uri) external onlyOwner {
        _baseUri = uri;
        emit NewBaseURI(uri);
    }

    function setMintPhase(EMintPhase _mintPhase) external onlyOwner {
        mintPhase = _mintPhase;
        emit NewMintPhase(_mintPhase);
    }

    function setPausedState(bool state) external onlyOwner {
        state ? _pause() : _unpause(); // these emit events
    }

    /**
     * @dev Setup the ChargedParticles Interface
     */
    function setChargedParticles(address chargedParticles) external onlyOwner {
        _chargedParticles = IChargedParticles(chargedParticles);
        emit ChargedParticlesSet(chargedParticles);
    }

    /// @dev Setup the Charged-State Controller
    function setChargedState(address stateController) external onlyOwner {
        _chargedState = IChargedState(stateController);
        emit ChargedStateSet(stateController);
    }

    /// @dev Setup the Charged-Settings Controller
    // function setChargedSettings(address settings) external onlyOwner {
    //     _chargedSettings = IChargedSettings(settings);
    //     emit ChargedSettingsSet(settings);
    // }

    function setTrustedForwarder(address _trustedForwarder) external onlyOwner {
        _setTrustedForwarder(_trustedForwarder); // Andy was here, trustedForwarder is already defined in opengsn/contracts/src/BaseRelayRecipient.sol
    }

    /***********************************|
    |          Only Admin/DAO           |
    |      (blackhole prevention)       |
    |__________________________________*/

    function withdrawEther(address payable receiver, uint256 amount)
        external
        onlyOwner
    {
        _withdrawEther(receiver, amount);
    }

    function withdrawERC20(
        address payable receiver,
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        _withdrawERC20(receiver, tokenAddress, amount);
    }

    function withdrawERC721(
        address payable receiver,
        address tokenAddress,
        uint256 tokenId
    ) external onlyOwner {
        _withdrawERC721(receiver, tokenAddress, tokenId);
    }

    /***********************************|
    |         Private Functions         |
    |__________________________________*/

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function _mintAmount(uint256 amount, address creator)
        internal
        returns (uint256 actualPrice)
    {
        uint256 newTokenId = totalSupply();
        // newTokenId is equal to the supply at this stage
        if (newTokenId + amount > MAX_SUPPLY) {
            amount = MAX_SUPPLY - newTokenId;
        }
        // totalSupply += amount;

        // _safeMint's second argument now takes in a quantity, not a tokenId.
        _safeMint(creator, amount);
        actualPrice = amount * _mintPrice; // Charge people for the ACTUAL amount minted;

        uint256 assetAmount;
        newTokenId++;
        for (uint256 i; i < amount; i++) {
            // Set the first minters as the creators
            _tokenCreator[newTokenId + i] = creator;
            assetAmount += _getAssetAmount(newTokenId + i);
            // _chargeParticlon(newTokenId, "generic", assetAmount);
        }
        // Put all ERC20 tokens into the first Particlon to save a lot of gas
        _chargeParticlon(newTokenId, "generic", assetAmount);
    }

    /**
     * @dev Changes the consumer
     * Requirement: `tokenId` must exist
     */
    function _changeConsumer(
        address _owner,
        address _consumer,
        uint256 _tokenId
    ) internal {
        _tokenConsumers[_tokenId] = _consumer;
        emit ConsumerChanged(_owner, _consumer, _tokenId);
    }

    function _beforeTokenTransfers(
        address _from,
        address _to,
        uint256 _startTokenId,
        uint256 _quantity
    ) internal virtual override(ERC721A) {
        if (_from == address(0)) {
            return;
        }
        super._beforeTokenTransfers(_from, _to, _startTokenId, _quantity);

        require(!paused(), "ERC721Pausable: token transfer while paused");

        if (_revokeConsumerOnTransfer) {
            /// @notice quantity is always one in this case
            _changeConsumer(_from, address(0), _startTokenId);
        }
    }

    function _setSalePrice(uint256 tokenId, uint256 salePrice) internal {
        _tokenSalePrice[tokenId] = salePrice;

        // Temp-Lock/Unlock NFT
        //  prevents front-running the sale and draining the value of the NFT just before sale
        _chargedState.setTemporaryLock(address(this), tokenId, (salePrice > 0));

        emit SalePriceSet(tokenId, salePrice);
    }

    function _setRoyaltiesPct(uint256 tokenId, uint256 royaltiesPct) internal {
        require(royaltiesPct <= MAX_ROYALTIES, "PRT:E-421"); // Andy was here
        _tokenCreatorRoyaltiesPct[tokenId] = royaltiesPct;
        emit CreatorRoyaltiesSet(tokenId, royaltiesPct);
    }

    function _creatorRoyaltiesReceiver(uint256 tokenId)
        internal
        view
        returns (address)
    {
        address receiver = _tokenCreatorRoyaltiesRedirect[tokenId];
        if (receiver == address(0x0)) {
            receiver = _tokenCreator[tokenId];
        }
        return receiver;
    }

    /// @notice The tokens from a batch are being nested into the first NFT minted in that batch
    function _getAssetAmount(uint256 tokenId) internal pure returns (uint256) {
        if (tokenId == MAX_SUPPLY) {
            return 1596 * 10**18;
        } else if (tokenId > 9000) {
            return 1403 * 10**18;
        } else if (tokenId > 6000) {
            return 1000 * 10**18;
        } else if (tokenId > 3000) {
            return 1500 * 10**18;
        } else if (tokenId > 1000) {
            return 1750 * 10**18;
        }
        return 2500 * 10**18;
    }

    function _chargeParticlon(
        uint256 tokenId,
        string memory walletManagerId,
        uint256 assetAmount
    ) internal {
        address _self = address(this);
        _chargedParticles.energizeParticle(
            _self,
            tokenId,
            walletManagerId,
            _assetToken,
            assetAmount,
            _self
        );
    }

    function _buyParticlon(uint256 _tokenId, uint256 _gasLimit)
        internal
        returns (
            address contractAddress,
            uint256 tokenId,
            address oldOwner,
            address newOwner,
            uint256 salePrice,
            address royaltiesReceiver,
            uint256 creatorAmount
        )
    {
        contractAddress = address(this);
        tokenId = _tokenId;
        salePrice = _tokenSalePrice[_tokenId];
        require(salePrice > 0, "PRT:E-416");
        require(msg.value >= salePrice, "PRT:E-414");

        uint256 ownerAmount = salePrice;
        // creatorAmount;
        oldOwner = ownerOf(_tokenId);
        newOwner = _msgSender();

        // Creator Royalties
        royaltiesReceiver = _creatorRoyaltiesReceiver(_tokenId);
        uint256 royaltiesPct = _tokenCreatorRoyaltiesPct[_tokenId];
        uint256 lastSellPrice = _tokenLastSellPrice[_tokenId];
        if (
            royaltiesPct > 0 && lastSellPrice > 0 && salePrice > lastSellPrice
        ) {
            creatorAmount =
                ((salePrice - lastSellPrice) * royaltiesPct) /
                PERCENTAGE_SCALE;
            ownerAmount -= creatorAmount;
        }
        _tokenLastSellPrice[_tokenId] = salePrice;

        // Reserve Royalties for Creator
        if (creatorAmount > 0) {
            _tokenCreatorClaimableRoyalties[royaltiesReceiver] += creatorAmount;
        }

        // Transfer Token
        _transfer(oldOwner, newOwner, _tokenId);

        emit ParticlonSold(
            _tokenId,
            oldOwner,
            newOwner,
            salePrice,
            royaltiesReceiver,
            creatorAmount
        );

        // Transfer Payment
        if (ownerAmount > 0) {
            payable(oldOwner).sendValue(ownerAmount, _gasLimit);
        }
        _refundOverpayment(salePrice, _gasLimit);
    }

    /**
     * @dev Pays out the Creator Royalties of the calling account
     * @param receiver  The receiver of the claimable royalties
     * @return          The amount of Creator Royalties claimed
     */
    function _claimCreatorRoyalties(address receiver)
        internal
        returns (uint256)
    {
        uint256 claimableAmount = _tokenCreatorClaimableRoyalties[receiver];
        require(claimableAmount > 0, "PRT:E-411");

        delete _tokenCreatorClaimableRoyalties[receiver];
        payable(receiver).sendValue(claimableAmount, 0);

        emit RoyaltiesClaimed(receiver, claimableAmount);

        // Andy was here
        return claimableAmount;
    }

    function _refundOverpayment(uint256 threshold, uint256 gasLimit) internal {
        // Andy was here, removed SafeMath
        uint256 overage = msg.value - threshold;
        if (overage > 0) {
            payable(_msgSender()).sendValue(overage, gasLimit);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        // Unlock NFT
        _tokenSalePrice[tokenId] = 0; // Andy was here
        _chargedState.setTemporaryLock(address(this), tokenId, false);

        super._transfer(from, to, tokenId);
    }

    /***********************************|
    |          GSN/MetaTx Relay         |
    |__________________________________*/

    /// @dev See {BaseRelayRecipient-_msgSender}.
    /// Andy: removed payable
    function _msgSender()
        internal
        view
        override(BaseRelayRecipient, Context)
        returns (address)
    {
        return BaseRelayRecipient._msgSender();
    }

    /// @dev See {BaseRelayRecipient-_msgData}.
    function _msgData()
        internal
        view
        override(BaseRelayRecipient, Context)
        returns (bytes memory)
    {
        return BaseRelayRecipient._msgData();
    }

    /// @dev This is missing from ERC721A for some reason.
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /***********************************|
    |             Modifiers             |
    |__________________________________*/

    // Andy was here
    modifier notBeforePhase(EMintPhase _mintPhase) {
        require(mintPhase >= _mintPhase, "MINT PHASE ERR");
        _;
    }

    modifier whenRemainingSupply() {
        require(totalSupply() <= MAX_SUPPLY, "SUPPLY LIMIT");
        _;
    }

    modifier requirePayment(uint256 amount) {
        uint256 fullPrice = amount * _mintPrice;
        require(msg.value >= fullPrice, "LOW ETH");
        _;
    }

    modifier requireWhitelist(
        uint256 amountMint,
        uint256 amountAllowed,
        uint256 nonce,
        bytes calldata signature
    ) {
        require(amountMint <= amountAllowed, "AMOUNT ERR");
        require(nonce == _nonceWL, "NONCE ERR");
        require(
            _signatureVerifier.verify(
                _signer,
                _msgSender(),
                amountAllowed,
                nonce, // prevent WL signatures being used for claiming
                signature
            ),
            "SIGNATURE ERR"
        );
        require(
            _whitelistedAddressMinted[_msgSender()] + amountMint <=
                amountAllowed,
            "CLAIM ERR"
        );
        _whitelistedAddressMinted[_msgSender()] += amountMint;
        _;
    }

    /// @notice A snapshot is taken before the mint (mint pass NFT count is taken into consideration)
    modifier requirePass(
        uint256 amountMint,
        uint256 amountAllowed,
        uint256 nonce,
        bytes calldata signature
    ) {
        require(amountMint <= amountAllowed, "AMOUNT ERR");
        require(nonce == _nonceClaim, "NONCE ERR");
        require(
            _signatureVerifier.verify(
                _signer,
                _msgSender(),
                amountAllowed,
                nonce,
                signature
            ),
            "SIGNATURE ERR"
        );
        require(
            _mintPassMinted[_msgSender()] + amountMint <= amountAllowed,
            "CLAIM ERR"
        );
        _mintPassMinted[_msgSender()] += amountMint;
        _;
    }

    modifier onlyTokenOwnerOrApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "PRT:E-105");
        _;
    }

    modifier onlyTokenCreator(uint256 tokenId) {
        require(_tokenCreator[tokenId] == _msgSender(), "PRT:E-104");
        _;
    }
}