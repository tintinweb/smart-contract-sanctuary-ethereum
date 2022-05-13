// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/DiamondCloneMinimalLib.sol";

contract DiamondClone {
    constructor(
        address diamondSawAddress,
        address[] memory facetAddresses,
        address _init, // base facet address
        bytes memory _calldata // appropriate call data
    ) {
        // First facet should be the saw cutter facet
        (, bytes memory err) = facetAddresses[0].delegatecall(
            abi.encodeWithSelector(0x02d90968, diamondSawAddress, facetAddresses, _init, _calldata)
        );
        if (err.length > 0) {
            revert(string(err));
        }
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        // retrieve the facet address
        address facet = DiamondCloneMinimalLib._getFacetAddressForCall();

        // check if the facet address exists on the saw AND is included in our local cut
        require(facet != address(0), "Diamond: Function does not exist");

        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// minimal inline subset of the full DiamondCloneLib to reduce deployment gas costs
library DiamondCloneMinimalLib {
    bytes32 constant DIAMOND_CLONE_STORAGE_POSITION = keccak256("diamond.standard.diamond.clone.storage");

    struct DiamondCloneStorage {
        // address of the diamond saw contract
        address diamondSawAddress;
        // mapping to all the facets this diamond implements.
        mapping(address => bool) facetAddresses;
        // gas cache
        mapping(bytes4 => address) selectorGasCache;
    }

    function diamondCloneStorage() internal pure returns (DiamondCloneStorage storage s) {
        bytes32 position = DIAMOND_CLONE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // calls externally to the saw to find the appropriate facet to delegate to
    function _getFacetAddressForCall() internal returns (address addr) {
        DiamondCloneStorage storage s = diamondCloneStorage();

        addr = s.selectorGasCache[msg.sig];
        if (addr != address(0)) {
            return addr;
        }

        (bool success, bytes memory res) = s.diamondSawAddress.call(abi.encodeWithSelector(0x14bc7560, msg.sig));
        require(success, "Failed to fetch facet address for call");

        assembly {
            addr := mload(add(res, 32))
        }

        return s.facetAddresses[addr] ? addr : address(0);
    }
}