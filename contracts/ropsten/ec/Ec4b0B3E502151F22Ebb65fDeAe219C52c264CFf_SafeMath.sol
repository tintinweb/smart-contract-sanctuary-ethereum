/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.6;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    /**

     * @dev Returns the amount of tokens owned by `account`.

     */

    function balanceOf(address account) external view returns (uint256);

    /**

     * @dev Moves `amount` tokens from the caller's account to `recipient`.

     *

     * Returns a boolean value indicating whether the operation succeeded.

     *

     * Emits a {Transfer} event.

     */

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**

     * @dev Returns the remaining number of tokens that `spender` will be

     * allowed to spend on behalf of `owner` through {transferFrom}. This is

     * zero by default.

     *

     * This value changes when {approve} or {transferFrom} are called.

     */

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

     * @dev Moves `amount` tokens from `sender` to `recipient` using the

     * allowance mechanism. `amount` is then deducted from the caller's

     * allowance.

     *

     * Returns a boolean value indicating whether the operation succeeded.

     *

     * Emits a {Transfer} event.

     */

    function transferFrom(
        address sender,
        address recipient,
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

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable {
    address public _owner;

    /**

     * @dev Throws if called by any account other than the owner.

     */

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");

        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }
}

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**

     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on

     * overflow (when the result is negative).

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
        require(b <= a, errorMessage);

        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the

        // benefit is lost if 'b' is also tested.

        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;

        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**

     * @dev Returns the integer division of two unsigned integers. Reverts on

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
        return div(a, b, "SafeMath: division by zero");
    }

    /**

     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on

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
        require(b > 0, errorMessage);

        uint256 c = a / b;

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        return div(mul(x, y), z);
    }
}

contract MACTID is IERC20, Ownable {
    using SafeMath for uint256;

    //邀请信息
    struct info {
        uint8 level; //自身处于第几级关系 1 2 3
        uint256 Fcount; //一级邀请总数
        uint256 Scount; //二级邀请总数
        uint256 Tcount; //三级邀请总数
    }

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) private _rOwned;

    mapping(address => address) public inviter;

    mapping(address => uint256) private inviterLevel; // 邀请等级

    mapping(address => info) public inviterInfo; // 邀请信息 [a=>[level=1|2,Fcount=2,Scunt=3]]

    mapping(address => address) public inviterFirst; // 一级 to>from
    address[] private FirstAddress;
    mapping(address => address) public inviterSecond; // 二级 Sto>Sfrom
    address[] private SecondAddress;
    mapping(address => address) public inviterThird; // 三级 Sto>Sfrom
    address[] private ThirdAddress;

    address public burnAddress = address(0); // 黑洞地址

    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal;

    uint256 private _rTotal;

    uint256 public _minAmount;

    uint256 public _maxAmount;

    string private _name;

    string private _symbol;

    uint256 private _decimals;

    bool private _ExpBlock;
    uint256 public _uTotal; //有效地址总数
    uint256 public _uActiveNum; //有效持币|到达数字算有效账户
    uint256 public blockAmountCount; //累计爆块数量
    uint256 holdReta = 60;
    uint256 inviterReta = 35;
    uint256 inviterNum; //推广收益结束

    mapping(address => uint256) public _uLevel; //用户等级
    mapping(address => uint256) public _uProm; //推广等级

    mapping(uint256 => uint256) public _levelWeight; //每个等级总权重
    mapping(address => uint256) public _userWeight; //每个用户的权重

    address[] public lastAwardAddress; //上一次积压的奖励地址

    mapping(address => bool) private _uActive; // 已经触发过爆块的有效地址

    //黑洞地址
    address private _destroyAddress =
        address(0x000000000000000000000000000000000000dEaD);
    //底池0.2%
    address public uniswapV2Pair;
    //风险池 1%
    address public _fundAddress;
    //奖金池地址 1%
    address public _rewardLpAddress;
    //项目方地址 3.8%
    address public _MarketingAddress;
    //发币地址 94% 爆块奖励地址 权益奖励
    address public tokenOwner;

    uint32 private lastPopTime; // 上一次爆块的时间
    uint256 private popToken; // 爆块最大产出
    bool public is_test;

    event popBlockev(uint256 len, uint256 amount, uint256 time);
    event sendAwardev(uint256 len, uint256 amount, uint256 time);
    event getAwardev(
        uint256 holdAward,
        uint256 invAward,
        uint256 weig,
        uint256 Creta,
        uint256 Treta
    );
    event initUserRelationev(uint256 level, uint256 w);

    constructor(
        address fdaddr,
        address raddr,
        address maddr,
        address uaddr
    ) {
        _name = "mactid token";
        _symbol = "MACTID";
        _decimals = 8;
        _tTotal = 1 * 10**9 * 10**_decimals;

        tokenOwner = msg.sender;
        _owner = msg.sender;

        _rTotal = _tTotal.div(100).mul(94);
        //权益奖励
        _rOwned[tokenOwner] = _rTotal;

        //项目方地址 3.8%
        _rOwned[maddr] = _tTotal.div(1000).mul(38);
        _MarketingAddress = maddr;
        //奖金池地址 1%
        _rOwned[raddr] = _tTotal.div(100).mul(1);
        _rewardLpAddress = raddr;
        //风险池 风险池
        _rOwned[fdaddr] = _tTotal.div(100).mul(1);
        _fundAddress = fdaddr;
        //底池启动
        _rOwned[uaddr] = _tTotal.div(1000).mul(2);
        uniswapV2Pair = uaddr;

        //不允许爆块
        _ExpBlock = false;

        // 爆块相关的数据
        lastPopTime = uint32(block.timestamp);

        // 单次最大爆块数
        popToken = 181327 * 10**6;

        //推广收益结束界限 9400/0.51/0.5
        inviterNum = _rTotal.div(200).mul(51);

        emit Transfer(address(0), tokenOwner, _tTotal);
    }

    //测试立即爆块|手动爆块
    function testPock() public {
        is_test = true;
        _ExpBlock = true;
        popBlock();
        is_test = false;
    }

    //获取下级
    function _getchild(address account) public view returns (address[] memory) {
        address[] memory child;
        uint256 level = inviterInfo[account].level;
        address[] memory addr;
        if (level == 1) {
            addr = FirstAddress;
        } else if (level == 2) {
            addr = SecondAddress;
        } else if (level == 3) {
            addr = ThirdAddress;
        }
        for (uint256 f = 0; f < addr.length; f++) {
            if (inviterFirst[addr[f]] == account) {
                child[f] = addr[f];
            }
        }
        return child;
    }

    //判定是否有效地址
    function _isEffeActive(address account) public view returns (bool) {
        //爆块等级增加|有效地址比值递减
        uint256 BlockLevel = _getBlockLevel();
        return balanceOf(account) > 100 * (10 - BlockLevel);
    }

    //判定是否满足爆块
    function _isExpBlock() public returns (bool) {
        if (is_test) {
            return true;
        }
        // 判断爆块总量是否已经达到了 9400 万,此时便停止爆块
        if (blockAmountCount >= _rTotal) {
            _ExpBlock = false;
            return false;
        }
        // 新增有效账户和时间间隔不满足需求
        if (
            lastAwardAddress.length < 1 ||
            SafeMath.sub(block.timestamp, uint256(lastPopTime)) < 60 * 60
        ) {
            return false;
        }
        // 未达到首次爆块开启要求
        if (_ExpBlock != true && _uTotal > 500) {
            _ExpBlock = true;
        }
        return _ExpBlock;
    }

    //建立关系
    function _initUserRelation(address from, address to)
        private
        returns (bool)
    {
        require(to != address(0), "to is zero address");
        require(from != address(0), "to is zero address");
        // if (
        //     from == tokenOwner ||
        //     from == _MarketingAddress ||
        //     from == _fundAddress ||
        //     to == tokenOwner ||
        //     to == _MarketingAddress ||
        //     to == _fundAddress
        // ) {
        //     return false;
        // }
        //判定 to 是否已经绑定|to 不能重复绑定 只能绑定一次
        if (inviterInfo[to].level == 0 && _isEffeActive(from)) {
            (, uint256 weight, ) = _getMlevel(_rOwned[to]);
            //判定from等级
            if (inviterInfo[from].level >= 3) {
                address Faddr = inviterSecond[from];
                address Gaddr = inviterFirst[Faddr];
                inviterInfo[to].level = 4;
                //规定to
                inviterThird[to] = from;
                ThirdAddress.push(to);
                //三级关系

                inviterInfo[Faddr].Scount += 1;
                inviterInfo[Gaddr].Tcount += 1;

                //权重更新
                _userWeight[to] = weight;
                //本身
                _userWeight[from] += weight;
                //1级权重+=
                _userWeight[Faddr] += weight;
                //2级权重+=
                _userWeight[Gaddr] += weight;
                //3级权重+=

                _levelWeight[_uLevel[to]] += weight;
                //本身
                _levelWeight[_uLevel[from]] += weight;
                //1级等级总权重
                _levelWeight[_uLevel[Faddr]] += weight;
                //2级等级总权重
                _levelWeight[_uLevel[Gaddr]] += weight;
                //3级等级总权重
            } else if (inviterInfo[from].level == 2) {
                //如果处在第二级 则改变
                address Faddr = inviterFirst[from];
                inviterSecond[to] = from;
                SecondAddress.push(to);
                //二级关系
                //from 父级 二级总数 Scount +1
                inviterInfo[Faddr].Scount += 1;
                inviterInfo[to].level = 3;
                //规定to
                //权重更新
                _userWeight[to] = weight;
                //本身
                _userWeight[from] += weight;
                //父级权重+=
                _userWeight[Faddr] += weight;
                //爷级权重+=

                _levelWeight[_uLevel[to]] += weight;
                //本身
                _levelWeight[_uLevel[from]] += weight;
                //父级等级总权重
                _levelWeight[_uLevel[Faddr]] += weight;
                //爷级等级总权重
            } else {
                //初次建立关系|或者 from段位是1
                inviterFirst[to] = from;
                FirstAddress.push(to);
                //1级关系
                //a 段位1 直属推广人数+1
                inviterInfo[from].level = 1;
                //b 段位2
                inviterInfo[to].level = 2;
                //权重问题
                _userWeight[to] = weight;
                //本身
                _userWeight[from] += weight;
                //父级权重+=

                _levelWeight[_uLevel[to]] += weight;
                //本身
                _levelWeight[_uLevel[from]] += weight;
                //父级等级总权重
            }
            //直属推广+1
            inviterInfo[from].Fcount += 1;
            return true;
            emit initUserRelationev(inviterInfo[from].level, weight);
        }
        return false;
    }

    //改变用户等级|持币等级|权重值
    function _changeULevel(address account, uint256 beforAmount)
        private
        returns (uint256)
    {
        require(account != address(0), "ERC20: mint to the zero address");
        //三种地址不参与计算
        if (
            account == tokenOwner ||
            account == _MarketingAddress ||
            account == _fundAddress
        ) {
            return 0;
        }
        if (_isEffeActive(account) == false) {
            return 0;
        }

        (uint256 beforLevel, uint256 beforWeight, ) = _getMlevel(beforAmount);
        //改变之前的等级 权重
        (uint256 level, uint256 weight, ) = _getMlevel(_rOwned[account]);
        //改变之后的等级 权重

        //每次等级变化 更新父级权重 同时更新父类奖池的权重
        if (beforLevel != level && weight != beforWeight) {
            //等级改变
            _uLevel[account] = level;
            //权重差值
            uint256 weightDiff = weight - beforWeight;

            //自身权重发生改变
            _userWeight[account] = weight;
            //自身奖池权重发生改变
            _levelWeight[beforLevel] -= beforWeight;
            _levelWeight[level] += weight;

            //改变每个等级总权重
            //如果处在第三级 改变直属一级
            if (inviterInfo[account].level >= 3) {
                address Faddr = inviterThird[account];
                address Gaddr = inviterSecond[Faddr];
                address Zaddr = inviterFirst[Gaddr];
                //改变父级权重
                _userWeight[Faddr] += weightDiff;
                _userWeight[Gaddr] += weightDiff;
                _userWeight[Zaddr] += weightDiff;
                //父级奖池权重
                _levelWeight[_uLevel[Faddr]] += weightDiff;
                _levelWeight[_uLevel[Gaddr]] += weightDiff;
                _levelWeight[_uLevel[Zaddr]] += weightDiff;
            } else if (inviterInfo[account].level == 2) {
                //如果处在第二级 则改变
                address Faddr = inviterSecond[account];
                address Gaddr = inviterFirst[Faddr];
                //改变父级权重
                _userWeight[Faddr] += weightDiff;
                _userWeight[Gaddr] += weightDiff;
                //父级奖池权重
                _levelWeight[_uLevel[Faddr]] += weightDiff;
                _levelWeight[_uLevel[Gaddr]] += weightDiff;
            } else if (inviterInfo[account].level == 1) {
                //如果处在1级 只改变直输上级
                address Faddr = inviterFirst[account];
                //直属父级权重 变化
                _userWeight[Faddr] += weightDiff;
                //直属父级奖池权重 变化
                _levelWeight[_uLevel[Faddr]] += weightDiff;
            }
        }
        return level;
    }

    //改变用户推广等级|并且返回当前等级
    function _changeUProm(address account) private returns (uint256) {
        //三种地址不参与机算
        if (
            account == tokenOwner ||
            account == _MarketingAddress ||
            account == _fundAddress
        ) {
            return 0;
        }
        //三代累计
        if (_isEffeActive(account)) {
            uint256 count = inviterInfo[account]
                .Fcount
                .add(inviterInfo[account].Scount)
                .add(inviterInfo[account].Tcount);
            //二代累计
            uint256 Scount = inviterInfo[account].Fcount.add(
                inviterInfo[account].Scount
            );
            //直属统计
            uint256 Fcount = inviterInfo[account].Fcount;
            if (count >= 150 && Fcount >= 10) {
                _uProm[account] = 5;
            } else if (count >= 80 && Fcount >= 8) {
                _uProm[account] = 4;
            } else if (Scount >= 28 && Fcount >= 7) {
                _uProm[account] = 3;
            } else if (Scount >= 18 && Fcount >= 6) {
                _uProm[account] = 2;
            } else if (Scount >= 10 && Fcount >= 5) {
                _uProm[account] = 1;
            } else {
                _uProm[account] = 0;
            }
            return _uProm[account];
        }
        return 0;
    }

    //获取奖励占比
    function _getReta(uint256 Clevel, uint256 Plevel)
        private
        pure
        returns (uint256, uint256)
    {
        //1 等级收益 2推广收益
        uint256 Lreta = 0;
        uint256 Ireta = 0;
        if (Clevel == 5) {
            Lreta = 15;
        } else if (Clevel == 4) {
            Lreta = 25;
        } else if (Clevel == 3) {
            Lreta = 20;
        } else if (Clevel == 2) {
            Lreta = 25;
        } else if (Clevel == 1) {
            Lreta = 15;
        }
        if (Plevel == 5) {
            Ireta = 10;
        } else if (Plevel == 4) {
            Ireta = 20;
        } else if (Plevel == 3) {
            Ireta = 25;
        } else if (Plevel == 2) {
            Ireta = 20;
        } else if (Plevel == 1) {
            Ireta = 25;
        }
        return (Lreta, Ireta);
    }

    //获取持币静态数据|持币等级+静态权重
    function _getMlevel(uint256 amount)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 level;
        uint256 weight;
        uint256[5] memory Dweight = [uint256(3), 7, 15, 22, 53];
        //获取爆块等级
        uint256 blockLevel = _getBlockLevel();
        amount = amount.div(10**_decimals);
        if (amount <= 0) {
            return (0, 0, blockLevel);
        } else {
            //等级算法 o(n)
            uint256 degree;
            //对比值
            for (uint256 x = 4; x >= 0; x--) {
                degree = (2**x).mul(100);
                //递减-10%
                if (blockLevel > 0) {
                    degree = degree.sub(degree.mul(blockLevel).div(10));
                }
                if (amount >= degree) {
                    level = x + 1;
                    weight = Dweight[x];
                    break;
                }
            }
            return (level, weight, blockLevel);
        }
    }

    //获取爆块等级
    function _getBlockLevel() public view returns (uint256) {
        uint256[9] memory Dgrade = [
            uint256(20),
            50,
            100,
            180,
            300,
            500,
            800,
            1200,
            1550
        ];
        //爆块算法 o()
        uint256 blockLevel = 0;
        uint256 blockAC = blockAmountCount.div(10**6);
        for (uint256 i = Dgrade.length; i > 0; i--) {
            if (blockAC.div(10000) > Dgrade[i - 1]) {
                blockLevel = i;
            }
        }
        return blockLevel;
    }

    //发送奖励 单次发放奖励 parame account有效地址 amount 产出代币数量
    function sendAward(uint256 amount, uint256 leng) private {
        require(amount > 0, "Award: amount zero");
        if (leng > 1 && leng <= 24) {
            amount = amount.div(leng);
        }
        //循环发放
        for (uint256 i = 0; i < leng; i++) {
            if (lastAwardAddress[i] != address(0)) {
                // 95%用于发放奖励
                uint256 awardmoney = _getAward(lastAwardAddress[i], amount);
                //发奖励
                _awardTransfer(lastAwardAddress[i], awardmoney);
            }
        }
        //产出5%官方手续费（销毁）
        _awardTransfer(_MarketingAddress, amount.mul(5).div(100));
        //总体币减少
        _tTotal -= amount;
        //累计爆块增加
        blockAmountCount += amount;
        if (blockAmountCount >= inviterNum) {
            holdReta = 95;
            inviterReta = 0;
        }
        emit sendAwardev(leng, amount, blockAmountCount);
    }

    //计算奖励    持币+推广
    function _getAward(address account, uint256 money)
        private
        returns (uint256)
    {
        //权重占比300
        uint256 weig = _userWeight[account].mul(100).div(
            _levelWeight[_uLevel[account]]
        );
        //等级奖池占比
        // 1 等级收益 2推广收益
        (uint256 Creta, uint256 Treta) = _getReta(
            _uLevel[account],
            _uProm[account]
        );

        //计算持币奖励3
        uint256 holdMoney = money.mul(holdReta).div(100);
        //60%
        uint256 holdAward = holdMoney.mul(Creta).div(100).mul(weig).div(100);

        //计算推广奖励
        uint256 invAward = 0;
        if (inviterReta > 0) {
            uint256 inviterMoney = money.mul(inviterReta).div(100);
            //35%
            invAward = inviterMoney.mul(Treta).div(100);
        }
        emit getAwardev(holdAward, invAward, weig, Creta, Treta);
        //返回奖励值
        return invAward.add(holdAward);
    }

    //奖励转账
    function _awardTransfer(address recipient, uint256 tAmount) private {
        _rOwned[tokenOwner] = _rOwned[tokenOwner].sub(tAmount);

        _rOwned[recipient] = _rOwned[recipient].add(tAmount);

        emit Transfer(tokenOwner, recipient, tAmount);
    }

    //销毁94%账户 1:1 销毁
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _rOwned[account] -= amount;

        emit Transfer(account, address(0), amount);
    }

    //进行爆块
    function popBlock() private {
        // 判断是否开启爆块设置
        if (!_isExpBlock()) {
            return;
        }

        // 新增有效账户和时间间隔不满足需求
        uint256 len = lastAwardAddress.length;

        // 距离上次爆块如果已经过去了 24 小时，清空新增待奖励有效账户列表
        address[] memory newLastAwardAddress;
        if (
            SafeMath.sub(block.timestamp, uint256(lastPopTime)) > 60 * 60 * 24
        ) {
            lastAwardAddress = newLastAwardAddress;
            // 更新爆块时间
            lastPopTime = uint32(block.timestamp);
            return;
        }

        // 本次爆块 token 数量 181327
        uint256 currentPopToken = popToken;
        //产出爆块数量算法|每增加10000 -6%
        if (_uTotal.div(10000) > 1) {
            uint256 Minus = _uTotal.div(10000).mul(6);
            currentPopToken = popToken.sub(popToken.mul(Minus).div(100));
        }

        // 爆块时根据比例产出
        if (len <= 24) {
            currentPopToken = SafeMath.mulDiv(currentPopToken, len, 24);
            sendAward(currentPopToken, len);
        } else {
            // 如果有效账户数量大于 24，则本次只把奖励分配给前24个
            sendAward(currentPopToken, 24);
        }
        // 调用 token 奖励|单价
        sendAward(currentPopToken, len);

        //爆块1：1 销毁机制|销毁单价*所以
        _awardTransfer(_destroyAddress, currentPopToken);

        // 更新爆块时间
        lastPopTime = uint32(block.timestamp);

        // 把还没有分配奖励的有效账户留到下一次
        if (len > 24) {
            uint256 j = 0;
            for (uint256 i = 24; i < len; i++) {
                newLastAwardAddress[j] = lastAwardAddress[i];
                j++;
            }
        }
        // 如果没有超过 24 个直接清空
        lastAwardAddress = newLastAwardAddress;

        emit popBlockev(len, currentPopToken, lastPopTime);
        return;
    }

    //公共模块方法
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        return true;
    }

    function setMinAmount(uint256 minAmount) public onlyOwner {
        _minAmount = minAmount;
    }

    function setMaxAmount(uint256 maxAmount) public onlyOwner {
        _maxAmount = maxAmount;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");

        require(to != address(0), "ERC20: transfer to the zero address");

        require(amount > 0, "Transfer amount must be greater than zero");

        bool isInviter = from != uniswapV2Pair &&
            // from != tokenOwner &&
            balanceOf(to) == 0 &&
            inviter[to] == address(0);

        uint256 fromOldAm = _rOwned[from];
        uint256 toOldAm = _rOwned[to];

        _rOwned[from] = fromOldAm.sub(amount);
        _rOwned[to] = toOldAm.add(amount);

        //建立关系
        if (isInviter) {
            //判定是否已经存在关系
            bool isInit = _initUserRelation(from, to);
            if (isInit) {
                //确认有新的关系建立的时候 才改变推广等级
                _changeUProm(from);
                _changeUProm(to);
            }
            //改变等级
            _changeULevel(from, fromOldAm);
            _changeULevel(to, toOldAm);
        }

        // 满足以下条件时需要新增有效账户
        // 1. 持币量达到目前标准
        // 2. 从未被注册为有效账户过
        if (_isEffeActive(to) && !(_uActive[to])) {
            lastAwardAddress.push(to);
            _uActive[to] = true;
        }

        //触发爆块奖励
        popBlock();

        emit Transfer(from, to, amount);
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        uint256 rAmount = tAmount.mul(currentRate);

        _rOwned[to] = _rOwned[to].add(rAmount);

        emit Transfer(sender, to, tAmount);
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");

        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function changeRouter(address router) public onlyOwner {
        uniswapV2Pair = router;
    }
}