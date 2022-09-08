/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract EventsManager {
   uint count;

    event PublishA(address sender, address[] authors, string uri, string digest);
    event PublishB(address[] authors, string uri, string digest);
    event PublishC(address sender);
    event PublishD();

    constructor() {
    }


   function publiA(address[] calldata authors, string calldata uri, string calldata digest) public {  
      emit PublishA(msg.sender, authors, uri, digest);
   }

   function publiB(address[] calldata authors, string calldata uri, string calldata digest) public {  
      emit PublishB(authors, uri, digest);
   }

   function publiC(address[] calldata authors, string calldata uri, string calldata digest) public {  
      emit PublishC(msg.sender);
   }

   function publiD(address[] calldata authors, string calldata uri, string calldata digest) public {  
      emit PublishD();
   }

    function getCount() public view returns (uint) {
      return count;
    }
}