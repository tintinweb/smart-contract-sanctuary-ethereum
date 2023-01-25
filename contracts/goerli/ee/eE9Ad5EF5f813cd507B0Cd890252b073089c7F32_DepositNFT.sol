pragma solidity ^0.8.2;

contract DepositNFT {
    uint256 maxSupply;
    uint256 depositPrice;
    uint256 sellGoal;
    uint256 decisionTime;
    // address bankOwner;
    // bool private sellGoalReached;
    // bool private decisionTimeStarted;

    constructor(uint256 _maxSupply, uint256 _depositPrice, uint256 _sellGoal, uint256 _decisionTime/*,  address _bankOwner */) {
        maxSupply = _maxSupply;
        depositPrice = _depositPrice;
        sellGoal = _sellGoal;
        decisionTime = _decisionTime;
        // bankOwner = payable(_bankOwner);
}

    mapping(address => mapping(uint256 => bool)) private tokenMinted;

    function mint(uint256 _tokenId) public payable {
        require(msg.value >= depositPrice, "Deposit is less than the required deposit price");
        require(tokenMinted[msg.sender][_tokenId] == false, "Token already minted");
        bool sent = payable(msg.sender).send(depositPrice);
        require(sent, "Failed to send Ether");
        tokenMinted[msg.sender][_tokenId] = true;
    }
}