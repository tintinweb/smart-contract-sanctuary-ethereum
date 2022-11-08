// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IBridge.sol";

/// @title ERC721 Peg contract on ethereum
/// @author Root Network
/// @notice Provides an Eth/Root network ERC721/RN721 peg
///  - depositing: lock ERC721 tokens to redeem Root network RN721 tokens 1:1
///  - withdrawing: burn or lock RN721 to redeem ERC721 tokens 1:1
contract ERC721Peg is Ownable, ERC721Holder, IBridgeReceiver, ERC165 {

    uint8 constant MAX_BRIDGABLE_CONTRACT_ADDRESSES = 10;
    uint8 constant MAX_BRIDGABLE_CONTRACT_TOKENS = 50;

    // whether the peg is accepting deposits
    bool public depositsActive;
    // whether the peg is accepting withdrawals
    bool public withdrawalsActive;
    // whether the peg can forward data sent from erc721 calls
    bool public erc721CallForwardingActive;
    //  Bridge contract address
    IBridge public bridge;
    // the (pseudo) pallet address this contract is paried with on root
    address public palletAddress = address(0x6D6F646c726e2F6E667470670000000000000000);

    event DepositActiveStatus(bool indexed active);
    event WithdrawalActiveStatus(bool indexed active);
    event ERC721Called(address indexed token, bytes input, bytes data);
    event ERC721CallForwardingActiveStatus(bool indexed active);
    event BridgeAddressUpdated(address indexed bridge);
    event PalletAddressUpdated(address indexed palletAddress);
    event Deposit(address indexed _address, address[] indexed tokenAddresses, uint256[][] indexed tokenIds, address destination);
    event Withdraw(address indexed _address, address[] indexed tokenAddresses, uint256[][] indexed tokenIds);
    event AdminWithdraw(address indexed _address, address[] indexed tokenAddresses, uint256[][] indexed tokenIds);

    constructor(IBridge _bridge) {
        bridge = _bridge;
    }

    /// @notice Deposit token ids of erc721 NFTs.
    /// @notice The pegged version of the erc721 NFTs will be claim-able on Root network.
    /// @param _tokenAddresses The addresses of the erc721 NFTs to deposit
    /// @param _tokenIds The ids of the erc721 NFTs to deposit
    /// @param _destination The address to send the pegged ERC721 tokens to on Root network
    function deposit(address[] calldata _tokenAddresses, uint256[][] calldata _tokenIds, address _destination) payable external {
        require(depositsActive, "ERC721Peg: deposits paused");
        require(_tokenAddresses.length == _tokenIds.length, "ERC721Peg: tokenAddresses and tokenIds must be same length");
        require(_tokenAddresses.length <= MAX_BRIDGABLE_CONTRACT_ADDRESSES, "ERC721Peg: too many token addresses");
        require(msg.value >= bridge.sendMessageFee(), "ERC721Peg: insufficient bridge fee");

        // send NFTs to this contract
        for (uint256 i = 0; i < _tokenAddresses.length; ++i) {
            address tokenAddress = _tokenAddresses[i];
            uint256[] memory tokenIds = _tokenIds[i];
            require(tokenIds.length <= MAX_BRIDGABLE_CONTRACT_TOKENS, "ERC721Peg: too many token ids");
            for (uint256 j = 0; j < tokenIds.length; j++) {
                uint256 tokenId = tokenIds[j];
                require(tokenId < type(uint32).max, "ERC721Peg: tokenId too large");
                IERC721(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId);
            }
        }

        emit Deposit(msg.sender, _tokenAddresses, _tokenIds, _destination);

        // send message to bridge
        bytes memory message = abi.encode(1, _tokenAddresses, _tokenIds, _destination); // msg type 1 is deposit
        bridge.sendMessage{ value: msg.value }(palletAddress, message);
    }

    function onMessageReceived(address _source, bytes calldata _message) external override {
        // only accept calls from the bridge contract
        require(msg.sender == address(bridge), "ERC721Peg: only bridge can call");
        // only accept messages from the peg pallet
        require(_source == palletAddress, "ERC721Peg: source must be peg pallet address");

        (address[] memory tokenAddresses, uint256[][] memory tokenIds, address recipient) = abi.decode(_message, (address[], uint256[][], address));
        _withdraw(tokenAddresses, tokenIds, recipient);
    }

    /// @notice Withdraw tokens from this contract
    /// @notice Requires signatures from a threshold of current Root network validators.
    function _withdraw(address[] memory _tokenAddresses, uint256[][] memory _tokenIds, address _recipient) internal {
        require(withdrawalsActive, "ERC721Peg: withdrawals paused");
        require(_tokenAddresses.length == _tokenIds.length, "ERC721Peg: tokenAddresses and tokenIds must be same length");

        // send NFTs to user
        for (uint256 i = 0; i < _tokenAddresses.length; ++i) {
            address tokenAddress = _tokenAddresses[i];
            uint256[] memory tokenIds = _tokenIds[i];
            for (uint256 j = 0; j < tokenIds.length; j++) {
                IERC721(tokenAddress).safeTransferFrom(address(this), _recipient, tokenIds[j]);
            }
        }

        emit Withdraw(_recipient, _tokenAddresses, _tokenIds);
    }

    /// @notice Calls a function on the ERC721 contract and forwards the result to the bridge as a message
    function callERC721(address _tokenAddress, bytes calldata _input) external payable {
        require(erc721CallForwardingActive, "ERC721Peg: erc721 call forwarding paused");
        require(msg.value >= bridge.sendMessageFee(), "ERC721Peg: insufficient bridge fee");

        (bool success, bytes memory data) = _tokenAddress.staticcall(_input);
        require(success, "ERC721Peg: ERC721 call failed");

        emit ERC721Called(_tokenAddress, _input, data);

        // send message to bridge
        bytes memory message = abi.encode(2, _tokenAddress, _input, data); // msg type 2 is call erc721
        bridge.sendMessage{ value: msg.value }(palletAddress, message);
    }

    /// @dev See {IERC165-supportsInterface}. Docs: https://docs.openzeppelin.com/contracts/4.x/api/utils#IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IBridgeReceiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // ============================================================================================================= //
    // ============================================== Admin functions ============================================== //
    // ============================================================================================================= //

    function setDepositsActive(bool _active) external onlyOwner {
        depositsActive = _active;
        emit DepositActiveStatus(_active);
    }

    function setWithdrawalsActive(bool _active) external onlyOwner {
        withdrawalsActive = _active;
        emit WithdrawalActiveStatus(_active);
    }

    function setERC721CallForwardingActive(bool _active) external onlyOwner {
        erc721CallForwardingActive = _active;
        emit ERC721CallForwardingActiveStatus(_active);
    }

    function setBridgeAddress(IBridge _bridge) external onlyOwner {
        bridge = _bridge;
        emit BridgeAddressUpdated(address(_bridge));
    }

    function setPalletAddress(address _palletAddress) external onlyOwner {
        palletAddress = _palletAddress;
        emit PalletAddressUpdated(_palletAddress);
    }

    function adminEmergencyWithdraw(address[] memory _tokenAddresses, uint256[][] memory _tokenIds, address _recipient) external onlyOwner {
        _withdraw(_tokenAddresses, _tokenIds, _recipient);
        emit AdminWithdraw(_recipient, _tokenAddresses, _tokenIds);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

// Proof of a witnessed event by validators
struct EventProof {
    // The Id (nonce) of the event
    uint256 eventId;
    // The validator set Id which witnessed the event
    uint32 validatorSetId;
    // v,r,s are sparse arrays expected to align w public key in 'validators'
    // i.e. v[i], r[i], s[i] matches the i-th validator[i]
    // v part of validator signatures
    uint8[] v;
    // r part of validator signatures
    bytes32[] r;
    // s part of validator signatures
    bytes32[] s;
    // The validator addresses
    address[] validators;
}

interface IBridge {
    // A sent message event
    event SendMessage(uint messageId, address source, address destination, bytes message, uint256 fee);
    // Receive a bridge message from the remote chain
    function receiveMessage(address source, address destination, bytes calldata message, EventProof calldata proof) external payable;
    // Send a bridge message to the remote chain
    function sendMessage(address destination, bytes calldata message) external payable;
    // Send message fee - used by sendMessage caller to obtain required fee for sendMessage
    function sendMessageFee() external view returns (uint256);
}

interface IBridgeReceiver {
    // Handle a bridge message received from the remote chain
    // It is guaranteed to be valid
    function onMessageReceived(address source, bytes calldata message) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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