// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;

import "AggregatorV3Interface.sol";
import "ShareEngineInterface.sol";

contract share_gear {

// @dev - Declaring variables.

    string recording_title;
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
        uint Owner_percent;
        uint Owner_change;
        bool isContract;
    }

    struct Payments {
        uint paymentValue;
    }

    Payments[] public payments;
    Taxer public taxer;
    Owners[] public owners;

// @dev - Initial information when deploying contract.

    constructor(string memory _recording_title, uint _minTxVal, uint _taxPercent, address _taxAddr, address[] memory _addresses, uint[] memory _percents) {
        recording_title = _recording_title;
        owners.push(Owners({Owner_wallet: address(this), Owner_percent: 0, Owner_change: 0, isContract: true}));
        minTxVal = _minTxVal;
        taxer.taxPercent = _taxPercent;
        taxer.taxAddr = _taxAddr;
        uint _i = 0;
        while(_i < _addresses.length) {
            if(isContract(_addresses[_i])){
                owners.push(Owners({Owner_wallet: _addresses[_i], Owner_percent: _percents[_i], Owner_change: 0, isContract: true}));
                owner_array[msg.sender] = owners.length - 1;
            } else {
                owners.push(Owners({Owner_wallet: _addresses[_i], Owner_percent: _percents[_i], Owner_change: 0, isContract: false}));
                owner_array[msg.sender] = owners.length - 1;
            }
            _i++;
        }
    }

// @dev - Returns contract basic parameters.

    function retrieve_info() external view returns (string memory, uint) {
        return(recording_title, minTxVal);
    }

// @dev - Returns address' royalty percentage.

    function check_percent(address _address) external view returns (uint) {
        return(owners[owner_array[_address]].Owner_percent);
    }

// @dev - Using ChainLink's AggregatorV3Interface to get Ether price in USD.

    function getEthPrice() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer/1000000);
    }

// @dev - Automatic royalties distribution between token owners. If due payment is less than the minimium transaction allowed,
//        it remains stored as 'change'. The change is payed when it gets greater than the minimum transaction amount.

    function autopay_roy() internal {
        minTxValEth = (minTxVal*10**20)/getEthPrice();
        taxValue = (royBalance/100)*taxer.taxPercent;
        taxValueSum = taxValue + taxer.taxChange;
        if (taxValueSum > minTxValEth) {
            payable(taxer.taxAddr).transfer(taxValueSum);
            taxer.taxChange = 0;
        } else {
            taxer.taxChange = taxValueSum;
        }
        royBalance = royBalance - taxValue;
        royBalanceNew = royBalance;
        while(j < owners.length) {
            shareVal = ((owners[j].Owner_percent)*(royBalance))/10000;
            shareValSum = shareVal+owners[j].Owner_change;
            if (shareValSum > minTxValEth) {
                if(owners[j].isContract){
                    ShareEngineInterface c = ShareEngineInterface(owners[j].Owner_wallet);
                    c.royalty_pay{value: shareValSum}();
                } else {
                    payable(owners[j].Owner_wallet).transfer(shareValSum);
                }
                owners[j].Owner_change = 0;
            } else {
                owners[j].Owner_change = shareValSum;
            }
            royBalanceNew = royBalanceNew - shareVal;
            j++;
        }
        j = 1;
        royBalance = royBalanceNew;
        royBalanceNew = 0;
    }

// @dev - Check if receiver address is contract.

    function isContract(address _a) internal view returns(bool){
      uint32 size;
      assembly {
        size := extcodesize(_a)
      }
      return (size > 0);
    }

// @dev - Royalty payment function. Must be used by the royalty distributor.

    function royalty_pay() external payable {
        royBalance = royBalance + msg.value;
        payments.push(Payments({paymentValue: msg.value}));
        autopay_roy();
    }
}