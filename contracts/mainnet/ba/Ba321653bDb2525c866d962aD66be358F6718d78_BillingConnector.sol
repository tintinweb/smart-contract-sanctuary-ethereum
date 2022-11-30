// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IBilling } from "./IBilling.sol";
import { IBillingConnector } from "./IBillingConnector.sol";
import { Governed } from "./Governed.sol";
import { ITokenGateway } from "arb-bridge-peripherals/contracts/tokenbridge/libraries/gateway/ITokenGateway.sol";
import { Rescuable } from "./Rescuable.sol";
import { IERC20WithPermit } from "./IERC20WithPermit.sol";
import { L1ArbitrumMessenger } from "./arbitrum/L1ArbitrumMessenger.sol";

/**
 * @title Billing Connector Contract
 * @dev The billing contract allows for Graph Tokens to be added by a user. The
 * tokens are immediately sent to the Billing contract on L2 (Arbitrum)
 * through the GRT token bridge.
 */
contract BillingConnector is IBillingConnector, Governed, Rescuable, L1ArbitrumMessenger {
    // -- State --
    // The contract for interacting with The Graph Token
    IERC20 private immutable graphToken;
    // The L1 Token Gateway through which tokens are sent to L2
    ITokenGateway public l1TokenGateway;
    // The Billing contract in L2 to which we send tokens
    address public l2Billing;
    // The Arbitrum Delayed Inbox address
    address public inbox;

    /**
     * @dev Address of the L1 token gateway was updated
     */
    event L1TokenGatewayUpdated(address l1TokenGateway);
    /**
     * @dev Address of the L2 Billing contract was updated
     */
    event L2BillingUpdated(address l2Billing);
    /**
     * @dev Address of the Arbitrum Inbox contract was updated
     */
    event ArbitrumInboxUpdated(address inbox);
    /**
     * @dev Tokens sent to the Billing contract on L2
     */
    event TokensSentToL2(address indexed _from, address indexed _to, uint256 _amount);
    /**
     * @dev Request sent to the Billing contract on L2 to remove tokens from the balance
     */
    event RemovalRequestSentToL2(address indexed _from, address indexed _to, uint256 _amount);

    /**
     * @notice Constructor function for BillingConnector
     * @param _l1TokenGateway   L1GraphTokenGateway address
     * @param _l2Billing Address of the Billing contract on L2
     * @param _token     Graph Token address
     * @param _governor  Governor address
     * @param _inbox Arbitrum Delayed Inbox address
     */
    constructor(
        address _l1TokenGateway,
        address _l2Billing,
        IERC20 _token,
        address _governor,
        address _inbox
    ) Governed(_governor) {
        _setL1TokenGateway(_l1TokenGateway);
        _setL2Billing(_l2Billing);
        _setArbitrumInbox(_inbox);
        graphToken = _token;
    }

    /**
     * @notice Sets the L1 token gateway address
     * @param _l1TokenGateway New address for the L1 token gateway
     */
    function setL1TokenGateway(address _l1TokenGateway) external override onlyGovernor {
        _setL1TokenGateway(_l1TokenGateway);
    }

    /**
     * @notice Sets the L2 Billing address
     * @param _l2Billing New address for the L2 Billing contract
     */
    function setL2Billing(address _l2Billing) external override onlyGovernor {
        _setL2Billing(_l2Billing);
    }

    /**
     * @notice Sets the Arbitrum Delayed Inbox address
     * @param _inbox New address for the Arbitrum Delayed Inbox
     */
    function setArbitrumInbox(address _inbox) external override onlyGovernor {
        _setArbitrumInbox(_inbox);
    }

    /**
     * @notice Add tokens into the billing contract on L2, for any user
     * @dev Ensure graphToken.approve() is called for the BillingConnector contract first
     * @param _to  Address that tokens are being added to
     * @param _amount  Amount of tokens to add
     * @param _maxGas Max gas for the L2 retryable ticket execution
     * @param _gasPriceBid Gas price for the L2 retryable ticket execution
     * @param _maxSubmissionCost Max submission price for the L2 retryable ticket
     */
    function addToL2(
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable override {
        require(_amount != 0, "Must add more than 0");
        require(_to != address(0), "destination != 0");
        _addToL2(msg.sender, _to, _amount, _maxGas, _gasPriceBid, _maxSubmissionCost);
    }

    /**
     * @notice Remove tokens from the billing contract on L2, sending the tokens
     * to an L2 address
     * @dev Useful when the tokens are in the balance for an address
     * that doesn't exist in L2.
     * Keep in mind there's no guarantee that the transaction will succeed in L2,
     * e.g. if the sender doesn't actually have enough balance there.
     * @param _to  L2 address to which the tokens (and any surplus ETH) will be sent
     * @param _amount  Amount of tokens to remove
     * @param _maxGas Max gas for the L2 retryable ticket execution
     * @param _gasPriceBid Gas price for the L2 retryable ticket execution
     * @param _maxSubmissionCost Max submission price for the L2 retryable ticket
     */
    function removeOnL2(
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable override {
        require(_amount != 0, "Must remove more than 0");
        require(_to != address(0), "destination != 0");
        // Callers of this function should generally be L1 contracts
        // (e.g. multisigs) that don't exist in L2, so the destination
        // must be some other address.
        require(_to != msg.sender, "destination != sender");

        bytes memory l2Calldata = abi.encodeWithSelector(IBilling.removeFromL1.selector, msg.sender, _to, _amount);

        // The bridge will validate msg.value and submission cost later, but at least fail early
        // if no submission cost is supplied.
        require(_maxSubmissionCost != 0, "Submission cost must be > 0");
        L2GasParams memory gasParams = L2GasParams(_maxSubmissionCost, _maxGas, _gasPriceBid);

        sendTxToL2(inbox, l2Billing, _to, msg.value, 0, gasParams, l2Calldata);
        emit RemovalRequestSentToL2(msg.sender, _to, _amount);
    }

    /**
     * @notice Add tokens into the billing contract on L2, for any user, using a signed permit
     * @param _user Address of the current owner of the tokens, that will also be the destination in L2
     * @param _amount  Amount of tokens to add
     * @param _maxGas Max gas for the L2 retryable ticket execution
     * @param _gasPriceBid Gas price for the L2 retryable ticket execution
     * @param _maxSubmissionCost Max submission price for the L2 retryable ticket
     * @param _deadline Expiration time of the signed permit
     * @param _v Signature recovery id
     * @param _r Signature r value
     * @param _s Signature s value
     */
    function addToL2WithPermit(
        address _user,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable override {
        require(_amount != 0, "Must add more than 0");
        require(_user != address(0), "destination != 0");
        IERC20WithPermit(address(graphToken)).permit(_user, address(this), _amount, _deadline, _v, _r, _s);
        _addToL2(_user, _user, _amount, _maxGas, _gasPriceBid, _maxSubmissionCost);
    }

    /**
     * @notice Allows the Governor to rescue any ERC20 tokens sent to this contract by accident
     * @param _to  Destination address to send the tokens
     * @param _token  Token address of the token that was accidentally sent to the contract
     * @param _amount  Amount of tokens to pull
     */
    function rescueTokens(
        address _to,
        address _token,
        uint256 _amount
    ) external override onlyGovernor {
        _rescueTokens(_to, _token, _amount);
    }

    /**
     * @dev Add tokens into the billing contract on L2, for any user
     * Ensure graphToken.approve() or graphToken.permit() is called for the BillingConnector contract first
     * @param _owner Address of the current owner of the tokens
     * @param _to  Address that tokens are being added to
     * @param _amount  Amount of tokens to add
     * @param _maxGas Max gas for the L2 retryable ticket execution
     * @param _gasPriceBid Gas price for the L2 retryable ticket execution
     * @param _maxSubmissionCost Max submission price for the L2 retryable ticket
     */
    function _addToL2(
        address _owner,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) internal {
        graphToken.transferFrom(_owner, address(this), _amount);

        bytes memory extraData = abi.encode(_to);
        bytes memory data = abi.encode(_maxSubmissionCost, extraData);

        graphToken.approve(address(l1TokenGateway), _amount);
        l1TokenGateway.outboundTransfer{ value: msg.value }(
            address(graphToken),
            l2Billing,
            _amount,
            _maxGas,
            _gasPriceBid,
            data
        );

        emit TokensSentToL2(_owner, _to, _amount);
    }

    /**
     * @dev Sets the L1 token gateway address
     * @param _l1TokenGateway New address for the L1 token gateway
     */
    function _setL1TokenGateway(address _l1TokenGateway) internal {
        require(_l1TokenGateway != address(0), "L1 Token Gateway cannot be 0");
        l1TokenGateway = ITokenGateway(_l1TokenGateway);
        emit L1TokenGatewayUpdated(_l1TokenGateway);
    }

    /**
     * @dev Sets the L2 Billing address
     * @param _l2Billing New address for the L2 Billing contract
     */
    function _setL2Billing(address _l2Billing) internal {
        require(_l2Billing != address(0), "L2 Billing cannot be zero");
        l2Billing = _l2Billing;
        emit L2BillingUpdated(_l2Billing);
    }

    /**
     * @dev Sets the Arbitrum Delayed Inbox address
     * @param _inbox New address for the Arbitrum Delayed Inbox
     */
    function _setArbitrumInbox(address _inbox) internal {
        require(_inbox != address(0), "Arbitrum Inbox cannot be zero");
        inbox = _inbox;
        emit ArbitrumInboxUpdated(_inbox);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IBilling {
    /**
     * @dev Set or unset an address as an allowed Collector
     * @param _collector  Collector address
     * @param _enabled True to set the _collector address as a Collector, false to remove it
     */
    function setCollector(address _collector, bool _enabled) external; // onlyGovernor

    /**
     * @dev Sets the L2 token gateway address
     * @param _l2TokenGateway New address for the L2 token gateway
     */
    function setL2TokenGateway(address _l2TokenGateway) external;

    /**
     * @dev Sets the L1 Billing Connector address
     * @param _l1BillingConnector New address for the L1 BillingConnector (without any aliasing!)
     */
    function setL1BillingConnector(address _l1BillingConnector) external;

    /**
     * @dev Add tokens into the billing contract
     * @param _amount  Amount of tokens to add
     */
    function add(uint256 _amount) external;

    /**
     * @dev Add tokens into the billing contract for any user
     * @param _to  Address that tokens are being added to
     * @param _amount  Amount of tokens to add
     */
    function addTo(address _to, uint256 _amount) external;

    /**
     * @dev Receive tokens with a callhook from the Arbitrum GRT bridge
     * Expects an `address user` in the encoded _data.
     * @param _from Token sender in L1
     * @param _amount Amount of tokens that were transferred
     * @param _data ABI-encoded callhook data: contains address that tokens are being added to
     */
    function onTokenTransfer(
        address _from,
        uint256 _amount,
        bytes calldata _data
    ) external;

    /**
     * @dev Remove tokens from the billing contract, from L1
     * This can only be called from the BillingConnector on L1.
     * @param _from  Address from which the tokens are removed
     * @param _to Address to send the tokens
     * @param _amount  Amount of tokens to remove
     */
    function removeFromL1(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    /**
     * @dev Add tokens into the billing contract in bulk
     * Ensure graphToken.approve() is called on the billing contract first
     * @param _to  Array of addresses where to add tokens
     * @param _amount  Array of amount of tokens to add to each account
     */
    function addToMany(address[] calldata _to, uint256[] calldata _amount) external;

    /**
     * @dev Remove tokens from the billing contract
     * Tokens will be removed from the sender's balance
     * @param _to  Address that tokens are being moved to
     * @param _amount  Amount of tokens to remove
     */
    function remove(address _to, uint256 _amount) external;

    /**
     * @dev Collector pulls tokens from the billing contract
     * @param _user  Address that tokens are being pulled from
     * @param _amount  Amount of tokens to pull
     * @param _to Destination to send pulled tokens
     */
    function pull(
        address _user,
        uint256 _amount,
        address _to
    ) external;

    /**
     * @dev Collector pulls tokens from many users in the billing contract
     * @param _users  Addresses that tokens are being pulled from
     * @param _amounts  Amounts of tokens to pull from each user
     * @param _to Destination to send pulled tokens
     */
    function pullMany(
        address[] calldata _users,
        uint256[] calldata _amounts,
        address _to
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IBillingConnector {
    /**
     * @dev Sets the L1 token gateway address
     * @param _l1TokenGateway New address for the L1 token gateway
     */
    function setL1TokenGateway(address _l1TokenGateway) external;

    /**
     * @dev Sets the L2 Billing address
     * @param _l2Billing New address for the L2 Billing contract
     */
    function setL2Billing(address _l2Billing) external;

    /**
     * @dev Sets the Arbitrum Delayed Inbox address
     * @param _inbox New address for the L2 Billing contract
     */
    function setArbitrumInbox(address _inbox) external;

    /**
     * @dev Add tokens into the billing contract on L2, for any user
     * Ensure graphToken.approve() is called for the BillingConnector contract first
     * @param _to  Address that tokens are being added to
     * @param _amount  Amount of tokens to add
     * @param _maxGas Max gas for the L2 retryable ticket execution
     * @param _gasPriceBid Gas price for the L2 retryable ticket execution
     * @param _maxSubmissionCost Max submission price for the L2 retryable ticket
     */
    function addToL2(
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable;

    /**
     * @dev Remove tokens from the billing contract on L2, sending the tokens
     * to an L2 address. Useful when the tokens are in the balance for an address
     * that doesn't exist in L2.
     * @param _to  L2 address to which the tokens will be sent
     * @param _amount  Amount of tokens to remove
     * @param _maxGas Max gas for the L2 retryable ticket execution
     * @param _gasPriceBid Gas price for the L2 retryable ticket execution
     * @param _maxSubmissionCost Max submission price for the L2 retryable ticket
     */
    function removeOnL2(
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable;

    /**
     * @dev Add tokens into the billing contract on L2, for any user, using a signed permit
     * @param _user Address of the current owner of the tokens, that will also be the destination in L2
     * @param _amount  Amount of tokens to add
     * @param _maxGas Max gas for the L2 retryable ticket execution
     * @param _gasPriceBid Gas price for the L2 retryable ticket execution
     * @param _maxSubmissionCost Max submission price for the L2 retryable ticket
     * @param _deadline Expiration time of the signed permit
     * @param _v Signature recovery id
     * @param _r Signature r value
     * @param _s Signature s value
     */
    function addToL2WithPermit(
        address _user,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable;

    /**
     * @dev Allows the Governor to rescue any ERC20 tokens sent to this contract by accident
     * @param _to  Destination address to send the tokens
     * @param _token  Token address of the token that was accidentally sent to the contract
     * @param _amount  Amount of tokens to pull
     */
    function rescueTokens(
        address _to,
        address _token,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

/**
 * @title Graph Governance contract
 * @dev Allows a contract to be owned and controlled by the 'governor'
 */
contract Governed {
    // -- State --

    // The address of the governor
    address public governor;
    // The address of the pending governor
    address public pendingGovernor;

    // -- Events --

    // Emit when the pendingGovernor state variable is updated
    event NewPendingOwnership(address indexed from, address indexed to);
    // Emit when the governor state variable is updated
    event NewOwnership(address indexed from, address indexed to);

    /**
     * @dev Check if the caller is the governor.
     */
    modifier onlyGovernor() {
        require(msg.sender == governor, "Only Governor can call");
        _;
    }

    /**
     * @dev Initialize the governor with the _initGovernor param.
     * @param _initGovernor Governor address
     */
    constructor(address _initGovernor) {
        require(_initGovernor != address(0), "Governor must not be 0");
        governor = _initGovernor;
    }

    /**
     * @dev Admin function to begin change of governor. The `_newGovernor` must call
     * `acceptOwnership` to finalize the transfer.
     * @param _newGovernor Address of new `governor`
     */
    function transferOwnership(address _newGovernor) external onlyGovernor {
        require(_newGovernor != address(0), "Governor must be set");

        address oldPendingGovernor = pendingGovernor;
        pendingGovernor = _newGovernor;

        emit NewPendingOwnership(oldPendingGovernor, pendingGovernor);
    }

    /**
     * @dev Admin function for pending governor to accept role and update governor.
     * This function must called by the pending governor.
     */
    function acceptOwnership() external {
        require(pendingGovernor != address(0) && msg.sender == pendingGovernor, "Caller must be pending governor");

        address oldGovernor = governor;
        address oldPendingGovernor = pendingGovernor;

        governor = pendingGovernor;
        pendingGovernor = address(0);

        emit NewOwnership(oldGovernor, governor);
        emit NewPendingOwnership(oldPendingGovernor, pendingGovernor);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ERC20 with Permit interface
 * @dev This is an ERC20 interface with an additional permit() function
 * that allows approving a user to move tokens using a signed permit.
 * The GraphToken contract implements this function.
 */
interface IERC20WithPermit is IERC20 {
    /**
     * @dev Approve token allowance by validating a message signed by the holder.
     * @param _owner Address of the token holder
     * @param _spender Address of the approved spender
     * @param _value Amount of tokens to approve the spender
     * @param _deadline Expiration time of the signed permit (if zero, the permit will never expire, so use with caution)
     * @param _v Signature recovery id
     * @param _r Signature r value
     * @param _s Signature s value
     */
    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Rescuable contract
 * @dev Allows a contract to have a function to rescue tokens sent by mistake.
 * The contract must implement the external rescueTokens function or similar,
 * that calls this contract's _rescueTokens.
 */
contract Rescuable {
    /**
     * @dev Tokens rescued by the permissioned user
     */
    event TokensRescued(address indexed to, address indexed token, uint256 amount);

    /**
     * @dev Allows a permissioned user to rescue any ERC20 tokens sent to this contract by accident
     * @param _to  Destination address to send the tokens
     * @param _token  Token address of the token that was accidentally sent to the contract
     * @param _amount  Amount of tokens to pull
     */
    function _rescueTokens(
        address _to,
        address _token,
        uint256 _amount
    ) internal {
        require(_to != address(0), "Cannot send to address(0)");
        require(_amount != 0, "Cannot rescue 0 tokens");
        IERC20 token = IERC20(_token);
        require(token.transfer(_to, _amount), "Rescue tokens failed");
        emit TokensRescued(_to, _token, _amount);
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Originally copied from:
 * https://github.com/OffchainLabs/arbitrum/tree/e3a6307ad8a2dc2cad35728a2a9908cfd8dd8ef9/packages/arb-bridge-peripherals
 *
 * MODIFIED from Offchain Labs' implementation:
 * - Changed solidity version to 0.8.16 ([email protected])
 *
 */

pragma solidity ^0.8.16;

import "./IInbox.sol";
import "./IOutbox.sol";

/// @notice L1 utility contract to assist with L1 <=> L2 interactions
/// @dev this is an abstract contract instead of library so the functions can be easily overriden when testing
abstract contract L1ArbitrumMessenger {
    event TxToL2(address indexed _from, address indexed _to, uint256 indexed _seqNum, bytes _data);

    struct L2GasParams {
        uint256 _maxSubmissionCost;
        uint256 _maxGas;
        uint256 _gasPriceBid;
    }

    function sendTxToL2(
        address _inbox,
        address _to,
        address _user,
        uint256 _l1CallValue,
        uint256 _l2CallValue,
        L2GasParams memory _l2GasParams,
        bytes memory _data
    ) internal virtual returns (uint256) {
        // alternative function entry point when struggling with the stack size
        return
            sendTxToL2(
                _inbox,
                _to,
                _user,
                _l1CallValue,
                _l2CallValue,
                _l2GasParams._maxSubmissionCost,
                _l2GasParams._maxGas,
                _l2GasParams._gasPriceBid,
                _data
            );
    }

    function sendTxToL2(
        address _inbox,
        address _to,
        address _user,
        uint256 _l1CallValue,
        uint256 _l2CallValue,
        uint256 _maxSubmissionCost,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes memory _data
    ) internal virtual returns (uint256) {
        uint256 seqNum = IInbox(_inbox).createRetryableTicket{ value: _l1CallValue }(
            _to,
            _l2CallValue,
            _maxSubmissionCost,
            _user,
            _user,
            _maxGas,
            _gasPriceBid,
            _data
        );
        emit TxToL2(_user, _to, seqNum, _data);
        return seqNum;
    }

    function getBridge(address _inbox) internal view virtual returns (IBridge) {
        return IInbox(_inbox).bridge();
    }

    /// @dev the l2ToL1Sender behaves as the tx.origin, the msg.sender should be validated to protect against reentrancies
    function getL2ToL1Sender(address _inbox) internal view virtual returns (address) {
        IOutbox outbox = IOutbox(getBridge(_inbox).activeOutbox());
        address l2ToL1Sender = outbox.l2ToL1Sender();

        require(l2ToL1Sender != address(0), "NO_SENDER");
        return l2ToL1Sender;
    }
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

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface ITokenGateway {
    /// @notice event deprecated in favor of DepositInitiated and WithdrawalInitiated
    // event OutboundTransferInitiated(
    //     address token,
    //     address indexed _from,
    //     address indexed _to,
    //     uint256 indexed _transferId,
    //     uint256 _amount,
    //     bytes _data
    // );

    /// @notice event deprecated in favor of DepositFinalized and WithdrawalFinalized
    // event InboundTransferFinalized(
    //     address token,
    //     address indexed _from,
    //     address indexed _to,
    //     uint256 indexed _transferId,
    //     uint256 _amount,
    //     bytes _data
    // );

    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes memory);

    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable;

    /**
     * @notice Calculate the address used when bridging an ERC20 token
     * @dev the L1 and L2 address oracles may not always be in sync.
     * For example, a custom token may have been registered but not deploy or the contract self destructed.
     * @param l1ERC20 address of L1 token
     * @return L2 address of a bridged ERC20 token
     */
    function calculateL2TokenAddress(address l1ERC20) external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Originally copied from:
 * https://github.com/OffchainLabs/arbitrum/tree/e3a6307ad8a2dc2cad35728a2a9908cfd8dd8ef9/packages/arb-bridge-eth
 *
 * MODIFIED from Offchain Labs' implementation:
 * - Changed solidity version to 0.8.16 ([email protected])
 *
 */

pragma solidity ^0.8.16;

import "./IBridge.sol";
import "./IMessageProvider.sol";

interface IInbox is IMessageProvider {
    function sendL2Message(bytes calldata messageData) external returns (uint256);

    function sendUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendL1FundedUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function sendL1FundedContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function createRetryableTicket(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

    function depositEth(uint256 maxSubmissionCost) external payable returns (uint256);

    function bridge() external view returns (IBridge);

    function pauseCreateRetryables() external;

    function unpauseCreateRetryables() external;

    function startRewriteAddress() external;

    function stopRewriteAddress() external;
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Originally copied from:
 * https://github.com/OffchainLabs/arbitrum/tree/e3a6307ad8a2dc2cad35728a2a9908cfd8dd8ef9/packages/arb-bridge-eth
 *
 * MODIFIED from Offchain Labs' implementation:
 * - Changed solidity version to 0.8.16 ([email protected])
 *
 */

pragma solidity ^0.8.16;

interface IOutbox {
    event OutboxEntryCreated(
        uint256 indexed batchNum,
        uint256 outboxEntryIndex,
        bytes32 outputRoot,
        uint256 numInBatch
    );
    event OutBoxTransactionExecuted(
        address indexed destAddr,
        address indexed l2Sender,
        uint256 indexed outboxEntryIndex,
        uint256 transactionIndex
    );

    function l2ToL1Sender() external view returns (address);

    function l2ToL1Block() external view returns (uint256);

    function l2ToL1EthBlock() external view returns (uint256);

    function l2ToL1Timestamp() external view returns (uint256);

    function l2ToL1BatchNum() external view returns (uint256);

    function l2ToL1OutputId() external view returns (bytes32);

    function processOutgoingMessages(bytes calldata sendsData, uint256[] calldata sendLengths) external;

    function outboxEntryExists(uint256 batchNum) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Originally copied from:
 * https://github.com/OffchainLabs/arbitrum/tree/e3a6307ad8a2dc2cad35728a2a9908cfd8dd8ef9/packages/arb-bridge-eth
 *
 * MODIFIED from Offchain Labs' implementation:
 * - Changed solidity version to 0.8.16 ([email protected])
 *
 */

pragma solidity ^0.8.16;

interface IMessageProvider {
    event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

    event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Originally copied from:
 * https://github.com/OffchainLabs/arbitrum/tree/e3a6307ad8a2dc2cad35728a2a9908cfd8dd8ef9/packages/arb-bridge-eth
 *
 * MODIFIED from Offchain Labs' implementation:
 * - Changed solidity version to 0.8.16 ([email protected])
 *
 */

pragma solidity ^0.8.16;

interface IBridge {
    event MessageDelivered(
        uint256 indexed messageIndex,
        bytes32 indexed beforeInboxAcc,
        address inbox,
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    );

    event BridgeCallTriggered(address indexed outbox, address indexed destAddr, uint256 amount, bytes data);

    event InboxToggle(address indexed inbox, bool enabled);

    event OutboxToggle(address indexed outbox, bool enabled);

    function deliverMessageToInbox(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable returns (uint256);

    function executeCall(
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData);

    // These are only callable by the admin
    function setInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    // View functions

    function activeOutbox() external view returns (address);

    function allowedInboxes(address inbox) external view returns (bool);

    function allowedOutboxes(address outbox) external view returns (bool);

    function inboxAccs(uint256 index) external view returns (bytes32);

    function messageCount() external view returns (uint256);
}