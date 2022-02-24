/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

/// @notice Gas-optimized reentrancy protection.
/// @author Modified from OpenZeppelin 
/// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
/// License-Identifier: MIT
abstract contract ReentrancyGuard {
    error Reentrancy();

    uint256 private constant NOT_ENTERED = 1;

    uint256 private constant ENTERED = 2;

    uint256 private status = NOT_ENTERED;

    modifier nonReentrant() {
        if (status == ENTERED) revert Reentrancy();

        status = ENTERED;

        _;

        status = NOT_ENTERED;
    }
}

/// @notice Kali DAO share manager interface.
interface IKaliShareManager {
    function mintShares(address to, uint256 amount) external;

    function burnShares(address from, uint256 amount) external;
}

/// @notice Merger contract that burns DAO tokens for another.
contract KaliDAOacquisition is ReentrancyGuard {
    event ExtensionSet(IKaliShareManager indexed dao0, IKaliShareManager indexed dao1, uint8 rate);

    event ExtensionCalled(
        IKaliShareManager indexed dao0, 
        IKaliShareManager indexed dao1, 
        address indexed member, 
        uint256 amountIn, 
        uint256 amountOut
    );

    uint256 private count;

    mapping(uint256 => Terms) public terms;

    struct Terms {
        IKaliShareManager dao0; // dao to burn shares from
        IKaliShareManager dao1; // dao to mint shares from
        uint8 rate; // dao0-1 exchange rate
    }

    function setExtension(bytes calldata extensionData) public nonReentrant virtual {
        (IKaliShareManager dao1, uint8 rate) = abi.decode(extensionData, (IKaliShareManager, uint8));

        terms[count++] = Terms({
            dao0: IKaliShareManager(msg.sender),
            dao1: dao1,
            rate: rate
        });

        emit ExtensionSet(IKaliShareManager(msg.sender), dao1, rate);
    }

    function setExtensionWithParams(IKaliShareManager dao1, uint8 rate) public nonReentrant virtual {
        terms[count++] = Terms({
            dao0: IKaliShareManager(msg.sender),
            dao1: dao1,
            rate: rate
        });

        emit ExtensionSet(IKaliShareManager(msg.sender), dao1, rate);
    }

    function callExtension(uint256 dealId, uint256 amountIn) public nonReentrant virtual returns (uint256 amountOut) {
        Terms storage deal = terms[dealId];

        deal.dao0.burnShares(msg.sender, amountIn);

        amountOut = amountIn * deal.rate;

        deal.dao1.mintShares(msg.sender, amountOut);

        emit ExtensionCalled(IKaliShareManager(msg.sender), deal.dao1, msg.sender, amountIn, amountOut);
    }
}