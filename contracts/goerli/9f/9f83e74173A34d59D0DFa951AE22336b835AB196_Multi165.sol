// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC165 {function supportsInterface(bytes4 interfaceId) external view returns (bool);}

contract Multi165 {

    function supportsInterface(IERC165[] calldata contracts, bytes4 interfaceId) public view returns (bool[] memory result) {
        result = new bool[](contracts.length);
        bytes memory callData = new bytes(36);
        assembly {            
            mstore(add(callData, 32), 0x01ffc9a700000000000000000000000000000000000000000000000000000000)
            mstore(add(callData, 36), interfaceId)
        }
        for(uint256 i = 0; i < contracts.length; i++) {
            (bool success, bytes memory returndata) = address(contracts[i]).staticcall{gas: 30000}(callData);
            // ensure there was enough gas ( >= 30,000) given to the `supportsInterface` call
            // Note that `{gas: 30000}` do not ensure that, it only protect the caller to not spend more than 30,000.
            assert(gasleft() > 476); // 30,000 / 63
            if (success && returndata.length > 0 && returndata.length < 33) {
                bytes32 data;
                assembly {
                        data := mload(add(returndata, 32))
                }
                result[i] = uint256(data) != 0;
            }
        }
    }

    function supportsMultipleInterfaces(IERC165[] calldata contracts, bytes4[] calldata interfaceIds) public view returns (bool[] memory result) {
        result = new bool[](contracts.length);
        uint256 numI = contracts.length;
        for(uint256 i = 0; i < numI; i++) {
            // asume true and set to false once one interfaceId is found to be not supported.
            result[i] = true;
            uint256 numJ = interfaceIds.length;
            for (uint256 j = 0; j < numJ; j ++) {
                bytes4 interfaceId = interfaceIds[j];
                bytes memory callData = new bytes(36);
                assembly {            
                    mstore(add(callData, 32), 0x01ffc9a700000000000000000000000000000000000000000000000000000000)
                    mstore(add(callData, 36), interfaceId)
                }
                (bool success, bytes memory returndata) = address(contracts[i]).staticcall{gas: 30000}(callData);
                // ensure there was enough gas ( >= 30,000) given to the `supportsInterface` call
                // Note that `{gas: 30000}` do not ensure that, it only protect the caller to not spend more than 30,000.
                assert(gasleft() > 476); // 30,000 / 63
                
                if (!success || returndata.length == 0 || returndata.length > 32) {
                    result[i] = false;
                    break;
                }
                bytes32 data;
                assembly {
                        data := mload(add(returndata, 32))
                }
                if(uint256(data) == 0) {
                    result[i] = false;
                    break;
                }
            }
        }
    }
}