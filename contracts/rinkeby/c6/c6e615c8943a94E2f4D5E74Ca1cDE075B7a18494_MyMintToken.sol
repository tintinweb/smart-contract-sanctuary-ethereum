// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155Supply.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./IERC20.sol";

contract MyMintToken is ERC1155, Ownable, Pausable, ERC1155Supply {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    IERC20 private usdt;

    struct Event {
        uint256 tokenId;
        uint256 amount;
        uint256 priceUsd;
        bool hasValue;
    }

    mapping(uint256 => Event) private events;

    constructor(string memory _url, IERC20 usdtContract) ERC1155(_url) {
        usdt = usdtContract;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getEventById(uint256 _id)
        public
        view
        returns (
            uint256 id,
            uint256 amount,
            uint256 priceUsd
        )
    {
        return (events[_id].tokenId, events[_id].amount, events[_id].priceUsd);
    }

    function createTickets(
        uint256 eventId,
        uint256 amount,
        uint256 priceUsd
    ) public onlyOwner {
        if (events[eventId].hasValue) {
            uint256 plusAmount = 0;
            if (amount > events[eventId].amount) {
                plusAmount = amount - events[eventId].amount;
            } else {
                amount = events[eventId].amount;
            }
            events[eventId] = Event(
                events[eventId].tokenId,
                amount,
                priceUsd,
                true
            );
            if (plusAmount > 0) {
                _mint(_msgSender(), events[eventId].tokenId, plusAmount, "");
            }
        } else {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            events[eventId] = Event(tokenId, amount, priceUsd, true);
            _mint(_msgSender(), tokenId, amount, "");
        }
    }

    function buyTicket(uint256 eventId, uint256 amount) public virtual {
        require(
            totalSupply(events[eventId].tokenId) + amount >
                events[eventId].amount,
            "Can't buy more"
        );
        uint256 _amount = events[eventId].priceUsd;
        uint256 allowance = usdt.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");

        bool sent = usdt.transferFrom(msg.sender, address(this), _amount);
        require(sent, "Failed to send USDT");
        _safeTransferFrom(
            owner(),
            _msgSender(),
            events[eventId].tokenId,
            amount,
            ""
        );
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(_getURI(), Strings.toString(_tokenId)));
    }

    function withdrawMatic() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawUsdt() external onlyOwner {
        uint256 balance = usdt.balanceOf(address(this));
        require(balance > 0, "Amount sent is not correct");

        usdt.transfer(owner(), balance);
    }
}