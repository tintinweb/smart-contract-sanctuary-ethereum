/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

/**
 *Submitted for verification at BscScan.com on 2022-07-21
*/

pragma solidity >=0.7.0 <0.9.0;

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor (address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

contract ArchieAggregatorFeeController is Auth {

    address feeAddress;
    bool feeEnabled;
    uint fee;

    constructor (address _feeAddress, bool _feeEnabled) Auth (msg.sender) {
        feeAddress = _feeAddress;
        feeEnabled = _feeEnabled;
    }

    function getFeeAddress() public view returns (address) {
        return feeAddress;
    }

    function changeFeeAddress(address addr) public authorized {
        feeAddress = addr;
    }

    function isFeeEnabled() public view returns (bool) {
        return feeEnabled;
    }

    function enableFee(bool _feeEnabled) public authorized {
        feeEnabled = _feeEnabled;
    }
}