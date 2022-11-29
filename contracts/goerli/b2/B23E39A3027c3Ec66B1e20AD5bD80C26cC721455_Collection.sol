//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Collection {


    constructor(address admin) {
        adminer[msg.sender] = 1;
        adminer[admin] = 1;
    }


    event Collect (
        uint256 ctId,
        string ctAddress,
        string ctBanner,
        string ctImage,
        string ctName,
        string ctDetails,
        string ctUrl_1,
        string ctUrl_2,
        string ctUrl_3,
        string releaseTime,
        uint256 weight
    );

    struct Data {
        uint256 ctId;
        string ctAddress;
        string ctBanner;
        string ctImage;
        string ctName;
        string ctDetails;
        string ctUrl_1;
        string ctUrl_2;
        string ctUrl_3;
        string releaseTime;
        uint256 weight;
    }

    Data[] public datas; 
    uint256 Index = 0;
    mapping (address => uint) adminer;
    
    modifier isadminer() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(adminer[msg.sender] == 1, "Caller is not adminer");
        _;
    }
    
    function changeAdminer(address newAdminer,uint state) public isadminer {
        require(state == 1 || state ==0 ,"state failed");
        adminer[newAdminer] = state;
    }


    function insertCollect(
        string memory ContractAddress,
        string memory Banner,
        string memory Image,
        string memory Name,
        string memory Details,
        string memory Url_1,
        string memory Url_2,
        string memory Url_3,
        string memory ReleaseTime,
        uint256 Weight
    )  external isadminer returns (uint256) {

        Data memory data = Data({
            ctId : Index,
            ctAddress : ContractAddress,
            ctBanner : Banner,
            ctImage : Image,
            ctName : Name,
            ctDetails : Details,
            ctUrl_1 : Url_1,
            ctUrl_2 : Url_2,
            ctUrl_3 : Url_3,
            releaseTime:ReleaseTime,
            weight :Weight
        });
        datas.push(data);
        Index++;

        emit Collect(
            data.ctId,
            data.ctAddress,
            data.ctBanner,
            data.ctImage,
            data.ctName,
            data.ctDetails,
            data.ctUrl_1,
            data.ctUrl_2,
            data.ctUrl_3,
            data.releaseTime,
            data.weight
        );

        return Index;
    }

    function changeNews(
        uint256 cgId,
        string memory ContractAddress,
        string memory Banner,
        string memory Image,
        string memory Name,
        string memory Details,
        string memory Url_1,
        string memory Url_2,
        string memory Url_3,
        string memory ReleaseTime,
        uint256 Weight
    )  external isadminer returns (uint256) {
        
        require(datas[cgId].ctId >=0 ,"not found news");

        Data memory data = Data({
            ctId : cgId,
            ctAddress : ContractAddress,
            ctBanner : Banner,
            ctImage : Image,
            ctName : Name,
            ctDetails : Details,
            ctUrl_1 : Url_1,
            ctUrl_2 : Url_2,
            ctUrl_3 : Url_3,
            releaseTime:ReleaseTime,
            weight :Weight
        });
        datas[cgId]=data;

        emit Collect(
            data.ctId,
            data.ctAddress,
            data.ctBanner,
            data.ctImage,
            data.ctName,
            data.ctDetails,
            data.ctUrl_1,
            data.ctUrl_2,
            data.ctUrl_3,
            data.releaseTime,
            data.weight
        );
        return cgId;
    }

    // function getNewsInfo(uint256 ctId)
    //     external
    //     view
    // returns (Data memory)
    // {
    //     return datas[ctId];
    // }


}