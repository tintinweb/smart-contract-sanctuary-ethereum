/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: MIT
// Hey  My Name is Moonzart
// My dream is it to give Checks a Sound !
// Follow me on Twitter @MoonzartEth 
// Open Editon Check Notes are Live I need your Support
// https://zora.co/collections/0x563ccdd80aa46d2c19f6abea9ae195d5d3f5ae7e

pragma solidity ^0.8.16;

                                                                            
/*
                                        ▄▄█▄
                                      ▄██████
                                     █████████
                                    █████▀▀`▀██
                                   ▐███▀      █▌
                                   ███       ▐██
                                   ██▌       ███
                                   ██      ,████
                                   ██     ▄████"
                                   ▐█▌  ▄█████▀
                                    █████████▀
                                  ,▄████████
                                ▄█████████▀
                              ▄█████████▀
                            ▄████████▀██
                          ▄███████▀   ▐█▌
                        ,███████▀      ██
                       ,██████▀      ,▄████████▄▄
                       █████▀      ▄███████████████▄
                      j████▀     ▄██████▀██▀▀████████
                      j████     ▐████▀   ██     ▀█████
                       ███▌     ▐███      █▌      ████▌
                       └███      ██▌      ██       ███▌
                         ██▄      ▀█▄     `█▌     ,███
                          ▀██,      ▀▀█▄   ██    ,██▀
                            ▀██▄,          -█▌ ▄██▀
                               ▀▀███▄▄▄▄▄▄▄▄███▀-
                                     `       █▌
                                             ██
                                              █▌
                               ▄██████▄       ██
                              ██████████      ▐█▌
                              ██████████      ██
                              ▀██████▀▀      ██▀
                                ▀███▄▄▄▄▄▄▄██▀
*/                                                                               

contract HeyMoonzartHere {
  // Tipps are Welcome 
  function deposit() payable public {
    
    
}


 function withdraw() public   {
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(0xD2d2ED0C2fAFF23e579F8bA959683e8a9771B69D).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

}