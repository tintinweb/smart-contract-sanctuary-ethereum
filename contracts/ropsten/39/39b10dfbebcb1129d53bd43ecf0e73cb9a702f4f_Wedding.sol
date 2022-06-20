/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

/** Wedding contract */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Wedding {
    string public firtsPersonName;
    string public secondPersonName;
    string public weddingDate;
    string public weddingPlace;
    string public weddingTime;
    string public weddingAddress;
    string public weddingCity;

    constructor(
        string memory _firtsPersonName,
        string  memory _secondPersonName,
        string memory _weddingDate,
        string memory _weddingPlace,
        string memory _weddingTime,
        string memory _weddingAddress,
        string memory _weddingCity
    ) public {
        firtsPersonName = _firtsPersonName;
        secondPersonName = _secondPersonName;
        weddingDate = _weddingDate;
        weddingPlace = _weddingPlace;
        weddingTime = _weddingTime;
        weddingAddress = _weddingAddress;
        weddingCity = _weddingCity;
    }

    /** getWedding
     returns the wedding details */
    function get()
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            string memory
        )
    {
        return (
            firtsPersonName,
            secondPersonName,
            weddingDate,
            weddingPlace,
            weddingTime,
            weddingAddress,
            weddingCity
        );
    }

    // /** setWedding
    //  sets the wedding details */
    // function set(
    //     string memory _firtsPersonName,
    //     string memory _secondPersonName,
    //     string memory _weddingDate,
    //     string memory _weddingPlace,
    //     string memory _weddingTime,
    //     string memory _weddingAddress,
    //     string memory _weddingCity
    // ) public {
    //     firtsPersonName = _firtsPersonName;
    //     secondPersonName = _secondPersonName;
    //     weddingDate = _weddingDate;
    //     weddingPlace = _weddingPlace;
    //     weddingTime = _weddingTime;
    //     weddingAddress = _weddingAddress;
    //     weddingCity = _weddingCity;
    // }

}