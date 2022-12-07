/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Cardamom {
    address spicesBoard;

    constructor() {
        spicesBoard = msg.sender;
    }
// Declaring admin authority to the spices board
    modifier onlyspicesBoard() {
        require(msg.sender == spicesBoard, "Insufficient privilege");
        _;
    }
 // struct for saving the data of cardamom
    struct cardamomData {
        string farmerName;
        string origin;
        string harvestedDate;
        string expiryDate;
        uint256 weight;
    }

    mapping(string => cardamomData) public cardamomDetails;
    
// adding new cardamom information to the blockchain by Spices Board
    function newCardamomData(
        string memory _batchID,
        string memory _farmerName,
        string memory _origin,
        string memory _harvestedDate,
        string memory _expiryDate,
        uint256 _weight
    ) public onlyspicesBoard {
        cardamomDetails[_batchID] = cardamomData(
            _farmerName,
            _origin,
            _harvestedDate,
            _expiryDate,
            _weight
        );
    }
// struct for saving the data of cardamom
    struct pesticideData {
        string color;
        uint256 aceta;
        uint256 dithio;
        string date;
        
    }

    mapping(string => pesticideData) public pesticideDetails;
    
// adding new cardamom information to the blockchain by Spices Board
    function newTestingData(
        string memory _batchID,
        string memory _color,
        uint256 _aceta,
        uint256 _dithio,
        string memory _date

    ) public onlyspicesBoard {
        pesticideDetails[_batchID] = pesticideData(
            _color,
            _aceta,
            _dithio,
            _date
        );

    }
}