/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

/**
/**
*        \\                                                             //
*         \\\\\\\\                                               ////////
*          \\\\\\\\\\\\\\                                ///////////////
*           \\\\\\\\\\\\\\\\                           ////////////////
*            \\\\\\\\\\\\\\\\                         ////////////////
*             \\\\\\\\\\\\\\\\                       ////////////////
*              \\\\\\\\\\\\\\\\                     ////////////////
*               \\\\\\\\\\\\\\\\                   ////////////////
*       \\\      \\\\\\\\\\\\\\\\                 ////////////////      ///
*         \\\\\\\\\\\\\\\\\\\\\\\\               ////////////////////////
*          \\\\\\\\\\\\\\\\\\\\\\\\             ////////////////////////
*            \\\\\\\\\\\\\\\\\\\\\\\           ///////////////////////
*             \\\\\\\\\\\\\\\\\\\\\\\         ///////////////////////
*               \\\\\\\\\\\\\\\\\\\\\\       //////////////////////
*                \\\\\\\\\\\\\\    \\\\     ////    //////////////
*                  \\\\\\\\\\\\\                   /////////////
*                   \\\\\\\\\\\\\\               //////////////
*                     \\\\\\\\\\\\\             /////////////
*                      \\\\\\\\\\\\\\         //////////////
*                        \\\\\\\\\\\\\       /////////////
*                          \\\\\\\\\\\\\   //////////////
*                           \\\\\\\\\\\\\\/////////////
*                            \\\\\\\\\\\\\////////////
*                              \\\\\\\\\\\//////////
*                               \\\\\\\\\\/////////
*
*
*                     ██╗   ██╗███████╗███╗   ██╗██╗  ██╗   ██╗
*                     ██║   ██║██╔════╝████╗  ██║██║  ╚██╗ ██╔╝
*                     ██║   ██║█████╗  ██╔██╗ ██║██║   ╚████╔╝
*                     ╚██╗ ██╔╝██╔══╝  ██║╚██╗██║██║    ╚██╔╝
*                      ╚████╔╝ ███████╗██║ ╚████║███████╗██║
*                       ╚═══╝  ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝
*
*
* Copyright (C) 2020 Venly NV (https://kbopub.economie.fgov.be/kbopub/toonondernemingps.html?lang=en&ondernemingsnummer=704738355)
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
* SPDX-License-Identifier: Apache-2.0
*
*/

pragma solidity >=0.7.5;

interface ERC20 {
    function totalSupply() external view returns (uint supply);
}

interface ERC721 {
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}


contract ContractProxy {

    function checkErc721Approval(address contractAddress) public view returns (bool) {
        return ERC721(contractAddress).isApprovedForAll(contractAddress, contractAddress);
    }

    function checkErc20Supply(address contractAddress) public view returns (uint) {
        return ERC20(contractAddress).totalSupply();
    }

}

contract SupportsInterface {

    function supportsInterface(address contractAddress, bytes4[] calldata interfaceIds) external view returns (bool[] memory) {
        bool[] memory result = new bool[](interfaceIds.length);
        for (uint i = 0; i < interfaceIds.length; i++) {
            ERC165 erc165 = ERC165(contractAddress);
            result[i] = erc165.supportsInterface(interfaceIds[i]);
        }
        return result;
    }
}

contract VenlyTokenDetective {

    enum TOKEN_TYPE {UNKNOWN, IGNORED, ERC_20, ERC_721, ERC_1155}

    SupportsInterface public supportsInterfaceContract;

    bytes4[] public erc721InterfaceIds;
    bytes4[] public erc1155InterfaceIds;
    ContractProxy internal contractProxy;

    constructor(bytes4[] memory _erc721InterfaceIds, bytes4[] memory _erc1155InterfaceIds) {
        erc721InterfaceIds = _erc721InterfaceIds;
        erc1155InterfaceIds = _erc1155InterfaceIds;
        contractProxy = new ContractProxy();
        supportsInterfaceContract = new SupportsInterface();

    }

    function determineType(address contractAddress) public view returns (TOKEN_TYPE tokenType) {
        bool[] memory erc1155Results = supportsInterface(contractAddress, erc1155InterfaceIds);
        for (uint i = 0; i < erc1155Results.length; i++) {
            if (erc1155Results[i] == true) return TOKEN_TYPE.ERC_1155;
        }
        bool[] memory erc721Results = supportsInterface(contractAddress, erc721InterfaceIds);
        for (uint i = 0; i < erc721Results.length; i++) {
            if (erc721Results[i] == true) return TOKEN_TYPE.ERC_721;
        }
        //check isApprovedForAll function - it must be erc721
        //if has getBalance - it probably is ERC20

        try contractProxy.checkErc20Supply(contractAddress) returns (uint res) {
            res;
            return TOKEN_TYPE.ERC_20;
        }
        catch Error(string memory /*reason*/) {}
        catch (bytes memory /*lowLevelData*/) {}

        try contractProxy.checkErc721Approval(contractAddress) returns (bool res) {
            res;
            return TOKEN_TYPE.ERC_721;
        }
        catch Error(string memory /*reason*/) {}
        catch (bytes memory /*lowLevelData*/) {}

        return TOKEN_TYPE.UNKNOWN;
    }

    function supportsInterface(address contractAddress, bytes4[] memory interfaceIds) public view returns (bool[] memory) {
        try supportsInterfaceContract.supportsInterface(contractAddress, interfaceIds) returns (bool[] memory res) {
            return res;
        }
        catch Error(string memory /*reason*/) {}
        catch (bytes memory /*lowLevelData*/) {}

        bool[] memory result = new bool[](interfaceIds.length);
        for (uint i = 0; i < interfaceIds.length; i++) {
            result[i] = false;
        }
        return result;
    }

}