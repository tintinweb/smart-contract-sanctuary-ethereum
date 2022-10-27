/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error notOwner();

contract ContractToDeployMetamask { //Bytecode matches creation code with no constructor input arguments. Bytecode with Remix IDE default wallet address 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4: 
                                    //0x60a060405234801561001057600080fd5b5073c1202e7d42655f23097476f6d48006fe56d38d4f73ffffffffffffffffffffffffffffffffffffffff1660808173ffffffffffffffffffffffffffffffffffffffff16815250506080516102c96100806000396000818160bb0152818160df015261016401526102c96000f3fe608060405234801561001057600080fd5b506004361061004c5760003560e01c806321cf146c14610051578063b4a99a4e1461006f578063f81bfa3f1461008d578063f965e32e14610097575b600080fd5b6100596100b3565b60405161006691906101be565b60405180910390f35b6100776100b9565b604051610084919061021a565b60405180910390f35b6100956100dd565b005b6100b160048036038101906100ac9190610266565b61019b565b005b60005481565b7f000000000000000000000000000000000000000000000000000000000000000081565b7f000000000000000000000000000000000000000000000000000000000000000073ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614610162576040517f251c9d6300000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b7f000000000000000000000000000000000000000000000000000000000000000073ffffffffffffffffffffffffffffffffffffffff16ff5b8060008190555050565b6000819050919050565b6101b8816101a5565b82525050565b60006020820190506101d360008301846101af565b92915050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000610204826101d9565b9050919050565b610214816101f9565b82525050565b600060208201905061022f600083018461020b565b92915050565b600080fd5b610243816101a5565b811461024e57600080fd5b50565b6000813590506102608161023a565b92915050565b60006020828403121561027c5761027b610235565b5b600061028a84828501610251565b9150509291505056fea2646970667358221220f13ed2f135ac0e33e3f372e325eaa526fa74eefc16e73495164e7b2549f0974464736f6c63430008110033
    uint public storageSlot0;
    address public immutable Owner;
    
    constructor() { // Put your address as Owner instead of msg.sender because msg.sender will be another contract with CREATE2 salt deploy.
        Owner = 0xc1202e7d42655F23097476f6D48006fE56d38d4f; // Default address in Remix IDE VM. 
    }                                                       // Do not do tx.origin because someone can front run you during contract creation!

    function changeValue(uint updateStorageSlot) public {
        storageSlot0 = updateStorageSlot;
    }

    function killThisContract() public { //After a contract is killed at an address, you can deploy another contract at that address.
        if(msg.sender != Owner) { revert notOwner(); }
        selfdestruct(payable(Owner)); //Deletes all data from this contract address. Address inside selfdestruct call gets all ether in the contract self destructing. 
    }                                

}