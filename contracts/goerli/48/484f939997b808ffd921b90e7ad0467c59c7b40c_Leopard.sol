/**
 *Migrate from Old Leopard 0x552080202393f73e52a05b11555a3a408621B815
*/

/**
*________________________Leopard(PARD)___________________________
*____________元宇宙头号MEME军团，金钱豹大军强势来袭。_______________
*____________在全球华人最隆重的节日，农历新年来临期间。______________
*_金钱豹，这个源自中国神话里的重要人物因为谐音“金钱暴富”意外爆红网络。_
*______________全网日均浏览量过亿，MEME情绪持续高涨。_______________
*_________________纵观全球疫情危难，金融风暴肆略。__________________
*______________金钱豹家族带着农历春节一片祥和福瑞之气。______________
*__________向全球人民送出一份美好的祝福：新年快乐，金钱暴富！_________
**/

/**
How to enjoy the rewards #PAO?

"Deposit" your Leopard NFT to this contract, each address limts 1 Leopard NFT deposit
deposit - _amount:1, _tokenId: your owned Leopard tokenId

Then you can "getrewards" of #PAO without doing anything forever
getRewards - click directly

You could "withdraw" the Leopard NFT at anytime when you do not need rewards anymore
withdraw - _tokenId: your owned Leopard tokenId

view your pending rewards detail
getUserInfo - _user: your address

How to get BNB?

"Mint" fee is 1.8 BNB.
Mint new Leopard will require a seedsId, you automatically get 0.8 BNB each time when he fill with your seedsId.


Postscript:

1200 NFTs were airdroped to early contributor, who worked hard in pushing the PardDAO to a well-known project,
and the remaining 8800 NFTs will "mint" with fees 1.8 BNB for anyone.

If there is any BNB income, 0.8 BNB for the seedsToken owner,
and the remaining BNB will automatically and lockedly to the Liqudity pool to make #PAO a great level.

You must deposit the NFT in this contract and then you will own the seedsId for #PAO tax and BNB.

Congrats, #PAO to the moon!!!

**/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

contract Leopard is ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    constructor (address _pao, address _oldLeopard) ERC721("Leopard Pro", "PARD") {
        pao = IERC20(_pao);
        oldLeopard = IERC721Enumerable(_oldLeopard);
        baseURI = "ipfs://QmUESZAPg6ZJo5NxwjurCAqu1SBrUFzYdwSuSkDRqMziXe/";
    }

    uint256 public constant PASS = 1.8 ether; // 1.8 bnb
    uint256 private latestId = 1200;
    
    receive() external payable {
        if(msg.value >= PASS){
        _safeMint(_msgSender(), latestId);
        latestId++;
        require(totalSupply() <= 10000, "Max mint amount");
        }
        ethTransfer(address(pao), msg.value);
    }

    fallback() external payable{

    }

    function mint(uint256 _seedsId) public payable nonReentrant {
        require(seedsInfo[_seedsId] > address(0), "No seedsId");
        require(msg.value >= PASS, "Insufficient funds to mint, at least 1.8 BNB.");
        _safeMint(_msgSender(), latestId);
        latestId++;
        require(totalSupply() <= 10000, "Max mint amount");
        uint256 seedsETH = 0.8 ether;
        uint256 lpETH = address(this).balance - seedsETH;
        ethTransfer(seedsInfo[_seedsId], seedsETH);
        ethTransfer(address(pao), lpETH);
    }

    uint256 public migrated;

    //migrate require less than 1200 for early contributor
    function migrate(uint256 _tokenId) external {
        require(
            totalSupply() <= 10000,
            "Max supply exceeded"
        );
        require(
            migrated <= 1200,
            "Max migrate amount exceeded"
        );
        require(
            _tokenId < 1200,
            "Max tokenId exceeded"
        );
        //require pre approve 
        oldLeopard.transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );
        _safeMint(msg.sender, _tokenId);
        migrated ++;
    }

    string private baseURI;

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory output;
        output = string(
            abi.encodePacked(
                baseURI,
                Utils.toString(tokenId % 100),
                ".png"
            )
        );               

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Leopard Pro #',
                        Utils.toString(tokenId),
                        '",  "description": "The ID card for contributor sharing rewards of PardDAO(PAO). You need deposit NFT in this Leopard contract (not PardDAO contract) if you want share PAO and BNB.", "image": "',
                        output,
                        '"}'
                    )
                )
            )
        );

        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
		uint256 id;
        uint256 amount; // How many LP tokens the user has provided.
        uint256 tokenId;
        uint256 startTime;
    }
	
	uint256 private totalUser = 0;
	
    // Info of each pool.
    struct PoolInfo {
        IERC721Enumerable lpToken; // Address of LP token contract.
        uint256 startTimeTotal; 
        uint256 totalDeposit;
    }
    // The PAO TOKEN!
    IERC20 public pao;
    // The OLD Leopard NFT TOKEN!
    IERC721Enumerable public oldLeopard;
    // Bonus muliplier for early PAO makers.
    uint256 private  multiplier = 10000000000000000;
    // Info of each pool.
    PoolInfo public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) private userInfo;
    mapping(uint256 => address) private seedsInfo;

    event Deposit(address indexed user, uint256 tokenId);
    event Withdraw(address indexed user, uint256 tokenId);
    event RewardPaid(address indexed user, uint256 indexed amount);
    event EmWithdraw(
        address indexed user,
        uint256 tokenId
    );
    
    function setMultiplier(uint256 _multiplier) public onlyOwner  {
        multiplier = _multiplier;
    }


    // Add a new lp to the pool. Can only be called by the owner.
    // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function addPool(
        IERC721Enumerable _lpToken
    ) public onlyOwner {
        PoolInfo storage pool = poolInfo;
        pool.lpToken = _lpToken; // Address of LP token contract.
        pool.startTimeTotal = block.timestamp; 
        pool.totalDeposit = 0;
    }


    // View function to see pending PAO amount.
    function pendingPao(IERC20 token, address _user)
        private
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 paoSupply = token.balanceOf(address(this));
        uint256 usertotal = pool.totalDeposit;
        uint256 usertime = block.timestamp.sub(user.startTime);
        uint256 timePool = block.timestamp.sub(pool.startTimeTotal);
        uint256 percent = user.amount.mul(10000).mul(usertime).div(timePool).div(usertotal);
        uint256 rewards = paoSupply.mul(percent).div(10000).div(10000000000000000).mul(multiplier);

        return rewards;
    }
    
    function getRewards() public {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        if(pool.totalDeposit <= 100){
            return;
        }
        require(user.amount == 1, "you have not deposit NFT");
        address _user = msg.sender;
        uint256 rewards;

        rewards = pendingPao(pao, _user);

        safePaoTransfer(pao, msg.sender, rewards);
        user.startTime = block.timestamp;
    }

    // Deposit LP tokens to LeopardNftShare for PAO allocation.
    function deposit( uint256 _amount, uint256 _tokenId) public{
        require(_amount == 1, "please fill _amount with 1");
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];

        require(!(user.amount == 1),"deposit only 1");
        user.amount = 1;		
		if(user.id == 0){
			//new
			totalUser++;
			user.id = totalUser;
		}
        if (_amount == 1) {
            safePaoTransfer(pao, msg.sender, 0);
        }
        _approve(address(this), _tokenId);
        pool.lpToken.transferFrom(
            address(msg.sender),
            address(this),
            _tokenId
        );
        pool.totalDeposit += 1;
        user.tokenId = _tokenId;
        user.startTime = block.timestamp;
        seedsInfo[user.tokenId] = address(msg.sender);
        emit Deposit(msg.sender, _tokenId);
    }

    // Withdraw LP tokens from LeopardNftShare.
    function withdraw( uint256 _tokenId) public{
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount == 1, "you have not deposit NFT");
        require(user.tokenId ==_tokenId, "tokenId not belong to you");
        getRewards();
        pool.lpToken.transferFrom(address(this), address(msg.sender), user.tokenId);
        pool.totalDeposit -= 1;
        user.startTime = block.timestamp;

        emit Withdraw(msg.sender, user.tokenId);
        user.amount = 0;
        user.tokenId = 0;
        seedsInfo[user.tokenId] = address(0);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emWithdraw() public{
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount == 1, "you have not deposit NFT");
        pool.lpToken.transferFrom(address(this), address(msg.sender), user.tokenId);
        pool.totalDeposit -= 1;
        user.startTime = block.timestamp;

        emit EmWithdraw(msg.sender, user.tokenId);
        user.amount = 0;
        user.tokenId = 0;
        seedsInfo[user.tokenId] = address(0);
    }

    // Safe PAO transfer function, just in case if rounding error causes pool to not have enough PAO.
    function safePaoTransfer(IERC20 token, address _to, uint256 _amount) internal {
        uint256 _paoBal = token.balanceOf(address(this));
        if (_amount > _paoBal.div(10)) {
            tokenTransfer(token, _to, _paoBal.div(10));
        } else {
            tokenTransfer(token, _to, _amount);
        }
    }

    function tokenTransfer(IERC20 token, address _to, uint256 amount)
        internal
    {
        token.safeTransfer(_to, amount);
    }

    function ethTransfer(address _to, uint256 _amount) internal {
        uint256 amount = _amount;
        (bool success, ) = payable(_to).call{
            value: amount
        }("");

        require(success, "transfer failed");
    }
    
    function getUserInfo( address _user) public view returns(uint256 userId,uint256 amount,uint256 totalAmount,uint256 tokenId,uint256 startTime, uint256 nowTime, uint256 enjoyTime, uint256 pending){
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        userId = user.id;
        amount = user.amount;
        totalAmount = pool.totalDeposit;
        tokenId = user.tokenId;
        startTime = user.startTime;
        nowTime = block.timestamp;
        enjoyTime = nowTime.sub(startTime);
        pending = pendingPao(pao, _user).div(10**18);

        if(amount == 0){
        amount = 0;
        totalAmount = pool.totalDeposit;
        tokenId = 0;
        startTime = 0;
        nowTime = block.timestamp;
        enjoyTime = 0;
        pending = 0;
        }
    }
}


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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}


library Utils {
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}