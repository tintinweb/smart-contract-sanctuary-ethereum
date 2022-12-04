// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma abicoder v2;

import {Auth, Authority} from "../lib/solmate/src/auth/Auth.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {ReentrancyGuard} from "../lib/solmate/src/utils/ReentrancyGuard.sol";
import {Ascent} from "./Payoffs/Ascent.sol";
import {ILido} from "./Lido/interface.sol";
import {AggregatorV3Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Gateway is Auth, ReentrancyGuard {
    address public lidoAddress =
        address(0x1643E812aE58766192Cf7D2Cf9567dF2C37e9B7F);
    uint256 public totalPremium;
    mapping(address => uint256) mapPremium;
    uint256 public collateral;
    address public immutable seller;
    ERC20 public immutable wETH;
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    Ascent public immutable payoff;
    ILido public immutable lido;
    address public immutable buyerPool;
    uint256 public totalAmount;
    bool public IsSettled = false;
    AggregatorV3Interface public immutable ethUSD;
    AggregatorV3Interface public immutable stethETH;
    ERC20 public immutable stETH;

    uint256 public immutable HEALTH_FACTOR;

    constructor(
        address _seller,
        address wETH_addr,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        address _ascentAddress,
        address _buyerPool,
        uint256 _HEALTH_FACTOR
    ) Auth(msg.sender, Authority(address(0x0))) {
        seller = _seller;
        wETH = ERC20(wETH_addr);
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        payoff = Ascent(_ascentAddress);
        lido = ILido(lidoAddress);
        buyerPool = _buyerPool;
        ethUSD = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        stethETH = AggregatorV3Interface(
            0x86392dC19c0b719886221c78AB11eb8Cf5c52812
        );
        stETH = ERC20(0x1643E812aE58766192Cf7D2Cf9567dF2C37e9B7F);
        HEALTH_FACTOR = _HEALTH_FACTOR;
    }

    function depositBuyer(address user, uint256 amt) public nonReentrant {
        require(block.timestamp < startTimestamp);
        totalPremium += amt;
        mapPremium[user] += amt;
        totalAmount += amt;
        wETH.transferFrom(msg.sender, address(this), amt);
    }

    function depositSeller(uint256 amt) public nonReentrant {
        require(block.timestamp < startTimestamp);
        require(msg.sender == seller);
        collateral += amt;
        totalAmount += amt;
        wETH.transferFrom(msg.sender, address(this), amt);
    }

    function trade(uint256 amt) public nonReentrant {
        require(block.timestamp > startTimestamp);
        require(msg.sender == seller);
        require(totalAmount >= amt);
        lido.submit{value: amt}(address(this));
        totalAmount -= amt;
    }

    function checkLiquidation() public returns (bool) {
        uint256 stETHPrice = getCurrentSTETHPrice();
        uint256 stETHBalance = stETH.balanceOf(address(this));
        uint256 currentPosition = totalAmount +
            (stETHBalance * stETHPrice) /
            1e18;
        uint256 marginRequired = totalPremium +
            payoff.getMaxPayoff(totalPremium);
        marginRequired = (marginRequired * HEALTH_FACTOR) / 1e18;
        return currentPosition < marginRequired;
    }

    function liquidate() public {
        require(checkLiquidation());
        require(IsSettled == false);
        uint256 maxPayoff = totalPremium + payoff.getMaxPayoff(totalPremium);
        if (maxPayoff > totalAmount)
            wETH.transferFrom(
                msg.sender,
                address(this),
                maxPayoff - totalAmount
            );
        wETH.transferFrom(address(this), buyerPool, maxPayoff);
        uint256 stETHBalance = stETH.balanceOf(address(this));
        stETH.transfer(msg.sender, stETHBalance);
        IsSettled = true;
    }

    function settle() public {
        require(block.timestamp > endTimestamp);
        require(IsSettled == false);

        uint256 stETHBalance = stETH.balanceOf(address(this));
        uint256 ethValue = (stETHBalance * getCurrentSTETHPrice()) / 1e18;
        wETH.transferFrom(msg.sender, address(this), ethValue);
        totalAmount += ethValue;
        stETH.transfer(msg.sender, stETHBalance);
        uint256 ethPrice = getCurrentEthPrice();
        uint256 buyerPayoff = payoff.getValue(totalPremium, ethPrice) +
            totalPremium;
        totalAmount -= buyerPayoff;
        wETH.transfer(buyerPool, buyerPayoff);
        wETH.transfer(seller, totalAmount);
    }

    function getCurrentEthPrice() public returns (uint256) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = ethUSD.latestRoundData();
        return uint256(price);
    }

    function getCurrentSTETHPrice() public returns (uint256) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = stethETH.latestRoundData();
        return uint256(price);
    }

    function setTimestamps(uint256 start, uint256 end) public {
        startTimestamp = start;
        endTimestamp = end;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnershipTransferred(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function transferOwnership(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

contract Ascent {
    uint256 public immutable low;
    uint256 public immutable high;
    uint256 public immutable slope;
    uint256 public immutable maxApy;
    uint256 public immutable baseApy;

    constructor(
        uint256 _low,
        uint256 _high,
        uint256 _maxApy,
        uint256 _baseApy
    ) {
        baseApy = _baseApy;
        maxApy = _maxApy;
        low = _low;
        high = _high;
        slope = ((maxApy - baseApy) * 1e18) / (_high + _low);
    }

    function getStrike(uint256 spot) public returns (uint256) {
        return spot - (spot * low) / 1e18;
    }

    function getBarrier(uint256 spot) public returns (uint256) {
        return spot + (spot * low) / 1e18;
    }

    function getValue(uint256 spot, uint256 price) public returns (uint256) {
        uint256 strike = getStrike(spot);
        uint256 barrier = getBarrier(spot);
        if (price <= strike || price >= barrier) {
            return (baseApy * spot) / 1e18;
        } else {
            uint256 payoffPer = baseApy + ((price - strike) * slope) / 1e18;
            return (payoffPer * spot) / 1e18;
        }
    }

    function getMaxPayoff(uint256 spot) public returns (uint256) {
        return (maxApy * spot) / 1e18;
    }
}

interface ILido {
    function submit(address _referral) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}