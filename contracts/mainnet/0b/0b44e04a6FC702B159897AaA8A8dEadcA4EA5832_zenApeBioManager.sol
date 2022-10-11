/**
 *Submitted for verification at Etherscan.io on 2022-07-08
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

interface IERC20Burnable { 
    function transferFrom(address from_, address to_, uint256 amount_) external;
    function approve(address spender_, uint256 amount_) external;
    function burn(uint256 amount_) external;
    function balanceOf(address wallet_) external view returns (uint256);
}

contract zenApeBioManager is Ownable {

    iZenApe public ZenApe = iZenApe(0x838804a3dd7c717396a68F94E736eAf76b911632);
    iZenToken public ZenToken = iZenToken(0x0591c71E88a74E612aE1759ABc938973421Ba027);
    IERC20Burnable public Banana = 
        IERC20Burnable(0x94e496474F1725f1c1824cB5BDb92d7691A4F03a);

    // Zen Token
    uint256 public changeNamePrice = 10 ether;
    uint256 public changeBioPrice = 20 ether;

    function setChangeNamePrice(uint256 price_) external onlyOwner { 
        changeNamePrice = price_; }
    function setChangeBioPrice(uint256 price_) external onlyOwner {
        changeBioPrice = price_; }
    
    // Banana
    uint256 public bananaChangeNamePrice = 1 ether;
    uint256 public bananaChangeBioPrice = 2 ether;

    function setBananaChangeNamePrice(uint256 price_) external onlyOwner { 
        bananaChangeNamePrice = price_; }
    function setBananaChangeBioPrice(uint256 price_) external onlyOwner {
        bananaChangeBioPrice = price_; }

    function ownerChangeName(uint256 tokenId_, string calldata name_) 
    external onlyOwner {
        ZenApe.changeName(tokenId_, name_);
    }
    
    function ownerChangeBio(uint256 tokenId_, string calldata bio_) 
    external onlyOwner {
        ZenApe.changeBio(tokenId_, bio_);
    }
    
    // For Burnerable functions, an invalid-amount burnAsController will trigger
    // to Solidity 8.0's underflow check and fail the function with no error message
    // in return, this saves a bit of gas from requiring to query balanceOf(msg.sender)
    function changeName(uint256 tokenType_, uint256 tokenId_, 
    string calldata name_) public {
        
        if (tokenType_ == 1) {
            ZenToken.burnAsController(msg.sender, changeNamePrice);
        }

        else if (tokenType_ == 2) {
            Banana.transferFrom(msg.sender, address(this), bananaChangeNamePrice);
            Banana.burn(Banana.balanceOf(address(this)));
        }

        else { revert("Invalid token type!"); }

        ZenApe.changeName(tokenId_, name_);
    }
    function changeBio(uint256 tokenType_, uint256 tokenId_, 
    string calldata bio_) public {

        if (tokenType_ == 1) {
            ZenToken.burnAsController(msg.sender, changeBioPrice);
        }

        else if (tokenType_ == 2) {
            Banana.transferFrom(msg.sender, address(this), bananaChangeBioPrice);
            Banana.burn(Banana.balanceOf(address(this)));
        }

        else { revert("Invalid token type!"); }

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