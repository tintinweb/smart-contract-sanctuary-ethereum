/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract Jackson{

    bytes public constant svgStub2 = hex"2720783d273131302720793d273630272077696474683d2732383027206865696768743d27333830272f3e3c72656374207374796c653d2766696c6c3a75726c28237368292720783d273338362720793d273630272077696474683d273527206865696768743d27333830272f3e3c72656374207374796c653d2766696c6c3a75726c2823736832292720783d273131302720793d27343337272077696474683d2732383127206865696768743d2734272f3e3c72656374207374796c653d2766696c6c3a75726c2823736832292720783d273131302720793d27343337272077696474683d2732383127206865696768743d273427207472616e73666f726d3d277363616c6528312c2d312927207472616e73666f726d2d6f726967696e3d2763656e746572272f3e3c672069643d27722720";
    bytes public constant svgStub3 = hex"0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000378797a0000000000000000000000000000000000000000000000000000000000";

    function _generateSVG() public view returns(bytes memory) {
        return abi.encodePacked(

            svgStub3

        );
    }
    function _ddSVG() public view returns(string memory) {
        return decode1(svgStub3);
    }


    function decode1(bytes memory data) public pure returns (string memory _str1) {
        return abi.decode(data, (string));            
    }

    function decode(bytes memory data) public pure returns (string memory _str1, uint _number, string memory _str2) {
        (_str1, _number, _str2) = abi.decode(data, (string, uint, string));            
    }

    function encode1(string memory _string1) public pure returns (bytes memory) {
        return (abi.encode(_string1));
    }

}