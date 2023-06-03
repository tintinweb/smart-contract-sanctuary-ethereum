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

import "../../../diamond/IDiamondFacet.sol";
import "../../hasher/HasherLib.sol";
import "../../reentrancy-lock/ReentrancyLockLib.sol";
import "./IFiatHandler.sol";
import "./FiatHandlerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract FiatHandlerFacet is IDiamondFacet, IFiatHandler {

    modifier reentrancyProtected {
        ReentrancyLockLib._engageLock(HasherLib._hashStr("GLOBAL"));
        _;
        ReentrancyLockLib._releaseLock(HasherLib._hashStr("GLOBAL"));
    }

    function getFacetName()
      external pure override returns (string memory) {
        return "fiat-handler";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "1.2.0";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](14);
        pi[ 0] = "convertMicroUSDToWei(uint256)";
        pi[ 1] = "convertWeiToMicroUSD(uint256)";
        pi[ 2] = "convertMicroUSDToERC20(address,uint256)";
        pi[ 3] = "convertERC20ToMicroUSD(address,uint256)";
        pi[ 4] = "calcDiscount(address,uint256)";
        pi[ 5] = "initializeFiatHandler(address,address,address,uint256)";
        pi[ 6] = "getFiatHandlerSettings()";
        pi[ 7] = "setFiatHandlerSettings(address,address,address,uint256)";
        pi[ 8] = "getDiscount(address)";
        pi[ 9] = "setDiscount(address,bool,bool,uint256,uint256)";
        pi[10] = "isErc20Allowed(address)";
        pi[11] = "setErc20Allowed(address,bool)";
        pi[12] = "getListOfErc20s()";
        pi[13] = "transferTo(address,address,uint256,string)";
        return pi;
    }

    function getFacetProtectedPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](4);
        pi[ 0] = "setFiatHandlerSettings(address,address,address,uint256)";
        pi[ 1] = "setDiscount(address,bool,bool,uint256,uint256)";
        pi[ 2] = "setErc20Allowed(address,bool)";
        pi[ 3] = "transferTo(address,address,uint256,string)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return
            interfaceId == type(IDiamondFacet).interfaceId ||
            interfaceId == type(IFiatHandler).interfaceId;
    }

    function convertMicroUSDToWei(uint256 microUSDAmount) external view returns (uint256) {
        return FiatHandlerInternal._convertMicroUSDToWei(microUSDAmount);
    }

    function convertWeiToMicroUSD(uint256 weiAmount) external view returns (uint256) {
        return FiatHandlerInternal._convertWeiToMicroUSD(weiAmount);
    }

    function convertMicroUSDToERC20(
        address erc20,
        uint256 microUSDAmount
    ) external view returns (uint256) {
        return FiatHandlerInternal._convertMicroUSDToERC20(erc20, microUSDAmount);
    }

    function convertERC20ToMicroUSD(
        address erc20,
        uint256 tokensAmount
    ) external view returns (uint256) {
        return FiatHandlerInternal._convertERC20ToMicroUSD(erc20, tokensAmount);
    }

    function calcDiscount(
        address erc20,
        uint256 amount
    ) external view returns (uint256) {
        return FiatHandlerInternal._calcDiscount(erc20, amount);
    }

    function initializeFiatHandler(
        address uniswapV2Factory,
        address wethAddress,
        address microUSDAddress,
        uint256 maxNegativeSlippage
    ) external override {
        FiatHandlerInternal._initialize(
            uniswapV2Factory,
            wethAddress,
            microUSDAddress,
            maxNegativeSlippage
        );
    }

    function getFiatHandlerSettings()
    external view returns (
        address, // uniswapV2Factory
        address, // wethAddress
        address, // microUSDAddress
        uint256  // maxNegativeSlippage
    ) {
        return FiatHandlerInternal._getFiatHandlerSettings();
    }

    function setFiatHandlerSettings(
        address uniswapV2Factory,
        address wethAddress,
        address microUSDAddress,
        uint256 maxNegativeSlippage
    ) external {
        FiatHandlerInternal._setFiatHandlerSettings(
            uniswapV2Factory,
            wethAddress,
            microUSDAddress,
            maxNegativeSlippage
        );
    }

    function getDiscount(address erc20)
    external view returns (bool, bool, uint256, uint256) {
        return FiatHandlerInternal._getDiscount(erc20);
    }

    function setDiscount(
        address erc20,
        bool enabled,
        bool useFixed,
        uint256 discountF,
        uint256 discountP
    ) external {
        FiatHandlerInternal._setDiscount(
            erc20,
            enabled,
            useFixed,
            discountF,
            discountP
        );
    }

    function getListOfErc20s() external view returns (address[] memory) {
        return FiatHandlerInternal._getListOfErc20s();
    }

    function isErc20Allowed(address erc20) external view returns (bool) {
        return FiatHandlerInternal._isErc20Allowed(erc20);
    }

    function setErc20Allowed(address erc20, bool allowed) external {
        FiatHandlerInternal._setErc20Allowed(erc20, allowed);
    }

    function transferTo(
        address erc20,
        address to,
        uint256 amount,
        string memory data
    ) external reentrancyProtected {
        FiatHandlerInternal._transferTo(erc20, to, amount, data);
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
interface IFiatHandler {

    function initializeFiatHandler(
        address uniswapV2Factory,
        address wethAddress,
        address microUSDAddress,
        uint256 maxNegativeSlippage
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