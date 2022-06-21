/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// Copyright (C) 2018-2020 Maker Ecosystem Growth Holdings, INC.

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

pragma solidity 0.6.7;

abstract contract SAFEEngineLike {
    function safes(bytes32, address) virtual public view returns (uint, uint);
    function approveSAFEModification(address) virtual public;
    function transferCollateral(bytes32, address, address, uint) virtual public;
    function transferInternalCoins(address, address, uint) virtual public;
    function modifySAFECollateralization(bytes32, address, address, address, int, int) virtual public;
    function transferSAFECollateralAndDebt(bytes32, address, address, int, int) virtual public;
}

contract SAFEHandler {
    constructor(address safeEngine) public {
        SAFEEngineLike(safeEngine).approveSAFEModification(msg.sender);
    }
}