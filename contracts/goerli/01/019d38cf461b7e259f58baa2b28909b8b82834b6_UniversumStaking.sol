/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A {

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
}

/**
 * @dev ERC721 token receiver interface.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC20 {
    function mint(address to, uint256 amount) external;
}

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

contract UniversumStaking is Ownable {
    IERC20 public UM;
    IERC721A public NFT; 
    using SafeMath for uint;

    //Rate for counting UM per day. This is UM/sec for 1 UM 
    uint public stakingRate = 11574074074074;

    //The price for the count score of city on server
    uint public priceForStakeUnstake = 100;

    //An manage address for server app
    address private manager;

    //Staking time for all NFT which holds on smart contract
    mapping(address=>uint) public stakingTime;

    //Keeping an address who staked NFT
    mapping(uint=>address) public stakedIdOwner;

    //Total sсor for whole city
    mapping(address=>uint) public cityScore;

    //Event for the server application, it starting counting and writing data
    event UpdateScore(address _adr);

    //Stake one a NFT
    function stakeSingle(uint _id) payable public {
        //Checks value this tx, that needs spending of team  for server function updateScore
        require(msg.value >= priceForStakeUnstake);
        //Checks haves NFT or no on address
        if(cityScore[msg.sender] != 0) {
            //Claim the profit
            UM.mint(msg.sender, getProfit());
        }

        //Transfer NFT to contract address
        NFT.transferFrom(msg.sender, address(this), _id);
        //Sets owner an address for withdraw a NFT
        stakedIdOwner[_id] = msg.sender;
        //Sets time for count a staking time
        stakingTime[msg.sender] = block.timestamp;
        //Emits event for the chain logs. It for count current city score
        emit UpdateScore(msg.sender);
    }

    //Stake some NFTs
    function stakeMulti(uint[] memory _id) payable public {
        //Checks value this tx, that needs spending of team  for server function updateScore
        require(msg.value >= priceForStakeUnstake);
        //Checks haves NFT or no on address
        if(cityScore[msg.sender] != 0) {
            //Claim the profit
            UM.mint(msg.sender, getProfit());
        }

        for (uint i=0; i<_id.length; i++) {
            //Transfer NFT to contract address
            NFT.transferFrom(msg.sender, address(this), _id[i]);
            //Sets owner an address for withdraw a NFT
            stakedIdOwner[_id[i]] = msg.sender;
        }
        //Sets time for count staking time
        stakingTime[msg.sender] = block.timestamp;
        //Emits event for the chain logs. It for count current city score
        emit UpdateScore(msg.sender);
    }
 
    //Unstake one a NFT
    function unstakeSingle(uint _id) payable public {
        //Checks value this tx, that needs spending of team  for server function updateScore
        require(msg.value >= priceForStakeUnstake);
        //Checks who owner staked nft, sender or no
        require(stakedIdOwner[_id] == msg.sender);
        //Claim the profit
        claim(msg.sender);
        //Transfer NFT from the contract address to user address
        NFT.transferFrom(address(this), msg.sender, _id);
        //Emits event for the chain logs. It for count current city score
        emit UpdateScore(msg.sender);
    }

    //Unstake some NFTs
    function unstakeMulti(uint[] memory _id) payable public {
        //Checks value this tx, that needs spending of team  for server function updateScore
        require(msg.value >= priceForStakeUnstake);
        //Claim the profit
        claim(msg.sender);
        
        for (uint i=0; i<_id.length; i++) {
            //Checks who owner staked nft, sender or no
            require(stakedIdOwner[_id[i]] == msg.sender);
            //Transfer NFT from the contract address to user address
            NFT.transferFrom(address(this), msg.sender, _id[i]);
        }
        //Emits event for the chain logs. It for count current city score
        emit UpdateScore(msg.sender);
    }

    //Counts profit by safeMath library. Profit = (time - stakingTime) * (stakingRate * score);
    function getProfit() view public returns (uint) {
        uint _time = SafeMath.sub(block.timestamp, stakingTime[msg.sender]);
        uint _umPerSec = SafeMath.mul(stakingRate, cityScore[msg.sender]);
        return SafeMath.mul(_time, _umPerSec);
    }

    //Claim UM tokens
    function claim(address _to) public {
        require(cityScore[msg.sender] != 0, "Our city don't has staked blocks");
        UM.mint(_to, getProfit());
        stakingTime[msg.sender] = block.timestamp;
    }

    //Adds total score for city, access to the manager
    function setScoreForManager(address _adr, uint _score) public {
        require(msg.sender == manager);
        cityScore[_adr] = _score;
    }

    //ADMIN FUNCTIONS:
    //Set total score for city, admin access
    function setScoreForAdmin(address _adr, uint _score) public onlyOwner {
        cityScore[_adr] = _score;
    }

    //Sets a manger for server app
    function setManager(address _manager) public onlyOwner {
        manager = _manager;
    }

    //Sets price for stake/unstake
    function setPriceForStakeUnstake(uint _price) public onlyOwner {
       priceForStakeUnstake = _price;
    }

    //Sets address for ERC20 UM tokens
    function setUMContractERC20(IERC20 _erc20) public onlyOwner {
       UM = _erc20;
    }

    //Sets address for NFT UM tokens
    function setUMContractNFT(IERC721A _erc721) public onlyOwner {
       NFT = _erc721;
    }
}