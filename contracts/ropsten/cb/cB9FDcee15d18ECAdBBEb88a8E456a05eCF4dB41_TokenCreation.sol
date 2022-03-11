/*
This file is part of the DAO.

The DAO is free software: you can redistribute it and/or modify
it under the terms of the GNU lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The DAO is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the DAO.  If not, see <http://www.gnu.org/licenses/>.
*/


/*
 * Token Creation contract, used by the DAO to create its tokens and initialize
 * its ether. Feel free to modify the divisor method to implement different
 * Token Creation parameters
*/

import "./Token.sol";

pragma solidity ^0.4.4;

contract TokenCreationInterface {
    /// @dev Constructor setting the minimum fueling goal and the
    /// end of the Token Creation
    /// (the address can also create Tokens on behalf of other accounts)
    // This is the constructor: it can not be overloaded so it is commented out
    //  function TokenCreation(
        //  string _tokenName,
        //  string _tokenSymbol,
        //  uint _decimalPlaces
    //  );

    /// @notice Create Token with `_tokenHolder` as the initial owner of the Token
    /// @param _tokenHolder The address of the Tokens's recipient
    /// @return Whether the token creation was successful
    function createTokenProxy(address _tokenHolder) payable returns (bool success);
    event CreatedToken(address indexed to, uint amount);
}


contract TokenCreation is TokenCreationInterface, Token {
    function TokenCreation(
        string _tokenName,
        string _tokenSymbol,
        uint _decimalPlaces,
        Plutocracy _plutocracy) Token(_plutocracy) {
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalPlaces;
    }

    function createTokenProxy(address _tokenHolder) payable returns (bool success) {
        if (msg.value > 0 && this.balance + msg.value > 100000 ether) {
            balances[_tokenHolder] += msg.value;
            totalSupply += msg.value;
            CreatedToken(_tokenHolder, msg.value);
            return true;
        }
        throw;
    }
}