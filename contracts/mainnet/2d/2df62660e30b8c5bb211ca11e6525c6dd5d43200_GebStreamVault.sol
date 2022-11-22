/**
 *Submitted for verification at Etherscan.io on 2022-11-22
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

abstract contract SablierLike {
    function createStream(address, uint256, address, uint256, uint256) external virtual returns (uint256);
    function cancelStream(uint256) external virtual;
}

abstract contract TokenLike {
    function transfer(address, uint256) external virtual;
    function approve(address, uint256) external virtual;
}

/**
 * @title GebStreamVault
 * @notice Inspired by Ameen's Sablier stream-pie contract that can be loaded with FLX and an authed address can:
 *    - get back FLX from the contract,
 *    - start a Sablier stream with custom params (duration),
 *    - stop a stream
 * The contract can only have 1 stream active at any time. If a stream is cancelled, it can be started again (with custom params/duration).
 */
contract GebStreamVault is GebAuth {
    SablierLike public sablier;
    uint256 public streamId;

    // --- Init Functions ---
    /**
      * @notice Constructor.
      * @param sablierAddress Address of Sablier.
      */
    constructor(address sablierAddress) public {
        require(sablierAddress != address(0), "GebStreamVault/null-sablier-address");
        sablier = SablierLike(sablierAddress);
    }

    // --- Admin Functions ---
    /**
     * @notice Modify an address parameter.
     * @param parameter The name of the parameter to change.
     * @param val The new value for the parameter.
     */
    function modifyParameters(bytes32 parameter, address val) external isAuthorized {
        require(val != address(0), "GebStreamVault/null-param");
        if (parameter == "sablierAddress") {
          sablier = SablierLike(val);
        }
        else revert("GebStreamVault/modify-unrecognized-param");
    }

    /**
     * @notice Creates a Sablier stream
     * @param recipient The address toward which the tokens are streamed.
     * @param deposit The amount of tokens to be streamed.
     * @param tokenAddress The ERC20 token to use as streaming currency.
     * @param startTime The unix timestamp for when the stream starts.
     * @param stopTime The unix timestamp for when the stream stops.
     * @return id The uint256 id of the newly created stream.
     */
    function createStream(
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    ) external isAuthorized returns (uint256 id) {
        require(streamId == 0, "GebStreamVault/only-one-stream-allowed");
        TokenLike(tokenAddress).approve(address(sablier), deposit);
        id = sablier.createStream(recipient, deposit, tokenAddress, startTime, stopTime);
        streamId = id;
    }

    /**
     * @notice Cancels the Sablier stream
     */
    function cancelStream() external isAuthorized {
        require(streamId != 0, "GebStreamVault/no-stream-to-cancel");
        sablier.cancelStream(streamId);
        streamId = 0;
    }

    /**
     * @notice Transfer any token from this contract to dst (admin only).
     * @param dst The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     */
    function transferERC20(address _token, address dst, uint256 amount) external isAuthorized {
        TokenLike(_token).transfer(dst, amount);
    }
}