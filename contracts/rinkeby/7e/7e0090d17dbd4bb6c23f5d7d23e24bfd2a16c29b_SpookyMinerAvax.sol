/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

/**
 *Submitted for verification at snowtrace.io on 2022-04-15
*/

// SPDX-License-Identifier: MIT

/*
 
  .-')     _ (`-.                           .-. .-')                      _   .-')                 .-') _   ('-.  _  .-')   
 ( OO ).  ( (OO  )                          \  ( OO )                    ( '.( OO )_              ( OO ) )_(  OO)( \( -O )  
(_)---\_)_.`     \ .-'),-----.  .-'),-----. ,--. ,--.   ,--.   ,--.       ,--.   ,--.) ,-.-') ,--./ ,--,'(,------.,------.  
/    _ |(__...--''( OO'  .-.  '( OO'  .-.  '|  .'   /    \  `.'  /        |   `.'   |  |  |OO)|   \ |  |\ |  .---'|   /`. ' 
\  :` `. |  /  | |/   |  | |  |/   |  | |  ||      /,  .-')     /         |         |  |  |  \|    \|  | )|  |    |  /  | | 
 '..`''.)|  |_.' |\_) |  |\|  |\_) |  |\|  ||     ' _)(OO  \   /          |  |'.'|  |  |  |(_/|  .     |/(|  '--. |  |_.' | 
.-._)   \|  .___.'  \ |  | |  |  \ |  | |  ||  .   \   |   /  /\_         |  |   |  | ,|  |_.'|  |\    |  |  .--' |  .  '.' 
\       /|  |        `'  '-'  '   `'  '-'  '|  |\   \  `-./  /.__)        |  |   |  |(_|  |   |  | \   |  |  `---.|  |\  \  
 `-----' `--'          `-----'      `-----' `--' '--'    `--'             `--'   `--'  `--'   `--'  `--'  `------'`--' '--' 
                 
Spooky Miner - Fantom FTM Miner
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

pragma solidity 0.8.9;

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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract SpookyMinerAvax is Context, Ownable {
    using SafeMath for uint256;

    uint256 private BONES_TO_HATCH_1MINER = 1080000;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private feeValBuy = 2;
    uint256 private feeValSell = 6;
    bool private initialized = false;
    address payable private recAdd;
    mapping(address => uint256) private skeletonMiners;
    mapping(address => uint256) private claimedBones;
    mapping(address => uint256) private lastHatch;
    mapping(address => address) private referrals;
    uint256 private marketBones;

    constructor() {
        recAdd = payable(msg.sender);
    }

    function hatchBones(address ref) public {
        require(initialized);

        if (ref == msg.sender) {
            ref = address(0);
        }

        if (referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }

        uint256 bonesUsed = getMyBones(msg.sender);
        uint256 newMiners = SafeMath.div(bonesUsed, BONES_TO_HATCH_1MINER);
        skeletonMiners[msg.sender] = SafeMath.add(skeletonMiners[msg.sender], newMiners);
        claimedBones[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;

        //send referral eggs
        claimedBones[referrals[msg.sender]] = SafeMath.add(claimedBones[referrals[msg.sender]], SafeMath.div(bonesUsed, 8));

        //boost market to nerf miners hoarding
        marketBones = SafeMath.add(marketBones, SafeMath.div(bonesUsed, 5));
    }

    function sellBones() public {
        require(initialized);
        uint256 currentBones = getMyBones(msg.sender);
        uint256 boneValue = calculateBonesSell(currentBones);
        uint256 fee = feeSell(boneValue);
        claimedBones[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketBones = SafeMath.add(marketBones, currentBones);
        recAdd.transfer(fee);
        payable(msg.sender).transfer(SafeMath.sub(boneValue, fee));
    }

    function boneRewards(address adr) public view returns (uint256) {
        uint256 hasEggs = getMyBones(adr);
        uint256 eggValue = calculateBonesSell(hasEggs);
        return eggValue;
    }

    function buyBones(address ref) public payable {
        require(initialized);
        uint256 bonesBought = calculateBonesBuy(msg.value, SafeMath.sub(address(this).balance, msg.value));
        bonesBought = SafeMath.sub(bonesBought, feeBuy(bonesBought));
        uint256 fee = feeBuy(msg.value);
        recAdd.transfer(fee);
        claimedBones[msg.sender] = SafeMath.add(claimedBones[msg.sender], bonesBought);
        hatchBones(ref);
    }

    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
    }

    function calculateBonesSell(uint256 eggs) public view returns (uint256) {
        return calculateTrade(eggs, marketBones, address(this).balance);
    }

    function calculateBonesBuy(uint256 eth, uint256 contractBalance) public view returns (uint256) {
        return calculateTrade(eth, contractBalance, marketBones);
    }

    function calculateBonesBuySimple(uint256 eth) public view returns (uint256) {
        return calculateBonesBuy(eth, address(this).balance);
    }

    function feeSell(uint256 amount) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, feeValSell), 100);
    }

    function feeBuy(uint256 amount) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, feeValBuy), 100);
    }

    function seedMarket() public payable onlyOwner {
        require(marketBones == 0);
        initialized = true;
        marketBones = 108000000000;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMyMiners(address adr) public view returns (uint256) {
        return skeletonMiners[adr];
    }

    function getMyBones(address adr) public view returns (uint256) {
        return SafeMath.add(claimedBones[adr], getBonesSinceLastHatch(adr));
    }

    function getBonesSinceLastHatch(address adr) public view returns (uint256) {
        uint256 secondsPassed = min(BONES_TO_HATCH_1MINER, SafeMath.sub(block.timestamp, lastHatch[adr]));
        return SafeMath.mul(secondsPassed, skeletonMiners[adr]);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}