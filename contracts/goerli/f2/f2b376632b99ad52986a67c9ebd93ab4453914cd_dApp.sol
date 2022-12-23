/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

pragma solidity 0.8.17;

contract dApp {
    string mood;

    function setMood (string memory _mood) public {
        mood = _mood;
    }

    function getMood() public view returns (string memory) {
        return mood;
    }
}