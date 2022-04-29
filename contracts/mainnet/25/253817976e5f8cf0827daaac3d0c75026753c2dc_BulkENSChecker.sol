/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

pragma solidity ^0.8.0;


interface ENS {
  function available(string memory) external view returns (bool);
}

contract BulkENSChecker {
    ENS ens = ENS(0x283Af0B28c62C092C9727F1Ee09c02CA627EB7F5);

    function checkAvail(string[] memory test) external view returns (string[] memory) {
        string[] memory returnData = new string[] (test.length);
        uint count;
        for (uint i; i<test.length; i++) {
            if (ens.available(test[i])) returnData[count++]=test[i];
        }
    return returnData;
    }
}