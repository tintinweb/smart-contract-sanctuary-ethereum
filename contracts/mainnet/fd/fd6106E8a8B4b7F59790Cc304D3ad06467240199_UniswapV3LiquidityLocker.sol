/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: MIT

// Use the solidity compiler version 0.8.0 or later
pragma solidity >=0.8.0;


/// @title Interface to ERC721
interface IERC721 {
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;    
}

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
interface IUniswapV3Pool {
    // The current in range liquidity available to the pool 
    function liquidity() external view returns (uint128);

    // Collect fees
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    // Pool information
    struct Slot0 {
        // Current sqrt(P)
        uint160 sqrtPriceX96;
        // Current tick
        int24 tick;
    }
    function slot0() external view returns (Slot0 memory slot0);
    
    // Pool token0 contract address
    function token0() external view returns (address);

    // Pool token1 contract address
    function token1() external view returns (address);
}

/// @title Interface to Uniswap V3 NonfungiblePositionManager contract
interface INonfungiblePositionManager {
    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
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

    // Collect fees params structure definition
    struct CollectParams {
        /// @param tokenId The id of the ERC721 token
        /// @param recipient The address to which collected protocol fees should be sent
        /// @param amount0Max The maximum amount of token0 to send, can be 0 to collect fees in only token1
        /// @param amount1Max The maximum amount of token1 to send, can be 0 to collect fees in only token0
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects the fees associated with provided liquidity
    /// @dev The contract must hold the ERC721 token before it can collect fees
    /// @param params Collect fees request parameters of type CollectParams
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams memory params) external returns (uint256 amount0, uint256 amount1);
}

/*
 * @dev
 * -------------------------------
 * Uniswap V3 Locker contract
 * -------------------------------
 * 1. The contract deployer will be the owner of the contract.
 * 2. Only the current owner can change ownership.
 * 3. To lock the liquidity, the owner must transfer LP tokens to the locker contract and
 *    call the "lock" function with the unlock date.
 * 4. It is possible to transfer LP tokens from the locker contract only by calling the "unlock" function.
 * 5. If the unlock function is called before the unlock date (unlockDate), it will fail.
 * 6. It is possible to extend the lock period with the "lock" function, but it cannot be reduced. 
 * 7. It is possible to add liquidity to the locker by transfering LP-tokens to the locker contract (this).
 */
contract UniswapV3LiquidityLocker {
    /* @dev Contract constants and variables:
     * "public" means that the variable can be read by public (e.g. any bscscan.com user).
     * "private" means that the variable can be accessed by this contract only.
     * "immutable" means that the variable can be set once when the contract is created and cannot be changed after that.
     */

    /// @notice Uniswap V3 Pool address
    address public immutable uniswapV3Pool;

    /// @notice Uniswap V3: Positions NFT contract address
    address public immutable uniswapV3PositionManager;

    /// @notice The owner of the locker contract and liquidity.
    address public owner;

    /// @notice Unlock date as a unix timestamp. You can convert the timestamp to a readable date-time at https://www.unixtimestamp.com/.
    uint public unlockDate;

    /// @notice Uniswap V3 Position Token ID
    uint256[] private tokenIds;

    // Definition of events.
    // If event is emitted, it stores the arguments passed in transaction logs.
    // These logs are stored on blockchain and are accessible using address of the contract.
    event OwnerChanged(address oldOwner, address newOwner);
    event LiquidityLocked(uint until);
    event LiquidityUnlocked(uint256 tokenId, uint date);
    event ERC721TokenReceived(address sender, address owner, uint256 tokenId);

    /**
     * @notice Locker contract constructor. It will only be called once when deploying
     * contract.
     */
    constructor(address _uniswapV3Pool, address _uniswapV3PositionManager) {
        // Set the locker contract owner to the creator of the contract (msg.sender)
        owner = msg.sender;

        // Set Uniswap V3 Pool address
        uniswapV3Pool = _uniswapV3Pool;

        // Set Uniswap V3: Position NFT contract address
        uniswapV3PositionManager = _uniswapV3PositionManager;
    }

    /**
     * @notice The modifier will be used later with the lock and unlock functions, so only the owner of
     * contract owner can call these functions.
     */
    modifier onlyOwner() {
        // The function will fail if the contract is not called by its owner
        require (msg.sender == owner);

        // The _; symbol is a special symbol that is used in Solidity modifiers to indicate the end of 
        // the modifier and the beginning of the function that the modifier is modifying.
        _;
    }

    /*
     * ---------------------------------------------------------------------------------
     * Functions that change the state of the blockchain
     * ---------------------------------------------------------------------------------
     */

    /**
     * @notice
     * Change locker contract owner (Transfer ownership). 
     * @param _newOwner new owner of the locker contract
     */
    function changeOwner(address _newOwner) external
        // Only owner can call this function
        onlyOwner
    {
        // Emit public event to notify subscribers
        emit OwnerChanged(owner, _newOwner);

        // Set new owner to _newOwner
        owner = _newOwner;
    }

    // @notice The function called when the ERC721 token is received by the contract.
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        // Allow access to Uniswap V3 Position Manager contract only
        require (msg.sender == uniswapV3PositionManager, "Denied");

        // Enable NFT transfers to the contract to the contract owner only.
        require (from == owner, "Denied");
        
        // Check if the token is a Uniswap V3 NFT Position token
        (address token0, address token1,,,) = getPositionByTokenId(tokenId);

        // Check if the token belongs to the Uniswap V3 Pool (uniswapV3Pool)
        require ((token0 == IUniswapV3Pool(uniswapV3Pool).token0()) && (token1 == IUniswapV3Pool(uniswapV3Pool).token1()), "Invalid token");

        // Check if tokenId is not in the list of tokens
        require (getTokenIndexById(tokenId) == type(uint256).max, "Token exists");

        // Add token ID to a list of tokens
        tokenIds.push(tokenId);

        emit ERC721TokenReceived(msg.sender, IERC721(uniswapV3PositionManager).ownerOf(tokenId), tokenId);

        // Return selector according to ERC721 
        return this.onERC721Received.selector;
    }

    /**
     * @notice Lock function. The owner must call this function to lock or to extend the lock of
     * the liquidity.
     * @param _unlockDate the unlock date
     */
    function lock(uint _unlockDate) public
        // Only owner can call this function
        onlyOwner
    {

        // The new unlock date must be greater than the last unlock date.
        // This condition guarantees that we cannot reduce the blocking period,
        // but we can increase it.
        require (_unlockDate > unlockDate, "Invalid unlock date");

        // The unlock date must be in the future.
        require (_unlockDate > block.timestamp, "Invalid unlock date");

        // Set the date to unlock liquidity. Before this date, it is
        // not possible to transfer LP tokens from the contract.
        unlockDate = _unlockDate;

        // Emit a LiquidityLocked event so that it is visible to any event subscriber
        emit LiquidityLocked(unlockDate);
    }

    /**
     * @notice Unlock LP-token. This function will transfer LP-token from the contract to the owner.
     * If the function is called before the unlockDate, it will fail.
     * @param tokenId is the liquidity pool token ID to unlock
     */
    function unlock(uint256 tokenId) external
        // Only owner can call the function
        onlyOwner
    {
        // Check if the current date is greater than or equal to unlockDate. Fail if it is not.
        require (block.timestamp >= unlockDate, "Not yet");

        // Search liquidity token tokenId in the tokenIds list
        uint256 index = getTokenIndexById(tokenId);

        // Require tokenId is in the list of received Uniswap V3 Position NFTs
        require (index < type(uint256).max, "tokenId not found");

        // Move last element of tokenIds to the found one
        tokenIds[index] = tokenIds[tokenIds.length - 1];

        // Pop (delete) last element of tokenIds
        tokenIds.pop();

        // Transfer Uniswap V3 Position NFT with tokenId to the owner
        IERC721(uniswapV3PositionManager).safeTransferFrom(address(this), owner, tokenId);

        // Emit a LiquidityUnlocked event so that it is visible to any event subscriber
        emit LiquidityUnlocked(tokenId, block.timestamp);
    }

    /**
     * @notice Collect earned fees for position by tockenId
     * Only owner can call the function. Fees will be transfered to the owner account.
     * @param tokenId position Token ID
     * @return amount0
     * @return amount1
     */
    function collectFeesByTokenId(uint256 tokenId) external onlyOwner returns (uint256 amount0, uint256 amount1)
    {
        // Set CollectParams to request fees
        // set amount0Max and amount1Max to uint256.max to collect all fees
        INonfungiblePositionManager.CollectParams memory params =
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,      // ERC721 token ID
                recipient: owner, // recipient of fees
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });
        (amount0, amount1) = INonfungiblePositionManager(uniswapV3PositionManager).collect(params);
    }

    /**
     * @dev
     * -------------------------------------------------------------------------------------------
     * Read-only functions to retrieve information from the contract to make it publicly available
     * -------------------------------------------------------------------------------------------
     */

    /**
     * @notice Get list of liquidity tokens locked on the contract
     */
    function getTokenIds() public view returns (uint256[] memory) {
        return tokenIds;
    }

    /*
        @dev Get tokenId index in tokenIds list
        @return index the tokenId index in the tokenIds list or the maximum uint256 value if no token is found.
     */
    function getTokenIndexById(uint256 tokenId) private view returns (uint256 index) {
        // Search liquidity token tokenId in the tokenIds list
        index = type(uint256).max;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
                index = i;
                break;
            }
        }
        return index;
    }
    
    /**
     * @notice Get position information by token ID
     * @param tokenId Token ID
     * Range is [tickLower, tickUpper]
     * @return token0 The token0 contract address
     * @return token1 The token1 contract address
     * @return tickLower lower tick value
     * @return tickUpper upper tick value
     * @return liquidity the liquidity of the position
     */
    function getPositionByTokenId(uint256 tokenId) public view returns (address token0, address token1, int24 tickLower, int24 tickUpper, uint128 liquidity) {
        (,, token0, token1,, tickLower, tickUpper, liquidity,,,,) = INonfungiblePositionManager(uniswapV3PositionManager).positions(tokenId);
        return (token0, token1, tickLower, tickUpper, liquidity);
    }

    /**
     * @notice Get total liquidity of the Uniswap V3 Pool in range.
     * @return totalLiquidity the total liquidity of the Uniswap V3 Pool in range
     */
    function getTotalLiquidityInRange() public view returns (uint128 totalLiquidity)
    {
         return IUniswapV3Pool(uniswapV3Pool).liquidity();
    }

    /**
     * @notice Get locked liquidity information: percent of the total liquidity locked, percent X 100,
     * current tick, liquidity sum of the contract in range, total liquidity in range
     */
    function getLockedLiquidityInfo() public view returns (
        uint256 lockedPercentOfTotalLiquidityInRange,
        uint256 lockedPercentX100,
        int24 tick,
        uint128 liquiditySumInRange,
        uint128 totalLiquidityInRange)
    {
        // Get current tick
        tick = IUniswapV3Pool(uniswapV3Pool).slot0().tick;

        // Calculate sum of liquidity for all contract positions that are in range
        liquiditySumInRange = 0; 
        // Go through the list of contract liquidity tokens
        for (uint256 i = 0; i < tokenIds.length; i++) {

            // Get position data for tokenId
            (,, int24 tickLower, int24 tickUpper, uint128 liquidity) = getPositionByTokenId(tokenIds[i]);
            
            // Check if liquidity of position is in the range
            if ((tickLower <= tick) && (tick <= tickUpper)) {
                // Add lposition iquidity to the sum
                liquiditySumInRange += liquidity;
            }
        }

        // Get total liquidity in range
        totalLiquidityInRange = getTotalLiquidityInRange();

        // Check total liquidity in range
        require (totalLiquidityInRange > 0, "Total liquidity is zero");

        // Calculate the percentage of locked liquidity
        lockedPercentX100 = liquiditySumInRange * 100 * 100 / totalLiquidityInRange;

        // Return values
        return (
            lockedPercentX100 / 100,
            lockedPercentX100,
            tick,
            liquiditySumInRange,
            totalLiquidityInRange);
    }
}