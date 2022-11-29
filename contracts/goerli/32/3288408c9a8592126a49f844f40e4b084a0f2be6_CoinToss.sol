// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./VRFV2WrapperConsumerBase.sol";
   /*
      * Cointoss (A chance to double or lose your money in a random bet)
      * Randomness is implemented using chainlink-VRF.
      
      ### How to play ###
      * Call bet() and pass the amount to bet in msg.value and get request id (Set gas limit > 310,000)
      * Call checkTossStatus to see your bet's status and wait for it to be fulfilled
      * Once fulfilled you can see you won or lost incase of winning your must recieve the double the betted amount

      * More on using chainlink vrf https://docs.chain.link/vrf/v2/direct-funding/examples/get-a-random-number
    
   */


contract CoinToss is VRFV2WrapperConsumerBase {
    address constant linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address constant vrfWrapper = 0x708701a1DfF4f478de54383E49a627eD4852C816;
    uint32 callbackGasLimit = 1_000_000;
    uint16 requestConfirmations = 3;
    uint32 randomWordsCount = 1;

    struct TossStatus {
        uint256 paid; // amount paid in link
        bool fulfilled;
        uint256 randomWord;
        address player;
        bool playerWon;
        uint256 amount;
    }

    event CoinTossRequest(uint256 requestId);
    event CoinTossFulfilled(uint256 requestId, bool playerWon);

    mapping(uint256 => TossStatus) public statuses;

    // Payable constructor to fund initally
    constructor()
        payable
        VRFV2WrapperConsumerBase(linkAddress, vrfWrapper)
    {}

    function bet() external payable returns (uint256) {
        require(msg.value > 0 , "Bet amount should be greater than 0");
        // We multiply this by 2 to make this fair and consistent such that contract is always in position to double users fund incase contract loses. 
        require(msg.value * 2  < address(this).balance, "Bet amount is greater than treasury's balance");

        uint256 requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            randomWordsCount
        );

        statuses[requestId] = TossStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            fulfilled: false,
            randomWord: 0,
            player: msg.sender,
            playerWon: false,
            amount: msg.value
        });
        emit CoinTossRequest(requestId);
        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        require(statuses[requestId].paid > 0, "request not found");
        statuses[requestId].fulfilled = true;
        statuses[requestId].randomWord = (randomWords[0] % 1000) + 1;

        if (statuses[requestId].randomWord <= 499) {
            statuses[requestId].playerWon = true;
            // Solidity v0.8^ breaking change to get payable address
            payable(statuses[requestId].player).transfer(
                statuses[requestId].amount * 2
            );
        }
        emit CoinTossFulfilled(requestId, statuses[requestId].playerWon);
    }

    function checkTossStatus(uint256 requestId)
        external
        view
        returns (TossStatus memory)
    {
        require(statuses[requestId].paid > 0, "request not found");
        return (statuses[requestId]);
    }
}