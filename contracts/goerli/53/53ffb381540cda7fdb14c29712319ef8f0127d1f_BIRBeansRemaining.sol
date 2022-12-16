/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title An on-chain representation of the remaining Beans that can be minted for Immunefi bug bounties. 
 * The owner of this contract is the BIC Multisig.
 * More info can be seen here: https://docs.bean.money/almanac/governance/beanstalk/bic-process 
 * @dev
 */
contract BIRBeansRemaining {
    address private owner;
    uint256 private remainingBeans;

    // Events for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    event BeansRemainingDecreased(uint256 indexed numBeans);

    event BeansRemainingIncreased(uint256 indexed numBeans);

    // Modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor(uint256 initialBeansRemaining) {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        remainingBeans = initialBeansRemaining;
        emit OwnerSet(address(0), owner);
    }

    // Decreases the number of remaining Beans that can be minted for Immunefi bug bounties.
    // This should only decrease after a BIR unless the DAO votes to decrease the remaining Beans.
    function decreaseRemainingBeans(uint256 numBeans) external isOwner {
        remainingBeans -= numBeans;
    }


    // Increases the number of remaining Beans that can be minted for Immunefi bug bounties.
    // This can only increase via BIP.
    function increaseRemainingBeans(uint256 numBeans) external isOwner {
        remainingBeans += numBeans;
    }

    // Returns the number of remaining Beans that can be minted for Immunefi bug bounties.
    function getBeansRemaining() external view returns (uint256) {
        return remainingBeans;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) external isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
}