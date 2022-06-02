/**
 *Submitted for verification at Etherscan.io on 2022-06-02
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

abstract contract TokenLike {
    function transfer(address, uint256) external virtual;
}

/**
* @notice   Minimal treasury for the community DAO
*           Allows for delegating control of the treasury (fixed amount per epoch)
*           Governance can update allowance or revoke rights at any time
*           Increases in allowance take effect only in next epoch, decreases immediately
**/
contract GebDaoMinimalTreasury is GebAuth {
    // --- State vars ---
    // Token kept in the treasury
    TokenLike immutable public token;
    // Delegate, can spend allowance every epoch
    address public treasuryDelegate;
    // Duration of each epoch (seconds)
    uint256 public epochLength;
    // Amount that can be spent each epoch
    uint256 public delegateAllowance;
    // Amount left to spend in current epock
    uint256 internal delegateLeftoverToSpend_;
    // Current epoch start (Unix timestamp)
    uint256 public epochStart;

    // --- Constructor ---
    /**
     * @notice Constructor
     * @param _token Token to be used
     * @param _delegate Delegate
     * @param _epochLength Duration of each epoch (seconds)
     * @param _delegateAllowance Amount that can be spent by the delegate each epoch
     */
    constructor(
        address _token,
        address _delegate,
        uint256 _epochLength,
        uint256 _delegateAllowance
    ) public {
        require(_epochLength > 0, "GebDAOMinimalTreasury/invalid-epoch");
        require(_token != address(0), "GebDAOMinimalTreasury/invalid-epoch");
        token = TokenLike(_token);
        treasuryDelegate = _delegate;
        epochLength = _epochLength;
        delegateAllowance = _delegateAllowance;
        epochStart = now;
        delegateLeftoverToSpend_ = _delegateAllowance;
    }

    // --- SafeMath ---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "GebDAOMinimalTreasury/add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "GebDAOMinimalTreasury/sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "GebDAOMinimalTreasury/mul-overflow");
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Admin Functions ---
    /**
    * @notice Modify an int256 parameter
    * @param parameter The name of the parameter to change
    * @param val The new value for the parameter
    **/
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        if (parameter == "epochLength") {
          require(val > 0, "GebDAOMinimalTreasury/invalid-epochLength");
          epochLength = val;
        }
        else if (parameter == "delegateAllowance") {
          delegateAllowance = val;
          if (val < delegateLeftoverToSpend_)
            delegateLeftoverToSpend_ = val;
        }
        else revert("GebDAOMinimalTreasury/modify-unrecognized-param");
    }

    /**
    * @notice Modify an int256 parameter
    * @param parameter The name of the parameter to change
    * @param val The new value for the parameter
    **/
    function modifyParameters(bytes32 parameter, address val) external isAuthorized {
        if (parameter == "treasuryDelegate") {
          treasuryDelegate = val;
        }
        else revert("GebDAOMinimalTreasury/modify-unrecognized-param");
    }

    // --- Delegate functions ---
    /**
    * @notice Updates epoch info. Unused balance in previous epochs should not be available
    **/
    modifier updateEpoch() {
        uint256 epochFinish = add(epochStart, epochLength);
        if (now > epochFinish) {
            delegateLeftoverToSpend_ = delegateAllowance;
            if (now - epochFinish > epochLength) {
                uint256 epochsElapsed = sub(now, epochFinish) / epochLength;
                epochStart = add(mul(epochsElapsed, epochLength), epochFinish);
            } else
                epochStart = epochFinish;
        }
        _;
    }

    /**
     * @notice Transfer tokens from treasury to dst
     * @param dst The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     */
    function delegateTransferERC20(address dst, uint256 amount) external updateEpoch {
        require(msg.sender == treasuryDelegate, "GebDAOMinimalTreasury/unauthorized");
        delegateLeftoverToSpend_ = sub(delegateLeftoverToSpend_, amount); // reverts if lower allowance
        token.transfer(dst, amount);
    }

    /**
     * @notice Transfer any token from treasury to dst (admin only)
     * @param dst The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     */
    function transferERC20(address _token, address dst, uint256 amount) external isAuthorized {
        TokenLike(_token).transfer(dst, amount);
    }

    /**
     * @notice Returns current delegateLeftoverToSpend
     */
    function delegateLeftoverToSpend() external view returns (uint256) {
        uint256 epochFinish = add(epochStart, epochLength);
        if (now > epochFinish)
            return delegateAllowance;
        else
            return delegateLeftoverToSpend_;
    }
}