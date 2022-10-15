/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

    struct BasicOrderParameters {
        // calldata offset
        address considerationToken; // 0x24
        uint256 considerationIdentifier; // 0x44
        uint256 considerationAmount; // 0x64
        address payable offerer; // 0x84
        address zone; // 0xa4
        address offerToken; // 0xc4
        uint256 offerIdentifier; // 0xe4
        uint256 offerAmount; // 0x104
        uint256 basicOrderType; // 0x124
        uint256 startTime; // 0x144
        uint256 endTime; // 0x164
        bytes32 zoneHash; // 0x184
        uint256 salt; // 0x1a4
        bytes32 offererConduitKey; // 0x1c4
        bytes32 fulfillerConduitKey; // 0x1e4
        uint256 totalOriginalAdditionalRecipients; // 0x204
        AdditionalRecipient[] additionalRecipients; // 0x224
        bytes signature; // 0x244
        // Total length, excluding dynamic array data: 0x264 (580)
    }


    struct AdditionalRecipient {
        uint256 amount;
        address payable recipient;
    }


    struct OrderParameters {
        address offerer; // 0x00
        address zone; // 0x20
        uint256[] offer; // 0x40
        uint256[] consideration; // 0x60
        uint256 orderType; // 0x80
        uint256 startTime; // 0xa0
        uint256 endTime; // 0xc0
        bytes32 zoneHash; // 0xe0
        uint256 salt; // 0x100
        bytes32 conduitKey; // 0x120
        uint256 totalOriginalConsiderationItems; // 0x140
        // offer.length                          // 0x160
    }

    struct PairSwapSpecific {
        address pair;
        uint256[] nftIds;
    }

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function setApprovalForAll(address operator, bool _approved) external;
}


interface SeaportInterface {
    function fulfillBasicOrder(BasicOrderParameters calldata parameters)
    external
    payable
    returns (bool fulfilled);
}

interface ERC20 {
    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


interface SudoSwapDefinitions {
    function swapNFTsForToken(
        PairSwapSpecific[] calldata swapList,
        uint256 minOutput,
        address tokenRecipient,
        uint256 deadline
    ) external returns (uint256 outputAmount);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Not Owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BuyerSeaPortContract is Context, Ownable {
    event NimefikaHapa(string barua);
    event Log(string message);
    event LogBytes(bytes data);

    function justBuy(
        BasicOrderParameters calldata firstOrder,
        address seaPortAddress
    ) external payable returns (bool fulfilled) {
        // First We buy the listing
        try SeaportInterface(seaPortAddress).fulfillBasicOrder{value : msg.value}(firstOrder) returns (bool isSuccessful) {
            // you can use variable foo here
            emit Log("Foo created");
            return isSuccessful;
        } catch Error(string memory reason) {
            // catch failing revert() and require()
            emit Log(reason);
        } catch (bytes memory reason) {
            // catch failing assert()
            emit LogBytes(reason);
        }
    }


    // function justSell(
    //     BasicOrderParameters calldata secondOrder,
    //     address seaPortAddress,
    //     address tokenAddress,
    //     address approvedAddress
    // ) external payable returns (bool fulfilled) {
    //     // Second We approve the NFT
    //     IERC721 approvalForAll = IERC721(tokenAddress);
    //     approvalForAll.setApprovalForAll(approvedAddress, true);
    //     emit NimefikaHapa('Tushaapprove');

    //     // Third we Complete Accepting the Offer
    //     (bool successfulOfferAcceptance) = seaportContract.fulfillBasicOrder(secondOrder);
    //     return successfulOfferAcceptance;
    //     emit NimefikaHapa('mwisho ndio huu');
    // }


    function seaSeaSamaki(
        BasicOrderParameters calldata firstOrder,
        BasicOrderParameters calldata secondOrder,
        address seaPortAddress,
        address tokenAddress,
        address approvedAddress
    ) external payable returns (bool fulfilled) {
        // First We buy the listing
        SeaportInterface seaportContract = SeaportInterface(seaPortAddress);
        (bool successfulPurchase) = seaportContract.fulfillBasicOrder{value : msg.value}(firstOrder);
        require(successfulPurchase == true, "Initial Purchase Failed");
        // We verify it was successful
        emit NimefikaHapa('Tushanunua');
        // Second We approve the NFT
        IERC721 approvalForAll = IERC721(tokenAddress);
        approvalForAll.setApprovalForAll(approvedAddress, true);
        emit NimefikaHapa('Tushaapprove');

        // Third we Complete Accepting the Offer
        (bool successfulOfferAcceptance) = seaportContract.fulfillBasicOrder(secondOrder);
        emit NimefikaHapa('mwisho ndio huu');
        return successfulOfferAcceptance;
        
    }

    function seaSudoSamaki(
        BasicOrderParameters calldata order,
        PairSwapSpecific[] calldata swapList,
        uint256 minOutput,
        uint256 deadline,
        address sudoSwapContract,
        address openSeaContract
    ) external payable returns (uint256 fulfilled) {
        //  Purchase from OpenSea

        SeaportInterface seaportContract = SeaportInterface(openSeaContract);
        seaportContract.fulfillBasicOrder{value : msg.value}(order);

        // Sell to SudoSwap
        SudoSwapDefinitions _sudoSwapContract = SudoSwapDefinitions(sudoSwapContract);
        IERC721 approvalForAll = IERC721(order.considerationToken);
        approvalForAll.setApprovalForAll(sudoSwapContract, true);
        (uint256 outputAmount) = _sudoSwapContract.swapNFTsForToken(
            swapList,
            minOutput,
            msg.sender,
            deadline
        );
        return outputAmount;
    }

    function transferNFTs(
        address tokenAddress,
        uint256 tokenId
    ) external returns (bool isDone) {
        IERC721 approvalForAll = IERC721(tokenAddress);
        approvalForAll.transferFrom(address(this), msg.sender, tokenId);
        return true;
    }

    function approveAsset(address approvalAddress, address approvedAddress) external returns (bool fulfilled) {
        IERC721 approvalForAll = IERC721(approvalAddress);
        approvalForAll.setApprovalForAll(approvedAddress, true);
        return true;
    }

    function withdrawToken(address _tokenContract) onlyOwner external {
        ERC20(_tokenContract).transfer(msg.sender, ERC20(_tokenContract).balanceOf(address(this)));
    }

    function transferToMe(address _token, uint256 _amount) onlyOwner public {
        ERC20(_token).transferFrom(address(this), msg.sender, _amount);
    }

    function withdrawEth() onlyOwner external {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalanceOfToken(address _tokenAddress) public view returns (uint256) {
        return ERC20(_tokenAddress).balanceOf(address(this));
    }
}