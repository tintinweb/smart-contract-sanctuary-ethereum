/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// Solidity 註解可參考: https://docs.soliditylang.org/en/develop/natspec-format.html
contract Certification_1_0_0 {

    string public constant version = "1.0.0-SNAPSHOT";

    struct Certification {
        string chineseName;
        string englishName;
        address walletAddress;
        uint256 startTime;
        uint256 expireTime;
        uint256 id;
    }

    struct AllowAddress {
        address walletAddress;
        bool enable;
    }

    uint256 public certificationCounts;
    uint256 public walletCounts;
    mapping(address => uint256[]) walletIndexMap;
    mapping(uint256 => Certification) certifications;
    mapping(uint256 => address) public walletRecords;

    uint256 public allowAddressCounts;
    mapping(address => uint256) public allowAddressIndexMap;
    mapping(uint256 => AllowAddress) allowAddressRecords;

    modifier allowAddress() {
        uint256 index = allowAddressIndexMap[msg.sender];
        require(allowAddressRecords[index].enable == true, "address invalid");
        _;
    }

    constructor(
        address _initAddress
    )
    {
        allowAddressCounts = 1;
        allowAddressIndexMap[_initAddress] = allowAddressCounts;
        allowAddressRecords[allowAddressCounts] = AllowAddress(_initAddress, true);
    }

    event CertificationRes(
        string chineseName,
        string englishName,
        address walletAddress,
        uint256 startTime,
        uint256 expireTime
    );

    //    get the size of certifications by address
    function getCertificationSize(address _address) public view returns (uint256){
        uint256[] memory indexList = walletIndexMap[_address];
        return indexList.length;
    }

    //    get last certification by address
    function getLastCertification(address _address) public view returns (Certification memory) {
        uint256[] memory indexList = walletIndexMap[_address];
        require(indexList.length > 0, "empty certification");
        return certifications[indexList[indexList.length - 1]];
    }


    //    get certification list with page number and size by address
    //    page size cant larger than 20 due to ethereum limit
    function getCertificationListByAddress(address _address, uint256 pageNumber, uint256 pageSize) public view returns (Certification[] memory){
        uint256[] memory indexList = walletIndexMap[_address];
        require(indexList.length > 0, "empty certification");
        require(pageSize < 20, "batch size too large");
        uint256 startIndex = pageSize * pageNumber;
        uint256 endIndex = (startIndex + pageSize) > indexList.length ? indexList.length : (startIndex + pageSize);
        require(indexList.length > startIndex, "index out of bound");

        Certification[] memory certList = new Certification[](pageSize);
        uint saveCount = 0;
        for (uint256 i = startIndex; i < endIndex; i++) {
            certList[saveCount] = certifications[indexList[i]];
            saveCount++;
        }
        return certList;
    }

    //    get certification list by page number and size, which did not depend on any address
    function getCertificationList(uint256 pageNumber, uint256 pageSize) public view returns (Certification[] memory){
        require(pageSize < 20, "batch size too large");
        uint256 startIndex = pageSize * pageNumber;
        uint256 endIndex = (startIndex + pageSize) > certificationCounts ? certificationCounts : (startIndex + pageSize);
        require(certificationCounts > startIndex, "index out of bound");

        Certification[] memory certList = new Certification[](pageSize);
        uint saveCount = 0;
        for (uint256 i = startIndex; i < endIndex; i++) {
            certList[saveCount] = certifications[i];
            saveCount++;
        }
        return certList;
    }

    //    get certification by address and timestamp is in certification range
    function getCertificationByTimestamp(address _address, uint256 timestamp) public view returns (Certification memory _cert){
        uint256[] memory indexList = walletIndexMap[_address];
        require(indexList.length > 0, "empty certification");

        for (uint256 i = indexList.length - 1; i >= 0; i--) {
            Certification memory cert = certifications[indexList[i]];
            if (cert.startTime < timestamp && cert.expireTime > timestamp) {
                return cert;
            }
        }
        revert();
    }

    //    get certification by address and index
    //    index: start from 0, which means the index of certifications according to the address
    function getCertificationByIndex(address _address, uint256 index) public view returns (Certification memory) {
        uint256[] memory indexList = walletIndexMap[_address];
        require(indexList.length > index, "index out of bound");

        return certifications[indexList[index]];
    }

    event NewCertification(Certification);

    function writeCertification(
        string memory _chineseName,
        string memory _englishName,
        address _walletAddress,
        uint256 _startTime,
        uint256 _expireTime
    )
    public
    allowAddress
    returns (Certification memory)
    {
        Certification memory cert = Certification(
            _chineseName,
            _englishName,
            _walletAddress,
            _startTime,
            _expireTime,
            certificationCounts
        );
        certifications[certificationCounts] = cert;
        if (walletIndexMap[_walletAddress].length == 0) {
            bool found = false;
            for (uint256 i = 0; i < walletCounts; i++) {
                if (walletRecords[i] == _walletAddress) {
                    found = true;
                }
            }
            if (!found) {
                walletRecords[walletCounts] = _walletAddress;
                walletCounts++;
            }
        }
        walletIndexMap[_walletAddress].push(certificationCounts);
        certificationCounts ++;
        emit NewCertification(cert);
        return cert;
    }

    function editCertification(
        uint256 id,
        string memory _chineseName,
        string memory _englishName,
        address _walletAddress,
        uint256 _startTime,
        uint256 _expireTime
    )
    public
    allowAddress
    returns (Certification memory)
    {
        require(certifications[id].walletAddress == _walletAddress, "certification address is not equal to input address");
        certifications[id] = Certification(_chineseName, _englishName, _walletAddress, _startTime, _expireTime, id);
        Certification memory cert = certifications[id];
        emit NewCertification(cert);
        return cert;
    }

    function deleteCertification(address _address, uint256 id) public allowAddress returns (Certification memory) {
        require(certifications[id].walletAddress == _address, "certification address is not equal to input address");
        uint256[] storage indexArray = walletIndexMap[_address];
        require(indexArray.length > 0, "certification not in wallet index map");

        Certification memory deleteInfo = certifications[id];
        delete certifications[id];
        bool foundIndex = false;
        for (uint256 i = 0; i < indexArray.length - 1; i++) {
            if (foundIndex) {
                indexArray[i] = indexArray[i + 1];
            } else {
                if (indexArray[i] == id) {
                    foundIndex = true;
                    indexArray[i] = indexArray[i + 1];
                }
            }
        }
        indexArray.pop();
        emit NewCertification(deleteInfo);
        return deleteInfo;
    }

    function setAllowAddress(address _addAddress) public allowAddress {
        if (allowAddressIndexMap[_addAddress] == 0) {
            allowAddressCounts++;
            allowAddressIndexMap[_addAddress] = allowAddressCounts;
            allowAddressRecords[allowAddressCounts] = AllowAddress(_addAddress, true);
        } else {
            uint256 index = allowAddressIndexMap[_addAddress];
            allowAddressRecords[index].enable = true;
        }

    }

    function disableAllowAddress(address _address) public allowAddress {
        uint256 index = allowAddressIndexMap[_address];
        allowAddressRecords[index].enable = false;
    }

    function isAllowAddress(address _address) public view returns (AllowAddress memory){
        uint256 index = allowAddressIndexMap[_address];
        if (index == 0) {return AllowAddress(
            _address,
            false
        );}
        else {return allowAddressRecords[index];}
    }

    function getAllowAddressList(uint256 pageNum, uint256 pageSize) public view returns (AllowAddress[] memory){
        require(pageSize < 20, "pageSize too large");
        require(pageNum * pageSize + 1 <= allowAddressCounts, "request index out of bound");
        uint256 startIndex = pageNum * pageSize + 1;
        uint256 endIndex = allowAddressCounts > startIndex + pageSize ? startIndex + pageSize : allowAddressCounts;
        require(allowAddressCounts >= startIndex, "index out of bound");

        AllowAddress[] memory returnMap = new AllowAddress[](pageSize);
        uint256 saveIndex = 0;
        for (uint256 i = startIndex; i <= endIndex; i++) {
            returnMap[saveIndex] = allowAddressRecords[i];
            saveIndex++;
        }
        return returnMap;
    }
}