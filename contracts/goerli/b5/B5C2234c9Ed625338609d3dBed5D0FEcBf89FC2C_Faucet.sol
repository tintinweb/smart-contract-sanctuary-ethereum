// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;



interface PulseBitcoinLockNFT {
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenIdsToTransferable(uint256 tokenId) external view returns (bool);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
}



contract Faucet {
    address public immutable token_address; // Reward token
    IERC20 token;
    IERC20 carnToken;
    mapping(address=>uint256) public nextRequestAt;
    uint256 public withdrawAmount;
    uint256 public delay;
    uint256 public carnBalanceRequired;
    address public immutable lockNFTAddress;



    constructor (
        address _tokenAddress,
        address _carnTokenAddress,
        uint256 _withdrawAmount,
        uint256 _delay,
        uint256 _carnBalanceRequired,
        address _lockNFTAddress
    ) {
        token_address = _tokenAddress;
        token = IERC20(token_address);
        carnToken = IERC20(_carnTokenAddress);
        withdrawAmount = _withdrawAmount;
        delay = _delay;
        carnBalanceRequired = _carnBalanceRequired;
        lockNFTAddress = _lockNFTAddress;
    }

    function withdraw() external {
        require(token.balanceOf(address(this)) > withdrawAmount * 10**token.decimals(), "FaucetError: Empty");
        require(nextRequestAt[msg.sender] < block.timestamp, "Must wait 1 full week");
        require(carnToken.balanceOf(msg.sender) >= carnBalanceRequired, "Insufficient CARN balance");
        require(hasValidNFT(msg.sender), "User does not have a valid NFT");
        nextRequestAt[msg.sender] = block.timestamp + delay;
        token.transfer(msg.sender, withdrawAmount * 10**token.decimals());
    }

    function hasValidNFT(address user) internal view returns (bool) {
        PulseBitcoinLockNFT lockNFT = PulseBitcoinLockNFT(lockNFTAddress);
        uint256 nftSupply = 100000;//lockNFT.totalSupply();
        uint256 tokenId;
        for (tokenId = 0; tokenId <= nftSupply; tokenId++) {
            if (lockNFT.ownerOf(tokenId) == user && !lockNFT.tokenIdsToTransferable(tokenId)) {
                return true;
            }
        }
        return false;
    }
}