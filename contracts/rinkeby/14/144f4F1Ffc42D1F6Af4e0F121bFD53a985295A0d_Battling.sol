/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: Unlicense
// File: IERC165.sol


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
// File: ERC165.sol

pragma solidity ^0.8.0;

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)


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
// File: IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
// File: ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}
// File: ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
// File: IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
// File: IFortunasAssets.sol

pragma solidity ^0.8.0;



interface IFortunasAssets is IERC1155 {

    function mint(
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) external;

    function safeTransferFromWithCheck(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) external;

    function burnWithCheck(
        address _from,
        uint256 _tokenId,
        uint256 _amount
    ) external;
}
// File: IERC20.sol

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
// File: IERC20Metadata.sol

pragma solidity ^0.8.0;



/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
// File: IPancakeFactory.sol

pragma solidity >=0.5.0;


interface IPancakeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}
// File: IPancakeRouter02.sol

pragma solidity >=0.6.2;


interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
// File: IPancakePair.sol

pragma solidity >=0.5.0;


interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}
// File: ABDKMath64x64.sol

pragma solidity ^0.8.0;

/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}
// File: MathUpgradeable.sol

pragma solidity ^0.8.0;

// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }

    /**
     * @dev Returns the current rounding of the division of two numbers.
     *
     * This differs from standard division with `/` in that it can round up and
     * down depending on the floating point.
     */
    function roundDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = a * 10 / b;
        if (result % 10 >= 5) {
            result = a / b + (a % b == 0 ? 0 : 1);
        }
        else {
            result = a / b;
        }

        return result;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result;
        if (a > b) {
            result = a - b;
        }
        else {
            result = 0;
        }

        return result;
    }
}
// File: SafeMath.sol

pragma solidity ^0.8.0;


library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}
// File: Context.sol

pragma solidity ^0.8.0;


/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: ERC20.sol

pragma solidity ^0.8.0;






/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
// File: Ownable.sol

pragma solidity ^0.8.0;



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
// File: FortunasLedger.sol

pragma solidity ^0.8.0;





contract FortunasLedger is Ownable {
    using SafeMath for uint256;

    uint256 public passiveRewardTime;
    
    uint256 public multiplierForPassiveReward;

    uint256 public passiveRewardPercentage;
    uint256 public passiveRewardPercentagePerCycle;

    // mappings

    mapping (address => uint256) private _lastUpdate;
    mapping (address => uint256) private _totalPassiveRewards;

    // constructor

    constructor() {
        // passiveRewardTime = 1800;
        passiveRewardTime = 144;

        multiplierForPassiveReward = 10 ** 9;

        passiveRewardPercentage = 2500000;
        passiveRewardPercentagePerCycle = 52083;
    }

    // getters

    function getLastUpdate(address account) external view returns (uint256) {
        return _lastUpdate[account];
    }

    function getTotalPassiveRewards(address account) external view returns (uint256) {
        return _totalPassiveRewards[account];
    }

    // functions

    function updatePassiveRewards(address account, uint256 balance) public onlyOwner returns (uint256, bool) {
        uint256 tempTotalPassiveRewards = _totalPassiveRewards[account];
        uint256 tempLastUpdate = _lastUpdate[account];

        uint256 currentTime = block.timestamp;

        bool isFirstTransaction = tempLastUpdate == 0;

        if (isFirstTransaction) {
            _lastUpdate[account] = currentTime;
            return (0, true);
        }

        if (
            balance == 0 &&
            tempTotalPassiveRewards == 0 &&
            !isFirstTransaction
        ) {
            return (0, false);
        }

        bool isValid = currentTime > tempLastUpdate.add(passiveRewardTime);

        if (isValid) {
            uint256 timeToConsider = currentTime.sub(tempLastUpdate);

            uint256 rewardCycles = timeToConsider.div(passiveRewardTime);

            uint256 ratio = passiveRewardPercentagePerCycle.mul(10 ** 18).div(multiplierForPassiveReward);

            uint256 compoundReward = _compound(
                balance.add(tempTotalPassiveRewards),
                ratio,
                rewardCycles
            );
            tempTotalPassiveRewards += compoundReward;

            _totalPassiveRewards[account] = tempTotalPassiveRewards;
            _lastUpdate[account] += rewardCycles.mul(passiveRewardTime);
        }

        return (_totalPassiveRewards[account], false);
    }

    function calculateNextPassiveReward(address account, uint256 balance) public view returns (uint256) {
        uint256 tempTotalPassiveRewards = _totalPassiveRewards[account];

        if (
            balance == 0 &&
            tempTotalPassiveRewards == 0
        ) {
            return 0;
        }

        uint256 ratio = passiveRewardPercentagePerCycle.mul(10 ** 18).div(multiplierForPassiveReward);

        uint256 compoundReward = _compound(
            balance.add(tempTotalPassiveRewards),
            ratio,
            1
        );
        uint256 nextPassiveReward = compoundReward;

        return nextPassiveReward;
    }

    function claimPassiveRewards(address account, uint256 balance) external onlyOwner returns (uint256, uint256) {
        (uint256 updatedPassiveRewards, ) = updatePassiveRewards(account, balance);
        uint256 nextPassiveReward;

        bool isClaimable = updatedPassiveRewards > 0;

        if (isClaimable) {
            _totalPassiveRewards[account] = 0;
        }

        bool hasBalance = balance > 0;

        if (hasBalance) {
            nextPassiveReward = calculateNextPassiveReward(account, balance);
        }

        return (updatedPassiveRewards, nextPassiveReward);
    }

    function getCurrentLedgerStatus(address account, uint256 balance) external view returns (uint256, uint256) {
        uint256 tempTotalPassiveRewards = _totalPassiveRewards[account];
        uint256 tempLastUpdate = _lastUpdate[account];
        uint256 nextPassiveReward;

        uint256 currentTime = block.timestamp;

        if (
            balance == 0 &&
            tempTotalPassiveRewards == 0
        ) {
            return (0, 0);
        }

        bool isValid = currentTime > tempLastUpdate.add(passiveRewardTime);

        uint256 ratio = passiveRewardPercentagePerCycle.mul(10 ** 18).div(multiplierForPassiveReward);
        uint256 compoundReward;

        if (isValid) {
            uint256 timeToConsider = currentTime.sub(tempLastUpdate);

            uint256 rewardCycles = timeToConsider.div(passiveRewardTime);

            compoundReward = _compound(
                balance.add(tempTotalPassiveRewards),
                ratio,
                rewardCycles
            );
            tempTotalPassiveRewards += compoundReward;
        }

        compoundReward = _compound(
            balance.add(tempTotalPassiveRewards),
            ratio,
            1
        );
        nextPassiveReward = compoundReward;

        return (tempTotalPassiveRewards, nextPassiveReward);
    }

    function _compound(uint256 _principal, uint256 _ratio, uint256 _exponent) internal pure returns (uint256) {
        if (_exponent == 0) {
            return _principal;
        }

        uint256 accruedReward = ABDKMath64x64.mulu(ABDKMath64x64.pow(ABDKMath64x64.add(ABDKMath64x64.fromUInt(1), ABDKMath64x64.divu(_ratio,10**18)), _exponent), _principal);
        return accruedReward.sub(_principal);
    }
}
// File: FortunasToken.sol

pragma solidity ^0.8.0;









contract FortunasToken is ERC20, Ownable {
    using SafeMath for uint256;

    // BUSD mainnet
    // address public BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    
    // TODO remove
    address public BUSD;

    // PancakeSwap
    IPancakeRouter02 public pancakeRouter;
    address public immutable pancakePair;
    // address public pancakePair;

    bool private swapping;
    bool public swapAndLiquifyEnabled = true;

    // Bookkeeper for all FRTNA holders
    FortunasLedger public fortunasLedger;

    address public battling;
    
    address public liquidityWallet;
    address public treasuryWallet;

    // buy fees
    uint256 public liquidityBuyingFee;
    uint256 public treasuryBuyingFee;
    uint256 public burnBuyingFee;

    // sell fees
    uint256 public liquiditySellingFee;
    uint256 public treasurySellingFee;
    uint256 public burnSellingFee;

    uint256 public maxBuyingFee;
    uint256 public maxSellingFee;
    uint256 public immutable multiplierForTotalFee;

    uint256 public totalSellingFeesAccumulated;

    uint256 public swapAndTransferTokensAtAmount = 1000 * (10**18);

    // timestamp for when the token can be traded freely on PanackeSwap
    uint256 public immutable tradingEnabledTimestamp = 1623967200; //June 17, 22:00 UTC, 2021

    // mappings

    // addresses that are excluded from buying and selling fees
    mapping (address => bool) private isExcludedFromFees;

    // addresses that are excluded from FRTNA holder's rewards
    mapping (address => bool) private isExcludedFromPassiveRewards;

    // addresses that can make transfers before trading is enabled
    mapping (address => bool) private canTransferBeforeTradingIsEnabled;

    // store addresses that are automatic market maker pairs
    mapping (address => bool) public automatedMarketMakerPairs;

    // events

    event UpdatePancakeRouter(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event TreasuryWalletUpdated(address indexed newTreasuryWallet, address indexed oldTreasuryWallet);

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    event LedgerCreated(address indexed account, uint256 totalPassiveRewards, uint256 nextReward);

    event LedgerUpdated(address indexed account, uint256 totalPassiveRewards, uint256 nextReward);
    
    event LedgerClaimed(address indexed account, uint256 totalPassiveRewards, uint256 nextReward);

    // constructor

    constructor() ERC20("Fortunas Token", "FRTNA") {
        // TODO remove
        if (block.chainid == 97) {
            BUSD = 0x8354e8b945D6C35bD35615DD0277C4032cd0a67D;
        }
        else if (block.chainid == 4) {
            BUSD = 0x7D9385C733a967793EE14D933212ee44025f1B9d;
        }

        // PancakeRouter02 mainnet
    	// IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        // TODO remove
        IPancakeRouter02 _pancakeRouter;
        if (block.chainid == 97) {
            _pancakeRouter = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        }
        else if (block.chainid == 4) {
            _pancakeRouter = IPancakeRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        }
        address _pancakePair = IPancakeFactory(_pancakeRouter.factory())
            .createPair(address(this), BUSD);

        pancakeRouter = _pancakeRouter;
        pancakePair = _pancakePair;

        _setAutomatedMarketMakerPair(_pancakePair, true);

        fortunasLedger = new FortunasLedger();

        // TODO change
    	liquidityWallet = address(owner());
        treasuryWallet = address(0x49A61ba8E25FBd58cE9B30E1276c4Eb41dD80a80);

        uint256 _liquidityBuyingFee = 25;
        uint256 _treasuryBuyingFee = 75;
        uint256 _burnBuyingFee = 0;

        uint256 _liquiditySellingFee = 50;
        uint256 _treasurySellingFee = 25;
        uint256 _burnSellingFee = 25;

        liquidityBuyingFee = _liquidityBuyingFee;
        treasuryBuyingFee = _treasuryBuyingFee;
        burnBuyingFee = _burnBuyingFee;

        liquiditySellingFee = _liquiditySellingFee;
        treasurySellingFee = _treasurySellingFee;
        burnSellingFee = _burnSellingFee;

        maxBuyingFee = _liquidityBuyingFee.add(_treasuryBuyingFee).add(_burnBuyingFee);
        maxSellingFee = _liquiditySellingFee.add(_treasurySellingFee).add(_burnSellingFee);

        multiplierForTotalFee = 10 ** 3;

        // exclude from receiving rewards
        excludeFromPassiveRewards(address(this), true);
        excludeFromPassiveRewards(liquidityWallet, true);
        excludeFromPassiveRewards(treasuryWallet, true);
        excludeFromPassiveRewards(_pancakePair, true);
        excludeFromPassiveRewards(address(0), true);

        // exclude from paying fees
        excludeFromFees(address(this), true);
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(treasuryWallet, true);

        // enable owner to send tokens before trading is enabled
        canTransferBeforeTradingIsEnabled[owner()] = true;

        _mint(owner(), 1000000000 * (10 ** 18));
    }

    // getters and setters

    function initializeBattling(address contractAddress) external onlyOwner {
        // TODO uncomment
        // require(battling == address(0), "FRTNA: Battling has already been initialized");
        battling = contractAddress;

        excludeFromPassiveRewards(battling, true);
        excludeFromFees(battling, true);
    }

    function setSwapAndLiquifyEnabled(bool state) external onlyOwner {
        require(swapAndLiquifyEnabled != state, "FRTNA: SwapAndLiquifyEnabled is already of the value 'state'");
        swapAndLiquifyEnabled = state;
    }

    function updateBuyingFees(uint256 _liquidityBuyingFee, uint256 _treasuryBuyingFee, uint256 _burnBuyingFee) public onlyOwner {
        uint256 totalInputFee = _liquidityBuyingFee.add(_treasuryBuyingFee).add(_burnBuyingFee);
        require(totalInputFee <= maxBuyingFee, "FRTNA: Cannot exceed total Buying fees");

        liquidityBuyingFee = _liquidityBuyingFee;
        treasuryBuyingFee = _treasuryBuyingFee;
        burnBuyingFee = _burnBuyingFee;
    }

    function updateSellingFees(uint256 _liquiditySellingFee, uint256 _treasurySellingFee, uint256 _burnSellingFee) public onlyOwner {
        uint256 totalInputFee = _liquiditySellingFee.add(_treasurySellingFee).add(_burnSellingFee);
        require(totalInputFee <= maxSellingFee, "FRTNA: Cannot exceed total selling fees");

        liquiditySellingFee = _liquiditySellingFee;
        treasurySellingFee = _treasurySellingFee;
        burnSellingFee = _burnSellingFee;
    }

    function updatePancakeRouter(address newAddress) public onlyOwner {
        require(newAddress != address(pancakeRouter), "FRTNA: The router already has that address");
        emit UpdatePancakeRouter(newAddress, address(pancakeRouter));
        pancakeRouter = IPancakeRouter02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "FRTNA: Account is already the value of 'excluded'");
        isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function excludeFromPassiveRewards(address account, bool excluded) public onlyOwner {
        require(isExcludedFromPassiveRewards[account] != excluded, "FRTNA: Account is already the value of 'excluded'");

        isExcludedFromPassiveRewards[account] = excluded;
    }

    function excludeMultipleAccountsFromPassiveRewards(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromPassiveRewards[accounts[i]] = excluded;
        }
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != pancakePair, "FRTNA: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "FRTNA: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "FRTNA: The liquidity wallet is already this address");
        excludeFromFees(liquidityWallet, false);
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function updateTreasuryWallet(address newTreasuryWallet) public onlyOwner {
        require(newTreasuryWallet != treasuryWallet, "FRTNA: The treasury wallet is already this address");
        excludeFromFees(treasuryWallet, false);
        excludeFromFees(newTreasuryWallet, true);
        emit TreasuryWalletUpdated(newTreasuryWallet, treasuryWallet);
        treasuryWallet = newTreasuryWallet;
    }

    function getTradingIsEnabled() public view returns (bool) {
        return block.timestamp >= tradingEnabledTimestamp;
    }

    // functions

    function _isBuy(address from) internal view returns (bool) {
        // Transfer from pair is a buy swap
        return automatedMarketMakerPairs[from];
    }

    function _isSell(address from, address to) internal view returns (bool) {
        // Transfer to pair from non-router address is a sell swap
        return from != address(pancakeRouter) && automatedMarketMakerPairs[to];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        bool tradingIsEnabled = getTradingIsEnabled();

        if (!tradingIsEnabled) {
            require(canTransferBeforeTradingIsEnabled[from], "FRTNA: This account cannot send tokens until trading is enabled");
        }

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwapAndTransfer = contractTokenBalance >= swapAndTransferTokensAtAmount;

        if (
            tradingIsEnabled &&
            canSwapAndTransfer &&
            !swapping &&
            !_isBuy(from) &&
            from != liquidityWallet &&
            to != liquidityWallet
        ) {
            swapping = true;

            uint256 totalBuyingFeesAccumulated = contractTokenBalance;
            uint256 toLiquidityAmount;
            uint256 toTreasuryAmount;
            uint256 toBurnAmount;

            if (totalSellingFeesAccumulated > 0) {
                totalBuyingFeesAccumulated -= totalSellingFeesAccumulated;

                toLiquidityAmount = totalSellingFeesAccumulated
                    .mul(liquiditySellingFee).div(100);
                if (swapAndLiquifyEnabled) {
                    swapAndLiquify(toLiquidityAmount);
                }
                else {
                    super._transfer(address(this), liquidityWallet, toLiquidityAmount);
                }

                toTreasuryAmount = totalSellingFeesAccumulated
                    .mul(treasurySellingFee).div(100);
                super._transfer(address(this), treasuryWallet, toTreasuryAmount);

                toBurnAmount = totalSellingFeesAccumulated
                    .mul(burnSellingFee).div(100);
                _burn(address(this), toBurnAmount);

                totalSellingFeesAccumulated = 0;
            }
            
            if (totalBuyingFeesAccumulated > 0) {
                toLiquidityAmount = totalBuyingFeesAccumulated
                    .mul(liquidityBuyingFee).div(100);
                if (swapAndLiquifyEnabled) {
                    swapAndLiquify(toLiquidityAmount);
                }
                else {
                    super._transfer(address(this), liquidityWallet, toLiquidityAmount);
                }

                toTreasuryAmount = totalBuyingFeesAccumulated
                    .mul(treasuryBuyingFee).div(100);
                super._transfer(address(this), treasuryWallet, toTreasuryAmount);

                toBurnAmount = totalBuyingFeesAccumulated
                    .mul(burnBuyingFee).div(100);
                _burn(address(this), toBurnAmount);
            }

            swapping = false;
        }

        if (
            _isBuy(from) &&
            !isExcludedFromFees[to]
        ) {
            uint256 totalBuyingFee = liquidityBuyingFee.add(treasuryBuyingFee).add(burnBuyingFee);

            uint256 buyingFee = amount.mul(totalBuyingFee).div(multiplierForTotalFee);
            amount -= buyingFee;

            super._transfer(from, address(this), buyingFee);
        }

        if (
            _isSell(from, to) &&
            !isExcludedFromFees[from]
        ) {
            uint256 totalSellingFee = liquiditySellingFee.add(treasurySellingFee).add(burnSellingFee);

            uint256 sellingFee = amount.mul(totalSellingFee).div(multiplierForTotalFee);
            totalSellingFeesAccumulated += sellingFee;
            amount -= sellingFee;

            super._transfer(from, address(this), sellingFee);
        }

        super._transfer(from, to, amount);

        if (!isExcludedFromPassiveRewards[from]) {
            _updateLedger(from);
        }
 
        if (!isExcludedFromPassiveRewards[to]) {
            _updateLedger(to);
        }
    }

    function updateLedger(address account) external {
        require(!isExcludedFromPassiveRewards[account], "FRTNA: Account is excluded from passive rewards");

        _updateLedger(account);
    }

    function _updateLedger(address account) internal {
        (uint256 totalPassiveRewards, bool isFirstTransaction) =
            fortunasLedger.updatePassiveRewards(account, balanceOf(account));

        uint256 nextPassiveReward =
            fortunasLedger.calculateNextPassiveReward(account, balanceOf(account));

        if (isFirstTransaction) {
            emit LedgerCreated(
                account,
                totalPassiveRewards,
                nextPassiveReward
            );
            return;
        }

        emit LedgerUpdated(
            account,
            totalPassiveRewards,
            nextPassiveReward
        );
    }

    function claimLedger() external {
        require(!isExcludedFromPassiveRewards[msg.sender], "FRTNA: Account is excluded from passive rewards");

        (uint256 totalPassiveRewards, uint256 nextPassiveReward) =
            fortunasLedger.claimPassiveRewards(msg.sender, balanceOf(msg.sender));

        if (totalPassiveRewards == 0) {
            require(false, "FRTNA: No rewards to claim");
        }

        _mint(msg.sender, totalPassiveRewards);

        emit LedgerClaimed(
            msg.sender,
            0,
            nextPassiveReward
        );
    }

    function viewLedger(address account) external view returns (uint256, uint256) {
        require(!isExcludedFromPassiveRewards[account], "FRTNA: Account is excluded from passive rewards");

        (uint256 totalPassiveRewards, uint256 nextPassiveReward) =
            fortunasLedger.getCurrentLedgerStatus(account, balanceOf(account));

        return (totalPassiveRewards, nextPassiveReward);
    }

    function swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp.add(1800)
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp.add(1800)
        );
    }

    function mint(address account, uint256 amount) external onlyContract {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyContract {
        _burn(account, amount);
    }

    function circulatingSupply() external view returns (uint256) {
        return totalSupply().sub(balanceOf(address(battling)));
    }

    modifier onlyContract {
        require(msg.sender == battling, "FRTNA: Only Fortunas Battling Contract can call this function");
        _;
    }

    receive() external payable {

  	}
}
// File: BattlingBase.sol

pragma solidity ^0.8.0;





contract BattlingBase is Ownable {
    using SafeMath for uint256;
    using MathUpgradeable for uint256;

    // variables

    uint256 public rewardTime;                              // 30 minutes in seconds
    uint256 public oneDayTime;                              // 1 day in seconds
    uint256 public baseBattleTime;                          // 3 days in seconds

    uint256 multiplier;
    uint256 multiplierForReward;

    uint256[6] toCollectPercentages;                        // chance to win for every iteration
    uint256 toCollectIncreasePerDay;                        // increase in chance to win for every ration day

    uint256[6] rewardPercentages;                           // reward percentage per day
    uint256[6] rewardPercentagesPerCycle;                   // reward percentage per reward iteration
    uint256[6] public minStakeAmount;                       // minimum stake amount to be able to receive rewards

    // structs

    struct Battle {
        uint8 battleType;
        uint256 initialTokensStaked;
        uint256 additionalTokens;
        uint256 rewards;
        uint256 rations;
        uint256 passiveRewards;//
        uint256 currentRewardPercentagePerCycle;//
        uint256 currentToCollectPercentage;//
        uint256 battleStartTime;
        uint256 battleDaysExpended;
        uint256 rationsDaysTotal;
        uint256 hero;
        uint256 cavalry;
    }

    // constructor

    constructor() {
        // TODO
        // rewardTime = 1800;
        // oneDayTime = 86400;
        // baseBattleTime = 259200;
        rewardTime = 1;
        oneDayTime = 48;
        baseBattleTime = 144;

        multiplier = 10 ** 6;
        multiplierForReward = 10 ** 9;

        toCollectPercentages = [1000, 1000, 750, 500, 200, 100];
        toCollectIncreasePerDay = 5;

        rewardPercentages = [2500000, 5000000, 10000000, 12500000, 20000000, 25000000];
        _setRewards();
    }

    // setters

    function _setRewards() internal {
        for (uint256 i = 0 ; i < 6 ; i++) {
            rewardPercentagesPerCycle[i] = rewardPercentages[i].roundDiv(48);
            minStakeAmount[i] = multiplierForReward.ceilDiv(rewardPercentagesPerCycle[i]);
        }
    }
}
// File: BattlingExtension.sol

pragma solidity ^0.8.0;









contract BattlingExtension is BattlingBase {
    using SafeMath for uint256;
    using MathUpgradeable for uint256;

    // RNG variables

    IPancakeRouter02 public rng_pancakeRouter;
    IPancakeFactory public rng_pancakeFactory;

    IPancakePair public rng_pancakePair1;
    IPancakePair public rng_pancakePair2;
    IPancakePair public rng_pancakePair3;
    IPancakePair public rng_pancakePair4;

    // variables

    uint256[5] public rationsPercentages;                   // rations %
    uint256 public rationsIncreasePercentage;               // percentage increase in rations percentages when to collect limit is reached

    // constructor

    constructor() {
        // PancakeRouter02 mainnet
        // IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        // TODO remove
        IPancakeRouter02 _pancakeRouter;
        if (block.chainid == 97) {
            _pancakeRouter = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        }
        else if (block.chainid == 4) {
            _pancakeRouter = IPancakeRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        }
        IPancakeFactory _pancakeFactory = IPancakeFactory(_pancakeRouter.factory());

        address _addressForPancakePair1 = _pancakeFactory.allPairs(0);
        address _addressForPancakePair2 = _pancakeFactory.allPairs(1);
        address _addressForPancakePair3 = _pancakeFactory.allPairs(2);
        address _addressForPancakePair4 = _pancakeFactory.allPairs(3);

        rng_pancakeRouter = _pancakeRouter;
        rng_pancakeFactory = _pancakeFactory;

        rng_pancakePair1 = IPancakePair(_addressForPancakePair1);
        rng_pancakePair2 = IPancakePair(_addressForPancakePair2);
        rng_pancakePair3 = IPancakePair(_addressForPancakePair3);
        rng_pancakePair4 = IPancakePair(_addressForPancakePair4);

        rationsPercentages = [2500, 5000, 7500, 10000, 12500];
        rationsIncreasePercentage = 125000;
    }

    // RNG functions

    function createRandomness(uint256 _chance, uint256 _multiplier) public view onlyOwner returns (bool) {
        uint256 a = rng_pancakePair1.price0CumulativeLast();
        uint256 b = rng_pancakePair1.price1CumulativeLast();

        uint256 c = rng_pancakePair2.price0CumulativeLast();
        uint256 d = rng_pancakePair2.price1CumulativeLast();

        uint256 e = rng_pancakePair3.price0CumulativeLast();
        uint256 f = rng_pancakePair3.price1CumulativeLast();

        uint256 g = rng_pancakePair4.price0CumulativeLast();
        uint256 h = rng_pancakePair4.price1CumulativeLast();

        uint256 randomChance =
            uint256(keccak256(abi.encodePacked(a, b, c, d, e, f, g, h, block.timestamp))).mod(_multiplier).add(1);

        return randomChance <= _chance;
    }

    function createRandomnessForAsset() external view onlyOwner returns (uint256) {
        uint256 result;

        uint256 a = rng_pancakePair1.price0CumulativeLast();
        uint256 b = rng_pancakePair1.price1CumulativeLast();
        (uint256 c, , ) = rng_pancakePair1.getReserves();

        uint256 d = rng_pancakePair2.price0CumulativeLast();
        uint256 e = rng_pancakePair2.price1CumulativeLast();
        (uint256 f, , ) = rng_pancakePair2.getReserves();

        uint256 g = rng_pancakePair3.price0CumulativeLast();
        uint256 h = rng_pancakePair3.price1CumulativeLast();
        (uint256 i, , ) = rng_pancakePair3.getReserves();

        uint256 randomChance = uint256(keccak256(abi.encodePacked(a, b, c, d, e, f, g, h, i, block.timestamp))).mod(100).add(1);

        if (randomChance <= 50) {
            result = 1;
        }
        else if (50 < randomChance && randomChance <= 75) {
            result = 2;
        }
        else if (75 < randomChance && randomChance <= 90) {
            result = 3;
        }
        else if (90 < randomChance && randomChance <= 99) {
            result = 4;
        }
        else if (randomChance == 100) {
            result = 5;
        }

        return result;
    }

    function determineRewardCycles(
        uint256 _currentToCollectPercentage,
        uint256 _numberOfCycles,
        bool isStatic
    ) internal view returns (uint256, uint256) {
        uint256 numberOfWins;

        if (isStatic) {
            for (uint256 i = 0 ; i < _numberOfCycles ; i++) {
                bool result = createRandomness(_currentToCollectPercentage, 1000);

                if (result) {
                    numberOfWins++;
                }
            }
        }
        else {
            for (uint256 i = 0 ; i < _numberOfCycles ; i++) {
                if (i.mod(48) == 0) {
                    _currentToCollectPercentage += toCollectIncreasePerDay;
                }

                if (_currentToCollectPercentage == 1000) {
                    numberOfWins += _numberOfCycles.sub(i);
                    break;
                }

                bool result = createRandomness(_currentToCollectPercentage, 1000);

                if (result) {
                    numberOfWins++;
                }
            }
        }

        return (_currentToCollectPercentage, numberOfWins);
    }

    // functions

    function calculateRations(
        Battle memory _tempBattle,
        uint256 _extraRewards,
        uint256 _rationDays
    ) external view onlyOwner returns (Battle memory, uint256) {
        uint256 tempTotalTokens = _tempBattle.initialTokensStaked.add(_tempBattle.additionalTokens).add(_tempBattle.rewards).add(_extraRewards);
        uint256 tempRations;

        if (_tempBattle.currentToCollectPercentage == 1000) {
            tempRations = tempTotalTokens.mul(rationsPercentages[_rationDays - 1]).div(multiplier);

            uint256 rationsIncreaseAmount = _compound(
                tempRations,
                rationsIncreasePercentage,
                _rationDays
            );

            tempRations += rationsIncreaseAmount;
        }

        return (_tempBattle, tempRations);
    }

    function calculateRewards(Battle memory _tempBattle) public view onlyOwner returns (Battle memory) {
        uint256 tempTotalTokens = _tempBattle.initialTokensStaked.add(_tempBattle.additionalTokens).add(_tempBattle.rewards);

        uint256 daysWagingBattle = block.timestamp.sub(_tempBattle.battleStartTime).div(oneDayTime);

        uint256 ratio = _tempBattle.currentRewardPercentagePerCycle.mul(10 ** 18).div(multiplierForReward);

        uint256 daysForReward;
        uint256 cyclesForReward;
        uint256 compoundReward;

        if (daysWagingBattle.sub(_tempBattle.battleDaysExpended) != 0) {
            if (daysWagingBattle < 3) {
                daysForReward = daysWagingBattle.sub(_tempBattle.battleDaysExpended);

                if (_tempBattle.currentToCollectPercentage != 1000) {
                    (, cyclesForReward) = determineRewardCycles(
                        _tempBattle.currentToCollectPercentage,
                        daysForReward.mul(48),
                        true
                    );
                }

                compoundReward = _compound(
                    tempTotalTokens,
                    ratio,
                    cyclesForReward
                );
                _tempBattle.rewards += compoundReward;
            }
            else if (
                daysWagingBattle >= 3 &&
                daysWagingBattle < _tempBattle.rationsDaysTotal.add(3) &&
                _tempBattle.rationsDaysTotal > 0
            ) {
                if (_tempBattle.battleDaysExpended < 3) {
                    daysForReward = uint256(3).sub(_tempBattle.battleDaysExpended);

                    if (_tempBattle.currentToCollectPercentage != 1000) {
                        (, cyclesForReward) = determineRewardCycles(
                            _tempBattle.currentToCollectPercentage,
                            daysForReward.mul(48),
                            true
                        );
                    }

                    compoundReward = _compound(
                        tempTotalTokens,
                        ratio,
                        cyclesForReward
                    );
                    _tempBattle.rewards += compoundReward;
                    tempTotalTokens += compoundReward;

                    _tempBattle.battleDaysExpended = 3;
                }

                daysForReward = daysWagingBattle.sub(_tempBattle.battleDaysExpended);

                if (_tempBattle.currentToCollectPercentage != 1000) {
                    (_tempBattle.currentToCollectPercentage, cyclesForReward) = determineRewardCycles(
                        _tempBattle.currentToCollectPercentage,
                        daysForReward.mul(48),
                        false
                    );
                }

                compoundReward = _compound(
                    tempTotalTokens,
                    ratio,
                    cyclesForReward
                );
                _tempBattle.rewards += compoundReward;
                tempTotalTokens += compoundReward;
            }

            _tempBattle.battleDaysExpended = daysWagingBattle;
        }

        require(
            block.timestamp <
            _tempBattle.battleStartTime.add(baseBattleTime).add(_tempBattle.rationsDaysTotal.mul(oneDayTime)),
            "calculateRewards::BE"
        );

        return _tempBattle;
    }

    function calculateExtraRewards(Battle memory _tempBattle) public view onlyOwner returns (uint256, uint256) {
        uint256 tempTotalTokens = _tempBattle.initialTokensStaked.add(_tempBattle.additionalTokens).add(_tempBattle.rewards);

        uint256 cyclesRemaining = block.timestamp.sub(_tempBattle.battleDaysExpended.mul(oneDayTime).add(_tempBattle.battleStartTime)).div(rewardTime);
        uint256 cyclesForReward;

        uint256 ratio = _tempBattle.currentRewardPercentagePerCycle.mul(10 ** 18).div(multiplierForReward);

        if (_tempBattle.currentToCollectPercentage != 1000) {
            (, cyclesForReward) = determineRewardCycles(
                _tempBattle.currentToCollectPercentage,
                cyclesRemaining,
                true
            );
        }

        uint256 extraRewards = _compound(
            tempTotalTokens,
            ratio,
            cyclesForReward
        );
        tempTotalTokens += extraRewards;

        uint256 nextReward = _compound(
            tempTotalTokens,
            ratio,
            1
        );

        return (extraRewards, nextReward);
    }

    function calculateRewardsForEndBattle(
        Battle memory _tempBattle
    ) external view onlyOwner returns (Battle memory) {
        uint256 battleEndTime = _tempBattle.rationsDaysTotal.add(3).mul(oneDayTime).add(_tempBattle.battleStartTime);

        if (block.timestamp < battleEndTime && _tempBattle.battleType != 2) {
            _tempBattle = calculateRewards(_tempBattle);

            (uint256 extraRewards, ) = calculateExtraRewards(_tempBattle);
            _tempBattle.rewards += extraRewards;
        }
        else {
            uint256 tempTotalTokens = _tempBattle.initialTokensStaked.add(_tempBattle.additionalTokens).add(_tempBattle.rewards);

            uint256 daysWagingBattle = _tempBattle.rationsDaysTotal.add(3);
            uint256 daysForReward = daysWagingBattle.sub(_tempBattle.battleDaysExpended);

            uint256 ratio = _tempBattle.currentRewardPercentagePerCycle.mul(10 ** 18).div(multiplierForReward);

            uint256 cyclesForReward;
            uint256 compoundReward;

            if (_tempBattle.battleType == 2) {
                require(block.timestamp >= battleEndTime, "calculateRewardsForEndBattle::BNE");

                if (_tempBattle.currentToCollectPercentage != 1000) {
                    (, cyclesForReward) = determineRewardCycles(
                        _tempBattle.currentToCollectPercentage,
                        daysForReward.mul(48),
                        true
                    );
                }

                compoundReward = _compound(
                    tempTotalTokens,
                    ratio,
                    cyclesForReward
                );
                _tempBattle.rewards += compoundReward;
            }
            else {
                if (_tempBattle.battleDaysExpended < 3) {
                    daysForReward = uint256(3).sub(_tempBattle.battleDaysExpended);

                    if (_tempBattle.currentToCollectPercentage != 1000) {
                        (, cyclesForReward) = determineRewardCycles(
                            _tempBattle.currentToCollectPercentage,
                            daysForReward.mul(48),
                            true
                        );
                    }

                    compoundReward = _compound(
                        tempTotalTokens,
                        ratio,
                        cyclesForReward
                    );
                    _tempBattle.rewards += compoundReward;
                    tempTotalTokens += compoundReward;

                    _tempBattle.battleDaysExpended = 3;
                }

                daysForReward = daysWagingBattle.sub(_tempBattle.battleDaysExpended);

                bool continueBattle = daysForReward != 0;

                if (continueBattle) {
                    daysForReward = daysWagingBattle.sub(_tempBattle.battleDaysExpended);

                    if (_tempBattle.currentToCollectPercentage != 1000) {
                        (_tempBattle.currentToCollectPercentage, cyclesForReward) = determineRewardCycles(
                            _tempBattle.currentToCollectPercentage,
                            daysForReward.mul(48),
                            false
                        );
                    }

                    compoundReward = _compound(
                        tempTotalTokens,
                        ratio,
                        cyclesForReward
                    );
                    _tempBattle.rewards += compoundReward;
                    tempTotalTokens += compoundReward;
                }
            }

            _tempBattle.battleDaysExpended = daysWagingBattle;

            // TODO change "60" to "rewardTime"
            uint256 passiveRewardCycles = block.timestamp.sub(battleEndTime).div(60);

            ratio = rewardPercentages[0].mul(10 ** 18).div(multiplierForReward);

            _tempBattle.passiveRewards = _compound(
                tempTotalTokens,
                ratio,
                passiveRewardCycles
            );
        }

        return _tempBattle;
    }

    function _compound(uint256 _principal, uint256 _ratio, uint256 _exponent) internal pure returns (uint256) {
        if (_exponent == 0) {
            return _principal;
        }

        bool isInteger = _ratio.mod(10000000) == 0;

        uint256 accruedReward = ABDKMath64x64.mulu(ABDKMath64x64.pow(ABDKMath64x64.add(ABDKMath64x64.fromUInt(1), ABDKMath64x64.divu(_ratio,10**18)), _exponent), _principal);

        if (isInteger) {
            accruedReward++;
        }

        return accruedReward.sub(_principal);
    }

    // testing only
    function testRewardTime(uint256 _seconds) public {
        rewardTime = _seconds;
        oneDayTime = _seconds.mul(48);
        baseBattleTime = _seconds.mul(144);
    }

    function testToCollectPercentage(uint256 _chanceToCollect) public {
        toCollectPercentages = [1000, 1000, _chanceToCollect, _chanceToCollect, _chanceToCollect, _chanceToCollect];
    }
}
// File: Battling.sol

pragma solidity ^0.8.0;













contract Battling is BattlingBase, ERC1155Holder {
    using SafeMath for uint256;
    using MathUpgradeable for uint256;

    // BUSD mainnet
    // address public BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    // TODO remove
    address public BUSD;

    // PancakeSwap
    IPancakeRouter02 public pancakeRouter;
    IPancakePair public pancakePair;

    // LP Token for FRTNA-BUSD pair
    IERC20 public LPToken;

    // FRTNA
    FortunasToken public fortunasToken;

    // Fortunas Multi Token for heroes and cavalry
    IFortunasAssets public fortunasAssets;

    // Contract that handles calculations for Battling
    BattlingExtension public battlingExtension;

    // Treasury Wallet
    address public treasuryWallet;

    // Initial cost of supplies to send troops to battle
    uint256 public suppliesCost;

    // Initial staked tokens percentage at which battle resets
    uint256 public battleResetPercentage;

    // Each hero's/cavalry's effect on current/total battle APY
    uint256[10] public assetPercentages;

    // Percentage cost of LP for purchasing each hero/cavalry
    uint256[10] public assetPrices;

    // Percentage cost of LP for purchasing a random hero
    uint256 public randomAssetPrice;

    // Percentage chance of losing hero/cavalry in a battle that is being ended or having tokens removed
    uint256 public loseAssetChance;

    // mappings

    mapping (address => mapping(uint8 => Battle)) private battleForAddress;

    // events

    event BattleStarted (
        address indexed user,
        uint256 battleType,
        bool battleStatus,
        uint256 initialTokensStaked,
        uint256 additionalTokens,
        uint256 rewards,
        uint256 rations,
        uint256 passiveRewards,
        uint256 battleStartTime,
        uint256 battleDurationInDays,
        uint256 hero,
        uint256 cavalry
    );

    event BattleUpdated (
        address indexed user,
        uint256 battleType,
        bool battleStatus,
        uint256 initialTokensStaked,
        uint256 additionalTokens,
        uint256 rewards,
        uint256 rations,
        uint256 passiveRewards,
        uint256 battleStartTime,
        uint256 battleDurationInDays,
        uint256 hero,
        uint256 cavalry
    );

    event BattleEnded (
        address indexed user,
        uint256 battleType,
        bool battleStatus,
        uint256 initialTokensStaked,
        uint256 additionalTokens,
        uint256 rewards,
        uint256 rations,
        uint256 passiveRewards,
        uint256 battleStartTime,
        uint256 battleDurationInDays,
        uint256 hero,
        uint256 cavalry
    );

    event AssetPurchased (address indexed user, uint256 asset, uint256 amount);

    event AssetDeployed (address indexed user, uint256 asset, uint256 amount);

    event AssetReturned (address indexed user, uint256 asset, uint256 amount);

    event AssetLost (address indexed user, uint256 asset, uint256 amount);

    // constructor

    /*
     * @dev all rations related variables for battling are defined and initialized in base class
     * @dev all reward related variables for battling are defined base class
     * @dev all reward related variables for battling are initialized outside of constructor in parent class
     */
    constructor(address _fortunasToken, address _fortunasAssets) {
        // TODO remove
        if (block.chainid == 97) {
            BUSD = 0x8354e8b945D6C35bD35615DD0277C4032cd0a67D;
        }
        else if (block.chainid == 4) {
            BUSD = 0x7D9385C733a967793EE14D933212ee44025f1B9d;
        }

        // PancakeRouter02 mainnet
        // IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        // TODO remove
        IPancakeRouter02 _pancakeRouter;
        if (block.chainid == 97) {
            _pancakeRouter = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        }
        else if (block.chainid == 4) {
            _pancakeRouter = IPancakeRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        }
        address _addressForPancakePair = IPancakeFactory(_pancakeRouter.factory()).getPair(_fortunasToken, BUSD);

        pancakeRouter = _pancakeRouter;
        pancakePair = IPancakePair(_addressForPancakePair);

        LPToken = IERC20(_addressForPancakePair);

        fortunasToken = FortunasToken(payable(_fortunasToken));

        fortunasAssets = IFortunasAssets(_fortunasAssets);

        battlingExtension = new BattlingExtension();

        // TODO change
        treasuryWallet = 0x49A61ba8E25FBd58cE9B30E1276c4Eb41dD80a80;

        suppliesCost = 5000;

        battleResetPercentage = 200;

        assetPercentages = [20, 40, 60, 80, 100,
                            2083, 4167, 6250, 8333, 10417];

        assetPrices = [2500, 5000, 7500, 10000, 12500,
                        2500, 5000, 7500, 10000, 12500];

        randomAssetPrice = 5000;

        loseAssetChance = 50;
    }

    // getters

    function getBattleForAddress(address _user, uint8 _battleType) external view returns (Battle memory) {
        return battleForAddress[_user][_battleType];
    }

    // setters

    function setTreasuryWallet(address _treasuryWallet) external onlyOwner {
        treasuryWallet = _treasuryWallet;
    }

    function setBattleResetPercentage(uint256 _battleResetPercentage) external onlyOwner {
        battleResetPercentage = _battleResetPercentage;
    }

    // functions

    function startBattle(
        uint256 _amount,
        uint8 _battleType
    ) external {
        require(_amount >= minStakeAmount[_battleType - 1], "startBattle::MIN");
        require(2 <= _battleType && _battleType <= 6, "startBattle::WBT1");
        require(battleForAddress[msg.sender][_battleType].initialTokensStaked == 0, "startBattle::BAS");

        if (_battleType == 2) {
            LPToken.transferFrom(msg.sender, address(this), _amount);
        }
        else {
            uint256 supplies = _amount.mul(suppliesCost).div(multiplier);
            _amount -= supplies;

            fortunasToken.transferFrom(msg.sender, treasuryWallet, supplies);

            fortunasToken.transferFrom(msg.sender, address(this), _amount);
        }

        battleForAddress[msg.sender][_battleType] = Battle(_battleType, _amount, 0, 0, 0, 0, rewardPercentagesPerCycle[_battleType - 1], toCollectPercentages[_battleType - 1], block.timestamp, 0, 0, 0, 0);

        emit BattleStarted (
            msg.sender,
            _battleType,
            true,
            _amount,
            0, 0, 0, 0,
            battleForAddress[msg.sender][_battleType].battleStartTime,
            3, 0, 0
        );
    }

    function sendRations(
        uint256 _rationDays,
        uint8 _battleType
    ) external validBattleType(_battleType) validBattle(_battleType) {
        Battle memory tempBattle = battleForAddress[msg.sender][_battleType];

        require(1 <= _rationDays && _rationDays <= 5, "sendRations::WR1");

        if (tempBattle.rationsDaysTotal != 0) {
            uint256 rationsExpended = 
                block.timestamp.sub(tempBattle.battleStartTime.add(baseBattleTime)).ceilDiv(oneDayTime);
            uint256 currentRationsDays =
                tempBattle.rationsDaysTotal.sub(rationsExpended).add(_rationDays);
            require(currentRationsDays <= 5, "sendRations::WR2");
        }

        tempBattle = battlingExtension.calculateRewards(tempBattle);

        (uint256 extraRewards, ) = battlingExtension.calculateExtraRewards(tempBattle);

        uint256 tempRations;
        (tempBattle, tempRations) = battlingExtension.calculateRations(tempBattle, extraRewards, _rationDays);

        fortunasToken.burn(msg.sender, tempRations);

        battleForAddress[msg.sender][_battleType].rations += tempRations;
        battleForAddress[msg.sender][_battleType].rationsDaysTotal += _rationDays;

        tempBattle = battleForAddress[msg.sender][_battleType];

        emit BattleUpdated (
            msg.sender,
            _battleType,
            true,
            tempBattle.initialTokensStaked,
            tempBattle.additionalTokens,
            tempBattle.rewards,
            tempBattle.rations,
            tempBattle.passiveRewards,
            tempBattle.battleStartTime,
            tempBattle.rationsDaysTotal.add(3),
            tempBattle.hero,
            tempBattle.cavalry
        );
    }

    function addTroops(
        uint256 _amountToAdd,
        uint8 _battleType
    ) external validBattle(_battleType) {
        Battle memory tempBattle = battleForAddress[msg.sender][_battleType];

        tempBattle = battlingExtension.calculateRewards(tempBattle);

        tempBattle.additionalTokens += _amountToAdd;
        if (tempBattle.additionalTokens >
            tempBattle.initialTokensStaked.mul(battleResetPercentage).div(100)) {
            tempBattle.currentToCollectPercentage = toCollectPercentages[tempBattle.battleType - 1];
            if (tempBattle.hero != 0) {
                tempBattle.currentToCollectPercentage += assetPercentages[tempBattle.hero - 1];
            }
        }

        fortunasToken.transferFrom(msg.sender, address(this), _amountToAdd);

        battleForAddress[msg.sender][_battleType] = tempBattle;

        emit BattleUpdated (
            msg.sender,
            _battleType,
            true,
            tempBattle.initialTokensStaked,
            tempBattle.additionalTokens,
            tempBattle.rewards,
            tempBattle.rations,
            tempBattle.passiveRewards,
            tempBattle.battleStartTime,
            tempBattle.rationsDaysTotal.add(3),
            tempBattle.hero,
            tempBattle.cavalry
        );
    }

    function removeTroops(
        uint256 _amountToRemove,
        uint8 _battleType
    ) external validBattle(_battleType) {
        Battle memory tempBattle = battleForAddress[msg.sender][_battleType];

        tempBattle = battlingExtension.calculateRewards(tempBattle);

        uint256 tempTotalTokens = tempBattle.initialTokensStaked.add(tempBattle.additionalTokens).add(tempBattle.rewards);
        require(_amountToRemove < tempTotalTokens, "removeTroops::WA");
        require(minStakeAmount[_battleType - 1] <= tempTotalTokens.sub(_amountToRemove), "removeTroops::MIN");

        uint256 tempAmountToRemove = _amountToRemove;
        if (tempAmountToRemove > tempBattle.additionalTokens) {
            uint256 rewardsToMint;

            tempAmountToRemove -= tempBattle.additionalTokens;
            tempBattle.additionalTokens = 0;
            if (tempAmountToRemove > tempBattle.rewards) {
                rewardsToMint = tempBattle.rewards;
                tempAmountToRemove -= tempBattle.rewards;
                tempBattle.rewards = 0;
                tempBattle.initialTokensStaked -= tempAmountToRemove;
            }
            else {
                rewardsToMint = tempAmountToRemove;
                tempBattle.rewards -= tempAmountToRemove;
            }

            bool isMint = rewardsToMint != 0;

            if (isMint) {
                fortunasToken.mint(msg.sender, rewardsToMint);
                _amountToRemove -= rewardsToMint;
            }
        }
        else {
            tempBattle.additionalTokens -= tempAmountToRemove;
        }

        fortunasToken.transfer(msg.sender, _amountToRemove);

        uint256 chanceToLoseAssets = loseAssetChance;

        if (tempBattle.battleDaysExpended > 3) {
            uint256 chanceDecrease = tempBattle.battleDaysExpended.sub(3).mul(5);
            chanceToLoseAssets = chanceToLoseAssets.safeSub(chanceDecrease);
        }

        if (chanceToLoseAssets != 0) {
            tempBattle = handleLoss(tempBattle, chanceToLoseAssets, false);
        }

        battleForAddress[msg.sender][_battleType] = tempBattle;

        emit BattleUpdated (
            msg.sender,
            _battleType,
            true,
            tempBattle.initialTokensStaked,
            tempBattle.additionalTokens,
            tempBattle.rewards,
            tempBattle.rations,
            tempBattle.passiveRewards,
            tempBattle.battleStartTime,
            tempBattle.rationsDaysTotal.add(3),
            tempBattle.hero,
            tempBattle.cavalry
        );
    }

    function purchaseAsset(
        uint256 _assetToPurchase
    ) external {
        require(0 <= _assetToPurchase && _assetToPurchase <= 10, "purchaseHero::WA");

        uint256 pricePercentage;
        if (_assetToPurchase == 0) {
            pricePercentage = randomAssetPrice;
            _assetToPurchase = battlingExtension.createRandomnessForAsset();
        }
        else {
            pricePercentage = assetPrices[_assetToPurchase - 1];
        }

        uint256 reserves;
        if (address(fortunasToken) == pancakePair.token0()) {
            (reserves, , ) = pancakePair.getReserves();
        }
        else {
            (, reserves, ) = pancakePair.getReserves();
        }

        uint256 price = reserves.mul(pricePercentage).roundDiv(multiplier);
        fortunasToken.transferFrom(msg.sender, address(this), price);

        fortunasAssets.mint(msg.sender, _assetToPurchase, 1, "");

        emit AssetPurchased (
            msg.sender,
            _assetToPurchase,
            fortunasAssets.balanceOf(msg.sender, _assetToPurchase)
        );
    }

    function deployAsset(
        uint256 _assetToDeploy,
        uint8 _battleType
    ) external validBattleType(_battleType) validBattle(_battleType) {
        Battle memory tempBattle = battleForAddress[msg.sender][_battleType];

        require(1 <= _assetToDeploy && _assetToDeploy <= 10, "deployAsset::WA");
        require(fortunasAssets.balanceOf(msg.sender, _assetToDeploy) > 0, "deployAsset::ANO");

        if (_assetToDeploy <= 5) {
            require(tempBattle.hero == 0, "deployAsset::HIB");

            tempBattle = battlingExtension.calculateRewards(tempBattle);

            tempBattle.currentToCollectPercentage += assetPercentages[_assetToDeploy - 1];

            tempBattle.hero = _assetToDeploy;
        }
        else {
            require(tempBattle.cavalry == 0, "deployAsset::CIB");

            tempBattle = battlingExtension.calculateRewards(tempBattle);

            tempBattle.currentRewardPercentagePerCycle += assetPercentages[_assetToDeploy - 1];

            tempBattle.cavalry = _assetToDeploy;
        }

        fortunasAssets.safeTransferFromWithCheck(msg.sender, address(this), _assetToDeploy, 1, "");

        battleForAddress[msg.sender][_battleType] = tempBattle;

        emit AssetDeployed (
            msg.sender,
            _assetToDeploy,
            fortunasAssets.balanceOf(msg.sender, _assetToDeploy)
        );

        emit BattleUpdated (
            msg.sender,
            _battleType,
            true,
            tempBattle.initialTokensStaked,
            tempBattle.additionalTokens,
            tempBattle.rewards,
            tempBattle.rations,
            tempBattle.passiveRewards,
            tempBattle.battleStartTime,
            tempBattle.rationsDaysTotal.add(3),
            tempBattle.hero,
            tempBattle.cavalry
        );
    }

    function returnAsset(
        uint256 _assetToReturn,
        uint8 _battleType
    ) public validBattleType(_battleType) validBattle(_battleType) {
        Battle memory tempBattle = battleForAddress[msg.sender][_battleType];

        require(1 <= _assetToReturn && _assetToReturn <= 10, "returnAsset::WA");

        if (_assetToReturn <= 5) {
            require(tempBattle.hero == _assetToReturn, "returnAsset::HNIB");

            tempBattle = battlingExtension.calculateRewards(tempBattle);

            tempBattle.currentToCollectPercentage -= assetPercentages[_assetToReturn - 1];

            tempBattle.hero = 0;
        }
        else {
            require(tempBattle.cavalry == _assetToReturn, "returnAsset::CNIB");

            tempBattle = battlingExtension.calculateRewards(tempBattle);

            tempBattle.currentRewardPercentagePerCycle -= assetPercentages[_assetToReturn - 1];

            tempBattle.cavalry = 0;
        }

        fortunasAssets.safeTransferFromWithCheck(address(this), msg.sender, _assetToReturn, 1, "");

        battleForAddress[msg.sender][_battleType] = tempBattle;

        emit AssetReturned (
            msg.sender,
            _assetToReturn,
            fortunasAssets.balanceOf(msg.sender, _assetToReturn)
        );

        emit BattleUpdated (
            msg.sender,
            _battleType,
            true,
            tempBattle.initialTokensStaked,
            tempBattle.additionalTokens,
            tempBattle.rewards,
            tempBattle.rations,
            tempBattle.passiveRewards,
            tempBattle.battleStartTime,
            tempBattle.rationsDaysTotal.add(3),
            tempBattle.hero,
            tempBattle.cavalry
        );
    }

    function endBattle(
        uint8 _battleType
    ) external {
        Battle memory tempBattle = battleForAddress[msg.sender][_battleType];
        require(2 <= _battleType && _battleType <= 6, "endBattle::WBT1");
        require(tempBattle.initialTokensStaked != 0, "endBattle:WB");

        tempBattle = battlingExtension.calculateRewardsForEndBattle(tempBattle);

        if (_battleType == 2) {
            LPToken.transfer(msg.sender, tempBattle.initialTokensStaked);

            uint256 rewardsToMint = tempBattle.rewards.add(tempBattle.passiveRewards);

            bool isMint = rewardsToMint != 0;

            if (isMint) {
                fortunasToken.mint(msg.sender, rewardsToMint);
            }
        }
        else {
            uint256 tokensToReturn = tempBattle.initialTokensStaked.add(tempBattle.additionalTokens);

            uint256 rewardsToMint = tempBattle.rewards.add(tempBattle.passiveRewards);

            bool isMint = rewardsToMint != 0;

            if (isMint) {
                fortunasToken.mint(msg.sender, rewardsToMint);
            }

            fortunasToken.transfer(msg.sender, tokensToReturn);

            uint256 chanceToLoseAssets = loseAssetChance;

            if (tempBattle.battleDaysExpended > 3) {
                uint256 chanceDecrease = tempBattle.battleDaysExpended.sub(3).mul(5);
                chanceToLoseAssets = chanceToLoseAssets.safeSub(chanceDecrease);
            }

            if (chanceToLoseAssets != 0) {
                tempBattle = handleLoss(tempBattle, chanceToLoseAssets, true);
            }
        }

        Battle memory emptyBattle;
        battleForAddress[msg.sender][_battleType] = emptyBattle;

        emit BattleEnded (
            msg.sender,
            _battleType,
            false,
            tempBattle.initialTokensStaked,
            tempBattle.additionalTokens,
            tempBattle.rewards,
            tempBattle.passiveRewards,
            0, 0, 0, 0, 0
        );
    }

    function handleLoss(
        Battle memory _tempBattle,
        uint256 _chanceToLoseAssets,
        bool _isEndBattle
    ) internal returns (Battle memory) {
        bool isHeroLost;
        bool isCavalryLost;

        if (_tempBattle.hero != 0 && _tempBattle.cavalry != 0) {
            isHeroLost = battlingExtension.createRandomness(_chanceToLoseAssets, 100);
            isCavalryLost = battlingExtension.createRandomness(_chanceToLoseAssets, 100);
        }
        else if (_tempBattle.hero != 0) {
            isHeroLost = battlingExtension.createRandomness(_chanceToLoseAssets, 100);
        }
        else if (_tempBattle.cavalry != 0) {
            isCavalryLost = battlingExtension.createRandomness(_chanceToLoseAssets, 100);
        }

        if (isHeroLost) {
            fortunasAssets.burnWithCheck(address(this), _tempBattle.hero, 1);

            if (!_isEndBattle) {
                _tempBattle.currentToCollectPercentage -= assetPercentages[_tempBattle.hero - 1];
            }

            emit AssetLost (
                msg.sender,
                _tempBattle.hero,
                fortunasAssets.balanceOf(msg.sender, _tempBattle.hero)
            );

            _tempBattle.hero = 0;
        }

        if (isCavalryLost) {
            fortunasAssets.burnWithCheck(address(this), _tempBattle.cavalry, 1);

            if (!_isEndBattle) {
                _tempBattle.currentRewardPercentagePerCycle -= assetPercentages[_tempBattle.cavalry - 1];
            }

            emit AssetLost (
                msg.sender,
                _tempBattle.cavalry,
                fortunasAssets.balanceOf(msg.sender, _tempBattle.cavalry)
            );

            _tempBattle.cavalry = 0;
        }

        if (_isEndBattle) {
            if (_tempBattle.hero != 0) {
                fortunasAssets.safeTransferFromWithCheck(address(this), msg.sender, _tempBattle.hero, 1, "");

                emit AssetReturned (
                    msg.sender,
                    _tempBattle.hero,
                    fortunasAssets.balanceOf(msg.sender, _tempBattle.hero)
                );
            }

            if (_tempBattle.cavalry != 0) {
                fortunasAssets.safeTransferFromWithCheck(address(this), msg.sender, _tempBattle.cavalry, 1, "");

                emit AssetReturned (
                    msg.sender,
                    _tempBattle.cavalry,
                    fortunasAssets.balanceOf(msg.sender, _tempBattle.cavalry)
                );
            }
        }

        return _tempBattle;
    }

    /*
     * @dev Should be called if updated battle data needed
     * @dev Ideally to be called only if an update on current reward amount is needed
     * @dev Function "endBattle" should be called if unstaking
     */
    function viewAllRewards(
        address _user
    ) external view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory tempRewards = new uint256[](5);
        uint256[] memory nextRewards = new uint256[](5);
        uint256 extraRewards;
        Battle memory tempBattle;
        for (uint8 i = 0 ; i < 5 ; i++) {
            tempBattle = battleForAddress[_user][i + 2];
            if (tempBattle.initialTokensStaked != 0) {
                if (block.timestamp <
                    tempBattle.battleStartTime.add(baseBattleTime).add(tempBattle.rationsDaysTotal.mul(oneDayTime))) {
                    tempBattle = battlingExtension.calculateRewards(tempBattle);

                    (extraRewards, nextRewards[i]) = battlingExtension.calculateExtraRewards(tempBattle);
                    tempBattle.rewards += extraRewards;
                }
                else {
                    tempBattle = battlingExtension.calculateRewardsForEndBattle(tempBattle);
                }
            }
            tempRewards[i] = tempBattle.rewards;
        }

        return (tempRewards, nextRewards);
    }

    // modifiers

    modifier validBattle(uint8 _battleType) {
        _validBattle(_battleType);
        _;
    }

    function _validBattle(uint8 _battleType) internal view {
        Battle memory tempBattle = battleForAddress[msg.sender][_battleType];
        require(tempBattle.initialTokensStaked != 0, "Battling:WB");
        require(block.timestamp <
            tempBattle.battleStartTime.add(baseBattleTime).add(tempBattle.rationsDaysTotal.mul(oneDayTime)), "battling::BE");
    }

    modifier validBattleType(uint8 _battleType) {
        _validBattleType(_battleType);
        _;
    }

    function _validBattleType(uint8 _battleType) internal pure {
        require(3 <= _battleType && _battleType <= 6, "Battling::WBT2");
    }

    // testing only
    function testRewardTime(uint256 _seconds) public {
        rewardTime = _seconds;
        oneDayTime = _seconds.mul(48);
        baseBattleTime = _seconds.mul(144);

        battlingExtension.testRewardTime(_seconds);
    }

    function testToCollectPercentage(uint256 _chanceToCollect) public {
        toCollectPercentages = [1000, 1000, _chanceToCollect, _chanceToCollect, _chanceToCollect, _chanceToCollect];

        battlingExtension.testToCollectPercentage(_chanceToCollect);
    }
}