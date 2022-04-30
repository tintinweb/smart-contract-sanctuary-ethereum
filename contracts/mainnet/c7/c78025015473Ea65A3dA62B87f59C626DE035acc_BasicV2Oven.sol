import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./IFridge.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXXKKKK00000000000KKKXXNNWWWMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMWXOkdoolcc:;;;,,,,''''''''''',,,,;;::cclloddxkO0KXWMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMW0:.........''''''''''''''''''''''''..........'cdOWMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMXd,.......................................,o0WMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMWKl'....................................lKWMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMWO:.................................,xNMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMXd'.....''.......................:0WMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:............................cKMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd'.........................cXMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,.......................lXMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:.....................lXMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl....,'.............cXMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.................cKMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:...............;0MMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:.............,OWMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:............;KMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.............oNMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,....'........:XMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;.....'........lNMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc...............dWMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl................kMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd................,OMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'....''..........;KMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,.................cXMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;..................oWMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc...................xMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.....'.............'kMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd......'.............,0MMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMWk'....................:XMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMO,.....................lNMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMK;.....',,,,''..........lKKXWMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMXc.',;;::::::cc:'........,;;:lxKWMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMNl..;:::::::c:ccc;',,,'.',,,,;;;:oONMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMNd..';:::::llcclol;',,,'',,,,,,,,,,;cxNMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMNOxxxkOkc,',,,;;;;::;;:::;'''',''',,,,,,;;;;;,oNMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMWKx:,;:ccc;''',,'',,,'''',,,,''',,,'''',,;:;;:c:'cKMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMKc',;,;cc:;,''',,,,,,,'',,,,,''',,,,'''',;;,;c:,:OWMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMk,,::::c:;::;,','''',,,,,',,,'',,,,,,,,,'''',,':0MMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMXd::c:cc:;;;;,'','',,,,,'',,,,,,,,,,',,,,,,',,',d0OxkKWMMMMMMMMMMMM
//MMMMMMMMMMMMMMW0l,;::;;;,,,'',,,,'',,,'''''',,,,,,,,,,,,,,,,,''.'',oXMMMMMMMMMMM
//MMMMMMMMMMMMMMMXl',;,,,,',,,,,,,'..............'''',,,,,,,,,,.......cKMMMMMMMMMM
//MMMMMMMMMMMMMMNd,''''''',,,'''.....................',,,,'',,,.....'''dWMMMMMMMMM
//MMMMMMMMWXKXNWk,',,,'''''''.........................',,,'.',,'''''';oKWMMMMMMMMM
//MMMMMMMNx;,;:c;''''''''''.............................''..',',,,''oKNWMMMMMMMMMM
//MMMMMMWO:'''''''''''''....................................','',,,'cdxxONMMMMMMMM
//MMMMMMKc..',',,'',,'......................................,'',,,,;clcccxXMMMMMMM
//MMMMMWd,',,,',,,,,'.......................................',,,,,,;ccclc:xNMMMMMM
//MMMMW0c,'',,'',,,'........................''...............',,,,,,;:llc;lKMMMMMM
//MMMMKl,,,,,,,,,''.........................'.................',,,,,,;::;:xNMMMMMM
//MMMMO:,,,,,,,,,'.................'........''..................,,,,,',oOKWMMMMMMM
//MMMMW0xol:,'',''..........'.....,'........''......''...''.....',,,,,'dWMMMMMMMMM
//MMMMMMMWNo',,,'..........''....''.........'''....','...,'......'',,,'cXMMMMMMMMM
//MMMMMMMMNl',,''..........,'...''..........''''...,;'..,;........',,,';0MMMMMMMMM
//MMMMMMMMXc',,,'.........';,...';,........''''''.,;,..';;.........,,,,;kMMMMMMMMM
//MMMMMMMMXc',,,'.........';;...,;:,'....',;,''',;;;'..,:;.........',,,,xWMMMMMMMM
//MMMMMMMMKc',,,'.........';;'.',;;;;;,'';c:,',',;;;..';:;.........',,,'oNMMMMMMMM
//MMMMMMMMKc',,,.....'.....;:;;,,,;;;::::cc:'',,,;;,..';:;,'.......',,,'oNMMMMMMMM
//MMMMMMMMKc',,,....''.....';;;;,,;:::;;;:c;,',,,,,,,,,::;;;'......',,,'lNMMMMMMMM
//MMMMMMMMKc',,'....'''....',;;;,,;;;;;;::::;;,;,',:;,,::;;;'......',,,'lXMMMMMMMM
//MMMMMMMMKc',,'.....'''''',,;,,;;;;::;;::;;cc;,;;;;;,;:;;;,.......,,,,'lXMMMMMMMM
//MMMMMMMMXc',,'......''',,,''',::;:c:;,;;,:llc;:c;;:;;::;;'......',',,'lNMMMMMMMM
//MMMMMMMMXl',,'.......',,,,;,,,:c::ccc:::cllllll:;cl:;;;;,.......',,,,'oNMMMMMMMM
//MMMMMMMMNo',,'........',,;c:;;cllcllllllllloolccllllc;;;'......',,,','dWMMMMMMMM
//MMMMMMMMWx,','..........'':lcclxdodxxoollldkkxdddoodl;;,.......',,,,',xMMMMMMMMM
//MMMMMMMMMK:','............':cldkkkkOkkkkkkkkOOkkxxkxl:,........',,,,',kMMMMMMMMM
//MMMMMMMMMWd''''...............,;;;;:::::::::::::;;;,..........',,,,,':0MMMMMMMMM
//MMMMMMMMMMO,.,'..''''''......'........................''''',,,,',,,,'cKMMMMMMMMM
//MMMMMMMMMMNl','..'''''...''.',',;;;,;;;,,,,,,,,',:cccccccccccl:'',,,,oNMMMMMMMMM
//MMMMMMMMNK0o''''''''',,''''.',,;;;;,;;;,,,;;;,,'';:::::::;;;:;,'',,''oNMMMMMMMMM
//MMMMMMMNd:;;,,,,,''''',,,,'',,,,,,,,,,,,,,,,,,,,'''''''''''''''',,,;;:dXMMMMMMMM
//MMMMMMM0c::;:::::::;,;;,,,,,,,,'',''''''',,,''''''''''''',,;;;;::c::c:c0MMMMMMMM
//MMMMMMMNd;;;::::::::::::::::::;;;;;;;;;;;;;;;;;;;;;;;;::::ccccc::cc:::dXMMMMMMMM
//MMMMMMMMNOkkxc,,;;;;:::::::::::::::::c:::::cc::ccccccccccccc::::;;,;dKNMMMMMMMMM
//MMMMMMMMMMMMMO,',''',,,,,,,;;;;;;;:::::::::::::::::::::;;;;;,,,,,,'cXMMMMMMMMMMM
//MMMMMMMMMMMMMXl',,',,,,,,'',''',,,,,,,,,,,,,,,,,,,,,,,'''',,,,,,,,,xWMMMMMMMMMMM
//MMMMMMMMMMMMMWx,,,,,,,,,,,,,,,,,,,,,,,,'''''''',,,,,,,,,,,,,,,,,,':0MMMMMMMMMMMM
//MMMMMMMMMMMMMMK:',,,,,,,,,,,,,,,,,,,,,,''''',,,,,,,,,,,,,,,,,,,,,,dWMMMMMMMMMMMM
//MMMMMMMMMMMMMMWd',,,,,,,,,,,,,,,,,,,,,,''''',,'',,,,,,,,,,,,,,,,';0MMMMMMMMMMMMM
//MMMMMMMMMMMMMMMO;',,,,,,,,'''',,,,,,,,,,,,,,,,,''',,,''',,,,,,,,'oNMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMNl''''''...'''''''''''''''''''''''''''''''',,,,,';OMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMk,',,,'. .'',,'''''''''''''''''''.'''''''.',,,,'oNMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMKc',,,,.. .'''''''''''''''''''''. .'''''.',,,,':0MMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMWx,,,,,'. .','''''''''''''''''''.  .''''.',,,,,xWMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMM0:',,,,'..'''''''''''''''''''''.  .''''',,,,'cXMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMNo',,',,,'.''''''''''''''''''''......',,'',''xMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMO;,,,,,,'..''''''''''''''''''''..'',,,,,'..,0MMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMXl',,,,,,'.''''''''''''''''''''',,,,,,'';. cNMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMWk,',,,,,,,,,''''''''''''''''',,,,,,,';d0:.dWMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMNx;''.',,,,,,,,,,,,,,,,,,,,,,,,'''';oKWN:.:kXMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMWXo. .:lccc::;;,,,,'''''''''''. 'oKWMMNo'',oXMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMM0, .xWWWNNXXKK000OOOkkxxddo:. lNMMMMWNNNNNWMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMNl .kMMMMMMMMMMMMMMMMMMMMMMk..kMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMk..kMMMMMMMMMMMMMMMMMMMMMMk.,KMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMNOo:..kMMMMMMMMMMMMMMMMMMMMMMk..lOWMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMWOc;;;c0MMMMMMMMMMMMMMMMMMMMMM0:'':kWMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMWWWWWWMMMMMMMMMMMMMMMMMMMMMMMWNNNNNWMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

contract BasicV2Oven is Context, Ownable{
    /*
        The Oven's job is to consume tokens and send WETH to the fridge.
        The BasicV2Oven is designed for those poor tax-on-transfer tokens that are
        stuck in antiquated UniSwap pools.
    */
    IUniswapV2Factory factory;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    mapping (address => bool) private _targeted;
    mapping (address => uint8) private tax;
    mapping (address => uint256) private batchsize;
    // Sandwich-resistance:
    struct PriceReading {
        uint64 ethReserves;
        uint64 tokenReserves;
        uint32 block;
    }
    mapping (address => PriceReading) reading1;
    mapping (address => PriceReading) reading2;
    IFridge _fridge;
    address dev1;
    address dev2;
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeMath for uint32;
    event UsingFridge(address fridge);

    constructor (address fridge) {
        replaceFridge(fridge);
        factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    }

    function addTarget(address token, uint8 new_tax, uint256 new_batchsize) public onlyOwner() {
        // Record the exact cooking instructions for new targets
        require(new_tax < 100);
        require(new_batchsize > 0);
        _targeted[token] = true;
        tax[token] = new_tax;
        batchsize[token] = new_batchsize;
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair(factory.getPair(token, WETH)).getReserves();
        (uint ethReserves, uint tokenReserves) = WETH < token ? (reserve0, reserve1) : (reserve1, reserve0);
        PriceReading memory initialReading;
        initialReading.ethReserves = uint64(ethReserves / 10**9);
        initialReading.tokenReserves = uint64(tokenReserves / 10**9);
        initialReading.block = uint32(block.number);
        reading1[token] = initialReading;
        reading1[token].block = uint32(block.number - 1);
        reading2[token] = initialReading;
    }

    function removeTarget(address token) public onlyOwner() {
        _targeted[token] = false;
    }

    function replaceFridge (address fridge) public onlyOwner() {
        emit UsingFridge(fridge);
        _fridge = IFridge(fridge);
    }

    function setDevs(address new_dev1, address new_dev2) public onlyOwner() {
        // Operators who call the cook function.
        dev1 = new_dev1;
        dev2 = new_dev2;
    }

    function updatePrice(address token) external {
        // Take a new price reading from Uniswap.
        PriceReading storage my_reading1 = reading1[token];
        PriceReading storage my_reading2 = reading2[token];
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair(factory.getPair(token, WETH)).getReserves();
        (uint ethReserves, uint tokenReserves) = WETH < token ? (reserve0, reserve1) : (reserve1, reserve0);
        if (my_reading1.block < my_reading2.block && my_reading2.block < block.number) {
            my_reading1.ethReserves = uint64(ethReserves / 10**9);
            my_reading1.tokenReserves = uint64(tokenReserves / 10**9);
            my_reading1.block = uint32(block.number);
        } else if (my_reading1.block > my_reading2.block && my_reading1.block < block.number) {
            my_reading2.ethReserves = uint64(ethReserves / 10**9);
            my_reading2.tokenReserves = uint64(tokenReserves / 10**9);
            my_reading2.block = uint32(block.number);
        }
    }

    function getReserves(address token) internal view returns (uint256 ethReserves, uint256 tokenReserves) {
        // Retrieves recorded pool reserves.
        PriceReading memory toRead = reading1[token].block < reading2[token].block ? reading1[token] : reading2[token];
        ethReserves = uint256(toRead.ethReserves) * 10**9;
        tokenReserves = uint256(toRead.tokenReserves) * 10**9;
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'Zero input');
        require(reserveIn > 0 && reserveOut > 0, 'Zero liquidity');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function apply_tax(uint amount, address token) internal view returns (uint256) {
        return amount.mul(100 - tax[token]).div(100);
    }

    function getValues(address token, uint256 amount) external view returns (uint256 ethValue, uint256 paperValue) {
        // Estimates value of a given amount of target token, based on market conditions.
        require(_targeted[token]);
        (uint256 ethReserves, uint256 tokenReserves) = getReserves(token);
        ethValue = getAmountOut(apply_tax(apply_tax(amount, token), token), tokenReserves, ethReserves);
        paperValue = apply_tax(apply_tax(amount.mul(ethReserves) / tokenReserves, token), token);
    }

    function otcOffer(address token, uint256 amount) external view returns (uint256 ethValue, uint256 paperValue, uint256 vestedTime) {
        // Provides the estimated values back to DC, along with the "cook time" for the vest.
        require(_targeted[token]);
        (ethValue, paperValue) = this.getValues(token, amount);
        uint tokenBalance = IERC20(token).balanceOf(address(this));
        uint nPeriods = tokenBalance.add(amount) / batchsize[token];
        vestedTime = block.timestamp.add(7 days).add(nPeriods.mul(1 days));
    }

    function cook(address token, uint256 amountIn, uint256 amountOutMin, uint deadline) public {
        // Liquidates target tokens and passes the profits along to the fridge.
        require(block.timestamp < deadline, "Expired");
        require(_msgSender() == dev1 || _msgSender() == dev2, "Only chefs allowed in the kitchen!");
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token, WETH));
        uint balanceBefore = IERC20(WETH).balanceOf(address(_fridge));
        IERC20(token).transfer(address(pair), amountIn);
        uint amountInput;
        uint amountOutput;
        {
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) = WETH > token ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(token).balanceOf(address(pair)).sub(reserveInput);
        amountOutput = getAmountOut(amountInput, reserveInput, reserveOutput);
        }
        (uint amount0Out, uint amount1Out) = WETH > token ? (uint(0), amountOutput) : (amountOutput, uint(0));
        pair.swap(amount0Out, amount1Out, address(_fridge), new bytes(0));
        require(IERC20(WETH).balanceOf(address(_fridge)).sub(balanceBefore) >= amountOutMin, 'Slipped.');
    }

    //Fail-safe function for releasing non-target tokens, not meant to be used.
    function release(address token) public {
        require (!_targeted[token]);
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

interface IFridge {
    function valuate(uint256 ethAmount) external returns (uint256 tokenValue);
    function updatePrice() external;
}

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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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