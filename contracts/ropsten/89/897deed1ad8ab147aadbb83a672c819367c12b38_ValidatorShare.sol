// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner, bool state);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => bool) public owner;

    modifier onlyOwner() virtual {
        require(owner[msg.sender] == true, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner[_owner] = true;

        emit OwnerUpdated(address(0), _owner, true);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address _newOwner, bool _state) public virtual onlyOwner {
        owner[_newOwner] = _state;

        emit OwnerUpdated(msg.sender, _newOwner, _state);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IERC20 } from "./token/IERC20.sol";
import { ERC20NonTradeable } from "./token/ERC20NonTradeable.sol";
import { Owned } from "./Owned.sol";

contract ValidatorShare is ERC20NonTradeable, Owned {
    struct DelegatorUnbond {
        uint256 shares;
        uint256 withdrawBlock;
    }

    uint256 public validatorId = 0; // Random account
    IERC20 public stakingToken;

    uint256 public rewards;
    uint256 public rewardsDuration; // This will be the number of blocks in which we give rewards 
    uint256 public rewardsEndpoint; // This will be the block in which we stop giving rewards
    uint256 public totalStaked;
    uint256 public withdrawalDelay;
    mapping(address => mapping(uint256 => DelegatorUnbond)) public unbonds_new;
    mapping(address => uint256) public unbondNonces;

    event ShareMinted(
        uint256 indexed validatorId,
        address indexed user,
        uint256 indexed amount,
        uint256 tokens
    );
    event StakeUpdate(
        uint256 indexed validatorId,
        uint256 indexed nonce,
        uint256 indexed newAmount
    );
    event ShareBurnedWithId(
        uint256 indexed validatorId,
        address indexed user,
        uint256 indexed amount,
        uint256 tokens,
        uint256 nonce
    );
    event DelegatorUnstaked(
        uint256 indexed validatorId,
        address indexed user,
        uint256 amount
    );

    constructor(address _token, uint256 _delay, uint256 _rewardsDuration) ERC20NonTradeable("VShare", "VSH", 18) Owned(msg.sender) {
      withdrawalDelay = _delay;
      rewardsDuration = _rewardsDuration;
      rewardsEndpoint = block.timestamp + _rewardsDuration;
      stakingToken = IERC20(_token);
    }

    function buyVoucher(uint256 _amount, uint256 _minSharesToMint) public returns(uint256 amountToDeposit) {
      _withdrawAndTransferReward(msg.sender);
      stakingToken.transferFrom(msg.sender, address(this), _amount);
      _mint(msg.sender, _amount);
      totalStaked += _amount;

      emit ShareMinted(validatorId, msg.sender, _amount, _amount);
      emit StakeUpdate(
          validatorId,
          0,
          totalStaked
      );

      return _amount;
    }

    function sellVoucher_new(uint256 claimAmount, uint256 maximumSharesToBurn) public {
      _withdrawAndTransferReward(msg.sender);
      _burn(msg.sender, claimAmount);
      DelegatorUnbond memory unbond = DelegatorUnbond({
            shares: claimAmount,
            withdrawBlock: block.timestamp
      });
      uint256 unbondNonce = unbondNonces[msg.sender] + 1;
      unbonds_new[msg.sender][unbondNonce] = unbond;

      totalStaked -= claimAmount;
      emit ShareBurnedWithId(
        validatorId, 
        msg.sender, 
        claimAmount, 
        claimAmount, 
        unbondNonce
      );

      emit StakeUpdate(
          validatorId,
          0,
          totalStaked
      );
    }


    function unstakeClaimTokens_new(uint256 unbondNonce) public {
      DelegatorUnbond memory unbond = unbonds_new[msg.sender][unbondNonce];

      require(
            unbond.withdrawBlock + withdrawalDelay <= block.timestamp && unbond.shares > 0,
            "Incomplete withdrawal period"
        );

      stakingToken.transfer(msg.sender, unbond.shares);
      delete unbonds_new[msg.sender][unbondNonce];
      emit DelegatorUnstaked(validatorId, msg.sender, unbond.shares);
    }

    function _withdrawAndTransferReward(address user) private returns (uint256) {
      uint256 userRewards = getLiquidRewards(user);
      stakingToken.transfer(msg.sender, userRewards);
      rewards -= userRewards;
      return rewards;
    }

    function restake() public returns(uint256, uint256) { }

    function getLiquidRewards(address _account) public view returns (uint256) {
      uint256 accountBalance = balanceOf[_account];
      if (accountBalance == 0) return 0;

      uint256 unlockedRewards = 
        block.timestamp > rewardsEndpoint ? 
          rewards : 
          rewards * block.timestamp / rewardsEndpoint;

      return unlockedRewards * accountBalance/totalSupply;
    }

    
    // Test Only Functions

    // @notice: If you send funds in the mid of a rewards period, it won't calculate it 
    // in a time waged way. So don't.
    function refreshWithNewFunds(uint256 _rewards) onlyOwner public {
      rewardsEndpoint = block.timestamp + rewardsDuration;
      stakingToken.transferFrom(msg.sender, address(this), _rewards);
      rewards += _rewards;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "./ERC20.sol";

abstract contract ERC20NonTradeable is ERC20 {

    constructor(string memory _name, string memory _symbol, uint8 _decimals) ERC20(_name, _symbol, _decimals) {}

    function _approve(address owner, address spender, uint256 value) internal {
        revert("disabled");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

/// @notice Interface for Solmate's ERC20 tokens to use on other contracts.
/// @author Nation3 (https://github.com/nation3/app/contracts/contracts/tokens/ERC20/IERC20.sol).
interface IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}