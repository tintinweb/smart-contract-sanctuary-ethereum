// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import './IERC20.sol';

contract TCv2 is IERC20 {

    event Mint(address indexed minter, uint amount);
    event Burn(address indexed burner, uint amount);
    event OriginChanged(address indexed originWallet, address indexed newOrigin);
    event TransferFrom(address indexed owner, address indexed buyer, uint amount);
    event RewardFee(address indexed sender, address indexed origin, uint amount);
    event Reward(address indexed userRewarded, uint amount);

    string public constant name = "Triple Confirmation v2 Token";
    string public constant symbol = "TCv2-5";

    uint8 public constant decimals = 10;
    uint public constant supply = 142000000;
    uint public constant normalizedSupply = supply * 10 ** decimals;

    // can't transfer less than 0.00000001 TC
    uint8 public constant minDecimals = 8;
    uint public constant minIncrement = 10 ** minDecimals;
    uint8 public constant burnPct = 2;
    uint8 public constant rewardPct = 1;
    uint8 public constant whtlstPct = 3;

    // TC Incentives Multisig Wallet by default
    address public originWallet;
    bool public contractIsLocked;
    uint public rewardAmount;
    bool public burnAndRewardEnabled = true;

    struct user {
        address whitelist;
        uint balance;
    }

    uint numberOfUsers;
    mapping(uint => address) userIDs;
    mapping(address => user) users;
    mapping(address => mapping (address => uint)) allowed;

    constructor() {
        originWallet = getSender();
        users[originWallet].balance = normalizedSupply;

        emit Mint(originWallet, normalizedSupply);
        emit Transfer(address(0), originWallet, normalizedSupply);
    }

    function totalSupply() public override pure returns (uint) {
        return normalizedSupply;
    }

    function balanceOf(address toGet) public override view returns (uint) {
        return users[toGet].balance;
    }

    // origin wallet can set whether to collect fees
    function setBurnAndReward(bool newStatus) public {
        _checkAuth();

        burnAndRewardEnabled = newStatus;
    } 

    // prevent transfers
    function setLockStatus(bool newStatus) public {
        _checkAuth();

        contractIsLocked = newStatus;
    }

    // origin wallet can select a new origin
    function changeOrigin(address newOrigin) public {
        _checkAuth();

        emit OriginChanged(originWallet, newOrigin);
        _transfer(originWallet, newOrigin, users[originWallet].balance);

        originWallet = newOrigin;
    }

    // authorized personnel only
    function _checkAuth() private view {
        require(getSender() == originWallet, "Unauthorized");
    }

    function getSender() private view returns (address) {
        return msg.sender;
    }

    function _roundUp(uint amount) private pure returns (uint) {
        return amount + minIncrement - (amount % minIncrement);
    }

    function _roundDown(uint amount) private pure returns (uint) {
        return amount - (amount % minIncrement);
    }

    function _calcBurn(uint amount) private pure returns (uint) {
        return amount * burnPct / 100;
    }

    function _calcReward(uint amount) private pure returns (uint) {
        return amount * rewardPct / 100;
    }

    function _calcWhtlistBurn(uint amount) private pure returns (uint) {
        return amount * whtlstPct / 100;
    }

    // transfer precheck
    function transfer(address receiver, uint amount) public override returns (bool) {
        require(!contractIsLocked, "Contract is currently locked");

        amount = _roundDown(amount);
        require(amount > 0, "Must send at least 0.00000001 TC");
        require(amount <= balanceOf(getSender()), "Insufficient TC");

        amount = _checkAndTakeFees(getSender(), receiver, amount);
        return _transfer(getSender(), receiver, amount);
    }

    function _checkAndTakeFees(address sender, address receiver, uint amount) private returns (uint) {
        if (!exempt(sender, receiver)) {
            amount = _burnAndReward(sender, amount);
        }
        return amount;
    }

    function exempt(address sender, address receiver) private view returns (bool) {
        return sender == originWallet || receiver == originWallet || users[sender].whitelist == receiver;
    }

    // burn [burnPct]% and reward [rewardPct]% of transferred tokens
    function _burnAndReward(address sender, uint amount) private returns (uint) {
        uint amountToBurn = _calcBurn(amount);
        _burn(sender, amountToBurn);

        uint amountToReward = _calcReward(amount);
        rewardAmount += amountToReward;
        emit RewardFee(sender, originWallet, amountToReward);

        uint amountToTransfer = amount - amountToBurn - amountToReward;
        return amountToTransfer;
    }

    // transfer tokens
    function _transfer(address sender, address receiver, uint amount) private returns (bool) {
        users[sender].balance = balanceOf(sender) - amount;
        users[receiver].balance = balanceOf(receiver) + amount;

        emit Transfer(sender, receiver, amount);
        return true;
    }

    // burn precheck
    function burn(uint amount) public {
        require(amount <= balanceOf(getSender()), "Insufficient TC");

        _burn(getSender(), amount);
    }

    // burn tokens
    function _burn(address sender, uint amountToBurn) private {
        users[sender].balance = balanceOf(sender) - amountToBurn;
        users[originWallet].balance = balanceOf(originWallet) + amountToBurn;

        emit Burn(sender, amountToBurn);
        emit Transfer(sender, originWallet, amountToBurn);
    }

    // allows swapping
    function approve(address spender, uint amount) external override returns (bool) {
        return _approve(getSender(), spender, amount);
    }

    function _approve(address owner, address spender, uint amount) private returns (bool) {
        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    function transferFrom(address owner, address buyer, uint amount) external override returns (bool) {
        require(amount <= allowance(owner, getSender()), "Insufficient allowance");

        allowed[owner][getSender()] = allowed[owner][getSender()] - amount;
        emit TransferFrom(owner, buyer, amount);
        return _transfer(owner, buyer, amount);
    }

    function allowance(address owner, address spender) public override view returns (uint) {
        return allowed[owner][spender];
    }

    // add a wallet to your whitelist
    function addWhitelist(address toWhitelist) public {
        require(users[getSender()].whitelist != toWhitelist, "Already whitelisted that address");
        users[getSender()].whitelist = toWhitelist;

        uint amountToBurn = _calcWhtlistBurn(balanceOf(getSender()));
        _burn(getSender(), amountToBurn);
    }

    // send out the rewards
    function rewardUsers() public {
        _checkAuth();
        uint originBalance = users[originWallet].balance;
        require(originBalance > rewardAmount, "Current reward amount is higher than the origin wallet's balance");

        for (uint i = 0; i < numberOfUsers; i++) {
            // it's possible to determine everyone's user number based on order of rewards
            // TODO: implement random access of users?

            if (userIDs[i] == originWallet || isContract(userIDs[i])) {
                continue;
            }

            // round down to prevent abuse
            uint amountToReward = _roundDown(rewardAmount * users[userIDs[i]].balance / (normalizedSupply - originBalance));

            emit Reward(userIDs[i], amountToReward);
            _transfer(originWallet, userIDs[i], amountToReward);
        }
        rewardAmount = 0;
    }

    // imported function
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

}