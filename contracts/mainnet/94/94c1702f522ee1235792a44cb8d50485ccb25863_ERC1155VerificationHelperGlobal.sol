/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//////////////////////////////////////////////////////////
//     _______  _______________ ____                    //
//    / __/ _ \/ ___<  <  / __// __/                    //
//   / _// , _/ /__ / // /__ \/__ \                     //
//  /___/_/|_|\___//_//_/____/____/                     //
//                                                      //
//    _   __        _ ____          __  _               //
//   | | / /__ ____(_) _(_)______ _/ /_(_)__  ___       //
//   | |/ / -_) __/ / _/ / __/ _ `/ __/ / _ \/ _ \      //
//   |___/\__/_/ /_/_//_/\__/\_,_/\__/_/\___/_//_/      //
//                                                      //
//     __ __    __                                      //
//    / // /__ / /__  ___ ____                          //
//   / _  / -_) / _ \/ -_) __/                          //
//  /_//_/\__/_/ .__/\__/_/                             //
//            /_/                                       //
//                                                      //
//   by: 0xInuarashi.eth                                //
//                                                      //
//////////////////////////////////////////////////////////

interface IERC1155 {
    function balanceOf(address owner_, uint256 tokenId_) external view returns (uint256);
}

contract ERC1155VerificationHelperGlobal {
    function getTotalERC1155Balances(address contract_, address owner_, uint256 start_, uint256 end_) external view returns (uint256) {
        uint256 _balance;
        for (uint256 i = start_; i <= end_;) {
            _balance += IERC1155(contract_).balanceOf(owner_, i);
            unchecked { ++i; }
        }
        return _balance;
    }
}