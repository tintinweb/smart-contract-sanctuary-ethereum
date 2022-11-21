// SPDX-License-Identifier: MIT

/**
 * ---------------------- [ dbpower.com.hk ] ----------------------
 */


// File: @openzeppelin/[email protected]/utils/Address.sol


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

// File: @openzeppelin/[email protected]/utils/introspection/IERC165.sol


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

// File: @openzeppelin/[email protected]/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: @openzeppelin/[email protected]/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: @openzeppelin/[email protected]/security/ReentrancyGuard.sol


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

// File: @openzeppelin/[email protected]/utils/Context.sol


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

// File: @openzeppelin/[email protected]/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contract-erc1155-marketplace-20221018-a.sol







pragma solidity ^0.8.4;


interface IERC1155Ikasumi is IERC1155 {
    function creators(uint256 tokenId) external view returns (address);
    function burn(address account, uint256 id, uint256 value) external;
    function totalSupply(uint256 id) external view returns (uint256);
}

/**
 * @dev {ERC1155} Marketplace
 */
contract ERC1155YuzuInternal is Ownable {
    
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    /**
     * @dev initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(address owner, string memory name_, string memory symbol_) Ownable() {
        transferOwnership(owner);
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() external view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }
}

/**
 * @title ERC1155Cappuccino
 * ERC-721 Marketplace with tokens and royalties support
 */
contract ERC1155Cappuccino is ERC1155YuzuInternal, ReentrancyGuard {

    using Address for address;

    // admin address, the owner of the marketplace
    address public admin;

    // IERC20 token to be used for payments
    IERC20 public paymentToken;

    // IERC1155Ikasumi token to be used for trade
    IERC1155Ikasumi public erc1155Token;

    // commission rate is a value from 0 to 100
    uint256 public commissionRate;

    // royalties commission rate is a value from 0 to 100
    uint256 public royaltiesCommissionRate;
    
    // a sale object
    struct Sale {
        uint256 qty;    // qty for sale
        uint256 price;  // price 
        address user;   // seller
        address wallet; // seller wallet
    }

    // opened sales by tokenIds
    mapping(uint256 => Sale[]) public openSales;

    // length of the array
    mapping(uint256 => uint256) public openSalesLength;

    // a buy offer object
    struct Offer {
        uint256 qty;    // qty for buying
        uint256 price;  // buy price 
        address user;   // buyer
    }

    // opened offers by tokenIds
    mapping(uint256 => Offer[]) public openOffers;

    // length of the array
    mapping(uint256 => uint256) public openOffersLength;

    // a yield object
    struct Yield {
        uint256 id;     // nft id
        uint256 price;  // price
        uint256 qty;    // qty
    }

    // opened yield by tokenIds
    mapping(uint256 => Yield) public openYield;

    event Bid(        uint256 indexed tokenId, address indexed from,   uint256 queueId,     uint256 price);
    event Sell(       uint256 indexed tokenId, address indexed to,     uint256 queueId,     uint256 price);
    event Commission( uint256 indexed tokenId, address indexed from,   address indexed to,  uint256 value);
    event Royalty(    uint256 indexed tokenId, address indexed from,   address indexed to,  uint256 value);
    event Buy(        uint256 indexed tokenId, address indexed from,   address indexed to,  uint256 value);

    event CancelSale(uint256 indexed tokenId, uint256 index);
    event CancelBid(uint256 indexed tokenId, uint256 index);

    constructor(
        IERC20 _paymentToken, IERC1155Ikasumi _erc1155Token, address _owner, address _admin, uint256 _commissionRate, 
        uint256 _royaltiesCommissionRate, string memory name, string memory symbol) 
        ERC1155YuzuInternal(_owner, name, symbol)
    {
        require(_commissionRate + _royaltiesCommissionRate < 100, "Cappuccino: total commissions should be lower than 100");
        admin = _admin;
        commissionRate = _commissionRate;
        royaltiesCommissionRate = _royaltiesCommissionRate;
        paymentToken = _paymentToken;
        erc1155Token = _erc1155Token;
    }

    /**
     * Any user can sell X items at Y price each, valid ownership and qty of the sell will be handled by the UI
     * All selling options are shown as “Listings” in the UI
     * Any user can buy W items at Y price, of one listing, they cannot combine two listings in one transaction, given that W>0 and W<=Y
     * Restrictions:
     *    Limit the sell to owned items, the user cannot sell items do not have
     */
    
    function sell(uint256 tokenId, uint256 qty, uint256 price, address wallet) external {

        // Limit the sell to owned items, the user cannot sell items do not have
        require(erc1155Token.balanceOf(_msgSender(), tokenId) >= qty, "Cappuccino: you do not have enough tokens to sell");
        require(erc1155Token.isApprovedForAll(_msgSender(), address(this)), "Cappuccino: you do not approve tokens to sell");

        // add the selling option to openSales
        Sale memory sale = Sale(qty, price, _msgSender(), wallet);

        // An owner can add only one selling listing for one item at a time, new listings for one item will replace the old ones

        openSales[tokenId].push(sale);
        openSalesLength[tokenId] = openSales[tokenId].length;
        emit Sell(tokenId, _msgSender(), openSales[tokenId].length, price);

    }

    /**
     * Buy an NTF item, specifying qty to buy and index offer
     * Funds are transferred from the caller user directly, previous approval required
     */
    
    function buy(uint256 tokenId, uint256 index, uint256 qty) external nonReentrant {

        // validate user
        require(openSales[tokenId][index].user != _msgSender() , "Cappuccino: the user cannot buy his own offer");

        // transfer ownership
        // we need to call a transferFrom from this contract, which is the one with permission to sell the NFT
        callOptionalReturn(erc1155Token, abi.encodeWithSelector(erc1155Token.safeTransferFrom.selector, openSales[tokenId][index].user, _msgSender(), tokenId, qty, "0x"));

        /**
         * distribute funds between owner, creator and admin
         * This function will transfer the funds from the buyer, which must have previously approve the funds to the contract, to the beneficiaries of the sale
         * The "true" parameter at the end means: do a transferFrom
         */ 
        distributeFunds(qty * openSales[tokenId][index].price, _msgSender(), openSales[tokenId][index].wallet, tokenId, true);

        // substract items sold
        openSales[tokenId][index].qty -= qty;

        // remove the offer and reorder the array
        if (openSales[tokenId][index].qty == 0) {
            Sale memory sale = Sale(0, 0, address(0), address(0));
            openSales[tokenId][index] = sale;
        }

    }

    // cancel the sale
    function cancelSale(uint256 tokenId, uint256 index) external {

        // Only the original bidder can cancel his bids
        require(openSales[tokenId][index].user == _msgSender(), "Cappuccino: only the original seller can cancel his sales");

        // remove the sale
        Sale memory sale = Sale(0, 0, address(0), address(0));
        openSales[tokenId][index] = sale;

        emit CancelSale(tokenId, index);

    }

    function editSale(uint256 tokenId, uint256 index, uint256 qty, uint256 price, address wallet) external {

        // Only the original bidder can cancel his bids
        require(openSales[tokenId][index].user == _msgSender(), "Cappuccino: only the original seller can cancel his sales");

        // edit the sale
        Sale memory sale = Sale(qty, price, _msgSender(), wallet);
        openSales[tokenId][index] = sale;

    }

    /**
     * Any user can make an offer of X items at Y price each
     * Funds of the offer are stored on the contract
     * All offers are shown as “Offers” in the UI
     * Restrictions
     *    A buyer cannot add an offer bigger than the total supply
     */
    
    function bid(uint256 tokenId, uint256 qty, uint256 price) external nonReentrant {

        require(qty>0, "Cappuccino: qty has to be positive");
        require(price>0, "Cappuccino: price has to be positive");
        require(qty <= erc1155Token.totalSupply(tokenId), "Cappuccino: not enough items for sale");

        // record the offer
        Offer memory theBid = Offer(qty, price, _msgSender());

        openOffers[tokenId].push(theBid);
        openOffersLength[tokenId] = openOffers[tokenId].length;
        emit Bid(tokenId, _msgSender(), openOffers[tokenId].length, price);

    }

    // cancel the offer and return funds
    function cancelBid(uint256 tokenId, uint256 index) external nonReentrant {

        // Only the original bidder can cancel his bids
        require(openOffers[tokenId][index].user == _msgSender(), "Cappuccino: only the original bidder can cancel his bids");

        // remove the bid
        Offer memory theBid = Offer(0, 0, address(0));
        openOffers[tokenId][index] = theBid;

        emit CancelBid(tokenId, index);

    }

    function editBid(uint256 tokenId, uint256 index, uint256 qty, uint256 price) external nonReentrant {

        // Only the original bidder can cancel his bids
        require(openOffers[tokenId][index].user == _msgSender(), "Cappuccino: only the original bidder can cancel his bids");
        require(qty>0, "Cappuccino: qty has to be positive");
        require(price>0, "Cappuccino: price has to be positive");
        require(qty <= erc1155Token.totalSupply(tokenId), "Cappuccino: not enough items for sale");

        // edit the bid
        Offer memory theBid = Offer(qty, price, _msgSender());
        openOffers[tokenId][index] = theBid;

    }

    // owner accepts the bid and distribute the funds
    function acceptBid(uint256 tokenId, uint256 index, uint256 qty) external nonReentrant {

        // validate user
        require(openOffers[tokenId][index].user != _msgSender() , "Cappuccino: the user cannot accept his own bid");
        require(erc1155Token.isApprovedForAll(_msgSender(), address(this)), "Cappuccino: you do not approve tokens");

        // transfer item to bidder
        // we need to call a transferFrom from this contract, which is the one with permission to sell the NFT
        callOptionalReturn(erc1155Token, abi.encodeWithSelector(erc1155Token.safeTransferFrom.selector, _msgSender(), openOffers[tokenId][index].user, tokenId, qty, "0x"));

        /**
         * distribute funds between owner, creator and admin
         * This function will transfer the funds from the contract, which must have previously sent to the contract, to the beneficiaries of the sale
         * The "false" parameter at the end means: do a simple transfer
         */ 
        distributeFunds(qty * openOffers[tokenId][index].price, openOffers[tokenId][index].user, _msgSender(), tokenId, true);

        // substract items sold
        openOffers[tokenId][index].qty -= qty;

        // remove the offer and reorder the array
        if (openOffers[tokenId][index].qty == 0) {
            Offer memory theBid = Offer(0, 0, address(0));
            openOffers[tokenId][index] = theBid;
        }

    }

    function setYield(address from, uint256 tokenId, uint256 price) external nonReentrant {
        // validate user
        require(from != address(0), "Cappuccino: cannot zero address");
        require(tokenId > 0 , "Cappuccino: cannot zero tokenId");
        require(price > 0 , "Cappuccino: cannot zero price");
        uint256 qty = erc1155Token.totalSupply(tokenId);
        require(qty > 0 , "Cappuccino: cannot zero qty");

        uint256 total = qty * price;
        require(paymentToken.transferFrom(from, address(this), total), "Transfer failed.");

        Yield memory yield = Yield(tokenId, price, qty);
        openYield[tokenId] = yield;
    }

    function getYield(uint256 tokenId) external nonReentrant {
        // validate user
        require(tokenId > 0 , "Cappuccino: cannot zero id");
        uint256 qty = erc1155Token.balanceOf(msg.sender, tokenId);
        require(qty > 0 , "Cappuccino: cannot zero qty");
        require(openYield[tokenId].qty >= qty, "Cappuccino: cannot get yield more than fund quantity");
        uint256 total = qty * openYield[tokenId].price;
        require(paymentToken.balanceOf(address(this)) >= total, "Cappuccino: cannot get enoght yield");
        require(erc1155Token.isApprovedForAll(_msgSender(), address(this)), "Cappuccino: you do not approve tokens");

        erc1155Token.burn(msg.sender, tokenId, qty);
        require(paymentToken.transferFrom(address(this), msg.sender, total), "Transfer failed.");

        openYield[tokenId].qty = openYield[tokenId].qty - qty;
    }
    
    /**
     * do the funds distribution between owner, creator and admin
     * @param totalPrice the total value to distribute
     * @param from if useTransferFrom is true then the "from" is the origin of the funds, if false, then the "from" is only used for logs purposes
     * @param to is the owner of the token on sale / bid
     * @param tokenId is the token being sold
     * @param useTransferFrom if true the transfer will be made from to, if not, a simple transfer will be done from the contract to the beneficiaries
     */

    function distributeFunds(uint256 totalPrice, address from, address to, uint256 tokenId, bool useTransferFrom) internal {

        // calculate amounts
        uint256 amount4admin = totalPrice * commissionRate / 100;
        uint256 amount4creator = totalPrice * royaltiesCommissionRate / 100;
        uint256 amount4owner = totalPrice - amount4admin - amount4creator;

        // to owner
        if (useTransferFrom) {
            require(paymentToken.transferFrom(from, to, amount4owner), "Transfer failed.");
        } else {
            require(paymentToken.transfer(to, amount4owner), "Transfer failed.");
        }
        emit Buy(tokenId, from, to, amount4owner);

        // to creator
        if (amount4creator>0) {
            if (useTransferFrom) {
                require(paymentToken.transferFrom(from, erc1155Token.creators(tokenId), amount4creator), "Transfer failed.");
            } else {
                require(paymentToken.transfer(erc1155Token.creators(tokenId), amount4creator), "Transfer failed.");
            }
            emit Royalty(tokenId, from, erc1155Token.creators(tokenId), amount4creator);
        }

        // to admin
        if (amount4admin>0) {
            if (useTransferFrom) {
                require(paymentToken.transferFrom(from, admin, amount4admin), "Transfer failed.");
            } else {
                require(paymentToken.transfer(admin, amount4admin), "Transfer failed.");
            }
            emit Commission(tokenId, from, admin, amount4admin);
        }

    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC1155Ikasumi token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "Cappuccino: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "Cappuccino: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "Cappuccino: ERC20 operation did not succeed");
        }
    }

    // update contract fields
    function updateAdmin(address _admin, uint256 _commissionRate, uint256 _royaltiesCommissionRate, IERC20 _paymentToken, IERC1155Ikasumi _erc1155Token) external onlyOwner() {
        require(_commissionRate < 100, "Cappuccino: total commissions should be lower than 100");
        admin = _admin;
        commissionRate = _commissionRate;
        royaltiesCommissionRate = _royaltiesCommissionRate;
        paymentToken = _paymentToken;
        erc1155Token = _erc1155Token;
    }
    
}