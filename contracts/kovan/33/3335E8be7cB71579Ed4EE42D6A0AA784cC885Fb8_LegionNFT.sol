// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./IFeeHandler.sol";
import "./ILegionNFT.sol";
import "./FeeHandler.sol";
import "./IRewardPool.sol";
import "./RewardPool.sol";
import "./BeastNFT.sol";
import "./WarriorNFT.sol";
import "./Monster.sol";
import "./Marketplace.sol";

contract LegionNFT is Context, ILegionNFT, Ownable {
    using SafeMath for uint256;
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
    uint256 public supplyPrice = 1;

    uint256 maxBeasts = 10;
    uint256 public itemPrice = 50;
    uint256 public denominator = 100;


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
    
    event Hunted(uint256 roll, bool success);

    constructor() {
        bloodstone = IERC20(0x8Cc6529d211eAf6936d003B521C61869131661DA);
        feehandler = new FeeHandler();
        rewardpool = new RewardPool();
        rewardPoolAddr = address(rewardpool);
        beast = new BeastNFT(rewardPoolAddr, address(feehandler));
        warrior = new WarriorNFT(rewardPoolAddr, address(feehandler));
        marketplace = new Marketplace(rewardPoolAddr, address(feehandler), address(beast), address(warrior), address(this));
        monster = new Monster(rewardPoolAddr);
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
        _approve(address(0), tokenId);

        addressTokenIds[from][tokenIdIndex[tokenId]] = addressTokenIds[from][addressTokenIds[from].length-1];
        tokenIdIndex[addressTokenIds[from][addressTokenIds[from].length-1]] = tokenIdIndex[tokenId];
        addressTokenIds[from].pop();
        tokenToOwner[tokenId] = to;
        
        addressTokenIds[to].push(tokenId);
        tokenIdIndex[tokenId] = addressTokenIds[to].length - 1;
        emit Transfer(from, to, tokenId);
    }

    function mint(string memory name, uint256[] memory beastIds, uint256[] memory warriorIds) external {
        require(bytes(name).length>0, "mint:  you should mint with legion name");
        require(beastIds.length<=maxBeasts, "mint: you should not overflow max beast number");
        require(beastIds.length>0, "mint: you should add beasts");
        uint256 maxCapacity = 0;
        uint256 attack_power = 0;
        uint256 beastCount = beastIds.length;
        uint256 warriorCount = warriorIds.length;
        uint256 bloodstoneAmount = itemPrice.mul(warriorCount+beastCount).mul(10**18).div(denominator);
        require(bloodstone.balanceOf(msg.sender) >= bloodstoneAmount, "Insufficient payment");
        uint256 capacity = 0;
        for(uint i=0; i<beastCount; i++) {
            require(beast.ownerOf(beastIds[i]) == msg.sender, "mint : you should own these beast tokens");
            (,, capacity) = beast.getBeast(beastIds[i]);
            maxCapacity = maxCapacity.add(capacity);
            beast.burn(beastIds[i]);
        }
        require(maxCapacity >= warriorCount, "mint : You can not mint more warriors than max capacity");
        uint256 ap = 0;
        for(uint i=0; i<warriorCount; i++) {
            require(warrior.ownerOf(warriorIds[i]) == msg.sender, "mint : you should own these warrior tokens");
            (,, ap) = warrior.getWarrior(warriorIds[i]);
            attack_power = attack_power.add(ap);
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

    function getImage(uint256 ap) external view returns (string memory, string memory) {
        if(ap<=1500000) return ("QmV9wCwsTZXdRd3dkGUKGdwdmg59F5EqUunbVG8M8WeLVh", "QmeDrSV3B73rF6sNyyHdkeFEpsPLEfKAuv88YTC8MAgs4x");
        else if(ap>1500000 && ap<=3000000) return ("QmfVVYRwuiNNZQNgEgtS4jXfTAK8KZNErqSbzenZ68Js1j", "QmYKJVq6Zcna3uSbbKK6G8SVExZq8A9mdmUXMDfLpbA37w");
        else if(ap>3000000 && ap<=4500000) return ("Qma9cSKs7hJGEN1hxoH3JLKecegiyaJU8mbze3hcvnYpaq", "QmUchiwKL8SXGUC7NWafW8fKLc7XHMT6hfj7ciTzujtBnH");
        else if(ap>4500000 && ap<=6000000) return ("QmWd7VDzTeyPYLDexyMJYbz65VenmH2qyzobGiACHdcXGe", "Qma8yFuyGeYmjsZryF49rkBqomSo9oSt6d8nXxXSw5g4Uo");
        else if(ap>6000000 && ap<=25000000) return ("QmdnZYpBhNuxjieUZrnR14weZtiXRdz75SRAfhEAkissMm", "QmPrMs6xbuXVmbFiqMudxHyBCjS95GRwFJAq2p13KwSQEX");
        else return ("QmTaLJX1mhrg9aoJKv3fqcCBbsqZ8sKPaBDatW2bVSoFAW", "QmaJzMWMddCUfdxCTKbdnZ5e1FQKBJEJgwYpi4sv5re7s1");
    }

    function canHunt(uint256 tokenId) internal view returns (bool) {
        return block.timestamp >= lastHuntTime[tokenId] + 1 days
            && tokenData[tokenId].supplies > 0;
    }

    function canHuntMonster(uint256 tokenId) external view override returns (uint) {
        if(block.timestamp >= lastHuntTime[tokenId] + 1 days && tokenData[tokenId].supplies > 0) return 1;
        else if (tokenData[tokenId].supplies>0) return 2;
        else return 3;
    }

    function hunt(uint256 tokenId, uint8 monsterId) external returns(bool, uint256) {
        require(ownerOf(tokenId)==msg.sender, "Hunt: you should own this token first");
        require(canHunt(tokenId)==true, "Hunt: can not hunt");
        (,uint256 percent, uint256 ap, uint256 reward) = monster.getMonsterInfo(monsterId);
        require(tokenData[tokenId].attack_power>=ap, "This legion should have more strong power to hunt this monster");
        uint256 randnum = genRand(100);
        bool retval = false;
        if(randnum<percent) {
            if(rewardpool.getUnclaimedUSD(msg.sender)==0) taxStartDay[msg.sender] = block.timestamp;
            rewardpool.addReward(msg.sender, monsterId, reward);
            retval = true;
        }
        lastHuntTime[tokenId] = block.timestamp;
        tokenData[tokenId].supplies = tokenData[tokenId].supplies.sub(1);
        decreaseAttackPower(tokenId);
        emit Hunted(randnum, retval);
        return (retval, randnum);
    }

    function decreaseAttackPower(uint256 _tokenId) internal {
        uint damamgePercent = feehandler.getFee(4);
        tokenData[_tokenId].attack_power = tokenData[_tokenId].attack_power.sub(tokenData[_tokenId].attack_power.mul(damamgePercent).div(10000));
    }

    function claimReward() external {
        require(rewardpool.getUnclaimedUSD(msg.sender)>0, "You don't have any uncliamed reward");
        rewardpool.claimReward(msg.sender, taxStartDay[msg.sender]);
        taxStartDay[msg.sender] = 0;
    }

    function getTaxLeftDays(address _address) external view returns (uint) {
        if(taxStartDay[_address]==0) return 0;
        uint diffDays = (block.timestamp - taxStartDay[_address]) / 1 days;
        if(diffDays*2>=40) return 0;
        else return (40 - diffDays*2) / 2;
    }

    function genRand(uint256 maxNum) private view returns (uint256) {
        return uint256(uint256(keccak256(abi.encode(block.timestamp, block.difficulty, block.number))) % maxNum);
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

    function addBeasts(uint256 tokenId, uint256[] memory beastIds) external {
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
        uint256 unit = 10**18;
        uint256 bloodstoneAmount = itemPrice.mul(beastCount).mul(unit).div(denominator);
        require(bloodstone.balanceOf(msg.sender)>=bloodstoneAmount, "Insufficient balance");
        bloodstone.transferFrom(msg.sender, rewardPoolAddr, bloodstoneAmount);
    }
    function addWarriors(uint256 tokenId, uint256[] memory warriorIds) external {
        require(ownerOf(tokenId)==msg.sender, "You should own this legion");
        uint256 warriorCount = warriorIds.length;
        require(warriorCount > 0, "Please add warrior ids");
        uint256 ap = 0;
        for(uint i=0; i<warriorCount; i++) {
            require(warrior.ownerOf(warriorIds[i]) == msg.sender, "You should own these warriors");
            (,, ap) = warrior.getWarrior(warriorIds[i]);
            tokenData[tokenId].warrior_ids.push(warriorIds[i]);
            tokenData[tokenId].attack_power = tokenData[tokenId].attack_power.add(ap*100);
            warrior.burn(warriorIds[i]);
        }
        uint256 unit = 10**18;
        uint256 bloodstoneAmount = tokenData[tokenId].supplies.mul(supplyPrice).mul(unit).mul(warriorCount) + itemPrice.mul(warriorCount).mul(unit).div(denominator);
        require(bloodstone.balanceOf(msg.sender) >= bloodstoneAmount, "Insufficient balance");
        bloodstone.transferFrom(msg.sender, rewardPoolAddr, bloodstoneAmount);
    }
    function addSupply(uint256 tokenId, uint256 supply, bool fromWallet) external {
        require(ownerOf(tokenId)==msg.sender, "You should own this legion");
        if(fromWallet) {

        }
        // if(legion.supplies==0) {

        // }
        uint256 warriorCount = tokenData[tokenId].warrior_ids.length;
        uint256 bloodstoneAmount = warriorCount.mul(supply).mul(supplyPrice)*10**18;
        require(bloodstone.balanceOf(msg.sender)>=bloodstoneAmount, "Insufficient balance");
        bloodstone.transferFrom(msg.sender, rewardPoolAddr, bloodstoneAmount);
        tokenData[tokenId].supplies = tokenData[tokenId].supplies.add(supply);
    }

    function execute(uint256 _tokenId, bool isbeast) public {
        if(isbeast) {
            require(beast.ownerOf(_tokenId)==msg.sender, "Execute : you should own this beast");
            uint256 mintingPrice = beast.getMintingPrice();
            rewardpool.returnTokenToPlayer(msg.sender, mintingPrice.mul(2000).div(10000)*10**18);
            beast.burn(_tokenId);
        } else {
            require(warrior.ownerOf(_tokenId)==msg.sender, "Execute : you should own this warrior");
            uint256 mintingPrice = warrior.getMintingPrice();
            rewardpool.returnTokenToPlayer(msg.sender, mintingPrice.mul(2000).div(10000)*10**18);
            warrior.burn(_tokenId);
        }
    }

    function getTokenIds(address _address) external view returns (uint256[] memory) {
        return addressTokenIds[_address];
    }

    function getAvailableLegionsCount(address _address) external view returns (uint) {
        uint ret = 0;
        for(uint i=0; i<addressTokenIds[_address].length; i++) {
            if(canHunt(addressTokenIds[_address][i])) ret++;
        }
        return ret;
    }

    function getMaxAttackPower(address _address) external view returns(uint256) {
        uint256 ret = 0;
        for(uint i=0; i<addressTokenIds[_address].length; i++) {
            if(tokenData[addressTokenIds[_address][i]].attack_power>ret) ret = tokenData[addressTokenIds[_address][i]].attack_power;
        }
        return ret;
    }

    function setItemPrice(uint256 _itemPrice, uint256 _denominator) external onlyOwner {
        itemPrice = _itemPrice;
        denominator = _denominator;
    }

    function setSupplyPrice(uint256 _price) external onlyOwner {
        supplyPrice = _price;
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

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface IFeeHandler {
    function getFee(uint8 _index) external view returns(uint);
    function setFee(uint _fee, uint8 _index) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ILegionNFT is IERC721 {
    function getLegion(uint256 tokenId) external view returns(string memory, uint256[] memory, uint256[] memory, uint256, uint256, uint256);
    function canHuntMonster(uint256 tokenId) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./IFeeHandler.sol";
contract FeeHandler is IFeeHandler {
    uint[8] fees = [1500,250,200,800,100,20,12,16];
    address legion;
    modifier onlyLegion() {
        require(msg.sender == legion); _;
    }
    constructor() {
        legion = msg.sender;
    }
    function getFee(uint8 _index) external view override returns(uint) {
        return fees[_index];
    }
    function setFee(uint _fee, uint8 _index) external override onlyLegion{
        require(_index>=0 && _index<8, "Unknown fee type");
        fees[_index] = _fee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface IRewardPool {
    function returnTokenToPlayer(address _address, uint256 _amount) external;
    function addUnclaimedUSD(address _address, uint256 _amount) external;
    function addReward(address _winner, uint256 _monster_id, uint256 _reward) external;
    function getUnclaimedUSD(address _address) external view returns(uint256);
    function claimReward(address _address, uint256 taxStartDay) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IRewardPool.sol";

contract RewardPool is IRewardPool, Ownable {
    using SafeMath for uint256;
    IERC20 public bloodstone;
    address public legion;
    struct Reward {
        uint256 monster_id;
        uint256 timestamp;
        uint256 reward;
    }
    uint256 public totalHuntedCount;
    mapping (address => uint256) lastClaimedIndex;
    mapping (address => Reward[]) userRewards;

    event RewardClaimed(address indexed _address, uint256 amount);
    modifier onlyLegion() {
        require(msg.sender == legion); _;
    }

    mapping (address => uint256) unclaimedUSD;
    
    constructor () {
        legion = msg.sender;
        bloodstone = IERC20(0x8Cc6529d211eAf6936d003B521C61869131661DA);
    }

    function getUnclaimedUSD(address _address) external view override returns(uint256) {
        return unclaimedUSD[_address].mul(10**18).div(10);
    }

    function claimReward(address _address, uint256 taxStartDay) external override onlyLegion {
        uint diffDays = (block.timestamp - taxStartDay) / 1 days;
        if(diffDays>20) {
            diffDays = 20;
        }
        uint amountToClaim = (100-2*(20-diffDays)).mul((unclaimedUSD[_address]).mul(10**17)).div(100);
        bloodstone.transfer(_address, amountToClaim);
        unclaimedUSD[_address] = 0;
        emit RewardClaimed(_address, amountToClaim);
    }

    function addReward(address _winner, uint256 _monster_id, uint256 _reward) external override onlyLegion {
        userRewards[_winner].push(Reward(_monster_id, block.timestamp, _reward));
        unclaimedUSD[_winner] = unclaimedUSD[_winner].add(_reward);
        totalHuntedCount = totalHuntedCount.add(1);
    }

    function addUnclaimedUSD(address _address, uint256 _amount) external override onlyLegion {
        unclaimedUSD[_address] = unclaimedUSD[_address].add(_amount);
    }

    function returnTokenToPlayer(address _address, uint256 _amount) external override onlyLegion {
        require(bloodstone.balanceOf(address(this))>_amount, "returnTokenToPlayer : Insufficient Funds");
        bloodstone.transfer(_address, _amount);
    }
    
    function withdrawBNB(address payable _addr, uint256 amount) public onlyOwner {
        _addr.transfer(amount);
    }

    function withdrawBNBOwner(uint256 amount) public onlyOwner {
        msg.sender.transfer(amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IFeeHandler.sol";

interface IBeastNFT is IERC721 {
    function getBeast(uint256 tokenId) external  view returns(string memory, uint256, uint256);
    function getMintingPrice() external view returns (uint256);
    function burn(uint256 tokenId) external;
}

contract BeastNFT is Context, IBeastNFT, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    IERC20 public bloodstone;
    IFeeHandler feehandler;
    address public rewardpool;
    address public legion;
    uint256 mintingPrice;
    
    string public baseGifUrl = "https://gateway.pinata.cloud/ipfs/QmQhBohzSS8kF5cdYZnsNhEosiT9shL4P33syrE9buA2GH";
    string public baseJpgUrl = "https://gateway.pinata.cloud/ipfs/QmcrsRCQwNvnuRA47jvVTTard3YJaG93ysP75NWMRvgCiQ";
    
    modifier onlyLegion() {
        require(msg.sender == legion); _;
    }

    struct Beast {
        string name;
        uint256 strength;
        uint256 capacity;
    }
    mapping (uint256 => Beast) tokenData;
    mapping (address => uint256[]) addressTokenIds;

    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    mapping (uint256 => address) tokenToOwner;
    mapping (uint256 => uint256) tokenIdIndex;

    constructor(address _rewardpool, address _feehandler) {
        legion = msg.sender;
        bloodstone = IERC20(0x8Cc6529d211eAf6936d003B521C61869131661DA);
        feehandler = IFeeHandler(_feehandler);
        rewardpool = _rewardpool;
        mintingPrice = 20;
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

    function burn(uint256 tokenId) external override onlyLegion{
        address owner = ownerOf(tokenId);
        _transfer(owner, address(0), tokenId);
    }

    function mint(uint256 amount) external {
        uint256 bloodstoneAmount = getBloodstoneAmount(amount);
        require(bloodstone.balanceOf(msg.sender) >= bloodstoneAmount*10**18, "Insufficient payment");
        bloodstone.transferFrom(msg.sender, rewardpool, bloodstoneAmount*10**18);
        uint256 randNum = 0;
        Beast memory beast;
        for(uint i=0; i<amount; i++) {
            addressTokenIds[msg.sender].push(_tokenIds.current());
            tokenIdIndex[_tokenIds.current()] = addressTokenIds[msg.sender].length - 1;
            tokenToOwner[_tokenIds.current()] = msg.sender;
            randNum = genRand(1000, i);
            if (randNum==0&&randNum<4) {
                beast = Beast("Phoenix", 6, 20);
            } else if (randNum>=4&&randNum<14) {
                beast = Beast("Dragon", 5, 5);
            } else if (randNum>=14&&randNum<84) {
                beast = Beast("Griffin", 4, 4);
            } else if (randNum>=84&&randNum<224) {
                beast = Beast("Pegasus", 3, 3);
            } else if (randNum>=224&&randNum<504) {
                beast = Beast("Barghest", 2, 2);
            } else {
                beast = Beast("Centaur", 1, 1);
            }
            tokenData[_tokenIds.current()] = beast;
            _tokenIds.increment();
        }
    }

    function genRand(uint256 maxNum, uint256 i) private view returns (uint256) {
        return uint256(uint256(keccak256(abi.encode(block.timestamp, block.difficulty, i))) % maxNum);
    }

    function getBloodstoneAmount(uint256 _mintingAmount) public view returns (uint256) {
        if(_mintingAmount==1) {
            return mintingPrice;
        } else if(_mintingAmount==5) {
            return mintingPrice.mul(5).mul(98).div(100);
        } else if(_mintingAmount==10) {
            return mintingPrice.mul(10).mul(97).div(100);
        } else if(_mintingAmount==20) {
            return mintingPrice.mul(20).mul(95).div(100);
        } else if(_mintingAmount==100) {
            return mintingPrice.mul(100).mul(90).div(100);
        } else {
            return mintingPrice.mul(_mintingAmount);
        }
    }

    function getTokenIds(address _address) external view returns (uint256[] memory) {
        return addressTokenIds[_address];
    }

    function getBeast(uint256 tokenId) external view virtual override returns(string memory, uint256, uint256) {
        return (tokenData[tokenId].name, tokenData[tokenId].strength, tokenData[tokenId].capacity);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function getMintingPrice() external view override returns (uint256) {
        return mintingPrice;
    }

    function setMintingPrice(uint256 _price) public onlyOwner {
        require(_price>0, "price should be bigger than zero");
        mintingPrice = _price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IRewardPool.sol";
import "./IFeeHandler.sol";

interface IWarriorNFT is IERC721 {
    function getWarrior(uint256 tokenId) external view returns(string memory, uint256, uint256);
    function getMintingPrice() external view returns (uint256);
    function burn(uint256 tokenId) external;
}

contract WarriorNFT is Context, IWarriorNFT, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    IERC20 public bloodstone;
    IRewardPool rewardPool;
    address public rewardPoolAddr;
    IFeeHandler feehandler;
    address public legion;
    uint256 mintingPrice;
    
    string public baseGifUrl = "https://gateway.pinata.cloud/ipfs/QmbbbAszcvkYCengGP2tEWe7Q9yVSmNWPjqfJf5YKwqDQW";
    string public baseJpgUrl = "https://gateway.pinata.cloud/ipfs/QmfTvnF3Rk2JBrBSeRjFYe7erAzBN9c21NKyBTvcczX6Wm";

    modifier onlyLegion() {
        require(msg.sender == legion); _;
    }

    struct Warrior {
        string name;
        uint256 strength;
        uint256 attack_power;
    }
    mapping (uint256 => Warrior) tokenData;
    mapping (address => uint256[]) addressTokenIds;

    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    mapping (uint256 => address) tokenToOwner;
    mapping (uint256 => uint256) tokenIdIndex;
    constructor(address _rewardpool, address _feehandler) {
        legion = msg.sender;
        bloodstone = IERC20(0x8Cc6529d211eAf6936d003B521C61869131661DA);
        feehandler = IFeeHandler(_feehandler);
        mintingPrice = 20;
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

    function burn(uint256 tokenId) external override onlyLegion{
        address owner = ownerOf(tokenId);
        _transfer(owner, address(0), tokenId);
    }

    function mint(uint256 amount) external {
        uint256 bloodstoneAmount = getBloodstoneAmount(amount);
        require(bloodstone.balanceOf(msg.sender) >= bloodstoneAmount*10**18, "Insufficient payment");
        bloodstone.transferFrom(msg.sender, address(rewardPoolAddr), bloodstoneAmount*10**18);
        uint256 randNum;
        Warrior memory warrior;
        for(uint i=0; i<amount; i++) {
            addressTokenIds[msg.sender].push(_tokenIds.current());
            tokenIdIndex[_tokenIds.current()] = addressTokenIds[msg.sender].length - 1;
            tokenToOwner[_tokenIds.current()] = msg.sender;
            randNum = genRand(1000, i);
            if (randNum==0&&randNum<2) {
                warrior = Warrior("Dragon", 6, 50000+genRand(10001, randNum));
            } else if (randNum>=2&&randNum<12) {
                warrior = Warrior("Minotaur", 5, 4000+genRand(2001, randNum));
            } else if (randNum>=12&&randNum<82) {
                warrior = Warrior("Dwarf", 4, 3000+genRand(1001, randNum));
            } else if (randNum>=82&&randNum<222) {
                warrior = Warrior("Satyr", 3, 2000+genRand(1001, randNum));
            } else if (randNum>=222&&randNum<502) {
                warrior = Warrior("Gnome", 2, 1000+genRand(1001, randNum));
            } else {
                warrior = Warrior("Hobbit", 1, 500+genRand(501, randNum));
            }
            tokenData[_tokenIds.current()] = warrior;
            _tokenIds.increment();
        }
    }

    function genRand(uint256 maxNum, uint256 i) private view returns (uint256) {
        return uint256(uint256(keccak256(abi.encode(block.timestamp, block.difficulty, i))) % maxNum);
    }

    function getBloodstoneAmount(uint256 _mintingAmount) private view returns (uint256) {
        if(_mintingAmount==1) {
            return mintingPrice;
        } else if(_mintingAmount==5) {
            return mintingPrice.mul(5).mul(98).div(100);
        } else if(_mintingAmount==10) {
            return mintingPrice.mul(10).mul(97).div(100);
        } else if(_mintingAmount==20) {
            return mintingPrice.mul(20).mul(95).div(100);
        } else if(_mintingAmount==100) {
            return mintingPrice.mul(100).mul(90).div(100);
        } else {
            return mintingPrice.mul(_mintingAmount);
        }
    }

    function getTokenIds(address _address) external view returns (uint256[] memory) {
        return addressTokenIds[_address];
    }

    function getWarrior(uint256 tokenId) external override view returns(string memory, uint256, uint256) {
        return (
            tokenData[tokenId].name,
            tokenData[tokenId].strength,
            tokenData[tokenId].attack_power
        );
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function getMintingPrice() external view override returns (uint256) {
        return mintingPrice;
    }

    function setMintingPrice(uint256 _price) public onlyOwner {
        require(_price>0, "price should be bigger than zero");
        mintingPrice = _price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface IMonster {
    function getMonsterInfo(uint8 monsterId) external view returns(string memory, uint256, uint256, uint256);
    function getMonsterToHunt(uint256 ap) external view returns (uint256);
}


contract Monster is IMonster {
    using SafeMath for uint256;
    address public legion;
    address public rewardpool;
    string public baseGifUrl = "https://gateway.pinata.cloud/ipfs/QmcXzv8YAVctL8maUdB83sruPBkV2i7WdRNvxLfvbdnagF";
    string public baseJpgUrl = "https://gateway.pinata.cloud/ipfs/QmfX6GLJBGpQBfDRCnqUgTuQkFTp1BaM65F9QHxLNBZUJE";
    struct Monster {
        string name;
        uint256 percent;
        uint256 attack_power;
        uint256 reward;
    }
    mapping (uint8 => Monster) monsterData;
    modifier onlyLegion() {
        require(msg.sender == legion); _;
    }

    constructor (address _rewardpool) {
        legion = msg.sender;
        rewardpool = _rewardpool;
        initiateMonsterData();
    }

    function initiateMonsterData() internal {
        monsterData[1].name = "bat";
        monsterData[1].percent = 85;
        monsterData[1].attack_power = 200000;
        monsterData[1].reward = 65;
        monsterData[2].name = "wereshark";
        monsterData[2].percent = 82;
        monsterData[2].attack_power = 500000;
        monsterData[2].reward = 160;
        monsterData[3].name = "rhinark";
        monsterData[3].percent = 78;
        monsterData[3].attack_power = 800000;
        monsterData[3].reward = 260;
        monsterData[4].name = "lacodon";
        monsterData[4].percent = 75;
        monsterData[4].attack_power = 1000000;
        monsterData[4].reward = 325;
        monsterData[5].name = "oliphant";
        monsterData[5].percent = 72;
        monsterData[5].attack_power = 1300000;
        monsterData[5].reward = 440;
        monsterData[6].name = "ogre";
        monsterData[6].percent = 68;
        monsterData[6].attack_power = 1700000;
        monsterData[6].reward = 605;
        monsterData[7].name = "werewolf";
        monsterData[7].percent = 65;
        monsterData[7].attack_power = 2000000;
        monsterData[7].reward = 740;
        monsterData[8].name = "orc";
        monsterData[8].percent = 62;
        monsterData[8].attack_power = 2200000;
        monsterData[8].reward = 850;
        monsterData[9].name = "cyclops";
        monsterData[9].percent = 59;
        monsterData[9].attack_power = 2500000;
        monsterData[9].reward = 1010;
        monsterData[10].name = "gargoyle";
        monsterData[10].percent = 55;
        monsterData[10].attack_power = 2800000;
        monsterData[10].reward = 1210;
        monsterData[11].name = "golem";
        monsterData[11].percent = 52;
        monsterData[11].attack_power = 3100000;
        monsterData[11].reward = 1410;
        monsterData[12].name = "land dragon";
        monsterData[12].percent = 49;
        monsterData[12].attack_power = 3400000;
        monsterData[12].reward = 1620;
        monsterData[13].name = "chimera";
        monsterData[13].percent = 45;
        monsterData[13].attack_power = 3700000;
        monsterData[13].reward = 1900;
        monsterData[14].name = "earthworm";
        monsterData[14].percent = 42;
        monsterData[14].attack_power = 4000000;
        monsterData[14].reward = 2150;
        monsterData[15].name = "hydra";
        monsterData[15].percent = 41;
        monsterData[15].attack_power = 4200000;
        monsterData[15].reward = 2450;
        monsterData[16].name = "rancor";
        monsterData[16].percent = 41;
        monsterData[16].attack_power = 4700000;
        monsterData[16].reward = 2950;
        monsterData[17].name = "cerberus";
        monsterData[17].percent = 41;
        monsterData[17].attack_power = 5000000;
        monsterData[17].reward = 3250;
        monsterData[18].name = "titan";
        monsterData[18].percent = 39;
        monsterData[18].attack_power = 5300000;
        monsterData[18].reward = 3800;
        monsterData[19].name = "forest dragon";
        monsterData[19].percent = 39;
        monsterData[19].attack_power = 5600000;
        monsterData[19].reward = 4300;
        monsterData[20].name = "ice dragon";
        monsterData[20].percent = 39;
        monsterData[20].attack_power = 6000000;
        monsterData[20].reward = 4900;
        monsterData[21].name = "volcano dragon";
        monsterData[21].percent = 35;
        monsterData[21].attack_power = 25000000;
        monsterData[21].reward = 23000;
        monsterData[22].name = "fire demon";
        monsterData[22].percent = 30;
        monsterData[22].attack_power = 30000000;
        monsterData[22].reward = 33000;
    }
    
    function getMonsterInfo(uint8 monsterId) external override view returns(string memory, uint256, uint256, uint256) {
        require(monsterId>0&&monsterId<23, "Monster is not registered");
        return (monsterData[monsterId].name, monsterData[monsterId].percent, monsterData[monsterId].attack_power, monsterData[monsterId].reward);
    }

    function getMonsterToHunt(uint256 ap) external override view onlyLegion returns (uint256) {
        uint256 retVal = 0;
        for(uint8 i=1;i<23;i++) {
            if(ap<=monsterData[i].attack_power) continue;
            retVal = i;
            break;
        }
        return retVal;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./BeastNFT.sol";
import "./WarriorNFT.sol";
import "./IFeeHandler.sol";
import "./ILegionNFT.sol";

contract Marketplace {
    using SafeMath for uint256;
    address public rewardpool;
    IBeastNFT public beast;
    IWarriorNFT public warrior;
    IERC20 bloodstone;
    ILegionNFT public legion;
    IFeeHandler feehandler;
    struct MarketItem {
        address seller;
        uint256 price;
    }
    mapping(uint8 => mapping (uint256 => MarketItem)) items;

    event CancelSelling(uint8 _itemType, uint256 _tokenId);
    event SellToken(uint8 _itemType, uint256 _tokenId);
    event BuyToken(uint8 _itemType, uint256 _tokenId);

    constructor (address _rewardpool, address _feehandler, address _beast, address _warrior, address _legion) {
        legion = ILegionNFT(_legion);
        rewardpool = _rewardpool;
        feehandler = IFeeHandler(_feehandler);
        bloodstone = IERC20(0x8Cc6529d211eAf6936d003B521C61869131661DA);
        beast = IBeastNFT(_beast);
        warrior = IWarriorNFT(_warrior);
    }

    function buyToken(uint8 _itemType, uint256 _tokenId) external {
        require(bloodstone.balanceOf(msg.sender)>=items[_itemType][_tokenId].price*10**18, "Insufficent balance");
        uint256 amountToRewardpool = (items[_itemType][_tokenId].price*10**18).mul(feehandler.getFee(0)).div(10000);
        uint256 amountToSeller = (items[_itemType][_tokenId].price*10**18).sub(amountToRewardpool);
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
        if(_itemType==1) {
            require(beast.ownerOf(_tokenId)==msg.sender, "This is not your NFT");
            beast.transferFrom(msg.sender, address(this), _tokenId);
        } else if(_itemType==2) {
            require(warrior.ownerOf(_tokenId)==msg.sender, "This is not your NFT");
            warrior.transferFrom(msg.sender, address(this), _tokenId);
        } else {
            require(legion.ownerOf(_tokenId)==msg.sender && legion.canHuntMonster(_tokenId)==1, "This is not your NFT or this Legion can not hunt");
            legion.transferFrom(msg.sender, address(this), _tokenId);
        }
        items[_itemType][_tokenId] = MarketItem(msg.sender, _price);
        emit SellToken(_itemType, _tokenId);
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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