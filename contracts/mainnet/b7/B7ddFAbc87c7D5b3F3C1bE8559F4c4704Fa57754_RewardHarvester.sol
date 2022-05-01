// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase
pragma solidity ^0.8.10;

import "@rari-capital/solmate/src/tokens/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/Tether.sol";
import "../interfaces/curve/ICurveThreeCryptoPool.sol";
import "../interfaces/curve/ICurveThreePool.sol";
import "../interfaces/curve/ICurvePool.sol";

interface ICurveVoter {
    function lock() external;

    function claimAll(address recipient) external returns (uint256 amount);

    function claim(address recipient) external returns (uint256 amount);
}

contract RewardHarvester is Ownable {
    error InsufficientOutput();
    error NotAllowed();

    ERC20 public constant CRV = ERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    ERC20 public constant CRV3 = ERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    ERC20 public constant WETH = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    CurveThreePool public constant CRV3POOL = CurveThreePool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    CurvePool public constant CRVETH = CurvePool(0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511);
    Tether public constant USDT = Tether(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    CurveThreeCryptoPool public constant TRICRYPTO = CurveThreeCryptoPool(0xD51a44d3FaE010294C616388b506AcdA1bfAAE46);
    ICurveVoter public immutable curveVoter;

    mapping(address => bool) public allowedHarvesters;

    modifier onlyAllowedHarvesters() {
        if (!allowedHarvesters[msg.sender] && msg.sender != owner()) {
            revert NotAllowed();
        }
        _;
    }

    constructor(ICurveVoter _curveVoter) {
        curveVoter = _curveVoter;
        USDT.approve(address(TRICRYPTO), type(uint256).max);
        WETH.approve(address(CRVETH), type(uint256).max);
    }

    function setAllowedHarvester(address account, bool allowed) external onlyOwner {
        allowedHarvesters[account] = allowed;
    }

    function harvest(uint256 minAmountOut) external onlyAllowedHarvesters returns (uint256 amountOut) {
        uint256 crvAmount = curveVoter.claim(address(this));

        if (crvAmount != 0) {
            amountOut = _harvest(crvAmount, minAmountOut);
        }
    }

    function harvestAll(uint256 minAmountOut) external onlyAllowedHarvesters returns (uint256 amountOut) {
        uint256 crvAmount = curveVoter.claimAll(address(this));

        if (crvAmount != 0) {
            amountOut = _harvest(crvAmount, minAmountOut);
        }
    }

    function _harvest(uint256 crvAmount, uint256 minAmountOut) private returns (uint256 amountOut) {
        // 3CRV -> USDT
        CRV3POOL.remove_liquidity_one_coin(crvAmount, 2, 0);

        // USDT -> WETH
        TRICRYPTO.exchange(0, 2, USDT.balanceOf(address(this)), 0);

        // WETH -> CRV
        amountOut = CRVETH.exchange(0, 1, WETH.balanceOf(address(this)), 0);

        if (amountOut < minAmountOut) {
            revert InsufficientOutput();
        }

        CRV.transfer(address(curveVoter), amountOut);
        curveVoter.lock();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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

    /*///////////////////////////////////////////////////////////////
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
pragma solidity >=0.6.12;

interface Tether {
    function approve(address spender, uint256 value) external;

    function balanceOf(address user) external view returns (uint256);

    function transfer(address to, uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface CurveThreeCryptoPool {
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) payable external;

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function add_liquidity(uint256[3] memory amounts, uint256 _min_mint_amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface CurveThreePool {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function add_liquidity(uint256[3] memory amounts, uint256 _min_mint_amount) external;

    function remove_liquidity_one_coin(
        uint256 amount,
        int128 i,
        uint256 minAmount
    ) external;
}

// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase, var-name-mixedcase
pragma solidity >=0.6.12;

interface CurvePool {
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        address receiver
    ) external returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        address receiver
    ) external returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function approve(address _spender, uint256 _value) external returns (bool);

    function add_liquidity(uint256[2] memory amounts, uint256 _min_mint_amount) external;

    function add_liquidity(uint256[3] memory amounts, uint256 _min_mint_amount) external;

    function add_liquidity(uint256[4] memory amounts, uint256 _min_mint_amount) external;

    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 i,
        uint256 min_amount
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        uint256 i,
        uint256 min_amount
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 i,
        uint256 min_amount,
        address receiver
    ) external returns (uint256);
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