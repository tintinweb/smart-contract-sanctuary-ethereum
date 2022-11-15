/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

contract MMT {
    using SafeMath for uint256;

    string public constant name = "Ms Meta Token";
    string public constant symbol = "MMT";
    uint8 public constant decimals = 8;
    uint256 public constant totalSupply = 1_000_000_000e8;
    uint256 internal constant MASK = type(uint256).max;

    mapping(address => mapping(address => uint256)) internal allowances;
    mapping(address => uint256) internal balances;
    mapping(address => address) public delegates;
    mapping(address => uint256) public nonces;

    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;
    mapping(address => uint32) public numCheckpoints;

    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

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

    constructor(address account) {
        balances[account] = totalSupply;
        emit Transfer(address(0), account, totalSupply);
    }

    function allowance(address account, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[account][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];
        if (spender != src && spenderAllowance != MASK) {
            uint256 newAllowance = spenderAllowance.sub(amount);
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
        require(signatory != address(0), "delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return
            nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    function getPriorVotes(address account, uint32 blockNumber)
        public
        view
        returns (uint256)
    {
        require(
            blockNumber < uint32(block.number),
            "getPriorVotes: not yet determined"
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
        uint256 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;
        emit DelegateChanged(delegator, currentDelegate, delegatee);
        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(
        address src,
        address dst,
        uint256 amount
    ) internal {
        require(
            src != address(0),
            "_transferTokens: cannot transfer from the zero address"
        );
        require(
            dst != address(0),
            "_transferTokens: cannot transfer to the zero address"
        );
        balances[src] = balances[src].sub(amount);
        balances[dst] = balances[dst].add(amount);
        emit Transfer(src, dst, amount);
        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0
                    ? checkpoints[srcRep][srcRepNum - 1].votes
                    : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0
                    ? checkpoints[dstRep][dstRepNum - 1].votes
                    : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint32 blockNumber = uint32(block.number);
        if (
            nCheckpoints > 0 &&
            checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(
                blockNumber,
                newVotes
            );
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }
        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

library SafeMath {
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return sub(_a, _b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 _a,
        uint256 _b,
        string memory _errorMessage
    ) internal pure returns (uint256) {
        require(_b <= _a, _errorMessage);
        uint256 c = _a - _b;
        return c;
    }

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }
        uint256 c = _a * _b;
        require(c / _a == _b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return div(_a, _b, "SafeMath: division by zero");
    }

    function div(
        uint256 _a,
        uint256 _b,
        string memory _errorMessage
    ) internal pure returns (uint256) {
        require(_b > 0, _errorMessage);
        uint256 c = _a / _b;
        return c;
    }

    function mod(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return mod(_a, _b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 _a,
        uint256 _b,
        string memory _errorMessage
    ) internal pure returns (uint256) {
        require(_b != 0, _errorMessage);
        return _a % _b;
    }
}