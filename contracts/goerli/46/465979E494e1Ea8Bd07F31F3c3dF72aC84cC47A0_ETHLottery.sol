// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "@franknft.eth/erc721-f/contracts/utils/Payable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ETHLottery is Ownable, Payable {
    uint256 public ticketPrice = 0.001 ether;
    uint256 public currentLotteryId = 1;
    uint256 public cap = 125 ether;
    uint256 public devPayout;
    uint256 public constant MAX_PURCHASE = 1001; // set 1 to high to avoid some gas
    address private dev1 = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    address private dev2 = 0x3Faa2705080657AfEDe5cD42F5011f2b6FdD4273;
    address private operator;
    mapping(uint256 => LotteryStruct) public lotteries; // key is the lotteryId

    // State Variables
    struct LotteryStruct {
        uint256 lotteryId;
        uint256 totalSupply;
        uint256 activePlayers;
        bool isActive;
        mapping(address => uint256) balances;
        mapping(uint256 => address) owners;
        mapping(address => bool) winners;
        address winner1;
        address winner2;
        address winner3;
    }

    constructor() {
        lotteries[currentLotteryId].lotteryId = currentLotteryId;
        operator = msg.sender;
    }

    modifier lotteryActive() {
        require(
            lotteries[currentLotteryId].isActive,
            "Lottery is not currently active."
        );
        _;
    }

    modifier onlyOperator(){
        require(msg.sender == operator || msg.sender==owner(),"Frobidden.");
        _;
    }

    /**
     * Dev Address, this will change the DEV1 or DEV2 payout address, but can only be called by that specific dev.
     */
    function setDevAddress(address newWallet) public {
        if(msg.sender==dev1){
            dev1=newWallet;
        }else if (msg.sender==dev2){
            dev2=newWallet;
        } else {
            revert("Not allowed.");
        } 
    }  

    /**
     * Set price
     */
    function setPrice(uint256 price) public onlyOwner {
        ticketPrice = price;
    }

    /**
     * ADD more to the set cap
     */
    function setCap(uint256 value) public onlyOwner {
        cap += value;
    }

    function startLottery() external onlyOwner {
        lotteries[currentLotteryId].isActive = true;
    }

    /**
     * This is an emergency function to close down the contract, should not be used by the frontend at any time!
     */
    function stopLottery() external onlyOwner lotteryActive {
        lotteries[currentLotteryId].isActive = false;
    }

    /**
     * Buy lotery tickets here... will return the ETH, if the lottery is closed.
     */
    function mintLotteryTickets() external payable lotteryActive {
        require(
            msg.value >= ticketPrice,
            "Lottery:ETH send lower then ticket price."
        );
        uint256 numEntries = msg.value / ticketPrice;
        require(
            lotteries[currentLotteryId].balances[msg.sender] + numEntries <
                MAX_PURCHASE,
            "Lottery:Trying to buy too many tickets."
        );
        if (lotteries[currentLotteryId].balances[msg.sender] == 0) {
            // new player
            lotteries[currentLotteryId].activePlayers += 1;
        }
        // a loop to "mint" the lottery tickets
        uint256 supply = lotteries[currentLotteryId].totalSupply;
        for (uint256 i; i < numEntries; ) {
            lotteries[currentLotteryId].owners[supply + i] = msg.sender;
            unchecked {
                i++;
            }
        }
        lotteries[currentLotteryId].balances[msg.sender] += numEntries;
        lotteries[currentLotteryId].totalSupply += numEntries;
    }

    /**
     * Will:
     * Close the Lottery, so nobody can enter anymore.
     * Draw 3 winners, and pay them
     * Pay the team
     * Reset the contract, for next operation
     * start the new Lottery
     */
    function performRaffle() external onlyOwner lotteryActive {
        uint256 supply = lotteries[currentLotteryId].totalSupply;
        require(
            lotteries[currentLotteryId].activePlayers > 3,
            "Lottery:Not enough players to perform the raffle."
        );
        uint256 balance = address(this).balance;
        lotteries[currentLotteryId].isActive = false; // closing
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.difficulty, balance, supply))
        ) % supply;
        address winner1 = findWinner(randomNumber);

        randomNumber =
            uint256(keccak256(abi.encodePacked(block.difficulty, winner1))) %
            supply;
        address winner2 = findWinner(randomNumber);

        randomNumber =
            uint256(keccak256(abi.encodePacked(block.difficulty, winner2))) %
            supply;
        address winner3 = findWinner(randomNumber);

        _withdraw(winner1, (balance * 50) / 100);
        _withdraw(winner2, (balance * 29) / 100);
        _withdraw(winner3, (balance * 19) / 100);

        lotteries[currentLotteryId].winner1=winner1;
        lotteries[currentLotteryId].winner2=winner2;
        lotteries[currentLotteryId].winner2=winner3;

        if (devPayout < cap) {
            _withdraw(dev1, balance / 200);
            _withdraw(dev2, balance / 200);
            devPayout += balance / 100;
        }
        _withdraw(owner(), address(this).balance);

        // automaticly start a NEW lottery
        currentLotteryId += 1;
        lotteries[currentLotteryId].lotteryId = currentLotteryId;
        lotteries[currentLotteryId].isActive = true;
    }

    // will pick the owner of ticket 'randomIndex' as winner, if he was already an owner, it will pick the next one from the list
    function findWinner(uint256 randomIndex) internal returns (address) {
        uint256 supply = lotteries[currentLotteryId].totalSupply;
        address winner = ownerOf(randomIndex % supply);
        while (lotteries[currentLotteryId].winners[winner]) {
            randomIndex += 1;
            winner = ownerOf(randomIndex % supply);
        }
        lotteries[currentLotteryId].winners[winner] = true;
        return winner;
    }
    //////////////////////////////////////////////////
    //                                              //
    // Some read only functions for the frontend.   //
    //                                              //
    //////////////////////////////////////////////////

    /**
     * Gives the winner 1 of a lottery for a specific LotteryID
     */
    function winner1Address(uint256 lotteryId) public view returns (address) {
        return lotteries[lotteryId].winner1;
    }
    /**
     * Gives the winner 2 of a lottery for a specific LotteryID
     */
    function winner2Address(uint256 lotteryId) public view returns (address) {
        return lotteries[lotteryId].winner2;
    }
    /**
     * Gives the winner 3 of a lottery for a specific LotteryID
     */
    function winner3Address(uint256 lotteryId) public view returns (address) {
        return lotteries[lotteryId].winner3;
    }
    /**
     * Gives the owner of a tickets for a specific ticketID, for the current Lottery
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        require(
            tokenId < lotteries[currentLotteryId].totalSupply,
            "Lottery: invalid ticket ID"
        );
        address owner = lotteries[currentLotteryId].owners[tokenId];
        require(owner != address(0), "Lottery: invalid ticket ID");
        return owner;
    }

    /**
     * Gives the amount of Tickets for a wallet, for the current Lottery
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        require(
            owner != address(0),
            "Lottery: address zero is not a valid owner"
        );
        return lotteries[currentLotteryId].balances[owner];
    }

    /**
     * Gives the amount of ETH in the contract
     */
    function ethBalance() public view virtual returns (uint256) {
        return address(this).balance;
    }


    /**
     * Gives the number of Players in the current Lottery
     */
    function players() public view virtual returns (uint256) {
        return lotteries[currentLotteryId].activePlayers ;
    }

    /**
     * Gives the number of Tickets in the current Lottery
     */
    function totalSupply() public view virtual returns (uint256) {
        return lotteries[currentLotteryId].totalSupply ;
    }  

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

abstract contract Payable {
    /**
    * Helper method to allow ETH withdraws.
    */
    function _withdraw(address _address, uint256 _amount) internal {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to withdraw Ether");
    }

    // contract can recieve Ether
    receive() external payable { }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}