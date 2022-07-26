/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

pragma solidity >0.8.0;

contract GasTest {

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    function deposit() public payable {
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit Withdrawn(msg.sender, balance);
    }


    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}

    fallback() external payable {}

}