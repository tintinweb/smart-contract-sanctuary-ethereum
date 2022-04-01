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
import { ProtocolAdapter } from "../ProtocolAdapter.sol";
import { CToken } from "../../interfaces/CToken.sol";
import { CompoundRegistry } from "./CompoundRegistry.sol";

/**
 * @title Debt adapter for Compound protocol.
 * @dev Implementation of ProtocolAdapter abstract contract.
 * @author Igor Sobolev <[email protected]>
 */
contract CompoundDebtAdapter is ProtocolAdapter {
    address internal constant REGISTRY = 0xD0ff11EA62C867F6dF8E9cc37bb5339107FAb141;

    /**
     * @return Amount of debt of the given account for the protocol.
     * @dev Implementation of ProtocolAdapter abstract contract function.
     */
    function getBalance(address token, address account) public override returns (int256) {
        CToken cToken = CToken(CompoundRegistry(REGISTRY).getCToken(token));

        return int256(type(uint256).max - cToken.borrowBalanceCurrent(account) + 1);
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
 * @dev CToken contract interface.
 * The CToken contract is available here
 * github.com/compound-finance/compound-protocol/blob/master/contracts/CToken.sol.
 */
interface CToken {
    function borrowBalanceCurrent(address) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function mint(uint256) external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function borrowBalanceStored(address) external view returns (uint256);

    function underlying() external view returns (address);

    function borrowIndex() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);
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
 * @title Registry for Compound contracts.
 * @dev Implements the only function - getCToken(address).
 * @notice Call getCToken(token) function and get address
 * of CToken contract for the given token address.
 * @author Igor Sobolev <[email protected]>
 */
contract CompoundRegistry {
    mapping(address => address) internal cTokens;

    constructor() {
        cTokens[
            0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359
        ] = 0xF5DCe57282A584D2746FaF1593d3121Fcac444dC;
        cTokens[
            0x1985365e9f78359a9B6AD760e32412f4a445E862
        ] = 0x158079Ee67Fce2f58472A96584A73C7Ab9AC95c1;
        cTokens[
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
        ] = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
        cTokens[
            0x6B175474E89094C44Da98b954EedeAC495271d0F
        ] = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
        cTokens[
            0x0D8775F648430679A709E98d2b0Cb6250d2887EF
        ] = 0x6C8c6b02E7b2BE14d4fA6022Dfd6d75921D90E4E;
        cTokens[
            0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
        ] = 0xC11b1268C1A384e55C48c2391d8d480264A3A7F4;
        cTokens[
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        ] = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;
        cTokens[
            0xE41d2489571d322189246DaFA5ebDe1F4699F498
        ] = 0xB3319f5D18Bc0D84dD1b4825Dcde5d5f7266d407;
    }

    function getCToken(address token) external view returns (address) {
        return cTokens[token];
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

/**
 * @title Protocol adapter abstract contract.
 * @dev adapterType(), tokenType(), and getBalance() functions MUST be implemented.
 * @author Igor Sobolev <[email protected]>
 */
abstract contract ProtocolAdapter {
    /**
     * @dev MUST return amount and type of the given token
     * locked on the protocol by the given account.
     */
    function getBalance(address token, address account) public virtual returns (int256);
}