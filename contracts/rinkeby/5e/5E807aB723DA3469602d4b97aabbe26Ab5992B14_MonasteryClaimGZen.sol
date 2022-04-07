// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IERC721.sol";

contract MonasteryClaimGZen is Ownable {
    using SafeMath for *;
    struct Info {
        address user; // user address
        uint payout; // gZen amount will be claimed
        uint nftNumber; // amount of nft that user staked
        uint lastTimestamp; // Last interaction
    }

    struct stopTime {
        bool stop;
        uint256 lastTimestamp;
    }

    address public gZen;
    address public NFTToken;
    uint256 public tokenPerNFT;
    uint256 public StakedTimePerToken;
    uint256 public maxYield = 5;
    mapping( uint256 => address ) public NFTClaimed; // checking claimed nft
    mapping( uint256 => address ) public NFTStaked; // checking nft staked
    stopTime public stopTimeInfo;
    mapping( address => Info ) public StakedInfo;
    uint256 public maxTokenYield;
    uint256 public maxTokenClaim;
    uint256 public tokenClaimedAmount = 0;
    uint256 public tokenYieldedAmount = 0;
    Info public estimatedTokenYield;

    constructor (address _NFTTokenAddress, uint _tokenPerNFT) {
        require( _NFTTokenAddress != address(0) );
        NFTToken = _NFTTokenAddress;
        require(_tokenPerNFT > 0, "its not positive");
        tokenPerNFT = _tokenPerNFT;
        estimatedTokenYield = Info({
        user: msg.sender,
        payout: 0,
        nftNumber: 0,
        lastTimestamp: block.timestamp
        });

        stopTimeInfo = stopTime({
        stop: false,
        lastTimestamp: 0
        });
    }

    function setMaxYield(uint _max) external onlyOwner {
        maxYield = _max;
    }


    function setMaxTokenYield (uint256 _maxTokenYield) external onlyOwner {
        maxTokenYield = _maxTokenYield;
    }

    function setMaxTokenClaim (uint256 _maxTokenClaim) external onlyOwner {
        maxTokenClaim = _maxTokenClaim;
    }

    function setToken (address _gZen) external onlyOwner {
        require( _gZen != address(0) );
        gZen = _gZen;
    }

    function setStop(bool stop, uint time) external onlyOwner {
        stopTimeInfo.stop = stop;
        if (stop) {
            stopTimeInfo.lastTimestamp = block.timestamp;
        }
        if (time > 0 && time > block.timestamp) {
            stopTimeInfo.lastTimestamp = time;
        }
    }

    function setNFTToken(address NFTTokenAddress) external onlyOwner {
        require(NFTTokenAddress != address(0), "its zero address");
        NFTToken = NFTTokenAddress;
    }

    function setStakedTimePerToken(uint _StakedTimePerToken) external onlyOwner {
        require(_StakedTimePerToken != 0, "should not be zero");
        StakedTimePerToken = _StakedTimePerToken;
    }

    function setTokenPerNFT(uint256 _tokenPerNFT) external onlyOwner {
        require(_tokenPerNFT > 0, "its not positive");
        tokenPerNFT = _tokenPerNFT;
    }

    function claimPerNFT(uint256 _nftIndex) external {
        address ownerOfNFT = IERC721(NFTToken).ownerOf(_nftIndex);
        require(ownerOfNFT == msg.sender, "you are not the owner");
        require(NFTClaimed[_nftIndex] == address(0), "already claimed");
        require(tokenClaimedAmount < maxTokenClaim, "claimed amount exceeded" );
        NFTClaimed[_nftIndex] = msg.sender;
        tokenClaimedAmount += tokenPerNFT;
        IERC20Mintable(gZen).mint(msg.sender, tokenPerNFT.mul(1e9));
    }

    function estimateYields() public {
        Info memory _info = estimatedTokenYield;
        uint dif;
        uint time;
        if (stopTimeInfo.stop){
            dif = stopTimeInfo.lastTimestamp.sub(_info.lastTimestamp);
            time = stopTimeInfo.lastTimestamp;
        } else {
            dif = block.timestamp.sub(_info.lastTimestamp);
            time = block.timestamp;
        }
        uint reward = dif.mul(1e9).div(StakedTimePerToken).mul(_info.nftNumber);
        estimatedTokenYield = Info({
        user: _info.user,
        payout: _info.payout.add(reward),
        nftNumber: _info.nftNumber,
        lastTimestamp: time
        });
        checkStop();
    }

    function viewEstimateYields() public view returns (Info memory) {
        Info memory _info = estimatedTokenYield;
        uint dif;
        uint time;
        if (stopTimeInfo.stop) {
            dif = stopTimeInfo.lastTimestamp.sub(_info.lastTimestamp);
            time = stopTimeInfo.lastTimestamp;
        } else {
            dif = block.timestamp.sub(_info.lastTimestamp);
            time = block.timestamp;
        }
        uint reward = dif.mul(1e9).div(StakedTimePerToken).mul(_info.nftNumber);
        return Info({
        user: _info.user,
        payout: _info.payout.add(reward),
        nftNumber: _info.nftNumber,
        lastTimestamp: time
        });
    }

    function StakeNFT(uint256 _nftIndex) external {
        require(NFTStaked[_nftIndex] == address(0), "this nft already staked");
        require(!stopTimeInfo.stop, "max exceeded");
        NFTStaked[_nftIndex] = msg.sender;
        estimateYields();
        estimatedTokenYield.nftNumber += 1 ;
        syncStake(true, msg.sender);
        IERC721(NFTToken).transferFrom(msg.sender, address(this), _nftIndex);

    }

    function unstake(uint _nftIndex) public {
        require(NFTStaked[_nftIndex] == msg.sender, "you didnt staked this nft");
        estimateYields();
        estimatedTokenYield.nftNumber -=1;
        delete NFTStaked[_nftIndex];
        syncStake(false, msg.sender);
        IERC721(NFTToken).transferFrom(address(this), msg.sender, _nftIndex);
    }

    function syncStake(bool add, address _user) private {
        Info memory _info = StakedInfo[_user];
        uint dif;
        uint time;
        if (stopTimeInfo.stop){
            dif = stopTimeInfo.lastTimestamp.sub(_info.lastTimestamp);
            time = stopTimeInfo.lastTimestamp;
        }else{
            dif = block.timestamp.sub(_info.lastTimestamp);
            time = block.timestamp;
        }
        uint _payout = dif.div(StakedTimePerToken).mul(_info.nftNumber);
        if (add == true) {
            require(_info.nftNumber != maxYield,"nft staked number exceeded");
            StakedInfo[_user] = Info({
            user: _user,
            payout: _info.payout.add(_payout),
            nftNumber: _info.nftNumber.add(1),
            lastTimestamp: time
            });
        } else {
            require(_info.nftNumber != 0,"nft staked number exceeded");
            StakedInfo[_user] = Info({
            user: _user,
            payout: _info.payout.add(_payout),
            nftNumber: _info.nftNumber.sub(1),
            lastTimestamp: time
            });
        }
    }

    function syncPayout() public {
        Info memory _info = StakedInfo[msg.sender];
        uint dif;
        uint time;
        estimateYields();
        if (stopTimeInfo.stop){
            dif = stopTimeInfo.lastTimestamp.sub(_info.lastTimestamp);
            time = stopTimeInfo.lastTimestamp;
        } else {
            dif = block.timestamp.sub(_info.lastTimestamp);
            time = block.timestamp;
        }
        uint _payout = dif.div(StakedTimePerToken).mul(_info.nftNumber);
        StakedInfo[msg.sender] = Info({
        user: msg.sender,
        payout: _info.payout.add(_payout),
        nftNumber: _info.nftNumber,
        lastTimestamp: time
        });
    }

    function claimPayout() public {
        syncPayout();
        Info memory _info = StakedInfo[msg.sender];
        require(_info.payout > 0, "you dont have any payout");
        StakedInfo[msg.sender].payout = 0;
        tokenYieldedAmount += _info.payout;
        IERC20Mintable(gZen).mint(msg.sender, _info.payout.mul(1e9));
    }

    function viewPayout() public view returns ( Info memory) {
        uint dif;
        uint time;
        Info memory _info = StakedInfo[msg.sender];
        if (stopTimeInfo.stop){
            dif = stopTimeInfo.lastTimestamp.sub(_info.lastTimestamp);
            time = stopTimeInfo.lastTimestamp;
        }else{
            dif = block.timestamp.sub(_info.lastTimestamp);
            time = block.timestamp;
        }
        uint _payout = dif.div(StakedTimePerToken).mul(_info.nftNumber);

        return Info({
        user: msg.sender,
        payout: _info.payout.add(_payout),
        nftNumber: _info.nftNumber,
        lastTimestamp: time
        });
    }

    function checkStop() public {
        if(maxTokenYield.mul(1e9) < estimatedTokenYield.payout && !stopTimeInfo.stop) {
            stopTimeInfo = stopTime({
            stop: true,
            lastTimestamp: block.timestamp
            });
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IERC20Mintable {
  function mint( uint256 amount_ ) external;

  function mint( address account_, uint256 ammount_ ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.0;
interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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