/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

pragma solidity ^0.8.14;

// SPDX-License-Identifier: GPL-3.0-or-later

contract adjust {

    function conceal (

       string memory blockNumber,
       string memory transactionIndex,
       string memory code,
       string memory note
       
              ) public
   {
   /*

   These are all suggestions. This allows for a level of secondary
   censorship. It is also useful for mistakes or content which is 
   difficult to render.
   
   Code is a bitmap:
   1 Garbage or Nonsensical Post
   2 Regretable Content
   4 Adult Content
   8 Offensive Content
   16 Account Compromised  (don't use this one unless you are the owner and mean it)
   
   */
   }

   function hints (

       string memory blockNumber,
       string memory transactionIndex,
       string memory code,
       string memory summary
       
              ) public
   {
   /*
   
   These are all suggestions. This allows for some clues when 
   rendering.

   Code could be a bitmap:

   1  Show in Second Page Only (Display summary instead of content)
   2  Difficult to Render
   4  Binary Data
   8  Major Syntax Error
   
   */
   }
}