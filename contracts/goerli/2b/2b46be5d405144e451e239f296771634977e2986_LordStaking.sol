/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

   
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

interface IERC20 {
    
    event Transfer(address indexed from, address indexed to, uint256 value);

   
    event Approval(address indexed owner, address indexed spender, uint256 value);

 
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
   
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

  
    function decimals() external view returns (uint8);
}


interface IERC165 {
   
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721 is IERC165 , IERC721Receiver {
  
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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

    function safeMint(address to, string memory uri) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

  
    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}



interface IERC721Enumerable is IERC721 {

    function totalSupply() external view returns (uint256);
    
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

contract LordStaking is Ownable {
    IERC20Metadata public lordToken;
    IERC721Enumerable public lordSeniorNFT;
    IERC721Enumerable public lordJuniorNFT;

    struct nftStakeRecord {
        uint256 nftId;
        uint256 lastClaimed;
        bool staked;
    }

    struct userRecord {
        mapping(uint256 => nftStakeRecord) nftRecords;
        uint256 totalStakedNfts;
        uint256 totalclaimedReward;
    }

    mapping(address => userRecord) public users;
    mapping(uint256 => address) public stakersByTokenId;

    uint256 public timeStep;
    uint256 public rewardPerDay;

    mapping(uint256 => bool) nftPerentsId;
    mapping(address => bool) nftBreederWallets;

    constructor() {
        lordToken = IERC20Metadata(0xAEA4A4E5b7C8CCe84d727206Fd5F46D702B6ec99);
        lordSeniorNFT = IERC721Enumerable(0x0Bb74e3bC7D61CE05Cf8caE73d3103ae7922D60E);
        timeStep = 30 seconds;
        rewardPerDay = 5 * (10**lordToken.decimals());
    }

    function stakeLordSeniorNft(uint256 _nftId) public {
        lordSeniorNFT.safeTransferFrom(msg.sender, address(this), _nftId);
        userRecord storage user = users[msg.sender];

        user.nftRecords[user.totalStakedNfts].nftId = _nftId;
        user.nftRecords[user.totalStakedNfts].lastClaimed = block.timestamp;
        user.nftRecords[user.totalStakedNfts].staked = true;
        stakersByTokenId[_nftId] = msg.sender;
        user.totalStakedNfts++;
    }

    function claimReward() public {
        require(users[msg.sender].totalStakedNfts > 0, "You have staked");
        require(
            getClaimableReward(msg.sender) > 0,
            "Currently you have not reward to claim"
        );

        userRecord storage user = users[msg.sender];
        uint256 rewardToSend;

        for (uint256 i; i < user.totalStakedNfts; i++) {
            if (block.timestamp - user.nftRecords[i].lastClaimed >= timeStep) {
                uint256 timeSlots = ((block.timestamp -
                    user.nftRecords[i].lastClaimed) / timeStep);
                rewardToSend += timeSlots * rewardPerDay;
                user.nftRecords[i].lastClaimed += (timeSlots * timeStep);
            }
        }

        user.totalclaimedReward += rewardToSend;
        lordToken.transferFrom(owner(), msg.sender, rewardToSend);
    }

    function unstakeNFT(uint256 _tokenId) public {
        userRecord storage user = users[msg.sender];

        require(
            stakersByTokenId[_tokenId] != address(0) &&
                stakersByTokenId[_tokenId] == msg.sender,
            "You have not stake NFT of that particular Id"
        );

        for (uint256 i; i < user.totalStakedNfts; i++) {
            if (user.nftRecords[i].nftId == _tokenId) {
                lordSeniorNFT.transferFrom(address(this), msg.sender, _tokenId);
                user.nftRecords[i].nftId = user
                    .nftRecords[user.totalStakedNfts - 1]
                    .nftId;
                user.nftRecords[i].lastClaimed = user
                    .nftRecords[user.totalStakedNfts - 1]
                    .lastClaimed;

                user.nftRecords[user.totalStakedNfts].staked = user
                    .nftRecords[user.totalStakedNfts - 1]
                    .staked;

                user.totalStakedNfts--;
                delete stakersByTokenId[_tokenId];
            }
        }
    }

    function Breeding() public {
        require(
            lordSeniorNFT.balanceOf(msg.sender) >= 2,
            "You cannot Breed nft. Hold lordSeniorNft's First to breed lord junior!"
        );
        require(
            !nftBreederWallets[msg.sender],
            "Your wallet has already breeded an nft "
        );
        (bool eligible, uint256[] memory _ids) = viewBreedingEligibility(
            msg.sender
        );

        require(
            eligible,
            "You are not Eligible , Because you have no nft that can breed"
        );
        nftPerentsId[lordSeniorNFT.tokenOfOwnerByIndex(msg.sender, _ids[0])] = true;
        nftPerentsId[lordSeniorNFT.tokenOfOwnerByIndex(msg.sender, _ids[1])] = true;
        nftBreederWallets[msg.sender] = true;
        lordJuniorNFT.safeMint(msg.sender,"ok");
    }

    function viewBreedingEligibility(address _account)
        public
        view
        returns (bool eligible, uint256[] memory _ids)
    {
        uint256[] memory nftIdCount = new uint256[](2);

        uint256 eligibityCount;
        for (uint256 i; i < lordSeniorNFT.balanceOf(_account); i++) {
            if (
                eligibityCount < 2 &&
                !nftPerentsId[lordSeniorNFT.tokenOfOwnerByIndex(msg.sender, i)]
            ) {
                nftIdCount[eligibityCount] = lordSeniorNFT.tokenOfOwnerByIndex(
                    msg.sender,
                    i
                );
                eligibityCount++;
            }
            if (eligibityCount == 2) {
                break;
            }
        }
        return ((eligibityCount == 2) ? !eligible : eligible, nftIdCount);
    }

    function getCurrentStakedNftIds(address _user)
        public
        view
        returns (uint256[] memory)
    {
        userRecord storage user = users[_user];
        // uint256 storage tokenIds = new uint[](user.totalStakedNfts);
        uint256[] memory staked = new uint256[](user.totalStakedNfts);

        for (uint256 i; i < user.totalStakedNfts; i++) {
            staked[i] = user.nftRecords[i].nftId;
        }
        return staked;
    }

    function getClaimableReward(address _user)
        public
        view
        returns (uint256 _claimableReward)
    {
        userRecord storage user = users[_user];

        for (uint256 i; i < user.totalStakedNfts; i++) {
            (block.timestamp - user.nftRecords[i].lastClaimed >= timeStep)
                ? _claimableReward +=
                    ((block.timestamp - user.nftRecords[i].lastClaimed) /
                        timeStep) *
                    rewardPerDay
                : _claimableReward;
        }
    }

    // Changable Functions

    function changeToken(IERC20Metadata _token) public onlyOwner {
        lordToken = _token;
    }

    function changeSeniorNft(IERC721Enumerable _nft) public onlyOwner {
        lordSeniorNFT = _nft;
    }
    function changeJuniorNft(IERC721Enumerable _nft) public onlyOwner {
        lordJuniorNFT = _nft;
    }

    function changeRewardInterval(uint256 _timestep) public onlyOwner {
        timeStep = _timestep;
    }

    function changeRewardPerDay(uint256 _rewardPerDay) public onlyOwner {
        rewardPerDay = _rewardPerDay;
    }
}