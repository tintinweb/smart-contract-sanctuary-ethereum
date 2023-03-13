/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

// SPDX-License-Identifier: MIT

// Use the solidity compiler version 0.8.0 or later
pragma solidity ^0.8.11;

/*
 * @dev
 * -----------------------------------------------------
 * Interface to Pancakeswap Liquidity Pair (LP) contract
 * -----------------------------------------------------
 * We will use the functions of this contract to get information
 * from Pancakeswap and to transfer LP tokens when unlocking liquidity.
 */
interface IPancakeV2Pair {
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
}

/*
 * @dev
 * -------------------------------
 * Pancakeswap V2 Locker contract
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
contract PancakeswapV2LiquidityLocker {
    /* @dev Contract constants and variables:
     * "public" means that the variable can be read by any bscscan.com user (for example).
     * "immutable" means that the variable can be set once when the contract is created and cannot be changed after that.
     */

    // Pancake LP contract address.
    // It can only be set once when creating a contract.
    address public immutable lpToken;

    // The owner of the locker contract and liquidity.
    address public owner;

    // Unlock date as a unix timestamp. The default value is 0.
    // You can convert the timestamp to a readable date-time at https://www.unixtimestamp.com/.
    uint public unlockDate;

    // Definition of events.
    // If event is emitted, it stores the arguments passed in transaction logs.
    // These logs are stored on blockchain and are accessible using address of the
    // contract till the contract is present on the blockchain.
    event OwnerChanged(address oldOwner, address newOwner);
    event LiquidityLocked(uint256 amount, uint until);
    event LiquidityUnlocked(uint256 amount, uint date);

    /**
     * @notice Locker contract constructor. It will only be called once when deploying
     * contract.
     */
     constructor(address _lpToken) {
        // Set the locker contract owner to the creator of the contract (msg.sender)
        owner = msg.sender;

        // Set LP token address to _lpToken
        lpToken = _lpToken;

        // Simplified check if lpToken is a contract
        lpTokenBalance();
    }

    /**
     * @notice The modifier will be used later with the lock and unlock functions, so only the owner of
     * contract owner can call these functions.
     */
    modifier onlyOwner() {
        // The function will fail if the contract is not called by its owner
        require (msg.sender == owner);

        // Run the rest of the modified function code
        _;
    }

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

    /*
     * ---------------------------------------------------------------------------------
     * Lock and Unlock functions
     * ---------------------------------------------------------------------------------
     */

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
        emit LiquidityLocked(lpTokenBalance(), unlockDate);
    }

    /**
     * @notice Unlock LP-tokens. This function will transfer LP-tokens from the contract to the owner.
     * If the function is called before the unlockDate, it will fail.
     * @param amount is the amount of LP-tokens to unlock
     */
    function unlock(uint amount) external
        // Only owner can call the function
        onlyOwner
    {
        // Check if the current date is greater than or equal to unlockDate. Fail if it is not.
        require (block.timestamp >= unlockDate, "Not yet");

        // Get LP-token balance
        uint256 balance = lpTokenBalance();

        // Require amount > 0
        require (amount > 0, "Invalid amount");
        
        // Require balance >= amount
        require (balance >= amount, "Insufficient balance");

        // Transfer LP tokens to the owner's address
        IPancakeV2Pair(lpToken).transfer(owner, amount);

        // Emit a LiquidityUnlocked event so that it is visible to any event subscriber
        emit LiquidityUnlocked(amount, block.timestamp);
    }

    /**
     * @dev
     * -------------------------------------------------------------------------------------------
     * Read-only functions to retrieve information from the contract to make it publicly available
     * -------------------------------------------------------------------------------------------
     */

    // Get the balance of LP-tokens of the locker contract
    function lpTokenBalance() public view returns (uint256) {
        // Call the Pancakeswap LP contract to get the balance of the locker contract (this).
        return IPancakeV2Pair(lpToken).balanceOf(address(this));
    }

    /**
     * @notice Get the percentage of locked liquidity from the total liquidity for the Pancakeswap pair.
     * @return percent Percentage of liquidity locked on this contract from the total liquidity
     * @return percentMul100 "percent" multiplied by 100
     */
    function lockedPercentOfTotalLiquidity() public view returns (uint256 percent, uint256 percentMul100) {
        // Get LP-tokens balance of the locker contract
        uint256 balance = IPancakeV2Pair(lpToken).balanceOf(address(this));

        // Get total supply of LP tokens for the Pancakeswap pair
        uint256 totalSupply = IPancakeV2Pair(lpToken).totalSupply();

        // Check total supply
        require (totalSupply > 0, "Total supply is zero");

        // Calculate the percentage of locked liquidity
        uint256 _percentMul100 = balance * 100 * 100 / totalSupply;

        // Return percentage and percentage multiplied by 100
        return (_percentMul100 / 100, _percentMul100);
    }
}