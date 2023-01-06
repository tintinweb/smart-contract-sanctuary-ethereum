/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract DataAccessControl {

    address distributor;
    string dataURL;
    string dataDescription;
    mapping(int32 => bytes32) encSEK;
    int32[] indxsKEK;

    constructor(string memory _url, string memory _desc) {
        distributor = msg.sender;
        dataURL = _url;
        dataDescription = _desc;

        emit NewContentAlert(dataURL, dataDescription);
    }

    event NewContentAlert(
        string dataURL,
        string dataDescription
    );

    function subscribeRequest(bytes32 leafKEKHash) public {
        emit NewSubscribeRequestAlert(msg.sender, leafKEKHash);
    }

    event NewSubscribeRequestAlert(
        address subscriber,
        bytes32	leafKEKHash
    );

    function updateKeys(int32[] memory indxs, bytes32[] memory vals) public {
        if (msg.sender != distributor)	return;

        uint32 i;
        for (i=0; i<indxsKEK.length; i++) {
            delete encSEK[indxsKEK[i]];
        }

        for (i=0; i<indxs.length; i++)	{
            encSEK[indxs[i]] = vals[i];
        }

        indxsKEK = indxs;

        emit KeysupdatedAlert();
    }

    event KeysupdatedAlert();

    function getEncSEKByKEKIndex(int32[] memory indxs) public view returns (int32, bytes32) {
        int32 res_kekIndx = -1;
        bytes32 res_encSEK = 0;

        uint i;
        for(i=0; i<indxs.length && res_encSEK==0; i++) {
            res_encSEK = encSEK[indxs[i]];
        }

        if(res_encSEK != 0) res_kekIndx	= indxs[i-1];

        return (res_kekIndx, res_encSEK);
    }
 }