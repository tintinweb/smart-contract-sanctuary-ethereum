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
    function changeBoxState (
        uint256 boxID,
        address[] memory offerAddress
    ) public payable isOpenForSwap nonReentrant {
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
            if(offerAddress.length > 0) {
                for(uint256 i ; i < offerAddress.length ; ++i){
                    addrWhitelistedToOffer[_boxesCounter][i] = offerAddress[i];
                }
                swapBoxes[boxID].whiteListOffer = 1;
            }
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
        _historyCounter++;
        emit Swaped(
            _historyCounter,
            listBoxID,
            swapBoxes[listBoxID].owner,
            offerBoxID,
            swapBoxes[offerBoxID].owner
        );
        
        
        _deleteAssets(listBoxID);
        _deleteAssets(offerBoxID);

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
        uint256 removeIndex;
        for(uint256 i ; i < offeredList[offerBoxID].length ; ++i){
            if(offeredList[offerBoxID][i] == listBoxID)
                removeIndex = i;
        }

        for(uint256 i ; i < offeredList[offerBoxID].length-1; ++i){
            offeredList[offerBoxID][i] = offeredList[offerBoxID][i + i];
        }

        offeredList[offerBoxID].pop();

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