/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld {
    string handsomeGuy = "Nawit";

    function seeWhoHandsome() public view returns(string memory) {
        return handsomeGuy;
    }
}