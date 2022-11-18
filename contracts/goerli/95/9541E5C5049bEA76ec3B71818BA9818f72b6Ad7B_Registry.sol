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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./SignatureLib.sol";

interface IMarket {
	function getFee() external view returns (uint8);

	function getTotalInPlay() external view returns (uint256);

	function getInPlayCount() external view returns (uint256);

	function getTotalExposure() external view returns (uint256);

	function getBetByIndex(uint256 index)
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			bool,
			address
		);

	function getOdds(
		int256 wager,
		int256 odds,
		bytes32 propositionId
	) external view returns (int256);

	function getOracleAddress() external view returns (address);

	function getPotentialPayout(
		bytes32 propositionId,
		uint256 wager,
		uint256 odds
	) external view returns (uint256);

	function getVaultAddress() external view returns (address);

	function back(
		bytes32 nonce,
		bytes32 propositionId,
		bytes32 marketId,
		uint256 wager,
		uint256 odds,
		uint256 close,
		uint256 end,
		SignatureLib.Signature calldata sig
	) external returns (uint256);

	function settle(uint256 index) external;

	// function settleMarket(
	//     uint256 from,
	//     uint256 to,
	//     bytes32 marketId
	// ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IVault is IERC20Metadata {
    function asset() external view returns (IERC20Metadata assetTokenAddress);

    function deposit(
        uint256 assets,
        address receiver
    ) external returns (uint256 shares);

    function getPerformance() external view returns (uint256);

    function setMarket(address market, uint256 max) external;

    function totalAssets() external view returns (uint256);

    function withdraw(uint256 shares) external;

    event Deposit(address indexed who, uint256 value);
    event Withdraw(address indexed who, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./IMarket.sol";
import "./IVault.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract Registry {
    address[] public markets;
    IVault[] public vaults;

    mapping(address => IVault) private _underlying;
    mapping(address => address) private _markets;

    address private immutable _owner;
    IERC20Metadata private immutable _token;
    uint256 private _threshold;

    function marketCount() external view returns (uint256) {
        return markets.length;
    }

    function vaultCount() external view returns (uint256) {
        return vaults.length;
    }

    constructor(IERC20Metadata token) {
        _owner = msg.sender;
        _token = token;
    }

    function addVault(IVault vault) external onlyTokenHolders {
        IERC20Metadata underlying = vault.asset();
        require(
            address(_underlying[address(underlying)]) == address(0),
            "addVault: Vault with this underlying token already added"
        );

        vaults.push(vault);
        _underlying[address(underlying)] = vault; // underlying => vault

        emit VaultAdded(address(vault));
    }

    function addMarket(address market) external onlyTokenHolders {
        require(
            _markets[market] == address(0),
            "addMarket: Market already added"
        );
        _markets[market] = market;
        markets.push(market);
        emit MarketAdded(market);
    }

    function setThreshold(uint256 threshold) external onlyOwner {
        _threshold = threshold;
        emit ThresholdUpdated(threshold);
    }

    modifier onlyTokenHolders() {
        require(
            _token.balanceOf(msg.sender) >= _threshold,
            "onlyTokenHolders: Caller does not hold enough tokens"
        );
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "onlyOwner: Caller is not the contract owner"
        );
        _;
    }

    event MarketAdded(address indexed market);
    event ThresholdUpdated(uint256 threshold);
    event VaultAdded(address indexed vault);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

library SignatureLib {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function recoverSigner(
        bytes32 message,
        Signature memory signature
    ) public pure returns (address) {
        bytes32 prefixedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );
        return ecrecover(prefixedHash, signature.v, signature.r, signature.s);
    }
}