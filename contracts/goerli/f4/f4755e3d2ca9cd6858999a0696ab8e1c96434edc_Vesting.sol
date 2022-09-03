/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title Vesting v1
 * @dev This contract handles the vesting of Eth for a given beneficiary.
 * The vesting schedule is customizable through the {setDuration} function.
 */
contract Vesting {
    event EtherReleased(uint256 amount);

    address public beneficiary;

    uint256 public duration;
    uint256 public start;
    uint256 public released;

    /**
     * @dev Set the start timestamp of the vesting wallet.
     */
    function setStart(uint256 startTimestamp) public {
        require(start == 0, "already set");
        start = startTimestamp;
    }

    /**
     * @dev Set the vesting duration of the vesting wallet.
     */
    function setDuration(uint256 durationSeconds) public {
        require(
            durationSeconds > duration,
            "You cant decrease the vesting time!"
        );

        duration = durationSeconds;
    }

    /**
     * @dev Release the native token (ether) that have already vested.
     *
     * Emits a {EtherReleased} event.
     */
    function release() public virtual {
        uint256 releasable = vestedAmount(block.timestamp) - released;
        released += releasable;
        emit EtherReleased(releasable);
        (bool success, ) = payable(beneficiary).call{value: releasable}("");
        require(success, "tx failed");
    }

    /**
     * @dev Calculates the amount of ether that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(uint256 timestamp)
        public
        view
        virtual
        returns (uint256)
    {
        return _vestingSchedule(address(this).balance + released, timestamp);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(uint256 totalAllocation, uint256 timestamp)
        internal
        view
        virtual
        returns (uint256)
    {
        if (timestamp < start) {
            return 0;
        } else if (timestamp > start + duration) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start)) / duration;
        }
    }
}