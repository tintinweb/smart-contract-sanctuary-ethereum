// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IUSDT {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function balanceOf(address creatorAddress) external returns (uint256);
    function allowance(address _owner, address _spender) external returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
}

/**
    This smart contract servers as a payment processor for MDM.

    The process is:

    1. The creator will approve this smart contract to spend his ERC20 tokens for the amount X
    2. The creator will initiate a payment transaction by sending the "amount", campaign ID and the UPI number.
 */
contract MDM {
    mapping (uint256 => uint256) private _receipt;
    mapping (uint256 => uint256) private _campaignPayments;

    address private _usdtAddress;
    address private _coldStorage;
    IUSDT paymentMethod = IUSDT(_usdtAddress);


    constructor (address coldStorageAddress) {
        _coldStorage = coldStorageAddress;
    }

    function activateCampaign(uint256 campaignId, uint256 UPI, uint256 amount)
    public
    returns (bool)
    {
        require(campaignId > 0, "Please provide a valid Campaign ID.");
        require(UPI > 0, "Please provide a valid unique payment identifier.");
        require(amount > 0, "Please provide a valid payment amount.");
        require(IUSDT(_usdtAddress).balanceOf(msg.sender) >= amount, "Not enough funds in your USDT account.");
        require(IUSDT(_usdtAddress).allowance(msg.sender, address(this)) >= amount,"Please approve this contract before making the payment.");
        bool usdtTransfer = IUSDT(_usdtAddress).transferFrom(msg.sender, address(this), amount);
        bool campaignPayment = _makePayment(amount);

        if(usdtTransfer && campaignPayment) {
            _receipt[UPI] = amount;
            uint256 currentCampaignPayments = _campaignPayments[campaignId];
            uint256 newTotalCapaignPayments = currentCampaignPayments + amount;
            _campaignPayments[campaignId] = newTotalCapaignPayments;
            return true;
        } else {
            return false;
        }

    }

    function _makePayment(uint256 amount)
    private
    returns (bool)
    {
        bool paymentMade = IUSDT(_usdtAddress).transfer(_coldStorage, amount);

        if(paymentMade) {
            return true;
        } else {
            return false;
        }      
    }

    function getReceipt (uint256 UPI)
    public
    view
    returns (uint256) {
        return _receipt[UPI];
    }

    function getCampaignTotalPayments(uint256 campaignId)
    public
    view
    returns (uint256) {
        return _campaignPayments[campaignId];
    }

}