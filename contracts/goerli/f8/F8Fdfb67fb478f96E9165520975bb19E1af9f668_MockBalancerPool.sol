// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0;

import {MockERC20, ERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {JoinPoolRequest, ExitPoolRequest} from "policies/BoostedLiquidity/interfaces/IBalancer.sol";

// Define Mock Balancer Vault
contract MockVault {
    MockERC20 public bpt;
    address public token0;
    address public token1;
    uint256 public token0Amount;
    uint256 public token1Amount;

    constructor(address bpt_, address token0_, address token1_) {
        bpt = MockERC20(bpt_);
        token0 = token0_;
        token1 = token1_;
    }

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest calldata request
    ) external virtual {
        ERC20(request.assets[0]).transferFrom(sender, address(this), request.maxAmountsIn[0]);
        ERC20(request.assets[1]).transferFrom(sender, address(this), request.maxAmountsIn[1]);
        bpt.mint(recipient, request.maxAmountsIn[1]);
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        ExitPoolRequest calldata request
    ) external virtual {
        (, uint256 bptAmount) = abi.decode(request.userData, (uint256, uint256));
        bpt.burn(sender, bptAmount);
        ERC20(request.assets[0]).transfer(
            recipient,
            ERC20(request.assets[0]).balanceOf(address(this))
        );
        ERC20(request.assets[1]).transfer(
            recipient,
            ERC20(request.assets[1]).balanceOf(address(this))
        );
    }

    function getPoolTokens(
        bytes32 poolId
    ) external view returns (address[] memory, uint256[] memory, uint256) {
        address[] memory tokens = new address[](2);
        tokens[0] = token0;
        tokens[1] = token1;

        uint256[] memory balances = new uint256[](2);
        balances[0] = token0Amount;
        balances[1] = token1Amount;

        return (tokens, balances, block.timestamp);
    }

    function setPoolAmounts(uint256 token0Amount_, uint256 token1Amount_) external {
        token0Amount = token0Amount_;
        token1Amount = token1Amount_;
    }
}

/// @notice     Mock Balancer Vault with fixed BPT amount
contract MockBalancerVault is MockVault {
    uint256 public _bptMultiplier;

    constructor(
        address bpt_,
        address token0_,
        address token1_,
        uint256 bptMultiplier_
    ) MockVault(bpt_, token0_, token1_) {
        _bptMultiplier = bptMultiplier_;
    }

    /// @dev    Calculate BPT amount based on token amounts
    ///         This ensures that if the inputs change, the resulting number also changes
    function _calculateBptOut(
        uint256 token0Amount_,
        uint256 token1Amount_
    ) internal view returns (uint256) {
        return (token0Amount_ * _bptMultiplier) + (token1Amount_ * _bptMultiplier);
    }

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest calldata request
    ) external override {
        ERC20(request.assets[0]).transferFrom(sender, address(this), request.maxAmountsIn[0]);
        ERC20(request.assets[1]).transferFrom(sender, address(this), request.maxAmountsIn[1]);
        bpt.mint(recipient, _calculateBptOut(request.maxAmountsIn[0], request.maxAmountsIn[1]));
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        ExitPoolRequest calldata request
    ) external override {
        (, uint256 bptAmount) = abi.decode(request.userData, (uint256, uint256));
        bpt.burn(sender, bptAmount);
        ERC20(request.assets[0]).transfer(
            recipient,
            ERC20(request.assets[0]).balanceOf(address(this))
        );
        ERC20(request.assets[1]).transfer(
            recipient,
            ERC20(request.assets[1]).balanceOf(address(this))
        );
    }
}

// Define Mock Balancer Pool
contract MockBalancerPool is MockERC20 {
    constructor() MockERC20("Mock Balancer Pool", "BPT", 18) {}

    function getPoolId() external pure returns (bytes32) {
        return bytes32(0);
    }

    function setTotalSupply(uint256 totalSupply_) external {
        totalSupply = totalSupply_;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../../../tokens/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {}

    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

// Import types
import {ERC20} from "solmate/tokens/ERC20.sol";

// Define Data Structures
struct JoinPoolRequest {
    address[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
}

struct ExitPoolRequest {
    address[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
}

// Define Vault Interface
interface IVault {
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    function getPoolTokens(
        bytes32 poolId
    ) external view returns (address[] memory, uint256[] memory, uint256);
}

// Define Balancer Base Pool Interface
interface IBasePool {
    function getPoolId() external view returns (bytes32);

    function balanceOf(address user_) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function approve(address spender_, uint256 amount_) external returns (bool);
}

// Define Balancer Pool Factory Interface
interface IFactory {
    function create(
        string memory name,
        string memory symbol,
        ERC20[] memory tokens,
        uint256[] memory weights,
        uint256 swapFeePercentage,
        address owner
    ) external returns (address);
}

interface IBalancerHelper {
    function queryJoin(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external returns (uint256 bptOut, uint256[] memory amountsIn);

    function queryExit(
        bytes32 poolId,
        address sender,
        address recipient,
        ExitPoolRequest memory request
    ) external returns (uint256 bptIn, uint256[] memory amountsOut);
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