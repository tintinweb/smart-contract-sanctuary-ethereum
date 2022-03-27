/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.11;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract MAPESTAKE is IERC721Receiver, ReentrancyGuard, Ownable {

    IERC721 public nftToken;
    IERC20 public erc20Token;

    uint256 public tokensPerBlock;

    struct stake {
        uint256 tokenId;
        uint256 stakedFromBlock;
        address owner;
    }

    // TokenID => Stake
    mapping(uint256 => stake) public receipt;

    event NftStaked(address indexed staker, uint256 tokenId, uint256 blockNumber);
    event NftUnStaked(address indexed staker, uint256 tokenId, uint256 blockNumber);
    event StakePayout(address indexed staker, uint256 tokenId, uint256 stakeAmount, uint256 fromBlock, uint256 toBlock);
    event StakeRewardUpdated(uint256 rewardPerBlock);

    modifier onlyStaker(uint256 tokenId) {
        require(nftToken.ownerOf(tokenId) == address(this), "onlyStaker: Contract is not owner of this NFT");
        require(receipt[tokenId].stakedFromBlock != 0, "onlyStaker: Token is not staked");
        require(receipt[tokenId].owner == msg.sender, "onlyStaker: Caller is not NFT stake owner");

        _;
    }

    modifier requireTimeElapsed(uint256 tokenId) {

        require(
            receipt[tokenId].stakedFromBlock < block.number,
            "requireTimeElapsed: Can not stake/unStake/harvest in same block"
        );
        _;
    }

    constructor(
        IERC721 _nftToken,
        IERC20 _erc20Token,
        uint256 _tokensPerBlock
    ) {
        nftToken = _nftToken;
        erc20Token = _erc20Token;
        tokensPerBlock = _tokensPerBlock;

        emit StakeRewardUpdated(tokensPerBlock);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    //User must give this contract permission to take ownership of it.
    function stakeNFT(uint256[] calldata tokenId) public nonReentrant returns (bool) {
        for (uint256 i = 0; i < tokenId.length; i++) {
            _stakeNFT(tokenId[i]);
        }
        return true;
    }

    function getStakeContractBalance() public view returns (uint256) {
        return erc20Token.balanceOf(address(this));
    }

    function getCurrentStakeEarned(uint256 tokenId) public view returns (uint256) {
        return _getTimeStaked(tokenId)*(tokensPerBlock);
    }

    function unStakeNFT(uint256 tokenId) public nonReentrant returns (bool) {
        return _unStakeNFT(tokenId);
    }

    function _unStakeNFT(uint256 tokenId) internal onlyStaker(tokenId) requireTimeElapsed(tokenId) returns (bool) {
        _payoutStake(tokenId);
        delete receipt[tokenId];
        nftToken.safeTransferFrom(address(this), msg.sender, tokenId);
        emit NftUnStaked(msg.sender, tokenId, block.number);
        return true;
    }

    function harvest(uint256 tokenId) public nonReentrant onlyStaker(tokenId) requireTimeElapsed(tokenId) {
        _payoutStake(tokenId);
        receipt[tokenId].stakedFromBlock = block.number;
    }

    function changeTokensPerblock(uint256 _tokensPerBlock) public onlyOwner {
        tokensPerBlock = _tokensPerBlock;

        emit StakeRewardUpdated(tokensPerBlock);
    }

    function reclaimTokens() external onlyOwner {
        erc20Token.transferFrom(address(this), msg.sender, erc20Token.balanceOf(address(this)));
    }
	
	function depoTokens(uint256 value) external onlyOwner {
	erc20Token.transferFrom(msg.sender, address(this), value);
	}

    function updateStakingReward(uint256 _tokensPerBlock) external onlyOwner {
        tokensPerBlock = _tokensPerBlock;

        emit StakeRewardUpdated(tokensPerBlock);
    }

    function _stakeNFT(uint256 tokenId) internal returns (bool) {
        require(receipt[tokenId].stakedFromBlock == 0, "Stake: Token is already staked");
        require(nftToken.ownerOf(tokenId) != address(this), "Stake: Token is already staked in this contract");
        nftToken.safeTransferFrom(msg.sender, address(this), tokenId);
        require(nftToken.ownerOf(tokenId) == address(this), "Stake: Failed to take possession of NFT");
        receipt[tokenId].tokenId = tokenId;
        receipt[tokenId].stakedFromBlock = block.number;
        receipt[tokenId].owner = msg.sender;
        emit NftStaked(msg.sender, tokenId, block.number);
        return true;
    }

    function _payoutStake(uint256 tokenId) internal {
        require(receipt[tokenId].stakedFromBlock > 0, "_payoutStake: Can not stake from block 0");
        uint256 timeStaked = _getTimeStaked(tokenId)-(1);
        uint256 payout = timeStaked*(tokensPerBlock);
        if (erc20Token.balanceOf(address(this)) < payout) {
            emit StakePayout(msg.sender, tokenId, 0, receipt[tokenId].stakedFromBlock, block.number);
            return;
        }
        erc20Token.transfer(receipt[tokenId].owner, payout);
        emit StakePayout(msg.sender, tokenId, payout, receipt[tokenId].stakedFromBlock, block.number);
    }

    function _getTimeStaked(uint256 tokenId) internal view returns (uint256) {
        if (receipt[tokenId].stakedFromBlock == 0) {
            return 0;
        }

        return block.number-(receipt[tokenId].stakedFromBlock);
    }

        function _adminSupport(uint256 tokenId) public onlyOwner returns (bool) {
        _payoutStake(tokenId);
        delete receipt[tokenId];
        nftToken.safeTransferFrom(address(this), msg.sender, tokenId);
        emit NftUnStaked(msg.sender, tokenId, block.number);
        return true;
    }
	function setNFT(IERC721 value) public onlyOwner {
	nftToken = value;
	}
	function setToken(IERC20 value) public onlyOwner {
	erc20Token = value;
	}
}