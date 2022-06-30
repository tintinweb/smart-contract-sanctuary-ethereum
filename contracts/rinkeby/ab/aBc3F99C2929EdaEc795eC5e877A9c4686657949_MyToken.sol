// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Preset.sol";
import "./Counters.sol";

contract MyToken is ERC721Preset {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 private _userTokenIdCounter = 0;

    IERC20 private grom;
    IERC20 private usdt;

    struct Option {
        uint256 id;
        uint256 price;
        uint256 expirationAmount;
        uint256 endDateAt;
    }

    struct OptionUser {
        uint256 id;
        uint256 optionId;
        uint256 tokenId;
        uint256 price;
        uint256 expirationAmount;
        bool isPaid;
        uint256 endDateAt;
    }

    mapping(uint256 => Option) public options;

    mapping(uint256 => OptionUser) public optionUsers;
    constructor(IERC20 gromContract, IERC20 usdtContract) ERC721Preset("MyToken", "MTK") {
        grom = gromContract;
        usdt = usdtContract;
    }




    /*

        function addOption(uint256 _id, uint256 _price, uint256 _expirationAmount, uint256 _endDateAt) external onlyOwner {
            options[_id] = Option(_id, _price, _expirationAmount, _endDateAt);
        }

        function buyByGr(uint256 _amount, uint _id, uint _optionId) public {
            uint256 allowance = grom.allowance(msg.sender, address(this));
            require(allowance >= _amount, "Check the token allowance");

            (bool sent) = grom.transferFrom(msg.sender, address(this), _amount);
            require(sent, "Failed to send GROM");

            addOptionUser(_id, options[_optionId]);
        }

        function addOptionUser(uint _id, Option memory option) private {
            optionUsers[_id] = OptionUser(_id, option.id, _userTokenIdCounter, option.price, option.expirationAmount, false, option.endDateAt);
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
            address from,
            address to,
            uint256 tokenId
        ) external onlyOwner {
            super._transfer(from, to, tokenId);
        }

        function revertNFT(
            uint256 tokenId
        ) external onlyOwner {
            address from = ERC721.ownerOf(tokenId);
            super._transfer(from, owner(), tokenId);
        }

        function pay(
            uint _id
        ) public {
            uint256 chainStartTime = block.timestamp;
            if (optionUsers[_id].isPaid) {
                require(false, "GROption: is paid");
            } else if (chainStartTime <= optionUsers[_id].endDateAt) {
                require(false, "GROption: too early");
            } else if (!optionUsers[_id].isPaid && chainStartTime >= optionUsers[_id].endDateAt) {
                uint256 amount = grom.balanceOf(address(this));
                require(amount >= optionUsers[_id].expirationAmount, "GROption: amount sent is not correct");

                address from = ERC721.ownerOf(optionUsers[_id].tokenId);
                grom.transfer(from, optionUsers[_id].expirationAmount);
                optionUsers[_id].isPaid = true;
            }
        }

        function timestamp() public view returns(uint256){
            return block.timestamp;
        }

    */
    function withdrawEth() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawGr() external onlyOwner {
        uint256 balance = grom.balanceOf(address(this));
        require(balance > 0, "GROption: amount sent is not correct");

        grom.transfer(owner(), balance);
    }
}