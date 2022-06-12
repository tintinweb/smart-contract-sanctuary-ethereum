/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract WithdrawFairly {
    error Unauthorized();
    error ZeroBalance();
    error TransferFailed();

    struct Part {
        address wallet;
        uint256 royaltiesPart;
    }

    Part[] public parts;
    mapping(address => bool) public callers;

    constructor(){
        parts.push(Part(0xecB4278af1379c38Eab140063fFC426f05FEde28, 1000));
        callers[0xecB4278af1379c38Eab140063fFC426f05FEde28] = true;
        parts.push(Part(0xE1580cA711094CF2888716a54c5A892245653435, 2000));
        callers[0xE1580cA711094CF2888716a54c5A892245653435] = true;
        parts.push(Part(0x06DcBa9ef76B9C6a129Df78D55f99989905e5F96, 2800));
        callers[0x06DcBa9ef76B9C6a129Df78D55f99989905e5F96] = true;
        parts.push(Part(0x9d246cA915ea31be43B4eF151e473d6e8Bc892eF, 2172));
        callers[0x9d246cA915ea31be43B4eF151e473d6e8Bc892eF] = true;
        parts.push(Part(0x2af89f045fB0B17Ad218423Cff3744ee25a69845, 2028));
        callers[0x2af89f045fB0B17Ad218423Cff3744ee25a69845] = true;
    }

    function shareETHRoyaltiesPart() external {
        if (!callers[msg.sender])
            revert Unauthorized();
        
        uint256 balance = address(this).balance;
        
        if (balance == 0)
            revert ZeroBalance();

        for (uint256 i; i < parts.length;){
            if (parts[i].royaltiesPart > 0){
                _withdraw(parts[i].wallet, balance * parts[i].royaltiesPart / 10000);
            }

            unchecked {
                i++;
            }
        }
    }

     function shareTokenRoyaltiesPart(address token) external {
        if (!callers[msg.sender])
            revert Unauthorized();

        IERC20 tokenContract = IERC20(token);
        
        uint256 balance = tokenContract.balanceOf(address(this));
        
        if (balance == 0)
            revert ZeroBalance();

        for (uint256 i; i < parts.length;){
            if (parts[i].royaltiesPart > 0){
                if (!tokenContract.transfer(parts[i].wallet, balance * parts[i].royaltiesPart / 10000))
                    revert TransferFailed();
            }

            unchecked {
                i++;
            }
        }
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        
        if (!success)
            revert TransferFailed();
    }

    receive() external payable {}

}