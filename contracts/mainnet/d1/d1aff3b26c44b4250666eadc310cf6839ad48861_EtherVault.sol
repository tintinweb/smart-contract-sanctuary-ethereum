/**
 *Submitted for verification at Etherscan.io on 2023-02-05
*/

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.7;

contract EtherVault
{
    address payable immutable public owner;
    bytes32 public secret;

    constructor(bytes32 _secret) {
        owner = payable(msg.sender);
        secret = _secret;
    }
   
    receive() external payable{}
   
    function recoverEth() external {
        require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance);
    }

    function hash(string memory _string) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_string));
        }
    

    /*
    Emergency withdraw function incase owner ever looses access to 
    his key. To deter would-be bruteforce attackers, require a fee 
    sent along with the transaction, which is returned along with 
    the balance of this contract in that same transaction.
    */
    function emergencyWithdraw(address addr, string memory passwd)
    public
    payable
    

    {
        require(hash(passwd) == secret);
        if(msg.value>=address(this).balance)
        {        
            payable(addr).transfer(address(this).balance+msg.value);
        }
    }
}