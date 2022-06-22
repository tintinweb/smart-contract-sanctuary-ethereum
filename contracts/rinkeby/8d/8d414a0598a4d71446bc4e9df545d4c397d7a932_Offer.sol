/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(address, address, uint) external;
    function ownerOf(uint) external view returns (address);
}

interface Market {
    function getPrevOwner(address, uint, uint) external view returns (address);
    function getPrevOwnerAmount(address, uint) external view returns (uint);
    function owner() external view returns (address);
}

contract Offer {
    event OfferEvent(address indexed tokenAddr, uint indexed tokenId,address indexed offerer, uint amount, bool isOffer);
    event WithdrawEvent(address indexed tokenAddr, uint indexed tokenId,address indexed offerer);
    event SubmitEvent(address indexed tokenAddr, uint indexed tokenId, bool isOffer);

    mapping(address =>mapping(uint => Offers)) public offers;

    struct Offers {
        address[] offerer;
        mapping(address => uint) amount;
        bool isOffer;
    }

    uint public balances;

    function offer(address tokenAddr, uint tokenId) external payable {
        Offers storage _offers = offers[tokenAddr][tokenId];

        if(_offers.amount[msg.sender] == 0) {
            _offers.offerer.push(msg.sender);
        }
        _offers.amount[msg.sender] = msg.value;
        _offers.isOffer = true;

        balances += msg.value;

        emit OfferEvent(tokenAddr, tokenId, msg.sender, msg.value, true);
    }

    function submit(address contractAddr, address tokenAddr, uint tokenId, address offerer) external payable {
        Offers storage _offers = offers[tokenAddr][tokenId];
        IERC721 token = IERC721(tokenAddr);
        Market _market = Market(contractAddr);

        require(token.ownerOf(tokenId) == msg.sender, "Unauthorized.");
        require(_offers.isOffer == true, "No offer.");

        payable(msg.sender).transfer(_offers.amount[offerer] - (_offers.amount[offerer] / 20));
        
        if(_market.getPrevOwnerAmount(tokenAddr, tokenId) > 0) {
            payable(_market.owner()).transfer(_offers.amount[offerer] / 40);
            for (uint i = 0; i < 5; i++) {
                if (_market.getPrevOwner(tokenAddr, tokenId, i) != address(0)) {
                    payable(_market.getPrevOwner(tokenAddr, tokenId, i)).transfer((_offers.amount[offerer] / 40) / _market.getPrevOwnerAmount(tokenAddr, tokenId));
                }
                else {
                    break;
                }
            }
        }
        else {
            payable(_market.owner()).transfer(_offers.amount[offerer] / 20);
        }

        balances -= _offers.amount[offerer];
        _offers.isOffer = false;

        for(uint i = _offers.offerer.length - 1; i >= 0; i--) {
            payable(_offers.offerer[i]).transfer(_offers.amount[_offers.offerer[i]]);
            balances -= _offers.amount[_offers.offerer[i]];
            _offers.amount[_offers.offerer[i]] = 0;
            _offers.offerer.pop();
        }

        token.transferFrom(msg.sender, offerer, tokenId);

        emit SubmitEvent(tokenAddr, tokenId, false);
    }

    function withdraw(address tokenAddr, uint tokenId) public payable {
        Offers storage _offers = offers[tokenAddr][tokenId];

        require(_offers.isOffer == true, "No offer.");
        require(_offers.amount[msg.sender] > 0, "Offer is 0.");

        uint lastIndex = _offers.offerer.length - 1;

        if(msg.sender == _offers.offerer[lastIndex]) {
            _offers.offerer.pop();
        }
        else {
            for(uint i = 0; i < _offers.offerer.length; i++) {
                if(_offers.offerer[i] == msg.sender) {
                    _offers.offerer[i] = _offers.offerer[lastIndex];
                    _offers.offerer.pop();
                    break;
                }
            }
        }

        payable(msg.sender).transfer(_offers.amount[msg.sender]);
        _offers.amount[msg.sender] = 0;

        emit WithdrawEvent(tokenAddr, tokenId, msg.sender);
    }
}