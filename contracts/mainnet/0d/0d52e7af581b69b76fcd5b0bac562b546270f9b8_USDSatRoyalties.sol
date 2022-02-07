// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./Ownable.sol";

contract USDSatRoyalties is Ownable {
    address public ADDRESS_PBOY = 0x709e17B3Ec505F80eAb064d0F2A71c743cE225B3;
    address public ADDRESS_JOLAN = 0x51BdFa2Cbb25591AF58b202aCdcdB33325a325c2;

    uint256 public SHARE_PBOY = 90;
    uint256 public SHARE_JOLAN = 10;

    constructor() {}

    receive() external payable {}

    function setPboy(address PBOY)
    public {
        require(msg.sender == ADDRESS_PBOY, "error msg.sender");
        ADDRESS_PBOY = PBOY;
    }

    function setJolan(address JOLAN)
    public {
        require(msg.sender == ADDRESS_JOLAN, "error msg.sender");
        ADDRESS_JOLAN = JOLAN;
    }

    function withdrawEquity()
    public onlyOwner {
        uint256 balance = address(this).balance;

        address[2] memory shareholders = [
            ADDRESS_PBOY,
            ADDRESS_JOLAN
        ];

        uint256[2] memory _shares = [
            SHARE_PBOY * balance / 100,
            SHARE_JOLAN * balance / 100
        ];

        uint i = 0;
        while (i < 2) {
            require(payable(shareholders[i]).send(_shares[i]));
            i++;
        }
    }
}