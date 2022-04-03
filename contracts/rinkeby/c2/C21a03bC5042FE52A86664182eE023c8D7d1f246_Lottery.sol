// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Lottery is OwnableUpgradeable {
    // 管理员地址
    address payable manager;

    // 开奖号码数量
    uint8 constant numQuantity = 4;
    // 开奖号码的最大取值范围（不包含max）
    uint8 constant max = 10;

    // 彩民投注号码
    struct PlayerBet {
        address payable player;
        uint8[numQuantity] bet;
    }

    // 奖项
    enum Awards {FIRST, SECOND, THIRD}

    // 中奖人中奖号码及奖项
    struct WinnerBetGrade {
        address payable winner;
        uint8[numQuantity] bet;
        uint8 awards;
    }

    // 抽奖数据
    struct LotteryData {
        // 所有彩民的投注号码
        PlayerBet[] playersBet;
        // 彩民的投注号码
        mapping(address => uint8[numQuantity]) playerBet;
        // 开奖号码
        uint8[numQuantity] lotteryNums;
        // 所有中奖人中奖号码及奖项
        WinnerBetGrade[] winnersBetGrade;
        // 每个奖项的中奖人数
        mapping(uint8 => uint) awardWinnerCount;
    }

    // 彩票期数
    uint round;
    // 每期开奖中奖数据
    mapping(uint => LotteryData) LotteryDatas;

    function initialize() public initializer {
        __Ownable_init();

        manager = payable(owner());
        round = 1;
    }

    /*
     * 投注
     * bet  投注号码
     */
    function play(uint8[numQuantity] memory bet) payable public {
        // 每次投注1Eth
        require(msg.value == 1 ether);
        // 输入的投注号码必须小于max
        for (uint8 i = 0; i < bet.length; i++) {
            require(bet[i] < max);
        }
        PlayerBet memory playerBet = PlayerBet(payable(_msgSender()), bet);
        LotteryDatas[round].playersBet.push(playerBet);
        LotteryDatas[round].playerBet[_msgSender()] = bet;
    }

    /*
     * 开奖
     */
    function runLottery() public onlyOwner {
        LotteryData storage data = LotteryDatas[round];

        // 至少1个参与者才能开奖
        require(data.playersBet.length > 0);

        // 随机生成的开奖号码
        for (uint8 i = 0; i < numQuantity; i++) {
            uint v = uint(sha256(abi.encodePacked(block.timestamp, data.playersBet.length, i)));
            // 将随机获取的Hash值对max取余，保证号码在0~max之间（不包含max）
            data.lotteryNums[i] = uint8(v % uint(max));
        }

        for (uint i = 0; i < data.playersBet.length; i++) {
            uint8 count;
            // 记录彩民投注号码顺序符合开奖号码的个数
            uint8[numQuantity] memory bet = data.playersBet[i].bet;
            // 遍历开奖号码与彩民投注号码，顺序符合则count加1
            for (uint8 j = 0; j < numQuantity; j++) {
                if (data.lotteryNums[j] == bet[j]) {
                    count ++;
                }
            }
            // 如果numQuantity（4）个号码顺序相同，则中一等奖；3个号码相同则中二等奖；2个号码相同则中三等奖
            if (count == numQuantity) {
                WinnerBetGrade memory winnerBetGrade = WinnerBetGrade(data.playersBet[i].player, bet, uint8(Awards.FIRST));
                data.winnersBetGrade.push(winnerBetGrade);
                // 一等奖的中奖人数加1
                data.awardWinnerCount[uint8(Awards.FIRST)]++;
            } else if (count == numQuantity - 1) {
                WinnerBetGrade memory winnerBetGrade = WinnerBetGrade(data.playersBet[i].player, bet, uint8(Awards.SECOND));
                data.winnersBetGrade.push(winnerBetGrade);
                // 二等奖的中奖人数加1
                data.awardWinnerCount[uint8(Awards.SECOND)]++;
            } else if (count == numQuantity - 2) {
                WinnerBetGrade memory winnerBetGrade = WinnerBetGrade(data.playersBet[i].player, bet, uint8(Awards.THIRD));
                data.winnersBetGrade.push(winnerBetGrade);
                // 三等奖的中奖人数加1
                data.awardWinnerCount[uint8(Awards.THIRD)]++;
            }
        }

        dividePrizePool(data); // 瓜分奖池

        round++;
    }

    /*
     * 瓜分奖池
     */
    function dividePrizePool(LotteryData storage data) private {
        // 瓜分的总金额
        uint totalAmount = address(this).balance;
        // 每注一等奖瓜分的金额
        uint firstDivide = 0;
        // 每注二等奖瓜分的金额
        uint secondDivide = 0;
        // 每注三等奖瓜分的金额
        uint thirdDivide = 0;

        // 管理员收取全部金额的2%作为手续费
        uint managerDivide = totalAmount * 2 / 100;
        // 一等奖瓜分全部金额的80%
        if (data.awardWinnerCount[uint8(Awards.FIRST)] != 0) {
            firstDivide = totalAmount * 80 / (100 * data.awardWinnerCount[uint8(Awards.FIRST)]);
        }
        // 二等奖瓜分全部金额的15%
        if (data.awardWinnerCount[uint8(Awards.SECOND)] != 0) {
            secondDivide = totalAmount * 15 / (100 * data.awardWinnerCount[uint8(Awards.SECOND)]);
        }
        // 三等奖瓜分全部金额的3%
        if (data.awardWinnerCount[uint8(Awards.THIRD)] != 0) {
            thirdDivide = totalAmount * 3 / (100 * data.awardWinnerCount[uint8(Awards.THIRD)]);
        }

        // 向管理员转账
        manager.transfer(managerDivide);
        for (uint i = 0; i < data.winnersBetGrade.length; i++) {
            if (data.winnersBetGrade[i].awards == uint8(Awards.FIRST)) {
                // 向一等奖中奖者转账
                data.winnersBetGrade[i].winner.transfer(firstDivide);
            } else if (data.winnersBetGrade[i].awards == uint8(Awards.SECOND)) {
                // 向二等奖中奖者转账
                data.winnersBetGrade[i].winner.transfer(secondDivide);
            }  else if (data.winnersBetGrade[i].awards == uint8(Awards.THIRD)) {
                // 向三等奖中奖者转账
                data.winnersBetGrade[i].winner.transfer(thirdDivide);
            }
        }
    }

    /*
     * 获取合约余额
     */
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    /*
     * 获取当期彩民投注号码数组长度
     */
    function getPlayersBetLength() public view returns (uint) {
        return LotteryDatas[round].playersBet.length;
    }

    /*
     * 获取彩民某期投注号码
     */
    function getPlayersBet(uint _round) public view returns (uint8[numQuantity] memory) {
        return LotteryDatas[_round].playerBet[_msgSender()];
    }

    /*
     * 获取开奖号码
     */
    function getLotteryNums(uint _round) public view returns (uint8[numQuantity] memory) {
        return LotteryDatas[_round].lotteryNums;
    }

    /*
     * 获取某期中奖人总个数
     */
    function getWinnersBetGradeLength(uint _round) public view returns (uint) {
        return LotteryDatas[_round].winnersBetGrade.length;
    }

    /*
     * 获取某期某奖项中奖人个数
     */
    function getWinnersBetGradeLength(uint _round, uint8 _award) public view returns (uint) {
        return LotteryDatas[_round].awardWinnerCount[_award];
    }

    /*
     * 获取某期中奖人中奖号码及奖项
     */
    function getWinnersBetGradeLength(uint _round, uint _index) public view returns (WinnerBetGrade memory) {
        return LotteryDatas[_round].winnersBetGrade[_index];
    }

    /*
     * 获取彩票期数
     */
    function getRound() public view returns (uint) {
        return round;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}