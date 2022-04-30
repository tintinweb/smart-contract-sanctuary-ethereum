import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMWWNNNNXXX0KKKKKKKKKKKKKKKKXXNWWMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMWNXKK00KKKKKKKKKKKKKKKKKKKKKKKKKKKXNWMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMWNNNXKK000000KKKKKKKK0KKKK00KKKKKKKKKK00KXNWMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMWNXKKKKKKKK0000KKKKKK0000KK0000KKKKKKKKKKKKKKKKXNWMMMMMMMMMMMMMMMMMM
//MMMMMMMMMWNKK0OO0K00KKKKKKK00KKKK000KKK0000KKKKKKKKKKKKKKKKKKXNNWMMMMMMMMMMMMMMM
//MMMMMMMMNK00Oxdd0K0KKKK00KKKKKKKK00KKKKKKKKKKKKKKKKKK0KKKKKKKKKKKXWMMMMMMMMMMMMM
//MMMMMMMNK0Oxoolx0K000KK00KKKK00KKKKKKKKK0KKKKKKKKKKKKKKKKKKKKKKKK0KXWMMMMMMMMMMM
//MMMMMMWX0kolollxKK000KKKKK0KKK0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKkodOKNWMMMMMMMMM
//MMMMMMNKkolooolx0KKKK0KK000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00KKKo';k00KNMMMMMMMM
//MMMMMWXOxlllllld0KKK00K00KKKKKKKKKKKKKKKKK0KKKKK00KKKKKKKKKKKKKKd',x0000XWMMMMMM
//MMMMMN0xocccccclOK00OO00KKK000KKKKK00KKKKKKKKKKK0KKKKKKKKKKKK0KKx,,okxxxx0WMMMMM
//MMMMMNOxocccccclkKOolldOK000K000KKKKKKK0000KKKK000KK0KKKKKKK00KXk;'lkxxxxkXMMMMM
//MMMMMXkxdcccccccxKOoccoOKKK00KKK0KKKKKKKKKK00KKKK0KK00KKKKKKKKKKOl:oxxxxxkXMMMMM
//MMMMMKxxdcccccccd00dcclOK0KKKKKKKKKKKKKKKKKK0KKKKKK00KKKKKKKKKKK0xxxdxxxxxKWMMMM
//MMMMMKxxdcccccccd0KxlclkK00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00KKKKK0kxxxxxxxx0WMMMM
//MMMMMKxdoccccccco0KklclkKKKKKKKKKKKKKKK00KKKKKKKKKKKKKKKKKKKKKKXKkxxxxxxxdONMMMM
//MMMMMKkxdlccccc:lOKOoclx0KKKKKKKKKKKKKKKKKXKKKKKKKKKKKKKKKKKKKKKKkxxxxxxxxONMMMM
//MMMMMKxxxlccccc:lkX0dclx0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0kxkkxxxxxkNMMMM
//MMMMMXxdxl:ccccccxKKxlcd0KKKKKKKKK0KKKKKKKKKKKKKKKKKKKKKKKKKKK0K0kxkkkxxxxkNMMMM
//MMMMMXxddoc:cccccx0Kklcd0KKKKKKKKKKKKKKKKKKKKKKKK0KKKKKKKKKKKKKKKxclxxddxxkXMMMM
//MMMMMNkdxoccc:cc:d0KOocoOK0KKKKKKKKKKKKK0KKKKKKKKKKKKKKKKKKKKKKXKo';dkddxxkXMMMM
//MMMMMNOdxdcccccc:o0X0dclOK0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0o';dkxxxdkNMMMM
//MMMMMWOdxdlccccc:lOKKOxk0KKKKKKKKKKK0KKKKKK00KKKKKKKKKK0KKKKKKKK0o';oxxxxxONMMMM
//MMMMMW0xxdlcccccclkK000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0KKKKKKKKKo',oxxkxxONMMMM
//MMMMMMXxxxoccccccckKKKKKKKKKKKKKKKKKKKKK00KKKKKKKKKKKKKKKKKKKKKXKdcldxxxxxONMMMM
//MMMMMMNOxxocccccccxKKKKKKK00KKKKKKKKKKK00KKKKKKKKKKKKKKKKK0KKKK0kxkkxxkxxx0WMMMM
//MMMMMMN0xxdlcccccco0KKKKKKKKKKKKKKKK0KKKKKKKKKKKKKKKKKKKKKKKK0Okxxxxxxkxxx0WMMMM
//MMMMMMWKkkxxxdddddodkOOOOOOOOOOO000OOOOOOOOOOOOOOkkkkkkxxkkOkkkkkkddxxddod0WMMMM
//MMMMMMMXkxkkkkkkkkkxxxddxxxxdxxkkkxxxxxxxxxxxxxxxxxdxxxdxxkkkOOkxxxxxxxddxKMMMMM
//MMMMMMMNkxkkkkkkkOkkkkxxkxxxkxxkkkxdodkkkkkkkkOOOOOOkOOO000000OxxkxxxkxxxOXMMMMM
//MMMMMMMW0xkkkkkkkkOkkkkkxkkOOkkOO0000000000000000000OO00K000KK0xxkkkxkkkkONMMMMM
//MMMMMMMMKkkOOOkxxddddddk00KKKK0KKKKK0K00K0000000000K0KKKK00KKKOookkkkkkkxONMMMMM
//MMMMMMMMXkxkxolc:::::cd0KKKKKKKKK00000KKK0000000000K000K00KKKKx,,dkxkkkkx0WMMMMM
//MMMMMMMMNOxdc::::::::d0Oxxxk0000K000KK00K000O000000K000KKKKKKKd',dxxxxkkxKWMMMMM
//MMMMMMMMW0xo:::::::::dOdcccoOK0000KK00KKK000000000KK00KKKKKKKKd';oddxxkkkKMMMMMM
//MMMMMMMMMKko:;:::::::oOxclclkK00000000KKKKK00K0000KK00K000KKKKo';dxxxxxxkXMMMMMM
//MMMMMMMMMXkdc;;;;;::;cOklcccx00000000K00000000K00000OO00000KK0d,:dxdodxxONMMMMMM
//MMMMMMMMMNkoc;;;;;;;;:xOocccd0000KKKK0000KK000K00KK0000K00K00KOdxxxxdxddOWMMMMMM
//MMMMMMMMMWOdl;;;,,,;;;oOdcccoO0K0KK00KK000KKKKK000KK00K000KK00Oxdddddxdd0WMMMMMM
//MMMMMMMMMMKdl:;;;,,,,,lOdcccoO0000KKK00000000000000000K0O0K000kxxddddddxKMMMMMMM
//MMMMMMMMMMXxoc;,;;;,,,ckklcclkOOOOOOOOO00000000000000000O00000kdddoooooxXMMMMMMM
//MMMMMMMMMMNkol;,,,,,,,:xOocclxOOOOOOO000000000000000KKK0000000koodoollokNMMMMMMM
//MMMMMMMMMMW0dd:;;;,,;;;oOxcccdO0OOO000000OO0000K0000KKKKKKK000kdoddooooOWMMMMMMM
//MMMMMMMMMMMKdoc;;;,;;;;lOklccdO00000000000O00KKK00KKKKKKKKKK00OdooddoooOWMMMMMMM
//MMMMMMMMMMMXxol;;;;;;;;ckOoccoO00KKK0000000KKKKKK0KKKKKKKKKKKKOdddddxdxXMMMMMMMM
//MMMMMMMMMMMWOdo:,;;;;;;;dOdccoO00KKK000KK0000KKK00KK000KKKKKKKOxddxkkxONMMMMMMMM
//MMMMMMMMMMMWKddl;;;;;;;;o0klcoO00K00000000000KKKKKKK00KKKKKK0K0kxxxkkx0WMMMMMMMM
//MMMMMMMMMMMMXxxdc;:::;;;l00oclk00000000000000000KKKK00KK000K00OxdodxxxKMMMMMMMMM
//MMMMMMMMMMMMNOxxl::::;;,:k0dclx0000000000000000000KK0000000000kddddddkXMMMMMMMMM
//MMMMMMMMMMMMWKxko:::::;,;x0xlcd00O0000000000000000K000000000KKOxxxxxxONMMMMMMMMM
//MMMMMMMMMMMMMXxxxc::::;;;dK0xok0K0000000000000000KK0000KKKK0Okkddxxxx0WMMMMMMMMM
//MMMMMMMMMMMMMXxdxl::::;,,o0K00KK0KK00000K000KKKK00K00K00KKKOc'lxxxxxkKMMMMMMMMMM
//MMMMMMMMMMMMMNOxxl::::::;cOKKKKKK00000000000000K00KKKKKKK0Kx;'lxdxxxONMMMMMMMMMM
//MMMMMMMMMMMMMMXkxd:;:;;:::xKKKKKKKKKKK0000K000KKKKKKKKKK00Kd',oxxddx0WMMMMMMMMMM
//MMMMMMMMMMMMMMNkddl:;;::;;dKKKKKKKKKKKK0000000KKKKKKKKKKKK0l':dxdddxKMMMMMMMMMMM
//MMMMMMMMMMMMMMW0dddoc::::;o0KKKK0KKKKKKKKKK00KKKKK0KKK00KKOl,lxxxxdkXMMMMMMMMMMM
//MMMMMMMMMMMMMMMXkkkkxdl:;;cOKKKK0KKKKKKKKKKKK000KK00KKKKKK00xxxxxxxOWMMMMMMMMMMM
//MMMMMMMMMMMMMMMNOxkkkxxdc::xKKKKKKKKKKKKKKKK0000KK00000KK0K0kdxxddkXMMMMMMMMMMMM
//MMMMMMMMMMMMMMMW0xxkkxxxdoodOKKKKKKKKKKKKKK000K00KK000K0KK0OxodxxkXMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMXxdxxxxxddddxO0K0K000KK000KKKK00000000000OkxkxxxKWMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMW0xxxxxxkxxddxk0K0000KKKKKKKK00K00000OkkkkkkkdxKWMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMWKOkxxxkxxxxxxkO0KKKKKKKKKKKKKK000Okxxxkkkxo:dNMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMNX0OkkxxxxxxxxkOOOOOOOOOOOOkOkkxxxdxkkk0x',OMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMWWKocllox0O0000000O0000000OxodddkO0KNWXodNMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMWd...,OMMMMMMMMMMMMMMMMWNo''.cKWWMMMMWWMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMXc..oNMMMMMMMMMMMMMMMMMMK:.'xWMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMM0;;0MMMMMMMMMMMMMMMMMMMWk,lXMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMMMMMMMMMMMMMMMMMMMWXNMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

contract Fridge is Context, Ownable {
    /*
        The Fridge takes in WETH and reinforces DC. This first version can buy
        DC and add DC-WETH LP for price stability.
    */

    IUniswapV2Pair dcPair;
    IUniswapV2Router02 uniRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address WETH;
    address DC;
    struct PriceReading { 
        uint128 dcWeth;
        uint128 block;
    }
    PriceReading reading1 = PriceReading(800000, 0);
    PriceReading reading2 = PriceReading(800000, 1); 
    address dev1;
    address dev2;
    uint32 lastWithdrawal;
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeMath for uint32;

    constructor (address DogCatcher, address pair) {
        DC = DogCatcher;
        dcPair = IUniswapV2Pair(pair);
        WETH = uniRouter.WETH();
        lastWithdrawal = uint32(block.timestamp);
        IERC20(WETH).approve(address(uniRouter), type(uint256).max);
        IERC20(DC).approve(address(uniRouter), type(uint256).max);
    }

    function setDevs(address new_dev1, address new_dev2) public onlyOwner() {
        // Operators who call the snack & preserve functions.
        dev1 = new_dev1;
        dev2 = new_dev2;
    }

    function updatePrice() external {
        // The DC/WETH exchange rate is recorded in two alternating buckets,
        // so the effective mint price is always taken from a prior block.
        (uint reserve0, uint reserve1,) = dcPair.getReserves();
        (uint256 wethReserves, uint256 dcReserves) = WETH < DC ? (reserve0, reserve1) : (reserve1, reserve0);
        uint128 new_dcWeth = uint128(dcReserves.mul(10**9) / wethReserves);
        if (reading1.block < reading2.block && reading2.block < block.number) {
            reading1.dcWeth = new_dcWeth; 
            reading1.block = uint128(block.number);
        } else if (reading1.block > reading2.block && reading1.block < block.number) {
            reading2.dcWeth = new_dcWeth; 
            reading2.block = uint128(block.number);
        }
    }

    function valuate(uint256 ethAmount) public view returns (uint256 dcAmount) {
        // Calculate an amount of DC to mint given ETH.
        PriceReading memory toRead = reading1.block < reading2.block ? reading1 : reading2;
        dcAmount = ethAmount.mul(toRead.dcWeth) / 10**9;
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'Zero input');
        require(reserveIn > 0 && reserveOut > 0, 'Zero liquidity');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function snack(uint256 amountIn, uint256 amountOutMin, uint deadline) public {
        require(block.timestamp < deadline, "Expired.");
        require(_msgSender() == dev1 || _msgSender() == dev2, "Permission denied!");
        uint amountOutput;
        {
        (uint reserve0, uint reserve1,) = dcPair.getReserves();
        (uint reserveInput, uint reserveOutput) = WETH < DC ? (reserve0, reserve1) : (reserve1, reserve0);
        IERC20(WETH).transfer(address(dcPair), amountIn);
        amountOutput = getAmountOut(amountIn, reserveInput, reserveOutput);
        require(amountOutput>= amountOutMin, 'Slipped.');
        }
        (uint amount0Out, uint amount1Out) = WETH < DC ? (uint(0), amountOutput) : (amountOutput, uint(0));
        dcPair.swap(amount0Out, amount1Out, address(this), new bytes(0));

    }

    function preserve(uint256 amountWETHDesired, uint256 amountDCDesired, uint256 amountWETHMin, uint256 amountDCMin,  uint256 deadline) public { 
        // Add WETH+DC LP.
        require(_msgSender() == dev1 || _msgSender() == dev2, "Permission denied!");
        uniRouter.addLiquidity(WETH, DC, amountWETHDesired, amountDCDesired, amountWETHMin, amountDCMin, address(this), deadline);
    }

    function raid() public {
        // Contract creators can each withdraw 1% of liquidity every 30 days.
        // This is a dev fee that helps cover ongoing gas fees for calls to
        // snack() and preserve().
        require(lastWithdrawal < (block.timestamp - 30 days), "Don't be greedy!");
        uint256 ruggableLPBalance = dcPair.balanceOf(address(this)).div(50);
        IERC20(address(dcPair)).transfer(dev1, ruggableLPBalance.div(2));
        IERC20(address(dcPair)).transfer(dev2, ruggableLPBalance.div(2));
        lastWithdrawal = uint32(block.timestamp);
    }

    //Fail-safe functions for releasing tokens we don't care about, not meant to be used.
    function release(address token) public {
        require (token != WETH);
        require (token != DC);
        require (token != address(dcPair));
        IERC20(token).transfer(owner(), 
            IERC20(token).balanceOf(address(this)));
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}