/**
 *Submitted for verification at Etherscan.io on 2022-07-05
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
    function mint(address, uint256) external virtual;
}

/**
 * @title GebProtOneTimeMinter
 * @author Reflexer Labs
 * @notice Contract that can be called a single time to mint a predefined amount of FLX for a predefined address.
 * @dev Contract needs to be authed in the token for it to be able to mint.
 */
contract GebProtOneTimeMinter is GebAuth {
    TokenLike public immutable prot;
    address public immutable mintReceiver;
    uint256 public immutable mintAmount;
    bool public minted;


    // --- Init Functions ---
    /**
      * @notice Constructor.
      * @param _prot Address of token to be minted.
      */
    constructor(address _prot, address _mintReceiver, uint256 _mintAmount) public {
        require(_prot != address(0), "GebProtOneTimeMinter/invalid-prot-address");
        require(_mintReceiver != address(0), "GebProtOneTimeMinter/invalid-receiver-address");
        require(_mintAmount > 0, "GebProtOneTimeMinter/null-mint-amount");
        prot = TokenLike(_prot);
        mintReceiver = _mintReceiver;
        mintAmount = _mintAmount;
    }

    // --- Admin Functions ---
    /**
     * @notice Mint a predefined amount of prot tokens for mintReceiver.
     * @dev Can run only once.
     */
    function mint() external isAuthorized {
        require(!minted, "GebProtOneTimeMinter/only-one-mint-allowed");
        minted = true;
        prot.mint(mintReceiver, mintAmount);
    }

    /**
     * @notice Transfer any token from treasury to dst (admin only).
     * @param dst The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     */
    function transferERC20(address _token, address dst, uint256 amount) external isAuthorized {
        TokenLike(_token).transfer(dst, amount);
    }
}