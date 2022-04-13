//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/Stargate/IStargateReceiver.sol";
import "../interfaces/Stargate/IStargateRouter.sol";
import "../interfaces/dex/ISwapRouter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error NotFromRouter();
error NotTokenOwner();
error NotFromContract();
error NotActiveListing();
error InsufficientFunds();
error FundsTransferFailure();

/*Cross Chain NFT Marketplace on Eth Rinkeby */

contract NFTMarketplace is IStargateReceiver, Ownable {

    IStargateRouter public constant stargateRouter = IStargateRouter(0x82A0F5F531F9ce0df1DF5619f74a0d3fA31FF561);
    ISwapRouter public constant uniRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
	 IERC20 public constant USDC = IERC20(0x1717A0D5C8705EE89A8aD6E808268D6A826C97A4); 
	 address public constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

    mapping(uint16 => bytes) public marketplaceAddresses;

    struct ItemListing {
		address lister;
		address collectionAddress;
		uint256 tokenId;
		uint256 price;
		bool active;
	}

	event ItemSold(uint16 chainId, address indexed seller, address indexed buyer, address collectionAddress, uint256 tokenId, uint256 price);
	event ItemListed(uint16 chainId, address indexed seller, address collectionAddress, uint256 tokenId, uint256 price);
	event ItemDelisted(uint16 chainId, address indexed seller, address collectionAddress, uint256 tokenId);
	event SwapFailRefund(uint16 chainId, address indexed seller, address indexed buyer, address collectionAddress, uint256 tokenId, uint256 price);
	event PriceFailRefund(uint16 chainId, address indexed seller, address indexed buyer, address collectionAddress, uint256 tokenId, uint256 price);

	modifier onlyContract {
		if(msg.sender != address(this)) revert NotFromContract();
		_;
	}

	 //bytes32 is going to be the hash of the collectionAddress with the tokenId
    mapping(bytes32 => ItemListing) public sellerListings;
	
    constructor() {
		 USDC.approve(address(stargateRouter), 2**256 - 1);
		 USDC.approve(address(uniRouter), 2**256 - 1);
	 }
	 
    function setMarketplace(uint16 _chainId, bytes calldata _sourceAddress) external onlyOwner {
        marketplaceAddresses[_chainId] = _sourceAddress;
    }

    function sgReceive(uint16 /*_chainId*/, bytes memory /*_srcAddress*/, uint256 /*_nonce*/, address _token, uint256 amountLD, bytes memory _payload) external override {

		if(msg.sender != address(stargateRouter)) revert NotFromRouter();

      (address collectionAddress, uint256 tokenId, address toAddress) = abi.decode(_payload, (address, uint256, address));
		ItemListing memory listing = sellerListings[keccak256(abi.encodePacked(collectionAddress, tokenId))];

		ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
			tokenIn: _token,
			tokenOut: WETH,
			fee: 3000,
			recipient: address(0),
			deadline: block.timestamp,
			amountIn: amountLD,
			amountOutMinimum: 0,
			sqrtPriceLimitX96:0
		});

		/*We use try/catch so trasaction does not revert*/

		try this._executeBuy(params, listing, toAddress, collectionAddress, tokenId) {
			//do nothing
		} catch {
			USDC.transfer(toAddress, amountLD); //refund buyer USDC if buy fails
			emit SwapFailRefund(10001, listing.lister, toAddress, collectionAddress, tokenId, listing.price);
		} 
	}

	function _executeBuy(ISwapRouter.ExactInputSingleParams calldata _params, ItemListing calldata _listing, address _buyer, address _collectionAddress, uint256 _tokenId) external {
		if (!_listing.active) revert NotActiveListing();
		uint256 amountOut = uniRouter.exactInputSingle(_params);
		if (amountOut < _listing.price) {
			uniRouter.unwrapWETH9(0, _buyer); //refund the buyer the eth
			emit PriceFailRefund(10001, _listing.lister, _buyer, _collectionAddress, _tokenId, _listing.price);
		} else {
			uniRouter.unwrapWETH9(0, _listing.lister); //pay the seller
			IERC721(_collectionAddress).transferFrom(_listing.lister, _buyer, _tokenId);
			_delist(_collectionAddress, _tokenId);
			emit ItemSold(10001, _listing.lister, _buyer, _collectionAddress, _tokenId, _listing.price);
		}
	}

	function buyCrossChain(address _collectionAddress, uint256 _tokenId, address toAddr, uint16 _chainId, uint256 _nativePrice) external payable {
		bytes memory destAddr = marketplaceAddresses[_chainId];	
		uint256 fee = msg.value - _nativePrice;
		uint256 amountStable = _swapForPurchase(_nativePrice);
		bytes memory payload = abi.encode(_collectionAddress, _tokenId, toAddr);
		IStargateRouter.lzTxObj memory lzParams = IStargateRouter.lzTxObj(500000, 0, "0x");
		//T0-DO: Add a poolId tracker for each chain
		stargateRouter.swap{value:fee} (_chainId, 1, 1, payable(msg.sender), amountStable, 0, lzParams, destAddr, payload);
	}

	function _swapForPurchase(uint256 _amount) internal returns (uint256){
		ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
			tokenIn: WETH,
			tokenOut: address(USDC),
			fee: 3000,
			recipient: address(this),
			deadline: block.timestamp,
			amountIn: _amount,
			amountOutMinimum: 0,
			sqrtPriceLimitX96:0
		});
		uniRouter.exactInputSingle{value:_amount}(params);
		uniRouter.unwrapWETH9(0, msg.sender);
		return USDC.balanceOf(address(this));
	}

	function buyLocal(address _collectionAddress, uint256 _tokenId) external payable {
		ItemListing memory listing = sellerListings[keccak256(abi.encodePacked(_collectionAddress, _tokenId))];
		if (!listing.active) revert NotActiveListing();
		if (listing.price > msg.value) revert InsufficientFunds();
		(bool success, ) = listing.lister.call{value: msg.value}("");
		if (!success) revert FundsTransferFailure();
		IERC721(_collectionAddress).transferFrom(listing.lister, msg.sender, _tokenId);
		_delist(_collectionAddress, _tokenId);
		emit ItemSold(10001, listing.lister, msg.sender, _collectionAddress, _tokenId, listing.price);
	}

   function listItem(address _collectionAddress, uint256 _tokenId, uint256 _nativePrice) external {
		IERC721 nftToList = IERC721(_collectionAddress);
      if(nftToList.ownerOf(_tokenId) != msg.sender) revert NotTokenOwner();
		bytes32 key = keccak256(abi.encodePacked(_collectionAddress, _tokenId));
		ItemListing memory listing = ItemListing(msg.sender, _collectionAddress, _tokenId, _nativePrice, true);
		sellerListings[key] = listing;
	}

	function delistItem(address _collectionAddress, uint256 _tokenId) external {
		bytes32 key = keccak256(abi.encodePacked(_collectionAddress, _tokenId));
		if(msg.sender != sellerListings[key].lister) revert NotTokenOwner();
		sellerListings[key].active = false;
	}

	function _delist(address _collectionAddress, uint256 _tokenId) internal {
		bytes32 key = keccak256(abi.encodePacked(_collectionAddress, _tokenId));
		sellerListings[key].active = false;
	}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IStargateReceiver {
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;
pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;


/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}
/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

	 function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;
	 function refundEth() external payable;
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