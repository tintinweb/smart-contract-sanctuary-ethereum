pragma solidity 0.5.4;

import "./external/tenx/interfaces/IModerator.sol";
import "./external/tenx/roles/ModeratorRole.sol";

/**
 * @notice SimplePermissionedModerator
 * @dev Moderator contracts manages transfer restrictions and implements the IModerator interface.
 * Each address has an associated send, and receive permissions that either allows or disallows transfers.
 * Only whitelisted moderator addresses can set permissions.
 *
 * Modified version of PermissionedModerator from Tenx with timelocks and expiration removed
 */
// solhint-disable no-unused-vars
contract SimplePermissionedModerator is IModerator, ModeratorRole {
    bytes1 internal constant STATUS_TRANSFER_FAILURE = 0x50; // Uses status codes from ERC-1066
    bytes1 internal constant STATUS_TRANSFER_SUCCESS = 0x51;

    bytes32 internal constant ALLOWED_APPLICATION_CODE =
        keccak256("org.hydra.allowed");
    bytes32 internal constant FORBIDDEN_APPLICATION_CODE =
        keccak256("org.hydra.forbidden");
        
    bool public transfersEnabled;

    bool public redemptionsEnabled;

    mapping(address => Permission) public permissions; // Address-specific transfer permissions

    struct Permission {
        bool sendAllowed; // default: false
        bool receiveAllowed; // default: false
    }

    event PermissionChanged(
        address indexed investor,
        bool sendAllowed,
        bool receiveAllowed,
        address moderator
    );

    event GlobalTransferabilityChanged(
        bool transfersEnabled
    );
    
    event GlobalRedemptionChanged(
        bool redemptionsEnabled
    );

    /**
     * @notice Sets transfer permissions on a specified address.
     * @param _investor Address
     * @param _sendAllowed Boolean, transfers from this address is allowed if true.
     * @param _receiveAllowed Boolean, transfers to this address is allowed if true.
     */
    function setPermission(
        address _investor,
        bool _sendAllowed,
        bool _receiveAllowed
    ) external onlyModerator {
        require(
            _investor != address(0),
            "Investor must not be a zero address."
        );
        permissions[_investor] = Permission({
            sendAllowed: _sendAllowed,
            receiveAllowed: _receiveAllowed
        });
        emit PermissionChanged(
            _investor,
            _sendAllowed,
            _receiveAllowed,
            msg.sender
        );
    }

    /**
     * @notice Sets transfer permissions globally
     * @dev Individual permissions still needed. Useful for global disable
     * @param _transfersEnabled Boolean
     */
    function setTransfersEnabled(
        bool _transfersEnabled
    ) external onlyModerator {
        transfersEnabled = _transfersEnabled;
        emit GlobalTransferabilityChanged(transfersEnabled);
    }

    /**
     * @notice Sets redemption permissions globally
     * @dev Individual permissions still needed. Useful for global disable
     * @param _redemptionsEnabled Boolean
     */
    function setRedemptionsEnabled(
        bool _redemptionsEnabled
    ) external onlyModerator {
        redemptionsEnabled = _redemptionsEnabled;
        emit GlobalRedemptionChanged(redemptionsEnabled);
    }


    /**
    * @notice Verify if an issue is allowed.
    * @param _tokenHolder address The address tokens are minted to
    * @return {
        "allowed": "Returns true if issue is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }    
    */
    function verifyIssue(
        address _tokenHolder,
        uint256,
        bytes calldata
    )
        external
        view
        returns (
            bool allowed,
            bytes1 statusCode,
            bytes32 applicationCode
        )
    {
        if (canReceive(_tokenHolder)) {
            allowed = true;
            statusCode = STATUS_TRANSFER_SUCCESS;
            applicationCode = ALLOWED_APPLICATION_CODE;
        } else {
            allowed = false;
            statusCode = STATUS_TRANSFER_FAILURE;
            applicationCode = FORBIDDEN_APPLICATION_CODE;
        }
    }

    /**
    * @notice Verify if a transfer is allowed.
    * @param _from address The address tokens are transferred from
    * @param _to address The address tokens are transferred to
    * @dev Allowed if sender can send, receiver can receive, transfers enabled
    * @return {
        "allowed": "Returns true if transfer is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }
    */
    function verifyTransfer(
        address _from,
        address _to,
        uint256,
        bytes calldata
    )
        external
        view
        returns (
            bool allowed,
            bytes1 statusCode,
            bytes32 applicationCode
        )
    {
        if (canSend(_from) && canReceive(_to) && transfersEnabled) {
            allowed = true;
            statusCode = STATUS_TRANSFER_SUCCESS;
            applicationCode = ALLOWED_APPLICATION_CODE;
        } else {
            allowed = false;
            statusCode = STATUS_TRANSFER_FAILURE;
            applicationCode = FORBIDDEN_APPLICATION_CODE;
        }
    }

    /**
    * @notice Verify if a transferFrom is allowed.
    * @param _from address The address tokens are transferred from
    * @param _to address The address tokens are transferred to
    * @param _sender address The address calling the transferFrom method
    * @dev Allowed if sender can send, token holder can send, receiver can receive, transfers enabled
    * @return {
        "allowed": "Returns true if transferFrom is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }
    */
    function verifyTransferFrom(
        address _from,
        address _to,
        address _sender,
        uint256,
        bytes calldata
    )
        external
        view
        returns (
            bool allowed,
            bytes1 statusCode,
            bytes32 applicationCode
        )
    {
        if (canSend(_from) && canSend(_sender) && canReceive(_to) && transfersEnabled) {
            allowed = true;
            statusCode = STATUS_TRANSFER_SUCCESS;
            applicationCode = ALLOWED_APPLICATION_CODE;
        } else {
            allowed = false;
            statusCode = STATUS_TRANSFER_FAILURE;
            applicationCode = FORBIDDEN_APPLICATION_CODE;
        }
    }

    /**
    * @notice Verify if a redeem is allowed.
    * @dev Allowed if sender can send, redemptions enabled
    * @return {
        "allowed": "Returns true if redeem is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }
    */
    function verifyRedeem(
        address _sender,
        uint256,
        bytes calldata
    )
        external
        view
        returns (
            bool allowed,
            bytes1 statusCode,
            bytes32 applicationCode
        )
    {
        if (canSend(_sender) && redemptionsEnabled) {
            allowed = true;
            statusCode = STATUS_TRANSFER_SUCCESS;
            applicationCode = ALLOWED_APPLICATION_CODE;
        } else {
            allowed = false;
            statusCode = STATUS_TRANSFER_FAILURE;
            applicationCode = FORBIDDEN_APPLICATION_CODE;
        }
    }

    /**
    * @notice Verify if a redeemFrom is allowed.
    * @dev Allowed if sender can send, token holder can send, redemptions enabled
    * @return {
        "allowed": "Returns true if redeem is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }
    */
    function verifyRedeemFrom(
        address _sender,
        address _tokenHolder,
        uint256,
        bytes calldata
    )
        external
        view
        returns (
            bool allowed,
            bytes1 statusCode,
            bytes32 applicationCode
        )
    {
        if (canSend(_sender) && canSend(_tokenHolder) && redemptionsEnabled) {
            allowed = true;
            statusCode = STATUS_TRANSFER_SUCCESS;
            applicationCode = ALLOWED_APPLICATION_CODE;
        } else {
            allowed = false;
            statusCode = STATUS_TRANSFER_FAILURE;
            applicationCode = FORBIDDEN_APPLICATION_CODE;
        }
    }

    /**
    * @notice Verify if a controllerTransfer is allowed.
    * @dev All controllerTransfers are allowed by this basic moderator contract
    * @return {
        "allowed": "Returns true if transfer is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }    
    */
    function verifyControllerTransfer(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    )
        external
        view
        returns (
            bool allowed,
            bytes1 statusCode,
            bytes32 applicationCode
        )
    {
        allowed = true;
        statusCode = STATUS_TRANSFER_SUCCESS;
        applicationCode = ALLOWED_APPLICATION_CODE;
    }

    /**
    * @notice Verify if a controllerRedeem is allowed.
    * @dev All controllerRedeems are allowed by this basic moderator contract
    * @return {
        "allowed": "Returns true if transfer is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }    
    */
    function verifyControllerRedeem(
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    )
        external
        view
        returns (
            bool allowed,
            bytes1 statusCode,
            bytes32 applicationCode
        )
    {
        allowed = true;
        statusCode = STATUS_TRANSFER_SUCCESS;
        applicationCode = ALLOWED_APPLICATION_CODE;
    }

    /**
     * @notice Returns true if a transfer from an address is allowed.
     * @dev p.sendTime must be a date in the past for a transfer to be allowed.
     * @param _investor Address
     * @return true if address is whitelisted to send tokens, false otherwise.
     */
    function canSend(address _investor) public view returns (bool) {
        Permission storage p = permissions[_investor];
        // solium-disable-next-line security/no-block-members
        return p.sendAllowed;
    }

    /**
     * @notice Returns true if a transfer to an address is allowed.
     * @dev p.receiveTime must be a date in the past for a transfer to be allowed.
     * @param _investor Address
     * @return true if address is whitelisted to receive tokens, false otherwise.
     */
    function canReceive(address _investor) public view returns (bool) {
        Permission storage p = permissions[_investor];
        // solium-disable-next-line security/no-block-members
        return p.receiveAllowed;
    }
}

pragma solidity ^0.5.2;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

pragma solidity 0.5.4;


interface IModerator {
    function verifyIssue(address _tokenHolder, uint256 _value, bytes calldata _data) external view
        returns (bool allowed, byte statusCode, bytes32 applicationCode);

    function verifyTransfer(address _from, address _to, uint256 _amount, bytes calldata _data) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode);

    function verifyTransferFrom(address _from, address _to, address _forwarder, uint256 _amount, bytes calldata _data) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode);

    function verifyRedeem(address _sender, uint256 _amount, bytes calldata _data) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode);

    function verifyRedeemFrom(address _sender, address _tokenHolder, uint256 _amount, bytes calldata _data) external view
        returns (bool allowed, byte statusCode, bytes32 applicationCode);        

    function verifyControllerTransfer(address _controller, address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external view
        returns (bool allowed, byte statusCode, bytes32 applicationCode);

    function verifyControllerRedeem(address _controller, address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external view
        returns (bool allowed, byte statusCode, bytes32 applicationCode);
}

pragma solidity 0.5.4;

import "../../openzeppelin-solidity-2.2.0/contracts/access/Roles.sol";


// @notice Moderators are able to modify whitelists and transfer permissions in Moderator contracts.
contract ModeratorRole {
    using Roles for Roles.Role;

    event ModeratorAdded(address indexed account);
    event ModeratorRemoved(address indexed account);

    Roles.Role internal _moderators;

    modifier onlyModerator() {
        require(isModerator(msg.sender), "Only Moderators can execute this function.");
        _;
    }

    constructor() internal {
        _addModerator(msg.sender);
    }

    function isModerator(address account) public view returns (bool) {
        return _moderators.has(account);
    }

    function addModerator(address account) public onlyModerator {
        _addModerator(account);
    }

    function renounceModerator() public {
        _removeModerator(msg.sender);
    }    

    function _addModerator(address account) internal {
        _moderators.add(account);
        emit ModeratorAdded(account);
    }    

    function _removeModerator(address account) internal {
        _moderators.remove(account);
        emit ModeratorRemoved(account);
    }
}