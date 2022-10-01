// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Keisuke OHNO

/*

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

import { Base64 } from 'base64-sol/base64.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity >=0.7.0 <0.9.0;


interface iNFT {
    function balanceOf(address _address) external view returns (uint256);
    function name() external view returns (string memory);
}

interface iSBT {
    function ownerOf(uint256 _tokenId) external view returns (address);
}


contract SBTtokenURI is Ownable{

    string baseURI;
    string public baseExtension = ".json";
    string public baseImageExtension = ".png";
    iSBT public SBT;
    string public tokenName = "Your score is";
    string public tokenNameExtension = "!";
    uint256 public levelExp = 1000000;
    uint256 public maxImageNumber = 45;

    struct NFTCollection {
        iNFT NFTinterface;
        uint256 coefficient;
        string name;
        bool isVisible;
    }

    uint256 numberOfNFTCollections;
    mapping(uint256 => NFTCollection) public NFT;

    constructor(){
        setBaseURI("https://data.zqn.wtf/qnrank/images/");
        SBT  = iSBT(0x3Af3A277b6F5ff2162669Df804fb8aeb2589F672);

        //main net
        setCollectionData( 1 , 0x3Af3A277b6F5ff2162669Df804fb8aeb2589F672 , 1 , "NFT Checker SBT" , true);
        setCollectionData( 2 , 0x79d43460f3CB215bB78a8761aca0C6808263b0d4 , 1 , "KareQN!" , true);
        setCollectionData( 3 , 0x891AA1C3964D3a83554E4D1108c5964cE5441a1a , 1 , "QN Passport Genesis" , true);
        setCollectionData( 4 , 0xA728453157BBf28177462AbFEa5E7db9d7D70774 , 1 , "QN" , true);
        setCollectionData( 5 , 0xB270Ab4B03dbf46c6697E600671Bd4917d6Ea0De , 1 , "ZQN! Phase Zero" , true);
        setCollectionData( 6 , 0xe62482263Ac31d229875dCb9E5CfdadD7627e495 , 1 , "SanuQN!" , true);
        setNumberOfNFTCollections(6);

        //test
        //setCollectionData( 1 , 0x4e566bAee00E799a884f35CCe06C7D806C024A7F , 1 , "CollectionA" , true);
        //setCollectionData( 2 , 0x4e566bAee00E799a884f35CCe06C7D806C024A7F , 1 , "CollectionB" , false);
        //setCollectionData( 3 , 0x4e566bAee00E799a884f35CCe06C7D806C024A7F , 1 , "CollectionC" , true);
        //setNumberOfNFTCollections(3);
    }


    function setSBT(address _address) public onlyOwner() {
        SBT = iSBT(_address);
    }

    function setNumberOfNFTCollections(uint256 _numberOfNFTCollections) public onlyOwner{
        numberOfNFTCollections = _numberOfNFTCollections;
    }

    function setCoefficient(uint256 _CollectionId , uint256 _coefficient) public onlyOwner{
        NFT[_CollectionId].coefficient = _coefficient;
    }
    
    function setIsVisible(uint256 _CollectionId , bool _isVisible) public onlyOwner{
        NFT[_CollectionId].isVisible = _isVisible;
    }

    function setCollectionData(uint256 _CollectionId , address _address , uint256 _coefficient , string memory _name , bool _isVisible) public onlyOwner{
        NFT[_CollectionId].NFTinterface = iNFT(_address);  
        NFT[_CollectionId].coefficient = _coefficient;
        NFT[_CollectionId].name = _name;
        NFT[_CollectionId].isVisible = _isVisible;
    }

    // internal
    function _baseURI() internal view returns (string memory) {
        return baseURI;        
    }

    //public
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return string( abi.encodePacked( 'data:application/json;base64,' , Base64.encode(bytes(encodePackedJson(tokenId))) ) );
    }

    function encodePackedJson(uint256 _tokenId) public view returns (bytes memory) {
        string memory name = _toString(calcPoint(_tokenId));
        string memory description = "If you do not need this token, please transfer it to 0x000000000000000000000000000000000000dEaD.";
        return abi.encodePacked(
            '{',
                '"name":"', tokenName , ' ' , name, ' ' , tokenNameExtension , '",' ,
                '"description":"', description, '",' ,
                '"image": "', _baseURI(), _toString(imageNumber(_tokenId)) , baseImageExtension , '",' ,
                '"attributes": [' ,
                        collectionDataOutput(_tokenId) ,
                ']',
            '}'
        );
    }

    function collectionDataOutput(uint256 _tokenId) public view returns(string memory){
        string memory outputStr;
        for(uint256 i = numberOfNFTCollections ; 1 <= i ; i--){
            if( NFT[i].isVisible == false){
                continue;
            }
            if( NFT[i].NFTinterface.balanceOf(SBT.ownerOf(_tokenId)) == 0){
                continue ;
            }
            outputStr = _strConnect( outputStr , '{');
            outputStr = _strConnect( outputStr , '"trait_type": ');
            outputStr = _strConnect( outputStr , '"');
            outputStr = _strConnect( outputStr , NFT[i].name );
            outputStr = _strConnect( outputStr , '"');
            outputStr = _strConnect( outputStr , ',');
            outputStr = _strConnect( outputStr , '"value": ');
            outputStr = _strConnect( outputStr , _toString(NFT[i].NFTinterface.balanceOf(SBT.ownerOf(_tokenId))));
            outputStr = _strConnect( outputStr , '}');
            if( 1 < i ){
                outputStr = _strConnect( outputStr , ',');
            }
        }
        return outputStr;
    }

    function calcPoint(uint256 _tokenId)public view returns ( uint256 ){
        uint256 point = 0;
        for(uint256 i = 1 ; i <= numberOfNFTCollections ; i++){
            if( NFT[i].isVisible == false){
                continue;
            }
            point += NFT[i].NFTinterface.balanceOf(SBT.ownerOf(_tokenId)) * NFT[i].coefficient ;   
        }
        return point;
    }

    function imageNumber(uint256 _tokenId)public view returns ( uint256 ){
        uint256 number;
        number = (calcPoint(_tokenId) / levelExp) + 1;
        if( maxImageNumber < number ){
            number = maxImageNumber;
        }
        return number;
    }

    function setTokenName(string memory _tokenName) public onlyOwner {
        tokenName = _tokenName;
    }
    function setTokenNameExtension(string memory _tokenNameExtension) public onlyOwner {
        tokenNameExtension = _tokenNameExtension;
    }

    function setMaxImageNumber(uint256 _maxImageNumber) public onlyOwner {
        maxImageNumber = _maxImageNumber;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setLevelExp(uint256 _levelExp) public onlyOwner {
        levelExp = _levelExp;
    }

    function setBaseImageExtension(string memory _newBaseImageExtension) public onlyOwner {
        baseImageExtension = _newBaseImageExtension;
    }

    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    function _strConnect(string memory str1, string memory str2) private pure returns(string memory) {
        bytes memory strbyte1 = bytes(str1);
        bytes memory strbyte2 = bytes(str2);
        bytes memory str = new bytes(strbyte1.length + strbyte2.length);
        uint8 point = 0;
        for(uint8 j = 0; j < strbyte1.length;j++){
            str[point] = strbyte1[j];
            point++;
        }
        for(uint8 k = 0; k < strbyte2.length;k++){
            str[point] = strbyte2[k];
            point++;
        }
        return string(str);
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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