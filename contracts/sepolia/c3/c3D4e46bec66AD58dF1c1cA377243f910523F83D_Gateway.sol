// SPDX-License-Identifier: MIT

/*
    Gateway Contract
*/
/// @title Gateway Contract
/// @author @aurealarcon aurelianoa.eth
/// @notice The contract responsible to manage subscriptions


pragma solidity ^0.8.17;

import { ArrayManager } from "./Helpers/ArrayManager.sol";
import { Authorized } from "@privylabs/authorized/contracts/Authorized.sol";
import { INetwork } from "@aurelianoa/iris-channels/contracts/network/INetwork.sol";

contract Gateway is Authorized, ArrayManager {

    /// struct to store plan's info
    struct Plan {
        uint256 price;
        uint256 qty;
        bool active; 
    }

    struct Network {
        bool status;
        string version;
    }

    struct Channel {
        bool status;
        address[] channels;
    }

    struct Usage {
        uint256 used;
        uint256 total;
    }

    /// mapping of plan id and plan
    mapping(string => Plan) public plans;

    /// mapping of wallet address to Channel
    mapping(address => mapping (address => Channel)) public channels;

    /// mapping of wallet address and usage
    mapping(address => Usage) public usage;

    /// mapping to register networks
    mapping(address => Network) public networks;

    ///Events
    event PlanSet(string indexed planId, uint256 price, uint256 qty);
    event NetworkSet(address indexed network, string version);
    event ChannelSet(address indexed owner, address indexed network, address indexed emitter);
    event WalletSubscribed(address indexed susbcriber, string planId);

    /// Errors
    error PlanDoesNotExist();
    error PlanNotActive();
    error SubscriptionNotActive();
    error SubscriptionExpired();
    error AlreadySubscribedToCurrentActivePlan();
    error NotUsageLeft();
    error NetworkAlreadyRegistered();
    error NetworkNotActive();
    error ChannelAlreadyRegisteredToNetwork(address, address);

    /// modifiers
    modifier planExists(string memory planId) {
        if(!plans[planId].active) revert PlanDoesNotExist();

        _;
    }

    modifier onlyActiveSubscription(address susbcriber) {
        if(checkUsageLeft(susbcriber) <= 0) revert NotUsageLeft();

        _;
    }

    modifier onlySubscribed(address broadcaster, address susbcriber) {
        Channel memory network = channels[msg.sender][broadcaster];
        if(network.channels.length == 0) revert SubscriptionNotActive();
    
        _;
    }

    modifier updateSubscriptionUsage(address susbcriber) {
        _;

        usage[susbcriber].used += 1;
    }

    /// Admin functions

    /// function to create a new plan
    /// @param planId The id of the plan
    /// @param price The price of the plan
    /// @param qty The number of channels of the plan
    function createPlan(string memory planId, uint256 price, uint256 qty) external onlyAuthorizedAdmin {
        plans[planId] = Plan(price, qty, true);

        emit PlanSet(planId, price, qty);
    }

    ///internal function to set plan's info
    /// @param planId The id of the plan
    /// @param plan The plan object
    function setPlan(string memory planId, Plan memory plan) internal {
        plans[planId] = plan;
    }

    /// external function to update a plan's price
    /// @param planId The id of the plan
    /// @param price The new price of the plan
    function updatePlanPrice(string memory planId, uint256 price) external onlyAuthorizedAdmin {
        Plan memory plan = plans[planId];
        /// update the plan object
        plan.price = price;
        setPlan(planId, plan);
    }

    /// external function to update a plan's channels quantity
    /// @param planId The id of the plan
    /// @param qty The new channels quantity of the plan
    function updatePlanChannelsQty(string memory planId, uint256 qty) external onlyAuthorizedAdmin {
        Plan memory plan = plans[planId];
        /// update the plan object
        plan.qty = qty;
        setPlan(planId, plan);
    }

    /// external function to update a plan's status
    /// @param planId The id of the plan
    /// @param active The new status of the plan
    function updatePlanStatus(string memory planId, bool active) external onlyAuthorizedOperator {
        Plan memory plan = plans[planId];
        /// update the plan object
        plan.active = active;
        setPlan(planId, plan);
    }

    /// register a network
    /// @param networkAddress The address of the network
    /// @param status The status of the network
    /// @param version The version of the network
    function registerNetwork(address networkAddress, bool status, string memory version) external onlyAuthorizedAdmin {
        networks[networkAddress] = Network(status, version);

        emit NetworkSet(networkAddress, version);
    }

    /// internal function to susbcribe a wallet

    /// @param planId The id of the plan
    /// @param subscriber The address of the subscriber
   
    function _subscribe(string memory planId, address subscriber) internal  {
        /// get the plan by planId
        Plan memory plan = plans[planId];
        /// increase the usage of the subscriber
        Usage storage _usage = usage[subscriber];

        _usage.total += plan.qty;

        emit WalletSubscribed(subscriber, planId);
    }

    /// function to subscribe a wallet to a plan
    /// @param planId The id of the plan
    function subscribe(string memory planId) external planExists(planId) payable {
        require(plans[planId].price == msg.value, "Gateway: The amount sent is not equal to the plan's price");
        
        _subscribe(planId, msg.sender);
    }

    /// function to subscribe on befahalf of a wallet to a plan
    /// @param planId The id of the plan
    /// @param subscriber The address of the subscriber
    function subscribeOnBehalf(string memory planId, address subscriber) external planExists(planId) onlyAuthorizedOperator {
        _subscribe(planId, subscriber);
    }

    /// TODO: Rework the unsubscribe option

    /// Create a channel on Iris contract
    /// @param broadcaster The address of the broadcaster
    /// @param _channel The address of the channel
    /// @param listeners The addresses of the listeners
    function createChannel(address broadcaster, address _channel, address[] memory listeners) onlyActiveSubscription(msg.sender) updateSubscriptionUsage(msg.sender) external {
        // check if network is active
        if(!getNetworkStatus(broadcaster)) revert NetworkNotActive();

        Channel storage myNetwork = channels[msg.sender][broadcaster];

        bool found = isInArray(myNetwork.channels, _channel);
        if(found) revert ChannelAlreadyRegisteredToNetwork(broadcaster, _channel);
        channels[msg.sender][broadcaster].channels.push(_channel);
        
        INetwork network = INetwork(broadcaster);

        /// create the channel
        network.setChannel(_channel, listeners);

        emit ChannelSet(msg.sender, broadcaster, _channel);
    }

    /// Set the channel status on Iris contract
    /// @param broadcaster The address of the broadcaster
    /// @param _channel the address of the channel
    /// @param active set the channel active or inactive
    function setChannelStatus(address broadcaster, address _channel, bool active) external onlySubscribed(broadcaster, msg.sender) {

        INetwork network = INetwork(broadcaster);

        /// create the channel
        network.setChannelStatus(_channel, active);
    }
    
    /// Set the channel lazy status on Iris contract
    /// @param broadcaster The address of the broadcaster
    /// @param _channel the address of the channel
    /// @param lazy set the channel lazy or not
    function setChannelLazyStatus(address broadcaster, address _channel, bool lazy) external onlySubscribed(broadcaster, msg.sender) {
        
        INetwork network = INetwork(broadcaster);

        /// create the channel
        network.setChannelLazyStatus(_channel, lazy);
    }

    /// set the channel listeners on Iris contract
    /// @param broadcaster The address of the broadcaster
    /// @param _channel the address of the channel
    /// @param listeners the addresses of the listeners
    function setChannelListeners(address broadcaster, address _channel, address[] memory listeners) external onlySubscribed(broadcaster, msg.sender) {
        
        INetwork network = INetwork(broadcaster);

        /// create the channel
        network.addChannelListeners(_channel, listeners);
    }

    /// remove the channel listeners on Iris contract
    /// @param broadcaster The address of the broadcaster
    /// @param _channel the address of the channel
    /// @param listener the addresses of the listeners
    function removeChannelListener(address broadcaster, address _channel, address listener) external onlySubscribed(broadcaster, msg.sender) {
        
        INetwork network = INetwork(broadcaster);

        /// create the channel
        network.removeChannelListener(_channel, listener);
    }

    /// helpers

    /// function to check the usage left of a plan in a susbcription
    /// @param susbcriber the address of the subscriber
    /// @return available channels are left
    function checkUsageLeft(address susbcriber) public view returns (uint256) {
        Usage memory _usage = usage[susbcriber];
      
        /// return the usage left
        return _usage.total - _usage.used;
    }

    /// check network status
    /// @param networkAddress The address of the network
    /// @return bool the network status
    function getNetworkStatus(address networkAddress) public view returns (bool) {
        Network memory network = networks[networkAddress];

        return network.status;
    }

    /// get emmiters from an subscriber
    /// @param broadcaster The address of the broadcaster
    /// @param susbcriber The address of the subscriber
    /// @return address[] the channels
    function getChannels(address broadcaster, address susbcriber) public view returns (address[] memory) {
        Channel memory network = channels[susbcriber][broadcaster];

        return network.channels;
    }

    /// withdraw funds from the contract
    /// @param _to address
    function withdraw(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface INetwork {
    function broadcast(string memory eventIndex, bytes memory data) external;
    function setChannel(address channel, address[] memory listeners) external;
    function setChannelStatus(address channel, bool active) external;
    function setChannelLazyStatus(address channel, bool lazy) external;
    function addChannelListener(address channel, address listener) external;
    function addChannelListeners(address channel, address[] memory listeners) external;
    function removeChannelListener(address channel, address listener) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IAuthorized } from "./interfaces/IAuthorized.sol";

abstract contract Authorized is IAuthorized {
    constructor() {
        /// @notice Add the deployer as an authorized admin
        owner = msg.sender;
    }

    /// @notice the owner of the contract
    address private owner;

    /// @notice A mapping storing authorized admins
    /// @dev admin address => authorized status
    mapping (address => bool) private authorizedAdmins;

    /// @notice A mapping of the authorized delegate operators
    /// @dev operator address => authorized status
    mapping (address => bool) private authorizedOperators;

    /// @notice Modifier to ensure caller is owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    /// @dev Modifier to ensure caller is authorized admin
    modifier onlyAuthorizedAdmin() {
        if (msg.sender != owner && !authorizedAdmins[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }

    /// @dev Modifier to ensure caller is authorized operator
    modifier onlyAuthorizedOperator() {
        if (msg.sender != owner && !authorizedAdmins[msg.sender] && !authorizedOperators[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }

    /// @inheritdoc IAuthorized
    function transferOwnership(address newOwner) external onlyOwner {
        /// check if address is not null
        require(newOwner != address(0), "Authorized System: New owner cannot be null");
        /// check if address is not the same as owner
        require(newOwner != owner, "Authorized System: New owner cannot be the same as old owner");
        /// check if address is not the same as operator
        require(!authorizedOperators[owner], "Authorized System: Owner cannot be an operator");

        /// update the owner
        owner = newOwner;
    }

    /// @inheritdoc IAuthorized
    function setAuthorizedAdmin(address _admin, bool status) public virtual onlyAuthorizedAdmin {
        /// check if address is not null
        require(_admin != address(0), "Authorized System: Admin address cannot be null");
        /// check if address is not the same as operator
        require(!authorizedOperators[_admin], "Authorized System: Admin cannot be an operator");
        
        /// update the admin status
        authorizedAdmins[_admin] = status;
        emit SetAdmin(_admin);
    }

    /// @inheritdoc IAuthorized
    function setAuthorizedOperator(address _operator, bool status) public virtual onlyAuthorizedAdmin {
        /// check if address is not null
        require(_operator != address(0), "Authorized System: Operator address cannot be null");
        /// check if address is not the same as admin
        require(!authorizedAdmins[_operator], "Authorized System: Operator cannot be an admin");
        
        /// update the operator status
        authorizedOperators[_operator] = status;
        emit SetOperator(_operator);
    }

    /// @inheritdoc IAuthorized
    function getAuthorizedAdmin(address _admin) external view virtual returns (bool) {
        return authorizedAdmins[_admin];
    }

    /// @inheritdoc IAuthorized
    function getAuthorizedOperator(address _operator) external view virtual returns (bool) {
        return authorizedOperators[_operator];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IAuthorized {

    /// @notice Generic error when a user attempts to access a feature/function without proper access
    error Unauthorized();

    /// @notice Event emitted when a new admin is added
    event SetAdmin(address indexed admin);

    /// @notice Event emitted when a new operator is added
    event SetOperator(address indexed operator);

    /// @notice Event emmited when a new authOperator is added
    event SetAuthOperator(address indexed authOperator);

    /// @notice Transfer ownership of the contract to a new account (`newOwner`).
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address newOwner) external;

    /// @notice Add an authorized admin
    /// @param _admin address of the admin
    /// @param status status of the admin
    function setAuthorizedAdmin(address _admin, bool status) external;

    /// @notice Add an authorized Operator
    /// @param _operator address of the operator
    /// @param status status of the operator
    function setAuthorizedOperator(address _operator, bool status) external;

    /// @notice Get the status of an admin
    /// @param _admin address of the admin
    /// @return status of the admin
    function getAuthorizedAdmin(address _admin) external view returns (bool);

    /// @notice Get the status of an operator
    /// @param _operator address of the operator
    /// @return status of the operator
    function getAuthorizedOperator(address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract ArrayManager {
    /// Find in array
    /// @param addresses the array of addresses
    /// @param lookUp the address to look up
    /// @return the index of the address in the array
    function findInArray(address[] memory addresses, address lookUp) internal pure returns(uint256) {
        uint256 i = 0;
        
        uint256 found_index = addresses.length; /// @notice set up out of bounds

        while (i < addresses.length) {
            if(addresses[i] == lookUp) {
                found_index = i;
                break;
            }
            unchecked { ++i; }
        }

        return found_index;
    }

    /// Is in Array
    /// @param addresses the array of addresses
    /// @param lookUp the address to look up
    /// @return true if the address is in the array
    function isInArray(address[] memory addresses, address lookUp) internal pure returns (bool) {
        return findInArray(addresses, lookUp) < addresses.length;
    }

    /// Remove from array
    /// @param addresses the array of addresses
    /// @param index the index of the address to be removed
    function removeFromArray(address[] storage addresses, uint256 index) internal {
        if(index > addresses.length) return;

        addresses[index] = addresses[addresses.length - 1];
        addresses.pop();
    }
}