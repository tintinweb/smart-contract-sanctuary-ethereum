pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./IFridge.sol";
import "./IOven.sol";

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@*   [email protected]#@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@#° °#° #@#@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@#. OO## °#@#@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@###. #@#OO °O#@#@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@° #@##Oo [email protected]##@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@o [email protected]##o#@°.#[email protected]#@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@### °@#@[email protected]#° [email protected]@#@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@* ####[email protected]#@°.#[email protected]@#@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@### °@##[email protected]#@°[email protected]#o#@#@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@################@@#@O oO#@o#@#@.°#OooO*###@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@#####@@@@@@@@@@@@@@@@@###* ##[email protected]#@# oO#@O#[email protected]#@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@###@@@@@#OOoo******ooOO##@@@..##@oo#@@* o#@##[email protected]@#@@@@@@@
//@@@@@@@@@@@@@@@@@@@###@@@#Oo*°.................°*O *@@#OOO## °[email protected]##@#[email protected]##@@@@@@@
//@@@@@@@@@@@@@@@@@##@@@#o°....°°°°°°°°°°°°°°°°°°... .*[email protected]@#O* o###@#@O##[email protected]#@@@@@@
//@@@@@@@@@@@@@@@##@@#O°...°°°°°°°°°........°°°°°°°° ...°*#@# °[email protected]#@@@##[email protected]#@#@@@@@
//@@@@@@@@@@@@@@#@@#o...°°°°°°.......°°°°°°°......°. °°°°..*°[email protected]#@@@#@OO#[email protected]#@@@@@
//@@@@@@@@@@@@##@#*..°°°°°°...°°*oooooooooooooo**°.  .°°°°°. .oO###@@@#@o#O#@#@@@@
//@@@@@@@@@@@#@@o..°°°°°...°*oooooooooooooooooooooo° . ..°° ...*o###@@#@OO#[email protected]#@@@@
//@@@@@@@@@@#@#°.°°°°°..°*ooooooooooooooooooooooooo° **°..  °°°. *@@#@@@@o#O#@@@@@
//@@@@@@@@##@o..°°°°..°oooooooooooooooooooooooooooo* *oo*. .°°°°°.°#@#@#Oooo#@#@@@
//@@@@@@@#@@* °°°°..°oooooooooooooooooooooooooooooo* *oo° .°..°°°°[email protected]#o##[email protected]#@@@
//@@@@@@#@#°.°°°°..*oooooooooo*°°°°°*oooooooooooooo* *o* .o**°..°°°[email protected]#O#*##@@@
//@@@@@#@#..°°°. °ooooooooo°..       .*oooooooooooo* *o  ooo°**..°°°° *@#@O#O#@#@@
//@@@@#@#..°°°..*ooooooooo.            .*ooooooooooo °. *ooo*°oo..°°°° [email protected]#OO#[email protected]#@@
//@@@###°.°°°..ooooooooo*.               .oooooooooo.  **ooo***oo° °.°° [email protected]#O#[email protected]#@@
//@@@#@°.°°°..oooooooo*.                   *oooooooo  °o*oo**o**oo° .°°°.##O#[email protected]#@@
//@@#@o °°°..oooooooo.                     oo*****o* .***oo**o**ooo°.°°°..#O#[email protected]#@@
//@### °°°° *oooooooo*.                   .*..... .. *oo**o**oo**oo*..°°° *O#O#@@@
//@#@°.°°° *ooooooooooo.                  ....    . .oooo**°*oo**o*** .°°°.*#O#@@@
//#@o °°°.°ooooooooooooo                ....    .*. °ooooo*°*oo**o***° °°°[email protected]#@@@
//##..°°°.oooooooooooooo*            ........ .*o* .ooooo*o*°*****°***..°°°.OO#@@@
//@O °°°.°ooooooooooooooo.         ......  ..°ooo. °o******o*********** °°°.°[email protected]#@@
//@°.°°°.oooooooooooooooo.      ......°.   ..°oo* .oo********°***°***°*..°°° [email protected]#@@
//#.°°°.°oooooooooooooooo...........°°   ....°°°.  ..***********°°***°*° °°°[email protected]#@@
//o.°°° *ooooooooooooooo*........°°°.    °..        .*********°*°****°**..°°.°@#@@
//°.°°..ooooooooooooooo*......°°°°°.     °°        .**********°*°****°**..°°..#@#@
//..°°..ooooooooooooo*°....°°°°°°.      ..**°°.   ..**********°*°***°°**°.°°° [email protected]#@
// °°°.°ooooooooooo*°..°°°°°°..       ....***°.  . .o**********°°***°**°° °°°[email protected]#@
// °°°.*oooooooooo°...°°°...        .....°****.     *o*********°°***°*°**.°°°.*@#@
//.°°° *oooooooooo****°.    .. ......°.°°**°°°       °o*******°°°**°°°°**..°°.*@#@
//.°°° *ooooooo***ooo*      .°.....°°°°°°***°.       °o*******°°°°*°°°°°°..°°.*@#@
//.°°° *o**********o*..      ....°°°°°°°***°.       °ooo**°°°°°°°°°°°°°°° .°°.*@#@
//.°°°.°o*********o*....     ..°°°°°°°°°*°°.       *o**°......°°°°°°°°°°°.°°°.*@#@
// °°°.°o**********......     .°°°°°°°°°....     .*o°.   . ....°°°°°°°°°°.°°°[email protected]#@
//.°°°..o*********........      ..°°°°°....     °o*.   ..  .....°°°°°°°°. °°° [email protected]#@
//°.°°..*********.........         ... ....    °o.  .. .    ....°°°°°°°...°°°.#@#@
//o.°°° *******°..........           ...       ..  .        .....°°°°°....°°.°@#@@
//O.°°°.°******°°**.    ...              .       .          ......°°°... °°°.*@#@@
//@°.°°..*********°.      ...           ..                  ......°°.....°°° [email protected]#@@
//@o °°° °********°        ..         ...        .     .   .. ......... °°°.°@#@@@
//##.°°°..********.                   ...        .    ...  . ...........°°° [email protected]#@@@
//#@o °°°..******°                    ..         .           ......... °°°..##@@@@
//###..°°° °*****.                     .          ....      ......... .°°° [email protected]#@@@@
//@#@O °°°..**°°°.                   ..         . .....     ...... . .°°°.°@#@@@@@
//@@#@*.°°°..°°°.                   ....°       . .  ....  ......  ..°°°°.###@@@@@
//@@###..°°°..°°.                  .....°.     . ...   ...  .....   .°°° [email protected]#@@@@@@
//@@@#@#..°°°..°.                  .......         ...... ........  .°° [email protected]#@@@@@@@
//@@@@#@O.°°°°..                   ........         .....  .......  .° *@#@@@@@@@@
//@@@@@#@O..°°°.                    .......  .   .......      ....  . *@#@@@@@@@@@
//@@@@@@#@O..°°.                       .....  ...........     ... .  [email protected]#@@@@@@@@@@
//@@@@@@@#@#...                   .°.   ....  . ....... .     .  .  [email protected]#@@@@@@@@@@@
//@@@@@@@@#@#°                   ...... ..... . .  .... .      [email protected]#@@@@@@@@@@@@
//@@@@@@@@@#@o                  .......       ..   ... ..    .°..*#@#@@@@@@@@@@@@@
//@@@@@@@@@@#@o                .......         .        .  ..°.°[email protected]@#@@@@@@@@@@@@@@
//@@@@@@@@@@@#@O               ......          .  . .    [email protected]@##@@@@@@@@@@@@@@@
//@@@@@@@@@@@@#@#.             ...             .  .........°o#@##@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@#@#°            .°. .......     .... .   .°O#@@#@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@#@@*            ° .°°°°°°°     ..... .°o#@@@##@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@##@o           . ....°°°.      ... °[email protected]@@##@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@#@O           .o*°°°°°.      .. °#@###@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@#@O          [email protected]@@@@@@O      . °#@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@#@#.       [email protected]#######o       °#@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@#@#.      [email protected]#@@@@#@*      .#@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@#@#°     #@#@@@@#@#      *@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@#@#°   .##@@@@@@#@*     O##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@#@#°  [email protected]#@@@@@@###°   .##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@#@O °@#@@@@@@@@#@#*.*#@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@#@° #@#@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@#@O °@#@@@@@@@@@@@##@##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@#@o o##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
contract DogCatcher is Context, IERC20, Ownable {
    /*
        DogCatcher is the first Catcher-type token, designed to condense
        value from disparate liquidity pools. He uses flexible, modular
        strategies optimized for his different targets.
    */
    string private _name = "dog.catcher";
    string private _symbol = "DC";
    uint256 private _totalSupply = 0;
    uint8 private _decimals = 9;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    bool private _active = false;
    IFridge _fridge;
    mapping (address => address) _ovens;
    struct Vest { 
        uint128 vestedTime;
        uint128 ethAmount;
    }
    mapping (address => Vest) private userVests;
    event PresaleVote(uint dcAmount, uint8 indexed vote);
    event UsingFridge(address fridge);
    event AddedTarget(address token, address Oven);
    using SafeMath for uint256;

    function addTarget(address token, address oven) external onlyOwner() {
        // Different ovens are used to "handle" different targets.
        emit AddedTarget(token, oven);
        _ovens[token] = oven;
    }

    function setFavoriteFridge (address fridge) external onlyOwner() {
        // The favorite fridge is used for determining the value 
        // of DC tokens for the minting and vesting steps.
        emit UsingFridge(fridge);
        _fridge = IFridge(fridge);
    }

    function isActive() external view returns (bool) {
        // Inactive during pre-sale period.
        return _active;
    }

    function presaleMint(uint8 vote) public payable returns (uint256) {
        // Pre-sale open to public at 1m DC per ETH. This provides the initial
        // LP and pays our wonderful artist & front-end dev.
        require(!_active, "Presale is over!");
        uint256 mintedAmount = msg.value / 1000; 
        _mint(_msgSender(), mintedAmount);
        emit PresaleVote(mintedAmount, vote);
        return mintedAmount;
    }

    function endPresale () public onlyOwner() {
        require(!_active, "Already active.");
        // Pre-sold tokens represent 50% of the supply. The other 50% are minted 
        // and sent along with ETH to be added to LP manually.
        _mint(_msgSender(), _totalSupply);
        payable(owner()).transfer(address(this).balance);
        _active = true;
    }

    function otcOffer(address token, uint256 amount) public view returns (uint256 ethValue, uint256 paperValue, uint256 vestedTime) {
        // DC consults the proper oven and gives the users some choices
        // for how to dispose of their tokens.
        require(_ovens[token] != address(0), "Token not targeted.");
        (ethValue, paperValue, vestedTime) = IOven(_ovens[token]).otcOffer(token, amount);
    }

    function instaMint(address token, uint256 incomingTokenAmount) public {
        // User can instantly mint at a value comparable to what they would get
        // selling on the open market.
        require(_ovens[token] != address(0), "Token not targeted.");
        IOven oven = IOven(_ovens[token]);
        oven.updatePrice(token);
        IERC20(token).transferFrom(_msgSender(), address(oven), incomingTokenAmount);
        (uint256 ethValueIncoming, ) = oven.getValues(token, incomingTokenAmount);
        _fridge.updatePrice();
        _mint(_msgSender(), _fridge.valuate(ethValueIncoming));
    }

    function vestMint(address token, uint256 amount) public {
        // User mints a higher value, (not subject to price impact), in
        // a vesting position denominated in ETH.
        require(_ovens[token] != address(0), "Token not targeted.");
        IOven oven = IOven(_ovens[token]);
        oven.updatePrice(token);
        IERC20(token).transferFrom(_msgSender(), address(oven), amount);
        (, uint256 paperValue, uint256 vestedTime) = oven.otcOffer(token, amount);
        _vest(_msgSender(), vestedTime, paperValue);
    }   

    function _vest(address user, uint256 time, uint256 ethAmount) private {
        // Handles adding to existing vest: Maximum of timestamps, sum of values.
        Vest storage currentVest = userVests[user];
        uint128 time128 = uint128(time);
        uint128 newEthAmount = currentVest.ethAmount + uint128(ethAmount);
        uint128 newTime = time128 > currentVest.vestedTime ? time128 : currentVest.vestedTime;
        currentVest.vestedTime = newTime;
        currentVest.ethAmount = newEthAmount;
    }

    function vestOf(address user) public view returns (Vest memory) {
        return userVests[user];
    }

    function completeVest() public {
        // Finalizes vests that are past the completion date.
        // DC are issued at DC/ETH rate at time of completion.
        Vest storage userVest = userVests[_msgSender()];
        require(userVest.vestedTime < block.timestamp, "Your dogs are still cookin'.");
        _fridge.updatePrice();
        _mint(_msgSender(), _fridge.valuate(userVest.ethAmount));
        userVests[_msgSender()] = Vest(0, 0);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(_active, "Can't transfer during presale.");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    //Fail-safe functions for releasing tokens, not meant to be used.
    function release(address token) public {
        IERC20(token).transfer(owner(), 
            IERC20(token).balanceOf(address(this)));
    }

    //The rest is all boilerplate ERC-20, but go ahead and read if you need a sleeping aid.
    function name() public view returns (string memory) {return _name;}
    function symbol() public view returns (string memory) {return _symbol;}
    function decimals() public view returns (uint8) {return _decimals;}
    function totalSupply() public view override returns (uint256) {return _totalSupply;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
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

interface IOven  {
    function getValues(address token, uint256 amount) external view returns (uint256 ethValue, uint256 paperValue);
    function otcOffer(address token, uint256 amount) external view returns (uint256 ethValue, uint256 paperValue, uint256 vestTime);
    function updatePrice(address token) external;
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