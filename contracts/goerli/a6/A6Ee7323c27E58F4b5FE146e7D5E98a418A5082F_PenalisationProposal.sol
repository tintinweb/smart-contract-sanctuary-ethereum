// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { IStakingRewards } from "@interfaces/IStakingRewards.sol";
import { IRelayerRegistry } from "@interfaces/IRelayerRegistry.sol";

contract PenalisationProposal {
    address constant _registryAddress = 0x58E8dCC13BE9780fC42E8723D8EaD4CF46943dF2;
    address constant _stakingAddress = 0x5B3f656C80E8ddb9ec01Dd9018815576E9238c29;

    function getCheatingRelayersBalanceSum(address[7] memory cheatingRelayers) public returns (uint256) {
        uint256 balanceSum;
        for (uint8 i = 0; i < cheatingRelayers.length; i++) {
            balanceSum += IRelayerRegistry(_registryAddress).getRelayerBalance(cheatingRelayers[i]);
        }

        return balanceSum;
    }

    function nullifyRelayersBalance(address[7] memory cheatingRelayers) internal {
        IRelayerRegistry relayerRegistry = IRelayerRegistry(_registryAddress);

        for (uint8 i = 0; i < cheatingRelayers.length; i++) {
            relayerRegistry.nullifyBalance(cheatingRelayers[i]);
        }
    }

    function executeProposal() public {
        address[7] memory cheatingRelayers = [
            0x5007565e69E5c23C278c2e976beff38eF4D27B3d, // official-tornado.eth
            0x065f2A0eF62878e8951af3c387E4ddC944f1B8F4, // 0xtorn365.eth
            0x18F516dD6D5F46b2875Fd822B994081274be2a8b, // torn69.eth
            0x30F96AEF199B399B722F8819c9b0723016CEAe6C, // moon-relayer.eth
            0xa42303EE9B2eC1DB7E2a86Ed6C24AF7E49E9e8B9, // relayer-tornado.eth
            0x2ffAc4D796261ba8964d859867592B952b9FC158, // safe-tornado.eth
            0xCEdac436cEA98E93F471331eCC693fF41D730921 // relayer-secure.eth
        ];

        uint256 nullifiedTotalAmount = getCheatingRelayersBalanceSum(cheatingRelayers);

        nullifyRelayersBalance(cheatingRelayers);

        IStakingRewards(_stakingAddress).withdrawTorn(nullifiedTotalAmount);

        // Burn compensation from cheating relayer abracadabra-money-gone.eth - 67.8 TORN
        // https://etherscan.io/tx/0xdb15a8bbb808cdbe88883fcc99d5aeab84ae544cdb51c2b5acdd8e9489c0e418
        IStakingRewards(_stakingAddress).addBurnRewards(678 * 1e17);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IStakingRewards {
    function withdrawTorn(uint256 amount) external;

    function addBurnRewards(uint256 amount) external;

    function checkReward(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IRelayerRegistry {
    function getRelayerBalance(address relayer) external returns (uint256);

    function nullifyBalance(address relayer) external;
}