/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

pragma solidity ^0.8.7;

contract Registration {

    mapping (address => bool) public registered;

    function register() public {
        require(!isContract(msg.sender), "Contracts are disallowed!");
        registered[msg.sender] = true;
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}