/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

abstract contract OwnerHelper {
    address private _owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner() {
        require(msg.sender == _owner, "OwnerHelper: caller is not owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address _to) public onlyOwner {
        require(_to != _owner);
        require(_to != address(0x0));
        // address _from = _owner;
        _owner = _to;
        emit OwnershipTransferred(_owner, _to);
    }
}

abstract contract IssuerHelper is OwnerHelper {
    mapping(address => bool) private issuers;

    event AddIssuer(address _address);
    event DelIssuer(address _address);

    modifier onlyIssuer() {
        require(
            issuers[msg.sender] == true,
            "IssuerHelper: caller is not issuers"
        );
        _;
    }

    constructor() {
        issuers[msg.sender] = true;
    }

    function addIssuer(address _address) public onlyOwner returns (bool) {
        issuers[_address] = true;
        require(issuers[_address] == true);
        emit AddIssuer(_address);
        return true;
    }

    function isIssuer(address _address) public view returns (bool) {
        return issuers[_address];
    }

    function delIssuer(address _address) public onlyOwner returns (bool) {
        issuers[_address] = false;
        require(issuers[_address] == false);
        emit DelIssuer(_address);
        return true;
    }
}

contract VaccineDID is IssuerHelper {
    uint256 private idCount;
    mapping(uint8 => string) private vaccineType; // 백신타입 - 화이자, 모더나,,,
    mapping(uint8 => string) private hitCount;

    event Result(string);

    struct Credential {
        uint256 id;
        string vaccine;
        string cnt;
        string value;
    }

    mapping(address => Credential) private credentials;

    constructor() {
        idCount = 1;
        vaccineType[0] = "Pfizer";
        vaccineType[1] = "Moderna";
        vaccineType[2] = "AZ";

        hitCount[0] = unicode"1차 접종완료";
        hitCount[1] = unicode"2차 접종완료";
        hitCount[2] = unicode"3차 접종완료";
    }

    // 인증서 발급
    function claimCredential(
        address _addr,
        uint8 _vaccineType,
        uint8 _hitCount,
        string calldata _value
    ) public onlyIssuer returns (bool) {
        Credential storage credential = credentials[_addr];

        credential.id = idCount;
        credential.vaccine = vaccineType[_vaccineType];
        credential.cnt = hitCount[_hitCount];
        credential.value = _value;

        idCount += 1;
        emit Result("VC certificate issuance completed ");

        return true;
    }

    // 인증서 확인
    function getCredential(address _citizenaddress)
        public
        view
        returns (Credential memory)
    {
        return credentials[_citizenaddress];
    }
}