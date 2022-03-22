// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./EnumerableSet.sol";

contract StakingMaster is Ownable {

    event CreateOffer(uint256 id);
    event RemoveOffer(uint256 id);

    event ApplyForOffer(address indexed sender, uint256 id);
    event ResignFromOffer(address indexed sender, uint256 id);
    event Withdraw(address indexed token, address indexed recipient);

    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;

    struct Offer {
        string name;
        address token;
        uint256 amount;
        uint256 fee;
        uint256 duration;
        string membershipURL; // If the stake is sucessful it will send them a simple page with metamask connect to check if their account is staked on that offerCount and show a div with the hidden content.
    }

    uint256 internal _offersCount;
    
    mapping(address => uint256) internal _feeBalances;
    mapping(uint256 => Offer) internal _offers;

    /// @dev in the form of userAddress => (offerId => timestamp)
    mapping(address => mapping(uint256 => uint256)) internal _stakes;

    EnumerableSet.UintSet internal _activeOffers;

    function createOffer(
        string memory name, 
        address token, 
        uint256 amount, 
        uint256 fee, 
        uint256 duration, 
        string memory membershipURL
    ) public virtual onlyOwner {
        _offersCount += 1;
        _offers[_offersCount] = Offer(name, token, amount, fee, duration, membershipURL);
        _activeOffers.add(_offersCount);
        emit CreateOffer(_offersCount);
    }

    function removeOffer(uint256 id) public virtual onlyOwner {
        require(_activeOffers.contains(id), "Offer not found or active");
        _activeOffers.remove(id);
        emit RemoveOffer(id);
    }

    function applyForOffer(uint256 id) public virtual {
        require(_activeOffers.contains(id), "Offer not found or active");
        address user = _msgSender();
        Offer memory offer = _offers[id];
        ERC20(offer.token).transferFrom(user, address(this), offer.amount);
        _stakes[user][id] = block.timestamp;
        emit ApplyForOffer(user, id);
    }

    function resignFromOffer(uint256 id) public virtual {
        Offer memory offer = _offers[id];
        address user = _msgSender();
        require(offer.token != address(0), "Offer not found");
        require(isStaking(user, id), "Not in offer");
        ERC20 token = ERC20(offer.token);
        uint256 amount = token.balanceOf(address(this)) >= offer.amount ? offer.amount : token.balanceOf(address(this));

        if(!_activeOffers.contains(id) || _stakes[user][id].add(offer.duration) < block.timestamp) {
            token.transfer(user, amount);
        } else {
            uint256 takenFee = amount.mul(offer.fee).div(100);
            token.transfer(user, amount.sub(takenFee));
            _feeBalances[offer.token] += takenFee;
        }
        _stakes[user][id] = 0;

        emit ResignFromOffer(user, id);
    }

    function isStaking(address user, uint256 id) public view returns (bool) {
        return _stakes[user][id] > 0;
    }

    function getCount() public view returns(uint256) {
        return _offersCount;
    }

    function getActiveOffers() public view returns(uint256[] memory) {
        return _activeOffers.values();
    }

    function getOffer(uint256 id) public view returns(Offer memory) {
        return _offers[id];
    }

    function withdrawFees(address token, address recipient) public onlyOwner {
        ERC20(token).transfer(recipient, _feeBalances[token]);
        _feeBalances[token] = 0;
        emit Withdraw(token, recipient);
    }
}