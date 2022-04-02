// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol";

interface ILandContract {
    function ownerOf(uint256 tokenId) external returns (address);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IEstateContract {
    function ownerOf(uint256 tokenId) external returns (address);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function getScore(uint256 tokenId) external view returns(uint score);

    function getMultiplier(uint256 tokenId) external view returns(uint multiplier);

    function totalSupply() external view returns(uint);
}

interface ICogToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IScores {
    function getLandScore(uint tokenID) external view returns (uint score);
}

contract Staker is Ownable, IERC721Receiver {

    address public COG;
    address public LAND;
    address public ESTATE;
    address public SCORES;

    uint public COG_EMISSIONS_PER_DAY = 100;

    bool public CLAIM_REWARDS;

    uint public LOCKUP_PERIOD = 86400 * 50; // 50 days in seconds

    struct StakerInfo {
        address owner;
        uint stakedAt;
        uint lastRewardsClaimedAt;
    }

    // since token ids are unique so, creating a mapping with token ids instead of owner address
    mapping(uint => StakerInfo) public stakedLands;
    mapping(address => uint) public landBalances;

    mapping(uint => StakerInfo) public stakedEstates;
    mapping(address => uint) public estateBalances;

    constructor (address cog, address land, address estate, address scores) {
        COG = cog;
        LAND = land;
        ESTATE = estate;
        SCORES = scores;
    }

    // for land
    modifier onlyLandMinter() {
        require(msg.sender == LAND, "Only the land minter contract can call this function.");
        _;
    }

    // estate contract is the estate minter.
    modifier onlyEstateMinter() {
        require(msg.sender == ESTATE, "Only the estate minter contract can call this function.");
        _;
    }

    function setCOGEmissions(uint _cogEmissionsPerDay) public onlyOwner {
        require(_cogEmissionsPerDay > 0, "Can't be zero");
        COG_EMISSIONS_PER_DAY = _cogEmissionsPerDay;
    }

    function setClaimRewards(bool claim) public onlyOwner {
        CLAIM_REWARDS = claim;
    }

    function setLand(address land) public onlyOwner {
        require(land != address(0), "Can't be a zero address");
        LAND = land;
    }

    function setEstate(address estate) public onlyOwner {
        require(estate != address(0), "Can't be a zero address");
        ESTATE = estate;
    }

    function setScores(address scores) public onlyOwner {
        require(scores != address(0), "Can't be a zero address");
        SCORES = scores;
    }

    function setLockupPeriod(uint period) public onlyOwner {
        LOCKUP_PERIOD = period;
    }

    // for manual staking after mint
    function stakeLand(uint[] memory tokenIds) public returns (bool success) {
        for (uint index = 0; index < tokenIds.length; index++) {
            require(tokenIds[index] > 0 && tokenIds[index] <= 10000, "Invalid token id");
            require(ILandContract(LAND).ownerOf(tokenIds[index]) == msg.sender, "Token not your");
            require(stakedLands[tokenIds[index]].stakedAt == 0, "Token already staked");
            ILandContract(LAND).transferFrom(msg.sender, address(this), tokenIds[index]);
            stakedLands[tokenIds[index]] =
            StakerInfo({
                owner : msg.sender,
                stakedAt : block.timestamp,
                lastRewardsClaimedAt : 0
            });
            landBalances[msg.sender] += 1;
        }
        return true;
    }

    // stake directly from mint
    function stakeLandFromMinter(uint[] memory tokenIds, address _owner) public onlyLandMinter returns(bool success){
        for (uint index = 0; index < tokenIds.length; index++) {
            stakedLands[tokenIds[index]] =
            StakerInfo({
                owner : _owner,
                stakedAt : block.timestamp,
                lastRewardsClaimedAt : 0
            });
            landBalances[msg.sender] += 1;
        }
        return true;
    }

    // unstake all lands or one by one
    function unStakeLand(uint[] memory tokenIds) public returns (bool result) {
        for (uint index = 0; index < tokenIds.length; index++) {
            require(landBalances[msg.sender] > 0, "No tokens staked");
            StakerInfo storage stakerInfo = stakedLands[tokenIds[index]];
            require(stakerInfo.owner == msg.sender, "Not your token");
            require(stakerInfo.stakedAt > 0, "Not staked yet");
            uint countRewardsFrom;
            if (stakerInfo.lastRewardsClaimedAt > 0) {
                countRewardsFrom = stakerInfo.lastRewardsClaimedAt;
            } else {
                countRewardsFrom = stakerInfo.stakedAt;
            }
            if (CLAIM_REWARDS) {
                uint timeStaked = block.timestamp - stakerInfo.stakedAt;
                if (timeStaked > LOCKUP_PERIOD) {
                    distributeCOG(calculateTokenDistributionForLand(tokenIds[index], countRewardsFrom), stakerInfo.owner);
                }
            }
            ILandContract(LAND).transferFrom(address(this), stakerInfo.owner, tokenIds[index]);
            stakerInfo.owner = address(0);
            stakerInfo.stakedAt = 0;
            stakerInfo.lastRewardsClaimedAt = block.timestamp;
            landBalances[msg.sender] -= 1;
        }

        return true;
    }

    function claimLandRewards(uint[] memory tokenIds) public returns (bool success) {
        require(CLAIM_REWARDS, "Rewards distribution not started yet");
        require(landBalances[msg.sender] > 0, "No tokens staked");
        for (uint index = 0; index < tokenIds.length; index++) {
            StakerInfo storage stakerInfo = stakedLands[tokenIds[index]];
            require(stakerInfo.owner == msg.sender, "Not your token");
            require(stakerInfo.stakedAt > 0, "Not staked yet");
            uint countRewardsFrom;
            if (stakerInfo.lastRewardsClaimedAt > 0) {
                countRewardsFrom = stakerInfo.lastRewardsClaimedAt;
            } else {
                countRewardsFrom = stakerInfo.stakedAt;
            }
            uint timeStaked = block.timestamp - stakerInfo.stakedAt;
            require(timeStaked > LOCKUP_PERIOD, "Lockup period not expired yet.");
            distributeCOG(calculateTokenDistributionForLand(tokenIds[index], countRewardsFrom), stakerInfo.owner);
            stakerInfo.lastRewardsClaimedAt = block.timestamp;
        }
        return true;
    }

    // for estate token
    function stakeEstate(uint[] memory tokenIds) public returns (bool result) {
        for (uint index = 0; index < tokenIds.length; index++) {
            require(tokenIds[index] > 0 && tokenIds[index] <= IEstateContract(ESTATE).totalSupply(), "Invalid token id");
            require(IEstateContract(ESTATE).ownerOf(tokenIds[index]) == msg.sender, "Token not your");
            require(stakedEstates[tokenIds[index]].stakedAt == 0, "Token already staked");
            IEstateContract(ESTATE).transferFrom(msg.sender, address(this), tokenIds[index]);
            stakedEstates[tokenIds[index]] =
            StakerInfo({
                owner : msg.sender,
                stakedAt : block.timestamp,
                lastRewardsClaimedAt : 0
            });
            estateBalances[msg.sender] += 1;
        }
        return true;
    }

    function stakeEstateFromMinter(uint tokenId, address _owner) public onlyEstateMinter returns(bool) {
        stakedEstates[tokenId] =
        StakerInfo({
            owner : _owner,
            stakedAt : block.timestamp,
            lastRewardsClaimedAt : 0
        });
        estateBalances[_owner] += 1;
        return true;
    }

    function unStakeEstate(uint[] memory tokenIds) public returns (bool result) {
        for (uint index = 0; index < tokenIds.length; index++) {
            require(estateBalances[msg.sender] > 0, "No tokens staked");
            StakerInfo storage stakerInfo = stakedEstates[tokenIds[index]];
            require(stakerInfo.owner == msg.sender, "Not your token");
            require(stakerInfo.stakedAt > 0, "Not staked yet");
            uint countRewardsFrom;
            if (stakerInfo.lastRewardsClaimedAt > 0) {
                countRewardsFrom = stakerInfo.lastRewardsClaimedAt;
            } else {
                countRewardsFrom = stakerInfo.stakedAt;
            }
            uint timeStaked = block.timestamp - stakerInfo.stakedAt;
            if (CLAIM_REWARDS && timeStaked > LOCKUP_PERIOD) {
                distributeCOG(calculateTokenDistributionForEstate(tokenIds[index], countRewardsFrom), stakerInfo.owner);
            }
            IEstateContract(ESTATE).transferFrom(address(this), stakerInfo.owner, tokenIds[index]);
            stakerInfo.owner = address(0);
            stakerInfo.stakedAt = 0;
            stakerInfo.lastRewardsClaimedAt = 0;
            estateBalances[msg.sender] -= 1;
        }
        return true;
    }

    function claimEstateRewards(uint[] memory tokenIds) public returns (bool) {
        require(CLAIM_REWARDS, "Rewards distribution not started yet");
        require(estateBalances[msg.sender] > 0, "No tokens staked");
        for (uint index = 0; index < tokenIds.length; index++) {
            StakerInfo storage stakerInfo = stakedEstates[tokenIds[index]];
            require(stakerInfo.owner == msg.sender, "Not your token");
            require(stakerInfo.stakedAt > 0, "Not staked yet");
            uint countRewardsFrom;
            if (stakerInfo.lastRewardsClaimedAt > 0) {
                countRewardsFrom = stakerInfo.lastRewardsClaimedAt;
            } else {
                countRewardsFrom = stakerInfo.stakedAt;
            }
            uint timeStaked = block.timestamp - stakerInfo.stakedAt;
            require(timeStaked > LOCKUP_PERIOD, "Lockup period not expired yet.");
            distributeCOG(calculateTokenDistributionForEstate(tokenIds[index], countRewardsFrom), stakerInfo.owner);
            stakerInfo.lastRewardsClaimedAt = block.timestamp;
        }
        return true;
    }

    // emergency withdrawal functions

    function withdrawNFTs(uint tokenID, bool _isLand) public onlyOwner {
        if (_isLand) {
            ILandContract(LAND).transferFrom(address(this), msg.sender, tokenID);
        } else {
            IEstateContract(ESTATE).transferFrom(address(this), msg.sender, tokenID);
        }
    }

    function withdrawCOG(uint _amount) public onlyOwner {
        ICogToken(COG).transfer(msg.sender, _amount);
    }

    function distributeCOG(uint amount, address to) internal {
        ICogToken(COG).transfer(to, amount);
    }

    function calculateTokenDistributionForLand(uint tokenId, uint lastClaimedAt) public view returns(uint amountToDistribute) {
        uint landScore = IScores(SCORES).getLandScore(tokenId);
        uint tokensPerDay = COG_EMISSIONS_PER_DAY / 100 * landScore;
        uint tokensPerSecond = tokensPerDay / 86400;
        uint stakeTimeInSeconds = block.timestamp - lastClaimedAt;
        return (tokensPerSecond * stakeTimeInSeconds) * 10**18;
    }

    function calculateTokenDistributionForEstate(uint estateId, uint lastClaimedAt) public view returns(uint amountToDistribute) {

        uint estateScore = IEstateContract(ESTATE).getScore(estateId);
        uint multiplier = IEstateContract(ESTATE).getMultiplier(estateId);

        uint cogDistributionPerDay = (COG_EMISSIONS_PER_DAY / 100) * estateScore;
        uint tokensPerSecond = cogDistributionPerDay / 86400;
        uint stakeTimeInSeconds = block.timestamp - lastClaimedAt;
        uint tokensToDistribute = stakeTimeInSeconds * tokensPerSecond;
        // multiplier is supposed to be 1.multiplier
        uint multiplierAmount = (tokensToDistribute / 100) * multiplier;
        return (tokensToDistribute + multiplierAmount) * 10**18;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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