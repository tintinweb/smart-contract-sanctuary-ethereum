/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

contract LegionControl {
    uint256 guess;
    string correct = "Guess is correct";
    string incorrect = "Guess is incorrect";
    // Quest Part 1: Complete this function so that it returns true when `guess` is equal to 1.
    // Hint: You can use the comparison/equals operator `==`.
    // See: https://www.geeksforgeeks.org/solidity-operators/ Under "Relational Operators".
    function part1Condition(uint256 guess) public pure returns (bool) {
        // Add your code below here
        if (guess == 1) {
            return true;
        }
        // Add your code above here
    }

    // Quest Part 2: Complete this function so that it returns the following:
    // - "Guess is correct." when `guess` is 100.
    // - "Guess is incorrect." when `guess` is any other number.
    // Hint: Use an `if` statement with a condition like in Part 1.
    // See: https://www.geeksforgeeks.org/solidity-decision-making-statements Under "If Statement".
    function part2IfThenElse(uint256 guess) public view returns (string memory) {
        // Add your code below here
        if (guess == 100) {
            return(correct);
        } else {
            return(incorrect);
        }
        // Add your code above here
    }

    // Quest Part 3: Complete this function so that it returns 10 using a For loop.
    // For this part, you only need to fill in the part between the parenthesis for the For loop.
    // Specifically, you'll need to add the initialization, test condition, and iteration statement.
    // You do not need to modify anything else in the function.
    // See: https://www.geeksforgeeks.org/solidity-while-do-while-and-for-loop Under "For Loop".
    function part3ForLoop() public pure returns (uint) {
        uint count;
        uint i;
        for (i = 0; i < 10; i++) {
            count++;         
        }
        return count;
    }

    // Quest Part 4: Complete this function so that it returns 10 using a While loop.
    // For this part, you only need to fill in the part between the parenthesis for the While loop.
    // Specifically, you'll need to add the condition.
    // You do not need to modify anything else in the function.
    // See: https://www.geeksforgeeks.org/solidity-while-do-while-and-for-loop Under "While Loop".
    function part4WhileLoop() public pure returns (uint) {
        uint i;
        uint count;
        while (i < 10) {
            count++;
            i++;
        }
        return count;
    }
}