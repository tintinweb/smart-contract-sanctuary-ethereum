/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

pragma solidity ^0.8.0;

contract InvalidOpcode {

    enum Dir {UP, LEFT, DOWN, RIGHT}
    Dir public currentDir;

    function changeDir(Dir newDir) public {
        require(uint8(newDir) <= uint8(Dir.RIGHT), "Out of range");
        currentDir = newDir;
    } 

}