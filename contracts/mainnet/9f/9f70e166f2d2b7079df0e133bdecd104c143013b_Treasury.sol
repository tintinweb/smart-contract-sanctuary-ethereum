// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.17;

import "./ERC20.sol";

contract Treasury {
    ERC20 immutable _erc20;
    uint256 _firnSupply;
    address _owner;
    uint256 _startGas;
    uint256 constant _endGas = 100000; // hardcode to save sloads...

    uint256 private _status;
    mapping(address => bool) _skip;

    event Payout(address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner.");
        _;
    }

    constructor(address erc20_) {
        _owner = msg.sender;
        _erc20 = ERC20(erc20_);
    }

    function administrate(address owner_, uint256 startGas_) external onlyOwner {
        _owner = owner_;
        _startGas = startGas_;
    }

    function setSkip(address key, bool value) external onlyOwner {
        _skip[key] = value;
    }

    receive() external payable {

    }

    function payout() external {
        require(gasleft() >= _startGas, "Not enough gas supplied.");
        _firnSupply = _erc20.totalSupply();
        traverse(_erc20.root());
    }

    function traverse(address cursor) internal {
        (,address left,address right,) = _erc20.nodes(cursor);

        if (right != address(0)) {
            traverse(right);
        }
        if (gasleft() < _endGas) {
            return;
        }
        uint256 firnBalance = _erc20.balanceOf(cursor);
        if (!_skip[cursor]) {
            uint256 amount = address(this).balance * firnBalance / _firnSupply;
            bool success = payable(cursor).send(amount);
            if (success) {
                emit Payout(cursor, amount);
            }
        }
        // there is a further attack where someone could try to transfer their own firn balance within their `receive`.
        // the effect of this would be to get paid essentially twice for the same firn (there are other variants of this).
        // to prevent this, we're assuming that 2,300 gas isn't enough to do a FIRN ERC20 transfer.
        _firnSupply -= firnBalance;
        if (left != address(0)) {
            traverse(left);
        }
    }
}