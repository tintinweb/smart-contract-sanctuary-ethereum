// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;

import "AggregatorV3Interface.sol";

contract share_engine {

// @dev - Declaring variables.

    string project_name;
    uint total_tokens;
    uint remaining_tokens;
    address receiver;
    uint ethPriceUsd;
    uint valueUsd;
    uint fundValue;
    uint tokenValue;
    uint usr_token_bal;
    uint fundBalance;
    uint royBalance;
    uint royBalanceNew;
    uint shareVal;
    uint shareValSum;
    uint j = 1;
    uint minTxVal;
    uint minTxValEth;
    uint taxValue;
    uint taxValueSum;

    mapping (address => uint) public owner_array;

    struct Taxer {
        address taxAddr;
        uint taxPercent;
        uint taxChange;
    }

    struct Owners {
        address Owner_wallet;
        uint256 Owner_totaltokens;
        uint Owner_change;
    }

    struct Payments {
        uint paymentValue;
    }

    Payments[] public payments;
    Taxer public taxer;
    Owners[] public owners;

// @dev - Initial information when deploying contract.

    constructor(string memory _project_name, uint _total_tokens, uint _fundValue, address _receiver, uint _minTxVal, uint _taxPercent, address _taxAddr) {
        project_name = _project_name;
        total_tokens = _total_tokens; 
        remaining_tokens = total_tokens;
        owners.push(Owners({Owner_wallet: address(this), Owner_totaltokens: 0, Owner_change: 0}));
        fundValue = _fundValue;
        receiver = _receiver;
        minTxVal = _minTxVal;
        taxer.taxPercent = _taxPercent;
        taxer.taxAddr = _taxAddr;
    }

// @dev - Retrieving token value.

    function token_value() public view returns (uint256) {
        return ((((fundValue/total_tokens)*10**20)/getEthPrice()));
    }

// @dev - Main view function to get contract's infos.

    function retrieve_info() external view returns (string memory, uint256, uint256, uint256, uint256, uint256) {
        return (project_name, remaining_tokens, total_tokens, ((total_tokens-remaining_tokens)*(fundValue/total_tokens)), fundValue, (fundValue/total_tokens));
    }

// @dev - Using ChainLink's AggregatorV3Interface to get Ether price in USD.
// Add paleativo para EthPrice

    function getEthPrice() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer/1000000);
    }

// @dev - Automatic investment payment to the contract's receiver. The amount is payed each time a token is bought. If due
//        payment is less than the minimum transaction allowed, it remains stored as 'change'. The change is payed when it gets
//        greater than the minimum transaction amount.

    function autopay_funds() internal {
        minTxValEth = (minTxVal*10**20)/getEthPrice();
        taxValue = (fundBalance/100)*taxer.taxPercent;
        if (taxValue > minTxValEth) {
            payable(taxer.taxAddr).transfer(taxValue+taxer.taxChange);
        } else {
            taxer.taxChange = taxer.taxChange + taxValue;
        }
        fundBalance = fundBalance - taxValue;
        if (fundBalance > minTxValEth) {
            payable(receiver).transfer(fundBalance);
            fundBalance = 0;
        }
    }

// @dev - Automatic royalties distribution between token owners. If due payment is less than the minimium transaction allowed,
//        it remains stored as 'change'. The change is payed when it gets greater than the minimum transaction amount.

    function autopay_roy() internal {
        minTxValEth = (minTxVal*10**20)/getEthPrice();
        taxValue = (royBalance/100)*taxer.taxPercent;
        taxValueSum = taxValue + taxer.taxChange;
        if (taxValueSum > minTxValEth) {
            payable(taxer.taxAddr).transfer(taxValueSum);
        } else {
            taxer.taxChange = taxValueSum;
        }
        royBalance = royBalance - taxValue;
        royBalanceNew = royBalance;
        while(j < owners.length) {
            shareVal = (owners[j].Owner_totaltokens)*(royBalance/total_tokens);
            shareValSum = shareVal+owners[j].Owner_change;
            if (shareValSum > minTxValEth) {
                payable(owners[j].Owner_wallet).transfer(shareValSum);
                owners[j].Owner_change = 0;
            } else {
                owners[j].Owner_change = shareValSum;
            }
            royBalanceNew = royBalanceNew - shareVal;
            j++;
        }
        j = 1;
        if (royBalanceNew > minTxValEth) {
            payable(receiver).transfer(royBalanceNew);
            royBalance = 0;
            royBalanceNew = 0;
        }   else {
            royBalance = royBalanceNew;
            royBalanceNew = 0;
        }
    }

// @dev - Royalty payment function. Must be used by the royalty distributor.

    function royalty_pay() external payable {
        royBalance = royBalance + msg.value;
        payments.push(Payments({paymentValue: msg.value}));
        autopay_roy();
    }

// @dev - Token purchasing function.

     function buy_tokens(uint256 tokens_bought) external payable {
        require(msg.value > (minTxVal*10**20)/getEthPrice());
        if(tokens_bought<=remaining_tokens) {
            require(msg.value>=(token_value()*tokens_bought));
            remaining_tokens = remaining_tokens - tokens_bought;
            fundBalance = fundBalance + msg.value;
            if(owner_array[msg.sender]==0){
                owners.push(Owners({Owner_wallet: msg.sender, Owner_totaltokens: tokens_bought, Owner_change: 0}));
                owner_array[msg.sender] = owners.length - 1;
                autopay_funds();
            } else {
                usr_token_bal = owners[owner_array[msg.sender]].Owner_totaltokens;
                owners[owner_array[msg.sender]].Owner_totaltokens = usr_token_bal+tokens_bought;
                autopay_funds();
            }
        }   else    {
            revert();
        }
        
    }

}