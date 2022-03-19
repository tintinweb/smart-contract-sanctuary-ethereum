// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOpRewards {
    function claimRewards(address[] calldata xTokens) external;
}

contract Rewards {
    address _OpRewardAddress;

    struct AccountRewards {
        address dsa;
        address[] xToken;
    }
    event PrintDsa(address);

    event PrintxToken(address[]);

    constructor(address OpRewardAddress) {
        _OpRewardAddress = OpRewardAddress;
    }

    function claimRewards(AccountRewards[] calldata accountWithRewards) public {
        for (uint256 i = 0; i < accountWithRewards.length; i++) {
            emit PrintDsa(accountWithRewards[i].dsa);
            emit PrintxToken(accountWithRewards[i].xToken);
            IOpRewards(_OpRewardAddress).claimRewards(accountWithRewards[i].xToken);
        }
    }
}