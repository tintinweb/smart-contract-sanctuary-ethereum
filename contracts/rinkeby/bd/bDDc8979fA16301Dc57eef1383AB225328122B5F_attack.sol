// SPDX-License-Identifier: CHAINTROOPERS 2022
pragma solidity >=0.6.0 <0.9.0;

interface challenge {
    function buyTokens() external payable;

    function sellTokens(uint256 _amount) external;

    function claimReward() external;

    function setTokensBalance(address _user, uint256 _balance) external;

    function getUserBalance(address _user) external;

    function getBalance() external;
}

contract attack {
    challenge public challengeContract;
    address challengeContractaddress;

    constructor(address _challengeContract) public {
        challengeContractaddress = _challengeContract;
        challengeContract = challenge(_challengeContract);
    }

    // get balance of contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function performattack() external payable {}

    fallback() external payable {}
}