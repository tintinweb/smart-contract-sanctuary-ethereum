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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

// Define Booster Interface
interface IAuraBooster {
    function deposit(uint256 pid_, uint256 amount_, bool stake_) external returns (bool);
}

// Define Base Reward Pool interface
interface IAuraRewardPool {
    function balanceOf(address account_) external view returns (uint256);

    function earned(address account_) external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function rewardToken() external view returns (address);

    function extraRewardsLength() external view returns (uint256);

    function extraRewards(uint256 index) external view returns (address);

    function deposit(uint256 assets_, address receiver_) external;

    function getReward(address account_, bool claimExtras_) external;

    function withdrawAndUnwrap(uint256 amount_, bool claim_) external;
}

// Define Aura Mining Lib interface
interface IAuraMiningLib {
    function convertCrvToCvx(uint256 amount_) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {IAuraBooster, IAuraRewardPool, IAuraMiningLib} from "policies/BoostedLiquidity/interfaces/IAura.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

contract MockAuraBooster is IAuraBooster {
    address public token;
    address[] public pools;

    constructor(address token_, address pool_) {
        token = token_;
        pools.push(pool_);
    }

    function deposit(uint256 pid_, uint256 amount_, bool stake_) external returns (bool) {
        address pool = pools[pid_];

        MockERC20(token).transferFrom(msg.sender, address(this), amount_);

        MockERC20(token).approve(pool, amount_);
        IAuraRewardPool(pool).deposit(amount_, msg.sender);

        return true;
    }

    function addPool(address pool_) external {
        pools.push(pool_);
    }
}

contract MockAuraRewardPool is IAuraRewardPool {
    // Tokens
    address public depositToken;
    address public rewardToken;
    address public aura;

    // Reward Token Reward Rate (per second)
    uint256 public rewardRate = 1e18;

    // Extra Rewards
    uint256 public extraRewardsLength;
    address[] public extraRewards;

    // User balances
    mapping(address => uint256) public balanceOf;

    constructor(address depositToken_, address reward_, address aura_) {
        depositToken = depositToken_;
        rewardToken = reward_;
        aura = aura_;
    }

    function deposit(uint256 assets_, address receiver_) external {
        balanceOf[receiver_] += assets_;
        MockERC20(depositToken).transferFrom(msg.sender, address(this), assets_);
    }

    function getReward(address account_, bool claimExtras_) public {
        if (balanceOf[account_] == 0) return;

        MockERC20(rewardToken).mint(account_, 1e18);
        if (aura != address(0)) MockERC20(aura).mint(account_, 1e18);

        if (claimExtras_) {
            for (uint256 i; i < extraRewardsLength; i++) {
                IAuraRewardPool(extraRewards[i]).getReward(account_, false);
                ++i;
            }
        }
    }

    function withdrawAndUnwrap(uint256 amount_, bool claim_) external {
        MockERC20(depositToken).transfer(msg.sender, amount_);
        if (claim_) getReward(msg.sender, true);

        balanceOf[msg.sender] -= amount_;
    }

    function earned(address account_) external view returns (uint256) {
        if (balanceOf[account_] != 0) return 1e18;
        return 0;
    }

    function addExtraReward(address reward_) external {
        extraRewards.push(reward_);
        extraRewardsLength++;
    }

    function setRewardRate(uint256 rate_) external {
        rewardRate = rate_;
    }
}

contract MockAuraMiningLib is IAuraMiningLib {
    constructor() {}

    function convertCrvToCvx(uint256 amount_) external view returns (uint256) {
        return amount_;
    }
}