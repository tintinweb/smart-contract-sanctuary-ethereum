// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import './addons.sol';

contract TCv2 is IERC20 {

    event Burn(address indexed burner, uint256 amount);
    event OriginChanged(address indexed originWallet, address indexed newOrigin);
    event TransferFrom(address indexed owner, address indexed buyer, uint256 amount);
    event Reward(address indexed userRewarded, uint256 amount);

    string public constant name = "Triple Confirmation v2 Token";
    string public constant symbol = "TCv2-4";

    uint8 public constant decimals = 10;
    uint256 public constant supply = 142000000;
    uint256 public constant normalizedSupply = supply * 10 ** decimals;

    // can't transfer less than 0.00000001 TC
    uint256 public constant minDecimals = 8;
    uint256 public constant minIncrement = 10 ** minDecimals;
    uint8 public constant burnPct = 1;
    uint8 public constant rewardPct = 1;
    uint8 public constant whtlstPct = 2;

    // TC Incentives Multisig Wallet by default
    address public originWallet;
    uint8 public originUserID;
    bool public isLocked;
    uint256 public rewardAmount;

    struct user {
        address userAddress;
        address whitelist;
        uint256 balance;
        bool registered;
    }

    uint256 numberOfUsers;
    mapping(address => uint256) userIDs;
    mapping(uint256 => user) users;
    mapping(address => mapping (address => uint256)) allowed;

    IUniswapV2Router02 public immutable uniswapV2Router;
    // Create a uniswap pair for this new token
    address public immutable uniswapV2Pair;

    constructor() {
        originWallet = getSender();
        originUserID = 1;

        _addUser(address(0));
        users[userIDs[address(0)]].registered = false;

        _addUser(originWallet);
        users[userIDs[originWallet]].balance = normalizedSupply;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        // pseudo mint event
        emit Transfer(address(0), originWallet, normalizedSupply);
    }

    // etherscan/snowtrace function
    function totalSupply() public override pure returns (uint256) {
        return normalizedSupply;
    }

    // primarily an etherscan/snowtrace function
    function balanceOf(address user) public override view returns (uint256) {
        return getUser(user).balance;
    }

    // etherscan/snowtrace function
    function allowance(address owner, address spender) public override view returns (uint) {
        return allowed[owner][spender];
    }

    // etherscan/snowtrace function
    function transfer(address receiver, uint256 amount) public override returns (bool) {
        _addUser(getSender());
        _addUser(receiver);

        return _transferPrecheck(getSender(), receiver, amount);
    }

    // etherscan/snowtrace function
    function approve(address spender, uint256 amount) external override returns (bool) {
        return _approve(getSender(), spender, amount);
    }

    function increaseAllowance(address spender, uint256 amount) public returns (bool) {
        return _approve(getSender(), spender, allowed[getSender()][spender] + amount);
    }

    function decreaseAllowance(address spender, uint256 amount) public returns (bool) {
        return _approve(getSender(), spender, allowed[getSender()][spender] - amount);
    }

    function _roundUp(uint256 amount) private pure returns (uint256) {
        return amount + minIncrement - (amount % minIncrement);
    }

    function _roundDown(uint256 amount) private pure returns (uint256) {
        return amount - (amount % minIncrement);
    }

    function _calcBurn(uint256 amount) private pure returns (uint256) {
        return amount * burnPct / 100;
    }

    function _calcReward(uint256 amount) private pure returns (uint256) {
        return amount * rewardPct / 100;
    }

    // changing properties of the returned user does not affect the database
    function getUser(address toGet) public view returns (user memory) {
        return users[userIDs[toGet]];
    }

    // authorized personnel only
    function _checkAuth() private view {
        require(getSender() == originWallet, "Unauthorized");
    }

    function getSender() private view returns (address) {
        return msg.sender;
    }

    // so we can get ETH
    receive() external payable {}

    // lock or unlock the contract
    function changeLockStatus(bool status) public {
        _checkAuth();

        isLocked = status;
    }

    // origin wallet can select a new origin
    function changeOrigin(address newOrigin) public {
        _checkAuth();
        
        users[originUserID].userAddress = newOrigin;
        userIDs[newOrigin] = originUserID;

        emit OriginChanged(originWallet, newOrigin);
        emit Transfer(originWallet, newOrigin, balanceOf(originWallet));

        userIDs[originWallet] = 0;
        originWallet = newOrigin;
    }

    // check they're not a user, then add to database
    function _addUser(address newUser) private {
        if (getUser(newUser).registered) {
            return;
        }
        users[numberOfUsers].userAddress = newUser;
        users[numberOfUsers].registered = true;
        userIDs[newUser] = numberOfUsers;
        numberOfUsers++;
    }

    // gets the whole user database
    function getUsers() public view returns (user[] memory) {
        _checkAuth();

        user[] memory ret = new user[](numberOfUsers);
        for (uint256 i = 0; i < numberOfUsers; i++) {
            ret[i] = users[i];
        }
        return ret;
    }

    // burns tokens
    function _burn(address sender, uint256 amountToBurn) private {
        users[userIDs[sender]].balance = balanceOf(sender) - amountToBurn;
        users[userIDs[originWallet]].balance = balanceOf(originWallet) + amountToBurn;

        emit Burn(sender, amountToBurn);
        emit Transfer(sender, originWallet, amountToBurn);
    }

    // burn precheck
    function burn(uint256 amount) public {
        require(!isLocked, "Contract is currently locked");
        require(getSender() != originWallet, "Origin wallet can't burn");
        _addUser(getSender());

        require(amount > 10 ** (minDecimals - 2), "Must burn at least 0.0000000001 TC");
        require(amount <= balanceOf(getSender()), "Insufficient TC");
        _burn(getSender(), amount);
    }

    // transfer tokens
    function _transfer(address sender, address receiver, uint256 amount) private returns (bool) {
        users[userIDs[sender]].balance = balanceOf(sender) - amount;
        users[userIDs[receiver]].balance = balanceOf(receiver) + amount;

        emit Transfer(sender, receiver, amount);
        return true;
    }

    // burn [burnPct]% and reward [rewardPct]% of transferred tokens
    function _burnAndReward(address sender, address receiver, uint256 amount) private returns (bool) {
        uint256 amountToBurn = _calcBurn(amount);
        uint256 amountToReward = _calcReward(amount);
        rewardAmount += amountToReward;

        _burn(sender, amountToBurn + amountToReward);

        uint256 amountToTransfer = amount - amountToBurn - amountToReward;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), amountToTransfer);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToTransfer,
            0,
            path,
            address(this),
            block.timestamp
        );

        return _transfer(sender, receiver, amountToTransfer);
    }

    // to burn or not to burn
    function _transferPrecheck(address sender, address receiver, uint256 amount) private returns (bool) {
        require(!isLocked, "Contract is currently locked");

        amount = _roundDown(amount);
        require(amount > 0, "Must send at least 0.00000001 TC");
        require(amount <= balanceOf(sender), "Insufficient TC");
    
        // don't burn and reward
        if (
            sender == originWallet
            || receiver == originWallet
            || receiver == getUser(sender).whitelist
            || sender == uniswapV2Pair
            || sender == address(uniswapV2Router)
            || sender == address(this)
            || true // testing purposes
        ) {
            return _transfer(sender, receiver, amount);
        }
        return _burnAndReward(sender, receiver, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private returns (bool) {
        require(!isLocked, "Contract is currently locked");
        _addUser(owner);
        _addUser(spender);

        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    // etherscan/snowtrace function
    function transferFrom(address owner, address buyer, uint256 amount) external override returns (bool) {
        _addUser(owner);
        _addUser(buyer);

        require(amount <= allowed[owner][getSender()], "Insufficient allowance");

        allowed[owner][getSender()] = allowed[owner][getSender()] - amount;
        emit TransferFrom(owner, buyer, amount);
        return _transfer(owner, buyer, amount);
    }

    // send out the rewards
    function rewardUsers() public {
        _checkAuth();
        require(rewardAmount > 0, "Current reward amount is 0");
        uint256 originBalance = users[userIDs[originWallet]].balance;
        require(originBalance > rewardAmount, "Current reward amount is higher than the origin wallet's balance");

        for (uint256 i = originUserID + 1; i < numberOfUsers; i++) {
            // TODO: implement some restriction on which accounts can receive reward
            // it's possible to determine everyone's user number based on order of rewards
            // TODO: implement random access of users?
            uint256 amountToReward = _roundUp(rewardAmount * users[i].balance / (normalizedSupply - originBalance));

            emit Reward(users[i].userAddress, amountToReward);
            _transfer(originWallet, users[i].userAddress, amountToReward);
        }
        rewardAmount = 0;
    }

    // add a wallet to your whitelist
    function addWhitelist(address toWhitelist) public {
        require(getSender() != originWallet, "Origin wallet can't set a whitelist");
        _addUser(getSender());
        _addUser(toWhitelist);

        users[userIDs[getSender()]].whitelist = toWhitelist;

        uint256 amountToBurn = _calcBurn(balanceOf(getSender()));
        _burn(getSender(), amountToBurn);
    }

}