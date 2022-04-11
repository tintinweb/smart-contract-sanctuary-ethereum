// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Demo {
    address owner;
    string hi;
    address signer; 

     modifier testOwner() {
              require(owner == msg.sender, "Error message");
              _;
     }
     event Payd (address _add, uint _val, uint _time);

     constructor(string memory _message) {
         owner = msg.sender;
         hi = _message;
         signer = address(this);
     }

    // function pay () external payable {
    //     emit Payd (msg.sender, msg.value, block.timestamp);

    // }

    receive () external payable {
           emit Payd (msg.sender, msg.value, block.timestamp);
    }

    function withdraw(address payable _to) public testOwner {
        
         _to.transfer(signer.balance);

    }

    function getBalans () public view returns (uint) {
        return (signer.balance);
    }

}