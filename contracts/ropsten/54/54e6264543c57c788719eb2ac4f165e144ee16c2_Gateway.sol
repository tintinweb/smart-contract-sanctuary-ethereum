/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15 <0.9.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Gateway {
    uint256 public chain_id;
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;
    uint256 private status;
    
    event TransferETH(uint256 source_chain_idx, uint256 target_chain_idx, uint256 amount);
    event TransferERC20(uint256 source_chain_idx, uint256 target_chain_idx, address token_address, uint256 amount);

    modifier nonReentrant() {
        require(status != ENTERED, "reentrant call");
        status = ENTERED;
        _;
        status = NOT_ENTERED;
    }

    constructor(uint256 _chain_id) {
        chain_id = _chain_id;
        status = NOT_ENTERED;
    }

    function transferETH(uint256 _target_chain_idx, uint256 _amount) external payable nonReentrant {
        // TODO: check _target_chain_idx
        if (msg.value != _amount) {
            revert("amount error");
        }

        emit TransferETH(chain_id, _target_chain_idx, _amount);
    }

    function transferERC20(uint256 _target_chain_idx, address _token_address, uint256 _amount) external nonReentrant {
        // TODO: check _target_chain_idx
        IERC20 erc20token = IERC20(_token_address);
        assert(erc20token.transferFrom(msg.sender, address(this), _amount));

        emit TransferERC20(chain_id, _target_chain_idx, _token_address, _amount);
    }

    receive() external payable {}

    fallback() external {
        revert("fallback is not allowed");
    }
}