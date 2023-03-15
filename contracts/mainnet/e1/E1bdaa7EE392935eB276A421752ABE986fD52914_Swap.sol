// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import 'solmate/tokens/ERC20.sol';
import 'solmate/utils/SafeTransferLib.sol';
import './external/uniswap/ISwapRouter02.sol';
import './external/sushiswap/ISushiRouter.sol';
import {IAsset, IVault} from './external/balancer/IVault.sol';
import './libraries/Ownable.sol';
import './libraries/Path.sol';

/**
 * @notice
 * Swap contract used by strategies to:
 * 1. swap strategy rewards to 'asset'
 * 2. zap similar tokens to asset (e.g. USDT to USDC)
 */
contract Swap is Ownable {
	using SafeTransferLib for ERC20;
	using Path for bytes;

	enum Route {
		Unsupported,
		UniswapV2,
		UniswapV3Direct,
		UniswapV3Path,
		SushiSwap,
		BalancerBatch
	}

	/**
		@dev info depends on route:
		UniswapV2: address[] path
		UniswapV3Direct: uint24 fee
		UniswapV3Path: bytes path (address, uint24 fee, address, uint24 fee, address)
	 */
	struct RouteInfo {
		Route route;
		bytes info;
	}

	ISushiRouter internal constant sushiswap = ISushiRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
	/// @dev single address which supports both uniswap v2 and v3 routes
	ISwapRouter02 internal constant uniswap = ISwapRouter02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

	IVault internal constant balancer = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

	/// @dev tokenIn => tokenOut => routeInfo
	mapping(address => mapping(address => RouteInfo)) public routes;

	/*//////////////////
	/      Events      /
	//////////////////*/

	event RouteSet(address indexed tokenIn, address indexed tokenOut, RouteInfo routeInfo);
	event RouteRemoved(address indexed tokenIn, address indexed tokenOut);

	/*//////////////////
	/      Errors      /
	//////////////////*/

	error UnsupportedRoute(address tokenIn, address tokenOut);
	error InvalidRouteInfo();

	constructor() Ownable() {
		address CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
		address CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
		address LDO = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;

		address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

		address STG = 0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6;
		address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
		address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

		_setRoute(CRV, WETH, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(3_000))}));
		_setRoute(CVX, WETH, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(10_000))}));
		_setRoute(LDO, WETH, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(3_000))}));

		_setRoute(CRV, USDC, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(10_000))}));
		_setRoute(
			CVX,
			USDC,
			RouteInfo({
				route: Route.UniswapV3Path,
				info: abi.encodePacked(CVX, uint24(10_000), WETH, uint24(500), USDC)
			})
		);

		_setRoute(USDC, USDT, RouteInfo({route: Route.UniswapV3Direct, info: abi.encode(uint24(100))}));

		IAsset[] memory assets = new IAsset[](4);
		assets[0] = IAsset(STG);
		assets[1] = IAsset(0xA13a9247ea42D743238089903570127DdA72fE44); // bb-a-USD
		assets[2] = IAsset(0x82698aeCc9E28e9Bb27608Bd52cF57f704BD1B83); // bb-a-USDC
		assets[3] = IAsset(USDC);

		IVault.BatchSwapStep[] memory steps = new IVault.BatchSwapStep[](3);

		// STG -> bb-a-USD
		steps[0] = IVault.BatchSwapStep({
			poolId: 0x4ce0bd7debf13434d3ae127430e9bd4291bfb61f00020000000000000000038b,
			assetInIndex: 0,
			assetOutIndex: 1,
			amount: 0,
			userData: ''
		});

		// bb-a-USD -> bb-a-USDC
		steps[1] = IVault.BatchSwapStep({
			poolId: 0xa13a9247ea42d743238089903570127dda72fe4400000000000000000000035d,
			assetInIndex: 1,
			assetOutIndex: 2,
			amount: 0,
			userData: ''
		});

		// bb-a-USDC -> USDC
		steps[2] = IVault.BatchSwapStep({
			poolId: 0x82698aecc9e28e9bb27608bd52cf57f704bd1b83000000000000000000000336,
			assetInIndex: 2,
			assetOutIndex: 3,
			amount: 0,
			userData: ''
		});

		_setRoute(STG, USDC, RouteInfo({route: Route.BalancerBatch, info: abi.encode(steps, assets)}));
	}

	/*///////////////////////
	/      Public View      /
	///////////////////////*/

	function getRoute(address _tokenIn, address _tokenOut) external view returns (RouteInfo memory routeInfo) {
		return routes[_tokenIn][_tokenOut];
	}

	/*////////////////////////////
	/      Public Functions      /
	////////////////////////////*/

	function swapTokens(
		address _tokenIn,
		address _tokenOut,
		uint256 _amount,
		uint256 _minReceived
	) external returns (uint256 received) {
		RouteInfo memory routeInfo = routes[_tokenIn][_tokenOut];

		ERC20 tokenIn = ERC20(_tokenIn);
		tokenIn.safeTransferFrom(msg.sender, address(this), _amount);

		Route route = routeInfo.route;
		bytes memory info = routeInfo.info;

		if (route == Route.UniswapV2) {
			received = _uniswapV2(_amount, _minReceived, info);
		} else if (route == Route.UniswapV3Direct) {
			received = _uniswapV3Direct(_tokenIn, _tokenOut, _amount, _minReceived, info);
		} else if (route == Route.UniswapV3Path) {
			received = _uniswapV3Path(_amount, _minReceived, info);
		} else if (route == Route.SushiSwap) {
			received = _sushiswap(_amount, _minReceived, info);
		} else if (route == Route.BalancerBatch) {
			received = _balancerBatch(_amount, _minReceived, info);
		} else revert UnsupportedRoute(_tokenIn, _tokenOut);

		// return unswapped amount to sender
		uint256 balance = tokenIn.balanceOf(address(this));
		if (balance > 0) tokenIn.safeTransfer(msg.sender, balance);
	}

	/*///////////////////////////////////////////
	/      Restricted Functions: onlyOwner      /
	///////////////////////////////////////////*/

	function setRoute(
		address _tokenIn,
		address _tokenOut,
		RouteInfo memory _routeInfo
	) external onlyOwner {
		_setRoute(_tokenIn, _tokenOut, _routeInfo);
	}

	function unsetRoute(address _tokenIn, address _tokenOut) external onlyOwner {
		delete routes[_tokenIn][_tokenOut];
		emit RouteRemoved(_tokenIn, _tokenOut);
	}

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _setRoute(
		address _tokenIn,
		address _tokenOut,
		RouteInfo memory _routeInfo
	) internal {
		Route route = _routeInfo.route;
		bytes memory info = _routeInfo.info;

		if (route == Route.UniswapV2 || route == Route.SushiSwap) {
			address[] memory path = abi.decode(info, (address[]));

			if (path[0] != _tokenIn) revert InvalidRouteInfo();
			if (path[path.length - 1] != _tokenOut) revert InvalidRouteInfo();
		}

		// just check that this doesn't throw an error
		if (route == Route.UniswapV3Direct) abi.decode(info, (uint24));

		if (route == Route.UniswapV3Path) {
			bytes memory path = info;

			// check first tokenIn
			(address tokenIn, , ) = path.decodeFirstPool();
			if (tokenIn != _tokenIn) revert InvalidRouteInfo();

			// check last tokenOut
			while (path.hasMultiplePools()) path = path.skipToken();
			(, address tokenOut, ) = path.decodeFirstPool();
			if (tokenOut != _tokenOut) revert InvalidRouteInfo();
		}

		address router = route == Route.SushiSwap ? address(sushiswap) : route == Route.BalancerBatch
			? address(balancer)
			: address(uniswap);

		ERC20(_tokenIn).safeApprove(router, 0);
		ERC20(_tokenIn).safeApprove(router, type(uint256).max);

		routes[_tokenIn][_tokenOut] = _routeInfo;
		emit RouteSet(_tokenIn, _tokenOut, _routeInfo);
	}

	function _uniswapV2(
		uint256 _amount,
		uint256 _minReceived,
		bytes memory _path
	) internal returns (uint256) {
		address[] memory path = abi.decode(_path, (address[]));

		return uniswap.swapExactTokensForTokens(_amount, _minReceived, path, msg.sender);
	}

	function _sushiswap(
		uint256 _amount,
		uint256 _minReceived,
		bytes memory _path
	) internal returns (uint256) {
		address[] memory path = abi.decode(_path, (address[]));

		uint256[] memory received = sushiswap.swapExactTokensForTokens(
			_amount,
			_minReceived,
			path,
			msg.sender,
			block.timestamp + 30 minutes
		);

		return received[received.length - 1];
	}

	function _uniswapV3Direct(
		address _tokenIn,
		address _tokenOut,
		uint256 _amount,
		uint256 _minReceived,
		bytes memory _info
	) internal returns (uint256) {
		uint24 fee = abi.decode(_info, (uint24));

		return
			uniswap.exactInputSingle(
				ISwapRouter02.ExactInputSingleParams({
					tokenIn: _tokenIn,
					tokenOut: _tokenOut,
					fee: fee,
					recipient: msg.sender,
					amountIn: _amount,
					amountOutMinimum: _minReceived,
					sqrtPriceLimitX96: 0
				})
			);
	}

	function _uniswapV3Path(
		uint256 _amount,
		uint256 _minReceived,
		bytes memory _path
	) internal returns (uint256) {
		return
			uniswap.exactInput(
				ISwapRouter02.ExactInputParams({
					path: _path,
					recipient: msg.sender,
					amountIn: _amount,
					amountOutMinimum: _minReceived
				})
			);
	}

	function _balancerBatch(
		uint256 _amount,
		uint256 _minReceived,
		bytes memory _info
	) internal returns (uint256) {
		(IVault.BatchSwapStep[] memory steps, IAsset[] memory assets) = abi.decode(
			_info,
			(IVault.BatchSwapStep[], IAsset[])
		);

		steps[0].amount = _amount;

		int256[] memory limits = new int256[](assets.length);

		limits[0] = int256(_amount);
		limits[limits.length - 1] = int256(_minReceived);

		int256[] memory received = balancer.batchSwap(
			IVault.SwapKind.GIVEN_IN,
			steps,
			assets,
			IVault.FundManagement({
				sender: address(this),
				fromInternalBalance: false,
				recipient: payable(address(msg.sender)),
				toInternalBalance: false
			}),
			limits,
			block.timestamp + 30 minutes
		);

		return uint256(received[received.length - 1]);
	}
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

/// https://etherscan.io/address/0xBA12222222228d8Ba445958a75a0704d566BF2C8#code

interface IAsset {

}

interface IVault {
	enum SwapKind {
		GIVEN_IN,
		GIVEN_OUT
	}

	/**
	 * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
	 * `assets` array passed to that function, and ETH assets are converted to WETH.
	 *
	 * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
	 * from the previous swap, depending on the swap kind.
	 *
	 * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
	 * used to extend swap behavior.
	 */
	struct BatchSwapStep {
		bytes32 poolId;
		uint256 assetInIndex;
		uint256 assetOutIndex;
		uint256 amount;
		bytes userData;
	}

	/**
	 * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
	 * `recipient` account.
	 *
	 * If the caller is not `sender`, it must be an authorized relayer for them.
	 *
	 * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
	 * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
	 * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
	 * `joinPool`.
	 *
	 * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
	 * transferred. This matches the behavior of `exitPool`.
	 *
	 * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
	 * revert.
	 */
	struct FundManagement {
		address sender;
		bool fromInternalBalance;
		address payable recipient;
		bool toInternalBalance;
	}

	/**
	 * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
	 * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
	 *
	 * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
	 * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
	 * the same index in the `assets` array.
	 *
	 * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
	 * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
	 * `amountOut` depending on the swap kind.
	 *
	 * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
	 * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
	 * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
	 *
	 * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
	 * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
	 * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
	 * or unwrapped from WETH by the Vault.
	 *
	 * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
	 * the minimum or maximum amount of each token the vault is allowed to transfer.
	 *
	 * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
	 * equivalent `swap` call.
	 *
	 * Emits `Swap` events.
	 */
	function batchSwap(
		SwapKind kind,
		BatchSwapStep[] memory swaps,
		IAsset[] memory assets,
		FundManagement memory funds,
		int256[] memory limits,
		uint256 deadline
	) external payable returns (int256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// https://etherscan.io/address/0xd9e1ce17f2641f24ae83637ab66a2cca9c378b9f
// it's actually a UniswapV2Router02 but renamed for clarity vs actual uniswap

interface ISushiRouter {
	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// https://github.com/Uniswap/swap-router-contracts/blob/main/contracts/interfaces/ISwapRouter02.sol

interface ISwapRouter02 {
	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to
	) external payable returns (uint256 amountOut);

	struct ExactInputSingleParams {
		address tokenIn;
		address tokenOut;
		uint24 fee;
		address recipient;
		uint256 amountIn;
		uint256 amountOutMinimum;
		uint160 sqrtPriceLimitX96;
	}

	/// @notice Swaps `amountIn` of one token for as much as possible of another token
	/// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
	/// and swap the entire amount, enabling contracts to send tokens before calling this function.
	/// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
	/// @return amountOut The amount of the received token
	function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

	struct ExactInputParams {
		bytes path;
		address recipient;
		uint256 amountIn;
		uint256 amountOutMinimum;
	}

	/// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
	/// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
	/// and swap the entire amount, enabling contracts to send tokens before calling this function.
	/// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
	/// @return amountOut The amount of the received token
	function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: Unlicense

//https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol

pragma solidity >=0.8.0 <0.9.0;

library BytesLib {
	function slice(
		bytes memory _bytes,
		uint256 _start,
		uint256 _length
	) internal pure returns (bytes memory) {
		require(_length + 31 >= _length, 'slice_overflow');
		require(_bytes.length >= _start + _length, 'slice_outOfBounds');

		bytes memory tempBytes;

		assembly {
			switch iszero(_length)
			case 0 {
				// Get a location of some free memory and store it in tempBytes as
				// Solidity does for memory variables.
				tempBytes := mload(0x40)

				// The first word of the slice result is potentially a partial
				// word read from the original array. To read it, we calculate
				// the length of that partial word and start copying that many
				// bytes into the array. The first word we copy will start with
				// data we don't care about, but the last `lengthmod` bytes will
				// land at the beginning of the contents of the new array. When
				// we're done copying, we overwrite the full first word with
				// the actual length of the slice.
				let lengthmod := and(_length, 31)

				// The multiplication in the next line is necessary
				// because when slicing multiples of 32 bytes (lengthmod == 0)
				// the following copy loop was copying the origin's length
				// and then ending prematurely not copying everything it should.
				let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
				let end := add(mc, _length)

				for {
					// The multiplication in the next line has the same exact purpose
					// as the one above.
					let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
				} lt(mc, end) {
					mc := add(mc, 0x20)
					cc := add(cc, 0x20)
				} {
					mstore(mc, mload(cc))
				}

				mstore(tempBytes, _length)

				//update free-memory pointer
				//allocating the array padded to 32 bytes like the compiler does now
				mstore(0x40, and(add(mc, 31), not(31)))
			}
			//if we want a zero-length slice let's just return a zero-length array
			default {
				tempBytes := mload(0x40)
				//zero out the 32 bytes slice we are about to return
				//we need to do it because Solidity does not garbage collect
				mstore(tempBytes, 0)

				mstore(0x40, add(tempBytes, 0x20))
			}
		}

		return tempBytes;
	}

	function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
		require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
		address tempAddress;

		assembly {
			tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
		}

		return tempAddress;
	}

	function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
		require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
		uint24 tempUint;

		assembly {
			tempUint := mload(add(add(_bytes, 0x3), _start))
		}

		return tempUint;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

abstract contract Ownable {
	address public owner;
	address public nominatedOwner;

	error Unauthorized();

	event OwnerChanged(address indexed previousOwner, address indexed newOwner);

	constructor() {
		owner = msg.sender;
	}

	// Public Functions

	function acceptOwnership() external {
		if (msg.sender != nominatedOwner) revert Unauthorized();
		emit OwnerChanged(owner, msg.sender);
		owner = msg.sender;
		nominatedOwner = address(0);
	}

	// Restricted Functions: onlyOwner

	/// @dev nominating zero address revokes a pending nomination
	function nominateOwnership(address _newOwner) external onlyOwner {
		nominatedOwner = _newOwner;
	}

	// Modifiers

	modifier onlyOwner() {
		if (msg.sender != owner) revert Unauthorized();
		_;
	}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

// https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/Path.sol

import './BytesLib.sol';

/// @title Functions for manipulating path data for multihop swaps
library Path {
	using BytesLib for bytes;

	/// @dev The length of the bytes encoded address
	uint256 private constant ADDR_SIZE = 20;
	/// @dev The length of the bytes encoded fee
	uint256 private constant FEE_SIZE = 3;

	/// @dev The offset of a single token address and pool fee
	uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
	/// @dev The offset of an encoded pool key
	uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
	/// @dev The minimum length of an encoding that contains 2 or more pools
	uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

	/// @notice Returns true iff the path contains two or more pools
	/// @param path The encoded swap path
	/// @return True if path contains two or more pools, otherwise false
	function hasMultiplePools(bytes memory path) internal pure returns (bool) {
		return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
	}

	/// @notice Returns the number of pools in the path
	/// @param path The encoded swap path
	/// @return The number of pools in the path
	function numPools(bytes memory path) internal pure returns (uint256) {
		// Ignore the first token address. From then on every fee and token offset indicates a pool.
		return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
	}

	/// @notice Decodes the first pool in path
	/// @param path The bytes encoded swap path
	/// @return tokenA The first token of the given pool
	/// @return tokenB The second token of the given pool
	/// @return fee The fee level of the pool
	function decodeFirstPool(bytes memory path)
		internal
		pure
		returns (
			address tokenA,
			address tokenB,
			uint24 fee
		)
	{
		tokenA = path.toAddress(0);
		fee = path.toUint24(ADDR_SIZE);
		tokenB = path.toAddress(NEXT_OFFSET);
	}

	/// @notice Gets the segment corresponding to the first pool in the path
	/// @param path The bytes encoded swap path
	/// @return The segment containing all data necessary to target the first pool in the path
	function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
		return path.slice(0, POP_OFFSET);
	}

	/// @notice Skips a token + fee element from the buffer and returns the remainder
	/// @param path The swap path
	/// @return The remaining token + fee elements in the path
	function skipToken(bytes memory path) internal pure returns (bytes memory) {
		return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
	}
}