/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

pragma solidity ^0.6.0;
contract Simple {
    uint value =0;
    function setValue ( uint newValue ) external payable {
        require ( msg . value == 100 wei ) ;
        value = newValue ;
}

function getValue () external view returns ( uint ) {
    return value ;
}}