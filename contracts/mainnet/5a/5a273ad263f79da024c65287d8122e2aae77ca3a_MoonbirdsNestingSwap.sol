/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract MoonbirdsNestingSwap {
    struct Offer {
        uint128 price;
        uint32 minCurrentPeriod;
        uint32 minTotalPeriod;
        uint64 endTime;
    }

    struct Acceptance {
        address buyer;
        bytes32 offerHash;
    }

    IMoonbirds public immutable moonbirds;
    IERC20 public immutable weth;
    address internal _owner;
    uint256 internal _fee;

    /// @dev Record of buyer offers
    mapping(address => Offer) public buyerOffers;

    /// @dev Record of seller acceptances for buyer offers
    mapping(address => Acceptance) public sellerAcceptances;

    event Swap(address indexed buyer);

    constructor(address _moonbirds, address _weth) {
        moonbirds = IMoonbirds(_moonbirds);
        weth = IERC20(_weth);
        _owner = msg.sender;
        _fee = 200;
    }

    /// @notice Check buyer offer is unchanged
    function isValidOfferHash(address buyer, bytes32 offerHash) public view returns (bool) {
        Offer memory offer = buyerOffers[buyer];
        return
            offerHash ==
            keccak256(
                abi.encodePacked(buyer, offer.price, offer.minCurrentPeriod, offer.minTotalPeriod, offer.endTime)
            );
    }

    /// @notice Check buyer offer is rational
    function isValidBuyerOffer(address buyer, Offer memory offer) public view returns (bool) {
        return
            weth.allowance(buyer, address(this)) >= offer.price &&
            offer.minTotalPeriod >= offer.minCurrentPeriod &&
            offer.endTime > block.timestamp;
    }

    /// @notice Check buyer offer is rational
    function isValidBuyer(address buyer) external view returns (bool) {
        Offer memory offer = buyerOffers[buyer];
        return isValidBuyerOffer(buyer, offer);
    }

    /// @notice Buyer makes an offer
    function buyerMakeOffer(Offer calldata offer) external {
        require(isValidBuyerOffer(msg.sender, offer), 'Invalid offer');
        buyerOffers[msg.sender] = offer;
    }

    /// @notice Buyer cancels the offer
    function buyerCancelOffer() external {
        delete buyerOffers[msg.sender];
    }

    /// @notice Seller accepts an offer
    function sellerAcceptOffer(address buyer, bytes32 offerHash) external {
        require(isValidOfferHash(buyer, offerHash), 'Invalid hash');

        sellerAcceptances[msg.sender] = Acceptance({buyer: buyer, offerHash: offerHash});
    }

    /// @notice Seller cancels the acceptance
    function sellerCancelAcceptance() external {
        delete sellerAcceptances[msg.sender];
    }

    /// @notice Seller sends moonbird to this contract using `safeTransferWhileNesting()` and invoke swap
    function onERC721Received(
        address, // operator
        address from, // seller
        uint256 tokenId,
        bytes calldata // data
    ) external returns (bytes4) {
        require(msg.sender == address(moonbirds), 'Invalid caller');

        Acceptance memory acceptance = sellerAcceptances[from];
        address buyer = acceptance.buyer;
        Offer memory offer = buyerOffers[buyer];

        require(isValidOfferHash(buyer, acceptance.offerHash), 'Invalid hash');
        require(isValidBuyerOffer(buyer, offer), 'Invalid offer');

        delete sellerAcceptances[from];
        delete buyerOffers[buyer];

        (, uint256 current, uint256 total) = moonbirds.nestingPeriod(tokenId);
        require(current >= offer.minCurrentPeriod, '< min current');
        require(total >= offer.minTotalPeriod, '< min total');

        // Fee
        uint256 fee = (offer.price * _fee) / 1e4;
        weth.transferFrom(buyer, address(this), fee);

        // Swap
        weth.transferFrom(buyer, from, offer.price - fee);
        moonbirds.safeTransferWhileNesting(address(this), buyer, tokenId);
        emit Swap(buyer);

        return this.onERC721Received.selector;
    }

    function setOwner(address owner) external {
        require(msg.sender == _owner);
        _owner = owner;
    }

    function setFee(uint256 fee) external {
        require(msg.sender == _owner);
        _fee = fee;
    }

    function withdraw(address token) external {
        require(msg.sender == _owner);
        IERC20(token).transfer(_owner, IERC20(token).balanceOf(address(this)));
    }
}

interface IMoonbirds {
    function balanceOf(address owner) external returns (uint256);

    function ownerOf(uint256 tokenId) external returns (address);

    function safeTransferWhileNesting(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function nestingPeriod(uint256 tokenId)
        external
        returns (
            bool nesting,
            uint256 current,
            uint256 total
        );
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}