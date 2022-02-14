/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

pragma solidity ^0.8.0;

// comment below so compiler doesn't scream at me, pls ignore :)
// SPDX-License-Identifier: UNLICENSED
contract FireBirdCoin {
    int flagNum;

    mapping (address => uint) firebirdTokenCount;

    event log(string stuff);
    event giveFlag(string flag);

    constructor() {
        emit log("I hear y'all love flag :)\
        Here, you can exchange ether for firebird tokens \
        and use them to get lots of flags!");

        flagNum = 0;
    }

    function getFirebirdTokens() external payable {
        require(msg.value > 0, "Send some ether to get firebird tokens U_U");
        firebirdTokenCount[msg.sender] += (msg.value * 10); // 10 tokens per 1 wei
    }

    function spendFirebirdToken(uint numSpend) external {
        require(firebirdTokenCount[msg.sender] >= numSpend, "Not enough tokens :3");
        require(numSpend > 0, "You can't spend 0 tokens OwO");
        firebirdTokenCount[msg.sender] -= numSpend;

        for(uint i = 0; i < numSpend; i++) {
            string memory flag = string(abi.encodePacked("flag{", flagNum++, "}"));
            emit giveFlag(string(abi.encodePacked("Person at address ", msg.sender, 
            " spent a token to generate this flag: ", flag)));
        }
    }
}