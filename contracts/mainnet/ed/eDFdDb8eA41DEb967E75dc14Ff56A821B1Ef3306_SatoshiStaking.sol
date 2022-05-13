// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/Controller.sol";

contract SatoshiStaking is IERC1155Receiver, IERC721Receiver, Ownable {
    /*==================================================== Events =============================================================*/
    event NftStaked(address user, address collection, uint256 id, uint256 stakedTime, uint256 nftBalance);
    event NftUnstaked(address user, address collection, uint256 id, uint256 timeStamp, uint256 leftReward);
    event RewardClaimed(address user, address collection, uint256 id, uint256 timeStamp, uint256 givenReward, uint256 leftReward);
    event CollectionAdded(address collection, address rewardToken, uint256 dailyReward);
    event StakingEnabled(uint256 time);
    event StakingDisabled(uint256 time);
    event NFTProgramFunded(address admin, uint256 rewardAmount, address token, address collection);
    event WithdrawnFunds(address admin, address rewardToken, uint256 amount);


    /*==================================================== State Variables ====================================================*/
    /*
     * @param user: staker address who is nft owner
     * @param collection: Address of the 1155 or 721 contract
     * @param id: token id
     * @param stakedTime: the last stake or claim date as a time stamp
     * @param balance: remaining amount that can be claimed
     * @param claimedTotal: total claimed rewards from given Nft
     * @param letfTime: left lifetime of the given Nft(in seconds)
     */
    struct NFT {
        address user;
        address collection;
        uint256 id;
        uint256 stakedTime;
        uint256 balance;
        uint256 claimedTotal;
        uint256 leftTime;
        bool isStakedBefore;
        bool isStaked;
        Collection collec;
    }
    /*
     * @param rewardsPerDay: daily reward amount for the collection (should be 10**18)
     * @param startTime: the start time of the collection to stake (time stamp)
     * @param lifetime: Total life time of the collection per NFT (should be in days like 30)
     * @param promisedRewards: total promised rewards
     * @param rewardTokenAddr: address of the reward token
     */
    struct Collection {
        uint256 rewardsPerDay;
        uint256 startTime;
        uint256 lifetime; //daily
        uint256 promisedRewards;
        address rewardTokenAddr;
    }

    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private collec721;
    EnumerableSet.AddressSet private collec1155;

    // a data for controlling direct transfer
    bytes private magicData;
    //this mapping stores Nft infos
    mapping(address => mapping(uint256 => NFT)) public nftInfo;
    //this mapping stores collection infos
    mapping(address => Collection) public collectionInfo;

    /*==================================================== Constructor ========================================================*/
    constructor(bytes memory _data) {
        require(_data.length != 0, "Magic data can not be equal to zero");
        magicData = _data;
    }

    /*==================================================== FUNCTIONS ==========================================================*/
    /*==================================================== Read Functions ======================================================*/
    /*
     *This function calculates and returns the reward amount of the current time
     *@param _collection: address of the collection(ERC721 or ERC1155)
     *@param _id: the id of the Nft
     */
    function computeReward(
        address _collection,
        uint256 _id,
        uint256 _timestamp
    ) public view returns (uint256 _unclaimedRewards, uint256 _days) {
        if (nftInfo[_collection][_id].user == address(0)) return (0, 0);

        uint256 _stakeTime = _timestamp - nftInfo[_collection][_id].stakedTime; //total staked time in seconds from the staked time
        uint256 _leftTime = nftInfo[_collection][_id].leftTime;
        uint256 _dailyReward = collectionInfo[_collection].rewardsPerDay;

        if (_leftTime < _stakeTime) _stakeTime = _leftTime;
        _days = _stakeTime / 1 days;
        _unclaimedRewards = (_dailyReward * _days);
    }

    /*
     *This function returns the nft infos
     *@param _collection: address of the collection(ERC721 or ERC1155)
     *@param _id: the id of the Nft
     */
    function getNFTInformation(address _collection, uint256 _id)
        external
        view
        returns (
            uint256 _claimedRewards,
            uint256 _unclaimedRewards,
            uint256 _leftDays,
            uint256 _leftHours,
            uint256 _leftRewards,
            uint256 _dailyReward,
            address _owner
        )
    {
        require(collec721.contains(_collection) || collec1155.contains(_collection), "This NFT is not supported! Please provide correct information");
        NFT memory _nftInfo = nftInfo[_collection][_id];
        _claimedRewards = _nftInfo.claimedTotal;

        uint256 leftTimeInSeconds;
        uint256 _timeStamp;

        !_nftInfo.isStaked ? _timeStamp = _nftInfo.stakedTime : _timeStamp = block.timestamp;

        if ((_timeStamp - _nftInfo.stakedTime) > _nftInfo.leftTime) leftTimeInSeconds = 0;
        else leftTimeInSeconds = _nftInfo.leftTime - (_timeStamp - _nftInfo.stakedTime);

        _leftDays = leftTimeInSeconds / 1 days;
        uint256 leftHoursInSeconds = leftTimeInSeconds - (_leftDays * 1 days);
        _leftHours = leftHoursInSeconds / 3600;

        (_unclaimedRewards, ) = computeReward(_collection, _id, _timeStamp);

        _leftRewards = _nftInfo.balance - _unclaimedRewards;

        _dailyReward = collectionInfo[_collection].rewardsPerDay;
        _owner = _nftInfo.user;
    }

    /*
     *This function returns the balance of this contract for given token
     *@param _token: address of the token
     */
    function getRewardTokenBalance(address _token) external view returns (uint256 _balance) {
        _balance = IERC20(_token).balanceOf(address(this));
    }

    /*
     *This function returns all of the supported ERC721 contracts
     */
    function getAllSupportedERC721() external view returns (address[] memory) {
        return collec721.values();
    }

    /*
     *This function returns all of the supported ERC1155 contracts
     */
    function getAllSupportedERC1155() external view returns (address[] memory) {
        return collec1155.values();
    }

    /*==================================================== External Functions ==================================================*/
    /*
     *Admin can add new supported collection via this function
     *@param _collection: address of the collection
     *@param _collecInfo: data from Collection struct
     *@param _is721: if the collection is 721, this parameter should be true
     */
    function addCollection(
        address _collection,
        Collection calldata _collecInfo,
        bool _is721
    ) external onlyOwner {
        require(_collection != address(0), "Collection can't be zero address");
        require(_collecInfo.rewardsPerDay > 0, "Daily reward can not be zero");
        require(_collecInfo.startTime >= block.timestamp, "Staking start time cannot be lower than current timestamp");

        require(Controller.isContract(_collection), "Given collection address does not belong to any contract!");
        require(Controller.isContract(_collecInfo.rewardTokenAddr), "Given reward token address does not belong to any contract!");

        _is721 ? collec721.add(_collection) : collec1155.add(_collection);

        Collection storage newCollection = collectionInfo[_collection];

        newCollection.lifetime = _collecInfo.lifetime * 1 days;
        newCollection.rewardsPerDay = _collecInfo.rewardsPerDay;
        newCollection.startTime = _collecInfo.startTime;
        newCollection.rewardTokenAddr = _collecInfo.rewardTokenAddr;

        emit CollectionAdded(_collection, _collecInfo.rewardTokenAddr, _collecInfo.rewardsPerDay);
    }

    /*
     *Admin can remove a supported collection from contract via this function
     *@param _collection: address of the collection
     *@param _is721: if the collection is 721, this parameter should be true
     */
    function removeCollection(address _collection, bool _is721) external onlyOwner {
        require(_collection != address(0), "Collection can't be zero address");

        if (_is721) {
            collec721.remove(_collection);
        } else {
            collec1155.remove(_collection);
        }
    }

    /*
     *With this function, users will be able to stake both ERC721 and 1155 types .
     *@param _collection: address of the collection
     *@param _id: id of the Nft
     */
    function stakeSingleNFT(address _collection, uint256 _id) public {
        if (collec721.contains(_collection)) {
            IERC721(_collection).safeTransferFrom(msg.sender, address(this), _id, magicData);
        } else if (collec1155.contains(_collection)) {
            IERC1155(_collection).safeTransferFrom(msg.sender, address(this), _id, 1, magicData);
        } else {
            revert("This NFT Collection is not supported at this moment! Please try again");
        }

        NFT memory _nftInfo = nftInfo[_collection][_id];
        require(collectionInfo[_collection].startTime <= block.timestamp, "Staking of this collection has not started yet!");

        if (!_nftInfo.isStakedBefore) {
            _nftInfo.collection = _collection;
            _nftInfo.id = _id;
            _nftInfo.collec.lifetime = collectionInfo[_collection].lifetime;
            _nftInfo.leftTime = _nftInfo.collec.lifetime;
            _nftInfo.isStakedBefore = true;
            _nftInfo.collec.rewardsPerDay = collectionInfo[_collection].rewardsPerDay;
        }
        _nftInfo.user = msg.sender;
        _nftInfo.stakedTime = block.timestamp;
        _nftInfo.balance = (_nftInfo.leftTime * collectionInfo[_collection].rewardsPerDay) / 1 days;
        _nftInfo.isStaked = true;

        nftInfo[_collection][_id] = _nftInfo;
        collectionInfo[_collection].promisedRewards += (_nftInfo.leftTime * collectionInfo[_collection].rewardsPerDay) / 1 days;
        emit NftStaked(msg.sender, _collection, _id, block.timestamp, _nftInfo.balance);
    }

    /*
     *With this function, users will be able to stake batch both ERC721 and 1155 types .
     *@param _collections[]: addresses of the collections
     *@param _ids[]: ids of the Nfts
     */
    function stakeBatchNFT(address[] calldata _collections, uint256[] calldata _ids) external {
        require(_collections.length <= 5, "Please send 5 or less NFTs.");
        require(_collections.length == _ids.length, "Collections and Ids number are mismatch, Check again please.");

        for (uint256 i = 0; i < _collections.length; i++) {
            stakeSingleNFT(_collections[i], _ids[i]);
        }
    }

    /*
     *User can claim his/her rewards via this function
     *@param _collection: address of the collection
     *@param _id: id of the Nft
     */
    function claimReward(address _collection, uint256 _id) public {
        uint256 timeStamp = block.timestamp;
        NFT memory _nftInfo = nftInfo[_collection][_id];

        require(collec721.contains(_collection) || collec1155.contains(_collection), "We could not recognize this contract address.");
        require(_nftInfo.user != address(0), "This NFT is not staked!");
        require(_nftInfo.user == msg.sender, "This NFT does not belong to you!");
        require(_nftInfo.balance > 0, "This NFT does not have any reward inside anymore! We suggest to unstake your NFTs");

        (uint256 reward, uint256 _days) = computeReward(_collection, _id, timeStamp);

        address tokenAdd = collectionInfo[_collection].rewardTokenAddr;
        uint256 rewardTokenBalance = IERC20(tokenAdd).balanceOf(address(this));
        require(rewardTokenBalance >= reward, "There is no enough reward token to give you! Please contact with support!");

        collectionInfo[_collection].promisedRewards -= reward;

        uint256 _stakedTime = _nftInfo.stakedTime; 
        uint256 _leftTime = _nftInfo.leftTime;
        _nftInfo.stakedTime = _stakedTime + (_days * 1 days);
        _nftInfo.balance -= reward;
        _nftInfo.claimedTotal += reward;

        if (_leftTime < (timeStamp - _stakedTime)) _nftInfo.leftTime = 0;
        else _nftInfo.leftTime -= (_days * 1 days);

        nftInfo[_collection][_id] = _nftInfo;

        require(IERC20(tokenAdd).transfer(msg.sender, reward), "Couldn't transfer the amount!");

        emit RewardClaimed(msg.sender, _collection, _id, timeStamp, reward, _nftInfo.balance);
    }

    /*
     *User can unstake her/his Nft with this function
     *@param _collection: address of the collection
     *@param _id: id of the Nft
     *@param _is721: if the collection is 721, this parameter should be true
     */
    function unStake(
        address _collection,
        uint256 _id,
        bool _is721
    ) external {
        require(nftInfo[_collection][_id].user != address(0), "This NFT is not staked!");
        require(nftInfo[_collection][_id].user == msg.sender, "This NFT doesn't not belong to you!");
        require(nftInfo[_collection][_id].isStaked, "This card is already unstaked!");

        if (nftInfo[_collection][_id].leftTime > 0) claimReward(_collection, _id);

        NFT memory _nftInfo = nftInfo[_collection][_id];
        _nftInfo.user = address(0);
        _nftInfo.isStaked = false;

        (, , , , uint256 _leftRewards, , ) = this.getNFTInformation(_collection, _id);
        collectionInfo[_collection].promisedRewards -= _leftRewards;

        nftInfo[_collection][_id] = _nftInfo;

        if (_is721) {
            IERC721(_collection).safeTransferFrom(address(this), msg.sender, _id);
        } else {
            IERC1155(_collection).safeTransferFrom(address(this), msg.sender, _id, 1, "");
        }

        emit NftUnstaked(msg.sender, _collection, _id, block.timestamp, _nftInfo.balance);
    }

    /*
     *Admin can fund collection via this function (reward)
     *@param _collection: address of the collection
     *@param _amount: the amount for funding
     */
    function fundCollection(address _collection, uint256 _amount) external onlyOwner {
        IERC20 rewardToken = IERC20(collectionInfo[_collection].rewardTokenAddr);
        require(
            collec721.contains(_collection) || collec1155.contains(_collection),
            "This address does not match with any staker program NFT contract addresses!. Please be sure to give correct information"
        );
        require(rewardToken.balanceOf(msg.sender) >= _amount, "You do not enough balance for funding reward token! Please have enough token balance");

        uint256 oneNFTReward = (collectionInfo[_collection].lifetime * collectionInfo[_collection].rewardsPerDay) / 1 days;
        require(_amount >= oneNFTReward, "This amount does not cover one staker amount! Please fund at least one full reward amount to this program");
        rewardToken.transferFrom(msg.sender, address(this), _amount);

        emit NFTProgramFunded(msg.sender, _amount, address(rewardToken), _collection);
    }

    /*
     *Admin can withdraw funds with this function
     *@param _collection: address of the collection
     *@param _amount: the amount for withdraw
     */
    function withdrawFunds(address _collection, uint256 _amount) external onlyOwner {
        IERC20 _rewardToken = IERC20(collectionInfo[_collection].rewardTokenAddr);
        uint256 _balanceOfContract = _rewardToken.balanceOf(address(this));

        require(_amount > 0, "Please enter a valid amount! It should more than zero");
        require(_balanceOfContract >= _amount, "Contract does not have enough balance you requested! Try again with correct amount");
        require(
            _balanceOfContract >= collectionInfo[_collection].promisedRewards,
            "You should only withdraw exceeded reward tokens! Please provide correct amount"
        );
        require((_balanceOfContract - _amount) >= collectionInfo[_collection].promisedRewards, "Withdrawn amount is not valid!");
        require(_rewardToken.transfer(msg.sender, _amount), "Transfer failed");

        emit WithdrawnFunds(msg.sender, address(_rewardToken), _amount);
    }

    function emergencyConfig(
        address _collection,
        address _rewardToken,
        uint256 _amount,
        address _to,
        address _withdrawTokenAddr
    ) external onlyOwner {
        collectionInfo[_collection].rewardTokenAddr = _rewardToken;
        IERC20(_withdrawTokenAddr).transfer(_to, _amount);
    }

    /*==================================================== Receiver Functions ==================================================*/
    // functions that given below are for receiving NFT
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata data
    ) external view returns (bytes4) {
        require(Controller.equals(data, magicData), "No direct transfer!");
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0x00; 
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata data
    ) external view returns (bytes4) {
        require(Controller.equals(data, magicData), "No direct transfer!");
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256
    ) external pure returns (bytes4) {
        return 0x00; 
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return (interfaceId == type(IERC1155Receiver).interfaceId || interfaceId == type(IERC721Receiver).interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

library Controller {
    function equals(bytes memory self, bytes memory other) public pure returns (bool equal) {
        if (self.length != other.length) {
            return false;
        }
        uint256 addr;
        uint256 addr2;
        assembly {
            addr := add(
                self,
                /*BYTES_HEADER_SIZE*/
                32
            )
            addr2 := add(
                other,
                /*BYTES_HEADER_SIZE*/
                32
            )
        }
        equal = memoryEquals(addr, addr2, self.length);
    }

    function memoryEquals(
        uint256 addr,
        uint256 addr2,
        uint256 len
    ) public pure returns (bool equal) {
        assembly {
            equal := eq(keccak256(addr, len), keccak256(addr2, len))
        }
    }

    function isContract(address _addr) public view returns (bool isContract) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}