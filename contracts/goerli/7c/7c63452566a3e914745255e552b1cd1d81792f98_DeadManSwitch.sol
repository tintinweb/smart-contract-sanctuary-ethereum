/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: GPL-3.0 
pragma solidity >=0.7.0 <0.9.0;

contract DeadManSwitch{

    address public ownerAddress;
    address payable designatedAddress; //all money will be transferred to this account if owner account is dead
    uint256 public blockNumberOflastBlockCalled = 0;

    //only one time you make the contract and it get's deployed on some block
    constructor () payable{
        designatedAddress = payable(0x7B85313D1e5d46718B79724B4517809037ABb73D);
        ownerAddress = msg.sender;
    }
    /*
        Creating a modifier which only enables the owner to access functions

    */
   modifier onlyOwnerAccess {
            require(msg.sender == ownerAddress);
            _;
        }

    // the function which can be called only by the owner to set the last block number called
    function _stillAlive() external onlyOwnerAccess{
        blockNumberOflastBlockCalled = block.number;
    }
    /*
        Transferring all the money from owner account to the designatedAddress account
        (internal and private functions cannot be payable)
    */
    function destroySmartContract() internal {
        selfdestruct(designatedAddress);
    }

    /*
        Function that can be called to check if ownerAccount is still active or not
    */
    function checkIfOwnerAccountStillActive() public returns(bool) {
        uint256 numberOfBlocksCalledSinceLastCall = block.number - blockNumberOflastBlockCalled;
        if(block.number >= 10 && numberOfBlocksCalledSinceLastCall > 10) {
            destroySmartContract();
            return false;
        }
        else {
            return true;
        }
    }
}