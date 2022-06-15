/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

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

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;


struct TokenMetadata {
    address token;
    string name;
    string symbol;
    uint8 decimals;
}


struct Component {
    address token;
    string tokenType;  // "ERC20" by default
    uint256 rate;  // price per full share (1e18)
}


/**
 * @title Token adapter interface.
 * @dev getMetadata() and getComponents() functions MUST be implemented.
 * @author Igor Sobolev <[email protected]>
 */
interface TokenAdapter {

    /**
     * @dev MUST return TokenMetadata struct with ERC20-style token info.
     * struct TokenMetadata {
     *     address token;
     *     string name;
     *     string symbol;
     *     uint8 decimals;
     * }
     */
    function getMetadata(address token) external view returns (TokenMetadata memory);

    /**
     * @dev MUST return array of Component structs with underlying tokens rates for the given token.
     * struct Component {
     *     address token;    // Address of token contract
     *     string tokenType; // Token type ("ERC20" by default)
     *     uint256 rate;     // Price per share (1e18)
     * }
     */
    function getComponents(address token) external view returns (Component[] memory);
}


interface ERC20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}


/**
 * @dev Angle StableMasterFront contract interface.
 * The StableMasterFront contract is available here
 * https://github.com/AngleProtocol/angle-core/blob/main/contracts/stableMaster/StableMasterFront.sol
 */
interface StableMasterFront {
    function collateralMap(address) external view returns (
        address,
        address,
        address,
        address,
        uint256,
        uint256
    );
}

/**
 * @dev Angle SanToken contract interface.
 * The SanToken contract is available here
 * https://github.com/AngleProtocol/angle-core/blob/main/contracts/sanToken/SanToken.sol
 */
interface SanToken {
    function poolManager() external view returns (address);
}


/**
 * @title Token adapter for Angle sanToken.
 * @dev Implementation of TokenAdapter abstract contract.
 */
contract AngleTokenAdapter is TokenAdapter {
    address internal constant STABLE_MASTER = 0x5adDc89785D75C86aB939E9e15bfBBb7Fc086A87;

    /**
     * @return TokenMetadata struct with ERC20-style token info.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getMetadata(address token) external view override returns (TokenMetadata memory) {
        return TokenMetadata({
            token: token,
            name: ERC20(token).name(),
            symbol: ERC20(token).symbol(),
            decimals: ERC20(token).decimals()
        });
    }

    /**
     * @return Array of Component structs with underlying tokens rates for the given sanToken.
     * @dev Implementation of TokenAdapter abstract contract function.
     */
    function getComponents(address token) external view override returns (Component[] memory) {
        Component[] memory components = new Component[](1);

        address poolManager = SanToken(token).poolManager();
        (address underlyingToken, , , , , uint256 rate) =
            StableMasterFront(STABLE_MASTER).collateralMap(poolManager);

        components[0] = Component({ token: underlyingToken, tokenType: "ERC20", rate: rate });

        return components;
    }
}