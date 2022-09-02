// SPDX-License-Identifier: UNLICENSED
/// @title PunksWrapperProxy
/// @notice Punks Holder that holds punks to be wrapped for a single wallet, so that withdrawals can be sent to the right address.   Based on PunksV1Wrapper by @FrankPoncelet.
/// @author CyberPnk <[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____
//  __________________/\/\/\/\________________________________________________________________________________
// __________________________________________________________________________________________________________

pragma solidity ^0.8.16;

import "./ICryptoPunksMarket.sol";

contract PunksWrapperProxy {
    ICryptoPunksMarket public cryptoPunksMarket;
    address public punksOwner;
    address public controller;

    modifier onlyController {
      require(msg.sender == controller, "Not controller");
      _;
   }

    constructor(address _cryptoPunksMarket, address _punksOwner) {
        cryptoPunksMarket = ICryptoPunksMarket(_cryptoPunksMarket);
        punksOwner = _punksOwner;
        controller = msg.sender;
    }

    function acquire(uint _punkId, address wrapCaller) external payable onlyController {
        // Prereq: owner should call `offerPunkForSaleToAddress` to this (their proxy contract) address with price 0
        (bool isForSale, , address seller, uint minValue, address onlySellTo) = cryptoPunksMarket.punksOfferedForSale(_punkId);
        require(isForSale == true, "Not for sale");
        require(seller == wrapCaller, "Not your punk");
        require(minValue == 0, "Not 0");
        require((onlySellTo == address(this)) || (onlySellTo == address(0x0)), "Not offered to proxy");
        cryptoPunksMarket.buyPunk{value: msg.value}(_punkId);
    }

    function transferPunk(uint256 _punkId, address unwrapCaller) external onlyController {
        cryptoPunksMarket.transferPunk(unwrapCaller, _punkId);
    }

    function withdraw() external onlyController {
        cryptoPunksMarket.withdraw();
        payable(punksOwner).transfer(address(this).balance);
    }

    function offerPunkForSaleToAddress(uint id, uint minSalePriceInWei, address to) external onlyController {
        cryptoPunksMarket.offerPunkForSaleToAddress(id, minSalePriceInWei, to);
    }

    function offerPunkForSale(uint id, uint minSalePriceInWei) external onlyController {
        cryptoPunksMarket.offerPunkForSale(id, minSalePriceInWei);
    }

    function punkNoLongerForSale(uint id) external onlyController {
        cryptoPunksMarket.punkNoLongerForSale(id);
    }

    function acceptBidForPunk(uint punkIndex, uint minPrice) external onlyController {
        cryptoPunksMarket.acceptBidForPunk(punkIndex, minPrice);
    }

    function beforeTransferRemoveFromSale(uint punkIndex) external onlyController {
        (bool isForSale, , , , ) = cryptoPunksMarket.punksOfferedForSale(punkIndex);
        if (isForSale) {
            cryptoPunksMarket.punkNoLongerForSale(punkIndex);
        }
    }

    receive() external payable { }
}

// SPDX-License-Identifier: MIT
/// @title ICryptoPunksMarket
/// @notice ICryptoPunksMarket

pragma solidity ^0.8.13;

interface ICryptoPunksMarket {
    function punkIndexToAddress(uint) external view returns(address);

    function name() external view returns (string memory);

    function punksOfferedForSale(uint id) external view returns (bool isForSale, uint punkIndex, address seller, uint minValue, address onlySellTo);

    function totalSupply() external view returns (uint);

    function decimals() external view returns (uint8);

    function imageHash() external view returns (string memory);

    function nextPunkIndexToAssign() external view returns (uint);

    function standard() external view returns (string memory);

    function balanceOf(address) external view returns (uint);

    function symbol() external view returns (string memory);

    function numberOfPunksToReserve() external view returns (uint);

    function numberOfPunksReserved() external view returns (uint);

    function punksRemainingToAssign() external view returns (uint);

    function pendingWithdrawals(address) external view returns (uint);

    function reservePunksForOwner(uint maxForThisRun) external;

    function withdraw() external;

    function buyPunk(uint id) external payable;

    function transferPunk(address to, uint id) external;

    function offerPunkForSaleToAddress(uint id, uint minSalePriceInWei, address to) external;

    function offerPunkForSale(uint id, uint minSalePriceInWei) external;

    function getPunk(uint id) external;

    function punkNoLongerForSale(uint id) external;

    function enterBidForPunk(uint punkIndex) external payable;

    function acceptBidForPunk(uint punkIndex, uint minPrice) external;

}