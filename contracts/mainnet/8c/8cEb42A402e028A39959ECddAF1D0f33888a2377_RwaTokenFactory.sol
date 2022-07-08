/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// Copyright (C) 2022 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

//
// RwaToken.sol -- Collateral token for RWA
//
// Copyright (C) 2020-2021 Lev Livnev <[email protected]>
// Copyright (C) 2021-2022 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

contract RwaToken {
    // --- ERC20 Data ---
    string public name;
    string public symbol;

    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);

    // --- Math ---
    uint256 constant WAD = 10**18;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    constructor(string memory name_, string memory symbol_) public {
        balanceOf[msg.sender] = 1 * WAD;
        name = name_;
        symbol = symbol_;
        totalSupply = 1 * WAD;
    }

    // --- Token ---
    function transfer(address dst, uint256 wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        require(balanceOf[src] >= wad, "RwaToken/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(allowance[src][msg.sender] >= wad, "RwaToken/insufficient-allowance");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }

    function approve(address usr, uint256 wad) external returns (bool) {
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
        return true;
    }
}

/**
 * @author Nazar Duchak <[email protected]>
 * @title A Factory for RWA Tokens.
 */
contract RwaTokenFactory {
    uint256 internal constant WAD = 10**18;

    /// @notice registry for RWA tokens. `tokenAddresses[symbol]`
    mapping(bytes32 => address) public tokenAddresses;
    /// @notice list of created RWA token symbols.
    bytes32[] public tokens;

    /**
     * @notice RWA Token created.
     * @param name Token name.
     * @param symbol Token symbol.
     * @param recipient Token address recipient.
     */
    event RwaTokenCreated(string name, string indexed symbol, address indexed recipient);

    /**
     * @notice Deploy an RWA Token and mint `1 * WAD` to recipient address.
     * @dev History of created tokens are stored in `tokenData` which is publicly accessible
     * @param name Token name.
     * @param symbol Token symbol.
     * @param recipient Recipient address.
     */
    function createRwaToken(
        string calldata name,
        string calldata symbol,
        address recipient
    ) public returns (RwaToken) {
        require(recipient != address(0), "RwaTokenFactory/recipient-not-set");
        require(bytes(name).length != 0, "RwaTokenFactory/name-not-set");
        require(bytes(symbol).length != 0, "RwaTokenFactory/symbol-not-set");

        bytes32 _symbol = stringToBytes32(symbol);
        require(tokenAddresses[_symbol] == address(0), "RwaTokenFactory/symbol-already-exists");

        RwaToken token = new RwaToken(name, symbol);
        tokenAddresses[_symbol] = address(token);
        tokens.push(_symbol);

        token.transfer(recipient, 1 * WAD);

        emit RwaTokenCreated(name, symbol, recipient);
        return token;
    }

    /**
     * @notice Gets the number of RWA Tokens created by this factory.
     */
    function count() external view returns (uint256) {
        return tokens.length;
    }

    /**
     * @notice Gets the list of symbols of all RWA Tokens created by this factory.
     */
    function list() external view returns (bytes32[] memory) {
        return tokens;
    }

    /**
     * @notice Helper function for converting string to bytes32.
     * @dev If `source` is longer than 32 bytes (i.e.: 32 ASCII chars), then it will be truncated.
     * @param source String to convert.
     * @return result The numeric ASCII representation of `source`, up to 32 chars long.
     */
    function stringToBytes32(string calldata source) public pure returns (bytes32 result) {
        bytes memory sourceAsBytes = bytes(source);
        if (sourceAsBytes.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(sourceAsBytes, 32))
        }
    }
}