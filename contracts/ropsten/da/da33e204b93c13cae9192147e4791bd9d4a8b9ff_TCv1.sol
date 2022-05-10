/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract TCv1 {

    // cannot prototype functions in solidity?
    // function currentSupply() external view returns (uint256);
    // function balanceOf(address account) external view returns (uint256);
    // function allowance(address owner, address spender) external view returns (uint256);

    // function transfer(address recipient, uint256 amount) external returns (bool);
    // function approve(address spender, uint256 amount) external returns (bool);
    // function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // necessary for wallet connection
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    // event Burn(address indexed burner, uint256 value);

    string public constant name = "Triple Confirmation v2 Token";
    string public constant symbol = "TCv2";

    uint8 public constant decimals = 18;
    uint256 public constant supply = 142000000;
    uint256 public constant normalizedSupply = supply * 10 ** decimals;

    // can't transfer less than 0.00000001 TC
    uint256 public constant minDecimals = 10;
    uint256 public constant minIncrement = 10 ** minDecimals;
    uint8 public constant burnPct = 1;
    uint8 public constant rewardPct = 1;
    uint8 public constant whtlstPct = 2;

    // TC Incentives Multisig Wallet by default
    address originWallet;
    uint8 originUserID;
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

    function _roundUp(uint256 amount) internal pure returns (uint256) {
        return amount + minIncrement - (amount % minIncrement);
    }

    function _roundDown(uint256 amount) internal pure returns (uint256) {
        return amount - (amount % minIncrement);
    }

    // etherscan/snowtrace function
    function totalSupply() public pure returns (uint256) {
        return normalizedSupply;
    }

    function _calcBurn(uint256 amount) internal pure returns (uint256) {
        return amount * burnPct / 100;
    }

    function _calcReward(uint256 amount) internal pure returns (uint256) {
        return amount * rewardPct / 100;
    }

    // changing properties of the returned user does no affect the database
    function getUser(address toGet) public view returns (user memory) {
        return users[userIDs[toGet]];
    }

    // primarily an etherscan/snowtrace function
    function balanceOf(address user) public view returns (uint256 balance) {
        return getUser(user).balance;
    }

    // etherscan/snowtrace function
    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    // authorized personnel only
    function _checkAuth() internal view {
        require(msg.sender == originWallet, "Unauthorized");
    }

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

        emit Transfer(originWallet, newOrigin, balanceOf(originWallet));

        userIDs[originWallet] = 0;
        originWallet = newOrigin;
    }

    constructor() {
        address zeroAddress = address(0);
        originWallet = msg.sender;

        _addUser(zeroAddress);
        users[userIDs[zeroAddress]].registered = false;

        _addUser(originWallet);
        users[userIDs[originWallet]].balance = normalizedSupply;
        originUserID = 1;

        // pseudo mint event
        emit Transfer(zeroAddress, originWallet, normalizedSupply);
    }

    // check they're not a user, then add to database
    function _addUser(address newUser) internal {
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
    function _burn(address sender, uint256 amountToBurn) internal {
        users[userIDs[sender]].balance = balanceOf(sender) - amountToBurn;
        users[userIDs[originWallet]].balance = balanceOf(originWallet) + amountToBurn;

        emit Transfer(sender, originWallet, amountToBurn);
    }

    // burn precheck
    function burn(uint256 amount) public {
        require(!isLocked, "Contract is currently locked");
        address sender = msg.sender;
        _addUser(sender);

        require(amount > 10 ** (minDecimals - 2), "Must burn at least 0.0000000001 TC");
        require(amount <= balanceOf(sender), "Insufficient TC");
        _burn(sender, amount);
    }

    // transfer tokens
    function _transfer(address sender, address receiver, uint256 amount) internal returns (bool success) {
        users[userIDs[sender]].balance = balanceOf(sender) - amount;
        users[userIDs[receiver]].balance = balanceOf(receiver) + amount;

        emit Transfer(sender, receiver, amount);
        return true;
    }

    // burn [burnPct]% and reward [rewardPct]% of transferred tokens
    function _burnAndReward(address sender, address receiver, uint256 amount) internal returns (bool success) {
        uint256 amountToBurn = _calcBurn(amount);
        uint256 amountToReward = _calcReward(amount);
        rewardAmount += amountToReward;

        _burn(sender, amountToBurn + amountToReward);

        uint256 amountToTransfer = amount - amountToBurn - amountToReward;
        return _transfer(sender, receiver, amountToTransfer);
    }

    // to burn or not to burn
    function _transferPrecheck(address sender, address receiver, uint256 amount) internal returns (bool success) {
        require(!isLocked, "Contract is currently locked");
        _addUser(sender);
        _addUser(receiver);

        amount = _roundDown(amount);
        require(amount > 0, "Must send at least 0.00000001 TC");
        require(amount <= balanceOf(sender), "Insufficient TC");
    
        // don't burn/reward when xferring to/from origin wallet
        if (sender == originWallet || receiver == originWallet || getUser(sender).whitelist == receiver) {
            return _transfer(sender, receiver, amount);
        }
        return _burnAndReward(sender, receiver, amount);
    }

    // etherscan/snowtrace function
    function transfer(address receiver, uint256 amount) public returns (bool success) {
        return _transferPrecheck(msg.sender, receiver, amount);
    }

    // etherscan/snowtrace function
    function approve(address delegate, uint256 amount) public returns (bool) {
        allowed[msg.sender][delegate] = amount;
        emit Approval(msg.sender, delegate, amount);
        return true;
    }

    // etherscan/snowtrace function
    function transferFrom(address owner, address buyer, uint256 amount) public returns (bool success) {
        require(amount <= allowed[owner][msg.sender], "Insufficient allowance");
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - amount;
        return _transferPrecheck(owner, buyer, amount);
    }

    // send out the rewards
    function rewardUsers() public {
        _checkAuth();
        require(rewardAmount > 0, "Current reward amount is 0");
        uint256 originBalance = users[userIDs[originWallet]].balance;

        for (uint256 i = originUserID + 1; i < numberOfUsers; i++) {
            // TODO: implement some restriction on which accounts can receive reward
            uint256 amountToReward = _roundUp(rewardAmount * users[i].balance / (normalizedSupply - originBalance));
            _transfer(originWallet, users[i].userAddress, amountToReward);
        }
        rewardAmount = 0;
    }

    // add a wallet to your whitelist
    function addWhitelist(address toWhitelist) public {
        address sender = msg.sender;
        require(sender != originWallet, "Origin can't set a whitelist");
        _addUser(sender);
        _addUser(toWhitelist);

        users[userIDs[sender]].whitelist = toWhitelist;

        uint256 amountToBurn = _calcBurn(users[userIDs[sender]].balance);
        _burn(sender, amountToBurn);
    }

}