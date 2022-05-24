/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/// @notice Kali DAO share manager interface
interface IKaliShareManager {
    function mintShares(address to, uint256 amount) external payable;

    function burnShares(address from, uint256 amount) external payable;
}

/// @notice Gas optimized reentrancy protection for smart contracts
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// License-Identifier: AGPL-3.0-only
abstract contract ReentrancyGuard {
    error Reentrancy();
    
    uint256 private locked = 1;

    modifier nonReentrant() {
        if (locked != 1) revert Reentrancy();
        
        locked = 2;
        _;
        locked = 1;
    }
}

/// @notice Kali DAO share manager extension
contract KaliShareManager is ReentrancyGuard {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event ExtensionSet(
        address indexed dao,
        address[] managers,
        bool[] approvals
    );
    event ExtensionCalled(
        address indexed dao,
        address indexed manager,
        bytes[] updates
    );

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error NoArrayParity();
    error Forbidden();

    /// -----------------------------------------------------------------------
    /// Mgmt Storage
    /// -----------------------------------------------------------------------

    mapping(address => mapping(address => bool)) public management;

    /// -----------------------------------------------------------------------
    /// Mgmt Settings
    /// -----------------------------------------------------------------------

    function setExtension(bytes calldata extensionData) external {
        (address[] memory managers, bool[] memory approvals) = abi.decode(
            extensionData,
            (address[], bool[])
        );

        if (managers.length != approvals.length) revert NoArrayParity();

        for (uint256 i; i < managers.length; ) {
            management[msg.sender][managers[i]] = approvals[i];
            // cannot realistically overflow
            unchecked {
                ++i;
            }
        }

        emit ExtensionSet(msg.sender, managers, approvals);
    }

    /// -----------------------------------------------------------------------
    /// Mgmt Logic
    /// -----------------------------------------------------------------------

    function callExtension(address dao, bytes[] calldata extensionData)
        external
        nonReentrant
    {
        if (!management[dao][msg.sender]) revert Forbidden();

        for (uint256 i; i < extensionData.length; ) {
            (
                address account,
                uint256 amount,
                bool mint
            ) = abi.decode(extensionData[i], (address, uint256, bool));

            if (mint) {
                IKaliShareManager(dao).mintShares(
                    account,
                    amount
                );
            } else {
                IKaliShareManager(dao).burnShares(
                    account,
                    amount
                );
            }
            // cannot realistically overflow
            unchecked {
                ++i;
            }
        }

        emit ExtensionCalled(dao, msg.sender, extensionData);
    }
}