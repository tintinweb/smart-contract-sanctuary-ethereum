/*
SPDX-License-Identifier: GPL-3.0-or-later

Copyright (c) 2020-2023 XOneFi

OneFi Smart Contract is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

OneFi Router is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with OneFi Router.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity ^0.8.19;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/math/Math.sol";

import "./ERC20.sol";
import "./Math.sol";

contract OneFiToken is Context, ERC20 {
    using Math for uint256;

    /*
    Administrator's account is the account that can arbitrarily add (not remove) any number
    of OFI tokens to any account. This account must be an EOA. */
    address payable admin;

    /* To reduce fees, we use timestamps both for deadlines and as nonces of signed data.
    Only current timestamps are used as nonces, not future ones. Thus, the repeated values
    are not possible in a properly funcioning OneFi protocol. Even if there is a reasonable
    clock asynchronization between hotspot and client, it will not do any harm.
    This mapping prevents replay attacks by storing used nonces (timestamps).

    FORMAT: usedTimestamps[client][hotspot][timestamp] = {USED == true, NOT-USED == false} */
    mapping(address => mapping(address => mapping(uint256 => bool))) usedTimestamps;

    /* We keep track of two balances: the actual ERC-20 balance, and the available balance,
    i.e., the unfrozen funds that can be immediately frozen, transferred, or sold.
    IMPORTANT NOTE: This mapping does not represent the current available balance. Instead,
    it representds the last known available balance. Freezes have expiration timestamps. However,
    expired freeze does not immediately update the available balance. We use our novel
    approach called CHEDGACO (Cheap Expired Deadlines Garbage Collection), which allows to
    keep the available balance updated without incurring large fees associated with iteration
    over multiple deadlines.

    FORMAT: available[client] = tokens */
    mapping(address => uint256) available;

    /* Hotspots can freeze a client's funds using a cryptographic token called PAFREN (Partial
    Freeze Endorsement), received from the client. When the funds are frozen, they cannot be
    transferred, sold, or frozen by someone else until a given deadline. This allows the hotspot
    to gather SACKS (Satisfaction Acknowledgements) from clients, while being assured that the
    user balance has enough funds reserved to exchange the last SACK into OneFi tokens.

    FORMAT: frozenFunds[client][hotspot] = amount */
    mapping(address => mapping(address => uint256)) frozenFunds;

    /* Every freeze has a deadline, before which the hotspot can claim a portion (or the whole)
    of the frozen funds by using a cryptographic message called SACK (Satisfaction Acknowledgement),
    received from the client. For each freeze, the hotspot can only claim funds once.

    FORMAT: freezeDeadlines[client][hotspot] = deadline_timestamp */
    mapping(address => mapping(address => uint256)) freezeDeadlines;

    /* This mapping is used for the CHEDGACO set of algorithms to keep track of the last
    freeze deadline, i.e., there is no other freeze deadline further than the one stored
    in this mapping. If the current timestamp is larger than this deadline, it effectively
    signifies that the account has no freezes, and thus the whole balance is immediately
    available. The CHEDGACO algorithm is based on the common-sense realization that the
    build-up of freezes applies only to client in motion, and any moving client eventually
    stops, which enables to take advantage of the lastDeadlines mapping to bulk-purge
    expired sessions.

    FORMAT: lastDeadlines[client] = last_freeze_deadline */
    mapping(address => uint256) lastDeadlines;


    /* After receiving the last SACK, the hotspot owner needs to promptly exchange it
    into OneFi tokens before the reserved funds get unfrozen. This constant specifies
    the number of seconds after the PAFREN expiration that the funds remain frozen
    for the hotspot to safely claim them. */
    uint256 constant claimPause = 1800;

    constructor () payable ERC20("OneFiToken", "OFI") {
        // The deployer of the smart contract will be the admin, who will be able to add
        // funds to accounts.
        admin = payable(msg.sender);
        // The deployer has an opportunity to load a balance. However, this does not
        // give the deployer any special privileges.
        _mint(msg.sender, msg.value);
        // All deposited funds are immediately available.
        available[msg.sender] = msg.value;
    }

    // Just a getter to the lastDeadlines mapping
    function getLastDeadline(address a) public view returns (uint256) {
        return lastDeadlines[a];
    }

    // Return available funds, i.e., ERC-20 balance that that is not under freeze
    function getAvailable(address a) public view returns (uint256) {
        // If the current block's timestamp is past the last freeze deadline,
        // it means that all funds are available because all freezes are expired.
        if(block.timestamp > lastDeadlines[a]) {
            return balanceOf(a);
        }
        // Otherwise, assume the last known unfrozen funds as the ground truth.
        return available[a];
    }

    // Return the amount of client's funds currently frozen the the hotspot
    function getFrozen(address client, address hotspot) public view returns (uint256) {
        // If freeze is expired, return 0
        if(block.timestamp > freezeDeadlines[client][hotspot]) {
            return 0;
        }
        // Otherwise, just return the current record
        return frozenFunds[client][hotspot];
    }

    // Ether collateralization: exchange Ether for OneFi tokens
    function buy() public payable {
        // Create new tokens equal to the amount of Ether/Wei deposited
        _mint(msg.sender, msg.value);
        // Increase the amount of available (i.e., non-frozen) funds accordingly.
        available[msg.sender] = available[msg.sender] + msg.value;
    }


    // Add _amount of OFI tokens to the _beneficiary account.
    function give(address _beneficiary, uint256 _amount) public {
        // Only administrator account can do this
        require(msg.sender == admin);
        // Create new tokens equal to _amount
        _mint(_beneficiary, _amount);
        // Increase the amount of available (i.e., non-frozen) funds accordingly.
        available[_beneficiary] = available[_beneficiary] + _amount;
    }

    // Ether collateralization: exchange Ether for OneFi tokens
    receive () external payable {
        buy();
    }

    // Exchange OneFi tokens into Ether
    function sell(uint256 amount) public {
        // If the timestamp of the current block is past the last deadline,
        // assume the full balance as immediately available.
        if(block.timestamp > lastDeadlines[msg.sender]) {
            available[msg.sender] = balanceOf(msg.sender);
        }
        // Check if there is sufficient amount of tokens available for selling
        require(available[msg.sender] >= amount, "Insufficient funds amount.");
        // Destroy the tokens. This function also updates the ERC-20 balance.
        _burn(msg.sender, amount);
        // And transfer equal amount of Ether to the caller
        payable(msg.sender).transfer(amount);
        // Update the available balance accordingly
        available[msg.sender] = getAvailable(msg.sender) - amount;
    }

    // Exchange SACK into OneFi tokens. This function is called by the hotspot after the client
    // disconnects or before the freeze deadline.
    function claim(address client, uint256 amount, uint32 timestamp, bytes memory sack) public {
        // If the timestamp of the current block is past the last deadline,
        // assume the full balance as immediately available.
        if(block.timestamp > lastDeadlines[client]) {
            available[client] = balanceOf(client);
        }

        // Only one SACK per freeze is allowed.
        require(!usedTimestamps[client][msg.sender][timestamp], "Timestamp has already been used.");

        // The funds must be transferred from the frozen balance, which must be sufficient.
        require(frozenFunds[client][msg.sender] >= amount, "Insufficient funds amount.");

        // The frozen balance must be non-expired.
        require(block.timestamp < freezeDeadlines[client][msg.sender], "Missed deadline.");

        // Get the prefixed hash of the SACK. All SACKs have the 'S' prefix to prevent attempts of
        // using PAFRENs instead of SACKs and vice versa, since they have similar format.
        bytes32 message = prefixed(keccak256(abi.encodePacked('S', client, msg.sender, amount, timestamp)));

        // Verify the signature using the implementation used in the Solidity documentation example.
        require(recoverSigner(message, sack) == client, "SACK signature verification failed.");

        // Mark the current timestamp to prevent the reuse of the SACK.
        usedTimestamps[client][msg.sender][timestamp] = true;

        // Transfer the tokens to the hotspot caller (hotspot owner). The available funds value
        // is not changed because this claim is fulfilled from the frozen balance, not from available one.
        _transfer(client, msg.sender, amount);

        // The corresponding freeze is immediately cancelled
        frozenFunds[client][msg.sender] = 0;

        // The corresponding freeze deadline is removed
        freezeDeadlines[client][msg.sender] = 0;

        // Update the hotspot's available balance in case the same account is used as a client.
        available[msg.sender] = available[msg.sender] + amount;
    }

    // Freeze client's funds until the time speficied in the timestamp
    function freeze(address client, uint256 amount, uint32 timestamp, bytes memory pafren) public {
        // If the timestamp of the current block is past the last deadline,
        // assume the full balance as immediately available.
        if(block.timestamp > lastDeadlines[client]) {
            available[client] = balanceOf(client);
        }

        // Prevent the re-use of the same PAFREN
        require(!usedTimestamps[client][msg.sender][timestamp], "Timestamp has already been used.");

        // There must be enough non-frozen funds to freeze
        require(available[client] >= amount, "Insufficient available balance.");

        // Restore the encoded prefixed hash of the PAFREN
        // To prevent a malicious use of PAFREN in lieu of SACK or vice versa, the 'P' prefix is used
        // for separation of otherwise identical formats. The timestamp represents the freeze deadline.
        bytes32 message = prefixed(keccak256(abi.encodePacked('P', client, msg.sender, amount, timestamp)));

        // Verify that the PAFREN was signed by the client.
        require(recoverSigner(message, pafren) == client, "Freeze proof is incorrect.");

        // Prevent double use of PAFRENS with the same timestamp.
        usedTimestamps[client][msg.sender][timestamp] = true;

        // PAFREN freezes funds specified by the amount value. However, it does not increase any existing
        // freeze. If an existing freeze exists, it will be overridden.
        frozenFunds[client][msg.sender] = amount;

        // Reduce the available funds amount accordingly.
        available[client] = available[client] - amount;

        // Set the freeze deadline, extended by the period of time when the hotspot
        // can claim the funds.
        freezeDeadlines[client][msg.sender] = timestamp + claimPause;

        // If the current freeze's deadline is past the farthest one, replace the
        // last deadline for the client with the new one.
        if(timestamp > lastDeadlines[client]) {
            lastDeadlines[client] = timestamp;
        }
    }

    // We override the OpenZeppelin Contracts implementation of ERC-20 transfer function
    // to incorporate the available (unfrozen) part of the balance
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        // If the timestamp of the current block is past the last deadline,
        // assume the full balance as immediately available.
        if(block.timestamp > lastDeadlines[msg.sender]) {
            available[msg.sender] = balanceOf(msg.sender);
        }

        if(block.timestamp > lastDeadlines[recipient]) {
            available[recipient] = balanceOf(recipient);
        }

        // Only allow to transfer if the available/non-frozen balance is sufficient
        require(available[msg.sender] >= amount, "Insufficient available funds amount.");

        // Perform the transfer as it is implemented in the OpenZeppelin Contracts.
        _transfer(msg.sender, recipient, amount);

        // The transferred funds go towards the available amount
        available[recipient] = available[recipient] + amount;

        // Also reduce the available portion of the sender accordingly
        available[msg.sender] = available[msg.sender] - amount;
        return true;
    }

    // Also, override the OpenZeppelin Contracts ERC-20 approve function to
    // accomodate the available balace functionality.
    function approve(address spender, uint256 amount) public override returns (bool) {
        // If the timestamp of the current block is past the last deadline,
        // assume the full balance as immediately available.
        if(block.timestamp > lastDeadlines[spender]) {
            available[spender] = balanceOf(spender);
        }

        // Only non-frozen funds can be approved for transferFrom
        require(available[spender] >= amount, "Insufficient available funds amount.");
        _approve(msg.sender, spender, amount);
        return true;
    }

    // Override the OpenZeppelin Contracts transferFrom ERC-20 routine to accomodate the
    // available balance accounting.
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        // If the timestamp of the current block is past the last deadline,
        // assume the full balance as immediately available.
        if(block.timestamp > lastDeadlines[sender]) {
            available[sender] = balanceOf(sender);
        }

        // Only allow to transfer from an unfrozen portion of the balance.
        require(available[sender] >= amount, "Insufficient available funds amount.");

        // Perform the transfer as it is implemented in OpenZeppelin Contracts
        _transfer(sender, recipient, amount);

        // Make sure the remaining balance still fits into the available portion
        bool res;
        uint256 am;
        (res, am) = allowance(sender, msg.sender).trySub(amount);
        require(res);
        require(available[sender] >= am, "Insufficient available funds amount.");

        // Approve the remaining balance
        (res, am) = allowance(sender, msg.sender).trySub(amount);
        require(res, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, am);
        return true;
    }

    // Override the OpenZeppelin Contracts increaseAllowance ERC-20 routine to accomodate the
    // available balance accounting.
    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        // If the timestamp of the current block is past the last deadline,
        // assume the full balance as immediately available.
        if(block.timestamp > lastDeadlines[spender]) {
            available[spender] = balanceOf(spender);
        }

        // Make sure that the increased allowance is still covered by the available balance
        bool res;
        uint256 am;
        (res, am) = allowance(msg.sender, spender).tryAdd(addedValue);
        require(res);
        require(available[spender] >= am, "Insufficient available funds amount.");

        // Approve the updated allowance
        (res, am) = allowance(msg.sender, spender).tryAdd(addedValue);
        require(res);
        _approve(msg.sender, spender, am);
        return true;
    }

    // Override the OpenZeppelin Contracts decreaseAllowance ERC-20 routine to accomodate the
    // available balance accounting.
    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        // If the timestamp of the current block is past the last deadline,
        // assume the full balance as immediately available.
        if(block.timestamp > lastDeadlines[spender]) {
            available[spender] = balanceOf(spender);
        }

        // Although we are decreasing the already approved allowance, the volatility of the available
        // component of the balance requires a frequent check. Thus, if the subtracted allowance is still
        // below the available funds, cancel the allowance whatsoever.


        bool res;
        uint256 am;
        (res, am) = allowance(msg.sender, spender).trySub(subtractedValue);
        require(res);

        if(available[spender] < am) {
            _approve(_msgSender(), spender, 0);
        } else { // Otherwise, proceed with the normal approach.
            (res, am) = allowance(_msgSender(), spender).trySub(subtractedValue);
            require(res, "ERC20: decreased allowance below zero");
            _approve(_msgSender(), spender, am);
        }
        return true;
    }

    // This function is borrowed from a sample in the Solidity documentation
    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65, "Wrong signature length.");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    // This function is borrowed from a sample in the Solidity documentation
    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    // This function is borrowed from a sample in the Solidity documentation
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}