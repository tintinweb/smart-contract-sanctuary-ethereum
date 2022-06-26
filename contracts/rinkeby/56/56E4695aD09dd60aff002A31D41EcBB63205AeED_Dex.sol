// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TestTokenDex.sol";

contract Dex is Ownable {
  TestTokenDex public token;

  /**
   * @notice Amount of TTD that you can buy with 1 ETH.
   * @dev Since TTD has 2 decimal precision, let's
   * define 0.01 TTD = 1 cTTD (smallest TTD unit).
   * Then, if "10_000 wei gets you 1 TTD", it follows
   * that 1 ETH = 1*(10**18) wei gets you 1*(10**14) TTD
   * which is equivalent to 1*(10**16) cTTD.
   */
  uint256 public constant BUY_RATE = 10**16; // in cTTD
  /**
   * @notice Amount of ETH that you get when selling 1 TTD.
   * @dev We follow the "1 TTD gets you 5000 wei" rule.
   */
  uint256 public constant SELL_RATE = 5*(10**3); // in wei
  uint256 public buysCount; // we should be able to use something smaller such as uint112
  uint256 public sellsCount;
  uint256 public maxBuy;
  uint256 public maxSell;

  event TokenDeployed(address _tokenAddr);
  event BuyExecuted(address indexed _from, uint256 _ttdOut);
  event MaxBuyExecuted(address indexed _from, uint256 _ttdOut);
  event SellExecuted(address indexed _from, uint256 _ethOut);
  event MaxSellExecuted(address indexed _from, uint256 _ethOut);

  constructor() {
    token = new TestTokenDex();
    // ^ msg.sender === address(this)
    address tokenAddr = address(token);
    emit TokenDeployed(tokenAddr);
  }

  /**
   * @notice Return ETH balance for the `Dex` contract.
   */
  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  /**
   * @notice User deposits ETH getting TTD back using
   * "10_000 wei gets you 1 TTD" as the exchange rate.
   */
  function buy() external payable {
    // Amount of TTD (cTTD) to be sent to the buyer.
    uint256 ttdOut = (msg.value * BUY_RATE) / 10**18;
    // Unused ETH (wei) that should be returned to the buyer.
    uint256 remainder = msg.value - 2 * (ttdOut * SELL_RATE) / 10**2;
    // Amount of ETH (wei) added to the Dex's balance.
    uint256 ethIn = msg.value - remainder;

    // Make sure there is enough liquidity to perform the trade.
    require(token.balanceOf(address(this)) >= ttdOut, "Dex: not enough TTD liquidity");

    // Keep track of the number of buys and max buy.
    buysCount += 1;
    if (ttdOut > maxBuy) {
      maxBuy = ttdOut;
      emit MaxBuyExecuted(msg.sender, ttdOut);
    }

    // Send TTD tokens and remainder ETH to the buyer.
    bool ttdSentBuyer = token.transfer(msg.sender, ttdOut);
    require(ttdSentBuyer, "Dex: failed to send TTD to buyer");
    (bool ethSentBuyer,) = payable(msg.sender).call{value: remainder}("");
    require(ethSentBuyer, "Dex: failed to send ETH to buyer");

    // Send 50% of ETH to Dex's owner.
    (bool ethSentOwner,) = payable(owner()).call{value: ethIn / 2}("");
    require(ethSentOwner, "Dex: failed to send ETH to owner");

    emit BuyExecuted(msg.sender, ttdOut);
  }

  /**
   * @notice User deposits TTD getting ETH back using
   * "1 TTD gets you 5000 wei" as the exchange rate.
   * @dev Before selling the transfer must
   * be approved in the TTD contract.
   * @param _ttdIn The amount of cTTD tokens to be
   * exchanged.
   */
  function sell(uint256 _ttdIn) external {
    // Calculate expected ETH out.
    uint256 ethOut = (_ttdIn * SELL_RATE) / 10**2;

    // Notice: there is no need to check for ETH liquidity due to
    // the mechanics of the DEX. More concretely, whenever someone
    // sells TTD, she first had to deposit an equivalent amount of
    // ETH to buy the TTD in the first place. Therefore, there is always
    // enough ETH liquidity to perform the trade.
    // require(getBalance() >= ethOut, "Dex: not enough ETH liquidity");

    // Keep track of the number of sells and max sell.
    sellsCount += 1;
    if (ethOut > maxSell) {
      maxSell = ethOut;
      emit MaxSellExecuted(msg.sender, ethOut);
    }

    // Transfer tokens from seller's account to contract.
    bool ttdReceived = token.transferFrom(msg.sender, address(this), _ttdIn);
    require(ttdReceived, "Dex: failed to send TTD to contract");

    // Transfer ETH to seller.
    (bool ethSent,) = payable(msg.sender).call{value: ethOut}("");
    require(ethSent, "Dex: failed to send ETH to seller");

    emit SellExecuted(msg.sender, ethOut);
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
pragma solidity ^0.8.4;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

contract TestTokenDex is ERC20 {
  uint8 private constant DECIMALS = 2;

  constructor() ERC20 ("TestTokenDex", "TTD", DECIMALS) {
    _mint(msg.sender, 500000000000000 * (10 ** DECIMALS));
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
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
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