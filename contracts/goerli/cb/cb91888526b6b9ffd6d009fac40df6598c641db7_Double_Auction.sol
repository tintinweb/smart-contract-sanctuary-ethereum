/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// File: GammaTest.sol


pragma solidity ^0.8.7;
contract Double_Auction{
    //struct for Bidding
    struct MarketBid{
        address marketBen;
        uint price;
        uint quantity;
        bool status;
    }
    //struct for Market
    struct GenerationBid{
        uint price;
        uint quantity;
    }
    //struct for final settlement
     struct CMar{
        address marketBen;
        address consumerBen;
        uint price;
    }

    address owner;
    mapping (address=>uint) public bids;
    mapping (address=> GenerationBid) public Gbids;

    MarketBid[] public MB ;
    MarketBid[] public CB ;
    MarketBid[] MBtemp ;
    MarketBid[] CBtemp ;
    //mapping to store withdrawl amount
    mapping(address => uint)public pendingReturns;

    CMar[] public CM;

    // constructor(){
    //     owner = msg.sender;
    // }

    function ConBid(uint _price) public payable{
        require(msg.value == (_price)* (1 ether),"The bid and value doesnot match");
        bids[msg.sender]+=_price;
        pendingReturns[msg.sender]+=_price;
    }

    function GenBid(uint _price,uint _quantity) public {
        Gbids[msg.sender]=GenerationBid({
            price:_price,
            quantity:_quantity
        });
    }
    //finalising MarketBid
    function Sellerbid() public{
        MB.push(MarketBid({
            marketBen:msg.sender,
            price:Gbids[msg.sender].price,
            quantity:Gbids[msg.sender].quantity,
            status:false}));

        MBtemp.push(MarketBid({
            marketBen:msg.sender,
            price:Gbids[msg.sender].price,
            quantity:Gbids[msg.sender].quantity,
            status:false}));
    }
    //finalising Consumption Bid
    function Consumptionbid(uint _quantity) public{
        CB.push(MarketBid({
            marketBen:msg.sender,
            price:bids[msg.sender],
            quantity:_quantity,
            status:false}));
        
        CBtemp.push(MarketBid({
            marketBen:msg.sender,
            price:bids[msg.sender],
            quantity:_quantity,
            status:false}));
    }
    function sort()public{
        SortSeller();
        SortConsumer;
    }
     function SortSeller()internal {
        for(uint i=0;i<MB.length-1;i++){
            for(uint j=0;j<MB.length-i-1;j++){
                if (MB[j].price/MB[j].quantity > MB[j+1].price/MB[j+1].quantity)
                {
                    MarketBid memory temp = MB[j];
                    MB[j] =MB[j+1];
                    MB[j+1] = temp;

                    MarketBid memory temp1 = MBtemp[j];
                    MBtemp[j] =MBtemp[j+1];
                    MBtemp[j+1] = temp1;
                }
            }
        }    
    }

    function SortConsumer() internal {
        for(uint i=0;i<CB.length-1;i++){
            for(uint j=0;j<CB.length-i-1;j++){
                if (CB[j].price/CB[j].quantity < CB[j+1].price/CB[j+1].quantity)
                {
                    // swap arr[j+1] and arr[j]
                    MarketBid memory temp = CB[j];
                    CB[j] =CB[j+1];
                    CB[j+1] = temp;

                    MarketBid memory temp1 = CBtemp[j];
                    CBtemp[j] =CBtemp[j+1];
                    CBtemp[j+1] = temp1;
                }
            }
        }    
    }
    //for finalising deal
    function Clearing() public {
        uint i=0;
        uint j=0;
        uint h=Highest(MBtemp,CBtemp);
        for(i=0;i<MB.length;i++){
            for(j=0;j<CB.length;j++){
                if(CB[j].status==false && MB[i].status==false){
                    if(((CB[j].price)>=(MB[i].price/MB[i].quantity*CB[j].quantity)) && CB[j].quantity<=MB[i].quantity){
                        uint sh=(secondHighest(MBtemp,CBtemp,j));
                        //uint clearingAmount= (((MB[i].price/MB[i].quantity)*CB[j].quantity)+CB[j].price)/2;
                        uint clearingAmount=sh+CB[j].price-h;
                        payable(MB[i].marketBen).transfer(clearingAmount * (1 ether) );
                        payable(CB[j].marketBen).transfer((CB[j].price-clearingAmount)* (1 ether));
                        MB[i].quantity=MB[i].quantity-CB[j].quantity;
                        CB[j].quantity=0;
                        CB[j].status=true;
                        CM.push(CMar({
                            marketBen:MB[i].marketBen,
                            consumerBen:CB[j].marketBen,
                            price:clearingAmount
                        }));

                        if(MB[i].quantity==0){
                            MB[i].status=true;
                        }
                    }
                }
                if(MB[i].status==true){
                            break;
                }
            }
        }

    }
    //to calculate secondBest deal
    function secondHighest(MarketBid[] memory Mtemp,MarketBid[] memory Ctemp,uint index)internal returns(uint) {
        uint i=0;
        uint j=0;
        uint result=0;
        for(i=0;i<Mtemp.length;i++){
            for(j=0;j<Ctemp.length;j++){
                if(Ctemp[j].status==false && Mtemp[i].status==false && j!=index){
                    if(((Ctemp[j].price)>=(Mtemp[i].price/Mtemp[i].quantity*Ctemp[j].quantity)) && Ctemp[j].quantity<=Mtemp[i].quantity){
                        result+=Ctemp[j].price;
                        Mtemp[i].quantity=Mtemp[i].quantity-Ctemp[j].quantity;
                        Ctemp[j].quantity=0;
                        Ctemp[j].status=true;

                        if(Mtemp[i].quantity==0){
                            Mtemp[i].status=true;
                        }
                    }
                }
                if(Mtemp[i].status==true){
                    break;
                }
            }
        }
        return result;
    }
    //to calculate best deal
    function Highest(MarketBid[] memory Mtemp,MarketBid[] memory Ctemp)internal returns(uint) {
        uint i=0;
        uint j=0;
        uint result=0;
        for(i=0;i<Mtemp.length;i++){
            for(j=0;j<Ctemp.length;j++){
                if(Ctemp[j].status==false && Mtemp[i].status==false){
                    if(((Ctemp[j].price)>=(Mtemp[i].price/Mtemp[i].quantity*Ctemp[j].quantity)) && Ctemp[j].quantity<=Mtemp[i].quantity){
                        result+=Ctemp[j].price;
                        Mtemp[i].quantity=Mtemp[i].quantity-Ctemp[j].quantity;
                        Ctemp[j].quantity=0;
                        Ctemp[j].status=true;

                        if(Mtemp[i].quantity==0){
                            Mtemp[i].status=true;
                        }
                    }
                }
                if(Mtemp[i].status==true){
                    break;
                }
            }
        }
        return result;
    }

    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        if(amount>0){
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount * (1 ether) );
        }
    }

    function balanceOf()public view returns  (uint){
        uint amountB = address(this).balance;
        return amountB;
    }

    function MarketSize() public view returns (uint){
        return MB.length;
    }

    function ConsumerSize() public view returns (uint){
        return CB.length;
    }


}