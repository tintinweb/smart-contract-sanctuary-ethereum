// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error CoffeeShop__WithdrawFailed();
error CoffeeShop__NotOwner();

interface CoffeeNFTs {
    function mintNft(address) external returns (uint256);
}

contract CoffeeShop {
    CoffeeNFTs CoffeeNfts;

    event CoffeeBought(address indexed buyer, uint256 indexed tokenId);

    // 0.005 ETH
    uint256 private constant COFFEE_PRICE = 5000000000000000;
    address private immutable i_owner;
    address private receiptContract;

    ///////////////
    // Modifiers //
    ///////////////

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert CoffeeShop__NotOwner();
        _;
    }

    ///////////////
    // Constructor //
    ///////////////

    constructor() {
        i_owner = msg.sender;
    }

    /////////////////////
    // Main Functions //
    /////////////////////

    /*
     * @notice Method purchasing a coffee and receiving the receipt nft
     */
    function buyCoffee() external payable {
        require(msg.value >= COFFEE_PRICE, "You need to spend more ETH!");
        uint256 tokenId = CoffeeNfts.mintNft(msg.sender);
        emit CoffeeBought(msg.sender, tokenId);
    }

    /*
     * @notice Method for withdrawing the funds from this contract
     */
    function withdrawMoney() external onlyOwner {
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!callSuccess) {
            revert CoffeeShop__WithdrawFailed();
        }
    }

    /////////////////////
    // Setter Functions //
    /////////////////////

    /*
     * @notice Method setting the address of the CoffeeNFT receipt contract
     * @param receiptContract_: Address of the CoffeeNFT receipt contract
     */
    function setRecieptContract(address receiptContract_) external onlyOwner {
        CoffeeNfts = CoffeeNFTs(receiptContract_);
    }

    /////////////////////
    // Getter Functions //
    /////////////////////

    function getCoffeePrice() public pure returns (uint256) {
        return COFFEE_PRICE;
    }

    // function getReceiptContract() public view returns (uint256) {
    //     return CoffeeNft.address;
    // }
}