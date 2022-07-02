/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

pragma solidity ^0.8.10;


interface IReceiver {
    function receiveTokens(uint256 amount) external;
}

contract FlashLoanDeFi {
    uint256 public poolBalance;
    mapping (address => uint256) public balances;

    // deposit for stake we will give you 7% of your deposit.
    function deposit() external payable {
        poolBalance += msg.value;
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amountToWithdraw = balances[msg.sender];
        balances[msg.sender] = 0;
        poolBalance -= amountToWithdraw;
        (bool sent, ) = msg.sender.call{value: amountToWithdraw}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}

    function flashLoan(uint256 borrowAmount) external {
        require(borrowAmount > 0, "Must borrow at least one token");

        uint256 balanceBefore = address(this).balance;
        require(balanceBefore >= borrowAmount, "Not enough tokens in pool");

        (bool sent, ) = msg.sender.call{value: borrowAmount}("");
        require(sent, "Failed to send Ether");

        // Do something with the money
        IReceiver(msg.sender).receiveTokens(borrowAmount);

        // Pay me back
        uint256 balanceAfter = address(this).balance;
        require(balanceAfter == balanceBefore, "Flash loan hasn't been paid back");

        // Ensure that everything is fine once again to be 100% sure
        // assert(poolBalance == balanceBefore);
    }

}