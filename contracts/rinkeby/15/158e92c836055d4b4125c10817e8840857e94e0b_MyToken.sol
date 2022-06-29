// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Preset.sol";
import "./Counters.sol";

contract MyToken is ERC721Preset {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _userTokenIdCounter;

    IERC20 private grom;
    IERC20 private usdt;

    struct Option {
        uint256 id;
        uint256 price;
        uint256 expirationAmount;
        string endDateAt;
    }

    struct OptionUser {
        uint256 id;
        uint256 optionId;
        uint256 tokenId;
        uint256 price;
        uint256 expirationAmount;
        string endDateAt;
    }

    mapping(uint256 => Option) public options;

    mapping(uint256 => OptionUser) private optionUsers;

    constructor(IERC20 gromContract, IERC20 usdtContract) ERC721Preset("MyToken", "MTK") {
        grom = gromContract;
        usdt = usdtContract;
    }

    function addOption(uint256 _id, uint256 _price, uint256 _expirationAmount, string memory _endDateAt) external onlyOwner {
        options[_id] = Option(_id, _price, _expirationAmount, _endDateAt);
    }

    function buyByGr(uint256 _amount) public {
        uint256 allowance = grom.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");

        (bool sent) = grom.transferFrom(msg.sender, address(this), _amount);
        require(sent, "Failed to send GROM");
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

    function revertNFT(
        uint256 tokenId
    ) external onlyOwner {
        address owner = ERC721.ownerOf(tokenId);
        super._transfer(owner, msg.sender, tokenId);
    }

    /**
    * @notice Allow contract owner to withdraw ETH to its own account.
    */
    function withdrawEth() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
    * @notice Allow contract owner to withdraw GR to its own account.
    */
    function withdrawGr() external onlyOwner {
        uint256 balance = grom.balanceOf(address(this));
        require(balance > 0, "GROption: amount sent is not correct");

        grom.transfer(owner(), balance);
    }
}