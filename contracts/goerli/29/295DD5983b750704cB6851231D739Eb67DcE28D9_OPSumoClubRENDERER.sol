/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: sumo technologies

pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

interface IOPSC {
    //function seeDNA(uint256 tokenId) external view returns (uint256);
    function sumoDNA(uint256 tokenId_) external view returns (uint256);
}

interface IBackground {
    function renderBack(uint256 _srn) external view returns (string memory);
    function renderBackName(uint256 _srn) external view returns (string memory);
}

interface IBody1 {
    function renderBody1(uint256 _srn) external view returns (string memory);
    function renderBodyName1(uint256 _srn) external view returns (string memory);
}

interface IBody2 {
    function renderBody2(uint256 _srn) external view returns (string memory);
}

interface IHead1 {
    function renderHead1(uint256 _srn) external view returns (string memory);
    function renderHeadName1(uint256 _srn) external view returns (string memory);
}

interface IHead2 {
    function renderHead2(uint256 _srn) external view returns (string memory);
}

interface IEyes1 {
    function renderEyes1(uint256 _srn) external view returns (string memory);
    function renderEyesName1(uint256 _srn) external view returns (string memory);
}

interface IEyes2 {
    function renderEyes2(uint256 _srn) external view returns (string memory);
}

interface IMA {
    function renderMouth(uint256 _srn) external view returns (string memory);
    function renderMouthName(uint256 _srn) external view returns (string memory);
    function renderAcc(uint256 _srn) external view returns (string memory);
    function renderAccName(uint256 _srn) external view returns (string memory);
}

//interface ICHANCO {
//    function burnFrom(address from_, uint256 amount_) external;
//}

//interface ISC {
//    function tokenName(uint256 tokenId_) external view returns (string memory);
//   function tokenBio(uint256 tokenId_) external view returns (string memory);
//}

contract OPSumoClubRENDERER is Ownable {

    string private constant START = "<svg id='opsc' width='100%' height='100%' version='1.1' viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'>";
    string private constant END = "</svg>";

    IOPSC private OPSC = IOPSC(0xA618106200D14e28d3Fc2d83F93624076a28681a);
    IBackground private bg = IBackground(0x32B85D775D5ee1e21B6f7195F36d9f8a3155f766);
    IBody1 private body1 = IBody1(0xDAe248A0Ff8df7e1f51398B06181D47ed7dadFd4);
    IBody2 private body2 = IBody2(0xabfC100B174A21ad18A963e5000b72647a1adA9e);
    IHead1 private head1 = IHead1(0x73dF884bE34de4AbcFF8123BDe6434Eb0e30F7ab);
    IHead2 private head2 = IHead2(0x964d00EB1811C28daaE0765c0210079Ffa62920d);
    IEyes1 private eye1 = IEyes1(0x8b216AF0c99a0589188492c23cb660236F60b922);
    IEyes2 private eye2 = IEyes2(0x7AAD46b083EbE20622a6AC5149e57409C4d0db0F);
    IMA private ma = IMA(0x5Face81b909c0e3611797D187cEE3f44d44B8934);
    //ISC public sc;

    /*change name and bio stuff
    ICHANCO public CHANCO = ICHANCO(0x4E3600362e76256cFE13e6ed0B56C91E41Bc1333);

    mapping (uint256 => string) public tokenName;
    mapping (uint256 => string) public tokenBio;

    uint256 public changeNamePrice = 30 ether;
    uint256 public changeBioPrice = 60 ether;

    function changeName(uint256 tokenId, string memory newName) public {
        require(msg.sender == OPSC.ownerOf(tokenId), "You don't own this token");
        require(sha256(bytes(newName)) != sha256(bytes(tokenName[tokenId])), "Name is same");

        CHANCO.burnFrom(msg.sender, changeNamePrice);
        tokenName[tokenId] = newName;
    }

    function changeBio(uint256 tokenId, string memory newBio) public {
        require(msg.sender == OPSC.ownerOf(tokenId), "You don't own this token");
        require(sha256(bytes(newBio)) != sha256(bytes(tokenBio[tokenId])), "Name is same");

        CHANCO.burnFrom(msg.sender, changeBioPrice);
        tokenBio[tokenId] = newBio;
    }
    change name and bio stuff*/

    function setOPSC(address _address) external onlyOwner {
        OPSC = IOPSC(_address);
    }

    function setBackground(address _address) external onlyOwner {
        bg = IBackground(_address);
    }

    function setBody1(address _address) external onlyOwner {
        body1 = IBody1(_address);
    }

    function setBody2(address _address) external onlyOwner {
        body2 = IBody2(_address);
    }

    function setHead1(address _address) external onlyOwner {
        head1 = IHead1(_address);
    }

    function setHead2(address _address) external onlyOwner {
        head2 = IHead2(_address);
    }

    function setEyes1(address _address) external onlyOwner {
        eye1 = IEyes1(_address);
    }

    function setEyes2(address _address) external onlyOwner {
        eye2 = IEyes2(_address);
    }

    function setMA(address _address) external onlyOwner {
        ma = IMA(_address);
    }

    //function setSC(address _address) external onlyOwner {
    //    sc = ISC(_address);
    //}

    function getTraits(uint256 tokenId) internal view returns (string memory svg, string memory properties) {

        uint256 fundoshiDNA = OPSC.sumoDNA(tokenId);
        uint256 back = fundoshiDNA % 100000000000 / 10000000000;
        uint256 body = (fundoshiDNA % 10000000000 / 1000000000) + (fundoshiDNA % 1000000000 / 100000000);
        uint256 head = (fundoshiDNA % 100000000 / 10000000) + (fundoshiDNA % 10000000 / 1000000);
        uint256 mouth = (fundoshiDNA % 1000000 / 100000) + (fundoshiDNA % 100000 / 10000);
        uint256 eyes = (fundoshiDNA % 10000 / 1000) * (fundoshiDNA % 1000 / 100) + (fundoshiDNA % 100 / 10);
        uint256 acc = fundoshiDNA % 10;

        bytes memory _svg = abi.encodePacked(
            bg.renderBack(back),
            body1.renderBody1(body),
            body2.renderBody2(body),
            head1.renderHead1(head),
            head2.renderHead2(head),
            ma.renderMouth(mouth),
            eye1.renderEyes1(eyes),
            eye2.renderEyes2(eyes),
            ma.renderAcc(acc)
        );

        bytes memory _svgs = abi.encodePacked(
            START,
            _svg,
            END
        );

        svg = base64(_svgs);

        bytes memory _properties = abi.encodePacked(
            packMetaData("Background", bg.renderBackName(back), 0),
            packMetaData("Body", body1.renderBodyName1(body), 0),
            packMetaData("Head", head1.renderHeadName1(head), 0),
            packMetaData("Mouth", ma.renderMouthName(mouth), 0),
            packMetaData("Eyes", eye1.renderEyesName1(eyes), 0),
            packMetaData("Accessory", ma.renderAccName(acc), 1)
        );
        
        properties = string(_properties);

        return (svg, properties);
    }

    function packMetaData(string memory name, string memory svg, uint256 last) internal pure returns (bytes memory) {
        string memory comma = ",";
        if (last > 0) comma = "";
        return
            abi.encodePacked(
            '{"trait_type": "',
            name,
            '", "value": "',
            svg,
            '"}',
            comma
        );
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        (string memory svg, string memory properties) = getTraits(tokenId);
        return
        string(
        abi.encodePacked(
            "data:application/json;base64,",
                base64(
                    abi.encodePacked(
                        '{"name": "SUMO #', 
                        uint2str(tokenId),
                        '",',
                        '"description": "Welcome to OP Sumo Club !",',
                        '"traits": [',
                        properties,
                        '],',
                        '"image": "data:image/svg+xml;base64,',
                        svg,
                        '"}'
                    )
                )
            )
        );
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