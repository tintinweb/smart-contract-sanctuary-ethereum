//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract NftMarketV2 {
    struct NftMarket {
        address owners;
        bool isForSelling;
        uint256 price;
    }

    Tokentransfer xnfttoken;

    event payout(address recipient, uint256 amount);

    address public admin;
    uint256 public servicefeepercentage;

    mapping(uint256 => NftMarket) public Nfts;
    mapping(uint256 => uint256) public TokenIdtoPrice;

    constructor(uint256 _servicefeepercentage, address erc20) {
        admin = msg.sender;
        servicefeepercentage = _servicefeepercentage;
        xnfttoken = Tokentransfer(erc20);
    }


    function createNFT(
        uint256 tokenId,
        bool isForSelling,
        uint256 price
    ) public {
        require(Nfts[tokenId].owners == address(0), "token exist");
        Nfts[tokenId] = NftMarket(msg.sender, isForSelling, price);
    }

    function ownerOfNFT(uint256 _tokenId) public view returns (address) {
        return Nfts[_tokenId].owners;
    }

    function putForSale(uint256 _tokenId, uint256 price) public {
        require(Nfts[_tokenId].isForSelling == false, "already for sale");
        Nfts[_tokenId].isForSelling = true;
        TokenIdtoPrice[_tokenId] = price;
        require(price != 0, "price not assigned");
    }

    function buyNFT(uint256 _tokenId, string calldata currency) public payable {
        require(Nfts[_tokenId].owners != address(0), "token doesnt exist");
        require(Nfts[_tokenId].isForSelling == true, "Not for sale");

        if (
            keccak256(abi.encodePacked(currency)) ==
            keccak256(abi.encodePacked("Ether"))
        ) {
            require(msg.value == Nfts[_tokenId].price, "price not met");

            uint256 adminamount = (msg.value * servicefeepercentage) / (100);
            uint256 owneramount = msg.value - adminamount;

            payable(admin).transfer(adminamount);
            emit payout(admin, adminamount);
            payable(Nfts[_tokenId].owners).transfer(owneramount);
            emit payout(Nfts[_tokenId].owners, owneramount);
        } else if (
            keccak256(abi.encodePacked(currency)) ==
            keccak256(abi.encodePacked("Token"))
        ) {
            require(
                Nfts[_tokenId].price <= xnfttoken.balanceOf(msg.sender),
                "Insufficient balance"
            );
           
            uint256 adminamount = (Nfts[_tokenId].price *
                servicefeepercentage) / (100);
            uint256 owneramount = Nfts[_tokenId].price - adminamount;

            xnfttoken.transferToken(msg.sender, admin, adminamount);
            emit payout(admin, adminamount);
            xnfttoken.transferToken(
                msg.sender,
                Nfts[_tokenId].owners,
                owneramount
            );
            emit payout(Nfts[_tokenId].owners, owneramount);
        }
        Nfts[_tokenId].owners = msg.sender;
        Nfts[_tokenId].isForSelling = false;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface Tokentransfer {
    function transferToken (address from,address to, uint amount) external;
    function balanceOf(address account) external returns (uint256);
    function allowance(address owner, address spender) external returns (uint256);
}