//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 <0.9.0;

import './ITokenFactory.sol';
import './Token.sol';

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, a minter address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract FactoryOwnable {
    address public owner;

    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
    */
    constructor() {
        owner = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the owner.
      */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function changeOwner(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
        emit OwnerChanged(owner);
    }

    /**
     * @dev Emitted when the owner is changed
     */
    event OwnerChanged(address indexed owner);

}



contract TokenFactory is ITokenFactory, FactoryOwnable{

    Token[] private _allTokens;

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


        return address(tokenAddress);
    }

    function setOwnerAndMinter(uint8 index) public onlyOwner override returns (bool) {
        Token _token = _allTokens[index];
        Token(_token).changeOwner(msg.sender);
        Token(_token).changeMinter(msg.sender);
        return true;
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