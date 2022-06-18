// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error EtherCoffee__ValueMustBeAboveZero();
error EtherCoffee__NoProceeds();

contract EtherCoffee {
    mapping(address => uint256) private s_proceeds;

    event CoffeeBought(
        address indexed sender,
        uint256 indexed amount,
        uint256 indexed timestamp,
        string name,
        string message
    );

    function buyCoffee(
        address _user,
        string memory _name,
        string memory _message
    ) public payable {
        if (msg.value <= 0) {
            revert EtherCoffee__ValueMustBeAboveZero();
        }
        // Could just send the money...
        // https://fravoll.github.io/solidity-patterns/pull_over_push.html
        s_proceeds[_user] += msg.value;
        emit CoffeeBought(msg.sender, msg.value, block.timestamp, _name, _message);
    }

    function withdrawProceeds() external {
        uint256 proceeds = s_proceeds[msg.sender];
        if (proceeds <= 0) {
            revert EtherCoffee__NoProceeds();
        }
        s_proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        require(success, "Transfer failed");
    }

    function getProceeds(address user) external view returns (uint256) {
        return s_proceeds[user];
    }
}