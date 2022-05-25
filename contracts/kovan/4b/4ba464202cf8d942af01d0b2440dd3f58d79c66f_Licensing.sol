/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Licensing
{
    enum TraceType {
        CREATE,
        EXTEND,
        TRANSFER
    }

    event Trace(
        TraceType indexed tracetype,
        bytes32 indexed identifier,
        uint ltype,
        uint expiry,
        uint issuance
    );

    address private _issuer;
    mapping(uint => uint) private _rate;

    mapping(bytes32 => License) private _licenses;

    struct License {
        uint ltype;
        uint expiry;
        uint issuance;
    }

    constructor(address issuer) {
        _issuer = issuer;
        _rate[uint(0)] = 15;
    }

    function purchase(address owner, uint lt, uint dc, bytes32 hwid) public payable {
        require(msg.value == getLicensePrice(lt, dc));
        _create(owner, lt, dc, hwid);
    }

    function transfer(bytes32 hwid, address toAddress, bytes32 toHwid) public
    {
        require(msg.sender != toAddress);

        bytes32 identifier = getLicenseIdentifier(msg.sender, hwid);
        bytes32 toIdentifier = getLicenseIdentifier(toAddress, toHwid);

        require(_isLicenseValid(identifier), "Only valid licenses are transferable");
        require(_isLicenseValid(toIdentifier) == false, "Cannot overwrite on existing license");

        License memory license = _licenses[identifier];

        _licenses[toIdentifier] = License({
            ltype: license.ltype,
            expiry: license.expiry,
            issuance: block.timestamp
        });

        delete _licenses[identifier];
        emit Trace(TraceType.TRANSFER, toIdentifier, license.ltype, license.expiry, license.issuance);
    }

    function getLicensePrice(uint lt, uint dc) public view returns(uint) {
        return uint(0.002 ether);
    }

    function getRateByLicenseType(uint lt) public view returns (uint) {
        return _rate[lt] == uint(0) ? _rate[0] : _rate[lt];
    }

    function getLicenseIdentifier(address owner, bytes32 hwid) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(owner, hwid));
    }

    function getLicense(address owner, bytes32 hwid) public view returns(uint, uint, uint)
    {
        License memory license = _licenses[getLicenseIdentifier(owner, hwid)];

        return (
            license.ltype,
            license.expiry,
            license.issuance
        );
    }

    function isLicenseValid(address owner, bytes32 hwid) public view returns(bool) {
        return _isLicenseValid(getLicenseIdentifier(owner, hwid));
    }

    function setRateForLicenseType(uint lt, uint rate) public restricted {
        _rate[uint(lt)] = rate;
    }

    function create(address owner, uint lt, uint dc, bytes32 hwid) public restricted {
        _create(owner, lt, dc, hwid);
    }

    function _create(address owner, uint lt, uint dc, bytes32 hwid) private
    {
        uint begins = block.timestamp;
        bytes32 identifier = getLicenseIdentifier(owner, hwid);

        License storage license = _licenses[identifier];
        if (_isExtendable(license, lt)) {
            license.expiry = _getExpiry(license.expiry, dc);
            emit Trace(TraceType.EXTEND, identifier, license.ltype, license.expiry, license.issuance);
        }
        else
        {
            uint expiry = _getExpiry(begins, dc);
            _licenses[identifier] = License({
                ltype: lt,
                expiry: expiry,
                issuance: begins
            });

            emit Trace(TraceType.CREATE, identifier, lt, expiry, begins);
        }
    }

    function _isExtendable(License memory license, uint lt) private view returns(bool) {
        return block.timestamp < license.expiry && license.ltype == lt;
    }

    function _getExpiry(uint256 begins, uint256 dc) private pure returns (uint256) {
        return begins + dc * 86400;
    }

    function _isLicenseValid(bytes32 identifier) private view returns(bool) {
        License memory license = _licenses[identifier];
        return license.issuance > uint(0) && block.timestamp < license.expiry;
    }

    modifier restricted() {
        require(msg.sender == _issuer);
        _;
    }
}