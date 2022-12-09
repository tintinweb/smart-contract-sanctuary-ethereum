//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract MarketConfigure {
    function indexOf(address[] memory self, address value) private pure
        returns (uint)
    {
        for (uint i = 0; i < self.length; i++)
            if (self[i] == value) return i;
        return type(uint).max;
    }
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

    event HotAddress (
       address[]
    );

    struct Collects {
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


    Collects[] public collects; 
    uint256 Index = 0;
    mapping (address => uint) adminer;
    address[] public storedAddresses;
    
    modifier isadminer() {
        require(adminer[msg.sender] == 1, "Caller is not adminer");
        _;
    }
    
    function changeAdminer(address adminerAddr,uint state) public isadminer {
        require(state == 1 || state ==0 ,"state failed");
        adminer[adminerAddr] = state;
    }


    function addCollect(
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

        Collects memory data = Collects({
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
        collects.push(data);
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

    function changeCollect(
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
        
        require(collects[cgId].ctId >=0 ,"not found Collect");

        Collects memory data = Collects({
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
        collects[cgId]=data;

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

    function removeCollect(
        uint256 cgId
    )  external isadminer returns (uint256) {
        
        require(collects[cgId].ctId >=0 ,"not found Collect");

        delete collects[cgId];

        emit Collect(
            collects[cgId].ctId,
            collects[cgId].ctAddress,
            collects[cgId].ctBanner,
            collects[cgId].ctImage,
            collects[cgId].ctName,
            collects[cgId].ctDetails,
            collects[cgId].ctUrl_1,
            collects[cgId].ctUrl_2,
            collects[cgId].ctUrl_3,
            collects[cgId].releaseTime,
            collects[cgId].weight
        );
        return cgId;
    }


    function addAddress(address _address) external isadminer {
        uint findindex = indexOf(storedAddresses,_address);
        require(findindex == type(uint).max,"address Already exists");
        storedAddresses.push(_address);

        emit HotAddress(storedAddresses);
    }

    function removeAddress(address _address) external isadminer {
        uint findindex = indexOf(storedAddresses,_address);
        if (findindex != type(uint).max) {
            delete storedAddresses[findindex];
        }
        emit HotAddress(storedAddresses);
    }

    function getAddresses() public view returns (address[] memory) {
        return storedAddresses;
    }

}