// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.9.0;


import "./Holder.sol";
import "./ExchangeCore.sol";
import "./domain/ExchangeDomain.sol";
import "../proxy/TransferProxy.sol";
import "../libs/HashAsset.sol";


contract ExchangeSell is ExchangeCore {
	mapping (bytes32 => ExchangeDomain.AssetSell) public assetsSell;

	uint256 public constant LOWEST_PRICE = 0.001 ether;
	uint256 public constant TX_FEE = 0.0005 ether;

	TransferProxy public transferProxy;
	Holder public holder;

	event ListAsset(address indexed token, uint256 indexed tokenId);
	event DelistAsset(address indexed token, uint256 indexed tokenId);
	event Purchase(bytes32 assetKey, address buyer, uint256 amount);

	/**
		Init this contract with transferProxy & holder
	 */
	constructor(address _transfer, address _holder) 
	{
		transferProxy = TransferProxy(_transfer);
		holder = Holder(_holder);
	}

	/**
		@dev List a asset token
		@notice When listing success, token is transfered to holder
	 */
	function list(address token, uint256 tokenId, uint256 price) external 
	{
		// validate
		address ownerOfToken = _requireOwnerOfToken(token, tokenId);
		require(price >= LOWEST_PRICE, "ExchangeSell#list: asset price is too low");

		bytes32 assetKey = HashAsset.hashKey(token, tokenId);
		ExchangeDomain.AssetSell memory asset = assetsSell[assetKey];

		// add assetSell
		assetsSell[assetKey] = _prepareAssetInfo(asset, token, tokenId, price);

		// transfer to holder
		transferProxy.erc721SafeTransfer(
			IERC721(token),
			ownerOfToken,
			address(holder),
			tokenId);
		holder.set(assetKey, ExchangeState.AssetType.Sell);

		emit ListAsset(asset.domain.token, asset.domain.tokenId);
	}

	/**
		@dev Remove an asset token from market
		Return token from owner to seller
		Caller MUST be seller
	 */
	function delist(address token, uint256 tokenId) external 
	{
		bytes32 assetKey = HashAsset.hashKey(token, tokenId);
		_requireAvailable(assetKey);

		// redeem from holder
		transferProxy.erc721SafeTransfer(
			IERC721(token),
			address(holder),
			_msgSender(),
			tokenId);
		holder.set(assetKey, ExchangeState.AssetType.NULL);

		emit DelistAsset(token, tokenId);
	}

	/**
		@dev Allow other to buy an asset token on market
		@notice Token must be listed in holder
		Bid value must be greater than asset price
		When a purchase tx success, a fee will be given to this contract from asset selling price.
	 */
	function purchase(bytes32 assetKey) external payable
	{
		_requireAvailable(assetKey);
		ExchangeDomain.AssetSell memory asset = assetsSell[assetKey];
		require(msg.value >= asset.price, "ExchangeSell#purchase: insufficient value");

		(bool transferFee, ) = payable(address(this)).call{value: TX_FEE}("");
		require(transferFee, "transfer fee failed");
		(bool transferValue, ) = asset.domain.seller.call{value: msg.value - TX_FEE}("");
		require(transferValue, "transfer selling failed");

		// transfer asset token to buyer
		transferProxy.erc721SafeTransfer(
			IERC721(asset.domain.token),
			address(holder),
			_msgSender(),
			asset.domain.tokenId);

		// delist token
		holder.set(assetKey, ExchangeState.AssetType.NULL);

		emit Purchase(assetKey, _msgSender(), msg.value);
	}

	function _prepareAssetInfo(
		ExchangeDomain.AssetSell memory asset,
		address token,
		uint256 tokenId,
		uint256 price
	) internal view returns(ExchangeDomain.AssetSell memory) 
	{
		if (asset.domain.token == address(0)) {
			asset.domain.token = token;
			asset.domain.tokenId = tokenId;
		}
		asset.domain.seller = payable(_msgSender());
		asset.price = price;

		return asset;
	}

	function _requireAvailable(bytes32 assetKey) override internal view {
		require(holder.get(assetKey) == ExchangeState.AssetType.Sell,
				"ExchangeSell#delist: asset is not listed");
	}

	function _requireOwnerOfToken(address token, uint256 tokenId) override internal view returns(address){
		address owner = _ownerOfToken(IERC721(token), tokenId);
		require(owner == _msgSender(),
				"ExchangeSell: caller is not owner of token");
		return owner;
	}

	function _ownerOfToken(IERC721 erc721, uint256 tokenId) internal view returns(address)
	{
		return erc721.ownerOf(tokenId);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./HolderState.sol";


contract Holder is IERC721Receiver, HolderState
{
	function onERC721Received(address, address, uint256, bytes memory) 
	virtual override public returns(bytes4)
	{
		return this.onERC721Received.selector;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract ExchangeCore is Ownable {
	using Address for address;

	uint256 public balance;

	event Receive(uint256 amount, address sender);
	event Withdraw(uint256 amount, address caller);

	/**
		@dev Make contract can receive eth
	 */
	receive() external payable
	{
		balance += msg.value;
		emit Receive(msg.value, _msgSender());
	}

	/**
		@dev Allow owner to withdraw eth balance in this contract
	 */
	function withdraw(uint256 amount) external onlyOwner
	{
		require(amount <= balance, "ExchangeCore#withdraw: amount must be lesser than balance");

		(bool success, ) = payable(_msgSender()).call{value: amount}("");
		require(success, "Withdraw failed");

		balance -= amount;
		
		emit Withdraw(amount, _msgSender());
	}

	function _msgSender() override virtual internal view returns(address) {
		if (msg.sender.isContract()) {
			return tx.origin;
		}
		return super._msgSender();
	}

	function _requireAvailable(bytes32 assetKey) virtual internal {}
	function _requireOwnerOfToken(address token, uint256 tokenId) virtual internal returns(address){}
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.9.0;


import "./ExchangeState.sol";


contract ExchangeDomain {
	struct AssetDomain {
		address token;
		address payable seller;
		uint256 tokenId;
	}

	struct AssetSell {
		AssetDomain domain;
		uint256 price;
	}

	struct AssetAuction {
		AssetDomain domain;
		uint256 startPrice;
		uint256 endTime;
	}

	struct AuctionParam {
		uint256 highestBid;
		address highestBidder;
		address[] bidders;
		mapping (address => uint256) pendingReturns;
	}
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../access/OwnableOperatorRole.sol";

contract TransferProxy is OwnableOperatorRole {
	function erc721SafeTransfer(
		IERC721 erc721,
		address from,
		address to,
		uint256 tokenId
	) external onlyOperator {
		IERC721(erc721).safeTransferFrom(from, to, tokenId);
	}
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.9.0;


import "../exchange/domain/ExchangeDomain.sol";


library HashAsset {
	function hashKey(address token, uint256 tokenId) internal pure returns(bytes32) {
		return keccak256(abi.encodePacked(token, tokenId));
	}

	function hashKey(ExchangeDomain.AssetDomain calldata domain) internal pure returns(bytes32){
		return keccak256(abi.encodePacked(domain.token, domain.tokenId));
	}
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.9.0;

import "./domain/ExchangeState.sol";
import "../access/ProxyAccess.sol";

abstract contract HolderState is ProxyAccess {
	mapping (bytes32 => ExchangeState.AssetType) public assetTypes;

	bytes32 public constant EXCHANGE_ROLE = keccak256("EXCHANGE_ROLE");

	/**
		@dev Set asset token type, which type it's pin on market
		@notice This action MUST be call anytime when an asset token pin on market.
	 */
	function set(bytes32 key, ExchangeState.AssetType assetType) external onlyAccess(EXCHANGE_ROLE)
	{
		assetTypes[key] = assetType;
	}

	/**
		@dev Get the state of asset type from holder
	 */
	function get(bytes32 key) external view returns(ExchangeState.AssetType)
	{
		return assetTypes[key];
	}
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.9.0;



contract ExchangeState {
	enum SellState {Unavailable, Available}
	enum AssetType {NULL, Sell, Auction}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.9.0;


import "@openzeppelin/contracts/access/Ownable.sol";


abstract contract ProxyAccess is Ownable {
	mapping(bytes32 => mapping(address => bool)) private _accesses;

	event GrantAccess(bytes32 role, address op);
	event RevokeAccess(bytes32 role, address op);


	modifier onlyAccess(bytes32 role) {
		require(hasAccess(role), "ProxyAccess: caller not have access");
		_;
	}


	function grantAccess(bytes32 role, address operator) external onlyOwner {
		_grantAccess(role, operator);
	}

	function revokeAccess(bytes32 role, address op) external onlyOwner {
		delete _accesses[role][op];
		emit RevokeAccess(role, op);
	}

	function hasAccess(bytes32 role) public view returns(bool) {
		return _accesses[role][_msgSender()] == true;
	}


	function _grantAccess(bytes32 role, address op) internal {
		_accesses[role][op] = true;
		emit GrantAccess(role, op);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.9.0;


import "@openzeppelin/contracts/access/Ownable.sol";


contract OwnableOperatorRole is Ownable {
	mapping(address => bool) bearers;

	event AddOperator(address indexed op);
	event RemoveOperator(address indexed op);

	modifier onlyOperator {
		require(isOperator(_msgSender()), "OwnableOperatorRole: caller is not operator");
		_;
	}

	function add(address op) external onlyOwner {
		bearers[op] = true;
		emit AddOperator(op);
	}

	function remove(address op) external onlyOwner {
		require(isOperator(op), "OwnableOperatorRole: this is not an operator");
		bearers[op] = false;
		emit RemoveOperator(op);
	}

	function isOperator(address op) public view returns(bool) {
		return bearers[op] == true;
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