// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;  //// 要求Solidity版本大于0.8.13;

/// 需要导入的库
import "solmate/tokens/ERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";
//// 声明了接下来需要使用的两个错误
error NoPayMintPrice();         //// 将出现在合约执行人未转入ETH而直接交换代币的情况下
error WithdrawTransfer();     /// 发生在非智能合约创造者提取合约资金的情况下
error MaxSupply();            /// 发生在代币发行量超过阈值。

///使用is标识符表示该智能合约是对ERC20和Ownable继承
// ERC20 主要包括ERC20中的各种核心实现(引用自solmate)
// Ownable 主要实现了权限控制(引用自Openzeppelin)，避免非合约创造者在合约内提取ETH。
contract SDUFECoin is ERC20, Ownable { /// 代码声明智能合约主体

    /// 交换价格为0.00000001 ether, 定了1ETH兑换1个代币的量价关系
    //// MetaMask等钱包显示数量总是由铸造出的代币个数除以其基数。这也说明了为什么使用0.00000001 ether作为最小铸造价格，该价格可以保证你转入1eth将获得在钱包中显示为1的代币。
    uint256 public constant MINT_PRICE = 0.00000001 ether;
    
    // MetaMask等钱包显示数量总是由铸造出的代币个数除以其基数。
    // 10^10个单位代币，如果你将所有代币铸造出来放在在MetaMask钱包中，显示的数量为100个
    uint256 public constant MAX_SUPPLY  = 1_000_000; /// 规定了代币总发行量为 1_000_000_000，其为常量, 

    /// 代币基本属性的构造器
    constructor (
        string memory _name,        //代币名称
        string memory _symbol,       //代币的缩写
        uint8 _decimals                /// 代币的基数，类似于ETH中的ether单位
    ) ERC20 (_name, _symbol, _decimals) {}

    /// 最为重要的铸造函数
    /// 接受一个变量recipient即代币接受者，同时通过payable关键词也可接受转入的ETH。
    /// 该函数可以接受一个规定的变量recipient和一个隐含的变量，即转入的ETH数量(通过 msg.value 获得数值)
    /// 合约函数参考: https://ropsten.etherscan.io/address/0x6f719490dec688b8c7c394f5259ae5aa788c3a5d#writeContract
    function mintTo(address recipient) public payable {
        if (msg.value < MINT_PRICE) { /// 实现了规避交换价格低于最低价格的交易；
            revert NoPayMintPrice();
        } else {
            uint256 amount = msg.value / MINT_PRICE;
            uint256 nowAmount = totalSupply + amount;  // _mint函数和totalSupply变量实际来自solmate, totalSupply变量存储有当前的代币总发行量, 该变量也可以直接在etherscan中查阅
            if (nowAmount <= MAX_SUPPLY) { /// 实现了判断当前总发行量是否超标的逻辑
                _mint(recipient, amount); /// _mint函数是核心方法
            } else {
                revert MaxSupply();     /// 用于报错
            }
        }
    }

    /// 实现了提取合约内ETH的功能
    // 参数payee是提取地址，该合约通过external关键词对onlyOwner进行了扩展，而onlyOwner的主要作用是检查调用者是否为合约指定的Owner，默认为合约创建者，当然也可以通过Ownable.sol中实现的transferOwnership函数更改合约的Owner
    //
    //* call是一个底层函数，存在一定的安全问题，但可以减少转移时的gas耗费。该函数在未来可能会被弃用。如果想知道比较安全的提取资金的方式可以参考中文Solidity文档中的讨论或者参考著名NFT交易所Opensea给出的示例
    //* https://docs.opensea.io/docs/4-setting-a-price-and-supply-limit-for-your-contract#withdrawing-funds
    //* https://solidity-cn.readthedocs.io/zh/develop/security-considerations.html#id4
    //* 在此处的回调中，由于我们严格指定了合约调用人，而且不存在复杂的回调问题，所以使用call函数是合理的。而且通过onlyOwner实现了所谓检查-生效-交互模式。
    //* 检查-生效-交互模式: https://solidity-cn.readthedocs.io/zh/develop/security-considerations.html#checks-effects-interactions
    // onlyOwner隐含有合约创立者调用
    function withdrawPayments(address payable payee) external onlyOwner {
        uint256 balance = address(this).balance; // 第37行代码可以获得该合约内ETH的总量
        (bool transferTx, ) = payee.call{value: balance}(""); //通过一个底层函数call实现资金转移，并将转移的结果赋值给transferTx。如果该值为false，则证明调用失败。
        if (!transferTx) {
            revert WithdrawTransfer();
        }
    }
}