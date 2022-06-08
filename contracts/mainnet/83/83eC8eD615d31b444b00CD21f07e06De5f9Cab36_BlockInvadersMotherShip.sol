// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./stringutils.sol";
import "./stringutils2.sol";


//
//
//                              ///                                      
//                           ////////                                    
//                         /////////////                                 
//                     //////////////////                               
//                   ///////////////////////                            
//                ////////////////////////////                          
//    &&&&&&&&&     ////////////////////////     &&&&&&&&&&             
//                     ///////////////////                              
//      &&&&&&&&&&&      //////////////      &&&&&&&&&&&&               
//      &&&&&&&&&&&&&&      /////////     &&&&&&&&&&&&&&&               
//                &&&&&&      ////      &&&&&&&                         
//                  &&&&&&&          &&&&&&&                            
//            &&&&&    &&&&&&      &&&&&&&   &&&&&                      
//               &&&&&   &&&&&&&&&&&&&&    &&&&&                        
//                 &&&&&    &&&&&&&&&   &&&&&                           
//                    &&&&&   &&&&    &&&&&                             
//                      &&&&&      &&&&&                                
//                         &&&&& &&&&&                                  
//                           &&&&&&                                     
//                             &&                                       
//                                                                      
//                                                                      
//                      &&&     &&&&&    &&                             
//                    &&   &&   &&   &&  &&                             
//                   &&     &&  &&&&&&&  &&                             
//                    &&   &&   &&&   && &&                             
//                      &&&     &&&& &&  &&            
//
//========================================================================
// ONCHAIN BLOCK INVADERS - Upgradable Skin Renderer and Storage contract

interface ICargoShip  {
    function isCargoShip() external pure returns (bool);
    function unloadChroma(uint256 idx) external view returns (string[] memory,string[] memory,string[] memory,string[] memory,string memory,string memory);
}

contract BlockInvadersMotherShip is ReentrancyGuard, Ownable {
    using strings for *;
        
    uint256 constant BODY_COUNT  = 17;
    uint256 constant HEAD_COUNT  = 17;
    uint256 constant EYES_COUNT  = 32;
    uint256 constant MOUTH_COUNT = 21;
    
    struct dataStruct {
        string buffer;
        string prop;
        uint8 Cnt;
        uint8 tCnt;
        uint8 oCnt;
    }
    
   struct compIndexStruct {
        uint256 id0;  
        uint256 id1; 
        uint256 id2; 
        uint256 id3; 
        uint256 id4;
        uint256 idColH;
        uint256 idColB;
        }   

    //main data storage
    struct skinStruct{
    dataStruct[BODY_COUNT] bodies;
    dataStruct[HEAD_COUNT] heads;
    dataStruct[EYES_COUNT] eyes;
    dataStruct[MOUTH_COUNT] mouths;
    string skinName;
    }

    struct paintStruct{
    string[] eyesColor;
    string[] color;
    string[] backgroundColor;
    string[] colName;
    string   effect;
    string  chromaName;
    }
    mapping(uint256 => skinStruct) skin;
      
    //cuting the storing cost and execution costs to more than half using this neet SVG trick !
    //string mirror = ' transform= "scale(-1,1) translate(-350,0)"/>';
    string mirror = 'IHRyYW5zZm9ybT0gJ3NjYWxlKC0xLDEpIHRyYW5zbGF0ZSgtMzUwLDApJy8+';
    //string mirror2 = 'scale(-1,1) translate(-350,0)';
    string mirror2 = 'c2NhbGUoLTEsMSkgIHRyYW5zbGF0ZSgtMzUwLDAp';

    address private masterAddress ;
    address private cargoShipAddress;
      
    
    event MatterStorredLayer1();
    event MatterStorredLayer2();
    event MasterAddressSet(address masterAddress);
    event CargoShipAddressSet(address cargoShipAddress);
    
    //we lock the contract to be used only with the master address,the mint contract
    modifier onlyMaster() {
        require(masterAddress == _msgSender(), "Intruder Alert: Access denied in to the mothership");
        _;
    }
   
    constructor() Ownable(){ }
    
    function setMasterAddress(address _masterAddress) public onlyOwner {
        //store the address of the mothership contract
        masterAddress = _masterAddress;
         // Emit the event
        emit MasterAddressSet(masterAddress);
    }
    
    function setCargoShipAddress(address _cargoShipAddress) public onlyOwner {
        //store the address of the mothership contract
        cargoShipAddress = _cargoShipAddress;
         // Emit the event
        emit CargoShipAddressSet(cargoShipAddress);
    }
 
    //Acknowledge contract is `BlockInvadersMothership`;return always true
    function isMotherShip() external pure returns (bool) {return true;}
  
    function storeMatterLayer1(dataStruct[] memory _data,uint256 _idx,string memory _skinName ) external onlyOwner   {
        for (uint i = 0; i < BODY_COUNT; i++){
        skin[_idx].bodies[i] = _data[i];
        }
        for (uint i = BODY_COUNT; i < _data.length; i++){
            skin[_idx].eyes[i-BODY_COUNT] = _data[i];
        }
        skin[_idx].skinName= _skinName;
        emit MatterStorredLayer1();
    }
    
    function storeMatterLayer2(dataStruct[] memory _data,uint256 _idx ) external onlyOwner   {
        for (uint i = 0; i < HEAD_COUNT; i++){
            skin[_idx].heads[i] = _data[i];
        }
        for (uint i = HEAD_COUNT; i < _data.length; i++){
            skin[_idx].mouths[i-HEAD_COUNT] = _data[i];
        }
        emit MatterStorredLayer2();
    }

    function splitR(strings.slice memory slc,strings.slice memory rune,string memory col) internal pure returns(string memory)
    {
        return string(abi.encodePacked('PHJlY3QgeD0n',slc.split(rune).toString(),       //<rect x='
                                       'JyB5PSAn', slc.split(rune).toString(),          //'y='
                                       'JyB3aWR0aD0n',slc.split(rune).toString(),       //'width='
                                       'JyBoZWlnaHQ9ICAn',slc.split(rune).toString(),   //'height='
                                       'JyAgZmlsbD0g',col ));                           //'fill= 
    }

    function spiltRT(strings.slice memory slc,strings.slice memory rune,string memory col) internal pure returns(string memory)
    {
        return string(abi.encodePacked('PHJlY3QgeD0n',slc.split(rune).toString(),       //<rect x='
                                       'JyB5PSAn', slc.split(rune).toString(),          //'y= '  
                                       'JyB3aWR0aD0n',slc.split(rune).toString(),       //'width=' 
                                       'JyBoZWlnaHQ9ICAn',slc.split(rune).toString(),   //'height='
                                       'JyAgZmlsbD0g',col,                              //'fill=
                                       'IHRyYW5zZm9ybSA9ICcg' ));                       //'transform='
    }

    function splitO(strings.slice memory slc,strings.slice memory rune,string memory col) internal pure returns(string memory)
    {
        return string(abi.encodePacked('PGNpcmNsZSBjeD0n',slc.split(rune).toString(),      //<circle cx='
                                       'JyBjeT0n', slc.split(rune).toString(),             //'cy='
                                       'JyByID0n',slc.split(rune).toString(),              //'r=' 
                                       'JyAgZmlsbD0g',col ));                              //'fill='
    }

    function splitT(strings.slice memory slc,strings.slice memory rune)  internal pure returns(string memory)
    {
        return string(abi.encodePacked('IHRyYW5zbGF0ZSgg',slc.split(rune).toString(),      // translate(    
                                       'ICwg',slc.split(rune).toString(),                  // ,  
                                       'ICkgcm90YXRlICgg',slc.split(rune).toString(),      //) rotate ( 
                                       'KScgIC8+' ));                                      //)'  />
    }

    function joinR4(uint256 count,string memory o,string memory om,strings.slice memory slc,strings.slice memory rune,string memory col) internal view returns(string memory,string memory)
    {
         for(uint i = 0; i < count;) {
             string memory ot  = splitR(slc,rune,col);
             om=string(abi.encodePacked(om,ot,mirror));
             o= string(abi.encodePacked(o,ot,'IC8+')); 
             i=i+4;
          }
        return (o,om);
    }

    function joinR16(uint256 count,strings.slice memory slc,strings.slice memory rune,string memory col) internal view returns(string memory,string memory)
    {
         string memory o;
         string memory om;
         for(uint i = 0; i < count;) {
             string memory ot  = splitR(slc,rune,col);
             string memory ot1 = splitR(slc,rune,col);
             string memory ot2 = splitR(slc,rune,col);
             string memory ot3 = splitR(slc,rune,col);
             om = string(abi.encodePacked(om,ot,mirror,ot1,mirror,ot2,mirror,ot3,mirror));
             o  = string(abi.encodePacked(o,ot,'IC8+',ot1,'IC8+',ot2,'IC8+',ot3,'IC8+'));
             i=i+16;
          }
        return (o,om);
    }

    function joinO3(uint256 count,string memory o,string memory om,strings.slice memory slc,strings.slice memory rune,string memory col) internal view returns(string memory,string memory)
    {
         for(uint i = 0; i < count;) {
             string memory ot  = splitO(slc,rune,col);
             om=string(abi.encodePacked(om,ot,mirror));
             o= string(abi.encodePacked(o,ot,'IC8+'));
             i=i+3;
          }
        return (o,om);
    }
 
    function joinO9(uint256 count,string memory o,string memory om,strings.slice memory slc,strings.slice memory rune,string memory col) internal view returns(string memory,string memory)
    {
         
         for(uint i = 0; i < count;) {
             string memory c1 = splitO(slc,rune,col);
             string memory c2 = splitO(slc,rune,col);
             string memory c3 = splitO(slc,rune,col);
             om = string(abi.encodePacked(om,c1,mirror,c2,mirror,c3,mirror));
             o  = string(abi.encodePacked(o,c1,'IC8+',c2,'IC8+',c3,'IC8+'));
             i=i+9;
          }
        return (o,om);
    }
    function joinT7(uint256 count ,string memory o,string memory om,strings.slice memory slc,strings.slice memory rune,string memory col) internal view returns(string memory,string memory)
    {
        for(uint i = 0; i < count;) {
             string memory ot  = spiltRT(slc,rune,col);
             string memory  t  = splitT (slc,rune);
             om=string(abi.encodePacked(om,ot,mirror2,t));
             o= string(abi.encodePacked(o,ot,t));
             i=i+7;
          }
        return (o,om);
    }

    function joinT21(uint256 count ,string memory o,string memory om,strings.slice memory slc,strings.slice memory rune,string memory col) internal view returns(string memory,string memory)
    {
        string[6] memory sp;
        for(uint i = 0; i < count;) {
             sp[0]  = spiltRT(slc,rune,col);
             sp[1]  = splitT (slc,rune);
             sp[2]  = spiltRT(slc,rune,col);
             sp[3]  = splitT (slc,rune);
             sp[4]  = spiltRT(slc,rune,col);
             sp[5]  = splitT (slc,rune);
             om=string(abi.encodePacked(om,sp[0],mirror2,sp[1],sp[2] ));
             om=string(abi.encodePacked(om,mirror2,sp[3],sp[4],mirror2,sp[5]));
             o= string(abi.encodePacked(o,sp[0],sp[1],sp[2],sp[3],sp[4],sp[5]));
             i=i+21;
          }
        return (o,om);
    }
    
    function random(string memory input,uint max) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)))%max;
    }
     
    function randomW(string memory input,uint max) internal pure returns (uint256) {
        uint16[17] memory w = [3330,3200,3274,3264,3244,2234,2214,1594,1574,1564,554,544,334,324,315,205,44];
        
        uint256 rnd = uint256(keccak256(abi.encodePacked(input)))%27812;
        for (uint i=0;i<max;i++){
            if(rnd<w[i]){
                return i;
            }
            rnd -= w[i];
        }
        return 0;
    }

    function convertMattertoEnergy(dataStruct memory part,uint256 tokenId,string[] memory colorList,uint256 dataType) public view onlyMaster returns (string memory,uint256) {
       string memory o;
       string memory om;
  
       strings.slice memory slc = strings.toSlice( part.buffer);
       strings.slice memory rune =   strings.toSlice(",");
       uint256 did = 10; 

       uint256 id = random(stringutils2.UtoString(tokenId*2+dataType),colorList.length);
       did = id;
       uint256 offset = part.Cnt % 16;
       string memory col = colorList[id];
       if (dataType == 10){
           col = string(abi.encodePacked(col,'IGZpbHRlcj0ndXJsKCNuZW9uKScg')); //filter='url(#neon)' 
       }
       if ( part.Cnt >=16){
        (o,om) = joinR16(part.Cnt-offset,slc,rune,col);
       }
       (o,om) = joinR4(offset,o,om,slc,rune,col); 

       id = random(stringutils2.UtoString(tokenId*3+dataType),colorList.length);
       //check predominant color
       if ( part.Cnt < part.tCnt){
       did = id;}

       offset = part.tCnt % 21;
       col = colorList[id];
       if (dataType == 10){
           col = string(abi.encodePacked(col,'IGZpbHRlcj0ndXJsKCNuZW9uKScg')); //filter='url(#neon)' 
       }
       if (part.tCnt >=21){
       (o,om) = joinT21(part.tCnt-offset,o,om,slc,rune,col);
       }
       (o,om) = joinT7(offset,o,om,slc,rune,col);
      
       id = random(stringutils2.UtoString(tokenId*4+dataType),colorList.length);
       offset = part.oCnt % 9;
       col = colorList[id];
       if (dataType == 10){
           col = string(abi.encodePacked(col,'IGZpbHRlcj0ndXJsKCNuZW9uKScg'));//filter='url(#neon)' 
       }
       if (part.oCnt >=9){
       (o,om) = joinO9(part.oCnt-offset,o,om,slc,rune,col);
       }
       (o,om) = joinO3(offset,o,om,slc,rune,col);
       o = string(abi.encodePacked(o,om));

       return (o,did);

    }
    
    function generateBluePrint(skinStruct memory skn,paintStruct memory pnt,compIndexStruct memory p,uint8 cnt1,uint8 cnt2) public view onlyMaster returns (string memory) {
        string memory bp;
           
        bp = string(abi.encodePacked('PC9nPjwvc3ZnPiIsICJhdHRyaWJ1dGVzIjpbIHsidHJhaXRfdHlwZSI6IjAuQk9EWSIsInZhbHVlIjoi', skn.bodies[p.id1].prop,             //</g></svg> ","attributes": [ {"trait_type":"1.BODY", "value":"'
                                     'In0gLCB7InRyYWl0X3R5cGUiOiIxLkhFQUQiICwgInZhbHVlIjoi' ,skn.heads[p.id2].prop,                                                          //""} , {"trait_type":"2.HEAD" , "value":"
                                     'In0seyJ0cmFpdF90eXBlIjoiMi5CT0RZIENPTE9SIiwgInZhbHVlIjoi',pnt.colName[p.idColB],                                                                       
                                     'In0seyJ0cmFpdF90eXBlIjoiMy5IRUFEIENPTE9SIiwgInZhbHVlIjoi',pnt.colName[p.idColH],                                                                
                                     'In0gICwgIHsidHJhaXRfdHlwZSI6IjQuRVlFUyIsInZhbHVlIjoi',skn.eyes[p.id3].prop,                                                                    //"}  ,  {"trait_type":"3.EYES","value":"
                                     'In0seyJ0cmFpdF90eXBlIjoiNS5NT1VUSCIsInZhbHVlIjoi',skn.mouths[p.id4].prop ));                                                              //"} , {"trait_type":"4.MOUTH"," value":"
                                     
                                     
        bp = string(abi.encodePacked( bp,
                                     'In0gLCB7ICJ0cmFpdF90eXBlIjoiNi5TS0lOIiwgInZhbHVlIjoi',skn.skinName,                                                                        //" },{"trait_type":"Skin Name", "value":"
                                     'In0sIHsidHJhaXRfdHlwZSI6IjcuQ09MT1IgUEFMRVRURSIsInZhbHVlIjoi',pnt.chromaName,    
                                     'In0sIHsidHJhaXRfdHlwZSI6IjguVE9UQUwgU0tJTlMiLCJ2YWx1ZSIgOiAi', Base64.encode(stringutils2.uintToByteString(cnt1, 3)),                                        //"},{"trait_type":"Skins Count","value":"
                                     'In0seyJ0cmFpdF90eXBlIjoiOS5UT1RBTCBDT0xPUiBQQUxFVFRFUyIsInZhbHVlIjoi',Base64.encode(stringutils2.uintToByteString(cnt2, 3))                                 //"},{"trait_type":"Color Pallets Count","value":"
                                      ));
        return bp;
    }

    function launchPad(uint256 tokenId,uint8 idxSkin,uint8 idxChroma,uint8 cnt1,uint8 cnt2) public view onlyMaster returns (string memory) {
        string[5] memory p; 
        compIndexStruct memory part;
        paintStruct memory paint;
        
        ICargoShip cargoShip = ICargoShip (cargoShipAddress);
        (paint.eyesColor,paint.color,paint.backgroundColor,paint.colName,paint.effect,paint.chromaName) = cargoShip.unloadChroma(idxChroma);

        part.id0 = random  ( stringutils2.UtoString(tokenId),paint.backgroundColor.length);
        part.id1 = randomW ( stringutils2.UtoString(tokenId+36723),BODY_COUNT);
        part.id2 = randomW ( stringutils2.UtoString(tokenId+12323),HEAD_COUNT);
        part.id3 = random  ( stringutils2.UtoString(tokenId+232)  ,EYES_COUNT);
        part.id4 = random  ( stringutils2.UtoString(tokenId+3993) ,MOUTH_COUNT);
        
        p[0] = string(abi.encodePacked('PHJlY3Qgd2lkdGg9JzEwMCUnICBoZWlnaHQ9JzEwMCUnIGZpbGw9',paint.backgroundColor[part.id0],'Lz4gPGcgZmlsdGVyPSd1cmwoI25lb24pJyA+'));
        
        (p[4],part.idColH) = convertMattertoEnergy(skin[idxSkin].eyes[part.id3],tokenId,paint.eyesColor,10);
        (p[3],part.idColH) = convertMattertoEnergy(skin[idxSkin].mouths[part.id4],tokenId,paint.color,15);
        (p[2],part.idColH) = convertMattertoEnergy(skin[idxSkin].heads[part.id2],tokenId,paint.color,5);
        (p[1],part.idColB) = convertMattertoEnergy(skin[idxSkin].bodies[part.id1],tokenId,paint.color,1);

        p[0] = string(abi.encodePacked(p[0], p[1], p[2], p[3],"PC9nPjxnIGZpbGwtb3BhY2l0eT0nMC44NSc+",p[4])); 

        return string(abi.encodePacked(
                //"image_data": "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'>
                'data:application/json;base64,eyAgImltYWdlX2RhdGEiOiAiPHN2ZyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHByZXNlcnZlQXNwZWN0UmF0aW89J3hNaW5ZTWluIG1lZXQnIHZpZXdCb3g9JzAgMCAzNTAgMzUwJz4g',
                paint.effect,
                p[0],
                generateBluePrint(skin[idxSkin],paint,part,cnt1,cnt2),
                //"}], "name":"OBI #,
                'In0gXSwibmFtZSI6Ik9CSSAj',
                 Base64.encode(stringutils2.uintToByteString(tokenId, 6)),
                //", "description": "OBI ..."} 
                'IiwiZGVzY3JpcHRpb24iOiAiVGhlIGZpcnN0IDEwMCUgT04gQ0hBSU4gcGZwIGNvbGxlY3Rpb24gd2l0aCBpbnRlcmNoYW5nZWFibGUgc2tpbnMgYW5kIGNvbG9yIHBhbGV0dGVzLiJ9'
            ));
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


library stringutils2 {
    
    //Function from chainRunners's implementation - MIT license
    /*
    Convert uint to byte string, padding number string with spaces at end.
    Useful to ensure result's length is a multiple of 3, and therefore base64 encoding won't
    result in '=' padding chars.
    */
    function uintToByteString(uint a, uint fixedLen) internal pure returns (bytes memory _uintAsString) {
        uint j = a;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(fixedLen);
        j = fixedLen;
        if (a == 0) {
            bstr[0] = "0";
            len = 1;
        }
        while (j > len) {
            j = j - 1;
            bstr[j] = bytes1(' ');
        }
        uint k = len;
        while (a != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(a - a / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            a /= 10;
        }
        return bstr;
    }

    function UtoString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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

}

// SPDX-License-Identifier: Apache License 2.0
// part off library https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */
pragma solidity ^0.8.6;


library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }
   
    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }
   /*
   * @dev Copies a slice to a new string.
   * @param self The slice to copy.
   * @return A newly allocated string containing the slice's text.
   */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }
/*
 * @dev Splits the slice, setting `self` to everything after the first
 *      occurrence of `needle`, and returning everything before it. If
 *      `needle` does not occur in `self`, `self` is set to the empty slice,
 *      and the entirety of `self` is returned.
 * @param self The slice to split.
 * @param needle The text to search for in `self`.
 * @return The part of `self` up to the first occurrence of `delim`.
 */
function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
   } 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}