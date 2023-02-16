// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library CampaignLib {
    enum permission {
        PROCESSING,
        ACCEPTED,
        REJECTED
    }

    enum vote {
        ACCEPT,
        REJECT
    }
}