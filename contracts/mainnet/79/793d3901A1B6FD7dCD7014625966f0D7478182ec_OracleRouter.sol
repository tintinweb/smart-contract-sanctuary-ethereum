//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// GENERATED CODE - do not edit manually!!
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract OracleRouter {
    error UnknownSelector(bytes4 sel);

    address private constant _CORE_MODULE = 0xa9926406647Cc20F9b76644Ea0569E82641B75bB;
    address private constant _NODE_MODULE = 0x9B19470324c1A99a5Eb6d04de5F369f9c5937a65;

    fallback() external payable {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x718fe928) {
                    switch sig
                    case 0x1627540c { result := _CORE_MODULE } // CoreModule.nominateNewOwner()
                    case 0x2a952b2d { result := _NODE_MODULE } // NodeModule.process()
                    case 0x3659cfe6 { result := _CORE_MODULE } // CoreModule.upgradeTo()
                    case 0x50c946fe { result := _NODE_MODULE } // NodeModule.getNode()
                    case 0x53a47bb7 { result := _CORE_MODULE } // CoreModule.nominatedOwner()
                    case 0x625ca21c { result := _NODE_MODULE } // NodeModule.getNodeId()
                    leave
                }
                switch sig
                case 0x718fe928 { result := _CORE_MODULE } // CoreModule.renounceNomination()
                case 0x79ba5097 { result := _CORE_MODULE } // CoreModule.acceptOwnership()
                case 0x8da5cb5b { result := _CORE_MODULE } // CoreModule.owner()
                case 0xaaf10f42 { result := _CORE_MODULE } // CoreModule.getImplementation()
                case 0xc7f62cda { result := _CORE_MODULE } // CoreModule.simulateUpgradeTo()
                case 0xdeba1b98 { result := _NODE_MODULE } // NodeModule.registerNode()
                leave
            }

            implementation := findImplementation(sig32)
        }

        if (implementation == address(0)) {
            revert UnknownSelector(sig4);
        }

        // Delegatecall to the implementation contract
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}