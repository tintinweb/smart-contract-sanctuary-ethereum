/**
 *	Question 2:
 *  Explain whats wrong with this contract.
 * 	And Fix the same, please take note of the solidity code version.
 */

 /**
  * Answer:
  *
  * Notes:
  * Having three withdraw function seems to be excessive.
  * withdrawAllAmount function has an amount input param which is not used really.
  * There is no reason for withdraw functions to be payable or to check msg.value.
  * Also transfer event was not declared and using it only for one withdraw function doesn't make sense.
  */

pragma solidity >=0.4.21 <0.7.0;

contract ContractBalanceTest {
    address public owner;

    event Transfer(uint256 amount);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner () {
        require(msg.sender == owner, "This can only be called by the contract owner!");
        _;
    }

    function deposit() payable public {
    }

    function depositAmount(uint256 amount) payable public {
        require(msg.value == amount);
    }

    function withdraw() onlyOwner public {
        msg.sender.transfer(address(this).balance);
        emit Transfer(address(this).balance);
    }

    function withdrawAmount(uint256 amount) onlyOwner public {
        require(amount <= address(this).balance);
        msg.sender.transfer(amount);
        emit Transfer(amount);
    }

}