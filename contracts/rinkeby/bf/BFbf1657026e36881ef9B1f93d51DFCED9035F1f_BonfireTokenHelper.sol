// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

library BonfireTokenHelper {
    string constant _totalSupply = "totalSupply()";
    string constant _circulatingSupply = "circulatingSupply()";
    string constant _token = "sourceToken()";
    string constant _wrapper = "wrapper()";
    bytes constant SUPPLY = abi.encodeWithSignature(_totalSupply);
    bytes constant CIRCULATING = abi.encodeWithSignature(_circulatingSupply);
    bytes constant TOKEN = abi.encodeWithSignature(_token);
    bytes constant WRAPPER = abi.encodeWithSignature(_wrapper);

    function circulatingSupply(address token)
        external
        view
        returns (uint256 supply)
    {
        (bool _success, bytes memory data) = token.staticcall(CIRCULATING);
        if (!_success) {
            (_success, data) = token.staticcall(SUPPLY);
        }
        if (_success) {
            supply = abi.decode(data, (uint256));
        }
    }

    function getSourceToken(address proxyToken)
        external
        view
        returns (address sourceToken)
    {
        (bool _success, bytes memory data) = proxyToken.staticcall(TOKEN);
        if (_success) {
            sourceToken = abi.decode(data, (address));
        }
    }

    function getWrapper(address proxyToken)
        external
        view
        returns (address wrapper)
    {
        (bool _success, bytes memory data) = proxyToken.staticcall(WRAPPER);
        if (_success) {
            wrapper = abi.decode(data, (address));
        }
    }
}