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

//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Provenance is Ownable {
    enum ActionStatus {
        REMOVED,
        ADDED
    }

    struct Producer {
        string name;
        string phone_number;
        string city;
        string state;
        string country_of_origin;
        bool certification;
        ActionStatus action_status;
    }

    struct Product {
        address producer_address;
        string location;
        uint date_time_of_origin;
        ActionStatus action_status;
    }

    mapping(address => Producer) public producers;
    mapping(uint256 => Product) public products;
    
    function addProducer(address from, string memory name, string memory phone_number, string memory city, string memory state, string memory country_of_origin ) public {
        require(producers[from].action_status != ActionStatus.ADDED, "This producer is already exist.");
        producers[from] = Producer(name, phone_number, city, state, country_of_origin, false, ActionStatus.ADDED);
    }

    function findProducer(address recipient) public view returns (Producer memory) {
        return producers[recipient];
    }

    function removeProducer(address recipient) public onlyOwner{
        producers[recipient].action_status = ActionStatus.REMOVED;
    }

    function certifyProducer(address recipient) public onlyOwner {
        producers[recipient].certification = true;
    }

    function addProduct(uint256 serial_number, string memory location) public {
        require(products[serial_number].action_status != ActionStatus.ADDED, "This product is already exist.");
        products[serial_number] = Product(msg.sender, location, block.timestamp, ActionStatus.ADDED);
    }

    function removeProduct(uint256 serial_number) public onlyOwner {
        products[serial_number].action_status = ActionStatus.REMOVED;
    }
    
    function findProduct(uint256 serial_number) public view returns (Product memory) {
        return products[serial_number];
    }

}

//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Tracking.sol";

contract Reputation is Ownable {
    Tracking trackings = Tracking(0x3eee9c3cA6b066C8DE293D3577B59E592302325A);
    
    enum ActionStatus {
        REMOVED,
        ADDED
    }

    struct Supplier {
        string name;
        string phone_number;
        string city;
        string state;
        string country_of_origin;
        string type_of_goods;
        uint256 reputation;
        ActionStatus action_status;
    }

    mapping(address => Supplier) public suppliers;
    address[] private supplier_list;

    function addSupplier(address from, string memory name, string memory phone_number, string memory city, string memory state, string memory country_of_origin, string memory type_of_goods) public {
        require(suppliers[from].action_status != ActionStatus.ADDED, "This supplier is already exist");
        suppliers[from] = Supplier(name, phone_number, city, state, country_of_origin, type_of_goods, 0, ActionStatus.ADDED);
        supplier_list.push(from);
    }

    function removeSupplier(address recipient) public onlyOwner {
        suppliers[recipient].action_status = ActionStatus.REMOVED;
    }

    function findSupplier(address recipient) public view returns (Supplier memory) {
        return suppliers[recipient];
    }

    function allSuppliers() public view returns (Supplier[] memory){
        Supplier[] memory all_suppliers = new Supplier[](supplier_list.length);
        for(uint256 i = 0; i < supplier_list.length; i++) {
            if (suppliers[supplier_list[i]].action_status == ActionStatus.ADDED) {
                all_suppliers[i] = suppliers[supplier_list[i]];
            }
        }
        return all_suppliers;
    }

    function filterByGoodsType(string memory type_of_goods) public view returns (Supplier[] memory) {
        Supplier[] memory filter_suppliers = new Supplier[](supplier_list.length);
        for(uint256 i = 0; i < supplier_list.length; i++) {
            Supplier memory supplier = suppliers[supplier_list[i]];
            if (supplier.action_status == ActionStatus.ADDED && keccak256(abi.encodePacked(supplier.type_of_goods)) == keccak256(abi.encodePacked(type_of_goods))) {
                filter_suppliers[i] = supplier;
            }
        }
        return filter_suppliers;
    }

    function filterByReputation(uint256 reputation) public view returns (Supplier[] memory) {
        Supplier[] memory filter_suppliers = new Supplier[](supplier_list.length);
        for(uint256 i = 0; i < supplier_list.length; i++) {
            Supplier memory supplier = suppliers[supplier_list[i]];
            if (supplier.action_status == ActionStatus.ADDED && supplier.reputation >= reputation) {
                filter_suppliers[i] = supplier;
            }
        }
        return filter_suppliers;
    }
    
    function checkReputation(address recipient) public view returns (uint256) {
        return trackings.calculateReputation(recipient);
    }
    
    function updateReputations() public onlyOwner {
        for(uint256 i = 0; i < supplier_list.length; i++) {
            if (suppliers[supplier_list[i]].action_status == ActionStatus.ADDED) {
                suppliers[supplier_list[i]].reputation = trackings.calculateReputation(supplier_list[i]);
            }
        }
    }
}

//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Provenance.sol";

contract Tracking is Ownable {

    Provenance provenances = Provenance(0xb6041a315AbD7E4a7d69FcB1c0BF1861CFD7dC0d);

    enum ActionStatus {
        INPROGRESS,
        SUCCESS,
        FAILURE,
        CANCELED
    }

    struct Shipment {
        address sender;
        address recipient;
        uint start_time;
        uint256 item;
        uint256 quantity;
        ActionStatus action_status;
    }

    struct Condition {
        uint lead_time;
        string destination;
        uint256 token_amount;
    }

    event Log(string text);

    mapping(address => uint256) public balances;
    mapping(uint256 => Shipment) public shipments;
    mapping(uint256 => Condition) public conditions;
    mapping(address => uint256) public shipment_list;
    mapping(address => uint256) public success_shipment_list;

    function sendToken(address from, address to, uint256 token_amount) private {
        require(balances[from] >= token_amount, "You do not have enough tokens.");
        balances[from] =  balances[from] - token_amount;
        balances[to] =  balances[to] + token_amount;

        emit Log("Payment sent.");
    }

    function getBalance(address supplier) public view returns (uint256) {
        return balances[supplier];
    }

    function recoverToken(uint shipment_id) public onlyOwner {
        balances[shipments[shipment_id].sender] -= conditions[shipment_id].token_amount;
        balances[shipments[shipment_id].recipient] += conditions[shipment_id].token_amount;
    }

    function setContractParameters(uint256 shipment_id, uint lead_time, string memory destination, uint256 token_amount) public onlyOwner {
        conditions[shipment_id] = Condition(lead_time, destination, token_amount);
    }

    function sendShipment(uint256 shipment_id, uint256 item, address recipient, uint256 quantity) public {
        require(provenances.findProducer(msg.sender).certification, "This producer is not certified.");
        require(provenances.findProduct(item).producer_address != address(0), "This product is not registered.");
        shipments[shipment_id] = Shipment(msg.sender, recipient, block.timestamp, item, quantity, ActionStatus.INPROGRESS);
        shipment_list[msg.sender] ++;
    }

    function receiveShipment(uint256 shipment_id, uint256 item, uint256 quantity) public {
        if(shipments[shipment_id].recipient != msg.sender){
            emit Log("This shipment is not yours.");
            shipments[shipment_id].action_status = ActionStatus.FAILURE;
        } else if((shipments[shipment_id].item != item) || (shipments[shipment_id].quantity != quantity)) {
            emit Log("Item/quantity do not match");
            shipments[shipment_id].action_status = ActionStatus.FAILURE;
        } else {
            emit Log("Item received.");

            if(block.timestamp <= (shipments[shipment_id].start_time + conditions[shipment_id].lead_time)) {
                sendToken(msg.sender, shipments[shipment_id].sender, conditions[shipment_id].token_amount);
                shipments[shipment_id].action_status = ActionStatus.SUCCESS;
                success_shipment_list[shipments[shipment_id].sender] ++;
            } else {
                emit Log("Payment not triggered as criteria not met");
            }
        }
    }

    function deleteShipment(uint256 shipment_id) public onlyOwner {
        shipments[shipment_id].action_status = ActionStatus.CANCELED;
        shipment_list[shipments[shipment_id].sender] --;
    }
    
    function checkShipment(uint256 shipment_id) public view returns (Shipment memory) {
        return shipments[shipment_id];
    }
    
    function checkSuccess(address recipient) public view returns (uint256) {
        return success_shipment_list[recipient];
    }
    
    function calculateReputation(address recipient) public view returns (uint256)  {
        if(shipment_list[recipient] > 0){
            return (uint256) (success_shipment_list[recipient] * 100 / shipment_list[recipient]);
        } else {
            return 0;
        }
    }
}