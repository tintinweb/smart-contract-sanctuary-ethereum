// SPDX-License-Identifier: MIT License


pragma solidity ^0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


interface iSabi {
    function balanceOf(address address_) external view returns (uint); 
    function transferFrom(address from_, address to_, uint amount) external returns (bool);
    function burn(uint amount) external;
}

contract WLMarketplace is ReentrancyGuard {

    address public owner;
    address[] public players;
    
    uint256 public ticketPrice = 20000000000000000000; // 20ETH
    uint256 public drawId;
	uint256 public maxTicketsPerTx = 1; // 10 before
    
    bool public drawLive = false;

    mapping (uint => address) public pastDraw;
    mapping (address => uint256) public userEntries;

    /* NEW mapping */
    mapping (uint => address) public whitelistBuyers;
    mapping (uint => mapping (uint => address)) public allocToWhitelistBuyer;
    struct SaleItem {
        uint16 totalSlots;
        uint16 boughtSlots;
        bool isActive;
        uint256 itemPrice;
        address[] buyers;
    }
    mapping (uint => SaleItem) public idToSaleItem;
    mapping (address => uint) public lastBuyTime;
    //

    constructor() {
        owner = msg.sender;
        drawId = 1;
    }

    address public sabiAddress;
    iSabi public Sabi;
    function setSabi(address _address) external onlyOwner {
        sabiAddress = _address;
        Sabi = iSabi(_address);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /*  ======================
        |---Entry Function---|
        ======================
    */

    function buyWL(uint256 _numOfTickets, uint _id) public payable nonReentrant {
        // uint256 totalTicketCost = ticketPrice * _numOfTickets;
        // require(Sabi.balanceOf(msg.sender) >= ticketPrice * _numOfTickets, "insufficent $SABI");
        // require(drawLive == true, "cannot enter at this time");
        // require(_numOfTickets <= maxTicketsPerTx, "too many per TX");

        // uint256 ownerTicketsPurchased = userEntries[msg.sender];
        // require(ownerTicketsPurchased + _numOfTickets <= maxTicketsPerTx, "only allowed 1 WL");
        // Sabi.burn(msg.sender, totalTicketCost);

        // // player ticket purchasing loop
        // for (uint256 i = 1; i <= _numOfTickets; i++) {
        //     players.push(msg.sender);
        //     userEntries[msg.sender]++;
        // }

        /* NEW Modify */
        require(Sabi.balanceOf(msg.sender) >= idToSaleItem[_id].itemPrice, "insufficent $SABI");
        require(lastBuyTime[msg.sender] + 1 hours < block.timestamp, "last buy time is less than 72 hours");
        require(idToSaleItem[_id].boughtSlots < idToSaleItem[_id].totalSlots, "slots filled for saleItem");
        lastBuyTime[msg.sender] = block.timestamp;
        idToSaleItem[_id].boughtSlots++;
        idToSaleItem[_id].buyers.push(msg.sender);
        Sabi.transferFrom(msg.sender, address(0), idToSaleItem[_id].itemPrice);
    }

    /*  ======================
        |---View Functions---|
        ======================
    */

    //HELPERS
    function getLastBuyTimePlus72Hours(address _buyer) public view returns (uint) {
        return lastBuyTime[_buyer] + 1 hours;
    }

    function buyersOfSaleItem(uint16 _id) public view returns (address[] memory) {
        return idToSaleItem[_id].buyers;
    }

    function getRandom() public view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase)));
        uint index = rand % players.length;
        return index;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function drawEntrys() public view returns (uint) {
        return players.length;
    }

    function getWinnerByDraw(uint _drawId) public view returns (address) {
        return pastDraw[_drawId];
    }

    // Retrieves total entries of players address
    function playerEntries(address _player) public view returns (uint256) {
        address addressOfPlayer = _player;
        uint arrayLength = players.length;
        uint totalEntries = 0;
        for (uint256 i; i < arrayLength; i++) {
            if(players[i] == addressOfPlayer) {
                totalEntries++;
            }
            
        }
        return totalEntries;
    }




    /*  ============================
        |---Owner Only Functions---|
        ============================
    */

    // Salt should be a random number from 1 - 1,000,000,000,000,000
    function pickWinner(uint _firstSalt, uint _secondSalt, uint _thirdSalt, uint _fourthSalt, uint _fifthSalt, uint _sixthSalt) public onlyOwner {
        uint rand = getRandom();
        uint firstWinner = (rand + _firstSalt) % players.length;
        uint secondWinner = (firstWinner + _secondSalt) % players.length;
        uint thirdWinner = (secondWinner + _thirdSalt) % players.length;
        uint fourthWinner = (thirdWinner + _fourthSalt) % players.length;
        uint fifthWinner = (fourthWinner + _fifthSalt) % players.length;
        uint sixthWinner = (fifthWinner + _sixthSalt) % players.length;

        pastDraw[drawId] = players[firstWinner];
        drawId++;
        pastDraw[drawId] = players[secondWinner];
        drawId++;
        pastDraw[drawId] = players[thirdWinner];
        drawId++;
        pastDraw[drawId] = players[fourthWinner];
        drawId++;
        pastDraw[drawId] = players[fifthWinner];
        drawId++;
        pastDraw[drawId] = players[sixthWinner];
        drawId++;
    }

    function createSaleItem(uint256 _newTicketPrice, uint16 _newId, uint16 _totalSlots) public onlyOwner {
        ticketPrice = _newTicketPrice;

        idToSaleItem[_newId].totalSlots = _totalSlots;
        idToSaleItem[_newId].boughtSlots = 0;
        idToSaleItem[_newId].isActive = true;
        idToSaleItem[_newId].itemPrice = _newTicketPrice;
        // idToSaleItem[_newId].buyers = address[]

    }

    

    function setTicketPrice(uint256 _newTicketPrice) public onlyOwner {
        ticketPrice = _newTicketPrice;
    }

    function setMaxTicket(uint256 _maxTickets) public onlyOwner {
        maxTicketsPerTx = _maxTickets;

    }

    function startEntries() public onlyOwner {
        drawLive = true;
    }

    function stopEntries() public onlyOwner {
        drawLive = false;
    }

    function transferOwnership(address _address) public onlyOwner {
        owner = _address;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}