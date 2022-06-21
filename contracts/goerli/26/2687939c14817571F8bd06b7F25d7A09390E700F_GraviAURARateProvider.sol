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

import "./interfaces/IRateProvider.sol";
import "./interfaces/IVault.sol";

/**
 * @title graviAURA Rate Provider
 * @notice Returns the value of graviAURA in terms of AURA
 */
contract GraviAURARateProvider is IRateProvider {
    IVault public immutable graviAURA;

    constructor(IVault _graviAURA) {
        graviAURA = _graviAURA;
    }

    /**
     * @return the value of graviAURA in terms of AURA
     */
    function getRate() external view override returns (uint256) {
        return graviAURA.getPricePerFullShare();
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVault {

    function getPricePerFullShare() external view returns (uint256);
}