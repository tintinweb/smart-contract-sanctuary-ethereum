// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/IRoyaltyEngineV1.sol";

    /// @title NFTTraderSwap
    /// @author Salad Labs Inc.
    contract NFTTraderSwapRoyaltiesV1 is Ownable, Pausable, ReentrancyGuard {

        using Counters for Counters.Counter;
        using SafeMath for uint256;

        /* swapStruct is the swap order structure of a counterparty
           the swapStruct contains all the data needed for setup a trade with
           ERC20/ERC721/ERC11555
        */
        struct swapStruct {
            address dapp; // dapp address
            typeStd typeStd; // identify the standard related to the DAPP
            uint256[] tokenId; // tokenID if is an ERC721/ERC1155
            uint256[] blc; // balance if is an ERC20/ERC1155
            uint256[] roy; // royalties that have been paid
            bytes data;
        }

        /* swapIntent is the master structure of a swap
           the swapIntent contains the address of the Maker and the Taker
           and the native token involved. Would also be used to check if the
           counterparty involved will have access to a discount.
           The Taker address could be the address(0) if the swap is open.
           It contains also the swap status (if opened or closed)
         */
        struct swapIntent {
            address payable addressMaker; // maker address of the swap
            bool    discountMaker; // if the maker of the swap have a TRADESQUAD or a PARTNERSQUAD he'll get a discount
            uint256 valueMaker; // native token value of the Maker
            uint256 flatFeeMaker; // Protocol flat fee
            address payable addressTaker; // taker address of the swap
            bool    discountTaker; // if the taker of the swap have a TRADESQUAD or a PARTNERSQUAD he'll get a discount
            uint256 valueTaker; // native token value of the Taker
            uint256 flatFeeTaker; // Protocol flat fee
            uint256 swapStart; // creation date
            uint256 swapEnd; // closing / expiring date
            bool    flagFlatFee; // flag used for check if the flat fees are enabled
            bool    flagRoyalties; // flag used for check if the royalties are enabled
            swapStatus status; // status of the deal. Could be Opened, Closed or Cancelled
            uint256 royaltiesMaker; // Royalties in native token paid by the Maker
            uint256 royaltiesTaker; // Royalties in native token paid by the Taker
        }
        
        /*  Royalties struct is used for check if the maker/taker is a buyer 
            The royaltiesStruct is used to define if is possible to apply the royalties payment
            on the interested counterparty.
        */
        struct royaltiesStruct {
            bool hasRoyalties; // flag used to check if has royalties to pay. It means that is a buyer
            bool hasNTV; // flag used to check if NTV (native token) are involved in this side of the deal
            bool hasERC20; // flag used to check if ERC20 are involved in this side of the deal
            bool hasERC721; // flag used to check if ERC721 are involved in this side of the deal
            bool hasERC1155; // flag used to check if ERC1155 are involved in this side of the deal
        }

        /* Royalties support structure used as a support for pay native token/ERC20 royalties to creators
           the royaltiesSupport struct is used for store the results that will come from
           the royalty registry.
           More infos here: https://royaltyregistry.xyz/
        */
        struct royaltiesSupport {
            address payable[] royaltiesAddress; // recipients that should receive the royalties
            uint256[] royalties; // amount of royalties
        }

        /* Reference for main addresses used by this smart contract
           the referenceAddressStruct is used for store and recover all the address needed
           for run the application, from the manifold engine address to the vault in which
           our fees are sent.
           TRADESQUAD and PARTNERSQUAD address could be used for handle the platform discounts
        */ 
        struct referenceAddressStruct {
            address ROYALTYENGINEADDRESS; // manifold engine address
            address TRADESQUAD; // NFTTrader TRADESQUAD (ERC721) address that remove trading fee
            address PARTNERSQUAD; // ERC721 address that could be used as a partner to get the same benefits of the TRADESQUAD
            address payable VAULT; // VAULT address for send the protocol fee
        }       

        /*
            Struct used as a reference for handle the payments/fee/royalties
            The paymentStruct is used
        */
        struct paymentStruct {
            bool    flagFlatFee; // Check if there are FLAT FEE or FLAT FEE + % FEE
            bool    flagRoyalties; // Check if the royalties are enabled
            uint256 flatFee; // Flat fee amount
            uint256 bps; // Basis points 
            uint256 scalePercent; // Scale Percent
        }

        /*  closeStruct is used in _close function
            This structure is used for a better handling of
            the details of a deal
        */
        struct closeStruct {
            address from; // From side
            address to; // To side
            bool    discount; // Flag to check if there is a discount
            uint256 feeValue; // Support property
            uint256 dealValue; // Original deal value. Used for ERC20
            uint256 vaultFee; // Fee sent to the vault
            uint256 fee; // Fee sent to the counterparty
            uint256 nativeDealValue; // Original value
            uint256 flatFeeValue; // Flat fee value
            uint256 royalties; // Royalties amount
        }

        uint256 constant secs = 86400;
        Counters.Counter private _swapIds; // Counter of the swaps
        referenceAddressStruct public referenceAddress;
        paymentStruct public payment;

        /// mapping address => bool used for handle ERC721/ERC20 blacklist/whitelist
        mapping (address => bool) ERC20whiteList;
        mapping (address => bool) NFTblackList;

        /// mapping address => bool for handle the ban of an address
        mapping (address => bool) public bannedAddress;

        /// swapStruct mapping for the details of makers and takers. The uint256 identify the swapId
        mapping(uint256 => swapStruct[]) nftsMaker;
        mapping(uint256 => swapStruct[]) nftsTaker;
        
        /// Mapping key/value for get the swap infos
        mapping (uint256 => swapIntent) swapMapping;

        /// Enum used for handle the status of a deal
        enum swapStatus { Opened, Closed, Cancelled }

        /// Enum used for define which kind of standards are used during the deal
        enum typeStd { ERC20, ERC721, ERC1155 }

        /// @dev This event used for query the blockchain for check the situation of the swap
        /// @param _creator is the address that identify the creator of the deal
        /// @param _time is used to identify the date in which the swap happened
        /// @param _status is used to identify the status of the deal (open/closed)
        /// @param _swapId is the id of the swap
        /// @param _counterpart is the address that identify the counterpart of the deal
        /// @param _referral is the address that could be used in future for pay a referral
        event swapEvent(address indexed _creator, uint256 indexed _time, swapStatus indexed _status, uint256 _swapId, address _counterpart, address _referral);

        /// @dev This event is used for query the blockchain for recover the new counterpart of the specified swap
        /// @param _swapId is the id of the swap
        /// @param _counterpart is the address that identify the counterpart of the deal
        event counterpartEvent(uint256 indexed _swapId, address indexed _counterpart);

        /// @dev This event is used for track the changes in the setReferenceAddresses function
        /// @param _engineAddress is the address of the Royalty Registry engine
        /// @param _tradeSquad is the address of the TradeSquad ERC721
        /// @param _partnerSquad is the address of the PartnerSquad ERC721
        /// @param _vault is the address of the vault in which we're going to send the fees
        event referenceAddressEvent(address _engineAddress, address _tradeSquad, address _partnerSquad, address _vault);

        /// @dev This event is used for track the changes in the setPaymentStruct function
        /// @param _flagFlatFee bool used to enable or disable the flat fee. If true flat, if false flat + %
        /// @param _flatFee uint256 used to specify the flatfee in WEI
        /// @param _flagRoyalties bool used to enable or disable the royalties payment
        /// @param _bps uint256 used for the internal bps related to the platform fee
        /// @param _scalePercent uint256 used for the scale percent
        event paymentStructEvent(bool _flagFlatFee, uint256 _flatFee, bool _flagRoyalties, uint256 _bps, uint256 _scalePercent);

        /// @dev This event emitted when some native token are sent on the smart contract
        /// @param _payer sender of the native token received
        /// @param _value amount of native token received
        event paymentReceived(address indexed _payer, uint256 _value);

        /// @notice Emit an event each time someone send native token here
        /// @dev Emit an event each time someone send native token here
        receive() external payable { 
            emit paymentReceived(msg.sender, msg.value);
        }
        
        /// @notice This function is used for create a swap
        /// @dev This function is used for create a swap. The order is stored on the blockchain and will emit a swapEvent once executed
        /// @param _swapIntent master content of the order
        /// @param _nftsMaker swap structure that contains the detail content of swap creator
        /// @param _nftsTaker swap structure that contains the detail content of swap counterparty
        /// @param _referral address that could be used for a referral in future
        function createSwapIntent(swapIntent memory _swapIntent, swapStruct[] memory _nftsMaker, swapStruct[] memory _nftsTaker, address _referral) payable public whenNotPaused checkAssets(_swapIntent, _nftsMaker, _nftsTaker) {

            require(bannedAddress[msg.sender] == false, "Banned");
            // check the fee/value used by the creator of the swap
            _swapIntent.flagFlatFee = payment.flagFlatFee;
            _swapIntent.flagRoyalties = payment.flagRoyalties;

            // check if he've a discount
            (_swapIntent.discountMaker, _swapIntent.flatFeeMaker) = _checkDiscount();

            // Check if the amount needed is fine for accomplish the deal creation
            require(msg.value >= _swapIntent.valueMaker.add(_swapIntent.flatFeeMaker), "More wei needed");
            
            _swapIntent.addressMaker = payable(msg.sender);
            // Check if the counterparty is not the creator of the deal
            require(_swapIntent.addressMaker != _swapIntent.addressTaker, "maker=taker");

            _swapIntent.swapStart = block.timestamp;
            if(_swapIntent.swapEnd == 0)
                _swapIntent.swapEnd = block.timestamp.add(7 days);
            else {
                _swapIntent.swapEnd = _swapIntent.swapEnd.mul(1 days);
                _swapIntent.swapEnd = _swapIntent.swapEnd.add(block.timestamp);
            }
            _swapIntent.status = swapStatus.Opened;
            _swapIntent.royaltiesMaker = 0;
            _swapIntent.royaltiesTaker = 0;          

            swapMapping[_swapIds.current()] = _swapIntent;
            _create(_swapIds.current(), _nftsMaker, true);
            _create(_swapIds.current(), _nftsTaker, false);
                
            emit swapEvent(msg.sender, (block.timestamp-(block.timestamp%secs)), _swapIntent.status, _swapIds.current(), _swapIntent.addressTaker, _referral);
            _swapIds.increment();
        }
        
        /// @notice This is used for close a swap.
        /// @dev This function close an order that is stored on the blockchain and it will emit a swapEvent once executed
        /// @param _swapId identifier of the order
        /// @param _referral address that in future could be used for payouts
        function closeSwapIntent(uint256 _swapId, address _referral) payable public whenNotPaused nonReentrant {
            swapIntent memory swap = swapMapping[_swapId];
            uint256 vaultFee = 0;
            // Banned address
            require(bannedAddress[msg.sender] == false, "Banned");
            // Status            
            require(swap.status == swapStatus.Opened, "!Open");
            // Counterpart
            require(swap.addressTaker == msg.sender || swap.addressTaker == address(0), "You're not the interested counterpart");
            // Check if the counterparty is not the creator of the deal
            require(swap.addressMaker != swap.addressTaker, "maker=taker");                        
            // Deal Swap expired
            require(swap.swapEnd >= block.timestamp, "Expired");           
            // SwapId must be lower or equal to the current one
            require(_swapId < _swapIds.current(), "id KO");
            swapMapping[_swapId].addressTaker = payable(msg.sender);
            swapMapping[_swapId].status = swapStatus.Closed;
            swapMapping[_swapId].swapEnd = block.timestamp;
            
            // check if he've a discount
            (swapMapping[_swapId].discountTaker, swapMapping[_swapId].flatFeeTaker) = _checkDiscount();

            // Control if is enabled the flat fee or flat fee + %
            require(msg.value >= swapMapping[_swapId].valueTaker.add(swapMapping[_swapId].flatFeeTaker), "Not enough WEI");
            
            // Pay Royalties if enabled
            if(swapMapping[_swapId].flagRoyalties)
                _sendRoyalties(_swapId);

            // From Owner 1 to Owner 2
            vaultFee = _close(_swapId, true);
            // From Owner 2 to Owner 1
            vaultFee = vaultFee.add(_close(_swapId, false));
            require(transferFees(referenceAddress.VAULT, vaultFee), "Fee");
            emit swapEvent(swapMapping[_swapId].addressTaker, (block.timestamp-(block.timestamp%secs)), swapStatus.Closed, _swapId, msg.sender, _referral);
        }

        /// @notice This is used for cancel a swap.
        /// @dev This function cancel an order that is stored on the blockchain and will emit a swapEvent once executed
        /// @param _swapId identifier of the order
        function cancelSwapIntent(uint256 _swapId) public nonReentrant {
            swapIntent memory swap = swapMapping[_swapId];
            // Check if is the owner
            require(swap.addressMaker == msg.sender, "!Owner");
            // Check swap status
            require(swap.status == swapStatus.Opened, "!Open");
            // Save how much value should be refunded to the initiator of the deal
            uint256 refund = swap.valueMaker.add(swap.flatFeeMaker) ;

            swapMapping[_swapId].swapEnd = block.timestamp;
            swapMapping[_swapId].status = swapStatus.Cancelled;
            emit swapEvent(msg.sender, (block.timestamp-(block.timestamp%secs)), swapStatus.Cancelled, _swapId, address(0), address(0));
            
            // Refund the fee/value used by the creator of the swap
            if(refund > 0) {
                require(transferFees(msg.sender, refund), "Fee");
            }
        }

        /// @notice This function is used for populate the main address used by the procol
        /// @dev This function is used for populate the main address used by the procol. From the ryoalties registry to the vault
        /// @param _engineAddress address that must be used for the royalties engine reference
        /// @param _tradeSquad address used for apply a discount on the protocol for a TradeSquad owner
        /// @param _partnerSquad address used for apply a discount on the protocol for a partner
        /// @param _vault payable address used for send the fees generated by the protocol
        function setReferenceAddresses(address _engineAddress, address _tradeSquad, address _partnerSquad, address payable _vault) public onlyOwner {

            referenceAddress.ROYALTYENGINEADDRESS = _engineAddress;
            referenceAddress.TRADESQUAD   = _tradeSquad;
            referenceAddress.PARTNERSQUAD   = _partnerSquad;
            referenceAddress.VAULT = _vault;
            emit referenceAddressEvent(_engineAddress, _tradeSquad, _partnerSquad, _vault);

        }

        /// @notice This ERC721 address applies a discount if owned by a counterpart
        /// @dev This address is used to handle the ERC721 that will remove the fee from the smart contract
        /// @param _flagFlatFee bool used to enable or disable the flat fee. If true flat, if false flat + %
        /// @param _flatFee uint256 used to specify the flatfee in WEI
        /// @param _flagRoyalties bool used to enable or disable the royalties payment
        /// @param _bps uint256 used for the internal bps related to the platform fee
        /// @param _scalePercent uint256 used for the scale percent
        function setPaymentStruct(bool _flagFlatFee, uint256 _flatFee, bool _flagRoyalties, uint256 _bps, uint256 _scalePercent) public onlyOwner {

            require(_scalePercent >= 10000, 'Must be >= 10000');
            payment.flagFlatFee = _flagFlatFee;
            payment.flatFee = _flatFee;
            payment.flagRoyalties = _flagRoyalties;
            payment.bps = _bps;
            payment.scalePercent = _scalePercent;

            emit paymentStructEvent(_flagFlatFee, _flatFee, _flagRoyalties, _bps, _scalePercent);
        }

        /// @dev This function is used for enable or disable the trading of ERC20. By default ALL ERC20 are disabled
        /// @param _dapp address of an ERC20
        /// @param _status bool that is used for enable or disable the trading of the current asset
        function setERC20Whitelist(address _dapp, bool _status) public onlyOwner {
            ERC20whiteList[_dapp] = _status;
        }

        /// @dev This function is used for enable or disable the trading of ERC721 or ERC1155. By default ALL ERC721/ERC1155 are enabled
        /// @param _dapp address of an ERC721/ERC1155
        /// @param _status bool that is used for enable or disable the trading of the current asset
        function setNFTBlacklist(address _dapp, bool _status) public onlyOwner {
            NFTblackList[_dapp] = _status;
        }

        /// @notice This function is used for change the counterparty of a deal
        /// @dev This function is used for change the counterparty of a specified deal. Only the creator of the deal could change the counterparty
        /// @param _swapId identifier of the order
        /// @param _counterPart address that is used for change the counterparty of the specified deal
        function editCounterPart(uint256 _swapId, address payable _counterPart) public {
            swapIntent memory swap = swapMapping[_swapId];
            require(msg.sender == swap.addressMaker && msg.sender != _counterPart, "!Owner");
            swapMapping[_swapId].addressTaker = _counterPart;
            emit counterpartEvent(_swapId, _counterPart);
        }

        /// @notice This function is used for enable/disable onchain royalties
        /// @dev This function is used for enable/disable onchain royalties. Only the smart contract owner could flip the state
        function flipRoyaltiesState() public onlyOwner {
            payment.flagRoyalties = !payment.flagRoyalties;
        }

        /// @notice This function is used for ban/unban an address for the platform usage
        /// @dev This function is used for ban/unban an address for the platform usage.  Only the smart contract owner could ban an address
        function flipBannedAddressState(address _address) public onlyOwner {
            bannedAddress[_address] = !bannedAddress[_address];
        }

        /// @notice This function is used internally to check if an user is eligible to a discount
        /// @dev This function is used internally to check if an user is eligible to a discount. The account must own a TRADESQUAD or a PARTNERSQUAD to be eligible. It should be an ERC721
        function _checkDiscount() private view returns(bool, uint256) {
            if(IERC721(referenceAddress.TRADESQUAD).balanceOf(msg.sender) > 0 || IERC721(referenceAddress.PARTNERSQUAD).balanceOf(msg.sender) > 0) {
                return (true, 0);
            }
            else {
                return (false, payment.flatFee);
            }
        }

        /// @notice This function is used interally for create a deal
        /// @dev This function is used interally for create a deal. It will check if everything is setup properly
        /// @param _nfts swap structure is the content of a swap
        /// @param _maker identify is is the maker or the taker
        function _create(uint256 _swapId, swapStruct[] memory _nfts, bool _maker) private {
            uint256 i;
            uint256 j;
            for(i=0; i<_nfts.length; i++) {
                if(_nfts[i].typeStd == typeStd.ERC20) {
                    require(ERC20whiteList[_nfts[i].dapp] && _nfts[i].roy.length==1 && _nfts[i].blc.length==1 && _nfts[i].blc[0]>0, "ERC20 - Check values");
                    _nfts[i].roy[0] = 0;
                }
                else {
                    require(!NFTblackList[_nfts[i].dapp], "ERC721 - Blacklisted");

                    if(_nfts[i].typeStd == typeStd.ERC721) 
                        require(_nfts[i].tokenId.length==1, "ERC721 - Missing tokenId");

                    if(_nfts[i].typeStd == typeStd.ERC1155) {
                        require(_nfts[i].tokenId.length>0 && _nfts[i].blc.length>0 && _nfts[i].tokenId.length==_nfts[i].blc.length, "ERC1155 - Missing tokenId");
                        j=0;
                        while(j<_nfts[i].blc.length) {
                            require(_nfts[i].blc[j]>0, "ERC1155 - Balance must be > 0");
                            j++;
                        }
                    }
                }
                
                if(_maker)
                    nftsMaker[_swapId].push(_nfts[i]);
                else
                    nftsTaker[_swapId].push(_nfts[i]);
            }
        }

        /// @notice This function is used interally for pay the royalties
        /// @dev This function is used interally for pay the royalties and would be called if flagRoyalties is true. It will be called in the last phase of a swap
        /// @param _swapId is the swap identifier
        function _sendRoyalties(uint256 _swapId) private {
            swapIntent memory swap = swapMapping[_swapId];
            // Royalties Management
            royaltiesStruct memory maker;
            royaltiesStruct memory taker;

            maker.hasRoyalties = true;
            taker.hasRoyalties = true;

            if(swap.valueMaker>0)
                maker.hasNTV = true;
            if(swap.valueTaker>0)
                taker.hasNTV = true;

            // Maker
            (maker, taker.hasRoyalties) = _setRoyaltiesStatus(maker, nftsMaker[_swapId]);

            // Taker
            (taker, maker.hasRoyalties) = _setRoyaltiesStatus(taker, nftsTaker[_swapId]);

            // Check if the parts involved are doing a sale
            // Maker - Check if is a buyer
            if(maker.hasRoyalties) {
                if(!((maker.hasNTV || maker.hasERC20) && (taker.hasERC721 || taker.hasERC1155)))
                    maker.hasRoyalties = false;
                else {
                    // Maker is a buyer, must pay royalties
                    _checkBuyer(maker, taker, true, _swapId);
                }
            }

            // Taker - Check if is a buyer
            if(taker.hasRoyalties) {
                if(!((taker.hasNTV || taker.hasERC20) && (maker.hasERC721 || maker.hasERC1155)))
                    taker.hasRoyalties = false;
                else {
                    // Taker is a buyer, must pay royalties
                    _checkBuyer(taker, maker, false, _swapId);
                }
            }
        }

        /// @notice This function is used interally for setup the status of the Royalties struct
        /// @dev This function is used interally for setup the status of the Royalties struct
        /// @param _part royalties structure on the interested party
        /// @param _nfts swap structure is the detail content of the interested party
        /// @return the royalties structure of the interested party
        function _setRoyaltiesStatus(royaltiesStruct memory _part, swapStruct[] memory _nfts) private pure returns(royaltiesStruct memory, bool) {
            
            uint256 i;
            bool royalty;
            address address721;
            address address1155;

            i=0;
            royalty = true ;
            while(i<_nfts.length) {
                
                if(_nfts[i].typeStd == typeStd.ERC20) {
                    _part.hasERC20 = true;
                }
                else {

                    if(_nfts[i].typeStd == typeStd.ERC721) {
                        if(_part.hasERC721 == false) {
                            _part.hasERC721 = true;
                            address721 = _nfts[i].dapp;
                        }
                        else {
                            if(address721 != _nfts[i].dapp)
                                royalty = false;
                        }
                    }
                    
                    if(_nfts[i].typeStd == typeStd.ERC1155) {
                        if(_part.hasERC1155 == false) {
                            _part.hasERC1155 = true;
                            address1155 = _nfts[i].dapp;
                        }
                        else {
                            if(address1155 != _nfts[i].dapp)
                                royalty = false;
                        }
                    }
                }

                i++;
            }
            // Part has different collections
            if(_part.hasERC721 && _part.hasERC1155)
                royalty = false;

            return(_part, royalty);
        }

        /// @notice This function is used interally for check if the part is a buyer and have to pay royalties
        /// @dev This function is used interally for check if the part is a buyer and have to pay royalties. It will transfer the royalties if needed
        /// @param _part royalties structure on the interested party
        /// @param _counterpart royalties structure on the interested party
        /// @param _maker identifies the maker or the taker
        /// @param _swapId swap identifier
        function _checkBuyer(royaltiesStruct memory _part, royaltiesStruct memory _counterpart, bool _maker, uint256 _swapId) private {
            swapIntent memory swap = swapMapping[_swapId];
            uint256 i;
            uint256 j;
            bool flag;
            uint256 royBlc;
            swapStruct[] memory nfts;
            swapStruct[] memory ausNfts;
            royaltiesSupport memory support;

            // native token
            if(_part.hasNTV && (_counterpart.hasERC721 || _counterpart.hasERC1155)) {
                nfts = _maker?nftsTaker[_swapId]:nftsMaker[_swapId];
                i=0;
                flag=false;
                while(i<nfts.length && flag==false) {
                    if(nfts[i].typeStd == typeStd.ERC721 || nfts[i].typeStd == typeStd.ERC1155) {
                        if(_maker) {
                            (support.royaltiesAddress, support.royalties) = IRoyaltyEngineV1(referenceAddress.ROYALTYENGINEADDRESS).getRoyaltyView(nfts[i].dapp, nfts[i].tokenId[0], swapMapping[_swapId].valueMaker) ;
                        }
                        else {
                            (support.royaltiesAddress, support.royalties) = IRoyaltyEngineV1(referenceAddress.ROYALTYENGINEADDRESS).getRoyaltyView(nfts[i].dapp, nfts[i].tokenId[0], swapMapping[_swapId].valueTaker) ;
                        }
                        flag = true;
                    }
                    i++;
                }
                // update native token balance in swapIntent and sendRoyalties
                for(i=0; i<support.royalties.length; i++) {
                    if(_maker)
                        swapMapping[_swapId].royaltiesMaker = swap.royaltiesMaker.add(support.royalties[i]);
                    else
                        swapMapping[_swapId].royaltiesTaker = swap.royaltiesTaker.add(support.royalties[i]);
                    
                    require(transferFees(support.royaltiesAddress[i], support.royalties[i]), "Fee");
                }
            }

            //ERC20
            if(_part.hasERC20 && (_counterpart.hasERC721 || _counterpart.hasERC1155)) {
                nfts = _maker?nftsMaker[_swapId]:nftsTaker[_swapId];
                ausNfts = _maker?nftsTaker[_swapId]:nftsMaker[_swapId];

                for(i=0; i<nfts.length; i++) {
                    if(nfts[i].typeStd == typeStd.ERC20) {
                        j=0;
                        flag=false;
                        while(j<ausNfts.length && flag==false) {
                            if(ausNfts[j].typeStd == typeStd.ERC721 || ausNfts[j].typeStd == typeStd.ERC1155) {
                                (support.royaltiesAddress, support.royalties) = IRoyaltyEngineV1(referenceAddress.ROYALTYENGINEADDRESS).getRoyaltyView(ausNfts[j].dapp, ausNfts[j].tokenId[0], nfts[i].blc[0]) ;
                                flag = true;
                            }
                        }
                        royBlc = 0;
                        for(j=0; j<support.royalties.length; j++) {
                            if(_maker) {
                                IERC20(nfts[i].dapp).transferFrom(swap.addressMaker, support.royaltiesAddress[j], support.royalties[j]);
                            }
                            else {
                                IERC20(nfts[i].dapp).transferFrom(swap.addressTaker, support.royaltiesAddress[j], support.royalties[j]);
                            }
                            royBlc = royBlc.add(support.royalties[j]);
                        }
                        // Store Balance
                        if(_maker)
                            nftsMaker[_swapId][i].roy[0] = royBlc;
                        else
                            nftsTaker[_swapId][i].roy[0] = royBlc;
                    }
                }
            }
        }

        /// @notice This function is used interally for close a deal
        /// @dev This function is used interally for close a deal.
        /// @param _swapId swap identifier
        /// @param _maker identifies the maker or the taker
        function _close(uint256 _swapId, bool _maker) private returns(uint256) {
            swapIntent memory swap = swapMapping[_swapId];
            closeStruct memory closeDetail;
            swapStruct[] memory nfts;
            uint256 i;

            if(_maker) {
                nfts = nftsMaker[_swapId];
                closeDetail.from = swap.addressMaker;
                closeDetail.to = swap.addressTaker;
                closeDetail.discount = swap.discountMaker;
                closeDetail.nativeDealValue = swap.valueMaker;
                closeDetail.flatFeeValue = swap.flatFeeMaker;
                closeDetail.royalties = swap.royaltiesMaker;
            }
            else {
                nfts = nftsTaker[_swapId];
                closeDetail.from = swap.addressTaker;
                closeDetail.to = swap.addressMaker;
                closeDetail.discount = swap.discountTaker;
                closeDetail.nativeDealValue = swap.valueTaker;
                closeDetail.flatFeeValue = swap.flatFeeTaker;
                closeDetail.royalties = swap.royaltiesTaker;
            }

            // SPLIT ERC20
            closeDetail.dealValue = 0;
            for(i=0; i<nfts.length; i++) {
                closeDetail.feeValue = 0;
                if(nfts[i].typeStd == typeStd.ERC20) {
                    require(ERC20whiteList[nfts[i].dapp], "ERC20 - KO");

                    closeDetail.dealValue = nfts[i].blc[0];
                    // Check if exist a % fee
                    if(swap.flagFlatFee == false) {
                        if(!closeDetail.discount) { // If there is no discount, % fee on ERC20 is applied
                            closeDetail.feeValue = calculateFees(closeDetail.dealValue);
                            closeDetail.dealValue = closeDetail.dealValue.sub(closeDetail.feeValue);
                            IERC20(nfts[i].dapp).transferFrom(closeDetail.from, referenceAddress.VAULT, closeDetail.feeValue);
                        }
                    }
                    if(nfts[i].roy.length>0 && payment.flagRoyalties)
                        closeDetail.dealValue = closeDetail.dealValue.sub(nfts[i].roy[0]);
                    IERC20(nfts[i].dapp).transferFrom(closeDetail.from, closeDetail.to, closeDetail.dealValue);
                }
                else {
                    require(!NFTblackList[nfts[i].dapp], "ERC721 - Blacklisted");
                    if(nfts[i].typeStd == typeStd.ERC721) {
                        IERC721(nfts[i].dapp).safeTransferFrom(closeDetail.from, closeDetail.to, nfts[i].tokenId[0], nfts[i].data);
                    }
                    else if(nfts[i].typeStd == typeStd.ERC1155) {
                        IERC1155(nfts[i].dapp).safeBatchTransferFrom(closeDetail.from, closeDetail.to, nfts[i].tokenId, nfts[i].blc, nfts[i].data);
                    }
                }
            }

            // Split native token
            closeDetail.feeValue = 0;
            // Check if there is a % fee in the order. If was created without the %, is flat
            if(swap.flagFlatFee == false) {
                if(closeDetail.discount) {
                    if(closeDetail.nativeDealValue>0)
                        closeDetail.fee = closeDetail.fee.add(closeDetail.nativeDealValue).sub(closeDetail.royalties);
                }
                else {
                    closeDetail.feeValue = calculateFees(closeDetail.nativeDealValue);
                    closeDetail.nativeDealValue = closeDetail.nativeDealValue.sub(closeDetail.feeValue).sub(closeDetail.royalties);
                    closeDetail.vaultFee = closeDetail.feeValue.add(closeDetail.flatFeeValue);

                    if(closeDetail.nativeDealValue>0)
                        closeDetail.fee = closeDetail.fee.add(closeDetail.nativeDealValue);
                }
            }
            else { // Flat fee
                if(!closeDetail.discount) {
                    closeDetail.vaultFee = closeDetail.feeValue.add(closeDetail.flatFeeValue);
                }
                if(closeDetail.nativeDealValue>0)
                    closeDetail.fee = closeDetail.fee.add(closeDetail.nativeDealValue).sub(closeDetail.royalties);
            }

            require(transferFees(closeDetail.to, closeDetail.fee), "Fee");
            return closeDetail.vaultFee;
        }
        
        /// @notice This function is used for pause/unpause the smart contract
        /// @dev This function is used for pause the smart contract
        /// @param _paused true or false for enable/disable the pause
        function pauseContract(bool _paused) public onlyOwner {
            _paused?_pause():_unpause();
        }

        /// @notice Check if an ERC20 is enabled or disabled on the platform
        /// @dev Check if an ERC20 is enabled or disabled on the platform. By default all ERC20 are disabled
        /// @param _address address of an ERC20
        /// @return true or false if the asset is whitelisted or not
        function getERC20WhiteList(address _address) public view returns(bool) {
            return ERC20whiteList[_address];
        }

        /// @notice Check if an ERC721/ERC1155 is enabled or disabled on the platform
        /// @dev Check if an ERC721/ERC1155 is enabled or disabled on the platform. By default all ERC721/ERC1155 are enabled
        /// @param _address address of an ERC721/ERC1155
        /// @return this function return true if the asset is not blacklisted, false if is blacklisted
        function getNFTBlacklist(address _address) public view returns(bool) {
            return !NFTblackList[_address];
        }

        /// @notice This function is used internally for calculate the platform fee
        /// @dev This function is used internally for calculate the platform fee
        /// @param _amount uint256 value involved in the deal
        /// @return the fee that should be paid to the protocol if the % fee are enabled
        function calculateFees(uint256 _amount) private view returns(uint256) {
            return ((_amount * payment.bps) / (payment.scalePercent));
        }

        /// @notice This function is used internally for send the native tokens to other accounts
        /// @dev This function is used internally for send the the native tokens to other accounts
        /// @param _to address is the address that will receive the _amount
        /// @param _amount uint256 value involved in the deal
        /// @return true or false if the transfer worked out
        function transferFees(address _to, uint256 _amount) private returns(bool) {
            bool success = true;
            if(_amount>0)
                (success,  ) = payable(_to).call{value: _amount}("");
            return success;
        }

        /// @notice This function is used to get the master infos about a swap
        /// @dev This function is used to get infos about a swap.
        /// @param _swapId identifier of the order
        /// @return swapIntent that is master order of the interested swap
        function getSwapIntentById(uint256 _swapId) public view returns(swapIntent memory) {
            return swapMapping[_swapId];
        }
        
        /// @notice This function is used how many assets assets are involved in the swap.
        /// @dev This function is used how many assets assets are involved in the swap. It will be used to call later the getSwapStruct
        /// @param _swapId identifier of the order
        /// @param _nfts bool used to check the assets on creator(true) or counterparty(false) side
        /// @return the size of the deal. It's used on frontend for recover the whole party deal
        function getSwapStructSize(uint256 _swapId, bool _nfts) public view returns(uint256) {
            if(_nfts)
                return nftsMaker[_swapId].length;
            else
                return nftsTaker[_swapId].length;
        }

        /// @notice This function is used to get the details of the assets involved in a swap
        /// @dev This function is used to get the details of the assets involved in a swap, from tokenID for ERC721/ERC1155 to the balances for ERC1155/ERC20
        /// @param _swapId identifier of the order
        /// @param _nfts bool used to check the assets on creator(true) or counterparty(false) side
        /// @param _index uint256 inded used to get the detail of an asset
        /// @return the detail of the interested struct
        function getSwapStruct(uint256 _swapId, bool _nfts, uint256 _index) public view returns(swapStruct memory) {
            if(_nfts)
                return nftsMaker[_swapId][_index];
            else
                return nftsTaker[_swapId][_index];
        }

        /// @dev This modifier avoid to create swaps in which a party involved is without assets
        modifier checkAssets(swapIntent memory _swapIntent, swapStruct[] memory _nftsMaker, swapStruct[] memory _nftsTaker) {
            require(((_swapIntent.valueMaker > 0 || _nftsMaker.length > 0)&&(_swapIntent.valueTaker > 0 || _nftsTaker.length > 0)), "No assets");
            _;
        }
    }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT

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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Lookup engine interface
 */
interface IRoyaltyEngineV1 is IERC165 {

    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     * 
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value) external returns(address payable[] memory recipients, uint256[] memory amounts);

    /**
     * View only version of getRoyalty
     * 
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyaltyView(address tokenAddress, uint256 tokenId, uint256 value) external view returns(address payable[] memory recipients, uint256[] memory amounts);
}