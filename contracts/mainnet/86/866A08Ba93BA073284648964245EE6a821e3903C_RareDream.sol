/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//#####(#((###(###################(#####(((((###((((#(##((##(########(#((####((###
//####(((######(#(#########(((######(#(#########(((####(##(#########(#((@@#%@#####
//#(###((###(((##############(###(((########(####((((((#(#(######(###(&#@@##@%####
//###(#(((##(#######(#######(##(#(##(#(#######((#((((#####(##(####(#((####(#######
//###((#(###############(########((# (######..###(   ((######(#####(#######(######
//#(#(##(#####################.##/.(####(######(##(((#.(((##(####(#(#########(####
//###((#(#################(##/#./(#((######(#####(####(((#(########(##(#(##(((####
//##((###############(### (###  #(########(#((######((## .(##(#############(######
//#########(##(#(##### .######     (.#### ########(##(((((## /############(#(#(###
//##########(#(##((##. ##########(#( #(## ###########(#((#((# ####################
//####(#(#((#((######, ## ##.#%##(((# ##(, # ,##((((.#(,####  ########(###########
//#######((############.#.##.#.(.(##((  (##  ,  .(#(((.##/##.( ###################
//#(#(#(#####((#(######.#.##.# #%.#(########((((((####(.#.####.##(##########(#(###
//(########(##(((######@@@ ##.###(#((#@#####&&@&####(##,##@&%############(##(#####
//##(###(#(((###((####@%%#,(#######@@%#####%%%%%%#%######,#%%###########(((#######
//((#####(###((########(@%##########%@#####%%%##%@#%#### .%@@###(####(#(###((#####
//#########((#####(#######@####(##########@%@####(#####(##@@#(###########(########
//#####((###(((############@###((########&@%@############@####(#######(###(((#####
//####((#((((((######(####(@%%%(#########&&#%%########(%@%##########(((((((((#####
//(####(#(((#(########(####(@%%%%###################@%%&@##(####((###(#(((#(######
//#####(((###(((##(####(#####@@%@%%########@@@@@##%%%%%@(#######(##(##((####((####
//####(######(#((#(#(#######(#%@#%%%##############%%%%#((#######(#(((######(##(#(#
//##########(###((###(###########@@%%#(###########%@################((####((##((##
//######(##########################&@@#######&%@%%@###################((####(#####
//################################(&######((#%%%%%@####((#################(#######
//#########((###############(((#((#@#(##(##(###&%&@((#############################
//#####(###################((((#%(@@##########@#%@%@@@##(###########((############
//#################(#####(((@@@&#######(########%%%#(##@@@%#######(#(#############
//####(######(##(##(####(%@@####((@@@#(##%#@#(((@&@%%((##(###@@@##(((#############
//##@##@@@###((###@@@@@%###%@@#(##(#####(###########(@@@@@@######@@(##(####(######
//#(#&&(&#&###@#(################(##############((###(###(#######(#%@@%###########
//(##%#######@(#(####((#(###(#((((((######((######(((((((#####((#####@@&((((((####

library DateTime {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;

    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract RareDream is Ownable {
    uint public SUBSCRIPTION_PRICE_PREMIUM = 0.038 ether;
    uint public SUBSCRIPTION_PRICE_WHALE = 0.075 ether;

    mapping(address => uint) public subscriptionsPremium;
    mapping(address => uint) public subscriptionsWhale;

    function setPremiumSubscriptionPrice(uint price) 
        onlyOwner 
        public
    {
        SUBSCRIPTION_PRICE_PREMIUM = price;
    }

    function setWhaleSubscriptionPrice(uint price) 
        onlyOwner 
        public
    {
        SUBSCRIPTION_PRICE_WHALE = price;
    }
    
    function getPremiumSubscriptionPrice() 
        public view  
        returns (uint) {
        return SUBSCRIPTION_PRICE_PREMIUM;
    }

    function getWhaleSubscriptionPrice() 
        public view  
        returns (uint) {
        return SUBSCRIPTION_PRICE_WHALE;
    }

    function subscribePremium() 
        public 
        payable
    {
        require(msg.value >= SUBSCRIPTION_PRICE_PREMIUM, "Not enough ethers sent");
        subscriptionsPremium[msg.sender] = DateTime.addDays(block.timestamp, 30);
    }

    function subscribeWhale() 
        public 
        payable
    {
        require(msg.value >= SUBSCRIPTION_PRICE_WHALE, "Not enough ethers sent");
        subscriptionsWhale[msg.sender] = DateTime.addDays(block.timestamp, 30);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _withdraw(owner(), balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}