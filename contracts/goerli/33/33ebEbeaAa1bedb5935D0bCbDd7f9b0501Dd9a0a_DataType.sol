/**
 *Submitted for verification at Etherscan.io on 2023-02-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
contract DataType {
    int public i;
    uint public ui;
    bool public b;
    address public addr;
    uint private uiPrivate;
    uint internal uiInternal;
    uint public constant UI_CONSTANT = 6;
    function setI(int _i) public {
       i = _i;
    }
    function setUi(uint _ui) public {
        uint _localU = 6;
        ui = _ui + _localU;
    }
    function setB(bool _b) public {
        b = _b;
    }
    function setAddr() public {
        addr = msg.sender;
    }
    function setUiPrivate(uint _uiPrivate) public {
        uiPrivate = _uiPrivate;
    }  
    function getUiPrivate() public view returns (uint) {
        return uiPrivate;
    }
    function setUiInternal(uint _uiInternal) public {
        uiInternal = _uiInternal;
    }  
    function getUiInternal() public view returns (uint) {
        return uiInternal;
    } 
}