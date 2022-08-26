// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IWETHGateway} from "./deps/Aave.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract YieldGate {
    event PoolDeployed(address indexed beneficiary, address indexed deployer, address pool);

    address private immutable beneficiaryPoolLib;
    address public immutable aavePool;
    IWETHGateway public immutable wethgw;
    IERC20 public immutable token;

    // beneficiary => BeneficiaryPool
    mapping(address => BeneficiaryPool) public beneficiaryPools;

    constructor(
        address _pool,
        address wethGateway,
        address aWETH
    ) {
        aavePool = _pool;
        wethgw = IWETHGateway(wethGateway);
        token = IERC20(aWETH);

        BeneficiaryPool bp = new BeneficiaryPool();
        // init it so no one else can (RIP Parity Multisig)
        bp.init(address(this), msg.sender);
        beneficiaryPoolLib = address(bp);
    }

    function deployPool(address beneficiary) external returns (address) {
        BeneficiaryPool bpool = BeneficiaryPool(Clones.clone(beneficiaryPoolLib));
        bpool.init(address(this), beneficiary);
        beneficiaryPools[beneficiary] = bpool;

        emit PoolDeployed(beneficiary, msg.sender, address(bpool));
        return address(bpool);
    }

    // claimable returns the total earned ether by the provided beneficiary.
    // It is the accrued interest on all staked ether.
    // It can be withdrawn by the beneficiary with claim.
    function claimable(address beneficiary) public view returns (uint256) {
        BeneficiaryPool bpool = beneficiaryPools[beneficiary];
        if (address(bpool) == address(0)) {
            return 0;
        }
        return bpool.claimable();
    }

    // staked returns the total staked ether on behalf of the beneficiary.
    function staked(address beneficiary) public view returns (uint256) {
        BeneficiaryPool bpool = beneficiaryPools[beneficiary];
        if (address(bpool) == address(0)) {
            return 0;
        }
        return bpool.staked();
    }

    // returns the total staked ether by the supporter and the timeout until
    // which the stake is locked.
    function supporterStaked(address supporter, address beneficiary)
        public
        view
        returns (uint256, uint256)
    {
        BeneficiaryPool bpool = beneficiaryPools[beneficiary];
        if (address(bpool) == address(0)) {
            return (0, 0);
        }
        return (bpool.stakes(supporter), bpool.lockTimeouts(supporter));
    }
}

contract BeneficiaryPool {
    event Staked(
        address indexed beneficiary,
        address indexed supporter,
        uint256 amount,
        uint256 lockTimeout
    );
    event Unstaked(address indexed beneficiary, address indexed supporter, uint256 amount);
    event Claimed(address indexed beneficiary, uint256 amount);
    event ParametersChanged(address indexed beneficiary, uint256 minAmount, uint256 minDuration);

    YieldGate public gate;
    address public beneficiary;

    // Minimum required amount to stake.
    uint256 public minAmount;
    // Minimum required staking duration (in seconds).
    uint256 public minDuration;
    // Records when a supporter is allowed to unstake again. This has the added
    // benefit that future changes to the duration do not affect current stakes.
    mapping(address => uint256) public lockTimeouts;

    // supporter => amount
    mapping(address => uint256) public stakes;
    // total staked amount
    uint256 internal totalStake;

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "only beneficiary");
        _;
    }

    // Initializes this contract's parameters after deployment. This is called
    // by the pool factory, i.e. the Yieldgate main contract, right after
    // deployment. Can only be called once.
    function init(address _gate, address _beneficiary) public {
        require(address(gate) == address(0), "already initialized");

        gate = YieldGate(_gate);
        beneficiary = _beneficiary;

        emitParametersChanged(0, 0);
    }

    // To save gas, add individual parameter setters.

    function setMinAmount(uint256 _minAmount) external onlyBeneficiary {
        minAmount = _minAmount;
        emitParametersChanged(_minAmount, minDuration);
    }

    function setMinDuration(uint256 _minDuration) external onlyBeneficiary {
        minDuration = _minDuration;
        emitParametersChanged(minAmount, _minDuration);
    }

    function setParameters(uint256 _minAmount, uint256 _minDuration) external onlyBeneficiary {
        minAmount = _minAmount;
        minDuration = _minDuration;
        emitParametersChanged(_minAmount, _minDuration);
    }

    function emitParametersChanged(uint256 _minAmount, uint256 _minDuration) internal {
        emit ParametersChanged(beneficiary, _minAmount, _minDuration);
    }

    // Stakes the sent ether on behalf of the provided supporter. The supporter
    // is usually msg.sender if staking on the transaction sender's behalf.
    // The staking timeout is reset on each call, so prior stake is re-locked.
    function stake(address supporter) public payable {
        uint256 amount = msg.value;
        require(amount > 0 && stakes[supporter] + amount >= minAmount, "amount too low");

        stakes[supporter] += amount;
        totalStake += amount;
        uint256 timeout = 0;
        if (minDuration > 0) {
            timeout = block.timestamp + minDuration;
        }
        lockTimeouts[supporter] = timeout;

        gate.wethgw().depositETH{value: amount}(gate.aavePool(), address(this), 0);
        emit Staked(beneficiary, supporter, amount, timeout);
    }

    // Unstakes all previously staked ether by the calling supporter.
    // The beneficiary keeps all generated yield.
    // If a minimum staking duration was set by the beneficiary at the time of
    // staking, it is checked that the timeout has elapsed.
    function unstake() public returns (uint256) {
        address supporter = msg.sender;

        // Skip timeout check if minDuration == 0 because a supporter can then
        // trivially reset their lock timeout by staking and then immediately
        // unstaking anyways.
        if (minDuration > 0) {
            uint256 timeout = lockTimeouts[supporter]; // 0 ok
            require(block.timestamp >= timeout, "stake still locked");
        }

        uint256 amount = stakes[supporter];
        require(amount > 0, "no supporter");

        stakes[supporter] = 0;
        totalStake -= amount;

        withdraw(amount, supporter);
        emit Unstaked(beneficiary, supporter, amount);
        return amount;
    }

    // claim sends the accrued interest to the beneficiary of this pool. Staked
    // ether remains at the yield pool and continues generating yield.
    function claim() public onlyBeneficiary returns (uint256) {
        uint256 amount = claimable();
        withdraw(amount, beneficiary);
        emit Claimed(beneficiary, amount);
        return amount;
    }

    function withdraw(uint256 amount, address receiver) internal {
        require(gate.token().approve(address(gate.wethgw()), amount), "ethgw approval failed");
        gate.wethgw().withdrawETH(gate.aavePool(), amount, receiver);
    }

    // claimable returns the total earned ether by the provided beneficiary.
    // It is the accrued interest on all staked ether.
    // It can be withdrawn by the beneficiary with claim.
    function claimable() public view returns (uint256) {
        return gate.token().balanceOf(address(this)) - staked();
    }

    // staked returns the total staked ether by this beneficiary pool.
    function staked() public view returns (uint256) {
        return totalStake;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IWETHGateway {
    function depositETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(
        address pool,
        uint256 amount,
        address onBehalfOf
    ) external;
}