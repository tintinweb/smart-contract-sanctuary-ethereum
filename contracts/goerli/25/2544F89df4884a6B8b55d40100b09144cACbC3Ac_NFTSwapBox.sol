// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./interface/INFTSwap.sol";
import "./interface/INFTSwapBoxWhitelist.sol";
import "./interface/INFTSwapBoxFees.sol";
import "./interface/INFTSwapBoxAssets.sol";
import "./interface/INFTSwapBoxHistory.sol";
import "./interface/IERC20.sol";
import "./interface/IERC721.sol";
import "./interface/IERC1155.sol";
contract NFTSwapBox is
    ReentrancyGuard,
    Ownable,
    INFTSwap,
    ERC1155Holder
{
    mapping(uint256 => SwapBox) public swapBoxes;
    mapping(uint256 => ERC20Details[]) private erc20Details;
    mapping(uint256 => ERC721Details[]) private erc721Details;
    mapping(uint256 => ERC1155Details[]) private erc1155Details;
    mapping(uint256 => uint256) public gasTokenAmount;
    mapping(uint256 => uint256[]) private offers;
    mapping(uint256 => uint256[]) private offeredList;
    mapping(uint256 => uint256) public nft_gas_SwapFee;
    mapping(uint256 => ERC20Fee[])  private erc20Fees;
    mapping(uint256 => RoyaltyFee[]) private boxRoyaltyFee;

    mapping(uint256 => address[]) public addrWhitelistedToOffer;


    uint256 private _boxesCounter;
    uint256 private _historyCounter;
    /**
        Fees List
        0: Creating a box
        1: Listing a box
        2: Offering a box
        3: Delisting a box
    */

    uint256[] public swapConstantFees = [0.0001 ether, 0.0002 ether, 0.0003 ether, 0.0004 ether];

    bool openSwap = true;

    address public NFTSwapBoxWhitelist;
    address public NFTSwapBoxFees;
    address public NFTSwapBoxHistory;
    address public withdrawOwner;

    constructor(
        address whiteList,
        address boxFee,
        address withdraw
    ) {
        NFTSwapBoxWhitelist = whiteList;
        NFTSwapBoxFees = boxFee;
        withdrawOwner =  withdraw;
    }

    modifier isOpenForSwap() {
        require(openSwap, "Swap is not allowed");
        _;
    }

    /**
        Controlling WhiteListContract, SwapboxFees, History Address
     */
    function setNFTWhiteListAddress(address nftSwapboxWhiteListAddress) public onlyOwner {
        NFTSwapBoxWhitelist = nftSwapboxWhiteListAddress;
    }

    function setNFTSwapBoxFeesAddress(address nftFeesAddress) public onlyOwner {
        NFTSwapBoxFees = nftFeesAddress;
    }

    function setNFTSwapBoxHistoryAddress(address historyAddress) public onlyOwner {
        NFTSwapBoxHistory = historyAddress;
    }
    

    /**
    SwapBox Contract State
    _new : true(possilbe swapbox)
    _new : false(impossilbe swapbox)
     */
    function setSwapState(bool _new) public onlyOwner {
        openSwap = _new;
    }

    function setWithDrawOwner(address withDrawOwner) public onlyOwner {
        withdrawOwner = withDrawOwner;
    }
    function setSwapFee(uint256 _index, uint64 _value) public onlyOwner {
        swapConstantFees[_index] = _value;
    }
    function getSwapPrices() public view returns (uint256[] memory) {
        return swapConstantFees;
    }

    /**
        Get Assets 
    */

    function getERC20Data(uint256 _boxID) public view returns(ERC20Details[] memory) {
        return erc20Details[_boxID];
    }

    function getERC721Data(uint256 _boxID) public view returns(ERC721Details[] memory) {
        return erc721Details[_boxID];
    }

    function getERC1155Data(uint256 _boxID) public view returns(ERC1155Details[] memory) {
        return erc1155Details[_boxID];
    }

    function getERC20Fee(uint256 _boxID) public view returns(ERC20Fee[] memory) {
        return erc20Fees[_boxID];
    }

    function getRoyaltyFee(uint256 _boxID) public view returns(RoyaltyFee[] memory) {
        return boxRoyaltyFee[_boxID];
    }

    function getOffers(uint256 _boxID) public view returns(uint256[] memory) {
        return offers[_boxID];
    }

    function getofferedList(uint256 _boxID) public view returns(uint256[] memory) {
        return offeredList[_boxID];
    }

    function getBoxAssets(uint256 _boxID) public view returns(ERC721Details[] memory, ERC20Details[] memory, ERC1155Details[] memory, SwapBox memory, uint256) {
        return(erc721Details[_boxID], erc20Details[_boxID], erc1155Details[_boxID], swapBoxes[_boxID], gasTokenAmount[_boxID]);
    }
    /**
        Transferring ERC20Fee
        for creating box, prepaidFees, refund assets to users
     */
    function _transferERC20Fee(
        ERC20Fee[] memory erc20fee,
        address from, 
        address to, 
        bool transferFrom
    ) internal {
        for(uint256 i = 0 ; i < erc20fee.length ; i ++) {
            if(transferFrom == true) {
                require(
                        IERC20(erc20fee[i].tokenAddr).allowance(
                            from,
                            to
                            ) >= erc20fee[i].feeAmount,
                        "not approved to swap contract"
                        );

                    IERC20(erc20fee[i].tokenAddr).transferFrom(
                        from,
                        to,
                        erc20fee[i].feeAmount
                    );
            } else {
                    IERC20(erc20fee[i].tokenAddr).transfer(
                        to,
                        erc20fee[i].feeAmount
                    );
            }
        }
    }
    /**
        Transferring Box Assets including erc721, erc20, erc1155
        for creating box, destroy box
     */
    function _transferAssetsHelper(
        ERC721Details[] memory erc721Detail,
        ERC20Details[]  memory erc20Detail,
        ERC1155Details[] memory erc1155Detail,
        address from,
        address to,
        bool transferFrom
    ) internal {
        for (uint256 i = 0; i < erc721Detail.length; i++) {

            if(erc721Detail[i].id1 == 4294967295) continue;

            IERC721(erc721Detail[i].tokenAddr).transferFrom(
                from,
                to,
                erc721Detail[i].id1
            );

            if(erc721Detail[i].id2 == 4294967295) continue;

            IERC721(erc721Detail[i].tokenAddr).transferFrom(
                from,
                to,
                erc721Detail[i].id2
            );

            if(erc721Detail[i].id3 == 4294967295) continue;

            IERC721(erc721Detail[i].tokenAddr).transferFrom(
                from,
                to,
                erc721Detail[i].id3
            );
        }
        if(transferFrom == true) {
            for (uint256 i = 0; i < erc20Detail.length; i++) {
                IERC20(erc20Detail[i].tokenAddr).transferFrom(
                    from,
                    to,
                    erc20Detail[i].amounts
                );
            }
        } else {
            for (uint256 i = 0; i < erc20Detail.length; i++) {
                IERC20(erc20Detail[i].tokenAddr).transfer(to, erc20Detail[i].amounts);
            }
        }

        for (uint256 i = 0; i < erc1155Detail.length; i++) {
            if(erc1155Detail[i].amount1 == 0) continue;
            if(erc1155Detail[i].amount2 == 0) {
                uint256 [] memory ids = new uint256[](1);
                ids[0] = erc1155Detail[i].id1;
                uint256 [] memory amounts = new uint256[](1);
                amounts[0] = erc1155Detail[i].amount1; 
                IERC1155(erc1155Detail[i].tokenAddr).safeBatchTransferFrom(
                    from,
                    to,
                    ids,
                    amounts,
                    ""
                );
            } else {
                uint256 [] memory ids = new uint256[](2);
                ids[0] = erc1155Detail[i].id1;
                ids[1] = erc1155Detail[i].id2;
                uint256 [] memory amounts = new uint256[](2);
                amounts[0] = erc1155Detail[i].amount1;
                amounts[1] = erc1155Detail[i].amount2;
                IERC1155(erc1155Detail[i].tokenAddr).safeBatchTransferFrom(
                    from,
                    to,
                    ids,
                    amounts,
                    ""
                );
            }
        }
    }
    /**
    Check OfferState
    if return is true : it is offered
    if return is false : it is not offered
    */
    function _checkOfferState(
        uint256 listBoxID,
        uint256 offerBoxID
    ) internal view returns (bool) {
        for (uint256 i = 0; i < offers[listBoxID].length; i++) {
            if(offers[listBoxID][i] == offerBoxID)
                return true;
        }

        return false;
    }

    function _transferSwapFees(
        uint256 boxID,
        address to,
        bool swapped
    ) internal {
        payable(to).transfer(nft_gas_SwapFee[boxID]);
        _transferERC20Fee(erc20Fees[boxID], address(this), to, false);

        uint256 royaltyFeeLength = boxRoyaltyFee[boxID].length;
        if(!swapped) {
            for(uint256 i = 0; i < royaltyFeeLength; i++){
                payable(to).transfer(boxRoyaltyFee[boxID][i].feeAmount);
            }
        } else {
            for(uint256 i = 0; i < royaltyFeeLength; i++){
                payable(boxRoyaltyFee[boxID][i].reciever).transfer(boxRoyaltyFee[boxID][i].feeAmount);
            }
        }
        }

    function _checkingBoxAssetsCounter(
        ERC721Details[] memory _erc721Details,
        ERC20Details[] memory _erc20Details,
        ERC1155Details[] memory _erc1155Details,
        uint256 _gasTokenAmount
    ) internal pure returns (uint256) {
        uint256 assetCounter;

        for(uint256 i ; i < _erc721Details.length ; ++i){
            if(_erc721Details[i].id1 == 4294967295) continue;
                ++assetCounter;
            if(_erc721Details[i].id2 == 4294967295) continue;
                ++assetCounter;
            if(_erc721Details[i].id3 == 4294967295) continue;
                ++assetCounter;
        }

        for(uint256 i ; i < _erc1155Details.length ; ++i){
            if(_erc1155Details[i].amount1 == 0) continue;
                assetCounter += _erc1155Details[i].amount1;
            if(_erc1155Details[i].amount2 == 0) continue;
                assetCounter += _erc1155Details[i].amount2;
        }

        if(_erc20Details.length > 0)
            ++assetCounter;

        if(_gasTokenAmount > 0)
            ++assetCounter;

        return assetCounter;
    }

     //check availabe offerAddress for listing box
    function _checkAvailableOffer(uint256 boxID, address offerAddress) internal view returns(bool) {
        for(uint256 i = 0; i < addrWhitelistedToOffer[boxID].length; i++) {
            if(addrWhitelistedToOffer[boxID][i] == offerAddress)
                return true;
        }
        return false;
    }

    //Delect SwapBoxAssets

    function _deleteAssets(uint256 boxID) internal {
        delete swapBoxes[boxID];
        delete erc20Details[boxID];
        delete erc721Details[boxID];
        delete erc1155Details[boxID];
        delete gasTokenAmount[boxID];
        delete erc20Fees[boxID];
        delete boxRoyaltyFee[boxID];
        delete nft_gas_SwapFee[boxID];
        delete offers[boxID];
        delete offeredList[boxID];
        delete addrWhitelistedToOffer[boxID];
    }

    function createBox(
        ERC721Details[] calldata _erc721Details,
        ERC20Details[] calldata _erc20Details,
        ERC1155Details[] calldata _erc1155Details,
        uint256 _gasTokenAmount,
        address[] memory offerAddress,
        uint256 state
    ) public payable isOpenForSwap nonReentrant {

        require(_erc721Details.length + _erc20Details.length + _erc1155Details.length + _gasTokenAmount > 0,"No Assets");
        require(state == 1 || state == 2, "Invalid state");

        uint256 createFees = _checkingBoxAssetsCounter(_erc721Details, _erc20Details, _erc1155Details, _gasTokenAmount) * swapConstantFees[0];

        uint256 swapFees = INFTSwapBoxFees(NFTSwapBoxFees)._checknftgasfee(
            _erc721Details,
            _erc1155Details,
            _gasTokenAmount,
            msg.sender
        );

        RoyaltyFee[] memory royaltyFees = INFTSwapBoxFees(NFTSwapBoxFees)._checkRoyaltyFee(
            _erc721Details,
            _erc1155Details,
            msg.sender
        );

        ERC20Fee[] memory erc20swapFees = INFTSwapBoxFees(NFTSwapBoxFees)._checkerc20Fees(
            _erc20Details,
            msg.sender
        );
        
        uint256 boxroyaltyFees; 
          for (uint256 i = 0; i < royaltyFees.length; i++){
            boxroyaltyFees += royaltyFees[i].feeAmount;
        }

        if(state == 1){
            require(
                msg.value == createFees + _gasTokenAmount + swapConstantFees[1] + swapFees + boxroyaltyFees, "Insufficient Creating Fee"
            );
        } else {
            require(
                msg.value == createFees + _gasTokenAmount + swapConstantFees[2] + swapFees + boxroyaltyFees, "Insufficient Offering Fee"
            );
        }

        INFTSwapBoxWhitelist(NFTSwapBoxWhitelist)._checkAssets(
            _erc721Details,  
            _erc20Details,
            _erc1155Details,
            msg.sender,
            address(this)
        );

        _transferAssetsHelper(
            _erc721Details,
            _erc20Details,
            _erc1155Details,
            msg.sender,
            address(this),
            true
        );

        payable(withdrawOwner).transfer(createFees);

        ++_boxesCounter;


        SwapBox storage box = swapBoxes[_boxesCounter];
        box.id = uint32(_boxesCounter);
        box.owner = msg.sender;
        box.state = uint32(state);

        for(uint256 i ; i < _erc20Details.length; ++i) 
            erc20Details[_boxesCounter].push(_erc20Details[i]);

        for(uint256 i ; i < _erc721Details.length; ++i)
            erc721Details[_boxesCounter].push(_erc721Details[i]);

        for(uint256 i ; i < _erc1155Details.length; ++i)
            erc1155Details[_boxesCounter].push(_erc1155Details[i]);

        gasTokenAmount[_boxesCounter] = _gasTokenAmount;

        nft_gas_SwapFee[_boxesCounter] = swapFees;
        for(uint256 i ; i < erc20swapFees.length ; ++i)
            erc20Fees[_boxesCounter].push(erc20swapFees[i]);
        for(uint256 i ; i < royaltyFees.length ; ++i)
            boxRoyaltyFee[_boxesCounter].push(royaltyFees[i]);

        if(state == 1)
            payable(withdrawOwner).transfer(swapConstantFees[1]);

        if(offerAddress.length > 0) {
            for(uint256 i ; i < offerAddress.length ; ++i){
                addrWhitelistedToOffer[_boxesCounter][i] = offerAddress[i];
            }
            box.whiteListOffer = 1;
        }

        emit SwapBoxState(
            uint32(_boxesCounter),
            uint8(state)
        );
    }

    // Destroy Box. all assets back to owner's wallet
    function withdrawBox(uint256 boxID)
        payable
        public
        isOpenForSwap
        nonReentrant
    {

        require(
            swapBoxes[boxID].owner == msg.sender,
            "only Owner of SwapBox"
        );

        if(swapBoxes[boxID].state == 1) {

            require(msg.value == offers[boxID].length * swapConstantFees[3], "Insufficient Fee for Delisting");

        }

        _transferAssetsHelper(
            erc721Details[boxID],
            erc20Details[boxID],
            erc1155Details[boxID],
            address(this),
            msg.sender,
            false
        );

        if (gasTokenAmount[boxID] > 0) {
            payable(msg.sender).transfer(gasTokenAmount[boxID]);
        }

        _transferSwapFees(
            boxID,
            msg.sender,
            false
        );
        
        _deleteAssets(boxID);

        emit SwapBoxState(
            uint32(boxID),
            3
        );
    }
    /**
        Changine BoxState
        when box sate is 1(waiting_for_offeres), state will  change as state 2(offered)
     */
    function changeBoxState (uint256 boxID) public payable isOpenForSwap nonReentrant {
        require(
            swapBoxes[boxID].owner == msg.sender,
            "only Owner of SwapBox"
        );
        
        if(swapBoxes[boxID].state == 1){
            require(swapBoxes[boxID].state != 2,"Not Allowed");
            require(msg.value ==  offers[boxID].length * swapConstantFees[3], "Insufficient Fee for Delisting");

            delete offers[boxID];
            delete addrWhitelistedToOffer[boxID];

            swapBoxes[boxID].state = 2;
        }
        else {
            require(msg.value == swapConstantFees[1], "Insufficient Fee for listing");
            delete offeredList[boxID];

            swapBoxes[boxID].state = 1;
        }

        emit SwapBoxState(
            uint32(boxID),
            uint8(swapBoxes[boxID].state)
        );
    }

    // Link your Box to other's waiting Box. Equal to offer to other Swap Box
    function offerBox(uint256 listBoxID, uint256 offerBoxID)
        public
        payable
        isOpenForSwap
        nonReentrant
    {
        require(
            swapBoxes[offerBoxID].state == 2,
            "Not Allowed"
        );
        require(
            swapBoxes[offerBoxID].owner == msg.sender,
            "only Owner of SwapBox"
        );
        require(
            _checkOfferState(listBoxID, offerBoxID) == false,
            "already linked"
        );
        require(
            swapBoxes[listBoxID].state == 1,
            "not Waiting_for_offer State"
        );
        require(msg.value == swapConstantFees[2], "Insufficient Fee for making an offer");

        if(swapBoxes[listBoxID].whiteListOffer == 1)
            require(_checkAvailableOffer(listBoxID, msg.sender) == true, "Not listed Offer Address");

        payable(withdrawOwner).transfer(swapConstantFees[2]);

        offers[listBoxID].push(offerBoxID);
        offeredList[offerBoxID].push(listBoxID);

        emit SwapBoxOffer(uint32(listBoxID), uint32(offerBoxID));
    }

    // Swaping Box. Owners of Each Swapbox should be exchanged
    function swapBox(uint256 listBoxID, uint256 offerBoxID)
        public
        isOpenForSwap
    {
        require(
            swapBoxes[listBoxID].owner == msg.sender,
            "only Owner of SwapBox"
        );
        require(
            swapBoxes[listBoxID].state == 1,
            "Not Allowed"
        );
        require(
            swapBoxes[offerBoxID].state == 2,
            "Not offered"
        );
        require(
            _checkOfferState(listBoxID, offerBoxID),
            "not exist or active"
        );

        _transferSwapFees(
            listBoxID,
            withdrawOwner,
            true);
        _transferSwapFees(
            offerBoxID,
            withdrawOwner,
            true);

        _transferAssetsHelper(
            erc721Details[listBoxID],
            erc20Details[listBoxID],
            erc1155Details[listBoxID],
            address(this),
            swapBoxes[offerBoxID].owner,
            false
        );

        if(gasTokenAmount[listBoxID] > 0)
            payable(swapBoxes[offerBoxID].owner).transfer(gasTokenAmount[listBoxID]);

        _transferAssetsHelper(
            erc721Details[offerBoxID],
            erc20Details[offerBoxID],
            erc1155Details[offerBoxID],
            address(this),
            swapBoxes[listBoxID].owner,
            false
        );

        if(gasTokenAmount[offerBoxID] > 0)
            payable(swapBoxes[offerBoxID].owner).transfer(gasTokenAmount[listBoxID]);
        // INFTSwapBoxHistory(NFTSwapBoxHistory).addHistoryUserSwapFees(
        //     _historyCounter,
        //     swapBoxes[listBoxID],
        //     swapBoxes[offerBoxID]);

        emit Swaped(
            _historyCounter,
            listBoxID,
            swapBoxes[listBoxID].owner,
            offerBoxID,
            swapBoxes[offerBoxID].owner
        );
        
        
        _deleteAssets(listBoxID);
        _deleteAssets(offerBoxID);

        // _historyCounter++;
    }
    // WithDraw offer from linked offer
    function withDrawOffer(uint256 listBoxID, uint256 offerBoxID)
        public
        isOpenForSwap
        nonReentrant
    {
        require(
            swapBoxes[offerBoxID].owner == msg.sender,
            "only Owner of SwapBox"
        );

        uint256 offerLength =  offers[listBoxID].length;
        for(uint256 i ; i < offerLength ; ++i) {
            if(offers[listBoxID][i] == offerBoxID)
                delete offers[listBoxID][i];
        }

        emit SwapBoxWithDrawOffer(uint32(listBoxID), uint32(offerBoxID));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTSwap {

    event SwapBoxState(
        uint32 boxID,
        uint8 state
    );

    event SwapBoxOffer(
        uint32 listBoxID,
        uint32 OfferBoxID
    );

    event Swaped (
        uint256 historyID,
        uint256 listID,
        address listBoxOwner,
        uint256 offerID,
        address offerBoxOwner
    );

    event SwapBoxWithDrawOffer(
        uint32 listSwapBoxID,
        uint32 offerSwapBoxID
    );

    struct ERC20Details {
        address tokenAddr;
        uint96 amounts;
    }

    struct ERC721Details {
        address tokenAddr;
        uint32 id1;
        uint32 id2;
        uint32 id3;
    }

    struct ERC1155Details {
        address tokenAddr;
        uint32 id1;
        uint32 id2;
        uint16 amount1;
        uint16 amount2;
    }

    struct ERC20Fee {
        address tokenAddr;
        uint96 feeAmount;
    }

    struct RoyaltyFee {
        address reciever;
        uint96 feeAmount;
    }


    struct SwapBox {
        address owner;
        uint32 id;
        uint32 state;
        uint32 whiteListOffer;
    }
    
    struct SwapBoxConfig {
        uint8 usingERC721WhiteList;
        uint8 usingERC1155WhiteList;
        uint8 NFTTokenCount;
        uint8 ERC20TokenCount;
    }

    struct UserTotalSwapFees {
        address owner;
        uint256 nftFees;
        ERC20Fee[] totalERC20Fees;
    }

    struct SwapHistory {
        uint256 id;
        uint256 listId;
        address listOwner;
        uint256 offerId;
        address offerOwner;
        uint256 swapedTime;
    }

    struct Discount {
        address user;
        address nft;
    }

    struct PrePaidFee {
        uint256 nft_gas_SwapFee;
        ERC20Fee[] erc20Fees;
        RoyaltyFee[] royaltyFees;
    }

    enum State {    
        Waiting_for_offers,
        Offered
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTSwap.sol";

interface INFTSwapBoxWhitelist is INFTSwap {

    function _checkAssets(
        ERC721Details[] calldata,
        ERC20Details[] calldata,
        ERC1155Details[] calldata,
        address,
        address
    ) external view;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTSwap.sol";
interface INFTSwapBoxFees is INFTSwap {

    function _checkerc20Fees(
        ERC20Details[] calldata,
        address
    ) external view returns(ERC20Fee[] memory);

    function _checknftgasfee(
        ERC721Details[] calldata,
        ERC1155Details[] calldata,
        uint256,
        address
    ) external view returns(uint256);

    function _checkRoyaltyFee(
        ERC721Details[] calldata,
        ERC1155Details[] calldata,
        address
    ) external view returns(RoyaltyFee[] memory);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTSwap.sol";

interface INFTSwapBoxAssets is INFTSwap {
    
    function _transferERC20Fee(ERC20Fee[] calldata, address, address, bool) external;
    function _transferAssetsHelper(ERC721Details[] calldata, ERC20Details[] calldata, ERC1155Details[] calldata, address, address, bool) external;
    function _setOfferAdddress(uint256, address[] calldata) external;
    function _checkAvailableOffer(uint256, address) external view returns(bool);
    function _deleteOfferAddress(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTSwap.sol";

interface INFTSwapBoxHistory is INFTSwap {
    // function addHistoryUserSwapFees(uint256, SwapBox memory, SwapBox memory) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;
interface IERC721{
    function balanceOf(address owner) external view returns (uint256 balance);
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interface/INFTSwap.sol";

contract NFTSwapFeeDiscount is AccessControl {

    bytes32 public constant MANAGER = 0x0000000000000000000000000000000000000000000000000000000000000001;
    bytes32 public constant ADMIN = 0x0000000000000000000000000000000000000000000000000000000000000000;

    constructor(address _admin, address _manager) {
        _setupRole(MANAGER, _manager);
        _setupRole(ADMIN, _admin);
    }
    mapping(address => uint256) private userDiscount;
    mapping(address => uint256) private nftDiscount;

    function setUserDiscount(address userAddress, uint256 percentage) external {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender), "Not member");
        require(percentage > 100 && percentage <= 10000, "percentage must be between 1 and 100");
        userDiscount[userAddress] = percentage;
    }

    function setNFTDiscount(address nftAddress, uint256 percentage) external {
        require(hasRole(ADMIN, msg.sender), "Not Admin");
        require(percentage > 100 && percentage <= 10000, "percentage must be between 1 and 100");
        nftDiscount[nftAddress] = percentage;
    }

    function getUserDiscount(address userAddress) external view returns(uint256) {
        return userDiscount[userAddress];
    }

    function getNFTDiscount(address nftAddress) external view returns(uint256) {
        return nftDiscount[nftAddress];
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interface/INFTSwap.sol";
import "./interface/IERC20.sol";
import "./interface/IERC721.sol";
import "./interface/IERC1155.sol";

contract NFTSwapBoxWhitelist is INFTSwap, AccessControl {

    bytes32 public constant MANAGER = 0x0000000000000000000000000000000000000000000000000000000000000001;
    bytes32 public constant ADMIN = 0x0000000000000000000000000000000000000000000000000000000000000000;
    SwapBoxConfig private swapConfig;
    address[] public whitelistERC20Tokens;
    address[] public whitelistERC721Tokens;
    address[] public whitelistERC1155Tokens;

    /// @dev Add `root` to the admin role as a member.
    constructor(address _admin, address _manager) {
        _setupRole(MANAGER, _manager);
        _setupRole(ADMIN, _admin);
        swapConfig.usingERC721WhiteList = 1;
        swapConfig.usingERC1155WhiteList = 1;
        swapConfig.NFTTokenCount = 5;
        swapConfig.ERC20TokenCount = 5;
    }

    /**
        SetSwapConfig(usingERC721WhiteList, usingERC1155WhiteList, NFTTokenCount, ERC20TokenCount)
     */

    function setUsingERC721Whitelist(uint256 usingList) external  onlyRole(ADMIN) {
        swapConfig.usingERC721WhiteList = uint8(usingList);
    }

    function setUsingERC1155Whitelist(uint256 usingList) external  onlyRole(ADMIN) {
        swapConfig.usingERC1155WhiteList = uint8(usingList);
    }

    function setNFTTokenCount(uint256 limitTokenCount) external  onlyRole(ADMIN) {
        swapConfig.NFTTokenCount = uint8(limitTokenCount);
    }

    function setERC20TokenCount(uint256 limitERC20Count) external  onlyRole(ADMIN) {
        swapConfig.ERC20TokenCount = uint8(limitERC20Count);
    }
    /**
    Getting swapConfig((usingERC721WhiteList, usingERC1155WhiteList, NFTTokenCount, ERC20TokenCount))
    */
    function getSwapConfig() external view returns(SwapBoxConfig memory) {
        return swapConfig;
    }
    /**
        check assets for creating swapBox
     */
    function _checkAssets(
        ERC721Details[]  calldata erc721Details,
        ERC20Details[] calldata erc20Details,
        ERC1155Details[] calldata erc1155Details,
        address offer,
        address swapBox
    ) external view {
        require(
            (erc721Details.length + erc1155Details.length) <=
                swapConfig.NFTTokenCount,
            "Too much NFTs selected"
        );

        for (uint256 i = 0; i < erc721Details.length; i++) {
            require(
                validateWhiteListERC721Token(erc721Details[i].tokenAddr),
                "Not Allowed ERC721 Token"
            );

            require(
                erc721Details[i].id1 != 4294967295,
                "Non included ERC721 token"
            );

            require(
                IERC721(erc721Details[i].tokenAddr).getApproved(
                    erc721Details[i].id1
                ) == swapBox || IERC721(erc721Details[i].tokenAddr).isApprovedForAll(offer,swapBox) == true,
                "ERC721 tokens must be approved to swap contract"
            );

            if(erc721Details[i].id2 == 4294967295) continue;

            require(
                IERC721(erc721Details[i].tokenAddr).getApproved(
                    erc721Details[i].id2
                ) == swapBox || IERC721(erc721Details[i].tokenAddr).isApprovedForAll(offer,swapBox) == true,
                "ERC721 tokens must be approved to swap contract"
            );

            if(erc721Details[i].id3 == 4294967295) continue;

            require(
                IERC721(erc721Details[i].tokenAddr).getApproved(
                    erc721Details[i].id3
                ) == swapBox || IERC721(erc721Details[i].tokenAddr).isApprovedForAll(offer,swapBox) == true,
                "ERC721 tokens must be approved to swap contract"
            );
        }

        require(
            erc20Details.length <= swapConfig.ERC20TokenCount,
            "Too much ERC20 tokens selected"
        );

        for (uint256 i = 0; i < erc20Details.length; i++) {
            require(
                validateWhiteListERC20Token(erc20Details[i].tokenAddr),
                "Not Allowed ERC20 Tokens"
            );
            require(
                IERC20(erc20Details[i].tokenAddr).allowance(
                    offer,
                    swapBox
                ) >= erc20Details[i].amounts,
                "ERC20 tokens must be approved to swap contract"
            );
            require(
                IERC20(erc20Details[i].tokenAddr).balanceOf(offer) >=
                    erc20Details[i].amounts,
                "Insufficient ERC20 tokens"
            );
        }

        for (uint256 i = 0; i < erc1155Details.length; i++) {
            require(
                validateWhiteListERC1155Token(erc1155Details[i].tokenAddr),
                "Not Allowed ERC1155 Token"
            );
            
            require(erc1155Details[i].amount1 != 0, "Non included ERC1155 token");

            require(
                IERC1155(erc1155Details[i].tokenAddr).balanceOf(
                    offer,
                    erc1155Details[i].id1
                ) >= erc1155Details[i].amount1,
                "Insufficient ERC1155 Balance"
            );

            require(
                IERC1155(erc1155Details[i].tokenAddr).isApprovedForAll(
                    offer,
                    swapBox
                ),
                "ERC1155 token must be approved to swap contract"
            );

            if(erc1155Details[i].amount2 != 0) {
                require(
                    IERC1155(erc1155Details[i].tokenAddr).balanceOf(
                        offer,
                        erc1155Details[i].id2
                    ) >= erc1155Details[i].amount2,
                    "Insufficient ERC1155 Balance"
                );
            }

        }
    }
    /**
        add tokens to Whitelist
     */

    function whiteListERC20Token(address erc20Token) public {
        require(hasRole(ADMIN, msg.sender), "Not Admin");
        require(
            validateWhiteListERC20Token(erc20Token) == false,
            "Exist Token"
        );
        whitelistERC20Tokens.push(erc20Token);
    }

    function whiteListERC721Token(address erc721Token) public {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender) , "Not member");
        
        require(
            validateWhiteListERC721Token(erc721Token) == false,
            "Exist Token"
        );
        whitelistERC721Tokens.push(erc721Token);
    }

    function whiteListERC1155Token(address erc1155Token)
        public
    {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender) , "Not member");
        require(
            validateWhiteListERC1155Token(erc1155Token) == false,
            "Exist Token"
        );
        whitelistERC1155Tokens.push(erc1155Token);
    }
    /**
        Get function for whitelist
     */

    function getERC20WhiteListTokens() public view returns (address[] memory) {
        return whitelistERC20Tokens;
    }

    function getERC721WhiteListTokens() public view returns (address[] memory) {
        return whitelistERC721Tokens;
    }

    function getERC1155WhiteListTokens()
        public
        view
        returns (address[] memory)
    {
        return whitelistERC1155Tokens;
    }

    /**
        RemoveToken from WhiteList
     */
    function removeFromERC20WhiteList(uint256 index) external {
        require(hasRole(ADMIN, msg.sender), "Not Admin");
        require(index < whitelistERC20Tokens.length, "Invalid element");
        whitelistERC20Tokens[index] = whitelistERC20Tokens[
            whitelistERC20Tokens.length - 1
        ];
        whitelistERC20Tokens.pop();
    }

    function removeFromERC721WhiteList(uint256 index) external {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender) , "Not member");
        require(index < whitelistERC721Tokens.length, "Invalid element");
        whitelistERC721Tokens[index] = whitelistERC721Tokens[
            whitelistERC721Tokens.length - 1
        ];
        whitelistERC721Tokens.pop();
    }

    function removeFromERC1155WhiteList(uint256 index) external {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender) , "Not member");
        require(index < whitelistERC1155Tokens.length, "Invalid element");
        whitelistERC1155Tokens[index] = whitelistERC1155Tokens[
            whitelistERC1155Tokens.length - 1
        ];
        whitelistERC1155Tokens.pop();
    }

    // Checking whitelist ERC20 Token
    function validateWhiteListERC20Token(address erc20Token)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < whitelistERC20Tokens.length; i++) {
            if (whitelistERC20Tokens[i] == erc20Token) {
                return true;
            }
        }

        return false;
    }

    // Checking whitelist ERC721 Token
    function validateWhiteListERC721Token(address erc721Token)
        public
        view
        returns (bool)
    {
        if (swapConfig.usingERC721WhiteList == 0) return true;

        for (uint256 i = 0; i < whitelistERC721Tokens.length; i++) {
            if (whitelistERC721Tokens[i] == erc721Token) {
                return true;
            }
        }

        return false;
    }

    // Checking whitelist ERC1155 Token
    function validateWhiteListERC1155Token(address erc1155Token)
        public
        view
        returns (bool)
    {
        if (swapConfig.usingERC1155WhiteList == 0) return true;

        for (uint256 i = 0; i < whitelistERC1155Tokens.length; i++) {
            if (whitelistERC1155Tokens[i] == erc1155Token) {
                return true;
            }
        }

        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interface/INFTSwap.sol";
import "./interface/INFTSwapFeeDiscount.sol";

contract NFTSwapBoxFees is INFTSwap,AccessControl {
    using SafeMath for uint256;
    bytes32 public constant MANAGER = 0x0000000000000000000000000000000000000000000000000000000000000001;
    bytes32 public constant ADMIN = 0x0000000000000000000000000000000000000000000000000000000000000000;

    uint256 public defaultNFTSwapFee = 0.0001 ether;
    uint256 public defaultTokenSwapPercentage;
    uint256 public defaultGasTokenSwapPercentage;

    mapping(address => uint256) public NFTSwapFee;
    mapping(address => uint256) public ERC20SwapFee;
    mapping(address => RoyaltyFee) public NFTRoyaltyFee;

    address public nftSwapFeeDiscount;

    /// @dev Add `root` to the admin role as a member.
    constructor(address _admin, address _manager) {
        _setupRole(MANAGER, _manager);
        _setupRole(ADMIN, _admin);
    }

    function setDefaultNFTSwapFee(uint256 fee) external {
        require(hasRole(ADMIN, msg.sender), "Not Admin");
        require(fee > 0, "fee must be greate than 0");
        defaultNFTSwapFee = fee;
    }

    function setDefaultTokenSwapPercentage(uint256 fee) public  {
        require(hasRole(ADMIN, msg.sender), "Not Admin");
        require(fee > 100 && fee <= 10000, "fee must be between 100 and 10000");
        defaultTokenSwapPercentage = fee;
    }

    function setDefaultGasTokenSwapPercentage(uint256 fee) public {
        require(hasRole(ADMIN, msg.sender), "Not Admin");
        require(fee > 100 && fee <= 10000, "fee must be between 100 and 10000");
        defaultGasTokenSwapPercentage = fee;
    }

    function setNFTSwapFee(address nftAddress, uint256 fee) public {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender), "Not member");
        require(fee > 0, "fee must be greate than 0");
        NFTSwapFee[nftAddress] = fee;
    }

    function setNFTRoyaltyFee(address nftAddress, uint256 fee, address receiver) public {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender), "Not member");
        require(fee > 0, "fee must be greate than 0");
        NFTRoyaltyFee[nftAddress].feeAmount = uint96(fee);
        NFTRoyaltyFee[nftAddress].reciever = receiver;
    }

    function setERC20Fee(address erc20Address, uint256 fee) public {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender), "Not member");
        require(fee > 100 && fee <= 10000, "fee must be greate than 0");
        ERC20SwapFee[erc20Address] = fee;
    }

    function setNFTSwapDiscountAddress(address addr) public {
        require(hasRole(ADMIN, msg.sender) || hasRole(MANAGER, msg.sender), "Not member");
        nftSwapFeeDiscount = addr;
    }

    function getNFTSwapFee(address nftAddress) public view returns(uint256) {
        return NFTSwapFee[nftAddress];
    }

    function getRoyaltyFee(address nftAddress) public view returns(RoyaltyFee memory) {
        return NFTRoyaltyFee[nftAddress];
    }

    function getERC20Fee(address erc20Address) public view returns(uint256) {
        return ERC20SwapFee[erc20Address];
    }

    // function _getNFTLength(
    //     ERC721Details[] memory _erc721Details,
    //     ERC1155Details[] memory _erc1155Details
    // ) internal view returns(uint256) {

    //     uint256 royaltyLength;
    //     for(uint256 i ; i < _erc721Details.length ; ++i) { 
    //         if(NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount > 0)
    //             ++royaltyLength;
    //     }

    //     for(uint256 i ; i < _erc1155Details.length ; ++i) { 
    //         if(NFTRoyaltyFee[_erc1155Details[i].tokenAddr].feeAmount > 0)
    //             ++royaltyLength;
    //     }

    //     return royaltyLength;
    // }

    function _checkerc20Fees(
        ERC20Details[] memory _erc20Details,
        address boxOwner
    ) external view returns(ERC20Fee[] memory) {
        uint256 erc20fee;
        ERC20Fee [] memory fees = new ERC20Fee[](_erc20Details.length);
        uint256 userDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getUserDiscount(boxOwner);

        for(uint256 i ; i < _erc20Details.length ; ++i) {
            erc20fee = 0;
            if(ERC20SwapFee[_erc20Details[i].tokenAddr] > 0)
                erc20fee = _erc20Details[i].amounts * ERC20SwapFee[_erc20Details[i].tokenAddr];
            else
                erc20fee = _erc20Details[i].amounts * defaultTokenSwapPercentage;
            erc20fee -= erc20fee * userDiscount / 10000;
            fees[i].tokenAddr = _erc20Details[i].tokenAddr;
            fees[i].feeAmount = uint96(erc20fee / 10000);
        }
        return fees;
    }
    
    function _checknftgasfee(
        ERC721Details[] memory _erc721Details,
        ERC1155Details[] memory _erc1155Details,
        uint256 _gasTokenAmount,
        address boxOwner
    ) external view returns(uint256){
        uint256 userDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getUserDiscount(boxOwner);
        uint256 erc721Fee;
        uint256 erc1155Fee;
        uint256 gasFee;
        for(uint256 i ; i < _erc721Details.length ; ++i) {
            uint256 nftDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getNFTDiscount(_erc721Details[i].tokenAddr);

            if(NFTSwapFee[_erc721Details[i].tokenAddr] == 0 && _erc721Details[i].id1 != 4294967295)
                erc721Fee += defaultNFTSwapFee;
            if(NFTSwapFee[_erc721Details[i].tokenAddr] == 0 && _erc721Details[i].id2 != 4294967295)
                erc721Fee += defaultNFTSwapFee;
            if(NFTSwapFee[_erc721Details[i].tokenAddr] == 0 && _erc721Details[i].id3 != 4294967295)
                erc721Fee += defaultNFTSwapFee;

            if(NFTSwapFee[_erc721Details[i].tokenAddr] != 0 && _erc721Details[i].id1 != 4294967295)
                erc721Fee += NFTSwapFee[_erc721Details[i].tokenAddr];
            if(NFTSwapFee[_erc721Details[i].tokenAddr] != 0 && _erc721Details[i].id2 != 4294967295)
                erc721Fee += NFTSwapFee[_erc721Details[i].tokenAddr];
            if(NFTSwapFee[_erc721Details[i].tokenAddr] != 0 && _erc721Details[i].id3 != 4294967295)
                erc721Fee += NFTSwapFee[_erc721Details[i].tokenAddr];    

            if(nftDiscount > userDiscount) {
                erc721Fee -= erc721Fee * nftDiscount / 10000;
            }
            else {  
                erc721Fee -= erc721Fee * userDiscount / 10000;
            }
        }

        for(uint256 i ; i < _erc1155Details.length ; ++i) {
            uint256 nftDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getNFTDiscount(_erc1155Details[i].tokenAddr);
            if(NFTSwapFee[_erc1155Details[i].tokenAddr] == 0 && _erc1155Details[i].amount1 != 0)
                erc1155Fee += defaultNFTSwapFee * _erc1155Details[i].amount1;
            if(NFTSwapFee[_erc1155Details[i].tokenAddr] == 0 && _erc1155Details[i].amount2 != 0)
               erc1155Fee += defaultNFTSwapFee * _erc1155Details[i].amount2;
            
            if(NFTSwapFee[_erc1155Details[i].tokenAddr] != 0 && _erc1155Details[i].amount1 != 0)
                erc1155Fee += NFTSwapFee[_erc1155Details[i].tokenAddr] * _erc1155Details[i].amount1;
            if(NFTSwapFee[_erc1155Details[i].tokenAddr] != 0 && _erc1155Details[i].amount2 != 0)
                erc1155Fee += NFTSwapFee[_erc1155Details[i].tokenAddr] * _erc1155Details[i].amount2;

            if(nftDiscount > userDiscount) {
                erc1155Fee -= erc1155Fee * nftDiscount / 10000;
            }
            else {  
                erc1155Fee -= erc1155Fee * userDiscount / 10000;
            }
        }

        if(_gasTokenAmount > 0)
            gasFee = _gasTokenAmount *  defaultGasTokenSwapPercentage / 10000;
        gasFee -= gasFee * userDiscount / 10000;

        return erc721Fee + erc1155Fee + gasFee;
    }

    function _checkRoyaltyFee(
        ERC721Details[] memory _erc721Details,
        ERC1155Details[] memory _erc1155Details,
        address boxOwner
    ) external view returns(RoyaltyFee[] memory) {
        RoyaltyFee[] memory royalty = new RoyaltyFee[](_erc721Details.length + _erc1155Details.length);
       
        uint256 nftIndex;
        uint256 userDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getUserDiscount(boxOwner);

        for(uint256 i ; i < _erc721Details.length ; ++i) {
            uint256 nftDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getNFTDiscount(_erc721Details[i].tokenAddr);

            if(NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount != 0 && _erc721Details[i].id1 != 4294967295)
                royalty[nftIndex].feeAmount += NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount;
            if(NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount != 0 && _erc721Details[i].id2 != 4294967295)
                royalty[nftIndex].feeAmount += NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount;
            if(NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount != 0 && _erc721Details[i].id3 != 4294967295)
                royalty[nftIndex].feeAmount += NFTRoyaltyFee[_erc721Details[i].tokenAddr].feeAmount;

            if(nftDiscount > userDiscount) {
                royalty[nftIndex].feeAmount -= uint96(royalty[nftIndex].feeAmount * nftDiscount / 10000);
            }
            else {  
                royalty[nftIndex].feeAmount -= uint96(royalty[nftIndex].feeAmount * userDiscount / 10000);
            }

            royalty[nftIndex].reciever = NFTRoyaltyFee[_erc721Details[i].tokenAddr].reciever;
            ++nftIndex;
        }

        for(uint256 i ; i < _erc1155Details.length ; ++i) {
            uint256 nftDiscount = INFTSwapFeeDiscount(nftSwapFeeDiscount).getNFTDiscount(_erc1155Details[i].tokenAddr);
            
            if(NFTRoyaltyFee[_erc1155Details[i].tokenAddr].feeAmount != 0 && _erc1155Details[i].amount1 != 0)
                royalty[nftIndex].feeAmount += NFTRoyaltyFee[_erc1155Details[i].tokenAddr].feeAmount * _erc1155Details[i].amount1;   
            if(NFTRoyaltyFee[_erc1155Details[i].tokenAddr].feeAmount != 0 && _erc1155Details[i].amount2 != 0)
                royalty[nftIndex].feeAmount += NFTRoyaltyFee[_erc1155Details[i].tokenAddr].feeAmount * _erc1155Details[i].amount2;   

            if(nftDiscount > userDiscount){
                royalty[nftIndex].feeAmount -= uint96(royalty[nftIndex].feeAmount * nftDiscount / 10000);
            }
            else{
                royalty[nftIndex].feeAmount -= uint96(royalty[nftIndex].feeAmount * userDiscount / 10000);
            }

            royalty[nftIndex].reciever = NFTRoyaltyFee[_erc1155Details[i].tokenAddr].reciever;
            ++nftIndex;
        }

        return royalty;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTSwapFeeDiscount {
    function getUserDiscount(address) external view returns(uint256);
    function getNFTDiscount(address) external view returns(uint256);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}