// SPDX-License-Identifier: unlisenced
pragma solidity ^0.8.0;
import "./IMarket.sol";
import "./Imint721.sol";
import "./IERC165.sol";
import "./Imint1155.sol";
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract Market is IMarket {
    mapping(address => mapping(uint256 => mapping(address => MarketInfo)))
        public saleInfo;
    mapping(address => mapping(uint256 => mapping(address => AuctionInfo)))
        public auctionInfo;
    mapping(address => mapping(uint256 => mapping(address => BidInfo))) bidInfo;

    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    function isERC721(address nftAddress) private view returns (bool) {
        bytes4 IID_IERC721 = type(IERC721).interfaceId;
        return IERC165(nftAddress).supportsInterface(IID_IERC721);
    }

    function isERC1155(address nftAddress) private view returns (bool) {
        bytes4 IID_IERC1155 = type(IERC1155).interfaceId;
        return IERC165(nftAddress).supportsInterface(IID_IERC1155);
    }

    function wrongAddress() private pure {
        revert("Market: wrong address");
    }

    function _contractAddress(address contractAddress)
        private
        view
    {
        if (isERC721(contractAddress)) {
            // require(seller == address(0), "Market: zero address");
        } else if (isERC1155(contractAddress)) {} else {
            wrongAddress();
        }
    }

    function mint(
        address contractAddress,
        uint256 id,
        uint256 amount
    ) external {
        amountOfToken(contractAddress,amount);
        if (isERC721(contractAddress)) {
            // require(amount == 1, "Market: amount must be 1");
            Imint721(contractAddress).mint(msg.sender);
        } else if (isERC1155(contractAddress)) {
            // require(amount > 0, "Market: amount cannot be zero");
            Imint1155(contractAddress).mint(msg.sender, id, amount);
        } else {
            wrongAddress();
        }
    }

    function sell(
        address contractAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external {
        _price(price);
        // require(price > 0, "Market: price cannot be zero");
        // address sellBy;
        amountOfToken(contractAddress, amount);
        if (isERC721(contractAddress)) {
            // _erc721CheckOwner(msg.sender, tokenId, contractAddress);
            _erc721Approval(tokenId, contractAddress);
            _saleOrAuction(tokenId, contractAddress, msg.sender, amount);

            // sellBy = address(0);
        } else if (isERC1155(contractAddress)) {
            _saleOrAuction(tokenId, contractAddress, msg.sender, amount);

            _erc1155Approval(msg.sender, contractAddress);
            // sellBy = msg.sender;
        } else {
            wrongAddress();
        }
        saleInfo[contractAddress][tokenId][msg.sender] = MarketInfo(
            msg.sender,
            tokenId,
            amount,
            price
        );
        emit Sell(contractAddress, msg.sender, tokenId, amount, price);
    }

    function buy(
        address contractAddress,
        uint256 id,
        uint256 amount,
        address from
    ) external payable {
        address tempOwner;
        uint256 tempValue;
        amountOfToken(contractAddress, amount);
        if (isERC721(contractAddress)) {
            notOnSell(saleInfo[contractAddress][id][from].owner);
            // from = address(0);

            address owner = saleInfo[contractAddress][id][from].owner;
            // _erc721CheckOwner(owner, id, contractAddress);
            noOwnerAllowed(owner);
            // require(msg.sender != owner, "Market: you are the owner");

            _erc721Approval(id, contractAddress);
            // require(
            //     msg.value == saleInfo[contractAddress][id][address(0)].price,
            //     "Market: please enter the exact price"
            // );
            inputPrice(saleInfo[contractAddress][id][from].price);

            tempOwner = saleInfo[contractAddress][id][from].owner;
            tempValue = saleInfo[contractAddress][id][from].price;
            erc721Transfer(contractAddress, id, owner, msg.sender);
            delete saleInfo[contractAddress][id][from];
        } else if (isERC1155(contractAddress)) {
            
            notOnSell(from);

            uint256 amountForSell = saleInfo[contractAddress][id][from].amount;
            noOwnerAllowed(from);

            // require(msg.sender != from, "Market: you are the owner");
            // require(
            //     amountForSell >= amount,
            //     "Market: not enough amount in sell"
            // );
            _insufficientTokens(amountForSell,amount);
            _erc1155Approval(from, contractAddress);

            // require(
            //     msg.value == saleInfo[contractAddress][id][from].price * amount,
            //     "Market: please enter exact amount"
            // );

            inputPrice( saleInfo[contractAddress][id][from].price * amount);
            tempOwner = saleInfo[contractAddress][id][from].owner;
            tempValue = msg.value;
            erc1155Transfer(
                contractAddress,
                id,
                tempOwner = saleInfo[contractAddress][id][from].owner,
                msg.sender,
                amount
            );
            saleInfo[contractAddress][id][from].amount = amountForSell - amount;
            if (saleInfo[contractAddress][id][from].amount == 0) {
                delete saleInfo[contractAddress][id][from];
            }
        }
        ethTransfer(tempOwner,tempValue);
        // payable(tempOwner).transfer(tempValue);
        emit Buy(contractAddress, id, amount, tempOwner);
    }

    function cancelSell(address contractAddress, uint256 id) external {
        // address cancelBy;
        if (isERC721(contractAddress)) {
            _erc721CheckOwner(msg.sender,id,contractAddress);
            // cancelBy = address(0);
        } else if (isERC1155(contractAddress)) {
            // cancelBy = msg.sender;
        } else {
            wrongAddress();
        }

        notOnSell(saleInfo[contractAddress][id][msg.sender].owner);
        delete saleInfo[contractAddress][id][msg.sender];
    }

    function setAuction(
        address contractAddress,
        uint256 id,
        uint256 amount,
        uint256 basePrice,
        uint256 auctionTime
    ) external {
        _price(basePrice);
        // require(basePrice > 0, "Market: price cannot be zero");
        timeLimit(auctionTime);
        // address auctionFrom;
        amountOfToken(contractAddress, amount);
        if (isERC721(contractAddress)) {
            // _erc721CheckOwner(msg.sender, id, contractAddress);
            _erc721Approval(id, contractAddress);


            _saleOrAuction(id, contractAddress,msg.sender, amount);

            // auctionFrom = address(0);
        } else if (isERC1155(contractAddress)) {
            // require(
            //     IERC1155(contractAddress).balanceOf(msg.sender, id) >=
            //         amount + saleInfo[contractAddress][id][msg.sender].amount,
            //     "Market: insufficient tokens in account for auction"
            // );
            _saleOrAuction(id, contractAddress, msg.sender, amount);

            require(
                auctionInfo[contractAddress][id][msg.sender].owner ==
                    address(0),
                "Market: token already in auction"
            );

            _erc1155Approval(msg.sender, contractAddress);
            // auctionFrom = msg.sender;
        } else {
            wrongAddress();
        }
        auctionInfo[contractAddress][id][msg.sender] = AuctionInfo(
            msg.sender,
            id,
            amount,
            basePrice,
            block.timestamp,
            auctionTime,
            0,
            address(0)
        );
        emit SetAuction(
            contractAddress,
            msg.sender,
            id,
            amount,
            basePrice,
            block.timestamp,
            auctionTime
        );
    }

    function bidInAuction(
        address contractAddress,
        uint256 id,
        address seller
    ) external payable {
        notOnSell(auctionInfo[contractAddress][id][seller].owner);

        timeLimit(auctionInfo[contractAddress][id][seller].auctionTime);
        noOwnerAllowed(auctionInfo[contractAddress][id][seller].owner);
        // require(msg.sender != auctionInfo[contractAddress][id][seller].owner, "Auction: you are the owner");




















        _contractAddress(contractAddress);
        require(
            msg.value >= auctionInfo[contractAddress][id][seller].price && msg.value > auctionInfo[contractAddress][id][seller].maxBid,
            "Market: value should be greater than base price and last bid"
        );
        // require(
        //     msg.value > auctionInfo[contractAddress][id][seller].maxBid,
        //     "Auction: your bid is not the highest"
        // );

        auctionInfo[contractAddress][id][seller].maxBid = msg.value;
        auctionInfo[contractAddress][id][seller].maxAddress = msg.sender;
        bidInfo[contractAddress][id][seller].bids.push(msg.value);
        bidInfo[contractAddress][id][seller].bidders.push(msg.sender);

        emit bid(contractAddress, id, seller);
    }

    function cancelBid(
        address contractAddress,
        uint256 id,
        address seller
    ) external {
        _contractAddress(contractAddress);

        timeLimit(auctionInfo[contractAddress][id][seller].auctionTime);
        uint256 maxVal = 0;
        address maxAddr;
        uint256 cancelledBid;
        for (
            uint256 index;
            index < bidInfo[contractAddress][id][seller].bids.length;
            index++
        ) {
            if (
                bidInfo[contractAddress][id][seller].bidders[index] ==
                msg.sender
            ) {
                cancelledBid = bidInfo[contractAddress][id][seller].bids[index];
                delete bidInfo[contractAddress][id][seller].bids[index];
                delete bidInfo[contractAddress][id][seller].bidders[index];
            } else if (
                bidInfo[contractAddress][id][seller].bids[index] > maxVal
            ) {
                maxVal = bidInfo[contractAddress][id][seller].bids[index];
                maxAddr = bidInfo[contractAddress][id][seller].bidders[index];
            }
        }

        auctionInfo[contractAddress][id][seller].maxBid = maxVal;
        auctionInfo[contractAddress][id][seller].maxAddress = maxAddr;
        ethTransfer(msg.sender,cancelledBid);
        // payable(msg.sender).transfer(cancelledBid);

        emit CancelBid(contractAddress, id, seller);
    }

    function claimToken(
        address contractAddress,
        uint256 id,
        address seller
    ) external {
        _contractAddress(contractAddress);
        notOnSell(auctionInfo[contractAddress][id][seller].owner);
        require(
            block.timestamp >
                auctionInfo[contractAddress][id][seller].auctionTime,
            "Market: auction is not over yet"
        );
        // require(
        //     auctionInfo[contractAddress][id][seller].maxAddress != address(0),
        //     "Auction: no one bidded"
        // );
        require(
            msg.sender == auctionInfo[contractAddress][id][seller].maxAddress,
            "Market: only winner can access"
        );
        address transferTo;
        uint256 transferAmount;
        // address __owner;
        if (isERC721(contractAddress)) {
            address owner = IERC721(contractAddress).ownerOf(id);
            // __owner = owner;

            _erc721Approval(id, contractAddress);
            erc721Transfer(
                contractAddress,
                id,
                owner,
                auctionInfo[contractAddress][id][seller].maxAddress
            );
            // seller = address(0);
        } else if (isERC1155(contractAddress)) {
            _erc1155Approval(seller, contractAddress);
            // require(
            //     IERC1155(contractAddress).balanceOf(
            //         auctionInfo[contractAddress][id][seller].owner,
            //         id
            //     ) >= auctionInfo[contractAddress][id][seller].amount,
            //     "Market: not enough tokens"
            // );

            _insufficientTokens( IERC1155(contractAddress).balanceOf(
                    auctionInfo[contractAddress][id][seller].owner,
                    id
                ) , auctionInfo[contractAddress][id][seller].amount);

            erc1155Transfer(
                contractAddress,
                id,
                auctionInfo[contractAddress][id][seller].owner,
                msg.sender,
                auctionInfo[contractAddress][id][seller].amount
            );
            // __owner = seller;
        } else {
            wrongAddress();
        }

        for (
            uint256 index;
            index < bidInfo[contractAddress][id][seller].bids.length;
            index++
        ) {
            if (
                bidInfo[contractAddress][id][seller].bidders[index] ==
                auctionInfo[contractAddress][id][seller].maxAddress
            ) {
                transferTo = bidInfo[contractAddress][id][seller].bidders[
                    index
                ];
                transferAmount = bidInfo[contractAddress][id][seller].bids[
                    index
                ];
            } else {
                transferTo = bidInfo[contractAddress][id][seller].bidders[
                    index
                ];
                transferAmount = bidInfo[contractAddress][id][seller].bids[
                    index
                ];
            }
            ethTransfer(transferTo,transferAmount);
            // payable(transferTo).transfer(transferAmount);
        }
        delete auctionInfo[contractAddress][id][seller];

        emit ClaimToken(contractAddress, id, seller);
    }

    function cancelAuction(address contractAddress, uint256 id) external {
        // address cancelFrom;
        if (isERC721(contractAddress)) {
            _erc721CheckOwner(msg.sender, id, contractAddress);
            // cancelFrom = address(0);
        } else if (isERC1155(contractAddress)) {
            // cancelFrom = msg.sender;
        } else {
            wrongAddress();
        }

        notOnSell(auctionInfo[contractAddress][id][msg.sender].owner);
        require(
        (block.timestamp < auctionInfo[contractAddress][id][msg.sender].auctionTime)|| (auctionInfo[contractAddress][id][msg.sender].maxAddress == address(0)),"cancel not allowed" );

        for (
            uint256 index;
            index < bidInfo[contractAddress][id][msg.sender].bids.length;
            index++
        ) {
            ethTransfer(bidInfo[contractAddress][id][msg.sender].bidders[index],bidInfo[contractAddress][id][msg.sender].bids[index]);
            // payable(bidInfo[contractAddress][id][cancelFrom].bidders[index])
            //     .transfer(bidInfo[contractAddress][id][cancelFrom].bids[index]);
        }

        delete auctionInfo[contractAddress][id][msg.sender];
    }


    function _price(uint __price) private pure{
        require(__price>0,"Market: price cannot be zero");
    }

    function timeLimit(uint256 auctionTime) private view {
        require(block.timestamp < auctionTime, "Market: auction is over");
    }

    function notOnSell(address addr) private pure {
        require(
            addr != address(0),
            "Market: not in market or incorrect address or you are not the owner"
        );
    }

    function amountOfToken(address contractAddress, uint256 amount)
        private
        view
    {
        if (isERC721(contractAddress)) {
            require(amount == 1, "Market: Only 1 amount is allowed");
        } else if (isERC1155(contractAddress)) {
            require(amount > 0, "Market: Only greater than 0 is allowed");
        } else {
            wrongAddress();
        }
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function noOwnerAllowed(address addr)private view{
        require(msg.sender!=addr,"Market: you are the owner");
    }

    function inputPrice(uint price) private view{
        require(msg.value == price,"Market: please enter exact price");
    }
    function erc721Transfer(
        address contractAddress,
        uint256 id,
        address from,
        address to
    ) private {
        IERC721(contractAddress).transferFrom(from, to, id);
    }

    function erc1155Transfer(
        address contractAddress,
        uint256 id,
        address from,
        address to,
        uint256 amount
    ) private {
        IERC1155(contractAddress).safeTransferFrom(
            from,
            to,
            id,
            amount,
            "0x00"
        );
    }

    function _saleOrAuction(
        uint256 id,
        address contractAddress,
        address seller,
        uint256 amount
    ) private view {
        if (isERC721(contractAddress)) {
            require(
                auctionInfo[contractAddress][id][seller].owner == address(0) &&
                    saleInfo[contractAddress][id][seller].owner == address(0),
                "Market: sale or auction is not allowed"
            );
        } else {
            require(
                IERC1155(contractAddress).balanceOf(seller, id) >=
                    (auctionInfo[contractAddress][id][seller].amount +
                        saleInfo[contractAddress][id][seller].amount) +
                        amount,
                "Market: balance is low for sale or auction"
            );
        }
    }

    function _insufficientTokens(uint availableToken, uint expectedTokens) private pure{
        require(availableToken >= expectedTokens,"Market: not enough tokens");
    }

    function _erc721Approval(uint256 id, address contractAddress) private view {
        require(
            IERC721(contractAddress).getApproved(id) == address(this),
            "Market: contract is not approved"
        );
    }

    function _erc721CheckOwner(
        address addr,
        uint256 id,
        address contractAddress
    ) private view {
        require(
            addr == IERC721(contractAddress).ownerOf(id),
            "Market: you are not the owner"
        );
    }

    function _erc1155Approval(address addr, address contractAddress)
        private
        view
    {
        require(
            IERC1155(contractAddress).isApprovedForAll(addr, address(this)),
            "Market: access not given to contract"
        );
    }

    function ethTransfer(address to, uint amount) private {
        payable(to).transfer(amount);
    }


    // function erc721saleOrAuction(address contractAddress,uint tokenId, uint amount) private view{
    //      _erc721Approval(tokenId, contractAddress);
    //     _saleOrAuction(tokenId, contractAddress, msg.sender, amount);
    // }
}

// SPDX-License-Identifier: unlisenced
pragma solidity ^0.8.0;
interface IERC1155 {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function mint(address to,uint256 id, uint256 amount) external;

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);
}

// SPDX-License-Identifier: unlisenced
pragma solidity ^0.8.0;


interface IERC165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: unlisenced
pragma solidity ^0.8.0;
 interface IERC721 {
    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external ;

    function mint(address to) external;

    function approve(address _approved, uint256 _tokenId) external payable;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );
}

// SPDX-License-Identifier: unlisenced
pragma solidity ^0.8.0;

interface IMarket {
    struct MarketInfo {
        address owner;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
    }

    struct AuctionInfo {
        address owner;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        uint256 startTime;
        uint256 auctionTime;
        uint256 maxBid;
        address maxAddress;
    }

    struct BidInfo {
        uint256[] bids;
        address[] bidders;
    }


    event Sell(
        address indexed contractAddress,
        address owner,
        uint256 indexed id,
        uint256 indexed amount,
        uint256 price
    );
    event SetAuction(
        address contractAddress,
        address from,
        uint256 indexed id,
        uint256 indexed amount,
        uint256 indexed basePrice,
        uint256 startTime,
        uint256 auctionTime
    );
    event Buy(
        address indexed contractAddress,
        uint256 indexed id,
        uint256 indexed amount,
        address from
    );
    event bid(
        address indexed contractAddress,
        uint256 indexed id,
        address indexed seller
    );
    event CancelBid(
        address indexed contractAddress,
        uint256 indexed id,
        address indexed seller
    );
    event ClaimToken(
        address indexed contractAddress,
        uint256 indexed id,
        address indexed seller
    );
}

// SPDX-License-Identifier: unlisenced
pragma solidity ^0.8.0;
import "./IERC1155.sol";

interface Imint1155 is IERC1155{
    function mint(address,uint,uint) external;

}

// SPDX-License-Identifier: unlisenced
pragma solidity ^0.8.0;
import "./IERC721.sol";

interface Imint721 is IERC721{
    function mint(address) external;

}