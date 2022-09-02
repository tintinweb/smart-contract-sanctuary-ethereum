// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "src/interface/IMultiMerkleStash.sol";
import "src/interface/IVeSDT.sol";

/// @notice Contract helper for bundle tx for claiming bribes and lock SDT for veSDT
contract ClaimAndLock {
	address public multiMerkleStash = address(0x03E34b085C52985F6a5D27243F20C84bDdc01Db4);
	address public constant VE_SDT = address(0x0C30476f66034E11782938DF8e4384970B6c9e8a);
	address public constant SDT = address(0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F);

	constructor() {
		IERC20(SDT).approve(VE_SDT, type(uint256).max);
	}

	/// @notice Bundle tx for Claiming (only) SDT from bribes and Lock it on veSDT
	/// @dev For locking SDT into veSDT, account should already have some veSDT
	/// @dev Can't lock SDT into veSDT for first time here
	/// @param index Index for the merkle tree
	/// @param amount Amount of bribes received
	/// @param merkleProof MerkleProof for this bribes session
	function claimAndLockSDT(
		uint256 index,
		uint256 amount,
		bytes32[] calldata merkleProof
	) external {
		//claim SDT from bribes
		IMultiMerkleStash(multiMerkleStash).claim(SDT, index, msg.sender, amount, merkleProof);
		// lock SDT
		IERC20(SDT).transferFrom(msg.sender, address(this), amount);
		IVeSDT(VE_SDT).deposit_for(msg.sender, amount);
	}

	/// @notice Bundle tx for Claiming bribes and Lock SDT for veSDT
	/// @dev For locking SDT into veSDT, account should already have some veSDT
	/// @dev Can't lock SDT into veSDT for first time here
	/// @param claims List containing claimParam structure argument needed for claimMulti
	function claimAndLockMulti(IMultiMerkleStash.claimParam[] calldata claims) external {
		//claim all bribes token
		IMultiMerkleStash(multiMerkleStash).claimMulti(msg.sender, claims);
		// find amount of SDT claimed
		uint256 amountSDT = 0;
		for (uint256 i = 0; i < claims.length; ) {
			if (claims[i].token == SDT) {
				amountSDT = claims[i].amount;
				break;
			}
			unchecked {
				++i;
			}
		}
		// lock SDT
		IERC20(SDT).transferFrom(msg.sender, address(this), amountSDT);
		IVeSDT(VE_SDT).deposit_for(msg.sender, amountSDT);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IMultiMerkleStash {
	struct claimParam {
		address token;
		uint256 index;
		uint256 amount;
		bytes32[] merkleProof;
	}

	function isClaimed(address token, uint256 index) external view returns (bool);

	function claim(
		address token,
		uint256 index,
		address account,
		uint256 amount,
		bytes32[] calldata merkleProof
	) external;

	function merkleRoot(address _address) external returns (bytes32);

	function claimMulti(address account, claimParam[] calldata claims) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IVeSDT {
	function deposit_for(address _addr, uint256 _value) external;

	function balanceOf(address _addr) external returns (uint256);
}