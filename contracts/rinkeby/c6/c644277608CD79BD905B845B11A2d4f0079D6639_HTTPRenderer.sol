// SPDX-License-Identifier: BSD
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "./HTTPData.sol";
import "base64-sol/base64.sol";

contract HTTPRenderer is HTTPData {         
   address                               private               cowner;
   address                               private               mintingContract;

   constructor() {
      cowner = msg.sender;
   }
   modifier onlyOwner {
      require(msg.sender == cowner,"ONLYOWNER");
      _;
   }   
   modifier onlyMintingContract {
      require(msg.sender == mintingContract,"ONLYMINTINGCONTRACT");
      _;
   }   

    function setMintingContract(address mintCon)  public onlyOwner  {
        mintingContract = mintCon;
    }

   function setVersion(uint tokenId, uint ver) public onlyMintingContract {
       _versions[tokenId] = ver;
   }
   function setUnofficial(uint tokenId, string calldata name) public onlyMintingContract {
       _unofficial[tokenId] = name;
   }   

   function getVersion(uint tokenId) public view returns(uint){
       return _versions[tokenId];
   }

   function upgradeSVGHeader(uint version, string calldata svg_header) public onlyMintingContract {
       _svg_image_template[version] = [svg_header];
   }

    function appendSVG(uint version, string memory svg_line)  external onlyOwner {
      _svg_image_template[version] .push(svg_line);
    }

    function setArtwork(string calldata artist ) external onlyOwner {      
        _artwork_by = artist;
    }    

    function setCopyright(string calldata copyright ) external onlyOwner {      
        _copyright = copyright;
    }    

    function setSVGIndexes(uint[] calldata indexes) external onlyOwner {    
        assert(indexes.length==6);
        _http_code_index = indexes[0];  
        _description_index = indexes[1];   
        _token_owner_index = indexes[2];
        _artwork_by_index = indexes[3];
        _copyright_index = indexes[4];
        _version_index = indexes[5];
    }    

    function svgToImageURI(uint tokenId,string memory owner) private view returns (string memory) {
        string memory svg = renderSVG(tokenId,owner);
        string memory base = "data:image/svg+xml;base64,";
        string memory svgBase64 = Base64.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(base,svgBase64));
    }

    function buildTokenURI(uint tokenId,bool official, string memory owner) public view onlyMintingContract returns (string memory) {
        string memory imageURI = svgToImageURI(tokenId,owner);
        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"HTTP Status Code ',toString(tokenId),'", ',                                
                                '"description":"',official ? _descriptions[tokenId]: _unofficial[tokenId],'", ',    
                                '"attributes": [ {"trait_type": "Category", "value": "',getCategory(tokenId),'",',
                                                 '"trait_type": "Official", "value": "',bulltoUInt256(official),'",',
                                                  '"trait_type": "Version", "value": "',_versions[tokenId],
                                                '"} ],',                                 
                                '"image":"',imageURI,'"}'
                            )
                        )
                    )
                )
            );
    }

    function renderSVG(uint tokenId,string memory owner) private view returns(string memory)  {  
        uint tokenVersion = _versions[tokenId];
        uint svg_length =  _svg_image_template[tokenVersion].length;
        require(svg_length > 0,"SVG Template not set"); 
        string memory str_val;
        string memory http_text =  _descriptions[tokenId]; 

        for (uint i=0; i < svg_length; i++){
            if (i == 1){
                str_val = string(abi.encodePacked(str_val,getCSSHeader(tokenId)));          
            }else if (i != 0 && _http_code_index != 0 && i == _http_code_index){
                str_val = string(abi.encodePacked(str_val,tokenId));
            }else if (i != 0 && _description_index != 0 && i == _description_index){
                str_val = string(abi.encodePacked(str_val,http_text));
            }else if (i != 0 && _token_owner_index != 0 && i == _token_owner_index){
                str_val = string(abi.encodePacked(str_val,owner));
            }else if (i != 0 && _artwork_by_index != 0 && i == _artwork_by_index){
                str_val = string(abi.encodePacked(str_val,_artwork_by));
            }else if (i != 0 && _copyright_index != 0 && i == _copyright_index){
                str_val = string(abi.encodePacked(str_val,_copyright));
            }else if (i != 0 && _version_index != 0 && i == _version_index){
                str_val = string(abi.encodePacked(str_val,_versions[tokenId]));                
            }else{
                str_val = string(abi.encodePacked(str_val, _svg_image_template[tokenVersion][i]));
            }
            
        }
        return str_val;   
    }

    function addHTTPCode(uint code_id, string memory text)  external onlyOwner   {
        _descriptions[code_id] = text; 
    }

    function addHTTPCodes(uint[] calldata tokenIds, string[] calldata text )  external onlyOwner    {
        uint len = tokenIds.length;
        for (uint i=0; i<len; i++){
            _descriptions[tokenIds[i]] = text[i];
        }  
    }

    function setCSSData(string[] calldata token_range, string[] calldata token_css )  external onlyOwner   {
        uint token_ranges = token_range.length;
        uint token_csses = token_css.length;
        assert(token_ranges == token_csses);
        for (uint i=0; i<token_ranges; i++){
            _css_data[token_range[i]] = token_css[i];
        }  
    }

   function httpAllocated(uint tokenId) public view override returns(bool) {
       if (bytes(_descriptions[tokenId]).length>=2)
          return true;
       else
          return false;
   }

   function getCSSHeader(uint tokenId) private view returns(string memory result) {
       
        if (tokenId <= 199){                        //INFORMATIONAL
            result = _css_data['1XX'];
        }else if (tokenId > 199 && tokenId <= 299){ //SUCCESSFUL
            result = _css_data['2XX'];
        }else if (tokenId > 299 && tokenId <= 399){ //REDIRECTION
            result = _css_data['3XX'];
        }else if (tokenId > 399 && tokenId <= 499){ //CLIENT_ERROR
            result = _css_data['4XX'];
        }else if (tokenId > 499 && tokenId <= 599){ //SERVER_ERROR
            result = _css_data['5XX'];
        }else if (tokenId > 599 && tokenId <= 699){ //C600
            result = _css_data['6XX'];
        }else if (tokenId > 699 && tokenId <= 799){ //C700
            result = _css_data['7XX'];
        }else if (tokenId > 799 && tokenId <= 899){ //C800
            result = _css_data['8XX'];
        }else if (tokenId > 899 && tokenId <= 999){ //C900
            result = _css_data['9XX'];
        }

    }

   function getCategory(uint tokenId) private pure returns(string memory result) {
       
        if (tokenId <= 199){                        
            result = 'INFORMATIONAL';
        }else if (tokenId > 199 && tokenId <= 299){ 
            result = 'SUCCESSFUL';
        }else if (tokenId > 299 && tokenId <= 399){ 
            result = 'REDIRECTION';
        }else if (tokenId > 399 && tokenId <= 499){ 
            result = 'CLIENT_ERROR';
        }else if (tokenId > 499 && tokenId <= 599){ 
            result = 'SERVER_ERROR';
        }else if (tokenId > 599 && tokenId <= 699){ 
            result = 'C600';
        }else if (tokenId > 699 && tokenId <= 799){ 
            result = 'C700';
        }else if (tokenId > 799 && tokenId <= 899){ 
            result = 'C800';
        }else if (tokenId > 899 && tokenId <= 999){ 
            result = 'C900';
        }

    }



}

// SPDX-License-Identifier: BSD
pragma solidity ^0.8.7;


abstract contract HTTPData  {         

    uint                                   internal       _http_code_index = 0;
    uint                                   internal       _description_index = 0;
    uint                                   internal       _token_owner_index = 0;
    uint                                   internal       _artwork_by_index = 0;
    uint                                   internal       _copyright_index = 0;
    uint                                   internal       _version_index = 0;
    string                                 internal       _artwork_by = '(c)ollectible status();';   
    string                                 internal       _copyright = 'Owner';   
    mapping( uint => string[] )            internal       _svg_image_template;  
    mapping( uint => string )              internal       _descriptions;  
    mapping( uint => string )              internal       _unofficial;  
    mapping( uint => uint )                internal       _versions;  
    mapping( string => string )            internal       _css_data;  

   function httpAllocated(uint tokenId) public view virtual returns(bool) {
   }
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation. -- from @openzeppelin/contracts/utils/Strings
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

function bulltoUInt256(bool x) internal pure returns (uint r) {   // :-)
  assembly { r := x }
}

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}