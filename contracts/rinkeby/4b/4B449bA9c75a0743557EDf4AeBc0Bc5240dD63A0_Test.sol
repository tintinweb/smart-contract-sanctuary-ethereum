/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

contract Test is Ownable, ReentrancyGuard  {

    using Strings for uint256;
    
    address payable public issuer; //owner

    uint256 public endDate; //total period duration
    uint256 public q; //duration in days
    uint256 public hh; //harberger hike
    uint256 public ht; //harberger tax
    uint256 public ip; //initial price
    uint256 private currentPrice; //current price
    address public currentOwner; //current owner
    string public v; //sell variable

    bool private _isSlotExtended = false; //state variable to determine if someone already payed in advance

    event SlotPurchased(address buyer, uint256 amount, uint256 enddate);
    event SlotExtended(address payer, uint256 amount, uint256 enddate);
    event SlotTextChanged(address owner, string oldText, string newText);

    //modifier to keep dates and prices updated
    modifier update() {
        //if current date is greater or equals to end date, and no extension has been made, we reset the values
        if(block.timestamp >= endDate && _isSlotExtended == false) {

            //we set the current price as initial price
            currentPrice = ip;

            //we set ownership to contract address
            currentOwner = address(this);

            //we set a new end date
            endDate = block.timestamp+q;
        }
        _;
    }
    
    constructor(uint256 _q, uint256 _hh, uint256 _ht, uint256 _ip) {

        //we set the contract deployer as owner "issuer"
        issuer = payable(msg.sender);

        //we set the duration in days
        q = _q;

        //we set a default end date
        endDate = block.timestamp+q;

        //we set a default  generic message
        v = "Space available for rent";

        //we set the harberger hike
        hh = _hh;

        //we set the harberger tax
        ht = _ht;

        //we set the initial price
        ip = _ip;

        //we set the current price as initial price too
        currentPrice = _ip;
    }

    function purchase() public payable nonReentrant update () {

        uint256 currentPriceCalc = price();
        uint256 buyFromPriceCalc = buyFromPrice();
        
        if(msg.sender == currentOwner) {
            //if buyer is current owner, he is charged with the same amout used for purchase (plus new fees)
            require(msg.value >= currentPriceCalc, "amount has to be greater than the current price");
        }
        else {
            //if buyer is not the owner, then we apply the P1 + (P1*HT) + (P1*HH) formula
            require(msg.value >= buyFromPriceCalc, "amount has to be greater than the current price");

            //we substract each participant shares
            uint256 currentOwnerShare = buyFromPriceCalc-currentPriceCalc;

            //we send the issuer P1*HT
            (bool sentIssuer, ) = payable(issuer).call{ value: currentPriceCalc }("");

            require(sentIssuer, "error in transferring eth to issuer");

            //we send the previous owner the rest P1*HH
            (bool sentPreviousOwner, ) = payable(currentOwner).call{ value: currentOwnerShare }("");

            require(sentPreviousOwner, "error in transferring eth to previous owner");
        }

        //if sender is current owner, and if there's no Q in advance payed already, we pay 1 Q in advance
        if(msg.sender == currentOwner && _isSlotExtended == false) {

            //we set the new end date
            endDate = block.timestamp+q;

            //we fill the global slot to prevent new extensions this period
            _isSlotExtended == true;

            //we flag the new extension as an event
            emit SlotExtended(msg.sender, msg.value, endDate);
        }

        //if current date is greater or equals to end date, and if the users already extended 1 q, we set a new end date for the new period, and enable the extension again
        if(block.timestamp >= endDate && _isSlotExtended == true) {

            //we set the new end date using current date
            endDate = block.timestamp+q;

            //we enable again the extension
            _isSlotExtended == false;
        }

        //we set the new price
        currentPrice = msg.value;

        //we set the sender as current owner
        currentOwner = msg.sender;

        //we flag the new purchase as an event
        emit SlotPurchased(msg.sender, msg.value, endDate);
    } 
    
    //only current owner can change text
    function setText(string memory _v) public {
        require(msg.sender == currentOwner, "only the current owner can perform this");
        
        string memory oldV = v;
        v = _v;

        //we flag the new text as an event
        emit SlotTextChanged(msg.sender, oldV, v);
    }

    //price function which returns P + (P*HT)
    function price() public view returns (uint256 amount) {

        uint256 newCurrentPrice = currentPrice;
        
        if(block.timestamp >= endDate && _isSlotExtended == false) {
            newCurrentPrice = ip;
        }

        amount = (newCurrentPrice*ht)+newCurrentPrice;

        return amount;
    }
    
    //price function which returns P1 + (P1*HT) + (P1*HH)
    function buyFromPrice() public view returns (uint256 amount) {

        uint256 priceCalc = price();

        amount = (priceCalc*hh)+priceCalc;

        return amount;
    }

    function currentBlock() public view returns (uint256 blocky) {

        blocky = block.timestamp;
        blocky += 3 days;
        
        return blocky;
    }
}