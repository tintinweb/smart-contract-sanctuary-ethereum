// SPDX-License-Identifier: MIT
//Im Rich Bitch is a contract that is unique to that which allows each holder that is early to the token and holds the most tokens to 
//"Claim" a reward...  The fee is redistributed to the holders to which you can claim.. Be quick and get the bag...You're rich bitch.
pragma solidity ^0.8.0;

contract ImRichBitch {
    string public name = "Im Rich Bitch";
    string public symbol = "Rich";
    uint256 public totalSupply = 60_000_000_00 * 10**18;
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;

    uint256 public buyFeePercent = 10;
    uint256 public sellFeePercent = 10;

    uint256 public constant feeRedistributionRate = 5; // Fee redistribution rate per transaction
    uint256 public constant maxTransactionsWithFees = 40; // Maximum transactions with fees

    uint256 public totalTransactions;

    mapping(address => uint256) public feeBalance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event BuyFeePercentChanged(uint256 newBuyFeePercent);
    event SellFeePercentChanged(uint256 newSellFeePercent);

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_to != address(0));

        uint256 fee = calculateFee(_value, sellFeePercent);
        uint256 amountToTransfer = _value - fee;

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += amountToTransfer;
        emit Transfer(msg.sender, _to, amountToTransfer);

        if (fee > 0) {
            uint256 redistributedFee = (fee * feeRedistributionRate) / 100;
            feeBalance[owner] += redistributedFee;
            fee -= redistributedFee;
        }

        updateFeePercentOnTransfer();

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        require(_to != address(0));

        uint256 fee = calculateFee(_value, sellFeePercent);
        uint256 amountToTransfer = _value - fee;

        balanceOf[_from] -= _value;
        balanceOf[_to] += amountToTransfer;
        emit Transfer(_from, _to, amountToTransfer);

        if (fee > 0) {
            uint256 redistributedFee = (fee * feeRedistributionRate) / 100;
            feeBalance[owner] += redistributedFee;
            fee -= redistributedFee;
        }

        updateFeePercentOnTransfer();

        return true;
    }

    function calculateFee(uint256 _amount, uint256 _percent) internal pure returns (uint256) {
        return (_amount * _percent) / 100;
    }

    function updateFeePercentOnTransfer() internal {
        totalTransactions++;

        if (totalTransactions <= maxTransactionsWithFees) {
            uint256 reductionFactor = 100 - (totalTransactions * feeRedistributionRate);
            uint256 newBuyFeePercent = (buyFeePercent * reductionFactor) / 100;
            uint256 newSellFeePercent = (sellFeePercent * reductionFactor) / 100;

            buyFeePercent = newBuyFeePercent;
            sellFeePercent = newSellFeePercent;
        }
    }

    function claimFees() public {
        uint256 feeAmount = feeBalance[msg.sender];
        require(feeAmount > 0, "No fees to claim.");

        feeBalance[msg.sender] = 0;
        balanceOf[msg.sender] += feeAmount;
        emit Transfer(owner, msg.sender, feeAmount);
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }
}