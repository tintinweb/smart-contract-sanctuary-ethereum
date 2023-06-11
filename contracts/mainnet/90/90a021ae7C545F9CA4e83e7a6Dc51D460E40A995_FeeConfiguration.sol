pragma solidity >=0.8.9;

contract FeeConfiguration {
    // Partner -> PartnerShare
    mapping(address => uint256) private _partnerShares;
    address public owner;
    

    ///Events///
    event SetPartnerShare(address indexed partnerAddress, uint256 partnerShare);
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    constructor (address _owner) public {
        owner = _owner;
    }

    function setPartnerShare(address partnerAddress, uint256 partnerShare) external onlyOwner {
        _partnerShares[partnerAddress] = partnerShare;
        emit SetPartnerShare(partnerAddress, partnerShare);
    }

    function getPartnerShare(address partnerAddress) external view returns (uint256) {
        return _partnerShares[partnerAddress];
    }

    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
        emit OwnerChanged(msg.sender, owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!ownerAddress");
        _;
    }
}