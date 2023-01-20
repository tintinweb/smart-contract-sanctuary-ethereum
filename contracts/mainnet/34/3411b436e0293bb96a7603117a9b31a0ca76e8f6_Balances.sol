/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IToken {
    function balanceOf(address) external view returns (uint256);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract Balances {
    struct TokenData {
        string _symbol;
        address _address;
        uint256 _balance;
        uint256 _decimals;
    }

    function getTokenInfo(address _user, address _address)
        public
        view
        returns (TokenData memory)
    {
        // check if token is actually a contract
        uint256 _tokenCode;
        assembly {
            _tokenCode := extcodesize(_address)
        }

        TokenData memory data;

        if (_tokenCode > 0) {
            IToken _contract = IToken(_address);

            data._address = _address;
            try _contract.balanceOf(_user) returns (uint256 _balance) {
                data._balance = _balance;
            } catch {}

            try _contract.symbol() returns (string memory _symbol) {
                data._symbol = _symbol;
            } catch {}

            try _contract.decimals() returns (uint8 _decimals) {
                data._decimals = _decimals;
            } catch {}
        }

        return data;
    }

    function balances(address[] calldata users, address[] calldata tokens)
        external
        view
        returns (TokenData[] memory)
    {
        TokenData[] memory data = new TokenData[](tokens.length * users.length);

        for (uint256 i = 0; i < users.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                uint256 addrIdx = j + tokens.length * i;
                if (tokens[j] != address(0x0)) {
                    data[addrIdx] = getTokenInfo(users[i], tokens[j]);
                } else {
                    TokenData memory _default;
                    data[addrIdx] = _default;
                }
            }
        }
        return data;
    }
}