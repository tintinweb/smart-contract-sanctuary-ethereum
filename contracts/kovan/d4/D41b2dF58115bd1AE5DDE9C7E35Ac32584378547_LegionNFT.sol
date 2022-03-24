// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IFeeHandler.sol";
import "./interfaces/ILegionNFT.sol";
import "./interfaces/IRewardPool.sol";
import "./FeeHandler.sol";
import "./RewardPool.sol";
import "./BeastNFT.sol";
import "./WarriorNFT.sol";
import "./Monster.sol";
import "./Marketplace.sol";

contract LegionNFT is Context, ILegionNFT, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    IERC20 public bloodstone;
    IBeastNFT public beast;
    IWarriorNFT public warrior;
    string public _baseURL;
    FeeHandler public feehandler;
    RewardPool public rewardpool;
    Marketplace public marketplace;
    Monster public monster;
    address public rewardPoolAddr;

    uint256 maxBeasts = 10;
    uint256 public totalHuntedCount;
    mapping(uint256 => uint256) public monsterHuntCount;

    struct Legion {
        string name;
        uint256[] beast_ids;
        uint256[] warrior_ids;
        uint256 supplies;
        uint256 attack_power;
        uint256 minted_time;
    }
    mapping (uint256 => Legion) tokenData;
    mapping (uint256 => uint256) public lastHuntTime;
    mapping (address => uint256[]) addressTokenIds;

    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    mapping (uint256 => address) tokenToOwner;
    mapping (uint256 => uint256) tokenIdIndex;
    mapping (address => uint256) taxStartDay;
    mapping (uint256 => uint256) transferTime;
    
    event Hunted(address indexed _addr, string name, uint256 legionId, uint256 monsterId, uint256 roll, uint256 percent, bool success, uint256 reward);
    event AddedSupply(address indexed _addr, uint256 _tokenId, uint256 _supply, uint256 time);
    constructor() {
        bloodstone = IERC20(0xd8344cc7fEbce19C2182988Ad219cF3553664356);
        feehandler = new FeeHandler();
        rewardpool = new RewardPool(address(feehandler));
        rewardPoolAddr = address(rewardpool);
        beast = new BeastNFT(rewardPoolAddr, address(feehandler));
        warrior = new WarriorNFT(rewardPoolAddr, address(feehandler));
        marketplace = new Marketplace(rewardPoolAddr, address(feehandler), address(beast), address(warrior), address(this));
        monster = new Monster(address(feehandler));
        bloodstone.approve(rewardPoolAddr, 5000000*10**18);
    }

    function supportsInterface(bytes4 interfaceId) external override view returns (bool){}

    function name() public view returns (string memory) {
        return "Crypto Legions Game";
    }
    function symbol() public view returns (string memory) {
        return "LEGION";
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner || isApprovedForAll(owner, msg.sender), "ERC721: approval to current owner");
        require(msg.sender==owner, "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId); // internal owner
    }
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return addressTokenIds[owner].length;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return tokenToOwner[tokenId];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        address owner = ownerOf(tokenId);
        require(msg.sender==owner || getApproved(tokenId)==msg.sender, "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(msg.sender==owner || getApproved(tokenId)==msg.sender, "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");
        if(from!=address(marketplace)&&to!=address(marketplace)) {
            require(checkCoolDownTime(tokenId)==true, "You can not transfer your legion between wallets for at least 20 days after making transfer");
            transferTime[tokenId] = block.timestamp;
        }
        _approve(address(0), tokenId);

        addressTokenIds[from][tokenIdIndex[tokenId]] = addressTokenIds[from][addressTokenIds[from].length-1];
        tokenIdIndex[addressTokenIds[from][addressTokenIds[from].length-1]] = tokenIdIndex[tokenId];
        addressTokenIds[from].pop();
        tokenToOwner[tokenId] = to;
        
        addressTokenIds[to].push(tokenId);
        tokenIdIndex[tokenId] = addressTokenIds[to].length - 1;
        emit Transfer(from, to, tokenId);
    }
    function checkCoolDownTime(uint256 tokenId) internal view returns(bool) {
        return block.timestamp > transferTime[tokenId] + 20 days;
    }

    function mint(string memory name, uint256[] memory beastIds, uint256[] memory warriorIds) external {
        require(bytes(name).length>0, "mint:  you should mint with legion name");
        require(beastIds.length<=maxBeasts, "mint: you should not overflow max beast number");
        require(beastIds.length>0, "mint: you should add beasts");
        uint256 maxCapacity = 0;
        uint256 attack_power = 0;
        uint256 beastCount = beastIds.length;
        uint256 warriorCount = warriorIds.length;
        uint256 bloodstoneAmount = feehandler.getTrainingCost(beastCount+warriorCount);
        require(bloodstone.balanceOf(msg.sender) >= bloodstoneAmount, "Insufficient payment");
        uint256 capacity = 0;
        for(uint i=0; i<beastCount; i++) {
            require(beast.ownerOf(beastIds[i]) == msg.sender, "mint : you should own these beast tokens");
            (,, capacity) = beast.getBeast(beastIds[i]);
            maxCapacity += capacity;
            beast.burn(beastIds[i]);
        }
        require(maxCapacity >= warriorCount, "mint : You can not mint more warriors than max capacity");
        uint256 ap = 0;
        for(uint i=0; i<warriorCount; i++) {
            require(warrior.ownerOf(warriorIds[i]) == msg.sender, "mint : you should own these warrior tokens");
            (,, ap) = warrior.getWarrior(warriorIds[i]);
            attack_power += ap;
            warrior.burn(warriorIds[i]);
        }
        
        addressTokenIds[msg.sender].push(_tokenIds.current());
        tokenIdIndex[_tokenIds.current()] = addressTokenIds[msg.sender].length - 1;
        tokenToOwner[_tokenIds.current()] = msg.sender;

        bloodstone.transferFrom(msg.sender, rewardPoolAddr, bloodstoneAmount);

        tokenData[_tokenIds.current()] = Legion(name, beastIds, warriorIds, 0, attack_power*100, block.timestamp);
        lastHuntTime[_tokenIds.current()] = 0;
        _tokenIds.increment();
    }

    function canHunt(uint256 tokenId) internal view returns (bool) {
        return block.timestamp >= lastHuntTime[tokenId] + 1 days
            && tokenData[tokenId].supplies > 0
            && tokenData[tokenId].attack_power >= 200000;
    }

    function canHuntMonster(uint256 tokenId) external view override returns (uint) {
        if(block.timestamp >= lastHuntTime[tokenId] + 1 days && tokenData[tokenId].supplies > 0 && tokenData[tokenId].attack_power >= 200000) return 1;
        else if (tokenData[tokenId].supplies>0) return 2;
        else return 3;
    }

    function hunt(uint256 tokenId, uint8 monsterId) public {
        require(ownerOf(tokenId)==msg.sender, "Hunt: you should own this token first");
        require(canHunt(tokenId)==true, "Hunt: can not hunt");
        (,uint256 percent, uint256 ap, uint256 reward) = monster.getMonsterInfo(monsterId);
        require(tokenData[tokenId].attack_power>=ap, "This legion should have more strong power to hunt this monster");
        uint256 randnum = genRand(100,tokenId, monsterId);
        bool retval = false;

        if(monsterId<=20) {
            uint256 bonusPercent = ((tokenData[tokenId].attack_power-ap)/2000)/100;
            if(percent+bonusPercent>89) percent = 89;
            else percent = percent+bonusPercent;
        }

        if(randnum<=percent) {
            if(rewardpool.getUnclaimedBLST(msg.sender)==0) taxStartDay[msg.sender] = block.timestamp-(block.timestamp % 1 days);
            rewardpool.addReward(msg.sender, monsterId, reward);
            retval = true;
        }
        lastHuntTime[tokenId] = block.timestamp;
        tokenData[tokenId].supplies--;
        totalHuntedCount++;
        monsterHuntCount[monsterId]++;
        decreaseAttackPower(tokenId);
        emit Hunted(msg.sender, tokenData[tokenId].name, tokenId, monsterId, randnum, percent, retval, feehandler.getBLSTReward(reward));
    }

    function massHunt() public {
        for(uint i=0;i<addressTokenIds[msg.sender].length;i++) {
            if(canHunt(addressTokenIds[msg.sender][i])) hunt(addressTokenIds[msg.sender][i], monster.getMonsterToHunt(tokenData[addressTokenIds[msg.sender][i]].attack_power));
        }
    }

    function decreaseAttackPower(uint256 _tokenId) internal {
        uint damamgePercent = feehandler.getFee(2);
        tokenData[_tokenId].attack_power = tokenData[_tokenId].attack_power- (tokenData[_tokenId].attack_power*damamgePercent/10000);
    }

    function claimReward() external {
        require(rewardpool.getUnclaimedBLST(msg.sender)>0, "You don't have any uncliamed reward");
        rewardpool.claimReward(msg.sender, taxStartDay[msg.sender]);
        taxStartDay[msg.sender] = 0;
    }

    function getTaxLeftDays(address _address) external view returns (uint) {
        if(taxStartDay[_address]==0) return 0;
        uint diffDays = (block.timestamp - taxStartDay[_address]) / 1 days;
        if(diffDays*2>=40) return 0;
        else return (40 - diffDays*2) / 2;
    }

    function genRand(uint256 maxNum, uint256 tokenId, uint256 monterId) private view returns (uint256) {
        return uint256(uint256(keccak256(abi.encode(block.timestamp, block.difficulty, block.number, tokenId, monterId))) % maxNum);
    }

    function getLegion(uint256 tokenId) external view override
        returns(string memory, uint256[] memory, uint256[] memory, uint256, uint256, uint256) {
        return (
            tokenData[tokenId].name,
            tokenData[tokenId].beast_ids,
            tokenData[tokenId].warrior_ids,
            tokenData[tokenId].supplies,
            tokenData[tokenId].attack_power,
            lastHuntTime[tokenId]
        );
    }

    function updateLegion(uint256 tokenId, uint256[] memory beastIds, uint256[] memory warriorIds) external {
        if(beastIds.length>0) {
            addBeasts(tokenId, beastIds);
        }
        if(warriorIds.length>0) {
            addWarriors(tokenId, warriorIds);
        }
    }

    function addBeasts(uint256 tokenId, uint256[] memory beastIds) internal {
        require(ownerOf(tokenId)==msg.sender, "You should own this legion");
        uint256 beastCount = beastIds.length;
        require(beastCount > 0, "Please add beast ids");
        uint beastLength = tokenData[tokenId].beast_ids.length;
        require(beastLength+beastIds.length<=maxBeasts, "You could not overflow the max beasts number");
        for(uint i=0; i<beastCount; i++) {
            require(beast.ownerOf(beastIds[i]) == msg.sender, "You should own these beasts");
            tokenData[tokenId].beast_ids.push(beastIds[i]);
            beast.burn(beastIds[i]);
        }
        uint256 bloodstoneAmount = feehandler.getTrainingCost(beastCount);
        require(bloodstone.balanceOf(msg.sender)>=bloodstoneAmount, "Insufficient balance");
        bloodstone.transferFrom(msg.sender, rewardPoolAddr, bloodstoneAmount);
    }
    function addWarriors(uint256 tokenId, uint256[] memory warriorIds) internal {
        require(ownerOf(tokenId)==msg.sender, "You should own this legion");
        uint256 warriorCount = warriorIds.length;
        uint256 maxCapacity = getCapacityOfLegion(tokenId);
        require(warriorCount > 0, "Please add warrior ids");
        require(maxCapacity>=tokenData[tokenId].warrior_ids.length+warriorIds.length, "Warrior count should not exceed the max capacity");
        uint256 ap = 0;
        for(uint i=0; i<warriorCount; i++) {
            require(warrior.ownerOf(warriorIds[i]) == msg.sender, "You should own these warriors");
            (,, ap) = warrior.getWarrior(warriorIds[i]);
            tokenData[tokenId].warrior_ids.push(warriorIds[i]);
            tokenData[tokenId].attack_power += ap*100;
            warrior.burn(warriorIds[i]);
        }
        uint256 bloodstoneAmount = feehandler.getCostForAddingWarrior(warriorCount, tokenData[tokenId].supplies);
        require(bloodstone.balanceOf(msg.sender) >= bloodstoneAmount, "Insufficient balance");
        bloodstone.transferFrom(msg.sender, rewardPoolAddr, bloodstoneAmount);
    }
    function addSupply(uint256 tokenId, uint256 supply, bool fromWallet) external {
        require(ownerOf(tokenId)==msg.sender, "You should own this legion");
        uint256 warriorCount = tokenData[tokenId].warrior_ids.length;
        if(!fromWallet) {
            rewardpool.subReward(msg.sender, feehandler.getSupplyCostInUSD(warriorCount, supply));
        } else {
            uint256 bloodstoneAmount = feehandler.getSupplyCost(warriorCount, supply);
            require(bloodstone.balanceOf(msg.sender)>=bloodstoneAmount, "Insufficient balance");
            bloodstone.transferFrom(msg.sender, rewardPoolAddr, bloodstoneAmount);
        }
        tokenData[tokenId].supplies += supply;
        emit AddedSupply(msg.sender, tokenId, supply, block.timestamp);
    }

    function execute(uint256 _tokenId, bool isbeast) public {
        uint256 executeAmount = feehandler.getExecuteAmount();
        if(isbeast) {
            require(beast.ownerOf(_tokenId)==msg.sender, "Execute : you should own this beast");
            rewardpool.returnTokenToPlayer(msg.sender, executeAmount);
            beast.burn(_tokenId);
        } else {
            require(warrior.ownerOf(_tokenId)==msg.sender, "Execute : you should own this warrior");
            rewardpool.returnTokenToPlayer(msg.sender, executeAmount);
            warrior.burn(_tokenId);
        }
    }

    function getTokenIds(address _address) public view returns (uint256[] memory) {
        return addressTokenIds[_address];
    }

    function getAvailableLegionsCount(address _address) public view returns (uint) {
        uint ret = 0;
        for(uint i=0; i<addressTokenIds[_address].length; i++) {
            if(canHunt(addressTokenIds[_address][i])) ret++;
        }
        return ret;
    }

    function getMaxAttackPower(address _address) public view returns(uint256) {
        uint256 ret = 0;
        for(uint i=0; i<addressTokenIds[_address].length; i++) {
            if(tokenData[addressTokenIds[_address][i]].attack_power>ret) ret = tokenData[addressTokenIds[_address][i]].attack_power;
        }
        return ret;
    }

    function getCapacityOfLegion(uint256 tokenId) public view returns(uint256) {
        uint256 maxCapacity = 0;
        uint256 capacity = 0;
        for(uint i=0; i<tokenData[tokenId].beast_ids.length; i++) {
            (,, capacity) = beast.getBeast(tokenData[tokenId].beast_ids[i]);
            maxCapacity += capacity;
        }
        return maxCapacity;
    }

    function setMaxBeastNumber(uint256 _maxNum) external onlyOwner {
        maxBeasts = _maxNum;
    }

    function setFee(uint _fee, uint8 _index) external onlyOwner {
        feehandler.setFee(_fee, _index);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
pragma solidity ^0.8.0;

interface IFeeHandler {
    function getFee(uint8 _index) external view returns(uint);
    function setFee(uint _fee, uint8 _index) external;
    function getSummoningPrice(uint256 _amount) external view returns(uint256);
    function getTrainingCost(uint256 _count) external view returns(uint256);
    function getBLSTAmountFromUSD(uint256 _usd) external view returns(uint256);
    function getSupplyCost(uint256 _warriorCount, uint256 _supply) external view returns(uint256);
    function getSupplyCostInUSD(uint256 _warriorCount, uint256 _supply) external view returns(uint256);
    function getCostForAddingWarrior(uint256 _warriorCount, uint256 _remainingHunts) external view returns(uint256);
    function getBLSTReward(uint256 _reward) external view returns(uint256);
    function getExecuteAmount() external view returns(uint256);
    function getUSDAmountInBLST(uint256 _blst) external view returns(uint256);
    function getUSDAmountFromBLST(uint256 _blst) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ILegionNFT is IERC721 {
    function getLegion(uint256 tokenId) external view returns(string memory, uint256[] memory, uint256[] memory, uint256, uint256, uint256);
    function canHuntMonster(uint256 tokenId) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardPool {
    function returnTokenToPlayer(address _address, uint256 _amount) external;
    function addReward(address _winner, uint256 _monster_id, uint256 _reward) external;
    function subReward(address _address, uint256 _reward) external;
    function getUnclaimedBLST(address _address) external view returns(uint256);
    function claimReward(address _address, uint256 taxStartDay) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFeeHandler.sol";

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external pure returns(uint256[] memory);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external pure returns(uint256[] memory);
}

contract FeeHandler is IFeeHandler, Ownable {
    /*
        Marketplace tax,
        Hunting tax,
        Damage for legions,
        Summon fee,
        14 Days Hunting Supplies Discounted Fee,
        28 Days Hunting Supplies Discounted Fee
    */
    address constant BUSD = 0x07de306FF27a2B630B1141956844eB1552B956B5;
    address constant BLST = 0xd8344cc7fEbce19C2182988Ad219cF3553664356;
    uint[6] fees = [1500,250,100,18,13,24];
    IDEXRouter public router;
    
    constructor() {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }
    function getFee(uint8 _index) external view override returns (uint) {
        return fees[_index];
    }
    function setFee(uint _fee, uint8 _index) external override onlyOwner {
        require(_index>=0 && _index<6, "Unknown fee type");
        fees[_index] = _fee;
    }

    function getSummoningPrice(uint256 _amount) external view override returns(uint256) {
        uint256 UsdValue = fees[3];
        uint256 amountIn;
        if(_amount==1) {
            amountIn = UsdValue*10**6;
        } else if(_amount==10) {
            amountIn = UsdValue*10*99*10**4;
        } else if(_amount==50) {
            amountIn = UsdValue*50*98*10**4;
        } else if(_amount==100) {
            amountIn = UsdValue*100*97*10**4;
        } else if(_amount==150) {
            amountIn = UsdValue*150*95*10**4;
        } else {
            amountIn = UsdValue*_amount*10**6;
        }
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut(amountIn, path)[1];
    }
    function getTrainingCost(uint256 _count) external view override returns(uint256) {
        if(_count==0) return 0;
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut(_count*(10**6)/2, path)[1];
    }
    function getSupplyCost(uint256 _warriorCount, uint256 _supply) external view override returns(uint256) {
        if(_supply==0) return 0;
        if(_supply==7) {
            return getBLSTAmount(7*_warriorCount);
        } else if(_supply==14) {
            return getBLSTAmount(fees[4]*_warriorCount);
        } else if (_supply==28) {
            return getBLSTAmount(fees[5]*_warriorCount);
        } else {
            return getBLSTAmount(_supply*_warriorCount);
        }
    }

    function getSupplyCostInUSD(uint256 _warriorCount, uint256 _supply) external view override returns(uint256) {
        if(_supply==7) {
            return 7*_warriorCount*10000;
        } else if(_supply==14) {
            return fees[4]*_warriorCount*10000;
        } else if (_supply==28) {
            return fees[5]*_warriorCount*10000;
        } else {
            return _supply*_warriorCount*10000;
        }
    }

    function getCostForAddingWarrior(uint256 _warriorCount, uint256 _remainingHunts) external view override returns(uint256) {
        if(_warriorCount==0) return 0;
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut((_remainingHunts*_warriorCount)*10**6+_warriorCount*10**6/2, path)[1];
    }
    function getBLSTAmountFromUSD(uint256 _usd) external view override returns(uint256) {
        return getBLSTAmount(_usd);
    }
    function getUSDAmountInBLST(uint256 _blst) external view override returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = BLST;
        path[1] = BUSD;
        return router.getAmountsOut(_blst, path)[1];
    }
    function getBLSTAmount(uint256 _usd) internal view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut(_usd*10**6, path)[1];
    }
    function getUSDAmountFromBLST(uint256 _blst) external view override returns(uint256) {
        if(_blst==0) return 0;
        address[] memory path = new address[](2);
        path[0] = BLST;
        path[1] = BUSD;
        return router.getAmountsOut(_blst, path)[1];
    }
    function getBLSTReward(uint256 _reward) external view override returns(uint256) {
        if(_reward==0) return 0;
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut(_reward*10**2, path)[1];
    }
    function getExecuteAmount() external view override returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut(fees[3]*10**6*2/10, path)[1]; // 20% will return back to player
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRewardPool.sol";
import "./interfaces/IFeeHandler.sol";

contract RewardPool is IRewardPool, Ownable {
    IERC20 private bloodstone;
    IFeeHandler private feehandler;
    mapping (address => uint256) public unclaimedUSD;

    event RewardClaimed(address indexed _address, uint256 amount);
    event RewardChanged(address indexed _address, uint256 amount);

    constructor (address _feehandler) {
        feehandler = IFeeHandler(_feehandler);
        bloodstone = IERC20(0xd8344cc7fEbce19C2182988Ad219cF3553664356);
    }

    function getUnclaimedBLST(address _address) external view override returns(uint256) {
        if(unclaimedUSD[_address]==0) return 0;
        return feehandler.getBLSTReward(unclaimedUSD[_address]);
    }

    function claimReward(address _address, uint256 taxStartDay) external override onlyOwner {
        uint diffDays = (block.timestamp - taxStartDay) / 1 days;
        if(diffDays>20) {
            diffDays = 20;
        }
        uint amountToClaim = (100-2*(20-diffDays))*feehandler.getBLSTReward(unclaimedUSD[_address])/100;
        bloodstone.transfer(_address, amountToClaim);
        unclaimedUSD[_address] = 0;
        emit RewardClaimed(_address, amountToClaim);
    }

    function addReward(address _winner, uint256 _monster_id, uint256 _reward) external override onlyOwner {
        uint256 huntingTax = feehandler.getFee(1);
        uint256 realReward = _reward*(10000-huntingTax)/10000;
        unclaimedUSD[_winner] += realReward;
        emit RewardChanged(_winner, unclaimedUSD[_winner]);
    }

    function subReward(address _address, uint256 _reward) external override onlyOwner {
        unclaimedUSD[_address] -= _reward;
        emit RewardChanged(_address, unclaimedUSD[_address]);
    }

    function returnTokenToPlayer(address _address, uint256 _amount) external override onlyOwner {
        require(bloodstone.balanceOf(address(this))>_amount, "returnTokenToPlayer : Insufficient Funds");
        bloodstone.transfer(_address, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IFeeHandler.sol";
import "./interfaces/IBeastNFT.sol";

contract BeastNFT is Context, IBeastNFT, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    IERC20 public bloodstone;
    IFeeHandler feehandler;
    address public rewardpool;
    string[] public names = ["Centaur", "Barghest", "Pegasus", "Griffin", "Dragon", "Phoenix"];
    uint256[] public capacities = [1,2,3,4,5,20];
    mapping (uint256 => uint256) private tokenData;
    mapping (address => uint256[]) private addressTokenIds;

    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    mapping (uint256 => address) tokenToOwner;
    mapping (uint256 => uint256) tokenIdIndex;

    event Minted(address indexed _addr, uint256 count, uint256 time);

    constructor(address _rewardpool, address _feehandler) {
        bloodstone = IERC20(0xd8344cc7fEbce19C2182988Ad219cF3553664356);
        feehandler = IFeeHandler(_feehandler);
        rewardpool = _rewardpool;
        bloodstone.approve(address(rewardpool), 5000000*10**18);
    }
    function supportsInterface(bytes4 interfaceId) external override view returns (bool){}
    function name() public view returns (string memory) {
        return "Crypto Legions Beast";
    }
    function symbol() public view returns (string memory) {
        return "BEAST";
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner || isApprovedForAll(owner, msg.sender), "ERC721: approval to current owner");
        require(msg.sender==owner, "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId); // internal owner
    }
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return addressTokenIds[owner].length;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return tokenToOwner[tokenId];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        address owner = ownerOf(tokenId);
        require(msg.sender==owner || getApproved(tokenId)==msg.sender, "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(msg.sender==owner || getApproved(tokenId)==msg.sender, "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        _approve(address(0), tokenId);

        addressTokenIds[from][tokenIdIndex[tokenId]] = addressTokenIds[from][addressTokenIds[from].length-1];
        tokenIdIndex[addressTokenIds[from][addressTokenIds[from].length-1]] = tokenIdIndex[tokenId];
        addressTokenIds[from].pop();
        tokenToOwner[tokenId] = to;
        
        addressTokenIds[to].push(tokenId);
        tokenIdIndex[tokenId] = addressTokenIds[to].length - 1;
        emit Transfer(from, to, tokenId);
    }

    function burn(uint256 tokenId) external override onlyOwner{
        address owner = ownerOf(tokenId);
        _transfer(owner, address(0), tokenId);
    }

    function mint(uint256 amount) external {
        uint256 bloodstoneAmount = feehandler.getSummoningPrice(amount);
        require(bloodstone.balanceOf(msg.sender) >= bloodstoneAmount, "Insufficient payment");
        bloodstone.transferFrom(msg.sender, rewardpool, bloodstoneAmount);
        uint256 randNum = 0;
        for(uint i=0; i<amount; i++) {
            addressTokenIds[msg.sender].push(_tokenIds.current());
            tokenIdIndex[_tokenIds.current()] = addressTokenIds[msg.sender].length - 1;
            tokenToOwner[_tokenIds.current()] = msg.sender;
            randNum = genRand(1000, i);
            if (randNum==0&&randNum<4) {
                tokenData[_tokenIds.current()] = 6;
            } else if (randNum>=4&&randNum<14) {
                tokenData[_tokenIds.current()] = 5;
            } else if (randNum>=14&&randNum<94) {
                tokenData[_tokenIds.current()] = 4;
            } else if (randNum>=94&&randNum<274) {
                tokenData[_tokenIds.current()] = 3;
            } else if (randNum>=274&&randNum<574) {
                tokenData[_tokenIds.current()] = 2;
            } else {
                tokenData[_tokenIds.current()] = 1;
            }
            _tokenIds.increment();
        }
        emit Minted(msg.sender, amount, block.timestamp);
    }

    function genRand(uint256 maxNum, uint256 i) private view returns (uint256) {
        return uint256(uint256(keccak256(abi.encode(block.timestamp, block.difficulty, i))) % maxNum);
    }

    function getTokenIds(address _address) external view returns (uint256[] memory) {
        return addressTokenIds[_address];
    }

    function getBeast(uint256 tokenId) external view virtual override returns(string memory, uint256, uint256) {
        return (names[tokenData[tokenId]-1], tokenData[tokenId], capacities[tokenData[tokenId]-1]);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IRewardPool.sol";
import "./interfaces/IFeeHandler.sol";
import "./interfaces/IWarriorNFT.sol";


contract WarriorNFT is Context, IWarriorNFT, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    IERC20 public bloodstone;
    IRewardPool public rewardPool;
    address public rewardPoolAddr;
    IFeeHandler public feehandler;

    struct Warrior {
        uint256 strength;
        uint256 attack_power;
    }
    string[] public names = ["Hobbit", "Gnome", "Satyr", "Dwarf", "Minotaur", "Dragon"];
    mapping (uint256 => Warrior) private tokenData;
    mapping (address => uint256[]) private addressTokenIds;

    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    mapping (uint256 => address) private tokenToOwner;
    mapping (uint256 => uint256) private tokenIdIndex;

    event Minted(address indexed _addr, uint256 count, uint256 time);

    constructor(address _rewardpool, address _feehandler) {
        bloodstone = IERC20(0xd8344cc7fEbce19C2182988Ad219cF3553664356);
        feehandler = IFeeHandler(_feehandler);
        rewardPoolAddr = _rewardpool;
        rewardPool = IRewardPool(rewardPoolAddr);
        bloodstone.approve(rewardPoolAddr, 5000000*10**18);
    }

    function supportsInterface(bytes4 interfaceId) external override view returns (bool){}

    function name() public view returns (string memory) {
        return "Crypto Legions Warrior";
    }
    function symbol() public view returns (string memory) {
        return "WARRIOR";
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner || isApprovedForAll(owner, msg.sender), "ERC721: approval to current owner");
        require(msg.sender==owner, "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId); // internal owner
    }
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return addressTokenIds[owner].length;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return tokenToOwner[tokenId];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        address owner = ownerOf(tokenId);
        require(msg.sender==owner || getApproved(tokenId)==msg.sender, "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(msg.sender==owner || getApproved(tokenId)==msg.sender, "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        _approve(address(0), tokenId);

        addressTokenIds[from][tokenIdIndex[tokenId]] = addressTokenIds[from][addressTokenIds[from].length-1];
        tokenIdIndex[addressTokenIds[from][addressTokenIds[from].length-1]] = tokenIdIndex[tokenId];
        addressTokenIds[from].pop();
        tokenToOwner[tokenId] = to;
        
        addressTokenIds[to].push(tokenId);
        tokenIdIndex[tokenId] = addressTokenIds[to].length - 1;
        emit Transfer(from, to, tokenId);
    }

    function burn(uint256 tokenId) external override onlyOwner{
        address owner = ownerOf(tokenId);
        _transfer(owner, address(0), tokenId);
    }

    function mint(uint256 amount) external {
        uint256 bloodstoneAmount = feehandler.getSummoningPrice(amount);
        require(bloodstone.balanceOf(msg.sender) >= bloodstoneAmount, "Insufficient payment");
        bloodstone.transferFrom(msg.sender, address(rewardPoolAddr), bloodstoneAmount);
        uint256 randNum;
        Warrior memory warrior;
        for(uint i=0; i<amount; i++) {
            addressTokenIds[msg.sender].push(_tokenIds.current());
            tokenIdIndex[_tokenIds.current()] = addressTokenIds[msg.sender].length - 1;
            tokenToOwner[_tokenIds.current()] = msg.sender;
            randNum = genRand(1000, i);
            if (randNum==0&&randNum<2) {
                warrior = Warrior(6, 50000+genRand(10001, randNum));
            } else if (randNum>=2&&randNum<12) {
                warrior = Warrior(5, 4000+genRand(2001, randNum));
            } else if (randNum>=12&&randNum<82) {
                warrior = Warrior(4, 3000+genRand(1001, randNum));
            } else if (randNum>=82&&randNum<222) {
                warrior = Warrior(3, 2000+genRand(1001, randNum));
            } else if (randNum>=222&&randNum<502) {
                warrior = Warrior(2, 1000+genRand(1001, randNum));
            } else {
                warrior = Warrior(1, 500+genRand(501, randNum));
            }
            tokenData[_tokenIds.current()] = warrior;
            _tokenIds.increment();
        }
        emit Minted(msg.sender, amount, block.timestamp);
    }

    function genRand(uint256 maxNum, uint256 i) private view returns (uint256) {
        return uint256(uint256(keccak256(abi.encode(block.timestamp, block.difficulty, i))) % maxNum);
    }

    function getTokenIds(address _address) external view returns (uint256[] memory) {
        return addressTokenIds[_address];
    }

    function getWarrior(uint256 tokenId) external override view returns(string memory, uint256, uint256) {
        return (
            names[tokenData[tokenId].strength-1],
            tokenData[tokenId].strength,
            tokenData[tokenId].attack_power
        );
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IMonster.sol";
import "./interfaces/IFeeHandler.sol";

contract Monster is IMonster {
    struct Monster {
        string name;
        uint256 percent;
        uint256 attack_power;
        uint256 reward;
    }
    mapping (uint8 => Monster) private monsterData;
    IFeeHandler public feehandler;
    constructor (address _feehandler) {
        feehandler = IFeeHandler(_feehandler);
        initiateMonsterData();
    }

    function initiateMonsterData() internal {
        monsterData[1].name = "bat";
        monsterData[1].percent = 85;
        monsterData[1].attack_power = 200000;
        monsterData[1].reward = 65000;
        monsterData[2].name = "wereshark";
        monsterData[2].percent = 82;
        monsterData[2].attack_power = 500000;
        monsterData[2].reward = 160000;
        monsterData[3].name = "rhinark";
        monsterData[3].percent = 78;
        monsterData[3].attack_power = 800000;
        monsterData[3].reward = 260000;
        monsterData[4].name = "lacodon";
        monsterData[4].percent = 75;
        monsterData[4].attack_power = 1000000;
        monsterData[4].reward = 325000;
        monsterData[5].name = "oliphant";
        monsterData[5].percent = 72;
        monsterData[5].attack_power = 1300000;
        monsterData[5].reward = 440000;
        monsterData[6].name = "ogre";
        monsterData[6].percent = 68;
        monsterData[6].attack_power = 1700000;
        monsterData[6].reward = 605000;
        monsterData[7].name = "werewolf";
        monsterData[7].percent = 65;
        monsterData[7].attack_power = 2000000;
        monsterData[7].reward = 740000;
        monsterData[8].name = "orc";
        monsterData[8].percent = 62;
        monsterData[8].attack_power = 2200000;
        monsterData[8].reward = 850000;
        monsterData[9].name = "cyclops";
        monsterData[9].percent = 59;
        monsterData[9].attack_power = 2500000;
        monsterData[9].reward = 1010000;
        monsterData[10].name = "gargoyle";
        monsterData[10].percent = 55;
        monsterData[10].attack_power = 2800000;
        monsterData[10].reward = 1210000;
        monsterData[11].name = "golem";
        monsterData[11].percent = 52;
        monsterData[11].attack_power = 3100000;
        monsterData[11].reward = 1410000;
        monsterData[12].name = "land dragon";
        monsterData[12].percent = 49;
        monsterData[12].attack_power = 3400000;
        monsterData[12].reward = 1620000;
        monsterData[13].name = "chimera";
        monsterData[13].percent = 45;
        monsterData[13].attack_power = 3700000;
        monsterData[13].reward = 1900000;
        monsterData[14].name = "earthworm";
        monsterData[14].percent = 42;
        monsterData[14].attack_power = 4000000;
        monsterData[14].reward = 2150000;
        monsterData[15].name = "hydra";
        monsterData[15].percent = 41;
        monsterData[15].attack_power = 4200000;
        monsterData[15].reward = 2450000;
        monsterData[16].name = "rancor";
        monsterData[16].percent = 41;
        monsterData[16].attack_power = 4700000;
        monsterData[16].reward = 2950000;
        monsterData[17].name = "cerberus";
        monsterData[17].percent = 41;
        monsterData[17].attack_power = 5000000;
        monsterData[17].reward = 3250000;
        monsterData[18].name = "titan";
        monsterData[18].percent = 39;
        monsterData[18].attack_power = 5300000;
        monsterData[18].reward = 3800000;
        monsterData[19].name = "forest dragon";
        monsterData[19].percent = 39;
        monsterData[19].attack_power = 5600000;
        monsterData[19].reward = 4300000;
        monsterData[20].name = "ice dragon";
        monsterData[20].percent = 39;
        monsterData[20].attack_power = 6000000;
        monsterData[20].reward = 4900000;
        monsterData[21].name = "undead dragon";
        monsterData[21].percent = 37;
        monsterData[21].attack_power = 15000000;
        monsterData[21].reward = 12850000;
        monsterData[22].name = "volcano dragon";
        monsterData[22].percent = 35;
        monsterData[22].attack_power = 25000000;
        monsterData[22].reward = 23000000;
        monsterData[23].name = "fire demon";
        monsterData[23].percent = 30;
        monsterData[23].attack_power = 30000000;
        monsterData[23].reward = 33000000;
        monsterData[24].name = "invisible";
        monsterData[24].percent = 15;
        monsterData[24].attack_power = 50000000;
        monsterData[24].reward = 150000000;
    }
    
    function getMonsterInfo(uint8 monsterId) external override view returns(string memory, uint256, uint256, uint256) {
        require(monsterId>0&&monsterId<25, "Monster is not registered");
        return (monsterData[monsterId].name, monsterData[monsterId].percent, monsterData[monsterId].attack_power, monsterData[monsterId].reward);
    }

    function getAllMonsters() public view returns (Monster[] memory, uint256[] memory){
        Monster[] memory monsters = new Monster[](24);
        uint256[] memory rewards = new uint256[](24);
        for (uint8 i = 0; i < 24; i++) {
            Monster storage monster = monsterData[i+1];
            monsters[i] = monster;
            rewards[i] = feehandler.getBLSTReward(monsterData[i+1].reward);
        }
        return (monsters, rewards);
    }

    function getMonsterToHunt(uint256 ap) external override view returns(uint8) {
        for(uint8 i=1;i<25;i++) {
            if(ap<monsterData[i].attack_power) return i-1;
        }
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BeastNFT.sol";
import "./WarriorNFT.sol";
import "./interfaces/IFeeHandler.sol";
import "./interfaces/ILegionNFT.sol";

contract Marketplace {
    address public rewardpool;
    IBeastNFT public beast;
    IWarriorNFT public warrior;
    IERC20 private bloodstone;
    ILegionNFT public legion;
    IFeeHandler private feehandler;
    struct MarketItem {
        address seller;
        uint256 price;
    }
    mapping(uint8 => mapping (uint256 => MarketItem)) private items;

    event CancelSelling(uint8 _itemType, uint256 _tokenId);
    event SellToken(uint8 _itemType, uint256 _tokenId);
    event BuyToken(uint8 _itemType, uint256 _tokenId);
    event PriceUpdated(uint8 _itemType, uint256 _tokenId, uint256 _price);

    constructor (address _rewardpool, address _feehandler, address _beast, address _warrior, address _legion) {
        legion = ILegionNFT(_legion);
        rewardpool = _rewardpool;
        feehandler = IFeeHandler(_feehandler);
        bloodstone = IERC20(0xd8344cc7fEbce19C2182988Ad219cF3553664356);
        beast = IBeastNFT(_beast);
        warrior = IWarriorNFT(_warrior);
    }

    function buyToken(uint8 _itemType, uint256 _tokenId, uint256 _price) external {
        require(bloodstone.balanceOf(msg.sender)>=items[_itemType][_tokenId].price, "Insufficent balance");
        require(_price==items[_itemType][_tokenId].price, "Can not buy in this price");
        uint256 amountToRewardpool = items[_itemType][_tokenId].price*feehandler.getFee(0)/10000;
        uint256 amountToSeller = items[_itemType][_tokenId].price-amountToRewardpool;
        bloodstone.transferFrom(msg.sender, rewardpool, amountToRewardpool);
        bloodstone.transferFrom(msg.sender, items[_itemType][_tokenId].seller, amountToSeller);
        if(_itemType==1) {
            beast.transferFrom(address(this), msg.sender, _tokenId);
        } else if(_itemType==2) {
            warrior.transferFrom(address(this), msg.sender, _tokenId);
        } else {
            legion.transferFrom(address(this), msg.sender, _tokenId);
        }
        emit BuyToken(_itemType, _tokenId);
    }
    
    function sellToken(uint8 _itemType, uint256 _tokenId, uint256 _price) external {
        require(_price<5000000*10**18, "Price can not exceed the BLST total supply");
        if(_itemType==1) {
            require(beast.ownerOf(_tokenId)==msg.sender, "This is not your NFT");
            beast.transferFrom(msg.sender, address(this), _tokenId);
        } else if(_itemType==2) {
            require(warrior.ownerOf(_tokenId)==msg.sender, "This is not your NFT");
            warrior.transferFrom(msg.sender, address(this), _tokenId);
        } else {
            require(legion.ownerOf(_tokenId)==msg.sender, "This is not your NFT");
            require(legion.canHuntMonster(_tokenId)!=2, "This Legion can not be sold");
            (,,,,uint256 ap,) = legion.getLegion(_tokenId);
            require(ap>=200000, "The legion with an attack power under 2000 can not be sold");
            legion.transferFrom(msg.sender, address(this), _tokenId);
        }
        items[_itemType][_tokenId] = MarketItem(msg.sender, _price);
        emit SellToken(_itemType, _tokenId);
    }

    function updatePrice(uint8 _itemType, uint256 _tokenId, uint256 _price) external {
        require(_price<5000000*10**18, "Price can not exceed the BLST total supply");
        require(items[_itemType][_tokenId].seller==msg.sender, "You didn't own this nft on Market");
        items[_itemType][_tokenId].price = _price;
        emit PriceUpdated(_itemType, _tokenId, _price);
    }

    function cancelSelling(uint8 _itemType, uint256 _tokenId) external {
        require(items[_itemType][_tokenId].seller==msg.sender, "You didn't own this nft on Market");
        if(_itemType==1) {
            beast.transferFrom(address(this), msg.sender, _tokenId);
        } else if(_itemType==2) {
            warrior.transferFrom(address(this), msg.sender, _tokenId);
        } else {
            legion.transferFrom(address(this), msg.sender, _tokenId);
        }
        emit CancelSelling(_itemType, _tokenId);
    }

    function getMarketItem(uint8 _itemType, uint256 _tokenId) external view returns(uint256, address) {
        return (items[_itemType][_tokenId].price, items[_itemType][_tokenId].seller);
    }
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
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBeastNFT is IERC721 {
    function getBeast(uint256 tokenId) external  view returns(string memory, uint256, uint256);
    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IWarriorNFT is IERC721 {
    function getWarrior(uint256 tokenId) external view returns(string memory, uint256, uint256);
    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMonster {
    function getMonsterInfo(uint8 monsterId) external view returns(string memory, uint256, uint256, uint256);
    function getMonsterToHunt(uint256 ap) external view returns(uint8);
}