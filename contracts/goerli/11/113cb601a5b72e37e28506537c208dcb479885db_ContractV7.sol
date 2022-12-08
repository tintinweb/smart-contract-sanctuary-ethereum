// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

struct Args {
    address arg1_1;
    address arg1_2;
    bytes arg1_3;
}

enum FacetCutAction {
    Add,
    Replace,
    Remove
}

struct Args2 {
    address facetAddress;
    FacetCutAction action;
    bytes4[] functionSelectors;
}

contract ContractV7 {
    address public admin;
    address public init;

    address public facetAddress;
    FacetCutAction public action;
    bytes4[] public functionSelectors;

    address public facetAddressV2;
    FacetCutAction public actionV2;
    bytes4[] public functionSelectorsV2;

    constructor(Args memory _args, Args2[] memory _args2) {
        admin = _args.arg1_1;
        init = _args.arg1_2;
        for (uint256 i; i < _args2.length; i++) {
            if (i == 0) {
                facetAddress = _args2[i].facetAddress;
                action = _args2[i].action;
                functionSelectors = _args2[i].functionSelectors;
            } else if (i == 1) {
                facetAddressV2 = _args2[i].facetAddress;
                actionV2 = _args2[i].action;
                functionSelectorsV2 = _args2[i].functionSelectors;
            }
        }
    }

    function bar(uint256 x) public pure returns (bool) {
        if (x > 100) {
            return true;
        } else {
            return false;
        }
    }
}
//'(0xc6fa133f3290e14Ad91C7449f8D8101A6f894E25,0x398f06007A9980AE041cc91745CcB72f24d9B195,0x19ab453c000000000000000000000000c6fa133f3290e14ad91c7449f8d8101a6f894e25)' '[(0x6012e27f7Cee8d88A14e710dcb7dfe397f43411B,0,[0x1f931c1c])]'

//'(0xc6fa133f3290e14Ad91C7449f8D8101A6f894E25,0x398f06007A9980AE041cc91745CcB72f24d9B195,0x19ab453c000000000000000000000000c6fa133f3290e14ad91c7449f8d8101a6f894e25)' '[(0x6012e27f7Cee8d88A14e710dcb7dfe397f43411B,0,[0x1f931c1c]),(0x13e1C806Ee3173df0279dFC18Ed07C5AD0428aFC,0,[0xcdffacc6,0x52ef6b2c,0xadfca15e,0x7a0ed627,0x01ffc9a7]),(0xdF492532F1937A3842c59A074d9e6086795C7294,0,[0x8da5cb5b,0xf2fde38b]),(0xf74C68bD2450258c4D911d83333A607D7d9e5D4A,0,[0xfbff3a41,0xc3ffb565,0xeec5e10a,0xaa965572,0xda1d7676,0x1b950751,0x48428cd9,0x55eb1a72,0xaef6be3c,0xd7a41b09,0x9e016ae4,0xf4a6220b,0x248a9ca3,0x09a26eab,0xd7932955,0xe0024604,0xc9c25245,0x4ef83214,0x2f2ff15d,0x91d14854,0x8bb9c5bf,0xd547741f,0xb3094fd6,0x0bcf9ca3,0x38174654,0xba2d8cdd,0x47091398,0x4c9f5d86,0xf986cd57,0xf6f172cb,0x15f97398,0xe2d443bd,0x53b07507,0xbe1d86e1,0x92324611,0x147f1b96,0x6605bfda,0x8e8e1387])]'