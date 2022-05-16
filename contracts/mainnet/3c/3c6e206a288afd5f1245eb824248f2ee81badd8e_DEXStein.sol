/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

/*********************    DEXStein utility token    ************************/
/***************************************************************************/
/** "Don't believe everything you read on the internet." ~Abraham Lincoln **/
/***************************************************************************/

contract owned {
    address payable private _owner;

    constructor () {
        _owner = payable(msg.sender);
    }

    function owner() public returns (address payable){
        return _owner;
    }

    modifier onlyOwner {
        require (msg.sender == _owner, 'you are not the owner');
        _;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        _owner = newOwner;
    }
}

interface ERC20Interface{
    function totalSupply() external returns (uint);

    function balanceOf(address tokenOwner) external returns (uint balance);

    function allowance(address tokenOwner, address spender) external returns (uint remaining);

    function transfer(address to, uint tokens) external returns (bool success);

    function approve(address spender, uint tokens) external returns (bool success);

    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

//Contract function to receive approval and execute function in one call
interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}

//Actual token contract
contract DEXStein is ERC20Interface, owned {
    string private constant _symbol = "DCSY";
    string private constant _name = "DEXStein commerce sys";
    uint8 private constant _decimals = 18;

    uint private _totalSupply;
    uint private _marketingPercent = 2;

    address private _marketingWallet = 0xb859BdfC54E100a54bcC6531A33Cb3913d7E361d;

    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;
    mapping (address => bool) private isBlackListed;
    mapping (address => bool) private isExcludedFromTaxAndLimits;

    // Txn limit //
    uint256 private _maxTxnAmount = 1000 * 10 ** _decimals;
    // Txn limit  //

    uint256 private _maxBurnAmount = 10 * 10 ** _decimals;

    constructor() {
        uint256 initialSupply = 250000000;
        _totalSupply = initialSupply * 10 ** uint256(_decimals);

        isExcludedFromTaxAndLimits[msg.sender] = true;
        isExcludedFromTaxAndLimits[_marketingWallet] = true;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public returns (uint balance) {
        return balances[tokenOwner];
    }

    function _transfer(address _from, address _to, uint _value) internal returns (bool success)  {
        require(!isBlackListed[_from] && !isBlackListed[_to], "You are a blocked from using this token. you know why");

        require(_value > 0, "Transfer amount must be greater than zero");

        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0), "No zero address transfers allowd here");

        // Check if the sender has enough
        require(balances[_from] >= _value, "You are trying to transfer more than you have");

        // Check for overflows
        require(balances[_to] + _value > balances[_to], "Overflow");
        // Save this for an assertion in the future

        // transfer free of marketing fees and limits
        if(isExcludedFromTaxAndLimits[_from] || isExcludedFromTaxAndLimits[_to]){
            balances[_from] -= _value;
            balances[_to] += _value;
            emit Transfer(_from, _to, _value);
            return true;
        }

        require(_value <= _maxTxnAmount ,"You have exided the maximum amount you can move");

        uint marketingValue = (_value * _marketingPercent) / 100;
        uint transferValue = _value - marketingValue;

        uint previousBalances = balances[_from] + balances[_to] + balances[_marketingWallet];
        // Subtract from the sender
        balances[_from] -= _value;

        // Add the value - marketing % to the recipient
        balances[_to] += transferValue;
        emit Transfer(_from, _to, transferValue);

        //Add the marketing % to the marketing wallet
        balances[_marketingWallet] += marketingValue;
        emit Transfer(_from, _marketingWallet, marketingValue);

        // Sanity check
        assert(balances[_from] + balances[_to] + balances[_marketingWallet] == previousBalances);

        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        return _transfer(msg.sender, to, tokens);
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        return _transfer(from, to, tokens);
    }

    function allowance(address tokenOwner, address spender) public returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes calldata data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    function burnTokens(uint256 amount) external virtual {
        uint256 burnAmount = amount * 10 ** _decimals;
        _burnTokens(msg.sender, burnAmount);
    }

    function burnTokensFrom(address _from, uint256 amount) external virtual {
        uint256 burnAmount = amount * 10 ** _decimals;

        // Check allowance
        require(burnAmount <= allowed[_from][msg.sender]);
       // Subtract from the sender's allowance
        allowed[_from][msg.sender] -= burnAmount;

        _burnTokens(_from, burnAmount);
    }

    function _burnTokens(address _from, uint256 burnAmount) internal virtual {
        require(burnAmount <= _maxBurnAmount, "sorry, but currently you cant burn that much");

        require(_from != address(0), "cant burn from the zero address");
        require(balances[_from] >= burnAmount, "burn amount exceeds balance");
        balances[_from] -= burnAmount;
        _totalSupply -= burnAmount;

        emit Transfer(_from, address(0), burnAmount);
    }

    /*SETTINGS*/
    function setMarketingWallet(address wallet) external onlyOwner{
        _marketingWallet = wallet;
         isExcludedFromTaxAndLimits[_marketingWallet] = true;
    }

    function setMarketingPercent(uint percent) external onlyOwner returns (uint oldPercent) {
        require(percent >= 1 && percent <= 10, "percent must be >=1 <=10");

        uint old = _marketingPercent;
        _marketingPercent = percent;
        return old;
    }

    function blockAddress(address account, bool state) external onlyOwner{
        isBlackListed[account] = state;
    }
    
    function blockAddressBulk(address[] memory accounts, bool state) external onlyOwner{
        for(uint256 i = 0; i < accounts.length; i++){
            isBlackListed[accounts[i]] = state;
        }
    }

    function excludeFromTaxAndLimits(address account) external onlyOwner {
        isExcludedFromTaxAndLimits[account] = true;
    }

    function includeInTaxAndLimits(address account) external onlyOwner {
        isExcludedFromTaxAndLimits[account] = false;
    }

    function updateMaxTxnAmount(uint256 amount) external onlyOwner{
        _maxTxnAmount = amount * 10 ** _decimals;
    }

    function updateMaxBurnAmount(uint256 amount) external onlyOwner{
        _maxBurnAmount = amount * 10 ** _decimals;
    }

    // allow owner to claim ERC20 tokens sent to this contract (by mistake)
    function rescueTokens(address _tokenAddr, address _to, uint _amount) external onlyOwner {
        ERC20Interface(_tokenAddr).transfer(_to, _amount);
    }

    //Transfer all ETH sent to the contract to the owner(depolyer) wallet
    receive() external payable {
        owner().transfer(msg.value);
    }
}