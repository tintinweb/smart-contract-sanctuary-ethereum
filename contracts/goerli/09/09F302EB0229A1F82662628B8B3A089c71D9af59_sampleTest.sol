/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
testing contract
 */

contract sampleTest
{

    struct Data {
        string firstName;
        string middleName;
        string lastName;
        string phoneNo;
    }

    //wallet address => email=> array of Data
    mapping(string => Data[]) allDataList;

    /**************************************************/
    /************** Public View Functions *************/
    /**************************************************/

    function getTotalIndex(string memory _email) public view returns (uint256) {
        return allDataList[_email].length;
    }

    function getData(string memory _email, uint256 index)
        public
        view
        returns (Data memory)
    {
        return allDataList[_email][index];
    }

    function getAllData(string memory _email)
        public
        view
        returns (Data[] memory)
    {
        return allDataList[_email];
    }

    /**************************************************/
    /********** EXternal Contract Functions ***********/
    /**************************************************/

    function store(
        string memory _email,
        Data memory newData
        ) public {
        allDataList[_email].push(
            newData
        );
    }

    function update(
        string memory _email,
        Data memory newData,
        uint256 index
    ) public {
        allDataList[_email][index] = newData;
    }

    function storeAll(
        string memory _email,
        Data[] memory newData
        ) public {
            for(uint i=0; i<newData.length;i++){
                allDataList[_email][i]=newData[i];            
            }
    }
}