//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Stakable.sol";
import "./Tradable.sol";

contract PiggyBank is Ownable, Stakable, Tradable {
    uint256 private _totalSupply;
    uint256 private _currentTokenPrice;
    uint8 private _decimals;
    string private _symbol;
    string private _name;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _etherBalances;
    mapping (address => bool) private _locked;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier noReentrant() {
        require(!_locked[msg.sender], "Token: no reentrancy");
        _locked[msg.sender] = true;
        _;
        _locked[msg.sender] = false;
    }

    constructor(uint256 tokenTotalSupply, string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) {
        _totalSupply = tokenTotalSupply;
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;

        _balances[msg.sender] = _totalSupply;
        
        _currentTokenPrice = 10 ** 16;
        _placeOrder(_totalSupply, _currentTokenPrice);

        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Token: cannot transfer from zero address");
        require(recipient != address(0), "Token: cannot transfer to zero address");
        require(_balances[sender] >= amount, "Token: cannot transfer more than account owns");

        _balances[recipient] = _balances[recipient] + amount;
        _balances[sender] = _balances[sender] - amount;
        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Token: zero address cannot approve");
        require(spender != address(0), "Token: cannot approve zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address spender, address recipient, uint256 amount) external returns(bool) {
        require(_allowances[spender][msg.sender] >= amount, "Token: You cannot spend that much on this account");
        _transfer(spender, recipient, amount);
        _approve(spender, msg.sender, _allowances[spender][msg.sender] - amount);
        return true;
    }
    
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Token: cannot mint to zero address");
        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Token: cannot burn from zero address");
        require(_balances[account] >= amount, "Token: cannot burn more than account owns");
        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }

    function burn(address account, uint256 amount) public onlyOwner returns (bool) {
        _burn(account, amount);
        return true;
    }

    function mint(address account, uint256 amount) public onlyOwner returns (bool) {
        _mint(account, amount);
        return true;
    }

    function stake(uint256 amount) public {
        require(amount <= _balances[msg.sender], "Token: cannot stake more than you own");
        _stake(amount);
        _burn(msg.sender, amount);
    }

    function claimReward() public {
        uint256 reward = _claimReward();
        _mint(msg.sender, reward);
    }

    function unstake(uint256 amount) public {
        uint256 stakes = _unstake(amount);
        _mint(msg.sender, stakes);
    }

    function placeOrder(uint256 amount, uint256 price) public {
        require(amount <= _balances[msg.sender], "Token: cannot place an order with more than you own");
        _burn(msg.sender, amount);
        _placeOrder(amount, price);
    }

    function removeOrder(uint256 orderId) public {
        _removeOrder(orderId);
        SellOrder memory order = _getOrder(orderId);
        _mint(msg.sender, order.amount);
    }

    function buyOrder(uint256 orderId, uint256 amount) public payable noReentrant {
        SellOrder memory order = _getOrder((orderId));
        uint256 orderPrice = order.price * amount;
        require(msg.value >= orderPrice, "Token: ether sent must be greater or equal orderPrice.");        
        address owner = owner();
        uint256 ownerFee = msg.value / 100;
        uint256 sellerPayment = msg.value - ownerFee;
        _etherBalances[order.seller] += sellerPayment;
        _etherBalances[owner] += ownerFee;
        _buyOrder(orderId, amount);
        _currentTokenPrice = order.price;
        _mint(msg.sender, amount);
    }

    function withdraw() public payable noReentrant {
        require(_etherBalances[msg.sender] > 0, "Token: no ether left to withdraw.");
        uint256 amount = _etherBalances[msg.sender];
        _etherBalances[msg.sender] = 0;
        (bool success, ) = (msg.sender).call{ value: amount }("");
        require(success, "Token: withdraw failed.");
    }

    function updateOrderPrice(uint256 orderId, uint256 newPrice) public {
        _updateOrderPrice(orderId, newPrice);
    }

    function getEtherBalance() public view returns (uint256) {
        return _etherBalances[msg.sender];
    }

    function getOrder(uint256 orderId) public view returns (SellOrder memory) {
        return _getOrder(orderId);
    }

    function listOrders() public view returns (SellOrder[] memory) {
        return _listOrders();
    }

    function getCurrentTokenPrice() public view returns (uint256) {
        return _currentTokenPrice;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Stakable {
    constructor() {
        stakeholders.push();
    }

    uint256 dailyPercentageYield = 27000; // 0.027% = 1 / 27000

    struct Stake {
        address holder;
        uint256 amount;
        uint256 stakedAt;
    }

    struct Stakeholder {
        address holder;
        Stake[] stakes;
    }

    Stakeholder[] internal stakeholders;
    mapping(address => uint256) internal stakeholderIds;    

    event Staked(address indexed holder, uint256 amount, uint256 stakeholderId, uint256 stakedAt);

    function _addStakeholder(address holder) internal returns (uint256) {
        stakeholders.push();
        uint256 id = stakeholders.length - 1;
        stakeholders[id].holder = holder; 
        stakeholderIds[holder] = id;
        return id;
    }

    function _stake(uint256 amount) internal {
        require(amount > 0, "Stakable: you can only stake a positive non null amount");
        uint256 stakeholderId = stakeholderIds[msg.sender];
        uint256 stakedAt = block.timestamp;
        
        if (stakeholderId == 0) {
            stakeholderId = _addStakeholder(msg.sender);
        }

        stakeholders[stakeholderId].stakes.push(Stake(msg.sender, amount, stakedAt));
        emit Staked(msg.sender, amount, stakeholderId, stakedAt);
    }

    function _calculateReward(Stake memory stake) internal view returns (uint256) {
        return ((((block.timestamp - stake.stakedAt) / 1 days) * stake.amount) / dailyPercentageYield);
    }

    function _retrieveReward(uint256 stakeholderId, uint256 stakesCount) internal view returns (uint256, uint256) {
        uint256 totalReward = 0;
        uint256 totalStaked = 0;

        for (uint256 stakeId = 0; stakeId < stakesCount; stakeId++) {
            Stake memory stake = stakeholders[stakeholderId].stakes[stakeId];
            uint256 reward = _calculateReward(stake);
            totalStaked = totalStaked + stake.amount;
            totalReward = totalReward + reward;
        }

        return (totalReward, totalStaked);
    }

    function _emptyHolderStakes(uint256 stakeholderId, uint256 stakesCount) internal {
        for (uint256 stakeId = 0; stakeId < stakesCount; stakeId++) {
            delete stakeholders[stakeholderId].stakes[stakeId];
        }
    }

    function _claimReward() internal returns (uint256) {
        require(stakeholderIds[msg.sender] != 0, "Stakable: address has nothing staked");
        uint256 stakeholderId = stakeholderIds[msg.sender];
        uint256 stakesCount = stakeholders[stakeholderId].stakes.length;
        uint256 totalReward;
        uint256 totalStaked;
        
        (totalReward, totalStaked) = _retrieveReward(stakeholderId, stakesCount);
        _emptyHolderStakes(stakeholderId, stakesCount);
        stakeholders[stakeholderId].stakes.push(Stake(msg.sender, totalStaked, block.timestamp));

        return totalReward;
    }

    function _unstake(uint256 amount) internal returns (uint256) {
        require(stakeholderIds[msg.sender] != 0, "Stakable: address has nothing staked");
        uint256 stakeholderId = stakeholderIds[msg.sender];
        uint256 stakesCount = stakeholders[stakeholderId].stakes.length;
        uint256 totalReward;
        uint256 totalStaked;
        uint256 totalUnstaked;
        
        (totalReward, totalStaked) = _retrieveReward(stakeholderId, stakesCount);

        if (amount > totalStaked) {
            _emptyHolderStakes(stakeholderId, stakesCount);
            stakeholders[stakeholderId].stakes.push(Stake(msg.sender, 0, block.timestamp));
            totalUnstaked = totalReward + totalStaked;
        } else {
            uint256 remainingStake = totalStaked - amount;
            _emptyHolderStakes(stakeholderId, stakesCount);
            stakeholders[stakeholderId].stakes.push(Stake(msg.sender, remainingStake, block.timestamp));            
            totalUnstaked = totalReward + amount;
        }

        return totalUnstaked;
    }

    function stakeReport() external view returns (uint256, uint256) {
        require(stakeholderIds[msg.sender] != 0, "Stakable: address has nothing staked");
        uint256 stakeholderId = stakeholderIds[msg.sender];
        uint256 stakesCount = stakeholders[stakeholderId].stakes.length;
        uint256 totalReward;
        uint256 totalStaked;
        
        (totalReward, totalStaked) = _retrieveReward(stakeholderId, stakesCount);

        return (totalReward, totalStaked);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Tradable {

    struct SellOrder {
        uint256 id;
        address seller;
        uint256 amount;
        uint256 price;
        bool active;
    }

    SellOrder[] internal orders;

    event OrderPlaced(uint256 indexed id, address indexed seller, uint256 amount, uint256 price);
    event Selled(uint256 indexed id, address indexed seller, address indexed buyer, uint256 amount, uint256 price);
    event UpdatedOrderPrice(uint256 indexed id, uint256 newPrice);
    event UpdatedOrderAmount(uint256 indexed id, uint256 newAmount);

    constructor() {}

    function _placeOrder(uint256 amount, uint256 price) internal {
        require(amount > 0, "Tradable: you can only place a sell order of a positive non null amount");
        require(price > 0, "Trabable: you order token price must be postive and not null");
        
        uint256 orderId = orders.length;

        orders.push(SellOrder(orderId, msg.sender, amount, price, true));
        emit OrderPlaced(orderId, msg.sender, amount, price);
    }

    function _removeOrder(uint256 orderId) internal {
        require(orders[orderId].seller == msg.sender, "Tradable: that order is not yours");
        require(orders[orderId].active == true, "Tradable: order was already removed or buyed");

        orders[orderId].active = false;
    }

    function _updateOrderPrice(uint256 orderId, uint256 newPrice) internal {
        require(orders[orderId].seller == msg.sender, "Tradable: that order is not yours");
        require(orders[orderId].active == true, "Tradable: order was already removed or buyed");
        require(newPrice > 0, "Trabable: you order token price must be postive and not null");

        orders[orderId].price = newPrice;

        emit UpdatedOrderPrice(orderId, newPrice);
    }

    function _buyOrder(uint256 orderId, uint256 amount) internal {
        require(orders[orderId].seller != msg.sender, "Tradable: you cannot buy your own order");
        require(orders[orderId].active == true, "Tradable: order was already removed or buyed");
        require(amount <= orders[orderId].amount, "Tradable: cannot buy amount greater than placed on order.");

        orders[orderId].amount -= amount;

        if (orders[orderId].amount == 0) orders[orderId].active = false;
        else emit UpdatedOrderAmount(orderId, orders[orderId].amount);
        
        emit Selled(orderId, orders[orderId].seller, msg.sender, amount, orders[orderId].price);
    }

    function _getOrder(uint256 orderId) internal view returns (SellOrder memory) {
        return orders[orderId];
    }

    function _listOrders() internal view returns (SellOrder[] memory) {
        return orders;
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