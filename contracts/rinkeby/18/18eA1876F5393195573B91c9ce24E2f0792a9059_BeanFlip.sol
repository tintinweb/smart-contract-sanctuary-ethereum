// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/utils/Context.sol';

contract BeanFlip is Context {
    ////////////////////////////////////////////////////////////////////////////
    // CONSTANT
    ////////////////////////////////////////////////////////////////////////////

    uint256 private constant EGGS_PER_MINER = 1080000;
    uint256 private constant PSN = 10000;
    uint256 private constant PSNH = 5000;
    uint256 private constant DEV_FEE = 3; // 3%

    ////////////////////////////////////////////////////////////////////////////
    // STATE
    ////////////////////////////////////////////////////////////////////////////

    uint256 private marketEggs = 108000000000;
    address payable private immutable treasury;

    mapping(address => uint256) private miners;
    mapping(address => uint256) private claimedEggs;
    mapping(address => uint256) private lastHatchTime;
    mapping(address => address) private referral;

    ////////////////////////////////////////////////////////////////////////////
    // CONSTRUCTOR
    ////////////////////////////////////////////////////////////////////////////

    constructor() {
        treasury = payable(msg.sender);
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC
    ////////////////////////////////////////////////////////////////////////////

    function hatchEggs(address ref) public {
        if (ref == msg.sender) {
            ref = address(0);
        } else if (referral[msg.sender] == address(0)) {
            referral[msg.sender] = ref;
        }

        uint256 eggsUsed = getMyEggs(msg.sender);
        uint256 newMiners = eggsUsed / EGGS_PER_MINER;

        miners[msg.sender] += newMiners;
        claimedEggs[msg.sender] = 0;
        lastHatchTime[msg.sender] = block.timestamp;

        //send referral eggs
        claimedEggs[referral[msg.sender]] =
            claimedEggs[referral[msg.sender]] +
            eggsUsed /
            8;

        //boost market to nerf miners hoarding
        marketEggs += eggsUsed / 5;
    }

    function sellEggs() public {
        uint256 hasEggs = getMyEggs(msg.sender);
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);

        claimedEggs[msg.sender] = 0;
        lastHatchTime[msg.sender] = block.timestamp;
        marketEggs += hasEggs;

        if (fee > 0) {
            (bool sent, ) = treasury.call{value: fee}('');
            require(sent, 'Failed to sent Ether');
        }
        if (eggValue > fee) {
            (bool sent, ) = payable(msg.sender).call{value: eggValue - fee}('');
            require(sent, 'Failed to sent Ether');
        }
    }

    function buyEggs(address ref) public payable {
        uint256 eggsBought = calculateEggBuy(
            msg.value,
            address(this).balance - msg.value
        );
        eggsBought -= devFee(eggsBought);
        uint256 fee = devFee(msg.value);

        if (fee > 0) {
            (bool sent, ) = treasury.call{value: fee}('');
            require(sent, 'Failed to sent Ether');
        }

        claimedEggs[msg.sender] += eggsBought;

        hatchEggs(ref);
    }

    ////////////////////////////////////////////////////////////////////////////
    // VIEW
    ////////////////////////////////////////////////////////////////////////////

    function beanRewards(address adr) public view returns (uint256) {
        uint256 hasEggs = getMyEggs(adr);
        uint256 eggValue = calculateEggSell(hasEggs);
        return eggValue;
    }

    function calculateEggSell(uint256 eggs) public view returns (uint256) {
        return calculateTrade(eggs, marketEggs, address(this).balance);
    }

    function calculateEggBuy(uint256 eth, uint256 contractBalance)
        public
        view
        returns (uint256)
    {
        return calculateTrade(eth, contractBalance, marketEggs);
    }

    function calculateEggBuySimple(uint256 eth) public view returns (uint256) {
        return calculateEggBuy(eth, address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMyMiners(address adr) public view returns (uint256) {
        return miners[adr];
    }

    function getMyEggs(address adr) public view returns (uint256) {
        return claimedEggs[adr] + getEggsSincelastHatchTime(adr);
    }

    function getEggsSincelastHatchTime(address adr)
        public
        view
        returns (uint256)
    {
        uint256 secondsPassed = min(
            EGGS_PER_MINER,
            block.timestamp - lastHatchTime[adr]
        );
        return secondsPassed * miners[adr];
    }

    ////////////////////////////////////////////////////////////////////////////
    /// PRIVATE
    ////////////////////////////////////////////////////////////////////////////

    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) private pure returns (uint256) {
        return (PSN * bs) / (2 * PSNH + (PSN * rs) / rt);
    }

    function devFee(uint256 amount) private pure returns (uint256) {
        return (amount * DEV_FEE) / 100;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}