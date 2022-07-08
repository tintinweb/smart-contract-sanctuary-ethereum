//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 <0.9.0;

import './ITokenFactory.sol';
import './Token.sol';


contract TokenFactory is ITokenFactory, Ownable{

    Token[] public allTokens;

    event TokenCreated(string indexed symbol, address indexed tokenAddress, uint);

    constructor() {
        owner = msg.sender;
    }

    function allTokensLength() public view override returns (uint) {
        return allTokens.length;
    }

    function createToken(uint initialSupply, string memory name, string memory symbol, uint8 decimals) public override onlyOwner returns(address) {
        require(initialSupply != 0);
        require(decimals != 0);
        // bytes memory bytecode = type(Token).creationCode;
        // bytes32 salt = keccak256(abi.encodePacked(initialSupply, name, symbol, decimals));
        // assembly {
        //     tokenAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        // }
        // Token(tokenAddress).init(initialSupply, name, symbol, decimals);
        Token tokenAddress = new Token(initialSupply, name, symbol, decimals);
        allTokens.push(tokenAddress);
        emit TokenCreated(symbol, address(tokenAddress), allTokens.length);

        return address(tokenAddress);
    }


    function getToken() public view returns(Token[] memory _token){
        _token = new Token[](allTokens.length);
        uint count;
        for(uint i=0;i<allTokens.length; i++){
            _token[count] = allTokens[i];
            count++;
        }
    }
}




// contract TokenFactory is Ownable{

//     Token[] public allTokens;

//     // event TokenCreated(string indexed symbol, address indexed tokenAddress, uint);

//     constructor() {
//         owner = msg.sender;
//     }

//     function allTokensLength() public view override returns (uint) {
//         return allTokens.length;
//     }

//     function createToken(uint initialSupply, string memory name, string memory symbol, uint8 decimals) public onlyOwner returns (address) {
        
//         Token token = new Token(initialSupply, name, symbol, decimals);
//         allTokens.push(token);
//         // emit TokenCreated(symbol, tokenAddress.address, allTokens.length);
//     }
// }