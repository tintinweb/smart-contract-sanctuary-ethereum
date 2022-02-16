/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

pragma solidity ^0.8.4;

contract NameContract {

    address private name = 0xF481c92a7e5b113b094E093CF3454Ceb5F395B91;

    function getName() public view returns (address) 
    {
        return name;
    }

    function setName(address newName) public
    {
        name = newName;
    }

}