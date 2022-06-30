// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";
import "./Strings.sol";

contract ReleaseTickets0xRichApeWife is ERC721URIStorage, Ownable {

    uint public constant max_tickets = 10;
    uint256 public ticketPrice;
    bool public isSaleLive = false;
    uint256 public ticketCounter;
    uint256 public desiredPrice = 6000; //USD

    AggregatorV3Interface internal priceFeed;
    string private _baseURIExtended;
    bool internal locked;

    struct Account {
        uint mintedNFTs;
        bool isAdmin;
    }

    mapping(address => Account) public accounts;

    event Mint(address indexed sender, uint totalSupply);
    event PriceUpdate(uint feedPrice, uint newPrice);

    constructor(address _dataFeed, string memory _networkBaseURI) ERC721("Success Tickets", "0xRAWT") {
        ticketCounter = 0;
        ticketPrice = 0;
        priceFeed = AggregatorV3Interface(_dataFeed);
        _baseURIExtended = _networkBaseURI;
        accounts[msg.sender] = Account(0, true);
    }

    modifier onlyAdmin() {
        require(accounts[msg.sender].isAdmin == true, "Only admins can execute this function");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    function setAdmin(address _addr) external onlyOwner {
        require(accounts[_addr].isAdmin == false, "This user is already admin");
        accounts[_addr].isAdmin = !accounts[_addr].isAdmin;
    }

    function activateSale() external onlyOwner {
        isSaleLive = true;
    }

    function deactivateSale() external onlyOwner {
        isSaleLive = false;
    }

    function totalSupply() public view returns (uint256) {
        return ticketCounter;
    }

    function updatePrice() external onlyAdmin {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        require(price > 0, "Error fetching data from price feed");
        uint256 desired_price = desiredPrice * 10 ** 18;
        uint8 baseDecimals = priceFeed.decimals();
        price = scalePrice(price, baseDecimals);
        uint256 basePrice = uint(price);
        ticketPrice = (desired_price * 10 ** 18) / basePrice;
        emit PriceUpdate(basePrice, ticketPrice);
    }

    function scalePrice(int256 _price, uint8 _baseDecimals) internal pure returns (int256) {
        if (_baseDecimals < uint8(18)) {
            return _price * int256(10 ** uint256(uint8(18) - _baseDecimals));
        } else {
            return _price / int256(10 ** uint256(_baseDecimals - uint8(18)));
        }
    }

    function adminMint() external onlyAdmin {
        require(ticketCounter + 1 <= max_tickets, "Ticket limit already reached");
        accounts[msg.sender].mintedNFTs = accounts[msg.sender].mintedNFTs + 1;
        uint id = ticketCounter;
        _safeMint(msg.sender, id);
        _setTokenURI(id, string.concat(_baseURIExtended, Strings.toString(id)));
        ticketCounter = ticketCounter + 1;
        emit Mint(msg.sender, ticketCounter);
    }

    function mintTicket(uint _amount) external payable noReentrant {
        require(isSaleLive, "Sale must be active to mint");
        require(_amount > 0, "You must mint at least one NFT and under 10");
        require(ticketCounter + _amount <= max_tickets, "Purchase would exceed the max supply of tickets");
        require(msg.value >= (ticketPrice * _amount), "Not enough ether send to buy the desired tickets");
        require(!isContract(msg.sender), "Contracts can't mint");

        for (uint i = 0; i < _amount; i++) {
            accounts[msg.sender].mintedNFTs++;
            _safeMint(msg.sender, ticketCounter);
            _setTokenURI(ticketCounter, string.concat(_baseURIExtended, Strings.toString(ticketCounter+1)));
            ticketCounter++;
            emit Mint(msg.sender, ticketCounter);
        }
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function releaseFunds(uint256 amount) external onlyAdmin {
        require(address(this).balance >= amount, "Insufficient balance");

        address payable recipient = payable(owner());
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Unable to send funds, caller may have reverted");
    }

}