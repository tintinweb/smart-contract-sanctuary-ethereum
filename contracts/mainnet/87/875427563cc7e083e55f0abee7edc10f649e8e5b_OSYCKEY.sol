// SPDX-License-Identifier: MIT

/***************************************************************************
          ___        __         _     __           __   __ ___
        / __ \      / /_  _____(_)___/ /____       \ \ / /  _ \
       / / / /_  __/ __/ / ___/ / __  / __  )       \ / /| |
      / /_/ / /_/ / /_  (__  ) / /_/ / ____/         | | | |_
      \____/\____/\__/ /____/_/\__,_/\____/          |_|  \___/
                                       
****************************************************************************/

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract OSYCKEY is Ownable, ERC1155 {
    string private name_;
    string private symbol_;

    mapping(uint8 => uint16) public MAX_SUPPLY;
    mapping(uint8 => uint16) public mintedCount;
    mapping(uint8 => address) public allowedAddress;
    mapping(uint8 => uint256) public price;

    constructor(string memory _name, string memory _symbol) {
        name_ = _name;
        symbol_ = _symbol;
    }

    function name() public view virtual returns (string memory) {
        return name_;
    }

    function symbol() public view virtual returns (string memory) {
        return symbol_;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        _setURI(_baseURI);
    }

    function setConfig(
        uint8 keyId,
        uint16 _max_supply,
        address _allowedAddress
    ) external onlyOwner {
        MAX_SUPPLY[keyId] = _max_supply;
        allowedAddress[keyId] = _allowedAddress;
    }

    function setMintPrice(uint8 keyId, uint256 _price) external onlyOwner {
        price[keyId] = _price;
    }

    function mintKey(
        address account,
        uint8 keyId,
        uint8 amount
    ) external {
        require(msg.sender == allowedAddress[keyId], "Not allowed to Mint");
        require(
            mintedCount[keyId] + amount < MAX_SUPPLY[keyId],
            "Max Limit To Sale"
        );

        _mint(account, keyId, amount, "");
        mintedCount[keyId] = mintedCount[keyId] + amount;
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public virtual {
        require(
            _msgSender() == owner() || isApprovedForAll(from, _msgSender()),
            "ERC1155Burnable: caller is not owner nor approved"
        );
        _burn(from, id, amount);
    }

    function buy(uint8 keyId, uint8 amount) external payable {
        require(tx.origin == msg.sender, "Only EOA");
        require(price[keyId] > 0, "No opened sale.");
        require(
            price[keyId] * amount <= msg.value,
            "Insufficient value To Mint"
        );

        _mint(msg.sender, keyId, amount, "");
    }

    function reserveKey(
        address[] memory accounts,
        uint8 keyId,
        uint8 amount
    ) external onlyOwner {
        require(
            mintedCount[keyId] + amount * accounts.length < MAX_SUPPLY[keyId],
            "Max Limit To Sale"
        );
        for (uint8 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], keyId, amount, "");
        }
        mintedCount[keyId] =
            mintedCount[keyId] +
            uint16(amount * accounts.length);
    }

    function withdrawAll() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        payable(msg.sender).transfer(totalBalance);
    }
}