/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface CallProxy{
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags

    ) external;
}

  

contract AnycallV6senderRinkebyTestnet{
    //real one 0x37414a8662bC1D25be3ee51Fb27C2686e2490A89

    // The destination anycall contract with anyexec method on ftm testnet
    address private anycallcontractdest=0xE4F2A6498E5e2BbBa41F77DB447c678C65b3cF7F;

    uint destchain=4002;

    address private owneraddress=0xfa7e030d2ac001c2bA147c0b147D468E4609f7CC;

    // Our Destination contract on FTM testnet
    address private receivercontract=0x0B9d284F411Aa8997c1E8286675E0ba2f6a5A4B3;
    
    event NewMsg(string msg);

    modifier onlyowner() {
        require(msg.sender == owneraddress, "only owner can call this method");
        _;
    }
    function changedestinationcontract(address _destcontract) onlyowner external {
        receivercontract=_destcontract;
    }

    function step1_initiateAnyCallSimple(string calldata _msg) external {
        emit NewMsg(_msg);
        if (msg.sender == owneraddress){
        CallProxy(anycallcontractdest).anyCall(
            receivercontract,

            // sending the encoded bytes of the string msg and decode on the destination chain
            abi.encode(_msg),
            address(0),
            destchain,

            // Using 0 flag to pay fee on destination chain
            0
            );
            
        }

    }

    function step1_initiateAnyCallSimple_srcfee(string calldata _msg) external {
        emit NewMsg(_msg);
        if (msg.sender == owneraddress){
        CallProxy(anycallcontractdest).anyCall(
            receivercontract,

            // sending the encoded bytes of the string msg and decode on the destination chain
            abi.encode(_msg),
            address(0),
            destchain,

            // Using 0 flag to pay fee on destination chain
            2
            );
            
        }

    }

}