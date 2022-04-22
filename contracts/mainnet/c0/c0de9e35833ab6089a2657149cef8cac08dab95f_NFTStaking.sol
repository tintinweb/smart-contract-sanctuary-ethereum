/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

// SPDX-License-Identifier: MIT

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

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IERC721Custom {
    function balanceOf(address owner) external view returns (uint256 balance);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC20Custom {
    function mint(address to, uint256 amount) external;
    function hasRole(bytes32 role, address account) external view returns (bool);
}

interface IVesting {
    function addLock(address to, uint256 amount) external;
}

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract NFTStaking is Context, Ownable, IERC721Receiver, ERC165, ReentrancyGuard {
    IERC721Custom public nftForStaking;
    IERC20Custom public rewardToken;
    IVesting public vestingContract;
    
    uint256 public firstStakingPoolRewardPercent  = 25;
    uint256 public secondStakingPoolRewardPercent = 35;
    uint256 public thirdStakingPoolRewardPercent  = 40;

    uint256 public defaultStakingPool = 3;

    uint256[25] public allPeriods;    
    uint256[24] public tokenMultipliers = [10,10,13,13,15,15,15,15,20,20,20,20,25,25,25,25,30,30,30,30,40,40,40,40];
    uint256[24] public periodRewards = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    uint256[24] public periodBonuses = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    uint256[24] public periodEstimatedRewards = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    uint256[24][3] public periodPoolsRewards;
    uint256[24][3] public periodPoolsBonuses;
    uint256[24][3] public periodPoolsEstimatedRewards;

    mapping(address => uint256[]) public stakedNfts;
    address[] public firstDayStakersAddresses;
    
    bool private stakingAllowance = false;
    uint256[3] private _isPoolEnabled = [1,1,1];
    mapping(address => bool) private _isFirstDayStaker;
    mapping(uint256 => address) private _nftsOwners;
    mapping(uint256 => uint256[11]) private _stakes;
    mapping(address => uint256[11][]) private _stakeSnapshots;
    uint256[24][3] private _allSharesPowerPerStakingPool;
    uint256 private _lastPeriodEstimatedRewards;

    uint256 quarter = 90;
    uint256 recalculation = 1;
    uint256 quantity = 1 days;
  
    
    // constructor
    constructor(address nft, address token) {
        _setNft(nft);
        _setToken(token);
        periodPoolsRewards[0] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        periodPoolsRewards[1] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        periodPoolsRewards[2] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        periodPoolsBonuses[0] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        periodPoolsBonuses[1] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        periodPoolsBonuses[2] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        periodPoolsEstimatedRewards[0] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        periodPoolsEstimatedRewards[1] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        periodPoolsEstimatedRewards[2] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        quarter = quarter * quantity;
        recalculation = recalculation * quantity;
    }


    // external functions
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        require (_msgSender() == address(nftForStaking), "NFTStaking: transfer not allowed");
        require(isStakingAllowed(), "NFTStaking: staking is not allowed");
        
        _addStake(from, tokenId, defaultStakingPool);

        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }


    // ownable public functions
    function setNft(address nft) public onlyOwner {
        require(nftForStaking.balanceOf(address(this)) == uint256(0), "NFTStaking: not empty balance");
        _setNft(nft);
    }

    function setToken(address erc20) public onlyOwner {
        IERC20Custom token = IERC20Custom(erc20);
        require(token.hasRole(keccak256("MINTER_ROLE"), address(this)), "NFTStaking: must have minter role to mint");
        _setToken(erc20);
    }   

    function setVesting(address vesting) public onlyOwner {
        _setVesting(vesting);
    }

    function allowStaking(address vesting) public onlyOwner {
        require(!stakingAllowance, "NFTStaking: staking is already allowed");
        require(rewardToken.hasRole(keccak256("MINTER_ROLE"), address(this)), "NFTStaking: must have minter role to mint");
        _setVesting(vesting);
        uint256 timestamp = block.timestamp;
        allPeriods[0] = timestamp;
        
        for (uint256 i = 1; i < 25; i++) {
            timestamp = timestamp + quarter;
            allPeriods[i] = timestamp;            
        }       
        stakingAllowance = true;
    }   

    function setStakingPoolsRewardPercentages(uint256 first, uint256 second, uint256 third) public onlyOwner {
        require((first + second + third) == 100, "NFTStaking: wrong percentages");
        firstStakingPoolRewardPercent = first;
        secondStakingPoolRewardPercent = second;
        thirdStakingPoolRewardPercent = third;
        
        _isPoolEnabled[0] = first > 0 ? 1 : 0;
        _isPoolEnabled[1] = second > 0 ? 1 : 0;
        _isPoolEnabled[2] = third > 0 ? 1 : 0;
        
        if (_isPoolEnabled[defaultStakingPool - 1] == 0) {
            for (uint256 pool = 0; pool < 3; pool++) {
                if (_isPoolEnabled[pool] == 1) {
                    defaultStakingPool = pool + 1;
                    break;
                }
            }
        }
    }

    function setDefaultStakingPool(uint256 pool) public onlyOwner {
        require(pool != 0 && pool < 4, "NFTStaking: wrong pool");
        require(_isPoolEnabled[pool - 1] != 0, "NFTStaking: pool is disabled");
        defaultStakingPool = pool;
    }

    function setRewardForLastPeriod(uint256 amount) public onlyOwner {
        require(stakingAllowance, "NFTStaking: staking is not allowed");
        require(amount > 0, "NFTStaking: empty reward");
        uint256 currentPeriod = (block.timestamp - allPeriods[0]) / quarter;
        if (currentPeriod > 0 && currentPeriod < 25) {
            if (periodRewards[currentPeriod - 1] == 0) {
                periodRewards[currentPeriod - 1] = amount;
                periodPoolsRewards[0][currentPeriod - 1] = amount * firstStakingPoolRewardPercent / 100;
                periodPoolsRewards[1][currentPeriod - 1] = amount * secondStakingPoolRewardPercent / 100;
                periodPoolsRewards[2][currentPeriod - 1] = amount * thirdStakingPoolRewardPercent / 100;
            }
        }
        
        if (currentPeriod > 24) {
            stakingAllowance = false;
        }
    }
    
    function setBonusForLastPeriod(uint256 amount) public onlyOwner {
        require(stakingAllowance, "NFTStaking: staking is not allowed");
        require(amount > 0, "NFTStaking: empty bonus");
        uint256 currentPeriod = (block.timestamp - allPeriods[0]) / quarter;
        if (currentPeriod > 0 && currentPeriod < 25) {
            if (periodRewards[currentPeriod - 1] != 0 && periodBonuses[currentPeriod - 1] == 0) {
                periodBonuses[currentPeriod - 1] = amount;
                periodPoolsBonuses[0][currentPeriod - 1] = amount * firstStakingPoolRewardPercent / 100;
                periodPoolsBonuses[1][currentPeriod - 1] = amount * secondStakingPoolRewardPercent / 100;
                periodPoolsBonuses[2][currentPeriod - 1] = amount * thirdStakingPoolRewardPercent / 100;
            }
        }
        
        if (currentPeriod > 24) {
            stakingAllowance = false;
        }
    }

    function setEstimatedReward(uint256 amount) public onlyOwner {
        require(stakingAllowance, "NFTStaking: staking is not allowed");
        require(amount > 0, "NFTStaking: empty reward");
        uint256 currentPeriod = (block.timestamp - allPeriods[0]) / quarter;
        if (currentPeriod < 24) {
            periodEstimatedRewards[currentPeriod] = amount;
            periodPoolsEstimatedRewards[0][currentPeriod] = amount * firstStakingPoolRewardPercent / 100;
            periodPoolsEstimatedRewards[1][currentPeriod] = amount * secondStakingPoolRewardPercent / 100;
            periodPoolsEstimatedRewards[2][currentPeriod] = amount * thirdStakingPoolRewardPercent / 100;
            _lastPeriodEstimatedRewards = currentPeriod;
        }

        if (currentPeriod > 24) {
            stakingAllowance = false;
        }
    }

    // public functions
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }    

    function isStakingAllowed() public view returns (bool) {
        if (stakingAllowance && ((block.timestamp - allPeriods[0]) / quarter) < 23) {
            return true;
        }
        return false;
    }

    function getOwnerByTokenId(uint256 tokenId) public view returns (address) {
        return _nftsOwners[tokenId];
    }
    
    function getCurrentQuarterFromStart() public view returns (uint256) {
        uint256 count = ((block.timestamp - allPeriods[0]) / quarter) + 1;
        return count;
    }
    
    function getCurrentDayOfQuarter() public view returns (uint256) {
        uint256 currentQuarter = (block.timestamp - allPeriods[0]) / quarter;
        uint256 day = ((block.timestamp - allPeriods[currentQuarter]) / recalculation) + 1;
        return day;
    }
    
    function getCurrentMultiplierForToken(uint256 tokenId) public view returns (uint256) {
        uint256 startTime = _stakes[tokenId][2];
        uint256 duration = (block.timestamp - startTime) / quarter;
        uint256 multiplier = tokenMultipliers[duration];
        return multiplier;
    }

    function getStakingPoolsOfToken(uint256 tokenId) public view returns (uint256 pools) {
        uint256 pool1 = _stakes[tokenId][8];
        uint256 pool2 = _stakes[tokenId][9];
        uint256 pool3 = _stakes[tokenId][10];
        if (pool1 == 1 && pool2 == 0 && pool3 == 0) {
            return 1;
        }
        if (pool1 == 0 && pool2 == 1 && pool3 == 0) {
            return 2;
        }
        if (pool1 == 0 && pool2 == 0 && pool3 == 1) {
            return 3;
        }
        if (pool1 == 1 && pool2 == 1 && pool3 == 0) {
            return 12;
        }
        if (pool1 == 1 && pool2 == 0 && pool3 == 1) {
            return 13;
        }
        if (pool1 == 0 && pool2 == 1 && pool3 == 1) {
            return 23;
        }
        if (pool1 == 1 && pool2 == 1 && pool3 == 1) {
            return 123;
        }                
    }

    function getNftsCount() public view returns (uint256) {
        uint256 len = stakedNfts[_msgSender()].length;
        return len;
    }
    
     function getNfts() public view returns (uint256[] memory) {
        uint256 len = stakedNfts[_msgSender()].length;
        uint256[] memory nfts = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            nfts[i] = stakedNfts[_msgSender()][i];
        }
        return nfts;
    }

    function getNftsByAddress(address user) public view returns (uint256[] memory) {
        uint256 len = stakedNfts[user].length;
        uint256[] memory nfts = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            nfts[i] = stakedNfts[user][i];
        }
        return nfts;
    }

    function getCurrentMultipliers() public view returns (uint256[] memory) {
        uint256 len = stakedNfts[_msgSender()].length;
        uint256[] memory multipliers = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = stakedNfts[_msgSender()][i];
            uint256 startTime = _stakes[tokenId][2];
            uint256 duration = (block.timestamp - startTime) / quarter;
            uint256 multiplier = tokenMultipliers[duration];
            multipliers[i] = multiplier;
        }
        return multipliers;               
    }

    function claimableRewards(address user) public view returns (uint256) {
        return _calcAccruedRewards(user);
    }

    function estimatedRewards(address user) public view returns (uint256) {
        return _calcEstimatedRewards(user);
    }

    function firstDayStakersCount() public view returns (uint256) {
        return firstDayStakersAddresses.length;
    }
    
    function stake(uint256 tokenId, uint256 pool) public nonReentrant {
        require(isStakingAllowed(), "NFTStaking: staking is not allowed");     
        require((nftForStaking.getApproved(tokenId) == address(this)) || (nftForStaking.isApprovedForAll(_msgSender(),address(this))), "NFTStaking: transfer not allowed");
        require(pool != 0 && pool < 4, "NFTStaking: wrong pool");
        require(_isPoolEnabled[pool - 1] != 0, "NFTStaking: pool is disabled");
        nftForStaking.transferFrom(_msgSender(), address(this), tokenId);
        _addStake(_msgSender(), tokenId, pool);
    }

    function chooseAdditionalStakingPool(uint256 tokenId, uint256 pool) public nonReentrant {
        require(isStakingAllowed(), "NFTStaking: staking is not allowed");
        require(tokenId > 250 && tokenId < 1501, "NFTStaking: not allowing additional staking");
        require(_msgSender() == _nftsOwners[tokenId], "NFTStaking: not a token owner");
        require(pool != 0 && pool < 4, "NFTStaking: wrong pool");
        require(_isPoolEnabled[pool - 1] != 0, "NFTStaking: pool is disabled");
        require((_stakes[tokenId][8] + _stakes[tokenId][9] + _stakes[tokenId][10]) == 1, "NFTStaking: additional pool already chosen");
        if (pool == 1) {
            require(_stakes[tokenId][8] == 0, "NFTStaking: pool already chosen");
            _stakes[tokenId][8] = 1;
        }
        else if (pool == 2) {
            require(_stakes[tokenId][9] == 0, "NFTStaking: pool already chosen");
            _stakes[tokenId][9] = 1;
        }        
        else if (pool == 3) {
            require(_stakes[tokenId][10] == 0, "NFTStaking: pool already chosen");
            _stakes[tokenId][10] = 1;
        }          

        uint256 tokenPower = _stakes[tokenId][5];        
        uint256 currentPeriod = _stakes[tokenId][3];
        uint256 startDay = _stakes[tokenId][4];      
        _addShare(tokenPower, currentPeriod, startDay, pool);
    }

    function unstake(uint256 tokenId) public {
        require(_msgSender() == _nftsOwners[tokenId], "NFTStaking: not a token owner");
        uint256 accruedInterest = _calcAccruedRewards(_msgSender());
        if (accruedInterest > 0) {
            claim();
        }
        _unstake(_msgSender(), tokenId);
        uint256 len = stakedNfts[_msgSender()].length;       
        for (uint256 i = 0; i < len; i++) {
            if (stakedNfts[_msgSender()][i] == tokenId) {
                stakedNfts[_msgSender()][i] = stakedNfts[_msgSender()][len - 1];
            }
        }     
        stakedNfts[_msgSender()].pop();      
    }

    function unstakeAll() public {
        uint256 len = stakedNfts[_msgSender()].length;
        uint256 accruedInterest = _calcAccruedRewards(_msgSender());
        if (accruedInterest > 0) {
            claim();
        }
        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = stakedNfts[_msgSender()][i];
            _unstake(_msgSender(), tokenId);
        }
        for (uint256 i = 0; i < len; i++) {
            stakedNfts[_msgSender()].pop();
        }
    }

    function claim() public nonReentrant {
        uint256 accruedInterest = _calcAccruedRewards(_msgSender());      
        require(accruedInterest > 0, "NFTStaking: nothing to claim");
        uint256 currentPeriod = (block.timestamp - allPeriods[0]) / quarter;
        uint256 i;
        
        if (currentPeriod > 23) {
            currentPeriod = 24;
        }

        for (i = 0; i < stakedNfts[_msgSender()].length; i++) {
            uint256 tokenId = stakedNfts[_msgSender()][i];        
            
            if (periodRewards[currentPeriod - 1] > 0 ) {
                _stakes[tokenId][0] = currentPeriod + 1;
            }
            else {
                _stakes[tokenId][0] = currentPeriod;
            }

            if (periodBonuses[currentPeriod - 1] > 0 ) {
                _stakes[tokenId][1] = currentPeriod + 1;
            }
            else {
                _stakes[tokenId][1] = currentPeriod;
            }
        }
    
        uint256 count = 0;
        for (i = 0; i < _stakeSnapshots[_msgSender()].length; i++) {
            uint256[11] memory snapshot = _stakeSnapshots[_msgSender()][i];
            uint256 check = 0;     
          
            if (periodRewards[snapshot[6]] > 0) {
                _stakeSnapshots[_msgSender()][i][0] = 99;
                check++;
            }
            else if (periodRewards[snapshot[6]] == 0 && periodRewards[snapshot[6] - 1] > 0) {
                _stakeSnapshots[_msgSender()][i][0] = snapshot[6] + 1;
            }
            else if (periodRewards[snapshot[6]] == 0 && periodRewards[snapshot[6] - 1] == 0) {
                _stakeSnapshots[_msgSender()][i][0] = snapshot[6];
            }

            if (periodBonuses[snapshot[6]] > 0 || periodRewards[snapshot[6] + 1] > 0) {
                _stakeSnapshots[_msgSender()][i][1] = 99;
                check++;
            }
            else if (periodBonuses[snapshot[6] - 1] > 0 || periodRewards[snapshot[6]] > 0) {
                _stakeSnapshots[_msgSender()][i][1] = snapshot[6] + 1;
            }            
            else if (periodBonuses[snapshot[6] - 1] == 0 && periodRewards[snapshot[6]] == 0) {
                _stakeSnapshots[_msgSender()][i][1] = snapshot[6];
            }
         
            if (check == 2) {
                count++;
            }
        }
        
        while (count != 0) {
            _stakeSnapshots[_msgSender()].pop();
            count--;
        }
        
        uint256 amountToWallet = (accruedInterest / 100) * 33;
        uint256 amountToVesting = (accruedInterest / 100) * 67;
        rewardToken.mint(_msgSender(), amountToWallet);
        rewardToken.mint(address(vestingContract), amountToVesting);
        vestingContract.addLock(_msgSender(), amountToVesting);        
    }

    // private functions 
    function _setNft(address erc721) private {
        require(erc721 != address(0), "not valid address");
        IERC721Custom nft = IERC721Custom(erc721);       
        require(nft.supportsInterface(bytes4(0x80ac58cd)), "not ERC721");       
        nftForStaking = nft;
    }
    
    function _setToken(address erc20) private {
        require(erc20 != address(0), "NFTStaking: not valid address");
        IERC20Custom token = IERC20Custom(erc20);
        rewardToken = token;
    }

    function _setVesting(address vesting_) private {
        require(vesting_ != address(0), "NFTStaking: not valid address");
        IVesting vesting = IVesting(vesting_);
        vestingContract = vesting;
    }

    function _addStake(address staker, uint256 tokenId, uint256 pool) private {
        stakedNfts[staker].push(tokenId);
        _nftsOwners[tokenId] = staker;

        uint256 currentPeriod = (block.timestamp - allPeriods[0]) / quarter;
        uint256 nextPeriod = currentPeriod + 1;
        uint256 startDay = ((block.timestamp - allPeriods[currentPeriod]) / recalculation) + 1;
        uint256 tokenPower = _getTokenPower(tokenId);
        
        if (tokenId < 251) {
            _stakes[tokenId] = [nextPeriod,nextPeriod,block.timestamp,currentPeriod,startDay,tokenPower,0,0,1,1,1];
            _addShare(tokenPower, currentPeriod, startDay, 1);
            _addShare(tokenPower, currentPeriod, startDay, 2);
            _addShare(tokenPower, currentPeriod, startDay, 3);
        }
        else {
            if (pool == 1) {
                _stakes[tokenId] = [nextPeriod,nextPeriod,block.timestamp,currentPeriod,startDay,tokenPower,0,0,1,0,0];
                _addShare(tokenPower, currentPeriod, startDay, 1);
            }
            else if (pool == 2) {
                _stakes[tokenId] = [nextPeriod,nextPeriod,block.timestamp,currentPeriod,startDay,tokenPower,0,0,0,1,0];
                _addShare(tokenPower, currentPeriod, startDay, 2);
            }
            else if (pool == 3) {
                _stakes[tokenId] = [nextPeriod,nextPeriod,block.timestamp,currentPeriod,startDay,tokenPower,0,0,0,0,1];
                _addShare(tokenPower, currentPeriod, startDay, 3);
            }        
        }
        
        if (currentPeriod == 0 && startDay == 1) {
            if (!_isFirstDayStaker[staker]) {
                _isFirstDayStaker[staker] = true;
                firstDayStakersAddresses.push(staker);
            }
        }
    }

    function _addShare(uint256 tokenPower, uint256 currentPeriod, uint256 startDay, uint256 pool) private {
        for (uint256 i = currentPeriod; i < 24; i++) {
            if (i == currentPeriod) {
                _allSharesPowerPerStakingPool[pool - 1][i] = _allSharesPowerPerStakingPool[pool - 1][i] + (tokenPower * tokenMultipliers[0] * (quarter + recalculation - startDay));
            }
            else {
                _allSharesPowerPerStakingPool[pool - 1][i] = _allSharesPowerPerStakingPool[pool - 1][i] + (tokenPower * ((tokenMultipliers[i - currentPeriod - 1] * startDay) + (tokenMultipliers[i - currentPeriod] * (quarter + recalculation - startDay))));
            }
        }
    }

    function _unstake(address staker, uint256 tokenId) private {    
        _removeStake(staker, tokenId);        
        nftForStaking.transferFrom(address(this), staker, tokenId);       
    }

    function _removeStake(address staker, uint256 tokenId) private {       
        delete _nftsOwners[tokenId];
        uint256 currentPeriod = (block.timestamp - allPeriods[0]) / quarter;
        
        if (currentPeriod < 24) {        
            uint256 duration = (block.timestamp - _stakes[tokenId][2]) / quarter;
            uint256 startPeriod = _stakes[tokenId][3];
            uint256 startDay = _stakes[tokenId][4];
            uint256 tokenPower = _stakes[tokenId][5];
            uint256 endDay = ((block.timestamp - allPeriods[currentPeriod]) / recalculation) + 1;
            uint256 i;

            if (duration >= 1) {      
                _stakes[tokenId][6] = currentPeriod;
                _stakes[tokenId][7] = endDay;
                _createSnapshot(staker, tokenId);
            }
        
            for (uint256 p = 8; p < 11; p++) {
                uint256 pool = 0;
                if (p == 8 && _stakes[tokenId][8] == 1) {
                    pool = 1;
                }
                else if (p == 9 && _stakes[tokenId][9] == 1) {
                    pool = 2;
                }
                else if (p == 10 && _stakes[tokenId][10] == 1) {
                    pool = 3;
                }

                if (pool > 0) {
                    if (duration >= 1) {      
                        for (i = currentPeriod; i < 24; i++) {
                            _allSharesPowerPerStakingPool[pool - 1][i] = _allSharesPowerPerStakingPool[pool - 1][i] - (tokenPower * ((tokenMultipliers[i - startPeriod - 1] * startDay) + (tokenMultipliers[i - startPeriod] * (quarter + recalculation - startDay))));
                            if (i == currentPeriod) {
                                if (endDay < startDay) {
                                    _allSharesPowerPerStakingPool[pool - 1][i] = _allSharesPowerPerStakingPool[pool - 1][i] + (tokenPower * tokenMultipliers[i - startPeriod - 1] * endDay);
                                } 
                                else {
                                    _allSharesPowerPerStakingPool[pool - 1][i] = _allSharesPowerPerStakingPool[pool - 1][i] + (tokenPower * ((tokenMultipliers[i - startPeriod - 1] * startDay) + (tokenMultipliers[i - startPeriod] * (endDay - startDay))));
                                }
                            }
                        }
                    }
                    else {        
                        for (i = startPeriod; i < 24; i++) {
                            if (i == startPeriod) {
                                _allSharesPowerPerStakingPool[pool - 1][i] = _allSharesPowerPerStakingPool[pool - 1][i] - (tokenPower * tokenMultipliers[0] * (quarter + recalculation - startDay)); 
                            }
                            else {
                                _allSharesPowerPerStakingPool[pool - 1][i] = _allSharesPowerPerStakingPool[pool - 1][i] - (tokenPower * ((tokenMultipliers[i - startPeriod - 1] * startDay) + (tokenMultipliers[i - startPeriod] * (quarter + recalculation - startDay))));
                            }
                        }   
                    }
                }
            }
        }
        delete _stakes[tokenId];
    }

    function _createSnapshot(address staker, uint256 tokenId) private {
        uint256[11] memory snapshot = _stakes[tokenId];    
        uint256 len = _stakeSnapshots[staker].length + 1;
        uint256[11][] memory newStakeSnapshots = new uint256[11][](len);
        newStakeSnapshots[0] = snapshot;

        for (uint256 i = 0; i < _stakeSnapshots[staker].length; i++) {
            newStakeSnapshots[i + 1] = _stakeSnapshots[staker][i];
        }
        _stakeSnapshots[staker] = newStakeSnapshots;
    }

    function _calcAccruedRewards(address staker) private view returns (uint256) {
        uint256 currentPeriod = (block.timestamp - allPeriods[0]) / quarter;        
        if (currentPeriod > 24) {
            currentPeriod = 24;
        }
        uint256 sum = 0;
        uint256 i;        
        for (i = 0; i < stakedNfts[staker].length; i++) {
            uint256 tokenId = stakedNfts[staker][i];
            uint256 nextClaim = _stakes[tokenId][0];
            uint256 nextBonus = _stakes[tokenId][1];
            uint256 startTime = _stakes[tokenId][2];
            uint256 duration = (block.timestamp - startTime) / quarter;
            uint256 startPeriod = _stakes[tokenId][3];
            uint256 startDay = _stakes[tokenId][4];
            uint256 tokenPower = _stakes[tokenId][5];
            uint256 delta;
            uint256 j;

            for (uint256 p = 8; p < 11; p++) {
                uint256 pool = 0;
                if (p == 8 && _stakes[tokenId][8] == 1) {
                    pool = 1;
                }
                else if (p == 9 && _stakes[tokenId][9] == 1) {
                    pool = 2;
                }
                else if (p == 10 && _stakes[tokenId][10] == 1) {
                    pool = 3;
                }
            
                if (pool > 0) { 
                    if (currentPeriod >= nextClaim && duration >= 1) {
                        for (j = nextClaim - 1; j < currentPeriod; j++) {               
                            delta = (allPeriods[j + 1] - startTime) / quarter;                    
                            if (j == startPeriod) {
                                sum = sum + ((tokenPower * tokenMultipliers[0] * (quarter + recalculation - startDay) * periodPoolsRewards[pool - 1][j]) / _allSharesPowerPerStakingPool[pool - 1][j]);
                            }
                            else {
                                sum = sum + (((tokenPower * ((tokenMultipliers[delta - 1] * startDay) + (tokenMultipliers[delta] * (quarter + recalculation - startDay)))) * periodPoolsRewards[pool - 1][j]) / _allSharesPowerPerStakingPool[pool - 1][j]);
                            }
                        }
                    }            
                    if (currentPeriod >= nextBonus && duration >= 1) {
                        for (j = nextBonus - 1; j < currentPeriod; j++) {               
                            delta = (allPeriods[j + 1] - startTime) / quarter;                    
                            if (j == startPeriod) {
                                sum = sum + ((tokenPower * tokenMultipliers[0] * (quarter + recalculation - startDay) * periodPoolsBonuses[pool - 1][j]) / _allSharesPowerPerStakingPool[pool - 1][j]);
                            }
                            else {
                                sum = sum + (((tokenPower * ((tokenMultipliers[delta - 1] * startDay) + (tokenMultipliers[delta] * (quarter + recalculation - startDay)))) * periodPoolsBonuses[pool - 1][j]) / _allSharesPowerPerStakingPool[pool - 1][j]);
                            }
                        }
                    } 
                }
            }
        }
        sum = sum + _calcAccruedSnapshots(staker);
        return sum;
    }

    function _calcAccruedSnapshots(address staker) private view returns (uint256) { 
        uint256 sum = 0;
        uint256 i;
        for (i = 0; i < _stakeSnapshots[staker].length; i++) {
            uint256[11] memory snapshot = _stakeSnapshots[staker][i];        
            uint256 nextClaim = snapshot[0];
            uint256 nextBonus = snapshot[1];
            uint256 startTime = snapshot[2];
            uint256 startPeriod = snapshot[3];
            uint256 startDay = snapshot[4];
            uint256 tokenPower = snapshot[5];          
            uint256 endPeriod = snapshot[6];
            uint256 endDay = snapshot[7];     

            for (uint256 p = 8; p < 11; p++) {
                uint256 pool = 0;
                if (p == 8 && snapshot[8] == 1) {
                    pool = 1;
                }
                else if (p == 9 && snapshot[9] == 1) {
                    pool = 2;
                }
                else if (p == 10 && snapshot[10] == 1) {
                    pool = 3;
                }
            
                if (pool > 0) {
                    uint256 j;
                    uint256 delta;
                    if (((block.timestamp - allPeriods[0]) / quarter) >= nextClaim) {
                        for (j = nextClaim - 1; j < endPeriod + 1; j++) {
                            delta = (allPeriods[j + 1] - startTime) / quarter;
                            if (j == startPeriod) {
                                sum = sum + ((tokenPower * tokenMultipliers[0] * (quarter + recalculation - startDay) * periodPoolsRewards[pool - 1][j]) / _allSharesPowerPerStakingPool[pool - 1][j]);
                            }
                            else if (j == endPeriod) {
                                if (endDay >= startDay) {
                                    sum = sum + ((tokenPower * ((tokenMultipliers[delta - 1] * startDay) + (tokenMultipliers[delta] * (endDay - startDay)))) * periodPoolsRewards[pool - 1][j] / _allSharesPowerPerStakingPool[pool - 1][j]);
                                } 
                                else {
                                    sum = sum + (tokenPower * tokenMultipliers[delta - 1] * endDay * periodPoolsRewards[pool - 1][j] / _allSharesPowerPerStakingPool[pool - 1][j]);
                                }
                            }
                            else {
                                sum = sum + (((tokenPower * ((tokenMultipliers[delta - 1] * startDay) + (tokenMultipliers[delta] * (quarter + recalculation - startDay)))) * periodPoolsRewards[pool - 1][j]) / _allSharesPowerPerStakingPool[pool - 1][j]);
                            }
                        }
                        for (j = nextBonus - 1; j < endPeriod + 1; j++) {
                            delta = (allPeriods[j + 1] - startTime) / quarter;
                            if (j == startPeriod) {
                                sum = sum + ((tokenPower * tokenMultipliers[0] * (quarter + recalculation - startDay) * periodPoolsBonuses[pool - 1][j]) / _allSharesPowerPerStakingPool[pool - 1][j]);
                            }
                            else if (j == endPeriod) {
                                if (endDay >= startDay) {
                                    sum = sum + ((tokenPower * ((tokenMultipliers[delta - 1] * startDay) + (tokenMultipliers[delta] * (endDay - startDay)))) * periodPoolsBonuses[pool - 1][j] / _allSharesPowerPerStakingPool[pool - 1][j]);
                                } 
                                else {
                                    sum = sum + (tokenPower * tokenMultipliers[delta - 1] * endDay * periodPoolsBonuses[pool - 1][j] / _allSharesPowerPerStakingPool[pool - 1][j]);
                                }
                            }
                            else {
                                sum = sum + (((tokenPower * ((tokenMultipliers[delta - 1] * startDay) + (tokenMultipliers[delta] * (quarter + recalculation - startDay)))) * periodPoolsBonuses[pool - 1][j]) / _allSharesPowerPerStakingPool[pool - 1][j]);
                            }
                        }
                    }
                    if (nextClaim == 99) {                        
                        for (j = nextBonus - 1; j < endPeriod + 1; j++) {
                            delta = (allPeriods[j + 1] - startTime) / quarter;
                            if (j == startPeriod) {
                                sum = sum + ((tokenPower * tokenMultipliers[0] * (quarter + recalculation - startDay) * periodPoolsBonuses[pool - 1][j]) / _allSharesPowerPerStakingPool[pool - 1][j]);
                            }
                            else if (j == endPeriod) {
                                if (endDay >= startDay) {
                                    sum = sum + ((tokenPower * ((tokenMultipliers[delta - 1] * startDay) + (tokenMultipliers[delta] * (endDay - startDay)))) * periodPoolsBonuses[pool - 1][j] / _allSharesPowerPerStakingPool[pool - 1][j]);
                                } 
                                else {
                                    sum = sum + (tokenPower * tokenMultipliers[delta - 1] * endDay * periodPoolsBonuses[pool - 1][j] / _allSharesPowerPerStakingPool[pool - 1][j]);
                                }
                            }
                            else {
                                sum = sum + (((tokenPower * ((tokenMultipliers[delta - 1] * startDay) + (tokenMultipliers[delta] * (quarter + recalculation - startDay)))) * periodPoolsBonuses[pool - 1][j]) / _allSharesPowerPerStakingPool[pool - 1][j]);
                            }
                        }                      
                    }
                }
            }
        }
        return sum;
    }

    function _calcEstimatedRewards(address staker) private view returns (uint256) {
        uint256 currentPeriod = (block.timestamp - allPeriods[0]) / quarter;
        if (currentPeriod > 23) {
            return 0;
        }
        uint256 sum = 0;
        uint256 i;        
        for (i = 0; i < stakedNfts[staker].length; i++) {
            uint256 tokenId = stakedNfts[staker][i];
            uint256 startPeriod = _stakes[tokenId][3];
            uint256 startDay = _stakes[tokenId][4];
            uint256 tokenPower = _stakes[tokenId][5];
            uint256 delta = currentPeriod - startPeriod;

            for (uint256 p = 8; p < 11; p++) {
                uint256 pool = 0;
                if (p == 8 && _stakes[tokenId][8] == 1) {
                    pool = 1;
                }
                else if (p == 9 && _stakes[tokenId][9] == 1) {
                    pool = 2;
                }
                else if (p == 10 && _stakes[tokenId][10] == 1) {
                    pool = 3;
                }
            
                if (pool > 0) {
                    if (periodPoolsEstimatedRewards[pool - 1][currentPeriod] > 0) {
                        if (currentPeriod == startPeriod) {
                            sum = sum + ((tokenPower * tokenMultipliers[0] * (quarter + recalculation - startDay) * periodPoolsEstimatedRewards[pool - 1][currentPeriod]) / _allSharesPowerPerStakingPool[pool - 1][currentPeriod]);
                        }
                        else {
                            sum = sum + (((tokenPower * ((tokenMultipliers[delta - 1] * startDay) + (tokenMultipliers[delta] * (quarter + recalculation - startDay)))) * periodPoolsEstimatedRewards[pool - 1][currentPeriod]) / _allSharesPowerPerStakingPool[pool - 1][currentPeriod]);
                        }
                    }
                    else {
                        if (currentPeriod > 0) {
                            if (currentPeriod == startPeriod) {
                                sum = sum + ((tokenPower * tokenMultipliers[0] * (quarter + recalculation - startDay) * periodPoolsEstimatedRewards[pool - 1][_lastPeriodEstimatedRewards]) / _allSharesPowerPerStakingPool[pool - 1][currentPeriod]);
                            }
                            else {
                                sum = sum + (((tokenPower * ((tokenMultipliers[delta - 1] * startDay) + (tokenMultipliers[delta] * (quarter + recalculation - startDay)))) * periodPoolsEstimatedRewards[pool - 1][_lastPeriodEstimatedRewards]) / _allSharesPowerPerStakingPool[pool - 1][currentPeriod]);

                            }
                        }
                    }
                }
             }
        }
        sum = sum + _calcEstimatedSnapshots(staker);
        return sum;
    }

    function _calcEstimatedSnapshots(address staker) private view returns (uint256) { 
        uint256 currentPeriod = (block.timestamp - allPeriods[0]) / quarter;  
        uint256 sum = 0;
        uint256 i;
        
        for (i = 0; i < _stakeSnapshots[staker].length; i++) {
            uint256[11] memory snapshot = _stakeSnapshots[staker][i];        
            uint256 startPeriod = snapshot[3];
            uint256 startDay = snapshot[4];
            uint256 tokenPower = snapshot[5];
            uint256 endPeriod = snapshot[6]; 
            uint256 endDay = snapshot[7];     
            uint256 delta = currentPeriod - startPeriod;
            if (currentPeriod == endPeriod) {
                for (uint256 p = 8; p < 11; p++) {
                    uint256 pool = 0;
                    if (p == 8 && snapshot[8] == 1) {
                        pool = 1;
                    }
                    else if (p == 9 && snapshot[9] == 1) {
                        pool = 2;
                    }
                    else if (p == 10 && snapshot[10] == 1) {
                        pool = 3;
                    }
            
                    if (pool > 0) {
                        if (periodPoolsEstimatedRewards[pool - 1][currentPeriod] > 0) {
                            if (endDay >= startDay) {
                                sum = sum + (((tokenPower * ((tokenMultipliers[delta - 1] * startDay) + (tokenMultipliers[delta] * (endDay - startDay)))) * periodPoolsEstimatedRewards[pool - 1][currentPeriod]) / _allSharesPowerPerStakingPool[pool - 1][currentPeriod]);
                            }
                            else {
                                sum = sum + (tokenPower * tokenMultipliers[delta - 1] * endDay * periodPoolsEstimatedRewards[pool - 1][currentPeriod] / _allSharesPowerPerStakingPool[pool - 1][currentPeriod]);
                            }
                        }
                        else {
                            if (endDay >= startDay) {
                                sum = sum + (((tokenPower * ((tokenMultipliers[delta - 1] * startDay) + (tokenMultipliers[delta] * (endDay - startDay)))) * periodPoolsEstimatedRewards[pool - 1][_lastPeriodEstimatedRewards]) / _allSharesPowerPerStakingPool[pool - 1][currentPeriod]);
                            }
                            else {
                                sum = sum + (tokenPower * tokenMultipliers[delta - 1] * endDay * periodPoolsEstimatedRewards[pool - 1][_lastPeriodEstimatedRewards] / _allSharesPowerPerStakingPool[pool - 1][currentPeriod]);
                            }
                        } 
                    }
                }
            }
        }
        return sum;
    }

    function _getTokenPower(uint256 tokenId) private pure returns (uint256 rate) {
        if (tokenId >= 1501) {
            return 100;
        }
        else if (tokenId >= 751) {
            return 130;
        }
        else if (tokenId >= 251) {
            return 150;
        }
        else if (tokenId >= 26) {
            return 175;
        }
        else if (tokenId >= 4) {
            return 200;
        }        
        else if (tokenId == 3) {
            return 250;
        }
        else if (tokenId == 2) {
            return 300;
        }
        else if (tokenId == 1) {
            return 400;
        }
    }
}