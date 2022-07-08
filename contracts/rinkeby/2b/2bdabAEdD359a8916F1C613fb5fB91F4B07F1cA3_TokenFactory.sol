//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 <0.9.0;

import './ITokenFactory.sol';
import './Token.sol';


contract TokenFactory is ITokenFactory, Ownable{

    Token[] public _allTokens;

    event TokenCreated(string indexed symbol, address indexed tokenAddress, uint);

    constructor() {
        owner = msg.sender;
    }

    function allTokensLength() public view override returns (uint) {
        return _allTokens.length;
    }

    function createToken(uint totalSupply, string memory name, string memory symbol, uint8 decimals) public override onlyOwner returns(address) {
        require(totalSupply != 0);
        require(decimals != 0);

        Token tokenAddress = new Token(totalSupply, name, symbol, decimals);
        _allTokens.push(tokenAddress);
        emit TokenCreated(symbol, address(tokenAddress), _allTokens.length);

        Token(tokenAddress).changeOwner(msg.sender);
        Token(tokenAddress).changeMinter(msg.sender);

        return address(tokenAddress);
    }


    function getToken() public view returns(Token[] memory _token){
        _token = new Token[](_allTokens.length);
        uint count;
        for(uint i=0;i<_allTokens.length; i++){
            _token[count] = _allTokens[i];
            count++;
        }
    }
}