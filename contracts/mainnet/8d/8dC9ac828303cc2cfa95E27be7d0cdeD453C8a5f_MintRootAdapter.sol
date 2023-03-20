// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IMint.sol";
import "../RootAdapter.sol";

contract MintRootAdapter is RootAdapter, IMint {
    function mintTokens(
        uint16 executionChainId_,
        string calldata token_,
        uint256 amount_,
        string calldata recipient_,
        uint256 gaslessClaimReward_,
        string calldata referrer_,
        uint256 referrerFee_
    ) external override whenInitialized whenNotPaused whenAllowed(msg.sender) {
        IMint(adapters[executionChainId_]).mintTokens(
            executionChainId_,
            token_,
            amount_,
            recipient_,
            gaslessClaimReward_,
            referrer_,
            referrerFee_
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IMint {
    function mintTokens(
        uint16 executionChainId_,
        string calldata token_,
        uint256 amount_,
        string calldata recipient_,
        uint256 gaslessClaimReward_,
        string calldata referrer_,
        uint256 referrerFee_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Initializable.sol";
import "../AllowedList.sol";
import "../Pausable.sol";

contract RootAdapter is AllowedList, Initializable, Pausable {
    mapping(uint16 => address) public adapters;

    function init(address admin_) external whenNotInitialized {
        require(admin_ != address(0), "zero address");
        admin = admin_;
        pauser = admin_;
        isInited = true;
    }

    function setAdapter(
        uint16 executionChainId_,
        address adapter_
    ) external onlyAdmin {
        adapters[executionChainId_] = adapter_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Initializable {
    bool internal isInited;

    modifier whenInitialized() {
        require(isInited, "not initialized");
        _;
    }

    modifier whenNotInitialized() {
        require(!isInited, "already initialized");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Adminable.sol";

abstract contract AllowedList is Adminable {
    mapping(address => bool) public allowance;

    function allow(address caller_) external onlyAdmin {
        allowance[caller_] = true;
    }

    function disallow(address caller_) external onlyAdmin {
        allowance[caller_] = false;
    }

    modifier whenAllowed(address member) {
        require(allowance[member], "not allowed");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Adminable.sol";

abstract contract Pausable is Adminable {
    event Paused(address account);
    event Unpaused(address account);
    event PauserUpdated(address sender, address oldPauser, address pauser);

    bool public isPaused;
    address public pauser;

    constructor() {
        isPaused = false;
    }

    modifier whenNotPaused() {
        require(!isPaused, "paused");
        _;
    }

    modifier whenPaused() {
        require(isPaused, "not paused");
        _;
    }

    modifier onlyPauser() {
        require(pauser == msg.sender, "only pauser");
        _;
    }

    function pause() external whenNotPaused onlyPauser {
        isPaused = true;
        emit Paused(msg.sender);
    }

    function unpause() external whenPaused onlyPauser {
        isPaused = false;
        emit Unpaused(msg.sender);
    }

    function updatePauser(address pauser_) external onlyAdmin {
        require(pauser_ != address(0), "zero address");
        emit PauserUpdated(msg.sender, pauser, pauser_);
        pauser = pauser_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Adminable {
    event AdminUpdated(address sender, address oldAdmin, address admin);

    address public admin;

    modifier onlyAdmin() {
        require(admin == msg.sender, "only admin");
        _;
    }

    function updateAdmin(address admin_) external onlyAdmin {
        require(admin_ != address(0), "zero address");
        emit AdminUpdated(msg.sender, admin, admin_);
        admin = admin_;
    }
}