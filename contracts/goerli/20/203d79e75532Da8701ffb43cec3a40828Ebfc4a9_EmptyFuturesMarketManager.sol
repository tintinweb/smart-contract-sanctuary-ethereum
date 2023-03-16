/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: EmptyFuturesMarketManager.sol
*
* Latest source (may be newer): https://github.com/Synthetixio/synthetix/blob/master/contracts/EmptyFuturesMarketManager.sol
* Docs: https://docs.synthetix.io/contracts/EmptyFuturesMarketManager
*
* Contract Dependencies: 
*	- IFuturesMarketManager
* Libraries: (none)
*
* MIT License
* ===========
*
* Copyright (c) 2023 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/



pragma solidity ^0.5.16;

interface IFuturesMarketManager {
    function markets(uint index, uint pageSize) external view returns (address[] memory);

    function markets(
        uint index,
        uint pageSize,
        bool proxiedMarkets
    ) external view returns (address[] memory);

    function numMarkets() external view returns (uint);

    function numMarkets(bool proxiedMarkets) external view returns (uint);

    function allMarkets() external view returns (address[] memory);

    function allMarkets(bool proxiedMarkets) external view returns (address[] memory);

    function marketForKey(bytes32 marketKey) external view returns (address);

    function marketsForKeys(bytes32[] calldata marketKeys) external view returns (address[] memory);

    function totalDebt() external view returns (uint debt, bool isInvalid);

    function isEndorsed(address account) external view returns (bool);

    function allEndorsedAddresses() external view returns (address[] memory);

    function addEndorsedAddresses(address[] calldata addresses) external;

    function removeEndorsedAddresses(address[] calldata addresses) external;
}


// Empty contract for ether collateral placeholder for OVM
// https://docs.synthetix.io/contracts/source/contracts/emptyethercollateral


contract EmptyFuturesMarketManager is IFuturesMarketManager {
    bytes32 public constant CONTRACT_NAME = "EmptyFuturesMarketManager";

    function markets(uint index, uint pageSize) external view returns (address[] memory) {
        index;
        pageSize;
        address[] memory _markets;
        return _markets;
    }

    function markets(
        uint index,
        uint pageSize,
        bool proxiedMarkets
    ) external view returns (address[] memory) {
        index;
        pageSize;
        proxiedMarkets;
        address[] memory _markets;
        return _markets;
    }

    function numMarkets() external view returns (uint) {
        return 0;
    }

    function numMarkets(bool proxiedMarkets) external view returns (uint) {
        proxiedMarkets;
        return 0;
    }

    function allMarkets() external view returns (address[] memory) {
        address[] memory _markets;
        return _markets;
    }

    function allMarkets(bool proxiedMarkets) external view returns (address[] memory) {
        proxiedMarkets;
        address[] memory _markets;
        return _markets;
    }

    function marketForKey(bytes32 marketKey) external view returns (address) {
        marketKey;
        return address(0);
    }

    function marketsForKeys(bytes32[] calldata marketKeys) external view returns (address[] memory) {
        marketKeys;
        address[] memory _markets;
        return _markets;
    }

    function totalDebt() external view returns (uint debt, bool isInvalid) {
        return (0, false);
    }

    function isEndorsed(address account) external view returns (bool) {
        account;
        return false;
    }

    function allEndorsedAddresses() external view returns (address[] memory) {
        address[] memory _endorsedAddresses;
        return _endorsedAddresses;
    }

    function addEndorsedAddresses(address[] calldata addresses) external {
        addresses;
    }

    function removeEndorsedAddresses(address[] calldata addresses) external {
        addresses;
    }
}