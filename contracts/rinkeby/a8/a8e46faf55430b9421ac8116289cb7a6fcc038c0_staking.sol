/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.4;

interface IERC721 {

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

}

interface IERC1155 {

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

}

contract staking {

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    event Staked(address user, address nftAddress, uint256[] tokenId); 
    event Unstaked(address user, address nftAddress, uint256[] tokenId, uint256 rewardTime);
    event StakeTimeLimitUpdated(uint256 tierLevel, uint256 stakeTimeLimit);
    event StakeAssetLimitUpdated(uint256 tierLevel, uint256 stakeAssetLimit);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    struct userDetails {
        uint256 tierLevel;
        uint256 stakeStartTime;
        uint256 stakingTime;
        assetType nftType;
        address nftAddress;
        uint256[] tokenId;
        uint256[] supply;
        uint256 rewardTime;
        bool isStake;
    }

    enum assetType {
        ERC1155,
        ERC721
    }

    struct Order {
        uint256 tierLevel;
        address nftAddress;
        assetType nftType;
        uint256[] tokenId;
        uint256[] supply;
    }

    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }

    struct tier {
        uint256 tierLevel;
        uint256 assetLimit;
        uint256 stakeLimit;
    }

    address public owner;

    mapping(uint256 => tier) private tierDetails;
    mapping(address => userDetails) private user;

    constructor() {
        owner = msg.sender;
        
        tierDetails[1].tierLevel = 1;
        tierDetails[1].assetLimit = 3;
        tierDetails[1].stakeLimit = 30 days;

        tierDetails[2].tierLevel = 2;
        tierDetails[2].assetLimit = 5;
        tierDetails[2].stakeLimit = 60 days;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner returns(bool){
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function setStakeTimeLImit(uint256 tierLevel, uint256 stakeTimeLimit) external onlyOwner returns(bool) {
        tierDetails[tierLevel].stakeLimit = stakeTimeLimit;
        emit StakeTimeLimitUpdated(tierLevel, stakeTimeLimit);
        return true;
    }

    function setStakeAssetLimit(uint256 tierLevel, uint256 _assetLimit) external onlyOwner returns(bool) {
        tierDetails[tierLevel].assetLimit = _assetLimit;
        emit StakeAssetLimitUpdated(tierLevel, _assetLimit);
        return true;
    }

    function _encode(uint256[] memory data) internal pure returns(bytes memory) {
        bytes memory hash;
        hash = abi.encode(data);
        return hash;
    }

    function verifySign(Order memory order, address caller, Sign memory sign) internal view {
        bytes memory tokenIdHash = _encode(order.tokenId);
        bytes32 hash = keccak256(abi.encodePacked(this, caller, order.nftAddress, tokenIdHash, sign.nonce));
        require(owner == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s), "Owner sign verification failed");
    }

    function stake(Order memory order, Sign memory sign) external returns(bool) {
        require((order.tokenId).length == tierDetails[order.tierLevel].assetLimit, "user need to stake more than or equal to assetLimit");
        require(!user[msg.sender].isStake, "user already staked");
        verifySign(order, msg.sender, sign);
        user[msg.sender].tierLevel = order.tierLevel;
        user[msg.sender].nftAddress = order.nftAddress;
        user[msg.sender].nftType = order.nftType;
        user[msg.sender].tokenId = order.tokenId;
        user[msg.sender].supply = order.supply;
        user[msg.sender].stakeStartTime = block.timestamp;
        user[msg.sender].stakingTime = block.timestamp + tierDetails[user[msg.sender].tierLevel].stakeLimit;
        user[msg.sender].isStake = true;
        address from = msg.sender;
        address to = address(this);
        assetTransfer( from, to, order.nftAddress, order.tokenId, order.nftType, order.supply);
        emit Staked(from, order.nftAddress, order.tokenId);
        return true;
    }

    function unstake() external returns(bool) {
        require(user[msg.sender].isStake, "user need to stake first");
        require(user[msg.sender].stakingTime <= block.timestamp, "user need to wait until the stakeTimeLimit");
        user[msg.sender].rewardTime = block.timestamp - user[msg.sender].stakeStartTime;
        address from = address(this);
        address to = msg.sender;
        assetTransfer(from, to, user[msg.sender].nftAddress, user[msg.sender].tokenId, user[msg.sender].nftType, user[msg.sender].supply);
        user[msg.sender].isStake = false;
        emit Unstaked(from, user[msg.sender].nftAddress, user[msg.sender].tokenId, user[msg.sender].rewardTime);
        return true;
    }

    function emergencyWithdraw() external returns(bool) {
        require(user[msg.sender].isStake, "user need to stake first");
        user[msg.sender].rewardTime = 0;
        address from = address(this);
        address to = msg.sender;
        assetTransfer(from, to, user[msg.sender].nftAddress, user[msg.sender].tokenId, user[msg.sender].nftType, user[msg.sender].supply);
        user[msg.sender].isStake = false;
        emit Unstaked(from, user[msg.sender].nftAddress, user[msg.sender].tokenId, user[msg.sender].rewardTime);
        return true;
    }

    function assetTransfer( address from, address to, address nftAddress, uint256[] memory tokenId, assetType nftType, uint256[] memory supply) internal {
        if(nftType == assetType.ERC721) {
            for(uint256 i = 0; i < (tokenId).length; i++) {
                IERC721(nftAddress).safeTransferFrom(from, to, tokenId[i]);
            }
        }
        if(nftType == assetType.ERC1155) {
            for(uint256 i = 0; i < tokenId.length; i++) {
                IERC1155(nftAddress).safeTransferFrom(from, to, tokenId[i], supply[i], "");
            }
        }
    }

    function getUserDetails(address account) external view returns(userDetails memory) {
        return user[account];
    }

    function onERC721Received( address, address, uint256, bytes calldata /*data*/) external pure returns(bytes4) {
        return _ERC721_RECEIVED;
    }
    
    function onERC1155Received( address /*operator*/, address /*from*/, uint256 /*id*/, uint256 /*value*/, bytes calldata /*data*/ ) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}