//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface IFlashLoanReceiver {
    function processLoan(uint256 borrowAmount) external payable;
}

contract FlashLoan {
    address payable public owner = payable(0x11dc744F9b69b87a1eb19C3900e0fF85B6853990);

    constructor() payable {}

    function takeFlashLoan(uint256 borrowAmount) external {
        uint256 balanceBefore = address(this).balance;
        require(balanceBefore >= borrowAmount, "Not enough ETH in pool");
        
        IFlashLoanReceiver receiver = IFlashLoanReceiver(msg.sender);
        receiver.processLoan{value: borrowAmount}(borrowAmount);

        require(
            address(this).balance >= balanceBefore, 
            "Flash loan hasn't been paid back"
        );
    }

    function finishChallenge() external {
        require(msg.sender == owner);
        owner.call{value: 100 ether}("");
    }

    receive() external payable {}
}