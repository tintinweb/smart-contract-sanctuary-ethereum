/**
 *Submitted for verification at Etherscan.io on 2022-03-31
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

contract BlockchainConfirmRecord {

    address internal owner;

    constructor() public {
        owner = msg.sender;
    }

    struct DocumentsRecord {
        string Certificate_ID;
        string Number_of_parties;
        string Number_of_files;
        string File_hash_and_size;
    }

    DocumentsRecord[] internal Record_of_documents;

    function checkContracts(uint256 _index) public view returns (string memory, string memory, string memory, string memory) {
        return (
            Record_of_documents[_index].Certificate_ID, 
            Record_of_documents[_index].Number_of_parties, 
            Record_of_documents[_index].Number_of_files, 
            Record_of_documents[_index].File_hash_and_size
        );
    }

    function addContract(string memory Certificate_ID, string memory Number_of_parties, string memory Number_of_files, string memory File_hash_and_size) public {
        if (msg.sender == owner) {
            Record_of_documents.push(DocumentsRecord(Certificate_ID, Number_of_parties, Number_of_files, File_hash_and_size));
        }
    }
}