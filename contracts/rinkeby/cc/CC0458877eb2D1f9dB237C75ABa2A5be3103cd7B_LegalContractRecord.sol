/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
// _______________________________________________________________________________________________
// ||                                                                                           ||
// ||     //////  //      //////   ////// //   //  ////// //    //    ////    ////// ///     // ||
// ||    //   // //     //    // //      // //   //      //    //   //  //     //   ////    //  ||
// ||   //////  //     //    // //      ////    //      ////////  ////////    //   //  //  //   ||
// ||  //   // //     //    // //      // //   //      //    // //      //   //   //    ////    ||
// || //////  /////// //////   ////// //   //  ////// //    // //      // ////// //     ///     ||
// ||                                                                                           ||
// ||     //////  //////  ///     // ////// ////// //////   ///     ///                         ||
// ||   //      //    // ////    // //       //   //   //  ////   ////                          ||
// ||  //      //    // //  //  // //////   //   //////   // // // //                           ||
// || //      //    // //    //// //       //   //  //   //  ///  //                            ||
// || //////  //////  //     /// //     ////// //    // //       //                             ||
// _______________________________________________________________________________________________

pragma solidity ^0.6.12;

contract LegalContractRecord {

    address internal owner;

    constructor() public {
        owner = msg.sender;
    }

    struct LegalContract {
        string contractName;
        string contractParties;
        string contractFiles;
        string filesHash;
    }

    LegalContract[] internal legalContract;

    function checkContracts(uint256 _index) public view returns (string memory, string memory, string memory, string memory) {
        return (
            legalContract[_index].contractName, 
            legalContract[_index].contractParties, 
            legalContract[_index].contractFiles, 
            legalContract[_index].filesHash
        );
    }

    function addContract(string memory ContractName, string memory PartiesInvolved, string memory Files, string memory FileHash) public {
        if (msg.sender == owner) {
            legalContract.push(LegalContract(ContractName, PartiesInvolved, Files, FileHash));
        }
    }
}