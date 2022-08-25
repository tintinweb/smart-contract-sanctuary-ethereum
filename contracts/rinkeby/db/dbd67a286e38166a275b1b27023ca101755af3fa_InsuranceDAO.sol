/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint a, uint b) internal pure returns (uint) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }
}

contract ERC20 {

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                     MAPPINGS, VARIABLES AND CONSTRUCTOR                      //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    using SafeMath for uint;

    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;

    uint private _decimals;
    uint private _totalSupply;
    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                               VIEW FUNCTIONS                                 //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint) {
        return _decimals;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                               EDIT FUNCTIONS                                 //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    function transfer(address recipient, uint amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function approve(address spender, uint amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
    }

    function _mint(address account, uint amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
    }

    function _burn(address account, uint amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
    }

    function _approve(address owner, address spender, uint amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
    }

    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual {}

}

contract InsuranceToken is ERC20("InsuranceToken", "INS") {

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                     MAPPINGS, VARIABLES AND CONSTRUCTOR                      //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    mapping (address => bool) public isManager;
    mapping (address => bool) public isBlacklisted;

    address owner;
    address presale;

    constructor() {
        owner = msg.sender;
        presale = msg.sender;
        _mint(owner, 1000 * 1e18);
        _mint(presale, 1000 * 1e18);
    }

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                               VIEW FUNCTIONS                                 //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    function switchManager(address _user) public onlyOwner {
        isManager[_user] = !isManager[_user];
    }

    function switchBlacklist(address _user) public onlyManager {
        isBlacklisted[_user] = !isBlacklisted[_user];
    }

    function _beforeTokenTransfer(address from, address to, uint amount) internal view override {
        require(isBlacklisted[from] == false);
    }

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                                  MODIFIERS                                   //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyManager() {
        require(isManager[msg.sender] == true);
        _;
    }
}



//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////



contract InsuranceDAO is InsuranceToken {

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                     MAPPINGS, VARIABLES AND CONSTRUCTOR                      //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    using SafeMath for uint;

    struct Application {
        uint appFunds;
        uint appSubscriptions;
        uint appPercentage;
        bool isEnsured;
        uint appHackMonth;
    }

    struct Subscription {
        uint subAmount;
        uint subLastMonth;
        uint subNextMonth;
    }

    mapping (uint => Application) apps;
    mapping (address => mapping (uint => Subscription)) subs;

    uint currentMonth = 1;

    constructor() {
        _mint(owner, 1000 * 1e18);
    }
    
    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                             MANAGERS FUNCTIONS                               //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    /*
        This function allows special users to add an application to the list of the supported apps.
    */
    function addApp(uint _app, uint _percentage) public onlyManager {
        apps[_app].appFunds = 0;
        apps[_app].appPercentage = _percentage;
        apps[_app].isEnsured = true;
    }

    /*
        This function allows special users to add funds to an app's insurance.
    */
    function addFunds(uint _app) public payable onlyManager {
        apps[_app].appFunds += msg.value;
    }

    function endMonth() public onlyManager {
        currentMonth = currentMonth.add(1);
    }

    function switchEnsured(uint _app) public onlyManager {
        apps[_app].isEnsured = !apps[_app].isEnsured;
    }

    /*
        This function allows special users to set an app as hacked by the time of the call.
    */
    function setHacked(uint _app) public onlyManager {
        apps[_app].appHackMonth = getCurrentMonth();
        apps[_app].isEnsured = !apps[_app].isEnsured;
    }

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                               VIEW FUNCTIONS                                 //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    function getMaxSubscription(uint _app) public view returns (uint) {
        return apps[_app].appFunds - apps[_app].appSubscriptions;
    }

    function getYearlyCost(uint _app, uint _amount) public view returns (uint) {
        return _amount * apps[_app].appPercentage / 100 + 1;
    }

    function getCurrentMonth() public view returns (uint) {
        return currentMonth;
    }

    function getApp(uint _app) public view returns (Application memory) {
        return apps[_app];
    }

    function getSub(address _user, uint _app) public view returns (Subscription memory) {
        return subs[_user][_app];
    }

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                             INTERNAL FUNCTIONS                               //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////





    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                              PUBLIC FUNCTIONS                                //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    /*
        This function allows the user to insure an amount of funds deposited on an application.
    */
    function subscribeApp(uint _app, uint _amount) public payable {
        require(apps[_app].isEnsured == true, "App not ensured");
        require(subs[msg.sender][_app].subNextMonth == 0, "Already subscribed");
        require(_amount <= getMaxSubscription(_app), "Amount too high");

        uint subValue = getYearlyCost(_app, _amount);
        require(msg.value == subValue, "Wrong value");

        apps[_app].appSubscriptions += _amount;
        subs[msg.sender][_app].subAmount = _amount;

        apps[_app].appFunds += subValue;
        subs[msg.sender][_app].subLastMonth = subs[msg.sender][_app].subNextMonth;
        subs[msg.sender][_app].subNextMonth = getCurrentMonth().add(1);
    }

    /*
        This function allow the user to pay his monthly subscription.
    */
    function paySubscription(uint _app) public payable {
        require(apps[_app].isEnsured == true, "App not ensured");
        require(subs[msg.sender][_app].subNextMonth <= getCurrentMonth(), "Already paid");
        require(subs[msg.sender][_app].subAmount != 0, "Not subscribed");

        uint subValue = getYearlyCost(_app, subs[msg.sender][_app].subAmount);
        require(msg.value == subValue, "Wrong value");

        apps[_app].appFunds += subValue;
        subs[msg.sender][_app].subLastMonth = subs[msg.sender][_app].subNextMonth;
        subs[msg.sender][_app].subNextMonth = getCurrentMonth().add(1);
    }

    /*
        This function allow the user to get refunded in case of hack.
    */
    function getRefunded(uint _app) public {
        require(apps[_app].appHackMonth != 0, "App not hacked");
        require(subs[msg.sender][_app].subLastMonth == apps[_app].appHackMonth || subs[msg.sender][_app].subNextMonth == apps[_app].appHackMonth, "You are not ensured.");

        (bool success, ) = msg.sender.call{value: subs[msg.sender][_app].subAmount}("");
        require(success, "Tx failed");

        apps[_app].appFunds -= subs[msg.sender][_app].subAmount;

        subs[msg.sender][_app].subAmount = 0;
        subs[msg.sender][_app].subLastMonth = 0;
        subs[msg.sender][_app].subLastMonth = 0;
    }

    //////////////////////////////////////////////////////////////////////////////////
    //                                                                              //
    //                                                                              //
    //                                  MODIFIERS                                   //
    //                                                                              //
    //                                                                              //
    //////////////////////////////////////////////////////////////////////////////////

    modifier appEnsured(uint _app) {
        require(apps[_app].isEnsured == true, "App not ensured");
        _;
    }
}