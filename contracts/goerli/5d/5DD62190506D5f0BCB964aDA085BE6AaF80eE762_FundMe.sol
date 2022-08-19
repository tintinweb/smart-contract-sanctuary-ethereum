//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import './PriceConverter.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/* @title Crowdfund contract
 * @author Franz Quarshie
 * @notice This contract allows users to deposit funds into the contract
 * @dev Contract deployer is the only one who can withdraw funds | Good Practices - Use 'constant' and 'immutable' to reduce gas
 */

error FUndMe__WithdrawFailed();

contract FundMe is Ownable {
	//Address of ETH price feed contract on Goerli Testnet - 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
	constructor(address priceFeedAddress) {
		priceFeed = AggregatorV3Interface(priceFeedAddress);
	}

	AggregatorV3Interface private priceFeed;
	using PriceConverter for uint256;
	//Set mimimun deposit amount  - 10 USD
	//Since solidity doesn't work with decimal plcaes, use base 18
	uint256 public constant MIN_USD = 0.1 * 1e18;
	address[] public funders;
	mapping(address => uint256) public addressToAmountFunded;

	/**
	 * @notice Function funds the contract
	 */
	function fund() public payable {
		//Require mimimun deposit amount
		//Function will revert with messsage if requirement fails -> Gas will be returned
		//msg.value will return 1e18
		require(
			msg.value.getConversionRate(priceFeed) >= MIN_USD,
			'Minimum Insufficient'
		); //1 x 10 x 18 = 100000000000000000 Wei
		funders.push(msg.sender);
		addressToAmountFunded[msg.sender] += msg.value;
	}

	function withdraw() public onlyOwner {
		for (
			uint256 funderIndex = 0;
			funderIndex < funders.length;
			funderIndex++
		) {
			address funder = funders[funderIndex];
			addressToAmountFunded[funder] = 0;
		}
		funders = new address[](0);
		//Transfer - Caps at 2300 gas, Throws error
		//payable(msg.sender).transfer(address(this).balance);

		//Send - Caps at 2300 gas, Returns boolean
		//bool sent = payable(msg.sender).send(address(this).balance);
		//require(sent, "Withdrawal failed");

		//Call - Forawards all gas or set gas, Returns boolean
		(bool callSuccess, ) = payable(msg.sender).call{
			value: address(this).balance
		}('');
		if (callSuccess == false) {
			revert FUndMe__WithdrawFailed();
		}
	}

	function cheaperWithdraw() public onlyOwner {
		address[] memory copyFunders = funders;
		for (
			uint256 funderIndex = 0;
			funderIndex < funders.length;
			funderIndex++
		) {
			address funder = copyFunders[funderIndex];
			addressToAmountFunded[funder] = 0;
		}
		funders = new address[](0);

		(bool callSuccess, ) = payable(msg.sender).call{
			value: address(this).balance
		}('');
		if (callSuccess == false) {
			revert FUndMe__WithdrawFailed();
		}
	}

	function getPriceFeed() public view returns (AggregatorV3Interface) {
		return priceFeed;
	}

	//If msg.data is null
	//This special function is triggered if a transaction is sent without data i.e the dedicated function to receive and process deposits
	receive() external payable {
		//Send donation to contract creator
		payable(owner()).transfer(msg.value);
	}

	//This special function is triggered if no msg.data is empty
	fallback() external payable {
		//Send donation to contract creator
		payable(owner()).transfer(msg.value);
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

library PriceConverter {
	function getETHPrice(AggregatorV3Interface priceFeed)
		internal
		view
		returns (uint256)
	{
		//latestRoundData() from AggregatorV3Interface.sol returns 5 variables; Use commas to escape
		//Refer to AggregatorV3Interface.sol to check return types
		(, int256 price, , , ) = priceFeed.latestRoundData();
		//int256 price will return 1e8
		//Multiply int256 price with 1e10 to match msg.sender decimal places
		return uint256(price * 1e10);
	}

	//Accepts ETH value and returns equivalent in USD 1e18
	function getConversionRate(
		uint256 ethValue,
		AggregatorV3Interface priceFeed
	) internal view returns (uint256) {
		uint256 ethPrice = getETHPrice(priceFeed);
		uint256 ethValue_Usd = (ethPrice * ethValue) / 1e18;
		return ethValue_Usd;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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