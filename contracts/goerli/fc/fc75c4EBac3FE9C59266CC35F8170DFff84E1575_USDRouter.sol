//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------
// GENERATED CODE - do not edit manually!!
// --------------------------------------------------------------------------------
// --------------------------------------------------------------------------------

contract USDRouter {
    error UnknownSelector(bytes4 sel);

    address private constant _INITIAL_MODULE_BUNDLE = 0x0831dd3d62fF9418C8bd749A4D67c9F47d5FdFe5;
    address private constant _ASSOCIATED_SYSTEMS_MODULE = 0x200801C26BD2181f1a5396988F31515A2Dfd39d1;
    address private constant _USDTOKEN_MODULE = 0xEa55C549561AC7B624D3e543b88Af00EFa97266A;

    fallback() external payable {
        _forward();
    }

    receive() external payable {
        _forward();
    }

    function _forward() internal {
        // Lookup table: Function selector => implementation contract
        bytes4 sig4 = msg.sig;
        address implementation;

        assembly {
            let sig32 := shr(224, sig4)

            function findImplementation(sig) -> result {
                if lt(sig,0x624bd96d) {
                    if lt(sig,0x35c22d29) {
                        switch sig
                        case 0x06fdde03 { result := _USDTOKEN_MODULE } // USDTokenModule.name()
                        case 0x095ea7b3 { result := _USDTOKEN_MODULE } // USDTokenModule.approve()
                        case 0x1624f6c6 { result := _USDTOKEN_MODULE } // USDTokenModule.initialize()
                        case 0x1627540c { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.nominateNewOwner()
                        case 0x18160ddd { result := _USDTOKEN_MODULE } // USDTokenModule.totalSupply()
                        case 0x23b872dd { result := _USDTOKEN_MODULE } // USDTokenModule.transferFrom()
                        case 0x2d22bef9 { result := _ASSOCIATED_SYSTEMS_MODULE } // AssociatedSystemsModule.initOrUpgradeNft()
                        case 0x313ce567 { result := _USDTOKEN_MODULE } // USDTokenModule.decimals()
                        leave
                    }
                    switch sig
                    case 0x35c22d29 { result := _USDTOKEN_MODULE } // USDTokenModule.transferCrossChain()
                    case 0x35eb2824 { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.isOwnerModuleInitialized()
                    case 0x3659cfe6 { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.upgradeTo()
                    case 0x392e53cd { result := _USDTOKEN_MODULE } // USDTokenModule.isInitialized()
                    case 0x40c10f19 { result := _USDTOKEN_MODULE } // USDTokenModule.mint()
                    case 0x53a47bb7 { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.nominatedOwner()
                    case 0x60988e09 { result := _ASSOCIATED_SYSTEMS_MODULE } // AssociatedSystemsModule.getAssociatedSystem()
                    leave
                }
                if lt(sig,0xaaa15fd1) {
                    switch sig
                    case 0x624bd96d { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.initializeOwnerModule()
                    case 0x70a08231 { result := _USDTOKEN_MODULE } // USDTokenModule.balanceOf()
                    case 0x718fe928 { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.renounceNomination()
                    case 0x79ba5097 { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.acceptOwnership()
                    case 0x8da5cb5b { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.owner()
                    case 0x95d89b41 { result := _USDTOKEN_MODULE } // USDTokenModule.symbol()
                    case 0x9dc29fac { result := _USDTOKEN_MODULE } // USDTokenModule.burn()
                    case 0xa9059cbb { result := _USDTOKEN_MODULE } // USDTokenModule.transfer()
                    leave
                }
                switch sig
                case 0xaaa15fd1 { result := _USDTOKEN_MODULE } // USDTokenModule.burnWithAllowance()
                case 0xaaf10f42 { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.getImplementation()
                case 0xc6f79537 { result := _ASSOCIATED_SYSTEMS_MODULE } // AssociatedSystemsModule.initOrUpgradeToken()
                case 0xc7f62cda { result := _INITIAL_MODULE_BUNDLE } // InitialModuleBundle.simulateUpgradeTo()
                case 0xd245d983 { result := _ASSOCIATED_SYSTEMS_MODULE } // AssociatedSystemsModule.registerUnmanagedSystem()
                case 0xda46098c { result := _USDTOKEN_MODULE } // USDTokenModule.setAllowance()
                case 0xdd62ed3e { result := _USDTOKEN_MODULE } // USDTokenModule.allowance()
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