/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

pragma solidity ^0.8.0;

contract Nani {
    constructor() payable {}
    function wtf() public {
        selfdestruct(payable(address(this)));
    }
}

contract Deployer {
    function deployNani() payable public returns(address) {
        bytes32 _salt = 0x00000000000000000000000000000000;
        Nani _nani = new Nani{salt: _salt, value: msg.value}();
        return(address(_nani));
    }

    function balanceOf(address a) public view returns(uint256) {
        return a.balance;
    }
}