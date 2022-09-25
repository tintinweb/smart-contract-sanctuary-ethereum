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

import "./interfaces/ISXTToken.sol";
import "./interfaces/ISXTValidator.sol";

contract SXTValidator is Admin, Initializer, SXTPartner, ISXTValidator {
    uint256 public constant SXT_REQUEST_EXPIRE_TIME = 5 minutes;

    /// @dev SXTApi contract address
    address public sxtApi;

    /// @dev SXTValidator contract nonce
    uint256 public nonce;

    /// @dev SXTRequest data
    mapping(bytes32 => SXTRequest) public requests;

    constructor() {
        admin = msg.sender;
    }

    /**
     * Initialize SXTValidator states
     * @param token SXTToken contract address
     */
    function initialize(address token, address api)
        external
        initializer
        onlyAdmin
    {
        setSXTToken(token);
        setSXTApi(api);
    }

    /**
     * Set SXTToken contract address
     * @param token SXTToken contract address
     */
    function setSXTToken(address token) public onlyAdmin {
        _setSXTToken(token);
    }

    /**
     * Set SXTApi contract address
     * @param api SXTApi contract address
     */
    function setSXTApi(address api) public onlyAdmin {
        sxtApi = api;
        emit SetSXTApi(api);
    }

    /**
     * Register SXT Node addresses
     * @param senders SXT Node addresses
     */
    function setAuthorizedSenders(address[] calldata senders)
        external
        onlyAdmin
    {
        _authorizeSenders(senders);
    }

    /**
     * Remove SXT Node addresses
     * @param senders SXT Node addresses
     */
    function removeAuthorizedSenders(address[] calldata senders)
        external
        onlyAdmin
    {
        _unauthorizeSenders(senders);
    }

    /**
     * Register SXT Request
     * @dev Only SXTApi contract will be able to call this function
     * @param callbackAddress callback contract address
     * @param callbackFunctionSignature callback function signature
     */
    function registerSXTRequest(
        address callbackAddress,
        bytes4 callbackFunctionSignature
    ) external override onlySXTApi returns (SXTRequest memory request) {
        require(
            callbackAddress != address(0),
            "SXTValidator: callback address is invalid"
        );
        require(
            callbackFunctionSignature != bytes32(0),
            "SXTValidator: callback function is invalid"
        );

        nonce++;
        bytes32 requestId = keccak256(abi.encodePacked(this, nonce));
        request.requestId = requestId;
        request.createdAt = (block.timestamp);
        request.expiredAt = (block.timestamp) + (SXT_REQUEST_EXPIRE_TIME);
        request.callbackFunctionSignature = callbackFunctionSignature;
        request.callbackAddress = callbackAddress;

        requests[requestId] = request;
    }

    /**
     * Send Api call response to caller contract
     * @dev Only authorized senders can call this function
     * @param requestId Apicall requestId
     * @param data Apicall response data
     */
    function fulfill(bytes32 requestId, bytes32 data)
        external
        onlyAuthorizedSenders
    {
        SXTRequest storage request = requests[requestId];
        require(
            request.expiredAt >= block.timestamp,
            "SXTValidator: request was expired"
        );
        require(
            !request.isCompleted,
            "SXTValidator: request was already completed"
        );

        (bool success, ) = request.callbackAddress.call(
            abi.encodeWithSelector(
                request.callbackFunctionSignature,
                requestId,
                data
            )
        );
        require(success, "SXTValidator: fulfilling is failed");
        request.isCompleted = true;
        emit SXTResponse(requestId, data);
    }

    modifier onlySXTApi() {
        require(msg.sender == sxtApi, "SXTValidator: only SXTApi can call");
        _;
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISXTToken is IERC20 {
    function mint(address to, uint256 amount) external;
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