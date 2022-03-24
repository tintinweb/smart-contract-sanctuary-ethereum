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
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBeastNFT is IERC721 {
    function getBeast(uint256 tokenId) external  view returns(string memory, uint256, uint256);
    function burn(uint256 tokenId) external;
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

interface IRewardPool {
    function returnTokenToPlayer(address _address, uint256 _amount) external;
    function addReward(address _winner, uint256 _monster_id, uint256 _reward) external;
    function subReward(address _address, uint256 _reward) external;
    function getUnclaimedBLST(address _address) external view returns(uint256);
    function claimReward(address _address, uint256 taxStartDay) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IWarriorNFT is IERC721 {
    function getWarrior(uint256 tokenId) external view returns(string memory, uint256, uint256);
    function burn(uint256 tokenId) external;
}