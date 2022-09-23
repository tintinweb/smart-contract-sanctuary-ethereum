// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FakeNFTMarketPlace {
    //mantem um mapping do Fake TokenID dos enderecos dos donos
    mapping(uint256 => address) public tokens;
    //estabelece o valor de cada token nft
    uint256 nftPrice = 0.1 ether;

    //aceita eth e marca o dono de um determinado tokenID como o endereco da chamada
    //param - tokenId - fake nft token
    function purchase(uint256 _tokenId) external payable {
        require(msg.value == nftPrice, "This NFT costs 0.1 ether");
        tokens[_tokenId] = msg.sender;
    }

    //getPrice() retorna o preco de um nft
    function getPrice() external view returns(uint256) {
        return nftPrice;
    }

    //available verifica quando um dado tokenId ja esta pronto para ser vendido ou nao
    //param _tokenID - 
    function available(uint256 _tokenId) external view returns (bool) {
        if(tokens[_tokenId] == address(0)) {
            return true;
        }
        return false;
    } 
}