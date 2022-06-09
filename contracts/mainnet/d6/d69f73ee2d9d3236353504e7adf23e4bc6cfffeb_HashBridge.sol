/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// File: @openzeppelin\contracts\utils\Context.sol

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

// File: @openzeppelin\contracts\access\Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: contracts\TransferHelper.sol

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// File: contracts\HashBridge.sol

pragma solidity ^0.8.0;
contract HashBridge is Ownable {
	address public hashAddress;
	uint public chainId;
	uint public reservationTime;
	uint public minVoteWeight;
	uint public votesThreshold;
	uint public arbitratorGuaranteePercent;
	uint public commissionForDeal;
	uint public finalVoteBonusPercent;

	uint public constant RATE_DECIMALS = 18;

	struct Offer {
		address token;
		uint amount;
		uint payChainId;
		address payToken;
		uint rate;
		address ownerAddress;
		address payAddress;
		uint minPurchase;
		bool active;
	}
	struct Order {
		uint offerId;
		uint rate;
		address ownerAddress;
		address withdrawAddress;
		uint amount;
		uint payAmount;
		address payAddress;
		uint reservedUntil;
		uint votesFor;
		uint votesAgainst;
		bool complete;
		bool declined;
	}
	struct Payment {
		uint chainId;
		uint orderId;
		uint payAmount;
		address payToken;
		address payAddress;
	}
	struct Vote {
	    uint orderId;
	    address voterAddress;
	    uint voteWeight;
	    uint guarantee;
	    bool success;
	    bool ultimate;
	}

	Offer[] public offers;
	Order[] public orders;
	Payment[] public payments;
	Vote[] public votes;

	event OfferAdd(
		uint indexed offerId,
		address indexed token,
		uint indexed payChainId,
		address payToken,
		address ownerAddress,
		address payAddress,
		uint amount,
		uint rate,
		uint minPurchase,
		bool active
	);
	event OfferUpdate(
		uint indexed offerId,
		address payAddress,
		uint amount,
		uint rate,
		uint minPurchase,
		bool active
	);
	event OrderAdd(
		uint indexed orderId,
		uint indexed offerId,
		address indexed ownerAddress,
		uint rate,
		address withdrawAddress,
		uint amount,
		uint payAmount,
		address payAddress,
		uint reservedUntil
	);
	event OrderPay(
		uint indexed paymentId,
		uint indexed chainId,
		uint indexed orderId,
		uint payAmount,
		address payToken,
		address payAddress
	);
	event VoteAdd(
		uint indexed voteId,
		uint indexed orderId,
		address indexed voterAddress,
		uint voteWeight,
		uint guarantee,
		bool success,
		bool ultimate,
		uint offerAmount
	);

	constructor(
		address _hashAddress,
		uint _chainId,
		uint _reservationTime,
		uint _minVoteWeight,
		uint _votesThreshold,
		uint _arbitratorGuaranteePercent,
		uint _commissionForDeal,
		uint _finalVoteBonusPercent
	) {
        hashAddress = _hashAddress;
		chainId = _chainId;
		reservationTime = _reservationTime;
		minVoteWeight = _minVoteWeight;
		votesThreshold = _votesThreshold;
		arbitratorGuaranteePercent = _arbitratorGuaranteePercent;
		commissionForDeal = _commissionForDeal;
		finalVoteBonusPercent = _finalVoteBonusPercent;
    }

	function changeHashAddress(address _hashAddress) external onlyOwner {
        hashAddress = _hashAddress;
    }

	function changeReservationTime(uint _reservationTime) external onlyOwner {
		reservationTime = _reservationTime;
	}

	function changeMinVoteWeight(uint _minVoteWeight) external onlyOwner {
		minVoteWeight = _minVoteWeight;
	}

	function changeVotesThreshold(uint _votesThreshold) external onlyOwner {
		votesThreshold = _votesThreshold;
	}

	function changeArbitratorGuaranteePercent(uint _arbitratorGuaranteePercent) external onlyOwner {
		arbitratorGuaranteePercent = _arbitratorGuaranteePercent;
	}

	function changeCommissionForDeal(uint _commissionForDeal) external onlyOwner {
		commissionForDeal = _commissionForDeal;
	}

	function changeFinalVoteBonusPercent(uint _finalVoteBonusPercent) external onlyOwner {
		finalVoteBonusPercent = _finalVoteBonusPercent;
	}

	function addOffer(
		address _token,
		uint _amount,
		uint _payChainId,
		address _payToken,
		uint _rate,
		address _payAddress,
		uint _minPurchase
	) external {
		require(_amount > 0, "Amount must be greater than 0");
		require(_amount >= _minPurchase, "Amount must not be less than the minimum purchase");
		require(_rate > 0, "Rate must be greater than 0");
		_checkExchangerHashBalance(msg.sender);
		TransferHelper.safeTransferFrom(_token, msg.sender, address(this), _amount);
		uint offerId = offers.length;
		offers.push(Offer(_token, _amount, _payChainId, _payToken, _rate, msg.sender, _payAddress, _minPurchase, true));
		emit OfferAdd(offerId, _token, _payChainId, _payToken, msg.sender, _payAddress, _amount, _rate, _minPurchase, true);
	}

	function updateOffer(uint _offerId, uint _amount, uint _rate, address _payAddress, uint _minPurchase) external {
		_checkOfferAccess(_offerId);
		require(_rate > 0, "Rate must be greater than 0");
		uint blockedAmount = _getBlockedAmount(_offerId);
		require(_amount >= blockedAmount, "You can not withdraw tokens ordered by customers");
		if (_amount > offers[_offerId].amount) {
			TransferHelper.safeTransferFrom(offers[_offerId].token, msg.sender, address(this), _amount - offers[_offerId].amount);
		} else {
			TransferHelper.safeTransfer(offers[_offerId].token, msg.sender, offers[_offerId].amount - _amount);
		}
		offers[_offerId].amount = _amount;
		offers[_offerId].rate = _rate;
		offers[_offerId].payAddress = _payAddress;
		offers[_offerId].minPurchase = _minPurchase;
		emit OfferUpdate(_offerId, _payAddress, _amount, _rate, _minPurchase, offers[_offerId].active);
	}

	function activateOffer(uint _offerId) external {
		_checkOfferAccess(_offerId);
		require(offers[_offerId].active == false, "Offer is already active");
		offers[_offerId].active = true;
		emit OfferUpdate(_offerId, offers[_offerId].payAddress, offers[_offerId].amount, offers[_offerId].rate, offers[_offerId].minPurchase, true);
	}

	function deactivateOffer(uint _offerId) external {
		_checkOfferAccess(_offerId);
		require(offers[_offerId].active == true, "Offer is already inactive");
		offers[_offerId].active = false;
		emit OfferUpdate(_offerId, offers[_offerId].payAddress, offers[_offerId].amount, offers[_offerId].rate, offers[_offerId].minPurchase, false);
	}

	function addOrder(uint _offerId, address _withdrawAddress, uint _amount, uint _payAmount) external {
		require(_offerId < offers.length, "Incorrect offerId");
		require(offers[_offerId].active == true, "Offer is inactive");
		require(_amount > 0 || _payAmount > 0, "Amount must be greater than 0");
		_checkExchangerHashBalance(offers[_offerId].ownerAddress);
		uint rate = offers[_offerId].rate;
		if (_amount > 0) {
			_payAmount = _amount * rate / (10 ** RATE_DECIMALS);
		} else {
			_amount = _payAmount * (10 ** RATE_DECIMALS) / rate;
		}
		require(_amount >= offers[_offerId].minPurchase, "Amount is less than the minimum purchase");
		uint blockedAmount = _getBlockedAmount(_offerId);
		require(_amount <= offers[_offerId].amount - blockedAmount, "Not enough tokens in the offer");
		address _payAddress = offers[_offerId].payAddress;
		uint reservedUntil = block.timestamp + reservationTime;
		uint orderId = orders.length;
		orders.push(Order(_offerId, rate, msg.sender, _withdrawAddress, _amount, _payAmount, _payAddress, reservedUntil, 0, 0, false, false));
		emit OrderAdd(orderId, _offerId, msg.sender, rate, _withdrawAddress, _amount, _payAmount, _payAddress, reservedUntil);
	}

	function payOrder(uint _chainId, uint _orderId, uint _payAmount, address _payToken, address _payAddress) external {
		require(_payAmount > 0, "Amount must be greater than 0");
		TransferHelper.safeTransferFrom(_payToken, msg.sender, _payAddress, _payAmount);
		uint paymentId = payments.length;
		payments.push(Payment(_chainId, _orderId, _payAmount, _payToken, _payAddress));
		emit OrderPay(paymentId, _chainId, _orderId, _payAmount, _payToken, _payAddress);
	}

	function vote(uint _orderId, bool _success) external {
	    require(_orderId < orders.length, "Incorrect orderId");
        require(orders[_orderId].complete == false, "Tokens are already withdrawn");
        require(orders[_orderId].declined == false, "Order is already declined");
        for (uint i = 0; i < votes.length; i++) {
            if (votes[i].orderId == _orderId) {
                require(votes[i].voterAddress != msg.sender, "You've alreay voted for this order");
            }
        }
        uint voteWeight = _getHashBalance(msg.sender);
        uint hashAllowance = _getHashAllowance(msg.sender);
        if (hashAllowance < voteWeight) {
            voteWeight = hashAllowance;
        }
        require(voteWeight >= minVoteWeight, "Not enough HASH tokens");
        uint guarantee = voteWeight * arbitratorGuaranteePercent / 100;
        uint offerId = orders[_orderId].offerId;
		bool ultimate = false;
        if (_success) {
            orders[_orderId].votesFor += voteWeight;
            if (orders[_orderId].votesFor > votesThreshold) {
                TransferHelper.safeTransfer(offers[offerId].token, orders[_orderId].withdrawAddress, orders[_orderId].amount);
                orders[_orderId].complete = true;
		        offers[offerId].amount -= orders[_orderId].amount;
		        ultimate = true;
            }
        } else {
            orders[_orderId].votesAgainst += voteWeight;
            if (orders[_orderId].votesAgainst > votesThreshold) {
                orders[_orderId].declined = true;
                ultimate = true;
            }
        }
        if (ultimate) {
            (uint votesWeight, uint penalties) = _getOrderVotesInfo(_orderId, _success);
            votesWeight += voteWeight;
            uint commissionSent = 0;
            uint penaltiesSent = 0;
            for (uint i = 0; i < votes.length; i++) {
    			if (votes[i].orderId == _orderId && votes[i].success == _success) {
    			    uint commission = commissionForDeal * votes[i].voteWeight * (100 - finalVoteBonusPercent) / (votesWeight * 100);
    			    if (_success && commission > 0) {
    			        TransferHelper.safeTransferFrom(hashAddress, offers[offerId].ownerAddress, votes[i].voterAddress, commission);
    				    commissionSent += commission;
    			    }
				    uint penaltyCommission = penalties * votes[i].voteWeight * (100 - finalVoteBonusPercent) / (votesWeight * 100);
			        TransferHelper.safeTransfer(hashAddress, votes[i].voterAddress, penaltyCommission + votes[i].guarantee);
			        penaltiesSent += penaltyCommission;
    			}
    		}
    		if (_success && commissionForDeal > commissionSent) {
    		    TransferHelper.safeTransferFrom(hashAddress, offers[offerId].ownerAddress, msg.sender, commissionForDeal - commissionSent);
    		}
    		if (penalties > penaltiesSent) {
    		    TransferHelper.safeTransfer(hashAddress, msg.sender, penalties - penaltiesSent);
    		}
        } else {
            TransferHelper.safeTransferFrom(hashAddress, msg.sender, address(this), guarantee);
        }
        uint voteId = votes.length;
        votes.push(Vote(_orderId, msg.sender, voteWeight, guarantee, _success, ultimate));
        emit VoteAdd(voteId, _orderId, msg.sender, voteWeight, guarantee, _success, ultimate, offers[offerId].amount);
	}

	function getOrderIdForArbitration(address _arbitratorAddress, uint _startId) external view returns(uint, bool) {
	    for (uint i = _startId; i < orders.length; i++) {
			if (orders[i].complete == true || orders[i].declined == true) {
			    continue;
			}
			bool returnThis = true;
			for (uint j = 0; j < votes.length; j++) {
			    if (votes[j].orderId == i && votes[j].voterAddress == _arbitratorAddress) {
			        returnThis = false;
			        break;
			    }
			}
		    if (returnThis) {
		        return (i, true);
		    }
		}
		return (0, false);
	}

	function checkPayment(
		uint _chainId,
		uint _orderId,
		uint _payAmount,
		address _payToken,
		address _payAddress
	) external view returns(bool) {
	    for (uint i = 0; i < payments.length; i++) {
	        if (
				payments[i].chainId == _chainId &&
				payments[i].orderId == _orderId &&
				payments[i].payAmount == _payAmount &&
				payments[i].payToken == _payToken &&
				payments[i].payAddress == _payAddress
			) {
	            return true;
	        }
	    }
	    return false;
	}

	function _checkOfferAccess(uint _offerId) private view {
		require(_offerId < offers.length, "Incorrect offerId");
		require(offers[_offerId].ownerAddress == msg.sender, "Forbidden");
	}

	function _getBlockedAmount(uint _offerId) private view returns(uint blockedAmount) {
		blockedAmount = 0;
		for (uint i = 0; i < orders.length; i++) {
			if (orders[i].offerId == _offerId && orders[i].complete == false && orders[i].declined == false && orders[i].reservedUntil >= block.timestamp) {
				blockedAmount += orders[i].amount;
			}
		}
	}

	function _getHashBalance(address _address) private returns(uint balance) {
	    (bool success, bytes memory data) = hashAddress.call(
	        abi.encodeWithSelector(bytes4(keccak256(bytes('balanceOf(address)'))), _address)
        );
        require(success, "Getting HASH balance failed");
        balance = abi.decode(data, (uint));
	}

	function _getHashAllowance(address _address) private returns(uint allowance) {
	    (bool success, bytes memory data) = hashAddress.call(
	        abi.encodeWithSelector(bytes4(keccak256(bytes('balanceOf(address)'))), _address, address(this))
        );
        require(success, "Getting HASH allowance failed");
        allowance = abi.decode(data, (uint));
	}

	function _getOrderVotesInfo(uint _orderId, bool _success) private view returns(uint votesWeight, uint penalties) {
	    votesWeight = 0;
	    penalties = 0;
	    for (uint i = 0; i < votes.length; i++) {
			if (votes[i].orderId == _orderId) {
    			if (votes[i].success == _success) {
    				votesWeight += votes[i].voteWeight;
    			} else {
    			    penalties += votes[i].guarantee;
    			}
			}
		}
	}

	function _checkExchangerHashBalance(address _address) private {
	    uint balance = _getHashBalance(_address);
	    uint allowance = _getHashAllowance(_address);
	    for (uint i = 0; i < offers.length; i++) {
	        if (offers[i].ownerAddress != _address) {
	            continue;
	        }
	        for (uint j = 0; j < orders.length; j++) {
	            if (orders[j].offerId == i && orders[j].complete == false && orders[j].declined == false && orders[j].reservedUntil >= block.timestamp) {
	                balance -= commissionForDeal;
	                allowance -= commissionForDeal;
	            }
	        }
	    }
	    require(balance >= commissionForDeal && allowance >= commissionForDeal, "Exchanger does not have enough HASH tokens for the deal arbitration");
	}
}