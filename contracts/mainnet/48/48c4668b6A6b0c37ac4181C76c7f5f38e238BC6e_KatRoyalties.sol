// SPDX-License-Identifier: MIT

////////////////////////////////////////////////////////
// @title KatWalkerz Royalties /ᐠ｡▿｡ᐟ\*ᵖᵘʳʳ*
// @notice this contract receives royalties, holders can
// enter the raffle and win 50% winning amount every week.
// @author sadat.eth
////////////////////////////////////////////////////////

pragma solidity ^0.8.4;

contract KatRoyalties {
    // import katwalkerz and katmonstarz nft collections
    IERC721 private KatWalkerz = IERC721(0x8D28EB8079aE341cA45Bb91E4900974b6999b959);
    IERC721 private KatMonstarz = IERC721(0xb5C2c4bdd64379DDA029F04340598EE9EBA7A7aF);
    // rules of the lottery & division
    uint256 private royaltiesSplit = 2;
    uint256 private maxWinners = 5;
    uint256 private minSpin = 0.1 ether;
    uint256 private minEntries = 10;
    uint256 private spinInterval = 7 days;
    uint256 private minVotes = 50;
    // storage for the spin records
    uint256 private currentPrize;
    uint256 private winnerFunds;
    uint256 private lastSpin;
    uint256[6] private proposal;
    address[] private votes;
    address[] private entries;
    mapping(address => uint256) private chances;
    address[] private winners;
    mapping(address => uint256) private balances;
    address private owner;
    // security checks for functions
    bool private spinning;
    bool private withdrawing;
    bool private voting;
    // initializes contract, sets deployer as owner
    constructor() { owner = msg.sender; }
    // sets contract to receive external payments
    receive() external payable { }

////////////////////////////////////////////////////////
// @notice public function to enter for the lottery.
// @dev checks if the caller is a holder of KatMonstarz,
// checks if the caller is also a holder of KatWalkerz,
// adds the caller to the list of entries if not already,
// @param number of "kw" increases the winning chances.
////////////////////////////////////////////////////////

    function enter() public {
        uint256 km = KatMonstarz.balanceOf(msg.sender);
        uint256 kw = KatWalkerz.balanceOf(msg.sender);
        require(km > 0, "must hold katmonstarz");
        require(kw > 0, "must hold katwalkerz");
        if (chances[msg.sender] == 0) {
            entries.push(msg.sender);
        }
        chances[msg.sender] = kw;
    }

////////////////////////////////////////////////////////
// @notic public function to withdraw amount.
// @param "addr" is the address of recipient,
// @dev checks for any ongoing withdrawal,
// checks if the caller has available amount,
// transfers amount and updates balances
////////////////////////////////////////////////////////

    function withdraw(address addr) public {
        require(!withdrawing, "withdrawing in process");
        require(balances[msg.sender] > 0, "no balance");
        uint256 amount = balances[msg.sender];
        withdrawing = true;
        (bool success, ) = payable(addr).call{value: amount}("");
        require(success, "failed");
        balances[msg.sender] = 0;
        winnerFunds -= amount;
        withdrawing = false;
    }

////////////////////////////////////////////////////////
// @notice public function to pick the random winners.
// @dev checks if next spin is available, checks if
// there are more than minimum entries and balance.
// sets distribution of new winning amount,  spins all
// entries and pick the random winners based on chances.
// sets balances of winners, owner and the  current
// winning prize, resets entries for the next spin.
////////////////////////////////////////////////////////

    function spin() public {
        require(!spinning, "spinning in process");
        require(block.timestamp - lastSpin > spinInterval, "not available");
        require(entries.length >= minEntries, "not enough entries");
        require(address(this).balance - winnerFunds > minSpin, "not enough balance");
        spinning = true;
        uint256 amount = address(this).balance - winnerFunds;
        uint256 split = amount / royaltiesSplit;
        uint256 share = split / maxWinners;
        uint256 maxChances = checkChances();
        address[] memory spinner = new address[](maxChances);
        uint256 luck = 0;
        uint256 karma = 0;
        while (karma < maxChances) {
            for (uint256 j = 0; j < chances[entries[luck]]; j++) {
                spinner[karma] = entries[luck];
                karma++;
            }
            luck++;
        }
        winners = new address[](0);
        for (uint256 w = 0; w < maxWinners; w++) {
            uint256 r = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, w))) % maxChances;
            if (!_alreadyIn(winners, spinner[r]) && KatWalkerz.balanceOf(spinner[r]) >= chances[spinner[r]]) {
                winners.push(spinner[r]);
                balances[spinner[r]] += share;
                winnerFunds += share;
            }
        }
        balances[owner] += split;
        winnerFunds += split;
        currentPrize = split;
        lastSpin = block.timestamp;
        spinning = false;
    }

////////////////////////////////////////////////////////
// @notice internal function to find duplicates.
// @param "list" is the list of addresses to find in.
// @param "addr" is the address to look for.
// @dev loops through the "list" array and returns "true"
// if "addr" is found and "false" if not found.
////////////////////////////////////////////////////////

    function _alreadyIn(address[] memory list, address addr) internal pure returns (bool) {
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == addr) return true;
        }
        return false;
    }

////////////////////////////////////////////////////////
// @notic public function to view total entries.
// @dev returns the total number of entries.
////////////////////////////////////////////////////////

    function checkEntries() public view returns (uint256) {
        return entries.length;
    }

////////////////////////////////////////////////////////
// @notic public function to view total possible chances.
// @dev returns the number of total winning chances.
////////////////////////////////////////////////////////

    function checkChances() public view returns (uint256) {
        uint256 totalChances;
        for (uint256 i = 0; i < entries.length; i++) {
            totalChances += chances[entries[i]];
        }
        return totalChances;
    }

////////////////////////////////////////////////////////
// @notic public function to view winning chances.
// @param "addr" is the address to check chances of.
// @dev returns the number of chances of the "addr".
////////////////////////////////////////////////////////

    function checkChances(address addr) public view returns (uint256) {
        return chances[addr];
    }

////////////////////////////////////////////////////////
// @notic public function to view current winning amount.
// @dev returns the current winning amount.
////////////////////////////////////////////////////////

    function checkPrize() public view returns (uint256) {
        return currentPrize;
    }

////////////////////////////////////////////////////////
// @notic public function to view list of winners.
// @dev returns list of addresses of current winners.
////////////////////////////////////////////////////////

    function checkWinners() public view returns (address[] memory) {
        return winners;
    }

////////////////////////////////////////////////////////
// @notic public function to view address winning status.
// @param "addr" is the address to check status of.
// @dev returns false or true if the "addr" is winner.
////////////////////////////////////////////////////////

    function checkWinner(address addr) public view returns (bool) {
        for (uint256 i = 0; i < winners.length; i++) {
            if (winners[i] == addr) return true;
        }
        return false;
    }

////////////////////////////////////////////////////////
// @notic public function to view winner balance.
// @param "addr" is the address to check balance of.
// @dev returns the balance of the "addr".
////////////////////////////////////////////////////////

    function checkBalance(address addr) public view returns (uint256) {
        return balances[addr];
    }

////////////////////////////////////////////////////////
// @notic public function to view current votes.
// @dev returns total number of votes.
////////////////////////////////////////////////////////

    function checkVotes() public view returns (uint256) {
        return votes.length;
    }

////////////////////////////////////////////////////////
// @notic public function to view current proposed rules.
// @dev returns new set of rules submitted by owner.
////////////////////////////////////////////////////////

    function checkProposal() public view returns (uint256[6] memory) {
        return proposal;
    }

////////////////////////////////////////////////////////
// @notic public function to vote for new rules.
// @dev check if voting has started,
// checks if caller is holder of km & kw.
// adds the caller in the voters list or
// approves the proposed rules if enough votes.
////////////////////////////////////////////////////////

    function vote() public {
        require(voting, "no new proposal");
        require(KatMonstarz.balanceOf(msg.sender) > 0, "must hold km");
        require(KatWalkerz.balanceOf(msg.sender) > 0, "must hold kw");
        require(!_alreadyIn(votes, msg.sender), "already voted");
        if (votes.length < minVotes) {
            votes.push(msg.sender);
        }
        else {
            royaltiesSplit = proposal[0];
            maxWinners = proposal[1];
            minSpin = proposal[2];
            minEntries = proposal[3];
            spinInterval = proposal[4];
            minVotes = proposal[5];
            voting = false;
        }
    }

////////////////////////////////////////////////////////
// @notic owner function to change contract settings
// settings can be changed if there are  enough votes.
// @param "newRules" is the new proposed set of rules.
// @dev checks if caller is the current owner,
// checks if rules are correct format, saves the new
// rules temporary and prepares new voting.
////////////////////////////////////////////////////////

    function settings(uint256[] memory newRules) public {
        require(msg.sender == owner, "only owner");
        require(newRules.length == 6, "iykyk");
        for (uint256 i = 0; i < 6; i++) {
            proposal[i] = newRules[i];
        }
        votes = new address[](0);
        voting = true;
    }
}

interface IERC721 {
    // interface of erc721 to check balanceOf of kw & km collections
    function balanceOf(address owner) external view returns (uint256 balance);
}