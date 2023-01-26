// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

    struct TokenState {
        bool burned;
        bool secondHand;
        bool minted;
        bool isDeposit;
        address owner;
    }

contract DepositNFT {
    uint256 maxSupply;
    uint256 depositPrice;
    uint256 sellGoal;
    uint256 decisionTime;
    uint256 private _tokenIdCounter = 1;

    address bankOwner;
    uint256 private decisionTimeStartedAt;

    event Mint(address to, uint256 tokenId);
    event Burn(address from, uint256 tokenId);
    event Sell(address from, address to, uint256 tokenId, uint256 price);
    event TransformDepositToBuy(address to, uint256 tokenId);

    constructor(uint256 _maxSupply, uint256 _depositPrice, uint256 _sellGoal, uint256 _decisionTime, address _bankOwner) {
        maxSupply = _maxSupply;
        depositPrice = _depositPrice; // one ne peut que des int
        sellGoal = _sellGoal;
        decisionTime = _decisionTime;
        bankOwner = payable(_bankOwner);
    }

    mapping(uint256 => TokenState) public tokenMinted;

    /* Write methods*/

    function mint() public payable {
        uint256 _tokenId = getTokenIdCounter();
        require(_tokenId < maxSupply, "Sold out");
        require(msg.value <= depositPrice, "Deposit is less than the required deposit price");
        require(tokenMinted[_tokenId].minted == false, "Token already minted");
        tokenMinted[_tokenId] = TokenState({
        burned : false,
        secondHand : false,
        minted : true,
        owner : msg.sender,
        isDeposit : true
        });
        _incrementCounter();

        emit Mint(msg.sender, _tokenId);
    }

    function burn(uint256 _tokenId) public {
        require(tokenMinted[_tokenId].owner == msg.sender, "You do not have this token");
        require(tokenMinted[_tokenId].burned == false, "Token is already burnable");
        require(tokenMinted[_tokenId].secondHand == false, "Token is not burnable");
        require(decisionTimeIsOver() == false, "The decision time is over, you can no longer burn your token");

        tokenMinted[_tokenId].burned = true;
        tokenMinted[_tokenId].isDeposit = false;
        payable(msg.sender).transfer(depositPrice);
        _transfer(_tokenId, address(0x0000000000000000000000000000000000000000));

        emit Burn(msg.sender, _tokenId);
    }

    /* 
    * If after the decision period, the supporter has not made a choice => contract auto burn
    */
    function burnIfGone() public {
        require(decisionTimeIsOver() == true, "The decision time is not over");
        for (uint256 i = 0; i < maxSupply; i++) {
            if (tokenMinted[i].isDeposit == true) {
                // Force auto burn or not (gaz fee)
                tokenMinted[i].burned = true;
                payable(tokenMinted[i].owner).transfer(depositPrice);
                _transfer(i, address(0x0000000000000000000000000000000000000000));
            }
        }
    }

    function sell(uint256 _tokenId, address _buyer, uint256 _price) public {
        require(tokenMinted[_tokenId].owner == msg.sender, "You do not have this token");
        require(tokenMinted[_tokenId].burned == false, "Token already burned");
        require(_price > depositPrice, "Selling price is less than or equal to deposit price");

        payable(msg.sender).transfer(_price);
        payable(bankOwner).transfer(depositPrice);

        tokenMinted[_tokenId].secondHand = true;
        tokenMinted[_tokenId].isDeposit = false;

        _transfer(_tokenId, _buyer);
        _checkGoal();

        emit Sell(msg.sender, _buyer, _tokenId, _price);
    }

    function transformDepositToBuy(uint256 _tokenId) public {
        require(tokenMinted[_tokenId].owner == msg.sender, "You do not have this token");
        require(decisionTimeIsOver() == false, "The decision time is over");
        require(tokenMinted[_tokenId].isDeposit == true, "You cannot buy this token");

        payable(bankOwner).transfer(depositPrice);

        tokenMinted[_tokenId].isDeposit = false;

        emit TransformDepositToBuy(msg.sender, _tokenId);
    }

    /* READ methods*/

    function getTokenIdCounter() public view returns (uint256) {
        return _tokenIdCounter;
    }

    function supplyLeft() public view returns (uint256) {
        return maxSupply - getTokenIdCounter() + 1;
    }

    function decisionTimeIsOver() public view returns (bool) {
        if (decisionTimeStartedAt != 0 && block.timestamp >= decisionTimeStartedAt + decisionTime * 1) {
            return true;
        }

        return false;
    }

    function decisionTimeEndedIn() public view returns (uint256) {
        if (decisionTimeStartedAt != 0) {
            return decisionTimeStartedAt + decisionTime * 1;
        }

        return decisionTimeStartedAt;
    }

    /* Private methods */

    function _incrementCounter() private{
        _tokenIdCounter += 1;
    }

    function _transfer(uint256 _tokenId, address _to) private{
        require(tokenMinted[_tokenId].owner != _to, "Token already exist for recipient");
        tokenMinted[_tokenId].owner = _to;
    }

    function _checkGoal() private{
        if (decisionTimeStartedAt == 0 && _tokenIdCounter > maxSupply) {
            uint256 totalSell = 0;
            for (uint256 i = 0; i < maxSupply; i++) {
                if (tokenMinted[i].secondHand) {
                    totalSell++;
                }
            }
            if (totalSell >= (maxSupply * 100 / sellGoal)) {
                decisionTimeStartedAt = block.timestamp;
            }
        }
    }
}