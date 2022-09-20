/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)





/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}






/**
    @title Interface for handler contracts that support deposits and deposit executions.
    @author ChainSafe Systems.
 */
interface IDepositExecute {
    /**
        @notice It is intended that deposit are made using the Bridge contract.
        @param depositer Address of account making the deposit in the Bridge contract.
        @param data Consists of additional data needed for a specific deposit.
     */
    function deposit(bytes32 resourceID, address depositer, bytes calldata data) external returns (bytes memory);

    /**
        @notice It is intended that proposals are executed by the Bridge contract.
        @param data Consists of additional data needed for a specific deposit execution.
     */
    function executeProposal(bytes32 resourceID, bytes calldata data) external;
}

 





/**
    @title Interface to be used with handlers that support ERC20s and ERC721s.
    @author ChainSafe Systems.
 */
interface IERCHandler {
    /**
        @notice Correlates {resourceID} with {contractAddress}.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
    function setResource(bytes32 resourceID, address contractAddress) external;
    /**
        @notice Marks {contractAddress} as mintable/burnable.
        @param contractAddress Address of contract to be used when making or executing deposits.
     */
    function setBurnable(address contractAddress) external;

    /**
        @notice Withdraw funds from ERC safes.
        @param data ABI-encoded withdrawal params relevant to the handler.
     */
    function withdraw(bytes memory data) external;

    /**
        @notice Exposing getter for {_resourceIDToTokenContractAddress}.
        @param resourceID ResourceID to be used.
        @return address The {tokenContractAddress} that is currently set for the resourceID.
     */
    function _resourceIDToTokenContractAddress(bytes32 resourceID) external view returns (address);
}


/**
    @title Function used across handler contracts.
    @author ChainSafe Systems.
    @notice This contract is intended to be used with the Bridge contract.
 */
contract HandlerHelpers is IERCHandler {
    address public immutable _bridgeAddress;

    // resourceID => token contract address
    mapping (bytes32 => address) public _resourceIDToTokenContractAddress;

    // token contract address => resourceID
    mapping (address => bytes32) public _tokenContractAddressToResourceID;

    // token contract address => is whitelisted
    mapping (address => bool) public _contractWhitelist;

    // token contract address => is burnable
    mapping (address => bool) public _burnList;

    modifier onlyBridge() {
        _onlyBridge();
        _;
    }

    /**
        @param bridgeAddress Contract address of previously deployed Bridge.
     */
    constructor(
        address          bridgeAddress
    ) public {
        _bridgeAddress = bridgeAddress;
    }

    function _onlyBridge() private view {
        require(msg.sender == _bridgeAddress, "sender must be bridge contract");
    }

    /**
        @notice First verifies {_resourceIDToContractAddress}[{resourceID}] and
        {_contractAddressToResourceID}[{contractAddress}] are not already set,
        then sets {_resourceIDToContractAddress} with {contractAddress},
        {_contractAddressToResourceID} with {resourceID},
        and {_contractWhitelist} to true for {contractAddress}.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
    function setResource(bytes32 resourceID, address contractAddress) external override onlyBridge {

        _setResource(resourceID, contractAddress);
    }

    /**
        @notice First verifies {contractAddress} is whitelisted, then sets {_burnList}[{contractAddress}]
        to true.
        @param contractAddress Address of contract to be used when making or executing deposits.
     */
    function setBurnable(address contractAddress) external override onlyBridge{
        _setBurnable(contractAddress);
    }

    function withdraw(bytes memory data) external virtual override {}

    function _setResource(bytes32 resourceID, address contractAddress) internal {
        _resourceIDToTokenContractAddress[resourceID] = contractAddress;
        _tokenContractAddressToResourceID[contractAddress] = resourceID;

        _contractWhitelist[contractAddress] = true;
    }

    function _setBurnable(address contractAddress) internal {
        require(_contractWhitelist[contractAddress], "provided contract is not whitelisted");
        _burnList[contractAddress] = true;
    }
}











interface IERC721MinterBurner is IERC721 {
    function mint(address to, uint256 tokenId, string memory _data) external;
    function burn(uint256 tokenId) external;
}



/**
    @title Manages deposited ERC721s.
    @author ChainSafe Systems.
    @notice This contract is intended to be used with ERC721Handler contract.
 */
contract ERC721Safe {
    /**
        @notice Used to gain custoday of deposited token.
        @param tokenAddress Address of ERC721 to transfer.
        @param owner Address of current token owner.
        @param recipient Address to transfer token to.
        @param tokenID ID of token to transfer.
     */
    function lockERC721(address tokenAddress, address owner, address recipient, uint tokenID) internal {
        IERC721 erc721 = IERC721(tokenAddress);
        erc721.transferFrom(owner, recipient, tokenID);

    }

    /**
        @notice Transfers custody of token to recipient.
        @param tokenAddress Address of ERC721 to transfer.
        @param owner Address of current token owner.
        @param recipient Address to transfer token to.
        @param tokenID ID of token to transfer.
     */
    function releaseERC721(address tokenAddress, address owner, address recipient, uint256 tokenID) internal {
        IERC721 erc721 = IERC721(tokenAddress);
        erc721.transferFrom(owner, recipient, tokenID);
    }

    /**
        @notice Used to create new ERC721s.
        @param tokenAddress Address of ERC721 to mint.
        @param recipient Address to mint token to.
        @param tokenID ID of token to mint.
        @param data Optional data to send along with mint call.
     */
    function mintERC721(address tokenAddress, address recipient, uint256 tokenID, bytes memory data) internal {
        IERC721MinterBurner erc721 = IERC721MinterBurner(tokenAddress);
        erc721.mint(recipient, tokenID, string(data));
    }

    /**
        @notice Used to burn ERC721s.
        @param tokenAddress Address of ERC721 to burn.
        @param tokenID ID of token to burn.
     */
    function burnERC721(address tokenAddress, uint256 tokenID) internal {
        IERC721MinterBurner erc721 = IERC721MinterBurner(tokenAddress);
        erc721.burn(tokenID);
    }

}


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)





/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId)
        internal
        view
        returns (bool)
    {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return
            supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(
                    account,
                    interfaceIds[i]
                );
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId)
        private
        view
        returns (bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(
            IERC165.supportsInterface.selector,
            interfaceId
        );
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(
            encodedParams
        );
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)





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


/**
    @title Handles ERC721 deposits and deposit executions.
    @author ChainSafe Systems.
    @notice This contract is intended to be used with the Bridge contract.
 */
contract ERC721Handler is IDepositExecute, HandlerHelpers, ERC721Safe {
    using ERC165Checker for address;

    bytes4 private constant _INTERFACE_ERC721_METADATA = 0x5b5e139f;

    /**
        @param bridgeAddress Contract address of previously deployed Bridge.
     */
    constructor(
        address bridgeAddress
    ) public HandlerHelpers(bridgeAddress) {
    }

    /**
        @notice A deposit is initiatied by making a deposit in the Bridge contract.
        @param resourceID ResourceID used to find address of token to be used for deposit.
        @param depositer Address of account making the deposit in the Bridge contract.
        @param data Consists of {tokenID} padded to 32 bytes.
        @notice Data passed into the function should be constructed as follows:
        tokenID                                     uint256    bytes    0  - 32
        @notice If the corresponding {tokenAddress} for the parsed {resourceID} supports {_INTERFACE_ERC721_METADATA},
        then {metaData} will be set according to the {tokenURI} method in the token contract.
        @dev Depending if the corresponding {tokenAddress} for the parsed {resourceID} is
        marked true in {_burnList}, deposited tokens will be burned, if not, they will be locked.
        @return metaData : the deposited token metadata acquired by calling a {tokenURI} method in the token contract.
     */
    function deposit(bytes32    resourceID,
                    address     depositer,
                    bytes       calldata data
                    ) external override onlyBridge returns (bytes memory metaData) {
        uint         tokenID;

        (tokenID) = abi.decode(data, (uint));

        address tokenAddress = _resourceIDToTokenContractAddress[resourceID];
        require(_contractWhitelist[tokenAddress], "provided tokenAddress is not whitelisted");

        // Check if the contract supports metadata, fetch it if it does
        if (tokenAddress.supportsInterface(_INTERFACE_ERC721_METADATA)) {
            IERC721Metadata erc721 = IERC721Metadata(tokenAddress);
            metaData = bytes(erc721.tokenURI(tokenID));
        }

        if (_burnList[tokenAddress]) {
            burnERC721(tokenAddress, tokenID);
        } else {
            lockERC721(tokenAddress, depositer, address(this), tokenID);
        }
    }

    /**
        @notice Proposal execution should be initiated when a proposal is finalized in the Bridge contract.
        by a relayer on the deposit's destination chain.
        @param data Consists of {tokenID}, {resourceID}, {lenDestinationRecipientAddress},
        {destinationRecipientAddress}, {lenMeta}, and {metaData} all padded to 32 bytes.
        @notice Data passed into the function should be constructed as follows:
        tokenID                                     uint256    bytes    0  - 32
        destinationRecipientAddress     length      uint256    bytes    32 - 64
        destinationRecipientAddress                   bytes    bytes    64 - (64 + len(destinationRecipientAddress))
        metadata                        length      uint256    bytes    (64 + len(destinationRecipientAddress)) - (64 + len(destinationRecipientAddress) + 32)
        metadata                                      bytes    bytes    (64 + len(destinationRecipientAddress) + 32) - END
     */
    function executeProposal(bytes32 resourceID, bytes calldata data) external override onlyBridge {
        uint         tokenID;
        uint         lenDestinationRecipientAddress;
        bytes memory destinationRecipientAddress;
        uint         offsetMetaData;
        uint         lenMetaData;
        bytes memory metaData;

        (tokenID, lenDestinationRecipientAddress) = abi.decode(data, (uint, uint));
        offsetMetaData = 64 + lenDestinationRecipientAddress;
        destinationRecipientAddress = bytes(data[64:offsetMetaData]);
        lenMetaData = abi.decode(data[offsetMetaData:], (uint));
        metaData = bytes(data[offsetMetaData + 32:offsetMetaData + 32 + lenMetaData]);

        bytes20 recipientAddress;

        assembly {
            recipientAddress := mload(add(destinationRecipientAddress, 0x20))
        }

        address tokenAddress = _resourceIDToTokenContractAddress[resourceID];
        require(_contractWhitelist[address(tokenAddress)], "provided tokenAddress is not whitelisted");

        if (_burnList[tokenAddress]) {
            mintERC721(tokenAddress, address(recipientAddress), tokenID, metaData);
        } else {
            releaseERC721(tokenAddress, address(this), address(recipientAddress), tokenID);
        }
    }

    /**
        @notice Used to manually release ERC721 tokens from ERC721Safe.
        @param data Consists of {tokenAddress}, {recipient}, and {tokenID} all padded to 32 bytes.
        @notice Data passed into the function should be constructed as follows:
        tokenAddress                           address     bytes  0 - 32
        recipient                              address     bytes  32 - 64
        tokenID                                uint        bytes  64 - 96
     */
    function withdraw(bytes memory data) external override onlyBridge {
        address tokenAddress;
        address recipient;
        uint tokenID;

        (tokenAddress, recipient, tokenID) = abi.decode(data, (address, address, uint));

        releaseERC721(tokenAddress, address(this), recipient, tokenID);
    }
}