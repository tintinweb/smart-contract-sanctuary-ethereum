/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

/**
Moontok.io Ads Payment

Website: https://www.moontok.io
TG Channel: https://t.me/Moontok_Channel
TG Group: https://t.me/Moontok_Group
TG Alert: https://t.me/moontok_listing
Tiktok: https://www.tiktok.com/@moontokofficial
Twitter: http://twitter.com/MoontokOfficial
Email: [email protected]
*/

pragma solidity ^0.6.12;

// SPDX-License-Identifier: Unlicensed

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address payable private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address payable) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

contract MoontokPay is Context, Ownable {
    
    //record
    struct BuyData {
        uint256 coinId;
        uint256 adsType;
        uint256 amount;
    }
    uint256 private currentBuyIndex;
    mapping (uint256 => BuyData) private buyRecord;

    constructor () public {
        currentBuyIndex = 1;
    }
    
    //toplist support
    function getBuyCount() public view returns (uint256) {
        return currentBuyIndex;
    }
    
    function getBuyRecord(uint256 idx) public view returns (uint256, uint256, uint256) {
        require(idx <= currentBuyIndex, "Index out of bounds");
        
        return (buyRecord[idx].coinId, buyRecord[idx].adsType, buyRecord[idx].amount);
    }
    
    function payWithETH(uint256 coinId, uint256 adsType) external payable {
        require(coinId > 0, "Invalid coin ID");
        require(msg.value >= 0.01 ether);
        
        bool success = owner().send(msg.value);
        require(success, "Money transfer failed");
        
        buyRecord[currentBuyIndex] = BuyData(coinId, adsType, msg.value);
        ++currentBuyIndex;
    }
    
     
    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {
         bool success = owner().send(msg.value);
         require(success, "Money transfer failed");
    }
}