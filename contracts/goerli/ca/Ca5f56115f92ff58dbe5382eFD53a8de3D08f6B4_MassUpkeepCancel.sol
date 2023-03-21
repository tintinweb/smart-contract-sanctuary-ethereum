/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

pragma solidity 0.7.6;

contract MassUpkeepCancel {

    function _CancelUpkeep(address registryAddress, uint256 upkeepId) private {
        KeeperRegistry registry = KeeperRegistry(registryAddress);
        registry.cancelUpkeep(upkeepId);
    }
    

    function MassCancelUpkeeps(address registryAddress, uint256[] memory upkeepIds) external {
        for (uint i=0; i<upkeepIds.length; i++) {
            _CancelUpkeep(registryAddress, upkeepIds[i]);
        }
    }

}

interface KeeperRegistry {
    function cancelUpkeep(uint256 id) external;
}