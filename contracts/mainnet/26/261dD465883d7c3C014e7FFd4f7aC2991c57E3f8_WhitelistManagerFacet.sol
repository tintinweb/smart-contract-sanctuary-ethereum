/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
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

import "../../../arteq-tech/contracts/diamond/IDiamondFacet.sol";
import "../../../arteq-tech/contracts/security/role-manager/RoleManagerLib.sol";
import "../arteQCollectionV2Config.sol";
import "./WhitelistManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract WhitelistManagerFacet is IDiamondFacet {

    modifier onlyAdmin() {
        RoleManagerLib._checkRole(arteQCollectionV2Config.ROLE_ADMIN);
        _;
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getVersion()
      external pure override returns (string memory) {
        return "0.0.1";
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId;
    }

    function getWhitelistingSettings()
      external view returns (bool, uint256, uint256, uint256) {
        return WhitelistManagerInternal._getWhitelistingSettings();
    }

    function setWhitelistingSettings(
        bool whitelistingAllowed,
        uint256 whitelistingFeeWei,
        uint256 whitelistingPriceWeiPerToken,
        uint256 maxNrOfWhitelistedTokensPerAccount
    ) external onlyAdmin {
        WhitelistManagerInternal._setWhitelistingSettings(
            whitelistingAllowed,
            whitelistingFeeWei,
            whitelistingPriceWeiPerToken,
            maxNrOfWhitelistedTokensPerAccount
        );
    }

    // Send 0 for nrOfTokens to de-list the address
    function whitelistMe(
        uint256 nrOfTokens,
        string memory paymentMethodName
    ) external payable {
        WhitelistManagerInternal._whitelistMe(
            nrOfTokens,
            paymentMethodName
        );
    }

    // Send 0 for nrOfTokens to de-list an address
    function whitelistAccounts(
        address[] memory accounts,
        uint256[] memory nrOfTokensArray
    ) external onlyAdmin {
        WhitelistManagerInternal._whitelistAccounts(
            accounts,
            nrOfTokensArray
        );
    }

    function getWhitelistEntry(address account) external view returns (uint256) {
        return WhitelistManagerInternal._getWhitelistEntry(account);
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
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
interface IDiamondFacet {

    function getVersion() external view returns (string memory);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
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

import "./RoleManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library RoleManagerLib {

    function _checkRole(uint256 role) internal view {
        RoleManagerInternal._checkRole(role);
    }

    function _hasRole(uint256 role) internal view returns (bool) {
        return RoleManagerInternal._hasRole(role);
    }

    function _grantRole(
        address account,
        uint256 role
    ) internal {
        RoleManagerInternal._grantRole(account, role);
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
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

/* solhint-disable contract-name-camelcase */
library arteQCollectionV2Config {

    uint256 constant public ROLE_ADMIN = uint256(keccak256(bytes("ROLE_ADMIN")));

    uint256 constant public ROLE_TOKEN_MANAGER = uint256(keccak256(bytes("ROLE_TOKEN_MANAGER")));
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
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

import "../payment-handler/PaymentHandlerLib.sol";
import "./WhitelistManagerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library WhitelistManagerInternal {

    event Whitelist(address account, uint256 nrOfTokens);

    function _getWhitelistingSettings()
      internal view returns (bool, uint256, uint256, uint256) {
        return (
            __s().whitelistingAllowed,
            __s().whitelistingFeeWei,
            __s().whitelistingPriceWeiPerToken,
            __s().maxNrOfWhitelistedTokensPerAccount
        );
    }

    function _setWhitelistingSettings(
        bool whitelistingAllowed,
        uint256 whitelistingFeeWei,
        uint256 whitelistingPriceWeiPerToken,
        uint256 maxNrOfWhitelistedTokensPerAccount
    ) internal {
        __s().whitelistingAllowed = whitelistingAllowed;
        __s().whitelistingFeeWei = whitelistingFeeWei;
        __s().whitelistingPriceWeiPerToken = whitelistingPriceWeiPerToken;
        __s().maxNrOfWhitelistedTokensPerAccount = maxNrOfWhitelistedTokensPerAccount;
    }

    // Send 0 for nrOfTokens to de-list the address
    function _whitelistMe(
        uint256 nrOfTokens,
        string memory paymentMethodName
    ) internal {
        require(__s().whitelistingAllowed, "WM:NA");
        PaymentHandlerLib._handlePayment(
            1, __s().whitelistingFeeWei,
            nrOfTokens, __s().whitelistingPriceWeiPerToken,
            paymentMethodName
        );
        _whitelist(msg.sender, nrOfTokens);
    }

    // Send 0 for nrOfTokens to de-list an address
    function _whitelistAccounts(
        address[] memory accounts,
        uint256[] memory nrOfTokensArray
    ) internal {
        require(__s().whitelistingAllowed, "WM:NA");
        require(accounts.length == nrOfTokensArray.length, "WM:IL");
        for (uint256 i = 0; i < accounts.length; i++) {
            _whitelist(accounts[i], nrOfTokensArray[i]);
        }
    }

    function _getWhitelistEntry(address account) internal view returns (uint256) {
        return __s().whitelistEntries[account];
    }

    function _whitelist(
        address account,
        uint256 nrOfTokens
    ) private {
        require(__s().maxNrOfWhitelistedTokensPerAccount == 0 ||
                nrOfTokens <= __s().maxNrOfWhitelistedTokensPerAccount,
                "WM:EMAX");
        __s().whitelistEntries[account] = nrOfTokens;
        emit Whitelist(account, nrOfTokens);
    }

    function __s() private pure returns (WhitelistManagerStorage.Layout storage) {
        return WhitelistManagerStorage.layout();
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
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

import "./RoleManagerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library RoleManagerInternal {

    event RoleGrant(uint256 role, address account);
    event RoleRevoke(uint256 role, address account);

    function _checkRole(uint256 role) internal view {
        require(__s().roles[role][msg.sender], "RM:MR");
    }

    function _hasRole(uint256 role) internal view returns (bool) {
        return __s().roles[role][msg.sender];
    }

    function _hasRole2(
        address account,
        uint256 role
    ) internal view returns (bool) {
        return __s().roles[role][account];
    }

    function _grantRole(
        address account,
        uint256 role
    ) internal {
        require(!__s().roles[role][account], "RM:AHR");
        __s().roles[role][account] = true;
        emit RoleGrant(role, account);
    }

    function _revokeRole(
        address account,
        uint256 role
    ) internal {
        require(__s().roles[role][account], "RM:DNHR");
        __s().roles[role][account] = false;
        emit RoleRevoke(role, account);
    }

    function __s() private pure returns (RoleManagerStorage.Layout storage) {
        return RoleManagerStorage.layout();
    }
}

/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
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
library RoleManagerStorage {

    struct Layout {
        mapping (uint256 => mapping(address => bool)) roles;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: d6cfccebecf684bbc10a5019ad1aed91fbc4f7461f5cd03e8c71240be4ca6bea
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-tech.contracts.security.role-manager.storage");

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
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
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

import "./PaymentHandlerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library PaymentHandlerLib {

    function _handlePayment(
        uint256 nrOfItems1, uint256 priceWeiPerItem1,
        uint256 nrOfItems2, uint256 priceWeiPerItem2,
        string memory paymentMethodName
    ) internal {
        PaymentHandlerInternal._handlePayment(
            nrOfItems1, priceWeiPerItem1,
            nrOfItems2, priceWeiPerItem2,
            paymentMethodName
        );
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
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
library WhitelistManagerStorage {

    struct Layout {
        bool whitelistingAllowed;
        uint256 whitelistingFeeWei;
        uint256 whitelistingPriceWeiPerToken;
        uint256 maxNrOfWhitelistedTokensPerAccount;
        mapping(address => uint256) whitelistEntries;
    }

    // Storage Slot: 71e0208316fc901686daf4f3337ab9e0c066ba9c3c2727e9209867af42765c4e
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-io.collections.v2.whitelist-manager.storage");

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
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
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

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../IUniswapV2Pair.sol";
import "./PaymentHandlerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library PaymentHandlerInternal {

    bytes32 constant public WEI_PAYMENT_METHOD_HASH = keccak256(abi.encode("WEI"));

    event WeiPayment(address payer, address dest, uint256 amountWei);
    event ERC20Payment(
        string paymentMethodName,
        address payer,
        address dest,
        uint256 amountWei,
        uint256 amountTokens
    );
    event TransferTo(address to, uint256 amount, string data);
    event TransferETH20To(string paymentMethodName, address to, uint256 amount, string data);

    function _getPaymentSettings() internal view returns (address, address) {
        return (__s().payoutAddress, __s().wethAddress);
    }

    function _setPaymentSettings(
        address payoutAddress,
        address wethAddress
    ) internal {
        __s().payoutAddress = payoutAddress;
        __s().wethAddress = wethAddress;
    }

    function _getERC20PaymentMethods() internal view returns (string[] memory) {
        return __s().erc20PaymentMethodNames;
    }

    function _getERC20PaymentMethodInfo(
        string memory paymentMethodName
    ) internal view returns (address, address, bool) {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(_paymentMethodExists(nameHash), "PH:NEM");
        return (
            __s().erc20PaymentMethods[nameHash].addr,
            __s().erc20PaymentMethods[nameHash].wethPair,
            __s().erc20PaymentMethods[nameHash].enabled
        );
    }

    function _addOrUpdateERC20PaymentMethod(
        string memory paymentMethodName,
        address addr,
        address wethPair
    ) internal {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        __s().erc20PaymentMethods[nameHash].addr = addr;
        __s().erc20PaymentMethods[nameHash].wethPair = wethPair;
        address token0 = IUniswapV2Pair(wethPair).token0();
        address token1 = IUniswapV2Pair(wethPair).token1();
        require(token0 == __s().wethAddress || token1 == __s().wethAddress, "PH:IPC");
        bool reverseIndices = (token1 == __s().wethAddress);
        __s().erc20PaymentMethods[nameHash].reverseIndices = reverseIndices;
        __s().erc20PaymentMethodNames.push(paymentMethodName);
    }

    function _enableERC20TokenPayment(
        string memory paymentMethodName,
        bool enabled
    ) internal {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(_paymentMethodExists(nameHash), "PH:NEM");
        __s().erc20PaymentMethods[nameHash].enabled = enabled;
    }

    function _transferTo(
        string memory paymentMethodName,
        address to,
        uint256 amount,
        string memory data
    ) internal {
        require(to != address(0), "PH:TTZ");
        require(amount > 0, "PH:ZAM");
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(nameHash == WEI_PAYMENT_METHOD_HASH || _paymentMethodExists(nameHash), "PH:MNS");
        if (nameHash == WEI_PAYMENT_METHOD_HASH) {
            require(amount <= address(this).balance, "PH:MTB");
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = to.call{value: amount}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "PH:TF");
            emit TransferTo(to, amount, data);
        } else {
            PaymentHandlerStorage.ERC20PaymentMethodInfo memory paymentMethod =
                __s().erc20PaymentMethods[nameHash];
            require(
                amount <= IERC20(paymentMethod.addr).balanceOf(address(this)),
                "PH:MTB"
            );
            IERC20(paymentMethod.addr).transfer(to, amount);
            emit TransferETH20To(paymentMethodName, to, amount, data);
        }
    }

    function _handlePayment(
        uint256 nrOfItems1, uint256 priceWeiPerItem1,
        uint256 nrOfItems2, uint256 priceWeiPerItem2,
        string memory paymentMethodName
    ) internal {
        uint256 totalWei =
            nrOfItems1 * priceWeiPerItem1 +
            nrOfItems2 * priceWeiPerItem2;
        if (totalWei == 0) {
            return;
        }
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(nameHash == WEI_PAYMENT_METHOD_HASH ||
                _paymentMethodExists(nameHash), "PH:MNS");
        if (nameHash == WEI_PAYMENT_METHOD_HASH) {
            _handleWeiPayment(totalWei);
        } else {
            _handleERC20Payment(totalWei, paymentMethodName);
        }
    }

    function _paymentMethodExists(bytes32 paymentMethodNameHash) private view returns (bool) {
        return __s().erc20PaymentMethods[paymentMethodNameHash].addr != address(0) &&
               __s().erc20PaymentMethods[paymentMethodNameHash].wethPair != address(0) &&
               __s().erc20PaymentMethods[paymentMethodNameHash].enabled;
    }

    function _handleWeiPayment(
        uint256 priceWeiToPay
    ) private {
        require(msg.value >= priceWeiToPay, "PH:IF");
        uint256 remainder = msg.value - priceWeiToPay;
        if (__s().payoutAddress != address(0)) {
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = __s().payoutAddress.call{value: priceWeiToPay}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "PH:TF");
            emit WeiPayment(msg.sender, __s().payoutAddress, priceWeiToPay);
        } else {
            emit WeiPayment(msg.sender, address(this), priceWeiToPay);
        }
        if (remainder > 0) {
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = msg.sender.call{value: remainder}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "PH:RTF");
        }
    }

    function _handleERC20Payment(
        uint256 priceWeiToPay,
        string memory paymentMethodName
    ) private {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        PaymentHandlerStorage.ERC20PaymentMethodInfo memory paymentMethod =
            __s().erc20PaymentMethods[nameHash];
        (uint112 amount0, uint112 amount1,) = IUniswapV2Pair(paymentMethod.wethPair).getReserves();
        uint256 reserveWei = amount0;
        uint256 reserveTokens = amount1;
        if (paymentMethod.reverseIndices) {
            reserveWei = amount1;
            reserveTokens = amount0;
        }
        require(reserveWei > 0, "PH:NWR");
        uint256 amountTokens = (priceWeiToPay * reserveTokens) / reserveWei;
        address dest = address(this);
        if (__s().payoutAddress != address(0)) {
            dest = __s().payoutAddress;
        }
        // this contract must have already been approved by the msg.sender
        IERC20(paymentMethod.addr).transferFrom(msg.sender, dest, amountTokens);
        emit ERC20Payment(paymentMethodName, msg.sender, dest, priceWeiToPay, amountTokens);
    }

    function __s() private pure returns (PaymentHandlerStorage.Layout storage) {
        return PaymentHandlerStorage.layout();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
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

interface IUniswapV2Pair {
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

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
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
library PaymentHandlerStorage {

    struct ERC20PaymentMethodInfo {
        address addr;
        // Uniswap V2 Pair
        address wethPair;
        bool reverseIndices;
        bool enabled;
    }

    struct Layout {
        address payoutAddress;
        address wethAddress;
        string[] erc20PaymentMethodNames;
        mapping(bytes32 => ERC20PaymentMethodInfo) erc20PaymentMethods;
        mapping(uint256 => uint256) extra;
    }

    // Storage Slot: a0efacd423120980dd05e5b29c20ccdcbe1b82d6c1e2453fa01907429f24d423
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-io.collections.v2.payment-handler.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
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