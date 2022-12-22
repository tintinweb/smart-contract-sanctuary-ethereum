/**
 *
 * InvestaX X-Token Lite
 *
 *
 * SPDX-License-Identifier: UNLICENSED
 * (c) Copyright 2020 IC SG PTE LTD, all rights reserved.
 * Contract: Investa Admin
 *
 *
 * No part of this source code may be reproduced, stored in a retrieval system,
 * or transmitted, in any form or by any means, electronic, printing, photocopying,
 * recording, or otherwise, without the prior written permission of IC SG PTE LTD.
 *
 *
 *
 * @author Binod Nirvan
 * @title X-Token Lite Contract
 *
 *
 * @notice X-Token Lite contract is a lightweight implementation of X-Token Framework.
 * X-Token Lite has some basic token transfer restriction features that are required to
 * satisfy compliance requirements. Some of the features include but are not limited to
 * ensuring transfers to only happen between whitelisted addresses, digital securities
 * having the ability of being halted for trade or in other words transfer restricted,
 * and pausable mechanism to stop during emergencies.
 *
 *
 * Additionally, X-Token Lite also allows recovery of accidentally-sent
 * ERC-20 compatible tokens and Ethers sent to this address. To request a recovery,
 * please send an email to [[email protected]]([email protected])
 * with ownership proof of wallet that actually sent digital assets to this contract,
 * your identiy documents, and berifly explain about what happened.
 *
 *
 */
pragma solidity >=0.4.22 <0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./utils/TransferState.sol";
import "./utils/Reclaimable.sol";

contract XTokenLite is ERC20, TransferState, Reclaimable {
  /**
   * @notice Emitted when a digital security is issued to an account.
   * @param account The wallet/account that received this digital security issuance.
   * @param id The identifier of the `account` which received the issuance.
   * @param amount The units of digital securities issued.
   */
  event Issuance(address indexed account, bytes32 indexed id, uint256 amount);

  /**
   * @notice Emitted when a digital security is redeemed from an account.
   * @param account The wallet/account that redeemed this digital security.
   * @param id The identifier of the `account` which redeemed the issuance. 
            A zero-value identifier here denotes the redemption was "forced".
   * @param amount The units of digital securities redeemed.
   */
  event Redemption(address indexed account, bytes32 indexed id, uint256 amount);

  /**
   * @notice Emitted when an account is added to the whitelist.
   * @param account The wallet/account that was added to the whitelist.
   * @param id The identifier of the displayed `account`.
   */
  event AddToWhitelist(address indexed account, bytes32 indexed id);

  /**
   * @notice Emitted when an account is removed from the whitelist.
   * @param account The wallet/account that was removed from the whitelist.
   * @param id The identifier of the displayed `account`.
   */
  event RemoveFromWhitelist(address indexed account, bytes32 indexed id);

  /**
   * @notice Emitted when an account is added to the transfer lock list.
   * @param account The wallet/account that was added to the transfer lock list.
   * @param releaseDate The date from when tokens transfers can happen.
   */
  event AddToTransferLock(address indexed account, uint256 releaseDate);

  /**
   * @notice Emitted when an account is removed from the whitelist.
   * @param account The wallet/account that was removed from the transfer lock list.
   */
  event RemoveFromTransferLock(address indexed account);

  /**
   * @notice Identity struct represents IX-Prime Identity Module.
   * This identifier is generated on the server side to uniquely identify investor(s).
   */
  struct Identity {
    bytes32 id;
  }

  // Mapping of addresses and their respective identity information
  mapping(address => Identity) private _whitelist;

  // Mapping of addresses and their respective token release date
  mapping(address => uint256) private _transferLocks;

  /**
   * @notice This constructs the XToken Lite contract.
   * When a new instance of XToken Lite is constructed,
   * the following tasks are performed:
   *
   * - Basic Digital Security (ERC-20) information is set up.
   * - The sender account is added to the whitelist.
   * - Zero account is added to the whitelist.
   * - Transfers are enabled by default.
   * - Trustee account is assigned.
   *
   * @param name The name of this digital security.
   * @param symbol The symbol of this digital security.
   * @param decimals The numer of decimal places or decimal granularity.
   */
  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals,
    address trustee
  ) public ERC20(name, symbol) {
    super._setupDecimals(decimals);

    addToWhitelist(super._msgSender(), "IXPA"); // InvestaX platform admin
    addToWhitelist(address(0), "ZERO");

    super.enableTransfers();
    super._assignTrustee(trustee);
  }

  /**
   * @notice Redeems the digital securities held by the specified account.
   * @param account The account to redeem the digital securities from.
   * @param amount The amount of units to redeem.
   */
  function redeem(
    address account,
    bytes32 id,
    uint256 amount
  ) public onlyAdmin whenNotPaused {
    require(getWhitelist(account) == id, "Identity/wallet mismatch");

    super._burn(account, amount);
    emit Redemption(account, id, amount);
  }

  /**
   * @notice Forcefully redeems the digital securities held by the specified account.
   * @param account The account to redeem the digital securities from.
   * @param amount The amount of units to redeem.
   */
  function forceRedeem(address account, uint256 amount) public onlyAdmin whenNotPaused {
    super._burn(account, amount);

    emit Redemption(account, 0, amount);
  }

  /**
   * @notice Issues the specified value of the tokens to the destination address .
   * @param account The account to issue the digital securities to.
   * @param id The identity account id.
   * @param amount The amount of tokens to issue.
   * @param releaseDate The date from when tokens transfers can happen. Enter 0 (zero) if you wish to not lock this account for transfers.
   *
   */
  function issue(
    address account,
    bytes32 id,
    uint256 amount,
    uint256 releaseDate,
    bool withWhitelist
  ) public onlyAdmin whenNotPaused {
    bytes32 identity = getWhitelist(account);

    if (withWhitelist && identity == bytes32(0)) {
      addToWhitelist(account, id);
      identity = id;
    }

    require(identity == id, "Identity/wallet mismatch");

    super._mint(account, amount);

    if (releaseDate > 0) {
      addTransferLock(account, releaseDate);
    }

    emit Issuance(account, id, amount);
  }

  /**
   * @notice Adds the specified account and identifier to the whitelist.
   * @param account The account to whitelist.
   * @param id The account identifier.
   */
  function addToWhitelist(address account, bytes32 id) public onlyAdmin whenNotPaused {
    bytes32 identity = getWhitelist(account);

    if (identity != bytes32(0)) {
      require(identity == id, "Account already whitelisted but by someone else");
    }

    _whitelist[account].id = id;
    emit AddToWhitelist(account, id);
  }

  /**
   * @notice Removes the specified account from the whitelist.
   * @param account The account to remove.
   */
  function removeFromWhitelist(address account) public onlyAdmin whenNotPaused {
    require(account != address(0), "Can't remove zero address");
    emit RemoveFromWhitelist(account, _whitelist[account].id);

    delete _whitelist[account];
  }

  /**
   * @notice Adds the specified account and release date to the transfer lock.
   * @param account The account to lock the transfers of.
   * @param releaseDate The date from when tokens transfers can happen.
   */
  function addTransferLock(address account, uint256 releaseDate) public onlyAdmin whenNotPaused {
    require(account != address(0), "Can't add zero address");
    require(releaseDate > block.timestamp, "Please provide a future release date");

    _transferLocks[account] = releaseDate;
    emit AddToTransferLock(account, releaseDate);
  }

  /**
   * @notice Removes the specified account from the transfer lock.
   * @param account The account to remove.
   */
  function removeFromTransferLock(address account) public onlyAdmin whenNotPaused {
    require(account != address(0), "Can't remove zero address");

    emit RemoveFromTransferLock(account);

    delete _transferLocks[account];
  }

  /**
   * @notice Gets the identifier of the specified whitelist account.
   * @param account Specify an account to obtain the whitelist information.
   * @return Returns the identifier of the specified account.
   */
  function getWhitelist(address account) public view returns (bytes32) {
    return _whitelist[account].id;
  }

  /**
   * @notice Signifies if specified account is actually whitelisted.
   * @param account Specify an account to check against the whitelist.
   * @return Returns true if the specified account is whitelisted.
   */
  function ifWhitelisted(address account) public view returns (bool) {
    return getWhitelist(account) != bytes32(0);
  }

  /**
   * @notice Signifies if specified account is allowed to perform transfers or is not locked.
   * @param account Specify an account to check against the transfer lock list.
   * @return Returns true if the specified account is transfer locked.
   */
  function ifTransferAllowed(address account) public view returns (bool) {
    uint256 releaseDate = _transferLocks[account];

    if (releaseDate == 0) {
      return true;
    }

    return block.timestamp > releaseDate;
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * @notice This overrides `_beforeTokenTransfer` of Open Zeppelin ERC-20 contract.
   * Before transfers can actually happen, the following checks are performed:
   *
   * - Check if the transfer state is enabled
   * - Check if the contract isn't paused
   * - Check if both sender and receiver are whitelisted
   *
   * If these conditions are not satisfied, the transfer reverts throwing an error.
   *
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 // amount
  ) internal override checkTransferState(from) whenNotPaused {
    require(ifWhitelisted(from), "From address not in whitelist");
    require(ifWhitelisted(to), "To address not in whitelist");
    require(ifTransferAllowed(from), "Transfers are locked");
  }
}

/**
 * InvestaX X-Token Lite
 *
 *
 * SPDX-License-Identifier: UNLICENSED
 * (c) Copyright 2020 IC SG PTE LTD, all rights reserved.
 * Contract: Investa Admin
 *
 *
 * No part of this source code may be reproduced, stored in a retrieval system,
 * or transmitted, in any form or by any means, electronic, printing, photocopying,
 * recording, or otherwise, without the prior written permission of IC SG PTE LTD.
 *
 *
 *
 * @author Binod Nirvan
 * @title Transfer State Contract
 * @notice Enables the admins to maintain the transfer state.
 * Transfer state when disabled disallows everyone but the admins to transfer tokens.
 */
pragma solidity >=0.4.22 <0.8.0;
import "./InvestaAdmin.sol";

abstract contract TransferState is InvestaAdmin {
  bool private _transfersEnabled = false;

  /**
   * @dev Emitted when transfer state is disabled.
   * @param disabledBy The address of the administrator who performed this operation.
   */
  event TransfersDisabled(address indexed disabledBy);

  /**
   * @dev Emitted when transfer state is enabled.
   * @param enabledBy The address of the administrator who performed this operation.
   */
  event TransfersEnabled(address indexed enabledBy);

  /**
   * @notice Checks if the supplied address is able to perform transfers.
   * @param _from The address to check against if the transfer is allowed.
   */
  modifier checkTransferState(address _from) {
    if (_transfersEnabled == false) {
      if (isAdmin(_from) == false) {
        revert("Transfer state is restricted.");
      }
    }

    _;
  }

  /**
   * Enables owners and administrators to disable transfer state
   * on global level. When transfer state is disabled, no one
   * but the administrators can transfer tokens.
   */
  function disableTransfers() public onlyAdmin {
    require(_transfersEnabled, "Sorry, transfer is already disabled.");
    _transfersEnabled = false;

    emit TransfersDisabled(super._msgSender());
  }

  /**
   * Resume the transfer state on global level. Meaning, everyone
   * can transfer their tokens freely.
   */
  function enableTransfers() public onlyAdmin {
    require(_transfersEnabled == false, "Sorry, transfer is already enabled.");
    _transfersEnabled = true;

    emit TransfersEnabled(super._msgSender());
  }

  /**
   * @dev Transfer state dictates if the tokens can be freely
   * transferred by the token holders. When transfers are
   * in disabled state, only the administrators have the
   * ability to perform token transfers.
   * @return If the return value is `true`, it means
   * tokens are freely transferrable.
   */
  function getTransferState() external view returns (bool) {
    return _transfersEnabled;
  }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 * (c) Copyright 2020 IC SG PTE LTD, all rights reserved.
 * Contract: Investa Admin
 *
 *
 * No part of this source code may be reproduced, stored in a retrieval system,
 * or transmitted, in any form or by any means, electronic, printing, photocopying,
 * recording, or otherwise, without the prior written permission of IC SG PTE LTD.
 *
 *
 *
 * @author Binod Nirvan
 * @title Reclaimable Contract
 * @notice Reclaimable contract enables the owner
 * to reclaim accidentally sent Ethers and ERC20 token(s)
 * to this contract.
 */
pragma solidity >=0.4.22 <0.8.0;
import "./Pausable.sol";
import "./ITransferable.sol";

abstract contract Reclaimable is Pausable {
  /**
   * @notice Transfers all Ether held by the contract to the caller.
   */
  function reclaimEther() external onlyOwner whenNotPaused {
    uint256 balance = address(this).balance;

    (bool success, ) = super._msgSender().call{ value: balance }("");

    // There is no point covering the else statement
    // of this line.
    require(success, "Transfer failed.");
  }

  /**
   * @notice Transfers all ERC20 tokens held by the contract to the caller.
   * @param token The amount of token to reclaim.
   */
  function reclaimToken(address token) external onlyOwner whenNotPaused {
    ITransferable erc20 = ITransferable(token);

    uint256 balance = erc20.balanceOf(address(this));
    erc20.transfer(super._msgSender(), balance);
  }
}

/**
 *
 * InvestaX X-Token Lite
 *
 *
 * SPDX-License-Identifier: UNLICENSED
 * (c) Copyright 2020 IC SG PTE LTD, all rights reserved.
 * Contract: Investa Admin
 *
 *
 * No part of this source code may be reproduced, stored in a retrieval system,
 * or transmitted, in any form or by any means, electronic, printing, photocopying,
 * recording, or otherwise, without the prior written permission of IC SG PTE LTD.
 *
 *
 *
 * @author Binod Nirvan
 * Todo: Review this contract
 * @title Pausable Contract
 * @dev This contract enables you to create pausable mechanism to stop in case of emergency.
 */
pragma solidity >=0.4.22 <0.8.0;
import "./InvestaAdmin.sol";

abstract contract Pausable is InvestaAdmin {
  event Paused();
  event Unpaused();

  bool public _paused = false;

  /**
   * @notice Verifies whether the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!_paused, "Sorry, contract is paused.");
    _;
  }

  /**
   * @notice Verifies whether the contract is paused.
   */
  modifier whenPaused() {
    require(_paused, "Sorry, contract is not paused.");
    _;
  }

  /**
   * @notice Pauses the contract.
   */
  function pause() external onlyAdmin whenNotPaused {
    _paused = true;
    emit Paused();
  }

  /**
   * @notice Unpauses the contract and returns to normal state.
   */
  function unpause() external onlyAdmin whenPaused {
    _paused = false;
    emit Unpaused();
  }
}

/**
 * InvestaX X-Token Lite
 *
 *
 * SPDX-License-Identifier: UNLICENSED
 * (c) Copyright 2020 IC SG PTE LTD, all rights reserved.
 * Contract: Ownable
 *
 *
 * No part of this source code may be reproduced, stored in a retrieval system,
 * or transmitted, in any form or by any means, electronic, printing, photocopying,
 * recording, or otherwise, without the prior written permission of IC SG PTE LTD.
 *
 *
 *
 * @title Ownable Contract
 * @author Binod Nirvan
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
pragma solidity >=0.4.22 <0.8.0;
import "openzeppelin-solidity/contracts/GSN/Context.sol";

abstract contract Ownable is Context {
  address private _owner;

  /*
   * This contract, unlike Open Zeppelin Ownable contract,
   * requires a two-step ownership change. The new owner address
   * is stored in this variable until the ownership change is
   * accepted. Once the ownership change request is accepted,
   * this address is assigned the zero address.
   */
  address private _newOwner;

  /**
   * Triggered when existing owner requests to
   * transfer the ownership to a new account.
   */
  event OwnershipTransferRequested(address indexed previousOwner, address indexed newOwner);

  /**
   * Triggered when the new account accepts
   * the request to become the new owner
   * of this contract.
   */
  event OwnershipTransferAccepted(address indexed previousOwner, address indexed newOwner);

  constructor() internal {
    _owner = super._msgSender();
    emit OwnershipTransferRequested(address(0), super._msgSender());
    emit OwnershipTransferAccepted(address(0), super._msgSender());
  }

  /**
   *
   * @dev Validates whether the caller is actually the contract owner.
   *
   */
  modifier onlyOwner() {
    require(isOwner(super._msgSender()), "Access is denied");
    _;
  }

  /**
   * @dev Transfers the ownership of this contract to a new account (`newOwner`).
   * @param newOwner The proposed new owner of this contract.
   * @notice Ownership change will not be effective unless the new owner accepts it
   * by calling the function `acceptOwnershipTransfer`.
   *
   * The existing contract owner can submit multiple ownership transfer requests
   * before the transfer is actually accepted. If the owner submits
   * multiple ownership transfer requests, only the last proposed `newOwner`
   * will be able to accept to honor the request.
   *
   * This feature is restricted for owner use only.
   */
  function transferOwnership(address newOwner) external onlyOwner returns (bool) {
    require(newOwner != address(0), "Invalid address");

    require(newOwner != _owner, "Can't transfer ownership to yourself!");

    return _transferOwnership(newOwner);
  }

  /**
   * @dev Allows the new owner (candidate) to accept the ownership transfer request.
   * Can only be called by the proposed new owner.
   * @notice This feature is restricted for candidate use only.
   */
  function acceptOwnershipTransfer() external returns (bool) {
    require(super._msgSender() == _newOwner, "Access is denied");

    emit OwnershipTransferAccepted(_owner, _newOwner);

    _owner = _newOwner;
    _newOwner = address(0);

    return true;
  }

  /**
  @dev Returns the address of the candidate owner.
   */
  function candidate() external view returns (address) {
    return _newOwner;
  }

  /**
  @dev Returns the address of the contract owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
  @dev Checks if the provided address is the contract owner.
  @param account Enter an address to check.
  @return Returns true if the entered address is the owner.
   */
  function isOwner(address account) public view returns (bool) {
    return account == _owner;
  }

  /**
   * @dev Internal ownership transfer function meant to be
   * only accessible to this and derived contracts.
   * @param newOwner The proposed new owner of this contract.
   * @notice Ownership change will not be effective unless the new owner accepts it
   * by calling the function `acceptOwnershipTransfer`.
   *
   * The existing contract owner can submit multiple ownership transfer requests
   * before the transfer is actually accepted. If the owner submits
   * multiple ownership transfer requests, only the last proposed `newOwner`
   * will be able to accept to honor the request.
   */
  function _transferOwnership(address newOwner) internal returns (bool) {
    emit OwnershipTransferRequested(_owner, newOwner);
    _newOwner = newOwner;

    return true;
  }
}

/**
 *
 * InvestaX X-Token Lite
 *
 *
 * SPDX-License-Identifier: UNLICENSED
 * (c) Copyright 2020 IC SG PTE LTD, all rights reserved.
 * Contract: Investa Admin
 *
 *
 * No part of this source code may be reproduced, stored in a retrieval system,
 * or transmitted, in any form or by any means, electronic, printing, photocopying,
 * recording, or otherwise, without the prior written permission of IC SG PTE LTD.
 *
 *
 *
 * @author Binod Nirvan
 * @title InvestaAdmin Contract
 * @dev Admin contract provides features to have multiple administrators
 * who can collective perform admin-related tasks instead of depending on the owner.
 *
 * It is assumed by default that the owner is more power than admins
 * and therefore cannot be added to or removed from the admin list.
 */
pragma solidity >=0.4.22 <0.8.0;
import "./Ownable.sol";

abstract contract InvestaAdmin is Ownable {
  // Trustee account can change the owner
  // if the owner loses access to their account.
  address private _trustee;

  //List of administrators
  mapping(address => bool) private _admins;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);
  event TrusteeAssigned(address indexed account);
  event OwnerReassigned(address indexed trustee, address indexed newOwner);

  /**
   * @dev Validates if the sender is actually the trustee.
   */
  modifier onlyTrustee() {
    require(super._msgSender() == _trustee, "Access is denied");
    _;
  }

  /**
   * @dev Validates if the sender is actually an administrator.
   */
  modifier onlyAdmin() {
    require(isAdmin(super._msgSender()), "Access is denied");
    _;
  }

  /**
   * @dev Assigns or changes the trustee wallet.
   * @param account Enter a wallet address which will become the new trustee.
   * @return Returns true if the operation was successful.
   * @notice This feature is restricted for owner use only.
   */
  function assignTrustee(address account) external onlyOwner returns (bool) {
    return _assignTrustee(account);
  }

  /**
   * @dev Internal function to assign or change the trustee wallet.
   * @param account Enter a wallet address which will become the new trustee.
   * @return Returns true if the operation was successful.
   * @notice This feature is restricted for owner use only.
   */
  function _assignTrustee(address account) internal returns (bool) {
    require(account != address(0), "Invalid address");
    require(account != super.owner(), "The owner cannot become the trustee!");

    _trustee = account;

    emit TrusteeAssigned(account);
    return true;
  }

  /**
   * @dev Adds the specified address to the list of administrators.
   * @param account The address to add to the administrator list.
   * @return Returns true if the operation was successful.
   * @notice This feature is restricted for admin use only.
   */
  function addAdmin(address account) external onlyAdmin returns (bool) {
    require(account != address(0), "Invalid address");
    require(account != super.owner(), "The owner cannot be added!");
    require(!_admins[account], "Already an admin.");

    _admins[account] = true;

    emit AdminAdded(account);
    return true;
  }

  /**
   * @dev Removes the specified address from the list of administrators.
   * @param account The address to remove from the administrator list.
   * @return Returns true if the operation was successful.
   * @notice This feature is restricted for admin use only.
   */
  function removeAdmin(address account) external onlyAdmin returns (bool) {
    require(account != address(0), "Invalid address");
    //The owner cannot be removed as admin.
    require(account != super.owner(), "The owner cannot be removed!");
    require(_admins[account], "This address is not an admin.");

    _admins[account] = false;

    emit AdminRemoved(account);
    return true;
  }

  /**
   * @dev Changes the owner of this contract. The new owner still needs
   * to accept the ownership transfer request before the transfer becomes effective.
   * @param newOwner Specify a wallet address which will become the new owner.
   * @return Returns true if the operation was successful.
   * @notice This feature is restricted for trustee use only.
   */
  function reassignOwner(address newOwner) external onlyTrustee returns (bool) {
    require(newOwner != _trustee, "Trustee cannot become owner!");
    require(newOwner != super.owner(), "Already the owner.");

    super._transferOwnership(newOwner);
    emit OwnerReassigned(super._msgSender(), newOwner);
    return true;
  }

  /**
   * @dev The trustee wallet has the power to change
   * the owner in case of unforeseen or unavoidable situation.
   * @return Wallet address of the trustee account.
   */
  function getTrustee() external view returns (address) {
    return _trustee;
  }

  /**
   * @dev Checks if an address is an administrator.
   * @return Returns true if the specified wallet
   * is in fact an administrator.
   */
  function isAdmin(address account) public view returns (bool) {
    if (account == super.owner()) {
      //The owner has all rights and privileges assigned to the admins.
      return true;
    }

    return _admins[account];
  }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 * (c) Copyright 2020 IC SG PTE LTD, all rights reserved.
 * Contract: Investa Admin
 *
 *
 * No part of this source code may be reproduced, stored in a retrieval system,
 * or transmitted, in any form or by any means, electronic, printing, photocopying,
 * recording, or otherwise, without the prior written permission of IC SG PTE LTD.
 *
 *
 *
 * @author Binod Nirvan
 * @title Transferable Interface
 * @notice Represents any contract which supports `transfer` and `balanceOf`
 * features of an `ERC-20 Token`.
 */
pragma solidity >=0.4.22 <0.8.0;

interface ITransferable {
  function transfer(address recipient, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}