//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IStaking.sol";

contract UnimoonMulticall {
    address public immutable TREASURY;
    address public immutable STAKING;

    constructor(address _treasury, address _staking) {
        require(
            _treasury != address(0) && _staking != address(0),
            "UnimoonMulticall: wrong input"
        );
        TREASURY = _treasury;
        STAKING = _staking;
    }

    /** @dev Function to get rewards array from current pool
     * @param user address
     * @param pid pool id
     * @return an array of rewards
     */
    function getRewards(address user, uint8 pid)
        external
        view
        returns (uint256[] memory)
    {
        uint256 stakeLen = (IStaking(STAKING).getUserStakes(user, pid)).length;
        uint256[] memory array = new uint256[](stakeLen);
        for (uint256 i; i < stakeLen; i++) {
            array[i] = IStaking(STAKING).pendingRewardPerDeposit(user, pid, i);
        }
        return array;
    }

    /** @dev Function to create many sells and purchases in one txn
     * @param data an array of calls' data
     */
    function multicall(bytes[] calldata data)
        external
        returns (uint256[] memory output)
    {
        require(data.length > 0, "UnimoonMulticall: wrong length");
        uint256 counter;
        output = new uint256[](data.length);
        for (uint256 i; i < data.length; i++) {
            (bool success, bytes memory outputData) = TREASURY.call(
                abi.encodePacked(data[i], msg.sender)
            );
            if (success) {
                output[i] = uint256(bytes32(outputData));
                counter++;
            }
        }
        require(counter > 0, "UnimoonMulticall: all calls failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IStaking {
    struct Data {
        uint256 value;
        uint64 lockedFrom;
        uint64 lockedUntil;
        uint256 weight;
        uint256 lastAccValue;
        uint256 pendingYield;
    }

    function increaseRewardPool(uint256 amount) external;

    function getAllocAndWeight() external view returns (uint256, uint256);

    function pendingRewardPerDeposit(
        address user,
        uint8 pid,
        uint256 stakeId
    ) external view returns (uint256);

    function getUserStakes(address user, uint256 pid)
        external
        view
        returns (Data[] memory);
}