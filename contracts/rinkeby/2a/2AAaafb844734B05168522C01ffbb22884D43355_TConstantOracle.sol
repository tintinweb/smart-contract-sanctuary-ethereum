// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.12;

contract TConstantOracle {

    uint256 private timestamp;

    uint80 private latestRoundId = 1;
    uint8 private _decimals;
    int256 private _precision = 100000000;

    mapping(uint80 => int256) public prices;

    constructor(int256 value_, uint8 decimals_) {
        prices[latestRoundId] = value_;
        _decimals = decimals_;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function description() public pure returns (string memory) {
        return "Constant";
    }

    function version() public pure returns (uint256) {
        return 1;
    }

    function latestRoundData()
    public
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        int256 a = prices[latestRoundId];
        return (latestRoundId, a, block.timestamp, block.timestamp, latestRoundId);
    }

}