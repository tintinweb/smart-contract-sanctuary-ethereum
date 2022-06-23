// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IEulDistributor {
    function updateRoot(bytes32 newRoot) external;
}

contract EulDistributorOwner {
    string public constant name = "EUL Distributor Owner";

    address public immutable eulDistributor;
    address public owner;
    address public updater;

    constructor(address eulDistributor_, address owner_, address updater_) {
        eulDistributor = eulDistributor_;
        owner = owner_;
        updater = updater_;
    }

    // Owner-only functions

    modifier onlyOwner {
        require(msg.sender == owner, "unauthorized");
        _;
    }

    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function changeUpdater(address newUpdater) external onlyOwner {
        updater = newUpdater;
    }

    function execute(address destination, uint value, bytes calldata payload) external onlyOwner {
        (bool success,) = destination.call{value: value}(payload);
        require(success, "execute failure");
    }

    // Updater-only functions

    function updateRoot(bytes32 newRoot) external {
        require(msg.sender == updater, "unauthorized");
        IEulDistributor(eulDistributor).updateRoot(newRoot);
    }
}