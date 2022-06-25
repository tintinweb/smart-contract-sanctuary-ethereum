//SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.3;


// Defines a contract named `deadmansSwitch`.
contract deadmansSwitch{

    address public owner;
    address payable public beneficiary;
    uint public lastBlockCalled;
   
    constructor(address _beneficiary) payable{
        owner = msg.sender;
        beneficiary = payable(_beneficiary);
        still_alive();
    }

     modifier onlyOwner {
        require(msg.sender == owner, "not owner");
        _;
    }


    function still_alive() public onlyOwner{
        lastBlockCalled = block.number;
    }


    function updateBeneficiary(address _beneficiary) public onlyOwner{
        beneficiary = payable(_beneficiary);
        still_alive();
    }

  function releaseFunds() public {
        require(block.number - lastBlockCalled > 10, "owner still alive");
        require(address(this).balance > 0, "insufficient balance");
        require(msg.sender != owner, "owner can't release funds");

        (bool success, ) = beneficiary.call{ value: address(this).balance}('');
        require(success,'successfully withdrawn funds to beneficiary account');
    }
}