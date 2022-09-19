// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol"; 
import "./Ownable.sol";

contract OptimizedOmnihorse is ERC721A, Ownable {
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

    uint256[] public priceArray;

    address paymentReceiver;

    modifier forSale (uint256 amount_) {
        require(state != 0, "Sale not enabled");
        require(maxSupply >= totalSupply() + amount_, "Insufficent supply");
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
        state = 0;

        priceArray = _priceArray;
    }

    receive() external payable {}

    /**
     * @dev Admin set sale state
     * 0 -> sale closed
     * 1 -> whitelist only
     * 2 -> public sale
     */
    function setState(uint256 _state) public onlyOwner {
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

    function mint() external payable forSale(1) {
        require(msg.value == getPrice(1), "Invalid amount of ETH sent");

        if(freeWl[msg.sender] && state == 1) {
            freeWl[msg.sender] = false;
        }
        _safeMint(msg.sender, 1);
    }

    /**
    * @dev updates an index in priceArray
    * index 0 -> default price
    * index 1 -> whitelist price
    * index 2 -> discount price
    * only indices 0 - 2 are updateable, higher indices are not used
    */
    function setPrice(uint256 index, uint256 newPrice) external onlyOwner {
        priceArray[index] = newPrice;
    }

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
    function setMaxSupply(uint256 maxSupply_) public onlyOwner {
        require(maxSupply_ > maxSupply, "Cannot lower supply");
        maxSupply = maxSupply_;
    }

    /**
     * @dev Set the base URI of the NFT metadata
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
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
    function addToWl(address[] calldata user) external onlyOwner {
        for(uint256 i = 0; i < user.length; i++) {
            wl[user[i]] = true;
        }
    }

    /**
     * @dev adds @param user to free whitelist,
     * getting them a free or discounted mint.
     * Also adds them to the regular whitelist.
     */
    function addToFreeWl(address[] calldata user) external onlyOwner {
        for(uint256 i = 0; i < user.length; i++) {
            freeWl[user[i]] = true;
            wl[user[i]] = true;
        }
    }

    /**
     * @dev removes addresses in array @param user from both wl and freeWl
     */
    function removeFromWL(address[] calldata user) external onlyOwner {
        for(uint256 i = 0; i < user.length; i++) {
            wl[user[i]] = false;
            freeWl[user[i]] = false;
        }
    }

    /**
     * @dev if active, getPrice will check the user's balance of the 
     * promotion token and give them the whitelist price if balance > 0
     */
    function setPromotionActive(bool active) external onlyOwner {
        promotionActive = active;
    }

    /**
     * @dev set the address of the token to be used for whitelist access
     */
    function setPromotionAddress(address promotion) external onlyOwner {
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
     * @dev Uint256 to String as documented in EIP
     *
     * @param _i integer input value
     * @return _uintAsString string output equivalent to uint input
     */
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) { return "0"; }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
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
     * @dev Admin withdraw function
     */
     function withdraw() public onlyOwner {
        (bool success,) = payable(paymentReceiver).call{value: address(this).balance}("");
        require(success, "Receiver rejected ETH transfer");
    }
}