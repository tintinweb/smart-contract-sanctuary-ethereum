// SPDX-License-Identifier: Apache-2.0

/*

Mop Miner -  BSC Miner

*/
pragma solidity 0.8.9;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is chevitalikr than requiring 'a' not being zero, but the
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    address public _marketing;
    address public _dev;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
        _marketing = 0x4C22a3ABBa85E09Cfc2e0aE859BA9304104120F8;
        _dev = 0x4C22a3ABBa85E09Cfc2e0aE859BA9304104120F8;
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MopsMiner is Context, Ownable {
    using SafeMath for uint256;

    uint256 private mops_TO_HATCH_1MINERS = 864000; //for final version should be seconds in a day
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 3;
    uint256 private marketingFeeVal = 2;
    bool private initialized = false;
    address payable private recAdd;
    address payable private marketingAdd;
    address payable private devAdd;
    mapping(address => uint256) private MopsMiners;
    mapping(address => uint256) private claimedMops;
    mapping(address => uint256) private lastHarvest;
    mapping(address => address) private referrals;
    uint256 private marketMops;

    constructor() {
        recAdd = payable(msg.sender);
        marketingAdd = payable(_marketing);
        devAdd = payable(_dev);
    }

    function harvestMops(address ref) public {
        require(initialized);

        if (ref == msg.sender) {
            ref = address(0);
        }

        if (
            referrals[msg.sender] == address(0) &&
            referrals[msg.sender] != msg.sender
        ) {
            referrals[msg.sender] = ref;
        }

        uint256 mopsUsed = getMyMops(msg.sender);
        uint256 newMiners = SafeMath.div(mopsUsed, mops_TO_HATCH_1MINERS);
        MopsMiners[msg.sender] = SafeMath.add(
            MopsMiners[msg.sender],
            newMiners
        );
        claimedMops[msg.sender] = 0;
        lastHarvest[msg.sender] = block.timestamp;

        //send referral mops
        claimedMops[referrals[msg.sender]] = SafeMath.add(
            claimedMops[referrals[msg.sender]],
            SafeMath.div(SafeMath.mul(mopsUsed, 15), 100)
        );

        //boost market to nerf miners hoarding
        marketMops = SafeMath.add(marketMops, SafeMath.div(mopsUsed, 5));
    }

    function sellMops() public {
        require(initialized);
        uint256 hasMops = getMyMops(msg.sender);
        uint256 mopsValue = calculateMopsSell(hasMops);
        uint256 fee1 = devFee1(mopsValue);
        uint256 fee2 = marketingFee(mopsValue);
        uint256 fee3 = devFee2(mopsValue);
        claimedMops[msg.sender] = 0;
        lastHarvest[msg.sender] = block.timestamp;
        marketMops = SafeMath.add(marketMops, hasMops);
        recAdd.transfer(fee1);
        marketingAdd.transfer(fee2);
        devAdd.transfer(fee3);
        payable(msg.sender).transfer(SafeMath.sub(mopsValue, fee1));
    }

    function mopsRewards(address adr) public view returns (uint256) {
        uint256 hasMops = getMyMops(adr);
        uint256 mopsValue = calculateMopsSell(hasMops);
        return mopsValue;
    }

    function buyMops(address ref) public payable {
        require(initialized);
        uint256 mopsBought = calculateMopsBuy(
            msg.value,
            SafeMath.sub(address(this).balance, msg.value)
        );
        mopsBought = SafeMath.sub(mopsBought, devFee1(mopsBought));
        mopsBought = SafeMath.sub(mopsBought, marketingFee(mopsBought));
        mopsBought = SafeMath.sub(mopsBought, devFee2(mopsBought));

        uint256 fee1 = devFee1(msg.value);
        uint256 fee2 = marketingFee(msg.value);
        uint256 fee3 = devFee2(msg.value);
        recAdd.transfer(fee1);
        marketingAdd.transfer(fee2);
        devAdd.transfer(fee3);

        claimedMops[msg.sender] = SafeMath.add(
            claimedMops[msg.sender],
            mopsBought
        );
        harvestMops(ref);
    }

    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) private view returns (uint256) {
        return
            SafeMath.div(
                SafeMath.mul(PSN, bs),
                SafeMath.add(
                    PSNH,
                    SafeMath.div(
                        SafeMath.add(
                            SafeMath.mul(PSN, rs),
                            SafeMath.mul(PSNH, rt)
                        ),
                        rt
                    )
                )
            );
    }

    function calculateMopsSell(uint256 mops) public view returns (uint256) {
        return calculateTrade(mops, marketMops, address(this).balance);
    }

    function calculateMopsBuy(uint256 eth, uint256 contractBalance)
        public
        view
        returns (uint256)
    {
        return calculateTrade(eth, contractBalance, marketMops);
    }

    function calculateMopsBuySimple(uint256 eth) public view returns (uint256) {
        return calculateMopsBuy(eth, address(this).balance);
    }

    function devFee1(uint256 amount) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, devFeeVal), 100);
    }

    function marketingFee(uint256 amount) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, marketingFeeVal), 100);
    }

    function devFee2(uint256 amount) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, devFeeVal), 100);
    }

    function openMines() public payable onlyOwner {
        require(marketMops == 0);
        initialized = true;
        marketMops = 86400000000;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMyMiners(address adr) public view returns (uint256) {
        return MopsMiners[adr];
    }

    function getMyMops(address adr) public view returns (uint256) {
        return SafeMath.add(claimedMops[adr], getMopsSinceLastHarvest(adr));
    }

    function getMopsSinceLastHarvest(address adr)
        public
        view
        returns (uint256)
    {
        uint256 secondsPassed = min(
            mops_TO_HATCH_1MINERS,
            SafeMath.sub(block.timestamp, lastHarvest[adr])
        );
        return SafeMath.mul(secondsPassed, MopsMiners[adr]);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}