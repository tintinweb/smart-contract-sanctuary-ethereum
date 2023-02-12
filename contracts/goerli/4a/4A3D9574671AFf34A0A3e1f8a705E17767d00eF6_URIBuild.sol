//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;



contract URIBuild {
   
    struct tokenData {
        string GIF;
        string trait;
    }

    mapping (uint => tokenData) public tokens;

    //remember to change permissions
    function setTokenInfo(uint tokenID, string memory _GIF, string memory _trait) public {     

        tokens[tokenID].trait = _trait;



        tokens[tokenID].GIF = string(abi.encodePacked('stuff',_GIF));

    }

    function getTokenInfo(uint tokenID) public view returns (string memory, string memory) {
        return (tokens[tokenID].GIF, tokens[tokenID].trait);
    }   

    /*function tokenURI(uint256 tokenId) public view override returns (string memory) {

        string(abi.encodePacked(
              'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                          '{"name":"', 
                          currentWord.name,
                          '", "description":"', 
                          currentWord.description,
                          '", "image": "', 
                          'data:image/svg+xml;base64,', 
                          buildImage(_tokenId),
                          '"}'))))); */
    

    
  
}