/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// Part: SafeMath

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
}

// File: Faucet.sol

/*
 * @title: Rinkeby Test Faucet [Modified].
 * @author: Anthony (fps) https://github.com/fps8k .
 * @dev: 
 *
 * I once wrote this contract to deposit any specific amount of ether from the contract.
 * But on this mod [28/05/2022] I am re-writing it to actually dispose some specific ether 0.2 ether.
 * But it shall demand just 1 ether for fundings.
*/

contract Faucet
{
    // Use SafeMath for all uint.
    using SafeMath for uint256;
    // Faucet has no owner.
    // Collections, that is the total amount that a particular address has collected from the Faucet.
    mapping (address => uint256) private collections;
    // Funders, the total amount that a particular address has donated to the Faucet.
    mapping (address => uint256) private funders;
    // Time, the last time a particular address withdrew. Addresses can withdraw ether every 12 hours.
    mapping (address => uint256) private time;
    // Array of the addresses that have donated to the faucet.
    address[] public donators;
    // Balance of the contract.
    uint256 private balance;
    // Interval that is 12 hours.
    uint256 private interval = 12 hours;
    // uint256 private interval = 1 seconds;
    // Boolean to check for Re-Entrancy attacks.
    bool locked;



    // ============= E V E N T S =================

    // Emitted when someone funds the contract.
    event Fund(address indexed __funder, uint256 indexed __fund);
    // Emitted when the contract pays someone.
    event Pay(address indexed __receiver, uint256 indexed __fund);

    // ============= E V E N T S =================



    // ================ F A L L B A C K   A N D   R E C E I V E ================

    fallback() external payable{}
    receive() external payable{}

    // ================ F A L L B A C K   A N D   R E C E I V E ================



    // ================= M O D I F I E R ==========================

    // Checks for Re-Entrancy attacks.
    modifier noReEntrance()
    {
        // Requires that the locked is set to false.
        require(!locked, "No ReEntrance");
        // Lock the function.
        locked = true;
        // Execute.
        _;
        // Re-open the lock.
        locked = false;
    }

    // ================= M O D I F I E R ==========================



    // Checks if the address is in the donators array for a new push.
    function hasDonated(address _address) private view returns(bool)
    {
        // Push the length of the donators array to memory.
        uint256 l = donators.length;
        // Loop over the array
        for (uint256 k = 0; k < l; k++)
        {
            // If the donor exists in the array.
            if (donators[k] == _address)
                // Return true.
                return true;
        }

        // On loop end, that is, the donor is not in the array.
        return false;
    }



    /*
    * @dev:
    *
    * Funds any address on the condition that the time span of the last transaction to that address was 12 hours.
    */
    function fund() public payable noReEntrance
    {
        // Ensure address donating isn't a 0 address.
        require(msg.sender != address(0), "!Address");
        // Require that the donation is >= 1 ether.
        require(msg.value >= 1 ether, "Amount needed: 1 ether");
        // Balance left after donation.
        uint bal = msg.value - 1 ether;
        // This should be == 1 ether but for confirmation purposes.
        uint _fund = msg.value - bal;
        // Record the funders value;
        // (, uint256 j) = funders[msg.sender].tryAdd(1 ether);
        (, uint256 j) = funders[msg.sender].tryAdd(_fund);
        // Update the funder value.
        funders[msg.sender] = j;
        // Increment the balance of the contract.
        // (, uint256 p) = balance.tryAdd(1 ether);
        (, uint256 p) = balance.tryAdd(_fund);
        // Update new balance.
        balance = p;

        // If the address has not donated before, it should be added to the donators array.
        if (!hasDonated(msg.sender))
            // Add the address to the array.
            donators.push(msg.sender);

        // Emit the fund event.
        emit Fund(msg.sender, _fund);

        // If the balance is > 0.
        if (bal > 0)
            // Refund the balance`.
            payable(msg.sender).transfer(bal);
            // Emit the pay event.
            emit Pay(msg.sender, bal);
    }



    /*
    * @dev:
    *
    * This function requests for some ether from the faucet.
    * The faucet dispenses 0.2 ether for every address every 12 hours.
    */
    function request() public payable noReEntrance
    {
        // Ensure address donating isn't a 0 address.
        require(msg.sender != address(0), "!Address");
        // Make sure that the contract still has ether.
        require(balance > 0, "We have run out of ether");
        // Get the requester's last request time.
        uint256 last_time = time[msg.sender];
        // Make sure that the time passed is more than or == 12 hours.
        require((block.timestamp - last_time) > interval, "You can only withdraw every 12 hours!");
        // Remove 0.2 ether from balance.
        (, uint256 p) = balance.trySub(0.2 ether);
        // Reassign new balance.
        balance = p;
        // Update the collections of the requester.
        (, uint j) = collections[msg.sender].trySub(0.2 ether);
        // Update the requesters collections.
        collections[msg.sender] = j;
        // Update the last request time.
        time[msg.sender] = block.timestamp;
        // Transfer the funds to the requester.
        payable(msg.sender).transfer(0.2 ether);
        // Emit the pay event.
        emit Pay(msg.sender, 0.2 ether);
    }
}