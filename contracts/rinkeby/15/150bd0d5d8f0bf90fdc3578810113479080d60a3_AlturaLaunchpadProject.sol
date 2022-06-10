// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./IERC1155.sol";

contract AlturaLaunchpadProject {
    address public owner;
    address[] public buyers;
    mapping(address => uint256) totalAmounts;
    address public creator;
    string public name;

    // events
    event BuyNFT(address collection, uint256 tokenId, uint256 quantity);

    // Initalize project
    function init(
        string memory _name,
        address _creator,
        address _owner
    ) external {
        name = _name;
        creator = _creator;
        owner = _owner;
    }

    // Buy NFT
    function buyNFT(
        address collection,
        uint256 tokenId,
        uint256 quantity,
        address quoteToken,
        uint256 amount
    ) public payable {
        if (quoteToken == address(0)) {
            require(msg.value == amount, "insufficient value");
        } else {
            require(
                IERC20(quoteToken).transferFrom(
                    msg.sender,
                    address(this),
                    amount
                ),
                "failed to transfer ERC20 token"
            );
        }

        IERC1155(collection).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            quantity,
            "0x0"
        );

        buyers.push(msg.sender);
        totalAmounts[msg.sender] += amount;

        emit BuyNFT(collection, tokenId, quantity);
    }

    // Get total amount by address
    function getTotalAmountByAddress(address buyerAddress)
        public
        view
        returns (uint256 totalAmount)
    {
        totalAmount = totalAmounts[buyerAddress];
    }
}