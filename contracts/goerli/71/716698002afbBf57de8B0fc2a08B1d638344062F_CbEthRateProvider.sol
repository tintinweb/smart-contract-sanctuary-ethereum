// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IcbETH.sol";
import "./interfaces/IRateProvider.sol";

/**
 * @title Coinbase wrapped staked Eth Rate Provider
 * @notice Returns value of cbEth in terms of Eth.
 * cbEth is built on Coinbase's wrapped token contract.
 * https://github.com/coinbase/wrapped-tokens-os. Coinbase
 * controls the oracle's address and updates exchangeRate
 * every 24 hours at 4pm UTC. This update cadende may change
 * in the future.
 */
contract CbEthRateProvider is IRateProvider {
    IcbETH public immutable cbETH;

    constructor(IcbETH _cbETH) {
        cbETH = _cbETH;
    }

    /**
     * @return value of cbETH in terms of Eth scaled by 10**18
     */
    function getRate() public view override returns (uint256) {
        return cbETH.exchangeRate();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Coinbase Staked ETH interface to return exchangeRate
 */
interface IcbETH {
    /**
     * @notice get exchange rate
     * @return Returns the current exchange rate scaled by by 10**18
     */
    function exchangeRate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

// TODO: pull this from the monorepo
interface IRateProvider {
    function getRate() external view returns (uint256);
}