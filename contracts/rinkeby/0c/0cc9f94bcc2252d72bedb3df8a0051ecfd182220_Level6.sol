/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

pragma solidity ^0.6.0;


interface Telephone {
    function transfer(address _to, uint _value) external returns (bool);
}

contract Level6 {

    constructor() public payable {

    }

    function selfDestruct() public {
        selfdestruct(payable(address(0x91a2071E6D7Cf4201832cB9Eb187E30fA8cA814B)));
    }

    receive() payable external {}
}