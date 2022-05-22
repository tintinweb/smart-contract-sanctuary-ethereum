/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IERC20Token {
    function transferFrom(address from, address to, uint value) external;
}

interface POLCToken {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
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
    address public polcToken;
    address public walletAddress;
    address public sellingWallet;
    bool public paused;
    uint256 public thsPrice;
    uint256 public refReward;
    
    constructor() {
        sellingWallet = 0xAD334543437EF71642Ee59285bAf2F4DAcBA613F;
        nftAddress = 0xB20217bf3d89667Fa15907971866acD6CcD570C8;
        USDTToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        polcToken = 0xaA8330FB2B4D5D07ABFE7A72262752a8505C6B37;
        walletAddress = 0xeA50CE6EBb1a5E4A8F90Bfb35A2fb3c3F0C673ec;
        thsPrice = 100;
        paused = true;
        refReward = 50 * 1 ether;
    }
    
    function _buyAsset(uint256 _ths) public {
        require(!paused, "Contract is paused");
        uint256 _bPrice = _ths * thsPrice;
        uint256 _cPrice = _bPrice * 1000000;
        IERC20Token token = IERC20Token(USDTToken);
        token.transferFrom(msg.sender, sellingWallet, _cPrice);
        IERC721 nft = IERC721(nftAddress);
        require(nft.mint(msg.sender, uint32(100), _bPrice, uint32(_ths)), "Not possible to mint this type of asset");
    }

    function buyAsset(uint256 _ths) public {
        _buyAsset(_ths);
    }

    function buyAsset(uint256 _ths, address _referral) public {
        _buyAsset(_ths);
        POLCToken token = POLCToken(polcToken);
        require(token.transferFrom(walletAddress, _referral, refReward), "referral transfer fail");
    }

    function pauseContract(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        thsPrice = _newPrice;
    }

    function setReward(uint256 _reward) public onlyOwner {
        refReward = _reward;
    }
}