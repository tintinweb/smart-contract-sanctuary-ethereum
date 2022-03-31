// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.9;
pragma abicoder v2;

import { ERC20 } from "../../shared/ERC20.sol";
import { Component } from "../../shared/Structs.sol";
import { TokenAdapter } from "../TokenAdapter.sol";
import { Helpers } from "../../shared/Helpers.sol";
import { UniswapV2Pair } from "../../interfaces/UniswapV2Pair.sol";

/**
 * @title Token adapter for Uniswap V2 Pool Tokens.
 * @dev Implementation of TokenAdapter abstract contract.
 * @author Igor Sobolev <[email protected]>
 */
contract UniswapV2TokenAdapter is TokenAdapter {
    using Helpers for bytes32;

    /**
     * @return Array of Component structs with underlying tokens rates for the given token.
     * @dev Implementation of TokenAdapter abstract contract function.
     */
    function getComponents(address token) external view override returns (Component[] memory) {
        address[] memory tokens = new address[](2);
        tokens[0] = UniswapV2Pair(token).token0();
        tokens[1] = UniswapV2Pair(token).token1();
        uint256 totalSupply = ERC20(token).totalSupply();

        Component[] memory components = new Component[](2);

        for (uint256 i = 0; i < 2; i++) {
            components[i] = Component({
                token: tokens[i],
                rate: int256((ERC20(tokens[i]).balanceOf(token) * 1e18) / totalSupply)
            });
        }

        return components;
    }

    /**
     * @return Pool name.
     */
    function getName(address token) internal view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    getUnderlyingSymbol(UniswapV2Pair(token).token0()),
                    "/",
                    getUnderlyingSymbol(UniswapV2Pair(token).token1()),
                    " Pool"
                )
            );
    }

    function getUnderlyingSymbol(address token) internal view returns (string memory) {
        (, bytes memory returnData) = token.staticcall(
            abi.encodeWithSelector(ERC20(token).symbol.selector)
        );

        if (returnData.length == 32) {
            return abi.decode(returnData, (bytes32)).toString();
        } else {
            return abi.decode(returnData, (string));
        }
    }
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.9;
pragma abicoder v2;

// The struct consists of TokenBalanceMeta structs for
// (base) token and its underlying tokens (if any).
struct FullTokenBalance {
    TokenBalanceMeta base;
    TokenBalanceMeta[] underlying;
}

// The struct consists of TokenBalance struct
// with token address and absolute amount
// and ERC20Metadata struct with ERC20-style metadata.
// NOTE: 0xEeee...EEeE address is used for ETH.
struct TokenBalanceMeta {
    TokenBalance tokenBalance;
    ERC20Metadata erc20metadata;
}

// The struct consists of ERC20-style token metadata.
struct ERC20Metadata {
    string name;
    string symbol;
    uint8 decimals;
}

// The struct consists of protocol adapter's name
// and array of TokenBalance structs
// with token addresses and absolute amounts.
struct AdapterBalance {
    bytes32 protocolAdapterName;
    TokenBalance[] tokenBalances;
}

// The struct consists of token address
// and its absolute amount (may be negative).
// 0xEeee...EEeE is used for Ether
struct TokenBalance {
    address token;
    int256 amount;
}

// The struct consists of token address,
// and price per full share (1e18).
// 0xEeee...EEeE is used for Ether
struct Component {
    address token;
    int256 rate;
}

//=============================== Interactive Adapters Structs ====================================

// The struct consists of array of actions, array of inputs,
// fee, array of required outputs, account,
// and salt parameter used to protect users from double spends.
struct TransactionData {
    Action[] actions;
    TokenAmount[] inputs;
    Fee fee;
    AbsoluteTokenAmount[] requiredOutputs;
    address account;
    uint256 salt;
}

// The struct consists of name of the protocol adapter,
// action type, array of token amounts,
// and some additional data (depends on the protocol).
struct Action {
    bytes32 protocolAdapterName;
    ActionType actionType;
    TokenAmount[] tokenAmounts;
    bytes data;
}

// The struct consists of token address
// its amount and amount type.
// 0xEeee...EEeE is used for Ether
struct TokenAmount {
    address token;
    uint256 amount;
    AmountType amountType;
}

// The struct consists of fee share
// and beneficiary address.
struct Fee {
    uint256 share;
    address beneficiary;
}

// The struct consists of token address
// and its absolute amount.
// 0xEeee...EEeE is used for Ether
struct AbsoluteTokenAmount {
    address token;
    uint256 amount;
}

enum ActionType {
    None,
    Deposit,
    Withdraw
}

enum AmountType {
    None,
    Relative,
    Absolute
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.9;
pragma abicoder v2;

/**
 * @notice Library helps to convert different types to strings.
 * @author Igor Sobolev <[email protected]>
 */
library Helpers {
    /**
     * @dev Internal function to convert bytes32 to string and trim zeroes.
     */
    function toString(bytes32 data) internal pure returns (string memory) {
        uint256 counter = 0;
        for (uint256 i = 0; i < 32; i++) {
            if (data[i] != bytes1(0)) {
                counter++;
            }
        }

        bytes memory result = new bytes(counter);
        counter = 0;
        for (uint256 i = 0; i < 32; i++) {
            if (data[i] != bytes1(0)) {
                result[counter] = data[i];
                counter++;
            }
        }

        return string(result);
    }

    /**
     * @dev Internal function to convert uint256 to string.
     */
    function toString(uint256 data) internal pure returns (string memory) {
        if (data == uint256(0)) {
            return "0";
        }

        uint256 length = 0;

        uint256 dataCopy = data;
        while (dataCopy != 0) {
            length++;
            dataCopy /= 10;
        }

        bytes memory result = new bytes(length);
        dataCopy = data;

        // Here, we have on-purpose underflow cause we need case `i = 0` to be included in the loop
        for (uint256 i = length - 1; i < length; i--) {
            result[i] = bytes1(uint8(48 + (dataCopy % 10)));
            dataCopy /= 10;
        }

        return string(result);
    }

    /**
     * @dev Internal function to convert address to string.
     */
    function toString(address data) internal pure returns (string memory) {
        bytes memory bytesData = abi.encodePacked(data);

        bytes memory result = new bytes(42);
        result[0] = "0";
        result[1] = "x";

        for (uint256 i = 0; i < 20; i++) {
            result[i * 2 + 2] = char(bytesData[i] >> 4); // First char of byte
            result[i * 2 + 3] = char(bytesData[i] & 0x0f); // Second char of byte
        }

        return string(result);
    }

    function char(bytes1 byteChar) internal pure returns (bytes1) {
        uint8 uintChar = uint8(byteChar);
        return uintChar < 10 ? bytes1(uintChar + 48) : bytes1(uintChar + 87);
    }
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.9;
pragma abicoder v2;

interface ERC20 {
    function approve(address, uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.9;

/**
 * @dev UniswapV2Pair contract interface.
 * The UniswapV2Pair contract is available here
 * github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2Pair.sol.
 */
interface UniswapV2Pair {
    function mint(address) external returns (uint256);

    function burn(address) external returns (uint256, uint256);

    function getReserves() external view returns (uint112, uint112);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.9;
pragma abicoder v2;

import { ERC20 } from "../shared/ERC20.sol";
import { ERC20Metadata, Component } from "../shared/Structs.sol";

/**
 * @title Token adapter abstract contract.
 * @dev getComponents() function MUST be implemented.
 * getName(), getSymbol(), getDecimals() functions
 * or getMetadata() function may be overridden.
 * @author Igor Sobolev <[email protected]>
 */
abstract contract TokenAdapter {
    /**
     * @dev MUST return array of Component structs with underlying tokens rates for the given token.
     * struct Component {
     *     address token;    // Address of token contract
     *     uint256 rate;     // Price per share (1e18)
     * }
     */
    function getComponents(address token) external virtual returns (Component[] memory);

    /**
     * @return ERC20Metadata struct with ERC20-style token info.
     * @dev It is recommended to override getName(), getSymbol(), and getDecimals() functions.
     * struct ERC20Metadata {
     *     string name;
     *     string symbol;
     *     uint8 decimals;
     * }
     */
    function getMetadata(address token) public view virtual returns (ERC20Metadata memory) {
        return
            ERC20Metadata({
                name: getName(token),
                symbol: getSymbol(token),
                decimals: getDecimals(token)
            });
    }

    /**
     * @return String that will be treated like token name.
     */
    function getName(address token) internal view virtual returns (string memory) {
        return ERC20(token).name();
    }

    /**
     * @return String that will be treated like token symbol.
     */
    function getSymbol(address token) internal view virtual returns (string memory) {
        return ERC20(token).symbol();
    }

    /**
     * @return Number (of uint8 type) that will be treated like token decimals.
     */
    function getDecimals(address token) internal view virtual returns (uint8) {
        return ERC20(token).decimals();
    }
}