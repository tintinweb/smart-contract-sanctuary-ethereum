// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import { SafeMath } from "./SafeMath.sol";
import { Address } from "./Address.sol";

import { IERC20Internal } from "./IERC20Internal.sol";
import { EIP3009 } from "./EIP3009.sol";
import { EIP2612 } from "./EIP2612.sol";
import { EIP712 } from "./EIP712.sol";

contract NeverEver is IERC20Internal, EIP3009, EIP2612
{
    //1 wei = 1
    //1 szabo = 1e12
    //1 finney = 1e15
    //1 ether = 1e18 
    uint256 internal pricePerNVR = 0.01 ether;
    using SafeMath for uint256;
    using Address for address;
   
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupply;
    string internal _name;
    string internal _version;
    string internal _symbol;
    uint8 internal _decimals;
    address _owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
    event BuyToken(address indexed from, uint256 amount, uint256 pricePerNVR);
    event SellToken(address indexed from, uint256 amount, uint256 pricePerNVR);

    constructor(
        string memory tokenName,
        string memory tokenVersion,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        uint256 tokenTotalSupply
    ){
        _name = tokenName;
        _version = tokenVersion;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;

        DOMAIN_SEPARATOR = EIP712.makeDomainSeparator(tokenName, tokenVersion);
        _owner = msg.sender;
        _mint(_owner, tokenTotalSupply);
    }

    receive() external payable {}

    /**
     * @notice Token name
     * @return Name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @notice Token version
     * @return Version
     */
    function version() external view returns (string memory) {
        return _version;
    }

    /**
     * @notice Token symbol
     * @return Symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Number of decimal places
     * @return Decimals
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Total amount of tokens in circulation
     * @return Total supply
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Get the balance of an account
     * @param account The account
     * @return Balance
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Amount of remaining tokens spender is allowed to transfer on
     * behalf of the token owner
     * @param owner     Token owner's address
     * @param spender   Spender's address
     * @return Allowance amount
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @notice Set spender's allowance over the caller's tokens to be a given
     * value
     * @param spender   Spender's address
     * @param amount    Allowance amount
     * @return True if successful
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Transfer tokens by spending allowance
     * @param sender    Payer's address
     * @param recipient Payee's address
     * @param amount    Transfer amount
     * @return True if successful
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transferring amount exceeds allowance!"
            )
        );
        return true;
    }

    /**
     * @notice Transfer tokens from the caller
     * @param recipient Payee's address
     * @param amount    Transfer amount
     * @return True if successful
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @notice Increase the allowance by a given amount
     * @param spender       Spender's address
     * @param addedValue    Amount of increase in allowance
     * @return True if successful
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _increaseAllowance(msg.sender, spender, addedValue);
        return true;
    }

    /**
     * @notice Decrease the allowance by a given amount
     * @param spender           Spender's address
     * @param subtractedValue   Amount of decrease in allowance
     * @return True if successful
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        _decreaseAllowance(msg.sender, spender, subtractedValue);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "ERC20: transferring from the zero address!");
        require(recipient != address(0), "ERC20: transferring to the zero address!");

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transferring amount exceeds balance!"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: minting to the zero address!");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: burning from the zero address!");

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burning amount exceeds balance!"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        require(owner != address(0), "ERC20: approving from the zero address!");
        require(spender != address(0), "ERC20: approving to the zero address!");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _increaseAllowance(
        address owner,
        address spender,
        uint256 addedValue
    ) internal override {
        _approve(owner, spender, _allowances[owner][spender].add(addedValue));
    }

    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 subtractedValue
    ) internal override {
        _approve(
            owner,
            spender,
            _allowances[owner][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero!"
            )
        );
    }

    modifier onlyOwner()
    {
       require(msg.sender == _owner, "You must be contract owner to call this function!");
       _;     
    }


    function getPricePerNVR() external view returns(uint256)
    {
        return pricePerNVR;
    }

    function setPricePerPRH(uint256 newPricePerNVR) external payable onlyOwner
    {
        require(newPricePerNVR != 0, "NeverEver.setPricePerNVR: price must be more than zero!");
        pricePerNVR = newPricePerNVR;
    }
    
      function buy(uint256 amountToBuy) external payable
    {
        uint256 amountEtherInWei = msg.value;
        require(amountToBuy <= this.balanceOf(_owner), "NeverEver.buy: do not have enough NVR tokens in reserve!");
        require(amountToBuy >= (10**this.decimals() ).div(pricePerNVR), "NeverEver.buy: purchasing amount is less than 1 wei!");
        uint256 TotalCost = amountToBuy.mul(pricePerNVR);
        TotalCost = TotalCost.div(10**18); 
        require(amountEtherInWei >= TotalCost,
        "NeverEver.buy: do not received enough ethers to buy requested amount of NVR tokens!");
        _transfer(_owner,msg.sender, amountToBuy);
        if(amountEtherInWei > TotalCost)
        {   
            uint256 refund = amountEtherInWei.sub(TotalCost);
            payable(msg.sender).transfer(refund);
        }
        emit BuyToken(msg.sender, amountToBuy, pricePerNVR);
    }

     function sell(uint256 amountToSell) external payable
    {
        require(this.balanceOf(msg.sender) >= amountToSell, "NeverEver.sell: you do not have enough NVR tokens!");
        require(amountToSell >= (10**this.decimals()).div(pricePerNVR), "NeverEver.sell: so little sum for selling!");
        uint256 _allowance = this.allowance(msg.sender, address(this));
         uint256 weiAmount = amountToSell.mul(pricePerNVR);
        weiAmount = weiAmount.div(10** this.decimals());
        require(_allowance >= amountToSell, "NeverEver.sell: check the NVR token allowance!");
        require(address(this).balance >= weiAmount, "NeverEver.sell: contract has not enough ethers. Try to call function later!");
        this.transferFrom(msg.sender, _owner, amountToSell);
        payable(msg.sender).transfer(weiAmount);
        emit SellToken(msg.sender, amountToSell, pricePerNVR);
    }

    function gassLessSell( 
        address from,
        address to, 
        uint256 value, 
        uint256 validAfter, 
        uint256 validBefore, 
        bytes32 nonce, 
        uint8 v, 
        bytes32 r,
        bytes32 s) 
    external
    {
        require(to == _owner, "NeverEver.gassLessSell: signed transaction must be send to owner address!");
        require(this.balanceOf(from) >= value, "NeverEver.gassLessSell: you do not have enough NVR tokens!");
        require(value >= (10**this.decimals()).div(pricePerNVR), "NeverEver.gassLessSell: so little sum to sell!");
        uint256 weiAmount = value.mul(pricePerNVR);
        weiAmount = weiAmount.div(10** this.decimals());
        require(address(this).balance >= weiAmount, "NeverEver.gassLessSell: contract has not enough ethers. Try to call function later!");
        transferWithAuthorization(from, _owner, value, validAfter, validBefore, nonce, v, r, s);
        payable(from).transfer(weiAmount);
        emit SellToken(msg.sender, value, pricePerNVR);
    }

    function gassLessTransfer(
        address from,
        address to, 
        uint256 value, 
        uint256 validAfter, 
        uint256 validBefore, 
        bytes32 nonce, 
        uint8 v, 
        bytes32 r,
        bytes32 s)
    external
    {
        require(this.balanceOf(from) >= value, 
                "NeverEver.gassLessTransfer: you do not have enough NVR tokens!");
        transferWithAuthorization(from, to, value, validAfter, validBefore, nonce, v, r, s);
        emit Transfer(from, to, value);
    } 
}