// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@ethereansos/swissknife/contracts/factory/model/IFactory.sol";
import "../../base/model/IProposalsManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@ethereansos/items-v2/contracts/model/Item.sol";

contract ValidateQuorum is IProposalChecker {

    string public constant LABEL = 'quorum';

    uint256 public constant ONE_HUNDRED = 1e18;

    string public uri;
    uint256 public value;
    bool public discriminant;

    function lazyInit(bytes memory lazyInitData) external returns(bytes memory lazyInitResponseData) {
        require(keccak256(bytes(uri)) == keccak256(""));
        (uri, lazyInitResponseData) = abi.decode(lazyInitData, (string, bytes));
        require(keccak256(bytes(uri)) != keccak256(""));

        (value, discriminant) = abi.decode(lazyInitResponseData, (uint256, bool));

        lazyInitResponseData = "";
    }

    function check(address, bytes32, bytes calldata proposalData, address, address) external override view returns(bool) {
        IProposalsManager.Proposal memory proposal  = abi.decode(proposalData, (IProposalsManager.Proposal));
        uint256 quorum = discriminant ? _calculatePercentage(_calculateCensusTotalSupply(proposal), value) : value;
        return ((proposal.accept + proposal.refuse) >= quorum) && (proposal.accept > proposal.refuse);
    }

    function _calculateCensusTotalSupply(IProposalsManager.Proposal memory proposal) private view returns (uint256 censusTotalSupply) {
        (address[] memory collectionAddresses, uint256[] memory objectIds, uint256[] memory weights) = abi.decode(proposal.votingTokens, (address[], uint256[], uint256[]));
        for(uint256 i = 0; i < collectionAddresses.length; i++) {
            censusTotalSupply += (_calculateTotalSupply(collectionAddresses[i], objectIds[i]) * weights[i]);
        }
    }

    function _calculatePercentage(uint256 totalSupply, uint256 percentage) private pure returns (uint256) {
        return (totalSupply * ((percentage * 1e18) / ONE_HUNDRED)) / 1e18;
    }

    function _calculateTotalSupply(address collectionAddress, uint256 collectionId) private view returns(uint256) {
        if(collectionAddress == address(0)) {
            return IERC20(address(uint160(collectionId))).totalSupply();
        }
        return Item(collectionAddress).totalSupply(collectionId);
    }
}

contract CanBeValidBeforeBlockLength is IProposalChecker {

    string public constant LABEL = 'validationBomb';

    string public uri;
    uint256 public value;

    function lazyInit(bytes memory lazyInitData) external returns(bytes memory lazyInitResponseData) {
        require(keccak256(bytes(uri)) == keccak256(""));
        (uri, lazyInitResponseData) = abi.decode(lazyInitData, (string, bytes));
        require(keccak256(bytes(uri)) != keccak256(""));

        value = abi.decode(lazyInitResponseData, (uint256));

        lazyInitResponseData = "";
    }

    function check(address, bytes32, bytes calldata proposalData, address, address) external override view returns(bool) {
        return block.number < (value + abi.decode(proposalData, (IProposalsManager.Proposal)).creationBlock);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IERC1155Views.sol";

struct Header {
    address host;
    string name;
    string symbol;
    string uri;
}

struct CreateItem {
    Header header;
    bytes32 collectionId;
    uint256 id;
    address[] accounts;
    uint256[] amounts;
}

interface Item is IERC1155, IERC1155Views {

    event CollectionItem(bytes32 indexed fromCollectionId, bytes32 indexed toCollectionId, uint256 indexed itemId);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint256);

    function burn(address account, uint256 itemId, uint256 amount) external;
    function burnBatch(address account, uint256[] calldata itemIds, uint256[] calldata amounts) external;

    function burn(address account, uint256 itemId, uint256 amount, bytes calldata data) external;
    function burnBatch(address account, uint256[] calldata itemIds, uint256[] calldata amounts, bytes calldata data) external;

    function mintItems(CreateItem[] calldata items) external returns(uint256[] memory itemIds);
    function setItemsCollection(uint256[] calldata itemIds, bytes32[] calldata collectionIds) external returns(bytes32[] memory oldCollectionIds);
    function setItemsMetadata(uint256[] calldata itemIds, Header[] calldata newValues) external returns(Header[] memory oldValues);

    function interoperableOf(uint256 itemId) external view returns(address);
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@ethereansos/swissknife/contracts/generic/model/ILazyInitCapableElement.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

interface IProposalsManager is IERC1155Receiver, ILazyInitCapableElement {

    struct ProposalCode {
        address location;
        bytes bytecode;
    }

    struct ProposalCodes {
        ProposalCode[] codes;
        bool alsoTerminate;
    }

    struct Proposal {
        address proposer;
        address[] codeSequence;
        uint256 creationBlock;
        uint256 accept;
        uint256 refuse;
        address triggeringRules;
        address[] canTerminateAddresses;
        address[] validatorsAddresses;
        bool validationPassed;
        uint256 terminationBlock;
        bytes votingTokens;
    }

    struct ProposalConfiguration {
        address[] collections;
        uint256[] objectIds;
        uint256[] weights;
        address creationRules;
        address triggeringRules;
        address[] canTerminateAddresses;
        address[] validatorsAddresses;
    }

    function batchCreate(ProposalCodes[] calldata codeSequences) external returns(bytes32[] memory createdProposalIds);

    function list(bytes32[] calldata proposalIds) external view returns(Proposal[] memory);

    function votes(bytes32[] calldata proposalIds, address[] calldata voters, bytes32[][] calldata items) external view returns(uint256[][] memory accepts, uint256[][] memory refuses, uint256[][] memory toWithdraw);
    function weight(bytes32 code) external view returns(uint256);

    function vote(address erc20TokenAddress, bytes memory permitSignature, bytes32 proposalId, uint256 accept, uint256 refuse, address voter, bool alsoTerminate) external payable;
    function batchVote(bytes[] calldata data) external payable;

    function withdrawAll(bytes32[] memory proposalIds, address voterOrReceiver, bool afterTermination) external;

    function terminate(bytes32[] calldata proposalIds) external;

    function configuration() external view returns(ProposalConfiguration memory);
    function setConfiguration(ProposalConfiguration calldata newValue) external returns(ProposalConfiguration memory oldValue);

    function lastProposalId() external view returns(bytes32);

    function lastVoteBlock(address voter) external view returns (uint256);

    event ProposalCreated(address indexed proposer, address indexed code, bytes32 indexed proposalId);
    event ProposalWeight(bytes32 indexed proposalId, address indexed collection, uint256 indexed id, bytes32 key, uint256 weight);
    event ProposalTerminated(bytes32 indexed proposalId, bool result, bytes errorData);

    event Accept(bytes32 indexed proposalId, address indexed voter, bytes32 indexed item, uint256 amount);
    event MoveToAccept(bytes32 indexed proposalId, address indexed voter, bytes32 indexed item, uint256 amount);
    event RetireAccept(bytes32 indexed proposalId, address indexed voter, bytes32 indexed item, uint256 amount);

    event Refuse(bytes32 indexed proposalId, address indexed voter, bytes32 indexed item, uint256 amount);
    event MoveToRefuse(bytes32 indexed proposalId, address indexed voter, bytes32 indexed item, uint256 amount);
    event RetireRefuse(bytes32 indexed proposalId, address indexed voter, bytes32 indexed item, uint256 amount);
}

interface IProposalChecker {
    function check(address proposalsManagerAddress, bytes32 id, bytes calldata data, address from, address voter) external view returns(bool);
}

interface IExternalProposalsManagerCommands {
    function createProposalCodeSequence(bytes32 proposalId, IProposalsManager.ProposalCode[] memory codeSequenceInput, address sender) external returns (address[] memory codeSequence, IProposalsManager.ProposalConfiguration memory localConfiguration);
    function proposalCanBeFinalized(bytes32 proposalId, IProposalsManager.Proposal memory proposal, bool validationPassed, bool result) external view returns (bool);
    function isVotable(bytes32 proposalId, IProposalsManager.Proposal memory proposal, address from, address voter, bool voteOrWithtraw) external view returns (bytes memory response);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../../dynamicMetadata/model/IDynamicMetadataCapableElement.sol";

interface IFactory is IDynamicMetadataCapableElement {

    event Deployed(address indexed modelAddress, address indexed deployedAddress, address indexed deployer, bytes deployedLazyInitResponse);

    function modelAddress() external view returns(address);
    function setModelAddress(address newValue) external returns(address oldValue);

    function deployer(address deployedAddress) external view returns(address);

    function deploy(bytes calldata deployData) external payable returns(address deployedAddress, bytes memory deployedLazyInitResponse);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
pragma solidity >=0.7.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ILazyInitCapableElement is IERC165 {

    function lazyInit(bytes calldata lazyInitData) external returns(bytes memory initResponse);
    function initializer() external view returns(address);

    event Host(address indexed from, address indexed to);

    function host() external view returns(address);
    function setHost(address newValue) external returns(address oldValue);

    function subjectIsAuthorizedFor(address subject, address location, bytes4 selector, bytes calldata payload, uint256 value) external view returns(bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../../generic/model/ILazyInitCapableElement.sol";

interface IDynamicMetadataCapableElement is ILazyInitCapableElement {

    function uri() external view returns(string memory);
    function plainUri() external view returns(string memory);

    function setUri(string calldata newValue) external returns (string memory oldValue);

    function dynamicUriResolver() external view returns(address);
    function setDynamicUriResolver(address newValue) external returns(address oldValue);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @title IERC1155Views - An optional utility interface to improve the ERC-1155 Standard.
 * @dev This interface introduces some additional capabilities for ERC-1155 Tokens.
 */
interface IERC1155Views {

    /**
     * @dev Returns the total supply of the given token id
     * @param itemId the id of the token whose availability you want to know 
     */
    function totalSupply(uint256 itemId) external view returns (uint256);

    /**
     * @dev Returns the name of the given token id
     * @param itemId the id of the token whose name you want to know 
     */
    function name(uint256 itemId) external view returns (string memory);

    /**
     * @dev Returns the symbol of the given token id
     * @param itemId the id of the token whose symbol you want to know 
     */
    function symbol(uint256 itemId) external view returns (string memory);

    /**
     * @dev Returns the decimals of the given token id
     * @param itemId the id of the token whose decimals you want to know 
     */
    function decimals(uint256 itemId) external view returns (uint256);

    /**
     * @dev Returns the uri of the given token id
     * @param itemId the id of the token whose uri you want to know 
     */
    function uri(uint256 itemId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

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