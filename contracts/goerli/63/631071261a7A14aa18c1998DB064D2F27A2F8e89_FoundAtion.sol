//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FoundAtion {


    constructor() {
        adminer[msg.sender] = 1;
    }


    event News (
        uint256  indexed newsId,
        string newsType,
        string newsTitle,
        string newsauther,
        string newsImg,
        string newsData,
        uint256 newsCreateTime,
        uint256 newsUpdateTime
    );

    struct Data {
        uint256 newsId;
        string newsType;
        string newsTitle;
        string newsauther;
        string newsImg;
        string newsData;
        uint256 newsCreateTime;
        uint256 newsUpdateTime;
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


    function insertNews(
        string memory Type,
        string memory Title,
        string memory Auther,
        string memory Img,
        string memory FdData
    )  external isadminer returns (uint256) {

        Data memory data = Data({
            newsId : Index,
            newsType : Type,
            newsTitle : Title,
            newsauther : Auther,
            newsImg : Img,
            newsData : FdData,
            newsCreateTime : block.timestamp,
            newsUpdateTime : block.timestamp
        });
        datas.push(data);
        Index++;

        emit News(
            data.newsId,
            data.newsType,
            data.newsTitle,
            data.newsauther,
            data.newsImg,
            data.newsData,
            data.newsCreateTime,
            data.newsUpdateTime
        );

        return Index;
    }

    function changeNews(
        uint256 newsId,
        string memory Type,
        string memory Title,
        string memory Auther,
        string memory Img,
        string memory FdData
    )  external isadminer returns (uint256) {
        
        Data memory oneNews = datas[newsId];
        require(oneNews.newsId >=0 ,"not found news");

        Data memory data = Data({
            newsId : newsId,
            newsType : Type,
            newsTitle : Title,
            newsauther : Auther,
            newsImg : Img,
            newsData : FdData,
            newsCreateTime : block.timestamp,
            newsUpdateTime : block.timestamp
        });
        datas[newsId]=data;


        emit News(
            data.newsId,
            data.newsType,
            data.newsTitle,
            data.newsauther,
            data.newsImg,
            data.newsData,
            data.newsCreateTime,
            data.newsUpdateTime
        );

        return newsId;
    }

    function getNewsInfo(uint256 newsId)
        external
        view
    returns (Data memory)
    {
        return datas[newsId];
    }


}