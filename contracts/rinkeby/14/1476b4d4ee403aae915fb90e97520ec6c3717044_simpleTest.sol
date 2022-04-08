/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.9.0;

contract simpleTest {
    address public owner;

    constructor() {
      owner = msg.sender;
    }

    function addOne (uint256 _num) public pure returns(uint256){
        return _num + 1;
    }

    function funding() public payable {

    }

    function nanoFaucet(address _receiver) public payable {
        uint256 faucetLeakageInWei = 200000;
        payable(_receiver).transfer(faucetLeakageInWei);
    }

    function balance() public view returns(uint256){
        return address(this).balance;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

}