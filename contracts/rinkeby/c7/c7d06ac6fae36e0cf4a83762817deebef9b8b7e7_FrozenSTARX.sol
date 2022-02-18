//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "./TransferHelper.sol";
import "./SafeMath.sol";

contract FrozenSTARX {

    using SafeMath for uint;

    address private _owner;
    address public token;

    struct Frozen {
        address beneficiary;
        uint256 balance;
    }

    mapping(address => Frozen) public frozens;

    event Freeze(address sender, address beneficiary, uint256 amount);
    event Release(address receiver, uint256 amount);

    constructor(address __token) public {
        token = __token;
        _owner = msg.sender;
    }

    modifier ownerOnly(){
        require(_owner == msg.sender, "caller is not the owner");
        _;
    }

    function freeze(address beneficiary, uint256 amount) public {
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
        frozens[beneficiary].beneficiary = beneficiary;
        frozens[beneficiary].balance = frozens[beneficiary].balance.add(amount);
        emit Freeze(msg.sender, beneficiary, amount);
    }

    function release(address beneficiary, uint256 amount) public ownerOnly() {
        require(frozens[beneficiary].balance > 0, "no tokens to release");
        TransferHelper.safeTransfer(token, beneficiary, amount);
        frozens[beneficiary].balance = frozens[beneficiary].balance.sub(amount);
        emit Release(beneficiary, amount);
    }

}