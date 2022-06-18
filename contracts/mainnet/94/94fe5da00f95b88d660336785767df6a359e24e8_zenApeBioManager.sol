/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

interface iZenApe {
    function changeName(uint256 tokenId_, string memory name_) external;
    function changeBio(uint256 tokenId_, string memory bio_) external;
    function zenApeName(uint256 tokenId_) external view returns (string memory);
    function zenApeBio(uint256 tokenId_) external view returns (string memory);
}

interface iZenToken {
    function burnAsController(address from_, uint256 amount_) external;
}

contract zenApeBioManager is Ownable {

    iZenApe public ZenApe = iZenApe(0x838804a3dd7c717396a68F94E736eAf76b911632);
    iZenToken public ZenToken = iZenToken(0x884345a7B7E7fFd7F4298aD6115f5d5afb2F7660);

    uint256 public changeNamePrice = 10 ether;
    uint256 public changeBioPrice = 20 ether;

    function setChangeNamePrice(uint256 price_) external onlyOwner { 
        changeNamePrice = price_; }
    function setChangeBioPrice(uint256 price_) external onlyOwner {
        changeBioPrice = price_; }
    
    // For Burnerable functions, an invalid-amount burnAsController will trigger
    // to Solidity 8.0's underflow check and fail the function with no error message
    // in return, this saves a bit of gas from requiring to query balanceOf(msg.sender)
    function changeName(uint256 tokenId_, string calldata name_) public {
        ZenToken.burnAsController(msg.sender, changeNamePrice);
        ZenApe.changeName(tokenId_, name_);
    }
    function changeBio(uint256 tokenId_, string calldata bio_) public {
        ZenToken.burnAsController(msg.sender, changeBioPrice);
        ZenApe.changeBio(tokenId_, bio_);
    }

    // Read Function for Easy Server Querying
    struct NameAndBio {
        string name;
        string bio;
    }
    function getNamesAndBiosOfZenApes(uint256 start_, uint256 end_) external
    view returns (NameAndBio[] memory) {
        uint256 _length = end_ - start_ + 1;
        uint256 _endPlus = end_ + 1;
        uint256 _index;
        NameAndBio[] memory _NameAndBio = new NameAndBio[](_length);

        for (uint256 i = start_; i < _endPlus;) {
            string memory _name  = ZenApe.zenApeName(i);
            string memory _bio   = ZenApe.zenApeBio(i);
            _NameAndBio[_index] = NameAndBio(_name, _bio);
            unchecked { ++i; ++_index; }
        }
        return _NameAndBio;
    }
    function getAllNamesAndBiosOfZenApes() external view 
    returns (NameAndBio[5002] memory) {
        NameAndBio[5002] memory _NameAndBio;
        for (uint256 i; i < 5002;) {
            string memory _name  = ZenApe.zenApeName(i);
            string memory _bio   = ZenApe.zenApeBio(i);
            _NameAndBio[i] = NameAndBio(_name, _bio);
            unchecked { ++i; }
        }
        return _NameAndBio;
    }
}