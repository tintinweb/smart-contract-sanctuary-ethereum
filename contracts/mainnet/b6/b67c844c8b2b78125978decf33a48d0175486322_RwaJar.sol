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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.12;

import "dss-interfaces/dss/DaiJoinAbstract.sol";
import "dss-interfaces/dss/DaiAbstract.sol";
import "dss-interfaces/dss/ChainlogAbstract.sol";

/**
 * @author Henrique Barcelos <[email protected]>
 * @title RwaJar: Facility to allow stability fee payments into the Surplus Buffer.
 * @dev Users can either send Dai directly to this conract or approve it to pull Dai from their wallet.
 */
contract RwaJar {
    /// @notice The DaiJoin adapter from MCD.
    DaiJoinAbstract public immutable daiJoin;
    /// @notice The Dai token.
    DaiAbstract public immutable dai;
    /// @notice The Chainlog from MCD.
    ChainlogAbstract public immutable chainlog;

    /**
     * @notice Emitted whenever Dai is sent to the `vow`.
     * @param usr The origin of the funds.
     * @param wad The amount of Dai sent.
     */
    event Toss(address indexed usr, uint256 wad);

    /**
     * @dev The Dai address is obtained from the DaiJoin contract.
     * @param chainlog_ The chainlog from MCD.
     */
    constructor(address chainlog_) public {
        address daiJoin_ = ChainlogAbstract(chainlog_).getAddress("MCD_JOIN_DAI");

        // DaiJoin and Dai are meant to be immutable, so we can store them.
        daiJoin = DaiJoinAbstract(daiJoin_);
        dai = DaiAbstract(DaiJoinAbstract(daiJoin_).dai());

        // We also store the chainlog to get the Vow address on-demand.
        chainlog = ChainlogAbstract(chainlog_);

        DaiAbstract(DaiJoinAbstract(daiJoin_).dai()).approve(daiJoin_, type(uint256).max);
    }

    /**
     * @notice Transfers any outstanding Dai balance in this contract to the `vow`.
     * @dev Reverts if there Dai balance of this contract is zero.
     * @dev This effectively burns ERC-20 Dai and credits it to the internal Dai balance of the `vow` in the Vat.
     */
    function void() external {
        uint256 balance = dai.balanceOf(address(this));
        require(balance > 0, "RwaJar/already-empty");

        daiJoin.join(chainlog.getAddress("MCD_VOW"), balance);

        emit Toss(address(this), balance);
    }

    /**
     * @notice Pulls `wad` amount of Dai from the sender's wallet into the `vow`.
     * @dev Requires `msg.sender` to have previously `approve`d this contract to spend at least `wad` Dai.
     * @dev This effectively burns ERC-20 Dai and credits it to the internal Dai balance of the `vow` in the Vat.
     * @param wad The amount of Dai.
     */
    function toss(uint256 wad) external {
        dai.transferFrom(msg.sender, address(this), wad);
        daiJoin.join(chainlog.getAddress("MCD_VOW"), wad);

        emit Toss(msg.sender, wad);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

// https://github.com/makerdao/dss/blob/master/src/join.sol
interface DaiJoinAbstract {
    function wards(address) external view returns (uint256);
    function rely(address usr) external;
    function deny(address usr) external;
    function vat() external view returns (address);
    function dai() external view returns (address);
    function live() external view returns (uint256);
    function cage() external;
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

// https://github.com/makerdao/dss/blob/master/src/dai.sol
interface DaiAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function version() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function nonces(address) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function approve(address, uint256) external returns (bool);
    function push(address, uint256) external;
    function pull(address, uint256) external;
    function move(address, address, uint256) external;
    function permit(address, address, uint256, uint256, bool, uint8, bytes32, bytes32) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

// https://github.com/makerdao/dss-chain-log
interface ChainlogAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function keys() external view returns (bytes32[] memory);
    function version() external view returns (string memory);
    function ipfs() external view returns (string memory);
    function setVersion(string calldata) external;
    function setSha256sum(string calldata) external;
    function setIPFS(string calldata) external;
    function setAddress(bytes32,address) external;
    function removeAddress(bytes32) external;
    function count() external view returns (uint256);
    function get(uint256) external view returns (bytes32,address);
    function list() external view returns (bytes32[] memory);
    function getAddress(bytes32) external view returns (address);
}

// Helper function for returning address or abstract of Chainlog
//  Valid on Mainnet, Kovan, Rinkeby, Ropsten, and Goerli
contract ChainlogHelper {
    address          public constant ADDRESS  = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;
    ChainlogAbstract public constant ABSTRACT = ChainlogAbstract(ADDRESS);
}