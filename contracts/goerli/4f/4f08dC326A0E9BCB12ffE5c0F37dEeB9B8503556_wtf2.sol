// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

//on goerli at:0x4692F6c59dfb3C0487B507Ff01253376b4C80D6B

//deployed on MainNet at: 
//Fixes problems w/202220929: election problem resolution
//adds feature: change SPend Limit

//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
//import "@openzeppelin/contracts/utils/Counters.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface InftContract {
    function ownerOf(uint256 tokenId) external view returns (address owner);    
}

//contract BasicNFT is ERC721URIStorage, Ownable {
contract wtf2  {
    //using Counters for Counters.Counter;
    //Counters.Counter private _tokenIds;
    
    //vars for Mangers voting
    bool public blnElecActive; //0=false=election NOT active
    uint256 public intElecEndTime; //example: block.timestamp;
    uint256 public intElecProposal; //enumeration of proposals: 10, 11 or 12-> replace wtfManager('0', 1 or 2)
    uint256 public intWtfMngr0Vote; //NFT that wtfManager(="wtfManager0") votes for in 'proposed' election above
    uint256 public intWtfMngr1Vote; //NFT that wtfManager1 votes for in 'proposed' election above
    uint256 public intWtfMngr2Vote; //NFT that wtfManager2 votes for in 'proposed' election above

    //vars for spending limit
    uint256 public intSpendInterval; //interval time period. aka: 1 day, 1 week ...
    uint256 public intSpendLimitUSD; //USD limit value of interval
    uint256 public intSpendCurrInterval;  //time stamp of curr' intervals start
    uint256 public intCurrSpendingUSD; //the amount that has been spent int the current interval

    //var's needed to track for a (ERC20 token only)"request for mngr approve":'requ mangr', 'tokenAddress', 'to address', 'amount'
    address public requSpendERC20Mngr;  //address of manager requesting to spend
    address public requSpendERC20Token;  //address of token
    address public requSpendERC20ToAddr; //address of where token(s) are TO be sent
    uint256 public requSpendERC20Amount; //amount of the token to send

    address public constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    //address public constant gTST_ADDRESS = 0x7af963cF6D228E564e2A0aA0DdBF06210B38615D;  //use for Goerli tests

    /*
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
    AggregatorV3Interface internal priceFeed;

    struct NftStat {
        uint256 movePos;  // request to move asset
        uint256 moveLoc;  // location requested to move
        uint256 moveQty;  // qty requested to move
        uint256 currPos;  // current move posion
        uint256 currLoc;  //current Locaion
        uint256 currQty;  //current QTY
    }

    mapping(uint256 => NftStat) public nftStat;
    //uint256 public totNft; //running total of all NFTs for this contract
    
    //nft number of WTF MANAGER that approves dispensation to and from WTF account
    uint256 public wtfManager; //primary manager. AKA wtfManager)
    uint256 public wtfManager1; //aux mngr1
    uint256 public wtfManager2; //aux mngr2

    //nftnumber of Helix account
    uint256 public helixNft;

    ////define: nftContrAddress, tokenId in constructor
    address nftContrAddress;
    //uint256 tokenId;

    string public wtfUrl = "helixnft.io";

    event evMoveRequest(
        uint256 indexed _token,
        address sender
    );
    event evMoved(
        uint256 indexed _token,
        address sender
    );
    event TransferSent(address _from, address _destAddr, uint _amount);

    
       

  


    //constructor() ERC721("wtf20230527", "WTF7") { 
    constructor(address _nftContrAddress){  //}, uint256 _tokenId){  
    //constructor(){ 
        wtfManager=1;//set manager(s) nft 1
        helixNft=15;//set helix nft 15
        wtfManager1=3;
        wtfManager2=13;

        //set ini' spend limit vars
        intSpendInterval = 60*60*24; //60*60*24=1 dayinterval time period. aka: 1 day, 1 week ...
        intSpendLimitUSD = 28000;//$28000 is starting limit for 1 mngr to trans in 1 day. USD limit value of interval
        //NOTE: block.timestamp = SECONDS from epoch
        intSpendCurrInterval = block.timestamp;  //time stamp of curr' intervals START (ends at + intSpendInterval)
        intCurrSpendingUSD =0;  //set initial current spending to zero

        //vars for Mangers voting
        blnElecActive =false; //0=false=election NOT active
        intElecEndTime= 0; //example: block.timestamp;
        intElecProposal=0; //enumeration of proposals: 10, 11 or 12-> replace wtfManager('0', 1 or 2)
        intWtfMngr0Vote=0; //NFT that wtfManager(="wtfManager0") votes for in 'proposed' election above
        intWtfMngr1Vote=0; //NFT that wtfManager1 votes for in 'proposed' election above
        intWtfMngr2Vote=0; //NFT that wtfManager2 votes for in 'proposed' election above

        //priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e); //!!!!!!!goerli only
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); //main net USD/ETH

        nftContrAddress=_nftContrAddress;
        //tokenId=_tokenId;
    }
   
    /*
    //mint func for setting up beginer nft's
    function ownerMint(string memory tokenURI) external onlyOwner {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        totNft = newItemId; //update total number of NFTs for this contract

        //set nftStat[newItemId]. struct items

    }
    */

    function getNftOwner(uint256 _tokenId) public view returns (address){
        InftContract nftContr=InftContract(nftContrAddress);
        address _nftOwner=nftContr.ownerOf(_tokenId);
        return _nftOwner;
    }

    //change Spend Limit
    function changeSpendLimitUSD(uint256 newLimit) internal{
        intSpendLimitUSD=newLimit;
    }

    //initiate an new election
    function createElection(uint256 proposal) internal{
        blnElecActive=true;
        //intElecEndTime= block.timestamp + 600; //600 sec =10min. !!!!!!!!!!!!!change 1 week on Main Net Deploy Deploy!!!!!!!!!!!
        intElecEndTime= block.timestamp + 604800;  //604800
        intElecProposal= proposal;
        intWtfMngr0Vote=0;
        intWtfMngr1Vote=0;
        intWtfMngr2Vote=0;
    }

    //call at end of election
    function destroyElection() internal{
        blnElecActive=false;
        intElecEndTime= 0; 
        intElecProposal= 0;
        intWtfMngr0Vote=0;
        intWtfMngr1Vote=0;
        intWtfMngr2Vote=0;
    }

    //resolve election function
    function resolveElec() public view returns(uint256){
        uint256 winner= 0; //default 'winner' (if zero "no winner")
        if(intWtfMngr0Vote == intWtfMngr1Vote){
            winner=intWtfMngr0Vote;
        }
        if(intWtfMngr0Vote == intWtfMngr1Vote){
            winner=intWtfMngr0Vote;
        }
        if(intWtfMngr1Vote == intWtfMngr2Vote){
            winner=intWtfMngr1Vote;
        }
        if(winner==0){
            if(intWtfMngr0Vote>0){ winner=intWtfMngr0Vote; }
            if(intWtfMngr1Vote>0){ winner=intWtfMngr1Vote; }
            if(intWtfMngr2Vote>0){ winner=intWtfMngr2Vote; }
        }
        return winner;
    }


    //election function
    function mngrElection(uint256 callingNft, uint256 request, uint256 directObject) public returns(uint256){
        //callingNft = number of nft who is calling this function
        //request = what election action being requested: 1 = "TO vote", 2 = "FOR a vote/election"
        //directObject = item or qty that 'action' is being requested on. 
            //intElecProposal=0; enumeration of proposals: 10, 11 or 12-> replace wtfManager('0', 1 or 2)
            //intElecProposal = 200,000,000 to 209,999,999 = change Mngr Spending Limit to: (intElecProposal - 200,000,000) = a number between 0 and 9,999,999 
        uint256 elecError =0; //default error = 0 = no errors
        if(blnElecActive){
            if(intWtfMngr0Vote>0 && intWtfMngr0Vote>0 && intWtfMngr0Vote>0){
                //resolveElec();	//call resolve election
                //check for elec' type: new manager OR spend limit change OR .........
                if (intElecProposal>9 && intElecProposal<13){
                    //new mangaer election
                    setWtfMngr(intElecProposal, resolveElec());
                }
                if (intElecProposal>200000000 && intElecProposal<210000000){
                    //spending limit change
                    if (resolveElec()!=0){ changeSpendLimitUSD((resolveElec()-200000000));}
                }
                
                destroyElection();
            }else{
                if(block.timestamp>intElecEndTime){
                    if(resolveElec()!=0){
                        //check for elec' type: new manager OR spend limit change OR .........
                        //setWtfMngr(intElecProposal, resolveElec());
                        if (intElecProposal>9 && intElecProposal<13){
                            //new mangaer election
                            setWtfMngr(intElecProposal, resolveElec());
                        }
                        if (intElecProposal>200000000 && intElecProposal<210000000){
                            //spending limit change
                            if (resolveElec()!=0){ changeSpendLimitUSD((resolveElec()-200000000));}
                        }
                    }
                    //reset election timer OR stop election
                    destroyElection();
                }else{
                    if(request==2){
                        elecError=1;  //error "1" = request for new vote with vote already in progress
                    }else{
                        if(request==1){
                            //check for 'callingNft' == manager 1, 2 or 3
                            address wtfManAddr=getNftOwner(wtfManager);             //set var for managers address
                            address wtfManAddr1=getNftOwner(wtfManager1);
                            address wtfManAddr2=getNftOwner(wtfManager2);
                            
                            //check mnager# = 'callingNft'
                            if (callingNft==wtfManager){
                                //setintwetMngr0Vote
                                require((wtfManAddr==msg.sender), "Not authorized. error3");  //check for user to be "wtfManager"
                                intWtfMngr0Vote==directObject;
                            }
                            if (callingNft==wtfManager1){
                                //setintwetMngr0Vote
                                require((wtfManAddr1==msg.sender), "Not authorized. error3");  //check for user to be "wtfManager"
                                intWtfMngr1Vote=directObject;
                            }
                            if (callingNft==wtfManager2){
                                //setintwetMngr0Vote
                                require((wtfManAddr2==msg.sender), "Not authorized. error3");  //check for user to be "wtfManager"
                                intWtfMngr2Vote=directObject;
                            }
                        }else{
                            elecError=2; 
                        }
                    }
                }
            }
        }else{
            if(request==1){
                elecError= 4; //error "4" = voting with out active election in progress
            }else{
                if(request==2){
                    //check for 'callingNft' == manager 1, 2 or 3
                    address wtfManAddr=getNftOwner(wtfManager);             //set var for managers address
                    address wtfManAddr1=getNftOwner(wtfManager1);
                    address wtfManAddr2=getNftOwner(wtfManager2);
                    require((wtfManAddr==msg.sender || wtfManAddr1==msg.sender || wtfManAddr2==msg.sender), "Not authorized. error3");  //check for user to be "wtfManager"
                    createElection(directObject); //call create Election function
                }else{
                    elecError = 2; //error "2" = unknow request. maybe researved for future use?
                }
            }
        }
        return elecError;
    }

    //change wtfUrl "pointer". primary manager (wtfMan) only.
    function setWtfUrl(string memory _value) public {
        address wtfManAddr=getNftOwner(wtfManager);
        require(wtfManAddr==msg.sender);
        wtfUrl = _value;
    }

    //change usd/eth oricale "pointer". primary manager (wtfMan) only.
    function setPriceFeed(address _addr) public {
        address wtfManAddr=getNftOwner(wtfManager);
        require(wtfManAddr==msg.sender);
        priceFeed = AggregatorV3Interface(_addr); //main net USD/ETH
    }

    //change NFT "pointer". primary manager (wtfMan) only.
    function setNftContrAddr(address _addr) public {
        address wtfManAddr=getNftOwner(wtfManager);
        require(wtfManAddr==msg.sender);
        //priceFeed = AggregatorV3Interface(_addr); //main net USD/ETH
        nftContrAddress=_addr;
    }

    /*
    //this is the mint function for managers only
    function mint(string memory tokenURI) public {
        address wtfManAddr=ownerOf(wtfManager);             //set var for managers address
        address wtfManAddr1=ownerOf(wtfManager1);
        address wtfManAddr2=ownerOf(wtfManager2);
        require((wtfManAddr==msg.sender || wtfManAddr1==msg.sender || wtfManAddr2==msg.sender), "Not authorized");  //check for user to be "wtfManager"
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        totNft = newItemId; //update total number of NFTs for this contract

        //set nftStat[newItemId]. struct items

    }
    */

    //owner of nft request asset to "move"
    function setMoveRequ(uint256 tokenId_, uint256 movePos_, uint256 moveLoc_, uint256 moveQty_) external payable {
        address nftOwner=getNftOwner(tokenId_);
        require(nftOwner==msg.sender, "not owner of NFT");
        
        //move qty not set by user. assume value to be amount payed to contract
        //"4" to be used as enumerated value for "deposit"
        if (moveQty_== 0 && movePos_==4){
            moveQty_=msg.value;
        }

        //"5" enum "movePos" value for "withdrawl". qty to withhdr' = moveQty_ in wei.
        
        nftStat[tokenId_].movePos=movePos_;
        nftStat[tokenId_].moveLoc=moveLoc_;
        nftStat[tokenId_].moveQty=moveQty_;
        emit evMoveRequest(
            tokenId_,
            msg.sender
        );

    }

    //function to withdrawl from WTF
    function wtfWithdrawl(uint256 tokenId_, uint256 currPos_, uint256 currLoc_, uint256 currQty_) external payable {
        //reqire func user to be wtfManager
        address wtfManAddr=getNftOwner(wtfManager);             //set var for managers address
        address wtfManAddr1=getNftOwner(wtfManager1);
        address wtfManAddr2=getNftOwner(wtfManager2);
        require((wtfManAddr==msg.sender || wtfManAddr1==msg.sender || wtfManAddr2==msg.sender), "Not authorized");  //check for user to be "wtfManager"
        
        address nftOwner=getNftOwner(tokenId_);                 //get address of nft owner to be payed

        uint256 withDrawlPaym = msg.value;                  //set amount to be payed

        payable(nftOwner).transfer(withDrawlPaym);          //pay nft owner 

        //set CURRent status for nftStat var's
        nftStat[tokenId_].currPos=currPos_;  //currPos- CURRent POSition
        nftStat[tokenId_].currLoc=currLoc_;  //currLoc- CURRent LOCation
        nftStat[tokenId_].currQty=currQty_;  //currQty- CURRent QuanTitY
        //set "move"(aka "request to MOVE") status to "null"
        nftStat[tokenId_].movePos=0;
        nftStat[tokenId_].moveLoc=0;
        nftStat[tokenId_].moveQty=0;
        //emit event to "listening" affected devices
        emit evMoved(
            tokenId_,
            msg.sender
        );

    }


    //WTF Manager to set vars per recent request
    //this is to ACTUALY set the 'move' request to the 'curr' (current) "status"
    function setMoveStatus(uint256 tokenId_, uint256 currPos_, uint256 currLoc_, uint256 currQty_) public {
        //reqire func user to be wtfManager
        address wtfManAddr=getNftOwner(wtfManager);             //set var for managers address
        address wtfManAddr1=getNftOwner(wtfManager1);
        address wtfManAddr2=getNftOwner(wtfManager2);
        require((wtfManAddr==msg.sender || wtfManAddr1==msg.sender || wtfManAddr2==msg.sender), "Not authorized");  //check for user to be "wtfManager"
        /*
        Reserved 'xPos' (movePos or currPos):
        4 ="deposit"
        5 = "withdrawal"
        xxx= "call for new manager election- existing managers only"
        xxx= "cast vote in manager election for a new manager - existing managers only"
        xxx="request for  approval of 'over limit transaction'- existing managers only"
        xxx="approve of 'over limit transaction'- existing managers only"

        */
        //add "switch" here= series of "IF"s



        //!!!!!!!Execute "move" !!!!!!!!!!!!!
        //set CURRent status for nftStat var's
        nftStat[tokenId_].currPos=currPos_;  //currPos- CURRent POSition
        nftStat[tokenId_].currLoc=currLoc_;  //currLoc- CURRent LOCation
        nftStat[tokenId_].currQty=currQty_;  //currQty- CURRent QuanTitY
        //!!!!!!!END Execute "move" !!!!!!!!!!!!


        //set "move"(aka "request to MOVE") status to "null"
        nftStat[tokenId_].movePos=0;
        nftStat[tokenId_].moveLoc=0;
        nftStat[tokenId_].moveQty=0;
        //emit event to "listening" affected devices
        emit evMoved(
            tokenId_,
            msg.sender
        );
    }

    function setWtfMngr(uint256 newWtfMngr) public {
        address wtfManAddr=getNftOwner(wtfManager);             //set var for managers address
        require((wtfManAddr==msg.sender), "Not authorized");  //check for user to be "wtfManager"
        wtfManager=newWtfMngr;
    }
    function setWtfMngr1(uint256 newWtfMngr) public {
        address wtfManAddr1=getNftOwner(wtfManager1);
        require((wtfManAddr1==msg.sender), "Not authorized");  //check for user to be "wtfManager"
        wtfManager1=newWtfMngr;
    }
    function setWtfMngr2(uint256 newWtfMngr) public {
        address wtfManAddr2=getNftOwner(wtfManager2);
        require((wtfManAddr2==msg.sender), "Not authorized");  //check for user to be "wtfManager"
        wtfManager2=newWtfMngr;
    }

    function setHelixNft(uint256 newHelixNft) public{
        address addrHelNft=getNftOwner(helixNft);
        require((addrHelNft==msg.sender), "Not authorized");
        helixNft=newHelixNft;

    }

    function setWtfMngr(uint256 mngrToSet, uint256 newWtfMngr) internal {
        if(mngrToSet==10){
        //reset mngr0
        wtfManager=newWtfMngr;
        }
        if(mngrToSet==11){
        //reset mngr1
        wtfManager1=newWtfMngr;
        }
        if(mngrToSet==12){
        //reset mngr2
        wtfManager2=newWtfMngr;
        }
        
    }

    //func for other manager to approve a spending request by a manager
    function approveSpendRequest(bool blnApprvTx) public {
        address wtfManAddr=getNftOwner(wtfManager);             //set var for managers address
        address wtfManAddr1=getNftOwner(wtfManager1);
        address wtfManAddr2=getNftOwner(wtfManager2);
        require((wtfManAddr==msg.sender || wtfManAddr1==msg.sender || wtfManAddr2==msg.sender), "Not authorized");
        require((msg.sender!=requSpendERC20Mngr), "another manager must authorize");
        if(blnApprvTx){
            //if requSpendERC20Token == address(this) then this is an ETH tx NOT ERC20!!!!
            if (requSpendERC20Token == address(this)){
                //use ETH tx process
                (bool sent,) =requSpendERC20ToAddr.call{value:requSpendERC20Amount}(""); //(amount);
                //(bool sent, bytes memory data) = _to.call{value: msg.value}("");
                require(sent, "Failed to send Ether");
            }else{
                //spending is approved. Execute Tx.
                //set erc20 token address
                IERC20 token =IERC20(requSpendERC20Token);
                token.transfer(requSpendERC20ToAddr, requSpendERC20Amount);
                //accumulate "current sum"="proposed sum"
                //intCurrSpendingUSD=propTotSpending;
                emit TransferSent(msg.sender, requSpendERC20ToAddr, requSpendERC20Amount);
            }
            
        }

        //reset requSpend var's
        requSpendERC20Mngr = address(0);//0;
        requSpendERC20Token = address(0);  //address of token
        requSpendERC20ToAddr = address(0); //address of where token(s) are TO be sent
        requSpendERC20Amount = 0; //amount of the token to send
    }
    //func' "request for mngr aprv spending"('requ mangr', 'tokenAddress', 'to address', 'amount')
    function requSpendApprove(address requMngr, address tokAddr, address to,uint256 amount) internal{
        //Manager 'requMngr' requests to send 'amount' of token at address 'tokAddr' TO 'to' .
        /*
        address public requSpendERC20Mngr;
        address public requSpendERC20Token;  //address of token
        address public requSpendERC20ToAddr; //address of where token(s) are TO be sent
        uint256 public requSpendERC20Amount; //amount of the token to send
        */
        //set public var's:
        requSpendERC20Mngr = requMngr;
        requSpendERC20Token = tokAddr;  //address of token
        requSpendERC20ToAddr = to; //address of where token(s) are TO be sent
        requSpendERC20Amount = amount; //amount of the token to send

        //insert EVENT if needed to notifiy listeners

    }

    //move an ERC 20 token from the SC to another address
    function transferERC20(address tokAddr, address to, uint256 amount) public {
        IERC20 token =IERC20(tokAddr); //convert tokAddr to IERC20 type
        //NOTE 'amoun' is in "Base Units" of the 'token'. Use erc20 contract (of token) 'decimals()' func' if needed
        //bool transApproved = false; //must be true for transfer to execute
        address wtfManAddr=getNftOwner(wtfManager);             //set var for managers address
        address wtfManAddr1=getNftOwner(wtfManager1);
        address wtfManAddr2=getNftOwner(wtfManager2);
        require((wtfManAddr==msg.sender || wtfManAddr1==msg.sender || wtfManAddr2==msg.sender), "Not authorized");  //check for user to be "wtfManager"
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        //get token type
        //!!!!!!!! for test on Goerli, use "TST" at 0x7af963cF6D228E564e2A0aA0DdBF06210B38615D !!!!!!!!!!!!!!!!!!!
        //verify to be "USDT"- only USDT or ETH currently supported for valuations in SC
            //IF token type is "NOT ETH" OR is "NOT USDT" token trans' requires aproval of a second manager!!
        if(tokAddr!=USDT_ADDRESS){      //!!!!!!!!!!!!!changed to USDT addresss for Main Net Deploy Deploy!!!!!!!!!!!
            //needs other mngr approval
            requSpendApprove(msg.sender, tokAddr, to, amount);
        }else{
            //get value "USD". note 'USDT' always val's at '1 to 1' //!!!!!!!!!!add on Main Net Deploy !!!!!!!
            uint256 valUSD=amount / (10**18); //!!!!!!!change on Main Net Deploy !!!!!!!!!!!!!!!!!!
            //get current interval 
            //if "current interval" is expired: reset interval
            if ((intSpendCurrInterval+intSpendInterval)>block.timestamp){
                intSpendCurrInterval=block.timestamp; //reset interval START
                intCurrSpendingUSD=0;   //reset current spending SUM
            }
            //get "current sum of spending"=intCurrSpendingUSD
            //"proposed Sum"= add  value to "current sum"
            uint256 propTotSpending=intCurrSpendingUSD + valUSD;
            //if "proposed sum"> "interval spend limit": move transaction to "pending mngr aproval" 
            if (propTotSpending>intSpendLimitUSD){
                //send info to func' "request for mngr aprv spending"('requ mangr', 'tokenAddress', 'to address', 'amount')
                requSpendApprove(msg.sender, tokAddr, to, amount);
            }else{
                token.transfer(to, amount);
                //accumulate "current sum"="proposed sum"
                intCurrSpendingUSD=propTotSpending;
                emit TransferSent(msg.sender, to, amount);        
            }  
        }
    }    

    //move an ETH the SC to another address
    function transferETH(address payable _to, uint256 amount) public payable {
        address wtfManAddr=getNftOwner(wtfManager);             //set var for managers address
        address wtfManAddr1=getNftOwner(wtfManager1);
        address wtfManAddr2=getNftOwner(wtfManager2);
        require((wtfManAddr==msg.sender || wtfManAddr1==msg.sender || wtfManAddr2==msg.sender), "Not authorized");  //check for user to be "wtfManager"
        //get value "USD".
        //if "current interval" is expired: reset interval
        if ((intSpendCurrInterval+intSpendInterval)>block.timestamp){
            intSpendCurrInterval=block.timestamp; //reset interval START
            intCurrSpendingUSD=0;   //reset current spending SUM
        }

        (
            /*uint80 roundID*/,
            int intCurrEthPrice,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        //int intCurrEthPrice = getLatestPrice();
        uint256 currEthPrice = 0;
        if(intCurrEthPrice < 0) {
            currEthPrice=0;
        }else{
            currEthPrice=uint(intCurrEthPrice);
        }
        //uint8 decimals = priceFeed.decimals();
        uint8 decs =  priceFeed.decimals();//getLatestDecimals();
        currEthPrice = currEthPrice/(10**decs);
        uint256 propTotSpending=intCurrSpendingUSD + currEthPrice * (amount/(10**18));
        if (propTotSpending>intSpendLimitUSD){
           //needs appr' by 2nd manager requSpendApprove(msg.sender, tokAddr, to, amount);
           requSpendApprove(msg.sender, address(this), _to, amount); //use "this" conatrcant address to distinguish a ETH trans'
        }else{
            (bool sent,) =_to.call{value:amount}(""); //(amount);
            //(bool sent, bytes memory data) = _to.call{value: msg.value}("");
            require(sent, "Failed to send Ether");
        }
    }  

    function depositApprove(uint256 depositorAtoms, uint256 depositorNft, uint256 wtfAtoms, uint256 helixAtoms, uint256 refrNftAtoms, uint256 refrNft)public {
        address wtfManAddr=getNftOwner(wtfManager);             //set var for managers address
        address wtfManAddr1=getNftOwner(wtfManager1);
        address wtfManAddr2=getNftOwner(wtfManager2);
        require((wtfManAddr==msg.sender || wtfManAddr1==msg.sender || wtfManAddr2==msg.sender), "Not authorized");  //check for user to be "wtfManager"
        //update SC depositors atoms
        //set CURRent status for nftStat var's
        //nftStat[depositorNft_].currPos=currPos_;  //currPos- CURRent POSition
        //nftStat[depositorNft_].currLoc=currLoc_;  //currLoc- CURRent LOCation
        nftStat[depositorNft].currQty=depositorAtoms;  //currQty- CURRent QuanTitY
        //set "move"(aka "request to MOVE") status to "null"
        nftStat[depositorNft].movePos=0;
        nftStat[depositorNft].moveLoc=0;
        nftStat[depositorNft].moveQty=0;
        
        //update SC Wtf atoms
        nftStat[wtfManager].currQty=wtfAtoms;  //currQty- CURRent QuanTitY
        //set "move"(aka "request to MOVE") status to "null"
        nftStat[wtfManager].movePos=0;
        nftStat[wtfManager].moveLoc=0;
        nftStat[wtfManager].moveQty=0;

	    //update SC Helix atoms
        nftStat[helixNft].currQty=helixAtoms;  //currQty- CURRent QuanTitY
        //set "move"(aka "request to MOVE") status to "null"
        nftStat[helixNft].movePos=0;
        nftStat[helixNft].moveLoc=0;
        nftStat[helixNft].moveQty=0;

        if (refrNft!=0){
            //update SC Referecne NFT atoms
             nftStat[refrNft].currQty=refrNftAtoms;  //currQty- CURRent QuanTitY
            //set "move"(aka "request to MOVE") status to "null"
            nftStat[refrNft].movePos=0;
            nftStat[refrNft].moveLoc=0;
            nftStat[refrNft].moveQty=0;

        }
	    
    }    


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}