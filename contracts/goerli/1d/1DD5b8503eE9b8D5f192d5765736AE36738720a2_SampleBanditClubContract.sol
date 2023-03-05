// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IBanditClub {
    // ------------------ External Functions ------------------------
    // Subscribe and start paying fees to Bandit Club
    function subscribe(address subscriber, uint256 feesPaid) external;

    // Add a contract to the registry
    function registerContract(address cntrct, address owner) external;

    // As a deployer of a Bandit Club contract, you can claim fees
    function claimSubscriptionFees(address cntrct) external;

    // When calling a function, check to make sure a user is subscribed
    // and they have enough points left
    function checkUserCall(address user, address cntrct) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "../IBanditClub.sol";

contract SampleBanditClubContract {
    IBanditClub banditClub;

    constructor(address BanditClub) {
        banditClub = IBanditClub(BanditClub);
    }

    // You would need to add the checkUser modifier to every functon and inherit the BanditClub contract
    function doSomething() public checkUser(msg.sender) {}

    // Just syntactic sugar to use a modifier instead of an internal function
    modifier checkUser(address user) {
        banditClub.checkUserCall(user, address(this));
        _;
    }
}