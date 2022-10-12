// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev this contract builds off of previous Omnihorse contracts.
 * 
 * While functions mint() and batchMint() can retain the same frontend implementation, price and state logic behave differently.
 * 
 * For example, instead of multiple boolean values, the state is managed by a single integer value, called "state".
 * The state can be updated in the setState() function. Details about which states correspond to which integer values can be found
 * above the setState function.
 * 
 * Price is now handled in an array of integers, called priceArray. There can only be three indices of priceArray (0 - 2).
 * The zero index of priceArray is the public price,
 * The one index of priceArray is the whitelist price,
 * The two index of priceArray is the discount price.
 * When deploying the contract, this array is initialized in the constructor via @param _priceArray.
 * When updating priceArray, @dev must specify the index to change along with the new price. See setPrice() for further details.
 */

import "../ERC721A.sol"; 
import "../Ownable.sol";
import "../IERC20.sol"; 

contract OmnihorseWithERC20 is ERC721A, Ownable {

    IERC20 public OMH;
    uint256 public priceInOMH;

    // 0 = !saleEnabled
    // 1 = wlSale
    // 2 = defaultSale (public sale)
    uint256 public state;

    IERC721A public promotionToken;
    address public promotionAddress;
    bool public promotionActive;

    uint256 private maxSupply;

    mapping(address => bool) public wl;
    mapping(address => bool) public freeWl;

    mapping(address => bool) private admin;

    uint256[] public priceArray;

    address paymentReceiver;

    /**
     * @dev blocks mint txs if state is 0 or maxSupply would be exceeded
     */
    modifier forSale (uint256 amount_) {
        require(state != 0, "Sale not enabled");
        require(maxSupply >= totalSupply() + amount_, "Insufficent supply");
      _;
    }

    modifier onlyAdmin() {
        require(admin[_msgSender()] || _msgSender() == owner(), "Admin: caller is not admin");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address paymentReceiver_ ,
        uint256[] memory _priceArray
        ) ERC721A(name_, symbol_) {
        URI = baseURI_;
        maxSupply = 100;
        paymentReceiver = paymentReceiver_;

        // state initialized as closed
        state = 0;

        admin[_msgSender()] = true;

        priceArray = _priceArray;
    }

    receive() external payable {}

    /**
     * @dev Admin set sale state
     * 0 -> sale closed
     * 1 -> whitelist only
     * 2 -> public sale
     */
    function setState(uint256 _state) public onlyAdmin {
        state = _state;
    }

    /**
     * @dev Batch mint consecutive NFTs to the sender wallet
     * Compiles the price of NFTs to be minted using the getPrice function
     */
    function batchMint(uint256 amount_) forSale(amount_) external payable {
        require(msg.value == getPrice(amount_), "Invalid amount of ETH sent");
        
        if(freeWl[msg.sender] && state == 1) {
            freeWl[msg.sender] = false;
        }

        _safeMint(msg.sender, amount_);
    }

    /**
     * @dev mint a single NFT to the sender wallet
     * Compiles the price of NFT to be minted using the getPrice function
     */
    function mint() external payable forSale(1) {
        require(msg.value == getPrice(1), "Invalid amount of ETH sent");

        if(freeWl[msg.sender] && state == 1) {
            freeWl[msg.sender] = false;
        }

        _safeMint(msg.sender, 1);
    }

    /**
     * @dev function returns the price in OMH tokens to be charged to user before minting
     */
    function getPriceInOMH(uint256 amount_) public view returns(uint256) {
        return priceInOMH * amount_;
    }

    /**
     * @dev user pays in OMH tokens to mint an NFT
     * @notice user will need to approve this contract as spender in 
     * OMH token contract, using the 'approve' function
     */
    function mintWithOMH(uint256 amount_) forSale(amount_) external {
        require(priceInOMH > 0, "Price in OMH not set");
        require(OMH.allowance(_msgSender(), address(this)) > getPriceInOMH(amount_), "Must approve contract to spend OMH first");
        
        bool success = OMH.transferFrom(_msgSender(), address(this), getPriceInOMH(amount_));
        require(success, "Failed transfer");
        _safeMint(_msgSender(), amount_);
    }

    /**
    * @dev updates an index in priceArray
    * index 0 -> default price
    * index 1 -> whitelist price
    * index 2 -> discount price
    * only indices 0 - 2 are updateable, higher indices are not used
    */
    function setPrice(uint256 index, uint256 newPrice) external onlyAdmin {
        priceArray[index] = newPrice;
    }

    /**
     * @dev returns the price @param user should be charged for @param amount_ NFTs
    */
    function getPriceOnly(address user, uint256 amount_) public view returns(uint256) {
        if(state == 1) {
            if(freeWl[user]) {
                return --amount_ * priceArray[1] + priceArray[2];
            }

            if(wl[user] || (promotionActive && promotionToken.balanceOf(user) > 0)) {
                return amount_ * priceArray[1];
            }
        }
        return amount_ * priceArray[0];
    }

    /**
     * @dev returns the price a user should be charged for amount_ NFTs
    */
    function getPrice(uint256 amount_) internal view returns(uint256) {
        if(state == 1) {
            if(freeWl[msg.sender]) {
                return --amount_ * priceArray[1] + priceArray[2];
            }

            if(wl[msg.sender] || (promotionActive && promotionToken.balanceOf(msg.sender) > 0)) {
                return amount_ * priceArray[1];
            }

            /**
             * @dev if no return is triggered, msg.sender is not whitelisted
             */
            revert('whitelist only');
        }
        return amount_ * priceArray[0];
    }

    /**
     * @dev Get address who recieves payment from mints
    */
    function getPaymentReceiver() external view returns(address) { return paymentReceiver; }

    /**
     * @dev Increase the number of tokens avalible to mint
     */
    function setMaxSupply(uint256 maxSupply_) public onlyAdmin {
        require(maxSupply_ > maxSupply, "Cannot lower supply");
        maxSupply = maxSupply_;
    }

    /**
     * @dev Set the base URI of the NFT metadata
     */
    function setBaseURI(string memory baseURI_) public onlyAdmin {
        URI = baseURI_;
    }

    /**
     * @dev Set address who recieves payment from mints
     */
    function setPaymentReceiver(address account_) public onlyOwner {
        require(account_ != address(0), "Cannot set zero address");
        paymentReceiver = account_;
    }

    /**
     * @dev adds users to whitelist
     * gets them the whitelist price -> priceArray[1]
     */
    function addToWl(address[] calldata user) external onlyAdmin {
        for(uint256 i = 0; i < user.length; i++) {
            wl[user[i]] = true;
        }
    }

    /**
     * @dev adds @param user to free whitelist,
     * getting them a free or discounted mint.
     * Also adds them to the regular whitelist.
     */
    function addToFreeWl(address[] calldata user) external onlyAdmin {
        for(uint256 i = 0; i < user.length; i++) {
            freeWl[user[i]] = true;
            wl[user[i]] = true;
        }
    }

    /**
     * @dev removes addresses in array @param user from both wl and freeWl
     */
    function removeFromWL(address[] calldata user) external onlyAdmin {
        for(uint256 i = 0; i < user.length; i++) {
            wl[user[i]] = false;
            freeWl[user[i]] = false;
        }
    }

    /**
     * @dev if active, getPrice will check the user's balance of the 
     * promotion token and give them the whitelist price if balance > 0
     */
    function setPromotionActive(bool active) external onlyAdmin {
        promotionActive = active;
    }

    /**
     * @dev set the address of the token to be used for whitelist access
     */
    function setPromotionAddress(address promotion) external onlyAdmin {
        promotionAddress = promotion;
        promotionToken = IERC721A(promotion);
    }

    /**
     * @dev Batch mint to owner
     */
    function reserveGiveaway(uint256 amount_) public onlyOwner {
        require(amount_ > 0, "Cannot mint zero");
        require(maxSupply >= totalSupply() + amount_, "Insufficent supply");
        _safeMint(msg.sender, amount_);
    }

    /**
     * @dev Admin can burn token
     *
     * @param _contract address representing the previous owner of the given token ID
     * @param _to target address that will receive the tokens
     * @param _amount uint256 ID of the token to be transferred
     */
    function burnTokens(address _contract, address _to, uint256 _amount) external onlyOwner {
        bytes memory payload = abi.encodeWithSignature("transferFrom(address, address, uint256)", address(this), _to, _amount);
        (bool success, ) = _contract.call(payload);
        require(success);
    }

    /**
     * @dev Owner withdraw function
     */
     function withdraw() public onlyOwner {
        (bool success,) = payable(paymentReceiver).call{value: address(this).balance}("");
        require(success, "Receiver rejected ETH transfer");
    }

    /**
     * @dev function for owner to add new wallet with admin permissions 
     */
    function setAdmin(address _admin, bool approved) external onlyOwner {
        admin[_admin] = approved;
    }

    /**
     * @dev function for owner to set the address of OMH ERC20 token
     * to be used for payments in the mintWithOMH function
     */
    function setOMH(address _omh) external onlyOwner {
        OMH = IERC20(_omh);
    }

    /**
     * @dev function for owner to set the price to be charged when users
     * are paying in OMH tokens.
     * @notice OMH token (like most ERC20 tokens) has 18 decimals. 
     * So whatever number of whole OMH tokens you want to charge should be 
     * multiplied by 10^18 => the result will be @param price.
     * 
     * For example, if you want to charge 50 $OMH for each NFT, the price will be
     * 50 * 10^18 => 50000000000000000000
     */
    function setPriceInOMH(uint256 price) external onlyOwner {
        priceInOMH = price;
    }

    function withdrawOMH() external onlyOwner {
        OMH.transfer(paymentReceiver, OMH.balanceOf(address(this)));
    }
}