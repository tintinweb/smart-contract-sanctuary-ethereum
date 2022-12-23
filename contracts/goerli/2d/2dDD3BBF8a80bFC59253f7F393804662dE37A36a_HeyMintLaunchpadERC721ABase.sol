// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IDiamondAddressRelay } from './interfaces/IDiamondAddressRelay.sol';

/**
 * @author Created by HeyMint Launchpad https://launchpad.heymint.xyz
 * @notice This contract contains the base logic for ERC-721A tokens deployed with HeyMint
 */
contract HeyMintLaunchpadERC721ABase {
    address public constant diamondAddressRelay =
        0xF46E213aAF8567896C0993745680004Fe092847F;

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        address facet = IDiamondAddressRelay(diamondAddressRelay).facetAddress(
            msg.sig
        );
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
pragma solidity ^0.8.17;

interface IDiamondAddressRelay {
    /// @notice Takes in a function signature and returns the address of the facet that implements that function
    /// @param msgSig Contains the facet addresses and function selectors
    function facetAddress(bytes4 msgSig) external view returns (address);
}