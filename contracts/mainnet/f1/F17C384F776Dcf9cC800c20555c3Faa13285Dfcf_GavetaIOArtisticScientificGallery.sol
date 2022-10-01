/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
/*
** This contract is inspired by the 16th-century italian math duels
** and the 21st-century american cryptopunks auction model;
** its structure is derived from late 19th early 20th-century legislative works;
*/
contract GavetaIOArtisticScientificGallery {
    // ** A0 - On the ARTISTIC-SCIENTIFIC gallery structure and setup
    // ** A0.1 - On the global constants and variables
    // ** A0.1.1 - Address acting as SCIENTIST and GALLERY OWNER; fixed
    address public scientist; 
    // ** A0.1.2 - Address acting as ARTIST; variable
    address public artist;
    // ** A0.1.3 - ARTIST's signature hash; fixed
    string public artistSignature;
    // ** A0.1.4 - GALLERY's name; fixed
    string public name; 
    // ** A0.1.5 - GALLERY's symbol; fixed
    string public symbol; 
    // ** A0.1.6 - GALLERY's principles hash; fixed
    string public galleryPrinciples;
    // ** A0.1.7 - GALLERY's amount of token supply; fixed
    uint8 public tokenSupply = 46;
    // ** A0.1.8 - GALLERY's allowed token transfers between auctions; fixed
    uint8 public tokenAllowedTransfers = 3;
    // ** A0.1.9 - GALLERY's bid/price increment; fixed
    uint public tokenPriceIncrement = 100 ether;
    // ** A0.1.10 - GALLERY's reserve price; incremental
    uint public tokenReservePrice = 123 ether;
    // ** A0.1.11 - GALLERY's duel flow security fee; variable
    uint public duelFlowSecurityFee = 0.1 ether;
    // ** A0.2 - GALLERY's TOKEN structure
    struct Token {
        uint8 tokenId;
        address owner;
        uint value;
        uint auctions;
        uint8 transfers;
        string name;
        string title;
        string description;
        string words;
        string notes;
        string source;
        string footer;
        bool active;
        bool acceptScienfificDuel;
        bool messageSent;
    }
    struct TokenBid {
        bool active;
        uint8 tokenId;
        address bidder;
        uint value;
    }
    struct TokenMessage {
        address owner;
        string message;
    }
    struct TokenOwners {
        uint8 tokenId;
        address[] owners;
        TokenMessage[] messages;
    }
    struct TokenScientificChallenge {
        address challenger;
        string challenge;
        string note;
    }
    struct TokenScientificChallenges {
        uint8 tokenId;
        address[] challengers;
        TokenScientificChallenge[] challenges;
    }
    mapping (uint8 => TokenBid) internal tokenBids;
    mapping (uint8 => Token) internal tokens;
    mapping (uint8 => TokenOwners) internal tokenOwners;
    mapping (uint8 => TokenScientificChallenges) internal tokenChallenges;
    event TokenCreated(address indexed to, uint8 tokenId, string name, string title);
    event TokenTransfered(address indexed to, uint8 tokenId);
    event TokenMessageRecorded(address indexed owner, uint8 tokenId, string message);
    event TokenBidEntered(address indexed bidder, uint8 tokenId, uint value, uint value2);
    event TokenBidAccepted(address indexed buyer, uint8 tokenId, uint value, uint droit);
    event TokenBidWithdrawn(address indexed bidder, uint8 tokenId, uint value);
    event TokenBidRefunded(address indexed bidder, uint8 tokenId, uint value);
    // ** A0.3 - GALLERY's SCIENTIFIC DUEL structure
    struct ScientificDuelChallenge {
        uint8 tokenId;
        address challenger;
        string  challenge;
        uint fee;
        bool active;
    }
    mapping (uint8 => ScientificDuelChallenge) internal scientificDuelChallenges;
    event ScientificDuelEntered(address indexed challenger, uint tokenId, string challenge, uint value, uint length);
    event ScientificDuelRejected(address indexed challenger, uint tokenId, string reason);
    event ScientificDuelWithdrawn(address indexed bidder, uint value);
    event ScientificDuelForfeited(address indexed challenger, uint tokenId, uint value, bool transfered);
    event ScientificDuelFlowSecurityFeeUpdated(address indexed scientist, uint value);
    // ** A0.4 - GALLERY's modifiers
    modifier isScientist() {
        require(msg.sender == scientist, "M1");
        _;
    }
    modifier isArtistOrScientist() {
        require(msg.sender == artist || msg.sender == scientist, "M2");
        _;
    }
    modifier isTokenOwner(uint8 tokenId) {
        require(tokens[tokenId].owner == msg.sender, "M3");
        _;
    }
    modifier isTokenActive(uint8 tokenId) {
        require(tokens[tokenId].active == true, "M4");
        _;
    }
    modifier isScientificDuelChallengeActive(uint8 tokenId) {
        require(scientificDuelChallenges[tokenId].active == true, "M5");
        _;
    }
    // ** A0.5 - GALLERY OWNER constructs the basis for launching the contract 
    constructor(
        string memory _name, 
        address _artist, 
        string memory _symbol, 
        string memory _artistSignature, 
        string memory _galleryPrinciples
        ) {
        scientist = msg.sender;
        artist = _artist;
        name = _name;
        symbol = _symbol;
        artistSignature = _artistSignature;
        galleryPrinciples = _galleryPrinciples;
    }

    // ** A1 - On the ARTISTIC-SCIENTIFIC token management 
    // ** A1.1 - SCIENTIST or ARTIST creates a new token 
    function createToken(address to, uint8 tokenId, string memory _name, string memory _title, string memory _source, string memory _description, string memory _words,  string memory _notes, string memory _footer, bool acceptScienfificDuel) public isArtistOrScientist {
        if (tokens[tokenId].active == true) revert("C1");
        if (tokenId == 0 || tokenId > tokenSupply) revert("C2");
        tokens[tokenId] = Token(tokenId, to, tokenReservePrice, 0, 0, _name, _title, _description, _words, _notes, _source, _footer, true, acceptScienfificDuel, false);
        tokenOwners[tokenId].owners.push(to);
        tokenOwners[tokenId].tokenId = tokenId;
        emit TokenCreated(to, tokenId, _name, _title);
    }
    // ** A1.2 - GALLERY OWNER increments the reservePrice by a fixed factor 
    function incrementGalleryTokenReservePrice() public isScientist {
        tokenReservePrice = tokenReservePrice + tokenPriceIncrement;
    }
    // ** A1.3 - GALLERY OWNER decrements the reservePrice by a fixed factor 
    function decrementGalleryTokenReservePrice() public isScientist {
        tokenReservePrice = tokenReservePrice - tokenPriceIncrement;
    }

    // ** A2 - On the TOKEN OWNER management actions 
    // ** A2.1 - TOKEN OWNER chooses to transfer its token ownership 
    function transferTokenOwnership(address to, uint8 tokenId) public isTokenOwner(tokenId) {
        if (tokens[tokenId].transfers > tokenAllowedTransfers) revert("T1");
        tokens[tokenId].owner = to;
        tokens[tokenId].transfers++;
        tokenOwners[tokenId].owners.push(to);
        emit TokenTransfered(to, tokenId);
    }
    // ** A2.2 - TOKEN OWNER chooses to carve a message on the block-chain 
    function recordTokenMessage(uint8 tokenId, string memory message) public isTokenOwner(tokenId) {
        if (tokens[tokenId].messageSent == true) revert("R1");
        if (bytes(message).length < 23) revert("R2");
        if (bytes(message).length > 223) revert("R3");
        tokens[tokenId].messageSent = true;
        TokenMessage memory newMessage = TokenMessage(msg.sender, message);
        tokenOwners[tokenId].messages.push(newMessage);
        emit TokenMessageRecorded(msg.sender, tokenId, message);
    }
    // ** A2.3 - TOKEN OWNER chooses to accept a token bid 
    // ** A2.3.1 - TOKEN value assumes the bid va*lue
    function acceptTokenBid(uint8 tokenId) public isTokenOwner(tokenId) isTokenActive(tokenId) {
        TokenBid memory bid = tokenBids[tokenId];
        if (bid.active == false) revert("A1");
        if (bid.value == 0) revert("A2");
        address owner = tokens[tokenId].owner;
        uint amount = bid.value * 97 / 100;
        uint droit = bid.value - amount;
        tokens[tokenId].owner = bid.bidder;
        tokens[tokenId].auctions++;
        tokens[tokenId].transfers = 0;
        tokens[tokenId].value = bid.value;
        tokens[tokenId].messageSent = false;
        tokenOwners[tokenId].owners.push(bid.bidder);
        tokenBids[tokenId] = TokenBid(false, tokenId, address(0), 0);
        payable(owner).transfer(amount);
        payable(artist).transfer(droit);
        emit TokenBidAccepted(bid.bidder, tokenId, amount, droit);
    }

    // ** A3 - On the TOKEN BIDDER actions 
    // ** A3.1 - TOKEN BIDDER chooses to enter a bid for a token 
    function enterTokenBid(uint8 tokenId) public payable isTokenActive(tokenId) {
        if (msg.value < tokenReservePrice) revert("E1");
        if ((msg.value - 23 ether) % 100 ether != 0) revert("E2");
        Token memory token = tokens[tokenId];
        if (token.owner == msg.sender) revert("E3");
        if (token.auctions != 0 && msg.value < (token.value + tokenPriceIncrement)) revert("E4");
        TokenBid memory currentBid = tokenBids[tokenId];
        if (msg.value <= currentBid.value) revert("E5");
        tokenBids[tokenId] = TokenBid(true, tokenId, msg.sender, msg.value);
        if (currentBid.active == true && currentBid.value > 0) {
            payable(currentBid.bidder).transfer(currentBid.value);
            emit TokenBidRefunded(currentBid.bidder, tokenId, currentBid.value);
        }
        emit TokenBidEntered(msg.sender, tokenId, msg.value, (msg.value - 23 ether) % 100 ether);
    }
    // ** A3.2 - TOKEN BIDDER chooses to withdraw token bid 
    function withdrawTokenBid(uint8 tokenId) public {
        if (tokenBids[tokenId].bidder != msg.sender) revert("W1");
        if (tokenBids[tokenId].active == false) revert("W2");
        uint amount = tokenBids[tokenId].value;
        tokenBids[tokenId] = TokenBid(false, tokenId, address(0), 0);
        payable(msg.sender).transfer(amount);
        emit TokenBidWithdrawn(msg.sender, tokenId, amount);
    }

    // ** A4 - On the SCIENTIFIC DUELS management 
    // ** A4.1 - CHALLENGER enters a new scientific duel by challenging an existing token 
    // ** A4.1.1 - The duelFlowSecurityFee is returned in full on challenge rejection, withdrawn or first forfeit 
    function enterScientificDuel(uint8 tokenId, string memory challenge) public payable isTokenActive(tokenId) {
        if (tokens[tokenId].acceptScienfificDuel == false) revert("E1");
        if (msg.value < duelFlowSecurityFee) revert("E2");
        if (scientificDuelChallenges[tokenId].active == true) revert("E3");
        bytes memory challengeBytes = bytes(challenge);
        if (challengeBytes.length < 223) revert("E4");
        if (challengeBytes.length > 1223) revert("E5");
        scientificDuelChallenges[tokenId] = ScientificDuelChallenge(tokenId, msg.sender, challenge, msg.value, true);
        emit ScientificDuelEntered(msg.sender, tokenId, challenge, msg.value, challengeBytes.length);
    }
    // ** A4.2 - CHALLENGER choose to withdraw from the scientific duel 
    function withdrawScientificDuel(uint8 tokenId) public isScientificDuelChallengeActive(tokenId) {
        if (scientificDuelChallenges[tokenId].challenger != msg.sender) revert("W1");
        uint amount = scientificDuelChallenges[tokenId].fee;
        scientificDuelChallenges[tokenId] = ScientificDuelChallenge(tokenId, address(0), "", 0, false);
        payable(msg.sender).transfer(amount);
        emit ScientificDuelWithdrawn(msg.sender, tokenId);
    }
    // ** A4.3 - GALLERY OWNER/SCIENTIST rejects scientific duel 
    function rejectScientificDuel(uint8 tokenId, string memory reason) public isScientist isScientificDuelChallengeActive(tokenId) {
        if(bytes(reason).length > 2323) revert("R1");
        ScientificDuelChallenge memory duel = scientificDuelChallenges[tokenId];
        scientificDuelChallenges[tokenId] = ScientificDuelChallenge(tokenId, address(0), "", 0, false);
        payable(msg.sender).transfer(duel.fee);
        emit ScientificDuelRejected(duel.challenger, tokenId, reason);
    }
    // ** A4.4 - GALLERY OWNER/SCIENTIST forteits scientific duel 
    // ** A4.4.1 - If SCIENTIST owns the TOKEN, transfer it to CHALLENGER with full owners*hip
    // ** A4.4.2 - If SCIENTIST doesn't own the TOKEN, payoff at least 90% of its owned value to CHALLEN*GER
    // ** A4.4.3 - If the TOKEN already had a forfeited duel, SCIENTIST receives the *fee
    function forfeitScientificDuel(uint8 tokenId, string memory note) public payable isScientist isTokenActive(tokenId) isScientificDuelChallengeActive(tokenId) {
        if(bytes(note).length > 2323) revert("F1");
        Token memory token = tokens[tokenId];
        bool isForfeited = tokenChallenges[tokenId].tokenId == tokenId;
        if (token.owner != scientist && isForfeited == false && msg.value < token.value * 97 / 100 * 9 / 10) revert("F1");
        ScientificDuelChallenge memory duel = scientificDuelChallenges[tokenId];
        scientificDuelChallenges[tokenId] = ScientificDuelChallenge(tokenId, address(0), "", 0, false);
        tokenChallenges[tokenId].challengers.push(duel.challenger);
        TokenScientificChallenge memory saveChallenge = TokenScientificChallenge(duel.challenger, duel.challenge, note);
        tokenChallenges[tokenId].challenges.push(saveChallenge);
        if (isForfeited == false) {
            tokenChallenges[tokenId].tokenId = tokenId;
            if (token.owner == scientist) {
                tokens[tokenId].owner = duel.challenger;
                tokens[tokenId].transfers = 0;
                tokens[tokenId].messageSent = false;
                tokenOwners[tokenId].owners.push(duel.challenger);
            } else {
                payable(duel.challenger).transfer(msg.value);
            }
            payable(duel.challenger).transfer(duel.fee);
            emit ScientificDuelForfeited(duel.challenger, tokenId, msg.value, token.owner == scientist);
        } else {
            payable(scientist).transfer(duel.fee);
            emit ScientificDuelForfeited(duel.challenger, tokenId, 0, false);
        }
    }
    // ** A4.5 - GALLERY OWNER/SCIENTIST sets the secure duel fee for reasonable duel creation 
    function updateDuelFlowSecurityFee(uint value) public isScientist {
        duelFlowSecurityFee = value;
        emit ScientificDuelFlowSecurityFeeUpdated(msg.sender, value);
    }

    // ** A5 - On the GENERAL PUBLIC observation getters 
    // ** A5.1 - GENERAL PUBLIC gets a Token's information 
    function getTokenInfo(uint8 tokenId) public view returns (Token memory) {
        return tokens[tokenId];
    }
    // ** A5.2 - GENERAL PUBLIC gets a Token's information 
    function getTokenOwner(uint8 tokenId) public view returns (address) {
        return tokens[tokenId].owner;
    }
    // ** A5.3 - GENERAL PUBLIC gets a TokenOwner's list of current and past onwership information 
    function getTokenOwnersHistoryInfo(uint8 tokenId) public view returns (TokenOwners memory) {
        return tokenOwners[tokenId];
    }
    // ** A5.4 - GENERAL PUBLIC gets a TokenOwner's list of current and past onwership information 
    function getTokenScientificChallengesInfo(uint8 tokenId) public view returns (TokenScientificChallenges memory) {
        return tokenChallenges[tokenId];
    }
    // ** A5.5 - GENERAL PUBLIC gets a TokenBid information 
    function getTokenBidInfo(uint8 tokenId) public view returns (TokenBid memory) {
        return tokenBids[tokenId];
    }
    // ** A5.6 - GENERAL PUBLIC gets the information from a specific ScientificDuelChallenge 
    function getScientificDuelInfo(uint8 tokenId) public view returns (ScientificDuelChallenge memory) {
        return scientificDuelChallenges[tokenId];
    }
}