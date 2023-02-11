// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Twitter {
    event Tweet(address indexed _from, string _msg);

    function tweet(string memory _tweet)
        public
    {
        emit Tweet(msg.sender, _tweet);
    }
}