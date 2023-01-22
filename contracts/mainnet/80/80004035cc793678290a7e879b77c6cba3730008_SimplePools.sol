pragma solidity ^0.8.17;
// SPDX-License-Identifier: GPL-3.0-or-later
// Simple Pools smart contract DeFi exchange.
// Copyright (C) 2023 Simple Pools

// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software 
// Foundation, either version 3 of the License, or (at your option) any later version.

// This program is distributed in the hope that it will be useful, but WITHOUT 
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
// FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

// You should have received a copy of the GNU General Public License along with this 
// program. If not, see <https://www.gnu.org/licenses/>.

/**
 * Simple Pools
 * https://simplepools.org/
 * DeFi made simple.
 */
contract SimplePools {

    /**
     * Main structure for the simple DeFi pool.
     */ 
    struct Pool {

        /**
         * The ID of the pool.
         */
        uint64 poolId;

        /**
         * Flag indicating whether asset1 is the native blockchain currency.
         */
        bool isAsset1NativeBlockchainCurrency;

        /**
         * The ERC20 contract address of the first asset in the pool
         * (the initially offered asset for selling).
         * Used only if isAsset1NativeBlockchainCurrency is false.
         */
        address asset1;

        /**
         * Flag indicating whether asset2 is the native blockchain currency.
         */
        bool isAsset2NativeBlockchainCurrency;

        /**
         * The ERC20 contract address of the second asset in the pool
         * (the initially asked asset for buying).
         * Used only if isAsset2NativeBlockchainCurrency is false.
         */
        address asset2;

        /**
         * The current amount of asset1 in the pool.
         */
        uint256 asset1Amount;

        /**
         * The current amount of asset2 in the pool.
         */
        uint256 asset2Amount;

        /**
         * Initial asked price in asset2 requested for the whole asset1.
         */
        uint256 asset2InitiallyAskedAmount;

        /**
         * Maximum percent of asset1 that can be bought with one transaction.
         * For example when the pool is used like a limit order in an orderbook
         * the value of maxBuyAsset1PercentPerTransaction can be 100% so the 
         * order can be filled with one transaction. But if a newly created
         * asset for which the whole supply is added to a simple pool the value
         * of maxBuyAsset1PercentPerTransaction can be 1% (or 5%, 10%, 15%, 50%),
         * depending on the use case.
         */
        uint8 maxBuyAsset1PercentPerTransaction;

        /**
         * The constantProduct equals (asset1Amount * (asset2Amount + asset2InitiallyAskedAmount))
         * it is used to calculate the amount of bought and sold assets on exchange transactions.
         * This is an invariant hold after each transaction in the pool when the flag isConstantPrice
         * is set to false. If isConstantPrice is true then this value is ignored and only 
         * asset2InitiallyAskedAmount and initialAsset1Amount is used for price calculation.
         */
        uint256 constantProduct; // (A1*(A2+IA2)) = constantProduct

        /**
         * Flag indicating whether the pool is with changing price for asset in asset2.
         * If the flag is "true" then the price will be always the same and constantProduct
         * is ignored. Otherwise the pool changes the price on each transaction to keep the
         * invariant (A1*(A2+IA2)) = constantProduct.
         */
        bool isConstantPrice;

        /**
         * The inital asset1 amount value when the pools was created. It is used to calculate
         * the amount of bought and sold assets when the flag "isConstantPrice" is set to "true". 
         */
        uint256 initialAsset1Amount;

        /**
         * The owner of the pool can take all assets, change maxBuyAsset1PercentPerTransaction,
         * change the constantPrice when the pool is not locked. Also the pool owner takes half
         * of the transaction taxes for each transaction. The other half is taken by the contract
         * owner.
         */
        address payable poolOwner;

        /**
         * Flag indicating whether the pool is locked. Locked pools cannot be unlocked.
         */
        bool isLocked;

        /**
         * Flag indicating whether all assets (asset1 and asset1) are taken from
         * the pool by the pool owner.
         * Empty pools cannot be used. 
         * Locked pools cannot be emptied.
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
    uint64[] _allTransactionsPoolIds;

    /*
     * Note: First the asset contract (if not native) have to allow the asset for spending 
     * by the SimplePools contract and then the operations can be performed.
     */

    /**
     * Creates a simple pool.
     * For the documentation of each parameter check the Pool structure definition.
     * 
     * @param poolCreatorAddress the address of the pool creator
     * @param isAsset1Native                         *
     * @param asset1                                 *
     * @param isAsset2Native                         *
     * @param asset2                                 *
     * @param asset1Amount                           *
     * @param asset2InitiallyAskedAmount             *
     * @param maxBuyAsset1PercentPerTransaction      *
     * @param isConstantPrice                        *
     */
    function createPool(
        address poolCreatorAddress,
        bool isAsset1Native,
        IERC20 asset1,
        bool isAsset2Native,
        IERC20 asset2,
        uint256 asset1Amount,
        uint256 asset2InitiallyAskedAmount,
        uint8 maxBuyAsset1PercentPerTransaction, 
        bool isConstantPrice
    ) external payable {
        uint256 nativeAmountRequired = contractTransactionTax + (isAsset1Native ? asset1Amount : 0);
        require(msg.value >= nativeAmountRequired, "Lower than the required transaction value");

        uint64 poolId = uint64(_pools.length);
        _allTransactionsPoolIds.push(poolId);
        if (isAsset1Native) {
            payable(this).transfer(asset1Amount);
            contractOwner.transfer(msg.value - asset1Amount);
        } else {
            asset1.transferFrom(poolCreatorAddress, address(this), asset1Amount);
            contractOwner.transfer(msg.value);
        }
        _pools.push().poolId = poolId;
        Pool storage pool = _pools[poolId];
        pool.asset1 = address(asset1);
        pool.asset1Amount = asset1Amount;
        pool.asset2 = address(asset2);
        pool.asset2Amount = 0;
        pool.isAsset1NativeBlockchainCurrency = isAsset1Native;
        pool.isAsset2NativeBlockchainCurrency = isAsset2Native;
        pool.asset2InitiallyAskedAmount = asset2InitiallyAskedAmount;
        pool.maxBuyAsset1PercentPerTransaction = maxBuyAsset1PercentPerTransaction;
        pool.isConstantPrice = isConstantPrice;
        pool.constantProduct = asset1Amount * asset2InitiallyAskedAmount;
        pool.initialAsset1Amount = asset1Amount;
        pool.poolOwner = payable(poolCreatorAddress);
        pool.isLocked = false;
        pool.isEmpty = false;
    }

    /**
     * Exchanges asset for asset from a simple pool.
     * 
     * @param personExecutingTheExchange address of the person executing the exchange
     * @param poolId the poolId for the pool where the exchange happens
     * @param isBuyingAsset1 boolean flag indicating whether asset1 is requested
     *            for buying in the transaction. If the value of the flag is true
     *            then asset2 from the pool is sold for asset1. Otherwise if the
     *            value of the flag is false then asset1 from the pool is sold for asset2.
     * @param sellAmount the amount of asset to sell for the exchange
     * @param minReceiveAssetToBuyAmount the minimum amount received from assetToBuy.
     *        This param ensures that front-runner bots cannot take advantage of the
     *        transaction. This should be set automatically by simplepools.org or
     *        calculated manually
     * @return the actual amount bought from the transaction
     */
    function exchangeAsset(
        address personExecutingTheExchange,
        uint64 poolId,
        bool isBuyingAsset1,
        uint256 sellAmount, 
        uint256 minReceiveAssetToBuyAmount
    ) external payable returns (uint256) {
        require(poolId < _pools.length, "Invalid poolId");
        Pool storage pool = _pools[poolId];
        require(!pool.isEmpty, "Pool is empty");
        _allTransactionsPoolIds.push(poolId);

        if (isBuyingAsset1) {
            uint256 amountOut;
            if (pool.isConstantPrice) {
                // amountOut = (sellAmount*initialAsset1Amount)/asset2InitiallyAskedAmount
                amountOut = Math.mulDiv(sellAmount, pool.initialAsset1Amount, pool.asset2InitiallyAskedAmount);
            } else {
                // amountOut = asset1Amount - constantProduct/(asset2InitiallyAsked+asset2Amount+sellAmount)
                amountOut = pool.asset1Amount -
                    pool.constantProduct / (pool.asset2InitiallyAskedAmount + pool.asset2Amount + sellAmount);
            }
            // maxBuyAsset1PercentPerTransaction correction of amountOut
            amountOut = Math.min(amountOut, 
                    Math.mulDiv(pool.asset1Amount, pool.maxBuyAsset1PercentPerTransaction, 100));
            require(minReceiveAssetToBuyAmount <= amountOut,"minReceive is less than calcualted amount");
            // complete the transaction now

            // transfer asset2 to the pool
            uint256 taxDivided = contractTransactionTax / 2;
            if (pool.isAsset2NativeBlockchainCurrency) {
                require(msg.value >= sellAmount + contractTransactionTax, "lower transaction value");
                payable(this).transfer(sellAmount); // move funds to the pool
                pool.poolOwner.transfer(taxDivided);
                contractOwner.transfer(msg.value - sellAmount - taxDivided);
            } else {
                require(msg.value >= contractTransactionTax, "lower transaction value");
                IERC20(pool.asset2).transferFrom(personExecutingTheExchange, address(this), sellAmount);
                pool.poolOwner.transfer(taxDivided);
                contractOwner.transfer(msg.value - taxDivided);
            }
            pool.asset2Amount += sellAmount;
            // transfer asset1 from the pool
            if (pool.isAsset1NativeBlockchainCurrency) {
                payable(personExecutingTheExchange).transfer(amountOut);
            } else {
                IERC20(pool.asset1).transfer(personExecutingTheExchange, amountOut);
            }
            pool.asset1Amount -= amountOut;

            pool.constantProduct = (pool.asset1Amount) * (pool.asset2Amount + pool.asset2InitiallyAskedAmount);
            return amountOut;
        } else { // is buying asset2 by selling asset1
            require(pool.asset2Amount > 0, "zero amount of asset2 for buy in the pool");
            uint256 amountOut;
            if (pool.isConstantPrice) {
                // amountOut = (sellAmount * asset2InitiallyAskedAmount) / initialAsset1Amount
                amountOut = Math.mulDiv(sellAmount, pool.asset2InitiallyAskedAmount, pool.initialAsset1Amount);
            } else {
                amountOut = pool.asset2InitiallyAskedAmount + pool.asset2Amount -
                        pool.constantProduct / (pool.asset1Amount + sellAmount);
            }
            // sell only from the available amount in the pool
            amountOut = Math.min(amountOut, pool.asset2Amount);
            require(minReceiveAssetToBuyAmount <= amountOut,"minReceive is more than calcualted amount");
            // complete the transaction now
            uint256 taxDivided = contractTransactionTax / 2;
            // transfer asset1 to the pool
            if (pool.isAsset1NativeBlockchainCurrency) {
                require(msg.value >= sellAmount + contractTransactionTax, "lower transaction value");
                payable(this).transfer(sellAmount);
                pool.poolOwner.transfer(taxDivided);
                contractOwner.transfer(msg.value - sellAmount - taxDivided);
            } else {
                require(msg.value >= contractTransactionTax, "lower transaction value");
                IERC20(pool.asset1).transferFrom(personExecutingTheExchange, address(this), sellAmount);
                pool.poolOwner.transfer(taxDivided);
                contractOwner.transfer(msg.value - taxDivided);
            }
            pool.asset1Amount += sellAmount;
            // transfer asset2 from the pool
            if (pool.isAsset2NativeBlockchainCurrency) {
                payable(personExecutingTheExchange).transfer(amountOut);
            } else {
                IERC20(pool.asset2).transfer(personExecutingTheExchange, amountOut);
            }
            pool.asset2Amount -= amountOut;
            pool.constantProduct = (pool.asset1Amount) * (pool.asset2Amount + pool.asset2InitiallyAskedAmount);
            return amountOut;
        }
    }

    /**
     * Transfers all assets (asset1 and asset2) from a pool to
     * the pool owner. Only callable by the pool owner.
     *
     * @param poolId the poolId of the pool
     */
    function getAllAssetsFromPool(
            uint64 poolId) external payable {
        require(_pools.length > poolId, "invalid pool id");
        Pool storage pool = _pools[poolId];
        require(!pool.isLocked, "pool is locked");
        require(!pool.isEmpty, "pool is empty");
        require(pool.poolOwner == msg.sender, "only the pool owner can empty pool");
        _allTransactionsPoolIds.push(poolId);
        require(msg.value >= contractTransactionTax, "lower tax specified");
        contractOwner.transfer(msg.value); // transfer the tax to the owner
        if (pool.isAsset1NativeBlockchainCurrency) {
            payable(msg.sender).transfer(pool.asset1Amount);
        } else {
            IERC20(pool.asset1).transfer(msg.sender, pool.asset1Amount);
        }
        pool.asset1Amount = 0;

        if (pool.isAsset2NativeBlockchainCurrency) {
            payable(msg.sender).transfer(pool.asset2Amount);
        } else {
            IERC20(pool.asset2).transfer(msg.sender, pool.asset2Amount);
        }
        pool.asset2Amount = 0;
        pool.asset2InitiallyAskedAmount = 0;
        pool.isEmpty = true;
    }

    /**
     * Locks a pool. Only callable by the pool owner.
     * Locked pools cannot be unlocked and the assets cannot be taken from the pool owner.
     *
     * @param poolId the id of the pool
     */
    function lockPool(
            uint64 poolId) external payable {
        require(_pools.length > poolId, "invalid pool id");
        Pool storage pool = _pools[poolId];
        require(!pool.isLocked, "pool is already locked");
        require(pool.poolOwner == msg.sender, "only the pool owner can lock a pool");
        _allTransactionsPoolIds.push(poolId);
        require(msg.value >= contractTransactionTax, "lower tax specified");
        contractOwner.transfer(msg.value); // transfer the tax to the owner
        pool.isLocked = true;
    }

    /**
     * Changes the ownership of a pool. Only callable by the pool owner.
     * If the owner gets compromised and is fast enough, they can transfer the ownership of the pool.
     * 
     * @param poolId the id of the pool
     * @param newPoolOwner the address of the new pool owner
     */
    function changeOwner(
            uint64 poolId, 
            address newPoolOwner) external payable {
        require(poolId < _pools.length, "invalid poolId");
        Pool storage pool = _pools[poolId];
        require(!pool.isLocked, "pool is locked");
        require(pool.poolOwner == msg.sender, "only the pool owner can change ownership");
        pool.poolOwner = payable(newPoolOwner);
        _allTransactionsPoolIds.push(poolId);
        require(msg.value >= contractTransactionTax, "lower tax specified");
        contractOwner.transfer(msg.value); // transfer the tax to the owner
    }

    /**
     * Changes maxBuyAsset1PercentPerTransaction. Only callable by the pool owner.
     * 
     * @param poolId the id of the pool
     * @param newMaxBuyAsset1PercentPerTransaction the new maxBuyAsset1PercentPerTransaction
     */
    function changePoolMaxBuyAsset1PercentPerTransaction(
            uint64 poolId, 
            uint8 newMaxBuyAsset1PercentPerTransaction) external payable {
        require(poolId < _pools.length, "invalid poolId");
        Pool storage pool = _pools[poolId];
        require(!pool.isLocked, "pool is locked");
        require(pool.poolOwner == msg.sender, 
                "only the pool owner can change newMaxBuyAsset1PercentPerTransaction");
        require(newMaxBuyAsset1PercentPerTransaction <= 100 &&
                    newMaxBuyAsset1PercentPerTransaction > 0, 
                    "invalid max percent per transaction");
        _pools[poolId].maxBuyAsset1PercentPerTransaction = newMaxBuyAsset1PercentPerTransaction;
        _allTransactionsPoolIds.push(poolId);
        require(msg.value >= contractTransactionTax, "lower tax specified");
        contractOwner.transfer(msg.value); // transfer the tax to the owner
    }

    /**
     * Changes a pool constant product. Only callable by the pool owner.
     * 
     * @param poolId the poolId
     * @param newConstantProduct the new constant product
     */
    function changeContantProduct(
            uint64 poolId, 
            uint256 newConstantProduct) external payable {
        require(poolId < _pools.length, "invalid poolId");
        Pool storage pool = _pools[poolId];
        require(!pool.isLocked, "pool is locked");
        require(pool.poolOwner == msg.sender, "only the pool owner can change the constant product");
        require(newConstantProduct > 0, "invalid constant product (only positive numbers)");
        pool.constantProduct = newConstantProduct;
        _allTransactionsPoolIds.push(poolId);
        require(msg.value >= contractTransactionTax, "lower tax specified");
        contractOwner.transfer(msg.value); // transfer the tax to the owner
    }

    /**
     * Returns whether a pool is locked.
     * 
     * @param poolId the id of the pool
     *
     * @return true if the pool is locked
     */
    function isPoolLocked(uint64 poolId) external view returns (bool) {
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
            uint64 startPoolIndex, 
            uint64 endPoolIndex
    ) external view returns (Pool[] memory) {
       require(endPoolIndex > startPoolIndex && endPoolIndex <= _pools.length, "invalid indexes");
       Pool[] memory pools = new Pool[](endPoolIndex - startPoolIndex);
       for (uint64 i = startPoolIndex; i < endPoolIndex; ++i) {
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
            uint64 startPoolIndex) external view returns (Pool[] memory) {
       require(startPoolIndex < _pools.length, "invalid index");
       Pool[] memory pools = new Pool[](_pools.length - startPoolIndex);
       for (uint64 i = startPoolIndex; i < _pools.length; ++i) {
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
            uint64[] memory indexes) external view returns (Pool[] memory) {
        Pool[] memory pools = new Pool[](indexes.length);
        for (uint64 i = 0; i < indexes.length; ++i) {
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
    function getPool(uint64 poolId) external view returns (Pool memory) {
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
            uint64 startTransactionIndex,
            uint64 endTransactionIndex
    ) external view returns (uint64[] memory) {
        require(endTransactionIndex > startTransactionIndex && 
                endTransactionIndex <= _allTransactionsPoolIds.length, "invalid indexes");
        uint64[] memory poolIndexes = new uint64[](endTransactionIndex - startTransactionIndex);
        for (uint64 i = startTransactionIndex; i < endTransactionIndex; ++i) {
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
            uint64 startTransactionIndex) external view returns (uint64[] memory) {
        require(startTransactionIndex < _allTransactionsPoolIds.length, "invalid index");
        uint64[] memory poolIndexes = new uint64[](_allTransactionsPoolIds.length - startTransactionIndex);
        for (uint64 i = startTransactionIndex; i < _allTransactionsPoolIds.length; ++i) {
            poolIndexes[i - startTransactionIndex] = _allTransactionsPoolIds[i];
        }
        return poolIndexes;
    }

    /**
     * The owner of the contract (the receiver of the taxes).
     */
    address payable public contractOwner;

    /**
     * Set the initial contract owner to the msg.sender.
     */
    constructor() {
        contractOwner = payable(msg.sender);
    }

    /**
     * Function to receive native asset, msg.data must be empty.
     */
    receive() external payable {}

    /**
     * Fallback function is called when msg.data is not empty.
     */
    fallback() external payable {}

    /**
     * Gets the current native asset balance of contract.
     */
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    /**
     * Sets a new contract owner. Only callable by the current contract owner.
     */
    function setNewOwner(address newOwner) external {
        require(msg.sender == contractOwner, "only the current owner can change the owner");
        contractOwner = payable(newOwner);
    }

    /**
     * Tax is equally divided by the contract owner and pool creator on each transaction.
     */
    uint256 contractTransactionTax = 10 ** 15;

    /**
     * This is the list of valid transaction taxes that can be set by the contract owner.
     */
    uint256[] validContractTransactionTaxes = [10**13, 10**14, 10**15, 10**16, 10**17];

    /**
     * Sets a new contractTransactionNax. Only callable by the current contract owner.
     * The list of valid transaction taxes which can be set is validContractTransactionTaxes.
     */
    function setNewGlobalTax(uint8 newTaxIndexFromValidContractTransactionTaxes) external {
        require(msg.sender == contractOwner, "only the current owner can change the tax");
        require(newTaxIndexFromValidContractTransactionTaxes < validContractTransactionTaxes.length &&
                newTaxIndexFromValidContractTransactionTaxes >= 0, 
                "invalid newTaxIndexFromValidContractTransactionTaxes");
        contractTransactionTax = validContractTransactionTaxes[newTaxIndexFromValidContractTransactionTaxes];
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

/**
 * Interface for ERC20 assets.
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