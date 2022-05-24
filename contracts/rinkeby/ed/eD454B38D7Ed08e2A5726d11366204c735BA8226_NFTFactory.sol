/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol



pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// File: @openzeppelin/contracts/math/SafeMath.sol



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

// File: contracts/NFTFactory.sol


pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;




interface IERC721 {
    function safeMint(address to, uint256 tokenId) external;

    function totalSupply() external view returns (uint256);
}


contract NFTFactory is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant MAXIMUM = 4500;

    IERC721 public nft;

    struct UserInfo {
        bool whitelist;
        uint256 offerPrice;
        uint256 claimedNum;
    }

    struct PoolInfo {
        uint256 maxNum;
        uint256 supply;
        uint256 startBlock;
        uint256 endBlock;
        uint256 limitPerAccount;
    }

    PoolInfo[] private pools;

    mapping(uint256 => uint256) private tokenMatrix;
    mapping(uint256 => mapping(address => UserInfo)) private users;

    event NewPool(uint256 indexed pid, uint256 maxNum, uint256 startBlock, uint256 endBlock, uint256 limitPerAccount);
    event ChangePoolMaxAndLimit(uint256 indexed pid, uint256 maxNum, uint256 limitPerAccount);
    event WhiteListed(uint256 indexed pid, address indexed account, uint256 offerPrice);
    event RemoveWhiteList(uint256 indexed pid, address account);
    event MintNFT(uint256 indexed pid, address indexed account, uint256 tokenId, uint256 payAmount);
    event NewStartAndEndBlocks(uint256 indexed pid, uint256 startBlock, uint256 endBlock);
    event Withdraw(address indexed account, uint256 amount);

    constructor(IERC721 _nft) {
        nft = _nft;
    }

    function addPool(uint256 _maxNum, uint256 _startBlock, uint256 _endBlock, uint256 _limitPerAccount) external onlyOwner {
        require(_startBlock > block.number, "NFTFactory::addPool: New startBlock must be higher than current block");
        require(_startBlock < _endBlock, "NFTFactory::addPool: StartBlock must be lower than new endBlock");
        require(_limitPerAccount > 0, "NFTFactory::addPool: Limit per account must great than zero");
        require(_maxNum > 0, "NFTFactory::addPool: Max num must be higher than zero");
        require(totalSupply() <= MAXIMUM, "NFTFactory::addPool: Max num cap exceeded");

        pools.push(PoolInfo({
        maxNum : _maxNum,
        supply : 0,
        startBlock : _startBlock,
        endBlock : _endBlock,
        limitPerAccount : _limitPerAccount
        }));

        emit NewPool(pools.length.sub(1), _maxNum, _startBlock, _endBlock, _limitPerAccount);
    }

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory) {
        return pools[_pid];
    }

    function userInfo(uint256 _pid, address account) external view returns (UserInfo memory) {
        return users[_pid][account];
    }

    function poolLength() external view returns (uint256) {
        return pools.length;
    }

    function mintNFT(uint256 _pid, uint256 _num) external payable nonReentrant {
        address account = _msgSender();
        PoolInfo storage poolInfo = pools[_pid];
        require(block.number >= poolInfo.startBlock, "NFTFactory::mintNFT: Too early");
        require(block.number < poolInfo.endBlock, "NFTFactory::mintNFT: Too late");
        require(_num > 0, "NFTFactory:mintNFT: num must be great than zero");
        require(poolInfo.supply.add(_num) <= poolInfo.maxNum, "NFTFactory:mintNFT: Pool cap exceeded");
        require(totalSupply().add(_num) <= MAXIMUM, "NFTFactory:mintNFT: Cap exceeded");

        UserInfo storage userinfo = users[_pid][account];
        require(userinfo.whitelist, "NFTFactory::mintNFT: Not in whitelist");
        require(userinfo.claimedNum.add(_num) <= poolInfo.limitPerAccount, "NFTFactory::mintNFT: Has claimed all");
        require(userinfo.offerPrice.mul(_num) == msg.value, "NFTFactory::mintNFT: Ask amount error");

        for (uint256 i = 0; i < _num; i++) {
            uint256 remain = MAXIMUM.sub(totalSupply());
            uint256 tokenId = nextTokenId(remain, account);

            poolInfo.supply = poolInfo.supply.add(1);
            userinfo.claimedNum = userinfo.claimedNum.add(1);
            nft.safeMint(account, tokenId);

            emit MintNFT(_pid, account, tokenId, msg.value);
        }
    }

    function mintAirdrop(uint256 _pid, address[] calldata _accounts) external onlyOwner {
        PoolInfo storage poolInfo = pools[_pid];
        require(block.number >= poolInfo.startBlock, "NFTFactory::mintAirdrop: Too early");
        require(block.number < poolInfo.endBlock, "NFTFactory::mintAirdrop: Too late");
        require(_accounts.length > 0, "NFTFactory::mintAirdrop: Accounts is empty");
        require(poolInfo.supply.add(_accounts.length) <= poolInfo.maxNum, "NFTFactory:mintAirdrop: Pool cap exceeded");
        require(totalSupply().add(_accounts.length) <= MAXIMUM, "NFTFactory:mintAirdrop: Cap exceeded");
        // poolInfo.limitPerAccount unused

        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            uint256 remain = MAXIMUM.sub(totalSupply());
            uint256 tokenId = nextTokenId(remain, account);

            UserInfo storage userinfo = users[_pid][account];
            poolInfo.supply = poolInfo.supply.add(1);
            userinfo.claimedNum = userinfo.claimedNum.add(1);
            nft.safeMint(account, tokenId);

            emit MintNFT(_pid, account, tokenId, 0);
        }
    }

    function nextTokenId(uint256 max, address recipient) internal returns (uint256) {
        uint256 supply = totalSupply();
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    recipient,
                    block.difficulty,
                    supply,
                    block.coinbase,
                    block.timestamp,
                    blockhash(block.number),
                    block.gaslimit,
                    block.coinbase.balance
                )
            )
        ) % max;
        uint256 tokenId = 0;
        if (tokenMatrix[random] == 0) {
            tokenId = random;
        } else {
            tokenId = tokenMatrix[random];
        }

        if (tokenMatrix[max - 1] == 0) {
            tokenMatrix[random] = max - 1;
        } else {
            tokenMatrix[random] = tokenMatrix[max - 1];
        }
        return tokenId;
    }

    function setPoolMaxNumAndLimit(uint256 _pid, uint256 _maxNum, uint256 _limitPerAccount) external onlyOwner {
        require(_limitPerAccount > 0, "NFTFactory::setPoolMaxNumAndLimit: Limit must great than zero");
        require(_maxNum > 0, "NFTFactory::setPoolMaxNumAndLimit: Max num must be higher than zero");
        require(_maxNum >= pools[_pid].supply, "NFTFactory::setPoolMaxNumAndLimit: Max num cap exceeded");
        pools[_pid].maxNum = _maxNum;
        pools[_pid].limitPerAccount = _limitPerAccount;

        emit ChangePoolMaxAndLimit(_pid, _maxNum, _limitPerAccount);
    }

    function setPoolWhitelistAndPrice(uint256 _pid, address[] calldata _accounts, uint256[] calldata _price) external onlyOwner {
        require(block.number < pools[_pid].startBlock, "NFTFactory::setPoolWhitelistAndPrice: Has started");
        require(_accounts.length == _price.length, "NFTFactory::setPoolWhitelistAndPrice: Account price error");

        for (uint256 i = 0; i < _accounts.length; i++) {
            _setPoolWhitelistAndPrice(_pid, _accounts[i], _price[i]);
        }
    }

    function removePoolWhitelist(uint256 _pid, address[] calldata _accounts) external onlyOwner {
        require(block.number < pools[_pid].startBlock, "NFTFactory::setPoolWhitelistAndPrice: Has started");
        for (uint256 i = 0; i < _accounts.length; i++) {
            UserInfo storage userinfo = users[_pid][_accounts[i]];
            userinfo.whitelist = false;

            emit RemoveWhiteList(_pid, _accounts[i]);
        }
    }

    function _setPoolWhitelistAndPrice(uint256 _pid, address _account, uint256 _price) internal {
//        require(_price > 0, "NFTFactory::setPoolPrice: Invalid price");
        UserInfo storage userinfo = users[_pid][_account];
        userinfo.whitelist = true;
        userinfo.offerPrice = _price;

        emit WhiteListed(_pid, _account, _price);
    }

    function setPoolStartAndEnd(uint256 _pid, uint256 _startBlock, uint256 _endBlock) external onlyOwner {
        require(block.number < pools[_pid].startBlock, "NFTFactory::addPool: Has started");
        require(block.number < _startBlock, "NFTFactory::addPool: New startBlock must be higher than current block");
        require(_startBlock < _endBlock, "NFTFactory::addPool: StartBlock must be lower than new endBlock");

        pools[_pid].startBlock = _startBlock;
        pools[_pid].endBlock = _endBlock;

        emit NewStartAndEndBlocks(_pid, _startBlock, _endBlock);
    }

    function totalMaxNum() public view returns (uint256) {
        uint256 maxNum;
        for (uint256 i = 0; i < pools.length; i++) {
            maxNum = maxNum.add(pools[i].maxNum);
        }
        return maxNum;
    }

    function totalSupply() public view returns (uint256) {
        uint256 supply;
        for (uint256 i = 0; i < pools.length; i++) {
            supply = supply.add(pools[i].supply);
        }
        return supply;
    }

    function withdrawETH() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success,) = msg.sender.call{value : balance}("");
        require(success, "Transfer failed");

        emit Withdraw(msg.sender, balance);
    }
}