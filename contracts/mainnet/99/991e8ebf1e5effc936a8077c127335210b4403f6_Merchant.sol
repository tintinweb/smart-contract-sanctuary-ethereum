// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMerchant.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

contract Merchant is IMerchant, Initializable, OwnableUpgradeable {

    mapping(address => MerchantInfo) public merchantMap;

    address[] public globalTokens;

    event AddMerchant(address merchant, address proxy);

    event SetMerchantRate(address merchant, address proxy, uint256 newRate);

    address public immutable SETTLE_TOKEN;

    receive() payable external {}

    constructor(address _settleToken){
        SETTLE_TOKEN = _settleToken;
    }

    function initialize()public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function addMerchant(
        address payable _settleAccount,
        address _settleCurrency,
        bool _autoSettle,
        address _proxy,
        uint256 _rate,
        address[] memory _tokens
    ) external {

        if(address(0) != _settleCurrency) {
            require(SETTLE_TOKEN == _settleCurrency);
        }

        if(_tokens.length > 0) {
            for(uint j = 0; j < _tokens.length; j++) {
                require(validatorGlobalToken(_tokens[j]));
            }
        }

        merchantMap[msg.sender] = MerchantInfo (msg.sender, _settleAccount, _settleCurrency, _autoSettle, _proxy, _rate, _tokens);

        emit AddMerchant(msg.sender, _proxy);

        emit SetMerchantRate(msg.sender, _proxy, _rate);

    }

    function setMerchantRate(address _merchant, uint256 _rate) external {

        require(msg.sender == merchantMap[_merchant].proxy);

        merchantMap[_merchant].rate = _rate;

        emit SetMerchantRate(_merchant, msg.sender, _rate);

    }

    function getMerchantInfo(address _merchant) external view returns(MerchantInfo memory){
        return merchantMap[_merchant];
    }

    function isMerchant(address _merchant) external view returns(bool) {
        return _isMerchant(_merchant);
    }

    function _isMerchant(address _merchant) public view returns(bool) {
        return merchantMap[_merchant].account != address(0);
    }

    function getMerchantTokens(address _merchant) external view returns(address[] memory) {
        return merchantMap[_merchant].tokens;
    }

    function getAutoSettle(address _merchant) external view returns(bool){
        return merchantMap[_merchant].autoSettle;
    }

    function getSettleCurrency(address _merchant) external view returns(address){
        return merchantMap[_merchant].settleCurrency;
    }

    function getSettleAccount(address _merchant) external view returns(address){
        return merchantMap[_merchant].settleAccount;
    }

    function getGlobalTokens() public view returns(address[] memory){
        return globalTokens;
    }

    function setGlobalTokens(address[] memory _tokens) external onlyOwner{
        globalTokens = _tokens;
    }

    function validatorCurrency(address _merchant, address _currency) public view returns (bool){
        for(uint idx = 0; idx < merchantMap[_merchant].tokens.length; idx ++) {
            if (_currency == merchantMap[_merchant].tokens[idx]) {
                return true;
            }
        }
        return false;
    }

    function validatorGlobalToken(address _token) public view returns (bool){
        for(uint idx = 0; idx < globalTokens.length; idx ++) {
            if (_token == globalTokens[idx]) {
                return true;
            }
        }
        return false;
    }

}