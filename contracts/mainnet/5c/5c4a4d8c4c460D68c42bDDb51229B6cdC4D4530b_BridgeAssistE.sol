/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IERC20 {
    function mint(address to, uint256 amount) external returns (bool);
    function burnFrom(address from, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
contract BridgeAssistE {
    address public owner;
    IERC20 public TKN;
    IERC20 public STABLE;

    modifier restricted {
        require(msg.sender == owner, "This function is restricted to owner");
        _;
    }
    
    event Collect(address indexed sender, uint256 amount, bool stable);
    event Dispense(address indexed sender, uint256 amount, bool stable);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    function collect(address _sender, uint256 _amount, bool _stable) public restricted returns (bool success) {
        if (_stable) {
            STABLE.transferFrom(_sender, address(this), _amount);
            emit Collect(_sender, _amount, true);
        } else {
            TKN.burnFrom(_sender,  _amount);
            emit Collect(_sender, _amount, false);
        } 
        
        return true;
    }

    function dispense(address _sender, uint256 _amount, bool _stable) public restricted returns (bool success) {
        if (_stable) {
            STABLE.transfer(_sender, _amount);
            emit Dispense(_sender, _amount, true);
        } else {
            TKN.mint(_sender, _amount);
            emit Dispense(_sender, _amount, false);
        }
        
        return true;
    }

    function transferOwnership(address _newOwner) public restricted {
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    constructor(IERC20 _TKN, IERC20 _STABLE) {
        TKN = _TKN;
        STABLE = _STABLE;
        owner = msg.sender;
    }
}