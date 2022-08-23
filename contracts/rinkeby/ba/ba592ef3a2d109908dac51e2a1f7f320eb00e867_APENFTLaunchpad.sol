/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: UNLICENSED

// File: contracts/dependencies/openzeppelin/contracts/utils/Context.sol

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/dependencies/openzeppelin/contracts/access/Ownable.sol


pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: contracts/dependencies/openzeppelin/contracts/introspection/IERC165.sol


pragma solidity >=0.6.0 <0.8.0;

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

// File: contracts/dependencies/openzeppelin/contracts/token/ERC721/IERC721.sol


pragma solidity >=0.6.2 <0.8.0;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: contracts/dependencies/openzeppelin/contracts/token/ERC1155/IERC1155.sol


pragma solidity >=0.6.2 <0.8.0;

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// File: contracts/dependencies/openzeppelin/contracts/utils/ReentrancyGuard.sol


pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// File: contracts/dependencies/openzeppelin/contracts/utils/Pausable.sol


pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// File: contracts/launchpad/interface/ILaunchpadProxy.sol

pragma solidity >=0.5.0 <0.9.0;


interface ILaunchpadProxy {

    // proxy id
    function getProxyId() external pure returns (bytes4);

    // buy
    function launchpadBuy(
        address sender,
        bytes4 launchpadId,
        uint256 slotIdx,
        uint256 quantity,
        uint256[] calldata additional,
        bytes calldata data
    ) payable external returns (uint256);

    // open box
    function launchpadOpenBox(
        address sender,
        bytes4 launchpadId,
        uint256 slotIdx,
        address tokenAddr,
        uint256 tokenId,
        uint256 quantity,
        uint256[] calldata additional
    ) external;

    // do some operation
    function launchpadDoOperation(
        address sender,
        bytes4 launchpadId,
        uint256 slotIdx,
        address[] calldata addrData,
        uint256[] calldata intData,
        bytes[] calldata byteData
    ) payable external;

    // get launchpad info
    function getLaunchpadInfo(bytes4 launchpadId, uint256[] calldata params)
        external
        view
        returns (
            bool[] memory boolData,
            uint256[] memory intData,
            address[] memory addressData,
            bytes[] memory bytesData);


    // get launchpad slot info
    function getLaunchpadSlotInfo(address sender, bytes4 launchpadId, uint256 slotIdx)
        external
        view
        returns (
            bool[] memory boolData,
            uint256[] memory intData,
            address[] memory addressData,
            bytes4[] memory bytesData);


    // get account info
    function getAccountInfoInLaunchpad(
        address sender,
        bytes4 launchpadId,
        uint256 slotIdx,
        uint256 quantity
    )
        external
        view
        returns (
            bool[] memory boolData,
            uint256[] memory intData,
            bytes[] memory byteData);


    // is in white list
    function isInWhiteList(
        bytes4 launchpadId,
        uint256 slotIdx,
        address[] calldata accounts,
        uint256[] calldata offChainMaxBuy,
        bytes[] calldata offChainSign
    ) external view returns (uint8[] memory wln);

}

// File: contracts/launchpad/library/Errors.sol

pragma solidity >=0.5.0 <0.9.0;

library Errors {

    string public constant OK = '0'; // 'ok'
    string public constant PROXY_ID_NOT_EXIST = '1'; // 'proxy not exist'
    string public constant PROXY_ID_ALREADY_EXIST = '2'; // 'proxy id already exists'
    string public constant LPAD_ONLY_COLLABORATOR_OWNER = '3'; // 'only collaborator,owner can call'
    string public constant LPAD_ONLY_CONTROLLER_COLLABORATOR_OWNER = '4'; //  'only controller,collaborator,owner'
    string public constant LPAD_ONLY_AUTHORITIES_ADDRESS = '5'; // 'only authorities can call'
    string public constant TRANSFER_ETH_FAILED = '6'; // 'transfer eth failed'
    string public constant SENDER_MUST_TX_CALLER = '7'; // 'sender must transaction caller'

    string public constant LPAD_INVALID_ID  = '10';  // 'launchpad invalid id'
    string public constant LPAD_ID_EXISTS   = '11';  // 'launchpadId exists'
    string public constant LPAD_RECEIPT_ADDRESS_INVALID = '12'; // 'receipt must be valid address'
    string public constant LPAD_REFERRAL_FEE_PCT_LIMIT = '13'; // 'referral fee upper limit'
    string public constant LPAD_RECEIPT_MUST_NOT_CONTRACT = '14'; // 'receipt can't be contract address'
    string public constant LPAD_NOT_ENABLE = '15'; // 'launchpad not enable'
    string public constant LPAD_TRANSFER_TO_RECEIPT_FAIL = '16'; // 'transfer to receipt address failed'
    string public constant LPAD_TRANSFER_TO_REFERRAL_FAIL = '17'; // 'transfer to referral address failed'
    string public constant LPAD_TRANSFER_BACK_TO_SENDER_FAIL = '18'; // 'transfer back to sender address failed'
    string public constant LPAD_INPUT_ARRAY_LEN_NOT_MATCH = '19'; // 'input array len not match'
    string public constant LPAD_FEES_PERCENT_INVALID = '20'; // 'fees total percent is not 100%'
    string public constant LPAD_PARAM_LOCKED = '21'; // 'launchpad param locked'
    string public constant LPAD_TRANSFER_TO_LPAD_PROXY_FAIL = '22'; // 'transfer to lpad proxy failed'
    string public constant LPAD_DEFAULT_FEE_RECIPIENT_CHECK = '23'; // 'default fee recipient percent'

    string public constant LPAD_SIMULATE_BUY_OK = '28'; // 'simulate buy ok'
    string public constant LPAD_SIMULATE_OPEN_OK = '29'; // 'simulate open ok'

    string public constant LPAD_SLOT_IDX_INVALID = '30'; // 'launchpad slot idx invalid'
    string public constant LPAD_SLOT_MAX_SUPPLY_INVALID = '31'; // 'max supply invalid'
    string public constant LPAD_SLOT_SALE_QUANTITY = '32'; // 'initial sale quantity must 0'
    string public constant LPAD_SLOT_TARGET_CONTRACT_INVALID = '33'; // "slot target contract address not valid"
    string public constant LPAD_SLOT_ABI_ARRAY_LEN = '34'; // "invalid abi selector array not equal max"
    string public constant LPAD_SLOT_MAX_BUY_QTY_INVALID = '35'; // "max buy qty invalid"
    string public constant LPAD_SLOT_FLAGS_ARRAY_LEN = '36'; // 'flag array len not equal max'
    string public constant LPAD_SLOT_TOKEN_ADDRESS_INVALID = '37';  // 'token must be valid address'
    string public constant LPAD_SLOT_BUY_DISABLE = '38'; // 'launchpad buy disable now'
    string public constant LPAD_SLOT_BUY_FROM_CONTRACT_NOT_ALLOWED = '39'; // 'buy from contract address not allowed)
    string public constant LPAD_SLOT_SALE_NOT_START = '40'; // 'sale not start yet'
    string public constant LPAD_SLOT_MAX_BUY_QTY_PER_TX_LIMIT = '41'; // 'max buy quantity one transaction limit'
    string public constant LPAD_SLOT_QTY_NOT_ENOUGH_TO_BUY = '42'; // 'quantity not enough to buy'
    string public constant LPAD_SLOT_PAYMENT_NOT_ENOUGH = '43'; // "payment not enough"
    string public constant LPAD_SLOT_PAYMENT_ALLOWANCE_NOT_ENOUGH = '44'; // 'allowance not enough'
    string public constant LPAD_SLOT_ACCOUNT_MAX_BUY_LIMIT = '45'; // "account max buy num limit"
    string public constant LPAD_SLOT_ACCOUNT_BUY_INTERVAL_LIMIT = '46'; // 'account buy interval limit'
    string public constant LPAD_SLOT_ACCOUNT_NOT_IN_WHITELIST = '47'; // 'not in whitelist'
    string public constant LPAD_SLOT_OPENBOX_DISABLE = '48'; // 'launchpad openbox disable now'
    string public constant LPAD_SLOT_OPENBOX_FROM_CONTRACT_NOT_ALLOWED = '49'; // 'not allowed to open from contract address'
    string public constant LPAD_SLOT_ABI_BUY_SELECTOR_INVALID = '50'; // 'buy selector invalid '
    string public constant LPAD_SLOT_ABI_OPENBOX_SELECTOR_INVALID = '51'; // 'openbox selector invalid '
    string public constant LPAD_SLOT_SALE_START_TIME_INVALID = '52'; // 'sale time invalid'
    string public constant LPAD_SLOT_OPENBOX_TIME_INVALID = '53'; // 'openbox time invalid'
    string public constant LPAD_SLOT_PRICE_INVALID = '54'; // 'price must > 0'
    string public constant LPAD_SLOT_CALL_BUY_CONTRACT_FAILED = '55'; // 'call buy contract fail'
    string public constant LPAD_SLOT_CALL_OPEN_CONTRACT_FAILED = '56'; // 'call open contract fail'
    string public constant LPAD_SLOT_CALL_0X_ERC20_PROXY_FAILED = '57'; // 'call 0x erc20 proxy fail'
    string public constant LPAD_SLOT_0X_ERC20_PROXY_INVALID = '58'; // '0x erc20 asset proxy invalid'
    string public constant LPAD_SLOT_ONLY_OPENBOX_WHEN_SOLD_OUT = '59'; // 'only can open box when sold out all'
    string public constant LPAD_SLOT_ERC20_BLC_NOT_ENOUGH = '60'; // "erc20 balance not enough"
    string public constant LPAD_SLOT_PAY_VALUE_NOT_ENOUGH = '61'; // "eth send value not enough"
    string public constant LPAD_SLOT_PAY_VALUE_NOT_NEED = '62'; // 'eth send value not need'
    string public constant LPAD_SLOT_PAY_VALUE_UPPER_NEED = '63'; // 'eth send value upper need value'
    string public constant LPAD_SLOT_OPENBOX_NOT_SUPPORT = '64'; // 'openbox not support'
    string public constant LPAD_SLOT_ERC20_TRANSFER_FAILED = '65'; // 'call erc20 transfer fail'
    string public constant LPAD_SLOT_OPEN_NUM_INIT = '66'; // 'initial open number must 0'
    string public constant LPAD_SLOT_ABI_NOT_FOUND = '67'; // 'not found abi to encode'
    string public constant LPAD_SLOT_SALE_END = '68'; // 'sale end'
    string public constant LPAD_SLOT_SALE_END_TIME_INVALID = '69'; // 'sale end time invalid'
    string public constant LPAD_SLOT_WHITELIST_BUY_NUM_LIMIT = '70'; // 'whitelist buy number limit'
    string public constant LPAD_CONTROLLER_NO_PERMISSION = '71'; // 'controller no permission'
    string public constant LPAD_SLOT_WHITELIST_SALE_NOT_START = '72'; // 'whitelist sale not start yet'
    string public constant LPAD_NOT_VALID_SIGNER = '73'; // 'not valid signer'
    string public constant LPAD_SLOT_WHITELIST_TIME_INVALID = '74'; // white list time invalid
    string public constant LPAD_INVALID_WHITELIST_SIGNATURE_LEN = '75'; // invalid whitelist signature length

    string public constant LPAD_SEPARATOR = ':'; // seprator :
}

// File: contracts/launchpad/APENFTLaunchpad.sol

pragma solidity >=0.5.0 <0.9.0;








// APENFT Launchpad
contract APENFTLaunchpad is Ownable,ReentrancyGuard,Pausable {

    // buy event
    event LaunchpadBuyEvt(bytes4 indexed proxyId, bytes4 launchpadId, uint256 slotIdx,
        uint256 quantity, uint256 payValue, uint256[] additional, bytes data);

    // openbox event
    event LaunchpadBoxOpenEvt(bytes4 indexed proxyId, bytes4 launchpadId, uint256 slotIdx,
        address tokenAddr, uint256 tokenId, uint256 quantity, uint256[] additional);

    // do operation event
    event LaunchpadDoOperationEvt(bytes4 indexed proxyId, bytes4 launchpadId, uint256 slotIdx,
        address[] addrData, uint256[] intData, bytes[] byteData);

    // register proxy address
    event ProxyRegistered(bytes4 indexed launchpadProxyId, address indexed proxyAddress);

    // launchpad proxy for execute function
    mapping (bytes4 => address) public launchpadRegistry;

    // pause
    function pause() public onlyOwner {
        _pause();
    }

    // unpause
    function unpause() public onlyOwner {
        _unpause();
    }

    // register proxy
    function registerLaunchpadProxy(address proxy) external onlyOwner {
        bytes4 registryProxyId = ILaunchpadProxy(proxy).getProxyId();
        require(launchpadRegistry[registryProxyId] == address(0), Errors.PROXY_ID_ALREADY_EXIST);
        launchpadRegistry[registryProxyId] = proxy;
        emit ProxyRegistered(registryProxyId, proxy);
    }

    // get proxy address
    function getRegistry(bytes4 proxyId) external view returns (address) {
        return launchpadRegistry[proxyId];
    }

    // buy nft from this launchpad
    function launchpadBuy(
        bytes4 proxyId,
        bytes4 launchpadId,
        uint256 slotIdx,
        uint256 quantity,
        uint256[] calldata additional,
        bytes calldata data
    )
        external
        payable
        nonReentrant
        whenNotPaused
    {
        address proxy = launchpadRegistry[proxyId];
        require(proxy != address(0), Errors.PROXY_ID_NOT_EXIST);
        uint256 paymentValue = ILaunchpadProxy(proxy).launchpadBuy{value: msg.value}(
                _msgSender(),
                launchpadId,
                slotIdx,
                quantity,
                additional,
                data);
        emit LaunchpadBuyEvt(proxyId, launchpadId, slotIdx, quantity, paymentValue, additional, data);
    }

    // open box that buy from this launchpad
    function launchpadOpenBox(
        bytes4 proxyId,
        bytes4 launchpadId,
        uint256 slotIdx,
        address tokenAddr,
        uint256 tokenId,
        uint256 quantity,
        uint256[] calldata additional
    ) external nonReentrant whenNotPaused {
        address proxy = launchpadRegistry[proxyId];
        require(proxy != address(0), Errors.PROXY_ID_NOT_EXIST);
        ILaunchpadProxy(proxy).launchpadOpenBox(_msgSender(), launchpadId, slotIdx, tokenAddr, tokenId, quantity, additional);
        emit LaunchpadBoxOpenEvt(proxyId, launchpadId, slotIdx, tokenAddr, tokenId, quantity, additional);
    }

    // do some operation
    function launchpadDoOperation(
        bytes4 proxyId,
        bytes4 launchpadId,
        uint256 slotIdx,
        address[] calldata addrData,
        uint256[] calldata intData,
        bytes[] calldata byteData
    ) external payable nonReentrant whenNotPaused {
        address proxy = launchpadRegistry[proxyId];
        require(proxy != address(0), Errors.PROXY_ID_NOT_EXIST);
        ILaunchpadProxy(proxy).launchpadDoOperation{value: msg.value}(_msgSender(), launchpadId, slotIdx, addrData, intData, byteData);
        emit LaunchpadDoOperationEvt(proxyId, launchpadId, slotIdx, addrData, intData, byteData);
    }

    // get launchpad info
    function getLaunchpadInfo(bytes4 proxyId, bytes4 launchpadId, uint256[] calldata params)
      external view returns (
        bool[] memory boolData,
        uint256[] memory intData,
        address[] memory addressData,
        bytes[] memory bytesData
    ) {
        address proxy = launchpadRegistry[proxyId];
        require(proxy != address(0), Errors.PROXY_ID_NOT_EXIST);
        return ILaunchpadProxy(proxy).getLaunchpadInfo(launchpadId, params);
    }

    // get launchpad slot info
    function getLaunchpadSlotInfo(bytes4 proxyId, bytes4 launchpadId, uint256 slotIdx)
      external view returns (
        bool[] memory boolData,
        uint256[] memory intData,
        address[] memory addressData,
        bytes4[] memory bytesData
    ) {
        address proxy = launchpadRegistry[proxyId];
        require(proxy != address(0), Errors.PROXY_ID_NOT_EXIST);
        return ILaunchpadProxy(proxy).getLaunchpadSlotInfo(_msgSender(), launchpadId, slotIdx);
    }

    // get account info related to the launchpad
    function getAccountInfoInLaunchpad(
        bytes4 proxyId,
        bytes4 launchpadId,
        uint256 slotIdx,
        uint256 quantity
    ) external view returns (
        bool[] memory boolData,
        uint256[] memory intData,
        bytes[] memory byteData
    ) {
        address proxy = launchpadRegistry[proxyId];
        require(proxy != address(0), Errors.PROXY_ID_NOT_EXIST);
        return ILaunchpadProxy(proxy).getAccountInfoInLaunchpad( _msgSender(), launchpadId, slotIdx, quantity);
    }

    function isInWhiteList(
        bytes4 proxyId,
        bytes4 launchpadId,
        uint256 slotIdx,
        address[] calldata accounts,
        uint256[] calldata offChainMaxBuy,
        bytes[] calldata offChainSign
    ) external view returns (uint8[] memory wln) {
        address proxy = launchpadRegistry[proxyId];
        require(proxy != address(0), Errors.PROXY_ID_NOT_EXIST);
        return ILaunchpadProxy(proxy).isInWhiteList(launchpadId, slotIdx, accounts, offChainMaxBuy, offChainSign);
    }

    // Emergency function: In case any ETH get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueETH(address recipient) onlyOwner external {
        uint256 _amount = address(this).balance;
        (bool success, ) = recipient.call{value: _amount}('');
        require(success, Errors.TRANSFER_ETH_FAILED);
    }

    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset, address recipient) onlyOwner external {
        IERC20(asset).transfer(recipient, IERC20(asset).balanceOf(address(this)));
    }

    // Emergency function: In case any ERC721 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC721(address asset, uint256[] calldata ids, address recipient) onlyOwner external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(asset).transferFrom(address(this), recipient, ids[i]);
        }
    }

    // Emergency function: In case any ERC1155 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC1155(address asset, uint256[] calldata ids, uint256[] calldata amounts, address recipient) onlyOwner external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC1155(asset).safeTransferFrom(address(this), recipient, ids[i], amounts[i], "");
        }
    }

}