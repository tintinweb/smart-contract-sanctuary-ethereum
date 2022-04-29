/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// pragma solidity ^0.4.21;

// contract TokenSaleChallenge {
//     mapping(address => uint256) public balanceOf;
//     uint256 constant PRICE_PER_TOKEN = 1;

//     function TokenSaleChallenge(address _player) public {
//         balanceOf[address(this)] += 1;
//     }

//     function isComplete() public view returns (bool) {
//         return balanceOf[address(this)] < 1;
//     }

//     function buy(uint256 numTokens) public payable {
//         balanceOf[msg.sender] += numTokens;
//     }

//     function sell(uint256 numTokens) public {
//         require(balanceOf[msg.sender] >= numTokens);

//         balanceOf[msg.sender] -= numTokens;
//     }
// }

pragma solidity ^0.4.21;

contract TokenSaleChallenge {
    mapping(address => uint8) public balanceOf;
    uint256 constant PRICE_PER_TOKEN = 1 ether;

    function TokenSaleChallenge(address _player) public payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance < 1 ether;
    }

    function buy(uint8 numTokens) public payable {
        require(msg.value == numTokens * PRICE_PER_TOKEN);

        balanceOf[msg.sender] += numTokens;
    }

    function sell(uint8 numTokens) public {
        require(balanceOf[msg.sender] >= numTokens);

        balanceOf[msg.sender] -= numTokens;
        msg.sender.transfer(numTokens * PRICE_PER_TOKEN);
    }
}