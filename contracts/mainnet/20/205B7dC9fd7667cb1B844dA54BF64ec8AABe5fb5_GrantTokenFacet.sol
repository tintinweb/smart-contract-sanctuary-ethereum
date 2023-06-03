/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../../diamond/IDiamondFacet.sol";
import "../../reentrancy-lock/ReentrancyLockLib.sol";
import "./IGrantTokenInitializer.sol";
import "./GrantTokenInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract GrantTokenFacet is
    IDiamondFacet,
    IERC20Metadata,
    IGrantTokenInitializer
{
    modifier reentrancyProtected {
        ReentrancyLockLib._engageLock(HasherLib._hashStr("GLOBAL"));
        _;
        ReentrancyLockLib._releaseLock(HasherLib._hashStr("GLOBAL"));
    }

    function getFacetName()
      external pure override returns (string memory) {
        return "grant-token";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
       return "2.0.4";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](25);
        pi[ 0] = "initializeGrantToken(uint256,address,address,string,string,uint256)";
        pi[ 1] = "getGrantTokenSettings()";
        pi[ 2] = "setGrantTokenSettings(address,bool)";
        pi[ 3] = "name()";
        pi[ 4] = "symbol()";
        pi[ 5] = "decimals()";
        pi[ 6] = "totalSupply()";
        pi[ 7] = "balanceOf(address)";
        pi[ 8] = "isAllowanceCheckExempt(address)";
        pi[ 9] = "setAllowanceCheckExempt(address,bool)";
        pi[10] = "allowance(address,address)";
        pi[11] = "approve(address,uint256)";
        pi[12] = "transfer(address,uint256)";
        pi[13] = "transferFrom(address,address,uint256)";
        pi[14] = "getHolders()";
        pi[15] = "getNrOfTransferRequests()";
        pi[16] = "getTransferRequestInfo(uint256)";
        pi[17] = "getPendingTransferRequests()";
        pi[18] = "getAccountTransferRequests(address,bool)";
        pi[19] = "attachInfoToTransferRequest(uint256,string)";
        pi[20] = "authorizeTransfer(uint256,uint256,string)";
        pi[21] = "deAuthorizeTransfer(uint256,string)";
        pi[22] = "completeTransfer(uint256,address,address,string)";
        pi[23] = "abortTransfer(uint256,address,address,string)";
        pi[24] = "superTransfer(uint256,address,address,uint256,string)";
        return pi;
    }

    function getFacetProtectedPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](5);
        pi[ 0] = "setGrantTokenSettings(address,bool)";
        pi[ 1] = "setAllowanceCheckExempt(address,bool)";
        pi[ 2] = "authorizeTransfer(uint256,uint256,string)";
        pi[ 3] = "deAuthorizeTransfer(uint256,string)";
        pi[ 4] = "superTransfer(uint256,address,address,uint256,string)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return
            interfaceId == type(IDiamondFacet).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == ConstantsLib.GRANT_TOKEN_INTERFACE_ID;
    }

    function initializeGrantToken(
        uint256 registereeId,
        address council,
        address feeCollectionAccount,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 nrOfTokens
    ) external override {
        GrantTokenInternal._initialize(
            registereeId,
            council,
            feeCollectionAccount,
            tokenName,
            tokenSymbol,
            nrOfTokens
        );
    }

    function getGrantTokenSettings() external view returns (
        address, // registrar
        uint256, // registereeId
        address, // council
        address, // feeCollectionAccount
        bool     // transferAuthorizationRequired
    ) {
        return GrantTokenInternal._getGrantTokenSettings();
    }

    function setGrantTokenSettings(
        address feeCollectionAccount,
        bool transferAuthorizationRequired
    ) external {
        GrantTokenInternal._setGrantTokenSettings(
            feeCollectionAccount, transferAuthorizationRequired);
    }

    function name() external view override returns (string memory) {
        return GrantTokenInternal._getTokenName();
    }

    function symbol() external view override returns (string memory) {
        return GrantTokenInternal._getTokenSymbol();
    }

    function decimals() external pure override returns (uint8) {
        return GrantTokenInternal._getDecimals();
    }

    function totalSupply() external view override returns (uint256) {
        return GrantTokenInternal._getNrOfTokens();
    }

    function balanceOf(address account) external view override returns (uint256) {
        return GrantTokenInternal._getBalanceOf(account);
    }

    function isAllowanceCheckExempt(address account) external view returns (bool) {
        return GrantTokenInternal._isAllowanceCheckExempt(account);
    }

    function setAllowanceCheckExempt(address account, bool exempt) external {
        GrantTokenInternal._setAllowanceCheckExempt(account, exempt);
    }

    function allowance(
        address owner,
        address spender
    ) external view override returns (uint256) {
        return GrantTokenInternal._allowance(owner, spender);
    }

    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        address caller = msg.sender;
        address owner = msg.sender;
        return GrantTokenInternal._approve(
            caller, owner, spender, amount);
    }

    function transfer(
        address to,
        uint256 amount
    ) external override returns (bool) {
        address caller = msg.sender;
        address from = msg.sender;
        return GrantTokenInternal._submitTransfer(
            caller, from, to, amount, "");
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        address caller = msg.sender;
        return GrantTokenInternal._submitTransfer(
            caller, from, to, amount, "");
    }

    function getHolders()
    external view returns (address[] memory, uint256[] memory, uint256[] memory) {
        return GrantTokenInternal._getHolders();
    }

    function getNrOfTransferRequests() external view returns (uint256) {
        return GrantTokenInternal._getNrOfTransferRequests();
    }

    function getTransferRequestInfo(
        uint256 transferRequestId
    ) external view returns (
        address, // caller
        address, // from
        address, // to
        uint256, // amount
        bool, // aborted
        bool, // completed
        bool, // authorized
        uint256, // feeMicroUSD
        string[] memory // data
    ) {
        return GrantTokenInternal._getTransferRequestInfo(transferRequestId);
    }

    function getPendingTransferRequests() external view returns (uint256[] memory) {
        return GrantTokenInternal._getPendingTransferRequests();
    }

    function getAccountTransferRequests(
        address account,
        bool onlyPending
    ) external view returns (uint256[] memory) {
        return GrantTokenInternal._getAccountTransferRequests(account, onlyPending);
    }

    function attachInfoToTransferRequest(
        uint256 transferRequestId,
        string memory data
    ) external {
        GrantTokenInternal._attachInfoToTransferRequest(transferRequestId, data);
    }

    function authorizeTransfer(
        uint256 transferRequestId,
        uint256 feeMicroUSD,
        string memory data
    ) external {
        GrantTokenInternal._authorizeTransfer(transferRequestId, feeMicroUSD, data);
    }

    function deAuthorizeTransfer(
        uint256 transferRequestId,
        string memory data
    ) external {
        GrantTokenInternal._deAuthorizeTransfer(transferRequestId, data);
    }

    function completeTransfer(
        uint256 transferRequestId,
        address payErc20,
        address payer,
        string memory data
    ) external reentrancyProtected payable {
        GrantTokenInternal._completeTransfer(transferRequestId, payErc20, payer, data);
    }

    function abortTransfer(
        uint256 transferRequestId,
        address payErc20,
        address payer,
        string memory data
    ) external reentrancyProtected payable {
        GrantTokenInternal._abortTransfer(transferRequestId, payErc20, payer, data);
    }

    function superTransfer(
        uint256 adminProposalId,
        address from,
        address to,
        uint256 amount,
        string memory data
    ) external {
        address caller = msg.sender;
        GrantTokenInternal._superTransfer(
            adminProposalId, caller, from, to, amount, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IDiamondFacet is IERC165 {

    // NOTE: The override MUST remain 'pure'.
    function getFacetName() external pure returns (string memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetVersion() external pure returns (string memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetPI() external pure returns (string[] memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetProtectedPI() external pure returns (string[] memory);
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./ReentrancyLockInternal.sol";

library ReentrancyLockLib {

    function _engageLock(bytes32 lockId) internal {
        ReentrancyLockInternal._engageLock(lockId);
    }

    function _releaseLock(bytes32 lockId) internal {
        ReentrancyLockInternal._releaseLock(lockId);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IGrantTokenInitializer {

    function initializeGrantToken(
        uint256 registereeId,
        address council,
        address feeCollectionAccount,
        string memory grantTokenName,
        string memory grantTokenSymbol,
        uint256 nrOfGrantTokens
    ) external;
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../rbac/RBACLib.sol";
import "../../task-executor/TaskExecutorLib.sol";
import "../registrar/IRegistrar.sol";
import "../catalog/ICatalog.sol";
import "../council/ICouncil.sol";
import "../fiat-handler/FiatHandlerInternal.sol";
import "../Constants.sol";
import "./GrantTokenStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library GrantTokenInternal {

    // TODO(kam): easy function in order to add to fast transfer

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event NewTransferRequest(
        uint256 indexed transferRequestId
    );
    event TransferRequestUpdate(
        uint256 indexed transferRequestId
    );
    event SuperTransfer(
        address indexed from,
        address indexed to,
        uint256 value,
        string data
    );

    function _initialize(
        uint256 registereeId,
        address council,
        address feeCollectionAccount,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 nrOfTokens
    ) internal {
        require(!__s().initialized, "GTI:AI");
        require(registereeId > 0, "GTI:INVREGID");
        require(council != address(0), "GTI:ZC");
        require(feeCollectionAccount != address(0), "GTI:ZFCA");
        require(bytes(tokenName).length > 0, "GTI:ETN");
        require(bytes(tokenSymbol).length > 0, "GTI:ETS");
        require(nrOfTokens > 0, "GTI:ZNT");
        __s().registereeId = registereeId;
        __s().registrar = msg.sender;
        __s().council = council;
        __s().feeCollectionAccount = feeCollectionAccount;
        __s().tokenName = tokenName;
        __s().tokenSymbol = tokenSymbol;
        __mint(council, nrOfTokens);
        __s().transferAuthorizationRequired = false;
        address catalog = IRegistrar(__s().registrar).getCatalog();
        __s().allowanceCheckExempt[catalog] = true;
        RBACLib._unsafeGrantRole(__s().council, ConstantsLib.FAST_TRANSFER_ELIGIBLE_ROLE);
        __s().initialized = true;
    }

    function _getGrantTokenSettings() internal view returns (
        address, // registrar
        uint256, // uint256
        address, // council
        address, // feeCollectionAccount
        bool     // transferAuthorizationRequired
    ) {
        require(__s().initialized, "GTI:NI");
        return (
            __s().registrar,
            __s().registereeId,
            __s().council,
            __s().feeCollectionAccount,
            __s().transferAuthorizationRequired
        );
    }

    function _setGrantTokenSettings(
        address feeCollectionAccount,
        bool transferAuthorizationRequired
    ) internal {
        require(__s().initialized, "GTI:NI");
        require(feeCollectionAccount != address(0), "GTI:ZA");
        __s().feeCollectionAccount = feeCollectionAccount;
        __s().transferAuthorizationRequired = transferAuthorizationRequired;
    }

    function _getTokenName() internal view returns (string memory) {
        require(__s().initialized, "GTI:NI");
        return __s().tokenName;
    }

    function _getTokenSymbol() internal view returns (string memory) {
        require(__s().initialized, "GTI:NI");
        return __s().tokenSymbol;
    }

    function _getDecimals() internal pure returns (uint8) {
        return 0;
    }

    function _getNrOfTokens() internal view returns (uint256) {
        require(__s().initialized, "GTI:NI");
        return __s().nrOfTokens;
    }

    function _getBalanceOf(
        address account
    ) internal view returns (uint256) {
        return __s().balances[account];
    }

    function _isAllowanceCheckExempt(address account) internal view returns (bool) {
        return __s().allowanceCheckExempt[account];
    }

    function _setAllowanceCheckExempt(address account, bool exempt) internal {
        __s().allowanceCheckExempt[account] = exempt;
    }

    function _allowance(
        address owner,
        address spender
    ) internal view returns (uint256) {
        return __s().allowances[owner][spender];
    }

    function _approve(
        address caller,
        address owner,
        address spender,
        uint256 amount
    ) internal returns (bool) {
        require(__s().initialized, "GTI:NI");
        require(owner != address(0), "GTI:ZO");
        require(spender != address(0), "GTI:ZS");
        require(caller == owner, "GTI:INVO");
        __s().allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    function _getHolders() internal view returns (address[] memory, uint256[] memory, uint256[] memory) {
        uint256 counter = 0;
        for (uint256 i = 0; i < __s().holders.length; i++) {
            if (_getBalanceOf(__s().holders[i]) > 0) {
                counter += 1;
            }
        }
        address[] memory holders = new address[](counter);
        uint256[] memory balances = new uint256[](counter);
        uint256[] memory ratios = new uint256[](counter);
        uint256 j = 0;
        for (uint256 i = 0; i < __s().holders.length; i++) {
            uint256 balance = _getBalanceOf(__s().holders[i]);
            if (balance > 0) {
                holders[j] = __s().holders[i];
                balances[j] = balance;
                ratios[j] = (100 * balance) / __s().nrOfTokens;
                j += 1;
            }
        }
        return (holders, balances, ratios);
    }

    function _getNrOfTransferRequests() internal view returns (uint256) {
        return __s().transferRequestIdCounter;
    }

    function _getTransferRequestInfo(
        uint256 transferRequestId
    ) internal view returns (
        address, // caller
        address, // from
        address, // to
        uint256, // amount
        bool, // aborted
        bool, // completed
        bool, // authorized
        uint256, // feeMicroUSD
        string[] memory // data
    ) {
        require(transferRequestId > 0 &&
                transferRequestId <= __s().transferRequestIdCounter, "GTI:TRNF");
        GrantTokenStorage.TransferRequest storage transferRequest =
            __s().transferRequests[transferRequestId];
        return (
            transferRequest.caller,
            transferRequest.from,
            transferRequest.to,
            transferRequest.amount,
            transferRequest.aborted,
            transferRequest.completed,
            transferRequest.authorized,
            transferRequest.feeMicroUSD,
            transferRequest.data
        );
    }

    function _getPendingTransferRequests() internal view returns (uint256[] memory) {
        uint256 counter = 0;
        {
            for (uint256 i = 1; i <= __s().transferRequestIdCounter; i++) {
                if (__isTransferRequestPending(i)) {
                    counter += 1;
                }
            }
        }
        uint256[] memory transferRequestIds = new uint256[](counter);
        uint256 j = 0;
        {
            for (uint256 i = 1; i <= __s().transferRequestIdCounter; i++) {
                if (__isTransferRequestPending(i)) {
                    transferRequestIds[j] = i;
                    j += 1;
                }
            }
        }
        return transferRequestIds;
    }

    function _getAccountTransferRequests(
        address account,
        bool onlyPending
    ) internal view returns (uint256[] memory) {
        uint256 counter = 0;
        {
            for (uint256 i = 1; i <= __s().transferRequestIdCounter; i++) {
                if (
                    (
                        __s().transferRequests[i].caller == account ||
                        __s().transferRequests[i].from == account
                    ) &&
                    (
                        !onlyPending || __isTransferRequestPending(i)
                    )
                ) {
                    counter += 1;
                }
            }
        }
        uint256[] memory transferRequestIds = new uint256[](counter);
        uint256 j = 0;
        {
            for (uint256 i = 1; i <= __s().transferRequestIdCounter; i++) {
                if (
                    (
                        __s().transferRequests[i].caller == account ||
                        __s().transferRequests[i].from == account
                    ) &&
                    (
                        !onlyPending || __isTransferRequestPending(i)
                    )
                ) {
                    transferRequestIds[j] = i;
                    j += 1;
                }
            }
        }
        return transferRequestIds;
    }

    function _submitTransfer(
        address caller,
        address from,
        address to,
        uint256 amount,
        string memory data
    ) internal returns (bool) {
        require(__s().initialized, "GTI:NI");
        require(from != address(0), "GTI:ZF");
        require(to != address(0), "GTI:ZT");
        require(amount > 0, "GTI:ZA");
        require(amount <= __s().balances[from], "GTI:NEB");
        if (caller != from) {
            if (!__s().allowanceCheckExempt[caller]) {
                require(__s().allowances[from][caller] >= amount, "GTI:NEA");
                __s().allowances[from][caller] -= amount;
            }
        }
        uint256[] memory councilPendingProposals =
            ICouncil(__s().council).getAccountProposals(from, true);
        require(councilPendingProposals.length == 0, "GTI:PP");
        if (
            !__s().transferAuthorizationRequired ||
            RBACLib._hasRole(caller, ConstantsLib.FAST_TRANSFER_ELIGIBLE_ROLE)
        ) {
            __transfer(from, to, amount);
        } else {
            // create the transfer request
            uint256 transferRequestId = __s().transferRequestIdCounter + 1;
            __s().transferRequestIdCounter += 1;
            GrantTokenStorage.TransferRequest storage transferRequest =
                __s().transferRequests[transferRequestId];
            transferRequest.caller = caller;
            transferRequest.from = from;
            transferRequest.to = to;
            transferRequest.amount = amount;
            if (bytes(data).length > 0) {
                transferRequest.data.push(data);
            }
            {
                // lock tokens
                __s().balances[from] -= amount;
            }
            emit NewTransferRequest(transferRequestId);
        }
        return true;
    }

    function _attachInfoToTransferRequest(
        uint256 transferRequestId,
        string memory data
    ) internal {
        require(__s().initialized, "GTI:NI");
        require(bytes(data).length > 0, "GTI:ED");
        require(transferRequestId > 0 && transferRequestId <= __s().transferRequestIdCounter, "GTI:TRNF");
        GrantTokenStorage.TransferRequest storage transferRequest =
            __s().transferRequests[transferRequestId];
        require(msg.sender == transferRequest.caller ||
                msg.sender == transferRequest.from ||
                RBACLib._hasRole(msg.sender, ConstantsLib.GRANT_TOKEN_ADMIN_ROLE), "GTI:ACCD");
        require(!transferRequest.completed, "GTI:CA");
        require(!transferRequest.aborted, "GTI:AA");
        transferRequest.data.push(data);
        emit TransferRequestUpdate(transferRequestId);
    }

    function _authorizeTransfer(
        uint256 transferRequestId,
        uint256 feeMicroUSD,
        string memory data
    ) internal {
        require(__s().initialized, "GTI:NI");
        require(transferRequestId > 0 && transferRequestId <= __s().transferRequestIdCounter, "GTI:TRNF");
        GrantTokenStorage.TransferRequest storage transferRequest =
            __s().transferRequests[transferRequestId];
        require(!transferRequest.completed, "GTI:CA");
        require(!transferRequest.aborted, "GTI:AA");
        transferRequest.feeMicroUSD = feeMicroUSD;
        if (bytes(data).length > 0) {
            transferRequest.data.push(data);
        }
        transferRequest.authorized = true;
        emit TransferRequestUpdate(transferRequestId);
    }

    function _deAuthorizeTransfer(
        uint256 transferRequestId,
        string memory data
    ) internal {
        require(__s().initialized, "GTI:NI");
        require(transferRequestId > 0 && transferRequestId <= __s().transferRequestIdCounter, "GTI:TRNF");
        GrantTokenStorage.TransferRequest storage transferRequest =
            __s().transferRequests[transferRequestId];
        require(!transferRequest.completed, "GTI:CA");
        require(!transferRequest.aborted, "GTI:AA");
        require(transferRequest.authorized, "GTI:NAU");
        if (bytes(data).length > 0) {
            transferRequest.data.push(data);
        }
        transferRequest.authorized = false;
        emit TransferRequestUpdate(transferRequestId);
    }

    function _completeTransfer(
        uint256 transferRequestId,
        address payErc20,
        address payer,
        string memory data
    ) internal {
        require(__s().initialized, "GTI:NI");
        require(
            transferRequestId > 0 &&
            transferRequestId <= __s().transferRequestIdCounter, "GTI:TRNF");
        GrantTokenStorage.TransferRequest storage transferRequest =
            __s().transferRequests[transferRequestId];
        require(msg.sender == transferRequest.caller ||
                msg.sender == transferRequest.from ||
                RBACLib._hasRole(msg.sender, ConstantsLib.GRANT_TOKEN_ADMIN_ROLE), "GTI:ACCD");
        require(!transferRequest.completed, "GTI:CA");
        require(!transferRequest.aborted, "GTI:AA");
        require(transferRequest.authorized, "GTI:NAU");
        {
            __addHolder(transferRequest.to);
            // release locked tokens by transferring the tokens to the target account
            __s().balances[transferRequest.to] += transferRequest.amount;
            emit Transfer(transferRequest.from, transferRequest.to, transferRequest.amount);
            // notify the catalog
            address catalog = IRegistrar(__s().registrar).getCatalog();
            ICatalog(catalog).submitTransfer(
                __s().registereeId,
                transferRequest.from,
                transferRequest.to,
                transferRequest.amount
            );
        }
        if (bytes(data).length > 0) {
            transferRequest.data.push(data);
        }
        transferRequest.completed = true;
        FiatHandlerInternal._pay(FiatHandlerInternal.PayParams(
            payErc20,
            payer,
            __s().feeCollectionAccount,
            transferRequest.feeMicroUSD,
            msg.value,
            true, // return the remainder
            true  // consider the discount
        ));
        emit TransferRequestUpdate(transferRequestId);
    }

    function _abortTransfer(
        uint256 transferRequestId,
        address payErc20,
        address payer,
        string memory data
    ) internal {
        require(__s().initialized, "GTI:NI");
        require(transferRequestId > 0 &&
                transferRequestId <= __s().transferRequestIdCounter, "GTI:TRNF");
        GrantTokenStorage.TransferRequest storage transferRequest =
            __s().transferRequests[transferRequestId];
        require(msg.sender == transferRequest.caller ||
                msg.sender == transferRequest.from ||
                RBACLib._hasRole(msg.sender, ConstantsLib.GRANT_TOKEN_ADMIN_ROLE), "GTI:ACCD");
        require(!transferRequest.completed, "GTI:CA");
        require(!transferRequest.aborted, "GTI:AA");
        require(transferRequest.authorized, "GTI:NAU");
        {
            // return the allowance
            if (transferRequest.caller != transferRequest.from) {
                if (!__s().allowanceCheckExempt[transferRequest.caller]) {
                    __s().allowances[transferRequest.from][transferRequest.caller] +=
                        transferRequest.amount;
                }
            }
            // release locked tokens by returning it to the sender account
            __s().balances[transferRequest.from] += transferRequest.amount;
        }
        if (bytes(data).length > 0) {
            transferRequest.data.push(data);
        }
        transferRequest.aborted = true;
        FiatHandlerInternal._pay(FiatHandlerInternal.PayParams(
            payErc20,
            payer,
            __s().feeCollectionAccount,
            transferRequest.feeMicroUSD,
            msg.value,
            true, // return the remainder
            true  // consider discount
        ));
        emit TransferRequestUpdate(transferRequestId);
    }

    function _superTransfer(
        uint256 adminProposalId,
        address caller,
        address from,
        address to,
        uint256 amount,
        string memory data
    ) internal {
        require(__s().initialized, "GTI:NI");
        require(from != address(0), "GTI:ZF");
        require(to != address(0), "GTI:ZT");
        __transfer(from, to, amount);
        emit SuperTransfer(from, to, amount, data);
        ICouncil(__s().council).executeAdminProposal(caller, adminProposalId);
    }

    function __isTransferRequestPending(uint256 transferRequestId) private view returns (bool) {
        GrantTokenStorage.TransferRequest storage transferRequest =
            __s().transferRequests[transferRequestId];
        return !transferRequest.aborted && !transferRequest.completed;
    }

    function __addHolder(address account) private {
        if (__s().holdersIndex[account] == 0) {
            __s().holders.push(account);
            __s().holdersIndex[account] = __s().holders.length;
        }
    }

    function __mint(
        address account,
        uint256 amount
    ) private {
        require(account != address(0), "GTI:ZA");
        __addHolder(account);
        __s().nrOfTokens += amount;
        __s().balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function __transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        __addHolder(to);
        require(__s().balances[from] >= amount, "GTI:IA");
        __s().balances[from] -= amount;
        __s().balances[to] += amount;
        address catalog = IRegistrar(__s().registrar).getCatalog();
        emit Transfer(from, to, amount);
        ICatalog(catalog).submitTransfer(__s().registereeId, from, to, amount);
    }

    function __s() private pure returns (GrantTokenStorage.Layout storage) {
        return GrantTokenStorage.layout();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./ReentrancyLockStorage.sol";

library ReentrancyLockInternal {

    function _engageLock(bytes32 lockId) internal {
        require(!__s().reentrancyLocks[lockId], "REENL:ALCKD");
        __s().reentrancyLocks[lockId] = true;
    }

    function _releaseLock(bytes32 lockId) internal {
        require(__s().reentrancyLocks[lockId], "REENL:NLCKD");
        __s().reentrancyLocks[lockId] = false;
    }

    function __s() private pure returns (ReentrancyLockStorage.Layout storage) {
        return ReentrancyLockStorage.layout();
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library ReentrancyLockStorage {

    struct Layout {
        // lock to protect functions against reentrancy attack
        // lock id >
        mapping(bytes32 => bool) reentrancyLocks;
        // reserved for future usage
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.reentrancy-lock.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./RBACInternal.sol";

library RBACLib {

    function _hasRole(
        address account,
        uint256 role
    ) internal view returns (bool) {
        return RBACInternal._hasRole(account, role);
    }

    function _unsafeGrantRole(
        address account,
        uint256 role
    ) internal {
        RBACInternal._unsafeGrantRole(account, role);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./TaskExecutorInternal.sol";

library TaskExecutorLib {

    function _initialize(
        address newTaskManager
    ) internal {
        TaskExecutorInternal._initialize(newTaskManager);
    }

    function _getTaskManager(
        string memory taskManagerKey
    ) internal view returns (address) {
        return TaskExecutorInternal._getTaskManager(taskManagerKey);
    }

    function _executeTask(
        string memory key,
        uint256 taskId
    ) internal {
        TaskExecutorInternal._executeTask(key, taskId);
    }

    function _executeAdminTask(
        string memory key,
        uint256 adminTaskId
    ) internal {
        TaskExecutorInternal._executeAdminTask(key, adminTaskId);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IRegistrar {

    function initializeRegistrar(
        address deedRegistry,
        address catalog,
        string memory registrarName,
        string memory registrarURI,
        address defaultTaskManager,
        address defaultAuthzSource
    ) external;

    function getDeedRegistry() external view returns (address);

    function getCatalog() external view returns (address);
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface ICatalog {

    function initializeCatalog(
        address registrar,
        address deedRegistry
    ) external;

    function addDeed(
        uint256 registreeId,
        address grantToken,
        address council
    ) external;

    function submitTransfer(
        uint256 registereeId,
        address from,
        address to,
        uint256 amount
    ) external;
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface ICouncil {

    function initializeCouncil(
        uint256 registereeId,
        address grantToken,
        address feeCollectionAccount,
        address icoCollectionAccount,
        uint256 proposalCreationFeeMicroUSD,
        uint256 adminProposalCreationFeeMicroUSD,
        uint256 icoTokenPriceMicroUSD,
        uint256 icoFeeMicroUSD
    ) external;

    function getAccountProposals(
        address account,
        bool onlyPending
    ) external view returns (uint256[] memory);

    function executeProposal(
        address executor,
        uint256 proposalId
    ) external;

    function executeAdminProposal(
        address executor,
        uint256 adminProposalId
    ) external;

    function icoTransferTokensFromCouncil(
        address payErc20,
        address payer,
        address to,
        uint256 nrOfTokens
    ) external payable;
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./FiatHandlerStorage.sol";
import "../../../uniswap-v2/interfaces/IUniswapV2Factory.sol";
import "../../../uniswap-v2/interfaces/IUniswapV2Pair.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library FiatHandlerInternal {

    event WeiDiscount(
        uint256 indexed payId,
        address indexed payer,
        uint256 totalMicroUSDAmountBeforeDiscount,
        uint256 totalWeiBeforeDiscount,
        uint256 discountWei
    );
    event WeiPay(
        uint256 indexed payId,
        address indexed payer,
        address indexed dest,
        uint256 totalMicroUSDAmountBeforeDiscount,
        uint256 totalWeiAfterDiscount
    );
    event Erc20Discount(
        uint256 indexed payId,
        address indexed payer,
        uint256 totalMicroUSDAmountBeforeDiscount,
        address indexed erc20,
        uint256 totalTokensBeforeDiscount,
        uint256 discountTokens
    );
    event Erc20Pay(
        uint256 indexed payId,
        address indexed payer,
        address indexed dest,
        uint256 totalMicroUSDAmountBeforeDiscount,
        address erc20,
        uint256 totalTokensAfterDiscount
    );
    event TransferWeiTo(
        address indexed to,
        uint256 indexed amount
    );
    event TransferErc20To(
        address indexed erc20,
        address indexed to,
        uint256 amount
    );

    modifier mustBeInitialized() {
        require(__s().initialized, "FHI:NI");
        _;
    }

    function _initialize(
        address uniswapV2Factory,
        address wethAddress,
        address microUSDAddress,
        uint256 maxNegativeSlippage
    ) internal {
        require(!__s().initialized, "CI:AI");
        require(uniswapV2Factory != address(0), "FHI:ZFA");
        require(wethAddress != address(0), "FHI:ZWA");
        require(microUSDAddress != address(0), "FHI:ZMUSDA");
        require(maxNegativeSlippage >= 0 && maxNegativeSlippage <= 10, "FHI:WMNS");
        __s().uniswapV2Factory = uniswapV2Factory;
        __s().wethAddress = wethAddress;
        __s().microUSDAddress = microUSDAddress;
        __s().maxNegativeSlippage = maxNegativeSlippage;
        __s().payIdCounter = 1000;
        // by default allow WETH and USDT
        _setErc20Allowed(wethAddress, true);
        _setErc20Allowed(microUSDAddress, true);
        __s().initialized = true;
    }

    function _getFiatHandlerSettings()
    internal view returns (
        address, // uniswapV2Factory
        address, // wethAddress
        address, // microUSDAddress
        uint256  // maxNegativeSlippage
    ) {
        return (
            __s().uniswapV2Factory,
            __s().wethAddress,
            __s().microUSDAddress,
            __s().maxNegativeSlippage
        );
    }

    function _setFiatHandlerSettings(
        address uniswapV2Factory,
        address wethAddress,
        address microUSDAddress,
        uint256 maxNegativeSlippage
    ) internal mustBeInitialized {
        require(uniswapV2Factory != address(0), "FHI:ZFA");
        require(wethAddress != address(0), "FHI:ZWA");
        require(microUSDAddress != address(0), "FHI:ZMUSDA");
        require(maxNegativeSlippage >= 0 && maxNegativeSlippage <= 10, "FHI:WMNS");
        __s().wethAddress = wethAddress;
        __s().microUSDAddress = microUSDAddress;
        __s().maxNegativeSlippage = maxNegativeSlippage;
        __s().maxNegativeSlippage = maxNegativeSlippage;
    }

    function _getDiscount(address erc20) internal view returns (bool, bool, uint256, uint256) {
        FiatHandlerStorage.Discount storage discount;
        if (erc20 == address(0)) {
            discount = __s().weiDiscount;
        } else {
            discount = __s().erc20Discounts[erc20];
        }
        return (
            discount.enabled,
            discount.useFixed,
            discount.discountF,
            discount.discountP
        );
    }

    function _setDiscount(
        address erc20,
        bool enabled,
        bool useFixed,
        uint256 discountF,
        uint256 discountP
    ) internal {
        require(discountP >= 0 && discountP <= 100, "FHI:WDP");
        FiatHandlerStorage.Discount storage discount;
        if (erc20 == address(0)) {
            discount = __s().weiDiscount;
        } else {
            discount = __s().erc20Discounts[erc20];
        }
        discount.enabled = enabled;
        discount.useFixed = useFixed;
        discount.discountF = discountF;
        discount.discountP = discountP;
    }

    function _getListOfErc20s() internal view returns (address[] memory) {
        return __s().erc20sList;
    }

    function _isErc20Allowed(address erc20) internal view returns (bool) {
        return __s().allowedErc20s[erc20];
    }

    function _setErc20Allowed(address erc20, bool allowed) internal {
        __s().allowedErc20s[erc20] = allowed;
        if (__s().erc20sListIndex[erc20] == 0) {
            __s().erc20sList.push(erc20);
            __s().erc20sListIndex[erc20] = __s().erc20sList.length;
        }
    }

    function _transferTo(
        address erc20,
        address to,
        uint256 amount,
        string memory /* data */
    ) internal {
        require(to != address(0), "FHI:TTZ");
        require(amount > 0, "FHI:ZAM");
        if (erc20 == address(0)) {
            require(amount <= address(this).balance, "FHI:MTB");
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = to.call{value: amount}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "FHI:TF");
            emit TransferWeiTo(to, amount);
        } else {
            require(amount <= IERC20(erc20).balanceOf(address(this)), "FHI:MTB");
            bool success = IERC20(erc20).transfer(to, amount);
            require(success, "FHI:TF2");
            emit TransferErc20To(erc20, to, amount);
        }
    }

    struct PayParams {
        address erc20;
        address payer;
        address payout;
        uint256 microUSDAmount;
        uint256 availableValue;
        bool returnRemainder;
        bool considerDiscount;
    }
    function _pay(
        PayParams memory params
    ) internal mustBeInitialized returns (uint256) {
        require(params.payer != address(0), "FHI:ZP");
        if (params.microUSDAmount == 0) {
            return 0;
        }
        if (params.erc20 != address(0)) {
            require(__s().allowedErc20s[params.erc20], "FHI:CNA");
        }
        uint256 payId = __s().payIdCounter + 1;
        __s().payIdCounter += 1;
        address dest = address(this);
        if (params.payout != address(0)) {
            dest = params.payout;
        }
        if (params.erc20 == address(0)) {
            uint256 weiAmount = _convertMicroUSDToWei(params.microUSDAmount);
            uint256 discount = 0;
            if (params.considerDiscount) {
                discount = _calcDiscount(address(0), weiAmount);
            }
            if (discount > 0) {
                emit WeiDiscount(
                    payId, params.payer, params.microUSDAmount, weiAmount, discount);
                weiAmount -= discount;
            }
            if (params.availableValue < weiAmount) {
                uint256 diff = weiAmount - params.availableValue;
                uint256 slippage = (diff * 100) / weiAmount;
                require(slippage < __s().maxNegativeSlippage, "FHI:XMNS");
                return 0;
            }
            if (dest != address(this) && weiAmount > 0) {
                /* solhint-disable avoid-low-level-calls */
                (bool success,) = dest.call{value: weiAmount}(new bytes(0));
                /* solhint-enable avoid-low-level-calls */
                require(success, "FHI:TRF");
            }
            emit WeiPay(payId, params.payer, dest, params.microUSDAmount, weiAmount);
            if (params.returnRemainder && params.availableValue >= weiAmount) {
                uint256 remainder = params.availableValue - weiAmount;
                if (remainder > 0) {
                    /* solhint-disable avoid-low-level-calls */
                    (bool success2, ) = params.payer.call{value: remainder}(new bytes(0));
                    /* solhint-enable avoid-low-level-calls */
                    require(success2, "FHI:TRF2");
                }
            }
            return weiAmount;
        } else {
            uint256 tokensAmount = _convertMicroUSDToERC20(params.erc20, params.microUSDAmount);
            uint256 discount = 0;
            if (params.considerDiscount) {
                discount = _calcDiscount(params.erc20, tokensAmount);
            }
            if (discount > 0) {
                emit Erc20Discount(
                    payId, params.payer, params.microUSDAmount, params.erc20, tokensAmount, discount);
                tokensAmount -= discount;
            }
            require(tokensAmount <=
                    IERC20(params.erc20).balanceOf(params.payer), "FHI:NEB");
            require(tokensAmount <=
                    IERC20(params.erc20).allowance(params.payer, address(this)), "FHI:NEA");
            if (tokensAmount > 0) {
                IERC20(params.erc20).transferFrom(params.payer, dest, tokensAmount);
            }
            emit Erc20Pay(
                payId, params.payer, dest, params.microUSDAmount, params.erc20, tokensAmount);
            return 0;
        }
    }

    function _convertMicroUSDToWei(uint256 microUSDAmount) internal view returns (uint256) {
        require(__s().wethAddress != address(0), "FHI:ZWA");
        require(__s().microUSDAddress != address(0), "FHI:ZMUSDA");
        (bool pairFound, uint256 wethReserve, uint256 microUSDReserve) =
            __getReserves(__s().wethAddress, __s().microUSDAddress);
        require(pairFound && microUSDReserve > 0, "FHI:NPF");
        return (microUSDAmount * wethReserve) / microUSDReserve;
    }

    function _convertWeiToMicroUSD(uint256 weiAmount) internal view returns (uint256) {
        require(__s().wethAddress != address(0), "FHI:ZWA");
        require(__s().microUSDAddress != address(0), "FHI:ZMUSDA");
        (bool pairFound, uint256 wethReserve, uint256 microUSDReserve) =
            __getReserves(__s().wethAddress, __s().microUSDAddress);
        require(pairFound && wethReserve > 0, "FHI:NPF");
        return (weiAmount * microUSDReserve) / wethReserve;
    }

    function _convertMicroUSDToERC20(
        address erc20,
        uint256 microUSDAmount
    ) internal view returns (uint256) {
        require(__s().microUSDAddress != address(0), "FHI:ZMUSDA");
        if (erc20 == __s().microUSDAddress) {
            return microUSDAmount;
        }
        (bool microUSDPairFound, uint256 microUSDReserve, uint256 tokensReserve) =
            __getReserves(__s().microUSDAddress, erc20);
        if (microUSDPairFound && microUSDReserve > 0) {
            return (microUSDAmount * tokensReserve) / microUSDReserve;
        } else {
            require(__s().wethAddress != address(0), "FHI:ZWA");
            (bool pairFound, uint256 wethReserve, uint256 microUSDReserve2) =
                __getReserves(__s().wethAddress, __s().microUSDAddress);
            require(pairFound && microUSDReserve2 > 0, "FHI:NPF");
            uint256 weiAmount = (microUSDAmount * wethReserve) / microUSDReserve2;
            (bool wethPairFound, uint256 wethReserve2, uint256 tokensReserve2) =
                __getReserves(__s().wethAddress, erc20);
            require(wethPairFound && wethReserve2 > 0, "FHI:NPF2");
            return (weiAmount * tokensReserve2) / wethReserve2;
        }
    }

    function _convertERC20ToMicroUSD(
        address erc20,
        uint256 tokensAmount
    ) internal view returns (uint256) {
        require(__s().microUSDAddress != address(0), "FHI:ZMUSDA");
        if (erc20 == __s().microUSDAddress) {
            return tokensAmount;
        }
        (bool microUSDPairFound, uint256 microUSDReserve, uint256 tokensReserve) =
            __getReserves(__s().microUSDAddress, erc20);
        if (microUSDPairFound && tokensReserve > 0) {
            return (tokensAmount * microUSDReserve) / tokensReserve;
        } else {
            require(__s().wethAddress != address(0), "FHI:ZWA");
            (bool wethPairFound, uint256 wethReserve, uint256 tokensReserve2) =
                __getReserves(__s().wethAddress, erc20);
            require(wethPairFound && wethReserve > 0, "FHI:NPF");
            uint256 weiAmount = (tokensAmount * wethReserve) / tokensReserve2;
            (bool pairFound, uint256 wethReserve2, uint256 microUSDReserve2) =
                __getReserves(__s().wethAddress, __s().microUSDAddress);
            require(pairFound && wethReserve2 > 0, "FHI:NPF2");
            return (weiAmount * microUSDReserve2) / wethReserve2;
        }
    }

    function _calcDiscount(
        address erc20,
        uint256 amount
    ) internal view returns (uint256) {
        FiatHandlerStorage.Discount storage discount;
        if (erc20 == address(0)) {
            discount = __s().weiDiscount;
        } else {
            discount = __s().erc20Discounts[erc20];
        }
        if (!discount.enabled) {
            return 0;
        }
        if (discount.useFixed) {
            if (amount < discount.discountF) {
                return amount;
            }
            return discount.discountF;
        }
        return (amount * discount.discountP) / 100;
    }

    function __getReserves(
        address erc200,
        address erc201
    ) private view returns (bool, uint256, uint256) {
        address pair = IUniswapV2Factory(
            __s().uniswapV2Factory).getPair(erc200, erc201);
        if (pair == address(0)) {
            return (false, 0, 0);
        }
        address token1 = IUniswapV2Pair(pair).token1();
        (uint112 amount0, uint112 amount1,) = IUniswapV2Pair(pair).getReserves();
        uint256 reserve0 = amount0;
        uint256 reserve1 = amount1;
        if (token1 == erc200) {
            reserve0 = amount1;
            reserve1 = amount0;
        }
        return (true, reserve0, reserve1);
    }

    function __s() private pure returns (FiatHandlerStorage.Layout storage) {
        return FiatHandlerStorage.layout();
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

library ConstantsLib {

    uint256 constant public GRANT_TOKEN_ADMIN_ROLE =
        uint256(keccak256(bytes("GRANT_TOKEN_ADMIN_ROLE")));
    uint256 constant public FAST_TRANSFER_ELIGIBLE_ROLE =
        uint256(keccak256(bytes("FAST_TRANSFER_ELIGIBLE_ROLE")));
    bytes4 constant public GRANT_TOKEN_INTERFACE_ID = 0x8fd617ec;

    bytes32 public constant SET_ZONE_ID = bytes32(uint256(1));

    bytes32 public constant ADMIN_SET_ID = bytes32(uint256(1));
    bytes32 public constant CREATOR_SET_ID = bytes32(uint256(2));
    bytes32 public constant EXECUTOR_SET_ID = bytes32(uint256(3));
    bytes32 public constant FINALIZER_SET_ID = bytes32(uint256(4));

    uint256 public constant OPERATOR_TYPE_ADMIN = 1;
    uint256 public constant OPERATOR_TYPE_CREATOR = 2;
    uint256 public constant OPERATOR_TYPE_EXECUTOR = 3;
    uint256 public constant OPERATOR_TYPE_FINALIZER = 4;
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library GrantTokenStorage {

    struct TransferRequest {
        address caller;
        address from;
        address to;
        uint256 amount;

        bool aborted;
        bool completed;
        bool authorized;

        uint feeMicroUSD;

        // info attached to this request
        string[] data;

        // reserved for future usage
        mapping(bytes32 => bytes) extra;
    }

    struct Layout {
        bool initialized;

        address registrar;
        address council;
        uint256 registereeId;

        // ERC-20
        string tokenName;
        string tokenSymbol;
        uint256 nrOfTokens;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;

        address[] holders;
        mapping(address => uint256) holdersIndex;

        mapping(address => bool) allowanceCheckExempt;

        bool transferAuthorizationRequired;
        uint256 transferRequestIdCounter;
        mapping(uint256 => TransferRequest) transferRequests;

        address feeCollectionAccount;

        // reserved for future usage
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.txn.grant-token.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../task-executor/TaskExecutorLib.sol";
import "./RBACStorage.sol";

library RBACInternal {

    event RoleGrant(uint256 role, address account);
    event RoleRevoke(uint256 role, address account);

    function _hasRole(
        address account,
        uint256 role
    ) internal view returns (bool) {
        return __s().roles[role][account];
    }

    // ATTENTION! this function MUST NEVER get exposed via a facet
    function _unsafeGrantRole(
        address account,
        uint256 role
    ) internal {
        require(!__s().roles[role][account], "RBACI:AHR");
        __s().roles[role][account] = true;
        emit RoleGrant(role, account);
    }

    function _grantRole(
        uint256 taskId,
        string memory taskManagerKey,
        address account,
        uint256 role
    ) internal {
        _unsafeGrantRole(account, role);
        TaskExecutorLib._executeTask(taskManagerKey, taskId);
    }

    function _revokeRole(
        uint256 taskId,
        string memory taskManagerKey,
        address account,
        uint256 role
    ) internal {
        require(__s().roles[role][account], "RBACI:DHR");
        __s().roles[role][account] = false;
        emit RoleRevoke(role, account);
        TaskExecutorLib._executeTask(taskManagerKey, taskId);
    }

    function __s() private pure returns (RBACStorage.Layout storage) {
        return RBACStorage.layout();
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library RBACStorage {

    struct Layout {
        // role > address > true if granted
        mapping (uint256 => mapping(address => bool)) roles;
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.rbac.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "../hasher/HasherLib.sol";
import "./ITaskExecutor.sol";
import "./TaskExecutorStorage.sol";

library TaskExecutorInternal {

    event TaskManagerSet (
        string key,
        address taskManager
    );

    function _initialize(
        address newTaskManager
    ) internal {
        require(!__s().initialized, "TFI:AI");
        __setTaskManager("DEFAULT", newTaskManager);
        __s().initialized = true;
    }

    function _getTaskManagerKeys() internal view returns (string[] memory) {
        return __s().keys;
    }

    function _getTaskManager(string memory key) internal view returns (address) {
        bytes32 keyHash = HasherLib._hashStr(key);
        require(__s().keysIndex[keyHash] > 0, "TFI:KNF");
        return __s().taskManagers[keyHash];
    }

    function _setTaskManager(
        uint256 adminTaskId,
        string memory key,
        address newTaskManager
    ) internal {
        require(__s().initialized, "TFI:NI");
        bytes32 keyHash = HasherLib._hashStr(key);
        address oldTaskManager = __s().taskManagers[keyHash];
        __setTaskManager(key, newTaskManager);
        if (oldTaskManager != address(0)) {
            ITaskExecutor(oldTaskManager).executeAdminTask(msg.sender, adminTaskId);
        } else {
            address defaultTaskManager = _getTaskManager("DEFAULT");
            require(defaultTaskManager != address(0), "TFI:ZDTM");
            ITaskExecutor(defaultTaskManager).executeAdminTask(msg.sender, adminTaskId);
        }
    }

    function _executeTask(
        string memory key,
        uint256 taskId
    ) internal {
        require(__s().initialized, "TFI:NI");
        address taskManager = _getTaskManager(key);
        require(taskManager != address(0), "TFI:ZTM");
        ITaskExecutor(taskManager).executeTask(msg.sender, taskId);
    }

    function _executeAdminTask(
        string memory key,
        uint256 adminTaskId
    ) internal {
        require(__s().initialized, "TFI:NI");
        address taskManager = _getTaskManager(key);
        require(taskManager != address(0), "TFI:ZTM");
        ITaskExecutor(taskManager).executeAdminTask(msg.sender, adminTaskId);
    }

    function __setTaskManager(
        string memory key,
        address newTaskManager
    ) internal {
        require(newTaskManager != address(0), "TFI:ZA");
        require(IERC165(newTaskManager).supportsInterface(type(ITaskExecutor).interfaceId),
            "TFI:IC");
        bytes32 keyHash = HasherLib._hashStr(key);
        if (__s().keysIndex[keyHash] == 0) {
            __s().keys.push(key);
            __s().keysIndex[keyHash] = __s().keys.length;
        }
        __s().taskManagers[keyHash] = newTaskManager;
        emit TaskManagerSet(key, newTaskManager);
    }

    function __s() private pure returns (TaskExecutorStorage.Layout storage) {
        return TaskExecutorStorage.layout();
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

library HasherLib {

    function _hashAddress(address addr) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(addr));
    }

    function _hashStr(string memory str) internal pure returns (bytes32) {
        return keccak256(bytes(str));
    }

    function _hashInt(uint256 num) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("INT", num));
    }

    function _hashAccount(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("ACCOUNT", account));
    }

    function _hashVault(address vault) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("VAULT", vault));
    }

    function _hashReserveId(uint256 reserveId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("RESERVEID", reserveId));
    }

    function _hashContract(address contractAddr) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("CONTRACT", contractAddr));
    }

    function _hashTokenId(uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("TOKENID", tokenId));
    }

    function _hashRole(string memory roleName) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("ROLE", roleName));
    }

    function _hashLedgerId(uint256 ledgerId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("LEDGERID", ledgerId));
    }

    function _mixHash2(
        bytes32 d1,
        bytes32 d2
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("MIX2_", d1, d2));
    }

    function _mixHash3(
        bytes32 d1,
        bytes32 d2,
        bytes32 d3
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("MIX3_", d1, d2, d3));
    }

    function _mixHash4(
        bytes32 d1,
        bytes32 d2,
        bytes32 d3,
        bytes32 d4
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("MIX4_", d1, d2, d3, d4));
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface ITaskExecutor {

    event TaskExecuted(address finalizer, address executor, uint256 taskId);

    function executeTask(address executor, uint256 taskId) external;

    function executeAdminTask(address executor, uint256 taskId) external;
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library TaskExecutorStorage {

    struct Layout {
        // list of the keys
        string[] keys;
        mapping(bytes32 => uint256) keysIndex;
        // keccak256(key) > task manager address
        mapping(bytes32 => address) taskManagers;
        // true if default task manager has been set
        bool initialized;
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.task-finalizer.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library FiatHandlerStorage {

    struct Discount {
        bool enabled;
        bool useFixed;
        uint256 discountF;
        uint256 discountP;
        // reserved for future usage
        mapping(bytes32 => bytes) extra;
    }

    struct Layout {
        bool initialized;

        // UniswapV2Factory contract address:
        //  On mainnet: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
        address uniswapV2Factory;
        // WETH ERC-20 contract address:
        //   On mainnet: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        address wethAddress;
        // USDT ERC-20 contract address:
        //   On Mainnet: 0xdAC17F958D2ee523a2206206994597C13D831ec7
        address microUSDAddress;

        uint256 payIdCounter;
        uint256 maxNegativeSlippage;

        Discount weiDiscount;
        mapping(address => Discount) erc20Discounts;

        address[] erc20sList;
        mapping(address => uint256) erc20sListIndex;
        mapping(address => bool) allowedErc20s;

        // reserved for future usage
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.txn.fiat-handler.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./IUniswapV2ERC20.sol";

interface IUniswapV2Pair is IUniswapV2ERC20 {

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}