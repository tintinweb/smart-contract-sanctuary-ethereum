/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// File contracts/actions/Receiver.sol

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

contract Receiver {
    address public smartVault;

    event Executed();

    constructor(address _smartVault) {
        smartVault = _smartVault;
    }

    receive() external payable {
        // solhint-disable-previous-line no-empty-blocks
    }

    function call() external {
        uint256 balance = address(this).balance;
        require(balance > 0, 'RECEIVER_BALANCE_ZERO');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = smartVault.call{ value: balance }('');
        require(success, 'RECEIVER_SEND_VALUE_FAILED');
        emit Executed();
    }
}