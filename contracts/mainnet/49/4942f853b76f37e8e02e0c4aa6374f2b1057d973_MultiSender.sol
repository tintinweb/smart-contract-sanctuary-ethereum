/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//////////////////////////////////////////////////////////////////////
//        __  ___      ____  _ _____                __              //
//       /  |/  /_  __/ / /_(_) ___/___  ____  ____/ /__  _____     //
//      / /|_/ / / / / / __/ /\__ \/ _ \/ __ \/ __  / _ \/ ___/     //
//     / /  / / /_/ / / /_/ /___/ /  __/ / / / /_/ /  __/ /         //
//    /_/  /_/\__,_/_/\__/_//____/\___/_/ /_/\__,_/\___/_/          //
//     by 0xInuarashi.eth                                           //
//                                                                  //
//////////////////////////////////////////////////////////////////////

interface IERC20 {
    function balanceOf(address address_) external view returns (uint256);
    function transferFrom(address from_, address to_, uint256 amount_) external
    returns (bool);
}

interface IERC721 {
    function ownerOf(uint256 tokenId_) external view returns (address);
    function transferFrom(address from_, address to_, uint256 tokenId_) external;
}

interface IERC1155 {
    function balanceOf(address address_, uint256 tokenId_) external view 
    returns (uint256);

    function safeTransferFrom(address from_, address to_, uint256 tokenId_,
    uint256 amount_, bytes calldata data_) external;
}

contract MultiSender {

    // Internal Functions
    function _sendETH(address payable address_, uint256 amount_) internal {
        (bool success, ) = payable(address_).call{value: amount_}("");
        require(success, "Transfer failed");
    }
    function _calculateTotalAmounts(uint256[] memory amounts_) internal pure
    returns (uint256 _totalAmount) {
        for (uint256 i = 0; i < amounts_.length; i++) {
            _totalAmount += amounts_[i];
        }
    }

    function multiSendETH(address payable[] calldata addresses_, 
    uint256[] calldata amounts_, bool useChecks_) external payable {
        require(addresses_.length == amounts_.length,
            "Array lengths mismatch!");

        // We use loop checks but we can opt out to save gas
        if (useChecks_) {
            // Get the Total Amount
            uint256 _totalAmount = _calculateTotalAmounts(amounts_);

            require(msg.value == _totalAmount,
                "Invalid amount of ETH sent!");
        }

        // Multi-Send the ETHs
        for (uint256 i = 0; i < addresses_.length; i++) {
            _sendETH(addresses_[i], amounts_[i]);
        }
    }

    function multiSendERC20(address erc20_, address[] calldata addresses_,
    uint256[] calldata amounts_, bool useChecks_) external {
        require(addresses_.length == amounts_.length,
            "Array lengths mismatch!");

        // We use loop checks but we can opt out to save gas
        if (useChecks_) {
            // Get the Total Amount
            uint256 _totalAmount = _calculateTotalAmounts(amounts_);

            // Make sure the msg.sender has enough ETH
            require(IERC20(erc20_).balanceOf(msg.sender) >= _totalAmount,
                "msg.sender does not have enough balance!");
        }

        // Multi-Send ERC20s
        for (uint256 i = 0; i < addresses_.length; i++) {
            IERC20(erc20_).transferFrom(msg.sender, addresses_[i], amounts_[i]);
        }
    }

    function multiSendERC721(address erc721_, address[] calldata addresses_,
    uint256[] calldata tokenIds_, bool useChecks_) external {
        require(addresses_.length == tokenIds_.length,
            "Array lengths mismatch!");

        if (useChecks_) {
            for (uint256 i = 0; i < tokenIds_.length; i++) {
                require(msg.sender == IERC721(erc721_).ownerOf(tokenIds_[i]),
                    "You are not the owner of this token!");
            }
        }

        // Multi-Send ERC721s
        for (uint256 i = 0; i < addresses_.length; i++) {
            IERC721(erc721_).transferFrom(msg.sender, addresses_[i], tokenIds_[i]);
        }
    }

    function multiSendERC1155(address erc1155_, address[] calldata addresses_,
    uint256[] calldata tokenIds_, uint256[] calldata amounts_,
    bytes calldata data_) external {
        require(addresses_.length == tokenIds_.length 
            && addresses_.length == amounts_.length,
            "Array lengths mismatch!");

        // No checks for this one.
        for (uint256 i = 0; i < addresses_.length; i++) {
            IERC1155(erc1155_).safeTransferFrom(msg.sender, addresses_[i], tokenIds_[i],
            amounts_[i], data_);
        }
    }

}