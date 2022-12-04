/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

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
  

contract AnycallV6senderBNBMainnet{

    // The Multichain anycall contract on bnb mainnet
    address private anycallcontractbnb=0xC10Ef9F491C9B59f936957026020C321651ac078
;


    address private owneraddress=0xb042D589af31C8a3eF48DBF361fAb55444e37d86;

    // Destination contract on Polygon
    address private receivercontract= 0xa27C55E6D081a37bD39d81Dc0D2B3517f3901C77;
    
    event NewMsg(string msg);

    function step1_initiateAnyCallSimple(string calldata _msg) external {
        emit NewMsg(_msg);
        if (msg.sender == owneraddress){
        CallProxy(anycallcontractbnb).anyCall(
            receivercontract,

            // sending the encoded bytes of the string msg and decode on the destination chain
            abi.encode(_msg),

            // 0x as fallback address because we don't have a fallback function
            address(0),

            // chainid of polygon
            56,

            // Using 0 flag to pay fee on destination chain
            1
            );
            
        }

    }
}