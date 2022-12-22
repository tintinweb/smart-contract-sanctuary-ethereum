// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";

error NotEnoughValue();
error PreLaunchIsDone();

contract EVMthroughCTFsPreLaunch is Ownable {
    mapping(address => bool) public evmWizards;
    uint256 public price = 0.025 ether;
    bool public isPreLaunchDone = false;

    constructor() Ownable() {}

    function becomeEvmWizard() external payable {
        if (msg.value < price) revert NotEnoughValue();
        if (isPreLaunchDone) revert PreLaunchIsDone();
        evmWizards[msg.sender] = true;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setPreLaunchDone() external onlyOwner {
        isPreLaunchDone = true;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error CallerIsNotTheOwner();

contract Ownable {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (owner != msg.sender) revert CallerIsNotTheOwner();
        _;
    }

    function transferOwnership(address _owner) external onlyOwner {
        owner = _owner;
    }
}