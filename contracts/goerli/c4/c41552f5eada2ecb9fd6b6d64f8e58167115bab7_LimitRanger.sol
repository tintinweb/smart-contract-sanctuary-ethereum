// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.9;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "contracts/interfaces/uniswap/INonfungiblePositionManager.sol";
import "contracts/interfaces/uniswap/IUniswapV3Pool.sol";
import "contracts/interfaces/uniswap/IUniswapV3Factory.sol";
import "contracts/interfaces/uniswap/IWETH9.sol";

import "./UniswapTransferHelper.sol";

contract LimitRanger {
    // Uniswap smart contracts
    INonfungiblePositionManager public immutable nonfungiblePositionManager;
    IUniswapV3Factory public immutable uniswapV3Factory;

    /// Smart contract of eth wrapper token
    IWETH9 public immutable weth9;

    /// Uniswap liquidity position NFT smart contract
    IERC721 public immutable uniNft;

    address public protocolOperator;

    address payable public protocolFeeReceiver;

    /// current fee in per thousand
    uint16 public currentMinFee;

    /// switch to disable opening of new positions
    bool public depositsActive;

    mapping(uint256 => PositionInfo) public positionInfos;

    mapping(address => uint256[]) internal ownedTokens;

    mapping(uint256 => uint256) internal ownedTokensIndex;

    /*****************************************/
    /*************** MODIFIERS ***************/
    /*****************************************/

    /// Modifier to check deadline of a transaction.
    modifier checkDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, "Transaction too old");
        _;
    }

    /// Modifier which checks if new deposits are currently allowed
    modifier onlyDepositsActive() {
        require(depositsActive, "Deposits are currently disabled");
        _;
    }

    modifier onlyOperator() {
        require(
            msg.sender == protocolOperator,
            "Operaton only allowed for operator of contract"
        );
        _;
    }

    /// @dev Mint params for a LimitRanger position.
    struct MintParams {
        address token0;
        address token1;
        uint256 token0Amount;
        uint256 token1Amount;
        int24 lowerTick;
        int24 upperTick;
        uint24 poolFee;
        uint256 deadline;
        uint16 protocolFee;
        bool unwrapToNative;
    }

    struct PositionInfo {
        address owner;
        int24 sellTarget;
        uint16 fee;
        bool sellAboveTarget;
        bool unwrapToNative;
    }

    /*
     * Events
     *
     */

    event AddPosition(
        uint256 token,
        address indexed owner,
        uint128 liquidity,
        bool sellAbove
    );

    constructor(
        INonfungiblePositionManager _nonfungiblePositionManager,
        IUniswapV3Factory _uniswapV3Factory,
        IWETH9 _weth9
    ) {
        nonfungiblePositionManager = _nonfungiblePositionManager;
        uniswapV3Factory = _uniswapV3Factory;
        uniNft = _nonfungiblePositionManager;
        protocolOperator = msg.sender;
        protocolFeeReceiver = payable(msg.sender);
        weth9 = _weth9;
        currentMinFee = 1;
        depositsActive = true;
    }

    function mintNewPosition(MintParams calldata params)
        external
        payable
        onlyDepositsActive
        checkDeadline(params.deadline)
        returns (uint256 tokenId)
    {
        require(
            params.token0Amount == 0 || params.token1Amount == 0,
            "Token amount of token0 or token1 must be 0"
        );
        require(
            params.token0Amount > 0 || params.token1Amount > 0,
            "Invalid token amount"
        );
        require(
            params.protocolFee >= currentMinFee && params.protocolFee <= 500,
            "Invalid protocol fee"
        );

        uint256 ethAmount = 0;

        if (msg.value > 0) {
            if (params.token0 == address(weth9)) {
                ethAmount = params.token0Amount;
            } else if (params.token1 == address(weth9)) {
                ethAmount = params.token1Amount;
            } else {
                revert("Message value not 0");
            }
            require(ethAmount == msg.value, "Invalid message value");
        }
        {
            IUniswapV3Pool pool = IUniswapV3Pool(
                uniswapV3Factory.getPool(
                    params.token0,
                    params.token1,
                    params.poolFee
                )
            );

            // check if the current tick is out of sell range
            (, int24 currentTick, , , , , ) = pool.slot0();

            if (params.token0Amount > 0) {
                require(
                    currentTick <= params.lowerTick,
                    "Currrent price of pool doesn't match desired sell range"
                );
            } else {
                require(
                    currentTick >= params.lowerTick,
                    "Currrent price of pool doesn't match desired sell range"
                );
            }

            // Approval for the position manger

            if (params.token0Amount > 0) {
                if (params.token0 != address(weth9) || ethAmount == 0) {
                    UniswapTransferHelper.safeTransferFrom(
                        params.token0,
                        msg.sender,
                        address(this),
                        params.token0Amount
                    );
                }
                UniswapTransferHelper.safeApprove(
                    params.token0,
                    address(nonfungiblePositionManager),
                    params.token0Amount
                );
            } else {
                if (params.token1 != address(weth9) || ethAmount == 0) {
                    UniswapTransferHelper.safeTransferFrom(
                        params.token1,
                        msg.sender,
                        address(this),
                        params.token1Amount
                    );
                }
                UniswapTransferHelper.safeApprove(
                    params.token1,
                    address(nonfungiblePositionManager),
                    params.token1Amount
                );
            }
        }

        // minting liquidity
        INonfungiblePositionManager.MintParams
            memory uniParams = INonfungiblePositionManager.MintParams({
                token0: params.token0,
                token1: params.token1,
                fee: params.poolFee,
                tickLower: params.lowerTick,
                tickUpper: params.upperTick,
                amount0Desired: params.token0Amount,
                amount1Desired: params.token1Amount,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });

        uint128 liquidity = 0;
        (tokenId, liquidity, , ) = nonfungiblePositionManager.mint{
            value: ethAmount
        }(uniParams);

        if (params.token0Amount > 0) {
            _storePositionInfo(
                tokenId,
                params.upperTick,
                true,
                msg.sender,
                params.protocolFee,
                params.unwrapToNative
            );
        } else {
            _storePositionInfo(
                tokenId,
                params.lowerTick,
                false,
                msg.sender,
                params.protocolFee,
                params.unwrapToNative
            );
        }

        emit AddPosition(
            tokenId,
            msg.sender,
            liquidity,
            params.token0Amount > 0
        );
        return tokenId;
    }

    function _storePositionInfo(
        uint256 tokenId,
        int24 sellTarget,
        bool sellAboveTarget,
        address owner,
        uint16 fee,
        bool unwrapToNative
    ) internal {
        positionInfos[tokenId] = PositionInfo({
            owner: owner,
            sellTarget: sellTarget,
            sellAboveTarget: sellAboveTarget,
            fee: fee,
            unwrapToNative: unwrapToNative
        });
        uint256 length = ownedTokens[owner].length;
        ownedTokens[owner].push(tokenId);
        ownedTokensIndex[tokenId] = length;
    }

    function retrieveEth() external onlyOperator returns (bool) {
        return protocolFeeReceiver.send(address(this).balance);
    }

    function retrieveERC20(address token) external onlyOperator {
        IERC20 erc20 = IERC20(token);
        UniswapTransferHelper.safeTransfer(
            token,
            protocolFeeReceiver,
            erc20.balanceOf(address(this))
        );
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.6;

import "contracts/interfaces/uniswap/IWETH9.sol";

// File @uniswap/v3-periphery/contracts/libraries/[email protected]
//
library UniswapTransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    // @notice Transfers tokens from msg.sender to a recipient
    // @dev Errors with ST if transfer fails
    // @param token The contract address of the token which will be transferred
    // @param to The recipient of the transfer
    // @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ST"
        );
    }

    // @notice Approves the stipulated contract to spend the given allowance in the given token
    // @dev Errors with "SA" if transfer fails
    // @param token The contract address of the token to be approved
    // @param to The target of the approval
    // @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SA"
        );
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.9;
pragma abicoder v2;

interface IUniswapV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.9;
pragma abicoder v2;

interface IUniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
    function tickSpacing() external view returns (int24);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.9;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INonfungiblePositionManager is IERC721 {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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