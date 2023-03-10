/**
 *Submitted for verification at Etherscan.io on 2023-03-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract LaiSee {
    uint256 public counter;
    mapping(uint256 => address) public order;
    mapping(address => uint256) public order_rev;

    mapping(uint256 => address) public getIn;
    mapping(uint256 => address) public getOut;

    mapping(uint256 => bool) public salvation;
    mapping(uint256 => uint256) public getInType;
    mapping(address => uint256) public addressFinished;

    address public lastPaymentTo;
    address public lastPaymentIn;

    uint256 public envelopesDelivered;

    address payable public constant FST_ADDRESS = payable(0xB99984d2C9445461E654a75857Aa93cC9Fd3a38f);
    address payable public constant FEE_ADDRESS = payable(0xF3514Bba90078E301E344d181aa0024528B46e13);
    address payable public constant NULL_ADDRESS = payable(0x0000000000000000000000000000000000000000);

    mapping(address => address) public left;
    mapping(address => address) public right;

    mapping(address => address) public refAddress;

    mapping(address => uint256) public inMyCycle;

    constructor() {
        counter = 1;
    }

    receive() external payable {
      address myWalletAddress = msg.sender;
      require(msg.value == 0.06 ether, "Must send exactly 0.06 ether");
      require(order_rev[myWalletAddress] == 0, "Already participating");
      if (myWalletAddress != FST_ADDRESS) {
        address userWalletAddress;
        for (uint256 j = 1; j <= counter; j++) {
            if (order[j] != NULL_ADDRESS) {
                userWalletAddress = order[j];
                break;
            }
        }
        require(userWalletAddress != NULL_ADDRESS, "Not possible");
        counter++;
        addMeToCycle (myWalletAddress, userWalletAddress);
        salvation[counter] = true;
      }
      if (myWalletAddress == FST_ADDRESS) { counter++; }
      FEE_ADDRESS.transfer(0.015 ether);
      order[counter] = myWalletAddress;
      order_rev[myWalletAddress] = counter;
      getIn[counter] = myWalletAddress;
      lastPaymentIn = myWalletAddress;
    }

    function payIn(address myWalletAddress, address userWalletAddress) external payable {
        require(msg.value == 0.06 ether, "Must send exactly 0.06 ether");
        require(userWalletAddress != NULL_ADDRESS, "Must be not NULL address");
        require(order_rev[myWalletAddress] == 0, "You are already participating");
        require(order_rev[userWalletAddress] != 0, "Other user is not participating");
        counter++;
        addMeToCycle (myWalletAddress, userWalletAddress);
        order[counter] = myWalletAddress;
        order_rev[myWalletAddress] = counter;
        getIn[counter] = myWalletAddress;
        lastPaymentIn = myWalletAddress;
        FEE_ADDRESS.transfer(0.015 ether);

        if (inMyCycle[userWalletAddress] > 13) {
            payOut(userWalletAddress);
        }
    }

    function payOut(address walletAddress) internal {
        address minAddress = walletAddress;

        payable(minAddress).transfer(0.36 ether);
        envelopesDelivered++;
        getOut[counter] = walletAddress;
        lastPaymentTo = walletAddress;
        setTiersToNull (walletAddress);
        uint256 finished = addressFinished[walletAddress];
        finished++;
        addressFinished[walletAddress] = finished;
    }

    function initiateMyPayment(address walletAddress) external {
        address tier2a = left[walletAddress];
        address tier2b = right[walletAddress];
        address tier3a = left[tier2a];
        address tier3b = left[tier2b];
        address tier3c = right[tier2a];
        address tier3d = right[tier2b];
        if (left[walletAddress] != NULL_ADDRESS && right[walletAddress] != NULL_ADDRESS && left[tier2a] != NULL_ADDRESS && right[tier2a] != NULL_ADDRESS && left[tier2b] != NULL_ADDRESS && right[tier2b] != NULL_ADDRESS && left[tier3a] != NULL_ADDRESS && right[tier3a] != NULL_ADDRESS && left[tier3b] != NULL_ADDRESS && right[tier3b] != NULL_ADDRESS && left[tier3c] != NULL_ADDRESS && right[tier3c] != NULL_ADDRESS && left[tier3d] != NULL_ADDRESS && right[tier3d] != NULL_ADDRESS) {
          payOut (walletAddress);
        }
    }

    function addMeToCycle(address myWalletAddress, address userWalletAddress) internal {
        bool stop;
        if (left[userWalletAddress] == NULL_ADDRESS) {
          left[userWalletAddress] = myWalletAddress;
          refAddress[myWalletAddress] = userWalletAddress;
          address aboveL1 = refAddress[userWalletAddress];
          address aboveL2 = refAddress[aboveL1];
          if (aboveL1 != NULL_ADDRESS) { inMyCycle[aboveL1]++; }
          if (aboveL2 != NULL_ADDRESS) { inMyCycle[aboveL2]++; }
          inMyCycle[userWalletAddress]++;
          stop = true;
        }
        if (right[userWalletAddress] == NULL_ADDRESS && !stop) {
          right[userWalletAddress] = myWalletAddress;
          refAddress[myWalletAddress] = userWalletAddress;
          address aboveL1 = refAddress[userWalletAddress];
          address aboveL2 = refAddress[aboveL1];
          if (aboveL1 != NULL_ADDRESS) { inMyCycle[aboveL1]++; }
          if (aboveL2 != NULL_ADDRESS) { inMyCycle[aboveL2]++; }
          inMyCycle[userWalletAddress]++;
          stop = true;
        }
        if (stop != true) {
          address tier2a = left[userWalletAddress];
          address tier2b = right[userWalletAddress];
          address tier3a = left[tier2a];
          address tier3b = left[tier2b];
          address tier3c = right[tier2a];
          address tier3d = right[tier2b];
          if (left[tier2a] == NULL_ADDRESS) {
            left[tier2a] = myWalletAddress;
            refAddress[myWalletAddress] = tier2a;
            address aboveL1 = refAddress[userWalletAddress];
            if (aboveL1 != NULL_ADDRESS) { inMyCycle[aboveL1]++; }
            inMyCycle[userWalletAddress]++;
            inMyCycle[tier2a]++;
            getInType[counter] = 2;
            stop = true;
          }
          if (left[tier2b] == NULL_ADDRESS && !stop) {
            left[tier2b] = myWalletAddress;
            refAddress[myWalletAddress] = tier2b;
            address aboveL1 = refAddress[userWalletAddress];
            if (aboveL1 != NULL_ADDRESS) { inMyCycle[aboveL1]++; }
            inMyCycle[userWalletAddress]++;
            inMyCycle[tier2b]++;
            getInType[counter] = 2;
            stop = true;
          }
          if (right[tier2a] == NULL_ADDRESS && !stop) {
            right[tier2a] = myWalletAddress;
            refAddress[myWalletAddress] = tier2a;
            address aboveL1 = refAddress[userWalletAddress];
            if (aboveL1 != NULL_ADDRESS) { inMyCycle[aboveL1]++; }
            inMyCycle[userWalletAddress]++;
            inMyCycle[tier2a]++;
            getInType[counter] = 2;
            stop = true;
          }
          if (right[tier2b] == NULL_ADDRESS && !stop) {
            right[tier2b] = myWalletAddress;
            refAddress[myWalletAddress] = tier2b;
            address aboveL1 = refAddress[userWalletAddress];
            if (aboveL1 != NULL_ADDRESS) { inMyCycle[aboveL1]++; }
            inMyCycle[userWalletAddress]++;
            inMyCycle[tier2b]++;
            getInType[counter] = 2;
            stop = true;
          }
          if (left[tier3a] == NULL_ADDRESS && !stop) {
            left[tier3a] = myWalletAddress;
            refAddress[myWalletAddress] = tier3a;
            inMyCycle[userWalletAddress]++;
            inMyCycle[tier2a]++;
            inMyCycle[tier3a]++;
            getInType[counter] = 3;
            stop = true;
          }
          if (left[tier3b] == NULL_ADDRESS && !stop) {
            left[tier3b] = myWalletAddress;
            refAddress[myWalletAddress] = tier3b;
            inMyCycle[userWalletAddress]++;
            inMyCycle[tier2b]++;
            inMyCycle[tier3b]++;
            getInType[counter] = 3;
            stop = true;
          }
          if (left[tier3c] == NULL_ADDRESS && !stop) {
            left[tier3c] = myWalletAddress;
            refAddress[myWalletAddress] = tier3c;
            inMyCycle[userWalletAddress]++;
            inMyCycle[tier2a]++;
            inMyCycle[tier3c]++;
            getInType[counter] = 3;
            stop = true;
          }
          if (left[tier3d] == NULL_ADDRESS && !stop) {
            left[tier3d] = myWalletAddress;
            refAddress[myWalletAddress] = tier3d;
            inMyCycle[userWalletAddress]++;
            inMyCycle[tier2b]++;
            inMyCycle[tier3d]++;
            getInType[counter] = 3;
            stop = true;
          }
          if (right[tier3a] == NULL_ADDRESS && !stop) {
            right[tier3a] = myWalletAddress;
            refAddress[myWalletAddress] = tier3a;
            inMyCycle[userWalletAddress]++;
            inMyCycle[tier2a]++;
            inMyCycle[tier3a]++;
            getInType[counter] = 3;
            stop = true;
          }
          if (right[tier3b] == NULL_ADDRESS && !stop) {
            right[tier3b] = myWalletAddress;
            refAddress[myWalletAddress] = tier3b;
            inMyCycle[userWalletAddress]++;
            inMyCycle[tier2b]++;
            inMyCycle[tier3b]++;
            getInType[counter] = 3;
            stop = true;
          }
          if (right[tier3c] == NULL_ADDRESS && !stop) {
            right[tier3c] = myWalletAddress;
            refAddress[myWalletAddress] = tier3c;
            inMyCycle[userWalletAddress]++;
            inMyCycle[tier2a]++;
            inMyCycle[tier3c]++;
            getInType[counter] = 3;
            stop = true;
          }
          if (right[tier3d] == NULL_ADDRESS && !stop) {
            right[tier3d] = myWalletAddress;
            refAddress[myWalletAddress] = tier3d;
            inMyCycle[userWalletAddress]++;
            inMyCycle[tier2b]++;
            inMyCycle[tier3d]++;
            getInType[counter] = 3;
            stop = true;
          }
        }
    }

    function setTiersToNull(address walletAddress) internal {
        address tier1a = left[walletAddress];
        address tier1b = right[walletAddress];
        left[walletAddress] = NULL_ADDRESS;
        right[walletAddress] = NULL_ADDRESS;
        refAddress[tier1a] = NULL_ADDRESS;
        refAddress[tier1b] = NULL_ADDRESS;
        refAddress[walletAddress] = NULL_ADDRESS;
        inMyCycle[walletAddress] = 0;
        uint256 tmpCounter = order_rev[walletAddress];
        order[tmpCounter] = NULL_ADDRESS;
        order_rev[walletAddress] = 0;
        inMyCycle[walletAddress] = 0;
    }

    function getMyCycleNumber(address account) public view returns(uint256) {
        return inMyCycle[account];
    }

    function getLeftLeg(address account) public view returns(address) {
        return left[account];
    }

    function getRightLeg(address account) public view returns(address) {
        return right[account];
    }

    function getWhoReferredMe(address account) public view returns(address) {
        return refAddress[account];
    }

    function getGetIn(uint256 number) public view returns(address) {
        return getIn[number];
    }

    function getGetOut(uint256 number) public view returns(address) {
        return getOut[number];
    }

    function getGetInType(uint256 number) public view returns(uint256) {
        return getInType[number];
    }

    function getSalvation(uint256 number) public view returns(bool) {
        return salvation[number];
    }

    function getAddressFinished(address account) public view returns(uint256) {
        return addressFinished[account];
    }

}