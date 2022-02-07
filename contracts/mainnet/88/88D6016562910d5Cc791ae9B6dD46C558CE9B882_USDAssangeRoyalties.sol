// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./Ownable.sol";

contract USDAssangeRoyalties is Ownable {
    address public ADDRESS_CHARITY = 0x27a21F51327F19668799E403d667187cc5A7DFF1;
    address public ADDRESS_PBOY = 0x709e17B3Ec505F80eAb064d0F2A71c743cE225B3;
    address public ADDRESS_JOLAN = 0x51BdFa2Cbb25591AF58b202aCdcdB33325a325c2;

    uint256[2] public SHARE_CHARITY = [90, 30];
    uint256[2] public SHARE_PBOY = [8, 55];
    uint256[2] public SHARE_JOLAN = [2, 15];

    uint256 public SHARE_TYPE = 0;

    constructor() {}

    receive() external payable {}

    function setShareType()
    public onlyOwner {
        SHARE_TYPE = SHARE_TYPE == 0 ? 1 : 0;
    }

    function setCharity(address CHARITY)
    public onlyOwner {
        ADDRESS_CHARITY = CHARITY;
    }

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

        address[3] memory shareholders = [
            ADDRESS_CHARITY,
            ADDRESS_PBOY,
            ADDRESS_JOLAN
        ];

        uint256[3] memory _shares = [
            SHARE_CHARITY[SHARE_TYPE] * balance / 100,
            SHARE_PBOY[SHARE_TYPE] * balance / 100,
            SHARE_JOLAN[SHARE_TYPE] * balance / 100
        ];

        uint i = 0;
        while (i < 3) {
            require(payable(shareholders[i]).send(_shares[i]));
            i++;
        }
    }
}