/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

pragma solidity ^0.8.17;
// SPDX-License-Identifier: MIT

/**
 * Simple Pools 
 * https://simplepools.org/
 * DeFi pools with simple code and zero tax.
 */
contract SimplePools {

    /**
     * Main structure for the simple DeFi pool.
     */ 
    struct Pool {

        /**
         * The ID of the pool.
         */
        uint256 poolId;

        /**
         * The first token in the pool (the token offered for selling).
         */
        IERC20 token1;

        /**
         * The second token in the pool (the token required for buying token1).
         */
        IERC20 token2;

        /**
         * The current amount of token1 in the pool.
         */
        uint256 token1Amount;

        /**
         * The current amount of token2 in the pool.
         */
        uint256 token2Amount;

        /**
         * Initial price requested for token1 in token2.
         */
        uint256 token2VirtualAmount;

        /**
         * Maximum percent of token1 that can be bought with one transaction.
         * For example when the pool is used like a limit order in orderbook
         * the value of maxBuyToken1PercentPerTransaction can be 100% so the 
         * order can be filled with one transaction. But if a newly created
         * token for which the whole supply is added to a simple pool the value
         * of maxBuyToken1PercentPerTransaction can be 1% (or 5, 10, 15, 50),
         * depending on the use case.
         */
        uint8 maxBuyToken1PercentPerTransaction;

        /**
         * The constantProduct equals (token1Amount * (token2Amount + token2VirtualAmount))
         * it is used to calculate the amount of bought and sold tokens on exchange transactions.
         */
        uint256 constantProduct; // (T1*(T2+VT2))=ConstantProduct

        /**
         * Flag indicating whether the pool is with changing price for token1 in token2.
         * If the flag is "true" then the price will be always the same and constantProduct
         * is not taken into account. Otherwise the pool changes the price on each transaction.
         */
        bool isConstantPrice;

        /**
         * The token1 amount value when the pools was created. It is used to calculate
         * the amount of bought and sold tokens when the flag "isConstantPrice" is set to "true". 
         */
        uint256 initialToken1Amount;

        /**
         * The owner of the pool can take all tokens, change maxBuyToken1PercentPerTransaction,
         * change isConstantPrice and etc. when the pool is not locked.
         */
        address poolOwner;

        /**
         * Flag indicating whether the pool is locked. Locked pools cannot be unlocked.
         */
        bool isLocked;

        /**
         * Flag indicating whether all amount of tokens (token1 and token2) are taken from
         * the pool by the pool owner. Empty pools cannot be used. Locked pools cannot be emptied.
         */
        bool isEmpty;
    }

    /**
     * List with all the pools in the smart contract.
     */
    Pool[] public _pools;

    /**
     * Each transaction with the smart contract is associated with a signle pool.
     * This array keeps for each transaction with what pool it was associated.
     * This is useful to sync the state of all pools in an indexed Database.
     * 
     * The procedure for syncing pool states is the following:
     * The Database stores the index of the last transaction with which it has synced
     * all pools. Then it gets the current state of transactions in the smart contract
     * by querying _allTransactionsPoolIds.length, and then get the only the indexes of the
     * pools that were modified by the lates transactions (not synced with the DB), and
     * sync the states only for these pools.
     */
    uint256[] _allTransactionsPoolIds;

    constructor() {}

    /*
     * Note: First the token contract have to allow the token for spending 
     * by the SimplePools contract and then the operations can be performed.
     */

    /**
     * Creates a simple pool.
     * 
     * @param token1 the first token in the pool (the token offered for selling)
     * @param token2 the second token in the pool (the token required for buying token1)
     * @param token1Amount the amount of token1 with which the pool is created
     * @param matchingPriceInToken2 initial price requested for token1 in token2
     * @param maxBuyToken1PercentPerTransaction maximum percent of token1 that can 
     *        be bought with one transaction
     * @param isConstantPrice indicating whether the pool is with changing price for token1 in token2
     */
    function createPool(
        IERC20 token1,
        IERC20 token2,
        uint256 token1Amount,
        uint256 matchingPriceInToken2,
        uint8 maxBuyToken1PercentPerTransaction, 
        bool isConstantPrice
    ) external {
        require(token1 != token2, "tokens must be different");
        uint poolId = _pools.length;
        _allTransactionsPoolIds.push(poolId);
        token1.transferFrom(msg.sender, address(this), token1Amount);
        _pools.push().poolId = poolId;
        _pools[poolId].token1 = token1;
        _pools[poolId].token2 = token2;
        _pools[poolId].token1Amount = token1Amount;
        _pools[poolId].token2Amount = 0;
        _pools[poolId].token2VirtualAmount = matchingPriceInToken2;
        _pools[poolId].maxBuyToken1PercentPerTransaction = maxBuyToken1PercentPerTransaction;
        _pools[poolId].constantProduct = token1Amount * matchingPriceInToken2;
        _pools[poolId].isConstantPrice = isConstantPrice;
        _pools[poolId].initialToken1Amount = token1Amount;
        _pools[poolId].poolOwner = msg.sender;
        _pools[poolId].isLocked = false;
        _pools[poolId].isEmpty = false;
    }

    /**
     * Exchanges token for tokenToBuy from _pools[poolId].
     * 
     * @param tokenToBuy the requested token to buy is one of the tokens
     *        in _pools[poolId]. This automatically makes the token to sell
     *        the other token from the pool
     * @param poolId the poolId for the pool where the exchange happens
     * @param tokenToSellAmount the amount of token to sell for the exchange
     * @param minReceiveTokenToBuyAmount the minimum amount received from tokenToBuy.
     *        This param ensures that front-runner bots cannot take advantage of the
     *        transaction. This should be set automatically by simplepools.org or
     *        calculated manually.
     * @return amount of tokenToBuy exchanged in the transaction
     */
    function exchangeToken(
        IERC20 tokenToBuy, 
        uint256 poolId, 
        uint256 tokenToSellAmount, 
        uint256 minReceiveTokenToBuyAmount
    ) external returns (uint256) { 
        require(!_pools[poolId].isEmpty, "Pool is empty");
        Pool storage pool = _pools[poolId];
        require(tokenToBuy == pool.token1 || tokenToBuy == pool.token2, "trying to buy from wrong pool");
        _allTransactionsPoolIds.push(poolId);
        if (tokenToBuy == pool.token1) {
            uint amountOut;
            if (pool.isConstantPrice) {
                amountOut = Math.mulDiv(tokenToSellAmount, pool.initialToken1Amount, pool.token2VirtualAmount);
            } else {
                amountOut = pool.token1Amount -
                    Math.ceilDiv(pool.constantProduct,
                             pool.token2VirtualAmount + pool.token2Amount + tokenToSellAmount);
            }
            amountOut = Math.min(amountOut, Math.mulDiv(pool.token1Amount, pool.maxBuyToken1PercentPerTransaction, 100));
            require(pool.token2.allowance(msg.sender, address(this)) >= tokenToSellAmount, "trying to sell more than allowance");
            require(minReceiveTokenToBuyAmount <= amountOut,"minReceive is less than calcualted amount");
            // complete the transaction now
            require(pool.token2.transferFrom(msg.sender, address(this), tokenToSellAmount), "cannot transfer tokenToSellAmount");
            pool.token2Amount += tokenToSellAmount;
            require(pool.token1.transfer(msg.sender, amountOut), "cannot transfer from amountOut from pool");
            pool.token1Amount -= amountOut;
            pool.constantProduct = (pool.token1Amount) * (pool.token2Amount + pool.token2VirtualAmount);
            return amountOut;
        } else if (tokenToBuy == pool.token2) {
            require(pool.token2Amount > 0, "zero amount of token for buy in pool");
            uint amountOut;
            if (pool.isConstantPrice) {
                amountOut = Math.mulDiv(tokenToSellAmount, pool.token2VirtualAmount, pool.initialToken1Amount);
            } else {
                amountOut = pool.token2VirtualAmount + pool.token2Amount 
                        - Math.ceilDiv(pool.constantProduct,
                               pool.token1Amount + tokenToSellAmount);
            }
            amountOut = Math.min(amountOut, pool.token2Amount);
            require(pool.token1.allowance(msg.sender, address(this)) >= tokenToSellAmount, "trying to sell more than allowance");
            require(minReceiveTokenToBuyAmount <= amountOut,"minReceive is more than calcualted amount");
            // complete the transaction now
            require(pool.token1.transferFrom(msg.sender, address(this), tokenToSellAmount), "cannot transfer tokenToSellAmount");
            pool.token1Amount += tokenToSellAmount;
            require(pool.token2.transfer(msg.sender, amountOut), "cannot transfer from amountOut from pool");
            pool.token2Amount -= amountOut;
            pool.constantProduct = (pool.token1Amount) * (pool.token2Amount + pool.token2VirtualAmount);
            return amountOut;
        }
        require(false, "Wrong token address or poolId");
        return 0;
    }

    /**
     * Transfers all tokens (token1 and token2) from a pool to
     * the pool owner. Only callable by the pool owner.
     *
     * @param poolId the poolId of the pool
     */
    function getAllTokensFromPool(
            uint256 poolId) external {
        require(_pools.length > poolId, "invalid pool id");
        require(!_pools[poolId].isLocked, "pool is locked");
        require(!_pools[poolId].isEmpty, "pool is empty");
        require(_pools[poolId].poolOwner == msg.sender, "only the pool owner can empty pool");
        _allTransactionsPoolIds.push(poolId);
        Pool storage pool = _pools[poolId];
        pool.token1.transferFrom(address(this), msg.sender, pool.token1Amount);
        pool.token1Amount = 0;
        pool.token2.transferFrom(address(this), msg.sender, pool.token2Amount);
        pool.token2Amount = 0;
        pool.token2VirtualAmount = 0;
        pool.isEmpty = true;
    }

    /**
     * Locks a pool. Only callable by the pool owner.
     * Locked pools cannot be unlocked and the tokens cannot be taken from the pool owner.
     *
     * @param poolId the id of the pool
     *
     * @return true if the operation succeeds
     */
    function lockPool(
            uint256 poolId) external returns (bool) {
        require(_pools.length > poolId, "invalid pool id");
        require(!_pools[poolId].isLocked, "pool is already locked");
        require(_pools[poolId].poolOwner == msg.sender, "only the pool owner can lock a pool");
        _allTransactionsPoolIds.push(poolId);
        _pools[poolId].isLocked = true;
        return true;
    }

    /**
     * Changes the ownership of a pool. Only callable by the pool owner.
     * If owner gets compromised and is fast enough they can transfer the ownership of the pool.
     * 
     * @param poolId the id of the pool
     * @param newPoolOwner the address of the new pool owner
     *
     * @return true if the operation succeeds
     */
    function changeOwner(
            uint256 poolId, 
            address newPoolOwner) external returns (bool) {
        require(poolId < _pools.length, "invalid poolId");
        require(!_pools[poolId].isLocked, "pool is locked");
        require(_pools[poolId].poolOwner == msg.sender, "only the pool owner can change ownership");
        _pools[poolId].poolOwner = newPoolOwner;
        _allTransactionsPoolIds.push(poolId);
        return true;
    }

    /**
     * Changes maxBuyToken1PercentPerTransaction. Only callable by the pool owner.
     * 
     * @param poolId the id of the pool
     * @param newMaxBuyToken1PercentPerTransaction the new maxBuyToken1PercentPerTransaction
     *
     * @return true if the transaction succeeds
     */
    function changePoolMaxBuyToken1PercentPerTransaction(
            uint256 poolId, 
            uint8 newMaxBuyToken1PercentPerTransaction) external returns (bool) {
        require(poolId < _pools.length, "invalid poolId");
        require(!_pools[poolId].isLocked, "pool is locked");
        require(_pools[poolId].poolOwner == msg.sender, 
                "only the pool owner can change newMaxBuyToken1PercentPerTransaction");
        require(newMaxBuyToken1PercentPerTransaction <= 100 &&
                    newMaxBuyToken1PercentPerTransaction > 0, 
                    "invalid max percent per transaction");
        _pools[poolId].maxBuyToken1PercentPerTransaction = newMaxBuyToken1PercentPerTransaction;
        _allTransactionsPoolIds.push(poolId);
        return true;
    }

    /**
     * Changes a pool constant product. Only callable by the pool owner.
     * 
     * @param poolId the poolId
     * @param newConstantProduct the new constant product
     *
     * @return true if the operation succeeds
     */
    function changeContantProduct(
            uint256 poolId, 
            uint256 newConstantProduct) external returns (bool) {
        require(poolId < _pools.length, "invalid poolId");
        require(!_pools[poolId].isLocked, "pool is locked");
        require(_pools[poolId].poolOwner == msg.sender, "only the pool owner can change the constant product");
        require(newConstantProduct > 0, "invalid constant product (only positive numbers)");
        _pools[poolId].constantProduct = newConstantProduct;
        _allTransactionsPoolIds.push(poolId);
        return true;
    }

    /**
     * Returns whether a pool is locked.
     * 
     * @param poolId the id of the pool
     *
     * @return true if the pool is locked
     */
    function isPoolLocked(uint256 poolId) external view returns (bool) {
        return _pools[poolId].isLocked;
    }

    /**
     * @return number of pools in the smart contract.
     */
    function getPoolsCount() external view returns (uint) {
        return _pools.length;
    }

    /**
     * Gets the states of the pools in a given range [startPoolIndex, ..., endPoolIndex).
     * Start index is included and end index is not included.
     * 
     * @param startPoolIndex the start index
     * @param endPoolIndex the end index
     *
     * @return list of requested pools
     */
    function getPools(
            uint256 startPoolIndex, 
            uint256 endPoolIndex
    ) external view returns (Pool[] memory) {
       require(endPoolIndex > startPoolIndex && endPoolIndex <= _pools.length, "invalid indexes");
       Pool[] memory pools = new Pool[](endPoolIndex - startPoolIndex);
       for (uint i = startPoolIndex; i < endPoolIndex; ++i) {
            pools[i - startPoolIndex] = _pools[i];
        }
        return pools;
    }
    
    /**
     * Gets the states of the pools from a given starting index till the end.
     * 
     * @param startPoolIndex the start index
     *
     * @return list of requested pools
     */
    function getPoolsFrom(
            uint256 startPoolIndex) external view returns (Pool[] memory) {
       require(startPoolIndex < _pools.length, "invalid index");
       Pool[] memory pools = new Pool[](_pools.length - startPoolIndex);
       for (uint i = startPoolIndex; i < _pools.length; ++i) {
            pools[i - startPoolIndex] = _pools[i];
        }
        return pools;
    }

    /**
     * Returns the states of the pools with the requested indexes.
     * 
     * @param indexes the list of requested pool indexes
     * 
     * @return list of requested pools
     */
    function getPools(
            uint256[] memory indexes) external view returns (Pool[] memory) {
        Pool[] memory pools = new Pool[](indexes.length);
        for (uint256 i = 0; i < indexes.length; ++i) {
            Pool storage pool = _pools[indexes[i]];
            pools[i] = pool;
        }
        return pools;
    }

    /**
     * Returns the state of a single pool.
     * 
     * @param poolId the id of the requested pool
     * 
     * @return the requested pool 
     */
    function getPool(uint256 poolId) external view returns (Pool memory) {
        return _pools[poolId];
    }

    /**
     * Returns the count of all transactions executed with the smart contract.
     */
    function getTransactionsCount() external view returns (uint256) {
        return _allTransactionsPoolIds.length;
    }

    /**
     * Returns the list of pool indexes of the pools participating in
     * the list of requested transactions in range [startTransactionIndex, ..., endTransactionIndex).
     * 
     * @param startTransactionIndex the index of the starting transaction
     * @param endTransactionIndex the index of the last transaction
     *
     * @return the requested list of pool indexes
     */
    function getPoolsForTransactionsWithIndexesBetween(
            uint256 startTransactionIndex,
            uint256 endTransactionIndex
    ) external view returns (uint256[] memory) {
        require(endTransactionIndex > startTransactionIndex && 
                endTransactionIndex <= _allTransactionsPoolIds.length, "invalid indexes");
        uint[] memory poolIndexes = new uint[](endTransactionIndex - startTransactionIndex);
        for (uint i = startTransactionIndex; i < endTransactionIndex; ++i) {
            poolIndexes[i - startTransactionIndex] = _allTransactionsPoolIds[i];
        }
        return poolIndexes;
    }

    /**
     * Returns the list of pool indexes of the pools participating in
     * the list of requested transactions in range [startTransactionIndex, ..., _allTransactionsPoolIds.length).
     * 
     * @param startTransactionIndex the index of the starting transaction
     *
     * @return the requested list of pool indexes
     */
    function getPoolsForTransactionsWithIndexesFrom(
            uint startTransactionIndex) external view returns (uint[] memory) {
        require(startTransactionIndex < _allTransactionsPoolIds.length, "invalid index");
        uint[] memory poolIndexes = new uint[](_allTransactionsPoolIds.length - startTransactionIndex);
        for (uint i = startTransactionIndex; i < _allTransactionsPoolIds.length; ++i) {
            poolIndexes[i - startTransactionIndex] = _allTransactionsPoolIds[i];
        }
        return poolIndexes;
    }

    /**
     * Returns the name of a given token
     * 
     * @param token the address of the requested token
     * 
     * @return name of the token
     */
    function getTokenName(IERC20 token) external view returns (string memory) {
        return token.name();
    }

    /**
     * Returns the symbol of a given token
     * 
     * @param token the address of the requested token
     * 
     * @return symbol of the token
     */
    function getTokenSymbol(IERC20 token) external view returns (string memory) {
        return token.symbol();
    }

    function getTokenDecimals(IERC20 token) external view returns (uint8) {
        return token.decimals();
    }

    function getTokenTotalSupply(IERC20 token) external view returns (uint256) {
        return token.totalSupply();
    }

    function getTokenTotalAllowance(IERC20 token, address owner, address spender) external view returns (uint256) {
        return token.allowance(owner, spender);
    }
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }
}

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

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);
}