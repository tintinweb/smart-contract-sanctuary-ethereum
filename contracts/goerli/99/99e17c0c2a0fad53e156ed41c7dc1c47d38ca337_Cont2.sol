// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Cont1.sol";
contract Cont2 is Welcome{
}
contract caller{
    Cont2 cont1 = new Cont2();
    function viewco1() public view returns(string memory){
        return cont1.retrieve();
    }
    function changeco1() public returns(string memory){
        return cont1.changeWord();
    }
}