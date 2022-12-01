// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Actions for revenue claims
interface IClaimActions {
    /// @notice Get the amount claimable at an event
    /// @param account The address to get claim amount
    /// @param claimID The claim event ID to claim revenue
    /// @return The amount claimed
    function getClaimAmount(
        address account,
        uint256 claimID
    ) external view returns (uint256);

    /// @notice Check if an address has claims at an event
    /// @param account The address to check
    /// @param claimID The claim event ID to check for claim revenue
    /// @return True of address has claim
    function hasClaim(
        address account,
        uint256 claimID
    ) external view returns (bool);

    /// @notice Claim revenue at for a particular event
    /// @param claimID The claim event ID to claim revenue
    /// @return The amount claimed
    function claim(uint256 claimID) external payable returns (uint256);

    // Make this receive eth
    receive() external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Actions that the ship can take
interface IClaimEvents {
    // When a user claims their share
    event Claimed(address account, uint256 amount, uint256 claimID);

    // Wben a new claim is available
    event Claimable(uint256 amount, uint256 claimID);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Actions open during the Crowdfund phase
interface ICrowdfundActions {
    /// @notice Contribute ETH for ship tokens
    /// @return minted The amount of ship tokens minted
    function contribute() external payable returns (uint256 minted);

    /// @notice Check if raise met
    /// @return True if raise was met
    function hasRaiseMet() external view returns (bool);

    /// @notice Check users can still contribute
    /// @return True if closed
    function isRaiseOpen() external view returns (bool);

    /// @notice End the ship raise
    function endRaise() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Events for crowdfund phase
interface ICrowdfundEvents {
    /// @notice When the minimum raise is met
    event RaiseMet();

    /// @notice When the captain or authorized 3rd party (eg: SZNS DAO) closes the ship before the pool duration
    event ForceEndRaise();

    /// @notice When the minimum raise is met
    /// @param contributor Address that contributed
    /// @param amount Amount contributed
    event Contributed(address indexed contributor, uint256 amount);
}

pragma solidity ^0.8.13;
import "szns/interfaces/claim/IClaimEvents.sol";
import "szns/interfaces/claim/IClaimActions.sol";
import "szns/interfaces/crowdfund/ICrowdfundEvents.sol";
import "szns/interfaces/crowdfund/ICrowdfundActions.sol";

contract MockShipModifier is
    IClaimEvents,
    IClaimActions,
    ICrowdfundEvents,
    ICrowdfundActions
{
    function getClaimAmount(address account, uint256 claimID)
        external
        view
        returns (uint256)
    {
        return 1000000000000000000; // return .1 as example
    }

    function hasClaim(address account, uint256 claimID)
        external
        view
        returns (bool)
    {
        return true;
    }

    function claim(uint256 claimID) external payable returns (uint256) {
        emit Claimed(msg.sender, 1000000000000000000, claimID);
        return 1000000000000000000;
    }

    // This is just for test purposes
    function makeClaimed(
        address account,
        uint256 amount,
        uint256 claimID
    ) external {
        emit Claimed(account, amount, claimID);
    }

    function makeClaimable(uint256 amount, uint256 claimID) external {
        emit Claimable(amount, claimID);
    }

    // send eth as value, returns 1000000000000000000000 (1000) for now
    function contribute() external payable returns (uint256 minted) {
        // assumes you always contribute 1 eth for now
        emit Contributed(msg.sender, 1000000000000000000);
        return 1000000000000000000000;
    }

    function hasRaiseMet() external view returns (bool) {
        return false;
    }

    function isRaiseOpen() external view returns (bool) {
        return true;
    }

    function endRaise() external {
        emit ForceEndRaise();
    }

    receive() external payable {}
}