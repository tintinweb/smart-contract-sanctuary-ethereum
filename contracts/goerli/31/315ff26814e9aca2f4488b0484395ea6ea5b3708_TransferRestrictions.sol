/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

/**
 *Submitted for verification at Etherscan.io on 2020-02-03
*/

// File: contracts/1404/IERC1404.sol

pragma solidity 0.5.8;

interface IERC1404 {
    /// @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
    /// @param from Sending address
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @return Code by which to reference message for rejection reasoning
    /// @dev Overwrite with your custom transfer restriction logic
    function detectTransferRestriction (address from, address to, uint256 value) external view returns (uint8);

    /// @notice Detects if a transferFrom will be reverted and if so returns an appropriate reference code
    /// @param sender Transaction sending address
    /// @param from Source of funds address
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @return Code by which to reference message for rejection reasoning
    /// @dev Overwrite with your custom transfer restriction logic
    function detectTransferFromRestriction (address sender, address from, address to, uint256 value) external view returns (uint8);

    /// @notice Returns a human-readable message for a given restriction code
    /// @param restrictionCode Identifier for looking up a message
    /// @return Text showing the restriction's reasoning
    /// @dev Overwrite with your custom message and restrictionCode handling
    function messageForTransferRestriction (uint8 restrictionCode) external view returns (string memory);
}

interface IERC1404getSuccessCode {
    /// @notice Return the uint256 that represents the SUCCESS_CODE
    /// @return uint256 SUCCESS_CODE
    function getSuccessCode () external view returns (uint256);
}

/**
 * @title IERC1404Success
 * @dev Combines IERC1404 and IERC1404getSuccessCode interfaces, to be implemented by the TransferRestrictions contract
 */
contract IERC1404Success is IERC1404getSuccessCode, IERC1404 {
}

// File: contracts/1404/IERC1404Validators.sol

pragma solidity 0.5.8;

/**
 * @title IERC1404Validators
 * @dev Interfaces implemented by the token contract to be called by the TransferRestrictions contract
 */
interface IERC1404Validators {
    /// @notice Returns the token balance for an account
    /// @param account The address to get the token balance of
    /// @return uint256 representing the token balance for the account
    function balanceOf (address account) external view returns (uint256);

    /// @notice Returns a boolean indicating the paused state of the contract
    /// @return true if contract is paused, false if unpaused
    function paused () external view returns (bool);

    /// @notice Determine if sender and receiver are whitelisted, return true if both accounts are whitelisted
    /// @param from The address sending tokens.
    /// @param to The address receiving tokens.
    /// @return true if both accounts are whitelisted, false if not
    function checkWhitelists (address from, address to) external view returns (bool);

    /// @notice Determine if a users tokens are locked preventing a transfer
    /// @param _address the address to retrieve the data from
    /// @param amount the amount to send
    /// @param balance the token balance of the sending account
    /// @return true if user has sufficient unlocked token to transfer the requested amount, false if not
    function checkTimelock (address _address, uint256 amount, uint256 balance) external view returns (bool);
}

// File: contracts/restrictions/RestrictionMessages.sol

pragma solidity 0.5.8;

contract RestrictionMessages {
    // ERC1404 Error codes and messages
    uint8 public constant SUCCESS_CODE = 0;
    uint8 public constant FAILURE_NON_WHITELIST = 1;
    uint8 public constant FAILURE_TIMELOCK = 2;
    uint8 public constant FAILURE_CONTRACT_PAUSED = 3;

    string public constant SUCCESS_MESSAGE = "SUCCESS";
    string public constant FAILURE_NON_WHITELIST_MESSAGE = "The transfer was restricted due to white list configuration.";
    string public constant FAILURE_TIMELOCK_MESSAGE = "The transfer was restricted due to timelocked tokens.";
    string public constant FAILURE_CONTRACT_PAUSED_MESSAGE = "The transfer was restricted due to the contract being paused.";
    string public constant UNKNOWN_ERROR = "Unknown Error Code";
}

// File: contracts/restrictions/TransferRestrictions.sol

pragma solidity 0.5.8;





/**
 * @title TransferRestrictions
 * @dev Defines the rules the validate transfers and the error messages
 */
contract TransferRestrictions is IERC1404, RestrictionMessages, IERC1404Success {

    IERC1404Validators validators;

    /**
    Constructor sets the address the validators contract which should be the token contract
    */
    constructor(address _validators) public
    {
        require(_validators != address(0), "0x0 is not a valid _validators address");
        validators = IERC1404Validators(_validators);
    }

    /**
    This function detects whether a transfer should be restricted and not allowed.
    If the function returns SUCCESS_CODE (0) then it should be allowed.
    */
    function detectTransferRestriction (address from, address to, uint256 amount)
        public
        view
        returns (uint8)
    {
        // Confirm that that addresses are whitelisted
        if(!validators.checkWhitelists(from,to)) {
            return FAILURE_NON_WHITELIST;
        }

        // If the from account is locked up, then don't allow the transfer
        if(!validators.checkTimelock(from, amount, validators.balanceOf(from))) {
            return FAILURE_TIMELOCK;
        }

        // If the entire contract is paused, then the transfer should be prevented
        if(validators.paused()) {
            return FAILURE_CONTRACT_PAUSED;
        }

        // If no restrictions were triggered return success
        return SUCCESS_CODE;
    }

    /**
    This function detects whether a transfer should be restricted and not allowed.
    If the function returns SUCCESS_CODE (0) then it should be allowed.
    */
    function detectTransferFromRestriction (address sender, address from, address to, uint256 value)
        public
        view
        returns (uint8)
    {
        // Confirm that that addresses are whitelisted
        if(!validators.checkWhitelists(sender, to)) {
            return FAILURE_NON_WHITELIST;
        }

        // return the result of detectTransferRestriction
        return detectTransferRestriction(from, to, value);
    }

    /**
    This function allows a wallet or other client to get a human readable string to show
    a user if a transfer was restricted.  It should return enough information for the user
    to know why it failed.
    */
    function messageForTransferRestriction (uint8 restrictionCode)
        external
        view
        returns (string memory)
    {
        if (restrictionCode == SUCCESS_CODE) {
            return SUCCESS_MESSAGE;
        }

        if (restrictionCode == FAILURE_NON_WHITELIST) {
            return FAILURE_NON_WHITELIST_MESSAGE;
        }

        if (restrictionCode == FAILURE_TIMELOCK) {
            return FAILURE_TIMELOCK_MESSAGE;
        }

        if (restrictionCode == FAILURE_CONTRACT_PAUSED) {
            return FAILURE_CONTRACT_PAUSED_MESSAGE;
        }

        return UNKNOWN_ERROR;
    }

    function getSuccessCode() external view returns (uint256) {
      return SUCCESS_CODE;
    }
}