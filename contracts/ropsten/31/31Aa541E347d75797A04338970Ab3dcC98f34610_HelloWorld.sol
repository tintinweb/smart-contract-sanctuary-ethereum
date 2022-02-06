/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

pragma solidity 0.5.16;

contract HelloWorld {
    uint storedData;

    function set(uint x) public {
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }

    function sayHello() public pure returns(string memory){
        return("hello world2");
    }

    function mint() public pure returns(string memory) {
        return ("you've just minted this NFT!");
    }
}