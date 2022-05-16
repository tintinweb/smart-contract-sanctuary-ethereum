/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IERC20Token {
    function transferFrom(address from, address to, uint value) external;
}

interface IERC721 {
    function mint(address to, uint32 _assetType, uint256 _value, uint32 _customDetails) external returns (bool success);
}
contract Ownable {

    address private owner;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }


    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}

contract MinerSeller is Ownable {

    address public nftAddress;
    address public USDTToken;
    address public sellingWallet;
    bool public paused;
    uint256 public thsPrice;

    
    constructor() {
        sellingWallet = 0xAD334543437EF71642Ee59285bAf2F4DAcBA613F;
        nftAddress = 0xB20217bf3d89667Fa15907971866acD6CcD570C8;
        USDTToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        thsPrice = 100;
        paused = true;
    }
    
    function buyAsset(uint256 _ths) public {
        require(!paused, "Contract is paused");
        uint256 _bPrice = _ths * thsPrice;
        uint256 _cPrice = _bPrice * 1000000;
        IERC20Token token = IERC20Token(USDTToken);
        token.transferFrom(msg.sender, sellingWallet, _cPrice);
        IERC721 nft = IERC721(nftAddress);
        require(nft.mint(msg.sender, uint32(100), _bPrice, uint32(_ths)), "Not possible to mint this type of asset");
    }

    function pauseContract(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        thsPrice = _newPrice;
    }
}