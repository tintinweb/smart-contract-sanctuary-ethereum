pragma solidity >=0.8.0;


import "PortfolioScore.sol";
import "Ownable.sol";


contract MockPortfolioScore is PortfolioScore, Ownable
{
	constructor() Ownable()
	{

	}

	function setScoreData(address vault, uint256[6] calldata s, uint256 profitScore, uint256 apy) external onlyOwner
	{
		scores[vault].data = s;
		scores[vault].profitScore = profitScore;
		scores[vault].apyInPpm = apy;

		emit ScoreDataUpdated(vault);
	}
}

pragma solidity >=0.8.0;


abstract contract PortfolioScore
{
	struct ScoreData
	{
		uint256[6] data;
		uint256 profitScore;
		uint256 apyInPpm;
	}

	event ScoreDataUpdated(address indexed vault);

	mapping (address => ScoreData) public scores;

	constructor ()
	{

	}

	// Returns number of ppms (from 0 to 1000)
	function getPortfolioScore(address vault) public view returns (uint256)
	{
		ScoreData storage scoreData = scores[vault];
		uint256 riskScore = 0;
		uint256[6] memory w = [uint256(20), 10, 10, 5, 50, 5];// First unit256() is need for declaration.
		for (uint256 i = 0; i < 6; i++)
		{
			riskScore += w[i] * scoreData.data[i];
		}

		//riskScore /= 100;

		return (riskScore * 60 / 100 + scoreData.profitScore * 40) / 100; 
	}

	function getApy(address vault) external view returns (uint256)
	{
		return scores[vault].apyInPpm;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}