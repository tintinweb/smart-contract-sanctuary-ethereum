// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IMarketPlace {
    function returnSeller(uint256 _id) external returns (address);
}

contract CoBatchingPool is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _pollId;

    enum PoolType {
        Private,
        Public
    }

    struct Pool {
        address admin;
        uint256 itemId;
        uint256 nftId;
        address nftContract;
        uint256 maxParticipants;
        uint256 maxContribution;
        uint256 expirationTime;
        PoolType poolType;
        uint256 floorPrice;
        uint256 neededContribution;
        bool active;
        uint256 resaleId;
    }

    struct Participant {
        address account;
        uint256 contribution;
        uint256 percentageOwns;
        bool voted;
    }

    struct resaleItemInfo {
        uint256 nftId;
        address nftcontract;
        uint256 newPrice;
        bool activeForSale;
    }

    struct fractionInfo {
        uint256 pollId;
        uint256 nftId;
        address nftContract;
        address sellPerson;
        uint256 contributionPrize;
        uint256 expirationTime;
        bool sold;
    }

    struct itemInfo {
        uint256 pollId;
        bool isPoolCreated;
    }

    struct resaleitem {
        uint256 pollid;
        bool resalepoolitem;
    }

    IERC20 public napaToken;
    address MarketPlaceAddress;

    mapping(uint256 => Pool) public pools;
    mapping(uint256 => mapping(address => Participant)) public participants;
    mapping(uint256 => mapping(uint256 => resaleItemInfo)) public resaleItem;
    mapping(uint256 => address[]) public participantList;
    mapping(uint256 => mapping(address => fractionInfo)) public fractionSeller;
    mapping(uint256 => itemInfo) public itempoolinfo;
    mapping(uint256 => resaleitem) public resalepooliteminfo;

    event PoolCreated(
        uint256 indexed poolId,
        address indexed admin,
        uint256 indexed nftId,
        address nftContract,
        uint256 maxParticipants,
        uint256 maxContribution,
        uint256 expirationTime,
        PoolType poolType,
        uint256 floorPrice
    );

    event PoolJoined(
        uint256 indexed poolId,
        address indexed participant,
        uint256 contribution
    );

    event PoolEnded(uint256 indexed poolId, bool success);

    event PoolListed(uint256 indexed poolId, uint256 price);

    event VoteCast(
        uint256 indexed poolId,
        address indexed participant,
        bool accept
    );

    constructor(address _napaToken) {
        napaToken = IERC20(_napaToken);
    }

    modifier onlyPoolAdmin(uint256 _poolId) {
        require(
            msg.sender == pools[_poolId].admin,
            "Only pool admin can call this function"
        );
        _;
    }

    modifier onlyPoolParticipant(uint256 _poolId) {
        require(
            participants[_poolId][msg.sender].account == msg.sender,
            "Only pool participant can call this function"
        );
        _;
    }

    //Fees setup starts
    address payable public feesAddress =
        payable(0x1cb0a69aA6201230aAc01528044537d0F9D718F3);

    function transferFees(uint256 amount)
        public
        payable
        returns (bool _response)
    {
        require((msg.value) >= amount, "please send Correct Fees.");
        require(
            (msg.sender).balance >= amount,
            "you don't have enough balance to initiate this swap"
        );
        feesAddress.transfer(msg.value);
        _response = true;
    }

    function changeFeesAddress(address payable _feesAddress) public onlyOwner {
        feesAddress = _feesAddress;
    }

    //Fees setup ends

    function setMarketplaceaddress(address _to) public onlyOwner {
        MarketPlaceAddress = _to;
    }

    function changeNapaToken(address _napaToken) public onlyOwner {
        napaToken = IERC20(_napaToken);
    }

    function createPool(
        uint256 _itemId,
        uint256 _nftId,
        address _nftContract,
        uint256 _maxParticipants,
        uint256 _maxContribution,
        uint256 _biddingTime,
        PoolType _poolType,
        uint256 _floorPrice
    ) public {
        require(
            itempoolinfo[_itemId].isPoolCreated == false,
            "already pool created for this itemid"
        );
        //Fees Payment
        uint256 newAmount = (_floorPrice * (10**18)).mul(2).div(100);
        require(transferFees(newAmount), "Error while Transffering the Fees");
        //ends
        _pollId.increment();
        uint256 pollId = _pollId.current();
        pools[pollId] = Pool({
            admin: msg.sender,
            itemId: _itemId,
            nftId: _nftId,
            nftContract: _nftContract,
            maxParticipants: _maxParticipants,
            maxContribution: _maxContribution * (10**18),
            expirationTime: block.timestamp + _biddingTime,
            poolType: _poolType,
            floorPrice: _floorPrice * (10**18),
            neededContribution: _floorPrice * (10**18),
            active: true,
            resaleId: 0
        });
        uint256 amt = (_floorPrice * (10**18)).mul(10).div(100);
        napaToken.transferFrom(msg.sender, MarketPlaceAddress, amt);
        pools[pollId].neededContribution =
            pools[pollId].neededContribution -
            amt;

        uint256 percentage = ((amt * 100) * 100) / (_floorPrice * 10**18);

        participants[pollId][msg.sender] = Participant({
            account: msg.sender,
            contribution: amt,
            percentageOwns: percentage,
            voted: false
        });

        participantList[pollId].push(msg.sender);
        itempoolinfo[_itemId] = itemInfo(pollId, true);

        emit PoolJoined(pollId, msg.sender, amt);

        emit PoolCreated(
            pollId,
            msg.sender,
            _nftId,
            _nftContract,
            _maxParticipants,
            _maxContribution * (10**18),
            block.timestamp + _biddingTime,
            _poolType,
            _floorPrice * (10**18)
        );
    }

    function joinPool(uint256 _poolId, uint256 _amount) public {
        uint256 amt = _amount * (10**18);
        Pool storage pool = pools[_poolId];
        require(pool.active, "Pool is not active");
        require(block.timestamp <= pool.expirationTime, "Pool has expired");
        require(
            participants[_poolId][msg.sender].account != msg.sender,
            "You have already joined this pool"
        );
        require(
            participantList[_poolId].length < pool.maxParticipants,
            "Pool is full"
        );
        require(
            pool.poolType == PoolType.Public || msg.sender == pool.admin,
            "Pool is private"
        );
        require(
            amt <= pool.maxContribution,
            "Amount is not within the contribution limits"
        );
        require(pool.neededContribution >= amt, "please transfer needed token");

        uint256 percentage = ((amt * 100) * 100) / pools[_poolId].floorPrice;

        napaToken.transferFrom(msg.sender, MarketPlaceAddress, amt);
        pool.neededContribution = pool.neededContribution - amt;
        napaToken.approve(address(this), amt);
        participants[_poolId][msg.sender] = Participant({
            account: msg.sender,
            contribution: amt,
            percentageOwns: percentage,
            voted: false
        });
        participantList[_poolId].push(msg.sender);
        emit PoolJoined(_poolId, msg.sender, amt);
    }

    function endPool(uint256 _poolId, uint256 _itemId) public {
        require(
            msg.sender == MarketPlaceAddress,
            "Only admin can call this function"
        );
        Pool storage pool = pools[_poolId];
        require(pool.active, "Pool is not active");
        for (uint256 i = 0; i < participantList[_poolId].length; i++) {
            address participant = participantList[_poolId][i];
            napaToken.transfer(
                participant,
                participants[_poolId][participant].contribution
            );
        }
        pools[_poolId].active = false;
        itempoolinfo[_itemId].isPoolCreated = false;
        emit PoolEnded(_poolId, false);
    }

    function reListItem(uint256 _poolId, uint256 _newPrice)
        public
        onlyPoolAdmin(_poolId)
    {
        Pool storage pool = pools[_poolId];
        require(!pool.active, "Pool is active");
        require(
            IERC721(pool.nftContract).ownerOf(pool.nftId) == address(this),
            "You must own the NFT to resale"
        );
        pool.resaleId++;
        uint256 resaleid = pool.resaleId;

        resaleItem[_poolId][resaleid] = resaleItemInfo(
            pool.nftId,
            pool.nftContract,
            _newPrice * (10**18),
            false
        );
    }

    function voteForPrice(uint256 _poolId, bool _accept)
        public
        onlyPoolParticipant(_poolId)
    {
        Pool storage pool = pools[_poolId];

        require(pool.active == false, "pool is active");

        require(
            !participants[_poolId][msg.sender].voted,
            "You have already voted"
        );
        participants[_poolId][msg.sender].voted = _accept;

        if (votingResult(_poolId) > 50) {
            uint256 resaleid = pool.resaleId;
            resaleItem[_poolId][resaleid].activeForSale = true;
        }
        emit VoteCast(_poolId, msg.sender, _accept);
    }

    function votingResult(uint256 _poolId) public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < participantList[_poolId].length; i++) {
            address participant = participantList[_poolId][i];
            if (participants[_poolId][participant].voted == true) {
                count++;
            }
        }
        uint256 voteResult = (count * 100) / participantList[_poolId].length;
        return voteResult;
    }

    function sellFraction(uint256 _poolId) public onlyPoolParticipant(_poolId) {
        Pool storage pool = pools[_poolId];
        require(pools[_poolId].active, "Pool is not active");
        require(block.timestamp <= pool.expirationTime, "Pool has expired");
        fractionSeller[_poolId][msg.sender] = fractionInfo(
            _poolId,
            pool.nftId,
            pool.nftContract,
            msg.sender,
            participants[_poolId][msg.sender].contribution,
            pool.expirationTime,
            false
        );
    }

    function BuyFraction(
        uint256 _poolId,
        address _seller,
        uint256 _amount
    ) public payable {
        Pool storage pool = pools[_poolId];
        uint256 amt = _amount * 10**18;
        require(pools[_poolId].active, "Pool is not active");
        require(block.timestamp <= pool.expirationTime, "Pool has expired");
        require(
            fractionSeller[_poolId][_seller].sold == false,
            "fraction already sold"
        );
        require(
            participants[_poolId][_seller].contribution == amt ||
                participants[_poolId][_seller].contribution == msg.value,
            "Amount not match"
        );

        uint256 percentage = participants[_poolId][_seller].percentageOwns;

        address seller = participants[_poolId][_seller].account;
        napaToken.transferFrom(msg.sender, seller, amt);
        for (uint256 i = 0; i < participantList[_poolId].length; i++) {
            address participant = participantList[_poolId][i];
            if (participant == seller) {
                participantList[_poolId][i] = msg.sender;
                break;
            }
        }
        delete participants[_poolId][_seller];
        participants[_poolId][msg.sender] = Participant(
            msg.sender,
            amt,
            percentage,
            false
        );
        fractionSeller[_poolId][seller].sold = true;
    }

    function returnPollId(uint256 _itemId)
        public
        view
        returns (uint256 pollId)
    {
        pollId = itempoolinfo[_itemId].pollId;
    }

    function resalePoolInfo(uint256 _itemId) public view returns (bool) {
        bool data = resalepooliteminfo[_itemId].resalepoolitem;
        return data;
    }

    function newPoolId(uint256 _itemId)
        public
        view
        returns (uint256, address[] memory)
    {
        uint256 _poolId = resalepooliteminfo[_itemId].pollid;
        address[] memory member = participantList[_poolId];
        return (_poolId, member);
    }

    function pooldata(uint256 _poolId)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        )
    {
        address _admin = pools[_poolId].admin;
        uint256 _itemId = pools[_poolId].itemId;
        uint256 _floorPrice = pools[_poolId].floorPrice;
        uint256 _neededContribution = pools[_poolId].neededContribution;
        bool _active = pools[_poolId].active;
        uint256 _resaleId = pools[_poolId].resaleId;
        return (
            _admin,
            _itemId,
            _floorPrice,
            _neededContribution,
            _active,
            _resaleId
        );
    }

    function memberPercentage(uint256 _pollid, address _member)
        public
        view
        returns (uint256)
    {
        uint256 percentage = participants[_pollid][_member].percentageOwns;
        return percentage;
    }

    function setData(uint256 _itemId, uint256 _pollid) public {
        resalepooliteminfo[_itemId].resalepoolitem = false;
        pools[_pollid].active = false;
        itempoolinfo[_itemId].isPoolCreated = false;
        resalepooliteminfo[_itemId] = resaleitem(_pollid, true);
    }

    function setsellData(uint256 _itemId, uint256 _pollid) public {
        pools[_pollid].active = false;
        itempoolinfo[_itemId].isPoolCreated = false;
        resalepooliteminfo[_itemId] = resaleitem(_pollid, true);
    }

    function setResaleValue(uint256 _itemId) public {
        resalepooliteminfo[_itemId].resalepoolitem = false;
    }

    function activePoll(uint256 _pollid) public view returns (bool) {
        bool data = pools[_pollid].active;
        return data;
    }

    function isResaleActive(uint256 _pollid)
        public
        view
        returns (uint256, bool)
    {
        uint256 _resaleId = pools[_pollid].resaleId;
        uint256 price = resaleItem[_pollid][_resaleId].newPrice;
        bool active = resaleItem[_pollid][_resaleId].activeForSale;
        return (price, active);
    }

    function transferNFT(
        address _to,
        uint256 _tokenId,
        address nftContractAddress
    ) external {
        require(
            msg.sender == address(MarketPlaceAddress),
            "only nftMarketplace can Call this function"
        );
        IERC721 nftContract = IERC721(nftContractAddress);
        nftContract.transferFrom(address(this), _to, _tokenId);
    }

    function fetchPoolmember(uint256 _poolId)
        public
        view
        returns (address[] memory _participants)
    {
        _participants = participantList[_poolId];
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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