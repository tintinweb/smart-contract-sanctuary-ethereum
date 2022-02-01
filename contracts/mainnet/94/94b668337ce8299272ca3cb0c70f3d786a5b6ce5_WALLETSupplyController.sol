/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

pragma solidity ^0.8.7;

// @TODO: Formatting
library LibBytes {
  // @TODO: see if we can just set .length = 
  function trimToSize(bytes memory b, uint newLen)
    internal
    pure
  {
    require(b.length > newLen, "BytesLib: only shrinking");
    assembly {
      mstore(b, newLen)
    }
  }


  /***********************************|
  |        Read Bytes Functions       |
  |__________________________________*/

  /**
   * @dev Reads a bytes32 value from a position in a byte array.
   * @param b Byte array containing a bytes32 value.
   * @param index Index in byte array of bytes32 value.
   * @return result bytes32 value from byte array.
   */
  function readBytes32(
    bytes memory b,
    uint256 index
  )
    internal
    pure
    returns (bytes32 result)
  {
    // Arrays are prefixed by a 256 bit length parameter
    index += 32;

    require(b.length >= index, "BytesLib: length");

    // Read the bytes32 from array memory
    assembly {
      result := mload(add(b, index))
    }
    return result;
  }
}



interface IERC1271Wallet {
	function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4 magicValue);
}

library SignatureValidator {
	using LibBytes for bytes;

	enum SignatureMode {
		EIP712,
		EthSign,
		SmartWallet,
		Spoof
	}

	// bytes4(keccak256("isValidSignature(bytes32,bytes)"))
	bytes4 constant internal ERC1271_MAGICVALUE_BYTES32 = 0x1626ba7e;

	function recoverAddr(bytes32 hash, bytes memory sig) internal view returns (address) {
		return recoverAddrImpl(hash, sig, false);
	}

	function recoverAddrImpl(bytes32 hash, bytes memory sig, bool allowSpoofing) internal view returns (address) {
		require(sig.length >= 1, "SV_SIGLEN");
		uint8 modeRaw;
		unchecked { modeRaw = uint8(sig[sig.length - 1]); }
		SignatureMode mode = SignatureMode(modeRaw);

		// {r}{s}{v}{mode}
		if (mode == SignatureMode.EIP712 || mode == SignatureMode.EthSign) {
			require(sig.length == 66, "SV_LEN");
			bytes32 r = sig.readBytes32(0);
			bytes32 s = sig.readBytes32(32);
			uint8 v = uint8(sig[64]);
			// Hesitant about this check: seems like this is something that has no business being checked on-chain
			require(v == 27 || v == 28, "SV_INVALID_V");
			if (mode == SignatureMode.EthSign) hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
			address signer = ecrecover(hash, v, r, s);
			require(signer != address(0), "SV_ZERO_SIG");
			return signer;
		// {sig}{verifier}{mode}
		} else if (mode == SignatureMode.SmartWallet) {
			// 32 bytes for the addr, 1 byte for the type = 33
			require(sig.length > 33, "SV_LEN_WALLET");
			uint newLen;
			unchecked {
				newLen = sig.length - 33;
			}
			IERC1271Wallet wallet = IERC1271Wallet(address(uint160(uint256(sig.readBytes32(newLen)))));
			sig.trimToSize(newLen);
			require(ERC1271_MAGICVALUE_BYTES32 == wallet.isValidSignature(hash, sig), "SV_WALLET_INVALID");
			return address(wallet);
		// {address}{mode}; the spoof mode is used when simulating calls
		} else if (mode == SignatureMode.Spoof && allowSpoofing) {
			// This is safe cause it's specifically intended for spoofing sigs in simulation conditions, where tx.origin can be controlled
			// slither-disable-next-line tx-origin
			require(tx.origin == address(1), "SV_SPOOF_ORIGIN");
			require(sig.length == 33, "SV_SPOOF_LEN");
			sig.trimToSize(32);
			return abi.decode(sig, (address));
		} else revert("SV_SIGMODE");
	}
}

library MerkleProof {
	function isContained(bytes32 valueHash, bytes32[] memory proof, bytes32 root) internal pure returns (bool) {
		bytes32 cursor = valueHash;

		uint256 proofLen = proof.length;
		for (uint256 i = 0; i < proofLen; i++) {
			if (cursor < proof[i]) {
				cursor = keccak256(abi.encodePacked(cursor, proof[i]));
			} else {
				cursor = keccak256(abi.encodePacked(proof[i], cursor));
			}
		}

		return cursor == root;
	}
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract WALLETToken {
	// Constants
	string public constant name = "Ambire Wallet";
	string public constant symbol = "WALLET";
	uint8 public constant decimals = 18;
	uint public constant MAX_SUPPLY = 1_000_000_000 * 1e18;

	// Mutable variables
	uint public totalSupply;
	mapping(address => uint) balances;
	mapping(address => mapping(address => uint)) allowed;

	event Approval(address indexed owner, address indexed spender, uint amount);
	event Transfer(address indexed from, address indexed to, uint amount);

	event SupplyControllerChanged(address indexed prev, address indexed current);

	address public supplyController;
	constructor(address _supplyController) {
		supplyController = _supplyController;
		emit SupplyControllerChanged(address(0), _supplyController);
	}

	function balanceOf(address owner) external view returns (uint balance) {
		return balances[owner];
	}

	function transfer(address to, uint amount) external returns (bool success) {
		balances[msg.sender] = balances[msg.sender] - amount;
		balances[to] = balances[to] + amount;
		emit Transfer(msg.sender, to, amount);
		return true;
	}

	function transferFrom(address from, address to, uint amount) external returns (bool success) {
		balances[from] = balances[from] - amount;
		allowed[from][msg.sender] = allowed[from][msg.sender] - amount;
		balances[to] = balances[to] + amount;
		emit Transfer(from, to, amount);
		return true;
	}

	function approve(address spender, uint amount) external returns (bool success) {
		allowed[msg.sender][spender] = amount;
		emit Approval(msg.sender, spender, amount);
		return true;
	}

	function allowance(address owner, address spender) external view returns (uint remaining) {
		return allowed[owner][spender];
	}

	// Supply control
	function innerMint(address owner, uint amount) internal {
		totalSupply = totalSupply + amount;
		require(totalSupply < MAX_SUPPLY, 'MAX_SUPPLY');
		balances[owner] = balances[owner] + amount;
		// Because of https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md#transfer-1
		emit Transfer(address(0), owner, amount);
	}

	function mint(address owner, uint amount) external {
		require(msg.sender == supplyController, 'NOT_SUPPLYCONTROLLER');
		innerMint(owner, amount);
	}

	function changeSupplyController(address newSupplyController) external {
		require(msg.sender == supplyController, 'NOT_SUPPLYCONTROLLER');
		// Emitting here does not follow checks-effects-interactions-logs, but it's safe anyway cause there are no external calls
		emit SupplyControllerChanged(supplyController, newSupplyController);
		supplyController = newSupplyController;
	}
}


interface IStakingPool {
	function enterTo(address recipient, uint amount) external;
}

contract WALLETSupplyController {
	event LogNewVesting(address indexed recipient, uint start, uint end, uint amountPerSec);
	event LogVestingUnset(address indexed recipient, uint end, uint amountPerSec);
	event LogMintVesting(address indexed recipient, uint amount);

	// solhint-disable-next-line var-name-mixedcase
	WALLETToken public immutable WALLET;
	mapping (address => bool) public hasGovernance;

	constructor(WALLETToken token, address initialGovernance) {
		hasGovernance[initialGovernance] = true;
		WALLET = token;
	}

	// Governance and supply controller
	function changeSupplyController(address newSupplyController) external {
		require(hasGovernance[msg.sender], "NOT_GOVERNANCE");
		WALLET.changeSupplyController(newSupplyController);
	}

	function setGovernance(address addr, bool level) external {
		require(hasGovernance[msg.sender], "NOT_GOVERNANCE");
		// Sometimes we need to get someone to de-auth themselves, but 
		// it's better to protect against bricking rather than have this functionality
		// we can burn conrtol by transferring control over to a contract that can't mint or by ypgrading the supply controller
		require(msg.sender != addr, "CANNOT_MODIFY_SELF");
		hasGovernance[addr] = level;
	}

	// Vesting
	// Some addresses (eg StakingPools) are incentivized with a certain allowance of WALLET per year
	// Also used for linear vesting of early supporters, team, etc.
	// mapping of (addr => end => rate) => lastMintTime;
	mapping (address => mapping(uint => mapping(uint => uint))) public vestingLastMint;
	function setVesting(address recipient, uint start, uint end, uint amountPerSecond) external {
		require(hasGovernance[msg.sender], "NOT_GOVERNANCE");
		// no more than 10 WALLET per second; theoretical emission max should be ~8 WALLET
		require(amountPerSecond <= 10e18, "AMOUNT_TOO_LARGE");
		require(start >= 1643695200, "START_TOO_LOW");
		require(vestingLastMint[recipient][end][amountPerSecond] == 0, "VESTING_ALREADY_SET");
		vestingLastMint[recipient][end][amountPerSecond] = start;
		emit LogNewVesting(recipient, start, end, amountPerSecond);
	}
	function unsetVesting(address recipient, uint end, uint amountPerSecond) external {
		require(hasGovernance[msg.sender], "NOT_GOVERNANCE");
		// AUDIT: Pending (unclaimed) vesting is lost here - this is intentional
		vestingLastMint[recipient][end][amountPerSecond] = 0;
		emit LogVestingUnset(recipient, end, amountPerSecond);
	}

	// vesting mechanism
	function mintableVesting(address addr, uint end, uint amountPerSecond) public view returns (uint) {
		uint lastMinted = vestingLastMint[addr][end][amountPerSecond];
		if (lastMinted == 0) return 0;
		// solhint-disable-next-line not-rely-on-time
		if (block.timestamp > end) {
			require(end > lastMinted, "VESTING_OVER");
			return (end - lastMinted) * amountPerSecond;
		} else {
			// this means we have not started yet
			// solhint-disable-next-line not-rely-on-time
			if (lastMinted > block.timestamp) return 0;
			// solhint-disable-next-line not-rely-on-time
			return (block.timestamp - lastMinted) * amountPerSecond;
		}
	}

	function mintVesting(address recipient, uint end, uint amountPerSecond) external {
		uint amount = mintableVesting(recipient, end, amountPerSecond);
		// solhint-disable-next-line not-rely-on-time
		vestingLastMint[recipient][end][amountPerSecond] = block.timestamp;
		WALLET.mint(recipient, amount);
		emit LogMintVesting(recipient, amount);
	}

	//
	// Rewards distribution
	//
	event LogUpdatePenaltyBps(uint newPenaltyBps);
	event LogClaimStaked(address indexed recipient, uint claimed);
	event LogClaimWithPenalty(address indexed recipient, uint received, uint burned);

	uint public immutable MAX_CLAIM_NODE = 80_000_000e18;

	bytes32 public lastRoot;
	mapping (address => uint) public claimed;
	uint public penaltyBps = 0;

	function setPenaltyBps(uint _penaltyBps) external {
		require(hasGovernance[msg.sender], "NOT_GOVERNANCE");
		require(penaltyBps <= 10000, "BPS_IN_RANGE");
		penaltyBps = _penaltyBps;
		emit LogUpdatePenaltyBps(_penaltyBps);
	}

	function setRoot(bytes32 newRoot) external {
		require(hasGovernance[msg.sender], "NOT_GOVERNANCE");
		lastRoot = newRoot;
	}

	function claimWithRootUpdate(
		// claim() args
		address recipient, uint totalRewardInTree, bytes32[] calldata proof, uint toBurnBps, IStakingPool stakingPool,
		// args for updating the root
		bytes32 newRoot, bytes calldata signature
	) external {
		address signer = SignatureValidator.recoverAddrImpl(newRoot, signature, false);
		require(hasGovernance[signer], "NOT_GOVERNANCE");
		lastRoot = newRoot;
		claim(recipient, totalRewardInTree, proof, toBurnBps, stakingPool);
	}

	// claim() has two modes, either receive the full amount as xWALLET (staked WALLET) or burn some (penaltyBps) and receive the rest immediately in $WALLET
	// toBurnBps is a safety parameter that serves two purposes:
	// 1) prevents griefing attacks/frontrunning where governance sets penalties higher before someone's claim() gets mined
	// 2) ensures that the sender really does have the intention to burn some of their tokens but receive the rest immediatey
	// set toBurnBps to 0 to receive the tokens as xWALLET, set it to the current penaltyBps to receive immediately
	// There is an edge case: when penaltyBps is set to 0, you pass 0 to receive everything immediately; this is intended
	function claim(address recipient, uint totalRewardInTree, bytes32[] memory proof, uint toBurnBps, IStakingPool stakingPool) public {
		require(totalRewardInTree <= MAX_CLAIM_NODE, "MAX_CLAIM_NODE");
		require(lastRoot != bytes32(0), "EMPTY_ROOT");

		// Check the merkle proof
		bytes32 leaf = keccak256(abi.encode(address(this), recipient, totalRewardInTree));
		require(MerkleProof.isContained(leaf, proof, lastRoot), "LEAF_NOT_FOUND");

		uint toClaim = totalRewardInTree - claimed[recipient];
		claimed[recipient] = totalRewardInTree;

		if (toBurnBps == penaltyBps) {
			// Claiming in $WALLET directly: some tokens get burned immediately, but the rest go to you
			uint toBurn = (toClaim * penaltyBps) / 10000;
			uint toReceive = toClaim - toBurn;
			// AUDIT: We can check toReceive > 0 or toBurn > 0, but there's no point since in the most common path both will be non-zero
			WALLET.mint(recipient, toReceive);
			WALLET.mint(address(0), toBurn);
      emit LogClaimWithPenalty(recipient, toReceive, toBurn);
		} else if (toBurnBps == 0) {
			WALLET.mint(address(this), toClaim);
			if (WALLET.allowance(address(this), address(stakingPool)) < toClaim) {
				WALLET.approve(address(stakingPool), type(uint256).max);
			}
			stakingPool.enterTo(recipient, toClaim);
			emit LogClaimStaked(recipient, toClaim);
		} else {
			revert("INVALID_TOBURNBPS");
		}
	}

	// In case funds get stuck
	function withdraw(IERC20 token, address to, uint256 tokenAmount) external {
		require(hasGovernance[msg.sender], "NOT_GOVERNANCE");
		// AUDIT: SafeERC20 or similar not needed; this is a trusted (governance only) method that doesn't modify internal accounting
		// so sucess/fail does not matter
		token.transfer(to, tokenAmount);
	}
}