/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

// librray for TokenDets
library TokenDetArrayLib {
    // Using for array of strcutres for storing mintable address and token id
    using TokenDetArrayLib for TokenDets;

    struct TokenDet {
        address NFTAddress;
        uint256 tokenID;
    }

    // custom type array TokenDets
    struct TokenDets {
        TokenDet[] array;
    }

    function addTokenDet(
        TokenDets storage self,
        TokenDet memory _tokenDet
        // address _mintableAddress,
        // uint256 _tokenID
    ) public {
        if (!self.exists(_tokenDet)) {
            self.array.push(_tokenDet);
        }
    }

    function getIndexByTokenDet(
        TokenDets storage self,
        TokenDet memory _tokenDet
    ) internal view returns (uint256, bool) {
        uint256 index;
        bool tokenExists = false;
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i].NFTAddress == _tokenDet.NFTAddress &&
                self.array[i].tokenID == _tokenDet.tokenID 
            ) {
                index = i;
                tokenExists = true;
                break;
            }
        }
        return (index, tokenExists);
    }

    function removeTokenDet(
        TokenDets storage self,
        TokenDet memory _tokenDet
    ) internal returns (bool) {
        (uint256 i, bool tokenExists) = self.getIndexByTokenDet(_tokenDet);
        if (tokenExists == true) {
            self.array[i] = self.array[self.array.length - 1];
            self.array.pop();
            return true;
        }
        return false;
    }

    function exists(
        TokenDets storage self,
        TokenDet memory _tokenDet
    ) internal view returns (bool) {
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i].NFTAddress == _tokenDet.NFTAddress &&
                self.array[i].tokenID == _tokenDet.tokenID
            ) {
                return true;
            }
        }
        return false;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    // event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        // address msgSender = _msgSender();
        _owner = msg.sender;
        // emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        // emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

// library for erc20address array 
library ERC20Addresses {
    using ERC20Addresses for erc20Addresses;

    struct erc20Addresses {
        address[] array;
    }

    function addERC20Tokens(erc20Addresses storage self, address erc20address)
        external
    {
        self.array.push(erc20address);
    }

    function getIndexByERC20Token(
        erc20Addresses storage self,
        address _ercTokenAddress
    ) internal view returns (uint256, bool) {
        uint256 index;
        bool exists;

        for (uint256 i = 0; i < self.array.length; i++) {
            if (self.array[i] == _ercTokenAddress) {
                index = i;
                exists = true;

                break;
            }
        }
        return (index, exists);
    }

    function removeERC20Token(
        erc20Addresses storage self,
        address _ercTokenAddress
    ) internal {
        if (self.array.length > 1){
            for (uint256 i = 0; i < self.array.length; i++) {
                    if (
                        self.array[i] == _ercTokenAddress 
                    ) {
                        delete self.array[i];
                    }
                }
        }
        else{
            self.array.length = 0;
        }
    }
    function exists(
        erc20Addresses storage self,
        address _ercTokenAddress
    ) internal view returns (bool) {
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _ercTokenAddress 
            ) {
                return true;
            }
        }
        return false;
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4);
}

contract ERC721Holder is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract IMintableToken {
    // Required methods
    function ownerOf(uint256 _tokenId) external view returns (address owner);

    function royalities(uint256 _tokenId) public view returns (uint256);

    function creators(uint256 _tokenId) public view returns (address payable);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public;

    function getApproved(uint256 tokenId)
        public
        view
        returns (address operator);
        
    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool);

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID)
        external
        view
        returns (bool);
}


contract Storage is Ownable {
    using TokenDetArrayLib for TokenDetArrayLib.TokenDets;
    using ERC20Addresses for ERC20Addresses.erc20Addresses;
    // address owner;
    // address owner;
    uint16 public rewardDistributionPercentage;
    uint16 public platFormFeePercentage;   
    uint16 public lpStakefeepercentage; 
    // uint16 public brokerage;
    uint256 public updateClosingTime;

    mapping(address => mapping(uint256 => bool)) tokenOpenForSale;
    mapping(address => TokenDetArrayLib.TokenDets) tokensForSalePerUser;
    TokenDetArrayLib.TokenDets fixedPriceTokens;
    TokenDetArrayLib.TokenDets auctionTokens;

    //auction type :
    // 1 : only direct buy
    // 2 : only bid
    // 3 : both buy and bid

    struct auction {
        address payable lastOwner;
        uint256 currentBid;
        address payable highestBidder;
        uint256 auctionType;
        uint256 startingPrice;
        uint256 buyPrice;
        bool buyer;
        uint256 startingTime;
        uint256 closingTime;
        address erc20Token;
    }

    struct OfferDetails {
        address offerer;
        uint256 amount;
    }
    
    /** Offer mapping
     * {
     *      ERC721Address:{
     *          tokenId:{
     *               ERC20Address{
     *                   offerer: Address of offerer,
     *                   amount: Offer in this currency
     *               }
     *           }
     *       }   
     * }
     */
    mapping(
        address => mapping( 
            uint256 => mapping(
                address => OfferDetails
            )
        )
    ) public offerprice;

    mapping(address => mapping(uint256 => auction)) public auctions;

    TokenDetArrayLib.TokenDets tokensForSale;
    ERC20Addresses.erc20Addresses erc20TokensArray;

    address public WETHAddress;
    address public StakeAddress;
    address public LPStakeAddress;
    function getErc20Tokens()
        public
        view
        returns (ERC20Addresses.erc20Addresses memory)
    {
        return erc20TokensArray;
    }

    function getTokensForSale()
        public
        view
        returns (TokenDetArrayLib.TokenDet[] memory)
    {
        return tokensForSale.array;
    }

    function getFixedPriceTokensForSale()
        public
        view
        returns (TokenDetArrayLib.TokenDet[] memory)
    {
        return fixedPriceTokens.array;
    }

    function getAuctionTokensForSale()
        public
        view
        returns (TokenDetArrayLib.TokenDet[] memory)
    {
        return auctionTokens.array;
    }

    function getTokensForSalePerUser(address _user)
        public
        view
        returns (TokenDetArrayLib.TokenDet[] memory)
    {
        return tokensForSalePerUser[_user].array;
    }

    // function setBrokerage(uint16 _brokerage) public onlyOwner {
    //     brokerage = _brokerage;
    // }


      function setBrokerage(address _rewardDistributionAddress,address _lpStakeAddress ,uint16 _lpStakefeepercentage, uint16 _rewardDistributionPercentage, uint16 _platFormFeePercentage) public onlyOwner {
        require(_rewardDistributionAddress != address(0) &&_lpStakeAddress!=address(0), "Address is Zero");
        require(_rewardDistributionPercentage >= 0 && _platFormFeePercentage >= 0 &&_lpStakefeepercentage>=0, "should be greater than zero");
        require(_rewardDistributionPercentage <= 1000 && _platFormFeePercentage <= 1000 && _lpStakefeepercentage<=1000, "should be greater than zero");
        rewardDistributionPercentage = _rewardDistributionPercentage;
        platFormFeePercentage = _platFormFeePercentage;
        lpStakefeepercentage=_lpStakefeepercentage;
        StakeAddress = _rewardDistributionAddress;
        LPStakeAddress = _lpStakeAddress;
    }

    function setUpdatedClosingTime(uint256 _updateTime) public onlyOwner {
        updateClosingTime = _updateTime;
    }

    function setAddress(address _weth, address _rewardDistributionAddress) external onlyOwner {
        WETHAddress =_weth;
        StakeAddress = _rewardDistributionAddress;
    }
}

contract BrokerModifiers is Storage {
    modifier erc20Allowed(address _erc20Token) {
        if (_erc20Token != address(0)) {
            require(
                erc20TokensArray.exists(_erc20Token),
                "ERC20 not allowed"
            );
        }
        _;
    }

    modifier onSaleOnly(uint256 tokenID, address _mintableToken) {
        require(
            tokenOpenForSale[_mintableToken][tokenID] == true,
            "Token Not For Sale"
        );
        _;
    }

    modifier activeAuction(uint256 tokenID, address _mintableToken) {
        require(
            block.timestamp < auctions[_mintableToken][tokenID].closingTime,
            "Auction Time Over!"
        );
        require(
            block.timestamp > auctions[_mintableToken][tokenID].startingTime,
            "Auction Not Started yet!"
        );
        _;
    }

    modifier auctionOnly(uint256 tokenID, address _mintableToken) {
        require(
            auctions[_mintableToken][tokenID].auctionType != 1,
            "Auction Not For Bid"
        );
        _;
    }

    modifier flatSaleOnly(uint256 tokenID, address _mintableToken) {
        require(
            auctions[_mintableToken][tokenID].auctionType != 2,
            "For flat sale only!"
        );
        _;
    }

    modifier tokenOwnerOnlly(uint256 tokenID, address _mintableToken) {
        // Sender will be owner only if no have bidded on auction.
        require(
            IMintableToken(_mintableToken).ownerOf(tokenID) == msg.sender,
            "You must be owner and Token should not have any bid"
        );
        _;
    }
}

pragma solidity ^0.5.17;

interface IWETH {
    function deposit() external payable;
    function approve(address spender, uint value) external returns (bool);
    function withdraw(uint) external;
    function transfer(address to, uint value) external returns (bool);
}

interface IStake{
    function receiveWETHFee(uint256 amount) external;
}

interface ILPStake{
    function receiveWETHFee(uint256 amount) external;
}

contract BrokerV2 is ERC721Holder, BrokerModifiers {
    // events
    event Bid(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address bidder,
        uint256 amouont,
        uint256 time,
        address ERC20Address
    );
    event Buy(
        address indexed collection,
        uint256 tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 amount,
        uint256 time,
        address ERC20Address,
        bool isOffer
    );
    event Collect(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        address collector,
        uint256 time,
        address ERC20Address
    );
    event OnSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event PriceUpdated(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 oldAmount,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event OffSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 time,
        address ERC20Address
    );

    event MakeAnOffer(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed offerer,
        address erc20Token,
        uint256 offerAmount
    );

    mapping(address => uint256) public brokerageBalance;

    //Struct of Asset
    struct Asset {
        uint256 _tokenID;
        uint256 _startingPrice;
        uint256 _auctionType;
        uint256 _buyPrice;
        uint256 _startingTime;
        uint256 _closingTime;
        address _mintableToken;
        address _erc20Token;
    }

    //Struct of Pair
    struct Pair {
        uint256 tokenID;
        address _mintableToken;
    }    

    constructor(
        uint16 _rewardDistributionPercentage,
        uint16 _platFormFeePercentage,
        uint16 _lpStakefeepercentage,
        uint256 _updatedTime,
        address _weth,
        address _rewardDistributionAddress,
        address _lpStakeAddress
    ) public {
        rewardDistributionPercentage = _rewardDistributionPercentage;
        platFormFeePercentage = _platFormFeePercentage;
        setUpdatedClosingTime(_updatedTime);
        transferOwnership(msg.sender);
        WETHAddress =_weth;
        StakeAddress = _rewardDistributionAddress;
        LPStakeAddress = _lpStakeAddress;
        lpStakefeepercentage = _lpStakefeepercentage;
    }    

    //Update contract parameter
    function updateparams(
        uint16 _rewardDistributionPercentage,
        uint16 _platFormFeePercentage,
        uint16 _lpStakefeepercentage,
        uint256 _updatedTime,
        address _weth,
        address _rewardDistributionAddress,
        address _lpStakeAddress
    ) external onlyOwner {
        
        require(_rewardDistributionAddress != address(0) &&_lpStakeAddress!=address(0), "Address is Zero");
        require(_rewardDistributionPercentage >= 0 && _platFormFeePercentage >= 0 &&_lpStakefeepercentage>=0, "should be greater than zero");
        require(_rewardDistributionPercentage <= 1000 && _platFormFeePercentage <= 1000 && _lpStakefeepercentage<=1000, "should be greater than zero");
       
        rewardDistributionPercentage = _rewardDistributionPercentage;
        platFormFeePercentage = _platFormFeePercentage;
        setUpdatedClosingTime(_updatedTime);
        WETHAddress =_weth;
        StakeAddress = _rewardDistributionAddress;
        LPStakeAddress = _lpStakeAddress;
        lpStakefeepercentage = _lpStakefeepercentage;

    }



    // Method to create any offer for any NFT.
    function makeAnOffer(
        uint256 tokenID,
        address _mintableToken,
        address _erc20Token,
        uint256 amount
    ) public payable erc20Allowed(_erc20Token) {
        // Allow offer only if token is not auction or auction have been ended withoud any bids.
        if (auctions[_mintableToken][tokenID].auctionType == 2) {
            require(
                block.timestamp <
                    auctions[_mintableToken][tokenID].closingTime &&
                    !auctions[_mintableToken][tokenID].buyer,
                "Can not make an offer on an incomplete auction"
            );
        }

        // Check if the amount offered is better than previous
        require(
            amount >= offerprice[_mintableToken][tokenID][_erc20Token].amount,
            "amount is not less  than msg value"
        );

        // Revert previous offer
        _revertOffer(_mintableToken, tokenID, _erc20Token);

        // If the offer is not native currency
        if (_erc20Token == address(0)) {
            require(msg.value >= amount, "Value sent less than amount");
        } else {
            IERC20 erc20Token = IERC20(_erc20Token);
            require(
                erc20Token.allowance(msg.sender, address(this)) >= amount,
                "Insufficient spent allowance "
            );
            erc20Token.transferFrom(msg.sender, address(this), amount);
        }

        // Update the offer
        offerprice[_mintableToken][tokenID][_erc20Token].offerer = msg.sender;
        offerprice[_mintableToken][tokenID][_erc20Token].amount = amount;

        // Trigger the event
        emit MakeAnOffer(
            _mintableToken,
            tokenID,
            msg.sender,
            _erc20Token,
            amount
        );
    }

    // Method to accept an offer.
    function accpetOffer(
        uint256 tokenID,
        address _mintableToken,
        address _erc20Token,
        bool isNotClubare
    )
        public
        payable
        flatSaleOnly(tokenID, _mintableToken)
        tokenOwnerOnlly(tokenID, _mintableToken)
        erc20Allowed(_erc20Token)
    {
        // Chekc offer details and offer exists.
        OfferDetails memory _offer = offerprice[_mintableToken][tokenID][
            _erc20Token
        ];
        require(
            _offer.offerer != address(0),
            "selected candidate amount not match "
        );


        IMintableToken Token = IMintableToken(_mintableToken);

        _calculateFees(tokenID, _mintableToken, msg.sender, _erc20Token, _offer.amount, isNotClubare, false);

        tokenOpenForSale[_mintableToken][tokenID] = false;

        // Transfer the NFT
        Token.safeTransferFrom(Token.ownerOf(tokenID), _offer.offerer, tokenID);

        // Buy event
        emit Buy(
            _mintableToken,
            tokenID,
            msg.sender,
            _offer.offerer,
            _offer.amount,
            block.timestamp,
            _erc20Token,
            true
        );

        // delete all auctin details.
        delete offerprice[_mintableToken][tokenID][_erc20Token];
        _revertAll(_mintableToken, tokenID);
        TokenDetArrayLib.TokenDet memory _tokenDet = TokenDetArrayLib.TokenDet(
            _mintableToken,
            tokenID
        );
        tokensForSale.removeTokenDet(_tokenDet);
        tokensForSalePerUser[msg.sender].removeTokenDet(_tokenDet);
        fixedPriceTokens.removeTokenDet(_tokenDet);
        delete auctions[_tokenDet.NFTAddress][_tokenDet.tokenID];
    }

    function _calculateFees(uint256 tokenID, address _collectionAddress, address payable _lastOwner2, address _erc20Token, uint256 amount, bool isNotClubare, bool isBuymethod) internal {

        IMintableToken Token = IMintableToken(_collectionAddress);
        {
            uint256 royalities;
            address payable creator;
            uint256 royality;
            if (!isNotClubare) {
                royalities = Token.royalities(tokenID);
                creator = Token.creators(tokenID);
                royality = (royalities * amount) / 10000;
            }

            uint256 stakingAmt = ((rewardDistributionPercentage *
                amount) / 10000);
            uint256 lpStakingAmt = ((lpStakefeepercentage *
                amount) / 10000);
            uint256 brokerage = ((platFormFeePercentage *
                amount) / 10000);

            uint256 lastOwner_funds = amount -
                royality -
                stakingAmt -
                lpStakingAmt-
                brokerage;

            address payable user = msg.sender;
            address payable lastOwner2 = _lastOwner2;
            IWETH weth = IWETH(WETHAddress);
        
            if (_erc20Token == address(0)) {
                if (isBuymethod) {
                    require(msg.value >= amount, "Insufficient Payment");                
                }
                if (!isNotClubare) {
                    creator.transfer(royality);
                }
                lastOwner2.transfer(lastOwner_funds);
                weth.deposit.value(stakingAmt+lpStakingAmt)();
            } else {
                IERC20 erc20Token = IERC20(_erc20Token);                
                if (isBuymethod) {
                    require(
                        erc20Token.allowance(user, address(this)) >=
                            amount,
                        "Insufficient spent allowance "
                    );
                    erc20Token.transferFrom(user, address(this), brokerage + stakingAmt + lpStakingAmt);
                    // transfer royalitiy to creator
                    if (!isNotClubare) {
                        erc20Token.transferFrom(user, creator, royality);
                    }
                    erc20Token.transferFrom(user, lastOwner2, lastOwner_funds);
                } else {                    
                    if (!isNotClubare) {
                        erc20Token.transfer(creator, royality);
                    }
                    erc20Token.transfer(lastOwner2, lastOwner_funds);
                }
            }
            if(_erc20Token==address(0)|| _erc20Token==WETHAddress){
                if(stakingAmt > 0) {
                    weth.approve(address(StakeAddress), stakingAmt);
                    IStake stake = IStake(StakeAddress);
                    stake.receiveWETHFee(stakingAmt);
                }
                if(lpStakingAmt > 0) {
                    weth.approve(address(LPStakeAddress), lpStakingAmt);
                    ILPStake lpStake = ILPStake(LPStakeAddress);
                    lpStake.receiveWETHFee(lpStakingAmt);
                }
            }
        
            // Update the brokerage and auction state of NFT
            address _stackDeep_erc20Token = _erc20Token;
            brokerageBalance[_stackDeep_erc20Token] += brokerage + stakingAmt + lpStakingAmt;
        }
    }

    // Method to update revert the current offer.
    function _revertOffer(
        address _mintableToken,
        uint256 tokenID,
        address _erc20Token
    ) internal {
        // If there is any amount offered for this currency
        if (
            offerprice[_mintableToken][tokenID][_erc20Token].amount > 0 &&
            offerprice[_mintableToken][tokenID][_erc20Token].offerer !=
            address(0)
        ) {
            // Revert amount for native currency
            if (_erc20Token == address(0)) {
                address(
                    uint160(
                        offerprice[_mintableToken][tokenID][_erc20Token].offerer
                    )
                ).transfer(
                        offerprice[_mintableToken][tokenID][_erc20Token].amount
                    );
            } else {
                // Revert other currency
                IERC20 erc20 = IERC20(_erc20Token);
                erc20.transfer(
                    offerprice[_mintableToken][tokenID][_erc20Token].offerer,
                    offerprice[_mintableToken][tokenID][_erc20Token].amount
                );
            }

            // Delete the mapping to gas reward.
            delete offerprice[_mintableToken][tokenID][_erc20Token];
        }
    }

    // Method to revert all offers on current tokenId.
    function _revertAll(address _mintableToken, uint256 tokenID) internal {
        for (uint256 i = 0; i < erc20TokensArray.array.length; i++) {
            _revertOffer(_mintableToken, tokenID, erc20TokensArray.array[i]);
        }
    }

    // Public method to revert offer
    function revertOffer(
        address _mintableToken,
        uint256 tokenID,
        address _erc20Token
    ) public payable {
        // only allowed to token owner of offerer
        require(
            msg.sender ==
                offerprice[_mintableToken][tokenID][_erc20Token].offerer ||
                IMintableToken(_mintableToken).ownerOf(tokenID) == msg.sender,
            "You must be offerer or owner to remove the offer."
        );
        // Must be valid offer
        require(
            offerprice[_mintableToken][tokenID][_erc20Token].amount > 0 &&
                offerprice[_mintableToken][tokenID][_erc20Token].offerer !=
                address(0),
            " Offer doesn't exist. "
        );
        // revert offer
        _revertOffer(_mintableToken, tokenID, _erc20Token);
    }

    // Public method to allow token owner to discard all offers
    function revertAll(address _mintableToken, uint256 tokenID)
        public
        tokenOwnerOnlly(tokenID, _mintableToken)
    {
        _revertAll(_mintableToken, tokenID);
    }

    function addERC20TokenPayment(address _erc20Token) public onlyOwner {
        erc20TokensArray.addERC20Tokens(_erc20Token);
    }

    function removeERC20TokenPayment(address _erc20Token)
        public
        erc20Allowed(_erc20Token)
        onlyOwner
    {
        erc20TokensArray.removeERC20Token(_erc20Token);
    }

    function bid(
        uint256 tokenID,
        address _mintableToken,
        uint256 amount
    )
        public
        payable
        onSaleOnly(tokenID, _mintableToken)
        activeAuction(tokenID, _mintableToken)
    {
        IMintableToken Token = IMintableToken(_mintableToken);

        auction memory _auction = auctions[_mintableToken][tokenID];

        if (_auction.erc20Token == address(0)) {
            require(
                msg.value > _auction.currentBid,
                "Insufficient bidding amount."
            );

            if (_auction.buyer == true) {
                _auction.highestBidder.transfer(_auction.currentBid);
            }
        } else {
            IERC20 erc20Token = IERC20(_auction.erc20Token);
            require(
                erc20Token.allowance(msg.sender, address(this)) >= amount,
                "Allowance is less than amount sent for bidding."
            );
            require(
                amount > _auction.currentBid,
                "Insufficient bidding amount."
            );
            erc20Token.transferFrom(msg.sender, address(this), amount);

            if (_auction.buyer == true) {
                erc20Token.transfer(
                    _auction.highestBidder,
                    _auction.currentBid
                );
            }
        }

        _auction.currentBid = _auction.erc20Token == address(0)
            ? msg.value
            : amount;

        Token.safeTransferFrom(Token.ownerOf(tokenID), address(this), tokenID);
        _auction.buyer = true;
        _auction.highestBidder = msg.sender;
        _auction.closingTime += updateClosingTime;
        auctions[_mintableToken][tokenID] = _auction;

        // Bid event
        emit Bid(
            _mintableToken,
            tokenID,
            _auction.lastOwner,
            _auction.highestBidder,
            _auction.currentBid,
            block.timestamp,
            _auction.erc20Token
        );
    }

    struct TokenDetails {
        uint256 tokenID;
        address _mintableToken;
        bool isNotClubare;
    }

    // Collect Function are use to collect funds and NFT from Broker
    function collect(
        uint256 tokenID,
        address _mintableToken,
        bool isNotClubare
    ) public {
        IMintableToken Token = IMintableToken(_mintableToken);
        auction memory _auction = auctions[_mintableToken][tokenID];
        TokenDetArrayLib.TokenDet memory _tokenDet = TokenDetArrayLib.TokenDet(
            _mintableToken,
            tokenID
        );
        require(
            block.timestamp > _auction.closingTime && _auction.auctionType == 2,
            "Auction Not Over!"
        );
        
        if (_auction.buyer == true) {
            address payable lastOwner2 = _auction.lastOwner;
             _calculateFees(tokenID, _mintableToken, lastOwner2, _auction.erc20Token, _auction.currentBid, isNotClubare, false);

            {
                //Scope added for stack too deep error
                uint id = tokenID;
                auction memory auction = _auction;
                Token.safeTransferFrom(
                    Token.ownerOf(id),
                    auction.highestBidder,
                    id
                );

                // Buy event
                emit Buy(
                    _tokenDet.NFTAddress,
                    _tokenDet.tokenID,
                    lastOwner2,
                    auction.highestBidder,
                    auction.currentBid,
                    block.timestamp,
                    auction.erc20Token,
                    false
                );
                // Revert all the offers.
                _revertAll(_mintableToken, id);
            }

            // Collect event
            emit Collect(
                _tokenDet.NFTAddress,
                _tokenDet.tokenID,
                lastOwner2,
                _auction.highestBidder,
                msg.sender,
                block.timestamp,
                _auction.erc20Token
            );
            tokenOpenForSale[_mintableToken][tokenID] = false;
            tokensForSale.removeTokenDet(_tokenDet);

            tokensForSalePerUser[lastOwner2].removeTokenDet(_tokenDet);
            auctionTokens.removeTokenDet(_tokenDet);
            delete auctions[_mintableToken][tokenID];
        }
    }

    function buy(
        uint256 tokenID,
        address _mintableToken,
        bool isNotClubare
    )
        public
        payable
        onSaleOnly(tokenID, _mintableToken)
        flatSaleOnly(tokenID, _mintableToken)
    {
        IMintableToken Token = IMintableToken(_mintableToken);
        auction memory _auction = auctions[_mintableToken][tokenID];
        TokenDetArrayLib.TokenDet memory _tokenDet = TokenDetArrayLib.TokenDet(
            _mintableToken,
            tokenID
        );
        address payable lastOwner2 = _auction.lastOwner;
        _calculateFees(tokenID, _mintableToken, lastOwner2, _auction.erc20Token, _auction.buyPrice, isNotClubare, true);

        tokenOpenForSale[_tokenDet.NFTAddress][_tokenDet.tokenID] = false;

        Token.safeTransferFrom(
            Token.ownerOf(_tokenDet.tokenID),
            msg.sender,
            _tokenDet.tokenID
        );

        // Buy event
        emit Buy(
            _tokenDet.NFTAddress,
            _tokenDet.tokenID,
            lastOwner2,
            msg.sender,
            _auction.buyPrice,
            block.timestamp,
            _auction.erc20Token,
            false
        );

        tokensForSale.removeTokenDet(_tokenDet);
        tokensForSalePerUser[lastOwner2].removeTokenDet(_tokenDet);

        fixedPriceTokens.removeTokenDet(_tokenDet);
        delete auctions[_tokenDet.NFTAddress][_tokenDet.tokenID];
        _revertAll(_tokenDet.NFTAddress, _tokenDet.tokenID);
    }

    function withdraw() public onlyOwner {
        msg.sender.transfer(brokerageBalance[address(0)]);
        brokerageBalance[address(0)] = 0;
    }

    function withdrawERC20(address _erc20Token) public onlyOwner {
        require(
            erc20TokensArray.exists(_erc20Token),
            "This erc20token payment not allowed"
        );
        IERC20 erc20Token = IERC20(_erc20Token);
        erc20Token.transfer(msg.sender, brokerageBalance[_erc20Token]);
        brokerageBalance[_erc20Token] = 0;
    }

    function putOnSale(
        uint256 _tokenID,
        uint256 _startingPrice,
        uint256 _auctionType,
        uint256 _buyPrice,
        uint256 _startingTime,
        uint256 _closingTime,
        address _mintableToken,
        address _erc20Token
    )
        public
        erc20Allowed(_erc20Token)
        tokenOwnerOnlly(_tokenID, _mintableToken)
    {
        IMintableToken Token = IMintableToken(_mintableToken);
        auction memory _auction = auctions[_mintableToken][_tokenID];

        // Allow to put on sale to already on sale NFT \
        // only if it was on auction and have 0 bids and auction is over
        if (tokenOpenForSale[_mintableToken][_tokenID] == true) {
            require(
                _auction.auctionType == 2 &&
                    _auction.buyer == false &&
                    block.timestamp > _auction.closingTime,
                "This NFT is already on sale."
            );
        }
        TokenDetArrayLib.TokenDet memory _tokenDet = TokenDetArrayLib.TokenDet(
            _mintableToken,
            _tokenID
        );
        auction memory newAuction = auction(
            msg.sender,
            _startingPrice,
            address(0),
            _auctionType,
            _startingPrice,
            _buyPrice,
            false,
            _startingTime,
            _closingTime,
            _erc20Token
        );

        require(
            (Token.isApprovedForAll(msg.sender, address(this)) ||
                Token.getApproved(_tokenDet.tokenID) == address(this)),
            "Broker Not approved"
        );
        require(
            _closingTime > _startingTime,
            "Closing time should be greater than starting time!"
        );
        auctions[_tokenDet.NFTAddress][_tokenDet.tokenID] = newAuction;

        // Store data in all mappings if adding fresh token on sale
        if (
            tokenOpenForSale[_tokenDet.NFTAddress][_tokenDet.tokenID] == false
        ) {
            tokenOpenForSale[_tokenDet.NFTAddress][_tokenDet.tokenID] = true;

            tokensForSale.addTokenDet(_tokenDet);
            tokensForSalePerUser[msg.sender].addTokenDet(_tokenDet);

            // Add token to fixedPrice on Timed list
            if (_auctionType == 1) {
                fixedPriceTokens.addTokenDet(_tokenDet);
            } else if (_auctionType == 2) {
                auctionTokens.addTokenDet(_tokenDet);
            }
        }

        // OnSale event
        emit OnSale(
            _tokenDet.NFTAddress,
            _tokenDet.tokenID,
            msg.sender,
            newAuction.auctionType,
            newAuction.auctionType == 1
                ? newAuction.buyPrice
                : newAuction.startingPrice,
            block.timestamp,
            newAuction.erc20Token
        );
    }

    /**
     * @notice Bulk De listing from marketplace
     * @param _assets array of struct Asset[]
     **/
    function batchListing(Asset[] calldata _assets) external {
        for (uint i = 0; i < _assets.length; i++) {
            Asset memory a = _assets[i];
            putOnSale(
                a._tokenID,
                a._startingPrice,
                a._auctionType,
                a._buyPrice,
                a._startingTime,
                a._closingTime,
                a._mintableToken,
                a._erc20Token
            );
        }
    }

    function updatePrice(
        uint256 tokenID,
        address _mintableToken,
        uint256 _newPrice,
        address _erc20Token
    )
        public
        onSaleOnly(tokenID, _mintableToken)
        erc20Allowed(_erc20Token)
        tokenOwnerOnlly(tokenID, _mintableToken)
    {
        // IMintableToken Token = IMintableToken(_mintableToken);
        auction memory _auction = auctions[_mintableToken][tokenID];

        if (_auction.auctionType == 2) {
            require(
                block.timestamp < _auction.closingTime,
                "Auction Time Over!"
            );
        }
        emit PriceUpdated(
            _mintableToken,
            tokenID,
            _auction.lastOwner,
            _auction.auctionType,
            _auction.auctionType == 1
                ? _auction.buyPrice
                : _auction.startingPrice,
            _newPrice,
            block.timestamp,
            _auction.erc20Token
        );
        // Update Price
        if (_auction.auctionType == 1) {
            _auction.buyPrice = _newPrice;
        } else {
            _auction.startingPrice = _newPrice;
            _auction.currentBid = _newPrice;
        }
        _auction.erc20Token = _erc20Token;
        auctions[_mintableToken][tokenID] = _auction;
    }

    function putSaleOff(uint256 tokenID, address _mintableToken)
        public
        tokenOwnerOnlly(tokenID, _mintableToken)
    {
        // IMintableToken Token = IMintableToken(_mintableToken);
        auction memory _auction = auctions[_mintableToken][tokenID];
        TokenDetArrayLib.TokenDet memory _tokenDet = TokenDetArrayLib.TokenDet(
            _mintableToken,
            tokenID
        );
        tokenOpenForSale[_mintableToken][tokenID] = false;

        // OffSale event
        emit OffSale(
            _mintableToken,
            tokenID,
            msg.sender,
            block.timestamp,
            _auction.erc20Token
        );

        tokensForSale.removeTokenDet(_tokenDet);

        tokensForSalePerUser[msg.sender].removeTokenDet(_tokenDet);
        // Remove token from list
        if (_auction.auctionType == 1) {
            fixedPriceTokens.removeTokenDet(_tokenDet);
        } else if (_auction.auctionType == 2) {
            auctionTokens.removeTokenDet(_tokenDet);
        }
        delete auctions[_mintableToken][tokenID];
    }

    /**
     * @notice Bulk De listing from marketplace
     * @param _pairs array of struct Pair[]
     **/
    function batchDelisting(Pair[] calldata _pairs) external {
        for (uint i = 0; i < _pairs.length; i++) {
            Pair memory p = _pairs[i];
            putSaleOff(p.tokenID, p._mintableToken);
        }
    }

    function getOnSaleStatus(address _mintableToken, uint256 tokenID)
        public
        view
        returns (bool)
    {
        return tokenOpenForSale[_mintableToken][tokenID];
    }
}