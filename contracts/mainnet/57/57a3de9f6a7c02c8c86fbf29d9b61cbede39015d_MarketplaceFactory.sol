// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Marketplace} from "./Marketplace.sol";
import {IMarketplace} from "./IMarketplace.sol";

/**
 * @author MetaPlayerOne DAO
 * @title MarketplaceFactory
 * @notice Manages creation of Marketplaces on MetaPlayerOne. 
 */
contract MarketplaceFactory is IMarketplace {
    address private _owner_of;

    constructor(address owner_of_) {
        _owner_of = owner_of_;
    }

    event created(address space_address, string title, address owner_of);

    function create(Metadata memory metadata, Access memory access, Partner[] memory partners, uint256 owner_fee, Curator[] memory curators) public {
        address[] memory partners_ = new address[](partners.length);
        uint256[] memory partners_fees_ = new uint256[](partners.length);
        for (uint256 i = 0; i < partners.length; i++) {
            partners_[i] = partners[i].eth_address;
            partners_fees_[i] = partners[i].percentage;
        }
        address[] memory curators_ = new address[](curators.length);
        uint256[] memory curator_fees_ = new uint256[](curators.length);
        for (uint256 i = 0; i < curators.length; i++) {
            curators_[i] = curators[i].eth_address;
            curator_fees_[i] = curators[i].percentage;
        }
        Marketplace marketplace = new Marketplace(metadata, access, partners_, partners_fees_, msg.sender, owner_fee, _owner_of, curators_, curator_fees_);
        emit created(address(marketplace), metadata.title, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMarketplace.sol";

contract Marketplace is IMarketplace {
    struct Token { uint256 uid; address token_address; uint256 token_id; uint256 amount; ContractType contract_type; uint256 price; bool is_sold; bool approved; bool canceled; address owner_of; }

    address private _platform_address;

    address private _owner_of;
    uint256 private _owner_fee;

    string private _title;
    string private _description;
    string private _short_description;
    string private _scene_uri;

    uint256 private _access_fee;
    uint256 private _submition_fee;
    address private _access_token_address;

    Token[] private _tokens;
    Curator[] private _curators;
    Partner[] private _partners;

    mapping(address => mapping(uint256 => bool)) private _submited_tokens;
    mapping(uint256 => bool) private _curator_approved_tokens;

    mapping(address => bool) private _is_curator_address;
    mapping(address => bool) private _is_partner_address;

    constructor(Metadata memory metadata_, Access memory access_, address[] memory partners_, uint256[] memory partners_fees_, address owner_of_, uint256 owner_fee_, address platform_address_, address[] memory curators_, uint256[] memory curator_fees_) {
        require(curators_.length == curator_fees_.length, "Invalid inputs for curators");
        require(partners_.length == partners_fees_.length, "Invalid inputs for partners");
        require(curators_.length <= 2, "To much curators for Space");
        uint256 percentages = (owner_fee_ * 10) + 25;
        for (uint256 i = 0; i < partners_fees_.length; i++) {
            percentages += partners_fees_[i] * 10;
        }
        for (uint256 i = 0; i < curator_fees_.length; i++) {
            percentages += curator_fees_[i] * 10;
        }
        require(percentages <= 1000, "Percentages is not valid");
        _owner_fee = owner_fee_;
        _owner_of = owner_of_;
        _title = metadata_.title;
        _short_description = metadata_.short_description;
        _description = metadata_.description;
        _scene_uri = metadata_.scene_uri;
        _access_token_address = access_.token_address;
        _access_fee = access_.access_fee;
        _submition_fee = access_.submition_fee;
        _platform_address = platform_address_;

        for (uint256 i = 0; i < partners_.length; i++) {
            _partners.push(Partner(partners_[i], partners_fees_[i]));
            _is_partner_address[partners_[i]] = true;
        }
        for (uint256 i = 0; i < curators_.length; i++) {
            _curators.push(Curator(curators_[i], curator_fees_[i]));
            _is_curator_address[curators_[i]] = true;
        }
    }

    function submitToken(address token_address_, uint256 token_id_, uint256 amount_, ContractType contract_type_, uint256 price_) public {
        if (_access_token_address != address(0) && _submition_fee != 0) {
            require(IERC20MarketPlace(_access_token_address).balanceOf(msg.sender) >= _submition_fee, "Not enough tokens for submit your nft");
        }
        require(!_submited_tokens[token_address_][token_id_], "Token is submited to this Space");
        if (contract_type_ == ContractType.single_token) {
            IERC721MarketPlace token = IERC721MarketPlace(token_address_);
            require(token.ownerOf(token_id_) == msg.sender, "You are not an owner of this token");
            require(token.getApproved(token_id_) == address(this), "Not approved to this Space");
        } else {
            IERC1155MarketPlace token = IERC1155MarketPlace(token_address_);
            require(token.balanceOf(msg.sender, token_id_) >= amount_, "Not enough tokens in your wallet");
            require(token.isApprovedForAll(msg.sender, address(this)), "Not approved to this Space");
        }
        uint256 newTokenId = _tokens.length;
        _submited_tokens[token_address_][token_id_] = true;
        _tokens.push(Token(newTokenId, token_address_, token_id_, amount_, contract_type_, price_, false, false, false, msg.sender));
    }
    
    function approvedToken(uint256 uid) public {
        require(!_curator_approved_tokens[uid], "Already approved by curator");
        require(_is_curator_address[msg.sender], "You are not curator");
        _curator_approved_tokens[uid] = true;
        _tokens[uid].approved = true;
    }

    function buy(uint256 uid) public payable {
        require(uid <= _tokens.length, "Order does not exist");
        require(_curator_approved_tokens[uid] && _tokens[uid].approved, "Not curator approved");
        if (_access_token_address != address(0) && _access_fee != 0) {
           require(IERC20MarketPlace(_access_token_address).balanceOf(msg.sender) >= _access_fee, "Permission denied");
        }
        Token memory order = _tokens[uid];
        require(msg.value >= order.price, "Not enough ETH sent");
        require(!order.is_sold, "Already resolved");
        if (order.contract_type == ContractType.single_token) {
            IERC721MarketPlace token = IERC721MarketPlace(order.token_address);
            require(token.ownerOf(order.token_id) == order.owner_of, "Not an owner of this token");
            require(token.getApproved(order.token_id) == address(this), "Not approved to this Space");
            token.safeTransferFrom(order.owner_of, msg.sender, order.token_id, "");
        } else {
            IERC1155MarketPlace token = IERC1155MarketPlace(order.token_address);
            require(token.balanceOf(order.owner_of, order.token_id) >= order.amount, "Not enough tokens in wallet");
            require(token.isApprovedForAll(_owner_of, address(this)), "Not approved to this Space");
            token.safeTransferFrom(order.owner_of, msg.sender, order.token_id, order.amount, "");
        }

        uint256 summ = 0;
        payable(_platform_address).transfer(msg.value * 25 / 1000);
        summ += msg.value * 25 / 1000;
        payable(_owner_of).transfer(msg.value * _owner_fee / 100);
        summ += msg.value * _owner_fee / 100;
        for (uint256 i = 0; i < _partners.length; i++) {
            payable(_partners[i].eth_address).transfer(msg.value * _partners[i].percentage / 100);
            summ += msg.value * _partners[i].percentage / 100;
        }
        for (uint256 i = 0; i < _curators.length; i++) {
            payable(_curators[i].eth_address).transfer(msg.value * _curators[i].percentage / 100);
            summ += msg.value * _curators[i].percentage / 100;
        }
        payable(order.owner_of).transfer(msg.value - summ);
        _submited_tokens[order.token_address][order.token_id] = false;
        _tokens[uid].is_sold = true;
    }

    function setDescription(string memory description_) public {
        require(msg.sender == _owner_of, "Permission denied");
        _description = description_;
    }

    function getSpace() public view returns (address owner_of, string memory title, string memory description, string memory short_description, string memory scene_uri, uint256 access_fee, uint256 submition_fee, address access_token_address, Token[] memory tokens, Partner[] memory partners, Curator[] memory curators) {
        if (msg.sender != _owner_of && !_is_partner_address[msg.sender] && !_is_curator_address[msg.sender] && _access_token_address != address(0) && _access_fee != 0) { require(IERC20MarketPlace(_access_token_address).balanceOf(msg.sender) >= _access_fee, "Permission denied"); }
        return (_owner_of, _title, _description, _short_description, _scene_uri, _access_fee, _submition_fee, _access_token_address, _tokens, _partners, _curators);
    }

    function getSpaceSecure() public view returns (address owner_of, string memory title, string memory description, string memory short_description, uint256 access_fee, uint256 submition_fee, address access_token_address) {
        return (_owner_of, _title, _description, _short_description, _access_fee, _submition_fee, _access_token_address);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketplace {
    struct Metadata {
        string title;
        string short_description;
        string description;
        string scene_uri;
    }

    struct Access {
        address token_address;
        uint256 access_fee;
        uint256 submition_fee;
    }

    struct Partner {
        address eth_address;
        uint256 percentage;
    }

    struct Curator {
        address eth_address;
        uint256 percentage;
    }

    enum ContractType {
        single_token,
        multiple_token
    }
}

interface IERC20MarketPlace {
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721MarketPlace {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC1155MarketPlace {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}