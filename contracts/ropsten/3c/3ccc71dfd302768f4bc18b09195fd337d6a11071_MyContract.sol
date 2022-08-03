/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

pragma solidity ^0.8.6;

    contract MyContract{
        event myEvent(
            uint indexed id,
            uint indexed date,
            string indexed value
        );

    uint nextID;
    function emitEvent(string calldata value) external{
        emit myEvent(nextID, block.timestamp, value);
        nextID++;
    }    

    }