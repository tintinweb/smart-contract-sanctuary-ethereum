// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ILenderVerifier {
    function isAllowed(
        address lender,
        uint256 amount,
        bytes memory signature
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IManageable {
    function manager() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IManageable} from "IManageable.sol";

contract Manageable is IManageable {
    address public manager;
    address public pendingManager;

    event ManagementTransferred(address indexed oldManager, address indexed newManager);

    modifier onlyManager() {
        require(manager == msg.sender, "Manageable: Caller is not the manager");
        _;
    }

    constructor(address _manager) {
        _setManager(_manager);
    }

    function transferManagement(address newManager) external onlyManager {
        pendingManager = newManager;
    }

    function claimManagement() external {
        require(pendingManager == msg.sender, "Manageable: Caller is not the pending manager");
        _setManager(pendingManager);
        pendingManager = address(0);
    }

    function _setManager(address newManager) internal {
        address oldManager = manager;
        manager = newManager;
        emit ManagementTransferred(oldManager, newManager);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ILenderVerifier} from "ILenderVerifier.sol";
import {Manageable} from "Manageable.sol";

contract GlobalWhitelistLenderVerifier is Manageable, ILenderVerifier {
    mapping(address => bool) public isWhitelisted;

    constructor() Manageable(msg.sender) {}

    event WhitelistStatusChanged(address user, bool status);

    function isAllowed(
        address user,
        uint256,
        bytes memory
    ) external view returns (bool) {
        return isWhitelisted[user];
    }

    function setWhitelistStatus(address user, bool status) public onlyManager {
        isWhitelisted[user] = status;
        emit WhitelistStatusChanged(user, status);
    }

    function setWhitelistStatusForMany(address[] calldata addressesToWhitelist, bool status) external onlyManager {
        for (uint256 i = 0; i < addressesToWhitelist.length; i++) {
            setWhitelistStatus(addressesToWhitelist[i], status);
        }
    }
}