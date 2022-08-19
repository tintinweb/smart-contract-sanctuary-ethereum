/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MultiCall {
    function multiCall(address[] calldata targets, bytes[] calldata data)
        public
        view
        returns (bytes[][] memory)
    {

        bytes[] memory targetResults = new bytes[](data.length);
        bytes[][] memory results = new bytes[][](targets.length);

        for (uint i; i < targets.length; i++) {
            for(uint j;j<data.length;j++){
                (bool success, bytes memory result) = targets[i].staticcall(data[j]);
                require(success, "call failed");
                targetResults[j] = result;
            }
            results[i]=targetResults;
        }

        return results;
    }

        function robustMultiCall(address[] calldata targets, bytes[][] calldata data)
        public
        view
        returns (bytes[][] memory)
    {
        require(targets.length==data.length,"Length not equal!");
        bytes[][] memory results = new bytes[][](targets.length);
        for (uint i; i < targets.length; i++) {
            bytes[] memory targetResults = new bytes[](data[i].length);
            for(uint j;j<data[i].length;j++){
                (bool success, bytes memory result) = targets[i].staticcall(data[i][j]);
                require(success, "call failed");
                targetResults[j] = result;
            }
            results[i]=targetResults;
        }
        return results;
    }
        function getEthBalances(address[] calldata _addresses)
        public
        view
        returns (uint256[] memory){
        uint256[] memory balances=new uint256[](_addresses.length);
        for(uint i;i<_addresses.length;i++){
            balances[i]=address(_addresses[i]).balance;
        }
        return balances;
    }

}