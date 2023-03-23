// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../../utils.sol";
import "../caller/IWavesCaller.sol";
import "../Adapter.sol";
import "./IMint.sol";

contract WavesMintAdapter is Adapter, IMint {
    IWavesCaller public protocolCaller;
    string public executionContract;

    function init(
        address admin_,
        address protocolCaller_,
        address rootAdapter_,
        string calldata executionContract_
    ) external whenNotInitialized {
        require(admin_ != address(0), "zero address");
        require(protocolCaller_ != address(0), "zero address");
        require(rootAdapter_ != address(0), "zero address");
        admin = admin_;
        pauser = admin_;
        protocolCaller = IWavesCaller(protocolCaller_);
        rootAdapter = rootAdapter_;
        executionContract = executionContract_;
        isInited = true;
    }

    function mintTokens(
        uint16 executionChainId_,
        string calldata token_,
        uint256 amount_,
        string calldata recipient_,
        uint256 gaslessReward_,
        string calldata referrer_,
        uint256 referrerFee_
    ) external override whenInitialized whenNotPaused onlyRootAdapter {
        string[] memory args = new string[](7);
        args[0] = ""; // require empty string (see WavesCaller CIP)
        args[1] = token_;
        args[2] = Utils.U256ToHex(amount_);
        args[3] = recipient_;
        args[4] = Utils.U256ToHex(gaslessReward_);
        args[5] = referrer_;
        args[6] = Utils.U256ToHex(referrerFee_);
        protocolCaller.call(
            executionChainId_,
            executionContract,
            "mintTokens",
            args
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library Utils {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    // slither-disable-start naming-convention
    function U256ToHex(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _HEX_SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }
    // slither-disable-end naming-convention

    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IWavesCaller {
    function call(
        uint16 executionChainId_,
        string calldata executionContract_,
        string calldata functionName_,
        string[] calldata args_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Pausable.sol";
import "../Initializable.sol";
import "../AllowedList.sol";

abstract contract Adapter is Initializable, Pausable {
    address public rootAdapter;

    event RootAdapterUpdated(address old_adapter, address new_adapter);

    function setRootAdapter(address rootAdapter_) external onlyAdmin {
        require(rootAdapter_ != address(0), "zero address");
        emit RootAdapterUpdated(rootAdapter, rootAdapter_);
        rootAdapter = rootAdapter_;
    }

    modifier onlyRootAdapter() {
        require(msg.sender == rootAdapter, "only root adapter");
        _;
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