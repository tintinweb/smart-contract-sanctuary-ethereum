/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]


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
interface IERC165Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/interfaces/[email protected]


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC1155/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}


// File contracts/interfaces/IFayreSharedCollection721.sol


pragma solidity 0.8.9;

interface IFayreSharedCollection721 {
    function mint(address recipient, string memory tokenURI) external returns(uint256);
}


// File contracts/interfaces/IFayreSharedCollection1155.sol


pragma solidity 0.8.9;

interface IFayreSharedCollection1155 {
    function mint(address recipient, string memory tokenURI, uint256 amount) external returns(uint256);
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts-upgradeable/interfaces/[email protected]


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


// File contracts/interfaces/IFayreSubscription721.sol


pragma solidity 0.8.9;
interface IFayreSubscription721 is IERC721EnumerableUpgradeable {
    struct SubscriptionData {
        uint256 expiration;
        uint256 volume;
    }

    function decreaseSubscriptionVolume(uint256 tokenId, uint256 newVolume) external;

    function getSubscriptionData(uint256 tokenId) external view returns(SubscriptionData memory);
}


// File contracts/FayreMarketplace.sol


pragma solidity 0.8.9;
contract FayreMarketplace is OwnableUpgradeable {
    /**
        E#1: ERC721 has no amount
        E#2: ERC1155 needs amount
        E#3: must send liquidity
        E#4: insufficient funds for minting
        E#5: unable to refund extra liquidity
        E#6: unable to send liquidity to treasury
        E#7: only the owner of the sale can create his own sale
        E#8: sale not found
        E#9: sale amount not specified
        E#10: sale expiration not specified
        E#11: a sale is already active
        E#12: cannot finalize your sale
        E#13: salelist to finalize not found
        E#14: salelist expired
        E#15: asset type not supported
        E#16: unable to send liquidity to sale owner
        E#17: not enough liquidity
        E#18: unable to send liquidity to creator
    */

    enum AssetType {
        LIQUIDITY,
        ERC20,
        ERC721,
        ERC1155
    }

    enum SaleType {
        FIXEDPRICE,
        ENGLISHAUCTION,
        DUTCHAUCTION
    }

    struct SaleList {
        address owner;
        SaleType saleType;
        uint256 tokenAmount;
        uint256 saleAmount;
        uint256 start;
        uint256 expiration;
    }

    struct SaleBid {
        address bidder;
        uint256 amount;
    }

    struct TokenData {
        SaleList[] saleLists;
        SaleBid[] saleBids;
        address creator;
        uint256 royaltiesPct;
    }

    event Mint(address indexed owner, AssetType indexed assetType, uint256 indexed tokenId, uint256 amount, uint256 royaltiesPct, string tokenURI);
    event Sale(address indexed collectionAddress, uint256 indexed tokenId, address indexed owner, SaleList saleList);
    event CancelSale(address indexed collectionAddress, uint256 indexed tokenId, address indexed owner, SaleList saleList);
    event FinalizeSale(address indexed collectionAddress, uint256 indexed tokenId, address indexed buyer, SaleList saleList);
    
    address public fayreSharedCollection721;
    address public fayreSharedCollection1155;
    address public oracleDataFeed;
    uint256 public mintFeeUSD;
    uint256 public tradeFeePct;
    address public treasuryAddress;

    mapping(address => mapping(uint256 => TokenData)) private _tokensData;

    function setFayreSharedCollection721(address newFayreSharedCollection721) external onlyOwner {
        fayreSharedCollection721 = newFayreSharedCollection721;
    }

    function setFayreSharedCollection1155(address newFayreSharedCollection1155) external onlyOwner {
        fayreSharedCollection1155 = newFayreSharedCollection1155;
    }

    function setOracleDataFeedAddress(address newOracleDataFeed) external onlyOwner {
        oracleDataFeed = newOracleDataFeed;
    }

    function setMintFee(uint256 newMintFeeUSD) external onlyOwner {
        mintFeeUSD = newMintFeeUSD;
    }

    function setTradeFee(uint256 newTradeFeePct) external onlyOwner {
        tradeFeePct = newTradeFeePct;
    }

    function setTreasury(address newTreasuryAddress) external onlyOwner {
        treasuryAddress = newTreasuryAddress;
    }

    function mint(AssetType assetType, string memory tokenURI, uint256 amount, uint256 royaltiesPct) external payable returns(uint256) {
        require(msg.value > 0, "E#3");

        (, int256 ethUSDPrice, , , ) = AggregatorV3Interface(oracleDataFeed).latestRoundData();

        uint8 oracleDataDecimals = AggregatorV3Interface(oracleDataFeed).decimals();

        uint256 paidUSDAmount = (msg.value * uint256(ethUSDPrice)) / (10 ** oracleDataDecimals);

        require(paidUSDAmount >= mintFeeUSD, "E#4");

        uint256 valueToRefund = 0;

        if (paidUSDAmount - mintFeeUSD > 0) {
            valueToRefund = ((paidUSDAmount - mintFeeUSD) * (10 ** oracleDataDecimals)) / uint256(ethUSDPrice);
            
            (bool refundSuccess, ) = msg.sender.call{value: valueToRefund }("");

            require(refundSuccess, "E#5");
        }

        _sendAssetToTreasury(AssetType.LIQUIDITY, msg.value - valueToRefund);

        uint256 tokenId = 0;

        if (assetType == AssetType.ERC721) {
            require(amount == 0, "E#1");

            tokenId = IFayreSharedCollection721(fayreSharedCollection721).mint(msg.sender, tokenURI);

            _tokensData[fayreSharedCollection721][tokenId].creator = msg.sender;
            _tokensData[fayreSharedCollection721][tokenId].royaltiesPct = royaltiesPct;
        } else {
            require(amount > 0, "E#2");

            tokenId = IFayreSharedCollection1155(fayreSharedCollection1155).mint(msg.sender, tokenURI, amount);

            _tokensData[fayreSharedCollection1155][tokenId].creator = msg.sender;
            _tokensData[fayreSharedCollection1155][tokenId].royaltiesPct = royaltiesPct;
        }

        emit Mint(msg.sender, assetType, tokenId, amount, royaltiesPct, tokenURI);

        return tokenId;
    }

    function putOnSale(address collectionAddress, uint256 tokenId, SaleList memory saleList) external { 
        require(saleList.owner == msg.sender, "E#7");

        SaleList[] storage saleLists = _tokensData[collectionAddress][tokenId].saleLists;

        for (uint256 i = 0; i < saleLists.length; i++)
            if (saleLists[i].owner == msg.sender && saleLists[i].expiration > block.timestamp)
                revert("E#11");

        AssetType collectionAssetType = _getContractAssetType(collectionAddress);

        if (collectionAssetType == AssetType.ERC721) {
            require(saleList.tokenAmount == 0, "E#1");
        } 
        else if (collectionAssetType == AssetType.ERC1155) {
            require(saleList.tokenAmount > 0, "E#2");
        }

        require(saleList.saleAmount > 0, "E#9");
        require(saleList.expiration > 0, "E#10");

        saleList.start = block.timestamp;
        saleList.expiration = saleList.start + saleList.expiration;

        _tokensData[collectionAddress][tokenId].saleLists.push(saleList);

        emit Sale(collectionAddress, tokenId, msg.sender, saleList);
    }

    function cancelSale(address collectionAddress, uint256 tokenId) external {
        SaleList[] storage saleLists = _tokensData[collectionAddress][tokenId].saleLists;

        uint256 indexToDelete = type(uint256).max;

        SaleList memory toDeleteSaleList;

        for (uint256 i = 0; i < saleLists.length; i++)
            if (saleLists[i].owner == msg.sender){
                toDeleteSaleList = saleLists[i];

                indexToDelete = i;
            }

        require(indexToDelete != type(uint256).max, "E#8");

        _deleteFromSaleLists(saleLists, indexToDelete);

        emit CancelSale(collectionAddress, tokenId, msg.sender, toDeleteSaleList);
    }

    function finalizeSaleList(address collectionAddress, uint256 tokenId, address owner) external payable {
        require(owner != msg.sender, "E#12");
        require(msg.value > 0, "E#3");

        SaleList[] storage saleLists = _tokensData[collectionAddress][tokenId].saleLists;

        SaleList memory toFinalizeSaleList;

        bool safeListToFinalizeFound;

        for (uint256 i = 0; i < saleLists.length; i++)
            if (saleLists[i].owner == owner) {
                toFinalizeSaleList = saleLists[i];

                safeListToFinalizeFound = true;
            }
        
        require(safeListToFinalizeFound, "E#13");
        require(toFinalizeSaleList.expiration > 0, "E#14");
        require(msg.value >= toFinalizeSaleList.saleAmount, "E#17");

        toFinalizeSaleList.expiration = 0;

        uint256 saleFee = (toFinalizeSaleList.saleAmount * tradeFeePct) / 10 ** 20;

        uint256 creatorRoyalties = 0;

        if (_tokensData[collectionAddress][tokenId].royaltiesPct > 0)
            creatorRoyalties = (toFinalizeSaleList.saleAmount * _tokensData[collectionAddress][tokenId].royaltiesPct) / 10 ** 20;

        (bool liquiditySendToOwnerSuccess, ) = toFinalizeSaleList.owner.call{value: toFinalizeSaleList.saleAmount - saleFee - creatorRoyalties }("");

        require(liquiditySendToOwnerSuccess, "E#16");

        if (creatorRoyalties > 0) {
            (bool liquiditySendToCreatorSuccess, ) = _tokensData[collectionAddress][tokenId].creator.call{value: creatorRoyalties }("");

            require(liquiditySendToCreatorSuccess, "E#18");
        }

        _sendAssetToTreasury(AssetType.LIQUIDITY, saleFee);

        if (msg.value > toFinalizeSaleList.saleAmount) {
            (bool refundSuccess, ) = msg.sender.call{value: msg.value - toFinalizeSaleList.saleAmount }("");

            require(refundSuccess, "E#5");
        }

        _transferAsset(_getContractAssetType(collectionAddress), collectionAddress, toFinalizeSaleList.owner, msg.sender, tokenId, toFinalizeSaleList.tokenAmount);

        emit FinalizeSale(collectionAddress, tokenId, msg.sender, toFinalizeSaleList);
    }

    function placeBid(address collectionAddress, uint256 tokenId, SaleBid memory saleBid) external {
    }

    function cancelBid(address collectionAddress, uint256 tokenId, SaleBid memory saleBid) external {
    }

    function finalizeBid(address collectionAddress, uint256 tokenId, SaleBid memory saleBid) external {
    }

    function getSaleLists(address collectionAddress, uint256 tokenId) external view returns(SaleList[] memory) {
        return _tokensData[collectionAddress][tokenId].saleLists;
    }

    function getSaleBids(address collectionAddress, uint256 tokenId) external view returns(SaleBid[] memory) {
        return _tokensData[collectionAddress][tokenId].saleBids;
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function _getContractAssetType(address contractAddress) private view returns(AssetType) {
        if (IERC165Upgradeable(contractAddress).supportsInterface(type(IERC721Upgradeable).interfaceId)) {
            return AssetType.ERC721;
        } 
        else if (IERC165Upgradeable(contractAddress).supportsInterface(type(IERC1155Upgradeable).interfaceId)) {
            return AssetType.ERC1155;
        }
        else {
            revert("E#15");
        } 
    }

    function _transferAsset(AssetType collectionAssetType, address collectionAddress, address from, address to, uint256 tokenId, uint256 amount) private {
        if (collectionAssetType == AssetType.ERC721)
            IERC721Upgradeable(collectionAddress).safeTransferFrom(from, to, tokenId);
        else if (collectionAssetType == AssetType.ERC1155)
            IERC1155Upgradeable(collectionAddress).safeTransferFrom(from, to, tokenId, amount, '');
    }

    function _deleteFromSaleLists(SaleList[] storage saleLists, uint index) private {
        saleLists[index] = saleLists[saleLists.length - 1];

        saleLists.pop();
    }

    function _deleteFromSaleBids(SaleBid[] storage saleBids, uint index) private {
        saleBids[index] = saleBids[saleBids.length - 1];

        saleBids.pop();
    }

    function _sendAssetToTreasury(AssetType assetType, uint256 amount) private {
        if (assetType == AssetType.LIQUIDITY) {
            (bool liquiditySendToTreasurySuccess, ) = treasuryAddress.call{value: amount }("");

            require(liquiditySendToTreasurySuccess, "E#6");
        }
    }
}