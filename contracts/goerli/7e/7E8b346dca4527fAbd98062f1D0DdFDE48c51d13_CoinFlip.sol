/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract CoinFlip {
    address public owner;
    address internal flipper;
    uint256 internal flipId;
    uint256 internal flipAmount;

    struct Flip {
        uint256 flipId;
        address flipper;
        uint256 flipAmount;
        bool flipResult;
    }

    mapping(uint256 => Flip) public flips;
    mapping(address => uint256) public balances;

    event FlipEvent(
        uint256 flipId,
        address flipper,
        uint256 flipAmount,
        bool flipResult
    );

    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert();
        } else {
            _;
        }
    }

    constructor() {
        owner = msg.sender;
    }

    function userFlip(bool flipResult) external payable {
        require(msg.sender != address(0), "Sender must be valid!");

        if (flipResult) {
            balances[msg.sender] += (msg.value * 2);
            flipId = flipId + 1;
            flips[flipId] = Flip({
                flipId: flipId,
                flipper: msg.sender,
                flipAmount: msg.value,
                flipResult: true
            });

            emit FlipEvent(flipId, msg.sender, flipAmount, flipResult);
        } else {
            balances[msg.sender] = 0;
            flipId = flipId + 1;
            flips[flipId] = Flip({
                flipId: flipId,
                flipper: msg.sender,
                flipAmount: msg.value,
                flipResult: false
            });

            emit FlipEvent(flipId, msg.sender, flipAmount, flipResult);
        }
    }

    function claim() external {
        require((balances[msg.sender]) > 0, "Nothing to claim!");
        payable(msg.sender).transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }

    function withdrawFunds() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    fallback() external payable {}

    receive() external payable {}
}