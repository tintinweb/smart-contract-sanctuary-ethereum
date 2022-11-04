/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

//   ___________       ___________       ___________       ___________       ___________       ___________       ___________       _________  _
// /__________    \ \/__________    \ \/__________    \ \/__________    \ \/__________    \ \/__________    \ \/__________    \ \/____________\ \ 
// \____\/    \____\/\____\/    \____\/\____\/    \____\/\____\/    \____\/\____\/    \____\/\____\/    \____\/\____\/    \____\/\____\/  \____\/ 
//                                                                                                                               
//              _             _                   _             _              _                                     _                               
//             /\ \          / /\                /\_\          /\_\           /\ \         ******         ******                /\ \    /\ \                             
//            /  \ \        / /  \              / / /  _      / / /  _        \ \ \       **********    ***********            /  \ \   \ \ \                            
//           / /\ \_\      / / /\ \            / / /  /\_\   / / /  /\_\      /\ \_\     ************  *************          / /\ \ \  /\ \_\                           
//          / / /\/_/     / / /\ \ \          / / /__/ / /  / / /__/ / /     / /\/_/     ***************************         / / /\ \_\/ /\/_/                           
//         / / / ______  / / /  \ \ \        / /\_____/ /  / /\_____/ /     / / /         *************************         / /_/_ \/_/ / /                              
//        / / / /\_____\/ / /___/ /\ \      / /\_______/  / /\_______/     / / /             ********************          / /____/\ / / /                               
//       / / /  \/____ / / /_____/ /\ \    / / /\ \ \    / / /\ \ \       / / /                *****************          / /\____\// / /                                
//      / / /_____/ / / /_________/\ \ \  / / /  \ \ \  / / /  \ \ \  ___/ / /__                  ************           / / /  ___/ / /__                               
//     / / /______\/ / / /_       __\ \_\/ / /    \ \ \/ / /    \ \ \/\__\/_/___\                   ********            / / /  /\__\/_/___\                              
//     \/___________/\_\___\     /____/_/\/_/      \_\_\/_/      \_\_\/_________/                     ****            \/_/   \/_________/                              
//                                                                                                    *                                                                                                                             
//                                                                                                          
//   ___________       ___________       ___________       ___________       ___________       ___________       ___________       ___________   
// /__________    \ \/__________    \ \/__________    \ \/__________    \ \/__________    \ \/__________    \ \/__________    \ \/__________  /  
// \____\/    \____\/\____\/    \____\/\____\/    \____\/\____\/    \____\/\____\/    \____\/\____\/    \____\/\____\/    \____\/\____\/_____/


// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


library LibStorage {
    function writeAddress(bytes32 _key, address _addr) internal {
        assembly {
            sstore(_key, _addr)
        }
    }
    
    function readAddress(bytes32 _key) internal view returns (address addr) {
        assembly {
            addr := sload(_key)
        }
    }

    function writeBytes32(bytes32 _key, bytes32 _val) internal {
        assembly {
            sstore(_key, _val)
        }
    }

    function readFirstBool(bytes32 _key) internal view returns (bool val) {
        assembly {
            let tmp := sload(_key)
            val := shr(248, tmp)
        }
    }

    function readBytes32(bytes32 _key) internal view returns (bytes32 val) {
        assembly {
            val := sload(_key)
        }
    }
}

contract GakkiFiProxy {

    // GAKKI_ADDRESS_SLOT = keccak256("gakki") 
    bytes32 private constant GAKKI_ADDRESS_SLOT = bytes32(0xf6d5a684f5420414de5bb830d36f11084ccb1442c5536d5caf13868aed4d0ada);
    // FI_ADDRESS_SLOT = keccak256("fi");
    bytes32 private constant FI_ADDRESS_SLOT = bytes32(0xd7884a76b5eebe601ddb427195752db0165b44150b83c38b75b75ca295e99dfe);

    // IMPL_SLOT = keccak256("gakki-fi-impl")
    bytes32 private constant IMPL_SLOT = bytes32(0xfa822b32e32a2ae29c7c263f0b76e7418fe3a4c9d8e1c3d048806fa080c04d6a);

    // LAUNCH_DATA_SLOT = keccak256("launch-data"); 
    bytes32 private constant LAUNCH_DATA_SLOT = bytes32(0x929974b8360e5bf3c7c8ba708795a63f96483f402eb2cd5119a30912816d4a9b);

    event Launch();

    constructor(
        address _gakki,
        address _fi
    ) {
        LibStorage.writeAddress(GAKKI_ADDRESS_SLOT, _gakki);

        LibStorage.writeAddress(FI_ADDRESS_SLOT, _fi);
    }

    function launchData() external view returns(bytes32 data) {
        data = LibStorage.readBytes32(LAUNCH_DATA_SLOT);
    }

    modifier onlyFamily {
        address gakki = LibStorage.readAddress(GAKKI_ADDRESS_SLOT);
        address fi = LibStorage.readAddress(FI_ADDRESS_SLOT);
        require(msg.sender == fi || msg.sender == gakki, "auth");
        _;
    }

    function start(
        bytes32 loveHash, 
        uint8 v, bytes32 r, bytes32 s
    ) external onlyFamily {
        address gakki = LibStorage.readAddress(GAKKI_ADDRESS_SLOT);
        bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", loveHash));

        require(gakki == ecrecover(messageDigest, v, r, s),  "Failed to launch");

        setLaunchData();

        emit Launch();
    }
    
    function setLaunchData() internal {
        bytes32 data = bytes32(abi.encodePacked(true, uint64(block.number), uint64(block.timestamp)));
        LibStorage.writeBytes32(LAUNCH_DATA_SLOT, data);
    }

    function setImpl(address impl) external onlyFamily {
        LibStorage.writeAddress(IMPL_SLOT, impl);
    }

    fallback() external payable {
        require(LibStorage.readFirstBool(LAUNCH_DATA_SLOT), "Not enabled");
    
        address _target = LibStorage.readAddress(IMPL_SLOT);

        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let result := delegatecall(gas(), _target, 0x0, calldatasize(), 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result case 0 {revert(0, 0)} default {return (0, returndatasize())}
        }
    }
}