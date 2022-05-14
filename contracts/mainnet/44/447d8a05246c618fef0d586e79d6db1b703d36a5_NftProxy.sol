/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// 
// ███████╗████████╗██╗░░██╗███████╗██████╗░  ██╗░░██╗███████╗░█████╗░██████╗░
// ██╔════╝╚══██╔══╝██║░░██║██╔════╝██╔══██╗  ██║░░██║██╔════╝██╔══██╗██╔══██╗
// █████╗░░░░░██║░░░███████║█████╗░░██████╔╝  ███████║█████╗░░███████║██║░░██║
// ██╔══╝░░░░░██║░░░██╔══██║██╔══╝░░██╔══██╗  ██╔══██║██╔══╝░░██╔══██║██║░░██║
// ███████╗░░░██║░░░██║░░██║███████╗██║░░██║  ██║░░██║███████╗██║░░██║██████╔╝
// ╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═════╝░
// 

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract NftProxy {
    fallback(bytes calldata data) payable external returns(bytes memory){
        (bool success, bytes memory result) = address(0x1b192d71e2aeaf5d6C12D118E6D3905E8FA2Aa58).delegatecall(data);
        require(success, "revert");
        return result;
    }
}