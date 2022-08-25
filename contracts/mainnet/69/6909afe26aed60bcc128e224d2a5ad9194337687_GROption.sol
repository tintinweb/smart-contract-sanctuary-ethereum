// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Preset.sol";
import "./Counters.sol";

contract GROption is ERC721Preset {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 private _userTokenIdCounter = 0;

    IERC20 private grom;
    IERC20 private usdt;

    struct Option {
        uint256 id;
        uint256 price;
        uint256 total;
        uint256 expirationAmount;
        uint256 endDateAt;
    }

    struct OptionUser {
        uint256 id;
        uint256 optionId;
        address wallet;
        uint256 tokenId;
        uint256 price;
        uint256 expirationAmount;
        bool isCreated;
        bool isPaid;
        uint256 endDateAt;
    }

    string private _uri;

    mapping(uint256 => Option) public options;
    mapping(uint256 => uint256) public optionsBuy;
    mapping(uint256 => OptionUser) public optionUsers;
    constructor(string memory _url, IERC20 gromContract, IERC20 usdtContract) ERC721Preset("GROption", "GRO") {
        grom = gromContract;
        usdt = usdtContract;
        _uri = _url;
    }

    function _setURI(string memory newuri) external onlyOwner {
        _uri = newuri;
    }

    function _getURI() internal view virtual returns (string memory) {
        return _uri;
    }

    function addOption(uint256 _id, uint256 _price, uint256 _total, uint256 _expirationAmount, uint256 _endDateAt) external onlyOwner {
        options[_id] = Option(_id, _price, _total, _expirationAmount, _endDateAt);
    }

    function buyByGr(uint256 _id, uint256 _optionId) public {
        require(optionsBuy[_optionId] <= options[_optionId].total, "Can't buy more");

        uint256 _amount = options[_optionId].price;
        uint256 allowance = grom.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");

        (bool sent) = grom.transferFrom(msg.sender, address(this), _amount);
        require(sent, "Failed to send GROM");
        optionsBuy[_optionId] = optionsBuy[_optionId] + 1;
        addOptionUser(_id, _optionId, msg.sender);
    }

    function addOptionUser(uint256 _id, uint256 _optionId, address wallet) private {
        require(!optionUsers[_id].isCreated, "Option exist");
        uint256 tokenId = _userTokenIdCounter;
        optionUsers[_id] = OptionUser(_id, options[_optionId].id, wallet, tokenId, options[_optionId].price, options[_optionId].expirationAmount, true, false, options[_optionId].endDateAt);
        _userTokenIdCounter++;
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function multipleMint(uint256 _numOfTokens) external onlyOwner {
        for (uint256 i = 0; i < _numOfTokens; i++) {
            safeMint(msg.sender);
        }
    }

    function transferNFT(
        address to,
        uint256 tokenId
    ) external onlyOwner {
        _transfer(owner(), to, tokenId);
    }

    function revertNFT(
        uint256 tokenId
    ) external onlyOwner {
        address from = ERC721.ownerOf(tokenId);
        _transfer(from, owner(), tokenId);
    }

    function pay(
        uint256 _id
    ) public {
        if (optionUsers[_id].isPaid || block.timestamp <= optionUsers[_id].endDateAt) {
            require(false, "GROption: is paid or too early");
        } else if (!optionUsers[_id].isPaid && block.timestamp >= optionUsers[_id].endDateAt) {
            uint256 amount = usdt.balanceOf(address(this));
            require(amount >= optionUsers[_id].expirationAmount, "GROption: amount sent is not correct");

            address from = ERC721.ownerOf(optionUsers[_id].tokenId);
            require(from == msg.sender, "GROption: is not owner");

            usdt.transfer(from, optionUsers[_id].expirationAmount);
            optionUsers[_id].isPaid = true;
            _transfer(from, owner(), optionUsers[_id].tokenId);
        }
    }

    function timestamp() public view returns (uint256){
        return block.timestamp;
    }

    function withdrawEth() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawGr() external onlyOwner {
        uint256 balance = grom.balanceOf(address(this));
        require(balance > 0, "GROption: amount sent is not correct");

        grom.transfer(owner(), balance);
    }

    function withdrawUsdt() external onlyOwner {
        uint256 balance = usdt.balanceOf(address(this));
        require(balance > 0, "GROption: amount sent is not correct");

        usdt.transfer(owner(), balance);
    }

    function uri(uint256 _tokenId) public view returns (string memory)
    {
        return string(abi.encodePacked(_getURI(), Strings.toString(_tokenId)));
    }
}