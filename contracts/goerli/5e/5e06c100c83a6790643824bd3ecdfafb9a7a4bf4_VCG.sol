/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
contract VCG{
    // struct for Bidding
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

    function ConBid(uint _price) public payable{
        require(msg.value == (_price),"The bid and value doesnot match");
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
        quickSortC(int(0), int(CB.length - 1));
        quickSortM(int(0), int(MB.length - 1));
    }

    function quickSortC( int left, int right)internal  {
    int i = left;
    int j = right;
    if (i == j) return;
    uint p=uint(left + (right - left) / 2);
    uint pivot = CB[p].price/CB[p].quantity;
    while (i <= j) {
        while (CB[uint(i)].price/CB[uint(i)].quantity > pivot) i++;
        while (pivot > CB[uint(j)].price/CB[uint(j)].quantity) j--;
        if (i <= j) {
            MarketBid memory temp = CB[uint(i)];
                    CB[uint(i)] =CB[uint(j)];
                    CB[uint(j)] = temp;
            // (CB[uint(i)], CB[uint(j)]) = (CB[uint(j)], CB[uint(i)]);
            i++;
            j--;
        }
    }
    if (left < j)
        quickSortC( left, j);
    if (i < right)
        quickSortC(i, right);
    }
    function quickSortM( int left, int right)internal  {
    int i = left;
    int j = right;
    if (i == j) return;
    uint p=uint(left + (right - left) / 2);
    uint pivot = MB[p].price/MB[p].quantity;
    while (i <= j) {
        while (MB[uint(i)].price/MB[uint(i)].quantity <pivot) i++;
        while (pivot < MB[uint(j)].price/MB[uint(j)].quantity) j--;
        if (i <= j) {
            MarketBid memory temp = MB[uint(i)];
                    MB[uint(i)] =MB[uint(j)];
                    MB[uint(j)] = temp;
            i++;
            j--;
        }
    }
    if (left < j)
        quickSortM( left, j);
    if (i < right)
        quickSortM(i, right);
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
                        uint clearingAmount=sh+CB[j].price-h;
                        payable(MB[i].marketBen).transfer(clearingAmount);
                        payable(CB[j].marketBen).transfer((CB[j].price-clearingAmount));
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
            payable(msg.sender).transfer(amount);
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