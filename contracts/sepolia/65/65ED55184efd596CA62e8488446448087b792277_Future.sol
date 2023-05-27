// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

// ERC20 standard interface
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// protect against reentrancy attacks
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Future is ReentrancyGuard {
    //-------------------------------------------------Structs + Enumerations---------------------------------------------------
    // Asset structs
    struct Asset {
        // Asset name
        string _name;
        // Asset adress
        address _address;
    }

	// Trade structs
	struct Trade {
        // OfferID
        uint _offerId;
        // buyer adress
		address buyer;
        // Quantity of Buyer
        uint quantity;
        // Trade time
		uint timestamp;
	}

	// Offer struct
	struct Offer {
        // ID
        uint _offerId;
        // Seller address
		address seller;
        // Asset address
		address asset;
        // Price
		uint price;
        // Quantity
		uint quantity;
        // The original quantity 
        // (because quantity is decreasing, whether the delivery becomes 0 or not)
        uint originQuantity;
        // Delivery time
        uint delivery_time;
        // Status
        OfferStatus status;
	}

    // Offer Status Enumeration
    enum OfferStatus {
        // 未成交
        Unsold,
        // 已成交，待交割
        DealDone,
        // 已交割
        Delivered,
        // 已撤销
        Revoked
    }
    //-------------------------------------------------Structs + Enumerations---------------------------------------------------

    //-------------------------------------------------Status variables------------------------------------------------------
	// Contract owner
	address public owner;

	// Service fee
	uint public serviceFee;

	// User ETH mapping
	mapping(address => uint) public balances;

    // User asset mapping, user address => (asset address => total assets)
    mapping(address => mapping(address => uint)) public assetBalance;

    // Asset ID => Asset mapping
    mapping(uint => Asset) public assets;

    // The next asset ID
    uint public assetId;

    // Asset address => Asset name mapping
    mapping(address => string) public assetName;

    // user => trade record mapping
	mapping(address => Trade[]) public tradeRecord;

    // OfferID => trade record mapping
    mapping(uint => Trade[]) public trades;

	// Published offers
	mapping(uint => Offer) public offers;

    // Next offer ID
    uint public offerId;

    // Pending delivery queue
    uint[] public deliveryQueue;
    //-------------------------------------------------Status variables-----------------------------------------------------

    //-------------------------------------------------Modifiers-------------------------------------------------------
    // Only contract owner can call
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    //-------------------------------------------------Modifiers-------------------------------------------------------

    //-------------------------------------------------Constructors-----------------------------------------------------
	// Constructors
	constructor(uint _serviceFee, string[] memory _assetName, address[] memory _assetAddress) {
        // Setting up the contract owner
		owner = msg.sender;

        // Set service charge percentage
		serviceFee = _serviceFee;

        // Setting up initial assets
        // Require an array of names and an array of addresses to be passed in, corresponding in length to each other
        require(_assetName.length == _assetAddress.length, "Asset name and address must correspond");

        // Store in order
        for (uint i = 0; i < _assetName.length; i++) {
            // Defining local variables
            string memory _name = _assetName[i];
            address _address = _assetAddress[i];

            // Store in mapping
            assetName[_address] = _name;
            assets[assetId] = Asset(_name, _address);
            
            // Asset ID increase
            assetId++;
        }
	}
    //-------------------------------------------------Constructors----------------------------------------------------

    //-------------------------------------------------Event----------------------------------------------------
    // Deposit
    event eventDeposit(address _address, address user, uint amount);
    event eventWithdraw(address _address, address user, uint amount);
    // Add edit the asset
    event evnetAddAsset(string _name, address _address);
    event eventEditAsset(uint _assetId, string _name, address _address);
    // Seller push the offer
    event eventPushOffer(uint id, address user, address asset, uint price, uint quantity, uint delivery_time);
    // Seller cancel the offer
    event eventCancelOffer(uint id);
    // Buyer accept the offer
	event eventSubmitOffer(uint id, address user, address asset, uint quantity);
    // Futures delivery events
    event eventDelivery(bool result);
    //-------------------------------------------------Event---------------------------------------------------

    //-------------------------------------------------Asset Operations---------------------------------------------------
    // Add the asset(only for the owner)
    function addAsset(string memory _name, address _address) external onlyOwner {
        // Requires that the asset name is not empty
        // In Solidity, string comparisons need to be performed using library functions or string operations.
        // Direct use of the == operator for string comparisons will result in compilation errors
        require(keccak256(bytes(_name)) != keccak256(bytes("")), "Asset name cannot be empty");
        // Requires assets not to have been entered before
        require(keccak256(bytes(assetName[_address])) == keccak256(bytes("")), "asset already exists");

        // Store the new asset
        assetName[_address] = _name;
        assets[assetId] = Asset(_name, _address);

        // Triggering the Add Asset event
        emit evnetAddAsset(_name, _address);

        // Asset ID increment
        assetId++;
    }

    // Edit the asset(only the owner)
    function editAsset(uint _assetId, string memory _name, address _address) external onlyOwner {
        // Assets must exist
        require(assets[_assetId]._address != address(0), "asset does not exist");
        // Name cannot be empty
        require(keccak256(bytes(_name)) != keccak256(bytes("")), "Asset name cannot be empty");
        // Asset address cannot be a contracted address or zero address
        require(_address != address(this) && _address != address(0), "asset does not exist");

        // Edit the asset
        assetName[_address] = _name;
        assets[_assetId] = Asset(_name, _address);

        // Triggering a Modify Asset event
        emit eventEditAsset(_assetId, _name, _address);
    }
    //-------------------------------------------------Asset Operations---------------------------------------------------

    //-------------------------------------------------Trading Operations---------------------------------------------------
	// For sellers publish the offer
	function pushOffer(
        // Asset address
		address asset,
        // Offer price
		uint price,
        // Total quantity
		uint quantity,
        // Delivery time
        uint delivery_time
	) external {
        // Assets must exist
        require(keccak256(bytes(assetName[asset])) != keccak256(bytes("")), "asset must exist");
        // Price and quantity must be greater than 0
        require(price > 0 && quantity > 0, "Price and quantity must be greater than 0");
        // The delivery time must be greater than the current time
        require(delivery_time > block.timestamp, "The delivery time must be greater than the current time");
        // Seller must have sufficient assets
        require(assetBalance[msg.sender][asset] >= quantity, "Insufficient margin");
        
        // Freezing of sellers' assets
        assetBalance[msg.sender][asset] -= quantity;

        // Add to offer list
		offers[offerId] = Offer(
            offerId,
            // Seller
            msg.sender,
            // Asset
            asset,
            // Price
            price,
            // quantity
            quantity,
            quantity,
            // Delivery time
            delivery_time,
            // Unsold status
            OfferStatus.Unsold
        );

        // Trigger push offer event
        emit eventPushOffer(offerId, msg.sender, asset, price, quantity, delivery_time);

        // Offer ID self-increasing
        offerId++;

        // Trigger delivery of futures
        delivery();
	}

    // Sellers cancel the offer
    // Parameters: offerID
    function cancelOffer(uint _offerId) external {
        // Find the offer ID
        Offer storage offer = offers[_offerId];

        // Request for quotation exist
        require(offer.seller != address(0), "Quote does not exist");
        // Request to withdraw your own quotation only
        require(offer.seller == msg.sender, "You can only cancel your own quotation");
        // Request for quotation must be unexecuted
        require(offer.status == OfferStatus.Unsold, "The request for quotation must be unexecuted");

        // Return of all or part of the seller's deposit
        assetBalance[msg.sender][offer.asset] += offer.quantity;
        // Change the status of the quotation to revoked
        offer.status = OfferStatus.Revoked;

        // Trigger the cancel offer event
        emit eventCancelOffer(_offerId);

        // Trigger delivery of futures
        delivery();
    }

	// Buyers placing orders
    // Parameters: Offer ID, quantity
	function submitOffer(uint _offerId, uint quantity) external {
        // Find the offer
		Offer storage offer = offers[_offerId];

        // Quote must exist
        require(offer.seller != address(0), "Quote does not exist");
        // Order quantity must be greater than 0
        require(quantity > 0, "Order quantity must be greater than 0");
        // Requires that the quantity of orders placed does not exceed the quantity of the quotation
		require(quantity <= offer.quantity, "Insufficient quantity");

        // total cost
		uint totalCost = offer.price * offer.quantity;
        // Require sufficient buyer ETH book balance
		require(balances[msg.sender] >= totalCost, "Insufficient balance");
        // Less buyer ETH
		balances[msg.sender] -= totalCost;

        // Create transaction record
		Trade memory newTrade = Trade(
            // Offer ID
            _offerId,
            // Buyer
			msg.sender,
            // Quantity of Buyer Transactions
			quantity,
            // Trade time
			block.timestamp
		);

        // Store the trade
		tradeRecord[msg.sender].push(newTrade);
		tradeRecord[offer.seller].push(newTrade);
        trades[_offerId].push(newTrade);

		// Trigger transaction events
		emit eventSubmitOffer(_offerId, msg.sender, offer.asset, quantity);

        // Refresh the quantity balance of quotation
		offer.quantity -= quantity;

        // Trigger delivery of futures
        delivery();
	}

    // Futures Settlement
    // Sellers publish the offer, sellers withdrawing offer, buyers placing orders, all triggering delivery, and also external timed task calls
    function delivery() public {
        // Check the offers
        for (uint i = 0; i < offerId; i++) {
            Offer storage offer = offers[i];

            // If it is undelivery and the offer is sold out, mark it as completed and press it into the queue
            if (offer.status == OfferStatus.Unsold && offer.quantity == 0) {
                // Change the status of the offer
                offer.status = OfferStatus.DealDone;

                // Put offer ID into the queue for delivery
                deliveryQueue.push(i);
            }

            // If the offer can be deliveried
            if (block.timestamp >= offer.delivery_time) {
                // If remain the unsold offer, withdraw the cost to the seller
                if (offer.quantity > 0) {
                    assetBalance[offer.seller][offer.asset] += offer.quantity;
                }

                // Status changed
                offer.status = OfferStatus.DealDone;

                bool exists;
                // Check queue for existing offer IDs
                for (uint x = 0; x < deliveryQueue.length; x++) {
                    if (deliveryQueue[x] == i) {
                        exists = true;
                    }
                }

                // If not, press the offer ID into the delivery queue
                if (exists == false) {
                    deliveryQueue.push(i);
                }
            }
        }

        // delivery in order
        for (uint i = 0; i < deliveryQueue.length; i++) {
            // Obtain quotation information
            Offer storage offer = offers[deliveryQueue[i]];

            // The offer must be in a completed status and the delivery time has been met
            if (offer.status == OfferStatus.DealDone && block.timestamp >= offer.delivery_time) {
                // Calculate total cost
                uint totalCost = offer.price * offer.originQuantity;

                // Caculate the service feex%
                uint fee = (totalCost * serviceFee) / 100;

                // Pay the service fee to the contract owner
                balances[owner] += fee;

                // The seller gets ETH (total transaction amount - service fee), 
                // i.e. the service fee is paid by the seller because he gets less and needs to add 18 digits of precision
                balances[offer.seller] += (totalCost - fee) * 1e18;

                // Find out who the buyers are
                Trade[] memory orders = trades[deliveryQueue[i]];

                // Delivery in order
                if (orders.length > 0) {
                    for (uint j = 0; j < orders.length; j++) {
                        // Buyer takes delivery of assets
                        assetBalance[orders[j].buyer][offer.asset] += orders[j].quantity;
                    }
                }

                // Change the status
                offer.status = OfferStatus.Delivered;

                // Remove the queue after delivery
                deliveryQueue[i] = deliveryQueue[deliveryQueue.length-1];
                deliveryQueue.pop();
            }
        }

        // Trigger the delivery event
        emit eventDelivery(true);
    }
    //-------------------------------------------------Trading Operations---------------------------------------------------

    //-------------------------------------------------ETH Deposit & Withdrawal--------------------------------------------------
	// ETH Deposit
	function deposit() external payable {
        // Amount must be greater than 0
        require(msg.value > 0, "Amount must be greater than 0");

        // Record to ETH ledger
		balances[msg.sender] += msg.value;

        // Trigger the deposit event
        emit eventDeposit(address(this), msg.sender, msg.value);

        // Trigger the delivery
        delivery();
	}

	// ETH Withdrawal
    // Use nonReentrant to prevent re entry attacks
	function withdraw(uint amount) external nonReentrant {
        // Amount must be greater than 0
        require(amount > 0, "Amount must be greater than 0");
        // Require sufficient user ETH book balance
		require(balances[msg.sender] >= amount, "Insufficient balance");

        // Deduct the withdrawal amount
		balances[msg.sender] -= amount;

        // Transfer to the caller
		payable(msg.sender).transfer(amount);

        // Trigger a withdrawal event
        emit eventWithdraw(address(this), msg.sender, amount);

        // Trigger the delivery
        delivery();
	}
    //-------------------------------------------------ETH Deposit & Withdrawal--------------------------------------------------

    //-------------------------------------------------Asset Deposit & Withdrawal-------------------------------------------------
    // Asset Deposit
    // Parameters: Deposit amount, asset address
    // This operation requires call to approve in the asset contract to authorise this contract, 
    // indicating that the contract is debiting the token
	function depositToken(uint amount, address asset) external {
        // Amount must be greater than 0
        require(amount > 0, "Amount must be greater than 0");
        // asset must exist
        require(keccak256(bytes(assetName[asset])) != keccak256(bytes("")), "asset must exist");

        // Instantiated assets
        IERC20 token = IERC20(asset);
        // Requirement that the caller has a sufficient amount of authorization for the contract
        require(token.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
        // Request for deduction of user assets must be successful
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Increase in user asset book
		assetBalance[msg.sender][asset] += amount;

        // Trigger the deposit event
        emit eventDeposit(asset, msg.sender, amount);

        // Trigger the delivery
        delivery();
	}
    
	// Asset Withdrawal
    // Parameters: Withdrawal amount, asset address
    // Use non-Reentrant to prevent re-entry attacks
	function withdrawToken(uint amount, address asset) external nonReentrant {
        // Amount must be greater than 0
        require(amount > 0, "Amount must be greater than 0");
        // asset must exist
        require(keccak256(bytes(assetName[asset])) != keccak256(bytes("")), "asset must exist");
        // Requires sufficient balance in the caller's asset book
		require(balances[msg.sender] >= amount, "Insufficient balance");

        // Instantiated assets
        IERC20 token = IERC20(asset);
        // Requirement that the contract actually holds sufficient assets
        require(token.balanceOf(msg.sender) >= amount, "Insufficient contract assets");

        // Decrease in user asset book
		assetBalance[msg.sender][asset] -= amount;
        // Requirement that the contract must successfully transfer the asset to the caller
        require(token.transfer(msg.sender, amount), "Transfer failed");

        // Trigger the withdraw event
        emit eventWithdraw(asset, msg.sender, amount);

        // Trigger the delivery
        delivery();
	}
    //-------------------------------------------------Asset Deposit & Withdrawal-------------------------------------------------

    //-------------------------------------------------Information Request---------------------------------------------------
    // Get a list of assets
    // Provided for front-end asset drop-down menus
    function getAssetList() external view returns(Asset[] memory) {
        // Creating arrays
        Asset[] memory assetlist = new Asset[](assetId);

        // Press in the data in sequence
        for (uint i = 0; i < assetId; i++) {
            assetlist[i] = assets[i];
        }

        // return the data
        return assetlist;
    }

    // Get a list of tradable offers
    function getOfferList() external view returns(Offer[] memory) {
        uint count = 0;
        for (uint i = 0; i < offerId; i++) {
            // The transaction status is correct, there is still spare capacity, the seller is not himself
            if (offers[i].status == OfferStatus.Unsold && offers[i].quantity > 0 && offers[i].seller != msg.sender) {
                count++;
            }
        }

        // Creating arrays
        Offer[] memory offerList = new Offer[](count);
        uint index = 0;

        for (uint i = 0; i < offerId; i++) {
            // The transaction status is correct, there is still spare capacity, the seller is not himself
            if (offers[i].status == OfferStatus.Unsold && offers[i].quantity > 0 && offers[i].seller != msg.sender) {
                offerList[index] = offers[i];
                index++;
            }
        }

        return offerList;
    }

    // Get my pending delivery orders
    // A sell order I post or a buy order I purchase counts
    function getWaitDeliveryList() external view returns(Trade[] memory){
        // Check My Orders
        Trade[] memory orders = tradeRecord[msg.sender];

        uint count = 0;
        for (uint i = 0; i < orders.length; i++) {
            Trade memory order = orders[i];
            Offer memory offer = offers[order._offerId];
            if (offer.status == OfferStatus.DealDone) {
                count++;
            }
        }

        // Creating arrays
        Trade[] memory tradeList = new Trade[](count);
        uint index = 0;

        for (uint i = 0; i < orders.length; i++) {
            Trade memory order = orders[i];
            Offer memory offer = offers[order._offerId];
            if (offer.status == OfferStatus.DealDone) {
                tradeList[index] = orders[i];
                index++;
            }
        }

        return tradeList;
    }

    // Get all my published quotes
    function getpublishedQuotesList() external view returns(Offer[] memory) {
        uint count = 0;
        for (uint i = 0; i < offerId; i++) {
            if (offers[i].seller == msg.sender) {
                count++;
            }
        }

        // Create array
        Offer[] memory offerList = new Offer[](count);
        uint index = 0;

        for (uint i = 0; i < offerId; i++) {
            // The seller is himself
            if (offers[i].seller == msg.sender) {
                offerList[index] = offers[i];
                index++;
            }
        }

        return offerList;
    }
    //-------------------------------------------------Information Request---------------------------------------------------
}