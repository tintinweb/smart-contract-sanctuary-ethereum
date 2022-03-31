/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.5;

interface IKYC {
    enum Statuses {
        Failed, // default status
        Verified
    }
    enum VerifiedLevels {
        IdentityDocument,
        Selfie,
        Phone,
        Email,
        ProofOfResidence
    }

    function getStatus(address user_) external view returns(Statuses);
    function getLevels(address user_) external view returns(VerifiedLevels[] memory);
    function getUserId(address user_) external view returns(bytes16);
}

contract KYC is IKYC {
    mapping(address => Statuses) private _statuses;
    mapping(address => VerifiedLevels[]) private _levels;
    mapping(address => bytes16) private _userIds;
    address public owner = msg.sender;
    uint256 public fee = 0.001 ether;

    modifier onlyOwner() {
        require(msg.sender == owner, "Address is not an owner");
        _;
    }

    function getStatus(address user_) public view override returns(Statuses) {
        return _statuses[user_];
    }

    function getLevels(address user_) public view override returns(VerifiedLevels[] memory) {
        return _levels[user_];
    }

    function getUserId(address user_) public view override returns(bytes16) {
        return _userIds[user_];
    }

    function setStatusAndLevels(address user_, Statuses status_, VerifiedLevels[] memory levels_) public onlyOwner() {
        _statuses[user_] = status_;
        _levels[user_] = levels_;
    }

    // TODO: setLevel() ???

    function setFee(uint256 fee_) public onlyOwner() {
        fee = fee_;
    }

    function setOwner(address owner_) public onlyOwner() {
        owner = owner_;
    }

    /**
     * R,S,V - server signed message
     */
    function setUserId(
        bytes16 userId,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public payable {
        require(msg.value == fee, "Bad fee");
        bytes32 hash = _prefixed(keccak256(abi.encodePacked(msg.sender, userId)));
        address recovered = ecrecover(hash, v, r, s);
        require(recovered == owner, "Signd data mismatch or not owner");
        require(userId > 0x0, "User id is invalid");
        _userIds[msg.sender] = userId;
    }

    function withdraw() public onlyOwner() {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * Builds a prefixed hash to mimic the behavior of eth_sign
     */
    function _prefixed(bytes32 hash) private pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}