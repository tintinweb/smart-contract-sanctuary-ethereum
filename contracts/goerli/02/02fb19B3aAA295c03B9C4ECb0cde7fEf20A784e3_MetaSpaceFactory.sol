// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MetaSpace} from "./MetaSpace.sol";
import "./IMetaSpace.sol";

contract MetaSpaceFactory is IMetaSpace {
    address private _platform_address;

    constructor (address platfrom_address_) {
        _platform_address = platfrom_address_;
    }

    event created(address space_address, string title, address owner_of);

    function create(Metadata memory metadata, Access memory access, Partner[] memory partners, uint256 owner_fee) public {
        address[] memory partners_ = new address[](partners.length);
        uint256[] memory partners_fees = new uint256[](partners.length);
        for (uint256 i = 0; i < partners.length; i++) {
            partners_[i] = partners[i].eth_address;
            partners_fees[i] = partners[i].percentage;
        }
        MetaSpace metaspace = new MetaSpace(metadata, access, partners_, partners_fees, msg.sender, owner_fee, _platform_address);
        emit created(address(metaspace), metadata.title, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMetaSpace.sol";

contract MetaSpace is IMetaSpace {
    struct Token { uint256 uid; address token_address; uint256 token_id; uint256 amount; ContractType contract_type; uint256 price; bool is_sold; bool canceled; }

    address private _platform_address;

    address private _owner_of;
    uint256 private _owner_fee;

    string private _title;
    string private _description;
    string private _short_description;
    string private _scene_uri;

    uint256 private _access_fee;
    address private _access_token_address;
    IERC20MetaSpace _access_token = IERC20MetaSpace(_access_token_address);

    Token[] private _tokens;
    Partner[] private _partners;
    
    mapping(address => mapping(uint256 => bool)) private _submited_tokens;

    mapping(address => bool) private _is_partner_address;

    constructor(Metadata memory metadata_, Access memory access_, address[] memory partners_, uint256[] memory partners_fees_, address owner_of_, uint256 owner_fee_, address platform_address_) {
        uint256 percentages = (owner_fee_ * 10) + 25;
        for (uint256 i = 0; i < partners_fees_.length; i++) {
            percentages += partners_fees_[i] * 10;
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
        _platform_address = platform_address_;

        for (uint256 i = 0; i < partners_.length; i++) {
            _partners.push(Partner(partners_[i], partners_fees_[i]));
            _is_partner_address[partners_[i]] = true;
        }

    }

    function submitToken(address token_address_, uint256 token_id_, uint256 amount_, ContractType contract_type_, uint256 price_) public {
        require(msg.sender == _owner_of, "You are not an creator of this Space");
        require(!_submited_tokens[token_address_][token_id_], "Token is submited to this Space");
        if (contract_type_ == ContractType.single_token) {
            IERC721MetaSpace token = IERC721MetaSpace(token_address_);
            require(token.ownerOf(token_id_) == msg.sender, "You are not an owner of this token");
            require(token.getApproved(token_id_) == address(this), "Not approved to this Space");
        } else {
            IERC1155MetaSpace token = IERC1155MetaSpace(token_address_);
            require(token.balanceOf(msg.sender, token_id_) >= amount_, "Not enough tokens in your wallet");
            require(token.isApprovedForAll(msg.sender, address(this)), "Not approved to this Space");
        }
        uint256 newTokenId = _tokens.length;
        _submited_tokens[token_address_][token_id_] = true;
        _tokens.push(Token(newTokenId, token_address_, token_id_, amount_, contract_type_, price_, false, false));
    }

    function cancelSubmition(uint256 uid) public {
        require(msg.sender == _owner_of, "You are not an creator of this Space");
        Token memory token = _tokens[uid];
        require(_submited_tokens[token.token_address][token.token_id], "Token is not submited to this MetaSpace");
        _tokens[uid].canceled = true;
        _submited_tokens[token.token_address][token.token_id] = false;
    }

    function buy(uint256 uid) public payable {
        require(uid <= _tokens.length, "Order does not exist");
        Token memory order = _tokens[uid];
        require(_access_token.balanceOf(msg.sender) >= _access_fee, "Permission denied");
        require(msg.value >= order.price, "Not enough ETH sent");
        require(!order.is_sold, "Already resolved");
        if (order.contract_type == ContractType.single_token) {
            IERC721MetaSpace token = IERC721MetaSpace(order.token_address);
            require(token.ownerOf(order.token_id) == _owner_of, "You are not an owner of this token");
            require(token.getApproved(order.token_id) == address(this), "Not approved to this Space");
            token.safeTransferFrom(_owner_of, msg.sender, order.token_id, "");
        } else {
            IERC1155MetaSpace token = IERC1155MetaSpace(order.token_address);
            require(token.balanceOf(_owner_of, order.token_id) >= order.amount, "Not enough tokens in your wallet");
            require(token.isApprovedForAll(_owner_of, address(this)), "Not approved to this Space");
            token.safeTransferFrom(_owner_of, msg.sender, order.token_id, order.amount, "");
        }
        payable(_platform_address).transfer(msg.value / 25 * 1000);
        payable(_owner_of).transfer(msg.value / _owner_fee * 100);
        for (uint256 i = 0; i < _partners.length; i++) {
            payable(_partners[i].eth_address).transfer(msg.value / _partners[i].percentage * 100);
        }
        _submited_tokens[order.token_address][order.token_id] = false;
        _tokens[uid].is_sold = true;
    }

    function getTokens() public view returns (Token[] memory) {
        if (msg.sender != _owner_of && !_is_partner_address[msg.sender]) { require(_access_token.balanceOf(msg.sender) >= _access_fee, "Permission denied"); }
        Token[] memory _submited = new Token[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            Token memory token = _tokens[i];
            if (!token.is_sold && !token.canceled) {
                _submited[_submited.length] = token;
            }
        }
        return _submited;
    }

    function setDescription(string memory description_) public {
        require(msg.sender == _owner_of, "Permission denied");
        _description = description_;
    }

    function getSpace() public view returns (address owner_of, uint256 owner_fee, string memory title, string memory description, string memory short_description, string memory scene_uri, uint256 access_fee, address access_token_address, Token[] memory tokens, Partner[] memory partners) {
        if (msg.sender != _owner_of && !_is_partner_address[msg.sender]) { require(_access_token.balanceOf(msg.sender) >= _access_fee, "Permission denied"); }
        return (_owner_of, _owner_fee, _title, _description, _short_description, _scene_uri, _access_fee, _access_token_address, getTokens(), _partners);
    }

    function getSpaceSecure() public view returns (address owner_of, string memory title, string memory description, string memory short_description, uint256 access_fee, address access_token_address) {
        return (_owner_of, _title, _description, _short_description, _access_fee, _access_token_address);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetaSpace {
    struct Metadata {
        string title;
        string short_description;
        string description;
        string scene_uri;
    }

    struct Access {
        address token_address;
        uint256 access_fee;
    }

    struct Partner {
        address eth_address;
        uint256 percentage;
    }

    enum ContractType {
        single_token,
        multiple_token
    }
}

interface IERC20MetaSpace {
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721MetaSpace {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC1155MetaSpace {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}