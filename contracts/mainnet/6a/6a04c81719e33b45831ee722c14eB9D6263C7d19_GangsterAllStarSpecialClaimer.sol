/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//////////////////////////////////////////////////////////////////////////////
//    _____                   __            ___   ____  ______              //
//   / ___/__ ____  ___ ____ / /____ ____  / _ | / / / / __/ /____ _____    //
//  / (_ / _ `/ _ \/ _ `(_-</ __/ -_) __/ / __ |/ / / _\ \/ __/ _ `/ __/    //
//  \___/\_,_/_//_/\_, /___/\__/\__/_/   /_/ |_/_/_/ /___/\__/\_,_/_/       //
//                /___/                                                     //
//     ____             _      __                                           //
//    / __/__  ___ ____(_)__ _/ /                                           //
//   _\ \/ _ \/ -_) __/ / _ `/ /                                            //
//  /___/ .__/\__/\__/_/\_,_/_/                                             //
//     /_/                                                                  //
//                                                                          //
//   Claimer by: 0xInuarashi                                                //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

 abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;
    constructor() { 
        owner = msg.sender; 
        emit OwnershipTransferred(address(0), msg.sender);
    }
    modifier onlyOwner { 
        require(owner == msg.sender, "onlyOwner not owner!");
        _; 
    }
    function transferOwnership(address new_) external onlyOwner {
        address _old = owner;
        owner = new_;
        emit OwnershipTransferred(_old, new_);
    }
}

interface ERC1155TokenReceiver {
    function onERC1155Received(address operator_, address from_, uint256 id_,
        uint256 amount_, bytes calldata data_) external returns (bytes4);
    function onERC1155BatchReceived(address operator_, address from_,
        uint256[] calldata ids_, uint256[] calldata amounts_, bytes calldata data_)
        external returns (bytes4);
}

interface IERC1155 {
    function safeTransferFrom(address from_, address to_, uint256 id_, uint256 amount_,
        bytes memory data_) external;
}

contract GangsterAllStarSpecialClaimer is Ownable { 

    event TokenClaimed(uint256 indexed tokenBefore, uint256 tokenAfter);
    event TokenWithdrawn(address indexed to, uint256 indexed tokenId, uint256 amt);

    address public constant GAS_SPECIAL = 0xB36698c7f5147AAc7F68B58eBbe905381b523C6f;

    uint256 public constant OLD_DUANG_TOKEN_ID = 8;
    uint256 public constant MAX_DUANG_TOKEN = 24;
    uint256 public mut_currDuangToken = 15;

    uint256 public constant OLD_SANTA_TOKEN_ID = 13;
    uint256 public constant MAX_SANTA_TOKEN = 29;
    uint256 public mut_currSantaToken = 25;

    // Receive ERC1155s
    // Note: This contract will be the owner of [15-29] tokens
    function onERC1155Received(address operator_, address from_, uint256 id_,
    uint256 amount_, bytes calldata data_) external returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }
    function onERC1155BatchReceived(address operator_, address from_,
    uint256[] calldata ids_, uint256[] calldata amounts_, bytes calldata data_)
    external returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }

    // Trade-in non 1/1s for 1/1s
    function tradeInSpecial(uint256 tokenId_) external {
        require(tokenId_ == OLD_DUANG_TOKEN_ID || 
                tokenId_ == OLD_SANTA_TOKEN_ID,
                "Token not trade-in able!");

        uint256 _tokenAfter;

        // Take the non 1/1 token from msg.sender
        IERC1155(GAS_SPECIAL).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId_,
            1,
            ""
        );

        if (tokenId_ == OLD_DUANG_TOKEN_ID) {
            require(mut_currDuangToken <= MAX_DUANG_TOKEN,
                    "Maximum trade-in reached for duang!");

            // Send the 1/1 token to the msg.sender
            IERC1155(GAS_SPECIAL).safeTransferFrom(
                address(this), 
                msg.sender, 
                mut_currDuangToken, // send then increment sstore
                1, 
                ""
            );

            _tokenAfter = mut_currDuangToken;
            
            mut_currDuangToken++;
        }

        else if (tokenId_ == OLD_SANTA_TOKEN_ID) {
            require(mut_currSantaToken <= MAX_SANTA_TOKEN,
                    "Maximum trade-in reached for santa!");

            IERC1155(GAS_SPECIAL).safeTransferFrom(
                address(this),
                msg.sender,
                mut_currSantaToken, // send then increment sstore
                1,
                ""
            );

            _tokenAfter = mut_currSantaToken;

            mut_currSantaToken++;
        }

        else revert ("Trade-in token error!"); // sanity check

        emit TokenClaimed(tokenId_, _tokenAfter);
    }

    // Ownable rescue
    function O_withdrawTokens(address to_, uint256[] calldata tokenIds_,
    uint256[] calldata amounts_) external onlyOwner {
        require(tokenIds_.length == amounts_.length,
                "Array lengths mismatch!");

        for (uint256 i = 0; i < tokenIds_.length; i++) {
            IERC1155(GAS_SPECIAL).safeTransferFrom(
                address(this), 
                to_, 
                tokenIds_[i], 
                amounts_[i], 
                ""
            );

            emit TokenWithdrawn(to_, tokenIds_[i], amounts_[i]);
        }
    }
}