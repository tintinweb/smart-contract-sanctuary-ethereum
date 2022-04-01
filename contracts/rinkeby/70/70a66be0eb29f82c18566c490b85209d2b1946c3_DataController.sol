/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// File: contracts/SvgData.sol



pragma solidity ^0.8.0;

contract SvgData
{
    string public svg;

    constructor(string memory _svg)
    {
        svg = _svg;
    }
}
// File: contracts/DataController.sol



pragma solidity ^0.8.0;


contract DataController
{
    SvgData[] private bodyList;
    SvgData[] private clothList;
    SvgData[] private faceList;
    SvgData[] private topList;

    // BG
    function addNewBody(string memory _svg) public
    {
        bodyList.push(new SvgData(_svg));
    }

    function getBodyCount() public view returns (uint)
    {
        return bodyList.length;
    }

    function getBody(uint index) public view returns (string memory svg)
    {
        return bodyList[index].svg();
    }

    // BODY
    function addNewCloth(string memory _svg) public
    {
        clothList.push(new SvgData(_svg));
    }

    function getClothCount() public view returns (uint)
    {
        return clothList.length;
    }

    function getCloth(uint index) public view returns (string memory svg)
    {
        return clothList[index].svg();
    }

    // FACE
    function addNewFace(string memory _svg) public
    {
        faceList.push(new SvgData(_svg));
    }

    function getFaceCount() public view returns (uint)
    {
        return faceList.length;
    }

    function getFace(uint index) public view returns (string memory svg)
    {
        return faceList[index].svg();
    }

    // TOP
    function addNewTop(string memory _svg) public
    {
        topList.push(new SvgData(_svg));
    }

    function getTopCount() public view returns (uint)
    {
        return topList.length;
    }

    function getTop(uint index) public view returns (string memory svg)
    {
        return topList[index].svg();
    }
}