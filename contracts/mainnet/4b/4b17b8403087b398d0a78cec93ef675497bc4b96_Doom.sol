// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

contract Doom {
  /// @notice EIP-20 token name for this token
  string public constant name = "Doom";

  /// @notice EIP-20 token symbol for this token
  string public constant symbol = "DOOM";

  /// @notice EIP-20 token decimals for this token
  uint8 public constant decimals = 18;

  /// @notice Address which may mint new tokens
  address public minter;

  /// @notice The timestamp after which minting may occur
  uint256 public mintingAllowedAfter;

  /// @notice Cap on the percentage of totalSupply that can be minted at each mint
  uint8 public constant mintCap = 0;

  /// @notice Minimum time between mints
  uint32 public constant minimumTimeBetweenMints = 1337 days;

  /// @notice Total number of tokens in circulation
  uint256 public totalSupply = 272_305e18;

  mapping(address => mapping(address => uint96)) internal allowances;

  mapping(address => uint96) internal balances;

  mapping(address => address) public delegates;

  struct Checkpoint {
    uint32 fromBlock;
    uint96 votes;
  }

  mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

  mapping(address => uint32) public numCheckpoints;

  bytes32 public constant DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
  );

  bytes32 public constant DELEGATION_TYPEHASH = keccak256(
    "Delegation(address delegatee,uint256 nonce,uint256 expiry)"
  );

  bytes32 public constant PERMIT_TYPEHASH = keccak256(
    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
  );

  mapping(address => uint256) public nonces;

  /// @notice An event thats emitted when the minter address is changed
  event MinterChanged(address minter, address newMinter);

  event DelegateChanged(
    address indexed delegator,
    address indexed fromDelegate,
    address indexed toDelegate
  );

  event DelegateVotesChanged(
    address indexed delegate,
    uint256 previousBalance,
    uint256 newBalance
  );

  event Transfer(address indexed from, address indexed to, uint256 amount);

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 amount
  );

  constructor(address account, address minter_, uint256 mintingAllowedAfter_) public {
    require(
      mintingAllowedAfter_ >= block.timestamp,
      "Doom::constructor: minting can only begin after deployment"
    );
    balances[account] = uint96(totalSupply);
    emit Transfer(address(0), account, totalSupply);
    minter = minter_;
    emit MinterChanged(address(0), minter);
    mintingAllowedAfter = 0;
  }

  /**
   * @notice Change the minter address
   * @param minter_ The address of the new minter
   */
  function setMinter(address minter_) external {
    require(msg.sender == minter, "Doom::setMinter: only the minter can change the minter address");
    emit MinterChanged(minter, minter_);
    minter = minter_;
  }

  /**
   * @notice Mint new tokens
   * @param dst The address of the destination account
   * @param rawAmount The number of tokens to be minted
   */
  function mint(address dst, uint rawAmount) external {
    require(msg.sender == minter, "Doom::mint: only the minter can mint");
    require(block.timestamp >= mintingAllowedAfter, "Doom::mint: minting not allowed yet");
    require(dst != address(0), "Doom::mint: cannot transfer to the zero address");

    // record the mint
    mintingAllowedAfter = SafeMath.add(block.timestamp, minimumTimeBetweenMints);

    // mint the amount
    uint96 amount = safe96(rawAmount, "Doom::mint: amount exceeds 96 bits");
    require(amount <= SafeMath.div(SafeMath.mul(totalSupply, mintCap), 100), "Doom::mint: exceeded mint cap");
    totalSupply = safe96(SafeMath.add(totalSupply, amount), "Doom::mint: totalSupply exceeds 96 bits");

    // transfer the amount to the recipient
    balances[dst] = add96(balances[dst], amount, "Doom::mint: transfer amount overflows");
    emit Transfer(address(0), dst, amount);

    // move delegates
    _moveDelegates(address(0), delegates[dst], amount);
  }

  function allowance(address account, address spender)
    external
    view
    returns (uint256)
  {
    return allowances[account][spender];
  }

  function approve(address spender, uint256 rawAmount) external returns (bool) {
    uint96 amount;
    if (rawAmount == uint256(-1)) {
      amount = uint96(-1);
    } else {
      amount = safe96(rawAmount, "Doom::approve: amount exceeds 96 bits");
    }

    allowances[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function permit(
    address owner,
    address spender,
    uint256 rawAmount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    uint96 amount;
    if (rawAmount == uint256(-1)) {
      amount = uint96(-1);
    } else {
      amount = safe96(rawAmount, "Doom::permit: amount exceeds 96 bits");
    }

    bytes32 domainSeparator = keccak256(
      abi.encode(
        DOMAIN_TYPEHASH,
        keccak256(bytes(name)),
        getChainId(),
        address(this)
      )
    );
    bytes32 structHash = keccak256(
      abi.encode(
        PERMIT_TYPEHASH,
        owner,
        spender,
        rawAmount,
        nonces[owner]++,
        deadline
      )
    );
    bytes32 digest = keccak256(
      abi.encodePacked("\x19\x01", domainSeparator, structHash)
    );
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "Doom::permit: invalid signature");
    require(signatory == owner, "Doom::permit: unauthorized");
    require(now <= deadline, "Doom::permit: signature expired");

    allowances[owner][spender] = amount;

    emit Approval(owner, spender, amount);
  }

  function balanceOf(address account) external view returns (uint256) {
    return balances[account];
  }

  function nonceOf(address account) external view returns (uint256) {
    return nonces[account];
  }

  function transfer(address dst, uint256 rawAmount) external returns (bool) {
    uint96 amount = safe96(rawAmount, "Doom::transfer: amount exceeds 96 bits");
    _transferTokens(msg.sender, dst, amount);
    return true;
  }

  function transferFrom(
    address src,
    address dst,
    uint256 rawAmount
  ) external returns (bool) {
    address spender = msg.sender;
    uint96 spenderAllowance = allowances[src][spender];
    uint96 amount = safe96(rawAmount, "Doom::approve: amount exceeds 96 bits");

    if (spender != src && spenderAllowance != uint96(-1)) {
      uint96 newAllowance = sub96(
        spenderAllowance,
        amount,
        "Doom::transferFrom: transfer amount exceeds spender allowance"
      );
      allowances[src][spender] = newAllowance;

      emit Approval(src, spender, newAllowance);
    }

    _transferTokens(src, dst, amount);
    return true;
  }

  function delegate(address delegatee) public {
    return _delegate(msg.sender, delegatee);
  }

  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    bytes32 domainSeparator = keccak256(
      abi.encode(
        DOMAIN_TYPEHASH,
        keccak256(bytes(name)),
        getChainId(),
        address(this)
      )
    );
    bytes32 structHash = keccak256(
      abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
    );
    bytes32 digest = keccak256(
      abi.encodePacked("\x19\x01", domainSeparator, structHash)
    );
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "Doom::delegateBySig: invalid signature");
    require(nonce == nonces[signatory]++, "Doom::delegateBySig: invalid nonce");
    require(now <= expiry, "Doom::delegateBySig: signature expired");
    return _delegate(signatory, delegatee);
  }

  function getCurrentVotes(address account) external view returns (uint96) {
    uint32 nCheckpoints = numCheckpoints[account];
    return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

  function getPriorVotes(address account, uint256 blockNumber)
    public
    view
    returns (uint96)
  {
    require(
      blockNumber < block.number,
      "Doom::getPriorVotes: not yet determined"
    );

    uint32 nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
      return 0;
    }

    if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
      return checkpoints[account][nCheckpoints - 1].votes;
    }

    if (checkpoints[account][0].fromBlock > blockNumber) {
      return 0;
    }

    uint32 lower = 0;
    uint32 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint32 center = upper - (upper - lower) / 2;
      Checkpoint memory cp = checkpoints[account][center];
      if (cp.fromBlock == blockNumber) {
        return cp.votes;
      } else if (cp.fromBlock < blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return checkpoints[account][lower].votes;
  }

  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = delegates[delegator];
    uint96 delegatorBalance = balances[delegator];
    delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _transferTokens(
    address src,
    address dst,
    uint96 amount
  ) internal {
    require(
      src != address(0),
      "Doom::_transferTokens: cannot transfer from the zero address"
    );
    require(
      dst != address(0),
      "Doom::_transferTokens: cannot transfer to the zero address"
    );

    balances[src] = sub96(
      balances[src],
      amount,
      "Doom::_transferTokens: transfer amount exceeds balance"
    );
    balances[dst] = add96(
      balances[dst],
      amount,
      "Doom::_transferTokens: transfer amount overflows"
    );
    emit Transfer(src, dst, amount);

    _moveDelegates(delegates[src], delegates[dst], amount);
  }

  function _moveDelegates(
    address srcRep,
    address dstRep,
    uint96 amount
  ) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint96 srcRepOld = srcRepNum > 0
          ? checkpoints[srcRep][srcRepNum - 1].votes
          : 0;
        uint96 srcRepNew = sub96(
          srcRepOld,
          amount,
          "Doom::_moveVotes: vote amount underflows"
        );
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      if (dstRep != address(0)) {
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint96 dstRepOld = dstRepNum > 0
          ? checkpoints[dstRep][dstRepNum - 1].votes
          : 0;
        uint96 dstRepNew = add96(
          dstRepOld,
          amount,
          "Doom::_moveVotes: vote amount overflows"
        );
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  function _writeCheckpoint(
    address delegatee,
    uint32 nCheckpoints,
    uint96 oldVotes,
    uint96 newVotes
  ) internal {
    uint32 blockNumber = safe32(
      block.number,
      "Doom::_writeCheckpoint: block number exceeds 32 bits"
    );

    if (
      nCheckpoints > 0 &&
      checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
    ) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  function safe32(uint256 n, string memory errorMessage)
    internal
    pure
    returns (uint32)
  {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function safe96(uint256 n, string memory errorMessage)
    internal
    pure
    returns (uint96)
  {
    require(n < 2**96, errorMessage);
    return uint96(n);
  }

  function add96(
    uint96 a,
    uint96 b,
    string memory errorMessage
  ) internal pure returns (uint96) {
    uint96 c = a + b;
    require(c >= a, errorMessage);
    return c;
  }

  function sub96(
    uint96 a,
    uint96 b,
    string memory errorMessage
  ) internal pure returns (uint96) {
    require(b <= a, errorMessage);
    return a - b;
  }

  function getChainId() internal pure returns (uint256) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    return chainId;
  }
}