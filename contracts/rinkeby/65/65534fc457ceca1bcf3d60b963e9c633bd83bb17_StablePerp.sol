/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// Sources flattened with hardhat v2.10.0 https://hardhat.org

/**
SPDX-License-Identifier: BUSL-1.1
Copyright(C) 2022 Eric Falkenstein
*/

// File contracts/ERC20b.sol

pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20b {
  /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event Transfer(address indexed from, address indexed to, uint256 amount);

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 amount
  );

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

  function approve(address spender, uint256 amount)
    public
    virtual
    returns (bool)
  {
    allowance[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);

    return true;
  }

  function _transfer(address to, uint256 amount)
    internal
    virtual
    returns (bool)
  {
    balanceOf[msg.sender] -= amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      balanceOf[to] += amount;
    }

    emit Transfer(msg.sender, to, amount);

    return true;
  }

  function _transferFrom(
    address from,
    address to,
    uint256 amount
  ) internal virtual returns (bool) {
    uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

    if (allowed != type(uint256).max)
      allowance[from][msg.sender] = allowed - amount;

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

      require(
        recoveredAddress != address(0) && recoveredAddress == owner,
        "INVALID_SIGNER"
      );

      allowance[recoveredAddress][spender] = value;
    }

    emit Approval(owner, spender, value);
  }

  function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
    return
      block.chainid == INITIAL_CHAIN_ID
        ? INITIAL_DOMAIN_SEPARATOR
        : computeDomainSeparator();
  }

  function computeDomainSeparator() internal view virtual returns (bytes32) {
    return
      keccak256(
        abi.encode(
          keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
          ),
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

// File @rari-capital/solmate/src/tokens/[email protected]

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

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 amount
  );

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

  function approve(address spender, uint256 amount)
    public
    virtual
    returns (bool)
  {
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

    if (allowed != type(uint256).max)
      allowance[from][msg.sender] = allowed - amount;

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

      require(
        recoveredAddress != address(0) && recoveredAddress == owner,
        "INVALID_SIGNER"
      );

      allowance[recoveredAddress][spender] = value;
    }

    emit Approval(owner, spender, value);
  }

  function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
    return
      block.chainid == INITIAL_CHAIN_ID
        ? INITIAL_DOMAIN_SEPARATOR
        : computeDomainSeparator();
  }

  function computeDomainSeparator() internal view virtual returns (bytes32) {
    return
      keccak256(
        abi.encode(
          keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
          ),
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

// File contracts/UsdXToken.sol


pragma solidity ^0.8.0;

// https://github.com/rari-capital/solmate/src/tokens/ERC20.sol"
contract UsdXToken is ERC20 {
  mapping(address => bool) public mintList;
  mapping(address => bool) public burnList;
  address public currentMinter;
  address public admin;

  event Governance(address _NewMinter);

  constructor() ERC20("USDx Token", "USDX", 6) {}

  function upDateContract(address _newContract) external {
    require(msg.sender == admin);
    mintList[currentMinter] = false;
    mintList[_newContract] = true;
    burnList[_newContract] = true;
    currentMinter = _newContract;
    emit Governance(_newContract);
  }

  function setSpecial(address _stableperp, address _VequityToken) external {
    require(admin == address(0x0), "Only once");
    mintList[_stableperp] = true;
    burnList[_stableperp] = true;
    currentMinter = _stableperp;
    admin = _VequityToken;
    emit Governance(_stableperp);
  }

  function mint(address account, uint256 amount) external returns (bool) {
    require(mintList[msg.sender] == true, "Only live contract can mint");
    _mint(account, amount);
    return true;
  }

  function burn(address account, uint256 amount) external returns (bool) {
    require(burnList[msg.sender] == true, "only approved contracts can burn");
    _burn(account, amount);
    return true;
  }
}

// File contracts/UpgradeFunction.sol


pragma solidity ^0.8.0;

interface UpgradeFunction {
  function forUpgrades() external returns (bool success);
}

// File contracts/EquityToken.sol

pragma solidity ^0.8.0;



contract EquityToken is ERC20b {
  uint32 public votePropNumber;
  mapping(address => uint32) public voteMonitor;
  mapping(address => bool) public mintList;
  mapping(address => bool) public burnList;
  uint256 public voteYes;
  uint256 public voteNo;
  uint256 public bonding_value;
  address public newContract;
  address public currentMinter;
  address public proposer;
  uint256 public deadLine;
  UsdXToken public usdXtoken;
  UpgradeFunction public upgradeNew;
  uint256 public constant CURE_TIME = 0 days;
  uint64 public constant MINT_AMOUNT = 30000;
  bool public isNew;

  event Proposal(address contractaddress, address proposer, uint256 deadline);
  event VoteOutcome(
    address newContract,
    uint256 numYes,
    uint256 numNo,
    uint256 deadline
  );
  event Governance(address _NewMinter);

  constructor(address _usdXtoken) ERC20b("Equity Token", "EQSP", 2) {
    usdXtoken = UsdXToken(_usdXtoken);
    deadLine = 9e9;
    mintList[msg.sender] = true;
    mint(msg.sender, MINT_AMOUNT);
    mintList[msg.sender] = false;
    isNew = true;
    votePropNumber = 1;
  }

  function mint(address account, uint256 _value) public returns (bool) {
    require(
      mintList[msg.sender] == true,
      "Only singular live contract can mint"
    );
    _mint(account, _value);
    return true;
  }

  function burn(address account, uint256 _value) external returns (bool) {
    require(burnList[msg.sender] == true, "ERC20: mint to the zero address");
    _burn(account, _value);
    return true;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) external returns (bool) {
    require(voteMonitor[_from] != votePropNumber);
    _transferFrom(_from, _to, _value);
    return true;
  }

  function transfer(address _to, uint256 _value) external returns (bool) {
    //require(voteMonitor[msg.sender] != votePropNumber);
    _transfer(_to, _value);
    return true;
  }

  function setSpecial(address _StablePerp) external {
    require(isNew, "Only once");
    mintList[_StablePerp] = true;
    burnList[_StablePerp] = true;
    emit Governance(_StablePerp);
    isNew = false;
  }

  function vote(bool isYes) public {
    require(voteYes > 0);
    require(balanceOf[msg.sender] > 0);
    require(voteMonitor[msg.sender] != votePropNumber);
    voteMonitor[msg.sender] = votePropNumber;
    if (isYes) {
      voteYes += balanceOf[msg.sender];
    } else {
      voteNo += balanceOf[msg.sender];
    }
  }

  function processVote() public {
    require(block.timestamp >= deadLine);
    if (voteYes > voteNo) {
      usdXtoken.upDateContract(newContract);
      upgradeNew.forUpgrades();
      mintList[currentMinter] = false;
      mintList[newContract] = true;
      burnList[newContract] = true;
      currentMinter = newContract;
      balanceOf[proposer] += bonding_value;
    }
    emit VoteOutcome(newContract, voteYes, voteNo, deadLine);
    voteYes = 0;
    voteNo = 0;
    votePropNumber++;
    deadLine = 9e9;
  }

  function proposeContract(address propContract) public {
    require(voteYes == 0);
    require((balanceOf[msg.sender] * 3) >= totalSupply);
    upgradeNew = UpgradeFunction(propContract);
    newContract = propContract;
    proposer = msg.sender;
    deadLine = block.timestamp + CURE_TIME;
    voteMonitor[proposer] = votePropNumber;
    voteYes = balanceOf[proposer];
    bonding_value = (totalSupply / 3);
    balanceOf[proposer] -= bonding_value;
    emit Proposal(newContract, proposer, deadLine);
  }

  function showProposal()
    public
    view
    returns (
      address contractAddress,
      uint256 yesvote,
      uint256 novote,
      uint256 deadline
    )
  {
    require(voteYes > 0);
    contractAddress = newContract;
    yesvote = voteYes;
    novote = voteNo;
    deadline = deadLine;
  }
}

// File contracts/StablePerpConstants.sol



pragma solidity ^0.8.0;

// needed to maintain precision when calculating
// the new price given an amount of eth sent to the pool
int256 constant DEC_PRC1 = 1e22;
// this constant is used in that same "eth in" transaction
int256 constant DEC_PRC2 = 1e11;
// fees denominated in basis points need this as a divisor.
//One basis point equals one ten thousandth of a percent
int256 constant BASIS_PT_ADJ = 10000;
// withdrawal fee in basis points
// it is half that when withdrawing virtual ETH and USD
int64 constant BPS_WD_FEE = 300; // 20 for real, 300 for tests
int64 constant BPS_WD_FEE_X = 150; // 20 for real, 300 for tests

// total trade fee in basis points
int256 constant BPS_TRADE_FEE = 100; // 20 for real, 100 for tests
int256 constant BPS_SWAP_FEE = 100; // 20 for real, 100 for tests
int256 constant BPS_USDC_SWAP_FEE = 100; // 20 for real, 100 for tests
// the default fee is 5% of the notional eth position. 1/20 equals 5%
int256 constant DEFAULT_FEE = 20;
// LPs should extend liquidity for a minimum of 1 week.
// If we divide the eth taken out of a pool by 1000, this will approximately
// double the fees that would have been paid had the LP instead made transactions
// in the regular way. It is meant so that anyone not intending to act as a true LP
// will see that a regular trading account dominates pretending to be an LP
int64 constant EARLY_WD_PENALTY = 1000;
// in timestamp seconds this represents 7 days. An LP withdrawing earlier than this pays a fee
uint64 constant EARLY_WD_DEFINED = 604800;
// translates virtual usd and usdc from their 6 decimals to the internal 2
uint64 constant DEC_USD_ADJ64 = 1e4;

uint256 constant DEC_TEST_ETH = 1e4;
int64 constant DEC_USD_ADJ = 1e4;
int256 constant DEC_USD_ADJ256 = 1e4;
// this turns the  18 decimals used in ETH deposits and withdrawals into ETH represented
//in this contract, which uses 5 decimals
uint256 constant DEC_ETH_ADJ = 1e13;
int256 constant DEC_ETH_ADJ_INT256 = 1e13;
// given the decimals used in this contract, this factor is applied when determining pool
// eth given liquidity
int256 constant DEC_POOL_ETH = 1e11;
// given the decimals used in this contract, this factor is applied when determining pool
// USD given liquidity
int256 constant DEC_POOL_USD = 1e10;
// given the decimals used in this contract, this number puts the eth notional value into
//USD, represented with 2 decimals
int256 constant DEC_ETHVAL_ADJ = 1e21;
// this combines the factor  that turns eth notional into USD decimals, with the number 5
// the required margin is 20%, or 1/5
int256 constant DEC_REQM = 5e21;
// LP fees are accumulated as the the sum of fee/liquidity.
//Given this is generally a number less than one,
//we multiply by this factor to avoid rounding it to zero.
//When fees are then attributed, this number is then used as the divisor
int256 constant FEE_PREC_FACTOR = 1e12;
// When the market value, in USD, of the equity collateral reaches this number
// LP's no longer receive equity tokens as payment,but instead ETH and USD
int256 constant INSUR_USDVAL_TARGET = 5e1; // lower for tests of non-token state
// an LP's liquidity is constructed so that the price level will have to move approximately 10%
// before the LP's initial ETH and USD deposit are deleted
// the liquidity = 22 * price^0.5 * eth deposited
int256 constant LIQ_ADD_22 = 22;
// during an LP add, after the liquidity number is determined, the amount of USD collateral needed
// is determined. it is USDCdeposit = liquidity * LIQ_ADD_19 / price^0.5
int256 constant LIQ_ADD_19 = 19;
// given an LP's pool eth position, an LP with a net zero ETH position will have
// her ETH trade account exactly equal to the negative of her pool ETH position
// which is a function of her liquidity and the square root of price
// The LP starts out with a trade account of 95% of her pool ETH number
// giving her a net positive ETH position of 5% of here pool ETH
// the LP will have free trading access when her net ETH position is
// between 2.5% and 7.5% of her pool ETH, which corresponds to 92.5% and 97.5%
// of her pool eth position
int256 constant LP_POS_TRADE_TOP = -9250;
int256 constant LP_POS_TRADE_BOT = -9750;
// an LP with a negative 5% net eth position as a percent of her pool eth
//  would have a trade account eth position of -105% of her pool eth. This corresponds
// to a 20% price change since the LP position was established, where the LP made no
// trades
int256 constant LP_LIQ_THRESH = -105; // -105 for mainnet and LP liquidation tests
// this caps the inputs to prevent overflow errors, while allowing users to
// deposit $100 billion
int256 constant MAX_IN = 2**46 - 1;
uint64 constant MAX_IN_64 = 2**46 - 1;
// A user's account balance must be at least $100. The contract needs to prevent
// accounts that are so small that any default would imply a net loss to the contract after paying the liquidator
int256 constant MIN_REQ_MARGIN = 1e4;
uint64 constant MIN_IN_64 = 10000;
int256 constant MIN_IN = 10000;
int256 constant MIN_IN_POOL = 90000;
int256 constant MAX_IN_POOL = 1e14;
// regardless of how small the account the liquidator will get at least $20
int64 constant MIN_LIQ_FEE = 2000;
// A user's account balance must be at least 0.1 eth. The contract needs to prevent
// accounts that are so small that any default would imply a net loss to the contract after paying the liquidator
int256 constant MIN_ETH_BAL = 10000;
// for monitoring the block of the last price update. It doesn't have to exactly correct
int256 constant MIN_ETH_LIQ = 10000;
// for monitoring the block of the last price update. It doesn't have to exactly correct
// so taking the modulus of the block number divided by 65535
uint256 constant MOD16_DIV = 2**16 - 1;
// to prevent flash crashes the contract only allows the price to move by 3.0%
// as this is applied to the square root of price, the restriction is applied using a
// constant of 1.5%, which is approximately a 3% price change cap
int256 constant PRICE_FLOOR = 9750; // 9850 real
int256 constant PRICE_CAP = 10253; // 10150

// File contracts/StablePerp.sol

pragma solidity ^0.8.0;


contract StablePerp {
  TradeParams public tradeParams;
  EquityBalances public equityBalances;
  bool public tokenPayout = true;
  EquityToken public usdxToken;
  EquityToken public equityToken;
  EquityToken public usdcToken;
  mapping(address => LiqProviderAcct) public liqProviderAcct;
  mapping(address => TradeAccount) public tradeAccount;

  struct TradeAccount {
    int64 vUSD;
    int64 vETH;
    address tradeDelegate;
  }

  struct LiqProviderAcct {
    int64 liquidity;
    int64 usdFeeSnap;
    int64 ethFeeSnap;
    uint64 epoch;
  }

  struct TradeParams {
    int64 sqrtPrice;
    int64 totLiquidity;
    int64 usdFeeSum;
    int48 lastBlockPrice;
    uint16 lastBlockNum;
  }

  struct EquityBalances {
    int64 usd;
    int64 eth;
    int64 ethFeeSum;
    int48 emaSqrtPrice;
  }

  event Deposit(address indexed user, uint8 coin, uint256 amount);
  event DepositLiquidity(
    address indexed user,
    int256 amountUSD,
    int256 amountETH
  );
  event DepositInjection(
    address indexed user,
    int256 amountUSD,
    uint256 amountETH,
    uint256 tokensIssued
  );
  event Inactivated(address indexed user);
  event Liquidity(address indexed user, int256 liquidityAdd);
  event LiquidateLP(
    address indexed liquidator,
    address defaulter,
    int256 indivLiquidity
  );
  event Liquidate(
    address indexed liquidator,
    address defaulter,
    int256 ethLiquidated
  );
  event Redemption(address indexed user, int256 liquiditySubtract);
  event Swap(
    address indexed user,
    int256 liquidity,
    int256 usdToAccountDec2,
    int64 ethToAccountDec5,
    int256 newSqrtPrice
  );
  event Trade(
    address indexed user,
    address indexed trader,
    int256 liquidity,
    int256 usdToAccountDec2,
    int64 ethToAccountDec5,
    int256 newSqrtPrice
  );
  event Withdraw(address indexed user, uint8 coin, uint256 amount);

  constructor(
    int64 _sqrtp,
    address _usdxToken,
    address _equityToken,
    address _usdcToken
  ) {
    tradeParams.sqrtPrice = _sqrtp;
    tradeParams.lastBlockPrice = int48(_sqrtp) / 10000;
    tokenPayout = false;
    usdxToken = EquityToken(_usdxToken);
    equityToken = EquityToken(_equityToken);
    usdcToken = EquityToken(_usdcToken);
  }

  function mktValReqMargin(address _acctAddress)
    public
    view
    returns (int256 mktValue, int256 reqMargin)
  {
    int256 sqrtPrice = int256(tradeParams.sqrtPrice);
    int256 ethPosition = int256(tradeAccount[_acctAddress].vETH);
    int256 usdPosition = int256(tradeAccount[_acctAddress].vUSD);
    if (liqProviderAcct[_acctAddress].liquidity > 0) {
      int256 indivLiq = int256(liqProviderAcct[_acctAddress].liquidity);
      int256 daiTxFees = (indivLiq *
        int256(
          tradeParams.usdFeeSum - liqProviderAcct[msg.sender].usdFeeSnap
        )) / FEE_PREC_FACTOR;
      int256 ethTxFees = (indivLiq *
        int256(
          equityBalances.ethFeeSum - liqProviderAcct[msg.sender].ethFeeSnap
        )) / FEE_PREC_FACTOR;
      ethPosition += (indivLiq * DEC_POOL_ETH) / sqrtPrice + ethTxFees;
      usdPosition += (indivLiq * sqrtPrice) / DEC_POOL_USD + daiTxFees;
    }
    mktValue = usdPosition + ((sqrtPrice**2) * ethPosition) / DEC_ETHVAL_ADJ;
    reqMargin = (ethPosition * (sqrtPrice**2)) / DEC_REQM;
    reqMargin = reqMargin > 0 ? reqMargin : -reqMargin;
    if (reqMargin < MIN_REQ_MARGIN) {
      if (reqMargin > 0) {
        reqMargin = MIN_REQ_MARGIN;
      } else {
        reqMargin = 0;
      }
    }
  }

  function fundUSDC(uint64 _UsdDec6) external payable returns (bool) {
    uint64 usdDec2 = _UsdDec6 / DEC_USD_ADJ64;
    require(
      usdDec2 >= MIN_IN_64 && usdDec2 < MAX_IN_64,
      "send amount wrong size"
    );
    bool success = usdcToken.transferFrom(
      msg.sender,
      address(this),
      uint256(_UsdDec6)
    );
    if (success) {
      tradeAccount[msg.sender].vUSD += int64(usdDec2);
      emit Deposit(msg.sender, 0, uint256(_UsdDec6));
    }
    return (success);
  }

  function fundUSDx(uint64 _UsdDec6) external payable returns (bool) {
    uint64 usdDec2 = _UsdDec6 / DEC_USD_ADJ64;
    require(
      usdDec2 >= MIN_IN_64 && usdDec2 < MAX_IN_64,
      "send amount wrong size"
    );
    bool success = usdxToken.burn(msg.sender, uint256(_UsdDec6));
    if (success) {
      tradeAccount[msg.sender].vUSD += int64(usdDec2);
      emit Deposit(msg.sender, 2, uint256(_UsdDec6));
    }
    return (success);
  }

  function fundETH() external payable returns (bool) {
    uint64 amt = uint64((DEC_TEST_ETH * msg.value) / DEC_ETH_ADJ);
    require(amt >= MIN_IN_64 && amt < MAX_IN_64, "send amount wrong size");
    tradeAccount[msg.sender].vETH += int64(amt);
    emit Deposit(msg.sender, 1, msg.value);
    return true;
  }

  function withDrawUSDC(int256 _usdDec2) external returns (bool success) {
    require(_usdDec2 >= 0 && _usdDec2 < MAX_IN, "size amount illogical");
    int256 sqrtPrice = tradeParams.sqrtPrice;
    mktValReqMarginCheck(msg.sender, sqrtPrice, -_usdDec2, 0, true);
    tradeAccount[msg.sender].vUSD -= int64(_usdDec2);
    int256 totLiq = int256(tradeParams.totLiquidity);
    int256 usdFee = (_usdDec2 * BPS_WD_FEE) / BASIS_PT_ADJ;
    if (totLiq > 0) {
      tradeParams.usdFeeSum += int64(
        (FEE_PREC_FACTOR * usdFee * 3) / (totLiq * 4)
      );
    }
    equityBalances.usd += int64(usdFee / 4);
    _usdDec2 -= usdFee;
    bool success0 = usdcToken.transfer(
      msg.sender,
      uint256(_usdDec2 * DEC_USD_ADJ)
    );
    require(success0, "insufficient usdc in contract");
    if (
      tradeAccount[msg.sender].vUSD == 0 && tradeAccount[msg.sender].vETH == 0
    ) {
      delete tradeAccount[msg.sender];
      emit Inactivated(msg.sender);
    }
    emit Withdraw(msg.sender, 0, uint256(_usdDec2 * DEC_USD_ADJ));
    return true;
  }

  function withDrawUSDx(int256 _usdDec2) external returns (bool success) {
    int256 sqrtPrice = tradeParams.sqrtPrice;
    mktValReqMarginCheck(msg.sender, sqrtPrice, -_usdDec2, 0, true);
    tradeAccount[msg.sender].vUSD -= int64(_usdDec2);
    int256 totLiq = int256(tradeParams.totLiquidity);
    int256 usdFee = (_usdDec2 * BPS_WD_FEE_X) / BASIS_PT_ADJ;
    equityBalances.usd += int64(usdFee / 4);
    if (totLiq > 0) {
      tradeParams.usdFeeSum += int64(
        (FEE_PREC_FACTOR * usdFee * 3) / (totLiq * 4 + 1)
      );
    }
    _usdDec2 -= usdFee;
    bool success0 = usdxToken.mint(msg.sender, uint256(_usdDec2 * DEC_USD_ADJ));
    require(success0, "mint failed");
    if (
      tradeAccount[msg.sender].vUSD == 0 && tradeAccount[msg.sender].vETH == 0
    ) {
      delete tradeAccount[msg.sender];
      emit Inactivated(msg.sender);
    }
    emit Withdraw(msg.sender, 2, uint256(_usdDec2 * DEC_USD_ADJ));
    return true;
  }

  function withDrawETH(int256 _ethDec5) external returns (bool success) {
    require(_ethDec5 >= 0 && _ethDec5 < MAX_IN, "size amount illogical");
    int256 sqrtPrice = tradeParams.sqrtPrice;
    mktValReqMarginCheck(msg.sender, sqrtPrice, 0, -_ethDec5, true);
    tradeAccount[msg.sender].vETH -= int64(_ethDec5);
    int256 totLiq = int256(tradeParams.totLiquidity);
    int256 ethFee = (_ethDec5 * BPS_WD_FEE) / BASIS_PT_ADJ;
    if (totLiq > 0) {
      equityBalances.ethFeeSum += int64(
        (FEE_PREC_FACTOR * ethFee * 3) / (totLiq * 4)
      );
    }
    equityBalances.eth += int64(ethFee / 4);
    _ethDec5 -= ethFee;
    uint256 ethOut = ((uint256(_ethDec5) * DEC_ETH_ADJ) / DEC_TEST_ETH);
    require(
      address(this).balance >= ethOut,
      "insufficient eth or usdc in contract"
    );
    payable(msg.sender).transfer(ethOut);

    if (
      tradeAccount[msg.sender].vUSD == 0 && tradeAccount[msg.sender].vETH == 0
    ) {
      delete tradeAccount[msg.sender];
      emit Inactivated(msg.sender);
    }
    emit Withdraw(msg.sender, 1, ethOut);
    return true;
  }

  function updateTrader(address _tradeDelegate)
    external
    returns (bool success)
  {
    tradeAccount[msg.sender].tradeDelegate = _tradeDelegate;
    return true;
  }

  function forUpgrades() external returns (bool success) {
    require(address(equityToken) == msg.sender);
    return true;
  }

  function addLiquidity() external payable returns (bool) {
    int256 ethIn = int256((DEC_TEST_ETH * msg.value) / DEC_ETH_ADJ);
    require(
      ethIn > MIN_IN_POOL && ethIn < MAX_IN_POOL,
      "position too small/big"
    );
    int256 sqrtPrice = int256(tradeParams.sqrtPrice);
    int256 liqi = (LIQ_ADD_22 * ethIn * sqrtPrice) / DEC_POOL_ETH;
    int256 usdIn = (((liqi * sqrtPrice) / LIQ_ADD_19) / DEC_POOL_USD);
    bool success = usdcToken.transferFrom(
      msg.sender,
      address(this),
      uint256(usdIn * DEC_USD_ADJ)
    );
    require(success, "token transfer fail");
    tradeParams.totLiquidity += int64(liqi);
    tradeAccount[msg.sender].vUSD += int64(
      usdIn - ((liqi * sqrtPrice) / DEC_POOL_USD)
    );
    tradeAccount[msg.sender].vETH += int64(
      ethIn - ((liqi * DEC_POOL_ETH) / sqrtPrice)
    );
    liqProviderAcct[msg.sender].usdFeeSnap = tradeParams.usdFeeSum;
    liqProviderAcct[msg.sender].ethFeeSnap = equityBalances.ethFeeSum;
    liqProviderAcct[msg.sender].epoch = uint64(block.timestamp);
    liqProviderAcct[msg.sender].liquidity = int64(liqi);
    emit DepositLiquidity(msg.sender, usdIn, ethIn);
    emit Liquidity(msg.sender, liqi);
    return true;
  }

  function removeLiquidity() external returns (bool success) {
    int256 sqrtPrice = int256(tradeParams.sqrtPrice);
    int256 indivLiquidity = int256(liqProviderAcct[msg.sender].liquidity);
    int256 daiTxFees = (indivLiquidity *
      int256(tradeParams.usdFeeSum - liqProviderAcct[msg.sender].usdFeeSnap)) /
      FEE_PREC_FACTOR;
    int256 ethTxFees = (indivLiquidity *
      int256(
        equityBalances.ethFeeSum - liqProviderAcct[msg.sender].ethFeeSnap
      )) / FEE_PREC_FACTOR;
    int64 poolUSD = int64((indivLiquidity * sqrtPrice) / DEC_POOL_USD);
    int64 poolEth = int64((indivLiquidity * DEC_POOL_ETH) / sqrtPrice);
    if (
      (liqProviderAcct[msg.sender].epoch + EARLY_WD_DEFINED) >
      block.timestamp ||
      tradeAccount[msg.sender].vETH < LP_LIQ_THRESH * poolEth ||
      tradeAccount[msg.sender].vUSD < LP_LIQ_THRESH * poolUSD
    ) {
      int64 penaltyUSD = poolUSD / EARLY_WD_PENALTY;
      int64 penaltyETH = poolEth / EARLY_WD_PENALTY;
      int64 totLiq = tradeParams.totLiquidity;
      tradeAccount[msg.sender].vUSD -= penaltyUSD;
      tradeParams.usdFeeSum += int64((FEE_PREC_FACTOR * penaltyUSD) / totLiq);
      tradeAccount[msg.sender].vETH -= penaltyETH;
      equityBalances.ethFeeSum += int64(
        (FEE_PREC_FACTOR * penaltyETH) / totLiq
      );
    }
    delete liqProviderAcct[msg.sender];
    if (tokenPayout) {
      int256 tokens = daiTxFees +
        ((ethTxFees * (sqrtPrice**2)) / DEC_ETHVAL_ADJ);
      bool success0 = equityToken.mint(msg.sender, uint256(tokens));
      require(success0, "token mint failed");
      equityBalances.usd += int64(daiTxFees);
      equityBalances.eth += int64(ethTxFees);
      tradeAccount[msg.sender].vETH += poolEth;
      tradeAccount[msg.sender].vUSD += poolUSD;
    } else {
      tradeAccount[msg.sender].vUSD += (int64(daiTxFees) + poolUSD);
      tradeAccount[msg.sender].vETH += (poolEth + int64(ethTxFees));
    }
    tradeParams.totLiquidity -= int64(indivLiquidity);
    emit Liquidity(msg.sender, -indivLiquidity);
    return true;
  }

  function swap(
    int64 _ethD5ToTrader,
    int256 _sqrtPLimit,
    address _account
  ) external returns (bool success) {
    require(
      msg.sender == _account ||
        msg.sender == tradeAccount[_account].tradeDelegate,
      "tradedelegate"
    );
    int256 sqrtPrice = int256(tradeParams.sqrtPrice);
    int256 liqTotal = int256(tradeParams.totLiquidity);
    int48 lastBlockPrc = tradeParams.lastBlockPrice;
    if ((block.number % MOD16_DIV) != uint256(tradeParams.lastBlockNum)) {
      lastBlockPrc = int48(tradeParams.sqrtPrice / 1e4);
      tradeParams.lastBlockPrice = lastBlockPrc;
      tradeParams.lastBlockNum = uint16(block.number % MOD16_DIV);
      equityBalances.emaSqrtPrice =
        lastBlockPrc /
        10 +
        (9 * equityBalances.emaSqrtPrice) /
        10;
    }
    int256 newsqrtPrice = DEC_PRC1 /
      ((DEC_PRC1 / sqrtPrice) -
        ((DEC_PRC2 * int256(_ethD5ToTrader)) / liqTotal));
    if (_ethD5ToTrader > 0) {
      _sqrtPLimit = _sqrtPLimit < (PRICE_CAP * int256(lastBlockPrc))
        ? _sqrtPLimit
        : PRICE_CAP * int256(lastBlockPrc);
      require(newsqrtPrice <= _sqrtPLimit, "prcCap exceeded");
    } else {
      _sqrtPLimit = _sqrtPLimit > (PRICE_FLOOR * int256(lastBlockPrc))
        ? _sqrtPLimit
        : PRICE_FLOOR * int256(lastBlockPrc);
      require(newsqrtPrice >= _sqrtPLimit, "prcFloor breached");
    }
    int256 usdToTrader = ((liqTotal * sqrtPrice) / DEC_POOL_USD) -
      ((liqTotal * newsqrtPrice) / DEC_POOL_USD);
    int256 fees = (BPS_TRADE_FEE * usdToTrader) / BASIS_PT_ADJ;
    fees = fees > 0 ? fees : -fees;
    usdToTrader -= (fees + 10);
    mktValReqMarginCheck(
      msg.sender,
      newsqrtPrice,
      usdToTrader,
      int256(_ethD5ToTrader),
      true
    );
    tradeAccount[_account].vUSD += int64(usdToTrader);
    tradeAccount[_account].vETH += _ethD5ToTrader;
    equityBalances.usd += int64(fees / 4);
    tradeParams.usdFeeSum += int64(
      (FEE_PREC_FACTOR * fees * 3) / (liqTotal * 4)
    );
    tradeParams.sqrtPrice = int64(newsqrtPrice);
    emit Trade(
      _account,
      msg.sender,
      liqTotal,
      usdToTrader,
      _ethD5ToTrader,
      newsqrtPrice
    );
    return true;
  }

  function swapE(int256 _sqrtPLimit, int256 _isUSDC)
    external
    payable
    returns (bool success)
  {
    int256 ethIn = int256((DEC_TEST_ETH * msg.value) / DEC_ETH_ADJ);
    int256 sqrtPrice = int256(tradeParams.sqrtPrice);
    int256 liqTotal = int256(tradeParams.totLiquidity);
    int48 lastBlockPrc = tradeParams.lastBlockPrice;
    if ((block.number % MOD16_DIV) != uint256(tradeParams.lastBlockNum)) {
      lastBlockPrc = int48(tradeParams.sqrtPrice / 1e4);
      tradeParams.lastBlockPrice = lastBlockPrc;
      tradeParams.lastBlockNum = uint16(block.number % MOD16_DIV);
      equityBalances.emaSqrtPrice =
        lastBlockPrc /
        10 +
        (9 * equityBalances.emaSqrtPrice) /
        10;
    }
    int256 newsqrtPrice = DEC_PRC1 /
      ((DEC_PRC1 / sqrtPrice) - ((DEC_PRC2 * int256(ethIn)) / liqTotal));
    _sqrtPLimit = _sqrtPLimit > (PRICE_FLOOR * int256(lastBlockPrc))
      ? _sqrtPLimit
      : PRICE_FLOOR * int256(lastBlockPrc);
    require(newsqrtPrice >= _sqrtPLimit, "prcFloor breached");
    int256 usdToTrader = -((liqTotal * sqrtPrice) / DEC_POOL_USD) +
      ((liqTotal * newsqrtPrice) / DEC_POOL_USD);
    int256 fees = ((BPS_SWAP_FEE + _isUSDC * BPS_USDC_SWAP_FEE) * usdToTrader) /
      BASIS_PT_ADJ;
    usdToTrader -= (fees + 10);
    bool success0;
    if (_isUSDC == 0) {
      success0 = usdxToken.mint(msg.sender, uint256(usdToTrader * DEC_USD_ADJ));
    } else {
      success0 = usdcToken.transfer(
        msg.sender,
        uint256(usdToTrader * DEC_USD_ADJ)
      );
    }
    require(success0, "insufficient usdc in contract");
    equityBalances.usd += int64(fees / 4);
    tradeParams.usdFeeSum += int64(
      (FEE_PREC_FACTOR * fees * 3) / (liqTotal * 4)
    );
    tradeParams.sqrtPrice = int64(newsqrtPrice);
    emit Swap(msg.sender, liqTotal, usdToTrader, int64(ethIn), newsqrtPrice);
    return true;
  }

  function swapU(
    int256 _usdIn,
    int256 _sqrtPLimit,
    int256 _isUSDC
  ) external returns (bool) {
    bool success0;
    if (_isUSDC == 0) {
      success0 = usdxToken.burn(msg.sender, uint256(_usdIn));
    } else {
      success0 = usdcToken.transfer(msg.sender, uint256(_usdIn));
    }
    require(success0);
    _usdIn = _usdIn / DEC_USD_ADJ256;
    int256 fees = ((BPS_SWAP_FEE + _isUSDC * BPS_USDC_SWAP_FEE) * _usdIn) /
      BASIS_PT_ADJ;
    _usdIn -= (fees + 10);
    int256 sqrtPrice = int256(tradeParams.sqrtPrice);
    int256 liqTotal = int256(tradeParams.totLiquidity);
    int256 newsqrtPrice = sqrtPrice + (DEC_POOL_USD * _usdIn) / liqTotal;
    int48 lastBlockPrc = tradeParams.lastBlockPrice;
    if ((block.number % MOD16_DIV) != uint256(tradeParams.lastBlockNum)) {
      lastBlockPrc = int48(tradeParams.sqrtPrice / 1e4);
      tradeParams.lastBlockPrice = lastBlockPrc;
      tradeParams.lastBlockNum = uint16(block.number % MOD16_DIV);
      equityBalances.emaSqrtPrice =
        lastBlockPrc /
        10 +
        (9 * equityBalances.emaSqrtPrice) /
        10;
    }
    _sqrtPLimit = _sqrtPLimit < (PRICE_CAP * int256(lastBlockPrc))
      ? _sqrtPLimit
      : PRICE_CAP * int256(lastBlockPrc);
    require(newsqrtPrice <= _sqrtPLimit, "prcCap exceeded");
    equityBalances.usd += int64(fees / 4);
    tradeParams.usdFeeSum += int64((3 * fees) / 4);
    int256 _ethD5ToTrader = ((liqTotal * DEC_POOL_ETH) / sqrtPrice) -
      ((liqTotal * DEC_POOL_ETH) / newsqrtPrice);
    tradeParams.sqrtPrice = int64(newsqrtPrice);
    emit Swap(
      msg.sender,
      liqTotal,
      int64(_ethD5ToTrader),
      int64(_usdIn),
      newsqrtPrice
    );
    payable(msg.sender).transfer(
      (uint256(_ethD5ToTrader) * DEC_ETH_ADJ) / DEC_TEST_ETH
    );
    return true;
  }

  function liquidate(address _defaulter, int256 _ethTarget)
    external
    returns (bool success)
  {
    int256 sqrtPrice = int256(equityBalances.emaSqrtPrice);
    int256 ethPosition = int256(tradeAccount[_defaulter].vETH);
    require(
      (ethPosition * _ethTarget) > 0 &&
        ((100 * _ethTarget) / ethPosition) <= 100,
      "illogical size"
    );
    require(
      _ethTarget <= -MIN_ETH_LIQ ||
        _ethTarget >= MIN_ETH_LIQ ||
        _ethTarget == ethPosition,
      "leaves insufficient residual"
    );
    mktValReqMarginCheck(_defaulter, sqrtPrice, 0, 0, false);
    int256 liqFee = (_ethTarget * (sqrtPrice**2)) /
      DEFAULT_FEE /
      DEC_ETHVAL_ADJ;
    liqFee = liqFee > 0 ? liqFee : -liqFee;
    if (liqFee < MIN_LIQ_FEE) liqFee = MIN_LIQ_FEE;
    tradeAccount[_defaulter].vUSD -= int64(
      2 * liqFee - (_ethTarget * sqrtPrice * sqrtPrice) / DEC_ETHVAL_ADJ
    );
    tradeAccount[_defaulter].vETH -= int64(_ethTarget);
    tradeAccount[msg.sender].vUSD += int64(
      liqFee - (_ethTarget * sqrtPrice * sqrtPrice) / DEC_ETHVAL_ADJ
    );
    tradeAccount[msg.sender].vETH += int64(_ethTarget);
    equityBalances.usd += int64(liqFee);
    if (
      (tradeAccount[_defaulter].vETH == 0) &&
      (tradeAccount[_defaulter].vUSD < 0)
    ) {
      equityBalances.usd += int64(tradeAccount[_defaulter].vUSD);
      delete tradeAccount[_defaulter];
      emit Inactivated(_defaulter);
    }
    emit Liquidate(msg.sender, _defaulter, _ethTarget);
    return true;
  }

  function liquidateLP(address _defaulter) external returns (bool success) {
    int256 indivLiquidity = int256(liqProviderAcct[_defaulter].liquidity);
    require(indivLiquidity > 0, "target not LP");
    int256 vETH = int256(tradeAccount[_defaulter].vETH);
    int256 vUSD = int256(tradeAccount[_defaulter].vUSD);
    int256 sqrtPrice = int256(equityBalances.emaSqrtPrice);
    int256 poolETH = (indivLiquidity * DEC_POOL_ETH) / sqrtPrice;
    int256 poolUSD = ((indivLiquidity * sqrtPrice) / DEC_POOL_USD);
    int256 daiTxFees = (indivLiquidity *
      (tradeParams.usdFeeSum - liqProviderAcct[_defaulter].usdFeeSnap)) /
      FEE_PREC_FACTOR;
    int256 ethTxFees = (indivLiquidity *
      (equityBalances.ethFeeSum - liqProviderAcct[_defaulter].ethFeeSnap)) /
      FEE_PREC_FACTOR;
    delete liqProviderAcct[_defaulter];
    int256 fee = poolUSD / EARLY_WD_PENALTY;
    fee = fee > MIN_LIQ_FEE ? fee : MIN_LIQ_FEE;
    tradeAccount[msg.sender].vUSD += int64(fee);
    tradeAccount[_defaulter].vUSD = int64(vUSD + daiTxFees + poolUSD - fee);
    tradeAccount[_defaulter].vETH = int64(vETH + ethTxFees + poolETH);
    tradeParams.totLiquidity -= int64(indivLiquidity);
    emit LiquidateLP(msg.sender, _defaulter, indivLiquidity);
    return true;
  }

  function liquidateLP2(address _defaulter) external returns (bool success) {
    int256 indivLiquidity = int256(liqProviderAcct[_defaulter].liquidity);
    require(indivLiquidity > 0, "target not LP");
    int256 vETH = int256(tradeAccount[_defaulter].vETH);
    int256 vUSD = int256(tradeAccount[_defaulter].vUSD);
    int256 sqrtPrice = int256(equityBalances.emaSqrtPrice);
    int256 poolETH = (indivLiquidity * DEC_POOL_ETH) / sqrtPrice;
    int256 poolUSD = ((indivLiquidity * sqrtPrice) / DEC_POOL_USD);
    int256 daiTxFees = (indivLiquidity *
      (tradeParams.usdFeeSum - liqProviderAcct[_defaulter].usdFeeSnap)) /
      FEE_PREC_FACTOR;
    int256 ethTxFees = (indivLiquidity *
      (equityBalances.ethFeeSum - liqProviderAcct[_defaulter].ethFeeSnap)) /
      FEE_PREC_FACTOR;
    {
      int256 ethPosUSD = ((vETH + ethTxFees + poolETH) * (sqrtPrice**2)) /
        DEC_ETHVAL_ADJ;
      int256 mktVal = ethPosUSD + (vUSD + daiTxFees + poolUSD);
      ethPosUSD = ethPosUSD > 0 ? ethPosUSD : -ethPosUSD;
      require(mktVal < (ethPosUSD / 5));
    }
    delete liqProviderAcct[_defaulter];
    int256 fee = poolUSD / EARLY_WD_PENALTY;
    fee = fee >= MIN_LIQ_FEE ? fee : MIN_LIQ_FEE;
    tradeAccount[msg.sender].vUSD += int64(fee);
    tradeAccount[_defaulter].vUSD = int64(vUSD + daiTxFees + poolUSD - fee);
    tradeAccount[_defaulter].vETH = int64(vETH + ethTxFees + poolETH);
    tradeParams.totLiquidity -= int64(indivLiquidity);
    emit LiquidateLP(msg.sender, _defaulter, indivLiquidity);
    return true;
  }

  function redeemToken(int256 _token) external returns (bool success) {
    require(
      _token > 0 && _token < MAX_IN,
      "send amount nonPositive or too big"
    );
    int256 mktValue = equityBalances.usd +
      (equityBalances.eth * int256(tradeParams.sqrtPrice)**2) /
      DEC_ETHVAL_ADJ;
    require(mktValue > 0, "equity account negative");
    int256 tokensOutstanding = int256(equityToken.totalSupply());
    int256 usdOut = (_token * int256(equityBalances.usd)) / tokensOutstanding;
    int256 ethOut = (_token * int256(equityBalances.eth)) / tokensOutstanding;
    bool success0 = equityToken.burn(msg.sender, uint256(_token));
    require(success0, "user has insufficient tokens");
    tradeAccount[msg.sender].vUSD += int64(usdOut);
    equityBalances.usd -= int64(usdOut);
    equityBalances.eth -= int64(ethOut);
    tradeAccount[msg.sender].vETH += int64(ethOut);
    emit Redemption(msg.sender, _token);
    return true;
  }

  function injectToken(int256 _usdDec6) external payable returns (bool) {
    require(_usdDec6 >= 0 && (_usdDec6 / 1e4) < MAX_IN, "too big");
    int256 _ethIn = int256((msg.value * DEC_TEST_ETH) / DEC_ETH_ADJ);
    bool success0 = usdcToken.transferFrom(
      msg.sender,
      address(this),
      uint256(_usdDec6)
    );
    require(success0, "user insufficient tokens");
    _usdDec6 = (_usdDec6 / 1e4);
    int256 ethPrice = int256(tradeParams.sqrtPrice)**2;
    int256 mktvalue = _usdDec6 + (_ethIn * ethPrice) / DEC_ETHVAL_ADJ;
    equityBalances.usd += int64(_usdDec6);
    equityBalances.eth += int64(_ethIn);
    int256 fundLevel = int256(equityBalances.usd) +
      (int256(equityBalances.eth * ethPrice) / DEC_ETHVAL_ADJ);
    if (fundLevel > INSUR_USDVAL_TARGET) {
      tokenPayout = false;
    } else {
      tokenPayout = true;
    }
    uint256 tokensOut;
    if (fundLevel < 0 && mktvalue > -fundLevel) {
      uint256 tokensOutstanding = equityToken.totalSupply();
      tokensOut = tokensOutstanding / 3;
      (success0) = equityToken.mint(msg.sender, tokensOut);
      require(success0, "mint failed");
    }
    emit DepositInjection(msg.sender, _usdDec6, msg.value, tokensOut);
    return true;
  }

  function mktValReqMarginCheck(
    address _acctAddress,
    int256 _sqrtPrice,
    int256 _usdOut,
    int256 _ethOut,
    bool _initMargin
  ) internal view {
    int256 ethPosition = int256(tradeAccount[_acctAddress].vETH) + _ethOut;
    int256 usdPosition = int256(tradeAccount[_acctAddress].vUSD) + _usdOut;
    if (liqProviderAcct[_acctAddress].liquidity > 0) {
      int256 indivLiq = int256(liqProviderAcct[_acctAddress].liquidity);
      ethPosition += (indivLiq * DEC_POOL_ETH) / _sqrtPrice;
      usdPosition += (indivLiq * _sqrtPrice) / DEC_POOL_USD;
    }
    int256 mktValue = usdPosition +
      ((_sqrtPrice**2) * ethPosition) /
      DEC_ETHVAL_ADJ;
    int256 reqMargin = (ethPosition * (_sqrtPrice**2)) / DEC_REQM;
    reqMargin = reqMargin > 0 ? reqMargin : -reqMargin;
    if (reqMargin < MIN_REQ_MARGIN) {
      if (reqMargin > 0) {
        reqMargin = MIN_REQ_MARGIN;
      } else {
        reqMargin = 0;
      }
    }
    if (_initMargin) {
      if (mktValue < ((reqMargin * 3) / 2)) revert();
    } else {
      if (mktValue > reqMargin) revert();
    }
  }
}