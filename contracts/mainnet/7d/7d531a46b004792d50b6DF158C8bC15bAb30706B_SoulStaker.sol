/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/SoulStakerNew.sol



pragma solidity ^0.8.4;



interface ISoulSplicers {
    function safeTransferFrom(address,address,uint256,bytes memory) external;
    function balanceOf(address) external view returns (uint256);
}

error IncorrectOwner();
error IncorrectStakePeriod();
error StakingNotComplete();
error NotStaked();
error NotBeenStaked();
error WrongSpender();
error StakingUnavailable();
error NotEnoughRewards();

pragma solidity ^0.8.7;

contract SoulStaker is IERC721Receiver, Ownable{
    ISoulSplicers public splicerContract;
    SoulStaker public oldStakerContract;

    struct StakedNFTData {
        address owner;     
        uint32 releaseTimestamp;
        uint8 t1Rewards;
        uint8 t2Rewards;
        uint8 t3Rewards;        
    }

    bool t2StakingClosed = false;
    bool t3StakingClosed = false;
    bool earlyReleaseActive = false;
    address spendingContract = address(0);
    mapping(uint256 => StakedNFTData) public stakedNFTs;
    mapping(address => uint256) public ownerTokenCount;

    constructor() {
        splicerContract = ISoulSplicers(0xfD4BfE64fea2ce11898c4b931AFAF728778a90b4);
        oldStakerContract = SoulStaker(0xf80faba16B4757598c6FaD1Fe4134039649cB099);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) override pure external returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function stake(uint256[] calldata _tokenIds, uint8[] calldata _months) public {
        uint256 tokenCount = ownerTokenCount[msg.sender];
        bool isT2StakingClosed = t2StakingClosed;
        bool isT3StakingClosed = t3StakingClosed;
        if (earlyReleaseActive) revert StakingUnavailable();

        for (uint256 i = 0; i < _tokenIds.length; i++){
            uint8 months = _months[i];
            uint256 tokenID = _tokenIds[i];

            if (months != 1 && months != 3 && months != 5) revert IncorrectStakePeriod();
            StakedNFTData memory nftData; 
            if (stakedNFTs[tokenID].t1Rewards > 0) nftData = stakedNFTs[tokenID];
            if (months == 3 && (isT2StakingClosed || nftData.t2Rewards > 0)) revert IncorrectStakePeriod();
            if (months == 5 && (isT3StakingClosed || nftData.t3Rewards > 0)) revert IncorrectStakePeriod();
            
            splicerContract.safeTransferFrom(msg.sender, address(this), tokenID, "0x00");
            addRewards(nftData, months, tokenID);
            stakedNFTs[tokenID].releaseTimestamp = uint32(block.timestamp) + (months * 2592000);
            stakedNFTs[tokenID].owner = msg.sender;
            tokenCount += 1;
        }
        ownerTokenCount[msg.sender] = tokenCount;
    }

    function restake(uint256[] calldata _tokenIds, uint8[] calldata _months) public {
        bool isT2StakingClosed = t2StakingClosed;
        if (earlyReleaseActive) revert StakingUnavailable();

        for (uint256 i = 0; i < _tokenIds.length; i++){
            uint8 months = _months[i];
            uint256 tokenID = _tokenIds[i];
            StakedNFTData memory nftData = stakedNFTs[tokenID];

            if (nftData.owner != msg.sender) revert IncorrectOwner();
            if (block.timestamp < nftData.releaseTimestamp) revert StakingNotComplete();
            if (months != 1 && months != 3) revert IncorrectStakePeriod();
            if (months == 3 && (isT2StakingClosed || nftData.t2Rewards > 0)) revert IncorrectStakePeriod();
            
            addRewards(nftData, months, tokenID);
            stakedNFTs[tokenID].releaseTimestamp = uint32(block.timestamp) + (months * 2592000);
        }
    }

    function stakeFromOldContract(uint256[] calldata _tokenIds) public {
        if (block.timestamp > 1661983740) revert StakingUnavailable();
        uint256 tokenCount = ownerTokenCount[msg.sender];

        for (uint256 i = 0; i < _tokenIds.length; i++){
            uint256 tokenID = _tokenIds[i];
            (, uint32 releaseTimestamp, , , ) = oldStakerContract.stakedNFTs(tokenID);
            uint8 months = 0;

            if (releaseTimestamp > 1669846140) months = 5;
            else if (releaseTimestamp > 1664662140) months = 3;
            else if (releaseTimestamp > 1659478140) months = 1;
            else revert NotBeenStaked();

            StakedNFTData memory nftData;
            splicerContract.safeTransferFrom(msg.sender, address(this), tokenID, "0x00");

            addRewards(nftData, months, tokenID);
            stakedNFTs[tokenID].releaseTimestamp = releaseTimestamp;
            stakedNFTs[tokenID].owner = msg.sender;
            tokenCount += 1;
        }
        ownerTokenCount[msg.sender] = tokenCount;
    }     

    function unstake(uint256[] calldata _tokenIds) public {
        bool isEarlyRealeaseActive = earlyReleaseActive;
        uint256 ownerCount = ownerTokenCount[msg.sender];
        for (uint256 i = 0; i < _tokenIds.length; i++){
            uint256 tokenID = _tokenIds[i];
            StakedNFTData memory nftData = stakedNFTs[tokenID];
            if (stakedNFTs[tokenID].owner != msg.sender) revert IncorrectOwner();
            if (!isEarlyRealeaseActive && block.timestamp < nftData.releaseTimestamp) revert StakingNotComplete();
            splicerContract.safeTransferFrom(address(this), msg.sender, tokenID, "0x00");
            delete stakedNFTs[tokenID].owner;
            ownerCount -= 1;
        }
        ownerTokenCount[msg.sender] = ownerCount;
    }    

    function spendRewards(uint256 _tokenID, uint8 _t1, uint8 _t2, uint8 _t3) public {
        if (msg.sender != spendingContract) revert WrongSpender();
        StakedNFTData memory nftRewards = stakedNFTs[_tokenID];
        if (_t1 > nftRewards.t1Rewards || _t2 > nftRewards.t2Rewards || _t3 > nftRewards.t3Rewards) revert NotEnoughRewards();

        nftRewards.t1Rewards -= _t1;
        nftRewards.t2Rewards -= _t2;        
        nftRewards.t3Rewards -= _t3;
        stakedNFTs[_tokenID] = nftRewards;
    }    

    function setEarlyRelease(bool _earlyRelease) public onlyOwner {
        earlyReleaseActive = _earlyRelease;
    }

    function setT2End(bool _ended) public onlyOwner {
        t2StakingClosed = _ended;
    }

    function SetT3End(bool _ended) public onlyOwner {
        t3StakingClosed = _ended;
    }

    function setSpendingContract(address _contractAddress) public onlyOwner {
        spendingContract = _contractAddress;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return ownerTokenCount[owner] + splicerContract.balanceOf(owner) + oldStakerContract.ownerTokenCount(owner);
    }

    function getTimeRemaining(uint256 _tokenID) public view returns (uint256) {
        StakedNFTData memory nftData = stakedNFTs[_tokenID];
        if (nftData.owner == address(0)) revert NotStaked();
        if (block.timestamp >= nftData.releaseTimestamp) return 0;
        return nftData.releaseTimestamp - block.timestamp;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = ownerTokenCount[_owner];
        uint256 currentTokenId = 0;
        uint256 arrIndex = 0;
        uint256[] memory tokenIds = new uint256[](tokenCount);

        while (arrIndex < tokenCount && currentTokenId <= 2600)
        {
            if (stakedNFTs[currentTokenId].owner == _owner)
            {
                tokenIds[arrIndex] = currentTokenId;
                arrIndex++;
            }
            currentTokenId++;
        }       
        return tokenIds;
    }

    function addRewards(StakedNFTData memory _nftData, uint8 months, uint256 id) internal {
        if (months == 1) {
            if (_nftData.t1Rewards < 4) _nftData.t1Rewards += 1;
            stakedNFTs[id].t1Rewards = _nftData.t1Rewards;
            return;
        }
        if (months == 3) {
            _nftData.t1Rewards += 2;
            stakedNFTs[id].t2Rewards = 1;
            stakedNFTs[id].t1Rewards = _nftData.t1Rewards;
            return;
        }
        if (months == 5) {
            stakedNFTs[id].t3Rewards = 1;
            stakedNFTs[id].t2Rewards = 2;
            stakedNFTs[id].t1Rewards = 4;
        }
    }
}