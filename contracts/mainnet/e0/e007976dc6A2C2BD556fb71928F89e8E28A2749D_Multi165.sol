// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC165 {function supportsInterface(bytes4 interfaceId) external view returns (bool);}


library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

contract Multi165 {

    function supportsInterface(IERC165[] calldata contracts, bytes4 interfaceId) public view returns (bool[] memory result) {
        result = new bool[](contracts.length);
        for(uint256 i = 0; i < contracts.length; i++) {
            if (!Address.isContract(address(contracts[i]))) {
                continue;
            }
            try contracts[i].supportsInterface{gas: 30000}(interfaceId) returns (bool a) {
                result[i] = a;
            } catch {
                // ensure there was enough gas ( >= 30,000) given to the `supportsInterface` call
                // Note that `{gas: 30000}` do not ensure that, it only protect the caller to not spend more than 30,000.
                assert(gasleft() > 476); // 30,000 / 63
            }
        }
    }

    function supportsMultipleInterfaces(IERC165[] calldata contracts, bytes4[] calldata interfaceIds) public view returns (bool[] memory result) {
        result = new bool[](contracts.length);
        uint256 numI = contracts.length;
        for(uint256 i = 0; i < numI; i++) {
            if (!Address.isContract(address(contracts[i]))) {
                continue;
            }

            // asume true and set to false once one interfaceId is found to be not supported.
            result[i] = true;
            uint256 numJ = interfaceIds.length;
            for (uint256 j = 0; j < numJ; j ++) {
                bytes4 interfaceId = interfaceIds[j];
                try contracts[i].supportsInterface{gas: 30000}(interfaceId) returns (bool a) {
                    if (!a) {
                        result[i] = false;
                        break;
                    }
                } catch {
                    // ensure there was enough gas ( >= 30,000) given to the `supportsInterface` call
                    // Note that `{gas: 30000}` do not ensure that, it only protect the caller to not spend more than 30,000.
                    assert(gasleft() > 476); // 30,000 / 63
                    result[i] = false;
                    break;
                }
            }
        }
    }
}