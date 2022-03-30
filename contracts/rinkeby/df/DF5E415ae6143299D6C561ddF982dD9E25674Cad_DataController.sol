/**
 *Submitted for verification at Etherscan.io on 2022-03-30
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
    SvgData[] private backgroundList;
    SvgData[] private faceList;
    SvgData[] private bodyList;

    // BG
    function AddNewBackground(string memory _svg) public
    {
        backgroundList.push(new SvgData(_svg));
    }

    function GetBackgroundCount() public view returns (uint)
    {
        return backgroundList.length;
    }

    function GetBackground(uint _index) public view returns (string memory _svg)
    {
        return backgroundList[_index].svg();
    }

    // BODY
    function AddNewBody(string memory _svg) public
    {
        bodyList.push(new SvgData(_svg));
    }

    function GetBodyCount() public view returns (uint)
    {
        return bodyList.length;
    }

    function GetBody(uint _index) public view returns (string memory _svg)
    {
        return bodyList[_index].svg();
    }

    // FACE
    function AddNewFace(string memory _svg) public
    {
        faceList.push(new SvgData(_svg));
    }

    function GetFaceCount() public view returns (uint)
    {
        return faceList.length;
    }

    function GetFace(uint _index) public view returns (string memory _svg)
    {
        return faceList[_index].svg();
    }
}