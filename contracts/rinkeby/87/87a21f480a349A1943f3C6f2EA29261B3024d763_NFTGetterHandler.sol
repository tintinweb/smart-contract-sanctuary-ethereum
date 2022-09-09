import "./INFTGetter.sol";
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract NFTGetterHandler {

    struct dataToFrontEnd {
        string tokenURI;
        bool isUsed;
        uint price;
        uint timeToExpirate;
    }

    INFTGetter nftGetter;
    
    constructor() {
        nftGetter = INFTGetter(0xE54CB67B86335286bE90c63E6C9632846D3830a1);
    }   

    function getListOfNFTsOfUser(address _user) private view returns (uint256[] memory result) {
        uint amountOfTokensOfUser = nftGetter.balanceOf(_user);
        uint[] memory listOfTokensIdOfUser = new uint[](amountOfTokensOfUser);

        for(uint i = 0; i < amountOfTokensOfUser; i++){
            listOfTokensIdOfUser[i] = nftGetter.tokenOfOwnerByIndex(_user, i);
        }
        
        return listOfTokensIdOfUser;
    }

    function getDataOfTokens(uint256[] memory _tokenList) private view returns (dataToFrontEnd[] memory data) {
        uint amountOfTokens = _tokenList.length;
        uint currentTokenId;
        dataToFrontEnd[] memory dataList = new dataToFrontEnd[](amountOfTokens);

        for(uint i = 0; i < amountOfTokens; i++) {
            currentTokenId = _tokenList[i];
            dataList[i] = getDataOfToken(i);
        }

        return dataList;
    }

    function getDataOfNftsOwnedByUser(address _user) public view returns (dataToFrontEnd[] memory data){
        uint[] memory tokenList = getListOfNFTsOfUser(_user);

        return getDataOfTokens(tokenList);
    }

    function getDataOfNftsWithUserAsProvider(address _user) public view returns (dataToFrontEnd[] memory data) {
        uint[] memory tokenListOfProvider = nftGetter.getCuponsProvider(_user);
        return getDataOfTokens(tokenListOfProvider);
    }

    function getDataOfToken(uint _tokenId) public view returns (dataToFrontEnd memory data) {
        return dataToFrontEnd(nftGetter.tokenURI(_tokenId), nftGetter.used(_tokenId), nftGetter.getPrice(_tokenId), nftGetter.expiration(_tokenId));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INFTGetter {

    function tokenURI(uint _id) external view returns (string memory);

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);

    function balanceOf(address _owner) external view returns(uint256 balance);

    function getCuponsProvider(address _user) external view returns(uint256[] memory);

    function getPrice(uint256 _tokenId) external view returns(uint256);

    function expiration(uint _tokenId) external view returns(uint256);

    function used(uint _tokenId) external view returns(bool);

}