/**
 ________  ________  ________  ________  _______   ________  ________   ________  _________  ___  _____ ______   _______      
|\   ____\|\   __  \|\   __  \|\   ____\|\  ___ \ |\   __  \|\   ___  \|\   ___ \|\___   ___\\  \|\   _ \  _   \|\  ___ \     
\ \  \___|\ \  \|\  \ \  \|\  \ \  \___|\ \   __/|\ \  \|\  \ \  \\ \  \ \  \_|\ \|___ \  \_\ \  \ \  \\\__\ \  \ \   __/|    
 \ \_____  \ \   ____\ \   __  \ \  \    \ \  \_|/_\ \   __  \ \  \\ \  \ \  \ \\ \   \ \  \ \ \  \ \  \\|__| \  \ \  \_|/__  
  \|____|\  \ \  \___|\ \  \ \  \ \  \____\ \  \_|\ \ \  \ \  \ \  \\ \  \ \  \_\\ \   \ \  \ \ \  \ \  \    \ \  \ \  \_|\ \ 
    ____\_\  \ \__\    \ \__\ \__\ \_______\ \_______\ \__\ \__\ \__\\ \__\ \_______\   \ \__\ \ \__\ \__\    \ \__\ \_______\
   |\_________\|__|     \|__|\|__|\|_______|\|_______|\|__|\|__|\|__| \|__|\|_______|    \|__|  \|__|\|__|     \|__|\|_______|
   \|_________|         
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstract/Admin.sol";
import "./abstract/SXTPartner.sol";
import "./abstract/Initializer.sol";

import "./interfaces/ISXTApi.sol";
import "./interfaces/ISXTToken.sol";
import "./interfaces/ISXTValidator.sol";

import "@openzeppelin/contracts/security/Pausable.sol";

contract SXTApi is Admin, Initializer, SXTPartner, Pausable, ISXTApi {
    ISXTValidator public sxtValidator;

    constructor() {
        admin = msg.sender;
    }

    function initialize(address token, address validator)
        external
        initializer
        onlyAdmin
    {
        setSXTToken(token);
        setSXTValidator(validator);
    }

    function setSXTToken(address token) public onlyAdmin {
        _setSXTToken(token);
    }

    function setSXTValidator(address validator) public onlyAdmin {
        sxtValidator = ISXTValidator(validator);
        emit SetSXTValidator(validator);
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function executeQuery(string memory, bytes4 callbackFunctionSignature)
        external
        override
        whenNotPaused
        returns (bytes32)
    {
        ISXTValidator.SXTRequest memory request = sxtValidator
            .registerSXTRequest(msg.sender, callbackFunctionSignature);
        return request.requestId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract Admin {
    address public admin;

    modifier onlyAdmin() {
        require(msg.sender == getAdmin(), "admin only function");
        _;
    }

    function getAdmin() public view returns (address adminAddress) {
        return admin;
    }

    function setAdmin(address adminAddress) public onlyAdmin {
        admin = adminAddress;
    }

    function adminCall(address target, bytes calldata data)
        external
        payable
        onlyAdmin
    {
        assembly {
            calldatacopy(0, data.offset, data.length)
            let result := call(gas(), target, callvalue(), 0, data.length, 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/ISXTToken.sol";
import "../interfaces/ISXTPartner.sol";

abstract contract SXTPartner is ISXTPartner {
    ISXTToken public sxtToken;

    mapping (address => bool) public authorizedSenders;

    function _setSXTToken(address token) internal {
        sxtToken = ISXTToken(token);
        emit SetSXTToken(token);
    }

    function _authorizeSenders(address[] calldata senders) internal {
        address sender;
        uint256 length = senders.length;
        for (uint256 i = 0; i < length; i ++) {
            sender = senders[i];
            authorizedSenders[sender] = true;
            emit AuthorizedSender(sender, true);
        }
    }

    function _unauthorizeSenders(address[] calldata senders) internal {
        address sender;
        uint256 length = senders.length;
        for (uint256 i = 0; i < length; i ++) {
            sender = senders[i];
            authorizedSenders[sender] = false;
            emit AuthorizedSender(sender, false);
        }
    }

    modifier onlyAuthorizedSenders {
        require(authorizedSenders[msg.sender], "SXTPartner: only authorized senders can call");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract Initializer {
    bool private _isInitialized;

    modifier initializer() {
        require(!_isInitialized, "Initializer: already initialized");
        _;
        _isInitialized = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISXTValidator {
    struct SXTRequest {
        bytes32 requestId;
        uint256 createdAt;
        uint256 expiredAt;
        bool isCompleted;
        bytes4 callbackFunctionSignature;
        address callbackAddress;
    }

    function registerSXTRequest(
        address callbackAddress,
        bytes4 callbackFunctionSignature
    ) external returns (SXTRequest memory);

    event SetSXTApi(address indexed sxtApi);

    event SXTResponse(bytes32 requestId, bytes32 data);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISXTApi {
    event SXTRequest(bytes32 requestId, bytes32 data);

    event SetSXTValidator(address indexed validator);

    function setSXTToken(address token) external;

    function executeQuery(
        string memory sqlText,
        bytes4 callbackFunctionSignature
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISXTToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISXTPartner {
    event SetSXTToken(address indexed token);

    event AuthorizedSender(address indexed sender, bool authorized);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}