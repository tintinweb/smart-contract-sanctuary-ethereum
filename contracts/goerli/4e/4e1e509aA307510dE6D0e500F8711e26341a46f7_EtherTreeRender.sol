/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

//SPDX-License-Identifier: UNLICENSED

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
    function getTime(uint256 tokenId) external view returns (uint256);
    function getPhase(uint256 tokenId) external view returns (uint256);
}

interface ICharacter {
    function seeName(uint256 tokenId) external view returns (string memory);
}

contract EtherTreeRender is Ownable {

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

    function tree1WaterImg (uint256 tokenId) internal view returns (string memory) {
      string memory treeImg = descriptor.renderphase1(seed.getTokenSeed(tokenId));
      return treeImg;
    }

    function tree1WaterTra (uint256 tokenId) internal view returns (string memory) {
      string memory treeTra = packMetaData("Phase1", descriptor.rendertrait1(seed.getTokenSeed(tokenId)));
      return treeTra;
    }

    function tree2WaterImg (uint256 tokenId) internal view returns (string memory) {
      string memory treeImg = string(abi.encodePacked(
          tree1WaterImg(tokenId),
          descriptor.renderphase2(seed.getTokenSeed(tokenId))
      ));
      return treeImg;
    }

    function tree2WaterTra (uint256 tokenId) internal view returns (string memory) {
      string memory treeTra = string(abi.encodePacked(
        tree1WaterTra(tokenId),
        packMetaData("Phase2", descriptor.rendertrait2(seed.getTokenSeed(tokenId)))
      ));
      return treeTra;
    }

    function tree3WaterImg (uint256 tokenId) internal view returns (string memory) {
      string memory treeImg = string(abi.encodePacked(
          tree2WaterImg(tokenId),
          descriptor.renderphase3(seed.getTokenSeed(tokenId))
      ));
      return treeImg;
    }

    function tree3WaterTra (uint256 tokenId) internal view returns (string memory) {
      string memory treeTra = string(abi.encodePacked(
        tree2WaterTra(tokenId),
        packMetaData("Phase3", descriptor.rendertrait3(seed.getTokenSeed(tokenId)))
      ));
      return treeTra;
    }

    function tree4WaterImg (uint256 tokenId) internal view returns (string memory) {
      string memory treeImg = string(abi.encodePacked(
          tree3WaterImg(tokenId),
          descriptor.renderphase4(seed.getTokenSeed(tokenId))
      ));
      return treeImg;
    }

    function tree4WaterTra (uint256 tokenId) internal view returns (string memory) {
      string memory treeTra = string(abi.encodePacked(
        tree3WaterTra(tokenId),
        packMetaData("Phase4", descriptor.rendertrait4(seed.getTokenSeed(tokenId)))
      ));
      return treeTra;
    }

    function tree5WaterImg (uint256 tokenId) internal view returns (string memory) {
      string memory treeImg = string(abi.encodePacked(
          tree4WaterImg(tokenId),
          descriptor.renderphase5(seed.getTokenSeed(tokenId))
      ));
      return treeImg;
    }

    function tree5WaterTra (uint256 tokenId) internal view returns (string memory) {
      string memory treeTra = string(abi.encodePacked(
        tree4WaterTra(tokenId),
        packMetaData("Phase5", descriptor.rendertrait5(seed.getTokenSeed(tokenId)))
      ));
      return treeTra;
    }

    function tree6WaterImg (uint256 tokenId) internal view returns (string memory) {
      string memory treeImg = string(abi.encodePacked(
          tree5WaterImg(tokenId),
          descriptor.renderphase6(seed.getTokenSeed(tokenId))
      ));
      return treeImg;
    }

    function tree6WaterTra (uint256 tokenId) internal view returns (string memory) {
      string memory treeTra = string(abi.encodePacked(
        tree5WaterTra(tokenId),
        packMetaData("Phase6", descriptor.rendertrait6(seed.getTokenSeed(tokenId)))
      ));
      return treeTra;
    }

    function tree7WaterImg (uint256 tokenId) internal view returns (string memory) {
      string memory treeImg = string(abi.encodePacked(
          tree6WaterImg(tokenId),
          descriptor.renderphase7(seed.getTokenSeed(tokenId))
      ));
      return treeImg;
    }

    function tree7WaterTra (uint256 tokenId) internal view returns (string memory) {
      string memory treeTra = string(abi.encodePacked(
        tree6WaterTra(tokenId),
        packMetaData("Phase7", descriptor.rendertrait7(seed.getTokenSeed(tokenId)))
      ));
      return treeTra;
    }

    function tree8WaterImg (uint256 tokenId) internal view returns (string memory) {
      string memory treeImg = string(abi.encodePacked(
          tree7WaterImg(tokenId),
          descriptor.renderphase8(seed.getTokenSeed(tokenId))
      ));
      return treeImg;
    }

    function tree8WaterTra (uint256 tokenId) internal view returns (string memory) {
      string memory treeTra = string(abi.encodePacked(
        tree7WaterTra(tokenId),
        packMetaData("Phase8", descriptor.rendertrait8(seed.getTokenSeed(tokenId)))
      ));
      return treeTra;
    }

    function tree9WaterImg (uint256 tokenId) internal view returns (string memory) {
      string memory treeImg = string(abi.encodePacked(
          tree8WaterImg(tokenId),
          descriptor.renderphase9(seed.getTokenSeed(tokenId))
      ));
      return treeImg;
    }

    function tree9WaterTra (uint256 tokenId) internal view returns (string memory) {
      string memory treeTra = string(abi.encodePacked(
        tree8WaterTra(tokenId),
        packMetaData("Phase9", descriptor.rendertrait9(seed.getTokenSeed(tokenId)))
      ));
      return treeTra;
    }

    function tree10WaterImg (uint256 tokenId) internal view returns (string memory) {
      string memory treeImg = string(abi.encodePacked(
          tree9WaterImg(tokenId),
          descriptor.renderphase10(seed.getTokenSeed(tokenId))
      ));
      return treeImg;
    }

    function tree10WaterTra (uint256 tokenId) internal view returns (string memory) {
      string memory treeTra = string(abi.encodePacked(
        tree9WaterTra(tokenId),
        packMetaData("Phase10", descriptor.rendertrait10(seed.getTokenSeed(tokenId)))
      ));
      return treeTra;
    }

    string private constant START = "<svg viewBox='0 0 120 120' xmlns='http://www.w3.org/2000/svg' style='background: black'><g fill='#008F11' font-size='10px' font-family='Courier New'>";
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
                       '{"name":"Ether Plant #',
                       uint2str(tokenId),' '
                       '", "description": "Ether Plants are full on-chain NFTs planted in the ether.", "traits": [{"trait_type": "Phase0", "value": "Seed"}',
                       metarender(tokenId),
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
                       '{"name":"Ether Plant #',
                       uint2str(tokenId),' ',character.seeName(tokenId),
                       '", "description": "Ether Plants are full on-chain NFTs planted in the ether.", "traits": [{"trait_type": "Phase0", "value": "Seed"}',
                       metarender(tokenId),
                       '], "image":"data:image/svg+xml;base64,',
                       svgrender(tokenId),
                       '"}'
                    )
                )
            )
        );
      }
    }

    function packMetaData(string memory name, string memory _type) internal pure returns (string memory) {
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

    function metarender(uint256 tokenId) internal view returns (string memory) {
        if (seed.getPhase(tokenId) == 1) {
            return tree1WaterTra(tokenId);
        }
        else if (seed.getPhase(tokenId) == 2) {
            return tree2WaterTra(tokenId);
        }
        else if (seed.getPhase(tokenId) == 3) {
            return tree3WaterTra(tokenId);
        }
        else if (seed.getPhase(tokenId) == 4) {
            return tree4WaterTra(tokenId);
        }
        else if (seed.getPhase(tokenId) == 5) {
            return tree5WaterTra(tokenId);
        }
        else if (seed.getPhase(tokenId) == 6) {
            return tree6WaterTra(tokenId);
        }
        else if (seed.getPhase(tokenId) == 7) {
            return tree7WaterTra(tokenId);
        }
        else if (seed.getPhase(tokenId) == 8) {
            return tree8WaterTra(tokenId);
        }
        else if (seed.getPhase(tokenId) == 9) {
            return tree9WaterTra(tokenId);
        }
        else if (seed.getPhase(tokenId) == 10) {
            return tree10WaterTra(tokenId);
        }
        else {
            return "";
        }
    }

    function svgrender(uint256 tokenId) internal view returns (string memory) {
        if (seed.getPhase(tokenId) == 1) {
        bytes memory b = abi.encodePacked(
            START, 
            tree1WaterImg(tokenId), 
            END
            ); 
        return base64(b);
        }
        else if (seed.getPhase(tokenId) == 2) {
        bytes memory b = abi.encodePacked(
            START, 
            tree2WaterImg(tokenId), 
            END
            ); 
        return base64(b);
        }
        else if (seed.getPhase(tokenId) == 3) {
        bytes memory b = abi.encodePacked(
            START, 
            tree3WaterImg(tokenId), 
            END
            ); 
        return base64(b);
        }
        else if (seed.getPhase(tokenId) == 4) {
        bytes memory b = abi.encodePacked(
            START,  
            tree4WaterImg(tokenId), 
            END
            ); 
        return base64(b);
        }
        else if (seed.getPhase(tokenId) == 5) {
        bytes memory b = abi.encodePacked(
            START, 
            tree5WaterImg(tokenId), 
            END
            ); 
        return base64(b);
        }
        else if (seed.getPhase(tokenId) == 6) {
        bytes memory b = abi.encodePacked(
            START, 
            tree6WaterImg(tokenId), 
            END
            ); 
        return base64(b);
        }
        else if (seed.getPhase(tokenId) == 7) {
        bytes memory b = abi.encodePacked(
            START, 
            tree7WaterImg(tokenId), 
            END
            ); 
        return base64(b);
        }
        else if (seed.getPhase(tokenId) == 8) {
        bytes memory b = abi.encodePacked(
            START, 
            tree8WaterImg(tokenId), 
            END
            ); 
        return base64(b);
        }
        else if (seed.getPhase(tokenId) == 9) {
        bytes memory b = abi.encodePacked(
            START, 
            tree9WaterImg(tokenId), 
            END
            ); 
        return base64(b);
        }
        else if (seed.getPhase(tokenId) == 10) {
        bytes memory b = abi.encodePacked(
            START, 
            tree10WaterImg(tokenId), 
            END
            ); 
        return base64(b);
        }
        else {
        bytes memory b = abi.encodePacked(
            START,  
            END
            ); 
        return base64(b);
        }
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