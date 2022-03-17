/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;



// File: BasicDataStorage.sol

contract BasicDataStorage {
    uint256 favoriteNumber;

    struct Transmittal {
        string project;
        uint256 drawingNumber;
        uint256 date;
    }

    Transmittal[] public transmittals;

    mapping(string => uint256) public projectToDrawingNumber;

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function update(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function addTransmittal(
        string memory _project,
        uint256 _drawingNumber,
        uint256 _date
    ) public {
        require(bytes(_project).length > 0);
        require(_drawingNumber > 0);
        require(_date > 0);
        transmittals.push(Transmittal(_project, _drawingNumber, _date));
        projectToDrawingNumber[_project] = _drawingNumber;
    }
}