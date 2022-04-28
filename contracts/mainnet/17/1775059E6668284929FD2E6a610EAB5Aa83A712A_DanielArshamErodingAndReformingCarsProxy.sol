// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*

    ██████╗  █████╗ ███╗   ██╗██╗███████╗██╗
    ██╔══██╗██╔══██╗████╗  ██║██║██╔════╝██║
    ██║  ██║███████║██╔██╗ ██║██║█████╗  ██║
    ██║  ██║██╔══██║██║╚██╗██║██║██╔══╝  ██║
    ██████╔╝██║  ██║██║ ╚████║██║███████╗███████╗
    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚══════╝╚══════╝

  █████╗ ██████╗ ███████╗██╗  ██╗ █████╗ ███╗   ███╗
 ██╔══██╗██╔══██╗██╔════╝██║  ██║██╔══██╗████╗ ████║
 ███████║██████╔╝███████╗███████║███████║██╔████╔██║
 ██╔══██║██╔══██╗╚════██║██╔══██║██╔══██║██║╚██╔╝██║
 ██║  ██║██║  ██║███████║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

                       ______
                      /     /\
                     /     /##\
                    /     /####\
                   /     /######\
                  /     /########\
                 /     /##########\
                /     /#####/\#####\
               /     /#####/++\#####\
              /     /#####/++++\#####\
             /     /#####/\+++++\#####\
            /     /#####/  \+++++\#####\
           /     /#####/    \+++++\#####\
          /     /#####/      \+++++\#####\
         /     /#####/        \+++++\#####\
        /     /#####/__________\+++++\#####\
       /                        \+++++\#####\
      /__________________________\+++++\####/
      \+++++++++++++++++++++++++++++++++\##/
       \+++++++++++++++++++++++++++++++++\/
        ``````````````````````````````````

              ██████╗██╗  ██╗██╗██████╗
             ██╔════╝╚██╗██╔╝██║██╔══██╗
             ██║      ╚███╔╝ ██║██████╔╝
             ██║      ██╔██╗ ██║██╔═══╝
             ╚██████╗██╔╝ ██╗██║██║
              ╚═════╝╚═╝  ╚═╝╚═╝╚═╝

*/

import "../interface/ICxipRegistry.sol";

// sha256(abi.encodePacked('eip1967.CxipRegistry.DanielArshamErodingAndReformingCarsProxy')) == 0xa02fc078e74005974d5615d21c608de70bf6b5bb5d4859bca6aeb16e41be6ff9
contract DanielArshamErodingAndReformingCarsProxy {
    fallback() external payable {
        // sha256(abi.encodePacked('eip1967.CxipRegistry.DanielArshamErodingAndReformingCars')) == 0xe3b4c4e0b41f8dc247603a686e2acd61e0a5b5d2a95ce2e35a1744406075c82f
        address _target = ICxipRegistry(0xC267d41f81308D7773ecB3BDd863a902ACC01Ade).getCustomSource(0xe3b4c4e0b41f8dc247603a686e2acd61e0a5b5d2a95ce2e35a1744406075c82f);
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _target, 0, calldatasize(), 0, 0)
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

interface ICxipRegistry {
    function getAsset() external view returns (address);

    function getAssetSigner() external view returns (address);

    function getAssetSource() external view returns (address);

    function getCopyright() external view returns (address);

    function getCopyrightSource() external view returns (address);

    function getCustomSource(bytes32 name) external view returns (address);

    function getCustomSourceFromString(string memory name) external view returns (address);

    function getERC1155CollectionSource() external view returns (address);

    function getERC721CollectionSource() external view returns (address);

    function getIdentitySource() external view returns (address);

    function getPA1D() external view returns (address);

    function getPA1DSource() external view returns (address);

    function getProvenance() external view returns (address);

    function getProvenanceSource() external view returns (address);

    function owner() external view returns (address);

    function setAsset(address proxy) external;

    function setAssetSigner(address source) external;

    function setAssetSource(address source) external;

    function setCopyright(address proxy) external;

    function setCopyrightSource(address source) external;

    function setCustomSource(string memory name, address source) external;

    function setERC1155CollectionSource(address source) external;

    function setERC721CollectionSource(address source) external;

    function setIdentitySource(address source) external;

    function setPA1D(address proxy) external;

    function setPA1DSource(address source) external;

    function setProvenance(address proxy) external;

    function setProvenanceSource(address source) external;
}