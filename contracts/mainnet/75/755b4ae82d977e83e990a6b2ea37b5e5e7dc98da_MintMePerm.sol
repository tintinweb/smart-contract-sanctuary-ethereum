/*
This file is part of the MintMe project.

The MintMe Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The MintMe Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the MintMe Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <[email protected]>
*/
// SPDX-License-Identifier: GNU lesser General Public License

pragma solidity ^0.8.0;

import "./mintme.sol";


contract MintMePerm is Ownable
{
    event Deployed();
    event Hidden(address indexed mintme);
    event Unhidden(address indexed mintme);
    event Banned(address indexed mintme);
    event Unbanned(address indexed mintme);

    mapping (address => bool) public _hidden;
    mapping (address => bool) public _banned;

    constructor ()
    {
        emit Deployed();
    }

    function hide(address mintme) public
    {
        require(Ownable(mintme).owner() == _msgSender(), "MintMePerm: only owner can change visibility");
        _hidden[mintme] = true;
        emit Hidden(mintme);
    }

    function unhide(address mintme) public
    {
        require(Ownable(mintme).owner() == _msgSender(), "MintMePerm: only owner can change visibility");
        _hidden[mintme] = false;
        emit Unhidden(mintme);
    }

    function ban(address mintme) public onlyOwner
    {
        _banned[mintme] = true;
        emit Banned(mintme);
    }

    function unban(address mintme) public onlyOwner
    {
        _banned[mintme] = true;
        emit Unbanned(mintme);
    }
}