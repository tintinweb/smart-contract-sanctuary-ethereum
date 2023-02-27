pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './interfaces/IHouseBusiness.sol';

contract HouseStaking {
    // total number of staked nft
    uint256 public stakedCounter;
    // token panalty
    uint256 public penalty;
    // All APY types
    uint256[] APYtypes;

    // APY
    mapping(uint256 => uint256) APYConfig;
    mapping(address => StakedNft[]) stakedNfts;

    address tokenAddress;
    address houseNFTAddress;

    // Staking NFT struct
    struct StakedNft {
        address owner;
        uint256 tokenId;
        uint256 startedDate;
        uint256 endDate;
        uint256 claimDate;
        uint256 stakingType;
        uint256 perSecRewards;
        bool stakingStatus;
    }

    constructor(address _houseNFTAddress, address _tokenAddress) {
        APYtypes.push(1);
        APYConfig[1] = 6;
        APYtypes.push(6);
        APYConfig[6] = 8;
        APYtypes.push(12);
        APYConfig[12] = 10;
        APYtypes.push(24);
        APYConfig[24] = 12;
        tokenAddress = _tokenAddress;
        houseNFTAddress = _houseNFTAddress;
    }

    // Devide number
    function calcDiv(uint256 a, uint256 b) external pure returns (uint256) {
        return (a - (a % b)) / b;
    }

    function setAPYConfig(uint256 _type, uint256 Apy) external {
        APYConfig[_type] = Apy;
        APYtypes.push(_type);
    }

    function getAllAPYTypes() public view returns (uint256[] memory) {
        return APYtypes;
    }

    // stake House Nft
    function stake(uint256 _tokenId, uint256 _stakingType) external {
        require(IERC721(houseNFTAddress).ownerOf(_tokenId) != address(this), 'You have already staked this House Nft');

        // _stakingType should be one, six, twelve, twentytwo
        require(APYConfig[_stakingType] > 0, 'Staking type should be specify.');
        // transfer the token from owner to the caller of the function (buyer)
        IERC721(houseNFTAddress).transferFrom(msg.sender, address(this), _tokenId);

        StakedNft memory simpleStakedNft;
        simpleStakedNft.owner = msg.sender;
        simpleStakedNft.tokenId = _tokenId;
        simpleStakedNft.startedDate = block.timestamp;

        simpleStakedNft.endDate = block.timestamp + (24 * 3600 * 366 * APYConfig[_stakingType]) / 12;
        simpleStakedNft.claimDate = block.timestamp;
        simpleStakedNft.stakingType = _stakingType;
        uint256 dayToSec = 365 * 24 * 60 * 60;
        uint256 price = IHouseBusiness(houseNFTAddress).getTokenPrice(_tokenId);
        simpleStakedNft.perSecRewards = this.calcDiv(price, dayToSec);
        simpleStakedNft.stakingStatus = true;
        stakedCounter++;
        stakedNfts[msg.sender].push(simpleStakedNft);

        IHouseBusiness(houseNFTAddress).setHouseStakedStatus(_tokenId, true);
    }

    // Unstake House Nft
    function unstake(uint256 _tokenId) external {
        StakedNft[] memory cStakedNfts = stakedNfts[msg.sender];
        bool status = true;
        for (uint256 i = 0; i < cStakedNfts.length; i++) {
            if (cStakedNfts[i].tokenId == _tokenId) {
                status = false;
            }
        }
        require(status == false, 'NS');
        StakedNft memory unstakingNft;
        uint256 counter;
        for (uint256 i = 0; i < stakedNfts[msg.sender].length; i++) {
            if (stakedNfts[msg.sender][i].tokenId == _tokenId) {
                unstakingNft = stakedNfts[msg.sender][i];
                counter = i;
            }
        }
        if (stakingFinished(_tokenId) == false) {
            uint256 claimAmount = totalRewards(msg.sender);
            IERC20(tokenAddress).transfer(msg.sender, (claimAmount * (100 - penalty)) / 100);
        } else {
            claimRewards(msg.sender);
        }
        // check if owner call this request
        require(unstakingNft.owner == msg.sender, 'OCUT');
        // transfer the token from owner to the caller of the function (buyer)
        IERC721(houseNFTAddress).transferFrom(address(this), msg.sender, _tokenId);
        // commit ustaked
        IHouseBusiness(houseNFTAddress).setHouseStakedStatus(_tokenId, false);
        stakedCounter--;
        delete stakedNfts[msg.sender][counter];
    }

    function stakingFinished(uint256 _tokenId) public view returns (bool) {
        StakedNft memory stakingNft;
        for (uint256 i = 0; i < stakedNfts[msg.sender].length; i++) {
            if (stakedNfts[msg.sender][i].tokenId == _tokenId) {
                stakingNft = stakedNfts[msg.sender][i];
            }
        }
        return block.timestamp < stakingNft.endDate;
    }

    // Claim Rewards
    function totalRewards(address _rewardOwner) public view returns (uint256) {
        StakedNft[] memory allmyStakingNfts = stakedNfts[_rewardOwner];
        uint256 allRewardAmount = 0;
        for (uint256 i = 0; i < allmyStakingNfts.length; i++) {
            if (allmyStakingNfts[i].stakingStatus == true) {
                uint256 stakingType = allmyStakingNfts[i].stakingType;
                uint256 expireDate = allmyStakingNfts[i].startedDate + 60 * 60 * 24 * 30 * stakingType;
                uint256 _timestamp;
                uint256 price = IHouseBusiness(houseNFTAddress).getTokenPrice(allmyStakingNfts[i].tokenId);
                if (block.timestamp <= expireDate) {
                    _timestamp = block.timestamp;
                } else {
                    _timestamp = expireDate;
                }
                allRewardAmount += this.calcDiv(
                    (price * APYConfig[stakingType] * (_timestamp - allmyStakingNfts[i].claimDate)) / 100,
                    (365 * 24 * 60 * 60)
                );
            }
        }
        return allRewardAmount;
    }

    // Claim Rewards
    function claimRewards(address _stakedNFTowner) public {
        StakedNft[] memory allmyStakingNfts = stakedNfts[_stakedNFTowner];
        uint256 allRewardAmount = 0;
        for (uint256 i = 0; i < allmyStakingNfts.length; i++) {
            if (allmyStakingNfts[i].stakingStatus == true) {
                uint256 stakingType = allmyStakingNfts[i].stakingType;
                uint256 expireDate = allmyStakingNfts[i].startedDate + 60 * 60 * 24 * 30 * stakingType;
                uint256 _timestamp;
                uint256 price = IHouseBusiness(houseNFTAddress).getTokenPrice(allmyStakingNfts[i].tokenId);
                if (block.timestamp <= expireDate) {
                    _timestamp = block.timestamp;
                } else {
                    _timestamp = expireDate;
                }
                allRewardAmount += this.calcDiv(
                    (price * APYConfig[stakingType] * (_timestamp - allmyStakingNfts[i].claimDate)) / 100,
                    (365 * 24 * 60 * 60)
                );
                stakedNfts[_stakedNFTowner][i].claimDate = _timestamp;
            }
        }
        if (allRewardAmount != 0) {
            IERC20(tokenAddress).transfer(_stakedNFTowner, allRewardAmount);
        }
    }

    // Gaddress _rewardOwneret All staked Nfts
    function getAllMyStakedNFTs() public view returns (StakedNft[] memory) {
        return stakedNfts[msg.sender];
    }

    // Get All APYs
    function getAllAPYs() public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory apyCon = new uint256[](APYtypes.length);
        uint256[] memory apys = new uint256[](APYtypes.length);
        for (uint256 i = 0; i < APYtypes.length; i++) {
            apys[i] = APYtypes[i];
            apyCon[i] = APYConfig[APYtypes[i]];
        }
        return (apys, apyCon);
    }

    // Penalty
    function getPenalty() public view returns (uint256) {
        return penalty;
    }

    function setPenalty(uint256 _penalty) public {
        require(IHouseBusiness(houseNFTAddress).allMembers(msg.sender), 'member');
        penalty = _penalty;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IHouseBusiness {
    // this contract's token collection name
    function collectionName() external view returns (string calldata);

    // this contract's token symbol
    function collectionNameSymbol() external view returns (string calldata);

    // total number of houses minted
    function houseCounter() external view returns (uint256);

    // total number of staked nft
    function stakedCounter() external view returns (uint256);

    // total number of solded nft
    function soldedCounter() external view returns (uint256);

    // total number of history type
    function hTypeCounter() external view returns (uint256);

    // min house nft price
    function minPrice() external view returns (uint256);

    // max house nft price
    function maxPrice() external view returns (uint256);

    // token panalty
    function penalty() external view returns (uint256);

    // token royalty
    function royalty() external view returns (uint256);

    // define house struct
    struct House {
        uint256 tokenId;
        uint256 tokenName;
        string tokenURI;
        string tokenType;
        address currentOwner;
        address previousOwner;
        address buyer;
        uint256 price;
        uint256 numberOfTransfers;
        bool nftPayable;
        bool staked;
        bool soldstatus;
    }
    // Staking NFT struct
    struct StakedNft {
        address owner;
        uint256 tokenId;
        uint256 startedDate;
        uint256 endDate;
        uint256 claimDate;
        uint256 stakingType;
        uint256 perSecRewards;
        bool stakingStatus;
    }
    // House history struct
    struct History {
        uint256 hID;
        uint256 contractId;
        string houseImg;
        string houseBrand;
        string desc;
        string history;
        string brandType;
        uint256 yearField;
    }
    // History Type Struct
    struct HistoryType {
        uint256 hID;
        string hLabel;
        bool connectContract;
        bool imgNeed;
        bool brandNeed;
        bool descNeed;
        bool brandTypeNeed;
        bool yearNeed;
        bool checkMark;
    }

    // history types
    function historyTypes(uint256) external view returns (HistoryType calldata);

    // all house histories
    function houseHistories(uint256) external view returns (History[] calldata);

    // map members
    function allMembers(address) external view returns (bool);

    // map house's token id to house
    function allHouses(uint256) external view returns (House calldata);

    // check if token name exists
    // mapping(string => bool) external tokenNameExists;
    // check if token URI exists
    // mapping(string => bool) external tokenURIExists;
    // All Staked NFTs
    function stakedNfts(address) external view returns (StakedNft[] calldata);

    function setMinMaxHousePrice(uint256 _min, uint256 _max) external;

    function setConfigToken(address _tokenAddress) external;

    function isMember() external view returns (bool);

    function addMember(address _newMember) external;

    function removeMember(address _newMember) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function setPayable(
        uint256 tokenId,
        address _buyer,
        bool nftPayable
    ) external;

    function mintHouse(
        string memory _name,
        string memory _tokenURI,
        string memory _tokenType,
        string memory initialDesc,
        uint256 _price
    ) external payable;

    // Add allow list
    function addAllowList(uint256 _tokenId, address allowed) external;

    // Remove allow list
    function removeAllowList(uint256 _tokenId, address allowed) external;

    // Confirm is allowed list
    function checkAllowedList(uint256 _tokenId, address allowed) external view returns (bool);

    // Add history of house
    function addHistory(
        uint256 _tokenId,
        uint256 newHistoryType,
        string memory houseImg,
        string memory houseBrand,
        string memory _history,
        string memory _desc,
        string memory brandType,
        uint256 yearField
    ) external;

    function getHistory(uint256 _tokenId) external view returns (History[] memory);

    // Edit history of house
    function editHistory(
        uint256 _tokenId,
        uint256 historyIndex,
        string memory houseImg,
        string memory houseBrand,
        string memory _history,
        string memory _desc,
        string memory brandType,
        uint256 yearField
    ) external;

    // Get History Type
    function getHistoryType() external view returns (HistoryType[] memory);

    // Add Or Edit History Type
    function addOrEditHType(
        uint256 _historyIndex,
        string memory _label,
        bool _connectContract,
        bool _imgNeed,
        bool _brandNeed,
        bool _descNeed,
        bool _brandTypeNeed,
        bool _yearNeed,
        bool _checkMark
    ) external;

    // Remove History Type
    function removeHistoryType(uint256 _hIndex) external;

    function getMinMaxNFT() external view returns (uint256, uint256);

    // get owner of the token
    function getTokenOwner(uint256 _tokenId) external view returns (address);

    // by a token by passing in the token's id
    function buyHouseNft(uint256 tokenId) external payable;

    // by a token by passing in the token's id
    function sendToken(address receiver, uint256 tokenId) external payable;

    // change token price by token id
    function changeTokenPrice(uint256 _tokenId, uint256 _newPrice) external;

    // get all houses NFT
    function getAllHouses() external view returns (House[] memory);

    // get all payable houses NFT
    function getAllPayableHouses() external view returns (House[] memory);

    // get all my houses NFT
    function getAllMyHouses() external view returns (House[] memory);

    // withdraw token
    function withdrawToken(uint256 _amountToken) external payable;

    // withdraw ETH
    function withdrawETH(uint256 _amountEth) external payable;

    function setAPYConfig(uint256 _type, uint256 Apy) external;

    function getAllAPYTypes() external view returns (uint256[] memory);

    // stake House Nft
    function stake(uint256 _tokenId, uint256 _stakingType) external;

    // Unstake House Nft
    function unstake(uint256 _tokenId) external;

    function stakingFinished(uint256 _tokenId) external view returns (bool);

    // Claim Rewards
    function totalRewards(address _rewardOwner) external view returns (uint256);

    // Claim Rewards
    function claimRewards(address _stakedNFTowner) external;

    // Gaddress _rewardOwneret All staked Nfts
    function getAllMyStakedNFTs() external view returns (StakedNft[] memory);

    // Get Overall total information
    function getTotalInfo()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    // Get All APYs
    function getAllAPYs() external view returns (uint256[] memory, uint256[] memory);

    // Penalty
    function getPenalty() external view returns (uint256);

    function setPenalty(uint256 _penalty) external;

    // Royalty
    function getRoyalty() external view returns (uint256);

    function setRoyalty(uint256 _royalty) external;

    function ownerOf(uint256 tokenId) external returns (address);

    function getTokenPrice(uint256 tokenId) external view returns (uint256);

    function setHouseStakedStatus(uint256 tokenId, bool status) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}