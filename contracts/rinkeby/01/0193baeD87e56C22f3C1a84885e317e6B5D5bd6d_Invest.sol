// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./VRFConsumerBase.sol";

contract Invest is VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 public randomResult;
    
    constructor() 
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
        ) payable
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }
    
    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in contract");
        return requestRandomness(keyHash, fee);
    }

    event randomRequestIdAndNumber(bytes32, uint256);

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        emit randomRequestIdAndNumber(requestId, randomness); 
        randomResult = randomness % 5 + 8; // get random number between 8~12   
    }
    

    // Game Logic
    event investInfo(address, uint);
    event randomResultInDistribution(uint);
    event distributeInfo(uint, uint, uint);

    function invest() payable public returns(uint fundReturn){
        // investor should invest less than 0.1 ether every time
        require(msg.value == 0.1 ether, "fund is not 0.1 ether"); 
        emit investInfo(msg.sender, msg.value);       
        
        getRandomNumber();    
        emit randomResultInDistribution(randomResult);
        
        // player get 0.8~1.2 fund back
        uint investResult = msg.value * randomResult / 10;
        uint contractBalanceBeforeTransfer = address(this).balance;

        if (contractBalanceBeforeTransfer + msg.value < investResult) {
            revert();
        } else {
            payable(msg.sender).transfer(investResult);
            uint contractBalanceAfterTransfer = address(this).balance;
            emit distributeInfo(contractBalanceBeforeTransfer, contractBalanceAfterTransfer, investResult);
            return investResult;
        }
    }
}