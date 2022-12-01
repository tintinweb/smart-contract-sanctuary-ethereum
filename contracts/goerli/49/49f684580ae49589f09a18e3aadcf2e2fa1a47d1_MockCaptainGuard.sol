// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Actions open during the Crowdfund phase
interface ICaptainGuard {
    // When msg.sender is not a captain
    error NotCaptain();

    /// @notice Assign a new captain
    /// @param captain The new address to assign as captain
    function updateCaptain(address captain) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Actions open during the Crowdfund phase
interface ICaptainGuardEvents {
    // When new captain assigned
    event CaptainAssigned(
        address initiator,
        address indexed avatar,
        address indexed captain
    );
}

pragma solidity ^0.8.13;
import "szns/interfaces/zodiac/guards/ICaptainGuard.sol";
import "szns/interfaces/zodiac/guards/ICaptainGuardEvents.sol";

contract MockCaptainGuard is ICaptainGuard, ICaptainGuardEvents {
    function updateCaptain(address captain) external {
        emit CaptainAssigned(msg.sender, address(this), captain);
    }
}