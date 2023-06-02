// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
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
pragma solidity ^0.6.12;

library Strings {
    /**
     * @dev Concatenates 2 strings together.
     * @param s1 The 1st string.
     * @param s2 The 2nd string.
     * @return The concatenated string.
     */
    function concat(string memory s1, string memory s2) external pure returns (string memory) {
        return string(abi.encodePacked(s1, s2));
    }

    /**
     * @dev Concatenates 2 strings together with a separator.
     * @param s1 The 1st string.
     * @param s2 The 2nd string.
     * @param sep The separator
     * @return The concatenated string.
     */
    function concat(
        string memory s1,
        string memory s2,
        string memory sep
    ) external pure returns (string memory) {
        return string(abi.encodePacked(s1, sep, s2));
    }

    /**
     * @dev Checks whether a string is empty or not.
     * @param s The string.
     * @return The concatenated string.
     */
    function isEmpty(string memory s) external pure returns (bool) {
        return bytes(s).length == 0;
    }
}