// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;
import "./B.sol";
import "./D.sol";

contract A{
    function sendEthertoB(address payable _to) public payable {
        (bool sent,) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether to B");
    }

    function sendEthertoD(address payable _to) public payable{
        (bool sent,) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether to D");
    }
}