// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8;

contract BondingRegister {
    event VouchForSolver(
        address solver,
        address bondingPool,
        address cowRewardTarget,
        address txSender
    );
    event Unvouch(address solver, address bondingPool, address txSender);

    constructor() {}

    /// @dev Allows a bonding pool to officially vouche for a new solver
    /// Anyone can call this function, but only the events with txSenders that created sufficiently funded
    /// bonding pools will be officially indexed
    /// @param solver The solver for whom the bonding pool will cover potential losses/penalities
    /// @param bondingPool Address of the bonding pool, from which a potential loss will be covered
    /// @param cowRewardTarget Address to which the solver rewards should be send for the particular solver
    function startBonding(
        address[] calldata solver,
        address[] calldata bondingPool,
        address[] calldata cowRewardTarget
    ) public {
        for (uint256 i = 0; i < solver.length; i++) {
            emit VouchForSolver(
                solver[i],
                bondingPool[i],
                cowRewardTarget[i],
                msg.sender
            );
        }
    }

    /// @dev Stops the vouching for a solver by a bonding pool
    /// Anyone can call this function, but only the events with txSenders that created sufficiently funded
    /// bonding pools will be officially indexed
    /// @param solver The solver for whom the bonding pool will no longer cover any posts
    /// @param bondingPool Address of the official bonding pool, from which a potential loss will be covered
    function stopBonding(
        address[] calldata solver,
        address[] calldata bondingPool
    ) public {
        for (uint256 i = 0; i < solver.length; i++) {
            emit Unvouch(solver[i], bondingPool[i], msg.sender);
        }
    }
}