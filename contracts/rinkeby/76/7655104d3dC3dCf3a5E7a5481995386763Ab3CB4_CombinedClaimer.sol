// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./GlobalClaimer.sol";

contract CombinedClaimer {
    function depositedTokenIds(GlobalClaimer stakingAddress, address depositer)
        public
        view
        returns (uint256[] memory)
    {
        return stakingAddress.depositsOf(depositer);
    }

    function claimableReward(
        GlobalClaimer stakingAddress,
        address depositer,
        uint256[] memory tokenIds
    ) public view returns (uint256) {
        uint256 reward;
        for (uint256 i; i < tokenIds.length; i++) {
            reward += stakingAddress.calculateReward(depositer, tokenIds[i]);
        }

        return reward;
    }

    function claimReward(
        GlobalClaimer squisyApesStakingAddress,
        GlobalClaimer jingleDogeStakingAddress
    ) public {
        uint256[] memory squishyStakedTokenIds = depositedTokenIds(
            squisyApesStakingAddress,
            msg.sender
        );

        uint256[] memory jingleDogeStakedTokenIds = depositedTokenIds(
            jingleDogeStakingAddress,
            msg.sender
        );

        squisyApesStakingAddress.claimAll(
            msg.sender,
            squishyStakedTokenIds,
            claimableReward(
                squisyApesStakingAddress,
                msg.sender,
                squishyStakedTokenIds
            )
        );

        jingleDogeStakingAddress.claimAll(
            msg.sender,
            jingleDogeStakedTokenIds,
            claimableReward(
                jingleDogeStakingAddress,
                msg.sender,
                jingleDogeStakedTokenIds
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface GlobalClaimer {
     function claimAll(
        address tokenOwner,
        uint256[] memory tokenIds,
        uint256 amount
    ) external;

    function depositsOf(address despositer) external view returns (uint256[] memory);

    function calculateReward(address account, uint256 tokenId)
        external
        view
        returns (uint256 reward);
    
}