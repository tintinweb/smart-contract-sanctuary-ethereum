pragma solidity ^0.8.0;



contract Test {

    mapping (address => int256) public balanceOf;

    event depositedBy(address indexed, uint value);
    event withdrawnBy(address indexed, uint value);
    
    // ... some logic
    
    function deposit(address app) public payable {
        balanceOf[app] += int256(msg.value);
        emit depositedBy(app, msg.value);
    }

    function withdraw(address app, uint256 amount)
        public
        returns (uint256 ethAmount)
    {
        balanceOf[app] -= int256(amount);
        (bool success, ) = app.call{value: amount}("");
        require(success);
        assembly {
            ethAmount := amount
        }
        emit withdrawnBy(app, amount);
    }

    fallback() external payable {

    }

    function getBalance () view external returns(uint balance) {
        balance = address(this).balance;
    }

}