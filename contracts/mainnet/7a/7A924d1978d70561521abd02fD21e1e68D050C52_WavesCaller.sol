// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./AllowedList.sol";
import "./Initializable.sol";
import "./Pausable.sol";

abstract contract AbstractCaller is AllowedList, Initializable, Pausable {
    uint16 public chainId;
    uint256 public nonce;
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

import "./AbstractCaller.sol";

contract WavesCaller is AbstractCaller {
    event WavesCallEvent(
        uint16 callerChainId,
        uint16 executionChainId,
        string executionContract,
        string functionName,
        string[] args,
        uint256 nonce
    );

    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function init(address admin_, uint16 chainId_) external whenNotInitialized {
        require(admin_ != address(0), "zero address");
        admin = admin_;
        pauser = admin_;
        chainId = chainId_;
        isInited = true;
    }

    // first argument must be empty (functionArgs_[0] = caller)
    function call(
        uint16 executionChainId_,
        string calldata executionContract_,
        string calldata functionName_,
        string[] memory functionArgs_
    ) external whenInitialized whenAllowed(msg.sender) whenNotPaused {
        string memory caller = toHexString_(msg.sender);
        functionArgs_[0] = caller;
        uint256 nonce_ = nonce;
        emit WavesCallEvent(
            chainId,
            executionChainId_,
            executionContract_,
            functionName_,
            functionArgs_,
            nonce_
        );
        nonce = nonce_ + 1;
    }

    function toHexString_(address addr) internal pure returns (string memory) {
        uint256 value = uint256(uint160(addr));
        bytes memory buffer = new bytes(2 * _ADDRESS_LENGTH + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * _ADDRESS_LENGTH + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "length insufficient");
        return string(buffer);
    }
}