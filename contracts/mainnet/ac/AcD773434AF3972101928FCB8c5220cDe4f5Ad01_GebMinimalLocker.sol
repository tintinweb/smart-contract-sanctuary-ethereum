/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.7;

contract GebAuth {
    // --- Authorization ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "GebAuth/account-not-authorized");
        _;
    }

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);

    constructor () public {
        authorizedAccounts[msg.sender] = 1;
        emit AddAuthorization(msg.sender);
    }
}

abstract contract DSDelegateTokenLike {
    function transfer(address, uint256) external virtual returns (bool);
    function delegate(address) external virtual;
}

/**
 * @title Contract that locks tokens in until a prespecified timestamp.
 * @notice Contract locks ERC20 tokens until a predefined timestamp.
 *         Allows vote power delegation for tokens that have a COMP style interface.
 */
contract GebMinimalLocker is GebAuth {
    // --- State Variables ---
    // Timestamp of when the tokens deposited in this contract are unlocked
    uint256 public unlockTimestamp;

    // --- Init Functions ---
    /**
     * @notice Constructor
     * @param _unlockTimestamp of when the tokens deposited in this contract can be unlocked
     */
    constructor(
        uint256 _unlockTimestamp
    ) public {
        require(_unlockTimestamp > now, "GebMinimalLocker/invalid-unlock-timestamp");
        unlockTimestamp = _unlockTimestamp;
    }

    // --- Main Logic ---
    /**
     * @notice Transfers tokens out.
     * @param _token Address of the token to be transferred out.
     * @param _to Destination of transfer.
     * @param _amount Amount to be transferred.
     */
    function getTokens(address _token, address _to, uint256 _amount) external isAuthorized {
        require(now >= unlockTimestamp, "GebMinimalLocker/too-early");
        require(DSDelegateTokenLike(_token).transfer(_to, _amount), "GebMinimalLocker/token-transfer-failed");
    }

    /**
     * @notice Delegates voting power of tokens locked in this contract.
     * @param _token Address of the token.
     * @param _delegatee Address of the delegatee.
     */
    function delegate(address _token, address _delegatee) external isAuthorized {
        DSDelegateTokenLike(_token).delegate(_delegatee);
    }
}