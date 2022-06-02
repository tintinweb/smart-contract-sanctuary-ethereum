/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

pragma solidity 0.6.4;
//pragma solidity 0.8.13;

contract Faucet {
    function withdraw(uint withdraw_amount) public {
        require(withdraw_amount <= 100000000000000000); // 0.1 ether

        msg.sender.transfer(withdraw_amount);
    }

    // Accept any incoming amount
    //function() public payable {}
    //receive() external payable {}
    event Received(address, uint);
    receive() external payable  {
        emit Received(msg.sender, msg.value);
    }
}