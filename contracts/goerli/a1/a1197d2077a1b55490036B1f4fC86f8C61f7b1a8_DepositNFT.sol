pragma solidity ^0.8.2;

contract DepositNFT {
    event Mint(address to, uint256 tokenId);
    event Burn(address from, uint256 tokenId);
    event Sell(address from, address to, uint256 tokenId, uint256 price);
    event BuyBack(address from, address to, uint256 tokenId);

    uint256 maxSupply;
    uint256 depositPrice;
    uint256 sellGoal;
    uint256 decisionTime;
    address private depositWallet;

    mapping(address => mapping(uint256 => bool)) private tokenExists;
    mapping(address => mapping(uint256 => bool)) private tokenBurnable;
    mapping(address => mapping(uint256 => bool)) private tokenMinted;

    bool private sellGoalReached;
    bool private decisionTimeStarted;

    constructor(uint256 _maxSupply, uint256 _depositPrice, uint256 _sellGoal, uint256 _decisionTime, address _depositWallet) {
        maxSupply = _maxSupply;
        depositPrice = _depositPrice;
        sellGoal = _sellGoal;
        decisionTime = _decisionTime;
        depositWallet = _depositWallet;
}

    function mint(uint256 _tokenId) public payable {
        require(tokenExists[msg.sender][_tokenId] == false, "Token already exists");
        require(tokenMinted[msg.sender][_tokenId] == false, "Token already minted");
        require(msg.value >= depositPrice, "Deposit is less than the required deposit price");
        tokenExists[msg.sender][_tokenId] = true;
        tokenMinted[msg.sender][_tokenId] = true;
        tokenBurnable[msg.sender][_tokenId] = true;
        emit Mint(msg.sender, _tokenId);
    }

    function burn(uint256 _tokenId) public {
        require(tokenExists[msg.sender][_tokenId] == true, "Token does not exist");
        require(tokenBurnable[msg.sender][_tokenId] == true, "Token is not burnable");
        tokenExists[msg.sender][_tokenId] = false;
        tokenBurnable[msg.sender][_tokenId] = false;
        payable(msg.sender).transfer(depositPrice);
        emit Burn(msg.sender, _tokenId);
    }

    function sell(uint256 _tokenId, address _buyer, uint256 _price) public {
        require(tokenExists[msg.sender][_tokenId] == true, "Token does not exist");
        require(_price > depositPrice, "Selling price is less than or equal to deposit price");
        require(tokenBurnable[msg.sender][_tokenId] == true, "Token is not burnable");
        tokenBurnable[msg.sender][_tokenId] = false;
        tokenMinted[msg.sender][_tokenId] = false;
        payable(_buyer).transfer(_price);
       
        payable(depositWallet).transfer(depositPrice);
        emit Sell(msg.sender, _buyer, _tokenId, _price);
        uint256 totalMinted = 0;
        for (uint256 i = 0; i < maxSupply; i++) {
            if (tokenMinted[msg.sender][i]) {
                totalMinted++;
            }
        }
        if (totalMinted == maxSupply) {
            sellGoalReached = true;
            // start decision time
            // if sell goal is reached during decision time, supporters can no longer burn tokens
            // you can use block.timestamp+decisionTime to check if time is over or any other timer library
        }
    }

    function buyBack(uint256 _tokenId) public {
        require(sellGoalReached && decisionTimeStarted, "Sell goal is not reached or decision time is not over.");
        require(tokenExists[msg.sender][_tokenId] == true, "Token does not exist");
        tokenExists[msg.sender][_tokenId] = false;
        payable(msg.sender).transfer(depositPrice);
        payable(depositWallet).transfer(depositPrice);
        emit BuyBack(msg.sender, msg.sender, _tokenId);
    }
}