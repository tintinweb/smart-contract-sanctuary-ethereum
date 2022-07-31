/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Cafe {

    address payable public owner;
    uint256 cost = 0 wei;

     constructor()  {
         owner = payable(msg.sender);
     }

    function buy() public payable {
      require(msg.value > cost); 
    }
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

     function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = payable(newOwner);
    }

     modifier onlyOwner(){
            require(msg.sender == owner);
            _;
        }

    function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}