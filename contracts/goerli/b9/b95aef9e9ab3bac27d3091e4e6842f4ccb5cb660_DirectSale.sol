/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

// File: contracts/22_rabbit_direct_sale.sol

/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// File: DirectSale_flat.sol


// File: contracts/DirectSale.sol

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


interface IRabbitHoleNFTToken {
    function awardItem(address player, string memory tokenURI)
        external
        returns (uint256);
        function balanceOf(address owner) external returns (uint256);
        function transferFrom(address from, address to, uint256 tokenId) external;
        function ownerOf(uint256 tokenId) external view returns (address);
}

interface IRabbitHoleToken {
        function balanceOf(address owner) external returns (uint256);
        function transferFrom(address from, address to, uint256 amount) external;
        function approve(address spender, uint256 amount) external;
}

contract DirectSale {  
    struct Sale {
        uint saleId;
        uint256 price;
        address payable owner;
        uint paymentType; // ether = 1 , fiat = 2, rabbit = 3 
        uint256 status;
        string uri;
    }

    IRabbitHoleNFTToken public RBTHLNFT;
    IRabbitHoleToken public RBTH;
    address admin;

    struct SaleTxn {
        uint txId;
        uint256 price;
        address seller;
        address buyer;
        uint paymentType;
        uint256 status;
    }

    // gets updated during minting(creation), buying and reselling
    uint256 private pendingArtCount;
    mapping(uint256 => SaleTxn) private saleTxns;
    uint256 public index; // uint256 value; is cheaper than uint256 value = 0;.
    Sale[] public sales;

    // log events back to the user interface
    event LogTx(
        uint _txId,
        uint256 _price,
        address _current_owner,
        address _buyer,
        uint _paymentType,
        uint256 _status
    );

    event LogSale(
        uint _saleId,
        uint256 _price,
        address _current_owner,
        uint _paymentType,
        uint256 _status,
        string _uri
    );

    event LogArtResell(uint256 tokenId, uint256 _status, uint256 _price);

    constructor(address _rbthl,address adminAdd ,address _rabbitToken)
        // string memory name, string memory symbol, )
        // ERC721(name, symbol)
    {
        RBTHLNFT = IRabbitHoleNFTToken(_rbthl);
         admin = adminAdd;
         RBTH = IRabbitHoleToken(_rabbitToken);
    }

    function createNonMintedSale(
        uint256 _price,
        address payable _current_owner,
        uint  _paymentType,
        string memory _uri
    ) public {

            require((_paymentType > 0 && _paymentType < 4), "the _payment type should be between 1 and 3 ");
            require(bytes(_uri).length > 0, "the NFT uri can not be empty");
            require((_price > 0),"the price should be greater than 0 ");
            require(_current_owner != address(0), "the payment Type can not be empty");

         Sale memory _sale = Sale({
         saleId : index,
         price : _price,
         owner : _current_owner,
         paymentType : _paymentType,
         status : 1,
         uri : _uri
            });

            sales.push(_sale);

            emit LogSale(
                index,
                _price,
                _current_owner,
                _paymentType,
                1,
                _uri
            ); 
            index++;
            pendingArtCount++;  
    }

    function findSale(uint _saleId) public view returns(
            Sale memory 
            )
        {
                Sale memory sale = sales[_saleId];
                return(sale);

    }

    function BuyNonMintedArtEther(
        uint256 _saleId,
        address _buyerAddress)public payable{

        Sale memory salefound = findSale(_saleId);
        // uint sentValue = msg.value * 1e18;
        require(salefound.paymentType > 0,"there should be a payment type");
        require(salefound.owner != address(0),"internal error");
        require(_buyerAddress != address(0),"");

        require(msg.value >= salefound.price,"ether value should be greater than price");
        require(msg.sender != salefound.owner,"owner can not be the buyer ");

        // payable(msg.sender).transfer(msg.value - salefound.price);
        if(msg.value > salefound.price){
        uint excess = msg.value - salefound.price;
       (bool success, ) =  msg.sender.call{value: excess}('');
       require(success, "excess Transfer failed.");
        }
       //make a payment to the current owner

    //    address(this).transfer(salefound.price -(salefound.price / 20));
    //    someAddress.call{value: 1 ether}('');

        RBTHLNFT.awardItem(_buyerAddress, salefound.uri);

        //calculate the platform fees;
        (bool success2, ) =  salefound.owner.call{value:salefound.price -(salefound.price / 20)}('');
        require(success2, "excess Transfer failed.");
        // salefound.owner.transfer((salefound.price - (salefound.price / (20))));

        sales[salefound.saleId].status = 0;

        SaleTxn memory _saleTxn = SaleTxn({
         txId : salefound.saleId,
         price : salefound.price,
         seller : salefound.owner,
         buyer : _buyerAddress,
         paymentType : 1,
         status : 0
        });
        saleTxns[_saleId] = _saleTxn;
        pendingArtCount--;
       
        emit LogTx(
         _saleTxn.txId,
         _saleTxn.price,
         _saleTxn.seller,
         _saleTxn.buyer,
         _saleTxn.paymentType,
         _saleTxn.status
    );

    }

    function BuyNonMintedArtFiat(
        uint256 _saleId,
        address _buyerAddress)external{

        Sale memory salefound = findSale(_saleId);
        require(salefound.paymentType > 0,"payment type is required");
        require(salefound.owner != address(0),"owner is empty");
        require(_buyerAddress != address(0),"emptybuyerAddress");
        require(_buyerAddress != salefound.owner,"buyer is owner");
        require(msg.sender == admin,"you are not admin");

        RBTHLNFT.awardItem(_buyerAddress, salefound.uri); //mint the NFT

        sales[salefound.saleId].status = 0;
        SaleTxn memory _saleTxn = SaleTxn({
         txId : salefound.saleId,
         price : salefound.price,
         seller : salefound.owner,
         buyer : _buyerAddress,
         paymentType : 2,
         status : 0
        });
        // saleTxn[_saleId].push(_saleTxn);
        saleTxns[_saleId] = _saleTxn;
        pendingArtCount--;
       
        emit LogTx(
         _saleTxn.txId,
         _saleTxn.price,
         _saleTxn.seller,
         _saleTxn.buyer,
         _saleTxn.paymentType,
         _saleTxn.status
    );
    }

    function BuyNonMintedArtRabbit(
        uint256 _saleId,
        address _buyerAddress)public {
            Sale memory salefound = findSale(_saleId);
        require(salefound.paymentType > 0,"payment type should not be empty");
        require(salefound.owner != address(0),"owner can not be empty");

            require(msg.sender != address(0),"sender should be there");
        require(msg.sender != salefound.owner,"sender should not be owner");
        // require(msg.value >= salefound.price,"value");
        require(RBTH.balanceOf(msg.sender)>=salefound.price , "not enough balance");
        uint maximumAmount = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        RBTH.approve(address(this),maximumAmount);
        
        RBTH.transferFrom(msg.sender,address(this),salefound.price);

        RBTHLNFT.awardItem(_buyerAddress, salefound.uri);

        //calculate the platform fees;
        salefound.owner.transfer((salefound.price - salefound.price / (20)));

        sales[salefound.saleId].status = 0;

        SaleTxn memory _saleTxn = SaleTxn({
         txId : salefound.saleId,
         price : salefound.price,
         seller : salefound.owner,
         buyer : _buyerAddress,
         paymentType : 3,
         status : 0
        });
        saleTxns[_saleId] = _saleTxn;
        pendingArtCount--;
       
        emit LogTx(
         _saleTxn.txId,
         _saleTxn.price,
         _saleTxn.seller,
         _saleTxn.buyer,
         _saleTxn.paymentType,
         _saleTxn.status
    );

    }

    // function  BuyNonMintedArt(
    //     uint256 _saleId,
    //     address _buyerAddress
    // )external payable{
    //     Sale memory salefound = findSale(_saleId);
    //     require(salefound.paymentType > 0);
    //     require(salefound.owner != address(0));

    //     if(salefound.paymentType == 2){ //fiat
    //     require(_buyerAddress != address(0));
    //     require(_buyerAddress != salefound.owner);
    //     require(msg.sender == admin);

    //     RBTHLNFT.awardItem(_buyerAddress, salefound.uri); //mint the NFT

    //     sales[salefound.saleId].status = 0;
    //     SaleTxn memory _saleTxn = SaleTxn({
    //      txId : salefound.saleId,
    //      price : salefound.price,
    //      seller : salefound.owner,
    //      buyer : _buyerAddress,
    //      paymentType : 2,
    //      status : 0
    //     });
    //     // saleTxn[_saleId].push(_saleTxn);
    //     saleTxns[_saleId] = _saleTxn;
    //     pendingArtCount--;
       
    //     emit LogTx(
    //      _saleTxn.txId,
    //      _saleTxn.price,
    //      _saleTxn.seller,
    //      _saleTxn.buyer,
    //      _saleTxn.paymentType,
    //      _saleTxn.status
    // );
    //     }
    //     else if(salefound.paymentType == 1){ //ether
    //     require(msg.sender != address(0));
    //     require(msg.value >= salefound.price);
    //     require(msg.sender != salefound.owner);

    //     RBTHLNFT.awardItem(_buyerAddress, salefound.uri);

    //     //calculate the platform fees;
    //     salefound.owner.transfer((salefound.price - (salefound.price / (20))));

    //     sales[salefound.saleId].status = 0;

    //     SaleTxn memory _saleTxn = SaleTxn({
    //      txId : salefound.saleId,
    //      price : salefound.price,
    //      seller : salefound.owner,
    //      buyer : _buyerAddress,
    //      paymentType : 2,
    //      status : 0
    //     });
    //     saleTxns[_saleId] = _saleTxn;
    //     pendingArtCount--;
       
    //     emit LogTx(
    //      _saleTxn.txId,
    //      _saleTxn.price,
    //      _saleTxn.seller,
    //      _saleTxn.buyer,
    //      _saleTxn.paymentType,
    //      _saleTxn.status
    // );


            
    //     }else if(salefound.paymentType == 3){ //rabbit
    //     require(msg.sender != address(0));
    //     require(msg.sender != salefound.owner);
    //     require(msg.value >= salefound.price);
    //     require(RBTH.balanceOf(msg.sender)>=salefound.price , "not enough balance");
    //     RBTH.transferFrom(msg.sender,address(this),salefound.price);
    //     RBTHLNFT.awardItem(_buyerAddress, salefound.uri);

    //     //calculate the platform fees;
    //     salefound.owner.transfer((salefound.price - salefound.price / (20)));

    //     sales[salefound.saleId].status = 0;

    //     SaleTxn memory _saleTxn = SaleTxn({
    //      txId : salefound.saleId,
    //      price : salefound.price,
    //      seller : salefound.owner,
    //      buyer : _buyerAddress,
    //      paymentType : 2,
    //      status : 0
    //     });
    //     saleTxns[_saleId] = _saleTxn;
    //     pendingArtCount--;
       
    //     emit LogTx(
    //      _saleTxn.txId,
    //      _saleTxn.price,
    //      _saleTxn.seller,
    //      _saleTxn.buyer,
    //      _saleTxn.paymentType,
    //      _saleTxn.status
    // );   
    //     }
    // }

    function findAllPendingSale()
        public
        view
        returns (
            uint256[] memory,
            address[] memory,
            uint256[] memory
        )
    {
        if (pendingArtCount == 0) {
            return (
                new uint256[](0),
                new address[](0),
                new uint256[](0)
            );
        }

        uint256 arrLength = sales.length;
        uint256[] memory ids = new uint256[](pendingArtCount);
        address[] memory owners = new address[](pendingArtCount);
        uint256[] memory status = new uint256[](pendingArtCount);
        uint256 idx = 0;
        for (uint256 i = 0; i < arrLength; ++i) {
            Sale memory sale = sales[i];
            if (sale.status == 1) {
                ids[idx] = sale.saleId;
                owners[idx] = sale.owner;
                status[idx] = sale.status;
                idx++;
            }
        }

        return (ids, owners, status);
    }

    function findMyArts()
        public
        returns (uint256[] memory _myArts)
    {
        require(msg.sender != address(0));
        uint256 numOftokens = RBTHLNFT.balanceOf(msg.sender);
        if (numOftokens == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory myArts = new uint256[](numOftokens);
            uint256 idx = 0;
            uint256 arrLength = sales.length;
            for (uint256 i = 0; i < arrLength; i++) {
                if (RBTHLNFT.ownerOf(i) == msg.sender) {
                    myArts[idx] = i;
                    idx++;
                }
            }
            return myArts;
        }
    }
    function isOwnerOf(uint256 tokenId, address account)
        public
        view
        returns (bool)
    {
        address owner = RBTHLNFT.ownerOf(tokenId);
        require(owner != address(0));
        return owner == account;
    }

    


    // function sellMintedArt(uint256 tokenId, uint256 _price) public payable {
    //     require(msg.sender != address(0));
    //     require(isOwnerOf(tokenId, msg.sender));
    //     sales[tokenId].status = 1;
    //     sales[tokenId].price = _price;
    //     pendingArtCount++;
    //     emit LogArtResell(tokenId, 1, _price);
    // }


// function buy() public payable nonReentrant {

//             require(totalSupply() > 0, "everything was sold");

//             // compute the amount of token to buy based on the current rate
//             (uint256 tokensToBuy, uint256 exceedingEther) = computeTokensAmount(
//                 msg.value
//             );
//             toClaim[msg.sender] = toClaim[msg.sender].add(tokensToBuy);


//             balance += msg.value;   // add the funds to the balance

//             // refund eventually exceeding eth
//             if (exceedingEther > 0) {
//                 uint256 _toRefund = toRefund[msg.sender] + exceedingEther;
//                 toRefund[msg.sender] = _toRefund;
//             }



//             distributed = distributed.add(tokensToBuy);

//             // Mint new tokens for each submission

//             // eth deposit of user is stored in _ethDeposit
//             ethDeposit[msg.sender] = ethDeposit[msg.sender].add(msg.value);

//             emit Buy(msg.sender, tokensToBuy);
//         } 

}