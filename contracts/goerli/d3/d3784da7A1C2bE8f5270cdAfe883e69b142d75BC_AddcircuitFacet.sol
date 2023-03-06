// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import "./CircuitLib.sol";

contract AddcircuitFacet {

    function addCircuit(string calldata _circuitId) external {
        CircuitLib.addCircuit(_circuitId);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

library CircuitLib{

    bytes32 internal constant NAMESPACE = keccak256("wtf.lib.circuit");
    struct Circuit{
        string[] circuitArray;
    }  

    function getStorage() internal pure returns (Circuit storage s){
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function addCircuit(string calldata _circuitId) internal{
        Circuit storage s = getStorage();
        s.circuitArray.push(_circuitId);
    }

    function getCircuits() internal view returns (string[] memory){
        return (getStorage().circuitArray);
    }

}