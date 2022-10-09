/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

interface IDescriptor {
   function renderphase1(uint256 _srn) external view returns (string memory);
   function renderphase2(uint256 _srn) external view returns (string memory);
   function renderphase3(uint256 _srn) external view returns (string memory);
   function renderphase4(uint256 _srn) external view returns (string memory);
   function renderphase5(uint256 _srn) external view returns (string memory);
   function renderphase6(uint256 _srn) external view returns (string memory);
   function renderphase7(uint256 _srn) external view returns (string memory);
   function renderphase8(uint256 _srn) external view returns (string memory);
   function renderphase9(uint256 _srn) external view returns (string memory);
   function renderphase10(uint256 _srn) external view returns (string memory);
 
   function rendertrait1(uint256 _srn) external view returns (string memory);
   function rendertrait2(uint256 _srn) external view returns (string memory);
   function rendertrait3(uint256 _srn) external view returns (string memory);
   function rendertrait4(uint256 _srn) external view returns (string memory);
   function rendertrait5(uint256 _srn) external view returns (string memory);
   function rendertrait6(uint256 _srn) external view returns (string memory);
   function rendertrait7(uint256 _srn) external view returns (string memory);
   function rendertrait8(uint256 _srn) external view returns (string memory);
   function rendertrait9(uint256 _srn) external view returns (string memory);
   function rendertrait10(uint256 _srn) external view returns (string memory);
}

interface ISeed {
    function getTokenSeed(uint256 tokenId) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface ICharacter {
    function seeName(uint256 tokenId) external view returns (string memory);
}

contract treeWater is Ownable {

    mapping(uint256 => string) public properties;
    mapping(uint256 => uint256) public watertime;
    mapping(uint256 => uint256) public lastwatertime;

    mapping(uint256 => string) public oneTwo;
    mapping(uint256 => string) public thrFou;
    mapping(uint256 => string) public fivSix;
    mapping(uint256 => string) public sevEig;
    mapping(uint256 => string) public ninTen;

    mapping (uint256 => string) private tokenEvent;


    IDescriptor public descriptor;
    ISeed public seed;
    ICharacter public character;

    function setDescriptor(address _address) external onlyOwner {
        descriptor = IDescriptor(_address);
    }

    function setSeed(address _address) external onlyOwner {
        seed = ISeed(_address);
    }

    function setCharacter(address _address) external onlyOwner {
        character = ICharacter(_address);
    }

    function seeIfWorks(uint256 tokenId) external view returns (uint256) {
        return seed.getTokenSeed(tokenId);
    }

    function treeWaterOne (uint256 tokenId) internal {
      /*string memory m = svg[tokenId];
        string memory n = descriptor.renderphase1(seed.getTokenSeed(tokenId));
        string memory q = packMetaData("Phase1", descriptor.rendertrait1(seed.getTokenSeed(tokenId)));

        svg[tokenId] = string.concat(m, n);
        properties[tokenId] = string(q);
      */
      string memory a = descriptor.renderphase1(seed.getTokenSeed(tokenId));
      string memory b = packMetaData("Phase1", descriptor.rendertrait1(seed.getTokenSeed(tokenId)));

      oneTwo[tokenId] = string(a);
      properties[tokenId] = string(b);

    }

    function treeWaterTwo (uint256 tokenId) internal {
      /*string memory m = svg[tokenId];
        string memory n = descriptor.renderphase2(seed.getTokenSeed(tokenId));
        string memory q = packMetaData("Phase2", descriptor.rendertrait2(seed.getTokenSeed(tokenId)));

        svg[tokenId] = string.concat(m, n);
        properties[tokenId] = string(q);
        */
        string memory a = oneTwo[tokenId];
        string memory b = descriptor.renderphase2(seed.getTokenSeed(tokenId));
        string memory p = properties[tokenId];
        string memory q = packMetaData("Phase2", descriptor.rendertrait2(seed.getTokenSeed(tokenId)));

        oneTwo[tokenId] = string.concat(a, b);
        properties[tokenId] = string.concat(p, q);
    }

    function treeWaterThree (uint256 tokenId) internal {
        /*string memory m = svg[tokenId];
        string memory n = descriptor.renderphase3(seed.getTokenSeed(tokenId));
        string memory q = packMetaData("Phase3", descriptor.rendertrait3(seed.getTokenSeed(tokenId)));

        svg[tokenId] = string.concat(m, n);
        properties[tokenId] = string(q);
        */

        string memory a = descriptor.renderphase3(seed.getTokenSeed(tokenId));
        string memory p = properties[tokenId];
        string memory q = packMetaData("Phase3", descriptor.rendertrait3(seed.getTokenSeed(tokenId)));

        thrFou[tokenId] = string(a);
        properties[tokenId] = string.concat(p, q);
    }

    function treeWaterFour (uint256 tokenId) internal {
        /*string memory m = svg[tokenId];
        string memory n = descriptor.renderphase4(seed.getTokenSeed(tokenId));
        string memory q = packMetaData("Phase4", descriptor.rendertrait4(seed.getTokenSeed(tokenId)));

        svg[tokenId] = string.concat(m, n);
        properties[tokenId] = string(q);
        */
        string memory a = thrFou[tokenId];
        string memory b = descriptor.renderphase4(seed.getTokenSeed(tokenId));
        string memory p = properties[tokenId];
        string memory q = packMetaData("Phase4", descriptor.rendertrait4(seed.getTokenSeed(tokenId)));

        thrFou[tokenId] = string.concat(a, b);
        properties[tokenId] = string.concat(p, q);
    }

    function treeWaterFive (uint256 tokenId) internal {
        /*string memory m = svg[tokenId];
        string memory n = descriptor.renderphase5(seed.getTokenSeed(tokenId));
        string memory q = packMetaData("Phase5", descriptor.rendertrait5(seed.getTokenSeed(tokenId)));

        svg[tokenId] = string.concat(m, n);
        properties[tokenId] = string(q);
        */
        string memory a = descriptor.renderphase5(seed.getTokenSeed(tokenId));
        string memory p = properties[tokenId];
        string memory q = packMetaData("Phase5", descriptor.rendertrait5(seed.getTokenSeed(tokenId)));

        fivSix[tokenId] = string(a);
        properties[tokenId] = string.concat(p, q);
    }

    function treeWaterSix (uint256 tokenId) internal {
        /*string memory m = svg[tokenId];
        string memory n = descriptor.renderphase6(seed.getTokenSeed(tokenId));
        string memory q = packMetaData("Phase6", descriptor.rendertrait6(seed.getTokenSeed(tokenId)));

        svg[tokenId] = string.concat(m, n);
        properties[tokenId] = string(q);
        */
        string memory a = fivSix[tokenId];
        string memory b = descriptor.renderphase6(seed.getTokenSeed(tokenId));
        string memory p = properties[tokenId];
        string memory q = packMetaData("Phase6", descriptor.rendertrait6(seed.getTokenSeed(tokenId)));

        fivSix[tokenId] = string.concat(a, b);
        properties[tokenId] = string.concat(p, q);
    }

    function treeWaterSeven (uint256 tokenId) internal {
        /*string memory m = svg[tokenId];
        string memory n = descriptor.renderphase7(seed.getTokenSeed(tokenId));
        string memory q = packMetaData("Phase7", descriptor.rendertrait7(seed.getTokenSeed(tokenId)));

        svg[tokenId] = string.concat(m, n);
        properties[tokenId] = string(q);
        */
        string memory a = descriptor.renderphase7(seed.getTokenSeed(tokenId));
        string memory p = properties[tokenId];
        string memory q = packMetaData("Phase7", descriptor.rendertrait7(seed.getTokenSeed(tokenId)));

        sevEig[tokenId] = string(a);
        properties[tokenId] = string.concat(p, q);
    }

    function treeWaterEight (uint256 tokenId) internal {
        /*string memory m = svg[tokenId];
        string memory n = descriptor.renderphase8(seed.getTokenSeed(tokenId));
        string memory q = packMetaData("Phase8", descriptor.rendertrait8(seed.getTokenSeed(tokenId)));

        svg[tokenId] = string.concat(m, n);
        properties[tokenId] = string(q);
        */
        string memory a = sevEig[tokenId];
        string memory b = descriptor.renderphase8(seed.getTokenSeed(tokenId));
        string memory p = properties[tokenId];
        string memory q = packMetaData("Phase8", descriptor.rendertrait8(seed.getTokenSeed(tokenId)));

        sevEig[tokenId] = string.concat(a, b);
        properties[tokenId] = string.concat(p, q);
    }

    function treeWaterNine (uint256 tokenId) internal {
        /*string memory m = svg[tokenId];
        string memory n = descriptor.renderphase9(seed.getTokenSeed(tokenId));
        string memory q = packMetaData("Phase9", descriptor.rendertrait9(seed.getTokenSeed(tokenId)));

        svg[tokenId] = string.concat(m, n);
        properties[tokenId] = string(q);
        */
        string memory a = descriptor.renderphase9(seed.getTokenSeed(tokenId));
        string memory p = properties[tokenId];
        string memory q = packMetaData("Phase9", descriptor.rendertrait9(seed.getTokenSeed(tokenId)));

        ninTen[tokenId] = string(a);
        properties[tokenId] = string.concat(p, q);
    }

    function treeWaterTen (uint256 tokenId) internal {
        /*string memory m = svg[tokenId];
        string memory n = descriptor.renderphase10(seed.getTokenSeed(tokenId));
        string memory q = packMetaData("Phase10", descriptor.rendertrait10(seed.getTokenSeed(tokenId)));

        svg[tokenId] = string.concat(m, n);
        properties[tokenId] = string(q);
        */
        string memory a = ninTen[tokenId];
        string memory b = descriptor.renderphase10(seed.getTokenSeed(tokenId));
        string memory p = properties[tokenId];
        string memory q = packMetaData("Phase10", descriptor.rendertrait10(seed.getTokenSeed(tokenId)));

        ninTen[tokenId] = string.concat(a, b);
        properties[tokenId] = string.concat(p, q);
    }

    function waterPlant (uint256 tokenId) external {
        //require(watertime[tokenId] == 0 || block.timestamp - lastwatertime[tokenId] > 7 days, "only once a week");
        //require(watertime[tokenId] == 0 || block.timestamp - lastwatertime[tokenId] < 14 days, "dead! Not growing anmore");
        require(watertime[tokenId] == 0 || block.timestamp - lastwatertime[tokenId] > 900, "only once a week");//15min
        require(watertime[tokenId] == 0 || block.timestamp - lastwatertime[tokenId] < 1800, "dead! Not growing anmore");//30min
        require(msg.sender == seed.ownerOf(tokenId), "only owner can grow the plant");
        require(watertime[tokenId] < 11, "this plant fully grown");

        if (watertime[tokenId] == 0) {treeWaterOne(tokenId);} 
        
        else if (watertime[tokenId] == 1) {treeWaterTwo(tokenId);} 
        
        else if (watertime[tokenId] == 2) {treeWaterThree(tokenId);} 
        
        else if (watertime[tokenId] == 3) {treeWaterFour(tokenId);} 
        
        else if (watertime[tokenId] == 4) {treeWaterFive(tokenId);} 
        
        else if (watertime[tokenId] == 5) {treeWaterSix(tokenId);} 
        
        else if (watertime[tokenId] == 6) {treeWaterSeven(tokenId);} 
        
        else if (watertime[tokenId] == 7) {treeWaterEight(tokenId);} 
        
        else if (watertime[tokenId] == 8) {treeWaterNine(tokenId);} 
        
        else if (watertime[tokenId] == 9) {treeWaterTen(tokenId);}      

        lastwatertime[tokenId] = block.timestamp;
        watertime[tokenId]++;
    } 

    function packMetaData(string memory name, string memory _type) private pure returns (string memory) {
        return
        string(
        abi.encodePacked(
            ', {"trait_type": "',
            name,
            '", "value": "',
            _type,
            '"}'
        )
        );
    }

    string private constant START = "<svg viewBox='0 0 120 120' xmlns='http://www.w3.org/2000/svg' style='background: black;'><g fill='#008F11' font-size='10px' font-family='Courier New'>";
    string private constant END = "<text text-anchor='middle' x='60' y='115'>xxxxxx0xxxxxx</text></g></svg>";

    bool public useRenderer;
    function setUseRenderer(bool bool_) external onlyOwner { useRenderer = bool_; }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
      if (!useRenderer) {
        return
        string(
           abi.encodePacked(
                "data:application/json;base64,",
                base64(
                    abi.encodePacked(
                       '{"name":"bckbcd #',
                       uint2str(tokenId),' '//,character.seeName(tokenId),
                       '", "description": "Korega descriptiondesu", "traits": [{"trait_type": "Phase0", "value": "Seed"}',
                       properties[tokenId],
                       '], "image":"data:image/svg+xml;base64,',
                       svgrender(tokenId),
                       '"}'
                    )
                )
            )
        );
      } else {
        return
        string(
           abi.encodePacked(
                "data:application/json;base64,",
                base64(
                    abi.encodePacked(
                       '{"name":"bckbcd #',
                       uint2str(tokenId),' ',character.seeName(tokenId),
                       '", "description": "Korega descriptiondesu", "traits": [{"trait_type": "Phase0", "value": "Seed"}',
                       properties[tokenId],
                       '], "image":"data:image/svg+xml;base64,',
                       svgrender(tokenId),
                       '"}'
                    )
                )
            )
        );
      }
    }

    //get all the token string for jic expanding to other contract

    function getOneTwo(uint256 tokenId) external view returns (string memory) {
        return oneTwo[tokenId];
    }

    function getThrFou(uint256 tokenId) external view returns (string memory) {
        return thrFou[tokenId];
    }

    function getFivSix(uint256 tokenId) external view returns (string memory) {
        return fivSix[tokenId];
    }

    function getSevEig(uint256 tokenId) external view returns (string memory) {
        return sevEig[tokenId];
    }

    function getNinTen(uint256 tokenId) external view returns (string memory) {
        return ninTen[tokenId];
    }
    

    function svgrender(uint256 tokenId) internal view returns (string memory) {
        bytes memory b = abi.encodePacked(
            START, 
            oneTwo[tokenId], 
            thrFou[tokenId],
            fivSix[tokenId],
            sevEig[tokenId],
            ninTen[tokenId],
            END
            ); 
        return base64(b);
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
          len++;
          j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

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
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }

}